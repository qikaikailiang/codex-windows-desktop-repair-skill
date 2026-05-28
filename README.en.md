# Codex Windows Desktop Repair and Persistence Skill

[中文](README.md) | English

This is a Chinese-first enhanced Codex skill for repairing and persisting Codex Desktop behavior on Windows. It focuses on real recovery symptoms rather than only the original Fast Mode patch flow.

## What It Covers

- Repatching Codex Desktop MSIX packages after Store upgrades.
- Verifying Fast Mode through the actual `service_tier=priority` request wire.
- Restoring plugin marketplace visibility and local marketplace layout.
- Persisting a stable `openai-bundled-local` marketplace.
- Keeping Goal and Computer Use feature flags enabled.
- Installing and enabling `computer-use@openai-bundled-local`.
- Repairing locked Chrome plugin cache directories before reinstalling Chrome.

## Skill Name

The machine-readable skill name is:

```text
codex-windows-desktop-repair
```

The Chinese display name is:

```text
Codex Windows 桌面修复与持久化
```

## Main Commands

Dry run after an upgrade:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\repatch-codex-windows.ps1" -DryRun
```

Full repair:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\repatch-codex-windows.ps1"
```

Persist desktop state:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1"
```

Repair Chrome plugin cache locks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\codex-windows-desktop-repair\scripts\persist-codex-desktop-state.ps1" -RepairChromeCache
```

## Project Focus

This skill targets complete Codex Desktop repair and persistence on Windows. It covers MSIX patch recovery after upgrades, plugin marketplace repair, Goal, Computer Use, Chrome plugin cache failures, and configuration loss after restarts.

The default workflow treats persistence as part of the repair path. After patching, it verifies and rewrites the stable `openai-bundled-local` marketplace, `computer-use@openai-bundled-local`, Goal/Computer Use feature flags, and the related user environment variable.
