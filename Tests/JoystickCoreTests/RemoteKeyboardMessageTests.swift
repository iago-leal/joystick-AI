import Foundation
import Testing
@testable import JoystickCore

/// Codificação do canal (`008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md` §3, D-16).
@Suite struct RemoteKeyboardMessageTests {
    typealias Client = RemoteKeyboardMessage.Client
    typealias Server = RemoteKeyboardMessage.Server

    static func decode(_ text: String) -> Client? { Client.decode(Data(text.utf8)) }

    static func object(_ message: Server) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: message.encoded()) as? [String: Any])
    }

    @Test func decodificaAsMensagensDoCliente() {
        #expect(Self.decode(#"{"t":"hello","code":"042917","v":1}"#) == .hello(.code("042917")))
        let token = String(repeating: "0a", count: 16)
        #expect(Self.decode(#"{"t":"hello","token":"\#(token)","v":1}"#) == .hello(.token([UInt8](repeating: 10, count: 16))))
        #expect(Self.decode(#"{"t":"down","k":0,"ts":1234.5}"#) == .down(code: 0, ts: 1234.5))
        #expect(Self.decode(#"{"t":"up","k":55}"#) == .up(code: 55, ts: nil))
        #expect(Self.decode(#"{"t":"ping"}"#) == .ping)
        #expect(Self.decode(#"{"t":"release"}"#) == .release)
        #expect(Self.decode(#"{"t":"bye"}"#) == .bye)
    }

    @Test(arguments: [
        #"{"t":"shout"}"#, #"{"k":0}"#, "não é json", "[1,2]", #"{"t":"down"}"#, #"{"t":"down","k":"a"}"#,
        #"{"t":"down","k":1.5}"#, #"{"t":"down","k":-1}"#, #"{"t":"down","k":70000}"#, #"{"t":"down","k":true}"#,
        #"{"t":"hello","code":"12345","v":1}"#, #"{"t":"hello","code":"12345a","v":1}"#, #"{"t":"hello","code":"123456"}"#,
        #"{"t":"hello","code":"123456","v":2}"#, #"{"t":"hello","token":"zz","v":1}"#, #"{"t":"hello","v":1}"#,
        #"{"t":"hello","code":"123456","token":"00000000000000000000000000000000","v":1}"#,
    ])
    func recusaMensagensInvalidas(_ text: String) {
        #expect(Self.decode(text) == nil)
    }

    @Test func recusaQuadroAcimaDe1KiB() {
        let padding = String(repeating: " ", count: 1024)
        #expect(Self.decode(#"{"t":"ping"}"# + padding) == nil)
        #expect(Self.decode(#"{"t":"ping"}"#) != nil)
    }

    @Test func codificaWelcomeERejeicao() throws {
        let welcome = try Self.object(.welcome(token: [0, 1, 0xAB, 0xFF]))
        #expect(welcome["t"] as? String == "welcome")
        #expect(welcome["token"] as? String == "0001abff")
        #expect(welcome["v"] as? Int == 1)
        for reason in [RemoteKeyboardMessage.ServerRejection.badCode, .badToken, .busy, .codeRotated] {
            let reject = try Self.object(.reject(reason))
            #expect(reject as NSDictionary == ["t": "reject", "reason": reason.rawValue] as NSDictionary)
        }
    }

    @Test func codificaLayoutComLinhasERotulos() throws {
        let geometry = RemoteKeyGeometry.standard(.iso)
        let labels = KeyLabelTable(labels: [
            0: KeyLabels(plain: "a", shift: "A", option: "å", shiftOption: "Å"),
            39: KeyLabels(plain: "~", shift: "^", option: "", shiftOption: "", dead: [.plain, .shift]),
        ])
        let layout = try Self.object(.layout(geometry: geometry, labels: labels))
        #expect(layout["t"] as? String == "layout")
        #expect(layout["physical"] as? String == "iso")
        let rows = try #require(layout["rows"] as? [[Int]])
        #expect(rows == geometry.rows.map { $0.map { Int($0.code) } })
        let keys = try #require(layout["keys"] as? [[String: Any]])
        #expect(keys.count == 2)
        let tilde = try #require(keys.first { $0["k"] as? Int == 39 })
        #expect(tilde["plain"] as? String == "~")
        #expect(tilde["dead"] as? [String] == ["plain", "shift"])
        #expect(Set(tilde.keys) == ["k", "plain", "shift", "option", "shiftOption", "dead"])
    }

    @Test func codificaModificadoresEStatus() throws {
        let modifiers = try Self.object(.modifiers([.command: .held, .shift: .latched]))
        #expect(modifiers as NSDictionary == [
            "t": "modifiers", "command": "held", "shift": "latched", "option": "released", "control": "released",
        ] as NSDictionary)
        #expect(try Self.object(.status(injectionOn: true)) as NSDictionary == ["t": "status", "injection": "on"] as NSDictionary)
        #expect(try Self.object(.status(injectionOn: false)) as NSDictionary == ["t": "status", "injection": "no_permission"] as NSDictionary)
        #expect(try Self.object(.capsLock(on: true)) as NSDictionary == ["t": "caps", "on": true] as NSDictionary)
        #expect(try Self.object(.capsLock(on: false)) as NSDictionary == ["t": "caps", "on": false] as NSDictionary)
    }

    /// Mensagens das sugestões (`009-sugestao-de-palavras/interfaces/remote-keyboard-protocol.md` §2 e §3).
    @Test func decodificaPrefsEPick() {
        #expect(Self.decode(#"{"t":"prefs","lang":"pt","visible":true}"#) == .prefs(language: .pt, visible: true))
        #expect(Self.decode(#"{"t":"prefs","lang":"en","visible":false}"#) == .prefs(language: .en, visible: false))
        #expect(Self.decode(#"{"t":"pick","rev":42,"i":0}"#) == .pick(revision: 42, index: 0))
        #expect(Self.decode(#"{"t":"pick","rev":0,"i":2}"#) == .pick(revision: 0, index: 2))
    }

    @Test(arguments: [
        #"{"t":"prefs","lang":"es","visible":true}"#, #"{"t":"prefs","lang":"PT","visible":true}"#,
        #"{"t":"prefs","visible":true}"#, #"{"t":"prefs","lang":"pt"}"#, #"{"t":"prefs","lang":"pt","visible":1}"#,
        #"{"t":"prefs","lang":"pt","visible":"true"}"#, #"{"t":"prefs","lang":1,"visible":true}"#,
        #"{"t":"pick","rev":1,"i":3}"#, #"{"t":"pick","rev":1,"i":-1}"#, #"{"t":"pick","rev":1,"i":1.5}"#,
        #"{"t":"pick","rev":1}"#, #"{"t":"pick","i":0}"#, #"{"t":"pick","rev":-1,"i":0}"#, #"{"t":"pick","rev":"1","i":0}"#,
        #"{"t":"pick","rev":1,"i":true}"#,
    ])
    func recusaPrefsEPickInvalidos(_ text: String) {
        #expect(Self.decode(text) == nil)
    }

    @Test func codificaSuggest() throws {
        let complete = try Self.object(.suggest(revision: 7, mode: .complete, words: ["implementar", "implica"]))
        #expect(complete as NSDictionary == [
            "t": "suggest", "rev": 7, "mode": "complete", "words": ["implementar", "implica"],
        ] as NSDictionary)
        let empty = try Self.object(.suggest(revision: 8, mode: .next, words: []))
        #expect(empty as NSDictionary == ["t": "suggest", "rev": 8, "mode": "next", "words": [String]()] as NSDictionary)
    }

    @Test func suggestLimitaATresPalavrasDeAte48Caracteres() throws {
        let long = String(repeating: "a", count: 49)
        let edge = String(repeating: "b", count: 48)
        let object = try Self.object(.suggest(revision: 1, mode: .complete, words: [long, "um", "", edge, "dois", "tres"]))
        #expect(object["words"] as? [String] == ["um", edge, "dois"])
    }

    // MARK: - Controle virtual (`010-joystick-virtual-iphone` §2 a §4)

    @Test func decodificaAsMensagensDoControle() {
        #expect(Self.decode(#"{"t":"btn","b":"cross","d":1}"#) == .button(.cross, down: true))
        #expect(Self.decode(#"{"t":"btn","b":"touchpadClick","d":0}"#) == .button(.touchpadClick, down: false))
        #expect(Self.decode(#"{"t":"btn","b":"dpadUp","d":1}"#) == .button(.dpadUp, down: true))
        #expect(Self.decode(#"{"t":"stick","s":"l","x":0.5,"y":-0.25}"#) == .stick(.left, StickSample(x: 0.5, y: -0.25)))
        #expect(Self.decode(#"{"t":"stick","s":"r","x":0,"y":1}"#) == .stick(.right, StickSample(x: 0, y: 1)))
        #expect(Self.decode(#"{"t":"pad","f":0,"p":"b","x":0.1,"y":0.2}"#)
            == .pad(PadSample(finger: 0, phase: .began, x: 0.1, y: 0.2)))
        #expect(Self.decode(#"{"t":"pad","f":3,"p":"m","x":-1,"y":0}"#)
            == .pad(PadSample(finger: 3, phase: .moved, x: -1, y: 0)))
        #expect(Self.decode(#"{"t":"pad","f":1,"p":"e","x":0,"y":0}"#)
            == .pad(PadSample(finger: 1, phase: .ended, x: 0, y: 0)))
        for mode in CenterMode.allCases {
            #expect(Self.decode(#"{"t":"mode","m":"\#(mode.rawValue)"}"#) == .mode(mode))
        }
    }

    @Test func todoBotaoDoProtocoloEhAceito() {
        for button in VirtualButton.allCases {
            #expect(Self.decode(#"{"t":"btn","b":"\#(button.rawValue)","d":1}"#) == .button(button, down: true))
        }
    }

    @Test func coordenadaForaDoIntervaloEhLimitadaSemRecusa() {
        #expect(Self.decode(#"{"t":"stick","s":"l","x":2.5,"y":-9}"#) == .stick(.left, StickSample(x: 1, y: -1)))
        #expect(Self.decode(#"{"t":"pad","f":0,"p":"m","x":-3,"y":8}"#)
            == .pad(PadSample(finger: 0, phase: .moved, x: -1, y: 1)))
    }

    @Test(arguments: [
        #"{"t":"btn","b":"share","d":1}"#, #"{"t":"btn","b":"Cross","d":1}"#, #"{"t":"btn","b":"","d":1}"#,
        #"{"t":"btn","d":1}"#, #"{"t":"btn","b":"cross"}"#, #"{"t":"btn","b":"cross","d":2}"#,
        #"{"t":"btn","b":"cross","d":-1}"#, #"{"t":"btn","b":"cross","d":true}"#, #"{"t":"btn","b":"cross","d":"1"}"#,
        #"{"t":"btn","b":1,"d":1}"#,
        #"{"t":"stick","s":"m","x":0,"y":0}"#, #"{"t":"stick","s":"L","x":0,"y":0}"#, #"{"t":"stick","x":0,"y":0}"#,
        #"{"t":"stick","s":"l","y":0}"#, #"{"t":"stick","s":"l","x":0}"#, #"{"t":"stick","s":"l","x":"0","y":0}"#,
        #"{"t":"stick","s":"l","x":0,"y":true}"#,
        #"{"t":"pad","f":0,"p":"x","x":0,"y":0}"#, #"{"t":"pad","f":4,"p":"b","x":0,"y":0}"#,
        #"{"t":"pad","f":-1,"p":"b","x":0,"y":0}"#, #"{"t":"pad","f":0.5,"p":"b","x":0,"y":0}"#,
        #"{"t":"pad","p":"b","x":0,"y":0}"#, #"{"t":"pad","f":0,"x":0,"y":0}"#, #"{"t":"pad","f":0,"p":"b","y":0}"#,
        #"{"t":"pad","f":0,"p":"b","x":null,"y":0}"#, #"{"t":"pad","f":true,"p":"b","x":0,"y":0}"#,
        #"{"t":"mode","m":"keyboard"}"#, #"{"t":"mode","m":"Pointer"}"#, #"{"t":"mode"}"#, #"{"t":"mode","m":1}"#,
    ])
    func recusaMensagensDoControleInvalidas(_ text: String) {
        #expect(Self.decode(text) == nil)
    }

    @Test func codificaOModoDoServidor() throws {
        for mode in CenterMode.allCases {
            let object = try Self.object(.mode(mode))
            #expect(object as NSDictionary == ["t": "mode", "m": mode.rawValue] as NSDictionary)
        }
    }

    @Test func hexadecimalIdaEVolta() {
        let bytes: [UInt8] = [0, 15, 16, 255, 128]
        #expect(RemoteKeyboardMessage.hexBytes(RemoteKeyboardMessage.hex(bytes)) == bytes)
        #expect(RemoteKeyboardMessage.hexBytes("ABcd") == [0xAB, 0xCD])
        #expect(RemoteKeyboardMessage.hexBytes("abc") == nil)
        #expect(RemoteKeyboardMessage.hexBytes("0g") == nil)
    }
}
