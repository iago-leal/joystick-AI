import AppKit

/// Ícone na barra de menus com "Editar atalhos" e "Sair" (`003-editor-atalhos` D-18, RF-06). Só na main thread.
///
/// "Sair" passa por `NSApp.terminate`, que já solta teclas e botões mantidos em `Lifecycle` (001 RF-23). Com a
/// configuração inválida, o ícone vira alerta e o menu ganha no topo o item com a linha do erro (RF-20).
///
/// O teclado remoto (`008-iphone-teclado-remoto` D-04, D-14) acrescenta "Teclado remoto" com marca de ligado,
/// "Mostrar pareamento", "Enviar certificado ao iPhone…" e, quando houver, a linha de erro de identidade ou de porta.
final class StatusMenu: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var alertItems: [NSMenuItem] = []
    private let remoteToggle = NSMenuItem(title: "Teclado remoto", action: nil, keyEquivalent: "")
    private let remotePairing = NSMenuItem(title: "Mostrar pareamento", action: nil, keyEquivalent: "")
    private let remoteCertificate = NSMenuItem(title: "Enviar certificado ao iPhone…", action: nil, keyEquivalent: "")
    private let remoteError = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    var onEditShortcuts: (() -> Void)?
    /// Item de erro escolhido; abre o editor com `source: alert`.
    var onOpenFromAlert: (() -> Void)?
    var onToggleRemote: ((Bool) -> Void)?
    var onShowPairing: (() -> Void)?

    override init() {
        super.init()
        setImage("gamecontroller")

        let edit = NSMenuItem(title: "Editar atalhos", action: #selector(editShortcuts), keyEquivalent: "")
        edit.target = self
        menu.addItem(edit)
        menu.addItem(.separator())
        remoteToggle.action = #selector(toggleRemote)
        remotePairing.action = #selector(showPairing)
        remoteCertificate.action = #selector(sendCertificate)
        remoteError.isEnabled = false
        remoteError.isHidden = true
        for item in [remoteToggle, remotePairing, remoteCertificate, remoteError] {
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Sair", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        menu.delegate = self
        menu.autoenablesItems = false
        update(remote: RemoteKeyboardStatus())
    }

    func update(remote: RemoteKeyboardStatus) {
        remoteToggle.state = remote.enabled ? .on : .off
        remotePairing.isEnabled = remote.enabled
        remoteError.title = remote.error ?? ""
        remoteError.isHidden = remote.error == nil
    }

    /// O arquivo da autoridade pode surgir com o app aberto (script rodado depois); confere a cada abertura do menu.
    func menuWillOpen(_ menu: NSMenu) {
        remoteCertificate.isEnabled = FileManager.default.fileExists(atPath: RemoteKeyboardIdentity.authorityCertificateURL.path)
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

    @objc private func toggleRemote() {
        onToggleRemote?(remoteToggle.state != .on)
    }

    @objc private func showPairing() {
        onShowPairing?()
    }

    /// AirDrop do certificado da autoridade (D-04); nunca da identidade do servidor.
    @objc private func sendCertificate() {
        let url = RemoteKeyboardIdentity.authorityCertificateURL
        guard FileManager.default.fileExists(atPath: url.path),
              let service = NSSharingService(named: .sendViaAirDrop), service.canPerform(withItems: [url])
        else { return }
        service.perform(withItems: [url])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
