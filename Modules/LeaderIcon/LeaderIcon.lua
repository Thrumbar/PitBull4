
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_LeaderIcon = PitBull4:NewModule("LeaderIcon")

PitBull4_LeaderIcon:SetModuleType("indicator")
PitBull4_LeaderIcon:SetName(L["Leader icon"])
PitBull4_LeaderIcon:SetDescription(L["Show an icon on the unit frame when the unit is the group leader."])
PitBull4_LeaderIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
})

local leader_unit

function PitBull4_LeaderIcon:OnEnable()
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED")
end

function PitBull4_LeaderIcon:GetTexture(frame)
	if frame.unit == leader_unit then
		return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
	end
end

function PitBull4_LeaderIcon:GetExampleTexture(frame)
	return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
end

function PitBull4_LeaderIcon:GetTexCoord(frame, texture)
	return 0.1, 0.84, 0.14, 0.88
end
PitBull4_LeaderIcon.GetExampleTexCoord = PitBull4_LeaderIcon.GetTexCoord

local function update_leader()
	local group_size = GetNumGroupMembers()
	if group_size > 0 then
		if UnitIsGroupLeader("player") then
			-- player is the leader
			leader_unit = "player"
		else
			local group_unit_prefix = IsInRaid() and "raid" or "party"
			for i = 1, group_size do
				local unit = group_unit_prefix..i
				if UnitIsGroupLeader(unit) then
					leader_unit = unit
					break
				end
			end
		end
	else
		-- not in a raid or a party
		leader_unit = nil
	end
	PitBull4_LeaderIcon:UpdateAll()
end

function PitBull4_LeaderIcon:PARTY_LEADER_CHANGED()
	self:ScheduleTimer(update_leader, 0.1)
end
