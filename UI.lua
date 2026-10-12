local _, S = ...
local gold = { .84, .70, .44 }
local ink = { .22, .17, .12 }
local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local selected, listOffset, onlyStars, query = nil, 0, false, ""
local rows, filtered = {}, {}

local function rect(parent, r, g, b, a)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(); t:SetColorTexture(r, g, b, a or 1)
    return t
end
local function label(parent, text, size, color)
    local f = parent:CreateFontString(nil, "OVERLAY")
    f:SetFont(font, size, ""); S.Text(f, text); f:SetJustifyH("LEFT")
    f:SetTextColor(unpack(color or gold))
    return f
end
local function button(parent, text, width, action)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 30)
    rect(b, .19, .18, .17)
    b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    b:GetHighlightTexture():SetVertexColor(1, .82, .50, .12)
    b.text = label(b, text, 13)
    b.text:SetPoint("CENTER")
    b:SetScript("OnClick", action)
    return b
end
local function scrollArea(parent, x, y, width, height)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, y); scroll:SetSize(width, height)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width, 1); scroll:SetScrollChild(child)
    return scroll, child
end
local function current() return selected and S.db.books[selected] end

function S.ShowExport(text)
    if not S.exportWindow then
        local f = CreateFrame("Frame", "WCScholarExport", UIParent)
        f:SetSize(760, 540); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true); f:EnableMouse(true)
        rect(f, .09, .10, .12)
        label(f, "TEXTEXPORT", 22):SetPoint("TOPLEFT", 24, -22)
        label(f, "Strg+A · Strg+C · im Texteditor einfügen und als .txt speichern", 13):SetPoint("TOPLEFT", 24, -56)
        button(f, "Schließen", 95, function() f:Hide() end):SetPoint("TOPRIGHT", -20, -17)
        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 24, -90); scroll:SetSize(684, 420)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFont(font, 14, "")
        edit:SetTextColor(.92, .90, .84); edit:SetWidth(680); edit:SetHeight(420)
        edit:SetMaxLetters(0); edit:SetTextInsets(4, 4, 4, 4)
        edit:SetScript("OnEscapePressed", function() f:Hide() end)
        edit:SetScript("OnTextChanged", function(self)
            self:SetHeight(math.max(420, self:GetNumLines() * 20 + 20))
            scroll:UpdateScrollChildRect()
        end)
        edit:SetScript("OnCursorChanged", function(_, _, y, _, h)
            local top = -y
            if top < scroll:GetVerticalScroll() then scroll:SetVerticalScroll(math.max(0,top))
            elseif top+h > scroll:GetVerticalScroll()+scroll:GetHeight() then
                scroll:SetVerticalScroll(math.max(0,top+h-scroll:GetHeight()))
            end
        end)
        scroll:SetScrollChild(edit); f.edit = edit
        f:SetScript("OnHide", function() edit:ClearFocus() end)
        UISpecialFrames[#UISpecialFrames + 1] = "WCScholarExport"
        S.exportWindow = f
    end
    local f = S.exportWindow
    f:SetScale(math.min(1, UIParent:GetWidth()/800, UIParent:GetHeight()/580))
    f:Show(); f.edit:SetText(text); f.edit:SetFocus(); f.edit:HighlightText()
end

local function readBook()
    local f, b = S.window, current()
    if not f then return end
    f.reader:SetVerticalScroll(0)
    if not b then
        S.Text(f.title, "Deine Bibliothek wartet.")
        S.Text(f.meta, "Geschichten bewahren · Azeroth entdecken")
        S.Text(f.body, "Öffne ein Buch, eine Notiz oder einen Brief im Spiel.\n\nWC Scholar bewahrt jede gelesene Seite hier für dich auf. Blättere mehrseitige Bücher einmal vollständig durch.\n\nLinks findest du deine Sammlung. Suche nach Titeln, Fundorten oder Textstellen und markiere Lieblingsstücke als Favoriten.")
        S.Text(f.page, "Noch kein Werk ausgewählt")
        S.Text(f.star.text, "Favorit")
    else
        local nums = S.PageNumbers(b)
        local n = b.bookmark or nums[1] or 1
        if not b.pages[n] then n = nums[1] or 1; b.bookmark = n end
        S.Text(f.title, "%s", b.title)
        S.Text(f.meta, "%s  ·  %d Seite(n)  ·  %s", b.zone or "", #nums, S.T(S.Complete(b) and "Vollständig" or "Unvollständig"))
        local text = b.pages[n] and (b.pages[n].raw and S.Plain(b.pages[n].raw) or b.pages[n].text) or S.T("Diese Seite wurde noch nicht gespeichert.")
        if b.creator and b.creator ~= "" then text = text.."\n\n"..S.T("Verfasst von: %s", b.creator) end
        S.Text(f.body, "%s", text)
        S.Text(f.page, "Seite %d / %s", n, tostring(b.lastPage or "?"))
        S.Text(f.star.text, b.favorite and "Favorit: ja" or "Favorit: nein")
    end
    f.body:SetFont(font, S.db.settings.fontSize or 18, "")
    f.body:SetSpacing(7)
    f.paper:SetHeight(math.max(f.reader:GetHeight(), f.body:GetStringHeight()+32))
    f.reader:UpdateScrollChildRect()
end

local function movePage(direction)
    local b = current()
    if not b then return end
    local nums = S.PageNumbers(b)
    for i, n in ipairs(nums) do
        if n == b.bookmark and nums[i+direction] then b.bookmark = nums[i+direction]; break end
    end
    readBook()
end

function S.Refresh()
    local f = S.window
    if not f then return end
    filtered = {}
    local total = 0
    for _, b in pairs(S.db.books) do
        total = total + 1
        local matches = query == "" or string.find(string.lower(b.title.." "..(b.zone or "")), query, 1, true)
        if not matches then
            for _, p in pairs(b.pages) do if string.find(string.lower(p.text), query, 1, true) then matches = true; break end end
        end
        if matches and (not onlyStars or b.favorite) then filtered[#filtered+1] = b end
    end
    table.sort(filtered, function(a,b)
        if a.title == b.title then return tonumber(a.id)<tonumber(b.id) end
        return a.title < b.title
    end)
    listOffset = math.min(listOffset, math.max(0, math.floor((#filtered-1)/8)*8))
    S.Text(f.count, "%d gesammelte Werke", total)
    S.Text(f.listPage, "%d Treffer · %d / %d", #filtered, math.floor(listOffset/8)+1, math.max(1,math.ceil(#filtered/8)))
    for i, row in ipairs(rows) do
        local b = filtered[listOffset+i]
        row.bookID = b and b.id
        row:SetShown(b ~= nil)
        if b then
            row.heading:SetText((b.favorite and "* " or "")..b.title)
            S.Text(row.sub, "%d Seite(n) · %s", #S.PageNumbers(b), S.T(S.Complete(b) and "Vollständig" or "Unvollständig"))
            row.bg:SetColorTexture(b.id == selected and .26 or .14, b.id == selected and .23 or .14, b.id == selected and .18 or .15)
        end
    end
    readBook()
end

local function createWindow()
    local f = CreateFrame("Frame", "WCScholarWindow", UIParent)
    S.window = f
    f:SetSize(960, 650); f:SetPoint("CENTER"); f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true)
    rect(f, .085, .09, .10)
    local drag = CreateFrame("Frame", nil, f)
    f.dragHandle = drag
    drag:SetPoint("TOPLEFT"); drag:SetPoint("TOPRIGHT"); drag:SetHeight(85)
    drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local x,y = f:GetCenter()
        S.db.settings.x, S.db.settings.y = x, y
    end)
    label(f, "WC SCHOLAR", 26):SetPoint("TOPLEFT", 26, -20)
    label(f, "D I E  G E S C H I C H T E N  A Z E R O T H S", 10):SetPoint("TOPLEFT", 28, -54)
    f.count = label(f, "", 12); f.count:SetPoint("TOPRIGHT", -65, -29)
    button(drag, "X", 30, function() f:Hide() end):SetPoint("TOPRIGHT", -16, -17)
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", 16, -88); sidebar:SetSize(282, 546); rect(sidebar, .11, .115, .13)
    label(sidebar, "KATALOG", 12):SetPoint("TOPLEFT", 14, -13)
    local search = CreateFrame("EditBox", nil, sidebar, "InputBoxTemplate")
    search:SetSize(242, 26); search:SetPoint("TOPLEFT", 20, -40)
    search:SetAutoFocus(false); search:SetMaxLetters(120)
    search:SetScript("OnTextChanged", function(self) query = string.lower(self:GetText()); listOffset = 0; S.Refresh() end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    label(sidebar, "Suche in Titel, Text und Fundort", 10, {.62,.63,.65}):SetPoint("TOPLEFT", 15, -72)
    local stars
    stars = button(sidebar, "Alle Werke", 252, function()
        onlyStars = not onlyStars; listOffset = 0
        S.Text(stars.text, onlyStars and "Nur Favoriten" or "Alle Werke"); S.Refresh()
    end)
    stars:SetPoint("TOPLEFT", 15, -95)
    for i=1,8 do
        local row = CreateFrame("Button", nil, sidebar)
        row:SetPoint("TOPLEFT", 10, -136-(i-1)*44); row:SetSize(262, 40)
        row.bg = rect(row, .14, .14, .15)
        row.heading = label(row, "", 13, {.91,.87,.77})
        row.heading:SetPoint("TOPLEFT", 10, -5); row.heading:SetSize(242,16); row.heading:SetWordWrap(false)
        row.sub = label(row, "", 10, {.60,.61,.63}); row.sub:SetPoint("TOPLEFT", 10, -24)
        row:SetScript("OnClick", function(self) selected = self.bookID; S.Refresh() end)
        row:SetScript("OnEnter", function(self)
            if not self.bookID then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(S.db.books[self.bookID].title); GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows[i] = row
    end
    button(sidebar, "<", 32, function() listOffset = math.max(0,listOffset-8); S.Refresh() end):SetPoint("BOTTOMLEFT", 10, 12)
    button(sidebar, ">", 32, function() if listOffset+8<#filtered then listOffset=listOffset+8 end; S.Refresh() end):SetPoint("BOTTOMRIGHT", -10, 12)
    f.listPage = label(sidebar, "", 10); f.listPage:SetPoint("BOTTOM", 0, 22)
    local page = CreateFrame("Frame", nil, f)
    page:SetPoint("TOPLEFT", 312, -88); page:SetSize(632, 484); rect(page, .91, .865, .75)
    local rule = page:CreateTexture(nil, "ARTWORK"); rule:SetColorTexture(.57,.43,.25,.4)
    rule:SetPoint("TOPLEFT", 28,-101); rule:SetSize(576,1)
    f.title = label(page, "", 24, ink); f.title:SetPoint("TOPLEFT", 28,-23); f.title:SetSize(576,57); f.title:SetJustifyV("TOP")
    f.meta = label(page, "", 11, {.43,.35,.24}); f.meta:SetPoint("TOPLEFT",28,-83); f.meta:SetWidth(576)
    f.reader, f.paper = scrollArea(page, 28, -119, 550, 345)
    f.body = label(f.paper, "",18,ink); f.body:SetPoint("TOPLEFT",0,-3); f.body:SetWidth(540); f.body:SetJustifyV("TOP")
    button(f, "< Zurück", 85, function() movePage(-1) end):SetPoint("TOPLEFT",312,-584)
    button(f, "Weiter >", 85, function() movePage(1) end):SetPoint("TOPLEFT",555,-584)
    f.page = label(f,"",12); f.page:SetPoint("CENTER",f,"TOPLEFT",475,-599)
    f.star = button(f,"Favorit",110,function() local b=current(); if b then b.favorite=not b.favorite; S.Refresh() end end)
    f.star:SetPoint("TOPLEFT",652,-584)
    f.exportBook = button(f,"TXT: Werk",82,function() local b=current(); if b then S.ShowExport(S.ExportBook(b)) end end)
    f.exportBook:SetPoint("TOPLEFT",774,-584)
    f.exportAll = button(f,"Alle",76,function() S.ShowExport(S.ExportAll()) end)
    f.exportAll:SetPoint("TOPLEFT",868,-584)
    S.UpdateExportButtons()
    label(f,"Gelesene Seiten werden automatisch gesammelt. Deine Leseposition bleibt erhalten.",10,{.59,.59,.57}):SetPoint("BOTTOMLEFT",316,15)
    button(drag,"A−",32,function() S.db.settings.fontSize=math.max(14,(S.db.settings.fontSize or 18)-2); readBook() end):SetPoint("TOPLEFT",312,-42)
    button(drag,"A+",32,function() S.db.settings.fontSize=math.min(28,(S.db.settings.fontSize or 18)+2); readBook() end):SetPoint("TOPLEFT",350,-42)
    button(drag,"Einstellungen",112,function() S.ShowSettings() end):SetPoint("TOPLEFT",406,-42)
    UISpecialFrames[#UISpecialFrames+1] = "WCScholarWindow"
    f:SetScript("OnHide",function() search:ClearFocus() end)
    f:Hide()
end

function S.Toggle()
    if not S.window then createWindow() end
    local f = S.window
    f:SetScale(math.min(1,UIParent:GetWidth()/990,UIParent:GetHeight()/680))
    if f:IsShown() then f:Hide() else
        if S.db.settings.x and S.db.settings.y then
            f:ClearAllPoints(); f:SetPoint("CENTER", UIParent,"BOTTOMLEFT",S.db.settings.x,S.db.settings.y)
        end
        f:Show(); S.Refresh()
    end
end

function S.UpdateExportButtons()
    if not S.window or not S.window.exportBook then return end
    S.window.exportBook:SetShown(S.db.settings.showExportButtons)
    S.window.exportAll:SetShown(S.db.settings.showExportButtons)
end

function S.UpdateSettings()
    local f = S.settingsWindow
    if not f then return end
    f.minimap:SetChecked(not S.db.settings.minimapHidden)
    f.tooltips:SetChecked(S.db.settings.tooltips)
    f.export:SetChecked(S.db.settings.showExportButtons)
    local language = S.db.settings.language
    local name = language == "auto" and S.T("Automatisch") or (language == "deDE" and "Deutsch" or "English")
    S.Text(f.language, "Aktuell: %s", name)
end

function S.ShowSettings()
    if not S.settingsWindow then
        local f = CreateFrame("Frame", "WCScholarSettings", UIParent)
        f:SetSize(520, 355); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true); f:EnableMouse(true)
        rect(f, .09, .10, .12)
        label(f, "EINSTELLUNGEN", 22):SetPoint("TOPLEFT", 22, -22)
        button(f, "X", 30, function() f:Hide() end):SetPoint("TOPRIGHT", -16, -18)
        local function check(text, y, action)
            local c = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            c:SetSize(28, 28); c:SetPoint("TOPLEFT", 22, y)
            label(c, text, 14, {.92,.90,.84}):SetPoint("LEFT", c, "RIGHT", 8, 0)
            c:SetScript("OnClick", function(self) action(self:GetChecked() and true or false) end)
            return c
        end
        f.minimap = check("Minimap-Button anzeigen", -76, function(checked)
            S.db.settings.minimapHidden = not checked; S.UpdateMinimap()
        end)
        f.tooltips = check("Sammelstatus in Tooltips anzeigen", -116, function(checked)
            S.db.settings.tooltips = checked
        end)
        f.export = check("Exportbuttons anzeigen", -156, function(checked)
            S.db.settings.showExportButtons = checked; S.UpdateExportButtons()
        end)
        label(f, "Sprache", 14):SetPoint("TOPLEFT", 25, -204)
        button(f, "Automatisch", 105, function() S.SetLanguage("auto") end):SetPoint("TOPLEFT", 25, -232)
        button(f, "Deutsch", 85, function() S.SetLanguage("deDE") end):SetPoint("TOPLEFT", 140, -232)
        button(f, "English", 85, function() S.SetLanguage("enUS") end):SetPoint("TOPLEFT", 235, -232)
        f.language = label(f, "", 12)
        f.language:SetPoint("TOPLEFT", 340, -242)
        label(f, "Minimap: Linksklick öffnet die Bibliothek.\nRechtsklick öffnet Einstellungen. Ziehen verschiebt den Button.", 12):SetPoint("TOPLEFT", 25, -293)
        UISpecialFrames[#UISpecialFrames + 1] = "WCScholarSettings"
        S.settingsWindow = f
    end
    local f = S.settingsWindow
    S.UpdateSettings()
    f:Show()
end
