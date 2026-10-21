# JO-Launcher

[![CI](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/ci.yml/badge.svg)](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/ci.yml)

JO-Launcher est un lanceur open source pour Minecraft: Java Edition, pensé pour lancer vos installations existantes avec une expérience de bureau propre et réactive. Windows est pris en charge aujourd'hui ; la prise en charge de Linux figure dans la feuille de route.

[English](./README.md) · [日本語](./README_ja.md) · [Svenska](./README_sv.md) · [Português (Brasil)](./README_pt_BR.md) · [Español](./README_es.md) · [Français](./README_fr.md) · [Deutsch](./README_de.md) · [Privacy](./PRIVACY.md) · [Apache License 2.0](./LICENSE)

![JO-Launcher](docs/screenshot.png)

> **NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

## Fonctionnalités

- **Détection des versions** — parcourt `versions/` et reconnaît les installations vanilla, Fabric, Quilt, Forge et NeoForge.
- **Paramètres de version** — configurez Java, les limites de mémoire et les arguments JVM par version ; les paramètres sont enregistrés dans `jolauncher.json` au sein du répertoire de la version.
- **Connexion Microsoft** — connectez-vous avec un compte Microsoft via le flux de code d'appareil.
- **Espace de lancement** — choisissez une version, lancez le jeu, suivez le journal en direct et arrêtez le processus.
- **Expérience de bureau** — thèmes sombre / clair / suivre le système, barre latérale déplaçable et sept langues d'interface.

## Feuille de route

- Gestion des versions : installer des versions du jeu, importer des modpacks, supprimer et renommer
- Prise en charge du bureau Linux
- Avatars de compte et changement de compte
- Diagnostic et récupération après plantage

## Contributions

Les issues sont les bienvenues. Les pull requests ne sont **pas** acceptées et seront fermées automatiquement. Voir [CONTRIBUTING.md](./CONTRIBUTING.md).

## Technologies

Flutter / Dart.

## Compilation

Vous avez besoin du SDK Flutter. Sous Windows, Inno Setup n'est nécessaire que pour produire l'installateur.

La connexion Microsoft nécessite le client_id d'une application Azure. **Il n'est pas stocké dans ce dépôt** ; transmettez-le au moment de la compilation via une variable d'environnement :

```powershell
$env:JO_MS_CLIENT_ID = "<your client_id>"
pwsh -ExecutionPolicy Bypass -File scripts\build.ps1
```

Pour compiler l'application sans l'installateur :

```powershell
flutter build windows --release --dart-define=JO_MS_CLIENT_ID=$env:JO_MS_CLIENT_ID
```

L'application se compile sans `JO_MS_CLIENT_ID` ; la connexion est simplement indisponible.

La prise en charge de Linux est prévue. Le répertoire de plateforme n'a pas encore été généré ; les instructions de compilation seront ajoutées dès que `linux/` existera.

## Licence

[Apache License 2.0](./LICENSE). Les redistributions doivent inclure [NOTICE](./NOTICE) ; les mentions de licences tierces qu'il contient ne doivent pas être supprimées.

## Composants tiers

- Flutter / Dart — BSD-3-Clause
- Noto Sans SC — SIL Open Font License 1.1
- Remix Icon — Remix Icon License v1.0

Les licences des autres dépendances Dart sont consultables dans l'écran des licences de l'application.
