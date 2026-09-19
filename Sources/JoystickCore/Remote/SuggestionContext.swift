import Foundation

/// Idioma das sugestões, escolhido no seletor PT / EN da página (`009-sugestao-de-palavras` RN-05).
public enum SuggestionLanguage: String, CaseIterable, Sendable {
    case pt, en
}

/// Completar a palavra em composição ou prever a seguinte (RN-01, RN-12).
public enum SuggestionMode: String, Sendable {
    case complete, next
}

/// Tecla que encerra a palavra em composição sem descartar o contexto recente (RN-03).
public enum SuggestionBoundary: Sendable {
    case space, `return`, tab

    var character: Character {
        switch self {
        case .space: " "
        case .return: "\r"
        case .tab: "\t"
        }
    }
}

/// Entrada do contexto, alimentada pelo app depois de cada tecla injetada (D-02, D-03).
public enum SuggestionInput: Equatable, Sendable {
    /// Texto produzido pela tecla; espaço, `\r`, `\n` e `\t` valem como fronteira, e os demais controles são ignorados.
    case text(String)
    case backspace
    case boundary(SuggestionBoundary)
    case discard
}

/// Pedido ao motor de previsão: o contexto recente, com o cursor no fim.
public struct SuggestionQuery: Equatable, Sendable {
    public let text: String
    public let mode: SuggestionMode
    public let revision: UInt64

    public init(text: String, mode: SuggestionMode, revision: UInt64) {
        self.text = text
        self.mode = mode
        self.revision = revision
    }
}

/// Máquina pura das sugestões de palavras (`009-sugestao-de-palavras` D-03, D-04): guarda em memória o contexto recente
/// montado pelas teclas do iPhone, decide o que pedir ao motor, filtra os candidatos e calcula o texto a digitar na
/// aceitação.
///
/// A palavra em composição e a última fronteira derivam do contexto: apagar um espaço devolve a palavra anterior à
/// composição, como acontece no aplicativo em foco. Nada daqui vai ao log nem a disco (RN-07, RN-08).
public struct SuggestionContext: Sendable {
    public static let maxContext = 200
    public static let maxWords = 3
    public static let maxWordLength = 48
    /// Sinais de abertura que ficam fora da palavra em composição quando a iniciam.
    static let openingSigns: Set<Character> = ["(", "[", "\"", "'"]

    /// Contexto recente, com no máximo `maxContext` caracteres.
    public private(set) var context = ""
    /// Sobe a cada entrada; respostas e toques de revisão velha são recusados (RN-09).
    public private(set) var revision: UInt64 = 0
    /// Sugestões aceitas na sessão, para `remote.disconnected` (D-13).
    public private(set) var accepted = 0

    public init() {}

    /// Palavra em composição: o que vem depois da última fronteira, sem os sinais de abertura iniciais.
    public var word: String {
        String(trailingRun(of: context).drop { Self.openingSigns.contains($0) })
    }

    /// Fronteira que precede a palavra em composição; `nil` com o contexto vazio ou sem fronteira dentro dele.
    public var lastBoundary: SuggestionBoundary? {
        let run = trailingRun(of: context)
        guard let index = context.index(context.endIndex, offsetBy: -run.count - 1, limitedBy: context.startIndex)
        else { return nil }
        return Self.boundary(context[index])
    }

    public mutating func apply(_ input: SuggestionInput) {
        revision &+= 1
        switch input {
        case .text(let text):
            for character in text {
                if let boundary = Self.boundary(character) {
                    context.append(boundary.character)
                } else if !Self.isControl(character) {
                    context.append(character)
                }
            }
            trim()
        case .backspace:
            if context.isEmpty { return }
            context.removeLast()
        case .boundary(let boundary):
            context.append(boundary.character)
            trim()
        case .discard:
            context = ""
        }
    }

    /// Pedido ao motor, ou `nil` quando a faixa deve ficar vazia: oculta (RN-14), sem contexto, palavra com algo além de
    /// letras (RN-13), ou sem palavra e sem espaço que tenha encerrado uma palavra só de letras (RN-12).
    public func query(visible: Bool) -> SuggestionQuery? {
        guard visible, !context.isEmpty else { return nil }
        let word = word
        if !word.isEmpty {
            guard Self.isLetters(word) else { return nil }
            return SuggestionQuery(text: context, mode: .complete, revision: revision)
        }
        guard context.last == " " else { return nil }
        let previous = trailingRun(of: context.dropLast()).drop { Self.openingSigns.contains($0) }
        guard !previous.isEmpty, Self.isLetters(previous) else { return nil }
        return SuggestionQuery(text: context, mode: .next, revision: revision)
    }

    /// Reduz os candidatos do motor a até três palavras (D-04), ou `nil` se o contexto mudou desde o pedido.
    ///
    /// No modo `complete`, a primeira letra segue a caixa da digitada (RN-04) e só ficam as palavras que estendem
    /// exatamente a palavra em composição, de modo que aceitar é sempre acrescentar texto. No modo `next`, vale a caixa
    /// do motor.
    public func filter(_ candidates: [String], for query: SuggestionQuery) -> [String]? {
        guard query.revision == revision else { return nil }
        let word = word
        var words: [String] = []
        for candidate in candidates {
            var text = candidate
            while text.last == " " { text.removeLast() }
            if query.mode == .complete {
                text = Self.matchingCase(text, of: word)
                guard text.count > word.count, text.hasPrefix(word) else { continue }
            }
            guard !text.isEmpty, text.count <= Self.maxWordLength, Self.isLetters(text), !words.contains(text)
            else { continue }
            words.append(text)
            if words.count == Self.maxWords { break }
        }
        return words
    }

    /// Texto a digitar ao aceitar `word`: o que falta da palavra em composição, seguido de espaço (RN-04). `nil` se o
    /// contexto mudou ou se a palavra não estende a em composição; aceita, o contexto recebe o texto e a contagem sobe.
    public mutating func accept(_ word: String, revision: UInt64) -> String? {
        let current = self.word
        guard revision == self.revision, word.count > current.count, word.hasPrefix(current), Self.isLetters(word)
        else { return nil }
        let typed = String(word.dropFirst(current.count)) + " "
        apply(.text(typed))
        accepted += 1
        return typed
    }

    // MARK: - Auxiliares

    private mutating func trim() {
        if context.count > Self.maxContext { context = String(context.suffix(Self.maxContext)) }
    }

    private func trailingRun<S: StringProtocol>(of text: S) -> S.SubSequence {
        guard let index = text.lastIndex(where: { Self.boundary($0) != nil }) else { return text[...] }
        return text[text.index(after: index)...]
    }

    static func boundary(_ character: Character) -> SuggestionBoundary? {
        switch character {
        case " ": .space
        case "\r", "\n", "\r\n": .return
        case "\t": .tab
        default: nil
        }
    }

    static func isControl(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { $0.properties.generalCategory == .control }
    }

    static func isLetters<S: StringProtocol>(_ text: S) -> Bool {
        !text.isEmpty && text.allSatisfy(\.isLetter)
    }

    /// Aplica à primeira letra de `text` a caixa da primeira letra de `typed`.
    static func matchingCase(_ text: String, of typed: String) -> String {
        guard let first = typed.first, let head = text.first else { return text }
        let rest = text.dropFirst()
        if first.isUppercase { return head.uppercased() + rest }
        if first.isLowercase { return head.lowercased() + rest }
        return text
    }
}
