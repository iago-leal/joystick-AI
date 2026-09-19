import Foundation
import JoystickCore
import Network
import Security
import SystemConfiguration

/// Identidade TLS do teclado remoto, criada por `scripts/create-remote-keyboard-identity.sh`
/// (`008-iphone-teclado-remoto` D-03, `interfaces/identidade-tls.md` §2). O app só a lê.
enum RemoteKeyboardIdentity {
    static let label = "JoystickAI Remote Keyboard"

    /// Certificado da autoridade, enviado ao iPhone por AirDrop (D-04).
    static var authorityCertificateURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/joystick-ai/remote-keyboard/JoystickAI-Local-CA.cer")
    }

    /// `<LocalHostName>.local`, ou `nil` se o Mac não tiver nome local.
    static var localHost: String? {
        guard let name = SCDynamicStoreCopyLocalHostName(nil) as String?, !name.isEmpty else { return nil }
        return name + ".local"
    }

    enum Failure: Error {
        case noIdentity, hostMismatch, expired

        var reason: RemoteRejectReason {
            switch self {
            case .noIdentity: .noIdentity
            case .hostMismatch: .hostMismatch
            case .expired: .expired
            }
        }

        /// Linha do menu (D-14).
        var message: String {
            switch self {
            case .noIdentity: "Identidade do teclado remoto ausente"
            case .hostMismatch: "Identidade do teclado remoto para outro nome de Mac"
            case .expired: "Identidade do teclado remoto vencida"
            }
        }
    }

    struct Loaded {
        let identity: SecIdentity
        let host: String

        /// TLS 1.2 ou superior com a identidade (`interfaces/remote-keyboard-protocol.md` §1).
        func tlsOptions() -> NWProtocolTLS.Options {
            let options = NWProtocolTLS.Options()
            if let secIdentity = sec_identity_create(identity) {
                sec_protocol_options_set_local_identity(options.securityProtocolOptions, secIdentity)
            }
            sec_protocol_options_set_min_tls_protocol_version(options.securityProtocolOptions, .TLSv12)
            return options
        }
    }

    /// Busca a identidade e confere o nome do Mac e a validade. Pode pedir autorização ao chaveiro (sonda P-02).
    static func load(now: Date = Date()) -> Result<Loaded, Failure> {
        guard let host = localHost else { return .failure(.noIdentity) }
        let candidates = identities()
        guard !candidates.isEmpty else { return .failure(.noIdentity) }
        var sawOtherHost = false
        var sawExpired = false
        for identity in candidates {
            var certificate: SecCertificate?
            guard SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess, let certificate else { continue }
            guard dnsNames(certificate).contains(where: { $0.caseInsensitiveCompare(host) == .orderedSame }) else {
                sawOtherHost = true
                continue
            }
            if let notAfter = notAfter(certificate), notAfter <= now {
                sawExpired = true
                continue
            }
            return .success(Loaded(identity: identity, host: host))
        }
        if sawExpired { return .failure(.expired) }
        return .failure(sawOtherHost ? .hostMismatch : .noIdentity)
    }

    /// Identidades com o rótulo; na falta, as emitidas pela autoridade cujo certificado está em Application Support
    /// (o rótulo do PKCS#12 vai à chave, e nem sempre ao certificado).
    private static func identities() -> [SecIdentity] {
        let byLabel = query([kSecAttrLabel as String: label])
        if !byLabel.isEmpty { return byLabel }
        guard let data = try? Data(contentsOf: authorityCertificateURL),
              let authority = SecCertificateCreateWithData(nil, data as CFData),
              let authoritySubject = SecCertificateCopyNormalizedSubjectSequence(authority) as Data?
        else { return [] }
        return query([:]).filter { identity in
            var certificate: SecCertificate?
            guard SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess, let certificate,
                  let issuer = SecCertificateCopyNormalizedIssuerSequence(certificate) as Data?
            else { return false }
            return issuer == authoritySubject
        }
    }

    private static func query(_ extra: [String: Any]) -> [SecIdentity] {
        var attributes: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnRef as String: true,
        ]
        attributes.merge(extra) { _, new in new }
        var result: CFTypeRef?
        guard SecItemCopyMatching(attributes as CFDictionary, &result) == errSecSuccess,
              let items = result as? [Any] else { return [] }
        return items.compactMap { item in
            CFGetTypeID(item as CFTypeRef) == SecIdentityGetTypeID() ? (item as! SecIdentity) : nil
        }
    }

    /// Nomes DNS do SAN; na falta dele, o nome comum.
    static func dnsNames(_ certificate: SecCertificate) -> [String] {
        var names: [String] = []
        if let values = SecCertificateCopyValues(certificate, [kSecOIDSubjectAltName] as CFArray, nil) as? [String: Any],
           let san = values[kSecOIDSubjectAltName as String] as? [String: Any],
           let entries = san[kSecPropertyKeyValue as String] as? [[String: Any]] {
            for entry in entries where (entry[kSecPropertyKeyLabel as String] as? String) == "DNS Name" {
                if let name = entry[kSecPropertyKeyValue as String] as? String { names.append(name) }
            }
        }
        if names.isEmpty, let common = SecCertificateCopySubjectSummary(certificate) as String? {
            names.append(common)
        }
        return names
    }

    private static func notAfter(_ certificate: SecCertificate) -> Date? {
        guard let values = SecCertificateCopyValues(certificate, [kSecOIDX509V1ValidityNotAfter] as CFArray, nil) as? [String: Any],
              let entry = values[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
              let seconds = entry[kSecPropertyKeyValue as String] as? NSNumber
        else { return nil }
        return Date(timeIntervalSinceReferenceDate: seconds.doubleValue)
    }
}
