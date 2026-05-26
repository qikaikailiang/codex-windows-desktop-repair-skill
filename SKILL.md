---
name: codex-windows-desktop-repair
description: Use when Windows 上的 Codex Desktop 在升级、重启、MSIX 重签名、插件缓存锁定后，出现 Fast Mode、插件市场、Goal、Computer Use 或 Chrome 插件安装不可用。
---

# Codex Windows 桌面修复与持久化

这是一个中文优先的 Windows Codex Desktop 修复 skill。它不是只做一次性补丁，而是按“先诊断、再修复、最后持久化”的顺序处理 Fast Mode、插件市场、Goal、Computer Use、Chrome 插件缓存和本地 marketplace 配置。

## 适用场景

- Codex Desktop 自动升级后，Fast Mode、插件入口、Goal 或 Computer Use 消失。
- 重启 Codex Desktop 后，本地插件市场或 Computer Use 状态掉回默认。
- 插件市场能打开，但安装 Chrome 等插件时提示安装失败、拒绝访问或缓存目录被占用。
- Computer Control 里 `Any App` / `任意应用` 被隐藏、灰掉，或者提示组织/地区不可用。
- 已经打过 MSIX 补丁，但想确认 `service_tier=priority` 是否真的发出。

## 总原则

- 不直接改 `C:\Program Files\WindowsApps` 里的已安装文件，除非用户明确要求并理解风险。
- 每次 Store 升级后先 dry run，再执行完整 repatch。
- 每次 repatch、重启、插件异常后都运行持久化脚本。
- 本地增强内容优先落到 `openai-bundled-local`，不要和 Desktop 自动重写的 `openai-bundled` 对抗。
- Fast Mode 只以抓到 `/v1/responses` WebSocket 请求里的 `service_tier=priority` 为准。

## 快速入口

查看当前安装状态：

```powershell
Get-AppxPackage -Name OpenAI.Codex | Select-Object Name,PackageFullName,Version,SignatureKind,InstallLocation
```

升级后先做补丁目标检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\repatch-codex-windows.ps1" -DryRun
```

执行完整修复：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\repatch-codex-windows.ps1"
```

执行持久化修复：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1"
```

## 决策流程

| 现象 | 先做什么 | 然后做什么 |
| --- | --- | --- |
| Store 升级后功能消失 | 跑 `repatch-codex-windows.ps1 -DryRun` | dry run 通过后跑完整 repatch |
| 重启后插件或 Computer Use 又掉 | 跑 `persist-codex-desktop-state.ps1` | 重启 Codex Desktop |
| Goal 不能设置 | 确认 `[features] goals = true` | 跑持久化脚本并重启 |
| Chrome 插件安装失败 | 关闭 Codex Desktop | 跑 `persist-codex-desktop-state.ps1 -RepairChromeCache` |
| `codex plugin list` 报 marketplace snapshot 错误 | 检查 `.agents\plugins\marketplace.json` | 先修 marketplace 布局，再诊断插件 |
| App 启动后自动退出 | 打开 Electron 日志 | 检查 ASAR integrity 或签名问题 |

## 持久化做了什么

`persist-codex-desktop-state.ps1` 会把容易被重启或升级冲掉的状态重新落盘：

- 同步当前安装包里的 bundled marketplace 到稳定目录。
- 维护 `$env:USERPROFILE\.codex\marketplaces\openai-bundled-local`。
- 安装并启用 `computer-use@openai-bundled-local`。
- 写入 `[features] computer_use = true` 和 `goals = true`。
- 写入 `[marketplaces.openai-bundled-local]`。
- 写入 `[plugins."computer-use@openai-bundled-local"] enabled = true`。
- 写入用户环境变量 `CODEX_ELECTRON_ENABLE_WINDOWS_COMPUTER_USE=1`。
- 提供 Chrome 插件缓存锁修复入口。

只检查不修改：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1" -VerifyOnly
```

修复 Chrome 插件缓存占用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```

## Computer Use 单独修复

只刷新 Windows Computer Use 兼容文件和环境变量：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\install-computer-use-local.ps1"
```

自动验证并补齐缺失文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\install-computer-use-local.ps1" -VerifyOnly
```

严格只读验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\install-computer-use-local.ps1" -StrictVerifyOnly
```

## 常用参数

| 参数 | 用途 |
| --- | --- |
| `-DryRun` | 只检查补丁目标，不安装 |
| `-NoLaunch` | 安装后不启动 Codex Desktop |
| `-SkipFastVerify` | 跳过 Fast Mode 抓包验证 |
| `-KeepBuild` | 保留 `Downloads\codex-msix-repack` 方便排错 |
| `-SkipSdkCleanup` | 不清理临时安装的 Windows SDK |
| `-RegisterMarketplaceOnly` | 只注册本地 marketplace，不重打补丁 |
| `-SkipComputerUse` | 跳过 Computer Use 兼容插件安装 |
| `-RepairChromeCache` | 清理 Chrome 插件安装失败常见的锁定缓存 |

## 启动即退出排查

如果 Codex Desktop 启动后立刻退出，先抓 Electron 日志：

```powershell
$pkg = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
$exe = Join-Path $pkg.InstallLocation 'app\Codex.exe'
$env:ELECTRON_ENABLE_LOGGING='1'
Push-Location (Split-Path -Parent $exe)
& $exe --enable-logging=stderr --v=1 2>&1 | Select-String -Pattern 'FATAL|Integrity|asar|ERROR'
Pop-Location
Remove-Item Env:ELECTRON_ENABLE_LOGGING -ErrorAction SilentlyContinue
```

看到 ASAR integrity、签名或资源文件错误时，重新走 MSIX repack，不要直接在 WindowsApps 里手改。

## 成功标准

- `Get-AppxPackage -Name OpenAI.Codex` 显示 `SignatureKind = Developer`。
- Fast Mode 抓包日志显示 `request wire service_tier=priority`。
- `codex features list` 显示 `fast_mode`、`plugins`、`computer_use`、`goals` 为 `true`。
- `config.toml` 包含 `[marketplaces.openai-bundled-local]`。
- `config.toml` 包含 `[plugins."computer-use@openai-bundled-local"] enabled = true`。
- `codex plugin list` 显示 `computer-use@openai-bundled-local (installed, enabled)`。
- 用户环境变量 `CODEX_ELECTRON_ENABLE_WINDOWS_COMPUTER_USE` 为 `1`。
- Computer Use helper_transport 能返回屏幕信息或截图。
- 如果启用了 SDK 清理，`makeappx.exe` 和 `signtool.exe` 不再残留在系统 PATH 可见位置。

## 和原始 fast-patch 版的区别

- 名称和定位改为“桌面修复与持久化”，不只强调 Fast Mode。
- 默认流程把持久化作为必要步骤，而不是附加说明。
- 增加 `openai-bundled-local` 稳定 marketplace 策略。
- 增加 Goal、Chrome 插件缓存、插件安装失败的排障路径。
- 说明文档中文优先，按真实故障现象组织，而不是按脚本参数堆叠。
