# Windows 源码与维护说明

普通用户请从仓库根目录阅读 [README.md](../README.md)，并使用根目录 `Install.ps1` 和 `Restore.ps1`。

本目录包含 Codex Miku Moonlight Theme 的 Windows 实现：主题资源、CDP 注入器、PowerShell 生命周期脚本、维护者参考资料和测试。

## 直接从源码安装

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
```

安装器将受管运行时复制到 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\package-v1`，设置和状态位于 `%LOCALAPPDATA%\CodexMikuMoonlightTheme\runtime`。只创建“Codex 初音未来主题”和“还原 Codex 官方界面”入口；不创建托盘快捷方式、服务、计划任务、Run 注册表项或开机自启动。

安装不修改 WindowsApps、`app.asar`、应用签名、API/模型配置或 Codex `config.toml`，也不要求仅为复制运行时而关闭一个无关的官方 Codex 会话。

## 启动与恢复

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\start-dream-skin.ps1" -PromptRestart

powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File `
  "$env:LOCALAPPDATA\CodexMikuMoonlightTheme\package-v1\scripts\restore-dream-skin.ps1" -RestoreBaseTheme
```

## 测试

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\miku-contract-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\miku-product-contract-tests.ps1
```

完整安装、路径、日志和排查说明见 [安装与故障排查](../docs/installation.md)。
