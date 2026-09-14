# Interface: seção `pointer` de `config.json`

> Feature: `001-poc-entrada-ponteiro`
> Tipo: arquivo, leitura
> Produtor: o usuário (edição manual); futuramente, `action-mapping` (criação do arquivo padrão)
> Consumidor: `JoystickAIPoC`, ao iniciar
> Origem: `requirements.md` RF-26; `_reversa_sdd/sdd/pointer-control.md#9. Modelo de Dados`; `_reversa_sdd/sdd/action-mapping.md#9. Modelo de Dados`
> Confidência: 🟢 caminho, nomes, padrões e faixas (RF-26, esclarecimentos 1 e 8); 🟡 mensagens e extração da linha do erro

## 1. Localização

`~/.config/joystick-ai/config.json`, expandido a partir de `FileManager.default.homeDirectoryForCurrentUser`. A PoC não cria o arquivo nem o diretório.

## 2. "Request": conteúdo aceito

```json
{
  "pointer": {
    "touchpadSensitivity": 1.0,
    "stickMaxSpeed": 1500,
    "stickExponent": 2.0,
    "deadzone": 0.12,
    "scrollSpeed": 40,
    "invertScrollY": false,
    "precisionFactor": 0.3,
    "doubleClickIntervalMs": 400
  }
}
```

- Objeto raiz JSON, codificação UTF-8. Chaves extras na raiz (`version`, `mappings`, `dictation`...) e dentro de `pointer` são ignoradas sem aviso, para que o mesmo arquivo sirva ao futuro `action-mapping`.
- Todos os campos são opcionais. Faixas e padrões em `data-delta.md#2`.
- Números inteiros são aceitos onde se espera decimal; `doubleClickIntervalMs` aceita apenas inteiro.

## 3. "Response": efeito e registro

| Situação | Efeito | Evento de log | Nível |
|----------|--------|---------------|-------|
| Arquivo ausente | Todos os padrões | `config.loaded` com `status: "defaults"`, `reason: "file_missing"` | info |
| Arquivo sem seção `pointer` | Todos os padrões | `config.loaded` com `status: "defaults"`, `reason: "section_missing"` | info |
| Arquivo válido | Valores lidos, padrões para os ausentes | `config.loaded` com `status: "loaded"` e os valores efetivos | info |
| Campo com tipo errado ou fora da faixa | Padrão naquele campo | `config.value_rejected` com `field`, `rejected`, `min`, `max`, `default` | warn |
| JSON sintaticamente inválido | Todos os padrões | `config.invalid_json` com `line` (quando disponível) e `message` | error |
| Arquivo ilegível (permissão, diretório no lugar do arquivo) | Todos os padrões | `config.unreadable` com `message` | error |

Os valores efetivos entram também em cada `TargetRun.settings`, o que liga cada rodada de calibração aos parâmetros vigentes (RF-25 b).

## 4. Erros

- A leitura nunca impede a inicialização; toda falha resulta em padrões.
- Mensagem de linha: extraída da descrição do erro de decodificação do Foundation ("line N"). Se o texto não trouxer a linha, `line` é omitido e o risco R-11 do roadmap é registrado no relatório.

## 5. Idempotência e concorrência

- Leitura única ao iniciar; alterações valem ao reabrir a PoC (RF-26). Não há observação de arquivo (Won't).
- Ler o mesmo arquivo duas vezes produz o mesmo `ConfigLoadResult`.
- Um editor salvando durante a leitura pode produzir JSON truncado, tratado como `config.invalid_json`; reabrir a PoC resolve.

## 6. Timeouts e limites

- Arquivo maior que 1 MiB é recusado como `config.unreadable`, limite de proteção sem impacto esperado (o arquivo padrão de `action-mapping` tem até 150 linhas).
- Sem timeout: a leitura é local e síncrona, antes de iniciar a leitura do controle.

## 7. Compatibilidade futura

`action-mapping` passará a criar o arquivo e a recarregá-lo ao salvar (`pointer-control` RF-10). Os nomes e padrões aqui não mudam; as faixas de RF-26 precisam ser incorporadas à spec `pointer-control` §9 pelo `/reversa-sync` para que os dois consumidores validem igual.
