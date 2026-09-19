import Foundation

/// Modo de depuração das sondas P-01 e P-02 (`009-sugestao-de-palavras` `investigation.md` §5): com a variável de
/// ambiente `JOYSTICK_SUGGEST_PROBE` apontando um arquivo, grava por tecla do teclado remoto o valor da entrada segura
/// e o texto traduzido, fora do log. Sem a variável, não existe.
///
/// Em entrada segura o texto não é gravado, para que a sonda de senha não leve a senha a disco. O arquivo é apagado
/// pelo usuário ao fim da sonda. Só na fila `input`.
final class SuggestionProbe {
    static let environmentKey = "JOYSTICK_SUGGEST_PROBE"

    private let handle: FileHandle

    init?(environment: [String: String] = ProcessInfo.processInfo.environment) {
        guard let path = environment[Self.environmentKey], !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600])
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return nil }
        _ = try? handle.seekToEnd()
        self.handle = handle
    }

    deinit {
        try? handle.close()
    }

    func record(code: UInt16, secure: Bool, text: String?) {
        var object: [String: Any] = ["k": Int(code), "secure": secure]
        if !secure, let text {
            object["text"] = text
            object["scalars"] = text.unicodeScalars.map { String(format: "U+%04X", $0.value) }
        }
        guard var line = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return }
        line.append(0x0A)
        try? handle.write(contentsOf: line)
    }
}
