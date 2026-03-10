-- Controls.lua : Implement the controls we need for the Aura module.

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

-- Table of functions included into the aura controls
local Aura = {}

-- Table of scripts set on a control
local Aura_scripts = {}

-- Calculate the path to the texture for the borders.
local border_path = [[Interface\AddOns\PitBull4\Modules\Aura\border]]

-- Get the unit the aura applies to.
function Aura:GetUnit()
	return self:GetParent().unit
end


-- Update handler for tooltips.
function Aura:UpdateTooltip()
	if self.id then
		-- Real Buffs
		GameTooltip:SetUnitAuraByAuraInstanceID(self:GetUnit(), self.id)
	elseif self.slot then
		local has_item = GameTooltip:SetInventoryItem("player", self.slot)
		if not has_item then
			GameTooltip:ClearLines()
			GameTooltip:AddLine(self.name, 1, 0.82, 0)
			GameTooltip:AddLine(L["Sample tempoary weapon enchant created by PitBull to allow you to see the results of your configuration easily."], 1, 1, 1, 1)
			GameTooltip:Show()
		end
	else
		-- Sample auras for config mode
		GameTooltip:ClearLines()
		-- Note that debuff_type gets localized here when displaying it
		-- because it needs to be in English for sorting and border
		-- purposes.  However the debuff types still need to be in our
		-- localization tables.  They are L["Poison"], L["Magic"],
		-- L["Disease"], L["Enrage"], L["Bleed"]
		GameTooltip:AddDoubleLine(self.name, self.debuff_type and L[self.debuff_type] or "", 1, 0.82, 0, 1, 0.82, 0)
		GameTooltip:AddLine(L["Sample aura created by PitBull to allow you to see the results of your configuration easily."], 1, 1, 1, 1)
		if self.is_mine then
			GameTooltip:AddLine(L["Aura shown as if cast by you."], 1, 0.82, 0, 1)
		else
			GameTooltip:AddLine(L["Aura shown as if cast by someone else."], 1, 0.82, 0, 1)
		end
		GameTooltip:Show()
	end
end

-- Click handler to allow buffs to be canceled.
-- Not in the Aura table since it is only active on
-- buff aura controls.
local function OnClick(self)
	if not self.is_buff or not "player" == self:GetUnit() then return end
	local slot = self.slot
	if InCombatLockdown() or slot then return end
	if slot then
		if slot == _G.INVSLOT_MAINHAND then
			CancelItemTempEnchantment(1)
		elseif slot == _G.INVSLOT_OFFHAND then
			CancelItemTempEnchantment(2)
		end
	else
		CancelUnitBuff("player", self.index)
	end
end

function Aura_scripts:OnEnter()
	if GameTooltip:IsForbidden() then return end
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT") -- self:IsAnchoringRestricted() and "ANCHOR_CURSOR" or
	self:UpdateTooltip()
end

function Aura_scripts:OnLeave()
	if GameTooltip:IsForbidden() then return end
	GameTooltip:Hide()
end

-- Control for the Auras
PitBull4.Controls.MakeNewControlType("Aura", "Button", function(control)
	-- onCreate
	control:RegisterForClicks("RightButtonUp")
	control:SetScript("OnClick", OnClick)

	local texture = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.texture = texture
	texture:SetAllPoints(control)

	local overlay = PitBull4.Controls.MakeFrame(control, "OVERLAY")
	control.overlay = overlay
	overlay:SetAllPoints(control)

	local border = PitBull4.Controls.MakeTexture(control, "BORDER")
	control.border = border
	border:SetAllPoints(control)
	border:SetTexture(border_path)

	local stealable = PitBull4.Controls.MakeTexture(control, "OVERLAY")
	stealable:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
	stealable:SetPoint("TOPLEFT", -3, 3)
	stealable:SetPoint("BOTTOMRIGHT", 3, -3)
	stealable:SetBlendMode("ADD")
	stealable:Hide()
	control.stealable = stealable

	local count_text = PitBull4.Controls.MakeFontString(overlay, "OVERLAY")
	control.count_text = count_text
	count_text:SetShadowColor(0, 0, 0, 1)
	count_text:SetShadowOffset(0.8, -0.8)
	count_text:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	local cooldown = PitBull4.Controls.MakeCooldown(control)
	control.cooldown = cooldown
	cooldown:SetReverse(true)
	-- cooldown:SetDrawBling(false)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true)
	-- cooldown:SetMinimumCountdownDuration(0)
	cooldown:SetAllPoints(control)

	-- Set the overlay above the cooldown spinner so the fonts will be over it.
	overlay:SetFrameLevel(cooldown:GetFrameLevel()+1)

	local cooldown_text = PitBull4.Controls.MakeFontString(overlay, "OVERLAY")
	control.cooldown_text = cooldown_text
	cooldown_text:SetShadowColor(0, 0, 0, 1)
	cooldown_text:SetShadowOffset(0.8, -0.8)
	cooldown_text:SetPoint("TOP", control, "TOP", 0, 0)

	for k,v in pairs(Aura) do
		control[k] = v
	end
	for k,v in pairs(Aura_scripts) do
		control:SetScript(k, v)
	end

end, function(control)
	-- onRetrieve
	-- It's important to note that you should never ever do something
	-- here that is dependent upon the actual aura being set or even
	-- the unit of the frame it is parented to.  It is fine to do things
	-- that depend upon the frame it is parented to here.  Other than
	-- that everything should be done when the actual aura is set on
	-- the control.  This is because the controls are recyled unless
	-- the number of them changes a new control will not be retrieved.

	local group = control:GetParent().masque_group
	if group then
		group:AddButton(control, {
			Icon = control.texture,
			Cooldown = control.cooldown,
			Border = control.border,
			-- Count = control.count_text,
			-- Duration = control.cooldown_text,
		}, "Legacy")
	else
		-- reset the control layout
		local texture = control.texture
		texture:SetAllPoints(control)
		texture:SetTexCoord(0, 1, 0, 1)

		local border = control.border
		border:SetAllPoints(control)
		border:SetTexture(border_path)
		border:SetBlendMode("BLEND")

		local cooldown = control.cooldown
		cooldown:SetAllPoints(control)
		cooldown:SetFrameLevel(control:GetFrameLevel() + 1)
		control.overlay:SetFrameLevel(cooldown:GetFrameLevel() + 1)
	end
end, function(control)
	-- onDelete
	control:SetScript("OnUpdate", nil)
	PitBull4_Aura:DisableCooldownText(control)

	local group = control:GetParent().masque_group
	if group then
		group:RemoveButton(control)

		-- Stop frame level tampering (Masque 8.0)
		control.__MSQ_Cooldown = nil

		-- Remove the "Blizzard" skin
		local texture = control.__MSQ_Normal or control.__MSQ_NormalTexture
		if texture then
			texture:SetTexture(nil)
		end
	end
end)
