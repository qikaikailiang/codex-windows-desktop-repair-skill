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

## Difference From The Original Fast Patch Skill

- It is positioned as a desktop repair and persistence skill, not just a Fast Mode patch.
- Persistence is part of the default recovery path.
- It introduces the stable `openai-bundled-local` marketplace strategy.
- It documents Goal, Computer Use, Chrome cache, plugin install failure, and restart durability issues.
- The primary documentation is Chinese and organized around user-visible failure symptoms.
