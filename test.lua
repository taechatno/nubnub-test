local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

-- WindUI
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local MAX_USERS = 15
local enabled = true
local usernameValues = {}

for i = 1, MAX_USERS do
    usernameValues[i] = ""
end

--==================================================
-- WINDOW
-- Folder จำเป็นสำหรับ ConfigManager
--==================================================

local Window = WindUI:CreateWindow({
    Title = "nubnub",
    Icon = "door-open",
    Author = "by nubnub",

    -- Config จะถูกเก็บใน Folder นี้
    Folder = "nubnub"
})

--==================================================
-- CONFIG
--==================================================

local ConfigManager = Window.ConfigManager
local Config = nil
local configLoaded = false

if ConfigManager then
    pcall(function()
        ConfigManager:Init(Window)
        Config = ConfigManager:CreateConfig("AutoLeave")
    end)
end

-- เซฟ Config อัตโนมัติ
local function saveConfig()
    if not configLoaded then
        return
    end

    if Config then
        pcall(function()
            Config:Save()
        end)
    end
end

--==================================================
-- TAB
--==================================================

local Tab = Window:Tab({
    Title = "Server",
    Icon = "users"
})

--==================================================
-- AUTO LEAVE
--==================================================

local AutoLeaveToggle

AutoLeaveToggle = Tab:Toggle({
    Title = "Auto Leave",
    Desc = "Leave server when target player is found",

    Flag = "AutoLeave",

    Value = true,

    Callback = function(value)
        enabled = value

        saveConfig()

        -- ถ้าเปิด Auto Leave กลับมา
        -- ให้ตรวจ Server ทันที
        if value and configLoaded then
            task.spawn(function()
                task.wait(0.1)

                if _G.NubNubCheckServer then
                    _G.NubNubCheckServer()
                end
            end)
        end
    end
})

--==================================================
-- USERNAME LIST
--==================================================

Tab:Section({
    Title = "Username Blacklist"
})

Tab:Paragraph({
    Title = "Target Players",
    Desc = "Enter username only. @ is optional.\nYou can save up to "
        .. MAX_USERS .. " players."
})

local UsernameInputs = {}

for i = 1, MAX_USERS do

    UsernameInputs[i] = Tab:Input({
        Title = "Username " .. i,

        Flag = "Username_" .. i,

        Value = "",

        Placeholder = "Enter username...",

        Callback = function(value)

            value = tostring(value or "")

            -- เอา @ ออก
            value = value:gsub("@", "")

            -- เอาช่องว่างออก
            value = value:gsub("%s+", "")

            usernameValues[i] = value

            saveConfig()
        end
    })

end

--==================================================
-- USERNAME CHECK
--==================================================

local function cleanUsername(name)

    if not name then
        return ""
    end

    name = tostring(name)

    -- ลบ @
    name = name:gsub("@", "")

    -- ลบช่องว่าง
    name = name:gsub("%s+", "")

    -- เปลี่ยนเป็นตัวเล็กทั้งหมด
    return string.lower(name)
end

local function isBlacklisted(username)

    local targetName = cleanUsername(username)

    for i = 1, MAX_USERS do

        local savedName = cleanUsername(usernameValues[i])

        if savedName ~= "" and savedName == targetName then
            return true
        end

    end

    return false
end

--==================================================
-- SERVER CHECK
--==================================================

local teleporting = false

local function checkServer()

    if not enabled then
        return
    end

    if teleporting then
        return
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do

        if otherPlayer ~= player then

            if isBlacklisted(otherPlayer.Name) then

                teleporting = true

                WindUI:Notify({
                    Title = "Player Found",
                    Content = otherPlayer.Name
                        .. " is in blacklist.\nChanging server...",
                    Icon = "triangle-alert",
                    Duration = 3
                })

                task.wait(0.5)

                local success = pcall(function()

                    TeleportService:Teleport(
                        game.PlaceId,
                        player
                    )

                end)

                if not success then
                    teleporting = false
                end

                return
            end

        end
    end
end

-- ให้ Toggle เรียกได้
_G.NubNubCheckServer = checkServer

--==================================================
-- BUTTON
--==================================================

Tab:Button({
    Title = "Check Server",
    Icon = "search",

    Callback = function()

        local found = false

        for _, otherPlayer in ipairs(Players:GetPlayers()) do

            if otherPlayer ~= player
                and isBlacklisted(otherPlayer.Name) then

                found = true
                break

            end

        end

        if not found then

            WindUI:Notify({
                Title = "Server Safe",
                Content = "No blacklisted player found.",
                Icon = "check",
                Duration = 3
            })

        end

        checkServer()
    end
})

--==================================================
-- CONFIG LOAD
--==================================================

if Config then

    -- Register ทุก Element
    Config:Register(
        "AutoLeave",
        AutoLeaveToggle
    )

    for i = 1, MAX_USERS do

        Config:Register(
            "Username_" .. i,
            UsernameInputs[i]
        )

    end

    -- โหลด Config เก่า
    pcall(function()
        Config:Load()
    end)

end

-- รอให้ WindUI ใส่ค่าที่โหลดกลับเข้า Input
task.wait(1)

configLoaded = true

-- อ่านค่าปัจจุบันหลัง Load
enabled = AutoLeaveToggle.Value

for i = 1, MAX_USERS do

    local input = UsernameInputs[i]

    if input and input.Value then

        usernameValues[i] =
            cleanUsername(input.Value)

    end

end

-- เซฟหลังโหลด
saveConfig()

--==================================================
-- CHECK SERVER WHEN SCRIPT STARTS
--==================================================

checkServer()

--==================================================
-- CHECK WHEN NEW PLAYER JOINS
--==================================================

Players.PlayerAdded:Connect(function(newPlayer)

    task.wait(1)

    if enabled then
        checkServer()
    end

end)
