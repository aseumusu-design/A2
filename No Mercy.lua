-- ==========================================
-- 👻 FE GHOST + NOCLIP EXECUTOR SCRIPT
-- Full client-side | UI + Drag + Auto Respawn
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Tunggu character
local character = player.Character
if not character then
	player.CharacterAdded:Wait()
	character = player.Character
end

-- State
local ghostEnabled = false
local noclipEnabled = false
local ghostClone = nil
local originalData = {}
local syncConnection = nil
local noclipConnection = nil

-- ==========================================
-- UI SETUP
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "GhostNoclipPanel"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Parent ke CoreGui (executor support)
local ok, core = pcall(function() return game:GetService("CoreGui") end)
gui.Parent = ok and core or player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 220)
frame.Position = UDim2.new(0.5, -160, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
frame.BackgroundTransparency = 0.02
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 22)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(130, 130, 255)
stroke.Thickness = 2.8
stroke.Transparency = 0.25

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 38)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "👻 GHOST + NOCLIP"
title.TextColor3 = Color3.fromRGB(235, 235, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack

-- Divider
local div = Instance.new("Frame", frame)
div.Size = UDim2.new(0.9, 0, 0, 2)
div.Position = UDim2.new(0.05, 0, 0, 52)
div.BackgroundColor3 = Color3.fromRGB(90, 90, 200)
div.BorderSizePixel = 0
Instance.new("UICorner", div).CornerRadius = UDim.new(1, 0)

-- Ghost Label
local ghostLabel = Instance.new("TextLabel", frame)
ghostLabel.Size = UDim2.new(0.4, 0, 0, 24)
ghostLabel.Position = UDim2.new(0.07, 0, 0, 66)
ghostLabel.BackgroundTransparency = 1
ghostLabel.Text = "Ghost: OFF"
ghostLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
ghostLabel.TextScaled = true
ghostLabel.Font = Enum.Font.GothamBold

-- Ghost Button
local ghostBtn = Instance.new("TextButton", frame)
ghostBtn.Size = UDim2.new(0.4, 0, 0, 52)
ghostBtn.Position = UDim2.new(0.07, 0, 0, 96)
ghostBtn.BackgroundColor3 = Color3.fromRGB(25, 110, 255)
ghostBtn.Text = "TURN ON"
ghostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ghostBtn.TextScaled = true
ghostBtn.Font = Enum.Font.GothamBlack
Instance.new("UICorner", ghostBtn).CornerRadius = UDim.new(0, 16)

-- NoClip Label
local noclipLabel = Instance.new("TextLabel", frame)
noclipLabel.Size = UDim2.new(0.4, 0, 0, 24)
noclipLabel.Position = UDim2.new(0.53, 0, 0, 66)
noclipLabel.BackgroundTransparency = 1
noclipLabel.Text = "NoClip: OFF"
noclipLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
noclipLabel.TextScaled = true
noclipLabel.Font = Enum.Font.GothamBold

-- NoClip Button
local noclipBtn = Instance.new("TextButton", frame)
noclipBtn.Size = UDim2.new(0.4, 0, 0, 52)
noclipBtn.Position = UDim2.new(0.53, 0, 0, 96)
noclipBtn.BackgroundColor3 = Color3.fromRGB(25, 110, 255)
noclipBtn.Text = "TURN ON"
noclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipBtn.TextScaled = true
noclipBtn.Font = Enum.Font.GothamBlack
Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0, 16)

-- Hint
local hint = Instance.new("TextLabel", frame)
hint.Size = UDim2.new(0.9, 0, 0, 34)
hint.Position = UDim2.new(0.05, 0, 0, 160)
hint.BackgroundTransparency = 1
hint.Text = "Drag to move • You see ghost self (50%) • Others see normal"
hint.TextColor3 = Color3.fromRGB(140, 140, 190)
hint.TextScaled = true
hint.Font = Enum.Font.Gotham
hint.TextWrapped = true

-- ==========================================
-- GHOST SYSTEM
-- ==========================================

local function clearData()
	originalData = {}
end

local function saveState(char)
	clearData()
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("MeshPart") then
			originalData[obj] = {Transparency = obj.Transparency, CastShadow = obj.CastShadow}
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			originalData[obj] = {Transparency = obj.Transparency}
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			originalData[obj] = {Enabled = obj.Enabled}
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		originalData[hum] = {DisplayDistanceType = hum.DisplayDistanceType}
	end
end

local function hideReal(char)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("MeshPart") then
			obj.Transparency = 1
			obj.CastShadow = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			obj.Enabled = false
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function restoreState(char)
	for obj, props in pairs(originalData) do
		if obj and obj.Parent then
			for prop, val in pairs(props) do
				pcall(function() obj[prop] = val end)
			end
		end
	end
end

local function makeGhostClone(char)
	if ghostClone then
		ghostClone:Destroy()
		ghostClone = nil
	end
	task.wait(0.15)

	local oldArchivable = char.Archivable
	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = oldArchivable

	if not clone then return end
	clone.Name = "LocalGhost"

	-- Bersihin script & humanoid biar gak conflict
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("Humanoid") then
			obj:Destroy()
		end
	end

	-- Hapus accessories (biar gak ngambang)
	for _, obj in ipairs(clone:GetChildren()) do
		if obj:IsA("Accessory") then
			obj:Destroy()
		end
	end

	-- Set ghost look (50% transparan)
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("MeshPart") then
			obj.Transparency = 0.5
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CastShadow = false
			obj.Anchored = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 0.5
		end
	end

	clone.Parent = workspace
	ghostClone = clone

	-- Sync posisi setiap frame
	syncConnection = RunService.RenderStepped:Connect(function()
		if not ghostEnabled or not ghostClone or not ghostClone.Parent then
			if syncConnection then syncConnection:Disconnect() syncConnection = nil end
			return
		end
		if not char or not char.Parent then return end

		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				local cPart = ghostClone:FindFirstChild(part.Name)
				if cPart and cPart:IsA("BasePart") then
					cPart.CFrame = part.CFrame
				end
			end
		end
	end)
end

local function killGhostClone()
	if syncConnection then
		syncConnection:Disconnect()
		syncConnection = nil
	end
	if ghostClone then
		ghostClone:Destroy()
		ghostClone = nil
	end
end

local function toggleGhost()
	ghostEnabled = not ghostEnabled
	local char = player.Character
	if not char then return end

	if ghostEnabled then
		-- UI
		ghostLabel.Text = "Ghost: ON"
		ghostLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
		ghostBtn.Text = "TURN OFF"
		TweenService:Create(ghostBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 55, 90)}):Play()

		saveState(char)
		hideReal(char)
		makeGhostClone(char)
	else
		-- UI
		ghostLabel.Text = "Ghost: OFF"
		ghostLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		ghostBtn.Text = "TURN ON"
		TweenService:Create(ghostBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 110, 255)}):Play()

		killGhostClone()
		restoreState(char)
	end
end

-- ==========================================
-- NOCLIP SYSTEM
-- ==========================================

local function setNoclip(char, on)
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.CanCollide = not on
		end
	end
end

local function toggleNoclip()
	noclipEnabled = not noclipEnabled

	if noclipEnabled then
		noclipLabel.Text = "NoClip: ON"
		noclipLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
		noclipBtn.Text = "TURN OFF"
		TweenService:Create(noclipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 55, 90)}):Play()

		if noclipConnection then noclipConnection:Disconnect() end
		noclipConnection = RunService.Stepped:Connect(function()
			local c = player.Character
			if c then setNoclip(c, true) end
		end)
	else
		noclipLabel.Text = "NoClip: OFF"
		noclipLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		noclipBtn.Text = "TURN ON"
		TweenService:Create(noclipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 110, 255)}):Play()

		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		local c = player.Character
		if c then setNoclip(c, false) end
	end
end

-- ==========================================
-- EVENTS
-- ==========================================

ghostBtn.MouseButton1Click:Connect(toggleGhost)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)

player.CharacterRemoving:Connect(function()
	if syncConnection then syncConnection:Disconnect() syncConnection = nil end
	if ghostClone then ghostClone:Destroy() ghostClone = nil end
end)

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	task.wait(0.7)

	if ghostEnabled then
		saveState(newChar)
		hideReal(newChar)
		makeGhostClone(newChar)
	end
	if noclipEnabled then
		setNoclip(newChar, true)
	end
end)

-- ==========================================
-- DRAG SYSTEM (Mouse + Touch)
-- ==========================================

local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

frame.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
		                           startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
