---
name: codex-api-access-repair-plugin
description: Use when Windows 上的 Codex Desktop 因升级、重启、MSIX 重签名、插件市场异常、API 接入配置或缓存锁定，导致 Fast Mode、Codex API 接入、插件市场、Goal、Computer Use 或 Chrome 插件不可用。
---

# Codex API 接入修复插件

这个 skill 的作用很明确：修复 Windows 上 Codex Desktop 的 API 接入、Fast Mode、插件市场、Goal、Computer Use 和插件安装能力，并把修复后的状态持久化，避免重启或升级后再次丢失。

它适合公开给其他人使用，因为它不是只处理单个按钮或单个补丁，而是把 Codex Desktop 在 Windows 上常见的“接入不稳定、插件不可用、配置不持久”问题整理成一套可复用的修复流程。

## 它解决什么问题

- Codex Desktop 升级后，Fast Mode、插件入口、Goal 或 Computer Use 消失。
- Codex API 接入链路不稳定，Fast Mode 看起来打开了但不确定是否真的发送 `service_tier=priority`。
- 插件市场能打开，但 Chrome 等插件安装失败、拒绝访问或缓存目录被占用。
- 重启后本地插件市场、Computer Use 或 Goal 状态掉回默认。
- Computer Control 里的 `Any App` / `任意应用` 被隐藏、灰掉，或提示组织/地区不可用。
- 本地 marketplace 清单结构不兼容，导致 `codex plugin list` 报 snapshot 加载失败。

## 公开定位

**一句话说明：这是一个用于修复 Windows Codex Desktop API 接入和插件能力的持久化修复插件。**

面向用户：

- 不懂 MSIX、ASAR、marketplace 结构的人，可以按故障现象运行命令。
- 已经打过补丁的人，可以用它验证和持久化当前状态。
- 遇到插件市场、Goal、Computer Use、Chrome 安装失败的人，可以用它直接排障。

面向维护者：

- 补丁脚本负责 MSIX repack、签名、安装和 Fast Mode wire verification。
- 持久化脚本负责 `openai-bundled-local`、Computer Use、Goal、环境变量和插件缓存修复。
- 文档按故障现象组织，方便公开仓库首页直接说明用途。

## 总原则

- 不直接修改 `C:\Program Files\WindowsApps` 中的已安装文件，优先使用 MSIX repack。
- Fast Mode 是否生效，只以请求里实际出现 `service_tier=priority` 为准。
- 本地增强内容写入稳定的 `openai-bundled-local`，不要和 Desktop 自动重写的 `openai-bundled` 对抗。
- 每次升级、重启、插件异常后，都可以重新运行持久化脚本。
- 修复完成后必须验证 feature flags、plugin list 和 Computer Use helper。

## 快速修复

查看当前 Codex Desktop 安装状态：

```powershell
Get-AppxPackage -Name OpenAI.Codex | Select-Object Name,PackageFullName,Version,SignatureKind,InstallLocation
```

升级后先做补丁目标检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\repatch-codex-windows.ps1" -DryRun
```

执行完整 API 接入与桌面能力修复：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\repatch-codex-windows.ps1"
```

执行持久化修复：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1"
```

## 故障速查

| 现象 | 先做什么 | 然后做什么 |
| --- | --- | --- |
| 升级后 Fast Mode / 插件 / Goal 消失 | 跑 `repatch-codex-windows.ps1 -DryRun` | 通过后跑完整 repatch |
| API 接入不确定是否走 Fast Mode | 跑完整 repatch | 查看 wire verification 是否有 `service_tier=priority` |
| 重启后插件或 Computer Use 又掉 | 跑 `persist-codex-desktop-state.ps1` | 重启 Codex Desktop |
| Goal 不能设置 | 确认 `[features] goals = true` | 跑持久化脚本并重启 |
| Chrome 插件安装失败 | 关闭 Codex Desktop | 跑 `persist-codex-desktop-state.ps1 -RepairChromeCache` |
| marketplace snapshot 错误 | 检查 `.agents\plugins\marketplace.json` | 先修 marketplace 布局 |
| App 启动后自动退出 | 打开 Electron 日志 | 检查 ASAR integrity 或签名问题 |

## 持久化脚本做什么

`persist-codex-desktop-state.ps1` 会把容易被升级或重启冲掉的状态重新落盘：

- 维护 `$env:USERPROFILE\.codex\marketplaces\openai-bundled-local` 稳定 marketplace。
- 安装并启用 `computer-use@openai-bundled-local`。
- 写入 `[features] computer_use = true` 和 `goals = true`。
- 写入 `[marketplaces.openai-bundled-local]`。
- 写入 `[plugins."computer-use@openai-bundled-local"] enabled = true`。
- 写入用户环境变量 `CODEX_ELECTRON_ENABLE_WINDOWS_COMPUTER_USE=1`。
- 提供 Chrome 插件缓存锁修复入口。

只检查不修改：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1" -VerifyOnly
```

修复 Chrome 插件缓存占用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```

## Computer Use 单独修复

刷新 Windows Computer Use 兼容文件和环境变量：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\install-computer-use-local.ps1"
```

自动验证并补齐缺失文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\install-computer-use-local.ps1" -VerifyOnly
```

严格只读验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\install-computer-use-local.ps1" -StrictVerifyOnly
```

## 启动即退出排查

```powershell
$pkg = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
$exe = Join-Path $pkg.InstallLocation 'app\Codex.exe'
$env:ELECTRON_ENABLE_LOGGING='1'
Push-Location (Split-Path -Parent $exe)
& $exe --enable-logging=stderr --v=1 2>&1 | Select-String -Pattern 'FATAL|Integrity|asar|ERROR'
Pop-Location
Remove-Item Env:ELECTRON_ENABLE_LOGGING -ErrorAction SilentlyContinue
```

如果看到 ASAR integrity、签名或资源文件错误，重新走 MSIX repack，不要直接手改 WindowsApps。

## 成功标准

- `Get-AppxPackage -Name OpenAI.Codex` 显示 `SignatureKind = Developer`。
- Fast Mode 抓包日志显示 `request wire service_tier=priority`。
- `codex features list` 显示 `fast_mode`、`plugins`、`computer_use`、`goals` 为 `true`。
- `config.toml` 包含 `[marketplaces.openai-bundled-local]`。
- `config.toml` 包含 `[plugins."computer-use@openai-bundled-local"] enabled = true`。
- `codex plugin list` 显示 `computer-use@openai-bundled-local (installed, enabled)`。
- 用户环境变量 `CODEX_ELECTRON_ENABLE_WINDOWS_COMPUTER_USE` 为 `1`。
- Computer Use helper_transport 能返回屏幕信息或截图。

## 本版定位

这个 skill 是“Codex API 接入修复插件”：重点是让所有人一眼知道它用于修复 Windows Codex Desktop 的 API 接入、Fast Mode、插件市场、Goal、Computer Use 和插件安装/持久化问题。
