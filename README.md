# SlotOver

A lightweight Hammerspoon-based window manager for macOS overlapping slot layouts.

https://github.com/user-attachments/assets/faa5257c-f891-4d26-b5f8-de330145e779

It is designed mainly for displays that are wide enough to benefit from side areas, but not wide enough to comfortably split into three equal tiles, such as 21:9 ultrawide monitors. The screen is divided into three spatial slots: `left`, `center`, and `right`. Unlike a tiling window manager, both the slot regions themselves and the windows assigned to each slot are allowed to overlap.

This lets you keep the focused app large while still using the side areas for chat, music, notes, docs, browser references, or other supporting windows. Side windows can remain visible enough to monitor notifications or keep reference material in view without forcing every app into a narrow non-overlapping tile.

## Features

- Overlapping `left`, `center`, and `right` slot regions
- Comfortable main-window sizing with configurable min/max slot widths
- App-based focus shortcuts for jumping directly to known windows
- Relative focus and movement between slots
- Cycling through overlapping windows in the same slot
- Explicit reset-layout behavior on config reload

## Install

SlotOver runs on [Hammerspoon](https://www.hammerspoon.org/), a macOS automation tool that can control windows through Accessibility permissions.

### 1. Install Hammerspoon

If you use Homebrew:

```sh
brew install --cask hammerspoon
```

You can also download it from the [Hammerspoon website](https://www.hammerspoon.org/).

Open Hammerspoon once after installation. macOS will ask for Accessibility permission. Allow it in:

```text
System Settings > Privacy & Security > Accessibility
```

### 2. Install SlotOver

Create the Hammerspoon config directory if it does not exist:

```sh
mkdir -p ~/.hammerspoon
```

Copy SlotOver into it:

```sh
~/.hammerspoon/init.lua
~/.hammerspoon/slotover.lua
~/.hammerspoon/config.lua
```

If you are starting from this repository:

```sh
cp init.lua ~/.hammerspoon/init.lua
cp slotover.lua ~/.hammerspoon/slotover.lua
cp config.lua ~/.hammerspoon/config.lua
```

The included `config.lua` is a starter configuration. Edit your copied `~/.hammerspoon/config.lua` for your apps, slots, and shortcuts.

### 3. Reload Hammerspoon

Click the Hammerspoon menu bar icon and choose:

```text
Reload Config
```

You should see:

```text
SlotOver loaded
```

SlotOver can load without `config.lua`, but app-focus shortcuts are configured there, so most users should keep one.

## Default Shortcuts

Shortcuts are grouped by operation. Each group defines its own modifier:

```lua
shortcuts = {
  focusApp = {
    modifier = { "ctrl", "alt", "cmd" },
  },
  action = {
    modifier = { "ctrl", "alt", "cmd" },
    toggleMaximize = "return",
    inspectWindow = ",",
    reloadConfig = ".",
  },
  focusRelative = {
    modifier = { "alt" },
    up = "k",
    left = "h",
    down = "j",
    right = "l",
  },
  moveRelative = {
    modifier = { "alt", "shift" },
    left = "h",
    right = "l",
  },
}
```

| Action | Shortcut |
|---|---|
| Focus previous window in current slot | `Option + K` |
| Focus left slot | `Option + H` |
| Focus next window in current slot | `Option + J` |
| Focus right slot | `Option + L` |
| Move window left | `Option + Shift + H` |
| Move window right | `Option + Shift + L` |
| Maximize / restore | `Action + Enter` |
| Inspect current window | `Action + ,` |
| Reload config | `Action + .` |

`Focus App` and `Action` both mean `Ctrl + Option + Command` by default.

Reloading the config is also the explicit reset-layout action. When `behavior.placeOnReload` is enabled, known app windows are moved back to their configured slots only on reload.

## App Configuration

Each app profile can define:

```lua
{
  key = "e",
  bundleID = "com.microsoft.VSCode",
  titleSubstring = "optional title text",
  defaultSlot = "center",
}
```

`titleSubstring` is optional and works for any app, not just browsers.

If several app profiles share the same `key`, pressing that key repeatedly cycles through matching windows in the order they appear in `apps`.

If one matching profile has multiple windows, those windows are also cycled.

## Configuration Model

`slotover.lua` contains defaults. `config.lua` overrides them with a deep merge.

Nested tables such as `shortcuts`, `behavior`, and `slots.definitions` can be partially overridden:

```lua
return {
  slots = {
    definitions = {
      center = {
        maxWidth = 1700,
      },
    },
  },
}
```

### Apps

`apps` is a complete list. Add, remove, or reorder entries directly in `config.lua`:

```lua
return {
  apps = {
    {
      key = "e",
      bundleID = "com.microsoft.VSCode",
      defaultSlot = "center",
    },
  },
}
```

Unlike nested settings, `apps` is not deep-merged. This keeps app-focus order explicit and predictable.

## Slot Configuration

The default slot sizes are:

```lua
center = {
  widthRatio = 0.65,
  minWidth = 1800,
  maxWidth = 1920,
  heightRatio = 1.0,
  margin = 0,
}

left = {
  widthRatio = 0.4,
  minWidth = 1200,
  maxWidth = 1400,
  heightRatio = 1.0,
  margin = 0,
}

right = {
  widthRatio = 0.4,
  minWidth = 1200,
  maxWidth = 1400,
  heightRatio = 1.0,
  margin = 0,
}
```

Widths are computed as:

```text
screen width * widthRatio, clamped between minWidth and maxWidth
```

If the screen is narrower than the minimum width, the slot is clamped to the screen width.

## Finding Bundle IDs and Titles

Focus a window and press:

```text
Action + ,
```

The manager shows the window title, app name, and bundle ID.

## Notes

- This manager deliberately avoids automatic app launching.
- It also avoids automatic placement on app launch because app-specific restore timing is inconsistent.

## License

MIT
