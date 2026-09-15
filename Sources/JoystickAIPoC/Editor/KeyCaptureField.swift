import AppKit
import JoystickCore
import SwiftUI

/// Gravação de acorde pelo teclado físico (`003-editor-atalhos` D-22 a, RN-15).
///
/// Sem aparência própria: usado como fundo do controle que o ativa. Só enquanto `isActive` for verdadeiro, e só para
/// eventos da janela em foco, um monitor local consome as teclas; nunca há monitor global. Teclas injetadas pelo
/// próprio app (marca `EventInjector.sourceMark`) são descartadas. O primeiro acorde com tecla do `KeyCatalog`
/// encerra a gravação.
struct KeyCaptureField: NSViewRepresentable {
    @Binding var isActive: Bool
    var onCapture: (KeyChord) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        KeyCaptureView()
    }

    func updateNSView(_ view: KeyCaptureView, context: Context) {
        view.onCapture = onCapture
        view.onFinish = { isActive = false }
        view.setActive(isActive)
    }

    static func dismantleNSView(_ view: KeyCaptureView, coordinator: ()) {
        view.setActive(false)
    }
}

final class KeyCaptureView: NSView {
    var onCapture: ((KeyChord) -> Void)?
    var onFinish: (() -> Void)?
    private var monitor: Any?
    private var wantsActive = false

    func setActive(_ active: Bool) {
        wantsActive = active
        if active, monitor == nil, window != nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
                guard let self else { return event }
                return self.handle(event)
            }
        } else if !active, let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil, let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        } else if window != nil {
            setActive(wantsActive)
        }
    }

    /// Devolve `nil` para consumir o evento, ou o próprio evento para deixá-lo seguir.
    private func handle(_ event: NSEvent) -> NSEvent? {
        guard let window, event.window === window, window.isKeyWindow else { return event }
        if event.cgEvent?.getIntegerValueField(.eventSourceUserData) == EventInjector.sourceMark {
            return nil
        }
        guard event.type == .keyDown else { return nil }
        guard KeyCatalog.entry(keyCode: event.keyCode) != nil else { return nil }
        let chord = KeyChord(event.keyCode, Self.modifiers(event.modifierFlags))
        setActive(false)
        onCapture?(chord)
        onFinish?()
        return nil
    }

    private static func modifiers(_ flags: NSEvent.ModifierFlags) -> Set<KeyModifier> {
        var result: Set<KeyModifier> = []
        if flags.contains(.command) { result.insert(.command) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.shift) { result.insert(.shift) }
        return result
    }
}
