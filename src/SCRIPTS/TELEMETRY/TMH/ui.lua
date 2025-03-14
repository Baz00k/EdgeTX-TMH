--[[
  UI Module for Telemetry
]]

local ui = {}

-- Module dependencies
local config
local utils
local battery
local link

-- Initialize the module
function ui.init(configModule, utilsModule, batteryModule, linkModule)
    config = configModule
    utils = utilsModule
    battery = batteryModule
    link = linkModule
end

-- Draw a small battery icon
function ui.drawBatteryIcon(x, y, width, height, percentage, status)
    -- Calculate colors based on status
    local frameColor = utils.getColor("primary")
    local fillColor = utils.getColor("active")

    if status == "warning" then
        fillColor = utils.getColor("warning")
    elseif status == "critical" then
        fillColor = utils.getColor("error")
    end

    -- Draw battery outline
    lcd.drawRectangle(x, y, width, height, frameColor)

    -- Draw battery terminal
    local termWidth = math.max(2, math.floor(width * 0.1))
    local termHeight = math.max(4, math.floor(height * 0.4))
    lcd.drawFilledRectangle(x + width, y + (height - termHeight) / 2, termWidth, termHeight, frameColor)

    local displayPercentage = utils.applyDisplayMargin(percentage, config.DISPLAY_MARGIN)

    -- Draw fill level
    local fillWidth = math.max(1, math.floor(((width - 2) * displayPercentage) / 100))
    lcd.drawFilledRectangle(x + 1, y + 1, fillWidth, height - 2, fillColor)
end

-- Draw a small signal strength icon
function ui.drawSignalIcon(x, y, width, height, quality, status)
    -- Calculate colors based on status
    local frameColor = utils.getColor("primary")
    local fillColor = utils.getColor("active")

    if status == "warning" then
        fillColor = utils.getColor("warning")
    elseif status == "critical" then
        fillColor = utils.getColor("error")
    end

    local displayQuality = utils.applyDisplayMargin(quality, config.DISPLAY_MARGIN)

    -- Draw signal strength bars (3 bars)
    local barCount = 3
    local barWidth = math.floor(width / barCount)
    local barSpacing = 1
    local maxBarHeight = height

    for i = 1, barCount do
        local barHeight = math.floor(maxBarHeight * i / barCount)
        local barX = x + (i - 1) * barWidth
        local barY = y + (maxBarHeight - barHeight)

        -- Determine if this bar should be filled based on signal quality
        local barFilled = (i / barCount) * 100 <= displayQuality

        if barFilled then
            lcd.drawFilledRectangle(barX, barY, barWidth - barSpacing, barHeight, fillColor)
        else
            lcd.drawLine(barX, barY + barHeight - 1, barX + barWidth - barSpacing - 1, barY + barHeight - 1, frameColor,
                utils.SOLID)
        end
    end
end

-- Draw the battery section
function ui.drawBatterySection(x, y, width, height, voltage, percentage, status)
    -- Draw section label and icon on the same line
    local iconWidth = math.min(16, width / 6)
    local iconHeight = math.min(8, height / 10)

    lcd.drawText(x + 5, y + 5, "BATT", utils.SMLSIZE, utils.LEFT)
    ui.drawBatteryIcon(x + width - iconWidth - 5, y + 5, iconWidth, iconHeight, percentage, status)

    -- Draw percentage with large font
    local fontSize = utils.MIDSIZE
    if utils.screenWidth >= 212 and utils.screenHeight >= 128 then
        fontSize = utils.XXLSIZE
    end

    local percentX = x + width / 2
    local percentY = y + 20
    lcd.drawText(percentX, percentY, percentage .. "%", fontSize + utils.CENTER)

    -- Draw voltage info
    local infoY = percentY + (fontSize == utils.XXLSIZE and 30 or 20)
    lcd.drawText(percentX, infoY, string.format("%.1fV/%dS", voltage, battery.getCellCount()),
        utils.SMLSIZE + utils.CENTER)

    -- Show cell detection status if in progress
    if battery.isCellDetectionInProgress() then
        local detectionY = infoY + 12
        local detectionText = string.format("Detecting: %d/%d",
            battery.getCellDetectionSamplesCount(),
            battery.getCellDetectSamplesNeeded())
        lcd.drawText(percentX, detectionY, detectionText, utils.SMLSIZE + utils.CENTER)
    end
end

-- Draw the link quality section
function ui.drawLinkSection(x, y, width, height, quality, status)
    -- Draw section label and icon on the same line
    local iconWidth = math.min(16, width / 6)
    local iconHeight = math.min(8, height / 10)

    lcd.drawText(x + 5, y + 5, "LINK", utils.SMLSIZE, utils.LEFT)
    ui.drawSignalIcon(x + width - iconWidth - 5, y + 5, iconWidth, iconHeight, quality, status)

    -- Draw percentage with large font
    local fontSize = utils.MIDSIZE
    if utils.screenWidth >= 212 and utils.screenHeight >= 128 then
        fontSize = utils.XXLSIZE
    end

    local percentX = x + width / 2
    local percentY = y + 20
    lcd.drawText(percentX, percentY, quality .. "%", fontSize + utils.CENTER)

    -- Draw status text
    local statusY = percentY + (fontSize == utils.XXLSIZE and 30 or 20)
    local statusText = "OK"
    if status == "unknown" then
        statusText = "UNKOWN"
    elseif status == "warning" then
        statusText = "WARN"
    elseif status == "critical" then
        statusText = "CRIT"
    end
    lcd.drawText(percentX, statusY, statusText, utils.SMLSIZE + utils.CENTER)
end

-- Main render function
function ui.render(event)
    lcd.clear()

    -- Calculate vertical split
    local halfWidth = math.floor(utils.screenWidth / 2)
    local dividerX = halfWidth
    local contentY = 0                       -- Start from the top to maximize space
    local contentHeight = utils.screenHeight -- Use full screen height

    -- Draw vertical divider
    lcd.drawLine(dividerX, contentY, dividerX, utils.screenHeight, utils.WHITE, utils.SOLID)

    -- Battery section (left side)
    if not battery.hasSensor() then
        -- No sensor found, show a concise error message in the battery section
        local sectionCenterX = halfWidth / 2
        local sectionCenterY = contentHeight / 2

        -- Draw section label
        lcd.drawText(5, 5, "BATT", utils.SMLSIZE, utils.LEFT)

        -- Draw error message centered in the section
        lcd.drawText(sectionCenterX, sectionCenterY - 8, "No data", utils.SMLSIZE + utils.CENTER)
        lcd.drawText(sectionCenterX, sectionCenterY + 8, "Sensor: " .. battery.getSensorName(),
            utils.SMLSIZE + utils.CENTER)
    else
        local voltage = battery.getVoltage()
        if voltage <= 0 then
            -- No valid reading yet, show message in the battery section
            local sectionCenterX = halfWidth / 2
            local sectionCenterY = contentHeight / 2

            -- Draw section label
            lcd.drawText(5, 5, "BATT", utils.SMLSIZE, utils.LEFT)

            -- Draw waiting message centered in the section
            lcd.drawText(sectionCenterX, sectionCenterY - 8, "Waiting for", utils.SMLSIZE + utils.CENTER)
            lcd.drawText(sectionCenterX, sectionCenterY + 8, "data...", utils.SMLSIZE + utils.CENTER)
        else
            -- Calculate battery percentage and status
            local percentage = battery.getPercentage()
            local status = battery.getStatus(voltage)

            -- Draw the battery section
            ui.drawBatterySection(0, contentY, halfWidth, contentHeight, voltage, percentage, status)
        end
    end

    -- Link quality section (right side)
    if not link.hasSensor() then
        -- No sensor found, show a concise error message in the link section
        local sectionCenterX = halfWidth + halfWidth / 2
        local sectionCenterY = contentHeight / 2

        -- Draw section label
        lcd.drawText(halfWidth + 5, 5, "LINK", utils.SMLSIZE, utils.LEFT)

        -- Draw error message centered in the section
        lcd.drawText(sectionCenterX, sectionCenterY - 8, "No data", utils.SMLSIZE + utils.CENTER)
        lcd.drawText(sectionCenterX, sectionCenterY + 8, "Sensor: " .. link.getSensorName(), utils.SMLSIZE + utils
            .CENTER)
    else
        local quality = link.getLinkQuality()
        if quality < 0 then
            -- No valid reading yet, show message in the link section
            local sectionCenterX = halfWidth + halfWidth / 2
            local sectionCenterY = contentHeight / 2

            -- Draw section label
            lcd.drawText(halfWidth + 5, 5, "LINK", utils.SMLSIZE, utils.LEFT)

            -- Draw waiting message centered in the section
            lcd.drawText(sectionCenterX, sectionCenterY - 8, "Waiting for", utils.SMLSIZE + utils.CENTER)
            lcd.drawText(sectionCenterX, sectionCenterY + 8, "data...", utils.SMLSIZE + utils.CENTER)
        else
            -- Calculate link status
            local status = link.getStatus(quality)

            -- Draw the link quality section
            ui.drawLinkSection(halfWidth, contentY, halfWidth, contentHeight, quality, status)
        end
    end

    -- Show reset instructions at the bottom has been removed to use full screen
end

return ui
