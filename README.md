# JO-Launcher

[![CI](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml/badge.svg)](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml)

JO-Launcher is an open-source launcher for Minecraft: Java Edition, focused on launching existing game installations with a clean, responsive desktop experience. Windows is supported today; Linux support is on the roadmap.

[English](./README.md) · [日本語](./README_ja.md) · [Svenska](./README_sv.md) · [Português (Brasil)](./README_pt_BR.md) · [Español](./README_es.md) · [Français](./README_fr.md) · [Deutsch](./README_de.md) · [Website](https://jo-beacon.github.io/JO-Launcher/) · [Privacy](./PRIVACY.md) · [Apache License 2.0](./LICENSE)

![JO-Launcher](docs/screenshot.png)

> **NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

## Features

- **Version discovery** — scans `versions/` and recognizes vanilla, Fabric, Quilt, Forge and NeoForge installations.
- **Version settings** — configure Java, memory limits and JVM arguments per version; settings live in `jolauncher.json` inside the version directory.
- **Microsoft sign-in** — sign in with a Microsoft account through the device-code flow.
- **Launch workspace** — choose a version, start the game, follow the live log and stop the process.
- **Desktop experience** — dark / light / follow-system themes, a draggable sidebar and seven interface languages.

## Roadmap

- Version management: install from user-provided local files, import modpacks, delete and rename
- Linux desktop support
- Account avatars and account switching
- Crash diagnostics and recovery

## Contributing

Issues are welcome. Pull requests are **not** accepted and will be closed automatically. See [CONTRIBUTING.md](./CONTRIBUTING.md) before opening an issue.

## Tech stack

Flutter / Dart.

## Building

You need the Flutter SDK. On Windows, Inno Setup is only needed to produce the installer.

Microsoft sign-in requires the client_id of an Azure application. **It is not stored in this repository**; pass it at build time through an environment variable:

```powershell
$env:JO_MS_CLIENT_ID = "<your client_id>"
pwsh -ExecutionPolicy Bypass -File scripts\build.ps1
```

To build the app without the installer:

```powershell
flutter build windows --release --dart-define=JO_MS_CLIENT_ID=$env:JO_MS_CLIENT_ID
```

The app still builds without `JO_MS_CLIENT_ID`; sign-in is simply unavailable.

Linux support is planned. The platform directory has not been generated yet; build instructions will be added once `linux/` exists.

## License

[Apache License 2.0](./LICENSE). Redistributions must include [NOTICE](./NOTICE); the third-party license notices in it must not be removed.

## Third-party components

- Flutter / Dart — BSD-3-Clause
- Noto Sans SC — SIL Open Font License 1.1
- Remix Icon — Remix Icon License v1.0

Licenses for the remaining Dart dependencies are available in the app under Settings → About → Licenses.
