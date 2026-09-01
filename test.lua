local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

--==================================================
-- WINDUI
--==================================================

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
local WebhookURL = ""

for i = 1, MAX_USERS do
    usernameValues[i] = ""
end

--==================================================
-- WINDOW
--==================================================

local Window = WindUI:CreateWindow({
    Title = "nubnub",
    Icon = "flame",
    Author = "by nubnub",
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

--==================================================
-- SAVE CONFIG
--==================================================

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
-- AUTO CHANGE SERVER
--==================================================

local AutoChangeServerToggle

AutoChangeServerToggle = Tab:Toggle({
    Title = "Auto Change Server",
    Desc = "Change server when target player is found",

    Flag = "AutoChangeServer",

    Value = true,

    Callback = function(value)

        enabled = value

        saveConfig()

        -- ถ้าเปิดกลับมา ให้ตรวจทันที
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

            -- ลบ @
            value = value:gsub("@", "")

            -- ลบช่องว่าง
            value = value:gsub("%s+", "")

            usernameValues[i] = value

            saveConfig()

        end
    })

end

--==================================================
-- CLEAN USERNAME
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

    -- ไม่สนตัวพิมพ์เล็ก/ใหญ่
    return string.lower(name)
end

--==================================================
-- CHECK BLACKLIST
--==================================================

local function isBlacklisted(username)

    local targetName = cleanUsername(username)

    if targetName == "" then
        return false
    end

    for i = 1, MAX_USERS do

        local savedName =
            cleanUsername(usernameValues[i])

        if savedName ~= ""
            and savedName == targetName then

            return true
        end

    end

    return false
end

--==================================================
-- WEBHOOK
--==================================================

Tab:Section({
    Title = "Webhook"
})

local WebhookInput

WebhookInput = Tab:Input({

    Title = "Discord Webhook",

    Desc = "Paste your Discord Webhook URL",

    Placeholder = "https://discord.com/api/webhooks/...",

    InputIcon = "webhook",

    Flag = "WebhookURL",

    Value = "",

    Callback = function(value)

        WebhookURL = tostring(value or "")

        saveConfig()

    end
})

--==================================================
-- REQUEST FUNCTION
--==================================================

local function getRequestFunction()

    return request
        or http_request
        or (syn and syn.request)
end

--==================================================
-- SEND WEBHOOK
--==================================================

local function sendWebhook(message)

    if WebhookURL == "" then
        return false
    end

    local requestFunc = getRequestFunction()

    if not requestFunc then
        return false
    end

    local success = pcall(function()

        requestFunc({

            Url = WebhookURL,

            Method = "POST",

            Headers = {
                ["Content-Type"] = "application/json"
            },

            Body = HttpService:JSONEncode({

                content = message

            })

        })

    end)

    return success
end

--==================================================
-- TEST WEBHOOK
--==================================================

Tab:Button({

    Title = "Test Webhook",

    Icon = "send",

    Callback = function()

        if WebhookURL == "" then

            WindUI:Notify({
                Title = "Webhook",
                Content = "Please enter Webhook URL first.",
                Icon = "triangle-alert",
                Duration = 3
            })

            return
        end

        local success = sendWebhook(
            "✅ **Webhook Test**\nWebhook ทำงานเรียบร้อย!"
        )

        if success then

            WindUI:Notify({
                Title = "Webhook",
                Content = "Test Webhook sent.",
                Icon = "check",
                Duration = 3
            })

        else

            WindUI:Notify({
                Title = "Webhook",
                Content = "ส่ง Webhook ไม่สำเร็จ",
                Icon = "triangle-alert",
                Duration = 3
            })

        end

    end
})

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

    for _, otherPlayer in ipairs(
        Players:GetPlayers()
    ) do

        if otherPlayer ~= player then

            if isBlacklisted(otherPlayer.Name) then

                teleporting = true

                --==================================
                -- WEBHOOK
                --==================================

                sendWebhook(
                    "⚠️ **Blacklisted Player Found**" ..
                    "\n\n" ..
                    "**Username:** " ..
                    otherPlayer.Name ..
                    "\n**Display Name:** " ..
                    otherPlayer.DisplayName ..
                    "\n**User ID:** " ..
                    otherPlayer.UserId ..
                    "\n**Place ID:** " ..
                    game.PlaceId ..
                    "\n**Job ID:** `" ..
                    game.JobId ..
                    "`"
                )

                --==================================
                -- NOTIFY
                --==================================

                WindUI:Notify({

                    Title = "Player Found",

                    Content =
                        otherPlayer.Name ..
                        " is in blacklist.\nChanging server...",

                    Icon = "triangle-alert",

                    Duration = 3

                })

                task.wait(0.5)

                --==================================
                -- CHANGE SERVER
                --==================================

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

--==================================================
-- GLOBAL CHECK FUNCTION
--==================================================

_G.NubNubCheckServer = checkServer

--==================================================
-- CHECK SERVER BUTTON
--==================================================

Tab:Button({

    Title = "Check Server",

    Icon = "search",

    Callback = function()

        local found = false
        local foundName = nil

        for _, otherPlayer in ipairs(
            Players:GetPlayers()
        ) do

            if otherPlayer ~= player
                and isBlacklisted(otherPlayer.Name) then

                found = true
                foundName = otherPlayer.Name

                break
            end

        end

        if not found then

            WindUI:Notify({

                Title = "Server Safe",

                Content =
                    "No blacklisted player found.",

                Icon = "check",

                Duration = 3

            })

        end

        checkServer()

    end
})

--==================================================
-- REGISTER CONFIG
--==================================================

if Config then

    -- Auto Change Server
    Config:Register(
        "AutoChangeServer",
        AutoChangeServerToggle
    )

    -- Username 1-15
    for i = 1, MAX_USERS do

        Config:Register(
            "Username_" .. i,
            UsernameInputs[i]
        )

    end

    -- Webhook
    Config:Register(
        "WebhookURL",
        WebhookInput
    )

    -- โหลด Config เดิม
    pcall(function()
        Config:Load()
    end)

end

--==================================================
-- WAIT FOR CONFIG LOAD
--==================================================

task.wait(1)

configLoaded = true

--==================================================
-- READ LOADED VALUES
--==================================================

-- Auto Change Server
if AutoChangeServerToggle then
    enabled = AutoChangeServerToggle.Value
end

-- Username
for i = 1, MAX_USERS do

    local input = UsernameInputs[i]

    if input and input.Value then

        usernameValues[i] =
            cleanUsername(input.Value)

    end

end

-- Webhook
if WebhookInput and WebhookInput.Value then

    WebhookURL =
        tostring(WebhookInput.Value or "")

end

--==================================================
-- SAVE CURRENT CONFIG
--==================================================

saveConfig()

--==================================================
-- CHECK SERVER ON SCRIPT START
--==================================================

checkServer()

--==================================================
-- CHECK WHEN PLAYER JOINS
--==================================================

Players.PlayerAdded:Connect(function(newPlayer)

    task.wait(1)

    if enabled then
        checkServer()
    end

end)
