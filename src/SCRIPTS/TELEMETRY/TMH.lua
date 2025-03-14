--[[
  Battery Percentage Telemetry Script for EdgeTX
  Version: 1.0.1
  Author: Jakub Buzuk
  License: MIT
]]

local FILE_PATH = "SCRIPTS/TELEMETRY/TMH/"

-- Load modules
local config = loadScript(FILE_PATH .. "config.lua")()
local utils = loadScript(FILE_PATH .. "utils.lua")()
local battery = loadScript(FILE_PATH .. "battery.lua")()
local link = loadScript(FILE_PATH .. "link.lua")()
local ui = loadScript(FILE_PATH .. "ui.lua")()


local function init()
  utils.initConstants()
  battery.init(config, utils)
  link.init(config, utils)
  ui.init(config, utils, battery, link)
end

local function background()
  battery.update()
  link.update()
end

local function run(event)
  if event == EVT_ENTER_BREAK then
    battery.resetCellDetection()
  end

  ui.render(event)

  -- Return 1 to allow other scripts to process events
  -- This ensures system announcements are not blocked
  return 1
end


return {
  init = init,
  run = run,
  background = background,
}
