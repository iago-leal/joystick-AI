import JoystickCore

/// Textos da interface do editor para camadas, teclas modificadoras e regras de validação.
/// O rótulo de cada botão (`ButtonID.displayName`) vive no núcleo desde a `004-figura-controle-web` (D-13).
enum EditorLabels {
    /// Texto da carga do controle ativo (`011-bateria-e-cursor-no-menu` RN-03, RN-04, RN-06).
    ///
    /// As duas ausências são frases, e não números: sem controle não se mostra zero, e carga indisponível não se
    /// estima. A marca de carregamento acompanha a porcentagem quando o sistema informa o estado, e some quando
    /// não informa, sem nunca impedir a exibição do número.
    static func charge(_ display: ChargeDisplay) -> String {
        switch display {
        case .noController: "Nenhum controle conectado"
        case .unavailable: "Carga indisponível neste controle"
        case .known(let percent, let charging, _): charging ? "\(percent)%, carregando" : "\(percent)%"
        }
    }

    /// Símbolo que acompanha a carga. O destaque da faixa baixa é por cor **e** por símbolo, nunca só por cor:
    /// a leitura é a 3 m, e o painel da paleta tem fundo escuro próprio, de modo que depender de matiz sozinha
    /// seria frágil nessa distância (D-08).
    static func chargeSymbol(_ display: ChargeDisplay) -> String? {
        switch display {
        case .noController, .unavailable: nil
        case .known(_, let charging, let low):
            if low { "exclamationmark.triangle.fill" } else if charging { "bolt.fill" } else { "battery.100" }
        }
    }

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
