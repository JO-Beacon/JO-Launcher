# JO-Launcher

[![CI](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml/badge.svg)](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml)

O JO-Launcher é um launcher de código aberto para Minecraft: Java Edition, focado em iniciar instalações existentes com uma experiência de desktop limpa e responsiva. O Windows é suportado hoje; o suporte a Linux está no roteiro.

[English](./README.md) · [日本語](./README_ja.md) · [Svenska](./README_sv.md) · [Português (Brasil)](./README_pt_BR.md) · [Español](./README_es.md) · [Français](./README_fr.md) · [Deutsch](./README_de.md) · [Privacy](./PRIVACY.md) · [Apache License 2.0](./LICENSE)

![JO-Launcher](docs/screenshot.png)

> **NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

## Recursos

- **Descoberta de versões** — verifica `versions/` e reconhece instalações vanilla, Fabric, Quilt, Forge e NeoForge.
- **Configurações da versão** — configure Java, limites de memória e argumentos da JVM por versão; as configurações ficam em `jolauncher.json` dentro do diretório da versão.
- **Login da Microsoft** — entre com uma conta Microsoft pelo fluxo de código de dispositivo.
- **Área de inicialização** — escolha uma versão, inicie o jogo, acompanhe o log ao vivo e pare o processo.
- **Experiência desktop** — temas escuro / claro / seguir o sistema, barra lateral arrastável e sete idiomas de interface.

## Roteiro

- Gerenciamento de versões: instalar versões do jogo, importar modpacks, excluir e renomear
- Suporte ao desktop Linux
- Avatares de conta e alternância entre contas
- Diagnóstico e recuperação de falhas

## Contribuindo

Issues são bem-vindas. Pull requests **não** são aceitos e serão fechados automaticamente. Consulte [CONTRIBUTING.md](./CONTRIBUTING.md).

## Tecnologias

Flutter / Dart.

## Compilação

Você precisa do Flutter SDK. No Windows, o Inno Setup só é necessário para gerar o instalador.

O login da Microsoft requer o client_id de um aplicativo do Azure. **Ele não é armazenado neste repositório**; passe-o em tempo de compilação por uma variável de ambiente:

```powershell
$env:JO_MS_CLIENT_ID = "<your client_id>"
pwsh -ExecutionPolicy Bypass -File scripts\build.ps1
```

Para compilar o aplicativo sem o instalador:

```powershell
flutter build windows --release --dart-define=JO_MS_CLIENT_ID=$env:JO_MS_CLIENT_ID
```

O aplicativo ainda compila sem `JO_MS_CLIENT_ID`; o login simplesmente fica indisponível.

O suporte a Linux está planejado. O diretório da plataforma ainda não foi gerado; as instruções de compilação serão adicionadas quando `linux/` existir.

## Licença

[Apache License 2.0](./LICENSE). As redistribuições devem incluir o [NOTICE](./NOTICE); os avisos de licenças de terceiros nele contidos não podem ser removidos.

## Componentes de terceiros

- Flutter / Dart — BSD-3-Clause
- Noto Sans SC — SIL Open Font License 1.1
- Remix Icon — Remix Icon License v1.0

As licenças das demais dependências Dart podem ser vistas na tela de licenças do aplicativo.
