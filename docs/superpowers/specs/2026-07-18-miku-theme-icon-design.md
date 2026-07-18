# Miku Moonlight Theme Icon Design

Date: 2026-07-18

## Goal

Give the separate `Codex 初音未来主题` launcher a recognizable Miku-themed icon and make it suitable for pinning to the Windows taskbar, while leaving the official Codex shortcut and icon unchanged.

## Approved visual direction

The selected direction is **C: Miku music monogram**.

The icon uses:

- a deep moonlight-blue to violet rounded-square background;
- a high-contrast turquoise `M` combined with a music note;
- one restrained white/cyan star sparkle;
- a subtle cyan glow that remains readable at taskbar sizes.

The design must be redrawn as a clean icon asset rather than reusing the comparison-page CSS mockup directly. Fine details are intentionally limited so the mark stays clear at 16, 20, 24, and 32 pixels.

## Deliverables

- A source PNG at high resolution for future editing.
- A Windows multi-resolution `.ico` containing at least 16, 20, 24, 32, 48, 64, 128, and 256 pixel representations.
- Updated desktop and Start Menu theme shortcuts whose `IconLocation` points to the installed icon.
- Installer/package changes so a reinstall recreates the same themed shortcuts.
- Updated release ZIP and user instructions.

## Shortcut behavior

The existing themed shortcut remains the entry point. Its target and arguments continue to launch the installed `start-dream-skin.ps1` script with the current restart behavior; only the display icon is changed.

The official Codex shortcut is not replaced, renamed, or modified. This keeps the unthemed recovery path available and avoids conflicts with Codex updates.

## Taskbar strategy

Windows does not provide a stable supported scripting API for taskbar pinning. The implementation will therefore:

1. create and verify the themed Start Menu shortcut;
2. attempt pinning through the normal Windows shell interface when available;
3. if Windows blocks automation, leave the verified shortcut ready and require one user action: right-click it and choose `固定到任务栏`.

The implementation will not use undocumented registry mutations or replace the official pinned Codex entry.

## Installation and recovery

The icon file is copied into the versioned installed package so the shortcut never points at a temporary or workspace-only path. Re-running the installer refreshes the icon and both themed shortcuts. The restore workflow continues to remove only theme-owned launchers and runtime files, without touching the official Codex installation.

## Validation

Acceptance requires:

- the `.ico` exposes all required sizes and renders without transparency or scaling defects;
- desktop and Start Menu shortcuts resolve to the installed icon file;
- launching either themed shortcut still applies the theme and opens Codex;
- the official Codex shortcut still opens the unthemed application;
- install, reinstall, and restore checks pass;
- the distributable ZIP contains the icon and updated installer sources.

## Non-goals

- Replacing Codex application binaries or executable resources.
- Changing the official Codex app icon globally.
- Shipping a separate launcher executable.
- Using the full anime character artwork as the taskbar icon.
