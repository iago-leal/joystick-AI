import CoreGraphics
import Foundation
import JoystickCore

/// Teclas e texto por `CGEvent`, com a mesma marca e o mesmo ponto de injeção do mouse (protótipo de atalhos).
///
/// Todo acesso ocorre na fila `input`. Com a injeção desativada (D-15), os eventos são descartados.
final class KeyboardInjector {
    private let injector: EventInjector
    /// Quantas teclas ou botões mantêm cada modificador pressionado.
    private var modifierCounts: [KeyModifier: Int] = [:]

    init(injector: EventInjector) {
        self.injector = injector
    }

    private static func keyCode(_ modifier: KeyModifier) -> UInt16 {
        switch modifier {
        case .command: 55
        case .shift: 56
        case .option: 58
        case .control: 59
        }
    }

    private static func flag(_ modifier: KeyModifier) -> CGEventFlags {
        switch modifier {
        case .command: .maskCommand
        case .shift: .maskShift
        case .option: .maskAlternate
        case .control: .maskControl
        }
    }

    private var heldFlags: CGEventFlags {
        modifierCounts.reduce(into: CGEventFlags()) { flags, entry in
            if entry.value > 0 { flags.insert(Self.flag(entry.key)) }
        }
    }

    func modifierDown(_ modifier: KeyModifier) {
        modifierCounts[modifier, default: 0] += 1
        if modifierCounts[modifier] == 1 { postModifier(modifier, down: true) }
    }

    func modifierUp(_ modifier: KeyModifier) {
        guard let count = modifierCounts[modifier], count > 0 else { return }
        modifierCounts[modifier] = count - 1
        if count == 1 { postModifier(modifier, down: false) }
    }

    /// Pressiona os modificadores do acorde que ainda não estão mantidos e depois a tecla.
    func chordDown(_ chord: KeyChord) {
        for modifier in chord.modifiers.sorted() { modifierDown(modifier) }
        postKey(chord, down: true, autorepeat: false)
    }

    func chordUp(_ chord: KeyChord) {
        postKey(chord, down: false, autorepeat: false)
        for modifier in chord.modifiers.sorted().reversed() { modifierUp(modifier) }
    }

    func chordRepeat(_ chord: KeyChord) {
        postKey(chord, down: true, autorepeat: true)
    }

    /// Solta a tecla e os modificadores do acorde mesmo que a contagem diga que já estão soltos.
    func forceUp(_ chord: KeyChord) {
        postKey(chord, down: false, autorepeat: false)
        for modifier in chord.modifiers.sorted().reversed() { forceModifierUp(modifier) }
    }

    func forceModifierUp(_ modifier: KeyModifier) {
        guard modifierCounts[modifier, default: 0] == 0 else { return }
        postModifier(modifier, down: false)
    }

    /// Digita o texto caractere a caractere, independente do *layout* do teclado.
    func type(_ text: String, pressEnter: Bool) {
        guard injector.enabled else { return }
        for unit in text.utf16 {
            for down in [true, false] {
                guard let event = CGEvent(keyboardEventSource: injector.eventSource, virtualKey: 0, keyDown: down) else { continue }
                var character = unit
                event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
                event.flags = []
                injector.deliver(event)
            }
        }
        if pressEnter {
            chordDown(KeyChord(KeyChord.returnKey))
            chordUp(KeyChord(KeyChord.returnKey))
        }
    }

    private func postModifier(_ modifier: KeyModifier, down: Bool) {
        guard injector.enabled,
              let event = CGEvent(keyboardEventSource: injector.eventSource, virtualKey: Self.keyCode(modifier), keyDown: down)
        else { return }
        event.type = .flagsChanged
        event.flags = heldFlags
        injector.deliver(event)
    }

    private func postKey(_ chord: KeyChord, down: Bool, autorepeat: Bool) {
        guard injector.enabled,
              let event = CGEvent(keyboardEventSource: injector.eventSource, virtualKey: chord.keyCode, keyDown: down)
        else { return }
        var flags = heldFlags
        // As setas do teclado físico chegam com essas duas máscaras; os atalhos de Mission Control as esperam.
        if chord.isArrow { flags.formUnion([.maskNumericPad, .maskSecondaryFn]) }
        event.flags = flags
        if autorepeat { event.setIntegerValueField(.keyboardEventAutorepeat, value: 1) }
        injector.deliver(event)
    }
}
