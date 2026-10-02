-- PaTiGroup: party awareness — saved settings and the group summary, no WoW API calls (tests/logic_spec.lua).
-- Display only: who tanks, who heals, what the tank targets. Nothing here marks, targets or decides anything.
local _, ns = ...
local Logic = {}
ns.Logic = Logic

-- Schema 1 was the PaTiGroupDB of the former PaTiGroup (now PaTiLead: markers, note, …). It is never read.
Logic.SCHEMA = 2
Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }

-- Position (point, relativePoint, x, y) is written by the PaTiShared window, not listed here.
Logic.DEFAULTS = {
    opacity = 0.75, -- panel body opacity (PaTiShared window; 0.3–1)
    locked = false,
    collapsed = false,
    scale = 1,
    language = "auto",
}

-- A table without schema 2 belongs to the former PaTiGroup (or is broken): start fresh, nothing is taken over
-- (pre-release, owner decision 2026-10-02). Otherwise missing values are filled, saved ones (also false) kept.
function Logic.Migrate(db)
    if type(db) ~= "table" or type(db.schema) ~= "number" or db.schema < Logic.SCHEMA then db = {} end
    for key, value in pairs(Logic.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": settings back, position kept.
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    return db
end

-- Secret-value rule (AGENTS.md §8): check readability FIRST, compare or test only afterwards.
-- isSecret is injected (issecretvalue in WoW), so these stay pure and testable.

-- A yes/no API flag: true / false for true / 1 / false / nil (older APIs return 1/nil), nil when secret.
function Logic.Flag(value, isSecret)
    if isSecret(value) then return nil end
    return value == true or value == 1
end

-- A raid target index 1-8, or nil (no marker, unreadable or unexpected).
function Logic.MarkerIndex(value, isSecret)
    if isSecret(value) then return nil end
    if type(value) == "number" and value >= 1 and value <= 8 then return value end
    return nil
end

-- "TANK" | "HEALER" | "DAMAGER", or "NONE" for no, unreadable or unknown role.
function Logic.Role(value, isSecret)
    if isSecret(value) then return "NONE" end
    if value == "TANK" or value == "HEALER" or value == "DAMAGER" then return value end
    return "NONE"
end

-- raw: { unit, name, role, connected, dead } straight from the API. Returns { unit, name, role, state }:
-- state "OFFLINE" | "DEAD" | "ALIVE", or nil when the flags are unreadable (not guessed). The name is passed on
-- untouched — it may be secret and only ever goes to SetText.
function Logic.Member(raw, isSecret)
    local member = { unit = raw.unit, name = raw.name, role = Logic.Role(raw.role, isSecret) }
    local connected, dead = Logic.Flag(raw.connected, isSecret), Logic.Flag(raw.dead, isSecret)
    if connected == false then member.state = "OFFLINE"
    elseif dead == true then member.state = "DEAD"
    elseif connected == true and dead == false then member.state = "ALIVE" end
    return member
end

-- members: Logic.Member list in group order (party: you first). Returns { tanks, healers, counts, total }.
-- The first tank in that order is "the" tank — you, if you are a tank yourself.
function Logic.Summary(members)
    local summary = { tanks = {}, healers = {}, counts = { TANK = 0, HEALER = 0, DAMAGER = 0, NONE = 0 },
        total = #members }
    for _, member in ipairs(members) do
        summary.counts[member.role] = summary.counts[member.role] + 1
        if member.role == "TANK" then summary.tanks[#summary.tanks + 1] = member end
        if member.role == "HEALER" then summary.healers[#summary.healers + 1] = member end
    end
    return summary
end

-- Unit token of the target of `unit`: your own target is "target", everyone else's "<unit>target"
-- (party1target, raid7target).
function Logic.TargetOf(unit)
    if unit == "player" then return "target" end
    return unit .. "target"
end

-- "+2" for the members after the first one of a role, or nil.
function Logic.MoreText(list)
    if #list > 1 then return "+" .. (#list - 1) end
    return nil
end
