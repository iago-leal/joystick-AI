import JoystickCore

/// Textos da interface do editor para botões, camadas, teclas modificadoras e regras de validação.
extension ButtonID {
    var displayName: String {
        switch self {
        case .cross: "✕"
        case .circle: "○"
        case .square: "□"
        case .triangle: "△"
        case .l1: "L1"
        case .r1: "R1"
        case .l2: "L2"
        case .r2: "R2"
        case .l3: "L3"
        case .r3: "R3"
        case .options: "Options"
        case .create: "Create"
        case .ps: "PS"
        case .touchpadClick: "Touchpad"
        case .dpadUp: "↑"
        case .dpadDown: "↓"
        case .dpadLeft: "←"
        case .dpadRight: "→"
        }
    }
}

enum EditorLabels {
    static func layerName(_ layer: ButtonID?) -> String {
        layer.map { $0.displayName } ?? "Base"
    }

    static func modifierName(_ modifier: KeyModifier) -> String {
        switch modifier {
        case .command: "Command ⌘"
        case .option: "Option ⌥"
        case .control: "Control ⌃"
        case .shift: "Shift ⇧"
        }
    }

    static func groupName(_ group: KeyGroup) -> String {
        switch group {
        case .letters: "Letras"
        case .digits: "Dígitos"
        case .punctuation: "Pontuação"
        case .editing: "Edição"
        case .navigation: "Navegação"
        case .function: "Funções"
        }
    }

    /// Motivo de um problema, sem o valor recusado (RN-14).
    static func message(_ rule: ShortcutIssue.Rule) -> String {
        switch rule {
        case .unsupportedVersion: "versão não suportada"
        case .pointerButtonNotAllowed: "R1, R2 e o clique do touchpad são cliques fixos"
        case .layerWithoutModifier: "camada de um botão que não é modificador"
        case .modifierHasAction: "botão modificador não pode ter ação; escolha Herdar ou remova a ação"
        case .unknownKey: "tecla desconhecida"
        case .unknownModifier: "tecla modificadora desconhecida"
        case .unknownSystemShortcut: "atalho de sistema desconhecido"
        case .unknownActionType: "tipo de ação desconhecido"
        case .textEmpty: "texto vazio"
        case .textTooLong: "texto acima de \(ShortcutsDocument.maxTextLength) caracteres"
        case .multiline: "texto com quebra de linha"
        case .labelTooLong: "rótulo acima de \(ShortcutsDocument.maxLabelLength) caracteres"
        case .paletteEmpty: "a paleta precisa de ao menos um item"
        case .paletteTooLong: "a paleta aceita no máximo \(ShortcutsDocument.paletteItemLimit.upperBound) itens"
        case .wrongType: "valor com tipo errado"
        case .syntax: "erro de sintaxe"
        case .unreadable: "arquivo ilegível ou acima de 1 MiB"
        }
    }

    /// "Configuração inválida: linha N (motivo)", como na faixa e no menu (RF-04, RF-20).
    static func invalidFile(_ issue: ShortcutIssue) -> String {
        let line = issue.line.map { " na linha \($0)" } ?? ""
        return "O arquivo de configuração tem erro\(line): \(message(issue.rule)). A configuração vigente foi mantida."
    }
}
