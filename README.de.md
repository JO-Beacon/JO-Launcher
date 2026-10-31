# JO-Launcher

Ein Windows-Desktop-Launcher für Minecraft: Java Edition. Linux-Unterstützung ist geplant.

[English](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [**Deutsch**](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Português](README.pt-BR.md) · [Svenska](README.sv.md)

## Voraussetzungen

- Windows 10 oder 11, x64
- Eine Java-Laufzeitumgebung für die gewünschte Minecraft-Version (automatisch erkannt; pro Version manuell einstellbar)
- Ein Microsoft-Konto, dem Minecraft: Java Edition gehört
- Eine eigene Azure-Anwendungs-(Client-)ID für die Anmeldung

## Funktionen

- Startet bereits installierte Minecraft-Versionen
- Einstellungen pro Version: Java-Laufzeitumgebung, Arbeitsspeicherlimit, JVM-Argumente
- Automatische Arbeitsspeicherplanung anhand des installierten RAMs, pro Version überschreibbar
- Versionsordner oder ZIP importieren, Versionen umbenennen und löschen
- Diagnoseprotokoll (Einstellungen → Über → Protokolle) zur Fehlersuche
- Spielverzeichnis pro Version: Spielstände, Optionen und Mods liegen im jeweiligen Versionsordner, sodass Versionen getrennt bleiben
- Microsoft-Anmeldung über den Gerätecode-Ablauf; eigene Azure-Anwendungs-(Client-)ID unter Einstellungen → Konto oder über die Umgebungsvariablen `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID`
- 10 Oberflächensprachen: English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- Dunkles, helles und systemabhängiges Design
- Bevorzugt einen portablen `.minecraft`-Ordner neben der EXE, sonst `%APPDATA%\.minecraft`

## Verzeichnisstruktur

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

Erfordert Visual Studio 2022 oder 2026 mit der C++-Workload (oder die passenden Build Tools) und CMake 3.25+.

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
cmake --build build/native --config Release
```

Ergebnis:

```text
build/native/Release/JO-Launcher.exe
```

Die ausführbare Datei ist statisch mit der MSVC-Laufzeit verknüpft.

## Status

Die Win32-Shell ist die einzige implementierte UI. Die Linux-Backends für HTTP, Secret-Speicherung und Prozesse liegen unter `core/platform/`, aber die GTK-Shell wurde noch nicht begonnen.

## Lizenz

JO-Launcher ist unter der Apache License 2.0 lizenziert; siehe [LICENSE](./LICENSE).
Bei der Weitergabe muss [NOTICE](./NOTICE) beiliegen und die darin genannten Hinweise Dritter müssen erhalten bleiben. Datenschutzhinweis: [PRIVACY.md](./PRIVACY.md).

Kein offizielles Minecraft-Produkt. Nicht von Mojang oder Microsoft genehmigt oder mit ihnen verbunden. Minecraft, Mojang, Microsoft und Xbox sind Marken der Microsoft Corporation oder ihrer verbundenen Unternehmen.
