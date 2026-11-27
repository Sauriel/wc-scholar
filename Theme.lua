local _, S = ...

-- Themes update existing widgets so the reader never loses its scroll position.
local bindings = setmetatable({}, {__mode = "k"})
local decorations = setmetatable({}, {__mode = "k"})
local classic = {
    cover = {.12, .105, .09, 1},
    libraryCover = {0, 0, 0, 0},
    paper = {1, 1, 1, 0},
    catalog = {.27, .16, .07, .045},
    accent = {.92, .80, .53, 1},
    ink = {.22, .12, .055, 1},
    catalogInk = {.16, .085, .035, 1},
    mutedInk = {.25, .145, .065, 1},
    searchInput = {.98, .94, .84, 1},
    muted = {.73, .62, .43, 1},
    rule = {.41, .24, .10, .35},
    row = {.45, .30, .12, .04},
    selected = {.53, .29, .08, .18},
}

local function atlasInfo(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end

function S.GetTheme()
    return S.db and S.db.settings.theme == "classic" and "classic" or "modern"
end

local function apply(object, binding)
    local color = S.GetTheme() == "classic" and classic[binding.role] or binding.modern
    color = color or binding.modern
    if binding.kind == "text" then
        object:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    else
        object:SetVertexColor(1, 1, 1, 1)
        object:SetColorTexture(unpack(color))
    end
end

function S.StyleColor(object, role, modern)
    bindings[object] = {kind = "text", role = role, modern = modern}
    apply(object, bindings[object])
end

function S.StyleSurface(object, role, modern)
    bindings[object] = {kind = "color", role = role, modern = modern}
    apply(object, bindings[object])
end

function S.StyleRow(texture, selected)
    S.StyleSurface(texture, selected and "selected" or "row",
        selected and {.26, .23, .18, 1} or {.14, .14, .15, 1})
end

-- Current Blizzard metal frame art. Corners retain their native dimensions.
local frameLayout = {
    TopLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft", x = -8, y = 16},
    TopRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16},
    BottomLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -8, y = -3},
    BottomRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3},
    TopEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop"},
    BottomEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom"},
    LeftEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft"},
    RightEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight"},
}

function S.StyleFrame(frame)
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:EnableMouse(false)
    border:SetFrameLevel(frame:GetFrameLevel())
    local native = NineSliceUtil and NineSliceUtil.ApplyLayout
    for _, piece in pairs(frameLayout) do
        if not atlasInfo(piece.atlas) then native = false; break end
    end
    if native then
        border:SetPoint("TOPLEFT", 8, -16); border:SetPoint("BOTTOMRIGHT", -4, 3)
        NineSliceUtil.ApplyLayout(border, frameLayout)
    else
        border:SetAllPoints()
        border:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12})
        border:SetBackdropBorderColor(.64, .56, .40, 1)
    end
    border:SetShown(S.GetTheme() == "classic")
    frame.classicBorder = border
    decorations[border] = "frame"
end

local function setIcon(texture, style, pressed, enabled, hovered)
    texture:SetTexCoord(0, 1, 0, 1)
    if style == "close" then
        local name = not enabled and "RedButton-Exit-Disabled"
            or (pressed and "RedButton-exit-pressed" or "RedButton-Exit")
        if atlasInfo(name) then texture:SetAtlas(name, false)
        else
            texture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-"..(pressed and "Down" or "Up"))
            texture:SetTexCoord(0, 1, 0, 1)
        end
    elseif style == "previous" or style == "next" then
        -- These are also the page controls used by the current retail spellbook.
        local state = not enabled and "Disabled" or (pressed and "Down" or "Up")
        texture:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-"..(style == "previous" and "PrevPage" or "NextPage").."-"..state)
        texture:SetTexCoord(0, 1, 0, 1)
    else
        local name = pressed and "common-button-square-gray-down" or "common-button-square-gray-up"
        if atlasInfo(name) then texture:SetAtlas(name, false)
        else
            texture:SetTexture("Interface\\Buttons\\UI-SquareButton-"..(pressed and "Down" or "Up"))
            texture:SetTexCoord(0, 1, 0, 1)
        end
    end
    local shade = not enabled and .55 or (hovered and not pressed and 1 or .90)
    texture:SetVertexColor(shade, shade, shade, 1)
    texture:SetDesaturated(false)
end

local function applyButton(b)
    local isClassic = S.GetTheme() == "classic"
    local enabled = b:IsEnabled()
    local pressed = enabled and b.classicPressed
    local hovered = enabled and b.classicHovered
    local icon = b.themeStyle ~= "action"
    -- Use Blizzard's shaped highlights instead of a solid rectangle over the
    -- Classic artwork. The button controls their visibility on mouse-over.
    local highlight = b:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetTexCoord(0, 1, 0, 1)
        highlight:SetBlendMode("ADD")
        if isClassic then
            local name = not icon and "128-RedButton-Highlight"
                or (b.themeStyle == "close" and "RedButton-Highlight")
            if name and atlasInfo(name) then
                highlight:SetAtlas(name, false)
            elseif not icon then
                highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
                highlight:SetTexCoord(0, .625, 0, .6875)
            elseif b.themeStyle == "close" then
                highlight:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
            else
                highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            end
            if icon then
                local size = math.min(b:GetHeight(), b:GetWidth())
                highlight:SetPoint("CENTER", b, "CENTER")
                highlight:SetSize(size, size)
            else
                highlight:SetAllPoints(b)
            end
            highlight:SetVertexColor(1, 1, 1, 1)
            highlight:SetAlpha(enabled and .85 or 0)
        else
            highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            highlight:SetAllPoints(b)
            highlight:SetVertexColor(1, .82, .50, .12)
            highlight:SetAlpha(1)
        end
    end
    b.flatArt:SetShown(not isClassic)
    b.classicArt:SetShown(isClassic)
    b.classicCenter:SetShown(isClassic and not icon)
    b.classicRight:SetShown(isClassic and not icon)
    if b.text then
        b.text:SetShown(not (isClassic and (b.themeStyle == "close" or b.themeStyle == "previous" or b.themeStyle == "next")))
        b.text:SetAlpha(enabled and 1 or .5)
        if isClassic then
            local color = hovered and {1, .94, .73} or classic.accent
            b.text:SetTextColor(color[1], color[2], color[3], 1)
        end
    end
    if icon then
        b.classicArt:ClearAllPoints(); b.classicArt:SetPoint("CENTER")
        local size = math.min(b:GetHeight(), b:GetWidth())
        b.classicArt:SetSize(size, size)
        setIcon(b.classicArt, b.themeStyle, pressed, enabled, hovered)
        return
    end

    local suffix = not enabled and "-Disabled" or (pressed and "-Pressed" or "")
    local leftName, centerName, rightName = "128-RedButton-Left"..suffix,
        "_128-RedButton-Center"..suffix, "128-RedButton-Right"..suffix
    local leftInfo, rightInfo = atlasInfo(leftName), atlasInfo(rightName)
    local native = leftInfo and rightInfo and atlasInfo(centerName)
    local height = b:GetHeight()
    -- Only the middle stretches horizontally. End caps scale with height.
    local leftWidth = native and leftInfo.width * height / leftInfo.height or height * .36
    local rightWidth = native and rightInfo.width * height / rightInfo.height or height * .36
    leftWidth = math.min(leftWidth, b:GetWidth() / 2)
    rightWidth = math.min(rightWidth, b:GetWidth() / 2)
    b.classicArt:ClearAllPoints(); b.classicArt:SetPoint("TOPLEFT"); b.classicArt:SetPoint("BOTTOMLEFT")
    b.classicArt:SetWidth(leftWidth)
    b.classicRight:ClearAllPoints(); b.classicRight:SetPoint("TOPRIGHT"); b.classicRight:SetPoint("BOTTOMRIGHT")
    b.classicRight:SetWidth(rightWidth)
    b.classicCenter:ClearAllPoints()
    b.classicCenter:SetPoint("TOPLEFT", b.classicArt, "TOPRIGHT")
    b.classicCenter:SetPoint("BOTTOMRIGHT", b.classicRight, "BOTTOMLEFT")
    local parts = {b.classicArt, b.classicCenter, b.classicRight}
    if native then
        for _, texture in ipairs(parts) do texture:SetTexCoord(0, 1, 0, 1) end
        b.classicArt:SetAtlas(leftName, false)
        b.classicCenter:SetAtlas(centerName, false)
        b.classicRight:SetAtlas(rightName, false)
    else
        local coords = {{0, .0625}, {.0625, .5625}, {.5625, .625}}
        for i, texture in ipairs(parts) do
            texture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
            texture:SetTexCoord(coords[i][1], coords[i][2], 0, .6875)
        end
    end
    for _, texture in ipairs(parts) do
        -- Neutral metal buttons fit the spellbook better than a wall of red.
        texture:SetDesaturated(true)
        local shade = not enabled and .43 or (pressed and .57 or (hovered and .84 or .72))
        texture:SetVertexColor(shade, shade * .92, shade * .78, 1)
    end
    b.classicCenter:SetHorizTile(native and true or false)
end

function S.StyleButton(b, style)
    b.themeStyle = style or "action"
    b.classicArt = b:CreateTexture(nil, "BACKGROUND")
    b.classicCenter = b:CreateTexture(nil, "BACKGROUND")
    b.classicRight = b:CreateTexture(nil, "BACKGROUND")
    -- A valid texture stays attached in both modes; nil is rejected by Forever.
    b:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    b:GetPushedTexture():SetAlpha(0)
    decorations[b] = "button"
    b:HookScript("OnMouseDown", function(self) self.classicPressed = true; applyButton(self) end)
    b:HookScript("OnMouseUp", function(self) self.classicPressed = false; applyButton(self) end)
    b:HookScript("OnEnter", function(self) self.classicHovered = true; applyButton(self) end)
    local function reset(self)
        self.classicPressed = false; self.classicHovered = false; applyButton(self)
    end
    b:HookScript("OnLeave", reset); b:HookScript("OnShow", reset)
    b:HookScript("OnEnable", applyButton); b:HookScript("OnDisable", reset)
    b:HookScript("OnSizeChanged", applyButton)
    applyButton(b)
end

local function position(object, point, x, y)
    object:ClearAllPoints(); object:SetPoint(point, x, y)
end

local function anchor(object, point, relative, relativePoint, x, y)
    object:ClearAllPoints(); object:SetPoint(point, relative, relativePoint, x or 0, y or 0)
end

local function applyBookLayout(f)
    local isClassic = S.GetTheme() == "classic"
    f.bookPaper:SetShown(isClassic)
    f.bookHeader:SetShown(isClassic)
    f.bookToolbar:SetShown(isClassic)
    f.bookSpine:SetShown(isClassic)
    f.bookClip:SetShown(isClassic)
    f.footerBar:SetShown(isClassic)
    f.tagline:SetShown(not isClassic)
    if isClassic then
        f.bookPaper:SetColorTexture(.86, .77, .58, 1)
        f.bookPaper:SetVertexColor(1, 1, 1, 1)
        if atlasInfo("spellbook-background-evergreen-right") then
            f.bookPaper:SetAtlas("spellbook-background-evergreen-right", false)
        elseif atlasInfo("QuestBG-Parchment") then
            f.bookPaper:SetAtlas("QuestBG-Parchment", false)
        end
        S.Text(f.brand, "WC Scholar")
        anchor(f.brand, "CENTER", f, "TOP", 0, -27.5); f.brand:SetFont(f.themeFont, 16, "")
        position(f.logoFrame, "TOPLEFT", 24, -42); f.logoFrame:SetSize(40, 40)
        position(f.closeButton, "TOPRIGHT", -12, -16); f.closeButton:SetSize(24, 24)
        position(f.fontMinus, "TOPLEFT", 92, -48)
        position(f.fontPlus, "TOPLEFT", 130, -48)
        position(f.settingsButton, "TOPLEFT", 178, -48)
        position(f.readButton, "TOPLEFT", 302, -48)
        position(f.count, "TOPRIGHT", -24, -58)
        position(f.catalogTitle, "TOPLEFT", 14, -27)
        position(f.search, "TOPLEFT", 20, -55)
        position(f.searchHint, "TOPLEFT", 15, -89); f.searchHint:SetFont(f.themeFont, 11, "")
        position(f.filterButton, "TOPLEFT", 15, -111)
        for i, row in ipairs(f.catalogRows) do
            position(row, "TOPLEFT", 10, -148-(i-1)*42)
            row.heading:SetFont(f.themeFont, 14, ""); row.heading:SetHeight(18)
            row.sub:SetFont(f.themeFont, 11, "")
        end
        position(f.title, "TOPLEFT", 28, -37)
        position(f.meta, "TOPLEFT", 28, -97)
        position(f.readerRule, "TOPLEFT", 28, -115)
        position(f.reader, "TOPLEFT", 28, -133)
        f.previousPage:SetSize(32, 32); f.nextPage:SetSize(32, 32)
        f.catalogPrevious:SetSize(32, 32); f.catalogNext:SetSize(32, 32)
        -- Both catalogue and reader controls share one vertical centre.
        anchor(f.catalogPrevious, "LEFT", f.footerBar, "LEFT", 10)
        anchor(f.catalogNext, "RIGHT", f.footerBar, "LEFT", 272)
        anchor(f.listPage, "CENTER", f.footerBar, "LEFT", 141)
        anchor(f.previousPage, "LEFT", f.footerBar, "LEFT", 296)
        anchor(f.nextPage, "LEFT", f.footerBar, "LEFT", 499)
        anchor(f.star, "LEFT", f.footerBar, "LEFT", 593)
        anchor(f.play, "LEFT", f.footerBar, "LEFT", 711)
        anchor(f.exportBook, "LEFT", f.footerBar, "LEFT", 793)
        anchor(f.exportAll, "LEFT", f.footerBar, "LEFT", 883)
        anchor(f.page, "CENTER", f.footerBar, "LEFT", 440)
        f.page:SetWidth(110); f.page:SetWordWrap(false)
        position(f.footerHint, "BOTTOMLEFT", 316, 23)
        f.footerHint:SetFont(f.themeFont, 11, "")
        f.footerHint:SetWidth(620); f.footerHint:SetWordWrap(false)
    else
        S.Text(f.brand, "WC SCHOLAR")
        position(f.brand, "TOPLEFT", 88, -20); f.brand:SetFont(f.themeFont, 26, "")
        position(f.logoFrame, "TOPLEFT", 20, -12); f.logoFrame:SetSize(58, 58)
        position(f.closeButton, "TOPRIGHT", -16, -17); f.closeButton:SetSize(30, 30)
        position(f.fontMinus, "TOPLEFT", 420, -42)
        position(f.fontPlus, "TOPLEFT", 458, -42)
        position(f.settingsButton, "TOPLEFT", 510, -42)
        position(f.readButton, "TOPLEFT", 638, -42)
        position(f.count, "TOPRIGHT", -65, -29)
        position(f.catalogTitle, "TOPLEFT", 14, -13)
        position(f.search, "TOPLEFT", 20, -40)
        position(f.searchHint, "TOPLEFT", 15, -72); f.searchHint:SetFont(f.themeFont, 10, "")
        position(f.filterButton, "TOPLEFT", 15, -95)
        for i, row in ipairs(f.catalogRows) do
            position(row, "TOPLEFT", 10, -136-(i-1)*44)
            row.heading:SetFont(f.themeFont, 13, ""); row.heading:SetHeight(16)
            row.sub:SetFont(f.themeFont, 10, "")
        end
        position(f.title, "TOPLEFT", 28, -23)
        position(f.meta, "TOPLEFT", 28, -83)
        position(f.readerRule, "TOPLEFT", 28, -101)
        position(f.reader, "TOPLEFT", 28, -119)
        f.previousPage:SetSize(85, 30); f.nextPage:SetSize(85, 30)
        f.catalogPrevious:SetSize(32, 30); f.catalogNext:SetSize(32, 30)
        position(f.catalogPrevious, "BOTTOMLEFT", 10, 12)
        position(f.catalogNext, "BOTTOMRIGHT", -10, 12)
        position(f.listPage, "BOTTOM", 0, 22)
        position(f.previousPage, "TOPLEFT", 312, -584)
        position(f.nextPage, "TOPLEFT", 515, -584)
        position(f.star, "TOPLEFT", 609, -584)
        position(f.play, "TOPLEFT", 727, -584)
        position(f.exportBook, "TOPLEFT", 809, -584)
        position(f.exportAll, "TOPLEFT", 899, -584)
        f.page:ClearAllPoints(); f.page:SetPoint("CENTER", f, "TOPLEFT", 456, -599)
        f.page:SetWidth(0); f.page:SetWordWrap(true)
        position(f.footerHint, "BOTTOMLEFT", 316, 15)
        f.footerHint:SetFont(f.themeFont, 10, "")
        f.footerHint:SetWidth(0); f.footerHint:SetWordWrap(true)
    end
end

function S.StyleBook(f, font)
    f.themeFont = font
    -- One continuous sheet, rather than two separately stretched quest panels.
    -- Crop the sheet to the inside of the metal border, including atlas padding.
    f.bookClip = CreateFrame("Frame", nil, f)
    f.bookClip:SetFrameLevel(f:GetFrameLevel()); f.bookClip:EnableMouse(false)
    f.bookClip:SetPoint("TOPLEFT", 18, -90); f.bookClip:SetPoint("BOTTOMRIGHT", -8, 12)
    f.bookClip:SetClipsChildren(true)
    f.bookArt = CreateFrame("Frame", nil, f.bookClip)
    f.bookArt:SetFrameLevel(f:GetFrameLevel()); f.bookArt:EnableMouse(false)
    f.bookArt:SetAllPoints()
    -- The retail atlas has transparent rounded corners. Back them with paper
    -- inside the clip so no world background shows between sheet and frame.
    f.bookBacking = f.bookArt:CreateTexture(nil, "BACKGROUND", nil, 0)
    f.bookBacking:SetAllPoints()
    f.bookBacking:SetColorTexture(.75, .54, .32, 1)
    f.bookPaper = f.bookArt:CreateTexture(nil, "BACKGROUND", nil, 1)
    -- Extend the atlas beneath the border before clipping: its transparent
    -- edge padding must not leave a view of the world along the right/bottom.
    f.bookPaper:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -84)
    f.bookPaper:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 6)
    f.footerBar = CreateFrame("Frame", nil, f)
    f.footerBar:EnableMouse(false)
    f.footerBar:SetPoint("TOPLEFT", 16, -580); f.footerBar:SetSize(928, 32)
    f.bookHeader = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.bookHeader:SetPoint("TOPLEFT", 18, -18); f.bookHeader:SetPoint("TOPRIGHT", -8, -18)
    f.bookHeader:SetHeight(19)
    if atlasInfo("_UI-Frame-TitleTileBg") then
        f.bookHeader:SetAtlas("_UI-Frame-TitleTileBg", false); f.bookHeader:SetHorizTile(true)
    else f.bookHeader:SetColorTexture(.20, .15, .09, 1) end
    f.bookToolbar = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.bookToolbar:SetPoint("TOPLEFT", 18, -37); f.bookToolbar:SetPoint("TOPRIGHT", -8, -37)
    f.bookToolbar:SetHeight(55)
    if atlasInfo("spellbook-background-evergreen-header") then
        f.bookToolbar:SetAtlas("spellbook-background-evergreen-header", false)
    else f.bookToolbar:SetColorTexture(.095, .09, .08, 1) end
    f.bookSpine = f:CreateTexture(nil, "ARTWORK")
    f.bookSpine:SetColorTexture(.34, .22, .10, .22)
    f.bookSpine:SetPoint("TOPLEFT", 304, -106); f.bookSpine:SetSize(1, 512)
    applyBookLayout(f)
end

function S.ApplyTheme()
    if S.window and S.window.bookPaper then applyBookLayout(S.window) end
    for object, binding in pairs(bindings) do apply(object, binding) end
    for object, kind in pairs(decorations) do
        if kind == "button" then applyButton(object)
        else object:SetShown(S.GetTheme() == "classic") end
    end
    if S.UpdateReaderScrollbar then S.UpdateReaderScrollbar() end
end

function S.SetTheme(theme)
    if theme ~= "modern" and theme ~= "classic" then return end
    S.db.settings.theme = theme
    S.ApplyTheme()
    if S.UpdateSettings then S.UpdateSettings() end
end
