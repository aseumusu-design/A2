--!strict
-- NinjaUI single-file GitHub bundle.
-- Recommended for trusted/private repositories only. For Roblox Studio,
-- prefer the modular ModuleScript package in ../src.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- CeypeepungUI: NinjaUI components + NovaUI vector icon engine, merged into one file.
local CeypeepungUI = {}
CeypeepungUI.Version = "2.0.0-ceypeepung"
local NinjaUI = CeypeepungUI

local C = {
	Background = Color3.fromRGB(13, 16, 25),
	Surface = Color3.fromRGB(21, 26, 39),
	SurfaceAlt = Color3.fromRGB(28, 34, 50),
	Primary = Color3.fromRGB(109, 92, 255),
	PrimaryAlt = Color3.fromRGB(64, 206, 255),
	Text = Color3.fromRGB(242, 245, 255),
	MutedText = Color3.fromRGB(153, 164, 189),
	Border = Color3.fromRGB(57, 68, 94),
	Success = Color3.fromRGB(69, 216, 146),
	Warning = Color3.fromRGB(255, 190, 74),
	Error = Color3.fromRGB(255, 91, 117),
}

local Light = {
	Background = Color3.fromRGB(239, 243, 251),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceAlt = Color3.fromRGB(230, 235, 245),
	Primary = Color3.fromRGB(85, 71, 219),
	PrimaryAlt = Color3.fromRGB(18, 157, 214),
	Text = Color3.fromRGB(25, 31, 48),
	MutedText = Color3.fromRGB(92, 103, 126),
	Border = Color3.fromRGB(200, 209, 225),
	Success = Color3.fromRGB(35, 166, 106),
	Warning = Color3.fromRGB(220, 145, 22),
	Error = Color3.fromRGB(216, 52, 76),
}

local function safe(callback, ...)
	if type(callback) ~= "function" then return end
	local ok, err = pcall(callback, ...)
	if not ok then warn("[NinjaUI] Callback error:", err) end
end

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		local ok, err = pcall(function() object[key] = value end)
		if not ok then warn("[NinjaUI] Property error:", key, err) end
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color)
	return make("UIStroke", { Color = color, Transparency = 0.15, Thickness = 1 }, parent)
end

local function label(parent, text, props)
	local base = {
		BackgroundTransparency = 1,
		Text = tostring(text or ""),
		TextColor3 = C.Text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for key, value in pairs(props or {}) do base[key] = value end
	return make("TextLabel", base, parent)
end

local function tween(object, properties, duration)
	if not object or not object.Parent then return end
	local ok, result = pcall(function()
		local t = TweenService:Create(object, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
		t:Play()
		return t
	end)
	if ok then return result end
	warn("[NinjaUI] Tween error:", result)
end

--==[ ICON ENGINE (vector, tanpa asset/ImageId) ]==--
local ICONS = {
    Home      = {{0.1,0.5,0.5,0.12},{0.5,0.12,0.9,0.5},{0.22,0.44,0.22,0.9},{0.78,0.44,0.78,0.9},{0.22,0.9,0.78,0.9},{0.4,0.9,0.4,0.62},{0.6,0.9,0.6,0.62},{0.4,0.62,0.6,0.62}},
    Play      = {{0.28,0.14,0.28,0.86},{0.28,0.14,0.85,0.5},{0.85,0.5,0.28,0.86}},
    Pause     = {{0.35,0.15,0.35,0.85},{0.65,0.15,0.65,0.85}},
    Settings  = {{0.5,0.14,0.5,0.28},{0.5,0.72,0.5,0.86},{0.14,0.5,0.28,0.5},{0.72,0.5,0.86,0.5},{0.24,0.24,0.34,0.34},{0.66,0.66,0.76,0.76},{0.76,0.24,0.66,0.34},{0.34,0.66,0.24,0.76},{0.34,0.5,0.5,0.34},{0.5,0.34,0.66,0.5},{0.66,0.5,0.5,0.66},{0.5,0.66,0.34,0.5}},
    User      = {{0.34,0.3,0.5,0.16},{0.5,0.16,0.66,0.3},{0.66,0.3,0.5,0.44},{0.5,0.44,0.34,0.3},{0.2,0.86,0.28,0.62},{0.28,0.62,0.72,0.62},{0.72,0.62,0.8,0.86},{0.2,0.86,0.8,0.86}},
    Search    = {{0.2,0.42,0.42,0.2},{0.42,0.2,0.64,0.42},{0.64,0.42,0.42,0.64},{0.42,0.64,0.2,0.42},{0.6,0.6,0.86,0.86}},
    Star      = {{0.5,0.12,0.62,0.4},{0.62,0.4,0.9,0.42},{0.9,0.42,0.68,0.6},{0.68,0.6,0.76,0.88},{0.76,0.88,0.5,0.72},{0.5,0.72,0.24,0.88},{0.24,0.88,0.32,0.6},{0.32,0.6,0.1,0.42},{0.1,0.42,0.38,0.4},{0.38,0.4,0.5,0.12}},
    Heart     = {{0.5,0.86,0.14,0.46},{0.14,0.46,0.2,0.22},{0.2,0.22,0.42,0.24},{0.42,0.24,0.5,0.38},{0.5,0.38,0.58,0.24},{0.58,0.24,0.8,0.22},{0.8,0.22,0.86,0.46},{0.86,0.46,0.5,0.86}},
    Check     = {{0.16,0.52,0.42,0.78},{0.42,0.78,0.86,0.22}},
    Close     = {{0.2,0.2,0.8,0.8},{0.8,0.2,0.2,0.8}},
    Plus      = {{0.5,0.16,0.5,0.84},{0.16,0.5,0.84,0.5}},
    Minus     = {{0.16,0.5,0.84,0.5}},
    Arrow     = {{0.16,0.5,0.84,0.5},{0.84,0.5,0.6,0.28},{0.84,0.5,0.6,0.72}},
    Bell      = {{0.28,0.66,0.28,0.42},{0.28,0.42,0.5,0.18},{0.5,0.18,0.72,0.42},{0.72,0.42,0.72,0.66},{0.18,0.66,0.82,0.66},{0.42,0.76,0.58,0.76},{0.42,0.76,0.5,0.86},{0.5,0.86,0.58,0.76}},
    Lock      = {{0.24,0.46,0.76,0.46},{0.24,0.46,0.24,0.86},{0.76,0.46,0.76,0.86},{0.24,0.86,0.76,0.86},{0.34,0.46,0.34,0.28},{0.34,0.28,0.5,0.16},{0.5,0.16,0.66,0.28},{0.66,0.28,0.66,0.46}},
    Folder    = {{0.12,0.28,0.42,0.28},{0.42,0.28,0.5,0.38},{0.5,0.38,0.88,0.38},{0.88,0.38,0.88,0.82},{0.12,0.28,0.12,0.82},{0.12,0.82,0.88,0.82}},
    Code      = {{0.34,0.28,0.14,0.5},{0.14,0.5,0.34,0.72},{0.66,0.28,0.86,0.5},{0.86,0.5,0.66,0.72},{0.58,0.2,0.42,0.8}},
    Trash     = {{0.16,0.28,0.84,0.28},{0.24,0.28,0.3,0.86},{0.76,0.28,0.7,0.86},{0.3,0.86,0.7,0.86},{0.38,0.28,0.4,0.16},{0.4,0.16,0.6,0.16},{0.6,0.16,0.62,0.28}},
    Refresh   = {{0.5,0.18,0.78,0.34},{0.78,0.34,0.78,0.66},{0.78,0.66,0.5,0.82},{0.5,0.82,0.22,0.66},{0.22,0.66,0.22,0.34},{0.22,0.34,0.5,0.18},{0.5,0.18,0.38,0.1},{0.5,0.18,0.4,0.3}},
    Power     = {{0.5,0.14,0.5,0.46},{0.28,0.28,0.2,0.52},{0.2,0.52,0.32,0.8},{0.32,0.8,0.68,0.8},{0.68,0.8,0.8,0.52},{0.8,0.52,0.72,0.28}},
}

local function drawIcon(parent, name, size, color)
	size = size or 18
	color = color or C.Text
	local canvas = make("Frame", {
		Name = "Icon_" .. tostring(name),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ZIndex = (parent.ZIndex or 1) + 1,
	}, parent)
	local set = ICONS[name]
	if not set then return canvas end
	local w = math.max(1, math.floor(size / 11 + 0.5))
	for _, s in ipairs(set) do
		local x1, y1 = s[1] * size, s[2] * size
		local x2, y2 = s[3] * size, s[4] * size
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local line = make("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
			Size = UDim2.fromOffset(math.max(1, len), w),
			Rotation = math.deg(math.atan2(dy, dx)),
			ZIndex = canvas.ZIndex,
		}, canvas)
		corner(line, w)
		for _, p in ipairs({ { x1, y1 }, { x2, y2 } }) do
			local cap = make("Frame", {
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(p[1], p[2]),
				Size = UDim2.fromOffset(w, w),
				ZIndex = canvas.ZIndex,
			}, canvas)
			corner(cap, w)
		end
	end
	return canvas
end

local function recolorIcon(holder, color)
	for _, d in ipairs(holder:GetDescendants()) do
		if d:IsA("Frame") and d.BackgroundTransparency == 0 then d.BackgroundColor3 = color end
	end
end

local function iconNames()
	local names = {}
	for name in pairs(ICONS) do names[#names + 1] = name end
	table.sort(names)
	return names
end

local function cleanup(self)
	if self._destroyed then return end
	self._destroyed = true
	for _, connection in ipairs(self._connections or {}) do pcall(function() connection:Disconnect() end) end
	for _, child in ipairs(self._owned or {}) do pcall(function() child:Destroy() end) end
	if self.Instance then pcall(function() self.Instance:Destroy() end) end
end

local function component(instance)
	local self = {
		Instance = instance,
		_connections = {},
		_owned = {},
		Changed = Instance.new("BindableEvent"),
		_destroyed = false,
	}
	function self:Destroy()
		cleanup(self)
		self.Changed:Destroy()
	end
	return self
end

local function bind(self, event, callback)
	local connection = event:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

local function themeColor(theme, token)
	return theme.Palette[token] or C[token]
end

local function applyTheme(theme, object, property, token)
	object[property] = themeColor(theme, token)
	table.insert(theme.Bindings, function()
		if object.Parent then object[property] = themeColor(theme, token) end
	end)
end

local function makeTheme(options)
	local theme = {
		Mode = options and options.Mode or "Dark",
		Palette = {},
		Bindings = {},
	}
	for key, value in pairs(C) do theme.Palette[key] = value end
	if options and options.Colors then
		for key, value in pairs(options.Colors) do theme.Palette[key] = value end
	end
	function theme:Get(token) return themeColor(theme, token) end
	function theme:SetMode(mode)
		if mode ~= "Dark" and mode ~= "Light" then return false end
		theme.Mode = mode
		for key in pairs(theme.Palette) do
			local source = mode == "Light" and Light or C
			if source[key] then theme.Palette[key] = source[key] end
		end
		for _, refresh in ipairs(theme.Bindings) do pcall(refresh) end
		return true
	end
	function theme:Extend(colors)
		for key, value in pairs(colors or {}) do theme.Palette[key] = value end
		for _, refresh in ipairs(theme.Bindings) do pcall(refresh) end
	end
	return theme
end

local function addRow(parent, title, description, height)
	local row = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or (description and 58 or 44)),
	}, parent)
	label(row, title, {
		Size = UDim2.new(0.42, 0, 0, 22),
		Font = Enum.Font.GothamBold,
	})
	if description then
		label(row, description, {
			Position = UDim2.fromOffset(0, 23),
			Size = UDim2.new(0.42, 0, 0, 30),
			TextColor3 = C.MutedText,
			TextSize = 10,
			TextWrapped = true,
		})
	end
	return row
end

local function addButton(page, theme, options)
	options = options or {}
	local button = make("TextButton", {
		AutoButtonColor = false,
		Selectable = true,
		Active = true,
		Size = options.Size or UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = theme:Get(options.Style == "Outline" and "Surface" or "Primary"),
		BorderSizePixel = 0,
		Text = options.Text or "Button",
		TextColor3 = theme:Get("Text"),
		Font = Enum.Font.GothamBold,
		TextSize = options.TextSize or 13,
	}, page)
	corner(button, 8)
	stroke(button, theme:Get("Border"))
	if options.Icon and ICONS[options.Icon] then
		local ico = drawIcon(button, options.Icon, options.IconSize or 18, theme:Get("Text"))
		ico.AnchorPoint = Vector2.new(0, 0.5)
		ico.Position = UDim2.new(0, 12, 0.5, 0)
		button.TextXAlignment = Enum.TextXAlignment.Left
		make("UIPadding", { PaddingLeft = UDim.new(0, 40) }, button)
	end
	if options.Style == "Gradient" then
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, theme:Get("Primary")),
				ColorSequenceKeypoint.new(1, theme:Get("PrimaryAlt")),
			}),
		}, button)
	end
	applyTheme(theme, button, "TextColor3", "Text")
	local self = component(button)
	bind(self, button.MouseEnter, function() tween(button, { BackgroundTransparency = 0.12 }, 0.12) end)
	bind(self, button.MouseLeave, function() tween(button, { BackgroundTransparency = 0 }, 0.12) end)
	bind(self, button.Activated, function()
		safe(options.Callback, self)
		self.Changed:Fire(true)
	end)
	function self:SetText(text) button.Text = tostring(text or "") end
	function self:SetEnabled(enabled)
		button.Active = enabled ~= false
		button.Selectable = enabled ~= false
		button.TextTransparency = enabled == false and 0.5 or 0
	end
	return self
end

local function addInput(page, theme, options)
	options = options or {}
	local row = addRow(page, options.Title or "Input", options.Description)
	local box = make("TextBox", {
		Position = UDim2.new(0.44, 0, 0, 5),
		Size = UDim2.new(0.56, 0, 0, 34),
		BackgroundColor3 = theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		PlaceholderText = options.Placeholder or "Type here...",
		Text = options.Default or "",
		TextColor3 = theme:Get("Text"),
		PlaceholderColor3 = theme:Get("MutedText"),
		Font = options.Password and Enum.Font.Code or Enum.Font.Gotham,
		TextSize = 13,
	}, row)
	corner(box, 7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
	local self = component(row)
	self.Input = box
	self.Value = box.Text
	applyTheme(theme, box, "TextColor3", "Text")
	bind(self, box:GetPropertyChangedSignal("Text"), function()
		self.Value = box.Text
		self.Changed:Fire(self.Value)
	end)
	bind(self, box.FocusLost, function()
		local valid, message = true
		if type(options.Validate) == "function" then
			local ok, result, reason = pcall(options.Validate, box.Text)
			valid, message = ok and result ~= false, reason
		end
		if not valid then
			box.BackgroundColor3 = theme:Get("Error")
			safe(options.OnInvalid, message, box.Text)
		else
			box.BackgroundColor3 = theme:Get("SurfaceAlt")
		end
		safe(options.OnSubmit, box.Text, valid)
	end)
	function self:SetValue(value) box.Text = tostring(value or "") end
	function self:GetValue() return box.Text end
	return self
end

local function addToggle(page, theme, options)
	options = options or {}
	local row = addRow(page, options.Title or "Toggle", options.Description)
	local button = make("TextButton", {
		Position = UDim2.new(0.44, 0, 0, 7),
		Size = UDim2.fromOffset(48, 28),
		AutoButtonColor = false,
		BackgroundColor3 = theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
		Text = "",
	}, row)
	corner(button, 999)
	local knob = make("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = theme:Get("Text"),
		BorderSizePixel = 0,
	}, button)
	corner(knob, 999)
	local self = component(row)
	self.Value = options.Default == true
	local function render(animated)
		local on = self.Value
		local buttonProps = { BackgroundColor3 = on and theme:Get("Primary") or theme:Get("SurfaceAlt") }
		local knobProps = { Position = on and UDim2.new(1, -24, 0, 4) or UDim2.fromOffset(4, 4) }
		if animated then tween(button, buttonProps) tween(knob, knobProps) else button.BackgroundColor3 = buttonProps.BackgroundColor3 knob.Position = knobProps.Position end
	end
	render(false)
	bind(self, button.Activated, function()
		self:SetValue(not self.Value)
	end)
	function self:SetValue(value)
		self.Value = value == true
		render(true)
		self.Changed:Fire(self.Value)
		safe(options.Callback, self.Value)
	end
	function self:GetValue() return self.Value end
	return self
end

local function addCheckbox(page, theme, options)
	options = options or {}
	local row = addRow(page, options.Title or "Checkbox", options.Description)
	local button = make("TextButton", {
		Position = UDim2.new(0.44, 0, 0, 8),
		Size = UDim2.fromOffset(26, 26),
		AutoButtonColor = false,
		BackgroundColor3 = theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
		Text = "",
	}, row)
	corner(button, 6)
	local check = label(button, "✓", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Visible = options.Default == true })
	local self = component(row)
	self.Value = options.Default == true
	local function render()
		check.Visible = self.Value
		button.BackgroundColor3 = self.Value and theme:Get("Primary") or theme:Get("SurfaceAlt")
	end
	render()
	bind(self, button.Activated, function() self:SetValue(not self.Value) end)
	function self:SetValue(value)
		self.Value = value == true
		render()
		self.Changed:Fire(self.Value)
		safe(options.Callback, self.Value)
	end
	function self:GetValue() return self.Value end
	return self
end

local function addSlider(page, theme, options)
	options = options or {}
	local min = tonumber(options.Min) or 0
	local max = tonumber(options.Max) or 100
	local row = addRow(page, options.Title or "Slider", options.Description)
	local track = make("Frame", {
		Position = UDim2.new(0.44, 0, 0, 20),
		Size = UDim2.new(0.56, 0, 0, 8),
		BackgroundColor3 = theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
	}, row)
	corner(track, 999)
	local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = theme:Get("Primary"), BorderSizePixel = 0 }, track)
	corner(fill, 999)
	local self = component(row)
	self.Value = math.clamp(tonumber(options.Default) or min, min, max)
	local dragging = false
	local function setFromX(x, emit)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		self.Value = min + (max - min) * ratio
		if options.Step then self.Value = math.floor(self.Value / options.Step + 0.5) * options.Step end
		fill.Size = UDim2.new((self.Value - min) / math.max(max - min, 0.001), 0, 1, 0)
		if emit then self.Changed:Fire(self.Value) safe(options.Callback, self.Value) end
	end
	setFromX(track.AbsolutePosition.X + track.AbsoluteSize.X * ((self.Value - min) / math.max(max - min, 0.001)), false)
	bind(self, track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X, true)
		end
	end)
	bind(self, UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	bind(self, UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFromX(input.Position.X, true) end
	end)
	function self:SetValue(value)
		self.Value = math.clamp(tonumber(value) or min, min, max)
		setFromX(track.AbsolutePosition.X + track.AbsoluteSize.X * ((self.Value - min) / math.max(max - min, 0.001)), true)
	end
	function self:GetValue() return self.Value end
	return self
end

local function addDropdown(page, theme, options)
	options = options or {}
	local row = addRow(page, options.Title or "Dropdown", options.Description, 44)
	local trigger = make("TextButton", {
		Position = UDim2.new(0.44, 0, 0, 5),
		Size = UDim2.new(0.56, 0, 0, 34),
		AutoButtonColor = false,
		BackgroundColor3 = theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
		Text = options.Placeholder or "Select...",
		TextColor3 = theme:Get("MutedText"),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	corner(trigger, 7)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, trigger)
	local menu = make("Frame", {
		Position = UDim2.new(0.44, 0, 1, 4),
		Size = UDim2.new(0.56, 0, 0, 0),
		BackgroundColor3 = theme:Get("Surface"),
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 20,
	}, row)
	corner(menu, 7)
	local list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(5, 5),
		Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, menu)
	make("UIListLayout", { Padding = UDim.new(0, 4) }, list)
	local self = component(row)
	self.Value = options.Default
	local function render()
		trigger.Text = self.Value ~= nil and tostring(self.Value) or (options.Placeholder or "Select...")
		trigger.TextColor3 = self.Value ~= nil and theme:Get("Text") or theme:Get("MutedText")
	end
	for _, item in ipairs(options.Items or options.Options or {}) do
		local value = type(item) == "table" and item.Value or item
		local text = type(item) == "table" and (item.Label or item.Value) or item
		local optionButton = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 28),
			AutoButtonColor = false,
			BackgroundColor3 = theme:Get("SurfaceAlt"),
			BorderSizePixel = 0,
			Text = tostring(text),
			TextColor3 = theme:Get("Text"),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
		}, list)
		corner(optionButton, 5)
		bind(self, optionButton.Activated, function()
			self:SetValue(value)
			menu.Visible = false
			row.Size = UDim2.new(1, 0, 0, options.Description and 58 or 44)
		end)
	end
	bind(self, trigger.Activated, function()
		menu.Visible = not menu.Visible
		row.Size = UDim2.new(1, 0, 0, menu.Visible and 190 or (options.Description and 58 or 44))
		if menu.Visible then menu.Size = UDim2.new(0.56, 0, 0, 180) end
	end)
	render()
	function self:SetValue(value)
		self.Value = value
		render()
		self.Changed:Fire(value)
		safe(options.Callback, value)
	end
	function self:GetValue() return self.Value end
	return self
end

local function addProgress(page, theme, options)
	options = options or {}
	local row = addRow(page, options.Title or "Progress", options.Description, options.Circular and 110 or 44)
	local track = make("Frame", {
		Position = options.Circular and UDim2.new(0.5, -44, 0, 8) or UDim2.new(0.44, 0, 0, 18),
		Size = options.Circular and UDim2.fromOffset(88, 88) or UDim2.new(0.56, 0, 0, 10),
		BackgroundColor3 = theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
	}, row)
	corner(track, options.Circular and 999 or 5)
	local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = theme:Get("Primary"), BorderSizePixel = 0 }, track)
	corner(fill, options.Circular and 999 or 5)
	local text = label(track, "0%", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 11 })
	local self = component(row)
	self.Value = tonumber(options.Default) or 0
	local function render()
		local ratio = math.clamp(self.Value / 100, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		text.Text = string.format("%d%%", math.floor(ratio * 100 + 0.5))
	end
	render()
	function self:SetValue(value)
		self.Value = math.clamp(tonumber(value) or 0, 0, 100)
		tween(fill, { Size = UDim2.new(self.Value / 100, 0, 1, 0) })
		render()
		self.Changed:Fire(self.Value)
	end
	function self:GetValue() return self.Value end
	return self
end

local function addColor(page, theme, options)
	options = options or {}
	local row = addRow(page, options.Title or "Color", options.Description, 44)
	local swatch = make("TextButton", {
		Position = UDim2.new(0.44, 0, 0, 5),
		Size = UDim2.new(0.56, 0, 0, 34),
		AutoButtonColor = false,
		BackgroundColor3 = options.Default or theme:Get("Primary"),
		BorderSizePixel = 0,
		Text = "",
	}, row)
	corner(swatch, 7)
	local hex = make("TextBox", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "#6D5CFF",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.Code,
		TextSize = 12,
	}, swatch)
	local self = component(row)
	self.Value = options.Default or theme:Get("Primary")
	local function toHex(color) return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255) end
	local function parse(value)
		value = string.gsub(value or "", "#", "")
		if #value ~= 6 or not string.match(value, "^[%x]+$") then return nil end
		return Color3.fromRGB(tonumber(string.sub(value, 1, 2), 16), tonumber(string.sub(value, 3, 4), 16), tonumber(string.sub(value, 5, 6), 16))
	end
	function self:SetValue(color)
		if typeof(color) ~= "Color3" then return end
		self.Value = color
		swatch.BackgroundColor3 = color
		hex.Text = toHex(color)
		self.Changed:Fire(color)
		safe(options.Callback, color)
	end
	function self:GetValue() return self.Value end
	bind(self, hex.FocusLost, function()
		local color = parse(hex.Text)
		if color then self:SetValue(color) else hex.Text = toHex(self.Value) end
	end)
	self:SetValue(self.Value)
	return self
end

local function addTab(window, name, options)
	options = options or {}
	local button = make("TextButton", {
		Size = UDim2.fromOffset(100, 34),
		AutoButtonColor = false,
		BackgroundColor3 = window.Theme:Get("SurfaceAlt"),
		BorderSizePixel = 0,
		Text = tostring(name),
		TextColor3 = window.Theme:Get("MutedText"),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
	}, window.Navigation)
	corner(button, 7)
	if options.Icon and ICONS[options.Icon] then
		local ico = drawIcon(button, options.Icon, 16, window.Theme:Get("MutedText"))
		ico.AnchorPoint = Vector2.new(0, 0.5)
		ico.Position = UDim2.new(0, 10, 0.5, 0)
		button.TextXAlignment = Enum.TextXAlignment.Left
		make("UIPadding", { PaddingLeft = UDim.new(0, 32) }, button)
		button.Size = UDim2.fromOffset(118, 34)
	end
	local page = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, window.Pages)
	make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	make("UIPadding", { PaddingBottom = UDim.new(0, 18) }, page)
	local api = { Name = name, Page = page, Button = button, Content = page }
	function api:AddButton(opts) return addButton(page, window.Theme, opts) end
	function api:AddInput(opts) return addInput(page, window.Theme, opts) end
	function api:AddToggle(opts) return addToggle(page, window.Theme, opts) end
	function api:AddCheckbox(opts) return addCheckbox(page, window.Theme, opts) end
	function api:AddSlider(opts) return addSlider(page, window.Theme, opts) end
	function api:AddDropdown(opts) return addDropdown(page, window.Theme, opts) end
	function api:AddProgressBar(opts) return addProgress(page, window.Theme, opts) end
	function api:AddColorPicker(opts) return addColor(page, window.Theme, opts) end
	function api:AddTooltip(target, text)
		local tip = label(target, text or "Tooltip", {
			Visible = false,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = window.Theme:Get("Surface"),
			TextSize = 11,
			ZIndex = 50,
		})
		corner(tip, 6)
		bind(window, target.MouseEnter, function() tip.Visible = true end)
		bind(window, target.MouseLeave, function() tip.Visible = false end)
		return tip
	end
	function api:AddLabel(text, opts)
		opts = opts or {}
		return label(page, text, {
			Size = UDim2.new(1, 0, 0, opts.Height or 20),
			TextColor3 = window.Theme:Get(opts.Muted == false and "Text" or "MutedText"),
			TextSize = opts.TextSize or 12,
			TextWrapped = true,
		})
	end
	function api:AddIcon(name, opts)
		opts = opts or {}
		local holder = make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, (opts.Size or 24) + 8),
		}, page)
		local ico = drawIcon(holder, name, opts.Size or 24, opts.Color or window.Theme:Get("Text"))
		ico.Position = UDim2.fromOffset(0, 4)
		if opts.Text then
			label(holder, opts.Text, {
				Position = UDim2.fromOffset((opts.Size or 24) + 10, 0),
				Size = UDim2.new(1, -(opts.Size or 24) - 10, 1, 0),
			})
		end
		return holder
	end
	function api:AddIconGrid(opts)
		opts = opts or {}
		local box = make("Frame", {
			BackgroundColor3 = window.Theme:Get("Surface"),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 10),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, page)
		corner(box, 10)
		stroke(box, window.Theme:Get("Border"))
		make("UIPadding", {
			PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		}, box)
		make("UIGridLayout", {
			CellSize = UDim2.fromOffset(76, 66),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.Name,
		}, box)
		local names = opts.Icons or iconNames()
		for _, n in ipairs(names) do
			local cell = make("TextButton", {
				Name = n, Text = "", AutoButtonColor = false,
				BackgroundColor3 = window.Theme:Get("SurfaceAlt"), BorderSizePixel = 0,
			}, box)
			corner(cell, 8)
			local ico = drawIcon(cell, n, 24, window.Theme:Get("Text"))
			ico.Position = UDim2.new(0.5, -12, 0, 10)
			label(cell, n, {
				Position = UDim2.fromOffset(0, 1, -20),
				Size = UDim2.new(1, 0, 0, 16),
				TextColor3 = window.Theme:Get("MutedText"),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Center,
			})
			cell.MouseEnter:Connect(function()
				cell.BackgroundColor3 = window.Theme:Get("Primary")
				recolorIcon(ico, window.Theme:Get("Text"))
			end)
			cell.MouseLeave:Connect(function()
				cell.BackgroundColor3 = window.Theme:Get("SurfaceAlt")
				recolorIcon(ico, window.Theme:Get("Text"))
			end)
			cell.Activated:Connect(function()
				if setclipboard then pcall(setclipboard, n) end
				safe(opts.Callback, n)
			end)
		end
		return box, #names
	end
	return api
end

-- Creates a single-file NinjaUI window.
function NinjaUI.new(options)
	options = options or {}
	local player = Players.LocalPlayer
	local parent = options.Parent
	if not parent then
		-- Executor-friendly parenting (Delta/Synapse/Fluxus): gethui() > CoreGui > PlayerGui.
		local ok, hidden = pcall(function() return gethui and gethui() end)
		if ok and hidden then
			parent = hidden
		else
			local ok2, core = pcall(function() return game:GetService("CoreGui") end)
			if ok2 and core and (typeof(syn) == "table" or protectgui or gethui) then parent = core end
		end
	end
	if not parent then parent = player and player:FindFirstChildOfClass("PlayerGui") or (player and player:WaitForChild("PlayerGui")) end
	assert(parent, "CeypeepungUI requires options.Parent, a LocalScript, or an executor")
	local existing = parent:FindFirstChild(options.Name or "CeypeepungUI")
	if existing and options.Replace ~= false then pcall(function() existing:Destroy() end) end

	local gui = make("ScreenGui", {
		Name = options.Name or "CeypeepungUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = options.DisplayOrder or 100,
	}, parent)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) elseif protectgui then protectgui(gui) end
	end)
	local theme = makeTheme(options.Theme)
	local root = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = options.Position or UDim2.fromScale(0.5, 0.5),
		Size = options.Size or UDim2.fromOffset(620, 430),
		BackgroundColor3 = theme:Get("Background"),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)
	corner(root, 16)
	stroke(root, theme:Get("Border"))
	applyTheme(theme, root, "BackgroundColor3", "Background")
	local top = make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = theme:Get("Surface"), BorderSizePixel = 0 }, root)
	local title = label(top, options.Title or "CeypeepungUI", { Position = UDim2.fromOffset(16, 5), Size = UDim2.new(1, -90, 0, 24), Font = Enum.Font.GothamBold, TextSize = 15 })
	if options.Subtitle then label(top, options.Subtitle, { Position = UDim2.fromOffset(16, 29), Size = UDim2.new(1, -90, 0, 16), TextColor3 = theme:Get("MutedText"), TextSize = 10 }) end
	local close = make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Text = "×", TextColor3 = theme:Get("MutedText"), TextSize = 22 }, top)
	local body = make("Frame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76), BackgroundTransparency = 1 }, root)
	local navigation = make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new() }, body)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, navigation)
	local pages = make("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), BackgroundTransparency = 1 }, body)
	local window = {
		Gui = gui,
		Root = root,
		Theme = theme,
		Navigation = navigation,
		Pages = pages,
		Tabs = {},
		Notifications = {},
		_connections = {},
		_owned = {},
	}
	function window:AddTab(name, tabOptions)
		local tab = addTab(window, tostring(name), tabOptions)
		window.Tabs[tab.Name] = tab
		local function select()
			for tabName, item in pairs(window.Tabs) do
				local active = tabName == tab.Name
				item.Page.Visible = active
				item.Button.BackgroundColor3 = active and theme:Get("Primary") or theme:Get("SurfaceAlt")
				item.Button.TextColor3 = active and theme:Get("Text") or theme:Get("MutedText")
			end
		end
		if not window._selected then window._selected = tab.Name select() end
		bind(window, tab.Button.Activated, function() window._selected = tab.Name select() end)
		return tab
	end
	function window:Notify(optionsOrMessage)
		local options = type(optionsOrMessage) == "string" and { Message = optionsOrMessage } or optionsOrMessage or {}
		local toast = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16 - (#window.Notifications * 48)),
			Size = UDim2.fromOffset(290, 38),
			BackgroundColor3 = theme:Get("Surface"),
			TextColor3 = theme:Get("Text"),
			Text = options.Message or "Notification",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextWrapped = true,
			ZIndex = 90,
		}, gui)
		corner(toast, 8)
		table.insert(window.Notifications, toast)
		task.delay(tonumber(options.Duration) or 4, function()
			for i, item in ipairs(window.Notifications) do if item == toast then table.remove(window.Notifications, i) break end end
			if toast then toast:Destroy() end
		end)
		return toast
	end
	function window:SetTitle(text) title.Text = tostring(text or "") end
	function window:SetVisible(value) gui.Enabled = value ~= false end
	function window:Toggle() gui.Enabled = not gui.Enabled end
	function window:SetMinimized(value) body.Visible = not value root.Size = value and UDim2.new(root.Size.X.Scale, root.Size.X.Offset, 0, 52) or (options.Size or UDim2.fromOffset(620, 430)) end
	function window:Destroy() cleanup(window) end
	window.Instance = gui
	window._owned = { gui }
	bind(window, close.Activated, function() window:Destroy() end)
	local dragging, start, origin = false, nil, nil
	bind(window, top.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true start = input.Position origin = root.Position end
	end)
	bind(window, UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - start
			root.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
		end
	end)
	bind(window, UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	return window
end

-- Alias untuk kemudahan pemanggilan
CeypeepungUI.CreateWindow = CeypeepungUI.new

-- Instansiasi langsung agar UI otomatis muncul saat dieksekusi oleh Delta/Executor
local window = CeypeepungUI.CreateWindow({
    Title = "CeypeepungUI",
    Subtitle = "Loaded Automatically"
})

-- Tambahkan tab default agar interface ter-render dengan sempurna
local mainTab = window:AddTab("Main", { Icon = "Home" })
mainTab:AddLabel("UI berhasil dimuat secara otomatis!")

return CeypeepungUI
