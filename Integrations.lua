local _, S = ...

-- No tooltip contents or protected/secret values are written back to the client.
local function accessible(value)
    return not issecretvalue or not issecretvalue(value)
end

function S.NormalizeTitle(title)
    if not accessible(title) or type(title) ~= "string" then return "" end
    return S.Plain(title):gsub("’", "'"):gsub("Ä", "ä"):gsub("Ö", "ö"):gsub("Ü", "ü"):lower()
end

function S.CollectionStatus(titles)
    local found, complete, count = false, false, 0
    for _, b in pairs(S.db.books) do
        if (not b.locale or b.locale == GetLocale()) and titles[S.NormalizeTitle(b.title)] then
            found = true; count = count + 1
            if S.Complete(b) then complete = true end
        end
    end
    if complete then return "complete", count end
    if found then return "partial", count end
    return "missing", 0
end

local colors = { complete = {.25, 1, .35}, partial = {1, .60, .12} }
local messages = { complete = "Vollständig gesammelt", partial = "Gesammelt – Seiten fehlen" }

-- Called only for Item and Object tooltips. Never interprets combat/unit tooltips.
function S.AnnotateTooltip(tooltip, data, kind)
    if not S.db or not S.db.settings.tooltips or tooltip:IsForbidden() then return end
    if not data or not accessible(data) or not accessible(data.lines) or type(data.lines) ~= "table" then return end
    local first = data.lines[1]
    if not first or not accessible(first) or not accessible(first.leftText) then return end
    local title = S.NormalizeTitle(first.leftText)
    if title == "" then return end
    -- Only actual collected titles qualify. No catalog IDs, blank-line markers
    -- or guessed cursor states: unknown items and objects receive no annotation.
    local status, editions = S.CollectionStatus({ [title] = true })
    if status == "missing" then return end
    -- Rebuilt tooltips clear lines first. Guard repeated callbacks for the same content.
    local key = kind..":"..title
    if tooltip.wcScholarKey == key then return end
    tooltip.wcScholarKey = key
    local message = messages[status]
    if editions > 1 and status == "complete" then message = "Mindestens eine Fassung vollständig" end
    tooltip:AddLine("WC Scholar: "..S.T(message), unpack(colors[status]))
end

function S.UpdateMinimap()
    local b = S.minimapButton
    if not b then return end
    local angle = math.rad(S.db.settings.minimapAngle or 225)
    local x, y = math.cos(angle), math.sin(angle)
    local rx, ry = Minimap:GetWidth()/2+9, Minimap:GetHeight()/2+9
    if GetMinimapShape and GetMinimapShape() == "SQUARE" then
        local divisor = math.max(math.abs(x), math.abs(y))
        x, y = x/divisor, y/divisor
    end
    b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", x*rx, y*ry)
    b:SetShown(not S.db.settings.minimapHidden)
end

local function cursorAngle(x, y)
    if x == 0 then return y >= 0 and 90 or 270 end
    local a = math.deg(math.atan(y/x))
    if x < 0 then a = a+180 end
    return a % 360
end

local function createMinimap()
    if S.minimapButton or not Minimap then return end
    local b = CreateFrame("Button", "WCScholarMinimapButton", Minimap)
    S.minimapButton = b
    b:SetSize(32,32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(Minimap:GetFrameLevel()+8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
    local icon = b:CreateTexture(nil,"BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09"); icon:SetSize(21,21); icon:SetPoint("CENTER")
    local border = b:CreateTexture(nil,"OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(54,54); border:SetPoint("TOPLEFT")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:SetScript("OnClick", function(_, mouseButton)
        if b.suppressClick then b.suppressClick = nil; return end
        if mouseButton == "RightButton" then S.ShowSettings() else S.Toggle() end
    end)
    b:SetScript("OnDragStart", function()
        b.suppressClick = true; GameTooltip:Hide()
        b:SetScript("OnUpdate", function()
            local x,y = GetCursorPosition(); local scale = Minimap:GetEffectiveScale()
            local cx,cy = Minimap:GetCenter()
            S.db.settings.minimapAngle = cursorAngle(x/scale-cx, y/scale-cy)
            S.UpdateMinimap()
        end)
    end)
    b:SetScript("OnDragStop", function()
        b:SetScript("OnUpdate", nil)
        -- Ignore a drag-release click, but do not swallow the user's next click.
        if C_Timer then C_Timer.After(0, function() b.suppressClick = nil end) end
    end)
    b:SetScript("OnHide", function() b:SetScript("OnUpdate", nil); b.suppressClick = nil end)
    b:SetScript("OnEnter", function()
        GameTooltip:SetOwner(b,"ANCHOR_LEFT"); GameTooltip:SetText("WC Scholar")
        GameTooltip:AddLine(S.T("Linksklick: Bibliothek"),1,1,1)
        GameTooltip:AddLine(S.T("Rechtsklick: Einstellungen"),1,1,1)
        GameTooltip:AddLine(S.T("Ziehen: Position ändern"),.84,.70,.44); GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    S.UpdateMinimap()
end

function S.InitIntegrations()
    if S.integrationsReady then return end
    S.integrationsReady = true
    createMinimap()
    local hooked = setmetatable({}, {__mode="k"})
    local function post(kind)
        return function(tooltip, data)
            if tooltip:IsForbidden() then return end
            if not hooked[tooltip] then
                tooltip:HookScript("OnTooltipCleared", function(self) self.wcScholarKey = nil end)
                hooked[tooltip] = true
            end
            S.AnnotateTooltip(tooltip, data, kind)
        end
    end
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, post("item"))
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, post("object"))
    end
end
