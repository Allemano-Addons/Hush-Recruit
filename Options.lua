-- Options: a "Recruit" page in the Hush settings.
local _, R = ...

local Hush = Hush
local W = Hush.Widgets

local LABEL_W = 80

-- A row of label + edit box inside a Custom block. Returns the edit box.
local function field(container, y, label, placeholder, maxLetters, onChange)
    local fs = W.Text(container, "semibold", 0, "text")
    fs:SetPoint("TOPLEFT", 0, y - 7)
    fs:SetText(label)
    local e = W.EditBox(container, placeholder, 28)
    e:SetPoint("TOPLEFT", LABEL_W, y)
    e:SetPoint("TOPRIGHT", 0, y)
    e:SetMaxLetters(maxLetters or 100)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:HookScript("OnTextChanged", function(self, userInput)
        if userInput then onChange(strtrim(self:GetText() or "")) end
    end)
    return e
end

Hush.AddSettingsPage({
    id = "recruit",
    label = "Recruit",
    build = function(page)
        local s = R.db.settings

        page:Header("Channel buttons")
        page:Custom(3 * 34, function(c)
            local boxes = {}
            for i, label in ipairs({ "General", "Trade", "LFG" }) do
                boxes[label] = field(c, -(i - 1) * 34, label, "Channel name (e.g. trade) or number", 30, function(v)
                    R.db.channels[label] = v
                end)
            end
            return function()
                for label, box in pairs(boxes) do box:SetText(R.db.channels[label] or "") end
            end
        end)

        page:Header("Candidates")
        page:Slider("Candidate window", "Unknown players who whisper you this long after an ad become candidates.",
            10, 120, 5, function(v) return v .. " min" end,
            function() return s.routeMinutes end, function(v) s.routeMinutes = v end)
        page:Slider("Trial length", "About two raid weeks is common.", 7, 28, 1, function(v) return v .. " days" end,
            function() return s.trialDays end, function(v)
                s.trialDays = v
                Hush.RefreshHeader()
            end)
        page:Slider("Ad cooldown", "Ask for a second click when posting to the same channel again.", 0, 300, 15,
            function(v) return v == 0 and "off" or (v .. " s") end,
            function() return s.adCooldown end, function(v) s.adCooldown = v end)

        page:Header("Apply")
        page:Custom(2 * 34, function(c)
            local link = field(c, 0, "Link", "Paste your guild's apply link, e.g. https://...", 300, function(v)
                R.db.applyLink = v
            end)
            local msg = field(c, -34, "Message", "{name} = the player's name, {link} = the link", 250, function(v)
                if v ~= "" then R.db.applyMessage = v end
            end)
            return function()
                link:SetText(R.db.applyLink or "")
                msg:SetText(R.db.applyMessage or "")
            end
        end)

        page:Header("Tools")
        page:Custom(28, function(c)
            local ads = W.Button(c, "Open ad panel", "accent", function() R.OpenAds() end)
            ads:SetHeight(28)
            ads:SetPoint("LEFT", 0, 0)
            local win = W.Button(c, "Start candidate window", "default", function() R.OpenWindow() end)
            win:SetHeight(28)
            win:SetPoint("LEFT", ads, "RIGHT", 8, 0)
        end)
    end,
})
