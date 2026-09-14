import Foundation
import JoystickCore

/// Tabela das sequências da tela de alvos para o bloco (b) (RF-25 b, RF-27).
enum RunsCommand {
    static var defaultDirectory: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/joystick-ai/target-runs").path
    }

    static let usage = """
    uso: poc-tools runs [--env mesa|sofa] [--dir <diretório>]

    Lê os resultados da tela de alvos (padrão: ~/Library/Application Support/joystick-ai/target-runs)
    e imprime uma linha por sequência completa, pronta para o bloco (b). Sequências incompletas
    ficam fora; tentativas acima de 60 s aparecem como discrepantes.
    """

    static func run(_ arguments: [String]) -> Int32 {
        var environment: TargetEnvironment?
        var directory = defaultDirectory
        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--env" where index + 1 < arguments.count:
                guard let env = TargetEnvironment(rawValue: arguments[index + 1]) else {
                    return ToolInput.fail("erro: --env deve ser mesa ou sofa, sem acento\n\n\(usage)", code: ToolInput.exitUsage)
                }
                environment = env
                index += 1
            case "--dir" where index + 1 < arguments.count:
                directory = (arguments[index + 1] as NSString).expandingTildeInPath
                index += 1
            default:
                return ToolInput.fail(usage, code: ToolInput.exitUsage)
            }
            index += 1
        }

        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return ToolInput.fail("erro: diretório inexistente: \(directory)", code: ToolInput.exitNoInput)
        }
        var runs: [TargetRun] = []
        var unreadable = 0
        let decoder = JSONDecoder()
        for name in names.sorted() where name.hasSuffix(".json") {
            let url = URL(fileURLWithPath: directory).appendingPathComponent(name)
            if let data = try? Data(contentsOf: url), let run = try? decoder.decode(TargetRun.self, from: data) {
                runs.append(run)
            } else {
                unreadable += 1
            }
        }
        if unreadable > 0 {
            ToolInput.warn("\(unreadable) arquivo(s) de resultado ilegível(is) ignorado(s)")
        }
        print(RunsReport.markdown(runs: runs, environment: environment), terminator: "")
        return 0
    }
}
