<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>Un lanzador de escritorio para Windows para Minecraft: Java Edition. La compatibilidad con Linux está prevista.</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">Sitio web</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">Última versión</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <a href="README.md">简体中文</a> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <b>Español</b> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

## Requisitos

- Windows 10 u 11, 64 bits
- Un entorno de ejecución de Java para la versión de Minecraft que quieras iniciar (se detecta automáticamente; se puede indicar por versión)
- Una cuenta de Microsoft que posea Minecraft: Java Edition
- Tu propio ID de aplicación (cliente) de Azure para iniciar sesión

## Características

- Inicia versiones de Minecraft ya instaladas
- Ajustes por versión: entorno de Java, límite de memoria, argumentos de JVM
- Planificación automática de memoria según la RAM instalada, modificable por versión
- Importa una carpeta o zip de versión, cambia el nombre y elimina versiones
- Registro de diagnóstico (Ajustes → Registros) para solucionar problemas
- Directorio de juego por versión: partidas, opciones y mods viven en la carpeta de cada versión, por lo que las versiones quedan aisladas
- Inicio de sesión de Microsoft mediante el flujo de código de dispositivo; introduce tu propio ID de aplicación (cliente) de Azure en Ajustes → Cuenta o mediante las variables de entorno `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID`
- 10 idiomas de interfaz: English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- Temas oscuro, claro y según el sistema
- Usa una carpeta portátil `.minecraft` junto al ejecutable; si no existe, `%APPDATA%\.minecraft`

## Estructura

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

## Compilación (Windows)

Requiere Visual Studio 2022 o 2026 con la carga de trabajo de C++ (o las Build Tools correspondientes), CMake 3.25+ y Python 3 con Pillow. El icono no está versionado: antes de compilar, ejecuta `python tools/export-icons.py`, que genera cada tamaño desde el SVG con Edge o Chrome sin interfaz.

Opcional (experimental): clona [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) junto a este repositorio y configura con `-DJO_USE_DRAFTUI=ON` para usarlo; está desactivado por defecto y la compilación funciona sin él. La interfaz todavía se dibuja con código Direct2D escrito a mano.

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
cmake --build build/native --config Release
```

Resultado:

```text
build/native/Release/JO-Launcher.exe
```

El ejecutable se enlaza estáticamente con el runtime de MSVC.

## Estado

La shell Win32 es la única interfaz implementada. Los backends de HTTP, almacenamiento de secretos y procesos de Linux están en `core/platform/`, pero la shell GTK aún no se ha comenzado.

## Licencia

JO-Launcher está licenciado bajo Apache License 2.0; consulta [LICENSE](./LICENSE).
Los iconos (`assets/icon/`, `platform/win32/app.ico` y los del sitio) no están cubiertos por la Apache License 2.0 y quedan con todos los derechos reservados: pueden distribuirse con un JO-Launcher sin ninguna modificación e idéntico a la versión oficial, mientras que cualquier cambio —incluidos forks, un cambio de nombre o de número de versión— obliga a reemplazarlos; consulta [assets/icon/LICENSE](./assets/icon/LICENSE).
Las redistribuciones deben incluir [NOTICE](./NOTICE) y conservar los avisos de terceros que referencia. Aviso de privacidad: [PRIVACY.md](./PRIVACY.md).

No es un producto oficial de Minecraft. No está aprobado por Mojang ni Microsoft ni asociado con ellos. Minecraft, Mojang, Microsoft y Xbox son marcas de Microsoft Corporation o de sus filiales.
