
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local ShouldUnitAuraInstanceBeSecret = C_Secrets.ShouldUnitAuraInstanceBeSecret

local player_class = UnitClassBase("player")
local _, player_race = UnitRace("player")

--- Return the DB dictionary for the specified filter.
-- Filter Types should use this to get their db.
-- @param filter the name of the filter
-- @usage local db = PitBull4_Aura:GetFilterDB("myfilter")
-- @return the DB dictionary for the specified filter or nil
function PitBull4_Aura:GetFilterDB(filter)
	return self.db.profile.global.filters[filter]
end

-- Setup the data for who can dispel what types of auras.
-- dispel in this context means remove from friendly players
local can_dispel = {
}
PitBull4_Aura.can_dispel = can_dispel

-- Setup the data for who can purge what types of auras.
-- purge in this context means remove from enemies.
local can_purge = {
}
PitBull4_Aura.can_purge = can_purge

-- Rescan spells that can change what we can dispel and purge.
function PitBull4_Aura:PLAYER_TALENT_UPDATE()
	if player_class == "DEMONHUNTER" then
		can_purge.Magic = IsPlayerSpell(278326) -- Consume Magic

	elseif player_class == "DRUID" then
		can_dispel.Curse = IsPlayerSpell(2782) or IsPlayerSpell(392378) -- Remove Corruption / Improved Nature's Cure
		can_dispel.Poison = can_dispel.Curse
		can_dispel.Magic = IsPlayerSpell(88423) -- Nature's Cure

		can_purge.Enrage = IsPlayerSpell(2908) -- Soothe

	elseif player_class == "EVOKER" then
		can_dispel.Poison = IsPlayerSpell(360823) or IsPlayerSpell(365585) or IsPlayerSpell(374251) -- Naturalize / Expunge / Cauterizing Flame
		can_dispel.Curse = IsPlayerSpell(374251) -- Cauterizing Flame
		can_dispel.Disease = IsPlayerSpell(374251) -- Cauterizing Flame
		can_dispel.Magic = IsPlayerSpell(360823) -- Naturalize

		can_purge.Magic = IsPlayerSpell(372048) -- Oppressing Roar

	elseif player_class == "HUNTER" then
		can_purge.Enrage = IsPlayerSpell(19801) -- Tranquilizing Shot
		can_purge.Magic = can_purge.Enrage

	elseif player_class == "MAGE" then
		can_dispel.Curse = IsPlayerSpell(475) -- Remove Curse

		can_purge.Magic = IsPlayerSpell(30449) -- Spellsteal

	elseif player_class == "MONK" then
		can_dispel.Poison = IsPlayerSpell(218164) or IsPlayerSpell(388874) -- Detox / Improved Detox
		can_dispel.Disease = can_dispel.Poison
		can_dispel.Magic = IsPlayerSpell(115450) -- Detox (Mistweaver)

	elseif player_class == "PALADIN" then
		can_dispel.Poison = IsPlayerSpell(213644) or IsPlayerSpell(393024) -- Cleanse Toxins / Improved Cleanse
		can_dispel.Disease = can_dispel.Poison
		can_dispel.Magic = IsPlayerSpell(4987) -- Cleanse

	elseif player_class == "PRIEST" then
		can_dispel.Disease = IsPlayerSpell(213634) or IsPlayerSpell(390632) -- Purify Disease / Improved Purify
		can_dispel.Magic = IsPlayerSpell(527) -- Purify

		can_purge.Magic = IsPlayerSpell(528) or IsPlayerSpell(32375) -- Dispel Magic / Mass Dispel

	elseif player_class == "SHAMAN" then
		can_dispel.Curse = IsPlayerSpell(51886) or IsPlayerSpell(383016) -- Cleanse Spirit / Improved Purify Spirit
		can_dispel.Poison = IsPlayerSpell(383013) -- Poison Cleansing Totem
		can_dispel.Magic = IsPlayerSpell(77130) -- Purify Spirit

		can_purge.Magic = IsPlayerSpell(370) or IsPlayerSpell(378773) -- Purge / Greater Purge

	elseif player_class == "WARLOCK" then
		can_dispel.Magic = IsSpellKnown(89808, true) -- Singe Magic (Imp)

		can_purge.Magic = IsSpellKnown(19505, true) -- Devour Magic (Felhunter)
	end

	-- Blood Elf Arcane Torrent
	if player_race == "BloodElf" then
		can_purge.Magic = true
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
