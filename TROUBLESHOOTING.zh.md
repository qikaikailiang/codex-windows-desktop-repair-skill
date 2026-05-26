# Windows Codex Desktop 排障速查

这份速查表用于配合 `codex-windows-desktop-repair` skill 使用。

## 1. 重启后插件或 Computer Use 消失

可能原因：

- Codex Desktop 启动时重写了 bundled marketplace。
- Computer Use 的环境变量或本地插件启用状态没有持久化。

处理命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1"
```

验证点：

```powershell
codex features list
codex plugin list
```

需要看到：

```text
computer_use true
goals true
plugins true
computer-use@openai-bundled-local (installed, enabled)
```

## 2. Chrome 插件安装失败

可能原因：

- 旧的 extension-host 进程占用插件缓存。
- `plugins\cache\openai-bundled\chrome` 目录权限或锁状态异常。

处理命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```

处理后重新从插件市场安装 Chrome。

## 3. Goal 不能设置

可能原因：

- `[features] goals = true` 没有写入或被覆盖。
- Desktop 还没有重启读取新配置。

处理命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1"
```

然后完全关闭并重新打开 Codex Desktop。

## 4. Fast Mode 看起来开了但不确定是否生效

不要只看 UI 或 `FAST_CHECK_OK`。必须抓 Codex Desktop 发出的请求，确认请求里有：

```text
service_tier=priority
```

推荐直接跑完整修复脚本，让脚本完成 wire verification。

## 5. App 启动后自动退出

先抓 Electron 日志：

```powershell
$pkg = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
$exe = Join-Path $pkg.InstallLocation 'app\Codex.exe'
$env:ELECTRON_ENABLE_LOGGING='1'
Push-Location (Split-Path -Parent $exe)
& $exe --enable-logging=stderr --v=1 2>&1 | Select-String -Pattern 'FATAL|Integrity|asar|ERROR'
Pop-Location
Remove-Item Env:ELECTRON_ENABLE_LOGGING -ErrorAction SilentlyContinue
```

如果出现 ASAR integrity 或签名相关错误，重新走 MSIX repack 流程。

## 6. marketplace snapshot 加载失败

检查本地 marketplace 目录是否有：

```text
.agents\plugins\marketplace.json
```

只有根目录 `marketplace.json` 通常不够，当前 Codex CLI 会按 `.agents\plugins\marketplace.json` 查找本地 marketplace 清单。
