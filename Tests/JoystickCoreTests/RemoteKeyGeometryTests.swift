import Foundation
import Testing
@testable import JoystickCore

/// Geometria do teclado remoto (`008-iphone-teclado-remoto` RF-04, D-16, D-17).
@Suite struct RemoteKeyGeometryTests {
    static let letters: [UInt16] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 31, 32, 34, 35, 37, 38, 40, 45, 46]
    static let digits: [UInt16] = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29]
    static let functionKeys: [UInt16] = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111]
    static let named: [UInt16] = [53, 48, 57, 36, 51, 49, 123, 124, 125, 126]
    static let punctuation: [UInt16] = [27, 24, 33, 30, 42, 41, 39, 43, 47, 44, 50]

    @Test(arguments: PhysicalLayout.allCases) func temAsTeclasDeRF04(_ physical: PhysicalLayout) {
        let geometry = RemoteKeyGeometry.standard(physical)
        for code in Self.letters + Self.digits + Self.functionKeys + Self.named + Self.punctuation {
            #expect(geometry.contains(code: code), "\(physical) sem \(code)")
        }
        for code: UInt16 in [55, 54, 56, 60, 58, 61, 59, 62] {
            #expect(geometry.contains(code: code), "\(physical) sem modificador \(code)")
        }
        #expect(geometry.rows.count == 6)
        #expect(Set(geometry.codes).count == geometry.codes.count, "código repetido")
    }

    @Test func isoTemSecaoEAnsiNao() {
        #expect(RemoteKeyGeometry.standard(.iso).contains(code: 10))
        #expect(!RemoteKeyGeometry.standard(.ansi).contains(code: 10))
        #expect(RemoteKeyGeometry.standard(.ansi).codes.count + 1 == RemoteKeyGeometry.standard(.iso).codes.count)
    }

    @Test func modificadoresDireitosResolvemParaOsMesmosDosEsquerdos() {
        let geometry = RemoteKeyGeometry.standard(.ansi)
        let pairs: [(UInt16, UInt16, KeyModifier)] = [(55, 54, .command), (56, 60, .shift), (58, 61, .option), (59, 62, .control)]
        for (left, right, modifier) in pairs {
            #expect(geometry.key(code: left)?.kind == .modifier(modifier))
            #expect(geometry.key(code: right)?.kind == .modifier(modifier))
        }
    }

    @Test func recusaCodigosForaDaGeometria() {
        let geometry = RemoteKeyGeometry.standard(.ansi)
        for code: UInt16 in [63, 71, 82, 114, 117, 160, 179, 255, 0xFFFF] {
            #expect(!geometry.contains(code: code), "\(code)")
            #expect(geometry.key(code: code) == nil)
        }
    }

    /// D-17: Caps Lock presente até a sonda P-04 decidir o contrário.
    @Test func capsLockPresenteEOpcional() {
        #expect(RemoteKeyGeometry.standard(.ansi).key(code: 57)?.kind == .capsLock)
        #expect(!RemoteKeyGeometry.standard(.ansi, capsLock: false).contains(code: 57))
    }
}
