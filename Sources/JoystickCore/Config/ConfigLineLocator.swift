import Foundation

/// Linha de um valor no texto do arquivo, para citar erros de conteúdo (`003-editor-atalhos` D-06, RF-04, RF-20).
///
/// Varredura léxica que acompanha objetos, listas e cadeias com escape; usada só quando a validação falha, pois o
/// `JSONDecoder` não informa posições. Erro de sintaxe segue com a linha de `ConfigLoader.describe`.
public enum ConfigLineLocator {
    enum Component: Equatable {
        case key(String)
        case index(Int)
    }

    /// Linha (a partir de 1) em que começa o valor de `path`, como `shortcuts.layers.l2.dpadLeft` ou
    /// `palette.items[3].text`; `nil` se o caminho não existir ou o texto estiver malformado antes dele.
    public static func line(of path: String, in data: Data) -> Int? {
        guard let components = components(of: path) else { return nil }
        var scanner = Scanner(bytes: Array(data))
        return scanner.locate(components[...])
    }

    /// Linha do trecho existente mais próximo de `path`: o próprio valor ou, se ausente, o ancestral mais longo.
    public static func nearestLine(of path: String, in data: Data) -> Int? {
        guard var components = components(of: path) else { return nil }
        while !components.isEmpty {
            var scanner = Scanner(bytes: Array(data))
            if let line = scanner.locate(components[...]) { return line }
            components.removeLast()
        }
        return nil
    }

    static func components(of path: String) -> [Component]? {
        var result: [Component] = []
        for segment in path.split(separator: ".", omittingEmptySubsequences: false) {
            var rest = Substring(segment)
            let name = rest.prefix { $0 != "[" }
            guard !name.isEmpty else { return nil }
            result.append(.key(String(name)))
            rest = rest.dropFirst(name.count)
            while !rest.isEmpty {
                guard rest.first == "[", let close = rest.firstIndex(of: "]"), let index = Int(rest[rest.index(after: rest.startIndex)..<close]) else {
                    return nil
                }
                result.append(.index(index))
                rest = rest[rest.index(after: close)...]
            }
        }
        return result
    }

    struct Scanner {
        let bytes: [UInt8]
        var position = 0
        var line = 1

        init(bytes: [UInt8]) {
            self.bytes = bytes
        }

        mutating func locate(_ path: ArraySlice<Component>) -> Int? {
            skipWhitespace()
            guard position < bytes.count else { return nil }
            guard let next = path.first else { return line }
            switch (bytes[position], next) {
            case (UInt8(ascii: "{"), .key(let wanted)):
                position += 1
                while true {
                    skipWhitespace()
                    guard position < bytes.count else { return nil }
                    if bytes[position] == UInt8(ascii: "}") { return nil }
                    guard let key = readString() else { return nil }
                    skipWhitespace()
                    guard position < bytes.count, bytes[position] == UInt8(ascii: ":") else { return nil }
                    position += 1
                    if key == wanted { return locate(path.dropFirst()) }
                    guard skipValue(), separatorFollows() else { return nil }
                }
            case (UInt8(ascii: "["), .index(let wanted)):
                position += 1
                var index = 0
                while true {
                    skipWhitespace()
                    guard position < bytes.count, bytes[position] != UInt8(ascii: "]") else { return nil }
                    if index == wanted { return locate(path.dropFirst()) }
                    guard skipValue(), separatorFollows() else { return nil }
                    index += 1
                }
            default:
                return nil
            }
        }

        /// Consome a vírgula entre membros; falso no fim do objeto ou da lista, ou em texto malformado.
        private mutating func separatorFollows() -> Bool {
            skipWhitespace()
            guard position < bytes.count, bytes[position] == UInt8(ascii: ",") else { return false }
            position += 1
            return true
        }

        private mutating func skipValue() -> Bool {
            skipWhitespace()
            guard position < bytes.count else { return false }
            switch bytes[position] {
            case UInt8(ascii: "\""):
                return readString() != nil
            case UInt8(ascii: "{"), UInt8(ascii: "["):
                var depth = 0
                while position < bytes.count {
                    let byte = bytes[position]
                    switch byte {
                    case UInt8(ascii: "\""):
                        guard readString() != nil else { return false }
                        continue
                    case UInt8(ascii: "{"), UInt8(ascii: "["):
                        depth += 1
                    case UInt8(ascii: "}"), UInt8(ascii: "]"):
                        depth -= 1
                        if depth == 0 {
                            position += 1
                            return true
                        }
                    default:
                        countNewline()
                    }
                    position += 1
                }
                return false
            default:
                // Número, `true`, `false` ou `null`: até o próximo delimitador.
                let start = position
                while position < bytes.count, ![UInt8(ascii: ","), UInt8(ascii: "}"), UInt8(ascii: "]")].contains(bytes[position]),
                      !isWhitespace(bytes[position]) {
                    position += 1
                }
                return position > start
            }
        }

        /// Lê uma cadeia a partir das aspas de abertura, respeitando escapes; devolve o conteúdo bruto.
        private mutating func readString() -> String? {
            guard position < bytes.count, bytes[position] == UInt8(ascii: "\"") else { return nil }
            position += 1
            let start = position
            while position < bytes.count {
                switch bytes[position] {
                case UInt8(ascii: "\\"):
                    position += 2
                case UInt8(ascii: "\""):
                    let raw = String(decoding: bytes[start..<position], as: UTF8.self)
                    position += 1
                    return raw.contains("\\") ? unescape(raw) : raw
                case 0x0A:
                    return nil
                default:
                    position += 1
                }
            }
            return nil
        }

        private func unescape(_ raw: String) -> String? {
            (try? JSONDecoder().decode(String.self, from: Data("\"\(raw)\"".utf8)))
        }

        private mutating func skipWhitespace() {
            while position < bytes.count, isWhitespace(bytes[position]) {
                countNewline()
                position += 1
            }
        }

        /// LF conta uma linha; CR só quando não é seguido de LF, para que CRLF conte uma vez.
        private mutating func countNewline() {
            let byte = bytes[position]
            if byte == 0x0A || (byte == 0x0D && (position + 1 >= bytes.count || bytes[position + 1] != 0x0A)) {
                line += 1
            }
        }

        private func isWhitespace(_ byte: UInt8) -> Bool {
            byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D
        }
    }
}
