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
        let ipega = ControllerInfo(id: UUID(), name: "Pro Controller", connection: .usb, connectedAt: 11, atStartup: false, model: .ipega)
        var settings = PointerSettings()
        settings.stickMaxSpeed = 1800
        return [
            LogEventCatalog.sessionStart(appVersion: "0.1.0", macOS: "26.5", pid: 42, debug: true, args: ["--debug"], signing: .object(["identifier": "dev.iagoleal.joystick-ai.poc"])),
            LogEventCatalog.permissionsStatus(postEvent: true, listenEvent: false, trigger: .startup),
            LogEventCatalog.permissionsGuidance(message: "Ajustes"),
            LogEventCatalog.displaysChanged(count: 2),
            LogEventCatalog.cursorReclamped(),
            LogEventCatalog.controllerConnected(info, charge: ControllerCharge(level: 0.84, state: .discharging), tArrival: 10),
            LogEventCatalog.controllerConnected(ipega, charge: nil, tArrival: 11),
            LogEventCatalog.controllerCharge(id: info.id, percent: 38, state: .charging),
            LogEventCatalog.menuCycle(keys: 4, durationMs: 3900),
            LogEventCatalog.controllerIgnored(name: "Xbox", productCategory: "Xbox One", reason: "unsupported_model"),
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
            LogEventCatalog.paletteClosed(reason: .configChanged),
        ] + Self.shortcutEvents + Self.remoteEvents + LogEventCatalog.config(ConfigLoadResult(settings: settings, status: .loaded, reason: nil, issues: [
            .valueRejected(field: "deadzone", rejected: 0.9, min: 0, max: 0.5, defaultValue: 0.12),
        ])) + LogEventCatalog.config(ConfigLoadResult(settings: PointerSettings(), status: .invalidJSON, reason: nil, issues: [.invalidJSON(line: 4, message: "vírgula")]))
            + LogEventCatalog.config(ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: nil, issues: [.unreadable(message: "diretório")]))
            + LogEventCatalog.config(ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: "file_missing", issues: []))
    }

    /// Eventos de `003-editor-atalhos/interfaces/diagnostic-log.md` §2.
    static var shortcutEvents: [LogEvent] {
        [
            LogEventCatalog.shortcutsLoaded(trigger: .external, source: .file, reason: nil, modifiers: [.options, .l3, .l1], items: 18),
            LogEventCatalog.shortcutsUnchanged(trigger: .external),
            LogEventCatalog.shortcutsInvalid(trigger: .startup, rule: .unknownKey, path: "shortcuts.layers.base.cross.key", line: 12),
            LogEventCatalog.shortcutsFileRemoved(),
            LogEventCatalog.shortcutsSaved(created: true, backup: false),
            LogEventCatalog.shortcutsSaveFailed(message: "/Users/u/.config/joystick-ai/config.json: permissão negada"),
            LogEventCatalog.shortcutsRestored(),
            LogEventCatalog.shortcutTriggered(button: .circle, layer: .l3, type: .systemShortcut),
            LogEventCatalog.editorOpened(source: .palette),
            LogEventCatalog.editorClosed(outcome: .saved),
            LogEventCatalog.editorConflict(choice: .pending),
            LogEventCatalog.editorIdentify(on: true),
            LogEventCatalog.editorActivationFailed(),
            LogEventCatalog.editorFigureUnavailable(reason: .resourceMissing),
        ]
    }

    /// Eventos de `008-iphone-teclado-remoto/interfaces/diagnostic-log.md` §2.
    static var remoteEvents: [LogEvent] {
        [
            LogEventCatalog.remoteEnabled(port: 47810, channelPort: 47811),
            LogEventCatalog.remoteDisabled(reason: .listenerFailed),
            LogEventCatalog.remoteConnected(resumed: true),
            LogEventCatalog.remoteRejected(reason: .notLocal),
            LogEventCatalog.remoteWatchdog(held: 2),
            LogEventCatalog.remoteDisconnected(reason: .invalidMessages, keys: 50, suggestions: 3, buttons: 12, clicks: 4),
            LogEventCatalog.remoteMode(.pointer),
        ]
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
            "controller.charge": .info, "menu.cycle": .info,
            "controller.elements": .debug, "controller.touch_source": .info, "controller.gesture_suppression": .info, "controller.extended_report": .info, "controller.error": .error,
            "input.button": .debug, "input.touch": .debug, "touch.raw_transition": .debug, "pointer.posted": .debug,
            "pointer.injection_suspended": .warn, "pointer.injection_resumed": .info,
            "targets.screens": .info, "targets.started": .info, "targets.finished": .info,
            "targets.invalid_args": .warn, "targets.screen_fallback": .warn, "targets.write_failed": .error,
            "app.terminating": .info, "log.debug_suspended": .warn,
            "palette.opened": .info, "palette.confirmed": .info, "palette.closed": .info, "palette.blocked": .info,
            "palette.invalid_args": .warn,
            "shortcuts.loaded": .info, "shortcuts.unchanged": .debug, "shortcuts.invalid": .error,
            "shortcuts.file_removed": .info, "shortcuts.saved": .info, "shortcuts.save_failed": .error,
            "shortcuts.restored": .info, "shortcut.triggered": .info,
            "editor.opened": .info, "editor.closed": .info, "editor.conflict": .warn, "editor.identify": .info,
            "editor.activation_failed": .warn, "editor.figure_unavailable": .warn,
            "remote.enabled": .info, "remote.disabled": .info, "remote.connected": .info, "remote.rejected": .warn,
            "remote.watchdog": .warn, "remote.disconnected": .info, "remote.mode": .info,
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
        #expect(Set(fields("controller.connected").keys) == ["id", "name", "connection", "atStartup", "model", "t_arrival", "charge", "chargeState"])
        #expect(fields("controller.connected")["atStartup"] == true)
        #expect(fields("controller.connected")["charge"] == 84)
        #expect(fields("controller.connected")["chargeState"] == "discharging")
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

    /// Carga no log (`011-bateria-e-cursor-no-menu` D-09, RN-12, `interfaces/diagnostic-log.md` §2 e §3).
    ///
    /// Os dois campos da carga são **omitidos**, e não gravados como zero, quando ela é indisponível: gravar zero
    /// tornaria indistinguíveis o controle descarregado e o controle que não conta quanta carga tem, a mesma
    /// confusão que D-02 evita na tela e que seria igualmente nociva na análise posterior.
    @Test func cargaIndisponivelOmiteOsCamposEmVezDeZerar() {
        let semCarga = Self.sampleEvents.filter { $0.name == "controller.connected" }.first { $0.fields["model"] == "ipega" }!
        #expect(semCarga.fields["charge"] == nil)
        #expect(semCarga.fields["chargeState"] == nil)
        #expect(Set(semCarga.fields.keys) == ["id", "name", "connection", "atStartup", "model", "t_arrival"])
    }

    @Test func camposDaCargaEDoCicloDoMenu() {
        #expect(fields("controller.charge").keys.contains("id"))
        #expect(fields("controller.charge")["charge"] == 38)
        #expect(fields("controller.charge")["state"] == "charging")
        #expect(Set(fields("controller.charge").keys) == ["id", "charge", "state"])
        #expect(fields("menu.cycle") == ["keys": 4, "durationMs": 3900])
        #expect(ControllerChargeState.allCases.map(\.rawValue) == ["unknown", "discharging", "charging", "full"])
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

    @Test func paletaFechadaPorConfiguracaoNova() {
        #expect(LogEventCatalog.paletteClosed(reason: .configChanged).fields == ["reason": "config_changed"])
    }

    /// RN-14: atalhos e editor levam botão, camada, tipo, contagens, caminho, linha e regra; nunca texto, rótulo,
    /// nome de tecla nem acorde.
    @Test func eventosDeAtalhosSemTextoTeclaNemAcorde() {
        let secrets = Set(PaletteDefaults.items.map(\.text) + [ShortcutDefaults.continueText])
            .union(KeyCatalog.entries.flatMap { [$0.name, $0.display] })
            .union(KeyCatalog.composedKeys.flatMap { [$0.name, $0.display] })
            .union(KeyModifier.allCases.map(\.rawValue))
        for event in Self.shortcutEvents {
            #expect(Self.allKeys(.object(event.fields)).isDisjoint(with: ["text", "label", "key", "keys", "chord", "item"]), "\(event.name)")
            for value in event.fields.values {
                let strings: [String] = switch value {
                case .string(let string): [string]
                case .array(let items): items.compactMap(\.stringValue)
                default: []
                }
                #expect(strings.allSatisfy { !secrets.contains($0) }, "\(event.name): \(strings)")
            }
        }
    }

    @Test func camposDosEventosDeAtalhos() {
        #expect(fields("shortcuts.loaded") == [
            "trigger": "external", "source": "file", "modifiers": .array(["l1", "l3", "options"]), "items": 18,
        ])
        #expect(LogEventCatalog.shortcutsLoaded(trigger: .startup, source: .defaults, reason: .fileMissing, modifiers: [], items: 17)
            .fields["reason"] == "file_missing")
        #expect(fields("shortcuts.unchanged") == ["trigger": "external"])
        #expect(fields("shortcuts.invalid") == ["trigger": "startup", "rule": "unknownKey", "path": "shortcuts.layers.base.cross.key", "line": 12])
        #expect(LogEventCatalog.shortcutsInvalid(trigger: .external, rule: .syntax, path: nil, line: nil).fields == [
            "trigger": "external", "rule": "syntax",
        ])
        #expect(fields("shortcuts.file_removed").isEmpty)
        #expect(fields("shortcuts.saved") == ["created": true, "backup": false])
        #expect(Set(fields("shortcuts.save_failed").keys) == ["message"])
        #expect(fields("shortcuts.restored").isEmpty)
        #expect(fields("shortcut.triggered") == ["button": "circle", "layer": "l3", "type": "systemShortcut"])
        #expect(LogEventCatalog.shortcutTriggered(button: .cross, layer: nil, type: .chord).fields["layer"] == "base")
        #expect(fields("editor.opened") == ["source": "palette"])
        #expect(fields("editor.closed") == ["outcome": "saved"])
        #expect(fields("editor.conflict") == ["choice": "pending"])
        #expect(fields("editor.identify") == ["on": true])
        #expect(fields("editor.activation_failed").isEmpty)
    }

    /// `004-figura-controle-web/interfaces/diagnostic-log.md` §2: só o motivo, em `snake_case`.
    @Test func figuraIndisponivelSoComMotivo() {
        #expect(fields("editor.figure_unavailable") == ["reason": "resource_missing"])
        #expect(LogEventCatalog.editorFigureUnavailable(reason: .loadFailed).fields == ["reason": "load_failed"])
        #expect(LogEventCatalog.editorFigureUnavailable(reason: .processTerminated).fields == ["reason": "process_terminated"])
    }

    @Test func campoOpcionalAusenteNaoAparece() {
        let posted = LogEventCatalog.pointerPosted(kind: .move, button: nil, source: .touch, clickState: nil, tArrival: 1, tPosted: 2)
        #expect(Set(posted.fields.keys) == ["kind", "source", "t_arrival", "t_posted"])
        let button = LogEventCatalog.inputButton(.cross, phase: .up, synthetic: true, tArrival: 1, tDelivered: 1, tFramework: nil)
        #expect(button.fields["t_framework"] == nil)
    }

    /// `007-controle-ipega` D-07: o modelo em `controller.connected` e o motivo de recusa.
    @Test func modeloNaConexaoEMotivoDeRecusa() {
        let connected = Self.sampleEvents.filter { $0.name == "controller.connected" }
        #expect(connected.map { $0.fields["model"] } == ["dualSense", "ipega"])
        #expect(fields("controller.ignored")["reason"] == "unsupported_model")
        #expect(Set(fields("controller.ignored").keys) == ["name", "productCategory", "reason"])
    }

    /// `008-iphone-teclado-remoto` RN-13, D-18: só motivos e contagens; nenhuma tecla, rótulo, código, token,
    /// endereço, nome de aparelho nem carimbo da página.
    @Test func eventosDoTecladoRemotoSemConteudo() {
        #expect(fields("remote.enabled") == ["port": 47810, "channelPort": 47811])
        #expect(fields("remote.disabled") == ["reason": "listener_failed"])
        #expect(fields("remote.connected") == ["resumed": true])
        #expect(fields("remote.rejected") == ["reason": "not_local"])
        #expect(fields("remote.watchdog") == ["held": 2])
        #expect(fields("remote.disconnected")
            == ["reason": "invalid_messages", "keys": 50, "suggestions": 3, "buttons": 12, "clicks": 4])
        #expect(fields("remote.mode") == ["mode": "pointer"])
        #expect(CenterMode.allCases.map(\.rawValue) == ["pointer", "compact", "full"])
        let forbidden: Set<String> = [
            "k", "key", "code", "token", "label", "address", "host", "name", "ts", "device",
            // Sugestões (`009-sugestao-de-palavras` RN-08, `interfaces/diagnostic-log.md` §3).
            "word", "words", "text", "context", "suggestion", "rev", "revision", "i", "index", "lang", "language", "visible",
            // Controle virtual (`010-joystick-virtual-iphone` RN-13, `interfaces/diagnostic-log.md` §4).
            "b", "button", "s", "stick", "f", "finger", "p", "phase", "m",
        ]
        for event in Self.remoteEvents {
            #expect(Self.allKeys(.object(event.fields)).isDisjoint(with: forbidden), "\(event.name)")
        }
        let rejectReasons: [RemoteRejectReason] = [.notLocal, .badOrigin, .badCode, .badToken, .busy, .codeRotated, .noIdentity, .hostMismatch, .expired]
        #expect(rejectReasons.map(\.rawValue) == [
            "not_local", "bad_origin", "bad_code", "bad_token", "busy", "code_rotated", "no_identity", "host_mismatch", "expired",
        ])
        let disconnectReasons: [RemoteDisconnectReason] = [.bye, .closed, .timeout, .invalidMessages, .replaced, .disabled]
        #expect(disconnectReasons.map(\.rawValue) == ["bye", "closed", "timeout", "invalid_messages", "replaced", "disabled"])
        #expect([RemoteDisabledReason.menu, .quit, .listenerFailed].map(\.rawValue) == ["menu", "quit", "listener_failed"])
    }
}
