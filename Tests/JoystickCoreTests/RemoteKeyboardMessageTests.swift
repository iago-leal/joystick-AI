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

    @Test func hexadecimalIdaEVolta() {
        let bytes: [UInt8] = [0, 15, 16, 255, 128]
        #expect(RemoteKeyboardMessage.hexBytes(RemoteKeyboardMessage.hex(bytes)) == bytes)
        #expect(RemoteKeyboardMessage.hexBytes("ABcd") == [0xAB, 0xCD])
        #expect(RemoteKeyboardMessage.hexBytes("abc") == nil)
        #expect(RemoteKeyboardMessage.hexBytes("0g") == nil)
    }
}
