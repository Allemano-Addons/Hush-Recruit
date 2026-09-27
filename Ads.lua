-- Ads: the recruitment panel. Five saved ad texts, quick channel buttons, a manual channel
-- number, and the apply link + message used by "Send apply link".
local _, R = ...

local Hush = Hush
local Theme, W = Hush.Theme, Hush.Widgets

local WIDTH, HEIGHT = 600, 500
local PAD = 20

local frame, edit, tabs, counter, statusLine, channelBox
local pendingConfirm -- { label, at } for the "sent recently" double-click confirmation

-- ---------------------------------------------------------------------------
-- Text handling
-- ---------------------------------------------------------------------------

-- Each line of an ad is its own chat message; long lines are split at 255 bytes.
function R.SplitAd(text)
    local parts = {}
    for line in ((text or "") .. "\n"):gmatch("(.-)\r?\n") do
        line = strtrim(line)
        if line ~= "" then
            for _, p in ipairs(Hush.SplitMessage(line)) do parts[#parts + 1] = p end
        end
    end
    return parts
end

local function activeText()
    return R.db.ads.texts[R.db.ads.active] or ""
end

local function setStatus(text, colorKey)
    statusLine:SetText(text or "")
    statusLine:SetTextColor(Theme:Color(colorKey or "textDim"))
end

local function updateCounter()
    local text = edit:GetText() or ""
    local n = #R.SplitAd(text)
    counter:SetText(("%d characters  ·  %d message%s"):format(#text, n, n == 1 and "" or "s"))
end

-- ---------------------------------------------------------------------------
-- Channels
-- ---------------------------------------------------------------------------

-- Channel number for a configured value: a fixed number, or a name to look up
-- among the channels you have joined ("trade" matches "Trade - City").
function R.ResolveChannel(value)
    value = strtrim(tostring(value or ""))
    if value == "" then return nil end
    local num = tonumber(value)
    if num then return num end
    local wanted = strlower(value)
    for i = 1, 20 do
        local id, name = GetChannelName(i)
        if id and id > 0 and type(name) == "string" and strlower(name):find(wanted, 1, true) then
            return id, name
        end
    end
    return nil
end

-- Send the active ad. target: "General"/"Trade"/"LFG" (configured), "Guild", or a number.
-- Must run inside the click handler: channel messages need a hardware event.
local function sendAd(label, number)
    local parts = R.SplitAd(activeText())
    if #parts == 0 then
        setStatus("Write an ad first.", "danger")
        return
    end

    local chatType, channel, where
    if label == "Guild" then
        if not IsInGuild() then setStatus("You are not in a guild.", "danger") return end
        chatType, where = "GUILD", "guild chat"
    else
        local value = number or R.db.channels[label]
        local id, name = R.ResolveChannel(value)
        if not id then
            setStatus(("No joined channel matches \"%s\". Join it (/join %s) or set a channel number in the options.")
                :format(tostring(value), tostring(value)), "danger")
            return
        end
        chatType, channel, where = "CHANNEL", id, (name and (id .. ". " .. name) or ("channel " .. id))
    end

    -- Guard against spamming the same channel: a second click within 5 s confirms.
    local key = label or tostring(number)
    local last = R.db.lastSent[key]
    local cooldown = R.db.settings.adCooldown or 60
    local now = time()
    if last and now - last < cooldown then
        if not (pendingConfirm and pendingConfirm.key == key and GetTime() - pendingConfirm.at < 5) then
            pendingConfirm = { key = key, at = GetTime() }
            setStatus(("Sent to %s %d s ago. Click again to send anyway."):format(where, now - last), "away")
            return
        end
    end
    pendingConfirm = nil

    for _, part in ipairs(parts) do
        if C_ChatInfo and C_ChatInfo.SendChatMessage then
            C_ChatInfo.SendChatMessage(part, chatType, nil, channel)
        else
            SendChatMessage(part, chatType, nil, channel)
        end
    end
    R.db.lastSent[key] = now
    if chatType == "CHANNEL" then R.db.lastAd = now end -- starts the candidate window (step 4)
    local status = ("Sent %d message%s to %s at %s."):format(#parts, #parts == 1 and "" or "s", where, date("%H:%M"))
    if chatType == "CHANNEL" then
        status = status .. ("  New whispers from unknown players become candidates until %s.")
            :format(date("%H:%M", now + (R.db.settings.routeMinutes or 30) * 60))
    end
    setStatus(status, "online")
end

-- ---------------------------------------------------------------------------
-- Frame
-- ---------------------------------------------------------------------------

local function selectAd(i)
    R.db.ads.active = i
    tabs:Set(i)
    edit:SetText(activeText())
    edit:SetCursorPosition(0)
    updateCounter()
end

local function savePosition()
    local d = R.db.adsWindow
    d.left, d.top = Theme:Snap(frame:GetLeft(), frame), Theme:Snap(frame:GetTop(), frame)
end

local function restorePosition()
    local d = R.db.adsWindow
    frame:ClearAllPoints()
    if d.left and d.top then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", d.left, d.top)
    else
        frame:SetPoint("CENTER", -120, 40)
    end
end

-- Multi-line edit box inside a clipping scroll frame (Classic has no ScrollBox).
local function buildEditor(parent, height)
    local box = CreateFrame("Frame", nil, parent)
    box:SetHeight(height)
    box.bg = W.Fill(box, "field", 1)
    box.bg:SetAllPoints()
    box.border = W.Border(box, "line")

    local scroll = CreateFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", 10, -8)
    scroll:SetPoint("BOTTOMRIGHT", -10, 8)

    local e = CreateFrame("EditBox", nil, scroll)
    e:SetMultiLine(true)
    e:SetAutoFocus(false)
    e:SetMaxLetters(2000)
    Theme:SetFont(e, "regular", 0)
    e:SetTextColor(Theme:Color("text"))
    e:SetWidth(WIDTH - PAD * 2 - 20)
    scroll:SetScrollChild(e)

    -- Keep the cursor visible while typing.
    e:SetScript("OnCursorChanged", function(_, _, y, _, h)
        y = -y
        local top = scroll:GetVerticalScroll()
        local view = scroll:GetHeight()
        if y < top then
            scroll:SetVerticalScroll(y)
        elseif y + h > top + view then
            scroll:SetVerticalScroll(y + h - view)
        end
    end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = max(0, e:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(min(maxScroll, max(0, self:GetVerticalScroll() - delta * 20)))
    end)
    -- Clicking anywhere in the box focuses the text.
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() e:SetFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEditFocusGained", function() box.border:SetColor(Theme:Accent()) end)
    e:SetScript("OnEditFocusLost", function() box.border:SetColor(Theme:Color("line")) end)
    return box, e
end

local function build()
    -- Named only so ESC closes it through UISpecialFrames (no keyboard capture).
    frame = CreateFrame("Frame", "HushRecruitFrame", UIParent)
    tinsert(UISpecialFrames, "HushRecruitFrame")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide()
    frame.bg = W.Fill(frame, "window", 0.98)
    frame.bg:SetAllPoints()
    frame.border = W.Border(frame, "line")

    -- Title row (drag to move)
    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT")
    title:SetPoint("TOPRIGHT")
    title:SetHeight(40)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function() frame:StartMoving() end)
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        savePosition()
        restorePosition()
    end)
    W.Line(title, "bottom", "line")
    local square = title:CreateTexture(nil, "ARTWORK")
    square:SetSize(10, 10)
    square:SetPoint("LEFT", PAD, 0)
    W.OnAccent(function(r, g, b) square:SetColorTexture(r, g, b, 1) end)
    local name = W.Text(title, "heading", 3, "text")
    name:SetPoint("LEFT", square, "RIGHT", 8, 0)
    name:SetText("RECRUITMENT")
    -- Hush themes: Blizzard Style gives this panel the classic frame too.
    if W.SkinPanel then W.SkinPanel(frame, { kind = "dialog", hide = { frame.bg }, borders = { frame.border }, title = name }) end
    local close = W.IconButton(title, "close", 24, "Close", function() frame:Hide() end, "x")
    close:SetPoint("RIGHT", -8, 0)

    -- Ad tabs
    local adLabel = W.Text(frame, "heading", -1, "textFaint")
    adLabel:SetPoint("TOPLEFT", PAD, -56)
    adLabel:SetText("AD TEXT")
    local options = {}
    for i = 1, R.NUM_ADS do options[i] = { value = i, label = "Ad " .. i } end
    tabs = W.Segment(frame, options, function(i)
        R.db.ads.texts[R.db.ads.active] = edit:GetText()
        selectAd(i)
    end)
    tabs:SetPoint("TOPRIGHT", -PAD, -50)

    -- Editor
    local box
    box, edit = buildEditor(frame, 130)
    box:SetPoint("TOPLEFT", PAD, -82)
    box:SetPoint("TOPRIGHT", -PAD, -82)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then R.db.ads.texts[R.db.ads.active] = self:GetText() end
        updateCounter()
    end)
    counter = W.Text(frame, "regular", -2, "textFaint")
    counter:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -6)
    local hint = W.Text(frame, "regular", -2, "textFaint")
    hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -6)
    hint:SetText("Each line is sent as its own message.")

    -- Send row
    local sendLabel = W.Text(frame, "heading", -1, "textFaint")
    sendLabel:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -34)
    sendLabel:SetText("SEND TO")
    local x = 0
    local row = CreateFrame("Frame", nil, frame)
    row:SetPoint("TOPLEFT", sendLabel, "BOTTOMLEFT", 0, -8)
    row:SetSize(WIDTH - PAD * 2, 28)
    for _, label in ipairs({ "General", "Trade", "LFG", "Guild" }) do
        local b = W.Button(row, label, "accent", function() sendAd(label) end)
        b:SetHeight(28)
        b:SetPoint("LEFT", x, 0)
        b:HookScript("OnEnter", function(self)
            local tip = label == "Guild" and "Guild chat" or ("Channel: " .. tostring(R.db.channels[label]))
            W.ShowTooltip(self, tip)
        end)
        b:HookScript("OnLeave", function() W.HideTooltip() end)
        x = x + b:GetWidth() + 6
    end
    local chLabel = W.Text(row, "regular", -1, "textDim")
    chLabel:SetPoint("LEFT", x + 10, 0)
    chLabel:SetText("Channel #")
    channelBox = W.EditBox(row, "", 28)
    channelBox:SetWidth(44)
    channelBox:SetNumeric(true)
    channelBox:SetMaxLetters(2)
    channelBox:SetPoint("LEFT", chLabel, "RIGHT", 8, 0)
    local sendNum = W.Button(row, "Send", "default", function()
        local num = tonumber(channelBox:GetText())
        if not num then setStatus("Enter a channel number first.", "danger") return end
        sendAd(nil, num)
    end)
    sendNum:SetHeight(28)
    sendNum:SetPoint("LEFT", channelBox, "RIGHT", 6, 0)

    -- Apply link
    local sep = W.Fill(frame, "line", 1, "BORDER")
    sep:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -18)
    sep:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, -18)
    W.PixelSize(sep, frame, "h")

    local applyLabel = W.Text(frame, "heading", -1, "textFaint")
    applyLabel:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -34)
    applyLabel:SetText("APPLY LINK")
    local link = W.EditBox(frame, "Paste your guild's apply link, e.g. https://...", 28)
    link:SetPoint("TOPLEFT", applyLabel, "BOTTOMLEFT", 0, -8)
    link:SetWidth(WIDTH - PAD * 2)
    link:SetMaxLetters(300)
    link:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    link:HookScript("OnTextChanged", function(self, userInput)
        if userInput then R.db.applyLink = strtrim(self:GetText() or "") end
    end)

    local msgLabel = W.Text(frame, "heading", -1, "textFaint")
    msgLabel:SetPoint("TOPLEFT", link, "BOTTOMLEFT", 0, -14)
    msgLabel:SetText("APPLY MESSAGE")
    local msgHint = W.Text(frame, "regular", -2, "textFaint")
    msgHint:SetPoint("LEFT", msgLabel, "RIGHT", 10, 0)
    msgHint:SetText("{name} = the player's name, {link} = the link above")
    local msg = W.EditBox(frame, "Hi {name}! You can apply to our guild here: {link}", 28)
    msg:SetPoint("TOPLEFT", msgLabel, "BOTTOMLEFT", 0, -8)
    msg:SetWidth(WIDTH - PAD * 2)
    msg:SetMaxLetters(250)
    msg:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    msg:HookScript("OnTextChanged", function(self, userInput)
        if userInput then
            local t = strtrim(self:GetText() or "")
            if t ~= "" then R.db.applyMessage = t end
        end
    end)

    statusLine = W.Text(frame, "regular", -1, "textDim")
    statusLine:SetPoint("BOTTOMLEFT", PAD, 16)
    statusLine:SetWidth(WIDTH - PAD * 2)
    statusLine:SetWordWrap(true)

    frame:SetScript("OnShow", function()
        link:SetText(R.db.applyLink or "")
        msg:SetText(R.db.applyMessage or "")
        selectAd(R.db.ads.active)
        setStatus("")
    end)
    frame:SetScript("OnHide", function()
        edit:ClearFocus()
        W.CloseMenus()
    end)

    restorePosition()
end

function R.OpenAds()
    if not R.db then return end
    if not frame then build() end
    frame:Show()
end

function R.ToggleAds()
    if not R.db then return end
    if not frame then build() end
    frame:SetShown(not frame:IsShown())
end

-- Entry points in Hush: a title-row button and the launcher menu.
function R.SetupAdsEntryPoints()
    Hush.AddTitleButton({ icon = "megaphone", glyph = "R", tooltip = "Recruitment ads", onClick = R.ToggleAds })
    Hush.AddLauncherMenuItems(function()
        return { text = "Recruitment ads", onClick = R.ToggleAds }
    end)
end

R.SetupAdsEntryPoints()
