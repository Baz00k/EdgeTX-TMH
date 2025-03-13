--[[
  Utilities Module for Battery Telemetry
]]

local utils = {}

-- Screen dimensions
utils.screenWidth = 0
utils.screenHeight = 0

-- Initialize constants needed for the UI
function utils.initConstants()
    -- Define color constants if they don't exist
    utils.WHITE = WHITE or 0xFFFF
    utils.BLACK = BLACK or 0
    utils.YELLOW = YELLOW or 0xFFE0
    utils.GREEN = GREEN or 0x07E0
    utils.RED = RED or 0xF800

    -- Define font constants if they don't exist
    utils.SMLSIZE = SMLSIZE or 0
    utils.MIDSIZE = MIDSIZE or 0
    utils.XXLSIZE = XXLSIZE or 0
    utils.CENTER = CENTER or 0

    -- Define line pattern constants
    utils.SOLID = SOLID or 0
    utils.DOTTED = DOTTED or 1
    utils.DASHED = DASHED or 2

    -- Get screen dimensions
    utils.screenWidth = LCD_W or 128
    utils.screenHeight = LCD_H or 64
end

-- Theme-aware colors
function utils.getColor(name)
    -- EdgeTX color constants
    if name == "primary" then return utils.WHITE end
    if name == "focus" then return utils.WHITE end
    if name == "active" then return utils.GREEN end
    if name == "warning" then return utils.YELLOW end
    if name == "error" then return utils.RED end

    return utils.WHITE
end

-- Linear interpolation helper function
function utils.lerp(x, x1, y1, x2, y2)
    -- If x is outside the range, clamp to the nearest value
    if x <= x1 then return y1 end
    if x >= x2 then return y2 end

    -- Linear interpolation formula
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end

-- Safe table operations
function utils.safeTableInsert(t, value)
    if table and table.insert then
        table.insert(t, value)
    else
        -- Fallback if table.insert is not available
        t[#t + 1] = value
    end
end

function utils.safeTableRemove(t, index)
    if table and table.remove then
        table.remove(t, index)
    else
        -- Fallback if table.remove is not available
        for i = index, #t - 1 do
            t[i] = t[i + 1]
        end
        t[#t] = nil
    end
end

-- Get current time in seconds
function utils.getTimeSeconds()
    return getTime() / 100 -- Convert to seconds
end

return utils
