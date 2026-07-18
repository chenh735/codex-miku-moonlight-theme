# Codex 初音未来·月光都市主题

[English](./README.en.md)

适用于 Windows 官方 Codex 桌面版的非官方初音未来粉丝主题。它保留原生侧栏、任务内容和输入框，通过仅绑定本机回环地址的 CDP 加载月光都市背景、玻璃界面与轻量动态效果。

![初音未来月光都市背景](./windows/assets/miku-moonlight-hero.png)

## 功能

- 主页和对话任务页使用同一套月光都市视觉。
- 任务页背景默认透明度为 30%，可在 5%–35% 之间调节。
- 星光、月光呼吸、城市灯光、边框流光和流星效果可分别关闭。
- 提供独立的“Codex 初音未来主题”桌面和开始菜单快捷方式。
- 主题运行时安装到 `%LOCALAPPDATA%\CodexMikuMoonlightTheme`，源码目录之后可以移动或删除。
- 可一键恢复官方 Codex；不会修改 WindowsApps、`app.asar`、应用签名或 Codex 的 `config.toml`。

## 系统要求

- Windows 10/11。
- 从 Microsoft Store 安装并注册到当前用户的官方 `OpenAI.Codex`。
- Node.js 22 或更高版本，并且 `node.exe` 可从 `PATH` 找到。
- Windows PowerShell 5.1 或更高版本。

当前完整验证版本为 Codex `26.715.3651.0`。其他版本可能可用，但尚未在本项目中声明为已验证。

## 从 GitHub Release 安装

1. 打开本仓库右侧的 **Releases**，下载最新的 `codex-miku-moonlight-theme-<版本>.zip`。
2. 可选：用同版本 `.zip.sha256` 文件校验下载内容。
3. 解压 ZIP，不要直接在压缩包预览窗口中运行脚本。
4. 在解压目录中右键 `Install.ps1`，选择“使用 PowerShell 运行”；也可以在 PowerShell 中执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

`Bypass` 只用于这次由你明确启动的安装过程。安装后的快捷方式使用 `RemoteSigned`，脚本不会修改系统或用户的永久执行策略。

## 正确启动主题

安装后请使用桌面或开始菜单中的 **Codex 初音未来主题**。直接点击官方 Codex 图标会启动未注入主题的官方界面，这是预期行为。

首次主题启动或 Codex 已经打开时，快捷方式会先询问是否重启当前 Codex。主题会把 CDP 绑定到 `127.0.0.1`；默认端口为 `9335`，被占用时会在有限范围内寻找空闲端口。

## 调整透明度与动态效果

主题设置面板可将任务页透明度从 5% 调整到 35%，默认值为 30%。星光、月光呼吸、城市灯光、流光边框和流星均可独立启停，也可以暂停全部动态。

设置只写入 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\settings.json`，不会写入 Codex 配置。

## 更新

下载新的 Release ZIP，解压后重新运行 `.\Install.ps1`。安装器会原子替换受管运行时并重建快捷方式，同时保留当前主题设置。

Codex 更新后若主题失效，也先重新运行安装器，再从“Codex 初音未来主题”快捷方式启动。

## 恢复与卸载

恢复官方界面并关闭主题调试会话：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -PromptRestart
```

同时删除主题快捷方式和受管主题目录：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -Uninstall -PromptRestart
```

恢复脚本不会删除 Codex 的任务、项目、登录状态或其他用户数据。

## 常见问题

### 主页有主题，但对话页看起来接近白色

对话页使用可读性玻璃层，背景穿透强度由任务页透明度控制。打开主题设置，将透明度调整到合适数值；当前默认是 30%。

### 通过默认 Codex 图标启动后没有主题

默认图标不启动 CDP 注入。请改用“Codex 初音未来主题”快捷方式。

### 找不到 Node.js 22

运行 `node --version`。如果版本低于 22 或命令不存在，请安装新版 Node.js 后重新打开 PowerShell。

### Codex 更新后主题失效

重新运行 `.\Install.ps1`。脚本每次都会重新发现当前注册的官方 Store 包，不依赖旧版 WindowsApps 路径。

### 端口或注入失败

查看 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\logs`。详细路径、排查步骤和 Issue 提交要求见 [安装与故障排查](./docs/installation.md)。

## 安全说明

- CDP 仅监听 `127.0.0.1`，不会暴露到局域网。
- CDP 对同一 Windows 用户下的其他本机进程没有独立身份验证；主题运行时不要启动不可信的本地程序。
- 本项目不会把对话、任务或工作区数据上传到第三方服务器。
- 不使用主题时可运行 `.\Restore.ps1` 关闭调试会话。
- 脚本只接受已注册的官方 Microsoft Store Codex 包，并在停止进程前校验包、路径、Browser ID 和会话状态。

## 上游、许可证与素材声明

本项目基于 [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) 的 Windows 实现，固定来源见 [UPSTREAM.md](./UPSTREAM.md)。软件代码按 [MIT License](./LICENSE) 发布。

初音未来名称、角色形象、相关商标和第三方插画不包含在 MIT 代码授权中。本项目是非官方、非商业粉丝主题，与 OpenAI、Crypton Future Media 或其他权利人不存在隶属、授权或背书关系。公开再分发或商业使用前，请阅读 [NOTICE.md](./NOTICE.md) 并自行完成权利审查。
