
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

-- constants for formating time
local DAY_ONELETTER_ABBR = _G.DAY_ONELETTER_ABBR:gsub("%s", "") -- "%dd"
local HOUR_ONELETTER_ABBR = _G.HOUR_ONELETTER_ABBR:gsub("%s", "") -- "%dh"
local MINUTE_ONELETTER_ABBR = _G.MINUTE_ONELETTER_ABBR:gsub("%s", "") -- "%dm"

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local next_text_update
local elapsed_since_text_update = 0
timerFrame:SetScript("OnUpdate",function(self, elapsed)
	next_text_update = next_text_update - elapsed
	elapsed_since_text_update = elapsed_since_text_update + elapsed
	if next_text_update <= 0 then
		next_text_update = PitBull4_Aura:UpdateCooldownTexts(elapsed_since_text_update)
		elapsed_since_text_update = 0
	end
	if not next_text_update then
		self:Hide()
	end
end)

local cooldown_texts = {}

local time_left_color_curve = C_CurveUtil.CreateColorCurve()
time_left_color_curve:AddPoint(0.1, CreateColor(1,0,0)) -- less than 10% so stay red.
time_left_color_curve:AddPoint(0.2, CreateColor(1,1,0)) -- fade from yellow to red between 20% left to 10% left
time_left_color_curve:AddPoint(0.3, CreateColor(0,1,0)) -- fade from green to yellow betwee 30% left to 20% left

local function format_time(seconds, threshold)
	threshold = threshold or 1.5
	if seconds >= 86400 * threshold then
		return DAY_ONELETTER_ABBR,floor(seconds/86400)
	elseif seconds >= 3600 * threshold then
		return HOUR_ONELETTER_ABBR,ceil(seconds/3600)
	elseif seconds >= 120 * threshold then
		return MINUTE_ONELETTER_ABBR,ceil(seconds/60)
	elseif seconds > 60 then
		seconds = ceil(seconds)
		return "%d:%02d",seconds/60,seconds%60
	elseif seconds < 3 then
		return "%.1f",seconds
	end
	return "%d",ceil(seconds)
end

local function update_cooldown_text(aura)
	local cooldown_text = aura.cooldown_text
	if not cooldown_text:IsShown() then return end
	local duration = aura.duration
	if not duration then return end

	if cooldown_text.color_by_time then
		local color = duration:EvaluateRemainingPercent(time_left_color_curve)
		cooldown_text:SetTextColor(color:GetRGB())
	end
	-- cooldown_text:SetAlphaFromBoolean(duration:IsZero(), 0, 1)

	local time_left = duration:GetRemainingDuration()
	if issecretvalue(time_left) or time_left == 0 then
		cooldown_text:SetText(C_StringUtil.TruncateWhenZero(time_left)) -- XXX wtf, no formatters?
	elseif time_left >= 0 then
		cooldown_text:SetFormattedText(format_time(time_left))
		local new_time = 0
		if time_left >= 3600 then
			new_time = 30
		elseif time_left >= 180 then
			new_time = 1
		elseif time_left >= 60 then
			new_time = 0.5
		elseif time_left < 3 then
			new_time = 0
		else
			new_time = 0.25
		end
		return new_time
	end
end

function PitBull4_Aura:EnableCooldownText(aura)
	local cooldown_text = aura.cooldown_text
	if not cooldown_text then return end
	cooldown_text:Show()
	cooldown_texts[aura] = 0
	next_text_update = 0
	timerFrame:Show()
end

function PitBull4_Aura:DisableCooldownText(aura)
	local cooldown_text = aura.cooldown_text
	if cooldown_text then
		cooldown_text:Hide()
	end
	cooldown_texts[aura] = nil
end

function PitBull4_Aura:UpdateCooldownTexts(elapsed)
	local min_time
	for aura, time in pairs(cooldown_texts) do
		time = time - elapsed
		if time <= 0 then
			time = update_cooldown_text(aura,elapsed)
		end
		cooldown_texts[aura] = time
		if not min_time or (time and time < min_time) then
			min_time = time
		end
	end
	return min_time
end
