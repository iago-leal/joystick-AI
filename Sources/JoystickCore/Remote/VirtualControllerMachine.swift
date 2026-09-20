import Foundation

/// Controle virtual do iPhone (`010-joystick-virtual-iphone` D-03, D-05 a D-08).
///
/// Máquina pura: traduz as mensagens do canal em `InputEvent` idênticos aos que a leitura do controle produz, de modo
/// que roteamento, cliques, camadas de atalho e apontamento continuem com uma regra só. Não tem fila própria, nem
/// relógio: o chamador serializa as transições na fila `input` e informa o `t_arrival` de cada mensagem.
///
/// A zona morta dos analógicos não é aplicada aqui: a amostra sai bruta, limitada a ±1, e o executor a normaliza com
/// os valores de `pointer` do arquivo de configuração, como `AxisTouchReader` faz com o controle físico (D-05).
public struct VirtualControllerMachine: Sendable {
    /// Botões mantidos pelo iPhone; nunca entram no `ActiveControllerRegistry` (D-04).
    public private(set) var pressed: Set<VirtualButton> = []
    /// Última amostra limitada de cada analógico, para suprimir a repetição (D-06).
    public private(set) var sticks: [VirtualStick: StickSample] = [:]
    /// Dedos na área de apontamento e a última posição de cada um, necessária para a fase `ended` sintética.
    public private(set) var fingerPositions: [Int: (x: Double, y: Double)] = [:]
    public private(set) var mode: CenterMode
    /// Botões pressionados na sessão, para `remote.disconnected` (D-10); não zera com a soltura.
    public private(set) var buttonCount = 0
    /// Cliques de mouse originados do controle virtual na sessão: os botões de apontamento de RN-11 (D-10).
    public private(set) var clickCount = 0
    /// `t_arrival` da última mensagem do controle, base do vigia (§5 do protocolo).
    public private(set) var lastMessageNs: UInt64

    /// Silêncio a partir do qual o vigia solta o que o iPhone mantém, como no teclado remoto (008 D-11).
    public static let watchdogNs: UInt64 = RemoteKeyboardMachine.watchdogNs

    public init(mode: CenterMode = .compact, nowNs: UInt64 = 0) {
        self.mode = mode
        lastMessageNs = nowNs
    }

    public var fingers: Set<Int> { Set(fingerPositions.keys) }

    /// Verdadeiro enquanto o iPhone mantém botão, analógico fora do repouso ou dedo na área de apontamento.
    public var holdsAnything: Bool {
        !pressed.isEmpty || !fingerPositions.isEmpty
            || VirtualStick.allCases.contains { (sticks[$0] ?? .centered) != .centered }
    }

    public mutating func noteMessage(nowNs: UInt64) {
        lastMessageNs = nowNs
    }

    /// Vigia: com algo mantido e um segundo sem mensagem, solta tudo. `nil` quando não há o que fazer.
    public mutating func tick(nowNs: UInt64) -> [InputEvent]? {
        guard holdsAnything, nowNs >= lastMessageNs, nowNs - lastMessageNs >= Self.watchdogNs else { return nil }
        return releaseAll(nowNs: nowNs)
    }

    // MARK: - Botões

    /// Pressionar botão já mantido, ou soltar botão livre, não tem efeito e não conta (§4 do protocolo).
    public mutating func button(_ button: VirtualButton, down: Bool, nowNs: UInt64) -> [InputEvent] {
        if down {
            guard pressed.insert(button).inserted else { return [] }
            buttonCount += 1
            if ShortcutConfig.pointerButtons.contains(button.buttonID) { clickCount += 1 }
        } else {
            guard pressed.remove(button) != nil else { return [] }
        }
        return [InputEvent(
            kind: down ? .buttonDown : .buttonUp, element: .button(button.buttonID), remote: true, timestamp: nowNs)]
    }

    // MARK: - Analógicos

    /// Amostra limitada a ±1 e entregue só quando muda; o repouso encerra a série com um evento (D-06).
    public mutating func stick(_ stick: VirtualStick, sample: StickSample, nowNs: UInt64) -> [InputEvent] {
        let clamped = sample.clamped
        guard sticks[stick] ?? .centered != clamped else { return [] }
        sticks[stick] = clamped
        return [InputEvent(
            kind: .axis, element: stick.element, x: clamped.x, y: clamped.y, remote: true, timestamp: nowNs)]
    }

    // MARK: - Área de apontamento

    /// Fase órfã é descartada e o quinto dedo não entra; a posição segue o limite de `Normalization.touchPosition`.
    public mutating func pad(_ sample: PadSample, nowNs: UInt64) -> [InputEvent] {
        let position = Normalization.touchPosition(x: sample.x, y: sample.y)
        switch sample.phase {
        case .began:
            guard fingerPositions[sample.finger] == nil, fingerPositions.count < PadSample.maxFingers else { return [] }
            fingerPositions[sample.finger] = position
        case .moved:
            guard fingerPositions[sample.finger] != nil else { return [] }
            fingerPositions[sample.finger] = position
        case .ended:
            guard fingerPositions.removeValue(forKey: sample.finger) != nil else { return [] }
        }
        return [touch(finger: sample.finger, phase: sample.phase, x: position.x, y: position.y, nowNs: nowNs,
                      synthetic: false)]
    }

    // MARK: - Estado do bloco central e solturas

    /// Troca do bloco central (D-08): sair do apontamento solta o que ele mantinha, e só isso. A soltura das teclas,
    /// ao sair de um dos teclados, é da `RemoteKeyboardMachine`.
    public mutating func apply(mode: CenterMode, nowNs: UInt64) -> [InputEvent] {
        guard mode != self.mode else { return [] }
        let leavingPointer = self.mode == .pointer
        self.mode = mode
        return leavingPointer ? releaseAll(nowNs: nowNs) : []
    }

    /// Solta tudo o que o iPhone mantém: botões em ordem estável, analógicos ao repouso e dedos levantados. Usada pelo
    /// vigia, pelo `release`, pelo `bye`, pela substituição de sessão e pelo desligamento (§5 do protocolo).
    public mutating func releaseAll(nowNs: UInt64) -> [InputEvent] {
        var events: [InputEvent] = []
        for button in pressed.sorted() {
            events.append(InputEvent(
                kind: .buttonUp, element: .button(button.buttonID), synthetic: true, remote: true, timestamp: nowNs))
        }
        pressed.removeAll()
        for stick in VirtualStick.allCases where (sticks[stick] ?? .centered) != .centered {
            sticks[stick] = .centered
            events.append(InputEvent(kind: .axis, element: stick.element, x: 0, y: 0, remote: true, timestamp: nowNs))
        }
        for finger in fingerPositions.keys.sorted() {
            let position = fingerPositions[finger]!
            events.append(touch(
                finger: finger, phase: .ended, x: position.x, y: position.y, nowNs: nowNs, synthetic: true))
        }
        fingerPositions.removeAll()
        return events
    }

    private func touch(finger: Int, phase: TouchPhase, x: Double, y: Double, nowNs: UInt64, synthetic: Bool) -> InputEvent {
        InputEvent(
            kind: .touch, element: .touch(finger), x: x, y: y, touchIndex: finger, touchPhase: phase,
            synthetic: synthetic, remote: true, timestamp: nowNs)
    }
}
