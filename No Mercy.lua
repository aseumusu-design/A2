local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("GhostRelayEvent")

local GHOST_SELF = 0.5   -- Kamu lihat diri sendiri (agak ilang)
local GHOST_OTHER = 1    -- Orang lain lihat kamu (benar-benar ilang)

local myGhost = false

-- ==========================================
-- BUAT UI
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "GhostUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 150)
frame.Position = UDim2.new(0.5, -130, 0.82, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(120, 120, 255)
stroke.Thickness = 2.5
stroke.Transparency = 0.4
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "👻 GHOST MODE"
title.TextColor3 = Color3.fromRGB(200, 200, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 26)
status.Position = UDim2.new(0, 10, 0, 46)
status.BackgroundTransparency = 1
status.Text = "Status: VISIBLE"
status.TextColor3 = Color3.fromRGB(0, 255, 140)
status.TextScaled = true
status.Font = Enum.Font.GothamBold
status.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.85, 0, 0, 46)
btn.Position = UDim2.new(0.075, 0, 0, 82)
btn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
btn.Text = "TURN ON"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextScaled = true
btn.Font = Enum.Font.GothamBlack
btn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 14)
btnCorner.Parent = btn

-- ==========================================
-- FUNGSI TRANSPARANSI
-- ==========================================
local function applyGhost(character, isGhost, isSelf)
	if not character then return end
	local trans = isGhost and (isSelf and GHOST_SELF or GHOST_OTHER) or 0

	for _, obj in pairs(character:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("MeshPart") then
			obj.Transparency = trans
			obj.CastShadow = (trans == 0)
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = trans
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			obj.Enabled = (trans < 0.9)
		end
	end

	-- Sembunyikan nama di atas kepala
	local hum = character:FindFirstChild("Humanoid")
	if hum then
		hum.DisplayDistanceType = isGhost and Enum.HumanoidDisplayDistanceType.None 
			or Enum.HumanoidDisplayDistanceType.Viewer
	end
end

-- ==========================================
-- TOGGLE LOGIC
-- ==========================================
local function updateUI()
	if myGhost then
		btn.Text = "TURN OFF"
		status.Text = "Status: GHOST 👁️"
		status.TextColor3 = Color3.fromRGB(255, 210, 60)
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 55, 90)}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 90, 90)}):Play()
	else
		btn.Text = "TURN ON"
		status.Text = "Status: VISIBLE"
		status.TextColor3 = Color3.fromRGB(0, 255, 140)
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 140, 255)}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 120, 255)}):Play()
	end
end

btn.MouseButton1Click:Connect(function()
	myGhost = not myGhost
	updateUI()
	event:FireServer(myGhost)

	if player.Character then
		applyGhost(player.Character, myGhost, true)
	end
end)

-- Saat respawn, terapkan ulang
player.CharacterAdded:Connect(function(char)
	task.wait(0.6)
	if myGhost then
		applyGhost(char, true, true)
	end
end)

-- ==========================================
-- TERIMA BROADCAST DARI SERVER
-- ==========================================
event.OnClientEvent:Connect(function(userId, isGhost)
	local p = Players:GetPlayerByUserId(userId)
	if not p then return end

	local isSelf = (p == player)
	local char = p.Character

	-- Jika character belum ada, tunggu
	if not char then
		local conn
		conn = p.CharacterAdded:Connect(function(newChar)
			task.wait(0.3)
			applyGhost(newChar, isGhost, isSelf)
			conn:Disconnect()
		end)
		return
	end

	applyGhost(char, isGhost, isSelf)
end)

-- ==========================================
-- DRAG UI (Bisa digeser)
-- ==========================================
local dragging = false
local dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
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

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
