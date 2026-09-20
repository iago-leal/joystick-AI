import Foundation

/// Alisa o arrasto que chega de fonte remota (`010-joystick-virtual-iphone` E-10).
///
/// O touchpad do controle entrega centenas de amostras por segundo em cadência estável, e aplicar cada delta na
/// chegada basta para o cursor parecer contínuo. O iPhone entrega no máximo uma amostra por quadro da página, e ainda
/// por Wi-Fi: elas chegam em rajada e em vazio, de modo que o mesmo tratamento transcreve o jitter da rede no cursor,
/// que anda aos pulos. O planador guarda o que falta andar e gasta uma fração a cada tick, convertendo chegada
/// irregular em movimento contínuo ao preço de uma constante de tempo curta.
///
/// A fração é exponencial, e não uma divisão em partes iguais, porque o número de amostras por vir é desconhecido:
/// cada tick anda a mesma proporção do que resta, o que absorve uma rajada nova sem recomeçar a conta.
public struct TouchGlide: Sendable {
    /// Em `timeConstant` segundos resta 1/e do caminho; 22 ms alisam a rajada sem que a mão perceba atraso.
    public static let timeConstant = 0.022
    /// Abaixo de meio ponto não há o que repartir: o resto sai inteiro e a série termina, em vez de arrastar uma
    /// cauda que nunca chega a zero.
    public static let floorPoints = 0.5

    private var pending = PointDelta.zero

    public init() {}

    public var isEmpty: Bool { pending.isZero }

    /// Quanto falta andar, para inspeção e teste.
    public var remaining: PointDelta { pending }

    public mutating func add(_ delta: PointDelta) {
        pending = pending + delta
    }

    /// Fração a andar neste tick; `.zero` quando não há nada pendente.
    public mutating func drain(dt: Double) -> PointDelta {
        guard !pending.isZero, dt > 0 else { return .zero }
        if hypot(pending.dx, pending.dy) <= Self.floorPoints {
            let rest = pending
            pending = .zero
            return rest
        }
        let step = pending * (1 - exp(-dt / Self.timeConstant))
        pending = PointDelta(dx: pending.dx - step.dx, dy: pending.dy - step.dy)
        return step
    }

    public mutating func reset() {
        pending = .zero
    }
}
