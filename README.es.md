# JO-Launcher

Un lanzador de escritorio para Windows para Minecraft: Java Edition. La compatibilidad con Linux está prevista.

[English](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [**Español**](README.es.md) · [Français](README.fr.md) · [Português](README.pt-BR.md) · [Svenska](README.sv.md)

## Requisitos

- Windows 10 u 11, x64
- Un entorno de ejecución de Java para la versión de Minecraft que quieras iniciar (se detecta automáticamente; se puede indicar por versión)
- Una cuenta de Microsoft que posea Minecraft: Java Edition
- Tu propio ID de aplicación (cliente) de Azure para iniciar sesión

## Características

- Inicia versiones de Minecraft ya instaladas
- Ajustes por versión: entorno de Java, límite de memoria, argumentos de JVM
- Planificación automática de memoria según la RAM instalada, modificable por versión
- Importa una carpeta o zip de versión, cambia el nombre y elimina versiones
- Registro de diagnóstico (Ajustes → Acerca de → Registros) para solucionar problemas
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
platform/win32/       Win32 + Direct2D shell
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## Compilación (Windows)

Requiere Visual Studio 2022 o 2026 con la carga de trabajo de C++ (o las Build Tools correspondientes) y CMake 3.25+.

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
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
Las redistribuciones deben incluir [NOTICE](./NOTICE) y conservar los avisos de terceros que referencia. Aviso de privacidad: [PRIVACY.md](./PRIVACY.md).

No es un producto oficial de Minecraft. No está aprobado por Mojang ni Microsoft ni asociado con ellos. Minecraft, Mojang, Microsoft y Xbox son marcas de Microsoft Corporation o de sus filiales.
