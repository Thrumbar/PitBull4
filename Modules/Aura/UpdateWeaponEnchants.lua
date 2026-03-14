
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local GetItemInfo = C_Item.GetItemInfo

-- constants for the slot ids
local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND
local INVSLOT_OFFHAND = _G.INVSLOT_OFFHAND

-- Table we store the weapon enchant info in.
-- This table is never cleared and entries are reused.
-- The entry tables follow the same format as those used for the aura
-- list.  Since they are simply copied into that list.  To avoid
-- GC'ing entries constantly when there is no MH or OH enchant the
-- index 2 (the slot value) is set to nil.
local weapon_list = {
	[INVSLOT_MAINHAND] = {},
	[INVSLOT_OFFHAND] = {},
}
PitBull4_Aura.weapon_list = weapon_list

-- cache for weapon enchant durations
local weapon_durations = {
	[INVSLOT_MAINHAND] = C_DurationUtil.CreateDuration(),
	[INVSLOT_OFFHAND] = C_DurationUtil.CreateDuration(),
}

-- Get the name of the temporary enchant on a weapon from the tooltip
-- given the item slot the weapon is in.
local function get_weapon_enchant_name(slot)
	local data = C_TooltipInfo.GetInventoryItem("player", slot, true)
	if not data then return end

	for _, line in next, data.lines do
		if line.type == 0 and line.leftText then -- Enum.TooltipDataLineType.None
			local buff_name = line.leftText:match("^(.+) %(%d+ [^$)]+%)$")
			if buff_name then
				local buff_name_no_rank = buff_name:match("^(.*) %d+$")
				return buff_name_no_rank or buff_name
			end
		end
	end
end

-- Takes the data for a weapon enchant and builds an aura entry
local function set_weapon_entry(is_enchant, time_left, expiration_time, count, slot)
	local entry = weapon_list[slot]

	-- No such enchant, clear the table
	if not is_enchant then
		wipe(entry)
		return
	end

	local weapon, _, quality, _, _, _, _, _, _, texture = GetItemInfo(GetInventoryItemLink("player", slot))
	-- Try and get the name of the enchant from the tooltip, if not use the weapon name.
	local name = get_weapon_enchant_name(slot) or weapon
	if not name then
		wipe(entry)
		return
	end

	local duration = weapon_durations[slot]
	duration:SetTimeSpan(GetTime(), expiration_time)

	entry.index = 0 -- index 0 means PitBull generated aura
	-- If there's no enchant set we set weaponEnchantSlot to nil
	entry.weaponEnchantSlot = slot
	entry.weaponEnchantQuality = quality
	entry.isHelpfulAura = true
	entry.isHarmfulAura = false
	entry.name = name
	entry.icon = texture
	entry.applications = count
	entry.debuffType = nil
	entry.duration = duration
	entry.expiration_time = expiration_time
	entry.isPlayerAura = true
end

-- Looks for changes to weapon enchants that we do not have cached
-- and if there is one updates all the frames set to display them.
-- If force is set then it clears the cache first.  Useful for
-- config changes that may invalidate our cache.
--
-- General operation of the Weapon Enchant aura system:
-- * Load changed weapon enchants into weapon_list which
--   is an table of aura entries identical in layout to list
-- * The aura entries are indexed by the slot id of the weapon.
-- * When a frames auras are updated (either normally or triggered
--   by a weapon enchant change) the weapon enchants are copied
--   into the list of auras built from UnitAura().
--
-- This design means that the tooltip scanning, duration calculations,
-- and spell icon guessing operations only happen once when the
-- weapon enchant is first seen.  Other arua changes for the player
-- simply cause the weapon enchant data to be copied again without
-- recalculation.
function PitBull4_Aura:UpdateWeaponEnchants()
	local updated = false

	local mh, mh_time_left, mh_count, _, oh, oh_time_left, oh_count = GetWeaponEnchantInfo()
	local current_time = GetTime()
	local mh_entry = weapon_list[INVSLOT_MAINHAND]
	local oh_entry = weapon_list[INVSLOT_OFFHAND]

	-- Grab the values from the weapon_list entries to use
	-- to compare against the current values to look for changes.
	local old_mh, old_mh_count, old_mh_expiration_time
	if mh_entry then
		old_mh = mh_entry.weaponEnchantSlot ~= nil and true or false
		old_mh_count = mh_entry.applications
		old_mh_expiration_time = mh_entry.expirationTime
	end

	local old_oh, old_oh_count, old_oh_expiration_time
	if oh_entry then
		old_oh = oh_entry.weaponEnchantSlot ~= nil and true or false
		old_oh_count = oh_entry.applications
		old_oh_expiration_time = oh_entry.expirationTime
	end

	-- GetWeaponEnchantInfo() briefly returns that there is
	-- an enchant but with the time_left set to zero.
	-- When this happens force it to appear to us as though
	-- the enchant isn't there.
	if mh_time_left == 0 then
		mh, mh_time_left, mh_count = nil, nil, nil
	end
	if oh_time_left == 0 then
		oh, oh_time_left, oh_count = nil, nil, nil
	end

	-- Calculate the expiration time from the time left.  We use
	-- expiration time since the normal Aura system uses it instead
	-- of time_left.
	local mh_expiration_time = mh_time_left and mh_time_left / 1000 + current_time
	local oh_expiration_time = oh_time_left and oh_time_left / 1000 + current_time

	-- Test to see if the enchant has changed and if so set the entry for it
	-- We check that the expiration time is at least 0.2 seconds further
	-- ahead than it was to avoid rebuilding auras for rounding errors.
	if mh ~= old_mh or mh_count ~= old_mh_count or (mh_expiration_time and old_mh_expiration_time and mh_expiration_time - old_mh_expiration_time > 0.2) then
		set_weapon_entry(mh, mh_time_left, mh_expiration_time, mh_count, INVSLOT_MAINHAND)
		updated = true
	end
	if oh ~= old_oh or oh_count ~= old_oh_count or (oh_expiration_time and old_oh_expiration_time and oh_expiration_time - old_oh_expiration_time > 0.2) then
		set_weapon_entry(oh, oh_time_left, oh_expiration_time, oh_count, INVSLOT_OFFHAND)
		updated = true
	end

	-- An enchant changed so find all the relevent frames and update
	-- their auras.
	if updated then
		for frame in PitBull4:IterateFrames() do
			if frame.unit == "player" then
				local layout_db = self:GetLayoutDB(frame)
				if layout_db.enabled and layout_db.enabled_weapons then
					self:UpdateAuras(frame)
					self:LayoutAuras(frame)
				end
			end
		end
	end
end
