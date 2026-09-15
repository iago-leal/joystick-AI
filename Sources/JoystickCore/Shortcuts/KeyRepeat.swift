import Foundation

/// Repetição enquanto o botão continua pressionado: 400 ms e depois a cada 50 ms (`action-mapping` RF-10).
///
/// Compartilhada pelas setas do protótipo de atalhos e pela navegação da paleta (`002-paleta-comandos` D-07).
public enum KeyRepeat {
    public static let delayMs = 400
    public static let intervalMs = 50

    public static var delay: DispatchTimeInterval { .milliseconds(delayMs) }
    public static var interval: DispatchTimeInterval { .milliseconds(intervalMs) }
}
