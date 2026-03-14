
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
	DEATHKNIGHT = {},
	DEMONHUNTER = {},
	DRUID = {},
	EVOKER = {},
	HUNTER = {},
	MAGE = {},
	MONK = {},
	PALADIN = {},
	PRIEST = {},
	ROGUE = {},
	SHAMAN = {},
	WARLOCK = {},
	WARRIOR = {},
}
can_dispel.player = can_dispel[player_class]
PitBull4_Aura.can_dispel = can_dispel

-- Setup the data for who can purge what types of auras.
-- purge in this context means remove from enemies.
local can_purge = {
	DEATHKNIGHT = {},
	DEMONHUNTER = {},
	DRUID = {},
	EVOKER = {},
	HUNTER = {},
	MAGE = {},
	MONK = {},
	PALADIN = {},
	PRIEST = {},
	ROGUE = {},
	SHAMAN = {},
	WARLOCK = {},
	WARRIOR = {},
}
can_purge.player = can_purge[player_class]
PitBull4_Aura.can_purge = can_purge

-- Rescan spells that can change what we can dispel and purge.
function PitBull4_Aura:PLAYER_TALENT_UPDATE()
	if player_class == "DEMONHUNTER" then
		can_purge.DEMONHUNTER.Magic = IsPlayerSpell(278326) -- Consume Magic
		self:GetFilterDB(',,7').aura_type_list.Magic = can_purge.DEMONHUNTER.Magic

	elseif player_class == "DRUID" then
		can_dispel.DRUID.Curse = IsPlayerSpell(2782) or IsPlayerSpell(392378) -- Remove Corruption / Improved Nature's Cure
		self:GetFilterDB(',3').aura_type_list.Curse = can_dispel.DRUID.Curse
		can_dispel.DRUID.Poison = can_dispel.DRUID.Curse
		self:GetFilterDB(',3').aura_type_list.Poison = can_dispel.DRUID.Poison
		can_dispel.DRUID.Magic = IsPlayerSpell(88423) -- Nature's Cure
		self:GetFilterDB(',3').aura_type_list.Magic = can_dispel.DRUID.Magic

		can_purge.DRUID.Enrage = IsPlayerSpell(2908) -- Soothe
		self:GetFilterDB(',7').aura_type_list.Enrage = can_purge.DRUID.Enrage

	elseif player_class == "EVOKER" then
		can_dispel.EVOKER.Poison = IsPlayerSpell(360823) or IsPlayerSpell(365585) or IsPlayerSpell(374251) -- Naturalize / Expunge / Cauterizing Flame
		self:GetFilterDB('--3').aura_type_list.Poison = can_dispel.EVOKER.Poison
		can_dispel.EVOKER.Curse = IsPlayerSpell(374251) -- Cauterizing Flame
		self:GetFilterDB('--3').aura_type_list.Curse = can_dispel.EVOKER.Curse
		can_dispel.EVOKER.Disease = IsPlayerSpell(374251) -- Cauterizing Flame
		self:GetFilterDB('--3').aura_type_list.Disease = can_dispel.EVOKER.Disease
		can_dispel.EVOKER.Magic = IsPlayerSpell(360823) -- Naturalize
		self:GetFilterDB('--3').aura_type_list.Magic = can_dispel.EVOKER.Magic

		can_purge.EVOKER.Magic = IsPlayerSpell(372048) -- Oppressing Roar
		self:GetFilterDB('--7').aura_type_list.Magic = can_purge.EVOKER.Magic

	elseif player_class == "HUNTER" then
		can_purge.HUNTER.Enrage = IsPlayerSpell(19801) -- Tranquilizing Shot
		self:GetFilterDB('-7').aura_type_list.Enrage = can_purge.HUNTER.Enrage
		can_purge.HUNTER.Magic = can_purge.HUNTER.Enrage
		self:GetFilterDB('-7').aura_type_list.Magic = can_purge.HUNTER.Magic

	elseif player_class == "MAGE" then
		can_dispel.MAGE.Curse = IsPlayerSpell(475) -- Remove Curse
		self:GetFilterDB('.3').aura_type_list.Curse = can_dispel.MAGE.Curse

		can_purge.MAGE.Magic = IsPlayerSpell(30449) -- Spellsteal
		self:GetFilterDB('.7').aura_type_list.Magic = can_purge.MAGE.Magic

	elseif player_class == "MONK" then
		can_dispel.MONK.Poison = IsPlayerSpell(218164) or IsPlayerSpell(388874) -- Detox / Improved Detox
		self:GetFilterDB('//3').aura_type_list.Poison = can_dispel.MONK.Poison
		can_dispel.MONK.Disease = can_dispel.MONK.Poison
		self:GetFilterDB('//3').aura_type_list.Disease = can_dispel.MONK.Disease
		can_dispel.MONK.Magic = IsPlayerSpell(115450) -- Detox (Mistweaver)
		self:GetFilterDB('//3').aura_type_list.Magic = can_dispel.MONK.Magic

	elseif player_class == "PALADIN" then
		can_dispel.PALADIN.Poison = IsPlayerSpell(213644) or IsPlayerSpell(393024) -- Cleanse Toxins / Improved Cleanse
		self:GetFilterDB('/3').aura_type_list.Poison = can_dispel.PALADIN.Poison
		can_dispel.PALADIN.Disease = can_dispel.PALADIN.Poison
		self:GetFilterDB('/3').aura_type_list.Disease = can_dispel.PALADIN.Disease
		can_dispel.PALADIN.Magic = IsPlayerSpell(4987) -- Cleanse
		self:GetFilterDB('/3').aura_type_list.Magic = can_dispel.PALADIN.Magic

	elseif player_class == "PRIEST" then
		can_dispel.PRIEST.Disease = IsPlayerSpell(213634) or IsPlayerSpell(390632) -- Purify Disease / Improved Purify
		self:GetFilterDB('03').aura_type_list.Disease = can_dispel.PRIEST.Disease
		can_dispel.PRIEST.Magic = IsPlayerSpell(527) -- Purify
		self:GetFilterDB('03').aura_type_list.Magic = can_dispel.PRIEST.Magic

		can_purge.PRIEST.Magic = IsPlayerSpell(528) or IsPlayerSpell(32375) -- Dispel Magic / Mass Dispel
		self:GetFilterDB('07').aura_type_list.Magic = can_purge.PRIEST.Magic

	elseif player_class == "SHAMAN" then
		can_dispel.SHAMAN.Curse = IsPlayerSpell(51886) or IsPlayerSpell(383016) -- Cleanse Spirit / Improved Purify Spirit
		self:GetFilterDB('23').aura_type_list.Curse = can_dispel.SHAMAN.Curse
		can_dispel.SHAMAN.Poison = IsPlayerSpell(383013) -- Poison Cleansing Totem
		self:GetFilterDB('23').aura_type_list.Poison = can_dispel.SHAMAN.Poison
		can_dispel.SHAMAN.Magic = IsPlayerSpell(77130) -- Purify Spirit
		self:GetFilterDB('23').aura_type_list.Magic = can_dispel.SHAMAN.Magic

		can_purge.SHAMAN.Magic = IsPlayerSpell(370) or IsPlayerSpell(378773) -- Purge / Greater Purge
		self:GetFilterDB('27').aura_type_list.Magic = can_purge.SHAMAN.Magic

	elseif player_class == "WARLOCK" then
		can_dispel.WARLOCK.Magic = IsSpellKnown(89808, true) -- Singe Magic (Imp)
		self:GetFilterDB('33').aura_type_list.Magic = can_dispel.WARLOCK.Magic

		can_purge.WARLOCK.Magic = IsSpellKnown(19505, true) -- Devour Magic (Felhunter)
		self:GetFilterDB('37').aura_type_list.Magic = can_purge.WARLOCK.Magic
	end

	-- Blood Elf Arcane Torrent
	if player_race == "BloodElf" then
		can_purge.player.Magic = true
		if player_class == "DEATHKNIGHT" then
			self:GetFilterDB('+7').aura_type_list.Magic = true
		elseif player_class == "DEMONHUNTER" then
			self:GetFilterDB(',,7').aura_type_list.Magic = true
		elseif player_class == "HUNTER" then
			self:GetFilterDB('-7').aura_type_list.Magic = true
		elseif player_class == "MAGE" then
			self:GetFilterDB('.7').aura_type_list.Magic = true
		elseif player_class == "MONK" then
			self:GetFilterDB('//7').aura_type_list.Magic = true
		elseif player_class == "PALADIN" then
			self:GetFilterDB('/7').aura_type_list.Magic = true
		elseif player_class == "PRIEST" then
			self:GetFilterDB('07').aura_type_list.Magic = true
		elseif player_class == "ROGUE" then
			self:GetFilterDB('17').aura_type_list.Magic = true
		elseif player_class == "WARLOCK" then
			self:GetFilterDB('37').aura_type_list.Magic = true
		elseif player_class == "WARRIOR" then
			self:GetFilterDB('47').aura_type_list.Magic = true
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
