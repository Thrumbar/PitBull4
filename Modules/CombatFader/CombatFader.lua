
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_CombatFader = PitBull4:NewModule("CombatFader")

PitBull4_CombatFader:SetModuleType("fader")
PitBull4_CombatFader:SetName(L["Combat fader"])
PitBull4_CombatFader:SetDescription(L["Make the unit frame fade if out of combat."])
PitBull4_CombatFader:SetDefaults({
	enabled = false,
	hurt_opacity = 0.75,
	in_combat_opacity = 1,
	out_of_combat_opacity = 0.25,
	target_opacity = 0.75,
})

local state = "out_of_combat"

local hurt_curve = C_CurveUtil.CreateCurve()
hurt_curve:SetType(Enum.LuaCurveType.Step)
hurt_curve:AddPoint(0, 0.75)
hurt_curve:AddPoint(1, 0.25)

local hurt_inverse_curve = C_CurveUtil.CreateCurve()
hurt_inverse_curve:SetType(Enum.LuaCurveType.Step)
hurt_inverse_curve:AddPoint(0, 0.25)
hurt_inverse_curve:AddPoint(1, 0.75)

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

timerFrame:SetScript("OnUpdate", function(self)
	self:Hide()
	PitBull4_CombatFader:RecalculateState()
	PitBull4_CombatFader:UpdateAll()
end)

function PitBull4_CombatFader:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "Refresh")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "Refresh")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "Refresh")
	self:RegisterUnitEvent("UNIT_HEALTH", "Refresh", "player")
	self:RegisterUnitEvent("UNIT_POWER_UPDATE", "Refresh", "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "Refresh", "player")

	self:RecalculateState()
	timerFrame:Show()
end

function PitBull4_CombatFader:RecalculateState()
	if UnitAffectingCombat("player") then
		state = "in_combat"
	elseif UnitExists("target") then
		state = "target"
	else
		state = "out_of_combat"
	end
end

function PitBull4_CombatFader:Refresh()
	-- this is handled through a timer because PLAYER_TARGET_CHANGED looks funny otherwise
	timerFrame:Show()
end

function PitBull4_CombatFader:GetOpacity(frame)
	local layout_db = self:GetLayoutDB(frame)

	if state == "in_combat" then
		return layout_db.in_combat_opacity
	elseif state == "target" then
		return layout_db.target_opacity
	end
	return UnitHealthPercent("player", true, hurt_curve)

	-- XXX really need non-secret tests for full/empty hp/pp
	-- local _, power_token = UnitPowerType("player")
	-- if power_token == "MANA" or power_token == "FOCUS" or power_token == "ENERGY" then
	-- 	return UnitPowerPercent("player", nil, nil, hurt_curve)
	-- end
	-- return UnitPowerPercent("player", nil, nil, hurt_inverse_curve)
end

PitBull4_CombatFader:SetLayoutOptionsFunction(function(self)
	return "hurt", {
		type = "range",
		name = L["Hurt opacity"],
		desc = L["The opacity to display if the player is missing health or mana."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.hurt_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.hurt_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
	}, "in_combat", {
		type = "range",
		name = L["In-combat opacity"],
		desc = L["The opacity to display if the player is in combat."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.in_combat_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.in_combat_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
	}, "out_of_combat", {
		type = "range",
		name = L["Out-of-combat opacity"],
		desc = L["The opacity to display if the player is out of combat."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.out_of_combat_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.out_of_combat_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
	}, "target", {
		type = "range",
		name = L["Target-selected opacity"],
		desc = L["The opacity to display if the player is selecting a target."],
		min = 0, max = 1, isPercent = true,
		step = 0.01, bigStep = 0.05,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.target_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.target_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
	}
end)
