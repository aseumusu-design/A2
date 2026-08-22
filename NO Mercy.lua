-- // ============================================================
-- // 🔥 EVADE HUB – AIR WALK + ESP (UPDATE)
-- // Fitur: Air Walk (Lompat = Jalan di Udara), ESP Player & Bot
-- // ============================================================

-- // ========== 1. LOAD FLUENT ==========
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- // ========== 2. SETUP ==========
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- // ========== 3. VARIABEL FITUR ==========
-- Air Walk
local AirWalkEnabled = false
local AirWalkSpeed = 50

-- ESP
local ESPEnabled = false
local ESPPlayerEnabled = false
local ESPBotEnabled = false
local ESPLines = {}

-- Fitur lain
local SpeedEnabled = false
local JumpEnabled = false
local walkSpeedValue = 50
local jumpPowerValue = 80
local AntiAFKEnabled = false
local AutoRespawnEnabled = false
local AutoReviveEnabled = false
local GodModeEnabled = false
local NoClipEnabled = false

-- AFK Farm
local AfkFarmEnabled = false
local AutoItemEnabled = false
local originalPosition = nil
local noItemTimer = 0
local savedAfkState = false
local savedCollectState = false

-- // ========== 4. AIR WALK (JALAN DI UDARA) ==========
-- Fungsi ini membuat player tetap bisa bergerak di udara seperti di darat
local function setupAirWalk()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Hapus koneksi lama biar ga double
    if _G.AirWalkConnection then
        _G.AirWalkConnection:Disconnect()
        _G.AirWalkConnection = nil
    end

    _G.AirWalkConnection = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
        if not AirWalkEnabled then return end
        -- Kalau lagi di udara, aktifkan PlatformStand biar bisa gerak
        if humanoid.FloorMaterial == Enum.Material.Air then
            humanoid.PlatformStand = true
            -- Terapkan kecepatan yang sudah diatur
            humanoid.WalkSpeed = AirWalkSpeed
        else
            humanoid.PlatformStand = false
            -- Kembali ke speed normal
            if SpeedEnabled then
                humanoid.WalkSpeed = walkSpeedValue
            else
                humanoid.WalkSpeed = 16
            end
        end
    end)
end

-- Fungsi untuk toggle Air Walk
local function toggleAirWalk(state)
    AirWalkEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    if not state then
        -- Matikan Air Walk, reset semuanya
        humanoid.PlatformStand = false
        if SpeedEnabled then
            humanoid.WalkSpeed = walkSpeedValue
        else
            humanoid.WalkSpeed = 16
        end
        if _G.AirWalkConnection then
            _G.AirWalkConnection:Disconnect()
            _G.AirWalkConnection = nil
        end
    else
        -- Aktifkan Air Walk
        setupAirWalk()
        -- Kalau lagi di udara, langsung aktifin PlatformStand
        if humanoid.FloorMaterial == Enum.Material.Air then
            humanoid.PlatformStand = true
            humanoid.WalkSpeed = AirWalkSpeed
        end
    end
end

-- Saat karakter respawn, setup ulang Air Walk
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if AirWalkEnabled then
        setupAirWalk()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
            humanoid.PlatformStand = true
            humanoid.WalkSpeed = AirWalkSpeed
        end
    end
end)

-- // ========== 5. ESP (PLAYER & BOT) ==========
-- Fungsi membuat ESP box
local function createESPBox(player, isBot)
    local char = isBot and player or player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Buat box di layar
    local box = Instance.new("BoxHandleAdornment")
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Size = Vector3.new(4, 6, 2)
    box.Adornee = root
    box.Color3 = isBot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    box.Transparency = 0.5
    box.Parent = root
    
    -- Buat label nama
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 30)
    billboard.Adornee = root
    billboard.Parent = root
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = isBot and "🤖 BOT" or player.Name
    label.TextColor3 = isBot and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard
    
    return {box = box, billboard = billboard, label = label}
end

-- Fungsi untuk update ESP
local function updateESP()
    -- Hapus ESP lama
    for _, line in ipairs(ESPLines) do
        pcall(function()
            if line.box then line.box:Destroy() end
            if line.billboard then line.billboard:Destroy() end
        end)
    end
    ESPLines = {}
    
    if not ESPEnabled then return end
    
    -- ESP untuk Player
    if ESPPlayerEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local esp = createESPBox(player, false)
                table.insert(ESPLines, esp)
            end
        end
    end
    
    -- ESP untuk Bot (Nextbot)
    if ESPBotEnabled then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:GetAttribute("Nextbot") == true then
                local esp = createESPBox(v, true)
                table.insert(ESPLines, esp)
            end
        end
    end
end

-- Update ESP setiap kali ada perubahan
Players.PlayerAdded:Connect(updateESP)
Players.PlayerRemoving:Connect(updateESP)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateESP()
end)

-- Loop update ESP untuk bot
task.spawn(function()
    while true do
        task.wait(2)
        if ESPEnabled and ESPBotEnabled then
            updateESP()
        end
    end
end)

-- // ========== 6. FUNGSI LAIN (SPEED, JUMP, DLL) ==========
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Kalau Air Walk aktif dan di udara, speed diatur oleh Air Walk
    if AirWalkEnabled and humanoid.FloorMaterial == Enum.Material.Air then
        return
    end
    
    if SpeedEnabled then
        humanoid.WalkSpeed = walkSpeedValue
    else
        humanoid.WalkSpeed = 16
    end
end

local function applyJump()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if JumpEnabled then
        humanoid.JumpPower = jumpPowerValue
    else
        humanoid.JumpPower = 50
    end
end

-- Loop update
task.spawn(function()
    while true do
        task.wait(0.5)
        applySpeed()
        applyJump()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applySpeed()
    applyJump()
    if AirWalkEnabled then
        setupAirWalk()
    end
end)

-- // ========== 7. AFK FARM & AUTO ITEM ==========
-- (Fungsi AFK Farm dan Auto Item sama seperti sebelumnya, disimpan agar tetap lengkap)
local function isPlayerAsset(instance)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and instance:IsDescendantOf(player.Character) then
            return true
        end
    end
    return false
end

local function getAllItems()
    local items = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if (v:IsA("BasePart") or v:IsA("Model")) then
            local nameLower = string.lower(v.Name)
            if string.find(nameLower, "bubble") or string.find(nameLower, "coconut") then
                local isVisualEffect = v:FindFirstChildWhichIsA("ParticleEmitter") 
                                    or v:FindFirstChildWhichIsA("Trail") 
                                    or v:FindFirstChildWhichIsA("Beam")
                                    or v.ClassName == "Accessory"
                local hasAnimation = v:FindFirstChildWhichIsA("Animation") or v:FindFirstChildWhichIsA("Animator")
                
                if not isVisualEffect and not hasAnimation and not isPlayerAsset(v) then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        table.insert(items, part)
                    end
                end
            end
        end
    end
    return items
end

local function isNextbotNear(position)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:GetAttribute("Nextbot") == true then
            local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
            if root then
                local distance = (position - root.Position).Magnitude
                if distance <= 12 then 
                    return true
                end
            end
        end
    end
    return false
end

local function getClosestSafeItem(hrp, items)
    local closest, minDst = nil, math.huge
    for _, part in ipairs(items) do
        local dst = (hrp.Position - part.Position).Magnitude
        if dst < minDst and not isNextbotNear(part.Position) then
            closest = part
            minDst = dst
        end
    end
    return closest
end

local function teleportTo(hrp, pos, duration)
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

task.spawn(function()
    while true do
        local items = getAllItems()
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if #items == 0 then
            noItemTimer = noItemTimer + 0.5
            if noItemTimer >= 20 then
                if AfkFarmEnabled then
                    AfkFarmEnabled = false
                    savedAfkState = false
                    if hrp then hrp.Anchored = false end
                    updateMiniGui()
                end
            end
        else
            if noItemTimer >= 20 and savedAfkState and not isDowned then
                task.wait(1)
                if hrp then
                    AfkFarmEnabled = true
                    originalPosition = hrp.Position + Vector3.new(0, 200, 0)
                    hrp.CFrame = CFrame.new(originalPosition)
                    task.wait(0.1)
                    hrp.Anchored = true
                    updateMiniGui()
                end
            end
            noItemTimer = 0
        end

        if AutoItemEnabled and not isDowned and #items > 0 then
            if hrp then
                local item = getClosestSafeItem(hrp, items)
                if item then
                    local startPos = hrp.Position
                    hrp.Anchored = false
                    
                    teleportTo(hrp, item.Position, 0.2)
                    
                    pcall(function()
                        local collectId = item.Parent:GetAttribute("Id") or item:GetAttribute("Id") or "a19ac91bff904b7385e826fd6a23dc01"
                        ReplicatedStorage.Events.Collectibles.Invoke:InvokeServer(LocalPlayer, collectId, "Collect")
                    end)
                    
                    task.wait(1)
                    isDowned = char and char:GetAttribute("Downed")
                    
                    if AutoItemEnabled and not isDowned and noItemTimer < 20 then
                        if AfkFarmEnabled and originalPosition then
                            teleportTo(hrp, originalPosition, 0.2)
                            hrp.Anchored = true
                        else
                            teleportTo(hrp, startPos, 0.2)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- // ========== 8. MINI GUI ==========
local miniGui = nil
local function createMiniGui()
    if miniGui then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "MiniStatusGui"
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    sg.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 210, 0, 95)
    frame.Position = UDim2.new(0.85, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Text = "📦 Status Farm"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 28)
    statusLabel.Text = "AFK: OFF | Auto: OFF"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 12
    statusLabel.Parent = frame

    local itemCount = Instance.new("TextLabel")
    itemCount.Size = UDim2.new(1, 0, 0, 25)
    itemCount.Position = UDim2.new(0, 0, 0, 56)
    itemCount.Text = "Item: 0"
    itemCount.TextColor3 = Color3.fromRGB(255, 200, 0)
    itemCount.BackgroundTransparency = 1
    itemCount.Font = Enum.Font.GothamMedium
    itemCount.TextSize = 12
    itemCount.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
        miniGui = nil
    end)

    miniGui = {
        ScreenGui = sg,
        Frame = frame,
        StatusLabel = statusLabel,
        ItemCount = itemCount,
        CloseBtn = closeBtn
    }

    task.spawn(function()
        while miniGui and miniGui.ScreenGui.Parent do
            task.wait(1)
            local items = getAllItems()
            local count = #items
            local afk = AfkFarmEnabled and "ON" or "OFF"
            local auto = AutoItemEnabled and "ON" or "OFF"
            miniGui.StatusLabel.Text = "AFK: " .. afk .. " | Auto: " .. auto
            miniGui.ItemCount.Text = "Item: " .. count
        end
    end)
end

function updateMiniGui()
    local anyActive = AfkFarmEnabled or AutoItemEnabled
    if anyActive then
        if not miniGui then
            createMiniGui()
        end
    else
        if miniGui then
            miniGui.ScreenGui:Destroy()
            miniGui = nil
        end
    end
end

-- // ========== 9. FLUENT WINDOW ==========
local Window = Fluent:CreateWindow({
    Title = "🔥 EVADE HUB",
    SubTitle = "Air Walk + ESP",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Bubble toggle
local ScreenGuiBubble = Instance.new("ScreenGui")
ScreenGuiBubble.Name = "EvadeBubbleGui"
ScreenGuiBubble.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local BubbleBtn = Instance.new("ImageButton")
BubbleBtn.Parent = ScreenGuiBubble
BubbleBtn.Size = UDim2.new(0, 48, 0, 48)
BubbleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
BubbleBtn.Image = "rbxassetid://102609928046926"
BubbleBtn.Active = true
BubbleBtn.Draggable = true
Instance.new("UICorner", BubbleBtn).CornerRadius = UDim.new(0, 10)
BubbleBtn.MouseButton1Click:Connect(function()
    Window.Root.Visible = not Window.Root.Visible
end)

-- Tabs
local Tabs = {
    Info     = Window:AddTab({ Title = "Info", Icon = "info" }),
    Main     = Window:AddTab({ Title = "Main", Icon = "home" }),
    AirWalk  = Window:AddTab({ Title = "🌊 Air Walk", Icon = "wind" }),
    ESP      = Window:AddTab({ Title = "👁️ ESP", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- // ========== 10. TAB INFO ==========
Tabs.Info:AddParagraph({
    Title = "Developer Details",
    Content = "Fitur: Air Walk (Jalan di Udara), ESP Player & Bot, AFK Farm, Auto Item, Speed, Jump, dll."
})

-- // ========== 11. TAB MAIN (AFK FARM & AUTO ITEM) ==========
Tabs.Main:AddParagraph({Title = "🚀 AFK Farm & Auto Item", Content = "Jendela mini muncul otomatis saat ON."})

Tabs.Main:AddToggle("AfkFarm", {
    Title = "🚀 AFK Farm",
    Default = false,
    Callback = function(Value)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        if isDowned then
            Fluent:Notify({Title = "Error", Content = "Karakter down!", Duration = 3})
            return
        end
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        AfkFarmEnabled = Value
        savedAfkState = Value
        if Value then
            originalPosition = hrp.Position + Vector3.new(0, 200, 0)
            hrp.CFrame = CFrame.new(originalPosition)
            task.wait(0.1)
            hrp.Anchored = true
        else
            hrp.Anchored = false
        end
        updateMiniGui()
    end
})

Tabs.Main:AddToggle("AutoItem", {
    Title = "🎯 Auto Item",
    Default = false,
    Callback = function(Value)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        if isDowned then
            Fluent:Notify({Title = "Error", Content = "Karakter down!", Duration = 3})
            return
        end
        AutoItemEnabled = Value
        savedCollectState = Value
        updateMiniGui()
    end
})

-- // ========== 12. TAB AIR WALK ==========
Tabs.AirWalk:AddParagraph({
    Title = "🌊 Air Walk (Jalan di Udara)",
    Content = "Aktifkan, lalu lompat untuk berjalan di udara! Speed tetap berfungsi."
})

Tabs.AirWalk:AddToggle("AirWalk", {
    Title = "🌊 Air Walk",
    Description = "Saat ON, kamu bisa berjalan di udara setelah melompat",
    Default = false,
    Callback = function(Value)
        toggleAirWalk(Value)
        Fluent:Notify({Title = "Air Walk", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.AirWalk:AddSlider("AirWalkSpeed", {
    Title = "🚀 Kecepatan di Udara",
    Description = "Kecepatan saat berjalan di udara",
    Default = 50,
    Min = 16,
    Max = 150,
    Rounding = 0,
    Callback = function(v)
        AirWalkSpeed = v
        if AirWalkEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local humanoid = char.Humanoid
                if humanoid.FloorMaterial == Enum.Material.Air then
                    humanoid.WalkSpeed = v
                end
            end
        end
    end
})

-- // ========== 13. TAB ESP ==========
Tabs.ESP:AddParagraph({
    Title = "👁️ ESP (Player & Bot)",
    Content = "Aktifkan ESP untuk melihat player dan bot (Nextbot) di sekitar."
})

Tabs.ESP:AddToggle("ESP", {
    Title = "👁️ ESP",
    Description = "Aktifkan ESP secara keseluruhan",
    Default = false,
    Callback = function(Value)
        ESPEnabled = Value
        if not Value then
            -- Hapus semua ESP
            for _, line in ipairs(ESPLines) do
                pcall(function()
                    if line.box then line.box:Destroy() end
                    if line.billboard then line.billboard:Destroy() end
                end)
            end
            ESPLines = {}
        else
            updateESP()
        end
    end
})

Tabs.ESP:AddToggle("ESPPlayer", {
    Title = "👤 ESP Player",
    Description = "Tampilkan ESP untuk player lain",
    Default = false,
    Callback = function(Value)
        ESPPlayerEnabled = Value
        if ESPEnabled then updateESP() end
    end
})

Tabs.ESP:AddToggle("ESPBot", {
    Title = "🤖 ESP Bot (Nextbot)",
    Description = "Tampilkan ESP untuk bot/monster",
    Default = false,
    Callback = function(Value)
        ESPBotEnabled = Value
        if ESPEnabled then updateESP() end
    end
})

-- // ========== 14. TAB MOVEMENT ==========
Tabs.Movement:AddParagraph({Title = "Speed & Jump", Content = "Atur kecepatan dan lompatan."})

Tabs.Movement:AddToggle("SpeedToggle", {
    Title = "⚡ Speed Boost",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        applySpeed()
    end
})

Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "🏃 Kecepatan",
    Default = 50,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        walkSpeedValue = v
        if SpeedEnabled then applySpeed() end
    end
})

Tabs.Movement:AddToggle("JumpToggle", {
    Title = "⬆ Jump Boost",
    Default = false,
    Callback = function(Value)
        JumpEnabled = Value
        applyJump()
    end
})

Tabs.Movement:AddSlider("JumpSlider", {
    Title = "💪 Kekuatan Lompat",
    Default = 80,
    Min = 20,
    Max = 300,
    Rounding = 0,
    Callback = function(v)
        jumpPowerValue = v
        if JumpEnabled then applyJump() end
    end
})

Tabs.Movement:AddToggle("NoClip", {
    Title = "👻 No Clip",
    Default = false,
    Callback = function(Value)
        NoClipEnabled = Value
        task.spawn(function()
            while NoClipEnabled do
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CanCollide = false
                end
                task.wait(0.5)
            end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CanCollide = true
            end
        end)
    end
})

-- // ========== 15. TAB MISC ==========
Tabs.Misc:AddParagraph({Title = "Lain-lain", Content = "Anti AFK, Auto Respawn, Auto Revive, God Mode"})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "🛡️ Anti AFK",
    Default = false,
    Callback = function(Value)
        AntiAFKEnabled = Value
        task.spawn(function()
            while AntiAFKEnabled do
                task.wait(30)
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end
        end)
    end
})

Tabs.Misc:AddToggle("AutoRespawn", {
    Title = "🔄 Auto Respawn",
    Default = false,
    Callback = function(Value)
        AutoRespawnEnabled = Value
        task.spawn(function()
            while AutoRespawnEnabled do
                task.wait(2)
                local char = LocalPlayer.Character
                if not char or not char.Parent then
                    LocalPlayer:LoadCharacter()
                end
            end
        end)
    end
})

Tabs.Misc:AddToggle("AutoRevive", {
    Title = "💉 Auto Revive",
    Default = false,
    Callback = function(Value)
        AutoReviveEnabled = Value
        task.spawn(function()
            while AutoReviveEnabled do
                task.wait(1)
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        if humanoid.Health <= 0 or char:GetAttribute("Downed") == true then
                            local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("ReviveGui")
                            if reviveGui then
                                for _, btn in pairs(reviveGui:GetDescendants()) do
                                    if btn:IsA("TextButton") then
                                        local text = string.lower(btn.Text or "")
                                        if string.find(text, "revive") or string.find(text, "respawn") then
                                            pcall(function() btn:Fire() end)
                                            break
                                        end
                                    end
                                end
                            end
                            task.wait(1)
                            pcall(function() LocalPlayer:LoadCharacter() end)
                        end
                    end
                end
            end
        end)
    end
})

Tabs.Misc:AddToggle("GodMode", {
    Title = "🛡️ God Mode",
    Description = "Kekebalan total (berisiko!)",
    Default = false,
    Callback = function(Value)
        GodModeEnabled = Value
        task.spawn(function()
            while GodModeEnabled do
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.MaxHealth = math.huge
                    char.Humanoid.Health = math.huge
                    char.Humanoid.BreakJointsOnDeath = false
                end
                task.wait(0.5)
            end
        end)
    end
})

-- // ========== 16. TAB CONFIG ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("EvadeHub")
SaveManager:SetFolder("EvadeHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(2)
SaveManager:LoadAutoloadConfig()

-- // ========== 17. NOTIFIKASI ==========
task.wait(1)
Fluent:Notify({
    Title = "🔥 EVADE HUB LOADED!",
    Content = "Air Walk + ESP siap digunakan",
    SubContent = "Tekan Ctrl untuk minimize menu",
    Duration = 5
})

print("✅ EVADE HUB – Air Walk + ESP berhasil dimuat!")
print("📌 Air Walk: Lompat lalu jalan di udara!")
print("📌 ESP: Aktifkan di tab ESP")
