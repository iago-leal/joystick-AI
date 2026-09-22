/// Leitura mínima dos relatórios HID de entrada do DualShock 4: só o bit do botão PS (`012-controle-dualshock-4` D-04).
///
/// O macOS retém o PS antes do GameController também neste modelo (sonda P-01 de 2026-09-22, GameSir G8+ no modo
/// PlayStation por Bluetooth: nenhuma mudança em `buttonHome` com o PS pressionado), e o app o lê do relatório bruto,
/// como faz no DualSense. O buffer inclui o identificador do relatório no byte 0. O bloco comum de entrada tem os
/// analógicos em `+0…+3`, direcional e faces em `+4`, ombros, gatilhos, Share, Options e cliques dos analógicos em
/// `+5`, PS (bit 0), clique do touchpad (bit 1) e contador (bits 2 a 7) em `+6`, e os gatilhos analógicos em `+7` e
/// `+8`. O bloco começa no byte 1 em `0x01` (USB completo, 64 bytes, ou Bluetooth simplificado, 10 bytes) e no byte 3
/// em `0x11` (Bluetooth completo, 78 bytes); o PS fica, portanto, no byte 7 ou no byte 9.
///
/// Confirmado no aparelho só o `0x11` (P-02: o sistema já põe o controle no modo completo por Bluetooth, e o bit 0 do
/// byte 9 acompanhou cada pressão do PS). O `0x01` vem da literatura (`investigation.md` §3.2) e nunca chegou na sonda.
public enum DualShock4Report {
    public static func homeButton(reportID: UInt32, bytes: [UInt8]) -> Bool? {
        let index: Int
        switch (reportID, bytes.count) {
        case (0x01, 10...): index = 1 + 6     // USB completo ou Bluetooth simplificado
        case (0x11, 12...): index = 3 + 6     // Bluetooth completo
        default: return nil
        }
        return bytes[index] & 0x01 != 0
    }
}
