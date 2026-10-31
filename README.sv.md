# JO-Launcher

En Windows-skrivbordsstartare för Minecraft: Java Edition. Linux-stöd är planerat.

[English](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Português](README.pt-BR.md) · [**Svenska**](README.sv.md)

## Förutsättningar

- Windows 10 eller 11, x64
- En Java-runtime för den Minecraft-version du vill starta (identifieras automatiskt; kan anges per version)
- Ett Microsoft-konto som äger Minecraft: Java Edition
- Ditt eget Azure-program-(klient-)ID för inloggning

## Funktioner

- Startar Minecraft-versioner som redan är installerade
- Inställningar per version: Java-runtime, minnesgräns, JVM-argument
- Automatisk minnesplanering utifrån installerat RAM, kan åsidosättas per version
- Importera en versionsmapp eller zip, byt namn och ta bort versioner
- Diagnostiklogg (Inställningar → Om → Loggar) för felsökning
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
platform/win32/       Win32 + Direct2D shell
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## Bygge (Windows)

Kräver Visual Studio 2022 eller 2026 med C++-arbetsbelastningen (eller motsvarande Build Tools) och CMake 3.25+.

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
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
Vid vidaredistribution måste [NOTICE](./NOTICE) ingå och tredjepartsnotiserna som den hänvisar till bevaras. Integritetsmeddelande: [PRIVACY.md](./PRIVACY.md).

Inte en officiell Minecraft-produkt. Inte godkänd av eller associerad med Mojang eller Microsoft. Minecraft, Mojang, Microsoft och Xbox är varumärken som tillhör Microsoft Corporation eller dess dotterbolag.
