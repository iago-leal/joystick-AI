import Testing
@testable import JoystickCore

@Suite struct StartupAdoptionTests {
    @Test func enumeracaoInicialEhSempreAoIniciar() {
        #expect(StartupAdoption.isAtStartup(source: .enumeration, elapsedNs: 0))
        #expect(StartupAdoption.isAtStartup(source: .enumeration, elapsedNs: 10_000_000_000))
    }

    @Test func notificacaoAntesDeDoisSegundos() {
        #expect(StartupAdoption.isAtStartup(source: .notification, elapsedNs: 150_000_000))
        #expect(StartupAdoption.isAtStartup(source: .notification, elapsedNs: 1_999_999_999))
    }

    @Test func notificacaoAPartirDeDoisSegundos() {
        #expect(!StartupAdoption.isAtStartup(source: .notification, elapsedNs: 2_000_000_000))
        #expect(!StartupAdoption.isAtStartup(source: .notification, elapsedNs: 45_000_000_000))
    }
}
