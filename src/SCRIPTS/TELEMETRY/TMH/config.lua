--[[
  Configuration Module for Battery Telemetry
]]

local config = {
  -- Battery settings
  AUTO_CELL_DETECT = true,  -- Automatically detect cell count
  CELL_COUNT = 3,           -- Number of cells in your battery, will be detected automatically if AUTO_CELL_DETECT is true
  FULL_CELL_VOLTAGE = 4.2,  -- Voltage of a fully charged cell
  WARN_CELL_VOLTAGE = 3.7,  -- Warning threshold per cell
  CRIT_CELL_VOLTAGE = 3.35, -- Critical threshold per cell

  -- Cell detection settings
  CELL_DETECT_SAMPLES = 5,     -- Number of samples to collect before finalizing cell count
  MIN_CELL_VOLTAGE = 3.3,      -- Minimum expected voltage per cell (for detection)
  MAX_CELL_VOLTAGE = 4.25,     -- Maximum expected voltage per cell (for detection)
  CELL_DETECTION_TIMEOUT = 10, -- Timeout in seconds

  -- Link quality settings
  WARN_LINK_QUALITY = 70, -- Warning threshold for link quality (%)
  CRIT_LINK_QUALITY = 50, -- Critical threshold for link quality (%)

  -- Display settings
  LARGE_FONT = true,   -- Use large font for percentage display
  ENABLE_VOICE = true, -- Enable voice warnings
  DISPLAY_MARGIN = 5,  -- Values within this margin of max will display as full (e.g., 95% shows as 100%)

  -- Announcement settings
  PERCENTAGE_STEP = 10,       -- Announce every X% change
  MIN_ANNOUNCE_INTERVAL = 10, -- Minimum seconds between announcements

  -- Sensor settings
  BATTERY_SENSOR_NAMES = { "RxBt", "VBAT", "Batt", "Voltage", "RxBatt" }, -- Possible names for the battery voltage sensor
  LINK_SENSOR_NAMES = { "RQly", "RxQly", "LQly" },                        -- Possible names for the link quality sensor

  -- LiPo discharge curve lookup table [voltage, percentage]
  -- This represents a typical 1S LiPo discharge curve
  LIPO_CURVE = {
    { 4.20, 100 },
    { 4.15, 95 },
    { 4.11, 90 },
    { 4.08, 85 },
    { 4.02, 80 },
    { 3.98, 75 },
    { 3.95, 70 },
    { 3.91, 65 },
    { 3.87, 60 },
    { 3.85, 55 },
    { 3.84, 50 },
    { 3.82, 45 },
    { 3.80, 40 },
    { 3.79, 35 },
    { 3.77, 30 },
    { 3.75, 25 },
    { 3.73, 20 },
    { 3.70, 15 },
    { 3.60, 10 },
    { 3.50, 5 },
    { 3.40, 1 },
    { 3.30, 0 },
  }
}

return config
