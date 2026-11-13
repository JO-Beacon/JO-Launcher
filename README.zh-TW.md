<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>一個面向 Minecraft: Java Edition 的 Windows 桌面啟動器。Linux 支援已在計畫中。</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">官網</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">最新版本</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <b>繁體中文</b> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

## 系統需求

- Windows 10 或 11，x64
- 要啟動的 Minecraft 版本所需的 Java 執行環境（自動偵測，也可依版本手動指定）
- 擁有 Minecraft: Java Edition 的 Microsoft 帳號
- 自己的 Azure 應用程式（用戶端）ID，用於登入

## 功能

- 啟動本機已安裝的 Minecraft 版本
- 依版本設定：Java 執行環境、記憶體上限、JVM 參數
- 依本機實體記憶體自動規劃記憶體，可依版本覆寫
- 匯入版本資料夾或 zip，重新命名、刪除版本
- 診斷記錄（設定 → 記錄），方便排查問題
- 依版本隔離遊戲目錄：存檔、選項和模組都保存在各自版本資料夾中，不同版本互不影響
- 透過裝置碼流程登入 Microsoft 帳號；可在 設定 → 帳號 填寫自己的 Azure 應用程式（用戶端）ID，也可使用 `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID` 環境變數
- 10 種介面語言：English、简体中文、繁體中文、日本語、한국어、Deutsch、Español、Français、Português、Svenska
- 深色、淺色和跟隨系統主題
- 優先使用 exe 旁的可攜 `.minecraft` 資料夾，否則使用 `%APPDATA%\.minecraft`

## 目錄結構

```text
core/                 platform-independent C++20 core
  auth/               Microsoft / Xbox / Minecraft sign-in
  launch/             version manifests, Java detection, process launch
  mc/                 version scanning and per-version settings
  net/                HTTP transport
  platform/           OS backends: HTTP, key storage, process
platform/win32/       Win32 + Direct2D shell
assets/icon/          icon sources (SVG); the .ico is generated, not tracked
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## 建置（Windows）

需要安裝 Visual Studio 2022 或 2026 的 C++ 工作負載（或對應的 Build Tools）、CMake 3.25+，以及含 Pillow 的 Python 3。圖示不納入版本控制，建置前先執行 `python tools/export-icons.py`，它以無頭 Edge 或 Chrome 從 SVG 產生各尺寸。

可選依賴（實驗性）：把 [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) 檢出到倉庫同層目錄，設定時加 `-DJO_USE_DRAFTUI=ON` 即可啟用；預設關閉，沒有它也能正常建置。目前介面仍以手寫 D2D 繪製為準。

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
cmake --build build/native --config Release
```

產生的結果：

```text
build/native/Release/JO-Launcher.exe
```

執行檔靜態連結 MSVC 執行階段。

## 狀態

目前只有 Win32 殼層。Linux 的 HTTP、密鑰儲存和處理程序後端已位於 `core/platform/` 下，但 GTK 殼層尚未開始。

## 授權條款

JO-Launcher 採用 Apache License 2.0 授權，詳見 [LICENSE](./LICENSE)。
圖示（`assets/icon/`、`platform/win32/app.ico`、站點圖示）不在 Apache-2.0 範圍內，保留所有權利：未經任何修改、與官方版本一致的 JO-Launcher 可原樣隨附散布；任何改動（含 fork、改名、改版本號）都必須替換圖示，詳見 [assets/icon/LICENSE](./assets/icon/LICENSE)。
再散布時必須包含 [NOTICE](./NOTICE)，並保留其中引用的第三方聲明。隱私說明：[PRIVACY.md](./PRIVACY.md)。

非 Minecraft 官方產品，未經 Mojang 或 Microsoft 批准或關聯。Minecraft、Mojang、Microsoft 和 Xbox 是 Microsoft Corporation 或其關聯公司的商標。
