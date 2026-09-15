import Foundation

/// Item da paleta: texto de uma linha digitado no aplicativo em foco, com Enter opcional (`002-paleta-comandos` RN-05)
/// e rótulo opcional exibido no lugar do texto (`003-editor-atalhos` RN-12).
public struct PaletteItem: Equatable, Sendable {
    public let text: String
    public let pressEnter: Bool
    /// Vazio exibe o próprio texto.
    public let label: String

    public init(_ text: String, pressEnter: Bool, label: String = "") {
        self.text = text
        self.pressEnter = pressEnter
        self.label = label
    }

    public var displayText: String { label.isEmpty ? text : label }
}

public enum PaletteDirection: Sendable {
    case up, down
}

/// Motivo de fechamento sem confirmação (`002-paleta-comandos/interfaces/diagnostic-log.md` §2).
public enum PaletteCloseReason: String, Sendable {
    case circle, ps, disconnected, idle
    case injectionSuspended = "injection_suspended"
    /// Configuração nova aplicada com a paleta aberta (`003-editor-atalhos` D-12).
    case configChanged = "config_changed"
    /// Modo de identificação do editor ligado com a paleta aberta (`003-editor-atalhos` D-24).
    case identify
}

/// Paleta padrão, usada sem arquivo ou sem a seção `palette` (`003-editor-atalhos` RN-11, D-04): a lista da
/// `002-paleta-comandos` (RF-05). Nenhum item envia Enter: o texto fica na linha para receber argumentos, e o envio é
/// um ✕ seguinte (emenda E001). Itens terminados em espaço esperam descrição.
public enum PaletteDefaults {
    public static let items: [PaletteItem] = [
        PaletteItem("CONTINUAR", pressEnter: false),
        PaletteItem("/reversa-forward", pressEnter: false),
        PaletteItem("/reversa-requirements ", pressEnter: false),
        PaletteItem("/reversa-clarify", pressEnter: false),
        PaletteItem("/reversa-plan", pressEnter: false),
        PaletteItem("/reversa-to-do", pressEnter: false),
        PaletteItem("/reversa-coding", pressEnter: false),
        PaletteItem("/reversa-add ", pressEnter: false),
        PaletteItem("/reversa-audit", pressEnter: false),
        PaletteItem("/reversa-quality", pressEnter: false),
        PaletteItem("/reversa-sync", pressEnter: false),
        PaletteItem("/reversa-resume", pressEnter: false),
        PaletteItem("/reversa-debugger ", pressEnter: false),
        PaletteItem("/reversa", pressEnter: false),
        PaletteItem("/clear", pressEnter: false),
        PaletteItem("/compact", pressEnter: false),
        PaletteItem("/resume", pressEnter: false),
    ]
}

/// Estado da paleta visto pela interface; cópia imutável enviada à main thread (`002-paleta-comandos` D-11).
public struct PaletteSnapshot: Equatable, Sendable {
    public let isOpen: Bool
    /// Índice a partir de 0; só tem sentido com a paleta aberta.
    public let selection: Int

    public init(isOpen: Bool, selection: Int) {
        self.isOpen = isOpen
        self.selection = selection
    }
}

public enum PaletteEffect: Equatable, Sendable {
    case render(PaletteSnapshot)
    case startRepeat(PaletteDirection)
    case stopRepeat
    /// `index` conta a partir de 1, como no log.
    case confirm(index: Int, item: PaletteItem)
    case closed(PaletteCloseReason)
    /// Confirmação da entrada fixa "Editar atalhos": abre o editor, sem digitar (`003-editor-atalhos` RF-07).
    case openEditor
}

/// Paleta de comandos operada pelo controle (`002-paleta-comandos` D-01, `data-delta.md` §4).
///
/// Com a paleta fechada, nenhuma entrada exceto `open()` produz efeito. Depois dos itens configurados vem a entrada
/// fixa "Editar atalhos", no índice `items.count`, fora da contagem de 1 a 50 (`003-editor-atalhos` D-13, RN-12).
public struct PaletteMachine: Sendable {
    public static let editorEntryTitle = "Editar atalhos"

    public let items: [PaletteItem]
    public private(set) var isOpen = false
    public private(set) var selection = 0
    /// Último item confirmado, mantido enquanto o app estiver em execução (RF-08).
    public private(set) var lastConfirmed: Int?
    public private(set) var repeating: PaletteDirection?

    public init(items: [PaletteItem] = PaletteDefaults.items) {
        precondition(!items.isEmpty, "a paleta precisa de ao menos um item")
        self.items = items
    }

    public var snapshot: PaletteSnapshot { PaletteSnapshot(isOpen: isOpen, selection: selection) }

    /// Posição da entrada fixa "Editar atalhos".
    public var editorEntryIndex: Int { items.count }

    /// Itens configurados mais a entrada fixa.
    public var entryCount: Int { items.count + 1 }

    public mutating func open() -> [PaletteEffect] {
        guard !isOpen else { return [] }
        isOpen = true
        selection = lastConfirmed ?? 0
        return [.render(snapshot)]
    }

    public mutating func press(_ button: ButtonID) -> [PaletteEffect] {
        guard isOpen else { return [] }
        switch button {
        case .dpadUp, .dpadDown:
            let direction: PaletteDirection = button == .dpadUp ? .up : .down
            step(direction)
            repeating = direction
            return [.render(snapshot), .startRepeat(direction)]
        case .cross:
            let index = selection
            // A entrada fixa não passa a ser a última confirmada: a próxima abertura volta ao último comando.
            guard index != editorEntryIndex else { return finish() + [.openEditor] }
            lastConfirmed = index
            return finish() + [.confirm(index: index + 1, item: items[index])]
        case .circle:
            return finish() + [.closed(.circle)]
        case .ps:
            return finish() + [.closed(.ps)]
        default:
            return []
        }
    }

    public mutating func release(_ button: ButtonID) -> [PaletteEffect] {
        guard isOpen, let repeating else { return [] }
        let direction: PaletteDirection? = switch button {
        case .dpadUp: .up
        case .dpadDown: .down
        default: nil
        }
        guard direction == repeating else { return [] }
        self.repeating = nil
        return [.stopRepeat]
    }

    public mutating func repeatTick() -> [PaletteEffect] {
        guard isOpen, let repeating else { return [] }
        step(repeating)
        return [.render(snapshot)]
    }

    /// Fechamento sem confirmação vindo de fora da paleta: desconexão, perda de permissão ou inatividade.
    public mutating func close(_ reason: PaletteCloseReason) -> [PaletteEffect] {
        guard isOpen else { return [] }
        return finish() + [.closed(reason)]
    }

    private mutating func step(_ direction: PaletteDirection) {
        let offset = direction == .up ? -1 : 1
        selection = (selection + offset + entryCount) % entryCount
    }

    private mutating func finish() -> [PaletteEffect] {
        var effects: [PaletteEffect] = []
        if repeating != nil {
            repeating = nil
            effects.append(.stopRepeat)
        }
        isOpen = false
        effects.append(.render(snapshot))
        return effects
    }
}
