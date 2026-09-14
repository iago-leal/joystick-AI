import Foundation
import JoystickCore
import Security

/// Assinatura do próprio processo, para o campo `signing` de `session.start` (RF-25 e).
struct SigningInfo {
    var identifier: String?
    var teamOrCertName: String?
    var designatedRequirement: String?

    static func current() -> SigningInfo {
        var info = SigningInfo()
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return info }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return info }

        var rawInfo: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation | kSecCSRequirementInformation)
        if SecCodeCopySigningInformation(staticCode, flags, &rawInfo) == errSecSuccess,
           let dict = rawInfo as? [String: Any] {
            info.identifier = dict[kSecCodeInfoIdentifier as String] as? String
            if let certificates = dict[kSecCodeInfoCertificates as String] as? [SecCertificate],
               let leaf = certificates.first {
                info.teamOrCertName = SecCertificateCopySubjectSummary(leaf) as String?
            } else if let team = dict[kSecCodeInfoTeamIdentifier as String] as? String {
                info.teamOrCertName = team
            }
        }

        var requirement: SecRequirement?
        if SecCodeCopyDesignatedRequirement(staticCode, [], &requirement) == errSecSuccess, let requirement {
            var text: CFString?
            if SecRequirementCopyString(requirement, [], &text) == errSecSuccess {
                info.designatedRequirement = text as String?
            }
        }
        return info
    }

    var jsonValue: JSONValue {
        .object([
            "identifier": identifier.map(JSONValue.string) ?? .null,
            "teamOrCertName": teamOrCertName.map(JSONValue.string) ?? .null,
            "designatedRequirement": designatedRequirement.map(JSONValue.string) ?? .null,
        ])
    }
}
