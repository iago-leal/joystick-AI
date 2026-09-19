import Testing
@testable import JoystickCore

/// Caixa por referência: o `#expect` não aceita chamar método `mutating` sobre valor capturado.
final class Box<Value> {
    var value: Value
    init(_ value: Value) { self.value = value }
}

extension Box where Value == RemoteKeyboardMachine {
    func down(_ code: UInt16) -> [RemoteKeyboardEffect]? { value.down(code) }
    func up(_ code: UInt16) -> [RemoteKeyboardEffect]? { value.up(code) }
    func tick(nowNs: UInt64) -> (effects: [RemoteKeyboardEffect], released: Int)? { value.tick(nowNs: nowNs) }
    func releaseAll() -> (effects: [RemoteKeyboardEffect], released: Int) { value.releaseAll() }
    func noteInvalid() -> Bool { value.noteInvalid() }
}

extension Box where Value == RemotePairing {
    func present(code: String) -> PairingOutcome { value.present(code: code) }
    func present(token: [UInt8]) -> PairingOutcome { value.present(token: token) }
}

/// Máquina do teclado remoto (`008-iphone-teclado-remoto` D-08, D-10, D-11, D-16, D-17; RN-07, RN-09, RN-10).
@Suite struct RemoteKeyboardMachineTests {
    static let a: UInt16 = 0
    static let c: UInt16 = 8
    static let v: UInt16 = 9
    static let delete: UInt16 = 51
    static let leftCommand: UInt16 = 55
    static let rightCommand: UInt16 = 54
    static let leftShift: UInt16 = 56
    static let capsLock: UInt16 = 57
    static let second: UInt64 = 1_000_000_000

    static func machine() -> RemoteKeyboardMachine {
        RemoteKeyboardMachine(geometry: .standard(.ansi))
    }

    /// Só os efeitos de tecla e modificador, sem os de estado e repetição.
    static func keys(_ effects: [RemoteKeyboardEffect]?) -> [RemoteKeyboardEffect] {
        (effects ?? []).filter {
            switch $0 {
            case .keyDown, .keyUp, .modifierDown, .modifierUp, .capsLock: true
            default: false
            }
        }
    }

    @Test func modificadorSeguradoValeEnquantoODedoEsta() {
        let m = Box(Self.machine())
        #expect(Self.keys(m.down(Self.leftCommand)) == [.modifierDown(.command)])
        #expect(m.value.state(of: .command) == .held)
        #expect(Self.keys(m.down(Self.c)) == [.keyDown(Self.c)])
        #expect(Self.keys(m.up(Self.c)) == [.keyUp(Self.c)])
        #expect(Self.keys(m.up(Self.leftCommand)) == [.modifierUp(.command)])
        #expect(m.value.state(of: .command) == .released)
    }

    @Test func tocadoESoltoFicaPresoESoltaDepoisDaProximaTeclaComum() {
        let m = Box(Self.machine())
        _ = m.down(Self.leftCommand)
        let upEffects = m.up(Self.leftCommand)
        #expect(Self.keys(upEffects).isEmpty)
        #expect(upEffects?.contains(.modifiers([.command: .latched, .shift: .released, .option: .released, .control: .released])) == true)
        #expect(m.value.state(of: .command) == .latched)
        #expect(Self.keys(m.down(Self.v)) == [.keyDown(Self.v)])
        #expect(m.value.state(of: .command) == .latched)
        #expect(Self.keys(m.up(Self.v)) == [.keyUp(Self.v), .modifierUp(.command)])
        #expect(m.value.state(of: .command) == .released)
    }

    @Test func tocarUmPresoOSolta() {
        let m = Box(Self.machine())
        _ = m.down(Self.leftShift)
        _ = m.up(Self.leftShift)
        #expect(m.value.state(of: .shift) == .latched)
        #expect(Self.keys(m.down(Self.leftShift)).isEmpty)
        #expect(Self.keys(m.up(Self.leftShift)) == [.modifierUp(.shift)])
        #expect(m.value.state(of: .shift) == .released)
        #expect(Self.keys(m.down(Self.a)) == [.keyDown(Self.a)])
        #expect(Self.keys(m.up(Self.a)) == [.keyUp(Self.a)])
    }

    @Test func comandoDireitoEEsquerdoSomam() {
        let m = Box(Self.machine())
        #expect(Self.keys(m.down(Self.leftCommand)) == [.modifierDown(.command)])
        #expect(Self.keys(m.down(Self.rightCommand)).isEmpty)
        _ = m.down(Self.c)
        _ = m.up(Self.c)
        #expect(Self.keys(m.up(Self.leftCommand)).isEmpty)
        #expect(m.value.state(of: .command) == .held)
        #expect(Self.keys(m.up(Self.rightCommand)) == [.modifierUp(.command)])
    }

    @Test func soAUltimaTeclaComumRepete() {
        let m = Box(Self.machine())
        #expect(m.down(Self.a) == [.keyDown(Self.a), .startRepeat(Self.a)])
        #expect(m.down(Self.delete) == [.stopRepeat, .keyDown(Self.delete), .startRepeat(Self.delete)])
        #expect(m.up(Self.a) == [.keyUp(Self.a)])
        #expect(m.value.repeating == Self.delete)
        #expect(m.up(Self.delete) == [.stopRepeat, .keyUp(Self.delete)])
        #expect(m.value.repeating == nil)
    }

    @Test func modificadorNaoRepete() {
        let m = Box(Self.machine())
        let effects = m.down(Self.leftShift) ?? []
        #expect(!effects.contains { if case .startRepeat = $0 { true } else { false } })
    }

    @Test func downEUpRepetidosSaoIgnorados() {
        let m = Box(Self.machine())
        _ = m.down(Self.a)
        #expect(m.down(Self.a) == [])
        _ = m.up(Self.a)
        #expect(m.up(Self.a) == [])
        #expect(m.up(Self.leftCommand) == [])
        #expect(m.value.keyCount == 1)
    }

    @Test func codigoForaDaGeometriaEInvalido() {
        let m = Box(Self.machine())
        #expect(m.down(71) == nil)
        #expect(m.up(71) == nil)
    }

    @Test func capsLockPorCaminhoProprio() {
        let m = Box(Self.machine())
        _ = m.down(Self.leftShift)
        _ = m.up(Self.leftShift)
        #expect(m.down(Self.capsLock) == [.capsLock(down: true)])
        #expect(m.up(Self.capsLock) == [.capsLock(down: false)])
        #expect(m.value.state(of: .shift) == .latched, "Caps Lock não solta os presos")
        #expect(m.value.repeating == nil)
        _ = m.down(Self.capsLock)
        let released = m.releaseAll()
        #expect(released.effects.contains(.capsLock(down: false)))
    }

    @Test func vigiaSoltaTudoSoComAlgoMantido() {
        let m = Box(RemoteKeyboardMachine(geometry: .standard(.ansi), nowNs: 0))
        #expect(m.tick(nowNs: 5 * Self.second) == nil, "nada mantido")
        m.value.noteMessage(nowNs: 10 * Self.second)
        _ = m.down(Self.leftCommand)
        _ = m.down(Self.delete)
        #expect(m.tick(nowNs: 10 * Self.second + Self.second / 2) == nil)
        m.value.noteMessage(nowNs: 11 * Self.second)
        #expect(m.tick(nowNs: 11 * Self.second + Self.second - 1) == nil)
        let fired = m.tick(nowNs: 12 * Self.second)
        #expect(fired?.released == 2)
        #expect(Self.keys(fired?.effects) == [.keyUp(Self.delete), .modifierUp(.command)])
        #expect(fired?.effects.first == .stopRepeat)
        #expect(!m.value.holdsAnything)
        #expect(m.tick(nowNs: 20 * Self.second) == nil)
    }

    @Test func vigiaSoltaModificadorPreso() {
        let m = Box(Self.machine())
        _ = m.down(Self.leftShift)
        _ = m.up(Self.leftShift)
        #expect(m.tick(nowNs: Self.second)?.released == 1)
        #expect(m.value.state(of: .shift) == .released)
    }

    @Test func quedaSoltaTudo() {
        let m = Box(Self.machine())
        _ = m.down(Self.leftCommand)
        _ = m.down(Self.rightCommand)
        _ = m.down(Self.leftShift)
        _ = m.up(Self.leftShift)
        _ = m.down(Self.a)
        let result = m.releaseAll()
        #expect(result.released == 3)
        #expect(Self.keys(result.effects) == [.keyUp(Self.a), .modifierUp(.command), .modifierUp(.shift)])
        #expect(m.value.modifierStates.values.allSatisfy { $0 == .released })
        #expect(m.releaseAll().effects.isEmpty)
    }

    @Test func contaAsTeclasDaSessao() {
        let m = Box(Self.machine())
        for _ in 0..<3 {
            _ = m.down(Self.a)
            _ = m.up(Self.a)
        }
        _ = m.down(Self.leftShift)
        _ = m.up(Self.leftShift)
        #expect(m.value.keyCount == 3)
    }

    @Test func cincoMensagensInvalidasSeguidasEncerram() {
        let m = Box(Self.machine())
        for _ in 1...4 { #expect(!m.noteInvalid()) }
        m.value.noteMessage(nowNs: 1)
        for _ in 1...4 { #expect(!m.noteInvalid()) }
        #expect(m.noteInvalid())
    }
}
