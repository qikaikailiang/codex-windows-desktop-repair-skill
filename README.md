# Codex API 接入修复插件

语言：中文 | [English](README.en.md)

**这是一个用于修复 Windows Codex Desktop API 接入和插件能力的持久化修复插件。**

它面向所有遇到 Codex Desktop 接入异常的人：Fast Mode 不生效、插件市场异常、Goal 不可用、Computer Use 消失、Chrome 插件安装失败、重启后配置丢失，都可以从这里开始排查。

## 这个插件能做什么

- 修复 Codex Desktop 升级后丢失的 Fast Mode、插件入口、Goal 和 Computer Use。
- 验证 Codex API 请求是否真的携带 `service_tier=priority`。
- 修复插件市场和本地 marketplace 配置。
- 持久化 `openai-bundled-local` 本地插件市场。
- 持久化 Goal 和 Computer Use 功能开关。
- 安装并启用 `computer-use@openai-bundled-local`。
- 修复 Chrome 插件安装失败时常见的缓存锁定问题。
- 修复 `Any App` / `任意应用` 被隐藏、禁用或显示不可用的问题。

## 适合谁用

- Windows 上 Codex Desktop 升级后功能消失的用户。
- 使用 Codex API / Fast Mode，但不确定请求是否真的走 priority 的用户。
- 插件市场能打开但插件安装失败的用户。
- 想把 Computer Use、Goal、插件市场状态持久化的用户。
- 维护 Codex Desktop 本地补丁、MSIX 重签名和插件市场配置的人。

## Skill 名称

机器可识别名称：

```text
codex-api-access-repair-plugin
```

中文展示名：

```text
Codex API 接入修复插件
```

## 安装位置

推荐安装到：

```powershell
$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin
```

## 常用命令

升级后先检查补丁目标：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\repatch-codex-windows.ps1" -DryRun
```

完整修复 API 接入和桌面能力：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\repatch-codex-windows.ps1"
```

持久化修复结果：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1"
```

只验证当前状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1" -VerifyOnly
```

修复 Chrome 插件安装失败或缓存占用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```

## 典型用法

可以这样对 Codex 说：

```text
使用 codex-api-access-repair-plugin 这个 skill，修复这台 Windows 机器上的 Codex API 接入、Fast Mode、插件市场、Goal 和 Computer Use 可用性/持久化问题。
```

## 排障速查

更多按故障现象整理的命令见：

[TROUBLESHOOTING.zh.md](TROUBLESHOOTING.zh.md)
