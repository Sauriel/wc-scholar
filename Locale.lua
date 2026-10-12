local _, S = ...
local en = {
    ["TEXTEXPORT"] = "TEXT EXPORT",
    ["Strg+A · Strg+C · im Texteditor einfügen und als .txt speichern"] = "Ctrl+A · Ctrl+C · paste into a text editor and save as .txt",
    ["Schließen"] = "Close",
    ["Deine Bibliothek wartet."] = "Your library awaits.",
    ["Geschichten bewahren · Azeroth entdecken"] = "Preserve stories · discover Azeroth",
    ["Öffne ein Buch, eine Notiz oder einen Brief im Spiel.\n\nWC Scholar bewahrt jede gelesene Seite hier für dich auf. Blättere mehrseitige Bücher einmal vollständig durch.\n\nLinks findest du deine Sammlung. Suche nach Titeln, Fundorten oder Textstellen und markiere Lieblingsstücke als Favoriten."] = "Open a book, note or letter in the game.\n\nWC Scholar keeps every page you read here. Browse through every page of a multi-page book once.\n\nYour collection is on the left. Search titles, locations or passages and mark your favourites.",
    ["Noch kein Werk ausgewählt"] = "No book selected",
    ["Favorit"] = "Favourite",
    ["Vollständig"] = "Complete",
    ["Unvollständig"] = "Incomplete",
    ["Diese Seite wurde noch nicht gespeichert."] = "This page has not been collected yet.",
    ["Favorit: ja"] = "Favourite: yes",
    ["Favorit: nein"] = "Favourite: no",
    ["D I E  G E S C H I C H T E N  A Z E R O T H S"] = "T H E  S T O R I E S  O F  A Z E R O T H",
    ["KATALOG"] = "CATALOGUE",
    ["Suche in Titel, Text und Fundort"] = "Search titles, text and locations",
    ["Alle Werke"] = "All books",
    ["Nur Favoriten"] = "Favourites only",
    ["< Zurück"] = "< Previous",
    ["Weiter >"] = "Next >",
    ["TXT: Werk"] = "TXT: Book",
    ["Alle"] = "All",
    ["Gelesene Seiten werden automatisch gesammelt. Deine Leseposition bleibt erhalten."] = "Pages are collected as you read. Your reading position is saved.",
    ["Einstellungen"] = "Settings",
    ["EINSTELLUNGEN"] = "SETTINGS",
    ["Minimap-Button anzeigen"] = "Show minimap button",
    ["Sammelstatus in Tooltips anzeigen"] = "Show collection status in tooltips",
    ["Minimap: Linksklick öffnet die Bibliothek.\nRechtsklick öffnet Einstellungen. Ziehen verschiebt den Button."] = "Minimap: left-click opens your library.\nRight-click opens settings. Drag to move the button.",
    ["Exportbuttons anzeigen"] = "Show export buttons",
    ["Sprache"] = "Language",
    ["Automatisch"] = "Automatic",
    ["Vollständig gesammelt"] = "Fully collected",
    ["Gesammelt – Seiten fehlen"] = "Collected – pages missing",
    ["Mindestens eine Fassung vollständig"] = "At least one edition complete",
    ["Linksklick: Bibliothek"] = "Left-click: Library",
    ["Rechtsklick: Einstellungen"] = "Right-click: Settings",
    ["Ziehen: Position ändern"] = "Drag: Change position",
    ["Fundort: %s"] = "Location: %s",
    ["Gesammelt von: %s"] = "Collected by: %s",
    ["Status: %s"] = "Status: %s",
    ["Unbekannt"] = "Unknown",
    ["Unvollständig – nur besuchte Seiten"] = "Incomplete – visited pages only",
    ["Verfasst von: %s"] = "Written by: %s",
    ["--- Seite %d ---"] = "--- Page %d ---",
    ["[Noch nicht gespeichert]"] = "[Not collected yet]",
    ["WC SCHOLAR · BIBLIOTHEK"] = "WC SCHOLAR · LIBRARY",
    ["Ohne Titel"] = "Untitled",
    ["Gesammelt: %s"] = "Collected: %s",
    ["%s  ·  %d Seite(n)  ·  %s"] = "%s  ·  %d page(s)  ·  %s",
    ["Seite %d / %s"] = "Page %d / %s",
    ["%d gesammelte Werke"] = "%d collected books",
    ["%d Treffer · %d / %d"] = "%d results · %d / %d",
    ["%d Seite(n) · %s"] = "%d page(s) · %s",
    ["Aktuell: %s"] = "Current: %s",
    ["[Abbildung]"] = "[Illustration]",
}

function S.GetLanguage()
    local language = S.db and S.db.settings.language or "auto"
    if language == "auto" then language = GetLocale() end
    return language == "deDE" and "deDE" or "enUS"
end

function S.T(key, ...)
    local text = S.GetLanguage() == "deDE" and key or (en[key] or key)
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end

local bindings = setmetatable({}, {__mode = "k"})
function S.Text(widget, key, ...)
    bindings[widget] = { key = key, args = {...} }
    widget:SetText(S.T(key, ...))
end

function S.SetLanguage(language)
    if language ~= "auto" and language ~= "deDE" and language ~= "enUS" then return end
    S.db.settings.language = language
    for widget, binding in pairs(bindings) do
        widget:SetText(S.T(binding.key, unpack(binding.args)))
    end
    if S.Refresh then S.Refresh() end
    if S.UpdateSettings then S.UpdateSettings() end
    if S.exportWindow then S.exportWindow:Hide() end
end
