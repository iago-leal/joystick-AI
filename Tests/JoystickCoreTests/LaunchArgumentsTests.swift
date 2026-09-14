import Testing
@testable import JoystickCore

@Suite struct LaunchArgumentsTests {
    @Test func semArgumentos() {
        let args = LaunchArguments.parse([])
        #expect(!args.targets)
        #expect(args.env == nil)
        #expect(args.screen == 1)
        #expect(args.seed == nil)
        #expect(!args.debug)
        #expect(args.scrollUnit == .pixel)
        #expect(args.errors.isEmpty)
    }

    @Test func targetsComAmbienteValido() {
        let args = LaunchArguments.parse(["--targets", "--env", "sofa", "--screen", "2", "--seed", "184467"])
        #expect(args.targets)
        #expect(args.env == .sofa)
        #expect(args.screen == 2)
        #expect(args.seed == 184467)
        #expect(args.targetsEnabled)
        #expect(args.errors.isEmpty)
    }

    @Test func targetsExigeAmbiente() {
        let args = LaunchArguments.parse(["--targets"])
        #expect(!args.targetsEnabled)
        #expect(args.errors == [.missingEnv])
    }

    @Test func ambienteInvalido() {
        let args = LaunchArguments.parse(["--targets", "--env", "sofá"])
        #expect(args.env == nil)
        #expect(!args.targetsEnabled)
        #expect(args.errors == [.invalidEnv("sofá")])
    }

    @Test func telaNaoInteira() {
        let args = LaunchArguments.parse(["--screen", "tv"])
        #expect(args.screen == 1)
        #expect(args.errors == [.invalidScreen("tv")])
        #expect(LaunchArguments.parse(["--screen", "0"]).errors == [.invalidScreen("0")])
    }

    @Test func sementeSemSinal() {
        #expect(LaunchArguments.parse(["--seed", "-3"]).errors == [.invalidSeed("-3")])
        #expect(LaunchArguments.parse(["--seed", "18446744073709551615"]).seed == UInt64.max)
    }

    @Test func unidadeDeRolagem() {
        #expect(LaunchArguments.parse(["--scroll-unit", "line"]).scrollUnit == .line)
        let invalid = LaunchArguments.parse(["--scroll-unit", "pagina"])
        #expect(invalid.scrollUnit == .pixel)
        #expect(invalid.errors == [.invalidScrollUnit("pagina")])
    }

    @Test func debug() {
        #expect(LaunchArguments.parse(["--debug"]).debug)
    }

    @Test func valorAusenteNoFim() {
        #expect(LaunchArguments.parse(["--screen"]).errors == [.missingValue("--screen")])
    }

    @Test func argumentosDesconhecidosIgnorados() {
        let args = LaunchArguments.parse(["-NSDocumentRevisionsDebugMode", "YES", "--debug", "-psn_0_12345"])
        #expect(args.debug)
        #expect(args.errors.isEmpty)
    }
}
