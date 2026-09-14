import Foundation
import Testing
@testable import JoystickCore

@Suite struct ScreenUnionTests {
    // Mac de 1512 × 982 à esquerda; TV de 1920 × 1080 à direita, alinhada pelo topo: arranjo em L.
    let mac = ScreenRect(x: 0, y: 0, width: 1512, height: 982)
    let tv = ScreenRect(x: 1512, y: 0, width: 1920, height: 1080)

    @Test func pontoContidoEhMantido() {
        let union = ScreenUnion(rects: [mac, tv])
        #expect(union.clamp(ScreenPoint(x: 700.5, y: 300)) == ScreenPoint(x: 700.5, y: 300))
        #expect(union.clamp(ScreenPoint(x: 2000, y: 1050)) == ScreenPoint(x: 2000, y: 1050))
    }

    @Test func vaoDoArranjoEmLVaiAoRetanguloMaisProximo() {
        let union = ScreenUnion(rects: [mac, tv])
        // Abaixo do Mac, na faixa em que só a TV tem altura: não pode ficar no vão.
        let clamped = union.clamp(ScreenPoint(x: 1500, y: 1030))
        #expect(union.contains(clamped))
        #expect(clamped == ScreenPoint(x: 1512, y: 1030))
    }

    @Test func bordaExterna() {
        let union = ScreenUnion(rects: [mac, tv])
        #expect(union.clamp(ScreenPoint(x: 5000, y: 500)) == ScreenPoint(x: 3431, y: 500))
        #expect(union.clamp(ScreenPoint(x: -40, y: -10)) == ScreenPoint(x: 0, y: 0))
    }

    @Test func remocaoDoRetanguloQueContinhaOPonto() {
        let union = ScreenUnion(rects: [mac])
        let clamped = union.clamp(ScreenPoint(x: 2500, y: 1000))
        #expect(clamped == ScreenPoint(x: 1511, y: 981))
        #expect(union.contains(clamped))
    }

    @Test func listaVaziaDevolveOPonto() {
        let union = ScreenUnion(rects: [])
        #expect(union.clamp(ScreenPoint(x: 12, y: 34)) == ScreenPoint(x: 12, y: 34))
    }
}
