-- PaTiGroup (party awareness): settings, member normalization, summary, target tokens. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Logic.lua", {}).Logic
end

local SECRET = setmetatable({}, { __tostring = function() return "secret" end })
local function isSecret(value) return value == SECRET end
local function never() return false end

describe("Logic.Migrate / RestoreDefaults", function()
    it("a new character gets the defaults and schema 2", function()
        local db = load().Migrate(nil)
        assert.same({ 0.75, false, false, 1, "auto", 2 },
            { db.opacity, db.locked, db.collapsed, db.scale, db.language, db.schema })
    end)

    it("the former PaTiGroup's table (schema 1, markers, note) is not taken over", function()
        local db = load().Migrate({ schema = 1, markers = { 8, 7 }, note = "x", locked = true, point = "TOP", x = 9 })
        assert.is_nil(db.markers)
        assert.is_nil(db.note)
        assert.is_nil(db.point)
        assert.is_false(db.locked)
        assert.equal(2, db.schema)
    end)

    it("a table without schema (very old or broken) also starts fresh", function()
        assert.is_nil(load().Migrate({ showPull = true }).showPull)
        assert.equal(2, load().Migrate("broken").schema)
    end)

    it("keeps saved values of schema 2 (also false) and the position", function()
        local db = load().Migrate({ schema = 2, locked = true, collapsed = true, scale = 1.25, point = "TOPLEFT", x = 5 })
        assert.same({ true, true, 1.25, "TOPLEFT", 5 }, { db.locked, db.collapsed, db.scale, db.point, db.x })
    end)

    it("Restore Defaults: settings back, position kept", function()
        local db = load().RestoreDefaults({ schema = 2, locked = true, scale = 1.5, point = "TOP", x = 3 })
        assert.same({ false, 1, "TOP", 3 }, { db.locked, db.scale, db.point, db.x })
    end)
end)

describe("Logic.Member (secret values first)", function()
    it("normalizes role and state", function()
        local Logic = load()
        local member = Logic.Member({ unit = "party1", name = "Anna", role = "HEALER", connected = true, dead = false },
            never)
        assert.same({ "party1", "Anna", "HEALER", "ALIVE" }, { member.unit, member.name, member.role, member.state })
        assert.equal("DEAD", Logic.Member({ unit = "party1", role = "TANK", connected = 1, dead = 1 }, never).state)
        assert.equal("OFFLINE", Logic.Member({ unit = "party2", connected = false, dead = true }, never).state)
    end)

    it("unknown or missing roles are NONE; a secret role is NONE, never guessed", function()
        local Logic = load()
        assert.equal("NONE", Logic.Member({ unit = "party1", role = "SOMETHING" }, never).role)
        assert.equal("NONE", Logic.Member({ unit = "party1" }, never).role)
        assert.equal("NONE", Logic.Member({ unit = "party1", role = SECRET }, isSecret).role)
    end)

    it("secret flags give no state; a secret name is passed on untouched", function()
        local member = load().Member({ unit = "party3", name = SECRET, role = "TANK", connected = SECRET,
            dead = SECRET }, isSecret)
        assert.is_nil(member.state)
        assert.equal(SECRET, member.name)
    end)
end)

describe("Logic.Summary", function()
    local function member(unit, role) return { unit = unit, role = role, name = unit } end

    it("counts roles and lists tanks and healers in group order", function()
        local summary = load().Summary({ member("player", "TANK"), member("party1", "HEALER"),
            member("party2", "DAMAGER"), member("party3", "DAMAGER"), member("party4", "NONE") })
        assert.same({ TANK = 1, HEALER = 1, DAMAGER = 2, NONE = 1 }, summary.counts)
        assert.equal("player", summary.tanks[1].unit)
        assert.equal("party1", summary.healers[1].unit)
        assert.equal(5, summary.total)
    end)

    it("you first: when you and another member tank, you are the tank", function()
        local summary = load().Summary({ member("player", "TANK"), member("party2", "TANK") })
        assert.equal("player", summary.tanks[1].unit)
        assert.equal("+1", load().MoreText(summary.tanks))
    end)

    it("no tank, no healer: empty lists", function()
        local summary = load().Summary({ member("player", "DAMAGER"), member("party1", "NONE") })
        assert.equal(0, #summary.tanks)
        assert.equal(0, #summary.healers)
        assert.is_nil(load().MoreText(summary.healers))
    end)
end)

describe("Logic.TargetOf / MarkerIndex", function()
    it("your target is 'target', everyone else's '<unit>target'", function()
        local Logic = load()
        assert.equal("target", Logic.TargetOf("player"))
        assert.equal("party2target", Logic.TargetOf("party2"))
        assert.equal("raid7target", Logic.TargetOf("raid7"))
    end)

    it("marker 1-8 only; secret, 0 and odd values are no marker", function()
        local Logic = load()
        assert.equal(8, Logic.MarkerIndex(8, never))
        assert.is_nil(Logic.MarkerIndex(0, never))
        assert.is_nil(Logic.MarkerIndex(9, never))
        assert.is_nil(Logic.MarkerIndex(nil, never))
        assert.is_nil(Logic.MarkerIndex(SECRET, isSecret))
    end)
end)
