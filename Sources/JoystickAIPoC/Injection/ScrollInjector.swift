import CoreGraphics
import Foundation
import JoystickCore

/// Rolagem por `CGEvent` em pixels ou linhas (D-13, RF-14). Chamado na fila `input`.
final class ScrollInjector {
    private let injector: EventInjector
    let unit: ScrollUnit

    init(injector: EventInjector, unit: ScrollUnit) {
        self.injector = injector
        self.unit = unit
    }

    func scroll(vertical: Int32, horizontal: Int32, origin: PostSource?, tArrival: UInt64?) {
        guard injector.enabled, vertical != 0 || horizontal != 0 else { return }
        guard let event = CGEvent(
            scrollWheelEvent2Source: injector.eventSource, units: unit == .pixel ? .pixel : .line,
            wheelCount: 2, wheel1: vertical, wheel2: horizontal, wheel3: 0)
        else { return }
        injector.deliver(event, kind: .scroll, button: nil, origin: origin, clickState: nil, tArrival: tArrival)
    }
}
