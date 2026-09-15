# Dependências — joystick-AI

> Gerado pelo Scout em 2026-09-15
> Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## 1. Gerenciador de pacotes

**Swift Package Manager**, com `swift-tools-version: 6.0`. 🟢

O manifesto não declara nenhuma dependência de terceiros, e por isso não existe `Package.resolved`. Todo o código depende apenas do SDK da Apple e do próprio `JoystickCore`. 🟢

## 2. Toolchain e plataforma

| Item | Versão | Fonte |
|------|--------|-------|
| Swift tools | 6.0 (mínimo do manifesto) | `Package.swift` 🟢 |
| Compilador local | Apple Swift 6.3.3 (arm64, macOS 26) | `swift --version` 🟢 |
| Ambiente de desenvolvimento | Command Line Tools, sem Xcode | `xcode-select -p` 🟢 |
| Plataforma mínima | macOS 13 (Ventura) | `Package.swift`, `Info.plist` 🟢 |
| Modo de linguagem | Swift 6 em `JoystickCore`, `poc-tools` e testes; Swift 5 em `JoystickAIPoC` | `Package.swift` 🟢 |

## 3. Frameworks do sistema por alvo

| Framework | `JoystickCore` | `JoystickAIPoC` | `poc-tools` | Testes | Uso |
|-----------|:-:|:-:|:-:|:-:|-----|
| Foundation | ✔ | ✔ | ✔ | ✔ | Base 🟢 |
| AppKit | | ✔ | | | Aplicativo agente, menus, painel da paleta, janelas 🟢 |
| SwiftUI | | ✔ | | | Editor de atalhos 🟢 |
| Combine | | ✔ | | | Estado observável do editor (`EditorViewModel`) 🟢 |
| GameController | | ✔ | | | Leitura do DualSense 🟢 |
| IOKit / IOKit.hid | | ✔ | | | Relatório estendido, calibração, transporte 🟢 |
| CoreGraphics | | ✔ | | | Injeção por `CGEvent`, geometria de telas 🟢 |
| ApplicationServices | | ✔ | | | `AXIsProcessTrusted` 🟢 |
| Security | | ✔ | | | Leitura da assinatura do app (`SigningInfo`) 🟢 |
| UniformTypeIdentifiers | | ✔ | | | Arrastar e soltar para reordenar itens da paleta (`PaletteTab`) 🟢 |
| os | | ✔ | | | Usado em `DiagnosticLog` 🟡 |
| Testing (Swift Testing) | | | | ✔ | 253 casos 🟢 |

A restrição de o `JoystickCore` importar só Foundation é deliberada (D-03) e se confirma no código: nenhum arquivo do núcleo importa outro framework. 🟢

## 4. Configurações condicionais de build

`Package.swift` detecta `Testing.framework` em `/Library/Developer/CommandLineTools/Library/Developer/Frameworks` e, quando presente, acrescenta ao alvo de testes:

- `unsafeFlags(["-F", <frameworks>])` nas configurações de Swift;
- `-rpath` para o diretório de frameworks e para `usr/lib` das Command Line Tools no linker.

Como o executor gerado pelo SwiftPM não herda essas flags, `scripts/test.sh` repete `-Xswiftc -F` na linha de comando. 🟢

As `unsafeFlags` impedem que o pacote seja consumido como dependência remota por outro projeto SwiftPM. É irrelevante enquanto o pacote for só um aplicativo, mas convém registrar. 🟡

## 5. Ferramentas externas usadas pelos scripts

| Ferramenta | Script | Finalidade |
|------------|--------|-----------|
| `swift` | `build-app.sh`, `test.sh` | Compilação e testes 🟢 |
| `codesign` | `build-app.sh`, `check-signature.sh` | Assinatura e inspeção 🟢 |
| `security` | `build-app.sh`, `create-local-signing-identity.sh` | Identidades de assinatura no chaveiro 🟢 |
| `openssl` | `create-local-signing-identity.sh` | Certificado e PKCS#12, com alternância entre OpenSSL 3 (`-legacy`) e LibreSSL 🟢 |
| `ditto`, `osascript`, `pgrep` | `build-app.sh` | Instalação e encerramento da instância aberta 🟢 |

## 6. Dependências de tempo de execução (permissões do macOS)

| Permissão | Por quê | Observação |
|-----------|---------|------------|
| Acessibilidade | Postar eventos `CGEvent` | Verificada por consulta periódica, pois `CGEvent.post` não informa descarte 🟢 |
| Input Monitoring | Ler o controle em segundo plano (`GCController.shouldMonitorBackgroundEvents`) | Citada em `build-app.sh` 🟢 |

As duas permissões dependem de identidade de assinatura estável, e é por isso que a assinatura ad hoc é recusada no build. 🟢
