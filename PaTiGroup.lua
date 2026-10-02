-- PaTiGroup: party awareness. Who tanks, who heals, what the tank has targeted and its raid marker.
-- Display only — no secure frames: nothing is targeted, marked or cast, so the window may update in combat.
local addonName, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic

local DB
local testMode = false

local WIDTH, LINE, LABEL_WIDTH, MARKER = 250, 18, 72, 14
local PAD = UI.Spacing.MD
local MARKER_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"
local TEST = { tank = "TEST_TANK", healer = "TEST_HEALER", target = "TEST_TARGET", marker = 8,
    counts = { TANK = 1, HEALER = 1, DAMAGER = 3, NONE = 0 } }

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

local window = UI.CreateWindow("PaTiGroupFrame", "PaTiGroup", WIDTH, UI.Sizes.HeaderHeight + 4 * LINE + 2 * PAD)

-- One line: muted label, optional marker icon, value (may be a secret name: SetText only), muted extra text.
local function newLine(labelKey, tooltip)
    local line = CreateFrame("Frame", nil, window)
    line:SetSize(WIDTH - 2 * PAD, LINE)
    line.label = line:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
    line.label:SetPoint("LEFT")
    line.label:SetWidth(LABEL_WIDTH)
    line.label:SetJustifyH("LEFT")
    line.label:SetWordWrap(false)
    line.labelWidth = labelKey and LABEL_WIDTH or 0 -- no label: a plain message line
    if labelKey then UI.BindText(line.label, labelKey) end
    line.icon = line:CreateTexture(nil, "ARTWORK")
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

local lines = {
    message = newLine(nil),
    tank = newLine("TANK"),
    healer = newLine("HEALER"),
    target = newLine("TANK_TARGET", function() return { L.TANK_TARGET, L.TIP_TANK_TARGET } end),
    roles = newLine("ROLES", function() return { L.ROLES, L.TIP_ROLES_SOURCE } end),
}
local ORDER = { "message", "tank", "healer", "target", "roles" }

-- value: text (plain or secret) or nil; muted: grey value; extra: { text, colour } or nil; marker: 1-8 or nil.
local function setLine(line, value, muted, extra, marker)
    line.icon:SetTexture(marker and MARKER_TEXTURE:format(marker) or nil)
    line.icon:SetShown(marker ~= nil)
    line.value:ClearAllPoints()
    line.value:SetPoint("LEFT", line.labelWidth + (marker and MARKER + UI.Spacing.SM or 0), 0)
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
            y = y + LINE
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

local function rolesText(counts)
    local text = L.ROLES_TEXT:format(counts.TANK, counts.HEALER, counts.DAMAGER)
    if counts.NONE > 0 then text = text .. " · " .. L.ROLES_UNSET:format(counts.NONE) end
    return text
end

-- The tank's target: name and marker read straight from the token (secret values only reach SetText).
local function paintTarget(tank)
    if not tank then
        setLine(lines.target, L.NO_TANK, true)
        return
    end
    local token = Logic.TargetOf(tank.unit)
    if Logic.Flag(UnitExists(token), isSecret) ~= true then
        setLine(lines.target, L.NO_TARGET, true)
        return
    end
    local marker = Logic.MarkerIndex(GetRaidTargetIndex and GetRaidTargetIndex(token), isSecret)
    setLine(lines.target, UnitName(token), false, nil, marker)
end

local summary -- last Logic.Summary (nil when solo); UNIT_TARGET uses it to repaint only the target line

local function paint()
    if not DB then return end
    window:SetTestMode(testMode)
    if DB.collapsed then
        showLines({})
        return
    end
    if testMode then
        setLine(lines.tank, L[TEST.tank])
        setLine(lines.healer, L[TEST.healer])
        setLine(lines.target, L[TEST.target], false, nil, TEST.marker)
        setLine(lines.roles, rolesText(TEST.counts))
        showLines({ tank = true, healer = true, target = true, roles = true })
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
    if tank then setLine(lines.tank, tank.name, false, moreExtra(summary.tanks)) else setLine(lines.tank, L.NOBODY, true) end
    if healer then
        setLine(lines.healer, healer.name, false, stateExtra(healer) or moreExtra(summary.healers))
    else
        setLine(lines.healer, L.NOBODY, true)
    end
    paintTarget(tank)
    setLine(lines.roles, rolesText(summary.counts))
    showLines({ tank = true, healer = true, target = true, roles = true })
end

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
        set = function(scale) DB.scale = scale; window:SetScale(scale) end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "LOCK_WINDOW", {
        get = function() return window:IsLocked() end,
        set = function(locked) window:SetLocked(locked) end,
    }))
    UI.AddWindowSettings(modal, window) -- panel opacity (PaTiShared)
    modal:Finish(function()
        Logic.RestoreDefaults(DB)
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

local function toggleCollapsed()
    DB.collapsed = not DB.collapsed
    paint()
end

local function setShown(shown, quiet) -- no secure frames: fine in combat
    window:SetShown(shown)
    if not shown and not quiet then say("HIDDEN_HINT") end
    return true
end

-- Optional PaTiSuite control panel: the same rules as the commands, without chat lines.
window.suiteSetShown = function(shown) return setShown(shown, true) end

local function resetPosition()
    DB.point, DB.relativePoint, DB.x, DB.y = nil, nil, nil, nil
    window:Attach(DB, -330, 20)
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
    "UNIT_TARGET", "RAID_TARGET_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_HEALTH", "UNIT_NAME_UPDATE" }) do
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
