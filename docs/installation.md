# 安装、设置与故障排查

本文面向 Windows 用户，介绍 Codex 初音未来·月光都市主题的完整安装、更新、验证、恢复和问题提交方式。

## 安装前检查

1. 确认官方 Codex 来自 Microsoft Store：

   ```powershell
   Get-AppxPackage -Name OpenAI.Codex
   ```

2. 确认 Node.js 版本不低于 22：

   ```powershell
   node --version
   ```

3. 确认系统包含 Windows PowerShell 5.1 或更高版本。

项目完整验证所用的 Codex 版本是 `26.715.3651.0`。其他版本不属于当前验证声明。

## 从 Release 安装

1. 从本仓库 Releases 下载 ZIP 和同名 `.zip.sha256`。
2. 可选校验：

   ```powershell
   Get-FileHash -Algorithm SHA256 .\codex-miku-moonlight-theme-1.0.0.zip
   Get-Content .\codex-miku-moonlight-theme-1.0.0.zip.sha256
   ```

3. 解压 ZIP，进入解压目录并运行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
   ```

4. 安装成功后，从桌面或开始菜单打开“Codex 初音未来主题”。直接打开官方 Codex 图标不会加载主题。

安装器会验证 Store 包和 Node.js，并把经过哈希验证的运行文件复制到 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1`。普通安装不需要管理员权限。

## 从源码安装

从 GitHub 仓库页面复制克隆地址并完成 `git clone` 后，在仓库根目录运行相同入口：

```powershell
Set-Location .\codex-miku-moonlight-theme
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

维护者也可以直接运行 `windows\scripts\install-dream-skin.ps1`。根目录脚本是面向用户的稳定接口。

## 端口

首选 CDP 端口为 `9335`，且只绑定 `127.0.0.1`。默认端口被占用时，启动器最多向后查找 100 个端口；明确指定的端口被占用时会安全停止。

安装时指定端口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -Port 9444
```

端口有效范围是 `1024`–`65535`。

## 调整设置

主题页面内的设置面板提供：

- 任务页背景透明度：默认 30%，范围 5%–100%。在窗口顶部、Windows 最小化按钮左侧点击圆形 `✦` 打开设置；100% 会完全移除任务页白色玻璃底层，背景最清晰但可能降低长文本和代码的可读性。
- 星光闪烁。
- 月光呼吸。
- 城市灯光。
- 边框流光。
- 偶发流星。
- 暂停全部动态。

设置只保存在 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\settings.json`。写入使用同目录临时文件和原子替换。

## 更新

退出正在运行的主题会话，下载并解压新版本，然后重新运行 `.\Install.ps1`。安装器会更新 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1` 和两个快捷方式，同时保留 `runtime` 下的设置。

Codex 自身升级后如果主题失效，也使用同一更新流程。

## 恢复官方界面

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -PromptRestart
```

恢复操作会关闭经过身份校验的主题注入器和 CDP 会话，随后按需重新打开官方 Codex。它不会读取或写入 Codex `config.toml`。

## 完整卸载主题

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -Uninstall -PromptRestart
```

卸载只移除：

- 桌面和开始菜单中的“Codex 初音未来主题”。
- 桌面中的“还原 Codex 官方界面”。
- `%LOCALAPPDATA%\CodexMikuMoonlightTheme` 受管目录。

不会删除 Codex 任务、项目、插件、登录状态、工作区或其他用户数据。

## 文件与日志位置

| 用途 | 路径 |
|---|---|
| 产品根目录 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme` |
| 已安装代码 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1` |
| 运行状态 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\state.json` |
| 主题设置 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\settings.json` |
| 日志目录 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\logs` |
| 注入器日志 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\logs\injector.log` |
| 注入器错误 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\logs\injector-error.log` |
| 验证日志 | `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime\logs\verify.log` |

## 手动验证

先通过主题快捷方式启动 Codex，再运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\verify-dream-skin.ps1"
```

验证器会检查官方包身份、回环监听、进程身份、Browser ID、目标渲染器、主题根类、主页或任务模式、设置桥接、透明度范围和无自启动项。

## 故障排查

### 找不到官方 Codex

确认 `Get-AppxPackage -Name OpenAI.Codex` 能返回当前用户注册的 Store 包。侧载包、开发包和任意路径下的 `ChatGPT.exe` 不会被接受。

### 找不到 Node.js

运行 `node --version`。安装 Node.js 22+ 后重新打开 PowerShell，让新的 `PATH` 生效。

### 默认图标启动后没有主题

改用“Codex 初音未来主题”快捷方式。官方图标不会携带 CDP 参数。

### 端口被占用

未显式指定端口时让启动器自动选择。使用 `-Port` 时，请换用另一个 `1024`–`65535` 范围内的空闲端口，不要结束身份不明的监听进程。

### 主页有主题、任务页不明显

任务页使用玻璃白可读层。打开主题设置，将透明度从默认 30% 调整到合适数值。

### Codex 升级后主题消失

重新运行 `.\Install.ps1` 并使用主题快捷方式。脚本会重新发现当前 Store 包。

## 提交 Issue

提交 Issue 时请提供：

- Windows 版本。
- Codex 版本和安装来源。
- Node.js 版本。
- 清晰的复现步骤。
- 验证器失败的检查名称。
- 已删除隐私内容的相关日志片段。

不要上传访问令牌、API Key、`auth.json`、完整 `config.toml`、私人对话、项目源码或整个用户目录。日志中如出现本机用户名和路径，可先替换为占位文本。

## 安全提醒

回环地址阻止局域网直接连接，但 CDP 不验证同一 Windows 用户下的其他本机进程。主题运行期间只运行可信软件；使用结束后可执行 Restore 关闭调试会话。
