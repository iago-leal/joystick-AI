import Foundation
import Testing
@testable import JoystickCore

@Suite struct SupportTests {
    @Test func relogioMonotonico() {
        var previous = MonotonicClock.nowNs()
        for _ in 0..<1000 {
            let now = MonotonicClock.nowNs()
            #expect(now >= previous)
            previous = now
        }
    }

    @Test func serializacaoDeterministica() {
        let value: JSONValue = .object(["b": 1, "a": "x\"y\n", "c": .array([true, .null, 0.5])])
        #expect(value.jsonString() == #"{"a":"x\"y\n","b":1,"c":[true,null,0.5]}"#)
    }

    @Test func decimalInteiroMantemPonto() {
        #expect(JSONValue.double(2).jsonString() == "2.0")
    }

    @Test func idaEVoltaPeloCodable() throws {
        let original: JSONValue = .object(["n": 3, "d": 1.25, "s": "ok", "u": .uint(UInt64.max), "z": .null, "f": false])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == original)
    }

    @Test func serializacaoEhJSONValido() throws {
        let value: JSONValue = .object(["texto": "controle\tç", "lista": .array([1, 2])])
        let data = Data(value.jsonString().utf8)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == value)
    }
}
