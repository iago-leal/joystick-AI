import AppKit
import JoystickCore

/// Lista numerada das telas para `--screen` (D-20, `target-run-result.md` §1). Só na main thread.
enum ScreenCatalog {
    static func listings() -> [ScreenListing] {
        NSScreen.screens.enumerated().map { offset, screen in
            ScreenListing(
                index: offset + 1, name: screen.localizedName,
                widthPt: Int(screen.frame.width), heightPt: Int(screen.frame.height),
                backingScale: Double(screen.backingScaleFactor))
        }
    }

    static func emit(log: DiagnosticLog) {
        log.log(LogEventCatalog.targetsScreens(listings()))
    }

    static func descriptor(for screen: NSScreen) -> ScreenDescriptor {
        let scale = Double(screen.backingScaleFactor)
        return ScreenDescriptor(
            name: screen.localizedName,
            widthPx: Int((Double(screen.frame.width) * scale).rounded()), heightPx: Int((Double(screen.frame.height) * scale).rounded()),
            widthPt: Int(screen.frame.width), heightPt: Int(screen.frame.height), backingScale: scale)
    }

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
