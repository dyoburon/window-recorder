-- Window Recorder for Hammerspoon
-- Record window positions with a hotkey, replay them with another
-- https://github.com/burtond/window-recorder

require("hs.ipc")

-- Saved window positions (persisted to file)
local savedPositions = {}
local nextSlot = 2
local saveFile = os.getenv("HOME") .. "/.hammerspoon/window-positions.json"

-- Load saved positions from file
local function loadPositions()
    local file = io.open(saveFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local decoded = hs.json.decode(content)
        if decoded then
            savedPositions = decoded.positions or {}
            nextSlot = decoded.nextSlot or 2
            -- Rebind hotkeys for saved positions
            for slot, pos in pairs(savedPositions) do
                hs.hotkey.bind({"cmd", "alt"}, tostring(slot), function()
                    local w = hs.window.focusedWindow()
                    if w then
                        w:setFrame(hs.geometry.rect(pos.x, pos.y, pos.w, pos.h))
                    end
                end)
            end
        end
    end
end

-- Save positions to file
local function savePositions()
    local data = hs.json.encode({positions = savedPositions, nextSlot = nextSlot})
    local file = io.open(saveFile, "w")
    if file then
        file:write(data)
        file:close()
    end
end

-- Load on startup
loadPositions()

-- Preset slot 1 (edit these values to your preference)
hs.hotkey.bind({"cmd", "alt"}, "1", function()
    local win = hs.window.focusedWindow()
    if win then
        win:setFrame(hs.geometry.rect(100, 100, 800, 600))
    end
end)

-- Cmd+Option+R: Record current window position to next available slot
hs.hotkey.bind({"cmd", "alt"}, "R", function()
    local win = hs.window.focusedWindow()
    if not win then
        hs.alert.show("No window focused")
        return
    end

    if nextSlot > 9 then
        hs.alert.show("All slots (2-9) are full! Reload config to reset.")
        return
    end

    local f = win:frame()
    local slot = nextSlot

    savedPositions[slot] = {x = f.x, y = f.y, w = f.w, h = f.h}

    hs.hotkey.bind({"cmd", "alt"}, tostring(slot), function()
        local w = hs.window.focusedWindow()
        if w then
            local pos = savedPositions[slot]
            w:setFrame(hs.geometry.rect(pos.x, pos.y, pos.w, pos.h))
        end
    end)

    hs.alert.show("Saved to Cmd+Option+" .. slot)
    nextSlot = nextSlot + 1
    savePositions()  -- Persist to disk
end)

-- Cmd+Option+0: Show all saved positions
hs.hotkey.bind({"cmd", "alt"}, "0", function()
    local msg = "Saved positions:\n"
    msg = msg .. "1: Preset\n"
    for i = 2, nextSlot - 1 do
        local p = savedPositions[i]
        msg = msg .. i .. ": " .. p.x .. "," .. p.y .. " (" .. p.w .. "x" .. p.h .. ")\n"
    end
    hs.alert.show(msg, 3)
end)
