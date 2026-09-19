# Regression watch: iPhone como teclado remoto do Mac

> Identificador: `008-iphone-teclado-remoto`
> Âncora: legado (`_reversa_sdd/architecture.md`, `_reversa_sdd/domain.md`, extração de 2026-09-15). Os itens do watch principal nascem da seção "Modificadas" do `legacy-impact.md`; só regras originalmente 🟢 entram nele. Os requisitos e as decisões 🟡, que dependem do PM-0 e do PM-1, ficam em "Observações", sem peso de regressão.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W001 | `_reversa_sdd/domain.md` §3.1, 001 RN-12 | O app não usa rede, exceto o teclado remoto: duas portas (47810 e 47811) que só existem com o recurso ligado pelo menu, que nasce desligado. | redação | Re-extração ainda dizendo "sem rede" sem a exceção, ou listener criado fora de `RemoteKeyboardService.enable`. |
| W002 | `_reversa_sdd/domain.md` §3.1, 001 RN-12; `requirements.md` RN-01 | Toda conexão cuja origem não passa em `LocalAddressPolicy.isAllowed` é fechada sem resposta, nas duas portas; o laço local só com a chave de teste. | presença | `LocalAddressPolicyTests` vermelho, ou `RemotePageListener`/`RemoteChannelListener` aceitando sem consultar a política. |
| W003 | `_reversa_sdd/permissions.md` §2, linha "Rede" | A linha registra a escuta local do teclado remoto, com TLS obrigatório e sem permissão TCC nova. | redação | `permissions.md` com "Rede: nenhuma" após a re-extração, ou listener sem `tlsOptions()`. |
| W004 | `_reversa_sdd/domain.md` §3.1, 001 RN-04 | Nenhum fechamento do canal remoto deixa tecla ou modificador presos: fechamento, substituição (4004), vigia de 1 s, cinco inválidas, suspensão e encerramento passam por `releaseAll` antes de liberar a sessão. | presença | `RemoteKeyboardMachineTests` de vigia ou de soltura vermelhos, ou `endSession` do canal sem chamar `channelSessionEnded` antes de aceitar a nova conexão. |
| W005 | `_reversa_sdd/domain.md` §4, RI-04 | A suspensão da injeção solta o teclado remoto antes de desligar o injetor, guarda as solturas e as repete na retomada; a página recebe `status` nas duas pontas. | presença | `InjectionGate` sem `remote?.releaseAll()` ou sem `repeatReleases(pendingRemoteReleases)`, ou `onAllowedChange` ausente. |
| W006 | `_reversa_sdd/injecao-de-eventos/requirements.md`, RN-IN-08 | As `flags` de tecla são os modificadores com contagem maior que zero, mais `maskAlphaShift` quando o Caps Lock do sistema está ligado; o Caps Lock remoto vai por `capsLock(down:)`, fora da contagem de `KeyModifier`. | redação | Re-extração com a redação antiga de RN-IN-08, ou Caps Lock entrando em `KeyModifier`. |
| W007 | `_reversa_sdd/injecao-de-eventos/requirements.md`, RN-IN-08; roadmap D-09 | ⌘, ⇧, ⌥ e ⌃ direitos (54, 60, 61, 62) resolvem para o mesmo `KeyModifier` dos esquerdos e somam na contagem do controle. | presença | `RemoteKeyGeometryTests` do mapeamento direito vermelho, ou modificador direito postado por outro caminho. |
| W008 | `_reversa_sdd/domain.md` §3.3, 003 RN-14; `injecao-de-eventos/requirements.md`, RN-IN-16 | Nenhum evento `remote.*` carrega tecla, código, token, rótulo ou endereço. | ausência | `LogEventCatalogTests.eventosDoTecladoRemotoSemConteudo` vermelho, ou campo `k`, `code`, `token` ou `address` num evento `remote.*`. |
| W009 | `_reversa_sdd/traceability/code-spec-matrix.md` | Contagens: `RemoteKeyGeometryTests` 5, `LocalAddressPolicyTests` 4, `RemotePairingTests` 9, `RemoteKeyboardMessageTests` 7, `RemoteKeyboardMachineTests` 14, `RemoteKeyboardAssetsTests` 5, `LogEventCatalogTests` 11; total de 351 testes em 39 suítes. | redação | Matriz com as contagens anteriores sem feature que as reduza, ou alguma das suítes removida. |

## Observações

Requisitos e decisões 🟡, conferidos no PM-0 (sondas P-01 a P-07) e no PM-1; sem peso de regressão até uma re-extração os confirmar como 🟢.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O001 | `roadmap.md` D-01, `investigation.md` P-01 | O Safari do iPhone aceita a autoridade local instalada e confiada, e abre a página e o canal sem aviso. | presença | Aviso de certificado ou WSS recusado com a autoridade confiada; reprovada, a cifragem de RN-03 volta ao usuário. |
| O002 | `requirements.md` RF-04; roadmap D-15 | O teclado completo cabe numa só tela na horizontal, sem rolar, no iPhone do usuário. | presença | Tecla cortada, rolagem, ou barra do Safari cobrindo a última linha. |
| O003 | `requirements.md` RF-10 | A página passa a "sem permissão" em até 3 s após a revogação da Acessibilidade e marca cada tecla tocada. | presença | Faixa de estado parada em "Conectado" após a revogação. |
| O004 | `roadmap.md` D-06; protocolo §3.4 | O token da sessão substitui a conexão ativa com 4004; a aba antiga mostra "sessão aberta noutra aba" e não reconecta. | presença | Duas abas disputando a sessão em laço de reconexão. |
| O005 | `roadmap.md` D-11; protocolo §3.5 | Sem mensagem por 1 s com tecla mantida, tudo solta e registra `remote.watchdog`; a sessão continua. | presença | Tecla presa ao bloquear o iPhone no meio de um toque longo. |
| O006 | `roadmap.md` D-17, `investigation.md` P-04 | O Caps Lock remoto liga e desliga o do sistema; reprovada a sonda, T035 retira a tecla. | presença | Caps Lock sem efeito ou preso; tecla 57 na geometria com P-04 reprovada. |
| O007 | `roadmap.md` D-12 | Os rótulos seguem a fonte de entrada ativa, inclusive teclas mortas, e mudam na troca de fonte sem reconectar. | presença | Rótulos do ABC com o layout brasileiro ativo, ou sem mudança após trocar a fonte. |
| O008 | `requirements.md`, requisito de desempenho | Uma tecla chega ao aplicativo em foco em até 150 ms após o toque, no p95, na rede doméstica. | presença | Sonda P-05 acima de 150 ms no p95. |

## Histórico de re-extrações

_(vazio; preenchido pelo agente reverso quando `/reversa` rodar de novo)_

## Arquivadas

_(vazio)_
