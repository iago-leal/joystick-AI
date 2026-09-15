import Foundation
import Testing
@testable import JoystickCore

@Suite struct LogEventCatalogTests {
    static let forbiddenKeys: Set<String> = ["x", "y", "dx", "dy", "location", "position", "value"]

    static func allKeys(_ value: JSONValue) -> Set<String> {
        switch value {
        case .object(let dict):
            return dict.reduce(into: Set(dict.keys)) { $0.formUnion(allKeys($1.value)) }
        case .array(let items):
            return items.reduce(into: Set<String>()) { $0.formUnion(allKeys($1)) }
        default:
            return []
        }
    }

    static var sampleEvents: [LogEvent] {
        let info = ControllerInfo(id: UUID(), name: "DualSense Wireless Controller", connection: .bluetooth, connectedAt: 10, atStartup: true)
        var settings = PointerSettings()
        settings.stickMaxSpeed = 1800
        return [
            LogEventCatalog.sessionStart(appVersion: "0.1.0", macOS: "26.5", pid: 42, debug: true, args: ["--debug"], signing: .object(["identifier": "dev.iagoleal.joystick-ai.poc"])),
            LogEventCatalog.permissionsStatus(postEvent: true, listenEvent: false, trigger: .startup),
            LogEventCatalog.permissionsGuidance(message: "Ajustes"),
            LogEventCatalog.displaysChanged(count: 2),
            LogEventCatalog.cursorReclamped(),
            LogEventCatalog.controllerConnected(info, tArrival: 10),
            LogEventCatalog.controllerIgnored(name: "Xbox", productCategory: "Xbox One", reason: "not_dualsense"),
            LogEventCatalog.controllerQueued(id: info.id, position: 1),
            LogEventCatalog.controllerDisconnected(id: info.id, tArrival: 20),
            LogEventCatalog.controllerElements(names: ["Button A"], touchpads: ["Touchpad 1"]),
            LogEventCatalog.controllerTouchSource(id: info.id, source: .zeroTransition),
            LogEventCatalog.controllerGestureSuppression(elements: ["buttonHome"], message: "PS"),
            LogEventCatalog.controllerExtendedReport(transport: .bluetooth, result: "ok"),
            LogEventCatalog.controllerError(message: "falha"),
            LogEventCatalog.inputButton(.r2, phase: .down, synthetic: false, tArrival: 1, tDelivered: 2, tFramework: 3.5),
            LogEventCatalog.inputTouch(finger: 0, phase: .began, tArrival: 1, tDelivered: 2),
            LogEventCatalog.touchRawTransition(finger: 1, toZero: true),
            LogEventCatalog.pointerPosted(kind: .down, button: .left, source: .button, clickState: 2, tArrival: 1, tPosted: 3),
            LogEventCatalog.injectionSuspended(heldButtons: [.left]),
            LogEventCatalog.injectionResumed(heldButtons: []),
            LogEventCatalog.targetsScreens([ScreenListing(index: 1, name: "Built-in", widthPt: 1512, heightPt: 982, backingScale: 2)]),
            LogEventCatalog.targetsStarted(environment: .sofa, seed: 7),
            LogEventCatalog.targetsFinished(environment: .sofa, seed: 7, complete: false, abortReason: .screenRemoved, file: "/tmp/r.json"),
            LogEventCatalog.targetsInvalidArgs(message: "env"),
            LogEventCatalog.targetsScreenFallback(message: "tela 3"),
            LogEventCatalog.targetsWriteFailed(message: "disco", payload: "{}"),
            LogEventCatalog.appTerminating(reason: .sigterm, releasedButtons: [.left]),
            LogEventCatalog.logDebugSuspended(sizeBytes: 52_428_801),
            LogEventCatalog.paletteOpened(selection: 1),
            LogEventCatalog.paletteConfirmed(index: 2, enter: true),
            LogEventCatalog.paletteClosed(reason: .injectionSuspended),
            LogEventCatalog.paletteBlocked(),
            LogEventCatalog.paletteInvalidArgs(message: "--palette-enter-delay-ms sem valor"),
        ] + LogEventCatalog.config(ConfigLoadResult(settings: settings, status: .loaded, reason: nil, issues: [
            .valueRejected(field: "deadzone", rejected: 0.9, min: 0, max: 0.5, defaultValue: 0.12),
        ])) + LogEventCatalog.config(ConfigLoadResult(settings: PointerSettings(), status: .invalidJSON, reason: nil, issues: [.invalidJSON(line: 4, message: "vírgula")]))
            + LogEventCatalog.config(ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: nil, issues: [.unreadable(message: "diretório")]))
            + LogEventCatalog.config(ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: "file_missing", issues: []))
    }

    @Test func nenhumEventoTemCoordenadasOuValoresDeEixo() {
        for event in Self.sampleEvents {
            var keys = Self.allKeys(.object(event.fields))
            // Única exceção do contrato: em `controller.queued`, `position` é a posição ordinal na fila, não espacial.
            if event.name == "controller.queued" {
                #expect(event.fields["position"]?.intValue != nil)
                keys.remove("position")
            }
            #expect(keys.isDisjoint(with: Self.forbiddenKeys), "\(event.name): \(keys)")
        }
    }

    @Test func nomesENiveisDoContrato() {
        let expected: [String: LogLevel] = [
            "session.start": .info, "permissions.status": .info, "permissions.guidance": .warn,
            "config.loaded": .info, "config.value_rejected": .warn, "config.invalid_json": .error, "config.unreadable": .error,
            "displays.changed": .info, "cursor.reclamped": .info,
            "controller.connected": .info, "controller.ignored": .info, "controller.queued": .info, "controller.disconnected": .info,
            "controller.elements": .debug, "controller.touch_source": .info, "controller.gesture_suppression": .info, "controller.extended_report": .info, "controller.error": .error,
            "input.button": .debug, "input.touch": .debug, "touch.raw_transition": .debug, "pointer.posted": .debug,
            "pointer.injection_suspended": .warn, "pointer.injection_resumed": .info,
            "targets.screens": .info, "targets.started": .info, "targets.finished": .info,
            "targets.invalid_args": .warn, "targets.screen_fallback": .warn, "targets.write_failed": .error,
            "app.terminating": .info, "log.debug_suspended": .warn,
            "palette.opened": .info, "palette.confirmed": .info, "palette.closed": .info, "palette.blocked": .info,
            "palette.invalid_args": .warn,
        ]
        let events = Self.sampleEvents
        #expect(Set(events.map(\.name)) == Set(expected.keys))
        for event in events {
            #expect(expected[event.name] == event.level, "\(event.name)")
        }
    }

    func fields(_ name: String) -> [String: JSONValue] {
        Self.sampleEvents.first { $0.name == name }!.fields
    }

    @Test func camposDosEventosPrincipais() {
        #expect(Set(fields("session.start").keys) == ["logSchema", "appVersion", "macOS", "pid", "debug", "args", "signing"])
        #expect(fields("session.start")["logSchema"] == 1)
        #expect(Set(fields("permissions.status").keys) == ["postEvent", "listenEvent", "trigger"])
        #expect(Set(fields("controller.connected").keys) == ["id", "name", "connection", "atStartup", "t_arrival"])
        #expect(fields("controller.connected")["atStartup"] == true)
        #expect(fields("controller.touch_source")["source"] == "zero_transition")
        #expect(fields("controller.gesture_suppression")["elements"] == .array(["buttonHome"]))
        #expect(Set(fields("input.button").keys) == ["button", "phase", "synthetic", "t_arrival", "t_delivered", "t_framework"])
        #expect(Set(fields("input.touch").keys) == ["finger", "phase", "t_arrival", "t_delivered"])
        #expect(Set(fields("pointer.posted").keys) == ["kind", "button", "source", "clickState", "t_arrival", "t_posted"])
        #expect(Set(fields("config.value_rejected").keys) == ["field", "rejected", "min", "max", "default"])
        #expect(fields("config.invalid_json")["line"] == 4)
        #expect(Set(fields("targets.finished").keys) == ["env", "seed", "complete", "abortReason", "file"])
        #expect(fields("targets.finished")["abortReason"] == "screen_removed")
        #expect(Set(fields("app.terminating").keys) == ["reason", "releasedButtons"])
        #expect(fields("config.loaded")["reason"] == nil)
    }

    /// RN-07 da `002-paleta-comandos`: os eventos da paleta levam índice e motivo, nunca o texto do item.
    @Test func eventosDaPaletaSemTextoDeItem() {
        let texts = Set(PaletteDefaults.items.map(\.text))
        for event in Self.sampleEvents where event.name.hasPrefix("palette.") {
            #expect(Self.allKeys(.object(event.fields)).isDisjoint(with: ["text", "label", "item"]), "\(event.name)")
            let leaked = event.fields.values.filter { value in
                if case .string(let string) = value { return texts.contains(string) }
                return false
            }
            #expect(leaked.isEmpty, "\(event.name)")
        }
        #expect(Set(fields("palette.opened").keys) == ["selection"])
        #expect(Set(fields("palette.confirmed").keys) == ["index", "enter"])
        #expect(fields("palette.closed")["reason"] == "injection_suspended")
        #expect(fields("palette.blocked")["reason"] == "targets")
    }

    @Test func campoOpcionalAusenteNaoAparece() {
        let posted = LogEventCatalog.pointerPosted(kind: .move, button: nil, source: .touch, clickState: nil, tArrival: 1, tPosted: 2)
        #expect(Set(posted.fields.keys) == ["kind", "source", "t_arrival", "t_posted"])
        let button = LogEventCatalog.inputButton(.cross, phase: .up, synthetic: true, tArrival: 1, tDelivered: 1, tFramework: nil)
        #expect(button.fields["t_framework"] == nil)
    }
}
