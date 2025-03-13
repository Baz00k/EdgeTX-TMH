--[[
  Battery Module for Battery Telemetry
]]

local battery = {}

-- Module dependencies
local config
local utils

-- Runtime variables
local lastVoltage = 0
local lastPercentage = 0
local lastAnnouncedPercentage = -1
local lastStatus = "unknown"
local lastAnnouncementTime = 0
local cellCount = 0
local hasSensor = false

-- Cell count detection variables
local cellDetectionSamples = {}
local cellDetectionInProgress = false
local cellDetectionComplete = false
local lastCellDetectionTime = 0
local cellDetectionStartTime = 0

-- Initialize the module
function battery.init(configModule, utilsModule)
    config = configModule
    utils = utilsModule

    -- Set initial cell count from config
    cellCount = config.CELL_COUNT

    -- Initialize cell detection
    battery.resetCellDetection()

    -- Initialize announcement variables
    lastAnnouncedPercentage = -1
    lastStatus = "unknown"
    lastAnnouncementTime = 0

    -- Try to find the sensor during initialization
    battery.findSensor()
end

-- Find the telemetry sensor by name
function battery.findSensor()
    if config.BATTERY_SENSOR_ID then return config.BATTERY_SENSOR_ID end

    -- Try to find the sensor by name
    local sensor = getValue(config.BATTERY_SENSOR_NAME)
    if sensor and sensor ~= 0 then
        hasSensor = true
        return config.BATTERY_SENSOR_NAME
    end

    -- Try alternative naming schemes
    local alternatives = { "VBAT", "Batt", "Voltage", "RxBatt" }
    for _, name in ipairs(alternatives) do
        sensor = getValue(name)
        if sensor and sensor ~= 0 then
            config.BATTERY_SENSOR_NAME = name
            hasSensor = true
            return name
        end
    end

    return nil
end

-- Detect cell count based on voltage readings
function battery.detectCellCount(voltage)
    if not voltage or voltage <= 0 then
        return cellCount
    end

    -- If detection is complete or not in progress, return current cell count
    if cellDetectionComplete and not cellDetectionInProgress then
        return cellCount
    end

    -- Check for timeout
    local currentTime = utils.getTimeSeconds()
    if currentTime - cellDetectionStartTime > config.CELL_DETECTION_TIMEOUT then
        -- If we've been trying to detect for too long, finalize with what we have
        cellDetectionInProgress = false
        cellDetectionComplete = true
        return cellCount
    end

    -- Only sample every 1 second to avoid rapid fluctuations
    if currentTime - lastCellDetectionTime < 1 then
        return cellCount
    end
    lastCellDetectionTime = currentTime

    -- Add the current voltage to our samples
    utils.safeTableInsert(cellDetectionSamples, voltage)

    -- Keep only the most recent samples
    if #cellDetectionSamples > config.CELL_DETECT_SAMPLES then
        utils.safeTableRemove(cellDetectionSamples, 1)
    end

    -- Wait until we have enough samples
    if #cellDetectionSamples < config.CELL_DETECT_SAMPLES then
        return cellCount
    end

    -- Calculate the average voltage from our samples
    local avgVoltage = 0
    for _, v in ipairs(cellDetectionSamples) do
        avgVoltage = avgVoltage + v
    end
    avgVoltage = avgVoltage / #cellDetectionSamples

    -- Try different cell counts and find the one that gives the most reasonable cell voltage
    local bestCellCount = config.CELL_COUNT
    local bestDeviation = 999

    for testCount = 1, 12 do
        local cellVoltage = avgVoltage / testCount

        -- Check if this cell voltage is within the expected range
        if cellVoltage >= config.MIN_CELL_VOLTAGE and cellVoltage <= config.MAX_CELL_VOLTAGE then
            -- Calculate how close this cell voltage is to a typical LiPo cell voltage
            -- Find the closest voltage in our discharge curve
            local closestDeviation = 999
            for _, point in ipairs(config.LIPO_CURVE) do
                local deviation = math.abs(cellVoltage - point[1])
                if deviation < closestDeviation then
                    closestDeviation = deviation
                end
            end

            -- If this cell count gives a more typical cell voltage, use it
            if closestDeviation < bestDeviation then
                bestDeviation = closestDeviation
                bestCellCount = testCount
            end
        end
    end

    -- If we've collected enough samples and found a reasonable cell count, finalize it
    if #cellDetectionSamples >= config.CELL_DETECT_SAMPLES and bestDeviation < 0.5 then
        cellCount = bestCellCount
        cellDetectionComplete = true
        cellDetectionInProgress = false
    end

    return cellCount
end

-- Start the cell detection process
function battery.startCellDetection()
    cellDetectionSamples = {}
    cellDetectionComplete = false
    cellDetectionInProgress = true
    cellDetectionStartTime = utils.getTimeSeconds()
    cellCount = config.CELL_COUNT -- Reset to default until detection completes
end

-- Reset cell detection (can be triggered by user)
function battery.resetCellDetection()
    cellDetectionSamples = {}
    cellDetectionComplete = false
    cellDetectionInProgress = false
    cellCount = config.CELL_COUNT
    lastAnnouncedPercentage = -1 -- Reset announced percentage on cell count reset
    lastStatus = "unknown"       -- Reset status on cell count reset

    -- If auto-detect is enabled, start the detection process
    if config.AUTO_CELL_DETECT then
        battery.startCellDetection()
    end
end

-- Calculate battery percentage from voltage using non-linear discharge curve
function battery.calculatePercentage(voltage)
    if not voltage or voltage == 0 then return 0 end

    -- If cell detection is in progress and auto-detect is enabled, update the cell count
    if config.AUTO_CELL_DETECT and cellDetectionInProgress then
        battery.detectCellCount(voltage)
    end

    local cellVoltage = voltage / cellCount
    local percentage = 0

    -- Use the discharge curve lookup table to determine percentage
    if cellVoltage >= config.LIPO_CURVE[1][1] then
        -- Voltage is at or above the maximum in our curve
        percentage = 100
    elseif cellVoltage <= config.LIPO_CURVE[#config.LIPO_CURVE][1] then
        -- Voltage is at or below the minimum in our curve
        percentage = 0
    else
        -- Find the two points in the curve to interpolate between
        for i = 1, #config.LIPO_CURVE - 1 do
            if cellVoltage <= config.LIPO_CURVE[i][1] and cellVoltage > config.LIPO_CURVE[i + 1][1] then
                -- Interpolate between these two points
                percentage = utils.lerp(
                    cellVoltage,
                    config.LIPO_CURVE[i][1], config.LIPO_CURVE[i][2],
                    config.LIPO_CURVE[i + 1][1], config.LIPO_CURVE[i + 1][2]
                )
                break
            end
        end
    end

    -- Round to integer
    percentage = math.floor(percentage + 0.5)

    -- Smooth the percentage changes
    if lastPercentage > 0 then
        -- Apply slight smoothing to avoid jumps
        percentage = math.floor(0.9 * lastPercentage + 0.1 * percentage)
    end

    lastPercentage = percentage
    return percentage
end

-- Get the battery status (normal, warning, critical)
function battery.getStatus(voltage)
    if not voltage or voltage == 0 then return "unknown" end

    local cellVoltage = voltage / cellCount

    if cellVoltage <= config.CRIT_CELL_VOLTAGE then
        return "critical"
    elseif cellVoltage <= config.WARN_CELL_VOLTAGE then
        return "warning"
    else
        return "normal"
    end
end

-- Play warning sounds if needed
function battery.handleWarnings(status, percentage)
    if not config.ENABLE_VOICE then return end

    local currentTime = utils.getTimeSeconds()

    -- Don't announce too frequently
    if currentTime - lastAnnouncementTime < config.MIN_ANNOUNCE_INTERVAL then
        return
    end

    local shouldAnnounce = false
    local message = nil

    -- Check if status has changed
    if status ~= lastStatus and status ~= "unknown" then
        shouldAnnounce = true
        lastStatus = status

        if status == "critical" then
            message = "critical"
        elseif status == "warning" then
            message = "warning"
        end
    end

    -- Check if percentage has changed significantly
    local percentageStep = config.PERCENTAGE_STEP
    local currentPercentageStep = math.floor(percentage / percentageStep) * percentageStep
    local lastPercentageStep = math.floor(lastAnnouncedPercentage / percentageStep) * percentageStep

    if currentPercentageStep ~= lastPercentageStep or lastAnnouncedPercentage == -1 then
        shouldAnnounce = true
        lastAnnouncedPercentage = percentage
        message = "percentage"
    end

    -- Announce if needed
    if shouldAnnounce then
        if message == "critical" then
            playFile("SCRIPTS/INAV/batcrt.wav")
        elseif message == "warning" then
            playFile("SCRIPTS/INAV/batlow.wav")
        else
            playFile("SCRIPTS/INAV/battry.wav")
        end

        playNumber(percentage, 0)
        playFile("SYSTEM/percent0.wav")

        lastAnnouncementTime = currentTime
    end
end

-- Update battery data (called from background)
function battery.update()
    local sensorName = battery.findSensor()

    if not sensorName then
        -- If we don't have a sensor, we can't do much in the background
        return
    end

    -- Get voltage from telemetry
    local voltage = getValue(sensorName)

    -- Only process if we have a valid voltage reading
    if voltage and voltage > 0 then
        lastVoltage = voltage
        local percentage = battery.calculatePercentage(voltage)
        local status = battery.getStatus(voltage)
        battery.handleWarnings(status, percentage)
    end
end

-- Getters for UI module
function battery.getVoltage()
    return lastVoltage
end

function battery.getPercentage()
    return battery.calculatePercentage(lastVoltage)
end

function battery.getCellCount()
    return cellCount
end

function battery.hasSensor()
    return hasSensor
end

function battery.getSensorName()
    return config.BATTERY_SENSOR_NAME
end

function battery.isCellDetectionInProgress()
    return cellDetectionInProgress
end

function battery.getCellDetectionSamplesCount()
    return #cellDetectionSamples
end

function battery.getCellDetectSamplesNeeded()
    return config.CELL_DETECT_SAMPLES
end

return battery
