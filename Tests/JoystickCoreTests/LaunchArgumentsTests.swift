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

    @Test func intervaloDoEnterDaPaleta() {
        #expect(LaunchArguments.parse([]).paletteEnterDelayMs == nil)
        for value in [0, 120, 500] {
            let args = LaunchArguments.parse(["--palette-enter-delay-ms", String(value)])
            #expect(args.paletteEnterDelayMs == value)
            #expect(args.errors.isEmpty)
        }
        for raw in ["-1", "501", "abc"] {
            let args = LaunchArguments.parse(["--palette-enter-delay-ms", raw])
            #expect(args.paletteEnterDelayMs == nil)
            #expect(args.errors == [.invalidPaletteEnterDelay(raw)])
            #expect(args.errors.first?.concernsPalette == true)
        }
        let missing = LaunchArguments.parse(["--palette-enter-delay-ms"])
        #expect(missing.paletteEnterDelayMs == nil)
        #expect(missing.errors == [.missingValue("--palette-enter-delay-ms")])
        #expect(missing.errors.first?.concernsPalette == true)
        #expect(!LaunchArgumentError.missingValue("--screen").concernsPalette)
        #expect(LaunchArgumentError.invalidPaletteEnterDelay("abc").message
            == "--palette-enter-delay-ms inválido: \"abc\"; use um inteiro de 0 a 500")
    }

    @Test func argumentosDesconhecidosIgnorados() {
        let args = LaunchArguments.parse(["-NSDocumentRevisionsDebugMode", "YES", "--debug", "-psn_0_12345"])
        #expect(args.debug)
        #expect(args.errors.isEmpty)
    }
}
