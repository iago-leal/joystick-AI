import Foundation

/// União dos botões mantidos pelas duas origens de entrada (`010-joystick-virtual-iphone` D-04).
///
/// O controle virtual não entra no `ActiveControllerRegistry`, porque `press(_:from:)` só aceita o controle ativo e
/// promover o iPhone a ativo bloquearia o controle físico (RN-01). Em vez disso, o conjunto do iPhone vive à parte e é
/// somado aqui, de modo que a precisão de L1, o clique com dois detentores, a decisão de camada e a tela de alvos
/// funcionem com qualquer combinação das duas origens.
///
/// É um valor sem estado próprio: quem guarda os dois conjuntos é o contexto da entrada, na fila `input`.
public struct CombinedPressed: Equatable, Sendable {
    /// Botões do controle físico ativo, como o `ActiveControllerRegistry` os conhece.
    public var controller: Set<ButtonID>
    /// Botões do controle virtual do iPhone.
    public var virtual: Set<ButtonID>

    public init(controller: Set<ButtonID> = [], virtual: Set<ButtonID> = []) {
        self.controller = controller
        self.virtual = virtual
    }

    /// O que o resto do aplicativo enxerga: um botão está pressionado se qualquer das origens o mantém.
    public var all: Set<ButtonID> { controller.union(virtual) }

    public func contains(_ button: ButtonID) -> Bool {
        controller.contains(button) || virtual.contains(button)
    }

    public var isEmpty: Bool { controller.isEmpty && virtual.isEmpty }
}
