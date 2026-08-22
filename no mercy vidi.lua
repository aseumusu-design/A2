--[[
=========================================================================
    NO MERCY HUB V3.5 - FINAL ULTIMATE
    - Invisible mode (full transparent + accessories)
    - Auto shoot langsung ke target dalam FOV
    - Laser radius adjustable
    - FOV radius with slider & manual input
    - Wallhack + Noclip
    - 3 Mode Aimbot (V1, V2, V3)
=========================================================================
]]

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local CoreGui             = game:GetService("CoreGui")
local UserInputService    = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ==================== THEME CONFIG ====================
local THEME = {
    Bg       = Color3.fromRGB(12, 12, 18),
    Dark     = Color3.fromRGB(18, 18, 26),
    Panel    = Color3.fromRGB(24, 24, 35),
    Accent   = Color3.fromRGB(138, 43, 226),
    Green    = Color3.fromRGB(46, 204, 113),
    Red      = Color3.fromRGB(231, 76, 60),
    White    = Color3.fromRGB(255, 255, 255),
    TextDim  = Color3.fromRGB(150, 150, 170),
}

local TARGET_COLORS = {
    Killer   = Color3.fromRGB(255, 60, 60),
    Survivor = Color3.fromRGB(52, 152, 219),
    Zombie   = Color3.fromRGB(46, 204, 113),
    All      = Color3.fromRGB(241, 196, 15),
}

-- ==================== STATE CONFIG ====================
local Config = {
    AimbotEnabled = true,
    AimVersion    = "V1",
    TargetType    = "Killer",
    SpecificName  = "",
    MaxDistance   = 800,
    Prediction    = true,
    AutoShoot     = true,
    FireDelay     = 0.1,
    LaserEnabled  = true,
    LaserRadius   = 0.08,       -- ketebalan laser
    FOVCircleOn   = true,
    FOVRadius     = 180,
    DoubleFire    = false,
    Invisible     = false,
    Wallhack      = false,
}

local CurrentTarget = nil
local LastFireTime = 0

-- ==================== VISUAL: LASER TRACER ====================
local LaserPart = Instance.new("Part")
LaserPart.Name = "NM_LaserTracer"
LaserPart.Anchored = true
LaserPart.CanCollide = false
LaserPart.CanQuery = false
LaserPart.CanTouch = false
LaserPart.Material = Enum.Material.Neon
LaserPart.Transparency = 1
LaserPart.Size = Vector3.new(Config.LaserRadius, Config.LaserRadius, 0.1)
LaserPart.Parent = Workspace

-- ==================== VISUAL: SCREEN FOV CIRCLE ====================
local guiParent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
pcall(function() if guiParent:FindFirstChild("NoMercyHubV35") then guiParent.NoMercyHubV35:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui", guiParent)
ScreenGui.Name = "NoMercyHubV35"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local FOVFrame = Instance.new("Frame", ScreenGui)
FOVFrame.Name = "FOVCircle"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = Config.FOVCircleOn

local UICornerFOV = Instance.new("UICorner", FOVFrame)
UICornerFOV.CornerRadius = UDim.new(1, 0)

local UIStrokeFOV = Instance.new("UIStroke", FOVFrame)
UIStrokeFOV.Color = Color3.fromRGB(255, 255, 255)
UIStrokeFOV.Thickness = 1.8
UIStrokeFOV.Transparency = 0.2

-- ==================== UTILS TARGET & COMBAT ====================
local function ClassifyTarget(char, plr)
    local n = (char and char.Name or ""):lower()
    local t = (plr and plr.Team and plr.Team.Name or ""):lower()
    if n:find("kill") or n:find("monster") or n:find("slasher") or n:find("murder") or t:find("kill") then 
        return "Killer" 
    end
    if n:find("zomb") or n:find("infect") then return "Zombie" end
    if plr then return "Survivor" end
    return "Killer"
end

local function IsAlive(char)
    if not char or not char.Parent then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 and char:FindFirstChild("Head") ~= nil
end

local function MatchesFilter(p, char, kind)
    if Config.TargetType == "All" then return true end
    if Config.TargetType == "Survivor" and Config.SpecificName ~= "" then
        return p.Name:lower() == Config.SpecificName:lower()
    end
    return kind == Config.TargetType
end

local function IsInFOV(headPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
    if not Config.Wallhack and not onScreen then return false end
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= Config.FOVRadius
end

local function FindBestTarget()
    local origin = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p.Character) then
            local kind = ClassifyTarget(p.Character, p)
            if MatchesFilter(p, p.Character, kind) then
                local head = p.Character:FindFirstChild("Head")
                if head and IsInFOV(head.Position) then
                    local dist = (head.Position - origin).Magnitude
                    if dist <= Config.MaxDistance and dist < bestScore then
                        best = { player = p, char = p.Character, kind = kind, name = p.Name }
                        bestScore = dist
                    end
                end
            end
        end
    end
    return best
end

local function GetPredictPos(char)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    if not Config.Prediction then return head.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity then
        local travelTime = (Camera.CFrame.Position - head.Position).Magnitude / 700
        return head.Position + hrp.AssemblyLinearVelocity * travelTime
    end
    return head.Position
end

-- Remote reference
local fireRemote = ReplicatedStorage:FindFirstChild("Remotes")
if fireRemote then
    fireRemote = fireRemote:FindFirstChild("Items")
end
if fireRemote then
    fireRemote = fireRemote:FindFirstChild("Twist of Fate")
end
if fireRemote then
    fireRemote = fireRemote:FindFirstChild("Fire")
end

local function FireWeapon(targetPos)
    local now = tick()
    if now - LastFireTime < Config.FireDelay then return end
    LastFireTime = now

    local char = LocalPlayer.Character
    if not char then return end
    local tof = char:FindFirstChild("Twist of Fate")
    local gun = tof and tof:FindFirstChild("Right Arm") and tof["Right Arm"]:FindFirstChild("EmperorGun")
    if not (gun and fireRemote) then return end

    local from = gun:IsA("BasePart") and gun.Position or Camera.CFrame.Position
    local dir = (targetPos - from).Unit
    pcall(function() fireRemote:FireServer(gun, Vector3.new(dir.X, dir.Y, dir.Z)) end)
end

-- ==================== INVISIBLE & NOCLIP ====================
local function applyInvisible(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 0.99 or 0
            -- juga handle accessories
            if part:FindFirstChild("Handle") and part.Handle:IsA("BasePart") then
                part.Handle.Transparency = state and 0.99 or 0
            end
        end
        -- untuk aksesoris pakaian
        if part:IsA("Accessory") and part:FindFirstChild("Handle") then
            part.Handle.Transparency = state and 0.99 or 0
        end
    end
end

local function applyNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- ==================== MAIN AIMBOT LOOP ====================
RunService.RenderStepped:Connect(function()
    -- Update FOV circle
    FOVFrame.Visible = Config.FOVCircleOn
    FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)

    -- Invisible & Noclip
    if Config.Invisible then
        applyInvisible(true)
    else
        applyInvisible(false)
    end
    if Config.Wallhack then
        applyNoclip(true)
    else
        applyNoclip(false)
    end

    if not Config.AimbotEnabled then
        LaserPart.Transparency = 1
        return
    end

    -- Re-check target validity
    if CurrentTarget then
        local head = CurrentTarget.char:FindFirstChild("Head")
        local origin = Camera.CFrame.Position
        local dist = head and (head.Position - origin).Magnitude or math.huge
        local inFOV = head and IsInFOV(head.Position) or false
        if not (IsAlive(CurrentTarget.char) and inFOV and dist <= Config.MaxDistance and MatchesFilter(CurrentTarget.player, CurrentTarget.char, CurrentTarget.kind)) then
            CurrentTarget = nil
        end
    end

    if not CurrentTarget then
        CurrentTarget = FindBestTarget()
    end

    -- Laser & shooting
    if CurrentTarget then
        local pos = GetPredictPos(CurrentTarget.char)
        if pos then
            -- Update laser with adjustable radius
            if Config.LaserEnabled then
                local gun = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Twist of Fate")
                gun = gun and gun:FindFirstChild("Right Arm") and gun["Right Arm"]:FindFirstChild("EmperorGun")
                local from = (gun and gun.Position) or Camera.CFrame.Position
                
                LaserPart.Transparency = 0.25
                LaserPart.Color = TARGET_COLORS[CurrentTarget.kind] or THEME.White
                LaserPart.CFrame = CFrame.lookAt(from, pos) * CFrame.new(0, 0, -(pos - from).Magnitude / 2)
                LaserPart.Size = Vector3.new(Config.LaserRadius, Config.LaserRadius, (pos - from).Magnitude)
            else
                LaserPart.Transparency = 1
            end

            -- Mode V2: Camera Lock
            if Config.AimVersion == "V2" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
            end

            -- Auto shoot (langsung tembak ke target dalam FOV)
            if Config.AutoShoot then
                FireWeapon(pos)
            end
        else
            LaserPart.Transparency = 1
        end
    else
        LaserPart.Transparency = 1
    end
end)

-- ==================== UI ====================
local Bubble = Instance.new("ImageButton", ScreenGui)
Bubble.Size = UDim2.new(0, 55, 0, 55)
Bubble.Position = UDim2.new(0, 15, 0.25, 0)
Bubble.BackgroundColor3 = THEME.Dark
Bubble.Image = "rbxassetid://126404877070566"
Bubble.Active = true
Bubble.Draggable = true
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

local Window = Instance.new("Frame", ScreenGui)
Window.Size = UDim2.new(0, 500, 0, 500)
Window.Position = UDim2.new(0.5, -250, 0.5, -250)
Window.BackgroundColor3 = THEME.Bg
Window.Active = true
Window.Draggable = true
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 12)

Bubble.MouseButton1Click:Connect(function() Window.Visible = not Window.Visible end)

local Header = Instance.new("Frame", Window)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = THEME.Dark
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NO MERCY HUB V3.5 — ULTIMATE EDITION"
Title.TextColor3 = THEME.White
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = THEME.Red
CloseBtn.Text = "X"
CloseBtn.TextColor3 = THEME.White
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Window.Visible = false end)

local Sidebar = Instance.new("ScrollingFrame", Window)
Sidebar.Size = UDim2.new(0, 130, 1, -50)
Sidebar.Position = UDim2.new(0, 10, 0, 45)
Sidebar.BackgroundTransparency = 1
Sidebar.ScrollBarThickness = 2
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.Padding = UDim.new(0, 5)

local Container = Instance.new("Frame", Window)
Container.Size = UDim2.new(1, -150, 1, -50)
Container.Position = UDim2.new(0, 145, 0, 45)
Container.BackgroundColor3 = THEME.Panel
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)

local Tabs = {}
local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = THEME.Dark
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = THEME.TextDim
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize, TabBtn.TextXAlignment = 11, Enum.TextXAlignment.Left
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("ScrollingFrame", Container)
    Page.Size = UDim2.new(1, -10, 1, -10)
    Page.Position = UDim2.new(0, 5, 0, 5)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    
    local pageLayout = Instance.new("UIListLayout", Page)
    pageLayout.Padding = UDim.new(0, 8)

    Tabs[name] = { Btn = TabBtn, Page = Page }
    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Page.Visible = false t.Btn.TextColor3 = THEME.TextDim end
        Page.Visible = true
        TabBtn.TextColor3 = THEME.White
    end)
    return Page
end

local AimTab = CreateTab("Aimbot Setup")
local VisualTab = CreateTab("Visuals & Laser")

Tabs["Aimbot Setup"].Page.Visible = true
Tabs["Aimbot Setup"].Btn.TextColor3 = THEME.White

-- ==================== UI HELPERS ====================
local function AddToggle(parent, text, default, callback)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundColor3 = THEME.Dark
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1, -45, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextColor3 = THEME.White
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local dot = Instance.new("Frame", holder)
    dot.Size = UDim2.new(0, 28, 0, 14)
    dot.Position = UDim2.new(1, -36, 0.5, -7)
    dot.BackgroundColor3 = default and THEME.Green or Color3.fromRGB(60, 60, 75)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local state = default
    holder.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            state = not state
            dot.BackgroundColor3 = state and THEME.Green or Color3.fromRGB(60, 60, 75)
            callback(state)
        end
    end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundColor3 = THEME.Dark
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1, -10, 0, 18)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. " (" .. tostring(default) .. ")"
    lbl.TextColor3 = THEME.White
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local slider = Instance.new("Frame", holder)
    slider.Size = UDim2.new(1, -20, 0, 12)
    slider.Position = UDim2.new(0, 10, 0, 22)
    slider.BackgroundColor3 = THEME.Panel
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(input)
        local posX = input.Position.X
        local rel = math.clamp((posX - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        local val = math.round(min + rel * (max - min))
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. " (" .. tostring(val) .. ")"
        callback(val)
    end

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

local function AddTextBox(parent, labelText, default, callback, buttonText)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.BackgroundColor3 = THEME.Dark
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(0.5, -10, 1, 0)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = THEME.White
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", holder)
    box.Size = UDim2.new(0.25, 0, 0, 22)
    box.Position = UDim2.new(0.52, 0, 0.5, -11)
    box.BackgroundColor3 = THEME.Panel
    box.Text = tostring(default)
    box.TextColor3 = THEME.White
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 11
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton", holder)
    btn.Size = UDim2.new(0.18, 0, 0, 24)
    btn.Position = UDim2.new(0.8, 0, 0.5, -12)
    btn.BackgroundColor3 = THEME.Accent
    btn.Text = buttonText or "Set"
    btn.TextColor3 = THEME.White
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        local val = tonumber(box.Text)
        if val then
            callback(val)
        end
    end)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local val = tonumber(box.Text)
            if val then
                callback(val)
            end
        end
    end)
end

-- ==================== AIMBOT TAB CONTENT ====================
AddToggle(AimTab, "Enable Aim Lock", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
AddToggle(AimTab, "Auto Shoot Target", Config.AutoShoot, function(v) Config.AutoShoot = v end)
AddToggle(AimTab, "Double Fire (Extra Silent Shot)", Config.DoubleFire, function(v) Config.DoubleFire = v end)
AddToggle(AimTab, "Invisible Mode", Config.Invisible, function(v) 
    Config.Invisible = v
    applyInvisible(v)
end)
AddToggle(AimTab, "Wallhack + Noclip", Config.Wallhack, function(v) 
    Config.Wallhack = v
    applyNoclip(v)
end)

-- Mode selection
local verFrame = Instance.new("Frame", AimTab)
verFrame.Size = UDim2.new(1, 0, 0, 56)
verFrame.BackgroundColor3 = THEME.Dark
Instance.new("UICorner", verFrame).CornerRadius = UDim.new(0, 6)

local verLbl = Instance.new("TextLabel", verFrame)
verLbl.Size = UDim2.new(1, -10, 0, 16)
verLbl.Position = UDim2.new(0, 8, 0, 2)
verLbl.BackgroundTransparency = 1
verLbl.Text = "Pilih Mode Aimbot:"
verLbl.TextColor3 = THEME.TextDim
verLbl.Font = Enum.Font.GothamMedium
verLbl.TextSize = 10
verLbl.TextXAlignment = Enum.TextXAlignment.Left

local function createModeButton(parent, text, xPos, width)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(width, 0, 0, 24)
    btn.Position = UDim2.new(xPos, 0, 0, 22)
    btn.Text = text
    btn.TextColor3 = THEME.White
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local btnV1 = createModeButton(verFrame, "V1 (Free Coord)", 0.02, 0.30)
local btnV2 = createModeButton(verFrame, "V2 (Cam Lock)", 0.35, 0.30)
local btnV3 = createModeButton(verFrame, "V3 (Silent + Double)", 0.68, 0.30)

btnV1.BackgroundColor3 = THEME.Green
btnV2.BackgroundColor3 = THEME.Panel
btnV3.BackgroundColor3 = THEME.Panel

local function setMode(mode)
    Config.AimVersion = mode
    if mode == "V3" then
        Config.DoubleFire = true
    end
    btnV1.BackgroundColor3 = (mode == "V1") and THEME.Green or THEME.Panel
    btnV2.BackgroundColor3 = (mode == "V2") and THEME.Green or THEME.Panel
    btnV3.BackgroundColor3 = (mode == "V3") and THEME.Green or THEME.Panel
end

btnV1.MouseButton1Click:Connect(function() setMode("V1") end)
btnV2.MouseButton1Click:Connect(function() setMode("V2") end)
btnV3.MouseButton1Click:Connect(function() setMode("V3") end)

-- Target type
local targetTypeLbl = Instance.new("TextLabel", AimTab)
targetTypeLbl.Size = UDim2.new(1, 0, 0, 18)
targetTypeLbl.BackgroundTransparency = 1
targetTypeLbl.Text = "Pilih Target Kategori:"
targetTypeLbl.TextColor3 = THEME.TextDim
targetTypeLbl.Font = Enum.Font.GothamMedium
targetTypeLbl.TextSize = 10
targetTypeLbl.TextXAlignment = Enum.TextXAlignment.Left

local typesContainer = Instance.new("Frame", AimTab)
typesContainer.Size = UDim2.new(1, 0, 0, 28)
typesContainer.BackgroundTransparency = 1
local tcLayout = Instance.new("UIListLayout", typesContainer)
tcLayout.FillDirection = Enum.FillDirection.Horizontal
tcLayout.Padding = UDim.new(0, 5)

local survivorDropdown = Instance.new("ScrollingFrame", AimTab)
survivorDropdown.Size = UDim2.new(1, 0, 0, 90)
survivorDropdown.BackgroundColor3 = THEME.Dark
survivorDropdown.ScrollBarThickness = 3
survivorDropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
survivorDropdown.Visible = false
Instance.new("UICorner", survivorDropdown).CornerRadius = UDim.new(0, 6)
local sdl = Instance.new("UIListLayout", survivorDropdown)
sdl.Padding = UDim.new(0, 3)

local function RefreshSurvivors()
    for _, c in ipairs(survivorDropdown:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local sBtn = Instance.new("TextButton", survivorDropdown)
            sBtn.Size = UDim2.new(1, -4, 0, 24)
            sBtn.BackgroundColor3 = THEME.Panel
            sBtn.Text = "  " .. p.Name
            sBtn.TextColor3 = THEME.White
            sBtn.TextSize = 10
            sBtn.Font = Enum.Font.Gotham
            sBtn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4)
            sBtn.MouseButton1Click:Connect(function()
                Config.SpecificName = p.Name
                CurrentTarget = nil
                survivorDropdown.Visible = false
            end)
        end
    end
end

for _, tName in ipairs({"Killer", "Survivor", "Zombie"}) do
    local tBtn = Instance.new("TextButton", typesContainer)
    tBtn.Size = UDim2.new(0.32, 0, 1, 0)
    tBtn.BackgroundColor3 = (Config.TargetType == tName) and THEME.Accent or THEME.Dark
    tBtn.Text = tName
    tBtn.TextColor3 = THEME.White
    tBtn.Font = Enum.Font.GothamBold
    tBtn.TextSize = 10
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
    
    tBtn.MouseButton1Click:Connect(function()
        Config.TargetType = tName
        CurrentTarget = nil
        survivorDropdown.Visible = (tName == "Survivor")
        if tName == "Survivor" then RefreshSurvivors() end
        for _, child in ipairs(typesContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = (child.Text == tName) and THEME.Accent or THEME.Dark
            end
        end
    end)
end

-- ==================== VISUAL TAB CONTENT ====================
AddToggle(VisualTab, "Laser Tracer ON/OFF", Config.LaserEnabled, function(v) Config.LaserEnabled = v end)
AddToggle(VisualTab, "FOV Circle ON/OFF", Config.FOVCircleOn, function(v) Config.FOVCircleOn = v end)

-- Laser Radius slider
AddSlider(VisualTab, "Laser Radius", 0.01, 0.5, Config.LaserRadius, function(val)
    Config.LaserRadius = val
    LaserPart.Size = Vector3.new(val, val, LaserPart.Size.Z)
end)

-- FOV Radius slider
AddSlider(VisualTab, "FOV Radius (slider)", 50, 400, Config.FOVRadius, function(val)
    Config.FOVRadius = val
    FOVFrame.Size = UDim2.new(0, val * 2, 0, val * 2)
end)

-- Manual FOV input
AddTextBox(VisualTab, "FOV Radius (manual)", Config.FOVRadius, function(val)
    Config.FOVRadius = val
    FOVFrame.Size = UDim2.new(0, val * 2, 0, val * 2)
end, "Apply")

print("✅ NO MERCY HUB ULTIMATE Loaded!")

-- ==================== DOUBLE FIRE SYNC ====================
local isFiring = false

if fireRemote and hookmetamethod and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Config.DoubleFire and method == "FireServer" and self == fireRemote and not isFiring then
            isFiring = true
            task.spawn(function()
                if CurrentTarget and IsAlive(CurrentTarget.char) then
                    local head = CurrentTarget.char:FindFirstChild("Head")
                    if head then
                        local targetPos = head.Position
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("Head") then
                            local tool = char:FindFirstChild("Twist of Fate")
                            if tool and tool:FindFirstChild("Right Arm") and tool["Right Arm"]:FindFirstChild("EmperorGun") then
                                local gun = tool["Right Arm"]["EmperorGun"]
                                local from = gun.Position
                                local dir = (targetPos - from).Unit
                                pcall(function()
                                    fireRemote:FireServer(gun, Vector3.new(dir.X, dir.Y, dir.Z))
                                end)
                            end
                        end
                    end
                end
                task.wait(0.1)
                isFiring = false
            end)
        end

        return oldNamecall(self, unpack(args))
    end)
end
