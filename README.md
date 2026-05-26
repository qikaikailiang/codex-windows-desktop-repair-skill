# Codex Windows 桌面修复与持久化 Skill

语言：中文 | [English](README.en.md)

这是 `codex-windows-desktop-repair` skill，用于在 Windows 上修复并持久化 Codex Desktop 的本地补丁、插件市场、Goal 和 Computer Use 能力。

## 主要能力

- 在 Codex Desktop 升级或重启后重新应用 MSIX 补丁。
- 验证 Fast Mode 请求是否真的携带 `service_tier=priority`。
- 修复插件入口、插件市场和本地 marketplace 配置。
- 持久化 `openai-bundled-local` 本地插件市场。
- 启用并持久化 `Goal` 和 `Computer Use` 功能开关。
- 安装并启用 `computer-use@openai-bundled-local` 兼容插件。
- 修复 Chrome 插件安装失败时常见的缓存锁定问题。
- 修复 Computer Control 页面里 `Any App` / `任意应用` 被隐藏、禁用或显示不可用的问题。

## 安装位置

推荐安装到：

```powershell
$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair
```

## 常用命令

完整修复并持久化：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\repatch-codex-windows.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1"
```

只验证当前持久化状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1" -VerifyOnly
```

修复 Chrome 插件安装失败或缓存占用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```

## 典型用法

可以这样对 Codex 说：

```text
使用 codex-windows-desktop-repair 这个 skill，检查并修复这台 Windows 机器上的 Codex Desktop Fast Mode、插件市场、Goal 和 Computer Use 可用性/持久化问题。
```

## 注意

`codex-windows-desktop-repair` 是 skill 的机器可识别名称，需要保留英文和连字符格式；中文名“Codex Windows 桌面修复与持久化”是展示名称。
