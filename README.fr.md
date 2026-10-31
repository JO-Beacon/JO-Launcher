# JO-Launcher

Un lanceur de bureau Windows pour Minecraft: Java Edition. La prise en charge de Linux est prévue.

[English](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [**Français**](README.fr.md) · [Português](README.pt-BR.md) · [Svenska](README.sv.md)

## Configuration requise

- Windows 10 ou 11, x64
- Un environnement d'exécution Java pour la version de Minecraft à lancer (détecté automatiquement ; peut être défini par version)
- Un compte Microsoft possédant Minecraft: Java Edition
- Votre propre ID d'application (client) Azure pour la connexion

## Fonctionnalités

- Lance les versions de Minecraft déjà installées
- Réglages par version : environnement Java, limite de mémoire, arguments JVM
- Planification automatique de la mémoire selon la RAM installée, modifiable par version
- Importer un dossier ou un zip de version, renommer et supprimer des versions
- Journal de diagnostic (Paramètres → À propos → Journaux) pour le dépannage
- Répertoire de jeu par version : sauvegardes, options et mods restent dans le dossier de chaque version, les versions sont donc isolées
- Connexion Microsoft via le flux de code d'appareil ; saisissez votre propre ID d'application (client) Azure dans Paramètres → Compte ou via les variables d'environnement `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID`
- 10 langues d'interface : English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- Thèmes sombre, clair et selon le système
- Utilise un dossier `.minecraft` portable à côté de l'exécutable, sinon `%APPDATA%\.minecraft`

## Structure

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

## Compilation (Windows)

Nécessite Visual Studio 2022 ou 2026 avec la charge de travail C++ (ou les Build Tools correspondants) et CMake 3.25+.

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
cmake --build build/native --config Release
```

Résultat :

```text
build/native/Release/JO-Launcher.exe
```

L'exécutable est lié statiquement au runtime MSVC.

## État

L'interface Win32 est la seule implémentée. Les backends Linux HTTP, de stockage de secrets et de processus se trouvent dans `core/platform/`, mais l'interface GTK n'a pas encore été commencée.

## Licence

JO-Launcher est sous licence Apache License 2.0 ; voir [LICENSE](./LICENSE).
Les redistributions doivent inclure [NOTICE](./NOTICE) et conserver les mentions de tiers qu'il référence. Avis de confidentialité : [PRIVACY.md](./PRIVACY.md).

Produit Minecraft non officiel. Non approuvé par Mojang ou Microsoft, ni associé à eux. Minecraft, Mojang, Microsoft et Xbox sont des marques de Microsoft Corporation ou de ses filiales.
