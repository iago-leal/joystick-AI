import AppKit

/// Ícone na barra de menus com "Editar atalhos" e "Sair" (`003-editor-atalhos` D-18, RF-06). Só na main thread.
///
/// "Sair" passa por `NSApp.terminate`, que já solta teclas e botões mantidos em `Lifecycle` (001 RF-23). Com a
/// configuração inválida, o ícone vira alerta e o menu ganha no topo o item com a linha do erro (RF-20).
final class StatusMenu: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var alertItems: [NSMenuItem] = []

    var onEditShortcuts: (() -> Void)?
    /// Item de erro escolhido; abre o editor com `source: alert`.
    var onOpenFromAlert: (() -> Void)?

    override init() {
        super.init()
        setImage("gamecontroller")

        let edit = NSMenuItem(title: "Editar atalhos", action: #selector(editShortcuts), keyEquivalent: "")
        edit.target = self
        menu.addItem(edit)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Sair", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    func update(status: ConfigState.Status) {
        alertItems.forEach(menu.removeItem)
        alertItems = []
        guard case .invalid(let issue) = status else {
            setImage("gamecontroller")
            return
        }
        setImage("exclamationmark.triangle")
        let title = issue.line.map { "Configuração inválida: linha \($0)" } ?? "Configuração inválida"
        let alert = NSMenuItem(title: title, action: #selector(openFromAlert), keyEquivalent: "")
        alert.target = self
        alertItems = [alert, .separator()]
        for (index, item) in alertItems.enumerated() {
            menu.insertItem(item, at: index)
        }
    }

    private func setImage(_ symbol: String) {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "JoystickAI")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    @objc private func openFromAlert() {
        onOpenFromAlert?()
    }

    @objc private func editShortcuts() {
        onEditShortcuts?()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
