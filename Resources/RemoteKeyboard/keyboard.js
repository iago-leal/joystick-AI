/*
  Teclado remoto no iPhone (`008-iphone-teclado-remoto` D-05, D-06, D-11, D-15; protocolo em
  `interfaces/remote-keyboard-protocol.md`).

  Lê o código do fragmento `#c=` e o apaga da barra de endereço; abre o canal na porta 47811 e se apresenta com o
  código ou, depois do primeiro `welcome`, com o token guardado em `sessionStorage`. As teclas vêm da mensagem
  `layout` e são montadas por APIs do DOM, sem HTML em texto. Cada dedo envia `down` ao tocar e `up` ao soltar;
  `ping` a cada 250 ms mantém o vigia do Mac; ao sair da tela a página manda `release`.

  Reconexão (§3.5): só depois de fechamento sem código de aplicação ou por tempo esgotado, a cada 1 s. `busy` (4001),
  a substituição por outra aba (4004), mensagens inválidas e as recusas do pareamento são finais.

  Sugestões de palavras (`009-sugestao-de-palavras` D-09 a D-12; protocolo em `interfaces/remote-keyboard-protocol.md`
  da 009): idioma e visibilidade da faixa ficam em `localStorage` e vão ao Mac em `prefs` depois de cada `welcome` e a
  cada troca. As palavras de `suggest` são desenhadas por `textContent`. Ao enviar `down` de uma tecla comum, a faixa
  esmaece até a próxima `suggest`; com modificador mantido ou preso, fica inativa. O toque numa sugestão envia `pick`
  com a revisão da lista, sem `down` nem `up`.

  Controle virtual (`010-joystick-virtual-iphone` D-02, D-08, RF-13): o teclado passa a morar no bloco central, que
  tem três estados. Em `full` desenha-se o teclado do Mac inteiro; em `compact`, o reduzido, com os modificadores,
  Esc, Tab, Return, apagar, espaço e setas; em `pointer` o teclado some e a área de apontamento ocupa o lugar. Ao
  trocar de estado, as teclas mantidas são soltas aqui mesmo, antes de o Mac saber (D-08). O canal é compartilhado
  com `controller.js` por `window.RemoteKeyboard`, que expõe o envio e os avisos de sessão.
*/
(function () {
  "use strict";

  var CHANNEL_PORT = 47811;
  var PING_MS = 250;
  var RETRY_MS = 1000;
  var OPEN_TIMEOUT_MS = 5000;
  var TOKEN_KEY = "remoteKeyboardToken";
  var PREFS_KEY = "remoteKeyboardPrefs";
  var ROW_UNITS = 15;
  var CAPS_LOCK = 57;

  // Teclado reduzido (`010-joystick-virtual-iphone` RF-13): duas linhas com o que a escrita curta pede.
  var COMPACT_ROWS = [
    [53, 48, 51, 36, 49],
    [56, 59, 58, 55, 123, 125, 126, 124]
  ];
  var COMPACT_WIDTHS = { 49: 5, 36: 2, 51: 2, 48: 2, 53: 2 };

  var CLOSE_BUSY = 4001;
  var CLOSE_BEFORE_HELLO = 4002;
  var CLOSE_INVALID = 4003;
  var CLOSE_REPLACED = 4004;

  // Teclas sem caractere: rótulo fixo (RF-04).
  var FIXED_LABELS = {
    53: "esc", 122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
    101: "F9", 109: "F10", 103: "F11", 111: "F12",
    51: "⌫", 48: "⇥", 36: "↩", 57: "⇪", 49: "",
    56: "⇧", 60: "⇧", 59: "⌃", 62: "⌃", 58: "⌥", 61: "⌥", 55: "⌘", 54: "⌘",
    123: "←", 125: "↓", 126: "↑", 124: "→"
  };

  var MODIFIER_CODES = {
    command: [55, 54],
    shift: [56, 60],
    option: [58, 61],
    control: [59, 62]
  };

  // Larguras em unidades de tecla; cada linha do Mac soma 15.
  var WIDTHS = {
    53: 1.5, 51: 2, 48: 1.5, 57: 1.75, 60: 2.75,
    59: 1, 58: 1, 55: 1.5, 49: 4, 54: 1.5, 61: 1, 62: 1
  };
  var FUNCTION_KEYS = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111];

  var keyboardEl = document.getElementById("keyboard");
  var statusEl = document.getElementById("status");
  var noticeEl = document.getElementById("notice");
  var leaveEl = document.getElementById("leave");
  var appEl = document.getElementById("app");
  var indicatorEl = document.getElementById("indicator");
  var stripEl = document.getElementById("strip");
  var langEl = document.getElementById("lang");
  var toggleEl = document.getElementById("toggle");
  var suggestionEls = Array.prototype.slice.call(stripEl.querySelectorAll(".suggestion"));

  var code = readCode();
  var token = readToken();
  var socket = null;
  var welcomed = false;
  var finished = false;
  var pingTimer = null;
  var retryTimer = null;
  var openTimer = null;

  var physical = "ansi";
  var labels = {};
  var modifiers = { command: "released", shift: "released", option: "released", control: "released" };
  var capsOn = false;
  var keyElements = {};
  var touches = {};

  // Ganchos do `controller.js`, que desenha o controle virtual e comanda o bloco central.
  var hooks = { welcome: null, message: null, release: null };

  var prefs = readPrefs();
  var statusOk = false;
  // Estado do bloco central; `controller.js` o comanda e o guarda nas preferências (D-08, D-11).
  var center = "compact";
  var lastLayout = null;
  // Última lista do Mac: `rev` e até três palavras.
  var offered = null;
  // Esmaecida desde o último `down` de tecla comum, até a próxima `suggest` (D-10).
  var stale = false;
  var picks = {};

  // MARK: - Credenciais

  function readCode() {
    var match = /^#c=(\d{6})$/.exec(window.location.hash);
    if (window.location.hash) {
      history.replaceState(null, "", window.location.pathname + window.location.search);
    }
    return match ? match[1] : null;
  }

  function readToken() {
    try {
      return window.sessionStorage.getItem(TOKEN_KEY);
    } catch (e) {
      return null;
    }
  }

  function storeToken(value) {
    token = value;
    try {
      if (value) {
        window.sessionStorage.setItem(TOKEN_KEY, value);
      } else {
        window.sessionStorage.removeItem(TOKEN_KEY);
      }
    } catch (e) {
      // Sem armazenamento, a sessão vale só enquanto a página estiver aberta.
    }
  }

  // MARK: - Preferências da faixa (D-11)

  function readPrefs() {
    var value = { lang: "pt", visible: true, center: "compact", sensitivity: 1, controls: true };
    try {
      var stored = JSON.parse(window.localStorage.getItem(PREFS_KEY));
      if (stored && (stored.lang === "pt" || stored.lang === "en")) {
        value.lang = stored.lang;
      }
      if (stored && typeof stored.visible === "boolean") {
        value.visible = stored.visible;
      }
      if (stored && (stored.center === "pointer" || stored.center === "compact" || stored.center === "full")) {
        value.center = stored.center;
      }
      if (stored && typeof stored.sensitivity === "number"
          && stored.sensitivity >= 0.5 && stored.sensitivity <= 2) {
        value.sensitivity = stored.sensitivity;
      }
      if (stored && typeof stored.controls === "boolean") {
        value.controls = stored.controls;
      }
    } catch (e) {
      // Sem armazenamento ou valor corrompido, vale o padrão.
    }
    return value;
  }

  function storePrefs() {
    try {
      window.localStorage.setItem(PREFS_KEY, JSON.stringify({
        lang: prefs.lang, visible: prefs.visible, center: prefs.center, sensitivity: prefs.sensitivity,
        controls: prefs.controls
      }));
    } catch (e) {
      // Sem armazenamento, a escolha vale só enquanto a página estiver aberta.
    }
  }

  function sendPrefs() {
    send({ t: "prefs", lang: prefs.lang, visible: prefs.visible });
  }

  function changePrefs(change) {
    change();
    storePrefs();
    offered = null;
    stale = false;
    applyPrefs();
    sendPrefs();
  }

  function applyPrefs() {
    langEl.textContent = prefs.lang === "en" ? "EN" : "PT";
    toggleEl.textContent = prefs.visible ? "Ocultar" : "Sugestões";
    appEl.classList.toggle("collapsed", !prefs.visible);
    renderStrip();
  }

  // MARK: - Canal

  function connect() {
    retryTimer = null;
    if (finished || socket) {
      return;
    }
    if (!code && !token) {
      finish("Escaneie o QR na tela do Mac para começar.");
      return;
    }
    setStatus(code ? "Conectando…" : "Reconectando…", "warn");
    var ws;
    try {
      ws = new WebSocket("wss://" + window.location.hostname + ":" + CHANNEL_PORT + "/ws");
    } catch (e) {
      scheduleRetry();
      return;
    }
    socket = ws;
    welcomed = false;
    openTimer = window.setTimeout(function () {
      if (socket === ws && ws.readyState !== WebSocket.OPEN) {
        ws.close();
      }
    }, OPEN_TIMEOUT_MS);
    ws.onopen = function () {
      window.clearTimeout(openTimer);
      var hello = { t: "hello", v: 1 };
      if (code) {
        hello.code = code;
      } else {
        hello.token = token;
      }
      ws.send(JSON.stringify(hello));
    };
    ws.onmessage = function (event) {
      if (socket === ws) {
        receive(event.data);
      }
    };
    ws.onclose = function (event) {
      if (socket === ws) {
        closed(event.code);
      }
    };
    ws.onerror = function () {
      // O `close` que vem em seguida decide a reconexão.
    };
  }

  function send(message) {
    if (socket && welcomed && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(message));
    }
  }

  function closed(closeCode) {
    window.clearTimeout(openTimer);
    stopPing();
    socket = null;
    welcomed = false;
    releaseLocal();
    offered = null;
    renderStrip();
    if (finished) {
      return;
    }
    switch (closeCode) {
      case CLOSE_BUSY:
        finish("Ocupado: outro aparelho está usando o teclado do Mac.");
        return;
      case CLOSE_REPLACED:
        finish("Sessão aberta noutra aba.");
        return;
      case CLOSE_BEFORE_HELLO:
      case CLOSE_INVALID:
        finish("O Mac encerrou a conexão. Escaneie o QR de novo para voltar.");
        return;
      default:
        if (closeCode >= 4000) {
          finish("O Mac encerrou a conexão.");
          return;
        }
        setStatus("Desconectado, tentando de novo…", "warn");
        scheduleRetry();
    }
  }

  function scheduleRetry() {
    if (!finished && !retryTimer) {
      retryTimer = window.setTimeout(connect, RETRY_MS);
    }
  }

  function finish(text) {
    finished = true;
    window.clearTimeout(retryTimer);
    retryTimer = null;
    stopPing();
    releaseLocal();
    setStatus("Desconectado", "warn");
    noticeEl.textContent = text;
    noticeEl.hidden = false;
    if (socket) {
      var ws = socket;
      socket = null;
      ws.close();
    }
  }

  function startPing() {
    stopPing();
    pingTimer = window.setInterval(function () {
      send({ t: "ping" });
    }, PING_MS);
  }

  function stopPing() {
    if (pingTimer) {
      window.clearInterval(pingTimer);
      pingTimer = null;
    }
  }

  // MARK: - Mensagens do Mac

  function receive(data) {
    var message;
    try {
      message = JSON.parse(data);
    } catch (e) {
      return;
    }
    if (!message || typeof message.t !== "string") {
      return;
    }
    switch (message.t) {
      case "welcome":
        welcomed = true;
        code = null;
        storeToken(message.token);
        noticeEl.hidden = true;
        offered = null;
        stale = false;
        setStatus("Conectado", "ok");
        startPing();
        sendPrefs();
        if (hooks.welcome) {
          hooks.welcome();
        }
        break;
      case "reject":
        rejected(message.reason);
        break;
      case "layout":
        buildLayout(message);
        break;
      case "modifiers":
        applyModifiers(message);
        break;
      case "caps":
        capsOn = message.on === true;
        applyCaps();
        break;
      case "suggest":
        receiveSuggestions(message);
        break;
      case "status":
        if (message.injection === "on") {
          setStatus("Conectado", "ok");
        } else {
          setStatus("Sem permissão de Acessibilidade no Mac", "warn");
        }
        break;
      default:
        if (hooks.message) {
          hooks.message(message);
        }
    }
  }

  function rejected(reason) {
    switch (reason) {
      case "busy":
        finish("Ocupado: outro aparelho está usando o teclado do Mac.");
        break;
      case "bad_token":
        storeToken(null);
        finish("A sessão terminou. Escaneie o QR na tela do Mac para voltar.");
        break;
      case "code_rotated":
        finish("O código mudou. Escaneie o novo QR na tela do Mac.");
        break;
      default:
        finish("Código recusado. Escaneie o QR na tela do Mac de novo.");
    }
  }

  // MARK: - Sugestões

  function receiveSuggestions(message) {
    if (typeof message.rev !== "number" || !Array.isArray(message.words)) {
      return;
    }
    offered = {
      rev: message.rev,
      words: message.words.filter(function (word) {
        return typeof word === "string" && word !== "";
      }).slice(0, suggestionEls.length)
    };
    stale = false;
    renderStrip();
  }

  function modifierActive() {
    return Object.keys(modifiers).some(function (name) {
      return modifiers[name] !== "released";
    });
  }

  // Com estado diferente de "Conectado", o texto do estado ocupa o lugar das sugestões (D-09).
  function renderStrip() {
    var showWords = statusOk && prefs.visible;
    statusEl.hidden = showWords;
    suggestionEls.forEach(function (button, i) {
      button.hidden = !showWords;
      var word = showWords && offered && i < offered.words.length ? offered.words[i] : "";
      button.textContent = word;
    });
    var state = modifierActive() ? "inactive" : stale ? "stale" : "";
    if (state) {
      stripEl.dataset.state = state;
    } else {
      delete stripEl.dataset.state;
    }
  }

  function isModifierCode(k) {
    return k === CAPS_LOCK || Object.keys(MODIFIER_CODES).some(function (name) {
      return MODIFIER_CODES[name].indexOf(k) >= 0;
    });
  }

  // Escolhe a sugestão sob o dedo (RN-11); lista velha, esmaecida ou inativa não faz nada no Mac.
  function pick(button) {
    var i = Number(button.dataset.i);
    if (!statusOk || !prefs.visible || !offered || stale || modifierActive() || !(i < offered.words.length)) {
      return;
    }
    send({ t: "pick", rev: offered.rev, i: i });
    stale = true;
    renderStrip();
  }

  function suggestionFor(target) {
    return target && target.closest ? target.closest(".suggestion") : null;
  }

  function stripTouchStart(event) {
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      var button = suggestionFor(touch.target);
      if (!button) {
        return;
      }
      event.preventDefault();
      if (button.textContent === "" || picks.hasOwnProperty(touch.identifier)) {
        return;
      }
      picks[touch.identifier] = button;
      button.classList.add("pressed");
    });
  }

  function stripTouchEnd(event) {
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      var button = picks[touch.identifier];
      if (!button) {
        return;
      }
      event.preventDefault();
      delete picks[touch.identifier];
      button.classList.remove("pressed");
      if (event.type === "touchend" && suggestionFor(document.elementFromPoint(touch.clientX, touch.clientY)) === button) {
        pick(button);
      }
    });
  }

  // MARK: - Desenho

  function width(k) {
    if (FUNCTION_KEYS.indexOf(k) >= 0) {
      return 1.125;
    }
    if (physical === "iso") {
      if (k === 42) return 1;
      if (k === 36) return 1.25;
      if (k === 56) return 1.25;
    } else {
      if (k === 42) return 1.5;
      if (k === 36) return 2.25;
      if (k === 56) return 2.25;
    }
    return WIDTHS[k] || 1;
  }

  function buildLayout(message) {
    if (!Array.isArray(message.rows) || !Array.isArray(message.keys)) {
      return;
    }
    physical = message.physical === "iso" ? "iso" : "ansi";
    labels = {};
    message.keys.forEach(function (entry) {
      if (entry && typeof entry.k === "number") {
        labels[entry.k] = entry;
      }
    });
    lastLayout = message.rows;
    drawKeyboard();
  }

  /// Desenha o teclado do estado em vigor: completo em `full`, reduzido em `compact`, nenhum em `pointer`.
  function drawKeyboard() {
    releaseLocal();
    keyElements = {};
    if (center === "pointer" || !lastLayout) {
      keyboardEl.replaceChildren();
      return;
    }
    var source = center === "compact" ? COMPACT_ROWS : lastLayout;
    var full = center === "compact" ? compactUnits() : ROW_UNITS;
    var rows = source.map(function (codes) {
      var row = document.createElement("div");
      row.className = "row";
      var total = 0;
      codes.forEach(function (k) {
        if (typeof k !== "number") {
          return;
        }
        var key = document.createElement("div");
        key.className = labels[k] ? "key" : "key special";
        key.dataset.k = String(k);
        var span = center === "compact" ? compactWidth(k) : width(k);
        key.style.flexGrow = String(span);
        total += span;
        keyElements[k] = key;
        row.appendChild(key);
      });
      if (total < full) {
        var spacer = document.createElement("div");
        spacer.className = "spacer";
        spacer.style.flexGrow = String(full - total);
        row.appendChild(spacer);
      }
      return row;
    });
    keyboardEl.replaceChildren.apply(keyboardEl, rows);
    applyModifiers(modifiers);
    applyCaps();
  }

  function compactWidth(k) {
    return COMPACT_WIDTHS.hasOwnProperty(k) ? COMPACT_WIDTHS[k] : 1;
  }

  // As duas linhas do teclado reduzido somam o mesmo total, para as teclas ficarem alinhadas.
  function compactUnits() {
    return COMPACT_ROWS.reduce(function (most, codes) {
      var total = codes.reduce(function (sum, k) { return sum + compactWidth(k); }, 0);
      return Math.max(most, total);
    }, 0);
  }

  function applyModifiers(message) {
    Object.keys(MODIFIER_CODES).forEach(function (name) {
      var state = message[name];
      if (state !== "held" && state !== "latched") {
        state = "released";
      }
      modifiers[name] = state;
      MODIFIER_CODES[name].forEach(function (k) {
        var key = keyElements[k];
        if (!key) {
          return;
        }
        if (state === "released") {
          delete key.dataset.state;
        } else {
          key.dataset.state = state;
        }
      });
    });
    relabel();
    renderStrip();
  }

  // A trava do Caps Lock é do sistema; o Mac avisa a cada toque no ⇪ e no início da sessão.
  function applyCaps() {
    var key = keyElements[CAPS_LOCK];
    if (key) {
      if (capsOn) {
        key.dataset.state = "latched";
      } else {
        delete key.dataset.state;
      }
    }
    relabel();
  }

  // Rótulos no estado dos modificadores: ⇧ e ⌥ mudam o que cada tecla escreve (RF-05).
  function relabel() {
    var shift = modifiers.shift !== "released";
    var option = modifiers.option !== "released";
    var state = shift && option ? "shiftOption" : shift ? "shift" : option ? "option" : "plain";
    Object.keys(keyElements).forEach(function (k) {
      var key = keyElements[k];
      var entry = labels[k];
      if (!entry) {
        key.textContent = FIXED_LABELS.hasOwnProperty(k) ? FIXED_LABELS[k] : "";
        return;
      }
      var text = entry[state];
      // Com a trava ligada e sem ⇧ nem ⌥, letras aparecem maiúsculas, como o Mac as escreverá.
      if (capsOn && state === "plain" && typeof entry.shift === "string" && entry.plain.toUpperCase() === entry.shift) {
        text = entry.shift;
      }
      key.textContent = typeof text === "string" && text !== "" ? text : entry.plain || "";
      var dead = Array.isArray(entry.dead) && entry.dead.indexOf(state) >= 0;
      key.classList.toggle("dead", dead);
    });
  }

  // MARK: - Toque

  function keyFor(target) {
    return target && target.closest ? target.closest(".key") : null;
  }

  function touchStart(event) {
    event.preventDefault();
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      var key = keyFor(touch.target);
      if (!key || touches.hasOwnProperty(touch.identifier)) {
        return;
      }
      touches[touch.identifier] = key;
      key.classList.add("pressed");
      var k = Number(key.dataset.k);
      send({ t: "down", k: k, ts: Date.now() });
      if (!isModifierCode(k) && !stale) {
        stale = true;
        renderStrip();
      }
    });
  }

  // Só cancela o evento dos dedos que começaram numa tecla, para o toque no botão "Sair" virar clique.
  function touchEnd(event) {
    Array.prototype.forEach.call(event.changedTouches, function (touch) {
      var key = touches[touch.identifier];
      if (!key) {
        return;
      }
      event.preventDefault();
      delete touches[touch.identifier];
      if (!isTouched(key)) {
        key.classList.remove("pressed");
        send({ t: "up", k: Number(key.dataset.k), ts: Date.now() });
      }
    });
  }

  function isTouched(key) {
    return Object.keys(touches).some(function (id) {
      return touches[id] === key;
    });
  }

  function releaseLocal() {
    Object.keys(touches).forEach(function (id) {
      touches[id].classList.remove("pressed");
    });
    touches = {};
    Object.keys(picks).forEach(function (id) {
      picks[id].classList.remove("pressed");
    });
    picks = {};
    if (hooks.release) {
      hooks.release();
    }
  }

  /// Troca do bloco central, pedida pelo `controller.js` (D-08): as teclas mantidas por toque são soltas aqui, e o
  /// Mac solta as suas ao receber o `mode`.
  function setCenter(value) {
    if (value !== "pointer" && value !== "compact" && value !== "full") {
      return;
    }
    if (center === value) {
      return;
    }
    releaseKeys();
    center = value;
    appEl.dataset.center = value;
    drawKeyboard();
  }

  /// Solta no Mac as teclas que o dedo ainda mantém, antes de o desenho mudar sob ele.
  function releaseKeys() {
    Object.keys(touches).forEach(function (id) {
      var key = touches[id];
      delete touches[id];
      key.classList.remove("pressed");
      send({ t: "up", k: Number(key.dataset.k), ts: Date.now() });
    });
  }

  // Sair da tela solta tudo no Mac (D-11); a volta reconecta de imediato se o iOS fechou o canal.
  function hidden() {
    send({ t: "release" });
    releaseLocal();
  }

  function setStatus(text, kind) {
    statusEl.textContent = text;
    statusEl.dataset.kind = kind;
    indicatorEl.dataset.kind = kind;
    statusOk = kind === "ok";
    renderStrip();
  }

  keyboardEl.addEventListener("touchstart", touchStart, { passive: false });
  stripEl.addEventListener("touchstart", stripTouchStart, { passive: false });
  document.addEventListener("touchend", stripTouchEnd, { passive: false });
  document.addEventListener("touchcancel", stripTouchEnd, { passive: false });
  document.addEventListener("touchend", touchEnd, { passive: false });
  document.addEventListener("touchcancel", touchEnd, { passive: false });
  document.addEventListener("touchmove", function (event) {
    // O seletor de sensibilidade do apontamento é o único controle que precisa do arrasto do navegador (RF-20).
    if (event.target && event.target.closest && event.target.closest(".sensitivity")) {
      return;
    }
    event.preventDefault();
  }, { passive: false });
  document.addEventListener("gesturestart", function (event) {
    event.preventDefault();
  });

  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "hidden") {
      hidden();
    } else if (!finished && !socket) {
      window.clearTimeout(retryTimer);
      connect();
    }
  });
  window.addEventListener("pagehide", hidden);

  leaveEl.addEventListener("click", function () {
    send({ t: "bye" });
    storeToken(null);
    finish("Sessão encerrada. Para voltar, escaneie o QR na tela do Mac.");
  });

  langEl.addEventListener("click", function () {
    changePrefs(function () {
      prefs.lang = prefs.lang === "pt" ? "en" : "pt";
    });
  });

  toggleEl.addEventListener("click", function () {
    changePrefs(function () {
      prefs.visible = !prefs.visible;
    });
  });

  window.RemoteKeyboard = {
    send: send,
    prefs: prefs,
    storePrefs: storePrefs,
    setCenter: setCenter,
    center: function () { return center; },
    isConnected: function () { return welcomed; },
    on: function (name, handler) { hooks[name] = handler; }
  };

  applyPrefs();
  appEl.dataset.center = center;
  // O `connect` sai do quadro atual para o `controller.js` registrar seus ganchos antes do primeiro `welcome`.
  window.setTimeout(connect, 0);
})();
