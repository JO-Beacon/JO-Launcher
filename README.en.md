# JO-Launcher

A Windows desktop launcher for Minecraft: Java Edition. Linux support is planned.

[**English**](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Português](README.pt-BR.md) · [Svenska](README.sv.md)

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
- Diagnostic log file (Settings → About → Logs) for troubleshooting
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
platform/win32/       Win32 + Direct2D shell
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## Build (Windows)

Requires Visual Studio 2022 or 2026 with the C++ workload (or the matching Build Tools) and CMake 3.25+.

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
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
Redistributions must include [NOTICE](./NOTICE) and keep the third-party notices it
references. Privacy notice: [PRIVACY.md](./PRIVACY.md).

Not an official Minecraft product. Not approved by or associated with Mojang or
Microsoft. Minecraft, Mojang, Microsoft and Xbox are trademarks of Microsoft
Corporation or its affiliates.
