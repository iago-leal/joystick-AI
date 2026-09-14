import Foundation
import JoystickCore

/// Leitura comum dos arquivos analisados pelos subcomandos.
enum ToolInput {
    static let exitUsage: Int32 = 64
    static let exitNoInput: Int32 = 66

    static func fail(_ message: String, code: Int32) -> Int32 {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        return code
    }

    static func warn(_ message: String) {
        FileHandle.standardError.write(Data(("aviso: " + message + "\n").utf8))
    }

    /// Lê um log JSON Lines; `nil` com a mensagem já emitida quando o arquivo não existe ou não abre.
    static func readLog(_ arguments: [String], usage: String) -> (LogReadResult?, Int32) {
        guard arguments.count == 1 else { return (nil, fail(usage, code: exitUsage)) }
        let path = (arguments[0] as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: path) else {
            return (nil, fail("erro: arquivo inexistente: \(path)", code: exitNoInput))
        }
        guard let data = FileManager.default.contents(atPath: path) else {
            return (nil, fail("erro: não foi possível ler \(path)", code: exitNoInput))
        }
        let result = LogAnalysis.read(contents: String(decoding: data, as: UTF8.self))
        if result.malformedLines > 0 {
            warn("\(result.malformedLines) linha(s) malformada(s) ignorada(s) em \(path)")
        }
        return (result, 0)
    }
}
