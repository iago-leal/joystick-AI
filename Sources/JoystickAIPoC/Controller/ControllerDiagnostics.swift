import Foundation
import GameController
import JoystickCore

/// Lista de elementos e pedido de supressão de gestos (D-06, D-23, RF-24, P-03, P-07).
enum ControllerDiagnostics {
    static let suppressionMessage = """
    Pedido ao macOS: botão PS sem gestos do sistema (preferredSystemGestureState = disabled). \
    O macOS não informa se acatou. Verifique visualmente: pressionar PS não deve abrir o Launchpad \
    nem a sobreposição de jogos; se abrir, anote no bloco (f) do relatório.
    """

    static func attach(controller: GCController, gamepad: GCDualSenseGamepad, context: InputContext) {
        let profile = controller.physicalInputProfile
        if context.log.debugEnabled {
            context.log.log(LogEventCatalog.controllerElements(
                names: profile.elements.keys.sorted(), touchpads: profile.touchpads.keys.sorted()))
        }

        if let home = gamepad.buttonHome {
            home.preferredSystemGestureState = .disabled
            context.log.log(LogEventCatalog.controllerGestureSuppression(elements: ["buttonHome"], message: suppressionMessage))
        } else {
            context.log.log(LogEventCatalog.controllerGestureSuppression(
                elements: [], message: "buttonHome ausente no perfil do controle; supressão não pedida."))
        }
    }
}
