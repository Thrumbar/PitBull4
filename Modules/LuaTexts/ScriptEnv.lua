-- ScriptEnv.lua: Utility functions for use in Lua scripts for LuaTexts.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_LuaTexts = PitBull4:GetModule("LuaTexts")

local ShouldUnitIdentityBeSecret = C_Secrets.ShouldUnitIdentityBeSecret

-- The ScriptEnv table serves as the environment that the scripts run
-- under LuaTexts run under.  The functions included in it are accessible
-- to this scripts as though they were local functions to it.  Functions
-- that they call will not have access to these functions.
local ScriptEnv = setmetatable({}, {__index = _G})
PitBull4_LuaTexts.ScriptEnv = ScriptEnv

local mouseover_check_cache = PitBull4_LuaTexts.mouseover_check_cache
local spell_cast_cache = PitBull4_LuaTexts.spell_cast_cache
local power_cache = PitBull4_LuaTexts.power_cache
local hp_cache = PitBull4_LuaTexts.hp_cache
local unit_cast_ids = PitBull4_LuaTexts.unit_cast_ids
local cast_data = PitBull4_LuaTexts.cast_data
local to_update = PitBull4_LuaTexts.to_update
local afk_cache = PitBull4_LuaTexts.afk_cache
local dnd_cache = PitBull4_LuaTexts.dnd_cache
local offline_cache = PitBull4_LuaTexts.offline_cache
local dead_cache = PitBull4_LuaTexts.dead_cache
local offline_times = PitBull4_LuaTexts.offline_times
local afk_times = PitBull4_LuaTexts.afk_times
local dnd = PitBull4_LuaTexts.dnd
local dead_times = PitBull4_LuaTexts.dead_times
local group_members = PitBull4_LuaTexts.group_members

local WrapString = C_StringUtil.WrapString
ScriptEnv.WrapString = WrapString

local TruncateWhenZero = C_StringUtil.TruncateWhenZero
ScriptEnv.TruncateWhenZero = TruncateWhenZero

local FloorToNearestString = C_StringUtil.FloorToNearestString
ScriptEnv.FloorToNearestString = FloorToNearestString

local function unit_guid(unit)
	if not ShouldUnitIdentityBeSecret(unit) then
		-- Update on wacky frames if we're not locked down
		return UnitGUID(unit)
	end
	return group_members[unit]
end

-- The following functions exist to provide a method to help people moving
-- from LibDogTag.  They implement the functionality that exists in some of
-- the tags in LibDogTag.  Tags that are identical to Blizzard API calls are
-- not included and you should use the API call.  Some of them do not implement
-- all of the features of the relevent tag in LibDogTag.  People interested in
-- contributing new functions should open a ticket on the PitBull4 project as
-- a patch to the LuaTexts module.  In general tags that are simplistic work
-- on other tags should be generalized (e.g. Percent instead of PercentHP and PercentMP)
-- or should simply not exist.  A major design goal is to avoid inefficient code.
-- Functions which encourage inefficient code design will not be accepted.

-- A number of these functions are borrowed or adapted from the code implmenting
-- similar tags in DogTag.  Permission to do so granted by ckknight.

local UnitToLocale = {player = L["Player"], target = L["Target"], pet = L["%s's pet"]:format(L["Player"]), focus = L["Focus"], mouseover = L["Mouse-over"]}
setmetatable(UnitToLocale, {__index=function(self, unit)
	if unit:find("pet$") then
		local nonPet = unit:sub(1, -4)
		self[unit] = L["%s's pet"]:format(self[nonPet])
		return self[unit]
	elseif not unit:find("target$") then
		if unit:find("^party%d$") then
			local num = unit:match("^party(%d)$")
			self[unit] = L["Party member #%d"]:format(num)
			return self[unit]
		elseif unit:find("^arena%d$") then
			local num = unit:match("^arena(%d)$")
			self[unit] = L["Arena enemy #%d"]:format(num)
			return self[unit]
		elseif unit:find("^boss%d$") then
			local num = unit:match("^boss(%d)$")
			self[unit] = L["Boss #%d"]:format(num)
			return self[unit]
		elseif unit:find("^raid%d%d?$") then
			local num = unit:match("^raid(%d%d?)$")
			self[unit] = L["Raid member #%d"]:format(num)
			return self[unit]
		elseif unit:find("^partypet%d$") then
			local num = unit:match("^partypet(%d)$")
			self[unit] = UnitToLocale["party" .. num .. "pet"]
			return self[unit]
		elseif unit:find("^arenapet%d$") then
			local num = unit:match("^arenapet(%d)$")
			self[unit] = UnitToLocale["arena" .. num .. "pet"]
			return self[unit]
		elseif unit:find("^raidpet%d%d?$") then
			local num = unit:match("^raidpet(%d%d?)$")
			self[unit] = UnitToLocale["raid" .. num .. "pet"]
			return self[unit]
		end
		self[unit] = unit
		return unit
	end
	local nonTarget = unit:sub(1, -7)
	self[unit] = L["%s's target"]:format(self[nonTarget])
	return self[unit]
end})

local function VehicleName(unit)
	local name = UnitName(unit:gsub("vehicle", "pet")) or UnitName(unit) or L["Vehicle"]
	local owner_unit = unit:gsub("vehicle", "")
	if owner_unit == "" then
		owner_unit = "player"
	end
	local owner = UnitName(owner_unit)
	if owner then
		return L["%s's %s"]:format(owner, name)
	end
	return name
end
ScriptEnv.VehicleName = VehicleName

local function Name(unit, show_server)
	if unit ~= "player" and not UnitExists(unit) and not ShowBossFrameWhenUninteractable(unit) then
		return UnitToLocale[unit]
	else
		if unit:match("%d*pet%d*$") then
			local vehicle = unit:gsub("pet", "vehicle")
			if UnitIsUnit(unit, vehicle) then
				return VehicleName(vehicle)
			end
		elseif unit:match("%d*vehicle%d*$") then
			return VehicleName(unit)
		end
	end

	local name, server = UnitName(unit)
	if UnitInPartyIsAI(unit) and (C_LFGInfo.IsInLFGFollowerDungeon() or C_PartyInfo.IsPartyWalkIn()) then
		name = LFG_FOLLOWER_NAME_PREFIX:format(name)
	elseif show_server and not issecretvalue(server) and server and server ~= "" then
		name = FULL_PLAYER_NAME:format(name, server)
	end
	return name
end
ScriptEnv.Name = Name

local L_DAY_ONELETTER_ABBR = DAY_ONELETTER_ABBR:gsub("%s*%%d%s*", "")
local function FormatDuration(number)
	local negative = ""
	if number < 0 then
		number = -number
		negative = "-"
	end

	if number == math.huge then
		return "**:**:**"
	elseif number >= 60*60*24 then
		return ("%s%.0f%s %d:%02d:%02d"):format(negative, math.floor(number/86400), L_DAY_ONELETTER_ABBR, number/3600 % 24, number/60 % 60, number % 60)
	elseif number >= 60*60 then
		return ("%s%d:%02d:%02d"):format(negative, number/3600, number/60 % 60, number % 60)
	end
	return ("%s%d:%02d"):format(negative, number/60 % 60, number % 60)
end
ScriptEnv.FormatDuration = FormatDuration

ScriptEnv.SeparateDigits = BreakUpLargeNumbers

local function Angle(value)
	if not value then
		return ""
	end
	return WrapString(value, "<", ">")
end
ScriptEnv.Angle = Angle

local function Paren(value)
	if not value then
		return ""
	end
	return WrapString(value, "(", ")")
end
ScriptEnv.Paren = Paren

local function Minus(value)
	return WrapString(TruncateWhenZero(value), "-")
end
ScriptEnv.Minus = Minus

local function UpdateIn(seconds)
	local font_string = ScriptEnv.font_string
	local current_timer = to_update[font_string]
	if not current_timer or current_timer > seconds then
		to_update[font_string] = seconds
	end
end
ScriptEnv.UpdateIn = UpdateIn

local function IsAFK(unit)
	afk_cache[ScriptEnv.font_string] = true
	return not not afk_times[unit_guid(unit)]
end
ScriptEnv.IsAFK = IsAFK

local function AFKDuration(unit)
	local afk = afk_times[unit_guid(unit)]
	afk_cache[ScriptEnv.font_string] = true
	if afk then
		UpdateIn(0.25)
		return GetTime() - afk
	end
end
ScriptEnv.AFKDuration = AFKDuration

local function AFK(unit)
	local afk = AFKDuration(unit)
	if afk then
		return ("%s (%s)"):format(_G.AFK, FormatDuration(afk))
	end
end
ScriptEnv.AFK = AFK

local function IsDND(unit)
	dnd_cache[ScriptEnv.font_string] = true
	return not not dnd[unit_guid(unit)]
end
ScriptEnv.IsDND = IsDND

local function DND(unit)
	dnd_cache[ScriptEnv.font_string] = true
	if dnd[unit_guid(unit)] then
		return _G.DND
	end
end
ScriptEnv.DND = DND

local function IsPlayer(unit)
	return UnitIsPlayer(unit) or UnitInPartyIsAI(unit)
end
ScriptEnv.UnitIsPlayer = IsPlayer -- existing LuaText compat

local function WrapTextInColor(text, r, g, b)
	return WrapString(text, ("|cff%02x%02x%02x"):format(r, g, b), "|r")
end

local function WrapTextInColorCode(text, textColorCode)
	return WrapString(text, ("|cff%s"):format(textColorCode), "|r")
end

local HOSTILE_REACTION = 2
local NEUTRAL_REACTION = 4
local FRIENDLY_REACTION = 5

local function HostileColor(unit)
	local r, g, b
	if not unit then
		r, g, b = unpack(PitBull4.ReactionColors.unknown)
	else
		if IsPlayer(unit) or UnitPlayerControlled(unit) then
			if UnitCanAttack(unit, "player") then
				-- they can attack me
				if UnitCanAttack("player", unit) then
					-- and I can attack them
					r, g, b = unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				else
					-- but I can't attack them
					r, g, b = unpack(PitBull4.ReactionColors.civilian)
				end
			elseif UnitCanAttack("player", unit) then
				-- they can't attack me, but I can attack them
				r, g, b = unpack(PitBull4.ReactionColors[NEUTRAL_REACTION])
			elseif UnitIsPVP(unit) then
				-- on my team
				r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
			else
				-- either enemy or friend, no violance
				r, g, b = unpack(PitBull4.ReactionColors.civilian)
			end
		elseif UnitIsTapDenied(unit) or UnitIsDead(unit) then
			r, g, b = unpack(PitBull4.ReactionColors.tapped)
		else
			local reaction = UnitReaction(unit, "player")
			if reaction then
				if reaction >= 5 then
					r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
				elseif reaction == 4 then
					r, g, b = unpack(PitBull4.ReactionColors[NEUTRAL_REACTION])
				else
					r, g, b = unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				end
			else
				r, g, b = unpack(PitBull4.ReactionColors.unknown)
			end
		end
	end
	return r * 255, g * 255, b * 255
end
ScriptEnv.HostileColor = HostileColor

local function ClassColor(unit)
	local _, class = UnitClass(unit)
	local color = PitBull4.ClassColors[class] or PitBull4.ClassColors.UNKNOWN
	return color[1] * 255, color[2] * 255, color[3] * 255
end
ScriptEnv.ClassColor = ClassColor

local function Level(unit)
	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
			return UnitBattlePetLevel(unit)
		end
	end
	local level = UnitLevel(unit)
	if level <= 0 then
		level = "??"
	end
	return level
end
ScriptEnv.Level = Level

local function DifficultyColor(unit)
	local level = Level(unit)
	if level == "??" then
		level = 99
	end
	local color = GetQuestDifficultyColor(level)
	return color.r * 255, color.g * 255, color.b * 255
end
ScriptEnv.DifficultyColor = DifficultyColor

local function AggroColor(unit)
	local r, g, b = UnitSelectionColor(unit)
	return r * 255, g * 255, b * 255
end
ScriptEnv.AggroColor = AggroColor

local classification_lookup = {
	rare = L["Rare"],
	rareelite = L["Rare-Elite"],
	elite = L["Elite"],
	worldboss = L["Boss"],
	minus = L["Minus"],
	trivial = L["Trivial"],
}

local function Classification(unit)
	return classification_lookup[PitBull4.Utils.BetterUnitClassification(unit)]
end
ScriptEnv.Classification = Classification

local ShortClassification_abbrev = {
	[L["Rare"]] = L["Rare_short"],
	[L["Rare-Elite"]] = L["Rare-Elite_short"],
	[L["Elite"]] = L["Elite_short"],
	[L["Boss"]] = L["Boss_short"],
	[L["Minus"]] = L["Minus_short"],
	[L["Trivial"]] = L["Trivial_short"],
}

local function ShortClassification(arg)
	local short = ShortClassification_abbrev[arg]
	if not short and PitBull4.Utils.GetBestUnitID(arg) then
		-- If it's empty then maybe arg is a unit
		short = ShortClassification_abbrev[Classification(arg)]
	end
	return short
end
ScriptEnv.ShortClassification = ShortClassification

local function Class(unit)
	local _, _, class_id = UnitClass(unit)
	if class_id then
		local class_info = C_CreatureInfo.GetClassInfo(class_id)
		if class_info and class_info.className then
			return class_info.className
		end
	end
	return UNKNOWN
end
ScriptEnv.Class = Class

local ShortClass_abbrev = {
	DEATHKNIGHT = L["Death Knight_short"],
	DEMONHUNTER = L["Demon Hunter_short"],
	DRUID = L["Druid_short"],
	EVOKER = L["Evoker_short"],
	HUNTER = L["Hunter_short"],
	MAGE = L["Mage_short"],
	MONK = L["Monk_short"],
	PALADIN = L["Paladin_short"],
	PRIEST = L["Priest_short"],
	ROGUE = L["Rogue_short"],
	SHAMAN = L["Shaman_short"],
	WARLOCK = L["Warlock_short"],
	WARRIOR = L["Warrior_short"],
}

local function ShortClass(arg)
	local short = ShortClass_abbrev[arg]
	if not short and PitBull4.Utils.GetBestUnitID(arg) then
		-- If it's empty then maybe arg is a unit
		local _, class, class_id = UnitClass(arg)
		if IsPlayer(arg) then
			short = ShortClass_abbrev[class]
		elseif class_id then
			local class_info = C_CreatureInfo.GetClassInfo(class_id)
			if class_info then
				short = ShortClass_abbrev[class_info.classFile]
			end
		end
	end
	return short
end
ScriptEnv.ShortClass = ShortClass

local function Creature(unit)
	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
			return _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)].." "..TOOLTIP_BATTLE_PET
		end
	end
	return UnitCreatureFamily(unit) or UnitCreatureType(unit) or UNKNOWN
end
ScriptEnv.Creature = Creature

do
	local race_pattern = _G.UNIT_TYPE_LEVEL_TEMPLATE:gsub("%%s", "(%%w+)"):gsub("%%d", "%%d+")
	local function SmartRace(unit)
		if UnitIsPlayer(unit) then
			local race = UnitRace(unit)
			return race or UNKNOWN
		elseif UnitInPartyIsAI(unit) then
			-- UnitRace doesn't work with AI units. UnitCreatureType does, but we prefer the actual race
			local info = C_TooltipInfo.GetUnit(unit)
			if info then
				for i = 1, #info.lines do -- should be 3, but just check every line
					local text = info.lines[i] and info.lines[i].leftText
					local race = text and text:match(race_pattern)
					if race then
						return race
					end
				end
			end
		end
		return Creature(unit)
	end
	ScriptEnv.SmartRace = SmartRace
end

local ShortRace_abbrev = {
	BloodElf = L["Blood Elf_short"],
	Draenei = L["Draenei_short"],
	Dwarf = L["Dwarf_short"],
	Gnome = L["Gnome_short"],
	Goblin = L["Goblin_short"],
	Human = L["Human_short"],
	NightElf = L["Night Elf_short"],
	Orc = L["Orc_short"],
	Pandaren = L["Pandaren_short"],
	Tauren = L["Tauren_short"],
	Troll = L["Troll_short"],
	Undead = L["Undead_short"],
	Worgen = L["Worgen_short"],
	DarkIronDwarf = L["Dark Iron Dwarf_short"],
	HighmountainTauren = L["Highmountain Tauren_short"],
	KulTiranHuman = L["Kul Tiran Human_short"],
	LightforgedDraenei = L["Lightforged Draenei_short"],
	MagharOrc = L["Mag'har Orc_short"],
	Nightborne = L["Nightborne_short"],
	VoidElf = L["Void Elf_short"],
	ZandalariTroll = L["Zandalari Troll_short"],
	Vulpera = L["Vulpera_short"],
	Mechagnome = L["Mechagnome_short"],
	Dracthyr = L["Dracthyr_short"],
}

local function ShortRace(arg)
	local short = ShortRace_abbrev[arg]
	if not short and PitBull4.Utils.GetBestUnitID(arg) then
		-- If it's empty then maybe arg is a unit
		local _, race = UnitRace(arg)
		short = ShortRace_abbrev[race]
	end
	return short
end
ScriptEnv.ShortRace = ShortRace

local function IsPet(unit)
	return not UnitIsPlayer(unit) and (UnitPlayerControlled(unit) or UnitPlayerOrPetInRaid(unit))
end
ScriptEnv.IsPet = IsPet

local function OfflineDuration(unit)
	local offline = offline_times[unit_guid(unit)]
	offline_cache[ScriptEnv.font_string] = true
	if offline then
		UpdateIn(0.25)
		return GetTime() - offline
	end
end
ScriptEnv.OfflineDuration = OfflineDuration

local function Offline(unit)
	local offline = OfflineDuration(unit)
	if offline then
		return ("%s (%s)"):format(_G.PLAYER_OFFLINE, FormatDuration(offline))
	end
end
ScriptEnv.Offline = Offline

local function IsOffline(unit)
	offline_cache[ScriptEnv.font_string] = true
	return not not offline_times[unit_guid(unit)]
end
ScriptEnv.IsOffline = IsOffline

local function DeadDuration(unit)
	local dead_time = dead_times[unit_guid(unit)]
	dead_cache[ScriptEnv.font_string] = true
	if dead_time then
		UpdateIn(0.25)
		return GetTime() - dead_time
	end
end
ScriptEnv.DeadDuration = DeadDuration

local function Dead(unit)
	local dead_time = DeadDuration(unit)
	local dead_type = (UnitIsGhost(unit) and L["Ghost"]) or (UnitIsDead(unit) and L["Dead"])
	if dead_time and dead_type then
		return ("%s (%s)"):format(dead_type, FormatDuration(dead_time))
	elseif dead_type then
		return dead_type
	end
end
ScriptEnv.Dead = Dead

local MOONKIN_FORM = C_Spell.GetSpellName(24858)
local TRAVEL_FORM = C_Spell.GetSpellName(783)
local TREE_OF_LIFE = C_Spell.GetSpellName(33891)

local function DruidForm(unit)
	local _, class = UnitClass(unit)
	if class == "DRUID" then
		local power = UnitPowerType(unit)
		if power == 1 then
			return L["Bear"]
		elseif power == 3 then
			return L["Cat"]
		else
			local i = 1
			repeat
				local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
				local name = auraData and auraData.name
				if name and not issecretvalue(name) then
					if name == MOONKIN_FORM then
						return L["Moonkin"]
					elseif name == TRAVEL_FORM then
						return L["Travel"]
					elseif name == TREE_OF_LIFE then
						return L["Tree"]
					end
				end
				i = i + 1
			until not auraData
		end
	end
end
ScriptEnv.DruidForm = DruidForm

local function Status(unit)
	return Offline(unit) or (UnitIsFeignDeath(unit) and L["Feigned Death"]) or Dead(unit)
end
ScriptEnv.Status = Status

local function HP(unit, no_fast)
	local hp = UnitHealth(unit)
	if not no_fast then
		hp_cache[ScriptEnv.font_string] = true
	end
	-- if hp == 1 and UnitIsGhost(unit) then
	-- 	return 0
	-- end
	return hp
end
ScriptEnv.HP = HP

local MaxHP = UnitHealthMax
ScriptEnv.MaxHP = MaxHP

local MissingHP = UnitHealthMissing
ScriptEnv.MissingHP = MissingHP

local function PercentHP(unit)
	local hpp = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
	return FloorToNearestString(hpp)
end
ScriptEnv.PercentHP = PercentHP

local Power = UnitPower
ScriptEnv.Power = Power

local MaxPower = UnitPowerMax
ScriptEnv.MaxPower = MaxPower

local MissingPower = UnitPowerMissing
ScriptEnv.MissingPower = MissingPower

local function PercentPower(unit, powerType, unmodified)
	local pp = UnitPowerPercent(unit, powerType, unmodified, CurveConstants.ScaleTo100)
	return FloorToNearestString(pp)
end
ScriptEnv.PercentPower = PercentPower

local function Round(number, digits)
	if issecretvalue(number) then
		return string.format("%." .. digits .. "f", number)
	end

	local mantissa = 10^(digits or 0)
	local norm = number * mantissa + 0.5
	local norm_floor = math.floor(norm)
	if norm == norm_floor and (norm_floor % 2) == 1 then
		return (norm_floor - 1) / mantissa
	end
	return norm_floor / mantissa
end
ScriptEnv.Round = Round

local Short, Shorter, VeryShort
do
	local short_opts, shorter_opts, very_short_opts
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" or locale == "koKR" then
		short_opts = {
			config = CreateAbbreviateConfig({
				{ breakpoint = 100000000000, abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 100000000, fractionDivisor = 1   },
				{ breakpoint = 10000000000,  abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 10000000,  fractionDivisor = 10  },
				{ breakpoint = 100000000,    abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 1000000,   fractionDivisor = 100 },
				{ breakpoint = 10000000,     abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 10000,     fractionDivisor = 1   },
				{ breakpoint = 1000000,      abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 1000,      fractionDivisor = 10  },
				{ breakpoint = 10000,        abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 100,       fractionDivisor = 100 },
			})
		}

		shorter_opts = {
			config = CreateAbbreviateConfig({
				{ breakpoint = 100000000000, abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 100000000, fractionDivisor = 1   },
				{ breakpoint = 10000000000,  abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 10000000,  fractionDivisor = 10  },
				{ breakpoint = 100000000,    abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 1000000,   fractionDivisor = 100 },
				{ breakpoint = 10000000,     abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 10000,     fractionDivisor = 1   },
				{ breakpoint = 1000000,      abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 1000,      fractionDivisor = 10  },
				{ breakpoint = 10000,        abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 100,       fractionDivisor = 100 },
				{ breakpoint = 1000,         abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 100,       fractionDivisor = 10  },
			})
		}

		very_short_opts = {
			config = CreateAbbreviateConfig({
				{ breakpoint = 100000000, abbreviation = "SECOND_NUMBER_CAP_NO_SPACE", significandDivisor = 100000000, fractionDivisor = 1 },
				{ breakpoint = 10000,     abbreviation = "FIRST_NUMBER_CAP_NO_SPACE",  significandDivisor = 10000,     fractionDivisor = 1 },
			})
		}
	else
		local BILLION_NUMBER = 10^9
		-- Use the correct symbol for long scale number locales
		if locale == "frFR" or locale == "esMX" or locale == "esES" then
			BILLION_NUMBER = 10^12
		end

		short_opts = {
			config = CreateAbbreviateConfig({
				{ breakpoint = BILLION_NUMBER, abbreviation = "b", significandDivisor = BILLION_NUMBER/10, fractionDivisor = 10,  abbreviationIsGlobal = false},
				{ breakpoint = 1000000000,     abbreviation = "m", significandDivisor = 10000000, fractionDivisor = 1,   abbreviationIsGlobal = false },
				{ breakpoint = 10000000,       abbreviation = "m", significandDivisor = 100000,   fractionDivisor = 10,  abbreviationIsGlobal = false },
				{ breakpoint = 1000000,        abbreviation = "m", significandDivisor = 10000,    fractionDivisor = 100, abbreviationIsGlobal = false },
				{ breakpoint = 100000,         abbreviation = "k", significandDivisor = 1000,     fractionDivisor = 1,   abbreviationIsGlobal = false },
				{ breakpoint = 10000,          abbreviation = "k", significandDivisor = 100,      fractionDivisor = 10,  abbreviationIsGlobal = false },
			})
		}

		shorter_opts = {
			config = CreateAbbreviateConfig({
				{ breakpoint = BILLION_NUMBER, abbreviation = "b", significandDivisor = BILLION_NUMBER/10, fractionDivisor = 10,  abbreviationIsGlobal = false},
				{ breakpoint = 1000000000,     abbreviation = "m", significandDivisor = 10000000, fractionDivisor = 1,   abbreviationIsGlobal = false },
				{ breakpoint = 10000000,       abbreviation = "m", significandDivisor = 100000,   fractionDivisor = 10,  abbreviationIsGlobal = false },
				{ breakpoint = 1000000,        abbreviation = "m", significandDivisor = 10000,    fractionDivisor = 100, abbreviationIsGlobal = false },
				{ breakpoint = 100000,         abbreviation = "k", significandDivisor = 1000,     fractionDivisor = 1,   abbreviationIsGlobal = false },
				{ breakpoint = 10000,          abbreviation = "k", significandDivisor = 100,      fractionDivisor = 10,  abbreviationIsGlobal = false },
				{ breakpoint = 1000,           abbreviation = "k", significandDivisor = 100,      fractionDivisor = 10,  abbreviationIsGlobal = false },
			})
		}

		very_short_opts = {
			config = CreateAbbreviateConfig({
				{ breakpoint = BILLION_NUMBER, abbreviation = "b", significandDivisor = BILLION_NUMBER, fractionDivisor = 1, abbreviationIsGlobal = false },
				{ breakpoint = 1000000,        abbreviation = "m", significandDivisor = 1000000,        fractionDivisor = 1, abbreviationIsGlobal = false },
				{ breakpoint = 1000,           abbreviation = "k", significandDivisor = 1000,           fractionDivisor = 1, abbreviationIsGlobal = false },
			})
		}
	end

	function Short(value)
		local success, result = pcall(AbbreviateNumbers, value, short_opts)
		if not success then
			result = ""
		end
		return result
	end
	ScriptEnv.Short = Short

	function Shorter(value)
		return AbbreviateNumbers(value, shorter_opts)
	end
	ScriptEnv.Shorter = Shorter

	function VeryShort(value)
		return AbbreviateNumbers(value, very_short_opts)
	end
	ScriptEnv.VeryShort = VeryShort
end

local function IsMouseOver()
	local font_string = ScriptEnv.font_string
	local frame = font_string.frame
	mouseover_check_cache[font_string] = frame
	return PitBull4_LuaTexts.mouseover == frame
end
ScriptEnv.IsMouseOver = IsMouseOver

local function Combos()
	if UnitHasVehicleUI("player") then
		return GetComboPoints("vehicle")
	end
	return UnitPower("player", Enum.PowerType.ComboPoints)
end
ScriptEnv.Combos = Combos

local function ComboSymbols(symbol)
	return string.rep(symbol or "@", Combos())
end
ScriptEnv.ComboSymbols = ComboSymbols

local function Percent(x, y)
	if hasanysecretvalues(x, y) then
		error("Percent cannot be used with secret values.")
	end
	if x and y and y ~= 0 then
		return Round(x / y * 100, 1)
	end
	return 0
end
ScriptEnv.Percent = Percent

local function XP(unit)
	if unit == "player" then
		return UnitXP(unit)
	elseif unit == "pet" or unit == "playerpet" then
		return GetPetExperience()
	end
	return 0
end
ScriptEnv.XP = XP

local function MaxXP(unit)
	if unit == "player" then
		return UnitXPMax(unit)
	elseif unit == "pet" or unit == "playerpet" then
		local _, max = GetPetExperience()
		return max
	end
	return 0
end
ScriptEnv.MaxXP = MaxXP

local function RestXP(unit)
	if unit == "player" then
		return GetXPExhaustion() or 0
	end
	return 0
end
ScriptEnv.RestXP = RestXP

-- Pre-Dragonflight API wrapper for old texts
local function GetFriendshipReputation(id)
	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		local info = C_GossipInfo.GetFriendshipReputation(id)
		if info.friendshipFactionID > 0 then
			return info.friendshipFactionID, info.standing, info.maxRep, info.name, info.text, info.texture, info.reaction, info.reactionThreshold, info.nextThreshold
		end
	end
end
ScriptEnv.GetFriendshipReputation = GetFriendshipReputation

local function WatchedFactionInfo()
	local name, reaction, min, max, value, faction_id
	if GetWatchedFactionInfo then
		name, reaction, min, max, value, faction_id = GetWatchedFactionInfo()
	else -- XXX wow_tww
		local watchedFactionData = C_Reputation.GetWatchedFactionData()
		if watchedFactionData then
			name = watchedFactionData.name
			reaction =  watchedFactionData.reaction
			min = watchedFactionData.currentReactionThreshold
			max = watchedFactionData.nextReactionThreshold
			value = watchedFactionData.currentStanding
			faction_id = watchedFactionData.factionID
		end
	end
	if not name then
		return nil
	end

	if ClassicExpansionAtLeast(LE_EXPANSION_LEGION) and C_Reputation.IsFactionParagon(faction_id) then
		local paragon_value, threshold, _, has_reward = C_Reputation.GetFactionParagonInfo(faction_id)
		min, max = 0, threshold
		value = paragon_value % threshold
		if has_reward then
			value = value + threshold
		end
	elseif ClassicExpansionAtLeast(LE_EXPANSION_DRAGONFLIGHT) and C_Reputation.IsMajorFaction(faction_id) then
		local faction_info = C_MajorFactions.GetMajorFactionData(faction_id)
		min, max = 0, faction_info.renownLevelThreshold
	elseif ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		local rep_info = C_GossipInfo.GetFriendshipReputation(faction_id)
		local friendship_id = rep_info.friendshipFactionID
		if friendship_id > 0 then
			if rep_info.nextThreshold then
				min, max, value = rep_info.reactionThreshold, rep_info.nextThreshold, rep_info.standing
			else -- max, show full amount?
				min, max, value = 0, rep_info.standing, rep_info.standing
			end
		end
	end

	-- Normalize values
	max = max - min
	value = value - min
	min = 0
	return name, reaction, min, max, value, faction_id
end
ScriptEnv.WatchedFactionInfo = WatchedFactionInfo

local function ArtifactPower()
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	if azeriteItemLocation then
		-- api can error if the active item is in your bank
		if azeriteItemLocation.bagID and (azeriteItemLocation.bagID < 0 or azeriteItemLocation.bagID > NUM_BAG_SLOTS) then
			return 0, 1, 0, -1
		end
		local artifactXP, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
		local numPoints = AzeriteUtil.GetEquippedItemsUnselectedPowersCount()
		local level = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
		return artifactXP, totalLevelXP, numPoints, level
	end
	return 0, 0, 0, 0
end
ScriptEnv.ArtifactPower = ArtifactPower

local function ThreatPair(unit)
	if UnitIsFriend("player", unit) then
		if UnitExists("target") then
			return unit, "target"
		end
		return nil
	end
	return "player", unit
end
ScriptEnv.ThreatPair = ThreatPair

ScriptEnv.ThreatSituation = UnitDetailedThreatSituation

local function ThreatStatusColor(status)
	local r, g, b = GetThreatStatusColor(status)
	return r * 255, g * 255, b * 255
end
ScriptEnv.ThreatStatusColor = ThreatStatusColor

local function CastData(unit)
	spell_cast_cache[ScriptEnv.font_string] = true
	return cast_data[unit_cast_ids[unit]]
end
ScriptEnv.CastData = CastData

local function InterruptedBy(interrupted_by)
	if interrupted_by then
		local name = UnitNameFromGUID(interrupted_by)
		if name then
			local _, class = UnitClassFromGUID(interrupted_by)
			local classColor = RAID_CLASS_COLORS[class]
			if classColor then
				name = classColor:WrapTextInColorCode(name)
			end
			return _G.SPELL_INTERRUPTED_BY:format(name)
		end
	end
end
ScriptEnv.InterruptedBy = InterruptedBy

local function Alpha(number)
	PitBull4_LuaTexts.alpha = Saturate(number)
end
ScriptEnv.Alpha = Alpha

local function Outline()
	PitBull4_LuaTexts.outline = "OUTLINE"
end
ScriptEnv.Outline = Outline

local function ThickOutline()
	PitBull4_LuaTexts.outline = "OUTLINE, THICKOUTLINE"
end
ScriptEnv.ThickOutline = ThickOutline

local function WordWrap()
	PitBull4_LuaTexts.word_wrap = true
end
ScriptEnv.WordWrap = WordWrap

local function abbreviate(text)
	local b = text:byte(1)
	if b <= 127 then
		return text:sub(1, 1)
	elseif b <= 223 then
		return text:sub(1, 2)
	elseif b <= 239 then
		return text:sub(1, 3)
	else
		return text:sub(1, 4)
	end
end
local function Abbreviate(value)
	if not issecretvalue(value) and value:find(" ") then
		return value:gsub(" *([^ ]+) *", abbreviate)
	end
	return value
end
ScriptEnv.Abbreviate = Abbreviate

local function PVPDuration(unit)
	if unit == "player" and IsPVPTimerRunning() then
		UpdateIn(0.25)
		return GetPVPTimer() / 1000
	end
end
ScriptEnv.PVPDuration = PVPDuration

local hp_color_curve = C_CurveUtil.CreateColorCurve()
hp_color_curve:AddPoint(0, CreateColor(1, 0, 0))
hp_color_curve:AddPoint(0.5, CreateColor(1, 1, 0))
hp_color_curve:AddPoint(1, CreateColor(0, 1, 0))
local function HPColor(value)
	local color = hp_color_curve:Evaluate(value)
	return color:GetRGBAsBytes()
end
ScriptEnv.HPColor = HPColor

local power_type_to_string = {
	[Enum.PowerType.Mana] = "MANA",
	[Enum.PowerType.Rage] = "RAGE",
	[Enum.PowerType.Focus] = "FOCUS",
	[Enum.PowerType.Energy] = "ENERGY",
	[Enum.PowerType.ComboPoints] = "COMBO_POINTS",
	[Enum.PowerType.Runes] = "RUNES",
	[Enum.PowerType.RunicPower] = "RUNIC_POWER",
	[Enum.PowerType.SoulShards] = "SOUL_SHARDS",
	[Enum.PowerType.LunarPower] = "LUNAR_POWER",
	[Enum.PowerType.HolyPower] = "HOLY_POWER",
	[Enum.PowerType.Maelstrom] = "MAELSTROM",
	[Enum.PowerType.Chi] = "CHI",
	[Enum.PowerType.Insanity] = "INSANITY",
	[Enum.PowerType.ArcaneCharges] = "ARCANE_CHARGES",
	[Enum.PowerType.Fury] = "FURY",
	[Enum.PowerType.Pain] = "PAIN",
}
local function PowerColor(power_type)
	if type(power_type) == "number" then
		power_type = power_type_to_string[power_type]
	end
	local color = PitBull4.PowerColors[power_type]
	if not color then
		return 178.5, 178.5, 178.5
	end
	return color[1] * 255, color[2] * 255, color[3] * 255
end
ScriptEnv.PowerColor = PowerColor

local function ReputationColor(reaction)
	local color = PitBull4.ReactionColors[reaction]
	if color then
		return color[1] * 255, color[2] * 255, color[3] * 255
	end
end
ScriptEnv.ReputationColor = ReputationColor

local function ConfigMode()
	local font_string = ScriptEnv.font_string
	local frame = font_string.frame
	if frame.force_show then
		return ("{%s}"):format(font_string.luatexts_name)
	end
end
ScriptEnv.ConfigMode = ConfigMode
