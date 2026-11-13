<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>Un lanceur de bureau Windows pour Minecraft: Java Edition. La prise en charge de Linux est prévue.</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">Site officiel</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">Dernière version</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <b>Français</b> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

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
- Journal de diagnostic (Paramètres → Journaux) pour le dépannage
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
  platform/           OS backends: HTTP, key storage, process
platform/win32/       Win32 + Direct2D shell
assets/icon/          icon sources (SVG); the .ico is generated, not tracked
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## Compilation (Windows)

Nécessite Visual Studio 2022 ou 2026 avec la charge de travail C++ (ou les Build Tools correspondants), CMake 3.25+ et Python 3 avec Pillow. L'icône n'est pas versionnée : lancez `python tools/export-icons.py` avant la compilation ; il génère chaque taille à partir du SVG via Edge ou Chrome en mode sans interface.

Facultatif (expérimental) : clonez [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) à côté de ce dépôt et configurez avec `-DJO_USE_DRAFTUI=ON` pour l'utiliser ; désactivé par défaut, la compilation fonctionne sans. L'interface est toujours dessinée par du code Direct2D écrit à la main.

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
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
Les icônes (`assets/icon/`, `platform/win32/app.ico` et celles du site) ne sont pas couvertes par l'Apache License 2.0 et restent tous droits réservés : elles peuvent accompagner un JO-Launcher sans aucune modification et identique à la version officielle, tandis que toute modification — fork, changement de nom ou de numéro de version — impose de les remplacer ; voir [assets/icon/LICENSE](./assets/icon/LICENSE).
Les redistributions doivent inclure [NOTICE](./NOTICE) et conserver les mentions de tiers qu'il référence. Avis de confidentialité : [PRIVACY.md](./PRIVACY.md).

Produit Minecraft non officiel. Non approuvé par Mojang ou Microsoft, ni associé à eux. Minecraft, Mojang, Microsoft et Xbox sont des marques de Microsoft Corporation ou de ses filiales.
