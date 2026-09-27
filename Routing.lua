-- Routing: unknown players who whisper you shortly after an ad become candidates, and a
-- candidate joining the guild starts their trial. Ordinary whispers are never touched:
-- guild members, friends and people you whisper first are not candidates.
local _, R = ...

local Hush = Hush

-- Seconds left in the candidate window after the latest ad (0 when closed).
function R.WindowLeft()
    local len = (R.db.settings.routeMinutes or 30) * 60
    return max(0, (R.db.lastAd or 0) + len - time())
end

-- New conversation from an unknown player (a "request") while the window is open -> Recruits.
Hush.AddRoutingRule(function(conv)
    if conv.kind == "whisper" and conv.request and R.WindowLeft() > 0 then
        return "recruits"
    end
end, 20, R.MODULE)

-- Mark it as a new candidate and show it under Recruits right away (not in Requests).
Hush.RegisterCallback("CONV_CREATED", function(_, key, conv)
    if conv.kind ~= "whisper" or conv.category ~= "recruits" or not conv.request then return end
    local d = R.Data(key)
    d.status, d.source, d.since = "new", "ad", time()
    Hush.MoveConversation(key, "recruits") -- accepts the request
end, R.MODULE)

-- ---------------------------------------------------------------------------
-- Guild join -> trial
-- ---------------------------------------------------------------------------

local joinPattern
local function matchJoin(msg)
    if not ERR_GUILD_JOIN_S then return nil end
    if not joinPattern then
        local p = ERR_GUILD_JOIN_S:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
        joinPattern = "^" .. p:gsub("%%%%s", "(.+)") .. "$"
    end
    return msg:match(joinPattern)
end

-- Candidate conversation for a character name, ignoring letter case.
local function findCandidate(name)
    local lname = strlower(name)
    for key, conv in Hush.Conversations() do
        if conv.kind == "whisper" and strlower(conv.target or "") == lname and R.IsCandidate(key) then
            return key, conv
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent", function(_, _, msg)
    if not R.db or not Hush.IsReady() then return end
    local who = matchJoin(msg or "")
    if not who then return end
    local key, conv = findCandidate(who:match("^[^%-]+") or who)
    if not key then key, conv = findCandidate(who) end
    if not key then return end
    local d = R.Data(key)
    if d.status == "member" or d.status == "trial" then return end
    d.trialStart = nil
    R.SetStatus(key, "trial")
    R.Print(("%s joined the guild – trial started (day 1/%d)."):format(conv.display, R.db.settings.trialDays or 14))
end)

-- ---------------------------------------------------------------------------
-- Trial reminders at login
-- ---------------------------------------------------------------------------

function R.CheckTrials()
    local len = R.db.settings.trialDays or 14
    local due = {}
    for key, conv in Hush.Conversations() do
        local d = R.Peek(key)
        if d and d.status == "trial" and d.trialStart then
            local day = R.TrialDay(d)
            if day > len then due[#due + 1] = ("%s (day %d)"):format(conv.display, day) end
        end
    end
    if #due > 0 then
        R.Print(("Trial ended for %d player(s): %s. Set them to Member or Declined."):format(#due, table.concat(due, ", ")))
    end
end

-- Open the window without posting an ad (e.g. you advertised on Discord).
function R.OpenWindow()
    R.db.lastAd = time()
    R.Print(("Candidate window open for %d minutes: unknown players who whisper you become candidates.")
        :format(R.db.settings.routeMinutes or 30))
end

R.OnReady = function() R.CheckTrials() end
