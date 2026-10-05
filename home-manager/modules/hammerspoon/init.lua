-- Select ABC (半角英数) whenever focus moves to another window.
-- azooKey's own windows are ignored so its candidate UI does not undo Japanese input.

local abcSourceID = "com.apple.keylayout.ABC"

local ignoredBundleIDs = {
  ["org.hammerspoon.Hammerspoon"] = true,
  ["dev.ensan.inputmethod.azooKeyMac"] = true,
}

local lastWindowID = nil
local switchTimer = nil

local function forceAbc(window)
  if window then
    local app = window:application()
    local bundleID = app and app:bundleID()
    if bundleID and ignoredBundleIDs[bundleID] then
      return
    end

    local windowID = window:id()
    if windowID ~= nil and windowID == lastWindowID then
      return
    end
    lastWindowID = windowID
  end

  if switchTimer then
    switchTimer:stop()
  end
  -- Delay past the focus change so macOS does not restore the previous source.
  switchTimer = hs.timer.doAfter(0.1, function()
    if hs.keycodes.currentSourceID() ~= abcSourceID then
      local ok = hs.keycodes.currentSourceID(abcSourceID)
      if not ok then
        hs.printf("failed to select %s (current: %s)", abcSourceID, hs.keycodes.currentSourceID() or "?")
      end
    end
  end)
end

hs.window.filter.default:subscribe(hs.window.filter.windowFocused, forceAbc)

appWatcher = hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.activated then
    forceAbc(app:focusedWindow())
  end
end):start()

hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(false)
hs.accessibilityState(true)
