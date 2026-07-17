# Codex 初音未来·月光都市主题

本项目为 Windows 官方 Codex 桌面应用提供本地、可恢复的运行时主题。

- 已验证 Codex 包：OpenAI.Codex 26.715.2305.0
- 上游底座：Fei-Away/Codex-Dream-Skin
- 固定提交：d4087e6e992b478f4626ba11e553f8bc19aea14f
- 默认任务背景透明度：15%
- 可调范围：5%–35%

安全边界：只连接本机回环 CDP；不修改 WindowsApps、app.asar、API/模型配置或 Codex config.toml；不创建服务、计划任务和开机自启。

## 安装与使用

在 `windows` 目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
```

安装后使用桌面或开始菜单中的“Codex 初音未来主题”启动。普通方式启动 Codex 仍为官方外观。

```powershell
# 启动主题
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\start-dream-skin.ps1"

# 验证十项安全与主题状态
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\verify-dream-skin.ps1"

# 恢复官方界面
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\restore-dream-skin.ps1" -RestoreBaseTheme

# 完整卸载主题
powershell -NoProfile -ExecutionPolicy RemoteSigned -File "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\restore-dream-skin.ps1" -Uninstall
```

任务页背景默认 15%，可在 5%–35% 间调节。星光、月光呼吸、城市灯光、边框流光和流星可独立关闭，也可暂停全部动态。所有设置只写入主题自己的 `runtime\settings.json`。
