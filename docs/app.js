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
      var srcset = button.getAttribute("data-srcset");
      if (srcset) image.srcset = srcset;
      else image.removeAttribute("srcset");
      image.alt = button.getAttribute("data-alt") || "";
    });
  }
  // Georgie boy! Get the TV reference?
  bindTabs(".menu-toggle", "menu-shot");
  bindTabs(".segmented", "tour-shot");

  var dialog = document.getElementById("license-dialog");
  if (dialog) {
    document.querySelectorAll("[data-open-license]").forEach(function (button) {
      button.addEventListener("click", function () {
        if (typeof dialog.showModal === "function") dialog.showModal();
      });
    });
    document.querySelectorAll("[data-close-license]").forEach(function (button) {
      button.addEventListener("click", function () {
        dialog.close();
      });
    });
    dialog.addEventListener("click", function (event) {
      if (event.target === dialog) dialog.close();
    });
  }
})();
