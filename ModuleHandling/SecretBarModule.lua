-- This file provides the template for the bar and bar_provider modules.

local _G = _G
local PitBull4 = _G.PitBull4

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)

local expect = PitBull4.expect
local new, del = PitBull4.new, PitBull4.del
local call_color_function, call_background_color_function, call_texture_function

local HOSTILE_REACTION = 2
local NEUTRAL_REACTION = 4
local FRIENDLY_REACTION = 5

--
-- secret bar module implementation
--

local BarModule = PitBull4:NewModuleType("secret_bar", {
	size = 2,
	reverse = false,
	alpha = 1,
	background_alpha = 1,
	position = 1,
	side = "center",
	enabled = true,
	custom_color = nil,
	custom_background = nil,
	icon_on_left = true,
	color_by_class = false,
	color_pvp_by_class = false,
	hostility_color = false,
	hostility_color_npcs = false,
	animated = false,
}, true)

--- Handle the frame being hidden
-- @param frame the Unit Frame hidden.
-- @usage MyModule:OnHide(frame)
function BarModule:OnHide(frame)
	if PitBull4.DEBUG then
		expect(frame, 'typeof', 'frame')
	end

	local id = self.id
	local control = frame[id]
	if control then
		control:Hide()
	end
end

--- Clear the status bar for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function BarModule:ClearFrame(frame)
	if PitBull4.DEBUG then
		expect(frame, 'typeof', 'frame')
	end

	local id = self.id
	local control = frame[id]
	if not control then
		return false
	end

	frame[id] = control:Delete()
	return true
end

--- Update the status bar for the current module
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateStatusBar(frame)
-- @return whether the update requires :UpdateLayout to be called
function BarModule:UpdateFrame(frame)
	if PitBull4.DEBUG then
		expect(frame, 'typeof', 'frame')
	end

	local value, extra, icon
	if frame.unit and UnitExists(frame.unit) then
		value, extra, icon = self:GetValue(frame)
	end
	if frame.unit and not UnitExists(frame.unit) and frame.force_show and self.GetExampleValue then
		value, extra, icon = self:GetExampleValue(frame)
	end
	if not value then
		return self:ClearFrame(frame)
	end
	self.value = value

	local db = self:GetLayoutDB(frame)
	local id = self.id
	local control = frame[id]
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeStatusBar(frame)
		frame[id] = control
	end

	local texture, isAtlas = call_texture_function(self, frame)
	control:SetStatusBarTexture(texture)
	local r, g, b, a = call_color_function(self, frame)
	if isAtlas then
		control:SetStatusBarColor(1, 1, 1, 1) -- a * db.alpha
		control.bg:SetAtlas(texture)
	else
		control:GetStatusBarTexture():SetVertexColor(r, g, b, a)
		control.bg:SetTexture(texture)
	end

	control:SetBackgroundColor(call_background_color_function(self, frame, r, g, b))

	control:SetIcon(icon)
	control:SetIconPosition(db.icon_on_left)

	local reverse = db.reverse
	if extra == Enum.StatusBarTimerDirection.RemainingTime then
		reverse = not reverse
	end
	control:SetReverse(reverse)

	local interpolation
	if self.allow_animations and db.animated then
		interpolation = Enum.StatusBarInterpolation.ExponentialEaseOut
	else
		interpolation = Enum.StatusBarInterpolation.Immediate
	end
	control:SetValue(value, interpolation)
	control:Show()

	return made_control
end

--- Handle a new media key being added to SharedMedia
-- @param event the event from LibSharedMedia
-- @param mediatype the type of the media being added (e.g. "font", "statusbar")
-- @param key the name of the new media
function BarModule:LibSharedMedia_Registered(event, mediatype, key)
	if mediatype == "statusbar" then
		self:UpdateAll()
	end
end


function call_color_function(self, frame)
	local unit = frame.unit
	local bar_db = self:GetLayoutDB(frame)

	local alpha = bar_db.alpha
	local custom_color = bar_db.custom_color

	if custom_color then
		return custom_color[1], custom_color[2], custom_color[3], alpha
	end

	local r, g, b, _, override
	if frame.unit and UnitExists(unit) then
		r, g, b, _, override = self:GetColor(frame)
	end

	if not override and unit then
		if UnitIsPlayer(unit) or UnitInPartyIsAI(unit) then
			if bar_db.color_by_class and (bar_db.color_pvp_by_class or UnitIsFriend("player", unit)) then
				local _, class = UnitClass(unit)
				local t = PitBull4.ClassColors[class]
				if t then
					r, g, b = t[1], t[2], t[3]
				end
			elseif bar_db.hostility_color then
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
				elseif UnitIsFriend("player", unit) then
					-- on my team
					r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
				else
					-- either enemy or friend, no violence
					r, g, b = unpack(PitBull4.ReactionColors.civilian)
				end
			end
		elseif bar_db.hostility_color_npcs then
			local reaction = UnitReaction(unit, "player")
			if reaction then
				if reaction > FRIENDLY_REACTION then
					r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
				elseif reaction > HOSTILE_REACTION then
					r, g, b = unpack(PitBull4.ReactionColors[reaction])
				else
					r, g, b = unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				end
			else
				if UnitIsFriend("player", unit) then
					r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
				elseif UnitIsEnemy("player", unit) then
					r, g, b = unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				end
			end
		end
	end
	if unit and not UnitExists(unit) and frame.force_show and self.GetExampleColor then
		r, g, b = self:GetExampleColor(frame)
	end
	return r, g, b, alpha
end

local function normal_to_bg_color(r, g, b, a)
	return (r + 0.2)/3, (g + 0.2)/3, (b + 0.2)/3, a
end

function call_background_color_function(self, frame, fg_r, fg_g, fg_b)
	local bar_db = self:GetLayoutDB(frame)

	local is_secret_fg_color = hasanysecretvalues(fg_r, fg_g, fg_b)
	local alpha = bar_db.background_alpha
	local custom_background = bar_db.custom_background

	local r, g, b, _, override
	if is_secret_fg_color and self.GetSecretBackgroundColor then
		r, g, b = self:GetSecretBackgroundColor(frame)
		if r then
			return r, g, b, alpha
		end
	end
	if not self.GetBackgroundColor then
		if custom_background then
			return custom_background[1], custom_background[2], custom_background[3], alpha
		end
		if not is_secret_fg_color then
			return normal_to_bg_color(fg_r, fg_g, fg_b, alpha)
		end
		return nil, nil, nil, alpha
	end
	if frame.unit and UnitExists(frame.unit) then
		r, g, b, _, override = self:GetBackgroundColor(frame)
	end
	if not override and custom_background then
		return custom_background[1], custom_background[2], custom_background[3], alpha
	end
	if (not frame.unit or not UnitExists(frame.unit)) and frame.force_show and self.GetExampleBackgroundColor then
		r, g, b = self:GetExampleBackgroundColor(frame)
	end
	if not r and not is_secret_fg_color then
		r, g, b = normal_to_bg_color(fg_r, fg_g, fg_b)
	end
	return r, g, b, alpha
end

function call_texture_function(self, frame)
	local texture, isAtlas
	if frame.unit and UnitExists(frame.unit) and self.GetTexture then
		texture, isAtlas = self:GetTexture(frame)
	end
	if not texture and LibSharedMedia then
		texture = LibSharedMedia:Fetch("statusbar", self:GetLayoutDB(frame).texture or frame.layout_db.bar_texture or "Blizzard")
		isAtlas = false
	end
	if not texture then
		texture = [[Interface\TargetingFrame\UI-StatusBar]]
		isAtlas = false
	end
	return texture, isAtlas
end
