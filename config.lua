return {
  slots = {
    order = { "left", "center", "right" },
    definitions = {
      center = {
        widthRatio = 0.65,
        minWidth = 1800,
        maxWidth = 1920,
        heightRatio = 1.0,
        margin = 0,
      },
      left = {
        widthRatio = 0.4,
        minWidth = 1200,
        maxWidth = 1400,
        heightRatio = 1.0,
        margin = 0,
      },
      right = {
        widthRatio = 0.4,
        minWidth = 1200,
        maxWidth = 1400,
        heightRatio = 1.0,
        margin = 0,
      },
    },
  },

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
  },

  behavior = {
    placeOnReload = true,
    launchApps = false,
    notificationSeconds = 1,
  },

  -- `apps` is a complete list. Add, remove, or reorder entries here.
  apps = {
    {
      key = "e",
      bundleID = "com.microsoft.VSCode",
      defaultSlot = "center",
    },
    {
      key = "b",
      bundleID = "com.google.Chrome",
      defaultSlot = "right",
    },
    {
      key = "s",
      bundleID = "com.tinyspeck.slackmacgap",
      defaultSlot = "left",
    },
  },
}
