import Testing
@testable import JoystickCore

/// Só a rede local chega ao teclado remoto (`008-iphone-teclado-remoto` D-07, RN-01).
@Suite struct LocalAddressPolicyTests {
    @Test(arguments: [
        "10.0.0.1", "10.255.255.254", "172.16.0.1", "172.31.255.255", "192.168.1.20", "169.254.3.4",
        "fe80::1", "fe80::1c2b:3aff:fe4d:5e6f%en0", "febf::1", "fd12:3456::1", "fc00::1", "::ffff:192.168.0.7",
    ])
    func aceitaRedeLocal(_ address: String) {
        #expect(LocalAddressPolicy.isAllowed(address))
    }

    @Test(arguments: [
        "172.32.0.1", "172.15.255.255", "8.8.8.8", "192.169.0.1", "100.64.0.1", "2001:db8::1", "2606:4700::1111",
        "fec0::1", "::ffff:8.8.8.8", "127.0.0.1", "::1",
    ])
    func recusaForaDaRedeLocal(_ address: String) {
        #expect(!LocalAddressPolicy.isAllowed(address))
    }

    @Test(arguments: ["", "localhost", "192.168.1", "192.168.1.256", "192.168.01.1x", "1.2.3.4.5", "fe80::g", ":::", "abc"])
    func recusaEnderecoMalformado(_ address: String) {
        #expect(!LocalAddressPolicy.isAllowed(address, allowLoopback: true))
    }

    @Test func lacoLocalSoComAOpcaoDeTeste() {
        #expect(LocalAddressPolicy.isAllowed("127.0.0.1", allowLoopback: true))
        #expect(LocalAddressPolicy.isAllowed("::1", allowLoopback: true))
        #expect(LocalAddressPolicy.isAllowed("::ffff:127.0.0.1", allowLoopback: true))
        #expect(!LocalAddressPolicy.isAllowed("127.0.0.1"))
    }
}
