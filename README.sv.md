<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>En Windows-skrivbordsstartare för Minecraft: Java Edition. Linux-stöd är planerat.</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">Webbplats</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">Senaste versionen</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <b>Svenska</b>
  </p>

</div>

## Förutsättningar

- Windows 10 eller 11, 64-bit
- En Java-runtime för den Minecraft-version du vill starta (identifieras automatiskt; kan anges per version)
- Ett Microsoft-konto som äger Minecraft: Java Edition
- Ditt eget Azure-program-(klient-)ID för inloggning

## Funktioner

- Startar Minecraft-versioner som redan är installerade
- Inställningar per version: Java-runtime, minnesgräns, JVM-argument
- Automatisk minnesplanering utifrån installerat RAM, kan åsidosättas per version
- Importera en versionsmapp eller zip, byt namn och ta bort versioner
- Diagnostiklogg (Inställningar → Loggar) för felsökning
- Spelmapp per version: sparade världar, inställningar och mods ligger i respektive versionsmapp, så versioner hålls åtskilda
- Microsoft-inloggning via enhetskodflödet; ange ditt eget Azure-program-(klient-)ID under Inställningar → Konto eller via miljövariablerna `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID`
- 10 gränssnittsspråk: English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- Mörkt, ljust och systemstyrt tema
- Använder en portabel `.minecraft`-mapp bredvid exe-filen, annars `%APPDATA%\.minecraft`

## Katalogstruktur

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

## Bygge (Windows)

Kräver Visual Studio 2022 eller 2026 med C++-arbetsbelastningen (eller motsvarande Build Tools), CMake 3.25+ och Python 3 med Pillow. Ikonen versionshanteras inte: kör `python tools/export-icons.py` före bygget – den renderar varje storlek från SVG via headless Edge eller Chrome.

Valfritt (experimentellt): checka ut [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) bredvid det här repot och konfigurera med `-DJO_USE_DRAFTUI=ON` för att använda det; avstängt som standard och bygget fungerar utan. Gränssnittet ritas fortfarande med handskriven Direct2D-kod.

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
cmake --build build/native --config Release
```

Resultat:

```text
build/native/Release/JO-Launcher.exe
```

Den körbara filen är statiskt länkad mot MSVC-runtime.

## Status

Win32-skalet är det enda implementerade gränssnittet. Linux-backendarna för HTTP, hemlighetslagring och processer finns under `core/platform/`, men GTK-skalet har inte påbörjats.

## Licens

JO-Launcher är licensierat under Apache License 2.0; se [LICENSE](./LICENSE).
Ikonerna (`assets/icon/`, `platform/win32/app.ico` och webbplatsens ikoner) omfattas inte av Apache License 2.0 och alla rättigheter förbehålls: de får följa med en JO-Launcher som är oförändrad och identisk med den officiella versionen, medan varje ändring — inklusive forks, namnbyte eller ändrat versionsnummer — kräver att de ersätts; se [assets/icon/LICENSE](./assets/icon/LICENSE).
Vid vidaredistribution måste [NOTICE](./NOTICE) ingå och tredjepartsnotiserna som den hänvisar till bevaras. Integritetsmeddelande: [PRIVACY.md](./PRIVACY.md).

Inte en officiell Minecraft-produkt. Inte godkänd av eller associerad med Mojang eller Microsoft. Minecraft, Mojang, Microsoft och Xbox är varumärken som tillhör Microsoft Corporation eller dess dotterbolag.
