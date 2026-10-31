# JO-Launcher

Um launcher de desktop para Windows para Minecraft: Java Edition. O suporte a Linux está planejado.

[English](README.en.md) · [简体中文](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [**Português**](README.pt-BR.md) · [Svenska](README.sv.md)

## Requisitos

- Windows 10 ou 11, x64
- Um runtime Java para a versão do Minecraft que você quer iniciar (detectado automaticamente; pode ser definido por versão)
- Uma conta Microsoft que possua Minecraft: Java Edition
- Seu próprio ID de aplicativo (cliente) do Azure para entrar

## Recursos

- Inicia versões do Minecraft já instaladas
- Configurações por versão: runtime Java, limite de memória, argumentos da JVM
- Planejamento automático de memória com base na RAM instalada, substituível por versão
- Importa uma pasta ou zip de versão, renomeia e exclui versões
- Log de diagnóstico (Configurações → Sobre → Logs) para solução de problemas
- Diretório de jogo por versão: saves, opções e mods ficam na pasta de cada versão, mantendo as versões isoladas
- Login da Microsoft pelo fluxo de código de dispositivo; informe seu próprio ID de aplicativo (cliente) do Azure em Configurações → Conta ou pelas variáveis de ambiente `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID`
- 10 idiomas de interface: English, 简体中文, 繁體中文, 日本語, 한국어, Deutsch, Español, Français, Português, Svenska
- Temas escuro, claro e seguir o sistema
- Usa uma pasta `.minecraft` portátil ao lado do executável; caso contrário, `%APPDATA%\.minecraft`

## Estrutura

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

## Compilação (Windows)

Requer Visual Studio 2022 ou 2026 com a carga de trabalho C++ (ou as Build Tools correspondentes) e CMake 3.25+.

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
cmake --build build/native --config Release
```

Resultado:

```text
build/native/Release/JO-Launcher.exe
```

O executável é vinculado estaticamente ao runtime da MSVC.

## Status

A shell Win32 é a única interface implementada. Os backends Linux de HTTP, armazenamento de segredos e processos estão em `core/platform/`, mas a shell GTK ainda não foi iniciada.

## Licença

JO-Launcher é licenciado sob a Apache License 2.0; consulte [LICENSE](./LICENSE).
Redistribuições devem incluir [NOTICE](./NOTICE) e manter os avisos de terceiros nele referenciados. Aviso de privacidade: [PRIVACY.md](./PRIVACY.md).

Não é um produto oficial do Minecraft. Não aprovado por Mojang ou Microsoft nem associado a eles. Minecraft, Mojang, Microsoft e Xbox são marcas da Microsoft Corporation ou de suas afiliadas.
