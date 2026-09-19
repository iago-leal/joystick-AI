import Foundation

/// Filtro de origem do teclado remoto (`008-iphone-teclado-remoto` D-07, RN-01): só a rede local.
///
/// Aceita IPv4 privado (10/8, 172.16/12, 192.168/16) e de enlace (169.254/16), IPv6 de enlace (`fe80::/10`) e
/// único local (`fc00::/7`), e IPv4 mapeado em IPv6 pelas mesmas regras. O laço local só passa com `allowLoopback`,
/// usado em teste. Trabalha sobre o texto do endereço, sem tocar a rede.
public enum LocalAddressPolicy {
    public static func isAllowed(_ address: String, allowLoopback: Bool = false) -> Bool {
        // Zona de enlace (`fe80::1%en0`) não faz parte do endereço.
        let text = address.split(separator: "%", maxSplits: 1).first.map(String.init) ?? address
        if let v4 = parseIPv4(text) {
            return isAllowedIPv4(v4, allowLoopback: allowLoopback)
        }
        guard let v6 = parseIPv6(text) else { return false }
        // ::ffff:a.b.c.d
        if v6[0..<10].allSatisfy({ $0 == 0 }), v6[10] == 0xFF, v6[11] == 0xFF {
            return isAllowedIPv4(Array(v6[12..<16]), allowLoopback: allowLoopback)
        }
        if v6[0] == 0xFE, v6[1] & 0xC0 == 0x80 { return true }
        if v6[0] & 0xFE == 0xFC { return true }
        if allowLoopback, v6[0..<15].allSatisfy({ $0 == 0 }), v6[15] == 1 { return true }
        return false
    }

    private static func isAllowedIPv4(_ b: [UInt8], allowLoopback: Bool) -> Bool {
        switch (b[0], b[1]) {
        case (10, _): return true
        case (172, 16...31): return true
        case (192, 168): return true
        case (169, 254): return true
        case (127, _): return allowLoopback
        default: return false
        }
    }

    static func parseIPv4(_ text: String) -> [UInt8]? {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return nil }
        var bytes: [UInt8] = []
        for part in parts {
            guard !part.isEmpty, part.count <= 3, part.allSatisfy(\.isASCII), part.allSatisfy(\.isNumber),
                  let value = UInt8(part) else { return nil }
            bytes.append(value)
        }
        return bytes
    }

    static func parseIPv6(_ text: String) -> [UInt8]? {
        var storage = in6_addr()
        guard text.contains(":"), inet_pton(AF_INET6, text, &storage) == 1 else { return nil }
        return withUnsafeBytes(of: storage) { Array($0) }
    }
}
