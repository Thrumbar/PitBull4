local StatusBar = {}


function StatusBar:SetIcon(value)
	-- if self.icon_path == value then
	-- 	return
	-- end

	self.icon_path = value
	-- if value then
	-- 	if not self.icon then
	-- 		self.icon = PitBull4.Controls.MakeTexture(self, "ARTWORK")
	-- 		self.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	-- 		-- fix_orientation(self)
	-- 	end
	-- 	self.icon:SetTexture(value)
	-- else
	-- 	if self.icon then
	-- 		self.icon = self.icon:Delete()
	-- 		-- fix_orientation(self)
	-- 	end
	-- end
end
function StatusBar:GetIcon()
	return self.icon_path
end

function StatusBar:SetIconPosition(value)
	if value == self.icon_position then
		return
	end

	self.icon_position = value
	-- fix_orientation(self)
end
function StatusBar:GetIconPosition()
	return self.icon_position
end

function StatusBar:SetReverse(isReverseFill)
	if self.reverse == isReverseFill then
		return
	end

	self.reverse = isReverseFill
	self:SetReverseFill(isReverseFill)
	-- self:SetValue(self.value)
end
function StatusBar:GetReverse()
	return self:GetReverseFill()
end

function StatusBar:SetDeficit(deficit)
	if self.deficit == deficit then
		return
	end

	self.deficit = deficit
	-- self:SetValue(self.value)
end
function StatusBar:GetDeficit()
	return self.deficit
end

function StatusBar:SetBackgroundColor(r, g, b, a)
	self.bg:SetVertexColor(r or 0, g or 0, b or 0, a or 1)
end
function StatusBar:GetBackgroundColor()
	return self.bg:GetVertexColor()
end

local StatusBar_scripts = {}

function StatusBar:OnSizeChanged()
	self:SetValue(self.value)
end


PitBull4.Controls.MakeNewControlType("StatusBar", "StatusBar", function(control)
	-- onCreate
	control:EnableMouse(false)
	control:SetMinMaxValues(0, 1)

	local control_bg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.bg = control_bg
	control_bg:SetPoint("LEFT")
	control_bg:SetPoint("RIGHT")
	control_bg:SetPoint("TOP")
	control_bg:SetPoint("BOTTOM")

	for k,v in pairs(StatusBar) do
		control[k] = v
	end
	for k,v in pairs(StatusBar_scripts) do
		control:SetScript(k, v)
	end
end, function(control)
	-- onRetrieve
end, function(control)
	-- onDelete
end)
