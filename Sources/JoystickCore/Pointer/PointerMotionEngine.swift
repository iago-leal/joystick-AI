import Foundation

/// Estado do movimento entre emissões (`data-delta.md` §1.4). Os campos de clique ficam em
/// `ClickStateMachine` e os de rolagem em `ScrollMapper`.
public struct PointerState: Sendable {
    public var leftStick = (x: 0.0, y: 0.0)
    public var rightStick = (x: 0.0, y: 0.0)
    public var pendingTouchDelta = PointDelta.zero
    /// Resto do arrasto vindo do iPhone, gasto aos poucos nos ticks (E-10).
    public var touchGlide = TouchGlide()
    public var subpixel = SubpixelAccumulator()
    public var timerRunning = false

    public init() {}
}

public enum TimerCommand: Equatable, Sendable {
    case none, start, stop
}

public struct MotionOutput: Equatable, Sendable {
    /// Deslocamento em pontos inteiros a postar agora; `nil` quando não há o que mover.
    public var move: PointDelta?
    public var timer: TimerCommand = .none
    /// A amostra saiu da zona morta do analógico esquerdo e foi postada de imediato.
    public var stickOnset = false
    /// A amostra saiu da zona morta do analógico direito; a rolagem inicial deve sair de imediato.
    public var scrollOnset = false

    public init(move: PointDelta? = nil, timer: TimerCommand = .none, stickOnset: Bool = false, scrollOnset: Bool = false) {
        self.move = move
        self.timer = timer
        self.stickOnset = stickOnset
        self.scrollOnset = scrollOnset
    }
}

/// Combina analógico e touchpad e governa o temporizador único de 120 Hz (D-11, D-12, RN-06, RN-08).
///
/// Recebe valores de analógico já com zona morta aplicada.
public struct PointerMotionEngine: Sendable {
    public static let tickInterval = 1.0 / 120.0

    public var settings: PointerSettings
    public private(set) var state = PointerState()

    public init(settings: PointerSettings) {
        self.settings = settings
    }

    public var timerRunning: Bool { state.timerRunning }

    /// RN-08: precisão só com L1 pressionado e nenhum outro dos 18 botões.
    public static func precisionActive(pressed: Set<ButtonID>) -> Bool {
        pressed == [.l1]
    }

    public mutating func setLeftStick(x: Double, y: Double, pressed: Set<ButtonID>) -> MotionOutput {
        let wasActive = isActive(state.leftStick)
        state.leftStick = (x, y)
        let nowActive = isActive(state.leftStick)
        var out = MotionOutput()
        if nowActive && !wasActive {
            out.stickOnset = true
            let d = StickKinematics.displacement(
                x: x, y: y, settings: settings, dt: Self.tickInterval,
                precision: Self.precisionActive(pressed: pressed))
            out.move = emit(d)
            startTimerIfNeeded(&out)
        } else if !nowActive && wasActive {
            stopTimerIfIdle(&out)
        }
        return out
    }

    public mutating func setRightStick(x: Double, y: Double) -> MotionOutput {
        let wasActive = isActive(state.rightStick)
        state.rightStick = (x, y)
        let nowActive = isActive(state.rightStick)
        var out = MotionOutput()
        if nowActive && !wasActive {
            out.scrollOnset = true
            startTimerIfNeeded(&out)
        } else if !nowActive && wasActive {
            stopTimerIfIdle(&out)
        }
        return out
    }

    /// Delta do touchpad em pt: imediato sem temporizador; acumulado para o próximo tick com ele.
    public mutating func touchDelta(_ delta: PointDelta, pressed: Set<ButtonID>) -> MotionOutput {
        let factor = Self.precisionActive(pressed: pressed) ? settings.precisionFactor : 1.0
        let scaled = delta * factor
        if state.timerRunning {
            state.pendingTouchDelta = state.pendingTouchDelta + scaled
            return MotionOutput()
        }
        return MotionOutput(move: emit(scaled))
    }

    /// Delta do arrasto do iPhone: em vez de sair na chegada, entra no planador e é gasto nos ticks (E-10).
    ///
    /// O temporizador passa a ser ligado também pelo arrasto remoto, e não só pelos analógicos, porque é ele que dá
    /// ao movimento a cadência regular que a rede não dá.
    public mutating func remoteTouchDelta(_ delta: PointDelta, pressed: Set<ButtonID>) -> MotionOutput {
        let factor = Self.precisionActive(pressed: pressed) ? settings.precisionFactor : 1.0
        var out = MotionOutput()
        state.touchGlide.add(delta * factor)
        startTimerIfNeeded(&out)
        return out
    }

    /// Descarta o resto do arrasto remoto; usada quando a origem some (desconexão, fim de sessão).
    public mutating func clearTouchGlide() {
        state.touchGlide.reset()
    }

    public mutating func tick(dt: Double, pressed: Set<ButtonID>) -> MotionOutput {
        guard state.timerRunning else { return MotionOutput() }
        var total = state.pendingTouchDelta
        state.pendingTouchDelta = .zero
        total = total + state.touchGlide.drain(dt: dt)
        if isActive(state.leftStick) {
            total = total + StickKinematics.displacement(
                x: state.leftStick.x, y: state.leftStick.y, settings: settings, dt: dt,
                precision: Self.precisionActive(pressed: pressed))
        }
        var out = MotionOutput(move: emit(total))
        // Com o planador vazio e os analógicos em repouso não há mais o que gastar: o tick desliga o próprio
        // temporizador, já que ninguém mais vai fazê-lo (E-10).
        if !isActive(state.leftStick), !isActive(state.rightStick), state.touchGlide.isEmpty {
            state.timerRunning = false
            out.timer = .stop
        }
        return out
    }

    private func isActive(_ stick: (x: Double, y: Double)) -> Bool {
        stick.x != 0 || stick.y != 0
    }

    private mutating func emit(_ delta: PointDelta) -> PointDelta? {
        let whole = state.subpixel.take(dx: delta.dx, dy: delta.dy)
        return whole.isZero ? nil : whole
    }

    private mutating func startTimerIfNeeded(_ out: inout MotionOutput) {
        guard !state.timerRunning else { return }
        state.timerRunning = true
        out.timer = .start
    }

    private mutating func stopTimerIfIdle(_ out: inout MotionOutput) {
        guard state.timerRunning, !isActive(state.leftStick), !isActive(state.rightStick),
              state.touchGlide.isEmpty else { return }
        state.timerRunning = false
        out.timer = .stop
        let pending = state.pendingTouchDelta
        state.pendingTouchDelta = .zero
        if let move = emit(pending) {
            out.move = move
        }
    }
}
