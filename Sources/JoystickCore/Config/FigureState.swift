import Foundation

/// Estado da figura do controle numa camada, como o editor o envia à página web (`004-figura-controle-web` D-12,
/// D-14, RN-02, RN-04). Valor codificável e testável sem interface; a página só desenha o que recebe.
///
/// As regras de derivação reproduzem as das fichas em SwiftUI da feature 003 (`chip` da figura antiga e
/// `EditorViewModel.hasIssue`): botão de apontamento é `fixed`; modificador é `modifier`; sem ação própria na camada
/// de modificador é `inherited`; o restante é `own`. O resumo vem de `ActionSummary.text(for:layer:in:)`.
public struct FigureState: Codable, Equatable, Sendable {
    /// `"base"` ou o `rawValue` do modificador cuja camada está selecionada.
    public var layer: String
    /// Sempre 18 itens, na ordem de `ButtonID.allCases`.
    public var buttons: [FigureButton]

    public init(layer: String, buttons: [FigureButton]) {
        self.layer = layer
        self.buttons = buttons
    }

    /// Deriva o estado da configuração do rascunho, da camada e do botão selecionados e dos problemas do rascunho.
    public init(config: ShortcutConfig, layer: ButtonID?, selected: ButtonID?, issues: [EditorIssue]) {
        self.layer = layer?.rawValue ?? "base"
        buttons = ButtonID.allCases.map { button in
            let kind: FigureButton.Kind = if ShortcutConfig.pointerButtons.contains(button) {
                .fixed
            } else if config.isModifier(button) {
                .modifier
            } else if config.resolvedAction(for: button, in: layer).inherited {
                .inherited
            } else {
                .own
            }
            return FigureButton(
                id: button.rawValue,
                label: button.displayName,
                summary: ActionSummary.text(for: button, layer: layer, in: config),
                kind: kind,
                problem: Self.hasIssue(button, in: layer, issues: issues),
                selected: button == selected)
        }
    }

    /// Problema do botão como gatilho na camada ou como modificador em qualquer camada (RN-02).
    public static func hasIssue(_ button: ButtonID, in layer: ButtonID?, issues: [EditorIssue]) -> Bool {
        issues.contains { issue in
            switch issue.target {
            case .trigger(let issueLayer, let issueButton): issueButton == button && issueLayer == layer
            case .modifier(let modifier): modifier == button
            default: false
            }
        }
    }
}

/// Um botão da figura: identificador do catálogo, rótulo, resumo da ação e os estados de RN-02.
public struct FigureButton: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Equatable, Sendable {
        case fixed, modifier, own, inherited
    }

    /// `ButtonID.rawValue`.
    public var id: String
    /// `ButtonID.displayName`.
    public var label: String
    /// `ActionSummary.text(for:layer:in:)`, inclusive o sufixo " (herdado)".
    public var summary: String
    public var kind: Kind
    public var problem: Bool
    public var selected: Bool

    public init(id: String, label: String, summary: String, kind: Kind, problem: Bool, selected: Bool) {
        self.id = id
        self.label = label
        self.summary = summary
        self.kind = kind
        self.problem = problem
        self.selected = selected
    }
}

/// Motivo pelo qual a figura não pôde ser exibida (D-10, D-15, RN-12). O `rawValue` é o campo `reason` do evento
/// `editor.figure_unavailable`; o tipo vive no núcleo para o catálogo do log continuar fechado.
public enum FigureFailureReason: String, Codable, Equatable, Sendable {
    /// `index.html` ausente do bundle; o `WKWebView` nem é criado.
    case resourceMissing = "resource_missing"
    /// A carga da página ou a chamada de `figure.render` falhou.
    case loadFailed = "load_failed"
    /// O processo WebContent caiu duas vezes em 60 s.
    case processTerminated = "process_terminated"
}
