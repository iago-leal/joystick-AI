/// Leitura mínima dos relatórios HID de entrada do DualSense: só o bit do botão PS.
///
/// O macOS retém o PS antes do GameController (PM-2, P-07), e a PoC o lê do relatório bruto.
/// O buffer inclui o identificador do relatório no byte 0. O bloco comum de entrada começa em 1 por USB
/// e em 2 por Bluetooth, com os botões em `+7...+10`; o PS é o bit 0 do terceiro byte de botões.
public enum DualSenseReport {
    public static func homeButton(reportID: UInt32, bytes: [UInt8]) -> Bool? {
        let index: Int
        switch (reportID, bytes.count) {
        case (0x01, 64...): index = 1 + 9     // USB, relatório completo
        case (0x31, 12...): index = 2 + 9     // Bluetooth, relatório estendido
        case (0x01, 10): index = 7            // Bluetooth, relatório simplificado
        default: return nil
        }
        return bytes[index] & 0x01 != 0
    }
}
