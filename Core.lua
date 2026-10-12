local addonName, S = ...
S.version = "1.2.0"

function S.Plain(text)
    text = (text or ""):gsub("\r\n", "\n")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", "")
    text = text:gsub("<[Bb][Rr]%s*/?>", "\n")
    text = text:gsub("</[Pp]%s*>", "\n\n"):gsub("</[Hh][123]%s*>", "\n\n")
    text = text:gsub("<[Ii][Mm][Gg][^>]*>", S.T("[Abbildung]"))
    text = text:gsub("<[^>]+>", "")
    local entities = { lt = "<", gt = ">", quot = '"', apos = "'", nbsp = " " }
    text = text:gsub("&(%a+);", function(e) return entities[e] or "&"..e..";" end)
    text = text:gsub("&#(%d+);", function(n)
        n = tonumber(n)
        if n > 0 and n < 128 then return string.char(n) end
        return "&#"..n..";"
    end):gsub("&amp;", "&")
    return (text:gsub("\n[ \t]+", "\n"):gsub("\n\n\n+", "\n\n"):match("^%s*(.-)%s*$"))
end

function S.Init()
    WCScholarDB = WCScholarDB or {}
    S.db = WCScholarDB
    S.db.books = S.db.books or {}
    S.db.nextID = S.db.nextID or 1
    S.db.settings = S.db.settings or { fontSize = 18 }
    if S.db.settings.minimapHidden == nil then S.db.settings.minimapHidden = false end
    if S.db.settings.tooltips == nil then S.db.settings.tooltips = true end
    S.db.settings.minimapAngle = S.db.settings.minimapAngle or 225
    if S.db.settings.showExportButtons == nil then S.db.settings.showExportButtons = false end
    S.db.settings.language = S.db.settings.language or "auto"
    S.db.schema = 1
end

function S.PageNumbers(book)
    local numbers = {}
    for n in pairs(book.pages) do numbers[#numbers + 1] = n end
    table.sort(numbers)
    return numbers
end

function S.Complete(book)
    if not book.lastPage then return false end
    for n = 1, book.lastPage do if not book.pages[n] then return false end end
    return true
end

local function newBook(data)
    local id = tostring(S.db.nextID)
    S.db.nextID = S.db.nextID + 1
    local b = { id = id, title = data.title, creator = data.creator,
        locale = data.locale, material = data.material, pages = {},
        found = data.now, updated = data.now, zone = data.zone,
        character = data.character, bookmark = 1 }
    S.db.books[id] = b
    return b
end

-- Identity is based on title, language, author AND the exact first page.
-- Later conflicting pages fork the edition instead of overwriting collected text.
function S.Store(data)
    local b = S.session and S.db.books[S.session]
    local fresh = false
    if b and (b.title ~= data.title or b.locale ~= data.locale or b.creator ~= data.creator) then b = nil end
    if not b and data.page == 1 then
        for _, candidate in pairs(S.db.books) do
            if candidate.title == data.title and candidate.creator == data.creator
                and candidate.locale == data.locale and candidate.pages[1]
                and candidate.pages[1].raw == data.raw then
                if not b or tonumber(candidate.id) > tonumber(b.id) then b = candidate end
            end
        end
    end
    if b and ((b.pages[data.page] and b.pages[data.page].raw ~= data.raw)
        or (b.lastPage and data.page > b.lastPage)
        or (b.lastPage == data.page and data.hasNext)
        or (not data.hasNext and b.lastPage and b.lastPage ~= data.page)) then
        local previous = b
        b = newBook(data)
        for n, page in pairs(previous.pages) do
            if n < data.page then b.pages[n] = { raw = page.raw, text = page.text } end
        end
        fresh = true
    end
    if not b then b = newBook(data); fresh = true end
    S.session = b.id
    b.pages[data.page] = { raw = data.raw, text = S.Plain(data.raw) }
    b.updated = data.now
    if not data.hasNext then b.lastPage = data.page end
    return b, fresh
end

function S.ExportBook(b)
    local lines = { b.title, string.rep("=", 48),
        S.T("Fundort: %s", b.zone or S.T("Unbekannt")),
        S.T("Gesammelt von: %s", b.character or S.T("Unbekannt")),
        S.T("Status: %s", S.T(S.Complete(b) and "Vollständig" or "Unvollständig – nur besuchte Seiten")), "" }
    if b.creator ~= "" then lines[#lines + 1] = S.T("Verfasst von: %s", b.creator); lines[#lines + 1] = "" end
    local nums = S.PageNumbers(b)
    local maximum = b.lastPage or nums[#nums] or 0
    for n = 1, maximum do
        lines[#lines + 1] = S.T("--- Seite %d ---", n)
        lines[#lines + 1] = b.pages[n] and (b.pages[n].raw and S.Plain(b.pages[n].raw) or b.pages[n].text) or S.T("[Noch nicht gespeichert]")
        lines[#lines + 1] = ""
    end
    return table.concat(lines, "\n")
end

function S.ExportAll()
    local books = {}
    for _, b in pairs(S.db.books) do books[#books + 1] = b end
    table.sort(books, function(a,b) if a.title == b.title then return tonumber(a.id)<tonumber(b.id) end return a.title<b.title end)
    local text = { S.T("WC SCHOLAR · BIBLIOTHEK"), "" }
    for _, b in ipairs(books) do text[#text + 1] = S.ExportBook(b) end
    return table.concat(text, "\n\n")
end

function S.Say(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd8b777WC Scholar|r  "..text)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("ITEM_TEXT_BEGIN")
events:RegisterEvent("ITEM_TEXT_READY")
events:RegisterEvent("ITEM_TEXT_CLOSED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        S.Init()
        if S.InitIntegrations then S.InitIntegrations() end
    elseif event == "ITEM_TEXT_BEGIN" or event == "ITEM_TEXT_CLOSED" then
        S.session = nil
    elseif event == "ITEM_TEXT_READY" and S.db then
        if not ItemTextGetText or not ItemTextGetItem or not ItemTextGetPage then return end
        local raw, title = ItemTextGetText(), ItemTextGetItem()
        if type(raw) ~= "string" or raw == "" or type(title) ~= "string" then return end
        local hasNext = ItemTextHasNextPage and ItemTextHasNextPage()
        local b, fresh = S.Store({ title = title ~= "" and title or S.T("Ohne Titel"), raw = raw,
            page = math.max(1, tonumber(ItemTextGetPage()) or 1),
            hasNext = hasNext ~= nil and hasNext ~= false and hasNext ~= 0,
            creator = ItemTextGetCreator and ItemTextGetCreator() or "",
            material = ItemTextGetMaterial and ItemTextGetMaterial() or "Parchment",
            locale = GetLocale(), now = time(), zone = GetRealZoneText() or "",
            character = (UnitName("player") or "").." – "..(GetRealmName() or "") })
        if fresh then S.Say(S.T("Gesammelt: %s", b.title)) end
        if S.Refresh then S.Refresh() end
    end
end)

SLASH_WCSCHOLAR1 = "/wcscholar"
SlashCmdList.WCSCHOLAR = function(message)
    if not S.db then S.Init() end
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "settings" or message == "einstellungen" then S.ShowSettings()
    elseif message == "minimap" then
        S.db.settings.minimapHidden = not S.db.settings.minimapHidden
        S.UpdateMinimap()
    elseif message == "export" then S.ShowExport(S.ExportAll())
    elseif message == "reset" then
        if S.window then S.window:ClearAllPoints(); S.window:SetPoint("CENTER") end
        S.db.settings.x, S.db.settings.y = nil, nil
    else S.Toggle() end
end
