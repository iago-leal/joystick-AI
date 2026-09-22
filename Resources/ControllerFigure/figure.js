/*
  Script da figura do controle (`004-figura-controle-web` D-07, D-08, D-16, D-17, D-18, RN-04, RN-07, RN-09).
  Um objeto global `figure` com `render(state)`: escreve rótulo e resumo por `textContent`, aplica os estados
  por `classList` e o controle ativo por `data-controller` (`007-controle-ipega` D-08). O clique em qualquer parte de um grupo `[data-button]` envia `{ button: id }` ao app.
  Nunca constrói marcação a partir de texto; sem temporizadores, sem armazenamento, sem rede.
*/
(function () {
  'use strict';

  /*
    Posição do balão de cada botão (canto superior esquerdo, em px da área de 830 × 620) e o lado do balão onde a
    linha-guia encosta (D-16). Faixa superior: L2, Create, Options, R2 e, numa segunda linha ao centro, Touchpad.
    Coluna esquerda: L1, ↑, ←, →, ↓, L3. Coluna direita: R1, △, ○, □, ✕, R3. Faixa inferior: PS. Os gatilhos L2 e R2
    ficam no alto porque a figura é vista de cima, com a borda de trás do controle para cima (emenda E003). As alturas das
    colunas não são uniformes: as de → e □ foram escolhidas para a linha-guia passar entre os braços do direcional
    (e entre □ e ✕) sem cruzar outro botão. Balões de 190 × 64 px.
    O Share do Ipega (`007-controle-ipega` D-09) não tem faixa livre de 190 px: ocupa, com um balão compacto de 104 px, o
    vão inferior entre L3 e PS. Posição provisória, a confirmar no ajuste visual do portão manual PM-1.
  */
  var BALLOON_WIDTH = 190;
  var BALLOON_HEIGHT = 64;
  var positions = {
    l2: { x: 8, y: 8, side: 'bottom' },
    create: { x: 216, y: 8, side: 'bottom' },
    options: { x: 424, y: 8, side: 'bottom' },
    r2: { x: 632, y: 8, side: 'bottom' },
    touchpadClick: { x: 320, y: 80, side: 'bottom' },
    l1: { x: 8, y: 108, side: 'right' },
    dpadUp: { x: 8, y: 191, side: 'right' },
    dpadLeft: { x: 8, y: 262, side: 'right' },
    dpadRight: { x: 8, y: 334, side: 'right' },
    dpadDown: { x: 8, y: 441, side: 'right' },
    l3: { x: 8, y: 524, side: 'right' },
    r1: { x: 632, y: 108, side: 'left' },
    triangle: { x: 632, y: 191, side: 'left' },
    circle: { x: 632, y: 262, side: 'left' },
    square: { x: 632, y: 334, side: 'left' },
    cross: { x: 632, y: 441, side: 'left' },
    r3: { x: 632, y: 524, side: 'left' },
    ps: { x: 320, y: 552, side: 'top' },
    share: { x: 208, y: 552, side: 'top', width: 104 }
  };

  /* `data-controller` da raiz: os valores que a página conhece, `ControllerModel.rawValue` do app (`007-controle-ipega`
     D-08; `012-controle-dualshock-4` D-08, que acrescenta o DualShock 4 com a figura do DualSense). Valor desconhecido
     ou ausente vale `dualSense`. */
  var CONTROLLERS = { dualSense: true, ipega: true, dualShock4: true };

  var KIND_CLASSES = { fixed: 'is-fixed', modifier: 'is-modifier', inherited: 'is-inherited' };
  var STATE_CLASSES = ['is-fixed', 'is-modifier', 'is-inherited', 'is-problem', 'is-selected'];

  /* Nós de cada botão conhecido: grupo do SVG e balão. Só identificadores da tabela entram aqui. */
  var nodes = {};
  var root = document.querySelector('.figure');

  function collectNodes() {
    var elements = document.querySelectorAll('[data-button]');
    for (var i = 0; i < elements.length; i += 1) {
      var element = elements[i];
      var id = element.getAttribute('data-button');
      if (!Object.prototype.hasOwnProperty.call(positions, id)) { continue; }
      var entry = nodes[id] || (nodes[id] = { targets: [], label: null, summary: null, guide: null, shape: null, center: null });
      entry.targets.push(element);
      if (element.classList.contains('balloon')) {
        entry.summary = element.querySelector('.summary');
      } else {
        entry.label = element.querySelector('.label');
        entry.guide = element.querySelector('.guide');
        entry.shape = element.querySelector('.shape');
        var hit = element.querySelector('.hit');
        if (hit) {
          entry.center = {
            x: parseFloat(hit.getAttribute('x')) + parseFloat(hit.getAttribute('width')) / 2,
            y: parseFloat(hit.getAttribute('y')) + parseFloat(hit.getAttribute('height')) / 2
          };
        }
      }
    }
  }

  /* Coloca cada balão na posição da tabela e liga a linha-guia do centro do botão à borda do balão. */
  function layout() {
    var ids = Object.keys(positions);
    for (var i = 0; i < ids.length; i += 1) {
      var id = ids[i];
      var entry = nodes[id];
      var position = positions[id];
      if (!entry) { continue; }
      for (var t = 0; t < entry.targets.length; t += 1) {
        var target = entry.targets[t];
        if (target.classList.contains('balloon')) {
          target.style.left = position.x + 'px';
          target.style.top = position.y + 'px';
          if (position.width) { target.style.width = position.width + 'px'; }
        }
      }
      if (entry.guide && entry.center) {
        var anchor = anchorPoint(position);
        var start = edgePoint(entry.shape, entry.center, anchor);
        entry.guide.setAttribute('x1', String(start.x));
        entry.guide.setAttribute('y1', String(start.y));
        entry.guide.setAttribute('x2', String(anchor.x));
        entry.guide.setAttribute('y2', String(anchor.y));
      }
    }
  }

  /* Ponto em que a linha-guia sai do desenho: borda da forma (com folga de 4 px) na direção do balão. */
  var GUIDE_GAP = 4;
  function edgePoint(shape, center, target) {
    var dx = target.x - center.x;
    var dy = target.y - center.y;
    var distance = Math.sqrt(dx * dx + dy * dy);
    if (!shape || distance === 0) { return center; }
    var t;
    if (shape.tagName === 'circle') {
      t = (parseFloat(shape.getAttribute('r')) + GUIDE_GAP) / distance;
    } else {
      var box = shape.getBBox();
      var tx = dx === 0 ? Infinity : (box.width / 2 + GUIDE_GAP) / Math.abs(dx);
      var ty = dy === 0 ? Infinity : (box.height / 2 + GUIDE_GAP) / Math.abs(dy);
      t = Math.min(tx, ty);
    }
    if (t >= 1) { return center; }
    return { x: center.x + dx * t, y: center.y + dy * t };
  }

  function anchorPoint(position) {
    var width = position.width || BALLOON_WIDTH;
    switch (position.side) {
      case 'left': return { x: position.x, y: position.y + BALLOON_HEIGHT / 2 };
      case 'right': return { x: position.x + width, y: position.y + BALLOON_HEIGHT / 2 };
      case 'top': return { x: position.x + width / 2, y: position.y };
      default: return { x: position.x + width / 2, y: position.y + BALLOON_HEIGHT };
    }
  }

  function applyClasses(element, item) {
    for (var i = 0; i < STATE_CLASSES.length; i += 1) {
      element.classList.remove(STATE_CLASSES[i]);
    }
    var kindClass = KIND_CLASSES[item.kind];
    if (kindClass) { element.classList.add(kindClass); }
    if (item.problem === true) { element.classList.add('is-problem'); }
    if (item.selected === true) { element.classList.add('is-selected'); }
  }

  /* App → página (D-07). Idempotente; itens com `id` desconhecido são ignorados. */
  function render(state) {
    if (!state || !Array.isArray(state.buttons)) { return; }
    var controller = typeof state.controller === 'string' && Object.prototype.hasOwnProperty.call(CONTROLLERS, state.controller)
      ? state.controller : 'dualSense';
    if (root) { root.setAttribute('data-controller', controller); }
    for (var i = 0; i < state.buttons.length; i += 1) {
      var item = state.buttons[i];
      if (!item || typeof item.id !== 'string') { continue; }
      if (!Object.prototype.hasOwnProperty.call(nodes, item.id)) { continue; }
      var entry = nodes[item.id];
      if (entry.label && typeof item.label === 'string') { entry.label.textContent = item.label; }
      if (entry.summary && typeof item.summary === 'string') { entry.summary.textContent = item.summary; }
      for (var t = 0; t < entry.targets.length; t += 1) {
        applyClasses(entry.targets[t], item);
      }
    }
  }

  /* Página → app (D-08): só o identificador do grupo clicado. */
  function post(id) {
    var webkit = window.webkit;
    if (!webkit || !webkit.messageHandlers || !webkit.messageHandlers.figure) { return; }
    webkit.messageHandlers.figure.postMessage({ button: id });
  }

  document.addEventListener('click', function (event) {
    var target = event.target;
    if (!(target instanceof Element)) { return; }
    var group = target.closest('[data-button]');
    if (!group) { return; }
    var id = group.getAttribute('data-button');
    if (!Object.prototype.hasOwnProperty.call(nodes, id)) { return; }
    event.preventDefault();
    post(id);
  });

  document.addEventListener('contextmenu', function (event) { event.preventDefault(); });
  document.addEventListener('dragstart', function (event) { event.preventDefault(); });

  collectNodes();
  layout();

  window.figure = { render: render };
}());
