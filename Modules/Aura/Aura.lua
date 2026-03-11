-- Aura.lua : Core setup of the Aura module and event processing

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:NewModule("Aura")

PitBull4_Aura:SetModuleType("custom")
PitBull4_Aura:SetName(L["Aura"])
PitBull4_Aura:SetDescription(L["Shows buffs and debuffs for PitBull4 frames."])

PitBull4_Aura.OnProfileChanged_funcs = {}

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
local timer = 0
timerFrame:SetScript("OnUpdate",function(self, elapsed)
	timer = timer + elapsed
	if timer >= 0.2 then
		PitBull4_Aura:OnUpdate()
		timer = 0
	end
end)


function PitBull4_Aura:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateAll")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateAll")
	self:RegisterEvent("UNIT_AURA")
	timerFrame:Show()

	-- Rescan spells that can change what we can dispel and purge.
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("SPELLS_CHANGED", "PLAYER_TALENT_UPDATE")
	self:PLAYER_TALENT_UPDATE()
end

function PitBull4_Aura:OnDisable()
	timerFrame:Hide()
end

function PitBull4_Aura:OnProfileChanged()
	for _, func in next, self.OnProfileChanged_funcs do
		func(self)
	end
end

function PitBull4_Aura:UNIT_AURA(_, unit, update_info)
	for frame in PitBull4:IterateFrames() do
		if frame.unit == unit then
			if self:GetLayoutDB(frame).enabled then
				self:UpdateAuraData(frame, update_info)
				self:UpdateFrame(frame)
			else
				self:ClearFrame(frame)
			end
		end
	end
end

function PitBull4_Aura:ClearFrame(frame)
	self:ClearAuras(frame)
	if frame.aura_highlight then
		frame.aura_highlight = frame.aura_highlight:Delete()
	end
end
PitBull4_Aura.OnHide = PitBull4_Aura.ClearFrame

function PitBull4_Aura:UpdateFrame(frame)
	self:UpdateSkin(frame)
	self:UpdateAuras(frame)
	self:LayoutAuras(frame)
end

function PitBull4_Aura:UpdateAll()
	for frame in PitBull4:IterateFrames() do
		self:Update(frame)
	end
end

function PitBull4_Aura:LibSharedMedia_Registered(event, mediatype, key)
	if mediatype == "font" then
		self:UpdateAll()
	end
end
