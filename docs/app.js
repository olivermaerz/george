(function () {
  function bindTabs(rootSelector, imageId) {
    var root = document.querySelector(rootSelector);
    var image = document.getElementById(imageId);
    if (!root || !image) return;

    root.addEventListener("click", function (event) {
      var button = event.target.closest("button[data-src]");
      if (!button || !root.contains(button)) return;

      root.querySelectorAll("button[role='tab']").forEach(function (tab) {
        tab.setAttribute("aria-selected", tab === button ? "true" : "false");
      });

      image.src = button.getAttribute("data-src");
      image.alt = button.getAttribute("data-alt") || "";
    });
  }

  bindTabs(".menu-toggle", "menu-shot");
  bindTabs(".segmented", "tour-shot");
})();
