hs = hs

hs.loadSpoon("SpoonInstall")

Install = spoon.SpoonInstall

Install:andUse("ReloadConfiguration", {
  start = true,
})

local excludedApps = {
  ["System Settings"] = true,
  ["Calculator"] = true,
}

local filter = hs.window.filter.new()

filter:subscribe(hs.window.filter.windowCreated, function(window, appName)
  if not window then
    return
  end

  -- Apps que queremos dejar a su aire
  if excludedApps[appName] then
    return
  end

  -- Evitar diálogos, popups, paneles, etc.
  if not window:isStandard() then
    return
  end

  -- Algunas apps crean la ventana y terminan de posicionarla
  -- unos milisegundos después.
  hs.timer.doAfter(0.15, function()
    if window:isStandard() and window:isVisible() then
      window:maximize()
    end
  end)
end)

filter:subscribe(hs.window.filter.windowFocused, function(window, appName)
  if not window then
    return
  end

  if excludedApps[appName] then
    return
  end

  if not window:isStandard() then
    return
  end

  -- Solo corregir ventanas claramente pequeñas.
  local screen = window:screen()
  local frame = window:frame()
  local max = screen:frame()

  local widthRatio = frame.w / max.w
  local heightRatio = frame.h / max.h

  if widthRatio < 0.90 or heightRatio < 0.90 then
    window:maximize()
  end
end)

local trustedNetworks = {
  ["Metech"] = true,
}

local function updateWarp()
  local ssid = hs.wifi.currentNetwork()

  if not ssid then
    return
  end

  if trustedNetworks[ssid] then
    hs.execute("/opt/homebrew/bin/warp-cli disconnect", true)
    hs.notify
      .new({
        title = "WARP",
        informativeText = "Red de confianza: WARP desactivado",
      })
      :send()
  else
    hs.execute("/opt/homebrew/bin/warp-cli connect", true)
    hs.notify
      .new({
        title = "WARP",
        informativeText = "Red externa: WARP activado",
      })
      :send()
  end
end

hs.wifi.watcher.new(updateWarp):start()
