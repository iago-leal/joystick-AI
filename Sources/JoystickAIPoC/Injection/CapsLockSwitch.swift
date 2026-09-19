import IOKit
import IOKit.hid

/// Trava do Caps Lock do sistema pela IOKit (`008-iphone-teclado-remoto` D-17, revista no PM-0).
///
/// O `flagsChanged` sintético do código 57 não alterna a trava (sonda P-04 reprovada); `IOHIDSetModifierLockState`
/// alterna, e a luz e o `maskAlphaShift` do estado do sistema acompanham. A conexão abre no primeiro uso.
final class CapsLockSwitch {
    private var connect: io_connect_t = 0

    deinit {
        if connect != 0 { IOServiceClose(connect) }
    }

    /// Estado atual da trava; `nil` sem acesso ao `IOHIDSystem`.
    var isOn: Bool? {
        guard open() else { return nil }
        var state = false
        return IOHIDGetModifierLockState(connect, Int32(kIOHIDCapsLockState), &state) == KERN_SUCCESS ? state : nil
    }

    /// Inverte a trava; devolve o estado novo, ou `nil` se a IOKit recusar.
    @discardableResult
    func toggle() -> Bool? {
        guard let current = isOn,
              IOHIDSetModifierLockState(connect, Int32(kIOHIDCapsLockState), !current) == KERN_SUCCESS
        else { return nil }
        return !current
    }

    private func open() -> Bool {
        if connect != 0 { return true }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }
        return IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect) == KERN_SUCCESS
    }
}
