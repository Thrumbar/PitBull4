
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.4
local EXAMPLE_ICON = 136222 -- Spell_Shadow_Teleport

local PitBull4_CastBar = PitBull4:NewModule("CastBar")

PitBull4_CastBar:SetModuleType("secret_bar")
PitBull4_CastBar:SetName(L["Cast bar"])
PitBull4_CastBar:SetDescription(L["Show a cast bar."])
PitBull4_CastBar:SetDefaults({
	size = 1,
	position = 10,
	show_icon = true,
	auto_hide = false,
	idle_background = false,
},{
	casting_interruptible_color = { 1, 0.7, 0 },
	casting_uninterruptible_color = { 1, 222/255, 144/255},
	casting_complete_color = { 0, 1, 0 },
	casting_failed_color = { 1, 0, 0 },
	channel_interruptible_color = { 0, 0, 1 },
	channel_uninterruptible_color = { 96/255, 180/255, 211/255 },
})

local cast_data = {}
PitBull4_CastBar.cast_data = cast_data

local timer_frame = CreateFrame("Frame")
timer_frame:Hide()
timer_frame:SetScript("OnUpdate", function()
	PitBull4_CastBar:FixCastData()
	PitBull4_CastBar:UpdateAll()
end)


local casting_interruptible_color = CreateColor()
local casting_uninterruptible_color = CreateColor()
local channel_interruptible_color = CreateColor()
local channel_uninterruptible_color = CreateColor()

local function update_colors()
	local db = PitBull4_CastBar.db.profile.global
	casting_interruptible_color:SetRGB(unpack(db.casting_interruptible_color))
	casting_uninterruptible_color:SetRGB(unpack(db.casting_uninterruptible_color))
	channel_interruptible_color:SetRGB(unpack(db.channel_interruptible_color))
	channel_uninterruptible_color:SetRGB(unpack(db.channel_uninterruptible_color))
end

function PitBull4_CastBar:OnEnable()
	update_colors()

	self:RegisterEvent("UNIT_SPELLCAST_START", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "UpdateInfo")

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
end

function PitBull4_CastBar:OnDisable()
	timer_frame:Hide()
end

local new, del
do
	local pool = setmetatable({}, {__mode='k'})
	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		end

		return {}
	end
	function del(t)
		wipe(t)
		pool[t] = true
	end
end

local last = 0
function PitBull4_CastBar:GetValue(frame)
	local unit = frame.unit
	if unit:match("%wtarget$") then
		return nil
	end

	local data = cast_data[unit]
	if not data then
		self:UpdateInfo(nil, unit)
		data = cast_data[unit]
	end

	local db = self:GetLayoutDB(frame)
	if not data then
		if db.auto_hide then
			return nil
		end
		return 0, nil, nil
	end

	local icon = db.show_icon and data.icon or nil

	if data.casting or data.channeling or data.empowering then
		if data.direction == Enum.StatusBarTimerDirection.RemainingTime then
			return data.duration:GetRemainingPercent(), nil, icon
		end
		return data.duration:GetElapsedPercent(), nil, icon
	elseif data.stop_value then
		return data.stop_value, nil, icon
	end

	if db.auto_hide then
		return nil
	end
	return 0, nil, icon
end

function PitBull4_CastBar:GetExampleValue(frame)
	local db = self:GetLayoutDB(frame)
	return EXAMPLE_VALUE, nil, db.show_icon and EXAMPLE_ICON or nil
end

function PitBull4_CastBar:GetColor(frame, value)
	local data = cast_data[frame.unit]
	if not data then
		return 0, 0, 0, 0
	end

	if data.casting then
		local color = C_CurveUtil.EvaluateColorFromBoolean(data.uninterruptible, casting_uninterruptible_color, casting_interruptible_color)
		return color:GetRGBA()
	elseif data.channeling then
		local color = C_CurveUtil.EvaluateColorFromBoolean(data.uninterruptible, channel_uninterruptible_color, channel_interruptible_color)
		return color:GetRGBA()
	elseif data.fade_out then
		local alpha, r, g, b
		local stop_time = data.stop_time
		if stop_time then
			alpha = stop_time - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			return 0, 0, 0, 0
		else
			-- Decide which color to use
			if not data.was_channeling then -- Last cast was a normal one...
				if data.failed then
					r, g, b = unpack(self.db.profile.global.casting_failed_color)
				else
					r, g, b = unpack(self.db.profile.global.casting_complete_color)
				end
			else -- Last cast was a channel...
				local color = C_CurveUtil.EvaluateColorFromBoolean(data.uninterruptible, channel_uninterruptible_color, channel_interruptible_color)
				r, g, b = color:GetRGB()
			end
			return r, g, b, alpha
		end
	end
	return 0, 0, 0, 0
end

function PitBull4_CastBar:GetBackgroundColor(frame)
	local data = cast_data[frame.unit]

	if not data then
		if not self:GetLayoutDB(frame).idle_background then
			return nil, nil, nil, 0
		end
	elseif data.fade_out then
		local alpha
		local stop_time = data.stop_time
		if stop_time then
			alpha = stop_time - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			alpha = 0
		end
		return nil, nil, nil, alpha
	end
end

function PitBull4_CastBar:GetExampleColor(frame)
	return 0, 1, 0, 1
end

function PitBull4_CastBar:UpdateInfo(event, unit, _, _, ...)
	local data = cast_data[unit]
	if not data then
		data = new()
		cast_data[unit] = data
	end

	local spell, text, icon, _, _, _, _, uninterruptible, spell_id, cast_id = UnitCastingInfo(unit)
	local channeling, empowering = false, false
	local direction, duration = Enum.StatusBarTimerDirection.ElapsedTime
	if spell then
		duration = UnitCastingDuration(unit)
	else
		local is_empowered
		spell, text, icon, _, _, _, uninterruptible, spell_id, is_empowered, _, cast_id = UnitChannelInfo(unit)
		if is_empowered then
			empowering = true
			duration = UnitEmpoweredChannelDuration(unit)
		else
			channeling = true
			duration = UnitChannelDuration(unit)
			direction = Enum.StatusBarTimerDirection.RemainingTime
		end
	end

	local event_cast_id, interrupted_by
	if event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		interrupted_by, event_cast_id = ...
	elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
		_, interrupted_by, event_cast_id = ...
	else
		event_cast_id = ...
	end

	if data.cast_id == event_cast_id then
		if interrupted_by or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED"  then
			data.failed = true
			data.interrupted_by = interrupted_by
		end
	end

	-- casting
	if spell then
		data.spell = text
		data.icon = icon
		data.duration = duration
		data.direction = direction

		data.casting = not channeling
		data.channeling = channeling
		data.empowering = empowering
		data.uninterruptible = uninterruptible
		data.was_channeling = channeling -- persistent state even after interrupted

		data.spell_id = spell_id
		data.cast_id = cast_id

		data.fade_out = false
		data.stop_time = nil
		data.stop_value = nil

		timer_frame:Show()
		return
	end

	-- not casting
	if not data.spell then
		cast_data[unit] = del(data)
		if not next(cast_data) then
			timer_frame:Hide()
		end
		return
	end

	if data.cast_id == event_cast_id then
		if event == "UNIT_SPELLCAST_SUCCEEDED" then
		-- This is necessary because if the interrupt happens just as the cast finishes
		-- it can look to the client like it failed but the server sends the success
		-- message after.
			data.failed = false
		end
	end

	data.casting = false
	data.channeling = false
	data.empowering = false
	data.fade_out = true
	if not data.stop_time then
		data.stop_time = GetTime()
		if data.direction == Enum.StatusBarTimerDirection.RemainingTime then
			data.stop_value = data.duration:GetRemainingPercent()
		else
			data.stop_value = data.duration:GetElapsedPercent()
		end
	end
end

local tmp = {}
function PitBull4_CastBar:FixCastData()
	local frame
	local current_time = GetTime()
	for unit, data in pairs(cast_data) do
		tmp[unit] = data
	end
	for unit, data in pairs(tmp) do
		local found = false
		for frame in PitBull4:IterateFramesForUnitID(unit) do
			if self:GetLayoutDB(frame).enabled then
				found = true
				if data.fade_out then
					local alpha = 0
					local stop_time = data.stop_time
					if stop_time then
						alpha = stop_time - current_time + 1
					end
					if alpha <= 0 then
						cast_data[unit] = del(data)
						self:UpdateForUnitID(unit)
					end
				elseif not data.casting and not data.channeling and not data.empowering then
					cast_data[unit] = del(data)
					self:UpdateForUnitID(unit)
				end
				break
			end
		end
		if not found then
			cast_data[unit] = del(data)
		end
	end
	if not next(cast_data) then
		timer_frame:Hide()
	end
	wipe(tmp)
end

function PitBull4_CastBar:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
	for i = 1, 8 do
		self:UpdateInfo(event, ("boss%d"):format(i))
	end
end

PitBull4_CastBar:SetLayoutOptionsFunction(function(self)
	return 'auto_hide', {
		name = L["Auto-hide"],
		desc = L["Automatically hide the cast bar when not casting."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).auto_hide
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).auto_hide = value

			PitBull4.Options.UpdateFrames()
		end,
	}, 'show_icon', {
		name = L["Show icon"],
		desc = L["Whether to show the icon that is being cast."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_icon
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_icon = value

			PitBull4.Options.RefreshFrameLayouts()
		end,
	}, 'icon_on_left', {
		name = L["Icon position"],
		desc = L["What side of the bar to show the icon on."],
		type = 'select',
		values = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			local icon_on_left = db.icon_on_left
			local side = db.side
			local reverse = db.reverse

			if not reverse then
				if side == "center" then
					return {
						left = L["Left"],
						right = L["Right"],
					}
				else
					return {
						left = L["Bottom"],
						right = L["Top"],
					}
				end
			else
				if side == "center" then
					return {
						left = L["Right"],
						right = L["Left"],
					}
				else
					return {
						left = L["Top"],
						right = L["Bottom"],
					}
				end
			end
		end,
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).icon_on_left and "left" or "right"
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).icon_on_left = (value == "left")

			PitBull4.Options.RefreshFrameLayouts()
		end,
		hidden = function(info)
			return not PitBull4.Options.GetLayoutDB(self).show_icon
		end
	}, 'idle_background', {
		name = L["Idle background"],
		desc = L["Show background on the cast bar when nothing is being cast."],
		type = 'toggle',
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.idle_background and not db.auto_hide
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).idle_background = value

			PitBull4.Options.RefreshFrameLayouts()
		end,
		disabled = function(info)
			return PitBull4.Options.GetLayoutDB(self).auto_hide
		end,
	}
end)

PitBull4_CastBar:SetColorOptionsFunction(function(self)
	return 'casting', {
		type = 'group',
		name = L["Casting"],
		inline = true,
		args = {
			casting_interruptible_color = {
				type = 'color',
				name = L["Interruptible"],
				desc = L["Sets which color to use on casting bar of casts that are interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.casting_interruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_interruptible_color = { r, g, b }
					casting_interruptible_color:SetRGB(r, g, b)
					self:UpdateAll()
				end,
				order = 1,
			},
			casting_uninterruptible_color = {
				type = 'color',
				name = L["Uninterruptible"],
				desc = L["Sets which color to use on casting bar of casts that are not interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.casting_uninterruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_uninterruptible_color = { r, g, b }
					casting_interruptible_color:SetRGB(r, g, b)
					self:UpdateAll()
				end,
				order = 2,
			},
			casting_complete_color = {
				type = 'color',
				name = L["Complete"],
				desc = L["Sets which color to use on casting bar of casts that completed."],
				get = function(info)
					return unpack(self.db.profile.global.casting_complete_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_complete_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 3,
			},
			casting_failed_color = {
				type = 'color',
				name = L["Failed"],
				desc = L["Sets which color to use on casting bar of casts that failed."],
				get = function(info)
					return unpack(self.db.profile.global.casting_failed_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_failed_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 4,
			},
		},
	}, 'channeling', {
		type = 'group',
		name = L["Channeling"],
		inline = true,
		args = {
			channel_interruptible_color = {
				type = 'color',
				name = L["Interruptible"],
				desc = L["Sets which color to use on casting bar of channeled casts that are interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.channel_interruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.channel_interruptible_color = { r, g, b }
					channel_interruptible_color:SetRGB(r, g, b)
					self:UpdateAll()
				end,
				order = 1,
			},
			channel_uninterruptible_color = {
				type = 'color',
				name = L["Uninterruptible"],
				desc = L["Sets which color to use on casting bar of channeled casts that are not interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.channel_uninterruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.channel_uninterruptible_color = { r, g, b }
					channel_uninterruptible_color:SetRGB(r, g, b)
					self:UpdateAll()
				end,
				order = 2,
			},
		},
	},
	function(info)
		self.db.profile.global.casting_interruptible_color = { 1, 0.7, 0 }
		self.db.profile.global.casting_uninterruptible_color = { 1, 222/255, 144/255 }
		self.db.profile.global.casting_complete_color = { 0, 1, 0 }
		self.db.profile.global.casting_failed_color = { 1, 0, 0 }
		self.db.profile.global.channel_interruptible_color = { 0, 0, 1 }
		self.db.profile.global.channel_uninterruptible_color = { 96/255, 180/255, 211/255 }
		update_colors()
	end
end)
