
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local ShouldUnitAuraInstanceBeSecret = C_Secrets.ShouldUnitAuraInstanceBeSecret
local IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook


--- Return the DB dictionary for the specified filter.
-- Filter Types should use this to get their db.
-- @param filter the name of the filter
-- @usage local db = PitBull4_Aura:GetFilterDB("myfilter")
-- @return the DB dictionary for the specified filter or nil
function PitBull4_Aura:GetFilterDB(filter)
	return self.db.profile.global.filters[filter]
end

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

function PitBull4_Aura:FilterEntry(name, entry, frame, allow_secrets)
	if not name or name == "" then return true end
	local filter = self:GetFilterDB(name)
	if not filter then return true end
	if not allow_secrets and ShouldUnitAuraInstanceBeSecret(frame.unit, entry.id) then return true end
	local filter_func = self.filter_types[filter.filter_type].filter_func
	return filter_func(name, entry, frame)
end
