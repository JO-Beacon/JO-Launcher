<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>A Windows desktop launcher for Minecraft: Java Edition. Linux support is planned.</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">Website</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">Latest release</a>
  </p>

  <p>
    <b>English</b> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

## Requirements

- Windows 10 or 11, x64
- A Java runtime for the Minecraft version you want to launch (detected automatically; can be set per version)
- A Microsoft account that owns Minecraft: Java Edition
- Your own Azure application (client) ID for sign-in

## Features

- Launches Minecraft versions that are already installed on your machine
- Per-version settings: Java runtime, memory limits, JVM arguments
- Automatic memory planning based on installed RAM, overridable per version
- Import a version folder or zip, rename and delete versions
- Diagnostic log file (Settings → Logs) for troubleshooting
- Per-version game directory: saves, options and mods live inside each version
  folder, so different versions stay isolated
- Microsoft sign-in through the device-code flow; set your own Azure application (client) ID in Settings → Account, or through the `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID` environment variable
- 10 interface languages: English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- Dark, light and system-following themes
- Uses a portable `.minecraft` folder next to the executable, otherwise `%APPDATA%\.minecraft`

## Layout

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

## Build (Windows)

Requires Visual Studio 2022 or 2026 with the C++ workload (or the matching Build Tools), CMake 3.25+, and Python 3 with Pillow. The icon is not tracked: run `python tools/export-icons.py` before building — it renders every frame from the SVG through headless Edge or Chrome.

Optional (experimental): check out [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) next to this repository and configure with `-DJO_USE_DRAFTUI=ON` to use it; it is off by default and the build works without it. The interface is still painted with hand-written Direct2D code.

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
cmake --build build/native --config Release
```

Result:

```text
build/native/Release/JO-Launcher.exe
```

The executable is statically linked against the MSVC runtime.

## Status

The Win32 shell is the only implemented UI. The Linux HTTP, secret-storage and process backends exist under `core/platform/`, but the GTK shell has not been started yet.

## License

JO-Launcher is licensed under the Apache License 2.0; see [LICENSE](./LICENSE).
The icons (`assets/icon/`, `platform/win32/app.ico` and the site icons) are not covered by the Apache License 2.0 and remain all rights reserved: they may ship with a JO-Launcher that is unmodified and identical to the official version, while any change — including forks, a renamed build or a version bump — requires replacing them; see [assets/icon/LICENSE](./assets/icon/LICENSE).
Redistributions must include [NOTICE](./NOTICE) and keep the third-party notices it
references. Privacy notice: [PRIVACY.md](./PRIVACY.md).

Not an official Minecraft product. Not approved by or associated with Mojang or
Microsoft. Minecraft, Mojang, Microsoft and Xbox are trademarks of Microsoft
Corporation or its affiliates.
