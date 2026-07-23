local slotover = {}

local defaultConfig = {
  slots = {
    order = { "left", "center", "right" },
    definitions = {
      left = {
        anchor = "left",
        widthRatio = 0.4,
        minWidth = 1200,
        maxWidth = 1400,
        heightRatio = 1.0,
        margin = 0,
      },
      center = {
        anchor = "center",
        widthRatio = 0.65,
        minWidth = 1800,
        maxWidth = 1920,
        heightRatio = 1.0,
        margin = 0,
      },
      right = {
        anchor = "right",
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

  apps = {},
}

local config = nil
local windowsBeforeMaximize = {}
local launchIndexes = {}

local function isArray(value)
  if type(value) ~= "table" then
    return false
  end

  local count = 0
  for key, _ in pairs(value) do
    if type(key) ~= "number" then
      return false
    end
    if key > count then
      count = key
    end
  end

  for index = 1, count do
    if value[index] == nil then
      return false
    end
  end

  return true
end

local function copy(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for key, item in pairs(value) do
    result[key] = copy(item)
  end
  return result
end

local function deepMerge(base, override)
  local result = copy(base)

  for key, value in pairs(override or {}) do
    if key ~= "apps" then
      if type(value) == "table" and type(result[key]) == "table" and not isArray(value) then
        result[key] = deepMerge(result[key], value)
      else
        result[key] = copy(value)
      end
    end
  end

  return result
end

local function buildConfig(userConfig)
  local merged = deepMerge(defaultConfig, userConfig or {})

  if userConfig and userConfig.apps then
    merged.apps = copy(userConfig.apps)
  else
    merged.apps = copy(defaultConfig.apps)
  end

  return merged
end

local function notify(message)
  hs.alert.show(message, config.behavior.notificationSeconds or 1)
end

local function screenFrame(screen)
  return screen:frame()
end

local function clampWidth(width, slot, frame)
  local result = width

  if slot.minWidth then
    result = math.max(result, slot.minWidth)
  end
  if slot.maxWidth then
    result = math.min(result, slot.maxWidth)
  end

  return math.min(result, frame.w)
end

local function slotFrame(screen, slotName)
  local frame = screenFrame(screen)
  local slot = config.slots.definitions[slotName]
  local margin = slot.margin or 0

  local width = clampWidth(frame.w * (slot.widthRatio or 1), slot, frame)
  local height = math.min(frame.h * (slot.heightRatio or 1), frame.h)
  local x = frame.x
  local y = frame.y + ((frame.h - height) / 2)

  if slot.anchor == "right" then
    x = frame.x + frame.w - width
  elseif slot.anchor == "center" then
    x = frame.x + ((frame.w - width) / 2)
  end

  return {
    x = x + margin,
    y = y + margin,
    w = math.max(1, width - (margin * 2)),
    h = math.max(1, height - (margin * 2)),
  }
end

local function usableWindow(window)
  if not window then
    return false
  end
  if not window:isStandard() then
    return false
  end
  if window:isMinimized() or window:isFullScreen() then
    return false
  end
  return window:screen() ~= nil
end

local function windowTitle(window)
  return window:title() or ""
end

local function appBundleID(window)
  local app = window:application()
  return app and app:bundleID() or ""
end

local function matchesProfile(window, profile)
  if not usableWindow(window) then
    return false
  end

  if profile.bundleID and appBundleID(window) ~= profile.bundleID then
    return false
  end

  if profile.titleSubstring and not string.find(windowTitle(window), profile.titleSubstring, 1, true) then
    return false
  end

  return true
end

local function slotIndex(slotName)
  for index, name in ipairs(config.slots.order) do
    if name == slotName then
      return index
    end
  end
  return nil
end

local function nearestSlotName(window)
  local screen = window:screen()
  if not screen then
    return nil
  end

  local frame = window:frame()
  local centerX = frame.x + (frame.w / 2)
  local nearestName = nil
  local nearestDistance = math.huge

  for _, name in ipairs(config.slots.order) do
    local candidate = slotFrame(screen, name)
    local candidateCenterX = candidate.x + (candidate.w / 2)
    local distance = math.abs(centerX - candidateCenterX)

    if distance < nearestDistance then
      nearestName = name
      nearestDistance = distance
    end
  end

  return nearestName
end

local function placeWindow(window, slotName)
  if not usableWindow(window) or not slotName then
    return
  end

  window:setFrame(slotFrame(window:screen(), slotName), 0)
end

local function allWindowsFrontToBack()
  local result = {}

  for _, window in ipairs(hs.window.orderedWindows()) do
    if usableWindow(window) then
      table.insert(result, window)
    end
  end

  return result
end

local function allWindowsSorted()
  local result = allWindowsFrontToBack()

  table.sort(result, function(a, b)
    local appA = appBundleID(a)
    local appB = appBundleID(b)
    if appA ~= appB then
      return appA < appB
    end

    local titleA = windowTitle(a)
    local titleB = windowTitle(b)
    if titleA ~= titleB then
      return titleA < titleB
    end

    return a:id() < b:id()
  end)

  return result
end

local function windowsForProfile(profile)
  local result = {}

  for _, window in ipairs(allWindowsSorted()) do
    if matchesProfile(window, profile) then
      table.insert(result, window)
    end
  end

  return result
end

local function windowsForKey(key)
  local result = {}

  for profileIndex, profile in ipairs(config.apps) do
    if profile.key == key then
      local windows = windowsForProfile(profile)
      for _, window in ipairs(windows) do
        table.insert(result, {
          profileIndex = profileIndex,
          window = window,
        })
      end
    end
  end

  return result
end

local function currentCandidateIndex(candidates)
  local focused = hs.window.focusedWindow()
  if not focused then
    return nil
  end

  local focusedID = focused:id()
  for index, candidate in ipairs(candidates) do
    if candidate.window:id() == focusedID then
      return index
    end
  end

  return nil
end

local function focusLaunchKey(key)
  local candidates = windowsForKey(key)

  if #candidates == 0 then
    notify("No matching windows")
    return
  end

  local lastIndex = launchIndexes[key] or 0
  local currentIndex = currentCandidateIndex(candidates)
  local nextIndex = currentIndex and (currentIndex + 1) or (lastIndex + 1)

  if nextIndex > #candidates then
    nextIndex = 1
  end

  launchIndexes[key] = nextIndex
  candidates[nextIndex].window:focus()
end

local function windowsInSlot(screen, slotName, ordered)
  local result = {}
  local source = ordered and allWindowsFrontToBack() or allWindowsSorted()

  for _, window in ipairs(source) do
    if window:screen() == screen and nearestSlotName(window) == slotName then
      table.insert(result, window)
    end
  end

  return result
end

local function focusAdjacentSlot(direction)
  local focused = hs.window.focusedWindow()
  if not usableWindow(focused) then
    return
  end

  local currentIndex = slotIndex(nearestSlotName(focused))
  if not currentIndex then
    return
  end

  local nextIndex = currentIndex + direction
  if nextIndex < 1 or nextIndex > #config.slots.order then
    return
  end

  local windows = windowsInSlot(focused:screen(), config.slots.order[nextIndex], true)
  if #windows > 0 then
    windows[1]:focus()
  end
end

local function focusWithinSlot(direction)
  local focused = hs.window.focusedWindow()
  if not usableWindow(focused) then
    return
  end

  local slotName = nearestSlotName(focused)
  local windows = windowsInSlot(focused:screen(), slotName, false)

  if #windows < 2 then
    return
  end

  local focusedIndex = nil
  for index, window in ipairs(windows) do
    if window:id() == focused:id() then
      focusedIndex = index
      break
    end
  end

  if not focusedIndex then
    return
  end

  local nextIndex = focusedIndex + direction
  if nextIndex < 1 then
    nextIndex = #windows
  elseif nextIndex > #windows then
    nextIndex = 1
  end

  windows[nextIndex]:focus()
end

local function moveAdjacentSlot(direction)
  local focused = hs.window.focusedWindow()
  if not usableWindow(focused) then
    return
  end

  local currentIndex = slotIndex(nearestSlotName(focused))
  if not currentIndex then
    return
  end

  local nextIndex = currentIndex + direction
  if nextIndex < 1 or nextIndex > #config.slots.order then
    return
  end

  placeWindow(focused, config.slots.order[nextIndex])
end

local function toggleMaximize()
  local focused = hs.window.focusedWindow()
  if not usableWindow(focused) then
    return
  end

  local id = focused:id()
  if windowsBeforeMaximize[id] then
    focused:setFrame(windowsBeforeMaximize[id], 0)
    windowsBeforeMaximize[id] = nil
  else
    windowsBeforeMaximize[id] = focused:frame()
    focused:setFrame(focused:screen():frame(), 0)
  end
end

local function inspectWindow()
  local focused = hs.window.focusedWindow()
  if not focused then
    notify("No focused window")
    return
  end

  local app = focused:application()
  local appName = app and app:name() or "Unknown app"
  local bundleID = app and app:bundleID() or "Unknown bundle ID"

  hs.alert.show(
    "Title: " .. windowTitle(focused) .. "\n"
      .. "App: " .. appName .. "\n"
      .. "Bundle ID: " .. bundleID,
    4
  )
end

local function placeConfiguredWindows()
  for _, profile in ipairs(config.apps) do
    if profile.defaultSlot then
      for _, window in ipairs(windowsForProfile(profile)) do
        placeWindow(window, profile.defaultSlot)
      end
    end
  end
end

local function bind(modifiers, key, fn)
  if key then
    hs.hotkey.bind(modifiers, key, fn)
  end
end

local function bindShortcuts()
  local shortcuts = config.shortcuts

  bind(shortcuts.focusRelative.modifier, shortcuts.focusRelative.up, function()
    focusWithinSlot(-1)
  end)
  bind(shortcuts.focusRelative.modifier, shortcuts.focusRelative.down, function()
    focusWithinSlot(1)
  end)
  bind(shortcuts.focusRelative.modifier, shortcuts.focusRelative.left, function()
    focusAdjacentSlot(-1)
  end)
  bind(shortcuts.focusRelative.modifier, shortcuts.focusRelative.right, function()
    focusAdjacentSlot(1)
  end)

  bind(shortcuts.moveRelative.modifier, shortcuts.moveRelative.left, function()
    moveAdjacentSlot(-1)
  end)
  bind(shortcuts.moveRelative.modifier, shortcuts.moveRelative.right, function()
    moveAdjacentSlot(1)
  end)

  bind(shortcuts.action.modifier, shortcuts.action.toggleMaximize, toggleMaximize)
  bind(shortcuts.action.modifier, shortcuts.action.inspectWindow, inspectWindow)
  bind(shortcuts.action.modifier, shortcuts.action.reloadConfig, hs.reload)

  local boundLaunchKeys = {}
  for _, profile in ipairs(config.apps) do
    if profile.key and not boundLaunchKeys[profile.key] then
      boundLaunchKeys[profile.key] = true
      bind(shortcuts.focusApp.modifier, profile.key, function()
        focusLaunchKey(profile.key)
      end)
    end
  end
end

function slotover.start(userConfig)
  config = buildConfig(userConfig or {})
  bindShortcuts()

  if config.behavior.placeOnReload then
    hs.timer.doAfter(0.1, placeConfiguredWindows)
  end

  notify("SlotOver loaded")
end

return slotover
