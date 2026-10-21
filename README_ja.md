# JO-Launcher

[![CI](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml/badge.svg)](https://github.com/JO-Beacon/JO-Launcher/actions/workflows/build-windows.yml)

JO-Launcher は、Minecraft: Java Edition 用のオープンソースランチャーです。既存のゲーム環境を、シンプルで軽快なデスクトップ体験で起動することに重点を置いています。現在は Windows に対応しており、Linux はロードマップに含まれています。

[English](./README.md) · [日本語](./README_ja.md) · [Svenska](./README_sv.md) · [Português (Brasil)](./README_pt_BR.md) · [Español](./README_es.md) · [Français](./README_fr.md) · [Deutsch](./README_de.md) · [Website](https://jo-beacon.github.io/JO-Launcher/) · [Privacy](./PRIVACY.md) · [Apache License 2.0](./LICENSE)

![JO-Launcher](docs/screenshot.png)

> **NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

## 機能

- **バージョン検出** — `versions/` を走査し、バニラ / Fabric / Quilt / Forge / NeoForge を認識します。
- **バージョン設定** — バージョンごとに Java、メモリ上限、JVM 引数を設定できます。設定はバージョンディレクトリ内の `jolauncher.json` に保存されます。
- **Microsoft サインイン** — デバイスコードフローで Microsoft アカウントにサインインします。
- **起動ワークスペース** — バージョンを選び、ゲームを起動し、リアルタイムログを確認してプロセスを停止できます。
- **デスクトップ UI** — ダーク / ライト / システム連動テーマ、ドラッグ可能なサイドバー、7 言語のインターフェース。

## ロードマップ

- バージョン管理：ユーザーが用意したローカルファイルからのインストール、Mod パックのインポート、削除、名前変更
- Linux デスクトップ対応
- アカウントのアバターとアカウント切り替え
- クラッシュ診断と復旧

## コントリビュート

Issue は歓迎します。プルリクエストは**受け付けません**。自動的に閉じられます。詳細は [CONTRIBUTING.md](./CONTRIBUTING.md) をご覧ください。

## 技術スタック

Flutter / Dart。

## ビルド

Flutter SDK が必要です。Windows では、インストーラーを作る場合のみ Inno Setup が必要です。

Microsoft サインインには Azure アプリケーションの client_id が必要です。**このリポジトリには保存されていません**。ビルド時に環境変数で渡してください：

```powershell
$env:JO_MS_CLIENT_ID = "<your client_id>"
pwsh -ExecutionPolicy Bypass -File scripts\build.ps1
```

インストーラーなしでアプリだけをビルドする場合：

```powershell
flutter build windows --release --dart-define=JO_MS_CLIENT_ID=$env:JO_MS_CLIENT_ID
```

`JO_MS_CLIENT_ID` がなくてもビルドできます。その場合、サインインは利用できません。

Linux 対応は計画中です。プラットフォームディレクトリはまだ生成されていません。`linux/` ができ次第、ビルド手順を追加します。

## ライセンス

[Apache License 2.0](./LICENSE)。再配布時は [NOTICE](./NOTICE) を同梱してください。記載されている第三者ライセンスの通知は削除しないでください。

## 第三者コンポーネント

- Flutter / Dart — BSD-3-Clause
- Noto Sans SC — SIL Open Font License 1.1
- Remix Icon — Remix Icon License v1.0

その他の Dart 依存関係のライセンスは、アプリ内のライセンス画面から確認できます。
