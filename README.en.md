# Codex API Access Repair Plugin

[中文](README.md) | English

**A persistence-focused repair plugin for Codex Desktop API access and plugin capabilities on Windows.**

Use it when Codex Desktop loses Fast Mode, plugin marketplace access, Goal, Computer Use, Chrome plugin installation, or local marketplace persistence after upgrades or restarts.

## What It Fixes

- Codex Desktop Fast Mode and `service_tier=priority` request verification.
- Codex API access behavior after Windows Store / MSIX upgrades.
- Plugin marketplace visibility and local marketplace layout.
- Stable `openai-bundled-local` marketplace persistence.
- Goal and Computer Use feature flags.
- `computer-use@openai-bundled-local` installation and enablement.
- Chrome plugin install failures caused by locked plugin cache directories.
- Hidden or unavailable `Any App` / Computer Control settings.

## Skill Name

Machine-readable name:

```text
codex-api-access-repair-plugin
```

Display name:

```text
Codex API 接入修复插件
```

## Main Commands

Dry run after an upgrade:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\repatch-codex-windows.ps1" -DryRun
```

Full API access and desktop capability repair:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\repatch-codex-windows.ps1"
```

Persist repaired state:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1"
```

Repair Chrome plugin cache locks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-api-access-repair-plugin\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```
