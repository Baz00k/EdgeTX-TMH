--[[
  Link Quality Module for Telemetry
]]

local link = {}

-- Module dependencies
local config
local utils

-- Runtime variables
local lastLinkQuality = 0
local hasSensor = false
local lastStatus = "unknown"
local lastAnnouncementTime = 0
local lastAnnouncedQuality = -1

-- Initialize the module
function link.init(configModule, utilsModule)
    config = configModule
    utils = utilsModule

    -- Initialize announcement variables
    lastAnnouncedQuality = -1
    lastStatus = "unknown"
    lastAnnouncementTime = 0

    -- Try to find the sensor during initialization
    link.findSensor()
end

-- Find the telemetry sensor by name and get its ID
function link.findSensor()
    if config.LINK_SENSOR_ID then return config.LINK_SENSOR_ID end

    -- Try to find the sensor by name and get its ID
    local fieldInfo = getFieldInfo(config.LINK_SENSOR_NAME)
    if fieldInfo then
        config.LINK_SENSOR_ID = fieldInfo.id
        hasSensor = true
        return config.LINK_SENSOR_ID
    end

    -- Try alternative naming schemes
    local alternatives = { "RQly", "RxQly", "LQly" }
    for _, name in ipairs(alternatives) do
        fieldInfo = getFieldInfo(name)
        if fieldInfo then
            config.LINK_SENSOR_NAME = name
            config.LINK_SENSOR_ID = fieldInfo.id
            hasSensor = true
            return config.LINK_SENSOR_ID
        end
    end

    return nil
end

-- Get the link status (normal, warning, critical)
function link.getStatus(quality)
    if not quality or quality < 0 then return "unknown" end

    if quality <= config.CRIT_LINK_QUALITY then
        return "critical"
    elseif quality <= config.WARN_LINK_QUALITY then
        return "warning"
    else
        return "normal"
    end
end

-- Play warning sounds if needed
function link.handleWarnings(status, quality)
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

    -- Check if quality has changed significantly and is in warning or critical state
    if status ~= "normal" and status ~= "unknown" then
        local qualityStep = config.PERCENTAGE_STEP
        local currentQualityStep = math.floor(quality / qualityStep) * qualityStep
        local lastQualityStep = math.floor(lastAnnouncedQuality / qualityStep) * qualityStep

        if currentQualityStep ~= lastQualityStep or lastAnnouncedQuality == -1 then
            shouldAnnounce = true
            lastAnnouncedQuality = quality
            message = "quality"
        end
    end

    -- Announce if needed
    if shouldAnnounce then
        if message == "critical" then
            playFile("lowsig.wav")
            playNumber(quality, 0)
            playFile("percent.wav")
        elseif message == "warning" then
            playFile("sigwarn.wav")
            playNumber(quality, 0)
            playFile("percent.wav")
        end

        lastAnnouncementTime = currentTime
    end
end

-- Update link data (called from background)
function link.update()
    local sensorId = link.findSensor()

    if not sensorId then
        -- If we don't have a sensor, we can't do much in the background
        return
    end

    -- Get link quality from telemetry using the sensor ID for better performance
    local quality = getValue(sensorId)

    -- Only process if we have a valid quality reading
    if quality and quality >= 0 then
        lastLinkQuality = quality
        local status = link.getStatus(quality)
        link.handleWarnings(status, quality)
    end
end

-- Getters for UI module
function link.getLinkQuality()
    return lastLinkQuality
end

function link.hasSensor()
    return hasSensor
end

function link.getSensorName()
    return config.LINK_SENSOR_NAME
end

function link.getSensorId()
    return config.LINK_SENSOR_ID
end

return link
