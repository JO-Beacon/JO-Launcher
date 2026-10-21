# JO-Launcher

[![CI](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml/badge.svg)](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml)

JO-Launcher ist ein quelloffener Launcher für Minecraft: Java Edition, der vorhandene Installationen mit einer klaren und flüssigen Desktop-Erfahrung startet. Windows wird derzeit unterstützt; Linux-Unterstützung steht auf der Roadmap.

[English](./README.md) · [日本語](./README_ja.md) · [Svenska](./README_sv.md) · [Português (Brasil)](./README_pt_BR.md) · [Español](./README_es.md) · [Français](./README_fr.md) · [Deutsch](./README_de.md) · [Website](https://jo-beacon.github.io/JO-Launcher/) · [Privacy](./PRIVACY.md) · [Apache License 2.0](./LICENSE)

![JO-Launcher](docs/screenshot.png)

> **NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

## Funktionen

- **Versionserkennung** — durchsucht `versions/` und erkennt Vanilla-, Fabric-, Quilt-, Forge- und NeoForge-Installationen.
- **Versionseinstellungen** — Java, Arbeitsspeichergrenzen und JVM-Argumente pro Version konfigurieren; die Einstellungen liegen in `jolauncher.json` im jeweiligen Versionsverzeichnis.
- **Microsoft-Anmeldung** — Anmeldung mit einem Microsoft-Konto über den Gerätecode-Flow.
- **Startbereich** — Version auswählen, Spiel starten, Live-Log verfolgen und den Prozess beenden.
- **Desktop-Erfahrung** — Dunkel-/Hell-/Systemthema, verschiebbare Seitenleiste und sieben Oberflächensprachen.

## Roadmap

- Versionsverwaltung: Spielversionen installieren, Modpacks importieren, löschen und umbenennen
- Linux-Desktop-Unterstützung
- Konto-Avatare und Kontowechsel
- Absturzdiagnose und Wiederherstellung

## Beitragen

Issues sind willkommen. Pull Requests werden **nicht** akzeptiert und automatisch geschlossen. Siehe [CONTRIBUTING.md](./CONTRIBUTING.md).

## Technik

Flutter / Dart.

## Build

Du benötigst das Flutter SDK. Unter Windows wird Inno Setup nur für den Installer benötigt.

Die Microsoft-Anmeldung benötigt die client_id einer Azure-Anwendung. **Sie ist nicht in diesem Repository gespeichert**; übergib sie beim Build über eine Umgebungsvariable:

```powershell
$env:JO_MS_CLIENT_ID = "<your client_id>"
pwsh -ExecutionPolicy Bypass -File scripts\build.ps1
```

Um die Anwendung ohne Installer zu bauen:

```powershell
flutter build windows --release --dart-define=JO_MS_CLIENT_ID=$env:JO_MS_CLIENT_ID
```

Die Anwendung lässt sich auch ohne `JO_MS_CLIENT_ID` bauen; die Anmeldung ist dann einfach nicht verfügbar.

Linux-Unterstützung ist geplant. Das Plattformverzeichnis wurde noch nicht erzeugt; die Build-Anleitung wird ergänzt, sobald `linux/` existiert.

## Lizenz

[Apache License 2.0](./LICENSE). Bei Weitergabe muss [NOTICE](./NOTICE) beiliegen; die darin enthaltenen Hinweise auf Lizenzen Dritter dürfen nicht entfernt werden.

## Komponenten von Drittanbietern

- Flutter / Dart — BSD-3-Clause
- Noto Sans SC — SIL Open Font License 1.1
- Remix Icon — Remix Icon License v1.0

Die Lizenzen der übrigen Dart-Abhängigkeiten sind im Lizenzbildschirm der Anwendung einsehbar.
