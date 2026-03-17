
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_CombatFader = PitBull4:NewModule("CombatFader")

PitBull4_CombatFader:SetModuleType("fader")
PitBull4_CombatFader:SetName(L["Combat fader"])
PitBull4_CombatFader:SetDescription(L["Make the unit frame fade if out of combat."])
PitBull4_CombatFader:SetDefaults({
	enabled = false,
	hurt_opacity = 0.75,
	instance_opacity = 1,
	in_combat_opacity = 1,
	out_of_combat_opacity = 0.25,
	target_opacity = 0.75,
})

local state = "out_of_combat"

-- local hurt_curve = C_CurveUtil.CreateCurve()
-- hurt_curve:SetType(Enum.LuaCurveType.Step)
-- hurt_curve:AddPoint(0, 0.75)
-- hurt_curve:AddPoint(1, 0.25)

-- local hurt_inverse_curve = C_CurveUtil.CreateCurve()
-- hurt_inverse_curve:SetType(Enum.LuaCurveType.Step)
-- hurt_inverse_curve:AddPoint(0, 0.25)
-- hurt_inverse_curve:AddPoint(1, 0.75)

local valid_instance_types = {
	pvp = true, arena = true,
	party = true, raid = true,
	scenario = true,
}

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

timerFrame:SetScript("OnEvent", function(self)
	self:Show()
end)

timerFrame:SetScript("OnUpdate", function(self)
	self:Hide()
	PitBull4_CombatFader:RecalculateState()
	PitBull4_CombatFader:UpdateAll()
end)

function PitBull4_CombatFader:OnEnable()
	-- this is handled through a timer because PLAYER_TARGET_CHANGED looks funny otherwise
	timerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	timerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	timerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	timerFrame:RegisterUnitEvent("UNIT_HEALTH", "player")
	timerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
	timerFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")

	timerFrame:Show()
end

function PitBull4_CombatFader:OnDisable()
	timerFrame:UnregisterAllEvents()
end

function PitBull4_CombatFader:RecalculateState()
	local inInstance, instanceType = IsInInstance()
	if UnitAffectingCombat("player") then
		state = "in_combat"
	elseif valid_instance_types[instanceType] then
		state = "in_instance"
	elseif UnitExists("target") then
		state = "target"
	else
		state = "out_of_combat"
	end
end

function PitBull4_CombatFader:GetOpacity(frame)
	local layout_db = self:GetLayoutDB(frame)

	if state == "in_combat" then
		return layout_db.in_combat_opacity
	elseif state == "target" then
		return layout_db.target_opacity
	else
		return layout_db.out_of_combat_opacity
	end

	-- XXX really need non-secret tests for full/empty hp/pp
	-- return UnitHealthPercent("player", true, hurt_curve)

	-- local _, power_token = UnitPowerType("player")
	-- if power_token == "MANA" or power_token == "FOCUS" or power_token == "ENERGY" then
	-- 	return UnitPowerPercent("player", nil, nil, hurt_curve) -- full => fade
	-- end
	-- return UnitPowerPercent("player", nil, nil, hurt_inverse_curve) -- empty => fade
end

PitBull4_CombatFader:SetLayoutOptionsFunction(function(self)
	local function get(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db[info[#info]]
	end
	local function set(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db[info[#info]] = value
			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
	end
	-- return "hurt_opacity", {
	-- 	type = "range",
	-- 	name = L["Hurt opacity"],
	-- 	desc = L["The opacity to display if the player is missing health or mana."],
	-- 	min = 0, max = 1, isPercent = true,
	-- 	step = 0.01, bigStep = 0.05,
	-- 	get = get,
	-- 	set = set,
	return "instance_opacity", {
		type = "range",
		name = "In instance opacity",
		desc = "The opacity to display if the player is in an instance.",
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = get,
		set = set,
	},"in_combat_opacity", {
		type = "range",
		name = L["In-combat opacity"],
		desc = L["The opacity to display if the player is in combat."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = get,
		set = set,
	}, "out_of_combat_opacity", {
		type = "range",
		name = L["Out-of-combat opacity"],
		desc = L["The opacity to display if the player is out of combat."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = get,
		set = set,
	}, "target_opacity", {
		type = "range",
		name = L["Target-selected opacity"],
		desc = L["The opacity to display if the player is selecting a target."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = get,
		set = set,
	}
end)
