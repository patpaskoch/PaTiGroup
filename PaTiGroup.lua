-- PaTiGroup: party awareness. Who tanks, who heals, what the tank has targeted and its raid marker.
-- Display only, with one exception (owner 2026-10-14): a click on the tank-target line targets what the tank has
-- targeted (like /assist) — one secure button, set up out of combat; nothing is targeted, marked or cast by itself.
local addonName, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic

local DB
local testMode = false

local WIDTH, LINE, LABEL_WIDTH, MARKER = 250, 18, 72, 14
-- The tank's target stands out (owner 2026-10-14: "would have liked to see it better"): below tank and healer, taller, own panel,
-- larger name and marker.
local TARGET_LINE, TARGET_MARKER = 28, 20
-- The enemy's portrait in front (owner 2026-10-17): it reads as a unit you can click, like a target frame.
local PORTRAIT = TARGET_LINE - 2 * UI.Spacing.XS
local TARGET_LABEL_WIDTH = 56 -- narrower than the other labels: portrait and marker need the room
local PAD = UI.Spacing.MD
local MARKER_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"
local TEST = { tank = "TEST_TANK", healer = "TEST_HEALER", target = "TEST_TARGET", marker = 8 }

local function say(key, ...)
    print("|cff68caffPaTiGroup:|r " .. L[key]:format(...))
end

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end

local function addonVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(addonName, "Version") or "?"
end

-- WoW API adapter ------------------------------------------------------------------------------

-- Group units in group order: party = you first, then party1–4; raid = raid1..n (you are one of them).
local function groupUnits()
    local units, count = {}, GetNumGroupMembers and GetNumGroupMembers() or 0
    if IsInRaid and IsInRaid() then
        for index = 1, count do units[#units + 1] = "raid" .. index end
    elseif IsInGroup and IsInGroup() then
        units[1] = "player"
        for index = 1, count - 1 do units[#units + 1] = "party" .. index end
    end
    return units
end

local function readMembers()
    local members = {}
    for _, unit in ipairs(groupUnits()) do
        if Logic.Flag(UnitExists(unit), isSecret) then
            members[#members + 1] = Logic.Member({ unit = unit, name = UnitName(unit),
                role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit),
                connected = UnitIsConnected(unit), dead = UnitIsDeadOrGhost(unit) }, isSecret)
        end
    end
    return members
end

-- Window ---------------------------------------------------------------------------------------

local window = UI.CreateWindow("PaTiGroupFrame", "PaTiGroup", WIDTH,
    UI.Sizes.HeaderHeight + TARGET_LINE + LINE + 2 * PAD)
-- Not movable in combat: the tank-target click button lies over the window and can only follow it out of combat.

-- One line: muted label, optional marker icon, value (may be a secret name: SetText only), muted extra text.
local function newLine(labelKey, tooltip, height)
    local line = CreateFrame("Frame", nil, window)
    line.height = height or LINE
    line:SetSize(WIDTH - 2 * PAD, line.height)
    line.label = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
    line.label:SetPoint("LEFT")
    line.label:SetWidth(LABEL_WIDTH)
    line.label:SetJustifyH("LEFT")
    line.label:SetWordWrap(false)
    line.labelWidth = labelKey and LABEL_WIDTH or 0 -- no label: a plain message line
    if labelKey then UI.BindText(line.label, labelKey) end
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.markerSize = MARKER
    line.icon:SetSize(MARKER, MARKER)
    line.icon:SetPoint("LEFT", line.labelWidth, 0)
    line.icon:Hide()
    line.extra = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    line.extra:SetPoint("RIGHT")
    line.value = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    line.value:SetJustifyH("LEFT")
    line.value:SetWordWrap(false)
    if tooltip then
        line:EnableMouse(true)
        UI.SetTooltip(line, tooltip)
    end
    return line
end

-- Tank and healer share one line (owner 2026-10-17): two halves, each a muted label and a name. Two font strings
-- instead of one joined text, because a name may be a secret value (SetText only, never concatenated).
local function newPairLine()
    local line = CreateFrame("Frame", nil, window)
    line.height = LINE
    line:SetSize(WIDTH - 2 * PAD, LINE)
    local half = (WIDTH - 2 * PAD) / 2
    line.values, line.extras = {}, {}
    for index, key in ipairs({ "TANK", "HEALER" }) do
        local label = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
        label:SetPoint("LEFT", (index - 1) * half, 0)
        UI.BindText(label, key)
        -- Each half has its own state text ("dead", "offline", "+1") at its right end (owner 2026-10-17: the tank's
        -- death was not shown).
        local extra = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
        extra:SetPoint("RIGHT", line, "LEFT", index * half - UI.Spacing.SM, 0)
        local value = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
        value:SetPoint("LEFT", label, "RIGHT", UI.Spacing.SM, 0)
        value:SetPoint("RIGHT", extra, "LEFT", -UI.Spacing.XS, 0)
        value:SetJustifyH("LEFT")
        value:SetWordWrap(false)
        line.values[index], line.extras[index] = value, extra
    end
    return line
end

local lines = {
    message = newLine(nil),
    target = newLine("TANK_TARGET", function() return { L.TANK_TARGET, L.TIP_TANK_TARGET } end, TARGET_LINE),
    party = newPairLine(),
}
-- Tank and healer above the tank target (owner 2026-10-17); the gap sits between them.
local ORDER = { "message", "party", "target" }

-- Tank target panel: plain textures of its line (a lighter shade with an accent stripe, as PaTiHeal's heal target),
-- the name in the title font, a larger marker and a small gap to the line above.
do
    local line = lines.target
    local panel = line:CreateTexture(nil, "BACKGROUND")
    panel:SetPoint("TOPLEFT", -UI.Spacing.SM, 0)
    panel:SetPoint("BOTTOMRIGHT", UI.Spacing.SM, 0)
    UI.Paint(panel, "SetColorTexture", "PanelHover")
    local stripe = line:CreateTexture(nil, "BORDER")
    stripe:SetPoint("TOPLEFT", panel, "TOPLEFT")
    stripe:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")
    stripe:SetWidth(2)
    UI.Paint(stripe, "SetColorTexture", "Accent")
    line.value:SetFontObject(UI.Fonts.Title)
    line.markerSize = TARGET_MARKER
    line.icon:SetSize(TARGET_MARKER, TARGET_MARKER)
    lines.party.gapAfter = UI.Spacing.SM -- the target panel keeps a little room to the line above
    line.portrait = line:CreateTexture(nil, "ARTWORK")
    line.portrait:SetSize(PORTRAIT, PORTRAIT)
    line.portrait:SetPoint("LEFT")
    line.label:ClearAllPoints()
    line.label:SetPoint("LEFT", PORTRAIT + UI.Spacing.SM, 0)
    line.label:SetWidth(TARGET_LABEL_WIDTH)
    line.labelWidth = PORTRAIT + UI.Spacing.SM + TARGET_LABEL_WIDTH
    line.icon:ClearAllPoints()
    line.icon:SetPoint("LEFT", line.labelWidth, 0)
end

-- token: whose face to show (nil = none). SetPortraitTexture takes the unit token itself, no unit data is read.
local function setPortrait(token)
    local portrait = lines.target.portrait
    if token and SetPortraitTexture then SetPortraitTexture(portrait, token) end
    portrait:SetShown(token ~= nil)
end

-- value: text (plain or secret) or nil; muted: grey value; extra: { text, colour } or nil; marker: 1-8 or nil.
local function setLine(line, value, muted, extra, marker)
    line.icon:SetTexture(marker and MARKER_TEXTURE:format(marker) or nil)
    line.icon:SetShown(marker ~= nil)
    line.value:ClearAllPoints()
    line.value:SetPoint("LEFT", line.labelWidth + (marker and line.markerSize + UI.Spacing.SM or 0), 0)
    line.value:SetPoint("RIGHT", line.extra, "LEFT", -UI.Spacing.SM, 0)
    line.value:SetText(value)
    line.value:SetTextColor(UI.Color(muted and "TextMuted" or "Text"))
    line.extra:SetText(extra and extra[1] or "")
    line.extra:SetTextColor(UI.Color(extra and extra[2] or "TextMuted"))
end

-- Shows the given lines (top to bottom) and sizes the window. Plain frames: also fine in combat.
local function showLines(shown)
    local y = UI.Sizes.HeaderHeight + UI.Spacing.SM
    for _, key in ipairs(ORDER) do
        local line = lines[key]
        line:SetShown(shown[key] == true)
        if shown[key] then
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", PAD, -y)
            line.top = y -- from the window top (the tank-target click button is placed from it)
            y = y + line.height + (line.gapAfter or 0)
        end
    end
    window:SetHeight(DB.collapsed and UI.Sizes.HeaderHeight or y + PAD)
end

local function stateExtra(member)
    if member.state == "DEAD" then return { L.STATE_DEAD, "Danger" } end
    if member.state == "OFFLINE" then return { L.STATE_OFFLINE, "Danger" } end
    return nil
end

local function moreExtra(list)
    local more = Logic.MoreText(list)
    return more and { more, "TextMuted" } or nil
end

-- Tank | Healer line. member nil = nobody with that role (muted "-"); extras = { tank's, healer's }: state or "+n".
local function paintParty(tank, healer, extras)
    local line = lines.party
    for index, member in ipairs({ tank or false, healer or false }) do
        local value, extra = line.values[index], extras and extras[index]
        value:SetText(member and member.name or L.NOBODY_SHORT)
        value:SetTextColor(UI.Color(member and "Text" or "TextMuted"))
        line.extras[index]:SetText(extra and extra[1] or "")
        line.extras[index]:SetTextColor(UI.Color(extra and extra[2] or "TextMuted"))
    end
end

-- The tank's target: name, marker and portrait read straight from the token (secret values only reach SetText).
local function paintTarget(tank)
    if not tank then
        setPortrait(nil)
        setLine(lines.target, L.NO_TANK, true)
        return
    end
    local token = Logic.TargetOf(tank.unit)
    if Logic.Flag(UnitExists(token), isSecret) ~= true then
        setPortrait(nil)
        setLine(lines.target, L.NO_TARGET, true)
        return
    end
    local marker = Logic.MarkerIndex(GetRaidTargetIndex and GetRaidTargetIndex(token), isSecret)
    setPortrait(token)
    setLine(lines.target, UnitName(token), false, nil, marker)
end

local summary -- last Logic.Summary (nil when solo); UNIT_TARGET uses it to repaint only the target line

local function paintLines()
    if not DB then return end
    window:SetTestMode(testMode)
    if DB.collapsed then
        showLines({})
        return
    end
    if testMode then
        paintParty({ name = L[TEST.tank] }, { name = L[TEST.healer] })
        setPortrait("player") -- any face will do for the example
        setLine(lines.target, L[TEST.target], false, nil, TEST.marker)
        showLines({ party = true, target = true })
        return
    end
    local members = readMembers()
    if #members == 0 then
        summary = nil
        setLine(lines.message, L.SOLO, true)
        showLines({ message = true })
        return
    end
    summary = Logic.Summary(members)
    local tank, healer = summary.tanks[1], summary.healers[1]
    paintParty(tank, healer, {
        tank and (stateExtra(tank) or moreExtra(summary.tanks)),
        healer and (stateExtra(healer) or moreExtra(summary.healers)),
    })
    paintTarget(tank)
    showLines({ party = true, target = true })
end

-- Tank-target click (owner 2026-10-14) ------------------------------------------------------------
-- One SecureActionButton over the tank-target line: type "target", unit "<tank>target" (party1target …). The token is
-- read at click time, so in combat a click takes whatever the tank has targeted right then — one click, one target,
-- like /assist. Secure attributes and position change only out of combat. The button is not a child of the window
-- (the display-only window stays free in combat); it is laid over the line in screen coordinates instead.
local targetButton = CreateFrame("Button", "PaTiGroupTankTargetButton", UIParent, "SecureActionButtonTemplate")
targetButton:RegisterForClicks("AnyUp", "AnyDown")
targetButton:Hide()
local targetHighlight = targetButton:CreateTexture(nil, "HIGHLIGHT")
targetHighlight:SetAllPoints()
UI.Paint(targetHighlight, "SetColorTexture", "Accent", 0.12)
UI.SetTooltip(targetButton, function() return { L.TANK_TARGET, L.TIP_TANK_TARGET, L.TIP_TANK_TARGET_CLICK } end)

-- The tank whose target a click takes: the first tank of the group, never you (your own target needs no button).
local function clickTank()
    local tank = not testMode and summary and summary.tanks[1]
    if not tank or tank.unit == "player" then return nil end
    if UnitIsUnit and Logic.Flag(UnitIsUnit(tank.unit, "player"), isSecret) == true then return nil end -- raid: you
    return tank
end

local function placeTargetButton()
    if InCombatLockdown() then return end -- PLAYER_REGEN_ENABLED repaints and places it again
    local line, tank = lines.target, clickTank()
    local left, top = window:GetLeft(), window:GetTop()
    if not tank or not DB or DB.collapsed or not window:IsShown() or not line:IsShown() or not left or not top then
        targetButton:SetAttribute("type1", nil)
        targetButton:SetAttribute("unit", nil)
        targetButton:Hide()
        return
    end
    local ratio = window:GetEffectiveScale() / UIParent:GetEffectiveScale()
    targetButton:ClearAllPoints()
    targetButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (left + PAD) * ratio, (top - line.top) * ratio)
    targetButton:SetSize(line:GetWidth() * ratio, line.height * ratio)
    targetButton:SetFrameStrata(window:GetFrameStrata())
    targetButton:SetFrameLevel(window:GetFrameLevel() + 10)
    targetButton:SetAttribute("type1", "target")
    targetButton:SetAttribute("unit", Logic.TargetOf(tank.unit))
    targetButton:Show()
end

local function paint()
    paintLines()
    placeTargetButton()
end
-- Dragging the window: the button does not follow while moving; it is laid over the line again where it stops.
window.header:HookScript("OnDragStart", function() if not InCombatLockdown() then targetButton:Hide() end end)
window.header:HookScript("OnDragStop", function() placeTargetButton() end)

-- Settings -------------------------------------------------------------------------------------

local modal

local function buildSettings()
    modal = UI.CreateModal("PaTiGroupSettings", function() return "PaTiGroup " .. L.SETTINGS end, 380)
    local scales = {}
    for _, scale in ipairs(Logic.SCALES) do
        scales[#scales + 1] = { value = scale, text = function() return ("%d %%"):format(scale * 100 + 0.5) end }
    end
    modal:AddSection("GENERAL")
    modal:AddRow("LANGUAGE", UI.CreateLanguageDropdown(modal, DB, 170))
    modal:AddRow("SCALE", UI.CreateDropdown(modal, 170, {
        items = function() return scales end,
        get = function() return DB.scale end,
        set = function(scale) DB.scale = scale; window:SetScale(scale); placeTargetButton() end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "LOCK_WINDOW", {
        get = function() return window:IsLocked() end,
        set = function(locked) window:SetLocked(locked) end,
    }))
    UI.AddWindowSettings(modal, window) -- panel opacity (PaTiShared)
    modal:Finish(function()
        Logic.RestoreDefaults(DB)
        window:ApplyTheme() -- Restore Defaults: theme back to default
        window:ApplyOpacity()
        UI.SetLanguage(DB.language)
        window:SetLocked(DB.locked)
        window:SetScale(DB.scale)
        paint()
    end)
end

local function openSettings()
    if not modal then buildSettings() end
    modal:Show()
end

-- Commands -------------------------------------------------------------------------------------

local function toggleTestMode()
    testMode = not testMode
    paint()
end

-- Collapse and hide change what lies under the tank-target click button: out of combat only.
local function toggleCollapsed()
    if InCombatLockdown() then say("COMBAT_LOCKED"); return end
    DB.collapsed = not DB.collapsed
    paint()
end

local function setShown(shown, quiet)
    if InCombatLockdown() then
        if not quiet then say("COMBAT_LOCKED") end
        return false
    end
    window:SetShown(shown)
    placeTargetButton()
    if not shown and not quiet then say("HIDDEN_HINT") end
    return true
end

-- Optional PaTiSuite control panel: the same rules as the commands, without chat lines (false = not possible now).
window.suiteSetShown = function(shown) return setShown(shown, true) end

local function resetPosition()
    DB.point, DB.relativePoint, DB.x, DB.y = nil, nil, nil, nil
    window:Attach(DB, -330, 20)
    placeTargetButton()
end

local function printDebug()
    local version, build, _, interface = GetBuildInfo()
    print("|cff68caffPaTiGroup Debug:|r")
    for _, line in ipairs({
        ("Addon %s %s · PaTiShared UI %s"):format(addonName, addonVersion(), tostring(UI.VERSION)),
        ("WoW %s (build %s, interface %s) · locale %s · UI language %s"):format(tostring(version), tostring(build),
            tostring(interface), GetLocale(), UI.GetLanguage()),
        ("APIs: UnitGroupRolesAssigned %s · GetRaidTargetIndex %s · issecretvalue %s · test mode %s"):format(
            UnitGroupRolesAssigned and "yes" or "no", GetRaidTargetIndex and "yes" or "no",
            issecretvalue and "yes" or "no", testMode and "on" or "off"),
    }) do print("  " .. line) end
    for _, member in ipairs(readMembers()) do
        local token = Logic.TargetOf(member.unit)
        local name = member.name
        if isSecret(name) then name = "(secret)" end
        print(("  %s %s · role %s · state %s · target %s exists %s"):format(member.unit, tostring(name), member.role,
            tostring(member.state), token, tostring(Logic.Flag(UnitExists(token), isSecret))))
    end
end

local COMMANDS = {
    [""] = function() setShown(not window:IsShown()) end,
    toggle = function() setShown(not window:IsShown()) end,
    show = function() setShown(true) end,
    hide = function() setShown(false) end,
    test = toggleTestMode,
    lock = function() window:SetLocked(true) end,
    unlock = function() window:SetLocked(false) end,
    reset = resetPosition,
    settings = openSettings,
    debug = printDebug,
    version = function() say("VERSION", addonVersion()) end,
}

SLASH_PATIGROUP1 = "/patigroup"
SLASH_PATIGROUP2 = "/pg"
SLASH_PATIGROUP3 = "/ptg"
SlashCmdList.PATIGROUP = function(message)
    local command = COMMANDS[(message or ""):match("^%s*(.-)%s*$"):lower()]
    if command and DB then command() else say("HELP") end
end

window:SetMenu(function()
    if not DB then return {} end
    return {
        { text = "SETTINGS", onClick = openSettings },
        { text = window:IsLocked() and "UNLOCK" or "LOCK", onClick = function() window:SetLocked(not window:IsLocked()) end },
        { text = DB.collapsed and "EXPAND" or "COLLAPSE", onClick = toggleCollapsed },
        { text = "TEST_MODE", checked = testMode, onClick = toggleTestMode },
        { text = "HIDE", onClick = function() setShown(false) end },
    }
end)

-- Events ---------------------------------------------------------------------------------------
-- Roster, roles, targets and markers change rarely: a full repaint is cheap. UNIT_TARGET and the health/connection
-- events come for many units; they repaint only when the unit matters (the tank, a healer).

-- In a raid you are "raidN", but your own unit events arrive as "player": compare through UnitIsUnit then.
local function sameUnit(token, eventUnit)
    if token == eventUnit then return true end
    return eventUnit == "player" and UnitIsUnit ~= nil and Logic.Flag(UnitIsUnit(token, "player"), isSecret) == true
end

local function isTank(unit)
    return summary ~= nil and summary.tanks[1] ~= nil and sameUnit(summary.tanks[1].unit, unit)
end

local function isHealer(unit)
    for _, healer in ipairs(summary and summary.healers or {}) do
        if sameUnit(healer.unit, unit) then return true end
    end
    return false
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_TARGET_CHANGED",
    "UNIT_TARGET", "RAID_TARGET_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_HEALTH", "UNIT_NAME_UPDATE",
    "PLAYER_REGEN_ENABLED" }) do -- after combat: the tank-target click button follows roster and window again
    events:RegisterEvent(event)
end
for _, event in ipairs({ "PLAYER_ROLES_ASSIGNED", "ROLE_CHANGED_INFORM" }) do
    pcall(events.RegisterEvent, events, event) -- not in every client generation
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        PaTiGroupDB = Logic.Migrate(PaTiGroupDB)
        DB = PaTiGroupDB
        UI.SetLanguage(DB.language)
        window:Attach(DB, -330, 20)
        window:SetScale(DB.scale)
        say("LOADED")
    elseif not DB or testMode then
        return
    elseif event == "UNIT_TARGET" then
        if not DB.collapsed and isTank(unit) then paintTarget(summary.tanks[1]) end
        return
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Your own target: in a raid you are "raidN", so any tank's target line is simply re-read (one line, cheap).
        if not DB.collapsed and summary and summary.tanks[1] then paintTarget(summary.tanks[1]) end
        return
    elseif event == "UNIT_HEALTH" or event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" or event == "UNIT_NAME_UPDATE" then
        if not (isHealer(unit) or isTank(unit)) then return end -- hot path: other units are ignored
    end
    paint()
end)
UI.OnLanguageChanged(paint)
UI.OnThemeChanged(paint) -- state colours follow the theme (static ones repaint themselves, UI.Paint)
