
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local ShouldUnitAuraInstanceBeSecret = C_Secrets.ShouldUnitAuraInstanceBeSecret
local IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook

-- Filters are indexed by two character codes: [type][identifier].
-- Types:
-- ! Master filters
-- # Intermediate filters
-- % Filter maps
-- & Aura field filters
-- * Aura filter strings
-- @ Simple filters

local filters = {
	['@I'] = {
		display_name = L["True"],
		filter_type = 'True',
		disabled = true,
		built_in = true,
	},
	['@J'] = {
		display_name = L["False"],
		filter_type = 'False',
		disabled = true,
		built_in = true,
	},
	['@A'] = {
		display_name = L["Buff"],
		filter_type = 'Buff',
		buff = true,
		disabled = true,
		built_in = true,
	},
	['@B'] = {
		display_name = L["Debuff"],
		filter_type = 'Buff',
		buff = false,
		disabled = true,
		built_in = true,
	},
	['@C'] = {
		display_name = L["Weapon enchant"],
		filter_type = 'Weapon Enchant',
		weapon = true,
		disabled = true,
		built_in = true,
	},
	['@D'] = {
		display_name = L["Friend"],
		filter_type = 'Unit',
		unit_operator = 'friend',
		disabled = true,
		built_in = true,
	},
	['@E'] = {
		display_name = L["Enemy"],
		filter_type = 'Unit',
		unit_operator = 'enemy',
		disabled = true,
		built_in = true,
	},
	['@F'] = {
		display_name = L["Pet"],
		filter_type = 'Unit',
		unit_operator = '==',
		unit = 'pet',
		disabled = true,
		built_in = true,
	},
	['@G'] = {
		display_name = L["Player"],
		filter_type = 'Unit',
		unit_operator = '==',
		unit = 'player',
		disabled = true,
		built_in = true,
	},
	['@H'] = {
		display_name = L["Mine"],
		filter_type = 'Mine',
		mine = true,
		disabled = true,
		built_in = true,
	},
	['@K'] = {
		display_name = L["Dispellable"],
		filter_type = 'Filter String',
		filter_string = "RAID_PLAYER_DISPELLABLE",
		disabled = true,
		built_in = true,
	},
	['@L'] = {
		display_name = L["Cast by my vehicle"],
		filter_type = 'Caster',
		unit_operator = '==',
		unit = 'vehicle',
		disabled = true,
		built_in = true,
	},
	['@P'] = {
		display_name = L["Purgeable"],
		filter_type = 'Filter String',
		filter_string = "RAID_PLAYER_DISPELLABLE",
		disabled = true,
		built_in = true,
	},
	['@Q'] = {
		display_name = L["Boss"],
		filter_type = 'Boss debuff',
		boss_debuff = true,
		disabled = true,
		built_in = true,
	},
	['@R'] = {
		display_name = L["Personal nameplate"],
		filter_type = 'Should consolidate',
		should_consolidate = true,
		disabled = true,
		built_in = true,
	},
	['@S'] = {
		display_name = L["Global nameplate"],
		filter_type = 'Global nameplate',
		global_nameplate = true,
		disabled = true,
		built_in = true,
	},
	['@T'] = {
		display_name = L["Cast by a player"],
		filter_type = 'Cast by a player',
		caster_is_player = true,
		disabled = true,
		built_in = true,
	},
	['@U'] = {
		display_name = L["Can apply aura"],
		filter_type = 'Can apply aura',
		can_apply_aura = true,
		disabled = true,
		built_in = true,
	},
	['@V'] = {
		display_name = L["Self buff"],
		filter_type = 'Self buff',
		self_buff = true,
		disabled = true,
		built_in = true,
	},
	['@W'] = {
		display_name = L["Any player"],
		filter_type = 'Unit',
		unit_operator = 'player',
		disabled = true,
		built_in = true,
	},
	['@X'] = {
		display_name = L["Other player pet"],
		filter_type = 'Unit',
		unit_operator = 'other_player_pet',
		disabled = true,
		built_in = true,
	},
	['@Y'] = {
		display_name = L["Has custom visibility"],
		filter_type = 'Has custom visibility',
		custom_visibility = true,
		disabled = true,
		built_in = true,
	},
	['@Z'] = {
		display_name = L["Custom show"],
		filter_type = 'Should show',
		should_show = true,
		disabled = true,
		built_in = true,
	},
	['!B'] = {
		display_name = L["Default buffs"],
		filter_type = 'Meta',
		filters = {'@G','#A','@F','&B','@D','#B','@E','@L'},
		operators = {'&','|','&','|','&','|','|'},
		built_in = true,
		display_when = "buff",
	},
	['!C'] = {
		display_name = L["Default buffs, mine"],
		filter_type = 'Meta',
		filters = {'@H','!B','@E'},
		operators = {'&','|'},
		built_in = true,
		display_when = "buff",
	},
	['!D'] = {
		display_name = L["Default debuffs"],
		filter_type = 'Meta',
		filters = {'@G','#C','@D','#D','#E','@L'},
		operators = {'&','|','&','|','|'},
		built_in = true,
		display_when = "debuff",
	},
	['!E'] = {
		display_name = L["Default debuffs, mine"],
		filter_type = 'Meta',
		filters = {'@H','!D','&D'},
		operators = {'&','|'},
		built_in = true,
		display_when = "debuff",
	},
	-- ['!F'] = {
	-- 	display_name = L["Highlight: all friend debuffs"],
	-- 	filter_type = 'Meta',
	-- 	filters = {'@D','@B'},
	-- 	operators = {'&'},
	-- 	built_in = true,
	-- },
	-- ['!G'] = {
	-- 	display_name = L["Highlight: dispellable debuffs"],
	-- 	filter_type = 'Meta',
	-- 	filters = {'!F','@K'},
	-- 	operators = {'&'},
	-- 	built_in = true,
	-- 	display_when = "highlight",
	-- },
	-- ['!H'] = {
	-- 	display_name = L["Highlight: dispellable by me debuffs"],
	-- 	filter_type = 'Meta',
	-- 	filters = {'!F','&D'},
	-- 	operators = {'&'},
	-- 	built_in = true,
	-- 	display_when = "highlight",
	-- },
	-- ['!K'] = {
	-- 	display_name = L["Highlight: purgeable buffs"],
	-- 	filter_type = 'Meta',
	-- 	filters = {'@E','@A','@P'},
	-- 	operators = {'&','&','&'},
	-- 	built_in = true,
	-- 	display_when = "highlight",
	-- },
	-- ['!L'] = {
	-- 	display_name = L["Highlight: purgeable by me buffs"],
	-- 	filter_type = 'Meta',
	-- 	filters = {'@E','@A','&P'},
	-- 	operators = {'&','&','&'},
	-- 	built_in = true,
	-- 	display_when = "highlight",
	-- },
	['!M'] = {
		-- NameplateBuffContainerMixin:ShouldShowBuff
		display_name = L["Blizzard buffs, nameplate"],
		filter_type = 'Meta',
		filters = {'@S','@R','@H'},
		operators = {'|','&'},
		built_in = true,
		display_when = "buff",
	},
	['!N'] = {
		-- CompactUnitFrame_UtilShouldDisplayBuff
		display_name = L["Blizzard buffs, group"],
		filter_type = 'Meta',
		filters = {'@Z','@Y','@H','@U','@V'},
		operators = {'|~','&','&','&~'},
		built_in = true,
		display_when = "buff",
	},
	['!P'] = {
		-- TargetFrame_ShouldShowDebuffs
		display_name = L["Blizzard debuffs, target"],
		filter_type = 'Meta',
		filters = {'@S','@H','@G','@W','@D','@X','@T'},
		operators = {'|','|','|','|','|','|~'},
		built_in = true,
		display_when = "debuff",
	},
	['!Q'] = {
		-- CompactUnitFrame_Util_ShouldDisplayDebuff
		-- Custom show |~ Custom visibility
		display_name = L["Blizzard debuffs, group"],
		filter_type = 'Meta',
		filters = {'@Z','@Y'},
		operators = {'|~'},
		built_in = true,
		display_when = "debuff",
	},
}
PitBull4_Aura.filters = filters

-- Set what types of auras you can dispel (remove from friends).
local dispel_spells = {
	Magic = {
		[527] = 0, -- Purify (Priest)
		[77130] = 0, -- Purify Spirit (Shaman)
		[115450] = 0, -- Detox (Monk)
		[4987] = 0, -- Cleanse (Paladin)
		[88423] = 0, -- Nature's Cure (Druid)
		[360823] = 0, -- Naturalize (Evoker)
		[89808] = 1, -- Singe Magic (Warlock Pet)
	},
	Disease = {
		[390632] = 0, -- Improved Purify (Priest)
		[213634] = 0, -- Purify Disease (Priest)
		[388874] = 0, -- Improved Detox (Monk)
		[218164] = 0, -- Detox (Monk)
		[393024] = 0, -- Improved Cleanse (Paladin)
		[213644] = 0, -- Cleanse Toxins (Paladin)
	},
	Poison = {
		[392378] = 0, -- Improved Nature's Cure (Druid)
		[2782] = 0, -- Remove Corruption (Druid)
		[388874] = 0, -- Improved Detox (Monk)
		[218164] = 0, -- Detox (Monk)
		[393024] = 0, -- Improved Cleanse (Paladin)
		[213644] = 0, -- Cleanse Toxins (Paladin)
		[360823] = 0, -- Naturalize (Evoker)
		[365585] = 0, -- Expunge (Evoker)
	},
	Curse = {
		[392378] = 0, -- Improved Nature's Cure (Druid)
		[2782] = 0, -- Remove Corruption (Druid)
		[383016] = 0, -- Improved Purify Spirit (Shaman)
		[51886] = 0, -- Cleanse Spirit (Shaman)
		[475] = 0, -- Remove Curse (Mage)
	}
}
local can_dispel = {}
PitBull4_Aura.can_dispel = can_dispel

-- Set what types of auras you can purge (remove from enemies).
local purge_spells = {
	Magic = {
		[32375] = 0, -- Mass Dispel (Priest)
		[528] = 0, -- Dispel Magic (Priest)
		[370] = 0, -- Purge (Shaman)
		[378773] = 0, -- Greater Purge (Shaman)
		[30449] = 0, -- Spellsteal (Mage)
		[278326] = 0, -- Consume Magic (Demon Hunter)
		[19505] = 1, -- Devour Magic (Warlock Pet)
		[19801] = 0, -- Tranquilizing Shot (Hunter)
		[154742] = 0, -- Arcane Acuity (Arcane Torrent proxy for Blood Elf)
	},
	Enrage = {
		[2908] = 0, -- Soothe (Druid)
		[19801] = 0, -- Tranquilizing Shot (Hunter)
		[5938] = 0, -- Shiv (Rogue)
		[450432] = 0, -- Pressure Points (Monk)
	},
}
local can_purge = {}
PitBull4_Aura.can_purge = can_purge

-- Rescan spells that can change what we can dispel and purge.
function PitBull4_Aura:PLAYER_TALENT_UPDATE()
	for spell_type, spells in next, purge_spells do
		for spell_id, spell_bank in next, spells do
			if IsSpellKnownOrInSpellBook(spell_id, spell_bank) then
				can_purge[spell_type] = true
				break
			end
		end
	end

	for spell_type, spells in next, dispel_spells do
		for spell_id, spell_bank in next, spells do
			if IsSpellKnownOrInSpellBook(spell_id, spell_bank) then
				can_dispel[spell_type] = true
				break
			end
		end
	end
end


--- Return the DB dictionary for the specified filter.
-- Filter Types should use this to get their db.
-- @param name the name of the filter
-- @usage local db = PitBull4_Aura:GetFilterDB("myfilter")
-- @return the DB dictionary for the specified filter or nil
function PitBull4_Aura:GetFilterDB(name)
	return filters[name]
end

--- Run a filter on an aura entry and return if it passes.
-- @param name the name of the filter
-- @param entry the aura data table
-- @param frame the frame the aura is attached to
-- @param allow_secrets if the filter should run on an aura data table containing secrets
-- @return the filter result
function PitBull4_Aura:FilterEntry(name, entry, frame, allow_secrets)
	local filter = self:GetFilterDB(name)
	if not filter then
		-- geterrorhandler()(("PitBull4_Aura:FilterEntry: Invalid filter name: %q"):format(name))
		return true
	end
	if not allow_secrets and ShouldUnitAuraInstanceBeSecret(frame.unit, entry.id) then
		return true
	end
	local filter_func = self.filter_types[filter.filter_type].filter_func
	return filter_func(name, entry, frame)
end
