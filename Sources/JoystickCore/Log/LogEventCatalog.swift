import Foundation

public enum PermissionTrigger: String, Sendable { case startup, poll }
public enum TouchSource: String, Sendable { case touchState, zeroTransition = "zero_transition" }
public enum TouchBoundary: String, Sendable { case began, ended }
public enum PostedKind: String, Sendable { case move, drag, scroll, down, up }
public enum PostSource: String, Sendable { case touch, stickOnset = "stick_onset", button }
public enum TerminationReason: String, Sendable { case quit, sigterm, sigint, sighup }
public enum ShortcutsTrigger: String, Sendable { case startup, external, editor, restore }
public enum ShortcutsSource: String, Sendable { case defaults, file }
public enum ShortcutsDefaultReason: String, Sendable { case fileMissing = "file_missing", sectionMissing = "section_missing" }
public enum EditorOpenSource: String, Sendable { case menu, palette, alert }
public enum EditorCloseOutcome: String, Sendable { case clean, saved, discarded }
public enum EditorConflictChoice: String, Sendable { case reload, keep, pending }

/// Tela listada em `targets.screens`, numerada a partir de 1.
public struct ScreenListing: Equatable, Sendable {
    public var index: Int
    public var name: String
    public var widthPt: Int
    public var heightPt: Int
    public var backingScale: Double

    public init(index: Int, name: String, widthPt: Int, heightPt: Int, backingScale: Double) {
        self.index = index
        self.name = name
        self.widthPt = widthPt
        self.heightPt = heightPt
        self.backingScale = backingScale
    }
}

/// Fábricas tipadas de todos os eventos de `diagnostic-log.md` §3 (D-18, RN-12).
///
/// Nenhuma fábrica aceita coordenadas do cursor, deltas, posições do toque ou valores de eixo.
public enum LogEventCatalog {
    public static func sessionStart(appVersion: String, macOS: String, pid: Int32, debug: Bool, args: [String], signing: JSONValue) -> LogEvent {
        LogEvent("session.start", level: .info, fields: [
            "logSchema": 1,
            "appVersion": .string(appVersion),
            "macOS": .string(macOS),
            "pid": .int(Int64(pid)),
            "debug": .bool(debug),
            "args": .array(args.map(JSONValue.string)),
            "signing": signing,
        ])
    }

    public static func permissionsStatus(postEvent: Bool, listenEvent: Bool, trigger: PermissionTrigger) -> LogEvent {
        LogEvent("permissions.status", level: .info, fields: [
            "postEvent": .bool(postEvent), "listenEvent": .bool(listenEvent), "trigger": .string(trigger.rawValue),
        ])
    }

    public static func permissionsGuidance(message: String) -> LogEvent {
        LogEvent("permissions.guidance", level: .warn, fields: ["message": .string(message)])
    }

    /// Eventos `config.*` correspondentes ao resultado da leitura (`config-pointer.md` §3).
    public static func config(_ result: ConfigLoadResult) -> [LogEvent] {
        var events: [LogEvent] = []
        var invalidOrUnreadable = false
        for issue in result.issues {
            switch issue {
            case .invalidJSON(let line, let message):
                invalidOrUnreadable = true
                var fields: [String: JSONValue] = ["message": .string(message)]
                if let line { fields["line"] = .int(Int64(line)) }
                events.append(LogEvent("config.invalid_json", level: .error, fields: fields))
            case .unreadable(let message):
                invalidOrUnreadable = true
                events.append(LogEvent("config.unreadable", level: .error, fields: ["message": .string(message)]))
            case .valueRejected: break
            }
        }
        if !invalidOrUnreadable {
            var fields: [String: JSONValue] = ["status": .string(result.status.rawValue), "settings": result.settings.jsonValue]
            if let reason = result.reason { fields["reason"] = .string(reason) }
            events.append(LogEvent("config.loaded", level: .info, fields: fields))
        }
        for issue in result.issues {
            if case .valueRejected(let field, let rejected, let min, let max, let defaultValue) = issue {
                events.append(LogEvent("config.value_rejected", level: .warn, fields: [
                    "field": .string(field),
                    "rejected": rejected,
                    "min": min.map(JSONValue.double) ?? .null,
                    "max": max.map(JSONValue.double) ?? .null,
                    "default": defaultValue,
                ]))
            }
        }
        return events
    }

    public static func displaysChanged(count: Int) -> LogEvent {
        LogEvent("displays.changed", level: .info, fields: ["count": .int(Int64(count))])
    }

    public static func cursorReclamped() -> LogEvent {
        LogEvent("cursor.reclamped", level: .info)
    }

    /// `charge` e `chargeState` são **omitidos** quando a carga é indisponível, e não gravados como zero
    /// (`011-bateria-e-cursor-no-menu`, `interfaces/diagnostic-log.md` §2): gravar zero tornaria indistinguíveis o
    /// controle descarregado e o controle que não conta quanta carga tem, a mesma confusão que D-02 evita na tela.
    public static func controllerConnected(_ info: ControllerInfo, charge: ControllerCharge?, tArrival: UInt64) -> LogEvent {
        var fields: [String: JSONValue] = [
            "id": .string(info.id.uuidString),
            "name": .string(info.name),
            "connection": .string(info.connection.rawValue),
            "atStartup": .bool(info.atStartup),
            "model": .string(info.model.rawValue),
            "t_arrival": .uint(tArrival),
        ]
        if let charge, case .known(let percent, _, _) = ChargeDisplay.decide(hasActiveController: true, charge: charge) {
            fields["charge"] = .int(Int64(percent))
            fields["chargeState"] = .string(charge.state.rawValue)
        }
        return LogEvent("controller.connected", level: .info, fields: fields)
    }

    /// Emitido apenas na mudança de faixa de dez ou de estado, nunca a cada leitura; quem decide é a
    /// `ChargeLogPolicy` (D-09, RN-12).
    public static func controllerCharge(id: UUID, percent: Int, state: ControllerChargeState) -> LogEvent {
        LogEvent("controller.charge", level: .info, fields: [
            "id": .string(id.uuidString),
            "charge": .int(Int64(percent)),
            "state": .string(state.rawValue),
        ])
    }

    /// Ciclo do menu do ícone da barra (`011-bateria-e-cursor-no-menu` E-04, RF-13).
    ///
    /// A forma original deste evento, com `released`, `resynced` e `timerRestarted`, supunha estado retido no fim
    /// do ciclo, hipótese que as sondas P-01, P-02, P-04 e P-05 falsificaram: nada fica retido, o sistema apenas
    /// toma os analógicos enquanto o menu rastreia. O que interessa registrar passou a ser se o controle
    /// conseguiu navegar o menu, e por quanto tempo ele ficou aberto.
    public static func menuCycle(keys: Int, durationMs: Int) -> LogEvent {
        LogEvent("menu.cycle", level: .info, fields: [
            "keys": .int(Int64(keys)),
            "durationMs": .int(Int64(durationMs)),
        ])
    }

    public static func controllerIgnored(name: String, productCategory: String, reason: String) -> LogEvent {
        LogEvent("controller.ignored", level: .info, fields: [
            "name": .string(name), "productCategory": .string(productCategory), "reason": .string(reason),
        ])
    }

    public static func controllerQueued(id: UUID, position: Int) -> LogEvent {
        LogEvent("controller.queued", level: .info, fields: ["id": .string(id.uuidString), "position": .int(Int64(position))])
    }

    public static func controllerDisconnected(id: UUID, tArrival: UInt64) -> LogEvent {
        LogEvent("controller.disconnected", level: .info, fields: ["id": .string(id.uuidString), "t_arrival": .uint(tArrival)])
    }

    public static func controllerElements(names: [String], touchpads: [String]) -> LogEvent {
        LogEvent("controller.elements", level: .debug, fields: [
            "names": .array(names.map(JSONValue.string)), "touchpads": .array(touchpads.map(JSONValue.string)),
        ])
    }

    public static func controllerTouchSource(id: UUID, source: TouchSource) -> LogEvent {
        LogEvent("controller.touch_source", level: .info, fields: ["id": .string(id.uuidString), "source": .string(source.rawValue)])
    }

    public static func controllerGestureSuppression(elements: [String], message: String) -> LogEvent {
        LogEvent("controller.gesture_suppression", level: .info, fields: [
            "elements": .array(elements.map(JSONValue.string)), "message": .string(message),
        ])
    }

    /// Pedido do relatório de recurso `0x05` a um DualSense por Bluetooth, que o tira do relatório simplificado sem touchpad.
    /// `result` é `ok` ou o código `IOReturn` em hexadecimal.
    public static func controllerExtendedReport(transport: ConnectionType, result: String) -> LogEvent {
        LogEvent("controller.extended_report", level: .info, fields: [
            "transport": .string(transport.rawValue), "result": .string(result),
        ])
    }

    public static func controllerError(message: String) -> LogEvent {
        LogEvent("controller.error", level: .error, fields: ["message": .string(message)])
    }

    public static func inputButton(_ button: ButtonID, phase: ButtonPhase, synthetic: Bool, tArrival: UInt64, tDelivered: UInt64, tFramework: Double?) -> LogEvent {
        var fields: [String: JSONValue] = [
            "button": .string(button.rawValue),
            "phase": .string(phase.rawValue),
            "synthetic": .bool(synthetic),
            "t_arrival": .uint(tArrival),
            "t_delivered": .uint(tDelivered),
        ]
        if let tFramework { fields["t_framework"] = .double(tFramework) }
        return LogEvent("input.button", level: .debug, fields: fields)
    }

    public static func inputTouch(finger: Int, phase: TouchBoundary, tArrival: UInt64, tDelivered: UInt64) -> LogEvent {
        LogEvent("input.touch", level: .debug, fields: [
            "finger": .int(Int64(finger)), "phase": .string(phase.rawValue), "t_arrival": .uint(tArrival), "t_delivered": .uint(tDelivered),
        ])
    }

    public static func touchRawTransition(finger: Int, toZero: Bool) -> LogEvent {
        LogEvent("touch.raw_transition", level: .debug, fields: ["finger": .int(Int64(finger)), "toZero": .bool(toZero)])
    }

    public static func pointerPosted(kind: PostedKind, button: MouseButton?, source: PostSource, clickState: Int?, tArrival: UInt64, tPosted: UInt64) -> LogEvent {
        var fields: [String: JSONValue] = [
            "kind": .string(kind.rawValue), "source": .string(source.rawValue), "t_arrival": .uint(tArrival), "t_posted": .uint(tPosted),
        ]
        if let button { fields["button"] = .string(button.rawValue) }
        if let clickState { fields["clickState"] = .int(Int64(clickState)) }
        return LogEvent("pointer.posted", level: .debug, fields: fields)
    }

    public static func injectionSuspended(heldButtons: [MouseButton]) -> LogEvent {
        LogEvent("pointer.injection_suspended", level: .warn, fields: ["heldButtons": .array(heldButtons.map { .string($0.rawValue) })])
    }

    public static func injectionResumed(heldButtons: [MouseButton]) -> LogEvent {
        LogEvent("pointer.injection_resumed", level: .info, fields: ["heldButtons": .array(heldButtons.map { .string($0.rawValue) })])
    }

    public static func targetsScreens(_ screens: [ScreenListing]) -> LogEvent {
        LogEvent("targets.screens", level: .info, fields: [
            "screens": .array(screens.map {
                .object([
                    "index": .int(Int64($0.index)), "name": .string($0.name),
                    "widthPt": .int(Int64($0.widthPt)), "heightPt": .int(Int64($0.heightPt)), "backingScale": .double($0.backingScale),
                ])
            }),
        ])
    }

    public static func targetsStarted(environment: TargetEnvironment, seed: UInt64) -> LogEvent {
        LogEvent("targets.started", level: .info, fields: ["env": .string(environment.rawValue), "seed": .uint(seed)])
    }

    public static func targetsFinished(environment: TargetEnvironment, seed: UInt64, complete: Bool, abortReason: AbortReason?, file: String) -> LogEvent {
        var fields: [String: JSONValue] = [
            "env": .string(environment.rawValue), "seed": .uint(seed), "complete": .bool(complete), "file": .string(file),
        ]
        if let abortReason { fields["abortReason"] = .string(abortReason.rawValue) }
        return LogEvent("targets.finished", level: .info, fields: fields)
    }

    public static func targetsInvalidArgs(message: String) -> LogEvent {
        LogEvent("targets.invalid_args", level: .warn, fields: ["message": .string(message)])
    }

    public static func targetsScreenFallback(message: String) -> LogEvent {
        LogEvent("targets.screen_fallback", level: .warn, fields: ["message": .string(message)])
    }

    public static func targetsWriteFailed(message: String, payload: String) -> LogEvent {
        LogEvent("targets.write_failed", level: .error, fields: ["message": .string(message), "payload": .string(payload)])
    }

    public static func appTerminating(reason: TerminationReason, releasedButtons: [MouseButton]) -> LogEvent {
        LogEvent("app.terminating", level: .info, fields: [
            "reason": .string(reason.rawValue), "releasedButtons": .array(releasedButtons.map { .string($0.rawValue) }),
        ])
    }

    // Paleta de comandos (`002-paleta-comandos/interfaces/diagnostic-log.md` §2): índices a partir de 1, nunca o texto.

    public static func paletteOpened(selection: Int) -> LogEvent {
        LogEvent("palette.opened", level: .info, fields: ["selection": .int(Int64(selection))])
    }

    public static func paletteConfirmed(index: Int, enter: Bool) -> LogEvent {
        LogEvent("palette.confirmed", level: .info, fields: ["index": .int(Int64(index)), "enter": .bool(enter)])
    }

    public static func paletteClosed(reason: PaletteCloseReason) -> LogEvent {
        LogEvent("palette.closed", level: .info, fields: ["reason": .string(reason.rawValue)])
    }

    public static func paletteBlocked() -> LogEvent {
        LogEvent("palette.blocked", level: .info, fields: ["reason": "targets"])
    }

    public static func paletteInvalidArgs(message: String) -> LogEvent {
        LogEvent("palette.invalid_args", level: .warn, fields: ["message": .string(message)])
    }

    // Atalhos configuráveis (`003-editor-atalhos/interfaces/diagnostic-log.md` §2): caminho, linha, regra e contagens,
    // nunca texto, rótulo, nome de tecla nem acorde (RN-14).

    public static func shortcutsLoaded(trigger: ShortcutsTrigger, source: ShortcutsSource, reason: ShortcutsDefaultReason?,
                                       modifiers: [ButtonID], items: Int) -> LogEvent {
        var fields: [String: JSONValue] = [
            "trigger": .string(trigger.rawValue),
            "source": .string(source.rawValue),
            "modifiers": .array(modifiers.sorted().map { .string($0.rawValue) }),
            "items": .int(Int64(items)),
        ]
        if let reason { fields["reason"] = .string(reason.rawValue) }
        return LogEvent("shortcuts.loaded", level: .info, fields: fields)
    }

    public static func shortcutsUnchanged(trigger: ShortcutsTrigger) -> LogEvent {
        LogEvent("shortcuts.unchanged", level: .debug, fields: ["trigger": .string(trigger.rawValue)])
    }

    public static func shortcutsInvalid(trigger: ShortcutsTrigger, rule: ShortcutIssue.Rule, path: String?, line: Int?) -> LogEvent {
        var fields: [String: JSONValue] = ["trigger": .string(trigger.rawValue), "rule": .string(rule.rawValue)]
        if let path { fields["path"] = .string(path) }
        if let line { fields["line"] = .int(Int64(line)) }
        return LogEvent("shortcuts.invalid", level: .error, fields: fields)
    }

    public static func shortcutsFileRemoved() -> LogEvent {
        LogEvent("shortcuts.file_removed", level: .info)
    }

    public static func shortcutsSaved(created: Bool, backup: Bool) -> LogEvent {
        LogEvent("shortcuts.saved", level: .info, fields: ["created": .bool(created), "backup": .bool(backup)])
    }

    /// `message` traz só o caminho e o erro do sistema.
    public static func shortcutsSaveFailed(message: String) -> LogEvent {
        LogEvent("shortcuts.save_failed", level: .error, fields: ["message": .string(message)])
    }

    public static func shortcutsRestored() -> LogEvent {
        LogEvent("shortcuts.restored", level: .info)
    }

    /// `layer` é `base` ou o botão modificador cuja camada valeu (`003-editor-atalhos` D-14).
    public static func shortcutTriggered(button: ButtonID, layer: ButtonID?, type: TriggerActionType) -> LogEvent {
        LogEvent("shortcut.triggered", level: .info, fields: [
            "button": .string(button.rawValue), "layer": .string(layer?.rawValue ?? "base"), "type": .string(type.rawValue),
        ])
    }

    // Editor de atalhos (`003-editor-atalhos/interfaces/diagnostic-log.md` §2).

    public static func editorOpened(source: EditorOpenSource) -> LogEvent {
        LogEvent("editor.opened", level: .info, fields: ["source": .string(source.rawValue)])
    }

    public static func editorClosed(outcome: EditorCloseOutcome) -> LogEvent {
        LogEvent("editor.closed", level: .info, fields: ["outcome": .string(outcome.rawValue)])
    }

    public static func editorConflict(choice: EditorConflictChoice) -> LogEvent {
        LogEvent("editor.conflict", level: .warn, fields: ["choice": .string(choice.rawValue)])
    }

    public static func editorIdentify(on: Bool) -> LogEvent {
        LogEvent("editor.identify", level: .info, fields: ["on": .bool(on)])
    }

    /// A janela não se tornou ativa após o pedido de abertura (sonda P-01).
    public static func editorActivationFailed() -> LogEvent {
        LogEvent("editor.activation_failed", level: .warn)
    }

    /// A figura do controle não pôde ser exibida; só o motivo, sem conteúdo
    /// (`004-figura-controle-web/interfaces/diagnostic-log.md` §2, D-15, RN-12).
    public static func editorFigureUnavailable(reason: FigureFailureReason) -> LogEvent {
        LogEvent("editor.figure_unavailable", level: .warn, fields: ["reason": .string(reason.rawValue)])
    }

    public static func logDebugSuspended(sizeBytes: Int) -> LogEvent {
        LogEvent("log.debug_suspended", level: .warn, fields: ["sizeBytes": .int(Int64(sizeBytes))])
    }

    // Teclado remoto (`008-iphone-teclado-remoto/interfaces/diagnostic-log.md` §2, D-18, RN-13): só motivos e
    // contagens; nunca tecla, rótulo, código de pareamento, token, endereço nem nome do aparelho.

    public static func remoteEnabled(port: UInt16, channelPort: UInt16) -> LogEvent {
        LogEvent("remote.enabled", level: .info, fields: ["port": .int(Int64(port)), "channelPort": .int(Int64(channelPort))])
    }

    public static func remoteDisabled(reason: RemoteDisabledReason) -> LogEvent {
        LogEvent("remote.disabled", level: .info, fields: ["reason": .string(reason.rawValue)])
    }

    public static func remoteConnected(resumed: Bool) -> LogEvent {
        LogEvent("remote.connected", level: .info, fields: ["resumed": .bool(resumed)])
    }

    public static func remoteRejected(reason: RemoteRejectReason) -> LogEvent {
        LogEvent("remote.rejected", level: .warn, fields: ["reason": .string(reason.rawValue)])
    }

    /// `held`: teclas e modificadores soltos pelo vigia (D-11).
    public static func remoteWatchdog(held: Int) -> LogEvent {
        LogEvent("remote.watchdog", level: .warn, fields: ["held": .int(Int64(held))])
    }

    /// `keys`: teclas pressionadas na sessão, sem distinguir quais (D-18).
    /// `suggestions`: sugestões aceitas na sessão, sem nenhuma palavra (`009-sugestao-de-palavras` D-13, RN-08).
    /// `buttons` e `clicks`: botões do controle virtual pressionados na sessão e cliques de mouse vindos deles, sem
    /// nome de botão, posição de analógico nem coordenada de dedo (`010-joystick-virtual-iphone` D-10).
    public static func remoteDisconnected(
        reason: RemoteDisconnectReason, keys: Int, suggestions: Int, buttons: Int, clicks: Int
    ) -> LogEvent {
        LogEvent("remote.disconnected", level: .info, fields: [
            "reason": .string(reason.rawValue), "keys": .int(Int64(keys)), "suggestions": .int(Int64(suggestions)),
            "buttons": .int(Int64(buttons)), "clicks": .int(Int64(clicks)),
        ])
    }

    /// Estado do bloco central da página, a cada troca confirmada (`010-joystick-virtual-iphone` D-10).
    /// Só o estado: nada do que o usuário fez dentro dele.
    public static func remoteMode(_ mode: CenterMode) -> LogEvent {
        LogEvent("remote.mode", level: .info, fields: ["mode": .string(mode.rawValue)])
    }
}

public enum RemoteDisabledReason: String, Sendable { case menu, quit, listenerFailed = "listener_failed" }

public enum RemoteRejectReason: String, Sendable {
    case notLocal = "not_local", badOrigin = "bad_origin", badCode = "bad_code", badToken = "bad_token", busy
    case codeRotated = "code_rotated", noIdentity = "no_identity", hostMismatch = "host_mismatch", expired
}

public enum RemoteDisconnectReason: String, Sendable {
    case bye, closed, timeout, invalidMessages = "invalid_messages", replaced, disabled
}
