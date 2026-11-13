<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>Ein Windows-Desktop-Launcher für Minecraft: Java Edition. Linux-Unterstützung ist geplant.</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">Website</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">Neueste Version</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <b>Deutsch</b> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

## Voraussetzungen

- Windows 10 oder 11, 64-Bit
- Eine Java-Laufzeitumgebung für die gewünschte Minecraft-Version (automatisch erkannt; pro Version manuell einstellbar)
- Ein Microsoft-Konto, dem Minecraft: Java Edition gehört
- Eine eigene Azure-Anwendungs-(Client-)ID für die Anmeldung

## Funktionen

- Startet bereits installierte Minecraft-Versionen
- Einstellungen pro Version: Java-Laufzeitumgebung, Arbeitsspeicherlimit, JVM-Argumente
- Automatische Arbeitsspeicherplanung anhand des installierten RAMs, pro Version überschreibbar
- Versionsordner oder ZIP importieren, Versionen umbenennen und löschen
- Diagnoseprotokoll (Einstellungen → Protokolle) zur Fehlersuche
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
  platform/           OS backends: HTTP, key storage, process
platform/win32/       Win32 + Direct2D shell
assets/icon/          icon sources (SVG); the .ico is generated, not tracked
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## Build (Windows)

Erfordert Visual Studio 2022 oder 2026 mit der C++-Workload (oder die passenden Build Tools), CMake 3.25+ und Python 3 mit Pillow. Das Icon wird nicht versioniert: vor dem Build `python tools/export-icons.py` ausführen — es rendert jede Größe aus dem SVG über headless Edge oder Chrome.

Optional (experimentell): [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) neben dieses Repository auschecken und mit `-DJO_USE_DRAFTUI=ON` konfigurieren, um es zu nutzen; standardmäßig aus, der Build funktioniert auch ohne. Die Oberfläche wird weiterhin mit handgeschriebenem Direct2D-Code gezeichnet.

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
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
Die Icons (`assets/icon/`, `platform/win32/app.ico` und die Icons der Website) fallen nicht unter die Apache License 2.0 und bleiben alle Rechte vorbehalten: Sie dürfen mit einem JO-Launcher weitergegeben werden, der unverändert und identisch mit der offiziellen Version ist; bei jeder Änderung — auch Fork, Umbenennung oder geänderter Versionsnummer — müssen sie ersetzt werden — siehe [assets/icon/LICENSE](./assets/icon/LICENSE).
Bei der Weitergabe muss [NOTICE](./NOTICE) beiliegen und die darin genannten Hinweise Dritter müssen erhalten bleiben. Datenschutzhinweis: [PRIVACY.md](./PRIVACY.md).

Kein offizielles Minecraft-Produkt. Nicht von Mojang oder Microsoft genehmigt oder mit ihnen verbunden. Minecraft, Mojang, Microsoft und Xbox sind Marken der Microsoft Corporation oder ihrer verbundenen Unternehmen.
