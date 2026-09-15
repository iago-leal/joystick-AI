# ADR-002: Assinatura local autoassinada e caminho fixo de instalação

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

As permissões do TCC (Acessibilidade) se perdem quando a identidade de assinatura muda a cada compilação, o que obrigaria a reconceder a permissão após todo build.

## Decisão

Assinar com o certificado autoassinado "JoystickAI Local Signing", criado por `scripts/create-local-signing-identity.sh` (caminho B de D-01), e instalar sempre em `~/Applications/JoystickAIPoC.app`. `SigningInfo` registra a assinatura em `session.start`, e `scripts/check-signature.sh` a confere.

## Alternativas consideradas

Caminho A, com certificado Apple Development da conta gratuita: abandonado porque exigiria baixar o Xcode e entrar com o Apple ID só para obter o certificado (R-13).

## Consequências

🟢 A Acessibilidade sobrevive às recompilações. 🟡 O app não é distribuível para outros Macs sem nova assinatura; é coerente com uma PoC de uso pessoal.

## Evidências

- `scripts/create-local-signing-identity.sh`
- `Sources/JoystickAIPoC/App/SigningInfo.swift`
- `validation-report.md` 001:119-120
