-- Offline checks: execute HideBlizzard with client-specific frame names.
local root = arg[1] or "PitBull4/"
local passed = 0
local function check(condition, message)
    assert(condition, message)
    passed = passed + 1
end

local function frame()
    local value = { shown = true, unregisters = 0, hooks = {}, show_hooks = {} }
    function value:UnregisterAllEvents() self.unregisters = self.unregisters + 1 end
    function value:HookScript(event, callback)
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], callback)
    end
    function value:Hide() self.shown = false end
    function value:Show()
        self.shown = true
        for _, callback in ipairs(self.hooks.OnShow or {}) do callback(self) end
        for _, callback in ipairs(self.show_hooks) do callback(self) end
    end
    function value:SetParent(parent) self.parent = parent end
    return value
end

local function fixture(classic, expansion, globals, options)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.LE_EXPANSION_CATACLYSM = 3
    env.ClassicExpansionAtLeast = function(level) return expansion >= level end
    local errors, queue, notices, registered = {}, {}, {}, {}
    env.geterrorhandler = function()
        return function(message) errors[#errors + 1] = message end
    end
    env.CreateFrame = frame
    env.UnregisterUnitWatch = function(value) value.unwatched = true end
    env.hooksecurefunc = function(value, method, callback)
        assert(method == "Show", "unexpected secure hook")
        value.show_hooks[#value.show_hooks + 1] = callback
    end
    env.C_UI = { Reload = function() end }
    env.InCombatLockdown = function() return env.in_combat end
    env.LibStub = function()
        return { NotifyChange = function() notices[#notices + 1] = "options" end }
    end
    local module = {}
    function module:SetModuleType() end
    function module:SetName() end
    function module:SetDescription() end
    function module:SetDefaults(_, defaults)
        self.db = { profile = { global = {} } }
        for name in pairs(defaults) do self.db.profile.global[name] = false end
        for name, enabled in pairs(options or { runebar = true }) do
            self.db.profile.global[name] = enabled
        end
    end
    function module:SetGlobalOptionsFunction(callback) self.options = callback end
    function module:IsEnabled() return true end
    function module:RegisterEvent(event) registered[event] = true end
    function module:Print(message) notices[#notices + 1] = message end
    env.PitBull4 = {
        DEBUG = true,
        wow_classic = classic,
        L = setmetatable({}, { __index = function(_, key) return key end }),
        NewModule = function() return module end,
        OutOfCombatWrapper = function(_, callback)
            return function(...)
                if env.in_combat then
                    local values = { ... }
                    local count = select("#", ...)
                    queue[#queue + 1] = function()
                        callback((table.unpack or unpack)(values, 1, count))
                    end
                else
                    return callback(...)
                end
            end
        end,
    }
    for name, value in pairs(globals or {}) do env[name] = value end
    local path = root .. "Modules/HideBlizzard/HideBlizzard.lua"
    local chunk, message
    if _VERSION == "Lua 5.1" then
        chunk, message = loadfile(path)
        if chunk then setfenv(chunk, env) end
    else
        chunk, message = loadfile(path, "t", env)
    end
    assert(chunk, message)
    chunk()
    local function leave_combat()
        env.in_combat = false
        local pending = queue
        queue = {}
        for _, callback in ipairs(pending) do callback() end
    end
    return module, env, errors, notices, registered, leave_combat
end

local function hidden_once(value, message)
    check(not value.shown, message .. ": hidden")
    check(value.unregisters == 1, message .. ": events disabled once")
    check(#(value.hooks.OnShow or {}) == 1, message .. ": one visibility hook")
    value:Show()
    check(not value.shown, message .. ": stays hidden when shown again")
end

-- Reproduce build 70032: indexes 3-6 of the original resource list are nil.
local rune, warlock, monk, paladin = frame(), frame(), frame(), frame()
local module, env, errors, notices, registered = fixture(true, 4, {
    RuneFrame = rune, WarlockPowerFrame = warlock,
    MonkHarmonyBar = monk, PaladinPowerBar = paladin,
})
module:OnEnable()
check(#errors == 0, "Mists optional frames must not generate errors")
check(registered.ADDON_LOADED, "existing addon-load event remains registered")
hidden_once(rune, "Mists runes")
hidden_once(warlock, "Mists warlock resources")
hidden_once(monk, "Mists monk chi")
hidden_once(paladin, "Mists paladin holy power")
module:OnProfileChanged()
module:OnEnable()
check(#errors == 0, "profile refresh does not report missing optional frames")
check(monk.unregisters == 1 and paladin.unregisters == 1,
    "profile refresh does not add duplicate class-bar hooks")
module.db.profile.global.runebar = false
module:OnProfileChanged()
check(#notices == 2, "showing already hidden frames retains the reload notice")

-- Sparse resource sets and clients without expansion class bars are valid.
for _, expansion in ipairs({ 0, 1, 2, 3, 4 }) do
    local sparse, _, captured = fixture(true, expansion)
    sparse:OnEnable()
    check(#captured == 0, "absent Classic resource frames are optional")
end

-- Retail and Camelot keep native names; PaladinPowerBar is a mixin there.
for _, label in ipairs({ "Retail", "Camelot" }) do
    local names = { "RuneFrame", "WarlockPowerFrame", "MonkHarmonyBarFrame",
        "PaladinPowerBarFrame", "MageArcaneChargesFrame", "EssencePlayerFrame" }
    local resources = { PaladinPowerBar = {} }
    for _, name in ipairs(names) do resources[name] = frame() end
    local modern, _, captured = fixture(false, 11, resources)
    modern:OnEnable()
    check(#captured == 0, label .. " optional-resource initialization")
    for _, name in ipairs(names) do hidden_once(resources[name], label .. " " .. name) end
    resources.PaladinPowerBarFrame = nil
    local absent, _, missing_errors = fixture(false, 11, resources)
    absent:OnEnable()
    check(#missing_errors == 0, label .. " does not treat a resource mixin as a frame")
end

-- Backported modern names take precedence over Classic fallback names.
local modern_monk, legacy_monk = frame(), frame()
local modern_paladin, legacy_paladin = frame(), frame()
local aliases = fixture(true, 4, {
    MonkHarmonyBarFrame = modern_monk, MonkHarmonyBar = legacy_monk,
    PaladinPowerBarFrame = modern_paladin, PaladinPowerBar = legacy_paladin,
})
aliases:OnEnable()
hidden_once(modern_monk, "preferred monk alias")
hidden_once(modern_paladin, "preferred paladin alias")
check(legacy_monk.shown and legacy_paladin.shown, "fallback names are not used twice")

-- The general frame helper also accepts absent optional child frames.
local target, casting = frame(), frame()
local optional, _, optional_errors = fixture(true, 4, {
    TargetFrame = target, PlayerCastingBarFrame = casting,
}, { target = true, focus = true, castbar = true })
local original_show = casting.Show
optional:OnEnable()
check(#optional_errors == 0, "missing focus, combo, ToT, and pet cast frames are optional")
check(target.unwatched and not target.shown, "available target frame remains hidden")
check(casting.Show == original_show, "native castbar Show method is preserved")
check(#casting.show_hooks == 1 and casting.parent == nil,
    "castbar keeps its secure post-hook without reparenting")
casting:Show()
check(not casting.shown, "secure castbar post-hook continues hiding the castbar")

-- Existing out-of-combat wrappers still control initial and OnShow hiding.
local combat_monk = frame()
local combat, combat_env, combat_errors, _, _, leave_combat = fixture(true, 4, {
    MonkHarmonyBar = combat_monk,
})
combat_env.in_combat = true
combat:OnEnable()
check(combat_monk.shown and combat_monk.unregisters == 0,
    "class-bar mutation remains deferred during combat")
leave_combat()
hidden_once(combat_monk, "post-combat monk resource")
combat_env.in_combat = true
combat_monk:Show()
check(combat_monk.shown, "OnShow hide callback remains deferred during combat")
leave_combat()
check(not combat_monk.shown and #combat_errors == 0,
    "queued hide finishes without optional-frame errors")

print(("HideBlizzard regression assertions passed: %d"):format(passed))
