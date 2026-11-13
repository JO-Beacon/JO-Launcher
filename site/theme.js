/* 主题三态：自动（跟随系统）/ 深色 / 浅色。
   选择存在 localStorage 的 jol-theme；"system" 时不留键。
   无脚本时按系统色由 CSS 媒体查询决定，这里只负责手动覆盖。 */
(function () {
  "use strict";

  var KEY = "jol-theme";
  var root = document.documentElement;
  var buttons = document.querySelectorAll("[data-theme-set]");
  var metas = document.querySelectorAll('meta[name="theme-color"]');
  var media = window.matchMedia("(prefers-color-scheme: light)");

  /* 移动端浏览器工具栏 / PWA 标题栏的颜色，取软件同一套底色 */
  var COLORS = { dark: "#0e0f12", light: "#f5f2ec" };

  function effectiveScheme(mode) {
    if (mode === "dark" || mode === "light") return mode;
    return media.matches ? "light" : "dark";
  }

  /* 手选主题时，把 meta 上按系统走的 media 去掉，改成当前实际生效的那一色；
     两条 meta 都写成同一个值，避免浏览器在其中挑到不一致的一条。 */
  function syncThemeColor(mode) {
    var color = COLORS[effectiveScheme(mode)];
    for (var i = 0; i < metas.length; i++) {
      metas[i].setAttribute("content", color);
      metas[i].removeAttribute("media");
    }
  }

  function read() {
    try {
      var value = localStorage.getItem(KEY);
      return value === "dark" || value === "light" ? value : "system";
    } catch (error) {
      return "system";
    }
  }

  function write(mode) {
    try {
      if (mode === "system") {
        localStorage.removeItem(KEY);
      } else {
        localStorage.setItem(KEY, mode);
      }
    } catch (error) {
      /* 隐私模式下写不进去，本次会话仍生效即可 */
    }
  }

  function render(mode) {
    if (mode === "dark" || mode === "light") {
      root.setAttribute("data-theme", mode);
    } else {
      root.removeAttribute("data-theme");
    }
    for (var i = 0; i < buttons.length; i++) {
      var active = buttons[i].getAttribute("data-theme-set") === mode;
      buttons[i].setAttribute("aria-pressed", active ? "true" : "false");
    }
    syncThemeColor(mode);
  }

  for (var i = 0; i < buttons.length; i++) {
    buttons[i].addEventListener("click", function () {
      var mode = this.getAttribute("data-theme-set") || "system";
      write(mode);
      render(mode);
    });
  }

  render(read());

  /* 跟随系统时，系统切换由 CSS 处理；这里保持按钮状态，并同步工具栏颜色 */
  var onChange = function () {
    if (read() === "system") render("system");
  };
  if (typeof media.addEventListener === "function") {
    media.addEventListener("change", onChange);
  } else if (typeof media.addListener === "function") {
    media.addListener(onChange);
  }
})();
