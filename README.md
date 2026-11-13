<div align="center">

  <img src="assets/icon/app-icon-plateless.svg" alt="JO-Launcher" width="100" />
  <h1>JO-Launcher</h1>

  <h2>一个面向 Minecraft: Java Edition 的 Windows 桌面启动器。Linux 支持已在计划中。</h2>

  <p>
    <a href="https://jo-beacon.github.io/JO-Launcher/">官网</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher">GitHub</a> ·
    <a href="https://github.com/JO-Beacon/JO-Launcher/releases/latest">最新版本</a>
  </p>

  <p>
    <a href="README.en.md">English</a> ·
    <b>简体中文</b> ·
    <a href="README.zh-TW.md">繁體中文</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.de.md">Deutsch</a> ·
    <a href="README.es.md">Español</a> ·
    <a href="README.fr.md">Français</a> ·
    <a href="README.pt-BR.md">Português</a> ·
    <a href="README.sv.md">Svenska</a>
  </p>

</div>

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
- 诊断日志（设置 → 日志），便于排查问题
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
  platform/           OS backends: HTTP, key storage, process
platform/win32/       Win32 + Direct2D shell
assets/icon/          icon sources (SVG); the .ico is generated, not tracked
tools/                build helpers and binary checks
third_party/          bundled third-party sources
```

## 构建（Windows）

需要安装 Visual Studio 2022 或 2026 的 C++ 工作负载（或对应的 Build Tools）、CMake 3.25+，以及带 Pillow 的 Python 3。图标不入版本控制，构建前先跑 `python tools/export-icons.py`，它用无头 Edge 或 Chrome 从 SVG 生成各尺寸。

可选依赖（实验性）：把 [JO-DraftUI](https://github.com/JO-Beacon/JO-DraftUI) 检出到仓库同级目录，配置时加 `-DJO_USE_DRAFTUI=ON` 即可启用；默认关闭，没有它也能正常构建。目前界面仍以手写 D2D 绘制为准。

```powershell
python tools/export-icons.py
cmake -S . -B build/native -A x64
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
图标（`assets/icon/`、`platform/win32/app.ico`、站点图标）不在 Apache-2.0 范围内，保留所有权利：未经任何修改、与官方版本一致的 JO-Launcher 可原样随附分发；任何改动（含 fork、改名、改版本号）都必须替换图标，详见 [assets/icon/LICENSE](./assets/icon/LICENSE)。
再分发时必须包含 [NOTICE](./NOTICE)，并保留其中引用的第三方声明。隐私说明：[PRIVACY.md](./PRIVACY.md)。

非 Minecraft 官方产品，未经 Mojang 或 Microsoft 批准或关联。Minecraft、Mojang、Microsoft 和 Xbox 是 Microsoft Corporation 或其关联公司的商标。
