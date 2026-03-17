
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local GetAuraDataBySlot = C_UnitAuras.GetAuraDataBySlot
local GetAuraDispelTypeColor = C_UnitAuras.GetAuraDispelTypeColor
local GetAuraSlots = C_UnitAuras.GetAuraSlots
local IsAuraFilteredOutByInstanceID = C_UnitAuras.IsAuraFilteredOutByInstanceID

local new, del = PitBull4.new, PitBull4.del
local wipe = _G.table.wipe

local HighlightNormal_path = [[Interface\AddOns\PitBull4\Modules\Aura\HighlightNormal]]
local HighlightBorder_path = [[Interface\AddOns\PitBull4\Modules\Aura\HighlightBorder]]
local HighlightThinBorder_path = [[Interface\AddOns\PitBull4\Modules\Aura\HighlightThinBorder]]

-- Handle the results table used for tracking the priority of auras to highlight
local results = {}

-- Clean the results table before starting a highlight filter
function PitBull4_Aura:ResetHighlightFilter()
	for i = 1, #results do
		results[i] = del(results[i])
	end
end

-- Replacement iterator for use when auras aren't being displayed on a frame we want to highlight.
-- Arguments mirror the update_auras() function in Update.lua.
function PitBull4_Aura:HighlightFilterIterator(frame, db, is_buff)
	local unit = frame.unit
	if not unit then return end
	local filter = is_buff and "HELPFUL" or "HARMFUL"
	local player_filter = is_buff and "HELPFUL|PLAYER" or "HARMFUL|PLAYER"

	-- Loop through the auras
	local slots = {GetAuraSlots(unit, filter)}
	for i = 2, #slots do -- continuationToken is the first return value of UnitAuraSlots
		local entry = GetAuraDataBySlot(unit, slots[i])
		if entry then -- Protect against GetAuraDataBySlot desyncing with GetAuraSlots
			entry.id = entry.auraInstanceID
			entry.isPlayerAura = not IsAuraFilteredOutByInstanceID(unit, entry.auraInstanceID, player_filter)
			entry.isHelpfulAura = is_buff
			entry.isHarmfulAura = not is_buff

			self:HighlightFilter(db, entry, frame)
		end
	end
end

-- Takes a single aura entry and runs the Highlight Filter on it.
-- Storing the results in the results table for use by SetHighlight() later
function PitBull4_Aura:HighlightFilter(db, entry, frame)
	local highlight_filters = db.highlight_filters_new

	-- Iterate the highlight filters
	for id = 1, #highlight_filters do
		local filter_result = self:FilterEntry(highlight_filters[id], entry, frame, true)
		if filter_result then
			-- Setup an entry in our result table
			local result = new()
			result.priority = id

			-- Determine the color for the match
			if db.highlight_filters_color_by_type_new[id] then
				local color = entry.id and GetAuraDispelTypeColor(frame.unit, entry.id, self.dispel_color_curve)
				if color == nil then
					color = self.dispel_color_curve:Evaluate(0)
				end
				result.color = {color:GetRGB()}
			else
				result.color = db.highlight_filters_custom_color_new[id]
			end

			-- Add the entry
			results[#results + 1] = result
		end
	end
end

-- Sort the highlights to select the best possible match
local function result_sort(a, b)
	if not a then
		return false
	elseif not b then
		return true
	end

	local a_priority, b_priority = a.priority, b.priority
	if a_priority ~= b_priority then
		return a_priority < b_priority
	end
end


-- Handle displaying or removing the actual highlight based on the
-- contents of the results table.
function PitBull4_Aura:SetHighlight(frame, db)
	-- Sort the table first to ensure the first entry is the highest priority
	table.sort(results, result_sort)

	-- Grab the highlight to display.  TODO: Handle display of multiple highlights
	local result = results[1]

	local aura_highlight = frame.aura_highlight
	if result then
		-- Display the highlight
		if not aura_highlight then
			aura_highlight = PitBull4.Controls.MakeTexture(frame.overlay, "OVERLAY")
			frame.aura_highlight = aura_highlight
		end

		local highlight_style = db.highlight_style
		if highlight_style == "border" then
			aura_highlight:SetTexture(HighlightBorder_path)
		elseif highlight_style == "thinborder" then
			aura_highlight:SetTexture(HighlightThinBorder_path)
		else
			aura_highlight:SetTexture(HighlightNormal_path)
		end

		aura_highlight:SetBlendMode("ADD")
		aura_highlight:SetAlpha(0.75)
		aura_highlight:SetAllPoints(frame)
		aura_highlight:SetVertexColor(unpack(result.color, 1, 3))
	else
		-- No highlight so remove one if we have one showing
		if aura_highlight then
			frame.aura_highlight = aura_highlight:Delete()
		end
	end
end
