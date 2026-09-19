import Foundation

/// Mensagens do canal do teclado remoto, em JSON com o campo `t` (`interfaces/remote-keyboard-protocol.md` §3, D-16).
public enum RemoteKeyboardMessage {
    /// Quadros acima disso são inválidos.
    public static let maxFrameBytes = 1024
    public static let version = 1

    /// Credencial do `hello`.
    public enum Credential: Equatable, Sendable {
        case code(String)
        case token([UInt8])
    }

    public enum Client: Equatable, Sendable {
        case hello(Credential)
        /// `ts` é o relógio da página, só para a sonda P-05; nunca vai ao log.
        case down(code: UInt16, ts: Double?)
        case up(code: UInt16, ts: Double?)
        case ping
        case release
        case bye

        /// Decodifica um quadro de texto; `nil` quando inválido (tamanho, JSON, `t` desconhecido ou campos errados).
        public static func decode(_ data: Data) -> Client? {
            guard data.count <= maxFrameBytes,
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = object["t"] as? String
            else { return nil }
            switch type {
            case "hello":
                guard integer(object["v"]) == version else { return nil }
                if let code = object["code"] as? String, object["token"] == nil {
                    guard code.utf8.count == 6, code.utf8.allSatisfy({ (0x30...0x39).contains($0) }) else { return nil }
                    return .hello(.code(code))
                }
                if let token = object["token"] as? String, object["code"] == nil, let bytes = hexBytes(token),
                   bytes.count == RemotePairing.tokenBytes {
                    return .hello(.token(bytes))
                }
                return nil
            case "down", "up":
                guard let value = integer(object["k"]), let code = UInt16(exactly: value) else { return nil }
                let ts = (object["ts"] as? NSNumber).map(\.doubleValue)
                return type == "down" ? .down(code: code, ts: ts) : .up(code: code, ts: ts)
            case "ping": return .ping
            case "release": return .release
            case "bye": return .bye
            default: return nil
            }
        }

        /// Inteiro JSON exato; recusa booleanos, frações e textos.
        private static func integer(_ value: Any?) -> Int? {
            guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
            let double = number.doubleValue
            guard double == double.rounded(), abs(double) < 1e9 else { return nil }
            return Int(double)
        }
    }

    public enum Server: Equatable, Sendable {
        case welcome(token: [UInt8])
        case reject(ServerRejection)
        case layout(geometry: RemoteKeyGeometry, labels: KeyLabelTable)
        case modifiers([KeyModifier: ModifierState])
        case status(injectionOn: Bool)
        /// Trava do Caps Lock do sistema (D-17 revista no PM-0).
        case capsLock(on: Bool)

        public func encoded() -> Data {
            var object: [String: Any]
            switch self {
            case .welcome(let token):
                object = ["t": "welcome", "token": hex(token), "v": version]
            case .reject(let reason):
                object = ["t": "reject", "reason": reason.rawValue]
            case .layout(let geometry, let labels):
                let keys: [[String: Any]] = geometry.codes.compactMap { code in
                    guard let entry = labels[code] else { return nil }
                    return [
                        "k": Int(code), "plain": entry.plain, "shift": entry.shift, "option": entry.option,
                        "shiftOption": entry.shiftOption,
                        "dead": KeyLabelState.allCases.filter(entry.dead.contains).map(\.rawValue),
                    ]
                }
                object = [
                    "t": "layout", "physical": geometry.physical.rawValue,
                    "rows": geometry.rows.map { $0.map { Int($0.code) } }, "keys": keys,
                ]
            case .modifiers(let states):
                object = ["t": "modifiers"]
                for modifier in KeyModifier.allCases {
                    object[modifier.rawValue] = (states[modifier] ?? .released).rawValue
                }
            case .status(let on):
                object = ["t": "status", "injection": on ? "on" : "no_permission"]
            case .capsLock(let on):
                object = ["t": "caps", "on": on]
            }
            return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        }
    }

    public enum ServerRejection: String, Equatable, Sendable {
        case badCode = "bad_code", badToken = "bad_token", busy, codeRotated = "code_rotated"
    }

    public static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    public static func hexBytes(_ text: String) -> [UInt8]? {
        let digits = Array(text.utf8)
        guard digits.count.isMultiple(of: 2) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(digits.count / 2)
        var index = 0
        while index < digits.count {
            guard let high = nibble(digits[index]), let low = nibble(digits[index + 1]) else { return nil }
            bytes.append(high << 4 | low)
            index += 2
        }
        return bytes
    }

    private static func nibble(_ c: UInt8) -> UInt8? {
        switch c {
        case 0x30...0x39: c - 0x30
        case 0x61...0x66: c - 0x61 + 10
        case 0x41...0x46: c - 0x41 + 10
        default: nil
        }
    }
}
