import Foundation

// Despacho dos subcomandos de análise (RF-25).

let usage = """
uso: poc-tools <subcomando> [argumentos]

subcomandos:
  buttons <log>                           cobertura dos 18 botões (bloco a)
  runs [--env mesa|sofa] [--dir <dir>]    tabela das sequências da tela de alvos (bloco b)
  latency <log>                           p50, p95 e máximo das latências (bloco d)
  cycles <log>                            ciclos de conexão e reinícios (robustez)

Use `poc-tools help <subcomando>` para os detalhes de cada um.
Códigos de saída: 0 sucesso; 64 uso incorreto; 66 arquivo ou diretório inexistente.
"""

let subcommandUsage = [
    "buttons": ButtonsCommand.usage,
    "runs": RunsCommand.usage,
    "latency": LatencyCommand.usage,
    "cycles": CyclesCommand.usage,
]

let arguments = Array(CommandLine.arguments.dropFirst())
guard let subcommand = arguments.first else {
    FileHandle.standardError.write(Data((usage + "\n").utf8))
    exit(ToolInput.exitUsage)
}

let rest = Array(arguments.dropFirst())
if rest.contains("-h") || rest.contains("--help"), let help = subcommandUsage[subcommand] {
    print(help)
    exit(0)
}

let status: Int32
switch subcommand {
case "buttons": status = ButtonsCommand.run(rest)
case "runs": status = RunsCommand.run(rest)
case "latency": status = LatencyCommand.run(rest)
case "cycles": status = CyclesCommand.run(rest)
case "-h", "--help", "help":
    if let topic = rest.first {
        if let help = subcommandUsage[topic] {
            print(help)
            status = 0
        } else {
            status = ToolInput.fail("subcomando desconhecido: \(topic)\n\n\(usage)", code: ToolInput.exitUsage)
        }
    } else {
        print(usage)
        status = 0
    }
default:
    status = ToolInput.fail("subcomando desconhecido: \(subcommand)\n\n\(usage)", code: ToolInput.exitUsage)
}
exit(status)
