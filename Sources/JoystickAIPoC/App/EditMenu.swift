import AppKit

/// Menu principal só com "Editar", para os atalhos de edição chegarem aos campos do editor (`003-editor-atalhos` P-03).
///
/// O app é `.accessory` e nunca mostra a barra de menus, mas ⌘V, ⌘C, ⌘X, ⌘A, ⌘Z e ⇧⌘Z só chegam ao campo em foco
/// como equivalentes de itens do menu principal. Sem ele, colar falhava, e com isso o ditado do Raycast, que insere
/// o texto colando. Não há item "Sair": ⌘Q no editor não deve encerrar o app. A gravação de acorde não é afetada,
/// porque o monitor local do `KeyCaptureField` consome as teclas antes dos equivalentes de menu.
enum EditMenu {
    static func install() {
        let edit = NSMenu(title: "Editar")
        edit.addItem(item("Desfazer", Selector(("undo:")), "z"))
        edit.addItem(item("Refazer", Selector(("redo:")), "z", [.command, .shift]))
        edit.addItem(.separator())
        edit.addItem(item("Recortar", #selector(NSText.cut(_:)), "x"))
        edit.addItem(item("Copiar", #selector(NSText.copy(_:)), "c"))
        edit.addItem(item("Colar", #selector(NSText.paste(_:)), "v"))
        edit.addItem(item("Selecionar tudo", #selector(NSText.selectAll(_:)), "a"))

        let editItem = NSMenuItem(title: "Editar", action: nil, keyEquivalent: "")
        editItem.submenu = edit
        let main = NSMenu()
        // O primeiro item é sempre tratado como menu do aplicativo; fica vazio.
        main.addItem(NSMenuItem(title: "JoystickAI", action: nil, keyEquivalent: ""))
        main.addItem(editItem)
        NSApp.mainMenu = main
    }

    private static func item(
        _ title: String, _ action: Selector, _ key: String, _ modifiers: NSEvent.ModifierFlags = [.command]
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        return item
    }
}
