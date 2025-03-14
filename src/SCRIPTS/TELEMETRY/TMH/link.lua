--[[
  Link Quality Module for Telemetry
]]

local link = {}

-- Module dependencies
local config
local utils

-- Runtime variables
local lastLinkQuality = 0
local lastStatus = "unknown"
local lastAnnouncementTime = 0
local sensorId = nil
local sensorName = nil

-- Initialize the module
function link.init(configModule, utilsModule)
    config = configModule
    utils = utilsModule

    -- Try to find the sensor during initialization
    sensorId, sensorName = utils.findSensor(config.LINK_SENSOR_NAMES)

    -- Initialize announcement variables
    lastStatus = "unknown"
    lastAnnouncementTime = 0
end

-- Get the link status (normal, warning, critical)
function link.getStatus(quality)
    if not quality or quality <= 0 then return "unknown" end

    if quality <= config.CRIT_LINK_QUALITY then
        return "critical"
    elseif quality <= config.WARN_LINK_QUALITY then
        return "warning"
    else
        return "normal"
    end
end

-- Play warning sounds if needed
function link.handleWarnings(status)
    if not config.ENABLE_VOICE then return end

    local currentTime = utils.getTimeSeconds()

    -- Don't announce too frequently
    if currentTime - lastAnnouncementTime < config.MIN_ANNOUNCE_INTERVAL then
        return
    end

    local shouldAnnounce = false
    local message = nil

    -- Check if status has changed to warning or critical (not for normal)
    if status ~= lastStatus and status ~= "unknown" and status ~= "normal" then
        shouldAnnounce = true
        lastStatus = status

        if status == "critical" then
            message = "critical"
        elseif status == "warning" then
            message = "warning"
        end
    else
        -- Update status without announcing if it's normal
        if status ~= lastStatus then
            lastStatus = status
        end
    end

    -- Announce if needed
    if shouldAnnounce then
        if message == "critical" then
            playFile("sigcrt.wav")
        elseif message == "warning" then
            playFile("siglow.wav")
        end

        lastAnnouncementTime = currentTime
    end
end

-- Update link data (called from background)
function link.update()
    if sensorId == nil then
        return
    end

    local quality = getValue(sensorId)

    -- Only process if we have a valid quality reading
    if quality and quality >= 0 then
        lastLinkQuality = quality
        local status = link.getStatus(quality)
        link.handleWarnings(status)
    end
end

-- Getters for UI module
function link.getLinkQuality()
    return lastLinkQuality
end

function link.hasSensor()
    return sensorId ~= nil
end

function link.getSensorName()
    return sensorName
end

function link.getSensorId()
    return sensorId
end

return link
