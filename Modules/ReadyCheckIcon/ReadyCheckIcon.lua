
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_ReadyCheckIcon = PitBull4:NewModule("ReadyCheckIcon")

PitBull4_ReadyCheckIcon:SetModuleType("indicator")
PitBull4_ReadyCheckIcon:SetName(L["Ready check icon"])
PitBull4_ReadyCheckIcon:SetDescription(L["Show a ready check icon on the unit frame based on their response."])
PitBull4_ReadyCheckIcon:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_right",
	position = 1,
})

function PitBull4_ReadyCheckIcon:OnEnable()
	self:RegisterEvent("READY_CHECK", "UpdateAll")
	self:RegisterEvent("READY_CHECK_CONFIRM", "UpdateAll")
	self:RegisterEvent("READY_CHECK_FINISHED")
end

local status_to_texture = {
	ready = [[Interface\RAIDFRAME\ReadyCheck-Ready]],
	notready = [[Interface\RAIDFRAME\ReadyCheck-NotReady]],
	waiting = [[Interface\RAIDFRAME\ReadyCheck-Waiting]],
}

function PitBull4_ReadyCheckIcon:GetTexture(frame)
	local status = GetReadyCheckStatus(frame.unit)
	return status_to_texture[status]
end

function PitBull4_ReadyCheckIcon:GetExampleTexture(frame)
	if frame.is_singleton then
		if frame.classification ~= "player" then
			return nil
		end
	elseif frame.header.unit_group ~= "party" and frame.header.unit_group ~= "raid" then
		return nil
	end

	local unit = frame.unit or frame:GetName()
	local index = tonumber(unit:match(".*(%d+)")) or 0
	index = index + #unit + unit:byte()
	index = index % 3

	local status
	if index == 0 then
		status = "ready"
	elseif index == 1 then
		status = "notready"
	else
		status = "waiting"
	end

	return status_to_texture[status]
end

function PitBull4_ReadyCheckIcon:READY_CHECK_FINISHED()
	self:ScheduleTimer("UpdateAll", 8.5)
end
