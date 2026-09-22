import Foundation

/// Filtro de rajadas de botão (`BUG-20260922-33HN`).
///
/// O GameSir G8+ em modo DualShock 4 alterna o bit dos botões de membrana no relatório HID a cada 15 a 100 ms
/// enquanto o botão é segurado com pressão variável (sonda de 2026-09-22, sem o app), e cada borda chegava ao
/// destino como uma pressão nova. O filtro deixa o `down` passar na hora e retém o `up` por `windowNs`: se outro
/// `down` chega antes de a janela vencer, o `up` retido é cancelado e esse `down` é descartado, de modo que a rajada
/// inteira vira uma única pressão. Quem agenda o `flush` é o app; aqui não há relógio nem fila.
///
/// Janela de 120 ms pelas medições: rajadas entre 15 e 100 ms; pressões humanas distintas a partir de 150 ms. Vale só
/// para o `dualShock4` e para os seis botões que oscilaram na sonda. Ombros, gatilhos, cliques dos analógicos, clique
/// do touchpad, PS e direcional não oscilam, e R1 e o clique do touchpad são botões de apontamento, cujo duplo clique
/// (RN-09) não pode ter o `up` retido.
public struct ButtonDebouncer: Sendable {
    public static let windowNs: UInt64 = 120_000_000
    public static let filteredButtons: Set<ButtonID> = [.cross, .circle, .square, .triangle, .options, .create]

    private var pendingUp: [ButtonID: UInt64] = [:]

    public init() {}

    public static func applies(to button: ButtonID, model: ControllerModel) -> Bool {
        model == .dualShock4 && filteredButtons.contains(button)
    }

    /// Botões com `up` retido, em ordem de `ButtonID`.
    public var pending: [ButtonID] { pendingUp.keys.sorted() }

    /// Borda de pressionar. Devolve `false` quando havia `up` retido: a borda é ruído da rajada, e o `up` é cancelado.
    public mutating func press(_ button: ButtonID, at t: UInt64) -> Bool {
        pendingUp.removeValue(forKey: button) == nil
    }

    /// Borda de soltar, que fica retida. Devolve `true` quando o chamador deve agendar o `flush` em `t + windowNs`, e
    /// `false` se já havia `up` retido para o botão.
    public mutating func release(_ button: ButtonID, at t: UInt64) -> Bool {
        guard pendingUp[button] == nil else { return false }
        pendingUp[button] = t
        return true
    }

    /// Libera o `up` retido quando a janela venceu; `false` se não há `up` retido ou se ainda não venceu.
    public mutating func flush(_ button: ButtonID, at t: UInt64) -> Bool {
        guard let since = pendingUp[button], t >= since + Self.windowNs else { return false }
        pendingUp[button] = nil
        return true
    }

    /// Descarta todos os `up` retidos (desconexão) e devolve os botões em ordem de `ButtonID`.
    public mutating func cancelAll() -> [ButtonID] {
        let buttons = pending
        pendingUp.removeAll()
        return buttons
    }
}
