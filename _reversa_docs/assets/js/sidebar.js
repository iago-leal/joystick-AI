// sidebar.js · liga controles [data-param] a um barramento de eventos e persiste em localStorage.
// Uso: RVSidebar.init({ onChange: function(name, value, all) {...}, defaults: {...} })
window.RVSidebar = (function () {
  var store = {}, key = "rv:" + (document.body.getAttribute("data-page-id") || "page") + ":params";
  function read(el) {
    if (el.type === "checkbox") return el.checked;
    if (el.type === "range" || el.type === "number") return parseFloat(el.value);
    return el.value;
  }
  function write(el, v) {
    if (el.type === "checkbox") el.checked = !!v; else el.value = v;
    var out = el.parentElement && el.parentElement.querySelector(".value");
    if (out) out.textContent = el.type === "checkbox" ? "" : v;
  }
  function init(opts) {
    opts = opts || {};
    var saved = {};
    try { saved = JSON.parse(localStorage.getItem(key) || "{}"); } catch (e) { saved = {}; }
    var els = document.querySelectorAll("[data-param]");
    els.forEach(function (el) {
      var name = el.getAttribute("data-param");
      var v = (opts.defaults && name in opts.defaults) ? opts.defaults[name] : read(el);
      if (name in saved && !opts.ignoreSaved) v = saved[name];
      write(el, v); store[name] = read(el);
      el.addEventListener("input", function () {
        store[name] = read(el); write(el, store[name]);
        try { localStorage.setItem(key, JSON.stringify(store)); } catch (e) {}
        if (opts.onChange) opts.onChange(name, store[name], store);
      });
    });
    var toggle = document.querySelector(".rv-sidebar-toggle");
    if (toggle) toggle.addEventListener("click", function () {
      var lay = document.querySelector(".rv-canvas-layout"); lay.classList.toggle("collapsed");
      window.dispatchEvent(new Event("resize"));
    });
    var reset = document.getElementById("reset");
    if (reset) reset.addEventListener("click", function () {
      try { localStorage.removeItem(key); } catch (e) {}
      els.forEach(function (el) {
        var name = el.getAttribute("data-param");
        var v = (opts.defaults && name in opts.defaults) ? opts.defaults[name] : el.getAttribute("data-default");
        if (v == null) v = el.defaultValue;
        if (el.type === "checkbox") v = el.defaultChecked; else if (el.type === "range") v = parseFloat(el.getAttribute("value"));
        write(el, v); store[name] = read(el);
      });
      if (opts.onReset) opts.onReset(store); else if (opts.onChange) opts.onChange("*", null, store);
    });
    return store;
  }
  return { init: init, get: function () { return store; } };
})();
