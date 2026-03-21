
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Background = PitBull4:NewModule("Background")

PitBull4_Background:SetModuleType("custom")
PitBull4_Background:SetName(L["Background"])
PitBull4_Background:SetDescription(L["Show a flat background for your unit frames."])
PitBull4_Background:SetDefaults({
	portrait = false,
	fallback_style = "three_dimensional",
	color = { 0, 0, 0, 0.5 }
})

function PitBull4_Background:OnEnable()
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
end

function PitBull4_Background:UNIT_PORTRAIT_UPDATE(_, unit)
	if unit then
		self:UpdateForUnitID(unit)
	end
end

-- this is here to allow it to be overridden, e.g., aggro module
function PitBull4_Background:GetColor(frame)
	return unpack(PitBull4_Background:GetLayoutDB(frame).color)
end

function PitBull4_Background:UpdateFrame(frame)
	local background = frame.Background
	if not background then
		background = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
		frame.Background = background
		background:SetAllPoints(frame)
	end

	local r, g, b, a = self:GetColor(frame)
	if r and g and b then
		background:SetColorTexture(r, g, b, a)
		background:Show()
	else
		background:Hide()
	end

	-- 3D Portrait
	local layout_db = self:GetLayoutDB(frame)
	if not layout_db.portrait then
		return false
	end

	local unit = frame.unit
	local falling_back = false
	if not unit or (not UnitExists(unit) and not ShowBossFrameWhenUninteractable(unit)) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
		falling_back = true
	end

	local portrait = frame.PortraitBG
	local created = not portrait
	if created then
		portrait = PitBull4.Controls.MakePlayerModel(frame)
		portrait:SetFrameLevel(frame:GetFrameLevel()) -- don't go above bars and indicators
		portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
		portrait:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
		portrait.guid = frame.guid
		frame.PortraitBG = portrait
	end

	local should_update = created or (not issecretvalue(frame.guid) and not issecretvalue(portrait.guid) and portrait.guid ~= frame.guid)
	if should_update then
		portrait:ClearModel()
		if not falling_back then
			portrait:SetUnit(unit)
			portrait:SetPortraitZoom(1)
			portrait:SetPosition(0, 0, 0)
		elseif layout_db.fallback_style == "three_dimensional" then
			portrait:SetModelScale(1)
			portrait:SetModel([[Interface\Buttons\talktomequestionmark.m2]])
			portrait:SetPosition(-0.55, 0, 0)
		end
		portrait.guid = frame.guid
	end
	portrait:Show()

	return created
end

function PitBull4_Background:ClearFrame(frame)
	if frame.Background then
		frame.Background = frame.Background:Delete()
	end
	if frame.PortraitBG then
		frame.PortraitBG = frame.PortraitBG:Delete()
		return true
	end
	return false
end

function PitBull4_Background:OnHide(frame)
	if frame.Background then
		frame.Background:Hide()
	end
	if frame.PortraitBG then
		frame.PortraitBG:Hide()
	end
end

PitBull4_Background:SetLayoutOptionsFunction(function(self)
	return 'color', {
		type = 'color',
		name = L["Color"],
		desc = L["Color that the background should be."],
		hasAlpha = true,
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).color
			color[1], color[2], color[3], color[4] = r, g, b, a

			PitBull4.Options.UpdateFrames()
		end,
	}, 'portrait', {
		type = 'toggle',
		name = L["Portrait"],
		desc = L["Show a portrait of the unit."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).portrait
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).portrait = value

			for frame in PitBull4:IterateFrames() do
				if self:GetLayoutDB(frame).enabled then
					self:Clear(frame)
					self:Update(frame)
				end
			end
		end,
	}, 'fallback_style', {
		type = 'select',
		name = L["Fallback style"],
		desc = L["Set the portrait style for when the normal style can't be shown, such as if they are out of visibility."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).fallback_style
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).fallback_style = value

			for frame in PitBull4:IterateFrames() do
				if self:GetLayoutDB(frame).portrait then
					self:Clear(frame)
					self:Update(frame)
				end
			end
		end,
		values = {
			["three_dimensional"] = L["3D question mark"],
			["blank"] = L["Blank"],
		},
	}
end)
