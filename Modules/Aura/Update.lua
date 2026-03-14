
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local GetAuraDispelTypeColor = C_UnitAuras.GetAuraDispelTypeColor
local GetUnitAuras = C_UnitAuras.GetUnitAuras
local IsAuraFilteredOutByInstanceID = C_UnitAuras.IsAuraFilteredOutByInstanceID

local GetItemInfo = C_Item.GetItemInfo
local GetItemQualityColor = C_Item.GetItemQualityColor

-- The table we use for gathering the aura data, filtering
-- and then sorting them.
local list = {}

-- Table we store the weapon enchant info in.
local weapon_list = PitBull4_Aura.weapon_list

-- constants for the slot ids
local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND
local INVSLOT_OFFHAND = _G.INVSLOT_OFFHAND

-- constants for building sample auras
local sample_buff_icon   = [[Interface\Icons\Spell_ChargePositive]]
local sample_debuff_icon = [[Interface\Icons\Spell_ChargeNegative]]
local sample_debuff_types = { "Poison", "Magic", "Disease", "Curse", "Enrage", "Bleed", "None" }
local sample_duration = C_DurationUtil.CreateDuration()

-- color curve for the dispel type
local dispel_color_curve = C_CurveUtil.CreateColorCurve()
dispel_color_curve:SetType(Enum.LuaCurveType.Step)
PitBull4_Aura.dispel_color_curve = dispel_color_curve

local dispel_types = {
	None = 0,
	Magic = 1,
	Curse = 2,
	Disease = 3,
	Poison = 4,
	Enrage = 9,
	Bleed = 11,
}

-- Fills an array of arrays with the information about the auras
local function get_aura_list(list, unit, db, is_buff, frame)
	if not unit then return end
	local filter = is_buff and "HELPFUL" or "HARMFUL"
	local player_filter = is_buff and "HELPFUL|PLAYER" or "HARMFUL|PLAYER"
	local max_auras = is_buff and db.max_buffs or db.max_debuffs
	local sort_rule = Enum.UnitAuraSortRule[(is_buff and db.layout.buff.sort_rule or db.layout.debuff.sort_rule) or "Unsorted"]
	local sort_direction = (is_buff and db.layout.buff.reverse or db.layout.debuff.reverse) and 1 or 0 -- Enum.UnitAuraSortDirection
	local filter_name = is_buff and db.layout.buff.filter or db.layout.debuff.filter

	-- Loop through the auras
	local index = 1
	for _, entry in next, GetUnitAuras(unit, filter, max_auras, sort_rule, sort_direction) do
		entry.index = index
		entry.id = entry.auraInstanceID
		entry.isPlayerAura = not IsAuraFilteredOutByInstanceID(unit, entry.auraInstanceID, player_filter)
		entry.isHelpfulAura = is_buff
		entry.isHarmfulAura = not is_buff

		-- Filter the list if not true
		if PitBull4_Aura:FilterEntry(filter_name, entry, frame) then
			list[index] = entry
			index = index + 1
		end
	end

	-- Clear the list of extra entries
	for i = index, #list do
		list[i] = nil
	end

	return list
end

-- Fills up to the maximum number of auras with sample auras
local function get_aura_list_sample(list, unit, max, db, is_buff, is_player)
	-- figure the slot to use for the mainhand and offhand slots
	local mainhand, offhand
	if is_buff and db.enabled_weapons and unit and is_player then
		local mh, oh = weapon_list[INVSLOT_MAINHAND], weapon_list[INVSLOT_OFFHAND]
		if not mh or not mh[2] then
			mainhand = #list + 1
		end
		if not oh or not oh[2] then
			offhand = (mainhand and mainhand + 1) or #list + 1
		end
	end

	local num_entries = #list
	for i = num_entries + 1, max do
		local entry = list[i]
		if not entry then
			entry = {}
			list[i] = entry
		end

		-- Create our bogus aura entry
		entry.index = 0 -- index 0 means PitBull generated aura
		if i == mainhand then
			entry.weaponEnchantSlot = INVSLOT_MAINHAND
			entry.weaponEnchantQuality = GetInventoryItemQuality("player", entry.weaponEnchantSlot) or Enum.ItemQuality.Epic
			entry.name = L["Sample Weapon Enchant"]
			entry.debuffType = nil -- no debuff type
			entry.isPlayerAura = true
		elseif i == offhand then
			entry.weaponEnchantSlot = INVSLOT_OFFHAND
			entry.weaponEnchantQuality = GetInventoryItemQuality("player", entry.weaponEnchantSlot) or Enum.ItemQuality.Epic
			entry.name = L["Sample Weapon Enchant"]
			entry.debuffType = nil -- no debuff type
			entry.isPlayerAura = true
		else
			entry.weaponEnchantSlot = nil -- not a weapon enchant
			entry.weaponEnchantQuality = nil -- no quality color
			entry.name = is_buff and L["Sample Buff"] or L["Sample Debuff"]
			entry.debuffType = dispel_types[sample_debuff_types[(i - 1) % #sample_debuff_types]]
			entry.isPlayerAura = (i - num_entries < 5) and true or false -- (show 4 player entries)
		end
		entry.isHelpfulAura = is_buff
		entry.isHarmfulAura = not is_buff
		entry.icon = is_buff and sample_buff_icon or sample_debuff_icon
		entry.applications = i -- count set to index to make order show
		entry.duration = sample_duration
	end
end

local aura_sort__is_only

local function aura_sort(a, b)
	if not a then
		return false
	elseif not b then
		return true
	end

	-- item buffs
	local a_slot, b_slot = a.weaponEnchantSlot, b.weaponEnchantSlot
	if a_slot and not b_slot then
		return true
	elseif not a_slot and b_slot then
		return false
	elseif a_slot and b_slot then
		return a_slot < b_slot
	end

	-- player auras (skip for NameOnly/ExpirationOnly)
	if not aura_sort__is_only then
		local a_mine, b_mine = a.isPlayerAura, b.isPlayerAura
		if a_mine ~= b_mine then
			if a_mine then
				return true
			elseif b_mine then
				return false
			end
		end
	end

	-- real auras
	local a_index, b_index = a.index, b.index
	if a_index ~= 0 and b_index == 0 then
		return true
	elseif a_index == 0 and b_index ~= 0 then
		return false
	end

	-- name
	if a_index == 0 and b_index == 0 then
		local a_name, b_name = a.name, b.name
		if a_name ~= b_name then
			if not a_name then
				return true
			elseif not b_name then
				return false
			end
			return a_name < b_name
		end
	end

	-- index order
	return a_index < b_index
end

-- Setups up the aura frame and fill it with the proper data
-- to display the proper aura.
local function set_aura(frame, db, aura_controls, aura, i, is_friend)
	local control = aura_controls[i]
	if not control then
		control = PitBull4.Controls.MakeAura(frame)
		control.cooldown.noCooldownCount = db.suppress_occ or nil
		aura_controls[i] = control
	end

	local unit = frame.unit
	local is_mine = aura.isPlayerAura
	local who = is_mine and "my" or "other"
	-- No way to know who applied a weapon buff so we have a separate category for them.
	if aura.weaponEnchantSlot then who = "weapon" end
	local rule = who .. '_' .. (aura.isHelpfulAura and "buffs" or "debuffs")

	local layout = aura.isHelpfulAura and db.layout.buff or db.layout.debuff
	control:SetFrameLevel(frame:GetFrameLevel() + layout.frame_level)

	control.index = aura.index
	control.id = aura.auraInstanceID
	control.is_mine = aura.isPlayerAura
	control.is_buff = aura.isHelpfulAura
	control.slot = aura.weaponEnchantSlot
	if aura.auraInstanceID then
		control.duration = GetAuraDuration(unit, aura.auraInstanceID)
		control.count = GetAuraApplicationDisplayCount(unit, aura.auraInstanceID)
	else -- used in config mode
		control.name = aura.name
		control.duration = aura.duration
		control.count = aura.applications
		control.debuff_type = aura.debuffType
	end

	local class_db = frame.classification_db
	if not db.click_through and class_db and not class_db.click_through then
		control:EnableMouse(true)
	else
		control:EnableMouse(false)
	end

	local texture = control.texture
	texture:SetTexture(aura.icon)
	if not frame.masque_group then
		if db.zoom_aura then
			texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		else
			texture:SetTexCoord(0, 1, 0, 1)
		end
	end

	if db.cooldown[rule] then
		control.cooldown:SetCooldownFromDurationObject(control.duration, true)
	else
		control.cooldown:Hide()
	end

	local texts_db = db.texts[rule]

	local count_db = texts_db.count
	local font, font_size = frame:GetFont(count_db.font, count_db.size)
	local count_text = control.count_text
	count_text:ClearAllPoints()
	count_text:SetPoint(count_db.anchor, control, count_db.anchor, count_db.offset_x, count_db.offset_y)
	count_text:SetFont(font, font_size, "OUTLINE")
	count_text:SetTextColor(unpack(count_db.color))
	count_text:SetText(control.count)

	if db.cooldown_text[rule] then
		local cooldown_text = control.cooldown_text
		local cooldown_text_db = texts_db.cooldown_text
		font,font_size = frame:GetFont(cooldown_text_db.font, cooldown_text_db.size)
		cooldown_text:SetFont(font, font_size, "OUTLINE")
		cooldown_text:ClearAllPoints()
		cooldown_text:SetPoint(cooldown_text_db.anchor, control, cooldown_text_db.anchor, cooldown_text_db.offset_x, cooldown_text_db.offset_y)
		if not cooldown_text_db.color_by_time then
			cooldown_text:SetTextColor(unpack(cooldown_text_db.color))
		end
		cooldown_text.color_by_time = cooldown_text_db.color_by_time
		PitBull4_Aura:EnableCooldownText(control)
	else
		PitBull4_Aura:DisableCooldownText(control)
	end

	local border_db
	if who == "weapon" then
		border_db = db.borders[rule]
	else
		border_db = db.borders[rule][is_friend and "friend" or "enemy"]
	end
	if border_db.enabled then
		local border = control.border
		local colors = PitBull4_Aura.db.profile.global.colors
		border:Show()

		local color_type = border_db.color_type
		if color_type == "weapon" and aura.weaponEnchantQuality then
			local r, g, b = GetItemQualityColor(aura.weaponEnchantQuality)
			border:SetVertexColor(r, g, b)

		elseif color_type == "type" then
			-- Use the Other color if there's not a color for the specific debuff type.
			local color = nil
			if aura.auraInstanceID then
				color = GetAuraDispelTypeColor(unit, aura.auraInstanceID, dispel_color_curve)
			elseif aura.debuffType then
				color = dispel_color_curve:Evaluate(aura.debuffType)
			end
			if color == nil then
				color = dispel_color_curve:Evaluate(0)
			end
			border:SetVertexColor(color:GetRGB())

		elseif color_type == "caster" then
			border:SetVertexColor(unpack(colors.caster[who]))

		elseif color_type == "custom" and border_db.custom_color then
			border:SetVertexColor(unpack(border_db.custom_color))
		else
			-- Unknown color type just set it to red, shouldn't actually ever get here.
			border:SetVertexColor(1,0,0)
		end
	else
		control.border:Hide()
	end
end

local function compare_units(unit_a, unit_b)
	return unit_a == unit_b or (not C_Secrets.ShouldUnitComparisonBeSecret(unit_a, unit_b) and UnitIsUnit(unit_a, unit_b))
end

-- If the src table has a valid weapon enchant entry for the slot
-- copy it to the dst table.  Uses #dst + 1 to determine next entry
local function copy_weapon_entry(src, dst, slot)
	local entry = src[slot]
	if entry and entry.weaponEnchantSlot then
		dst[#dst + 1] = CopyTable(entry)
	end
end

local function update_auras(frame, db, is_buff)
	-- Get the controls table
	local controls
	if is_buff then
		controls = frame.aura_buffs
		if not controls then
			controls = {}
			frame.aura_buffs = controls
		end
	else
		controls = frame.aura_debuffs
		if not controls then
			controls = {}
			frame.aura_debuffs = controls
		end
	end

	local unit = frame.unit
	local is_player = compare_units(unit, "player")
	local is_friend = unit and UnitIsFriend("player", unit)
	local max_auras = is_buff and db.max_buffs or db.max_debuffs

	get_aura_list(list, unit, db, is_buff, frame)

	-- If weapons are enabled and the unit is the player
	-- copy the weapon entries into the aura list
	if is_buff and db.enabled_weapons and is_player then
		local filter = db.layout.buff.filter
		copy_weapon_entry(weapon_list, list, INVSLOT_MAINHAND)
		if list[#list] and not PitBull4_Aura:FilterEntry(filter, list[#list], frame) then
			list[#list] = nil
		end
		copy_weapon_entry(weapon_list, list, INVSLOT_OFFHAND)
		if list[#list] and not PitBull4_Aura:FilterEntry(filter, list[#list], frame) then
			list[#list] = nil
		end
	end

	if frame.force_show then
		-- config mode so treat sample frames as friendly
		if not unit or not UnitExists(unit) then
			is_friend = true
		end

		-- Fill extra auras if we're in config mode
		get_aura_list_sample(list, unit, max_auras, db, is_buff, is_player)

		local layout_db = is_buff and db.layout.buff or db.layout.debuff
		if layout_db.sort_rule ~= "Unsorted" then
			aura_sort__is_only = layout_db.sort_rule == "NameOnly" or layout_db.sort_rule == "ExpirationOnly"
			table.sort(list, aura_sort)
		end
	end

	-- Limit the number of displayed buffs here after we
	-- have filtered and sorted to allow the most important
	-- auras to be displayed rather than randomly tossing
	-- some away that may not be our prefered auras
	local buff_count = (#list > max_auras) and max_auras or #list

	for i = 1, buff_count do
		set_aura(frame, db, controls, list[i], i, is_friend)
	end

	-- Remove unnecessary aura frames
	for i = buff_count + 1, #controls do
		controls[i] = controls[i]:Delete()
	end
end

local function clear_auras(frame, is_buff)
	local controls
	if is_buff then
		controls = frame.aura_buffs
	else
		controls = frame.aura_debuffs
	end

	if not controls then
		return
	end

	for i = 1, #controls do
		controls[i].cooldown.noCooldownCount = nil
		controls[i] = controls[i]:Delete()
	end
end

function PitBull4_Aura:ClearAuras(frame)
	clear_auras(frame, true) -- Buffs
	clear_auras(frame, false) -- Debuffs
end

function PitBull4_Aura:UpdateAuras(frame)
	local db = self:GetLayoutDB(frame)
	local highlight = db.highlight

	-- Start the Highlight Filter System
	if highlight then
		self:ResetHighlightFilter()
	end

	-- Buffs
	if db.enabled_buffs then
		update_auras(frame, db, true)
	else
		clear_auras(frame, true)
	end
	if highlight then
		self:HighlightFilterIterator(frame, db, true)
	end

	-- Debuffs
	if db.enabled_debuffs then
		update_auras(frame, db, false)
	else
		clear_auras(frame, false)
	end
	if highlight then
		self:HighlightFilterIterator(frame, db, false)
	end

	-- Finish the Highlight Filter System
	if highlight then
		self:SetHighlight(frame, db)
	end
end

-- table of frames to be updated on next filter update
local timed_filter_update = {}

--- Request that a frame is updated on the next timed update
-- The frame will only be updated once.  This is useful for
-- filters to request they be rerun on a frame for data that
-- changes with time.
-- @param frame the frame to update
-- @usage PitBull4_aura:RequestTimeFilterUpdate(my_frame)
-- @return nil
function PitBull4_Aura:RequestTimedFilterUpdate(frame)
	timed_filter_update[frame] = true
end

function PitBull4_Aura:UpdateFilters()
	for frame in pairs(timed_filter_update) do
		timed_filter_update[frame] = nil
		self:UpdateAuras(frame)
		self:LayoutAuras(frame)
	end
end
