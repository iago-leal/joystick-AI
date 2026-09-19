import Carbon.HIToolbox
import Foundation

/// Texto que cada tecla do teclado remoto produz na fonte de entrada ativa, com as teclas mortas
/// (`009-sugestao-de-palavras` D-02). É o mesmo cálculo que o sistema faz ao receber a tecla injetada.
///
/// Só na fila `input`. O layout é lido na main thread pelo `KeyboardLayoutReader` e entregue aqui, porque as funções
/// de fonte de entrada do HIToolbox exigem a main thread; `UCKeyTranslate` só lê os dados do layout.
final class KeyTextTranslator {
    /// Dados `uchr` da fonte de entrada ativa e o tipo de teclado.
    struct Layout {
        let data: Data
        let keyboardType: UInt32
    }

    private var layout: Layout?
    private var deadState: UInt32 = 0

    /// Fonte de entrada nova (início da sessão ou troca): o acento armado na anterior não vale mais.
    func setLayout(_ layout: Layout?) {
        self.layout = layout
        deadState = 0
    }

    /// Descarte do contexto (RN-03): esquece o acento armado.
    func reset() {
        deadState = 0
    }

    /// Texto da tecla com ⇧, ⌥ e Caps Lock; vazio quando só arma um acento ou sem layout.
    func text(code: UInt16, shift: Bool, option: Bool, capsLock: Bool) -> String {
        guard let layout else { return "" }
        var modifiers: UInt32 = 0
        if shift { modifiers |= UInt32(shiftKey >> 8) & 0xFF }
        if option { modifiers |= UInt32(optionKey >> 8) & 0xFF }
        if capsLock { modifiers |= UInt32(alphaLock >> 8) & 0xFF }
        var length = 0
        var characters = [UniChar](repeating: 0, count: 8)
        let status = layout.data.withUnsafeBytes { buffer -> OSStatus in
            guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return -1 }
            return UCKeyTranslate(
                pointer, code, UInt16(kUCKeyActionDown), modifiers, layout.keyboardType, 0, &deadState,
                characters.count, &length, &characters)
        }
        guard status == noErr else {
            deadState = 0
            return ""
        }
        return String(utf16CodeUnits: characters, count: length)
    }
}
