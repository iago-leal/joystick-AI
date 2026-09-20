/*
  Controle virtual no iPhone (`010-joystick-virtual-iphone` D-02, D-05, D-06, D-08, D-11, D-14, D-15; protocolo em
  `interfaces/remote-controller-protocol.md`).

  Desenha os analógicos, o direcional, as faces, os gatilhos e a faixa de botões secundários, e trata a área de
  apontamento do bloco central. Nada de HTML em texto: tudo por elementos e `textContent`, como `RemoteKeyboardAssets`
  exige (D-12).

  Cada dedo é seguido pelo seu `identifier`, do `touchstart` ao `touchend` ou `touchcancel`. O analógico envia `stick`
  no quadro de animação, no máximo sessenta vezes por segundo e só quando o valor muda (D-06), medido a partir da
  origem que o dedo fixa ao pousar, com curso fixo em pixels (E-06); o botão envia `btn` ao
  tocar e ao soltar, com marcação visual; a área de apontamento envia `pad` por dedo, com a fase, e multiplica o
  deslocamento pela sensibilidade da página (RF-20).

  Gatilhos aderentes (E-04, D-15 revista): no aparelho sobram dois polegares, e o da esquerda não pode estar em L1 e
  no analógico ao mesmo tempo, de modo que a precisão do cursor e as camadas do lado esquerdo ficariam inalcançáveis.
  Um toque curto em L1 ou L2 prende o botão como mantido, no mesmo laranja dos modificadores presos do teclado; outro
  toque solta. Segurar com o dedo continua funcionando como antes, e todo caminho de soltura desfaz a prisão. Os
  demais botões seguem sem prisão por toque, R1 e R2 inclusive, porque são os cliques do ponteiro.

  Controle oculto (E-05): o botão `controls` da barra esconde a faixa e as colunas e entrega a tela inteira ao bloco
  central. Antes de sumir, o controle solta tudo o que mantinha, para nada ficar preso no Mac.

  O estado do bloco central e a sensibilidade ficam em `remoteKeyboardPrefs`, ao lado das preferências da faixa de
  sugestões, sempre dentro de `try` (D-11). A tela fica acesa pelo bloqueio de tela do navegador enquanto a página
  estiver visível, e falha em silêncio quando o recurso não existir ou for negado (D-14, RF-19).
*/
(function () {
  "use strict";

  var channel = window.RemoteKeyboard;
  if (!channel) {
    return;
  }

  var STICK_HZ = 60;
  // Curso do dedo, em pixels, da origem até a amplitude máxima (E-06). Fica fora do desenho de propósito: o círculo
  // pode encolher conforme a tela sem que a sensibilidade mude junto.
  var STICK_TRAVEL = 64;
  var MAX_FINGERS = 4;
  // Toque mais curto que isto prende o gatilho; mais longo é o gesto de segurar, que solta ao tirar o dedo.
  var LATCH_MS = 300;
  // Só os gatilhos de camada prendem. R1 e R2 são os cliques do ponteiro, e clique preso é armadilha; além disso o
  // arraste de seleção usa R1 num polegar e o analógico no outro, de modo que nunca precisou de prisão (E-04).
  var LATCHABLE = { l1: true, l2: true };
  var CENTER_MODES = ["pointer", "compact", "full"];
  var CENTER_LABELS = { pointer: "Apontar", compact: "Teclado", full: "Teclado todo" };
  // O rótulo do botão diz para onde ele leva, não onde se está.
  var CENTER_NEXT = { pointer: "compact", compact: "full", full: "pointer" };

  // Agrupamentos do desenho (D-02, E-07, E-08). A cruz ocupa as nove casas da grade, e o vão do meio, antes vazio, é
  // o analógico daquele lado: o polegar já vive ali, e assim o comando fica no meio da coluna, com curso para todos
  // os lados, em vez de no pé da tela, onde faltava espaço para descer o dedo. O disco desenhado transborda a casa e
  // passa por baixo de toda a cruz, de modo que o alvo do polegar é ele, e não a casa.
  var DPAD = [
    null, { b: "dpadUp", label: "▲" }, null,
    { b: "dpadLeft", label: "◀" }, { s: "l" }, { b: "dpadRight", label: "▶" },
    null, { b: "dpadDown", label: "▼" }, null
  ];
  var FACES = [
    null, { b: "triangle", label: "△" }, null,
    { b: "square", label: "□" }, { s: "r" }, { b: "circle", label: "○" },
    null, { b: "cross", label: "✕" }, null
  ];
  // Faixa do alto (D-02 revista no PM-0, emendada por E-04): os botões de analógico nas pontas e os secundários no
  // meio. O `null` abre um vão entre os três grupos.
  var TRAY = [
    { b: "l3", label: "L3" },
    null,
    { b: "ps", label: "PS" }, { b: "create", label: "Create" }, { b: "options", label: "Options" },
    { b: "touchpadClick", label: "Painel" },
    null,
    { b: "r3", label: "R3" }
  ];
  // Gatilhos no topo da coluna do seu lado, ao alcance do polegar que comanda aquele analógico (E-04).
  var SHOULDERS = {
    "shoulders-left": [{ b: "l2", label: "L2" }, { b: "l1", label: "L1" }],
    "shoulders-right": [{ b: "r1", label: "R1" }, { b: "r2", label: "R2" }]
  };

  var appEl = document.getElementById("app");
  var pointerEl = document.getElementById("pointer");
  var centerModeEl = document.getElementById("center-mode");
  var controlsEl = document.getElementById("controls");
  var sensitivityEl = document.getElementById("sensitivity");
  var sensitivityBoxEl = document.getElementById("sensitivity-box");
  var sensitivityLabelEl = document.getElementById("sensitivity-label");
  var sticks = {
    l: { el: document.getElementById("stick-left"), zone: null, area: null, knob: null, sent: null, pending: null, finger: null, origin: null },
    r: { el: document.getElementById("stick-right"), zone: null, area: null, knob: null, sent: null, pending: null, finger: null, origin: null }
  };

  // Dedo por `identifier`: em botão, em analógico ou na área de apontamento.
  var touches = {};
  // Dedos da área de apontamento, por índice de 0 a 3 do protocolo.
  var padFingers = {};
  /// Caixa da área de apontamento, medida uma vez por série de toques: pedi-la a cada amostra força o Safari a
  /// recalcular o layout no meio do arrasto, e era isso que fazia o cursor andar aos pulos (emenda E-09).
  var padBox = null;
  /// Última posição de cada dedo ainda não enviada, drenada por quadro como no analógico (emenda E-09).
  var padPending = {};
  var padFrame = null;
  var buttonElements = {};
  // Gatilhos presos por toque curto, por nome de botão (E-04).
  var latched = {};
  var frame = null;
  var lastStickSendMs = 0;
  var wakeLock = null;

  // MARK: - Desenho

  function makeButton(spec) {
    var button = document.createElement("div");
    button.className = "pad-button";
    button.dataset.b = spec.b;
    button.textContent = spec.label;
    buttonElements[spec.b] = button;
    return button;
  }

  function fillCluster(id, specs) {
    var host = document.getElementById(id);
    if (!host) {
      return;
    }
    host.replaceChildren.apply(host, specs.map(function (spec) {
      if (!spec) {
        var hole = document.createElement("div");
        hole.className = id === "tray" ? "tray-gap" : "hole";
        return hole;
      }
      if (spec.s) {
        // O analógico já existe no documento; aqui ele só muda de lugar, para o vão central da cruz.
        return sticks[spec.s].zone;
      }
      return makeButton(spec);
    }));
  }

  function build() {
    // Os analógicos são resolvidos antes: a cruz precisa deles para preencher o vão central.
    Object.keys(sticks).forEach(function (side) {
      var stick = sticks[side];
      stick.knob = stick.el ? stick.el.querySelector(".knob") : null;
      stick.zone = stick.el ? stick.el.closest(".stick-zone") : null;
    });
    fillCluster("dpad", DPAD);
    fillCluster("faces", FACES);
    fillCluster("tray", TRAY);
    Object.keys(SHOULDERS).forEach(function (id) {
      fillCluster(id, SHOULDERS[id]);
    });
    // Só depois de a cruz receber o analógico é que se sabe por onde o desenho pode deslocar-se (E-08).
    Object.keys(sticks).forEach(function (side) {
      var stick = sticks[side];
      stick.area = stick.zone ? stick.zone.closest(".cluster") : null;
    });
  }

  // MARK: - Estado do bloco central (D-08, D-11)

  function applyCenter(mode, tell) {
    if (CENTER_MODES.indexOf(mode) < 0) {
      return;
    }
    if (channel.center() !== mode) {
      // Sair do apontamento larga os dedos daqui antes de o desenho mudar sob eles, e a troca desfaz as prisões:
      // o Mac solta o que a máquina mantinha ao deixar o apontamento, e página e Mac não podem discordar.
      releasePad();
      releaseLatched();
      channel.setCenter(mode);
    }
    centerModeEl.textContent = CENTER_LABELS[CENTER_NEXT[mode]];
    channel.prefs.center = mode;
    channel.storePrefs();
    if (tell) {
      channel.send({ t: "mode", m: mode });
    }
  }

  // MARK: - Controle visível (E-05)

  /// Esconde ou mostra a faixa e as colunas. Some o controle, some também tudo o que ele mantinha: o dedo perde o
  /// botão de vista e não teria como soltá-lo.
  function applyControls(visible, remember) {
    if (!visible) {
      releaseControl();
    }
    appEl.dataset.controls = visible ? "on" : "off";
    controlsEl.setAttribute("aria-pressed", visible ? "true" : "false");
    if (remember) {
      channel.prefs.controls = visible;
      channel.storePrefs();
    }
  }

  /// Solta no Mac tudo o que o controle mantém: botões sob o dedo, gatilhos presos, analógicos fora do repouso e
  /// dedos da área de apontamento.
  function releaseControl() {
    Object.keys(touches).forEach(function (id) {
      var entry = touches[id];
      if (entry.kind === "pad") {
        return;
      }
      delete touches[id];
      if (entry.kind === "button") {
        releaseButton(entry.element);
      } else if (entry.kind === "stick") {
        centerStick(sticks[entry.side], entry.side);
      }
    });
    releaseLatched();
    releasePad();
    Object.keys(sticks).forEach(function (side) {
      if (sticks[side].finger === null) {
        centerStick(sticks[side], side);
      }
    });
  }

  // MARK: - Botões (D-15, E-04)

  function buttonFor(target) {
    return target && target.closest ? target.closest(".pad-button") : null;
  }

  function pressButton(element) {
    element.classList.add("pressed");
    channel.send({ t: "btn", b: element.dataset.b, d: 1 });
  }

  function releaseButton(element) {
    element.classList.remove("pressed");
    delete element.dataset.state;
    delete latched[element.dataset.b];
    channel.send({ t: "btn", b: element.dataset.b, d: 0 });
  }

  /// Prende o gatilho: o Mac já recebeu o `down` no toque, de modo que aqui só fica a marca e a falta do `up`.
  function latchButton(element) {
    element.classList.remove("pressed");
    element.dataset.state = "latched";
    latched[element.dataset.b] = true;
  }

  /// Solta no Mac todo gatilho preso. Vale para a troca do bloco central, para o controle que se esconde e para o
  /// fim da sessão: nenhum caminho de saída pode deixar botão pendurado (001 RN-04).
  function releaseLatched() {
    Object.keys(latched).forEach(function (name) {
      var element = buttonElements[name];
      if (element) {
        releaseButton(element);
      } else {
        delete latched[name];
      }
    });
  }

  // MARK: - Analógicos (D-05, D-06)

  function stickFor(target) {
    var element = target && target.closest ? target.closest(".stick-zone") : null;
    return element ? sticks[element.dataset.s] : null;
  }

  /// Vetor do dedo em relação à origem fixada no pousar, limitado ao círculo unitário, com o Y positivo para cima
  /// (E-06). O curso é `STICK_TRAVEL`, não o raio desenhado: o polegar escorrega além dele sem que a saída cresça.
  function stickVector(stick, touch) {
    if (!stick.origin) {
      return { x: 0, y: 0 };
    }
    var dx = (touch.clientX - stick.origin.x) / STICK_TRAVEL;
    var dy = (touch.clientY - stick.origin.y) / STICK_TRAVEL;
    var length = Math.sqrt(dx * dx + dy * dy);
    if (length > 1) {
      dx /= length;
      dy /= length;
    }
    return { x: round(dx), y: round(-dy) };
  }

  /// Leva o círculo ao encontro do dedo, sem deixá-lo sair da própria área: é só referência visual, e o comando já
  /// nasceu na origem do toque.
  function placeStick(stick) {
    if (!stick.area || !stick.origin) {
      return;
    }
    var box = stick.el.getBoundingClientRect();
    var area = stick.area.getBoundingClientRect();
    var dx = stick.origin.x - (box.left + box.width / 2);
    var dy = stick.origin.y - (box.top + box.height / 2);
    dx = Math.max(area.left - box.left, Math.min(area.left + area.width - (box.left + box.width), dx));
    dy = Math.max(area.top - box.top, Math.min(area.top + area.height - (box.top + box.height), dy));
    stick.el.style.transform = "translate(" + Math.round(dx) + "px, " + Math.round(dy) + "px)";
  }

  function restStick(stick) {
    stick.origin = null;
    stick.el.style.transform = "";
    if (stick.zone) {
      stick.zone.classList.remove("pressed");
    }
  }

  // Três casas bastam para o Mac e encurtam o quadro, limitado a 1 KiB.
  function round(value) {
    return Math.round(value * 1000) / 1000;
  }

  function moveKnob(stick, vector) {
    if (stick.knob) {
      stick.knob.style.transform = "translate(" + (vector.x * 50) + "%, " + (-vector.y * 50) + "%)";
    }
  }

  function scheduleStick(stick, vector) {
    stick.pending = vector;
    moveKnob(stick, vector);
    if (frame === null) {
      frame = window.requestAnimationFrame(flushSticks);
    }
  }

  /// Envia, no máximo sessenta vezes por segundo, o que mudou desde a última amostra; o repouso encerra a série.
  function flushSticks() {
    frame = null;
    var now = Date.now();
    var due = now - lastStickSendMs >= 1000 / STICK_HZ;
    var waiting = false;
    Object.keys(sticks).forEach(function (side) {
      var stick = sticks[side];
      if (!stick.pending) {
        return;
      }
      if (!due) {
        waiting = true;
        return;
      }
      var vector = stick.pending;
      if (!stick.sent || stick.sent.x !== vector.x || stick.sent.y !== vector.y) {
        stick.sent = vector;
        channel.send({ t: "stick", s: side, x: vector.x, y: vector.y });
      }
      stick.pending = null;
    });
    if (due) {
      lastStickSendMs = now;
    }
    if (waiting && frame === null) {
      frame = window.requestAnimationFrame(flushSticks);
    }
  }

  function centerStick(stick, side) {
    stick.finger = null;
    restStick(stick);
    var rest = { x: 0, y: 0 };
    moveKnob(stick, rest);
    stick.pending = null;
    if (stick.sent && stick.sent.x === 0 && stick.sent.y === 0) {
      return;
    }
    stick.sent = rest;
    channel.send({ t: "stick", s: side, x: 0, y: 0 });
  }

  // MARK: - Área de apontamento (D-05, RF-20)

  function freeFinger() {
    for (var i = 0; i < MAX_FINGERS; i += 1) {
      if (!padFingers.hasOwnProperty(i)) {
        return i;
      }
    }
    return null;
  }

  /// Posição do dedo na área, de −1 a 1 nos dois eixos, no mesmo formato que o touchpad do controle entrega: o Y
  /// cresce para cima, e é o `TouchpadTracker` do Mac que o converte para o sentido da tela. Sem a inversão aqui, o
  /// Mac inverteria de novo e o cursor andaria ao contrário do dedo (achado do PM-0).
  /// O deslocamento desde o pousar é multiplicado pela sensibilidade da página, que se soma à do Mac (RF-20).
  function padPosition(entry, touch) {
    var box = padBox || pointerEl.getBoundingClientRect();
    if (box.width <= 0 || box.height <= 0) {
      return { x: 0, y: 0 };
    }
    var x = ((touch.clientX - box.left) / box.width) * 2 - 1;
    var y = 1 - ((touch.clientY - box.top) / box.height) * 2;
    if (entry && entry.origin) {
      var gain = channel.prefs.sensitivity;
      x = entry.origin.x + (x - entry.origin.x) * gain;
      y = entry.origin.y + (y - entry.origin.y) * gain;
    }
    return { x: round(clamp(x)), y: round(clamp(y)) };
  }

  function clamp(value) {
    return value < -1 ? -1 : value > 1 ? 1 : value;
  }

  function sendPad(finger, phase, position) {
    channel.send({ t: "pad", f: finger, p: phase, x: position.x, y: position.y });
  }

  /// Guarda o movimento e envia no próximo quadro, no máximo um por dedo: o `touchmove` do iOS entrega mais
  /// amostras do que o Mac consegue transformar em movimento contínuo, e a rajada chega como salto (emenda E-09).
  /// Pousar e levantar continuam imediatos, porque deles depende o começo e o fim da série.
  function schedulePad(finger, position) {
    padPending[finger] = position;
    if (padFrame === null) {
      padFrame = window.requestAnimationFrame(flushPad);
    }
  }

  function flushPad() {
    padFrame = null;
    var pendentes = padPending;
    padPending = {};
    Object.keys(pendentes).forEach(function (finger) {
      sendPad(Number(finger), "m", pendentes[finger]);
    });
  }

  /// Levanta os dedos que a área ainda segue, com a fase final, para o Mac não ficar com dedo preso.
  function releasePad() {
    Object.keys(touches).forEach(function (id) {
      var entry = touches[id];
      if (entry.kind !== "pad") {
        return;
      }
      delete touches[id];
      delete padFingers[entry.finger];
      delete padPending[entry.finger];
      sendPad(entry.finger, "e", entry.last);
    });
  }

  // MARK: - Toque

  function touchStart(event) {
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      if (touches.hasOwnProperty(touch.identifier)) {
        return;
      }
      var button = buttonFor(touch.target);
      if (button) {
        event.preventDefault();
        if (latched[button.dataset.b]) {
          // Segundo toque num gatilho preso: solta na hora, e o fim deste toque não faz mais nada.
          touches[touch.identifier] = { kind: "button", element: button, settled: true };
          releaseButton(button);
          return;
        }
        touches[touch.identifier] = { kind: "button", element: button, startedMs: Date.now() };
        pressButton(button);
        return;
      }
      var stick = stickFor(touch.target);
      if (stick && stick.finger === null) {
        event.preventDefault();
        var side = stick === sticks.l ? "l" : "r";
        stick.finger = touch.identifier;
        // O comando nasce onde o dedo pousou, e não no centro do desenho (E-06).
        stick.origin = { x: touch.clientX, y: touch.clientY };
        placeStick(stick);
        stick.zone.classList.add("pressed");
        touches[touch.identifier] = { kind: "stick", side: side };
        // Pousar o dedo não move nada: o analógico já está em repouso no Mac, e a origem acabou de ser fixada aqui.
        stick.sent = stick.sent || { x: 0, y: 0 };
        moveKnob(stick, { x: 0, y: 0 });
        return;
      }
      if (pointerEl.contains(touch.target) && !sensitivityBoxEl.contains(touch.target)) {
        var finger = freeFinger();
        if (finger === null) {
          return;
        }
        event.preventDefault();
        // Mede a área quando a série começa: entre uma série e outra o layout pode ter mudado, por troca de
        // bloco central, por controle escondido ou por giro do aparelho (emenda E-09).
        if (!Object.keys(padFingers).length) {
          padBox = pointerEl.getBoundingClientRect();
        }
        var entry = { kind: "pad", finger: finger, origin: null, last: { x: 0, y: 0 } };
        touches[touch.identifier] = entry;
        padFingers[finger] = true;
        var position = padPosition(null, touch);
        entry.origin = position;
        entry.last = position;
        sendPad(finger, "b", position);
      }
    });
  }

  function touchMove(event) {
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      var entry = touches[touch.identifier];
      if (!entry) {
        return;
      }
      event.preventDefault();
      if (entry.kind === "stick") {
        var stick = sticks[entry.side];
        scheduleStick(stick, stickVector(stick, touch));
      } else if (entry.kind === "pad") {
        var position = padPosition(entry, touch);
        entry.last = position;
        schedulePad(entry.finger, position);
      }
      // O botão não acompanha o dedo: sair de cima não solta, e voltar não repete (D-15).
    });
  }

  function touchEnd(event) {
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      var entry = touches[touch.identifier];
      if (!entry) {
        return;
      }
      event.preventDefault();
      delete touches[touch.identifier];
      if (entry.kind === "button") {
        if (entry.settled) {
          return;
        }
        if (LATCHABLE[entry.element.dataset.b] && Date.now() - entry.startedMs < LATCH_MS) {
          latchButton(entry.element);
        } else {
          releaseButton(entry.element);
        }
      } else if (entry.kind === "stick") {
        centerStick(sticks[entry.side], entry.side);
      } else if (entry.kind === "pad") {
        delete padFingers[entry.finger];
        delete padPending[entry.finger];
        sendPad(entry.finger, "e", padPosition(entry, touch));
      }
    });
  }

  /// Queda do canal ou saída da tela: o desenho volta ao repouso sem enviar nada, porque o Mac já soltou tudo.
  function releaseLocal() {
    Object.keys(touches).forEach(function (id) {
      var entry = touches[id];
      if (entry.kind === "button") {
        entry.element.classList.remove("pressed");
      }
    });
    Object.keys(latched).forEach(function (name) {
      var element = buttonElements[name];
      if (element) {
        delete element.dataset.state;
      }
    });
    latched = {};
    touches = {};
    padFingers = {};
    Object.keys(sticks).forEach(function (side) {
      var stick = sticks[side];
      stick.finger = null;
      stick.pending = null;
      stick.sent = null;
      restStick(stick);
      moveKnob(stick, { x: 0, y: 0 });
    });
  }

  // MARK: - Tela acesa (D-14, RF-19)

  function requestWakeLock() {
    if (!navigator.wakeLock || document.visibilityState !== "visible" || wakeLock) {
      return;
    }
    try {
      navigator.wakeLock.request("screen").then(function (lock) {
        wakeLock = lock;
        lock.addEventListener("release", function () {
          wakeLock = null;
        });
      }, function () {
        // Negado ou indisponível: a tela apaga como de costume, e a página segue igual.
      });
    } catch (e) {
      // Sem o recurso, nada muda.
    }
  }

  // MARK: - Sensibilidade (RF-20)

  function applySensitivity() {
    sensitivityEl.value = String(channel.prefs.sensitivity);
    sensitivityLabelEl.textContent = "Sensibilidade " + channel.prefs.sensitivity.toFixed(1) + "×";
  }

  function changeSensitivity() {
    var value = Number(sensitivityEl.value);
    if (!isFinite(value) || value < 0.5 || value > 2) {
      return;
    }
    channel.prefs.sensitivity = Math.round(value * 10) / 10;
    channel.storePrefs();
    applySensitivity();
  }

  // MARK: - Ligação

  build();
  applySensitivity();
  applyCenter(channel.prefs.center, false);
  applyControls(channel.prefs.controls, false);

  channel.on("welcome", function () {
    // O Mac conhece o estado da página desde o primeiro instante da sessão (§2 do protocolo).
    channel.send({ t: "mode", m: channel.center() });
    requestWakeLock();
  });
  channel.on("message", function (message) {
    if (message.t === "mode" && CENTER_MODES.indexOf(message.m) >= 0) {
      applyCenter(message.m, false);
    }
  });
  channel.on("release", releaseLocal);

  document.addEventListener("touchstart", touchStart, { passive: false });
  document.addEventListener("touchmove", touchMove, { passive: false });
  document.addEventListener("touchend", touchEnd, { passive: false });
  document.addEventListener("touchcancel", touchEnd, { passive: false });

  centerModeEl.addEventListener("click", function () {
    applyCenter(CENTER_NEXT[channel.center()], true);
  });
  controlsEl.addEventListener("click", function () {
    applyControls(appEl.dataset.controls !== "on", true);
  });
  sensitivityEl.addEventListener("input", changeSensitivity);
  sensitivityEl.addEventListener("change", changeSensitivity);

  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "visible") {
      requestWakeLock();
    } else {
      wakeLock = null;
    }
  });
  requestWakeLock();
})();
