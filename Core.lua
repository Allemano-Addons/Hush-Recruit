-- Hush_Recruit: guild recruitment module for Hush.
-- Core: namespace, saved data, one-time import from SlakthusetRecruit, slash command.
local addonName, R = ...

R.name = addonName
R.MODULE = "Hush_Recruit" -- key for Hush.GetModuleData
R.SCHEMA = 1

local Hush = Hush

function R.Print(...)
    local msg = strjoin(" ", tostringall(...))
    DEFAULT_CHAT_FRAME:AddMessage("|cff3fc7ebHush Recruit|r " .. msg)
end

-- ---------------------------------------------------------------------------
-- Saved data (account-wide). Candidate data lives on each Hush conversation.
-- ---------------------------------------------------------------------------

R.NUM_ADS = 5

local DEFAULTS = {
    ads = { texts = {}, active = 1 },
    -- Quick channel buttons: a channel name (looked up by name) or a fixed number.
    channels = { General = "general", Trade = "trade", LFG = "lookingforgroup" },
    applyLink = "",   -- set in game (the ad panel or the options)
    applyMessage = "Hi {name}! You can apply to our guild here: {link}",
    settings = {
        routeMinutes = 30,   -- whispers from unknown players this long after an ad become candidates
        trialDays = 14,      -- about two raid weeks
        adCooldown = 60,     -- warn when sending to the same channel again within this many seconds
    },
    lastAd = 0,
    lastSent = {},
    adsWindow = {},
}

local function fill(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(dst[k]) == "table" then
            fill(dst[k], v)
        end
    end
end

local function initDB()
    if type(HushRecruitDB) ~= "table" then HushRecruitDB = {} end
    local db = HushRecruitDB
    db.schema = db.schema or R.SCHEMA
    fill(db, DEFAULTS)
    -- Early 0.1.0 builds had a placeholder instead of {link}.
    if db.applyMessage:find("<your link>", 1, true) then db.applyMessage = DEFAULTS.applyMessage end
    for i = 1, R.NUM_ADS do db.ads.texts[i] = db.ads.texts[i] or "" end
    R.db = db
end

-- One-time import of ad texts and channel settings from SlakthusetRecruit
-- (its saved data is only loaded while that addon is enabled).
local function importOld()
    local old = SlakthusetRecruitDB
    if R.db.imported or type(old) ~= "table" then return end
    local n = 0
    if type(old.tabs) == "table" then
        for i = 1, R.NUM_ADS do
            local text = old.tabs[i]
            if type(text) == "string" and strtrim(text) ~= "" and R.db.ads.texts[i] == "" then
                R.db.ads.texts[i] = text
                n = n + 1
            end
        end
        if type(old.activeTab) == "number" then R.db.ads.active = old.activeTab end
    end
    if type(old.channelConfig) == "table" then
        for label, value in pairs(old.channelConfig) do
            if type(value) == "string" and value ~= "" then R.db.channels[label] = value end
        end
    end
    R.db.imported = true
    R.Print(("Imported %d ad text(s) and the channel settings from SlakthusetRecruit. "
        .. "You can disable SlakthusetRecruit now."):format(n))
end

-- ---------------------------------------------------------------------------
-- Startup
-- ---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, name)
    if name ~= addonName then return end
    initDB()
end)

Hush.RegisterCallback("READY", function()
    importOld()
    if R.OnReady then R.OnReady() end
end, addonName)

-- ---------------------------------------------------------------------------
-- Slash command: /hr (and /recruit once SlakthusetRecruit is gone)
-- ---------------------------------------------------------------------------

SLASH_HUSHRECRUIT1 = "/hr"
SLASH_HUSHRECRUIT2 = "/recruit"
SlashCmdList.HUSHRECRUIT = function(msg)
    msg = strlower(strtrim(msg or ""))
    if msg == "" then
        if R.ToggleAds then R.ToggleAds() else R.Print("The ad panel arrives in the next step.") end
    elseif msg == "options" then
        Hush.OpenSettings("recruit")
    elseif msg == "window" then
        R.OpenWindow()
    elseif msg == "status" then
        local filled = 0
        for i = 1, R.NUM_ADS do if R.db.ads.texts[i] ~= "" then filled = filled + 1 end end
        R.Print(("%d/%d ad texts, channels: General=%s, Trade=%s, LFG=%s"):format(filled, R.NUM_ADS,
            tostring(R.db.channels.General), tostring(R.db.channels.Trade), tostring(R.db.channels.LFG)))
    else
        R.Print("/hr - ad panel, /hr options - settings, /hr window - start the candidate window without an ad, /hr status - saved data")
    end
end

-- The apply message for a player, with {name} and {link} filled in. nil if no link is set.
function R.ApplyText(name)
    local link = strtrim(R.db.applyLink or "")
    if link == "" then return nil end
    local short = (name or ""):match("^[^%-]+") or name or ""
    -- "%" is special in gsub replacements (links can contain %20).
    local function lit(s) return (s:gsub("%%", "%%%%")) end
    return (R.db.applyMessage:gsub("{name}", lit(short)):gsub("{link}", lit(link)))
end
