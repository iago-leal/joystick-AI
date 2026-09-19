import Foundation

/// Estado de modificadores em que um rótulo é calculado (`008-iphone-teclado-remoto` D-12).
public enum KeyLabelState: String, CaseIterable, Codable, Sendable {
    case plain, shift, option, shiftOption
}

/// Rótulos de uma tecla nos quatro estados, com os estados em que ela é tecla morta (´, ~, ^ e similares).
public struct KeyLabels: Equatable, Codable, Sendable {
    public var plain: String
    public var shift: String
    public var option: String
    public var shiftOption: String
    public var dead: Set<KeyLabelState>

    public init(plain: String, shift: String, option: String, shiftOption: String, dead: Set<KeyLabelState> = []) {
        self.plain = plain
        self.shift = shift
        self.option = option
        self.shiftOption = shiftOption
        self.dead = dead
    }

    public func label(_ state: KeyLabelState) -> String {
        switch state {
        case .plain: plain
        case .shift: shift
        case .option: option
        case .shiftOption: shiftOption
        }
    }
}

/// Rótulos por código virtual, calculados pelo app a partir da fonte de entrada ativa e enviados à página (D-12).
///
/// Só entram teclas que produzem caractere; as demais (Esc, Tab, setas, modificadores) a página rotula por nome fixo.
public struct KeyLabelTable: Equatable, Codable, Sendable {
    public var labels: [UInt16: KeyLabels]

    public init(labels: [UInt16: KeyLabels] = [:]) {
        self.labels = labels
    }

    public subscript(code: UInt16) -> KeyLabels? { labels[code] }
}
