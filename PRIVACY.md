# JO-Launcher Privacy Notice

Last updated: 2026-11-01

JO-Launcher is an open-source desktop launcher for Minecraft: Java Edition. This notice explains what data the app handles locally, why, and how you can delete it.

## 1. Data the app processes

When you sign in with a Microsoft account, the app processes:

- your Microsoft account name
- your Minecraft player name and UUID
- Minecraft access and refresh tokens
- your Minecraft profile and skin information

The app does not collect telemetry, analytics, advertising identifiers, or crash reports.

## 2. Where the data is stored

Account data is stored only on your device, in `%APPDATA%\JO-Beacon\JO-Launcher\account.dat`, encrypted with Windows DPAPI (`CryptProtectData`). It is not uploaded to a JO-Launcher server. JO-Launcher has no backend service. As required by the Minecraft launch protocol, the access token is passed to the game on its command line; other processes running as the same Windows user can read process command lines.

Launcher logs are written to `%LOCALAPPDATA%\JO-Beacon\JO-Launcher\logs\launcher.log` (rotated at 2 MB). They record startup, version scanning, sign-in and launch events plus error messages, and may include local file paths. They never contain passwords, access tokens or refresh tokens. Open the folder from **Settings → About → Logs** and delete it at any time.

## 3. Why the data is used

The data is used only to:

- sign in with your own Microsoft account
- renew the Microsoft / Xbox / Minecraft session
- read your own Minecraft profile
- launch the game

## 4. Sharing

During sign-in, data is sent to Microsoft, Xbox and Minecraft services as required by their authentication protocols. Those services process data under their own privacy policies. JO-Launcher does not sell or share account data with anyone else.

## 5. Retention and deletion

Account data remains on your device until you sign out; signing out deletes the stored account file. Uninstalling the app does not remove files in your user profile — delete `%APPDATA%\JO-Beacon\JO-Launcher` manually if you want them gone. You can sign out at any time in:

**Settings → Account → Sign out**

Signing out does not delete game files or version settings.

## 6. Your rights

You can access, correct or delete your local account data through the app. To withdraw consent, sign out or delete the files above. For privacy questions, open an issue at:

<https://github.com/JO-Beacon/JO-Launcher/issues>

## 7. Minors

The app is not directed at children. If you are a minor under the age of 14, please use the app only with the consent of a parent or guardian.

## 8. Changes

If this notice changes, the app will ask for consent again when the privacy notice version changes. The current version is **1**.

---

# JO-Launcher 隐私说明

最后更新：2026-11-01

JO-Launcher 是一款开源的 Minecraft: Java 版桌面启动器。本说明解释应用在本机处理哪些数据、用途以及如何删除。

## 1. 处理的数据

使用微软账号登录时，应用会处理：

- 微软账号名
- Minecraft 玩家名和 UUID
- Minecraft access token 与 refresh token
- Minecraft 档案和皮肤信息

应用不收集遥测、分析数据、广告标识或崩溃报告。

## 2. 保存位置

账号数据只保存在本机的 `%APPDATA%\JO-Beacon\JO-Launcher\account.dat`，使用 Windows DPAPI（`CryptProtectData`）加密。数据不会上传到 JO-Launcher 服务器，JO-Launcher 没有后端服务。按照 Minecraft 的启动协议，access token 会作为命令行参数传给游戏进程；同一 Windows 用户下的其他进程可以读取进程命令行。

启动器日志写入 `%LOCALAPPDATA%\JO-Beacon\JO-Launcher\logs\launcher.log`（超过 2 MB 自动轮转）。日志记录启动、版本扫描、登录和启动事件以及错误信息，可能包含本机文件路径；不会记录密码、access token 或 refresh token。可在「设置 → 关于 → 日志」打开该文件夹，随时删除。

## 3. 使用目的

数据仅用于：

- 使用你自己的微软账号登录
- 续期 Microsoft / Xbox / Minecraft 会话
- 读取你自己的 Minecraft 档案
- 启动游戏

## 4. 共享

登录过程中，数据会按照认证协议发送给 Microsoft、Xbox 和 Minecraft 服务；这些服务按各自的隐私政策处理数据。JO-Launcher 不会出售或向其他人共享账号数据。

## 5. 保存期限与删除

账号数据会一直保存在本机，直到你退出登录；退出登录会删除本机保存的账号文件。卸载应用不会删除用户目录下的文件，如需清除请手动删除 `%APPDATA%\JO-Beacon\JO-Launcher`。你可以随时在：

**设置 → 账号 → 退出登录**

退出登录不会删除游戏文件或版本设置。

## 6. 你的权利

你可以通过应用查看、更正或删除本地账号数据。撤回同意可以退出登录或删除上面的文件。隐私问题请到：

<https://github.com/JO-Beacon/JO-Launcher/issues>

## 7. 未成年人

本应用不面向儿童。未满 14 周岁的未成年人应在父母或监护人同意后使用。

## 8. 变更

本说明更新时，如果隐私说明版本发生变化，应用会重新请求同意。当前版本为 **1**。
