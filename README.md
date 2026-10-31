# JO-Launcher

一个面向 Minecraft: Java Edition 的 Windows 桌面启动器。Linux 支持已在计划中。

[English](README.en.md) · [**简体中文**](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Português](README.pt-BR.md) · [Svenska](README.sv.md)

## 系统要求

- Windows 10 或 11，x64
- 要启动的 Minecraft 版本所需的 Java 运行环境（自动检测，也可按版本手动指定）
- 拥有 Minecraft: Java Edition 的微软账号
- 自己的 Azure 应用（客户端）ID，用于登录

## 功能

- 启动本机已安装的 Minecraft 版本
- 按版本设置：Java 运行环境、内存上限、JVM 参数
- 根据本机物理内存自动规划内存，可按版本覆盖
- 导入版本文件夹或 zip，重命名、删除版本
- 诊断日志（设置 → 关于 → 日志），便于排查问题
- 按版本隔离游戏目录：存档、选项和模组都保存在各自版本目录中，不同版本互不影响
- 通过设备码流程登录微软账号；可在 设置 → 账号 填写自己的 Azure 应用（客户端）ID，也可使用 `JO_MS_CLIENT_ID` / `JOL_MS_CLIENT_ID` 环境变量
- 10 种界面语言：English、简体中文、繁體中文、日本語、한국어、Deutsch、Español、Français、Português、Svenska
- 深色、浅色和跟随系统主题
- 优先使用 exe 旁的便携 `.minecraft` 目录，否则使用 `%APPDATA%\.minecraft`

## 目录结构

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

## 构建（Windows）

需要安装 Visual Studio 2022 或 2026 的 C++ 工作负载（或对应的 Build Tools）以及 CMake 3.25+。

```powershell
cmake -S . -B build/native -G "Visual Studio 18 2026" -A x64
cmake --build build/native --config Release
```

生成结果：

```text
build/native/Release/JO-Launcher.exe
```

可执行文件静态链接 MSVC 运行库。

## 状态

目前只有 Win32 外壳。Linux 的 HTTP、密钥存储和进程后端已经位于 `core/platform/` 下，但 GTK 外壳尚未开始。

## 许可证

JO-Launcher 使用 Apache License 2.0 授权，详见 [LICENSE](./LICENSE)。
再分发时必须包含 [NOTICE](./NOTICE)，并保留其中引用的第三方声明。隐私说明：[PRIVACY.md](./PRIVACY.md)。

非 Minecraft 官方产品，未经 Mojang 或 Microsoft 批准或关联。Minecraft、Mojang、Microsoft 和 Xbox 是 Microsoft Corporation 或其关联公司的商标。
