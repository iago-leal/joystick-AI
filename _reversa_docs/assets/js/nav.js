// nav.js · marca a página atual no menu e cuida do menu móvel. Sem fetch, sem dependências.
(function () {
  var pageId = document.body.getAttribute("data-page-id") || "";
  var nav = document.querySelector(".reversa-doc-nav");
  if (nav) {
    nav.querySelectorAll("a[data-page-id]").forEach(function (a) {
      var id = a.getAttribute("data-page-id");
      if (id === pageId || (id === "features" && pageId.indexOf("feature-") === 0)) a.setAttribute("aria-current", "page");
    });
  }
  var toggle = document.querySelector(".rv-nav-toggle");
  if (toggle && nav) toggle.addEventListener("click", function () { nav.classList.toggle("open"); });
  // mini-selo: se o Publisher já injetou window.RV_DATA.sealMiniSvg e o header ainda tem placeholder, preenche
  try {
    var slot = document.querySelector(".rv-brand .seal-slot");
    if (slot && window.RV_DATA && window.RV_DATA.sealMiniSvg && !slot.querySelector("svg")) slot.innerHTML = window.RV_DATA.sealMiniSvg;
  } catch (e) {}
})();
