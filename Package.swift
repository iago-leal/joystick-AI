// swift-tools-version: 6.0
import Foundation
import PackageDescription

// Só com as Command Line Tools, o Swift Testing fica fora do caminho de busca padrão (D-03).
let cltFrameworks = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let cltDeveloperLib = "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
let hasCLTTesting = FileManager.default.fileExists(atPath: cltFrameworks + "/Testing.framework")
let testSwiftFlags: [SwiftSetting] = hasCLTTesting ? [.unsafeFlags(["-F", cltFrameworks])] : []
let testLinkerFlags: [LinkerSetting] = hasCLTTesting
    ? [.unsafeFlags(["-F", cltFrameworks, "-Xlinker", "-rpath", "-Xlinker", cltFrameworks,
                     "-Xlinker", "-rpath", "-Xlinker", cltDeveloperLib])]
    : []

let package = Package(
    name: "JoystickAI",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "JoystickCore", targets: ["JoystickCore"]),
        .executable(name: "JoystickAIPoC", targets: ["JoystickAIPoC"]),
        .executable(name: "poc-tools", targets: ["poc-tools"]),
    ],
    targets: [
        // Lógica pura e testável, só Foundation (D-03).
        .target(
            name: "JoystickCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        // App agente com os adaptadores de plataforma; modo Swift 5, isolamento por filas explícitas (D-22).
        .executableTarget(
            name: "JoystickAIPoC",
            dependencies: ["JoystickCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Utilitário de análise do log e dos resultados da tela de alvos (RF-25).
        .executableTarget(
            name: "poc-tools",
            dependencies: ["JoystickCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "JoystickCoreTests",
            dependencies: ["JoystickCore"],
            swiftSettings: [.swiftLanguageMode(.v6)] + testSwiftFlags,
            linkerSettings: testLinkerFlags
        ),
    ]
)
