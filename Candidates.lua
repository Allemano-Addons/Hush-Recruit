-- Candidates: recruit status per conversation, header chip, header buttons and chat menu.
-- A conversation is a candidate when its module data has a status. Candidates live in the
-- Recruits category; members move to Guild. Ordinary whispers are never touched.
local _, R = ...

local Hush = Hush
local Theme = Hush.Theme
local M = R.MODULE

R.STATUSES = {
    { id = "new",      label = "New",       color = "3FC7EB" },
    { id = "linksent", label = "Link sent", color = "82C5FF" },
    { id = "applied",  label = "Applied",   color = "AAABFE" },
    { id = "trial",    label = "Trial",     color = "FF7F00" },
    { id = "member",   label = "Member",    color = "3FC77F" },
    { id = "declined", label = "Declined",  color = "7C858F" },
}

local byId = {}
for _, s in ipairs(R.STATUSES) do byId[s.id] = s end

-- Read-only look at the candidate data (nil if none). Does not create anything.
function R.Peek(key)
    local conv = Hush.GetConversation(key)
    return conv and conv.mod and conv.mod[M]
end

-- Writable candidate data (created on demand).
function R.Data(key) return Hush.GetModuleData(key, M) end

function R.IsCandidate(key)
    local d = R.Peek(key)
    return d ~= nil and d.status ~= nil
end

-- A candidate still in the recruiting process (Member means done: no chip or buttons).
function R.IsActiveCandidate(key)
    local d = R.Peek(key)
    return d ~= nil and d.status ~= nil and d.status ~= "member"
end

-- Days into the trial (1 on the first day).
function R.TrialDay(d)
    if not d.trialStart then return nil end
    return floor((time() - d.trialStart) / 86400) + 1
end

-- Set a status; moves the chat to Recruits (or Guild for members) and refreshes the UI.
function R.SetStatus(key, status)
    local conv = Hush.GetConversation(key)
    local d = R.Data(key)
    if not conv or not d then return end
    d.status = status
    d.since = d.since or time()
    d.changed = time()
    if status == "trial" and not d.trialStart then d.trialStart = time() end
    local target = status == "member" and "guild" or "recruits"
    if conv.category ~= target or conv.request then Hush.MoveConversation(key, target) end
    Hush.NotifyChanged(key)
end

-- "Not a recruit": forget everything and move back to Other.
function R.ClearCandidate(key)
    local conv = Hush.GetConversation(key)
    local d = R.Data(key)
    if not conv or not d then return end
    for k in pairs(d) do d[k] = nil end
    if conv.category == "recruits" then Hush.MoveConversation(key, "other") end
    Hush.NotifyChanged(key)
end

-- Send the apply message and mark the player as a candidate ("Link sent").
function R.SendApplyLink(key)
    local conv = Hush.GetConversation(key)
    if not conv or conv.kind ~= "whisper" then return end
    local text = R.ApplyText(conv.target)
    if not text then
        R.Print("Set your apply link first (/hr > APPLY LINK).")
        R.OpenAds()
        return
    end
    if Hush.SendMessage(key, text) then
        local d = R.Data(key)
        if not d.status or d.status == "new" then R.SetStatus(key, "linksent") else Hush.NotifyChanged(key) end
        d.linkSent = time()
    end
end

function R.EditNote(key)
    local conv = Hush.GetConversation(key)
    local d = R.Data(key)
    if not conv or not d then return end
    Hush.ShowDialog({
        title = "Note",
        text = conv.display .. "  ·  leave empty to remove the note",
        input = d.note or "",
        maxLetters = 250,
        allowEmpty = true,
        okText = "Save",
        onOk = function(text)
            d.note = text ~= "" and text or nil
            Hush.NotifyChanged(key)
        end,
    })
end

local function statusItems(key)
    local d = R.Peek(key) or {}
    local items = {}
    for _, s in ipairs(R.STATUSES) do
        items[#items + 1] = {
            text = s.label,
            checked = d.status == s.id,
            onClick = function() R.SetStatus(key, s.id) end,
        }
    end
    if d.status then
        items[#items + 1] = { separator = true }
        items[#items + 1] = { text = "Not a recruit", danger = true, onClick = function() R.ClearCandidate(key) end }
    end
    return items
end

-- ---------------------------------------------------------------------------
-- Hush integration
-- ---------------------------------------------------------------------------

local function isWhisper(conv) return conv.kind == "whisper" end
-- Guild member per the roster, or per the info Hush knows (roster may lag behind a join).
local function inGuild(conv)
    if Hush.IsGuildMember(conv.target) then return true end
    local mine = IsInGuild() and GetGuildInfo("player") or nil
    return mine ~= nil and conv.info and conv.info.guild == mine
end

-- Apply link only makes sense before someone is in the guild.
local function wantsApply(key, conv)
    if inGuild(conv) then return false end
    local d = R.Peek(key)
    return not (d and (d.status == "trial" or d.status == "member"))
end

-- Status chip: "TRIAL · DAY 5/14", colored per status.
Hush.AddStatusChip(function(key)
    local d = R.Peek(key)
    if not d or not d.status or d.status == "member" then return nil end
    local s = byId[d.status]
    if not s then return nil end
    local text = s.label
    local r, g, b = Theme.Hex(s.color)
    if d.status == "trial" and d.trialStart then
        local day, len = R.TrialDay(d), R.db.settings.trialDays or 14
        if day > len then
            text = "Trial ended · day " .. day
            r, g, b = Theme:Color("danger")
        else
            text = ("Trial · day %d/%d"):format(day, len)
        end
    end
    return text, r, g, b
end, M)

-- Header buttons, added right to left: Note, Status, Apply link. (Guild invite is in the
-- right-click menu: it is protected and only works reliably through the menu.)
Hush.AddHeaderButton({
    id = "recruit_note", text = "Note", tooltip = "Note about this candidate",
    isShown = function(key, conv) return isWhisper(conv) and R.IsActiveCandidate(key) end,
    onClick = function(key) R.EditNote(key) end,
}, M)

Hush.AddHeaderButton({
    id = "recruit_status", text = "Status", tooltip = "Recruit status",
    isShown = function(key, conv) return isWhisper(conv) and R.IsActiveCandidate(key) end,
    onClick = function(key) Hush.Widgets.OpenMenu(statusItems(key)) end,
}, M)

Hush.AddHeaderButton({
    id = "recruit_apply", text = "Apply link", tooltip = "Whisper your apply link and track as a recruit",
    isShown = function(key, conv) return isWhisper(conv) and wantsApply(key, conv) end,
    onClick = function(key) R.SendApplyLink(key) end,
}, M)

-- Chat right-click menu.
Hush.AddChatMenuItems(function(key, conv)
    if not isWhisper(conv) then return nil end
    local d = R.Peek(key) or {}
    local items = {}
    if wantsApply(key, conv) then
        items[#items + 1] = { text = "Send apply link", onClick = function() R.SendApplyLink(key) end }
    end
    if d.status then
        items[#items + 1] = { text = "Recruit status", submenu = statusItems(key) }
        items[#items + 1] = { text = d.note and "Edit note" or "Add note", onClick = function() R.EditNote(key) end }
    elseif not inGuild(conv) then
        items[#items + 1] = { text = "Track as recruit", onClick = function() R.SetStatus(key, "new") end }
    end
    return #items > 0 and items or nil
end)

-- The note on the header info line.
Hush.AddHeaderInfo(function(key)
    local d = R.Peek(key)
    if d and d.status and d.note and d.note ~= "" then
        return d.note -- Hush shows it on its own line with an accent bar
    end
end, M)

-- Storage cleanup never removes candidates still in the process (or members with a note).
Hush.AddRetentionGuard(function(key)
    local d = R.Peek(key)
    if not d or not d.status then return false end
    return d.status ~= "declined" and (d.status ~= "member" or (d.note ~= nil and d.note ~= ""))
end, M)
