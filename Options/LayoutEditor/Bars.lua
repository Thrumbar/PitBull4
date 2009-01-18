local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local CURRENT_BAR_PROVIDER_ID = {}

--- Return the DB dictionary for the current text for the current layout selected in the options frame.
-- BarProvider modules should be calling this and manipulating data within it.
-- @param module the status_bar_provider module
-- @usage local db = PitBull.Options.GetTextLayoutDB(MyModule); db.some_option = "something"
-- @return the DB dictionary for the current text
function PitBull4.Options.GetBarLayoutDB(module)
	if not CURRENT_BAR_PROVIDER_ID[module.id] then
		return
	end
	
	return PitBull4.Options.GetLayoutDB(module).bars[CURRENT_BAR_PROVIDER_ID[module.id]]
end

function PitBull4.Options.get_layout_editor_bar_options()
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	
	local options = {
		name = L["Bars"],
		desc = L["Status bars graphically display a value from 0% to 100%."],
		type = 'group',
		childGroups = "tab",
		args = {}
	}
	
	local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
	LoadAddOn("AceGUI-3.0-SharedMediaWidgets")
	local AceGUI = LibStub("AceGUI-3.0")
	
	options.args.general = {
		type = 'group',
		name = L["General"],
		desc = L["Options that apply to all status bars."],
		order = 1,
		args = {}
	}
	
	options.args.general.args.texture = {
		type = 'select',
		name = L["Default texture"],
		desc = L["The texture of status bars, unless overridden."],
		order = 1,
		get = function(info)
			return GetLayoutDB(false).bar_texture
		end,
		set = function(info, value)
			GetLayoutDB(false).bar_texture = value

			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			for k in pairs(LibSharedMedia:HashTable("statusbar")) do
				t[k] = k
			end
			return t
		end,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("statusbar") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Statusbar"] and "LSM30_Statusbar" or nil,
	}
	
	options.args.general.args.spacing = {
		type = 'range',
		name = L["Spacing"],
		desc = L["Spacing in pixels between bars."],
		order = 2,
		min = 0,
		max = 10,
		step = 1,
		get = function(info)
			return GetLayoutDB(false).bar_spacing
		end,
		set = function(info, value)
			GetLayoutDB(false).bar_spacing = value

			UpdateFrames()
		end,
	}
	
	options.args.general.args.padding = {
		type = 'range',
		name = L["Padding"],
		desc = L["Padding in pixels between bars and the sides of the unit frame."],
		order = 3,
		min = 0,
		max = 10,
		step = 1,
		get = function(info)
			return GetLayoutDB(false).bar_padding
		end,
		set = function(info, value)
			GetLayoutDB(false).bar_padding = value

			UpdateFrames()
		end,
	}
	
	local enable_option = {
		type = 'toggle',
		name = L["Enable"],
		desc = function(info)
			if #info == 4 then 
				return L["Enable this status bar."]
			else
				return L["Enable this status bar provider."]
			end
		end,
		order = 1,
		get = function(info)
			return GetLayoutDB(info[3]).enabled
		end,
		set = function(info, value)
			GetLayoutDB(info[3]).enabled = value
			
			UpdateFrames()
		end,
	}
	
	local function get_current_layout_db(info)
		if #info == 4 then
			return GetLayoutDB(info[3])
		else
			assert(#info == 5)
			if not CURRENT_BAR_PROVIDER_ID[info[3]] then
				CURRENT_BAR_PROVIDER_ID[info[3]] = "Default"
			end
			return GetLayoutDB(info[3]).bars[CURRENT_BAR_PROVIDER_ID[info[3]]]
		end
	end
	
	local bar_args = {}
	
	bar_args.remove = {
		type = 'execute',
		name = L["Remove"],
		desc = L["Remove this status bar."],
		confirm = true,
		confirmText = L["Are you sure you want to remove this status bar?"],
		order = 1.5,
		func = function(info, value)
			GetLayoutDB(info[3]).bars[CURRENT_BAR_PROVIDER_ID[info[3]]] = nil
			
			UpdateFrames()
		end,
		hidden = function(info)
			return #info ~= 5
		end,
	}
	
	local disabled = function(info)
		return not GetLayoutDB(info[3]).enabled
	end
	
	bar_args.side = {
		type = 'select',
		name = L["Side"],
		desc = L["Which side of the unit frame to place the status bar on. Note: For the left and right sides, your bar will be vertical rather than horizontal."],
		order = 2,
		get = function(info)
			return get_current_layout_db(info).side
		end,
		set = function(info, value)
			get_current_layout_db(info).side = value

			UpdateFrames()
		end,
		values = {
			center = "Center",
			left = "Left",
			right = "Right",
		},
		disabled = disabled,
	}
	
	bar_args.position = {
		type = 'select',
		name = L["Position"],
		desc = L["Where to place the bar in relation to other bars on the frame."],
		order = 3,
		values = function(info)
			local db = get_current_layout_db(info)
			local side = db.side
			local t = {}
			local sort = {}
			for other_id, other_module in PitBull4:IterateModulesOfType("status_bar") do
				local other_db = GetLayoutDB(other_id)
				if side == other_db.side and other_db.enabled then
					local position = other_db.position
					while t[position] do
						position = position + 1e-5
						other_db.position = position
					end
					t[position] = other_module.name
					sort[#sort+1] = position
				end
			end
			for other_id, other_module in PitBull4:IterateModulesOfType("status_bar_provider") do
				local other_db = GetLayoutDB(other_id)
				if other_db.enabled then
					for name, bar_db in pairs(other_db.bars) do
						if side == bar_db.side then
							local position = bar_db.position
							while t[position] do
								position = position + 1e-5
								bar_db.position = position
							end
							t[position] = ("%s: %s"):format(other_module.name, name)
							sort[#sort+1] = position
						end
					end
				end
			end
			table.sort(sort)
			local sort_reverse = {}
			for k, v in pairs(sort) do
				sort_reverse[v] = k
			end
			for position, name in pairs(t) do
				t[position] = ("%d. %s"):format(sort_reverse[position], name)
			end
			return t
		end,
		get = function(info)
			return get_current_layout_db(info).position
		end,
		set = function(info, new_position)
			local id = info[3]
			local db = get_current_layout_db(info)
			
			local id_to_position = {}
			local bars = {}
			
			local old_position = db.position
			
			for other_id, other_module in PitBull4:IterateModulesOfType("status_bar", true) do
				local other_position = GetLayoutDB(other_id).position
				if other_id == id then
					other_position = new_position
				elseif other_position >= old_position and other_position <= new_position then
					other_position = other_position - 1
				elseif other_position <= old_position and other_position >= new_position then
					other_position = other_position + 1
				end
				
				id_to_position[other_id] = other_position
				bars[#bars+1] = other_id
			end
			
			for other_id, other_module in PitBull4:IterateModulesOfType("status_bar_provider", true) do
				for name, bar_db in pairs(GetLayoutDB(other_id).bars) do
					local other_position = bar_db.position
					if other_id == id and name == CURRENT_BAR_PROVIDER_ID[id] then
						other_position = new_position
					elseif other_position >= old_position and other_position <= new_position then
						other_position = other_position - 1
					elseif other_position <= old_position and other_position >= new_position then
						other_position = other_position + 1
					end
					
					local joined_id = other_id .. ";" .. name
					id_to_position[joined_id] = other_position
					bars[#bars+1] = joined_id
				end
			end
			
			table.sort(bars, function(alpha, bravo)
				return id_to_position[alpha] < id_to_position[bravo]
			end)
			
			for position, bar_id in ipairs(bars) do
				if bar_id:match(";") then
					local module_id, name = (";"):split(bar_id, 2)
					GetLayoutDB(module_id).bars[name].position = position
				else
					GetLayoutDB(bar_id).position = position
				end
			end
			
			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.texture = {
		type = 'select',
		name = L["Texture"],
		desc = L["What texture the status bar should use."],
		order = 4,
		get = function(info)
			return get_current_layout_db(info).texture or GetLayoutDB(false).bar_texture
		end,
		set = function(info, value)
			local default = get_current_layout_db(info).bar_texture
			if value == default then
				value = nil
			end
			get_current_layout_db(info).texture = value
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			local default = GetLayoutDB(false).bar_texture
			for k in pairs(LibSharedMedia:HashTable("statusbar")) do
				if k == default then
					t[k] = ("%s (Default)"):format(k)
				else
					t[k] = k
				end
			end
			return t
		end,
		disabled = disabled,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("statusbar") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Statusbar"] and "LSM30_Statusbar" or nil,
	}
	
	bar_args.size = {
		type = 'range',
		name = function(info)
			if get_current_layout_db(info).side == "center" then
				return L["Height"]
			else
				return L["Width"]
			end
		end,
		desc = function(info)
			if get_current_layout_db(info).side == "center" then
				return L["How tall the bar should be in relation to other bars."]
			else
				return L["How wide the bar should be in relation to other bars."]
			end
		end,
		order = 5,
		get = function(info)
			return get_current_layout_db(info).size
		end,
		set = function(info, value)
			get_current_layout_db(info).size = value

			UpdateFrames()
		end,
		min = 1,
		max = 12,
		step = 1,
		disabled = disabled,
	}
	
	bar_args.deficit = {
		type = 'toggle',
		name = L["Deficit"],
		desc = L["Drain the bar instead of filling it."],
		order = 6,
		get = function(info)
			return get_current_layout_db(info).deficit
		end,
		set = function(info, value)
			get_current_layout_db(info).deficit = value

			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.reverse = {
		type = 'toggle',
		name = L["Reverse"],
		desc = L["Reverse the direction of the bar, filling from right-to-left instead of left-to-right."],
		order = 7,
		get = function(info)
			return get_current_layout_db(info).reverse
		end,
		set = function(info, value)
			get_current_layout_db(info).reverse = value

			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.alpha = {
		type = 'range',
		name = L["Full opacity"],
		desc = L["How opaque the full section of the bar is."],
		order = 8,
		get = function(info)
			return get_current_layout_db(info).alpha
		end,
		set = function(info, value)
			get_current_layout_db(info).alpha = value

			UpdateFrames()
		end,
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	bar_args.background_alpha = {
		type = 'range',
		name = L["Empty opacity"],
		desc = L["How opaque the empty section of the bar is."],
		order = 9,
		get = function(info)
			return get_current_layout_db(info).background_alpha
		end,
		set = function(info, value)
			get_current_layout_db(info).background_alpha = value

			UpdateFrames()
		end,
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	bar_args.toggle_custom_color = {
		type = 'toggle',
		name = L["Custom color"],
		desc = L["Whether to override the color and use a custom one."],
		order = -2,
		get = function(info)
			return not not get_current_layout_db(info).custom_color
		end,
		set = function(info, value)
			if value then
				get_current_layout_db(info).custom_color = { 0.75, 0.75, 0.75, 1 }
			else
				get_current_layout_db(info).custom_color = nil
			end
			
			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.custom_color = {
		type = 'color',
		name = L["Custom color"],
		desc = L["What color to override the bar with."],
		order = -1,
		hasAlpha = true,
		get = function(info)
			return unpack(get_current_layout_db(info).custom_color)
		end,
		set = function(info, r, g, b, a)
			local color = get_current_layout_db(info).custom_color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			UpdateFrames()
		end,
		hidden = function(info)
			return not get_current_layout_db(info).custom_color
		end,
		disabled = disabled,
	}
	
	local layout_functions = PitBull4.Options.layout_functions
	
	local function table_with_size(...)
		return { ... }, select('#', ...)
	end
	
	for id, module in PitBull4:IterateModulesOfType("status_bar", true) do
		local args = {}
		args.enable = enable_option
		for k, v in pairs(bar_args) do
			args[k] = v
		end
		if layout_functions[module] then
			local data, data_n = table_with_size(layout_functions[module](module))
			layout_functions[module] = false
			for i = 1, data_n, 2 do
				local k, v = data[i], data[i + 1]
				
				args[k] = v
				if v then
					v.order = 100 + i
					local v_disabled = v.disabled
					function v.disabled(info)
						return disabled(info) or (v_disabled and v_disabled(info))
					end
				end
			end
		end
		
		options.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			args = args,
			hidden = function(info)
				return not module:IsEnabled()
			end,
		}
	end
	
	for id, module in PitBull4:IterateModulesOfType("status_bar_provider", true) do
		options.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			hidden = function(info)
				return not module:IsEnabled()
			end,
			args = {}
		}
		
		options.args[id].args.enable = enable_option
		
		options.args[id].args.current_bar = {
			name = L["Current bar"],
			desc = L["Change the current bar that you are editing."],
			type = 'select',
			order = 2,
			values = function(info)
				local bars_db = GetLayoutDB(module).bars
				local t = {}
				if not rawget(bars_db, CURRENT_BAR_PROVIDER_ID[id]) then
					CURRENT_BAR_PROVIDER_ID[id] = nil
				end
				for name in pairs(GetLayoutDB(module).bars) do
					if not CURRENT_BAR_PROVIDER_ID[id] then
						CURRENT_BAR_PROVIDER_ID[id] = name
					end
					t[name] = name
				end
				if not CURRENT_BAR_PROVIDER_ID[id] then
					CURRENT_BAR_PROVIDER_ID[id] = "Default"
					t["Default"] = "Default"
				end
				return t
			end,
			get = function(info)
				return CURRENT_BAR_PROVIDER_ID[id]
			end,
			set = function(info, value)
				CURRENT_BAR_PROVIDER_ID[id] = value
			end,
			disabled = disabled
		}
		
		local function bar_name_validate(info, value)
			if value:len() < 3 then
				return L["Must be at least 3 characters long."]
			end
			
			if rawget(GetLayoutDB(module).bars, value) then
				return L["'%s' is already a text."]:format(value)
			end
			
			return true
		end
		
		options.args[id].args.new_bar = {
			name = L["New bar"],
			desc = L["This will make a new bar for this layout."],
			type = 'input',
			order = 3,
			get = function(info) return "" end,
			set = function(info, value)
				local bars_db = GetLayoutDB(module).bars
				
				local bar_db = bars_db[value] -- will also create it
				
				CURRENT_BAR_PROVIDER_ID[id] = value
				
				UpdateFrames()
			end,
			validate = bar_name_validate,
		}
		
		local args = {}
		for k, v in pairs(bar_args) do
			args[k] = v
		end
		if layout_functions[module] then
			local data, data_n = table_with_size(layout_functions[module](module))
			layout_functions[module] = false
			for i = 1, data_n, 2 do
				local k, v = data[i], data[i + 1]
				
				args[k] = v
				if v then
					v.order = 100 + i
					local v_disabled = v.disabled
					function v.disabled(info)
						return disabled(info) or (v_disabled and v_disabled(info))
					end
				end
			end
		end
		
		options.args[id].args.edit = {
			name = L["Edit bar"],
			type = 'group',
			inline = true,
			args = args,
		}
	end
	
	return options
end