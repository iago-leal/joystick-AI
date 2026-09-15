import AppKit

/// Ícone na barra de menus com "Editar atalhos" e "Sair" (`003-editor-atalhos` D-18, RF-06). Só na main thread.
///
/// "Sair" passa por `NSApp.terminate`, que já solta teclas e botões mantidos em `Lifecycle` (001 RF-23).
final class StatusMenu: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    var onEditShortcuts: (() -> Void)?

    override init() {
        super.init()
        let image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "JoystickAI")
        image?.isTemplate = true
        statusItem.button?.image = image

        let menu = NSMenu()
        let edit = NSMenuItem(title: "Editar atalhos", action: #selector(editShortcuts), keyEquivalent: "")
        edit.target = self
        menu.addItem(edit)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Sair", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func editShortcuts() {
        onEditShortcuts?()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
