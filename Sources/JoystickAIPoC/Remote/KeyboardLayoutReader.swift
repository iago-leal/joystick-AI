import Carbon.HIToolbox
import Foundation
import JoystickCore

/// Rótulos das teclas pela fonte de entrada ativa, como o Teclado de Acessibilidade os calcula
/// (`008-iphone-teclado-remoto` D-12, RN-12). Só na main thread.
final class KeyboardLayoutReader: NSObject {
    /// Chamado na main thread quando o usuário troca a fonte de entrada.
    var onChange: ((KeyLabelTable) -> Void)?
    private var observing = false

    /// Disposição desenhada na página: sempre ANSI, por escolha do usuário no PM-0. A P-07 aprovou a detecção do
    /// teclado embutido (ISO), mas o uso é com teclados externos americanos e a fonte EUA Internacional, em que o ` e
    /// o ~ ficam no canto do código 50, e não no § do código 10. A geometria ISO segue no núcleo.
    static var physicalLayout: PhysicalLayout { .ansi }

    /// A entrega é imediata: com a padrão, o `NSApplication` suspende as notificações distribuídas enquanto o app não
    /// está à frente, que é quase sempre o caso deste app de barra de menus, e a página nunca recebia os rótulos novos
    /// (passo 7 do PM-1).
    func start() {
        guard !observing else { return }
        observing = true
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(inputSourceChanged),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil,
            suspensionBehavior: .deliverImmediately)
    }

    func stop() {
        guard observing else { return }
        observing = false
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func inputSourceChanged(_ notification: Notification) {
        DispatchQueue.main.async { [self] in
            guard observing else { return }
            onChange?(Self.labels(for: RemoteKeyGeometry.standard(Self.physicalLayout).codes))
        }
    }

    /// Dados do layout da fonte de entrada ativa, para os rótulos e para o `KeyTextTranslator`
    /// (`009-sugestao-de-palavras` D-02).
    static func currentLayout() -> KeyTextTranslator.Layout? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue()
                ?? TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        return KeyTextTranslator.Layout(data: data, keyboardType: UInt32(LMGetKbdType()))
    }

    /// Tabela para os códigos pedidos; teclas que não produzem caractere ficam de fora.
    static func labels(for codes: [UInt16]) -> KeyLabelTable {
        guard let current = currentLayout() else { return KeyLabelTable() }
        let data = current.data
        let keyboardType = current.keyboardType
        var table: [UInt16: KeyLabels] = [:]
        data.withUnsafeBytes { buffer in
            guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return }
            let states: [(KeyLabelState, UInt32)] = [
                (.plain, 0),
                (.shift, UInt32(shiftKey >> 8) & 0xFF),
                (.option, UInt32(optionKey >> 8) & 0xFF),
                (.shiftOption, UInt32((shiftKey | optionKey) >> 8) & 0xFF),
            ]
            for code in codes {
                var labels: [KeyLabelState: String] = [:]
                var dead: Set<KeyLabelState> = []
                for (state, modifiers) in states {
                    let (text, isDead) = translate(layout, code: code, modifiers: modifiers, keyboardType: keyboardType)
                    labels[state] = text
                    if isDead { dead.insert(state) }
                }
                guard let plain = labels[.plain], !plain.isEmpty else { continue }
                table[code] = KeyLabels(
                    plain: plain, shift: labels[.shift] ?? "", option: labels[.option] ?? "",
                    shiftOption: labels[.shiftOption] ?? "", dead: dead)
            }
        }
        return KeyLabelTable(labels: table)
    }

    /// Caractere da tecla no estado; para tecla morta, o acento isolado (a tecla seguida de espaço).
    private static func translate(
        _ layout: UnsafePointer<UCKeyboardLayout>, code: UInt16, modifiers: UInt32, keyboardType: UInt32
    ) -> (String, Bool) {
        var deadState: UInt32 = 0
        var first = key(layout, code: code, modifiers: modifiers, keyboardType: keyboardType, deadState: &deadState)
        var isDead = false
        if first.isEmpty, deadState != 0 {
            isDead = true
            first = key(layout, code: UInt16(kVK_Space), modifiers: 0, keyboardType: keyboardType, deadState: &deadState)
        }
        // Controles (Esc, Tab, Return, setas) ficam com o nome fixo da página.
        guard let scalar = first.unicodeScalars.first, scalar.value >= 0x20, scalar.value != 0x7F else { return ("", false) }
        return (first, isDead)
    }

    private static func key(
        _ layout: UnsafePointer<UCKeyboardLayout>, code: UInt16, modifiers: UInt32, keyboardType: UInt32,
        deadState: inout UInt32
    ) -> String {
        var length = 0
        var characters = [UniChar](repeating: 0, count: 8)
        let status = UCKeyTranslate(
            layout, code, UInt16(kUCKeyActionDown), modifiers, keyboardType, 0, &deadState, characters.count, &length,
            &characters)
        guard status == noErr else { return "" }
        return String(utf16CodeUnits: characters, count: length)
    }
}
