
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_RaidTargetIcon = PitBull4:NewModule("RaidTargetIcon")

-- Source: Interface\AddOns\Blizzard_UnitFrame\Mainline\TargetFrame.lua
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture

local INDICATOR_SIZE = 15

PitBull4_RaidTargetIcon:SetModuleType("indicator")
PitBull4_RaidTargetIcon:SetName(L["Raid target icon"])
PitBull4_RaidTargetIcon:SetDescription(L["Show an icon on the unit frame based on which Raid Target it is."])
PitBull4_RaidTargetIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top",
	position = 1,
})

function PitBull4_RaidTargetIcon:OnEnable()
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function PitBull4_RaidTargetIcon:ClearFrame(frame)
	local control = frame.RaidTargetIcon
	if not control then
		return false
	end

	frame.RaidTargetIcon = control:Delete()
	return true
end

local function get_control(frame)
	local control = frame.RaidTargetIcon
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeIcon(frame)
		control:SetFrameLevel(frame:GetFrameLevel() + 13)
		frame.RaidTargetIcon = control
		control:SetWidth(INDICATOR_SIZE)
		control:SetHeight(INDICATOR_SIZE)
	end

	control:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")

	return control, made_control
end

function PitBull4_RaidTargetIcon:UpdateFrame(frame)
	local unit = frame.unit
	if frame.force_show and (not unit or not UnitExists(unit)) then
		local control, made_control = get_control(frame)

		-- create a stable "random" index for the unit in config mode
		local unit = unit or frame:GetName()
		local index = tonumber(unit:match(".*(%d+)")) or 0
		index = index + #unit + unit:byte()
		index = (index % 8) + 1

		SetRaidTargetIconTexture(control, index)

		return made_control
	end

	local index = GetRaidTargetIndex(unit)
	if index then
		local control, made_control = get_control(frame)

		SetRaidTargetIconTexture(control, index)

		control:Show()

		return made_control
	end

	return self:ClearFrame(frame)
end

function PitBull4_RaidTargetIcon:RAID_TARGET_UPDATE()
	self:UpdateAll()
end

function PitBull4_RaidTargetIcon:GROUP_ROSTER_UPDATE()
	self:ScheduleTimer("UpdateAll", 0.1)
end
