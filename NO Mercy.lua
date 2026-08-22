-- // ============================================================
-- // 🔥 EVADE HUB – ORION UI (NO MERCY STYLE)
-- // ============================================================

-- // ========== 1. LOAD ORION UI ==========
local ICON = {
    Info     = "rbxassetid://7733964719",
    Crosshair= "rbxassetid://7733765307",
    Swords   = "rbxassetid://7734056608",
    Globe    = "rbxassetid://7733954760",
    Axe      = "rbxassetid://7733674079",
    User     = "rbxassetid://7743875962",
    Eye      = "rbxassetid://7733774602",
    Zap      = "rbxassetid://7733771628",
    Settings = "rbxassetid://7734053495",
    Logo     = "rbxassetid://102609928046926",
}

local function GetHolder()
    return (gethui and gethui()) or game:GetService("CoreGui")
end

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Marpiii/UiLib/refs/heads/main/source.lua"))()

-- Forward declaration
local onCloseRequest

local Window = OrionLib:MakeWindow({
    Name = "🔥 EVADE HUB",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "EvadeHubOrion",
    IntroEnabled = true,
    IntroText = "EVADE HUB",
    IntroIcon = ICON.Logo,
    Icon = ICON.Logo,
    CloseCallback = function()
        if onCloseRequest then onCloseRequest() end
    end,
})

-- // ========== 2. UTIL – Cari Window Utama ==========
local function FindMainWindow()
    local root = GetHolder()
    if not root then return nil end
    local marv = root:FindFirstChild("MarV")
    if not marv then return nil end

    for _, child in ipairs(marv:GetChildren()) do
        if child:IsA("Frame") and child.AbsoluteSize.X > 300 then
            return child
        end
    end
    return nil
end

-- // ========== 3. BUBBLE TOGGLE ==========
local bubbleGui = nil

local function makeBubble()
    if bubbleGui then bubbleGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "EvadeBubble"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = GetHolder()
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

    local btn = Instance.new("ImageButton")
    btn.Parent = gui
    btn.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
    btn.Position = UDim2.new(0.02, 0, 0.2, 0)
    btn.Size = UDim2.fromOffset(48, 48)
    btn.Image = ICON.Logo
    btn.ScaleType = Enum.ScaleType.Fit
    btn.Active = true
    btn.Draggable = true
    btn.ZIndex = 10

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 100, 50)
    stroke.Thickness = 2
    stroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local main = FindMainWindow()
        if main then
            main.Visible = true
        end
        bubbleGui:Destroy()
        bubbleGui = nil
    end)

    bubbleGui = gui
end

-- // ========== 4. TUTUP UI ==========
local function closeUI()
    local main = FindMainWindow()
    if main then
        main.Visible = false
    end
    makeBubble()
end

local function showUI()
    local main = FindMainWindow()
    if main then
        main.Visible = true
    end
end

-- // ========== 5. KONFIRMASI TUTUP ==========
local function confirmClose(fromCloseBtn)
    if fromCloseBtn then
        showUI()
    end

    local holder = GetHolder()

    local gui = Instance.new("ScreenGui")
    gui.Name = "EvadeConfirm"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = holder
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

    local fade = Instance.new("Frame")
    fade.Size = UDim2.new(1, 0, 1, 0)
    fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fade.BackgroundTransparency = 0.4
    fade.ZIndex = 99
    fade.Parent = gui

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(280, 150)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.BackgroundColor3 = Color3.fromRGB(28, 32, 38)
    box.BorderSizePixel = 0
    box.ZIndex = 100
    box.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = box

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "Tutup EVADE HUB?"
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 101
    title.Parent = box

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 30)
    desc.Position = UDim2.new(0, 20, 0, 48)
    desc.BackgroundTransparency = 1
    desc.Text = "Klik bubble untuk buka lagi."
    desc.TextColor3 = Color3.fromRGB(150, 150, 150)
    desc.TextSize = 14
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.ZIndex = 101
    desc.Parent = box

    local function destroy()
        gui:Destroy()
    end

    local function cancel()
        destroy()
        if fromCloseBtn then
            showUI()
        end
    end

    local btnYa = Instance.new("TextButton")
    btnYa.Size = UDim2.fromOffset(90, 36)
    btnYa.Position = UDim2.new(1, -200, 1, -50)
    btnYa.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    btnYa.BorderSizePixel = 0
    btnYa.Text = "Ya"
    btnYa.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnYa.TextSize = 15
    btnYa.Font = Enum.Font.GothamBold
    btnYa.ZIndex = 101
    btnYa.Parent = box
    local cYa = Instance.new("UICorner"); cYa.CornerRadius = UDim.new(0, 8); cYa.Parent = btnYa

    btnYa.MouseButton1Click:Connect(function()
        destroy()
        closeUI()
    end)

    local btnTidak = Instance.new("TextButton")
    btnTidak.Size = UDim2.fromOffset(90, 36)
    btnTidak.Position = UDim2.new(1, -100, 1, -50)
    btnTidak.BackgroundColor3 = Color3.fromRGB(50, 55, 62)
    btnTidak.BorderSizePixel = 0
    btnTidak.Text = "Tidak"
    btnTidak.TextColor3 = Color3.fromRGB(240, 240, 240)
    btnTidak.TextSize = 15
    btnTidak.Font = Enum.Font.GothamBold
    btnTidak.ZIndex = 101
    btnTidak.Parent = box
    local cT = Instance.new("UICorner"); cT.CornerRadius = UDim.new(0, 8); cT.Parent = btnTidak

    btnTidak.MouseButton1Click:Connect(cancel)
    fade.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            cancel()
        end
    end)
end

onCloseRequest = function()
    confirmClose(true)
end

-- // ========== 6. SETUP GAME ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

-- // ========== 7. REMOTE REFERENCES ==========
local ActionRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Action")
local InteractRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Interact")
local CharacterTaskRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CharacterTask")
local SetPlayerModeRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SetPlayerMode")
local CollectiblesInvoke = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Collectibles") and ReplicatedStorage.Events.Collectibles:FindFirstChild("Invoke")

-- // ========== 8. VARIABEL FITUR ==========
-- AFK Farm & Auto Item
local AfkFarmEnabled = false
local AutoItemEnabled = false
local originalPosition = nil
local noItemTimer = 0
local savedAfkState = false
local savedCollectState = false

-- Speed & Jump
local SpeedEnabled = false
local JumpEnabled = false
local walkSpeedValue = 50
local jumpPowerValue = 80

-- Fly
local FlyEnabled = false
local flySpeedValue = 80
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

-- Lainnya
local NoClipEnabled = false
local AntiAFKEnabled = false
local AutoRespawnEnabled = false
local GodModeEnabled = false
local FullBrightEnabled = false
local AutoReviveEnabled = false
local AutoCollectEnabled = false
local InfiniteJumpEnabled = false
local InfiniteJumpConnection = nil

-- // ========== 9. FUNGSI UTILITY ==========
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

-- // ========== 10. AUTO REVIVE ==========
local function autoRevive()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true

    if isDead or isDowned then
        if ActionRemote then
            pcall(function() ActionRemote:FireServer("Revive") end)
            pcall(function() ActionRemote:FireServer("Respawn") end)
        end
        if InteractRemote then
            pcall(function() InteractRemote:FireServer("Revive") end)
        end
        if CharacterTaskRemote then
            pcall(function() CharacterTaskRemote:FireServer("Revive") end)
        end
        if SetPlayerModeRemote then
            pcall(function() SetPlayerModeRemote:FireServer(true) end)
        end

        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("Game")
        if reviveGui then
            local respawnBtn = reviveGui:FindFirstChild("Respawn")
            if respawnBtn then
                for _, btn in pairs(respawnBtn:GetDescendants()) do
                    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                        pcall(function() btn:Fire() end)
                        break
                    end
                end
            end
        end

        task.wait(0.5)
        pcall(function() LocalPlayer:LoadCharacter() end)
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoReviveEnabled then
            autoRevive()
        end
    end
end)

-- // ========== 11. AUTO COLLECT ==========
local function autoCollect()
    if not CollectiblesInvoke then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local items = getAllItems()
    if #items == 0 then return end
    
    local item = getClosestSafeItem(hrp, items)
    if item then
        local startPos = hrp.Position
        hrp.Anchored = false
        teleportTo(hrp, item.Position, 0.2)
        pcall(function()
            local collectId = item.Parent:GetAttribute("Id") or item:GetAttribute("Id") or "a19ac91bff904b7385e826fd6a23dc01"
            CollectiblesInvoke:InvokeServer(LocalPlayer, collectId, "Collect")
        end)
        task.wait(0.3)
        teleportTo(hrp, startPos, 0.2)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if AutoCollectEnabled then
            autoCollect()
        end
    end
end)

-- // ========== 12. AFK FARM & AUTO ITEM ==========
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
                        CollectiblesInvoke:InvokeServer(LocalPlayer, collectId, "Collect")
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

task.spawn(function()
    while true do
        task.wait(2)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        
        if AfkFarmEnabled and not AutoItemEnabled and not isDowned and noItemTimer < 20 then
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored == false then
                originalPosition = hrp.Position + Vector3.new(0, 200, 0)
                hrp.CFrame = CFrame.new(originalPosition)
                task.wait(0.1)
                hrp.Anchored = true
            end
        end
    end
end)

local function setupCharacter(char)
    char:GetAttributeChangedSignal("Downed"):Connect(function()
        local isDowned = char:GetAttribute("Downed")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if isDowned then
            AutoItemEnabled = false
            AfkFarmEnabled = false
            savedAfkState = false
            savedCollectState = false
            if hrp then hrp.Anchored = false end
            updateMiniGui()
        else
            task.wait(1)
            if hrp then
                originalPosition = hrp.Position + Vector3.new(0, 200, 0)
                hrp.CFrame = CFrame.new(originalPosition)
                task.wait(0.2)
                hrp.Anchored = true
                
                AfkFarmEnabled = savedAfkState
                AutoItemEnabled = savedCollectState
                updateMiniGui()
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    setupCharacter(char)
end)

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

-- // ========== 13. FLY ==========
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid or flying then return end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 10^6
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 10^6
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
    humanoid.PlatformStand = true
end

local function stopFly()
    if not flying then return end
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if not flying then continue end
        local char = LocalPlayer.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local camera = workspace.CurrentCamera
        if camera and bodyVelocity then
            bodyVelocity.Velocity = camera.CFrame.LookVector * flySpeedValue
        end
        if bodyGyro and camera then
            bodyGyro.CFrame = camera.CFrame
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and FlyEnabled then
        if flying then stopFly() else startFly() end
    end
end)

-- // ========== 14. SPEED & JUMP ==========
local function applySpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = SpeedEnabled and walkSpeedValue or 16
    end
end

local function applyJump()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = JumpEnabled and jumpPowerValue or 50
    end
end

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
end)

-- // ========== 15. NO CLIP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CanCollide = not NoClipEnabled
        end
    end
end)

-- // ========== 16. ANTI AFK ==========
task.spawn(function()
    while true do
        task.wait(30)
        if AntiAFKEnabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end
end)

-- // ========== 17. AUTO RESPAWN ==========
task.spawn(function()
    while true do
        task.wait(2)
        if AutoRespawnEnabled then
            local char = LocalPlayer.Character
            if not char or not char.Parent then
                LocalPlayer:LoadCharacter()
            end
        end
    end
end)

-- // ========== 18. GOD MODE ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if GodModeEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.MaxHealth = math.huge
                char.Humanoid.Health = math.huge
                char.Humanoid.BreakJointsOnDeath = false
            end
        end
    end
end)

-- // ========== 19. FULL BRIGHT ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if FullBrightEnabled then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").FogEnd = 1000
            game:GetService("Lighting").GlobalShadows = true
        end
    end
end)

-- // ========== 20. SERVER HOP ==========
local function hopServer()
    local placeId = game.PlaceId
    local servers = {}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            table.insert(servers, v)
        end
    end
    if #servers > 0 then
        local server = servers[math.random(1, #servers)]
        if server and server.Team then
            TeleportService:TeleportToPlaceInstance(placeId, server.Team, LocalPlayer)
        end
    end
end

-- // ========== 21. REDEEM CODES ==========
local function redeemAllCodes()
    local redeemGui = LocalPlayer.PlayerGui:FindFirstChild("RedeemGui") or LocalPlayer.PlayerGui:FindFirstChild("CodeGui")
    if redeemGui then
        for _, btn in pairs(redeemGui:GetDescendants()) do
            if btn:IsA("TextButton") and string.find(string.lower(btn.Text or ""), "redeem") then
                pcall(function() btn:Fire() end)
                return
            end
        end
    end
end

-- // ========== 22. MINI GUI ==========
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
    frame.BorderColor3 = Color3.fromRGB(255, 100, 50)
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
        ItemCount = itemCount
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

-- // ========== 23. TAB ==========
local InfoTab     = Window:MakeTab({ Name = "Info", Icon = ICON.Info, PremiumOnly = false })
local MainTab     = Window:MakeTab({ Name = "Main", Icon = ICON.Zap, PremiumOnly = false })
local ReviveTab   = Window:MakeTab({ Name = "💉 Revive", Icon = ICON.User, PremiumOnly = false })
local CollectTab  = Window:MakeTab({ Name = "🎯 Collect", Icon = ICON.Globe, PremiumOnly = false })
local UtilityTab  = Window:MakeTab({ Name = "Utility", Icon = ICON.Swords, PremiumOnly = false })
local VisualTab   = Window:MakeTab({ Name = "Visual", Icon = ICON.Eye, PremiumOnly = false })
local MiscTab     = Window:MakeTab({ Name = "Misc", Icon = ICON.Axe, PremiumOnly = false })
local SettingsTab = Window:MakeTab({ Name = "Pengaturan", Icon = ICON.Settings, PremiumOnly = false })

-- // ========== 24. TAB INFO ==========
local InfoSec = InfoTab:AddSection({ Name = "Tentang" })
InfoSec:AddLabel("🔥 EVADE HUB")
InfoSec:AddLabel("Script by: No Mercy Team")
InfoSec:AddLabel("Fitur: AFK Farm, Auto Item, Auto Revive, Auto Collect, Speed, Jump, Fly, NoClip, Anti AFK, Auto Respawn, God Mode, Full Bright, Server Hop, Redeem Codes")
InfoSec:AddButton({
    Name = "Copy Link Discord",
    Callback = function()
        if setclipboard then setclipboard("https://discord.gg/pbg6g79Hp") end
        OrionLib:MakeNotification({ Name = "EVADE HUB", Content = "Link Discord di-copy!", Image = ICON.Logo, Time = 3 })
    end,
})

-- // ========== 25. TAB MAIN ==========
local MainSec = MainTab:AddSection({ Name = "AFK Farm & Auto Item" })
MainSec:AddToggle({
    Name = "🚀 AFK Farm",
    Default = false,
    Callback = function(Value)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        if isDowned then
            OrionLib:MakeNotification({ Name = "Error", Content = "Karakter sedang down!", Image = ICON.Logo, Time = 3 })
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

MainSec:AddToggle({
    Name = "🎯 Auto Item",
    Default = false,
    Callback = function(Value)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        if isDowned then
            OrionLib:MakeNotification({ Name = "Error", Content = "Karakter sedang down!", Image = ICON.Logo, Time = 3 })
            return
        end
        AutoItemEnabled = Value
        savedCollectState = Value
        updateMiniGui()
    end
})

local SpeedSec = MainTab:AddSection({ Name = "⚡ Speed & Jump" })
SpeedSec:AddToggle({
    Name = "⚡ Speed Boost",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        applySpeed()
    end
})

SpeedSec:AddSlider({
    Name = "🏃 Kecepatan",
    Min = 16,
    Max = 200,
    Default = 50,
    Increment = 1,
    ValueName = "speed",
    Callback = function(v)
        walkSpeedValue = v
        if SpeedEnabled then applySpeed() end
    end
})

SpeedSec:AddToggle({
    Name = "⬆ Jump Boost",
    Default = false,
    Callback = function(Value)
        JumpEnabled = Value
        applyJump()
    end
})

SpeedSec:AddSlider({
    Name = "💪 Kekuatan Lompat",
    Min = 20,
    Max = 300,
    Default = 80,
    Increment = 1,
    ValueName = "jump",
    Callback = function(v)
        jumpPowerValue = v
        if JumpEnabled then applyJump() end
    end
})

-- // ========== 26. TAB REVIVE ==========
local ReviveSec = ReviveTab:AddSection({ Name = "💉 Auto Revive" })
ReviveSec:AddToggle({
    Name = "🔄 Auto Revive",
    Default = false,
    Callback = function(Value)
        AutoReviveEnabled = Value
        OrionLib:MakeNotification({ Name = "Auto Revive", Content = Value and "✅ Aktif" or "❌ Nonaktif", Image = ICON.Logo, Time = 2 })
    end
})

ReviveSec:AddButton({
    Name = "🧪 Test Revive (Paksa Mati)",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
            OrionLib:MakeNotification({ Name = "Test", Content = "Health di-set 0", Image = ICON.Logo, Time = 2 })
        end
    end
})

-- // ========== 27. TAB COLLECT ==========
local CollectSec = CollectTab:AddSection({ Name = "🎯 Auto Collect" })
CollectSec:AddToggle({
    Name = "🎯 Auto Collect",
    Default = false,
    Callback = function(Value)
        AutoCollectEnabled = Value
        OrionLib:MakeNotification({ Name = "Auto Collect", Content = Value and "✅ Aktif" or "❌ Nonaktif", Image = ICON.Logo, Time = 2 })
    end
})

CollectSec:AddButton({
    Name = "🧪 Test Collect (Ambil 1 Item)",
    Callback = function()
        autoCollect()
        OrionLib:MakeNotification({ Name = "Test", Content = "Mencoba ambil item...", Image = ICON.Logo, Time = 2 })
    end
})

-- // ========== 28. TAB UTILITY ==========
local UtilitySec = UtilityTab:AddSection({ Name = "🛠️ Utility" })
UtilitySec:AddToggle({
    Name = "🛡️ Anti AFK",
    Default = false,
    Callback = function(Value)
        AntiAFKEnabled = Value
    end
})

UtilitySec:AddToggle({
    Name = "🔄 Auto Respawn",
    Default = false,
    Callback = function(Value)
        AutoRespawnEnabled = Value
    end
})

UtilitySec:AddToggle({
    Name = "✈️ Fly Mode (F)",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        if not Value and flying then stopFly() end
    end
})

UtilitySec:AddSlider({
    Name = "🚀 Kecepatan Terbang",
    Min = 20,
    Max = 200,
    Default = 80,
    Increment = 1,
    ValueName = "speed",
    Callback = function(v)
        flySpeedValue = v
    end
})

UtilitySec:AddToggle({
    Name = "👻 No Clip",
    Default = false,
    Callback = function(Value)
        NoClipEnabled = Value
    end
})

UtilitySec:AddToggle({
    Name = "🦘 Infinite Jump",
    Default = false,
    Callback = function(Value)
        InfiniteJumpEnabled = Value
        if Value then
            InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Jump = true
                end
            end)
        else
            if InfiniteJumpConnection then
                InfiniteJumpConnection:Disconnect()
                InfiniteJumpConnection = nil
            end
        end
    end
})

UtilitySec:AddButton({
    Name = "📌 Teleport ke Item Terdekat",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local items = getAllItems()
        if #items == 0 then
            OrionLib:MakeNotification({ Name = "Teleport", Content = "Tidak ada item!", Image = ICON.Logo, Time = 2 })
            return
        end
        local item = getClosestSafeItem(hrp, items)
        if item then
            teleportTo(hrp, item.Position, 0.3)
            OrionLib:MakeNotification({ Name = "Teleport", Content = "Berhasil ke item terdekat", Image = ICON.Logo, Time = 2 })
        end
    end
})

-- // ========== 29. TAB VISUAL ==========
local VisualSec = VisualTab:AddSection({ Name = "👁️ Visual" })
VisualSec:AddToggle({
    Name = "☀️ Full Bright",
    Default = false,
    Callback = function(Value)
        FullBrightEnabled = Value
    end
})

VisualSec:AddToggle({
    Name = "🛡️ God Mode",
    Default = false,
    Callback = function(Value)
        GodModeEnabled = Value
    end
})

-- // ========== 30. TAB MISC ==========
local MiscSec = MiscTab:AddSection({ Name = "🎮 Lain-lain" })
MiscSec:AddButton({
    Name = "🔄 Server Hop",
    Callback = function()
        hopServer()
        OrionLib:MakeNotification({ Name = "Server Hop", Content = "Mencari server lain...", Image = ICON.Logo, Time = 2 })
    end
})

MiscSec:AddButton({
    Name = "🎁 Redeem Codes",
    Callback = function()
        redeemAllCodes()
        OrionLib:MakeNotification({ Name = "Redeem Codes", Content = "Mencoba klaim kode...", Image = ICON.Logo, Time = 2 })
    end
})

-- // ========== 31. TAB PENGATURAN ==========
local SettingsSec = SettingsTab:AddSection({ Name = "Pengaturan" })

SettingsSec:AddButton({
    Name = "💾 Save Config",
    Callback = function()
        OrionLib:SaveConfig()
        OrionLib:MakeNotification({ Name = "Config", Content = "Config disimpan!", Image = ICON.Logo, Time = 2 })
    end
})

SettingsSec:AddButton({
    Name = "📂 Load Config",
    Callback = function()
        OrionLib:LoadConfig()
        OrionLib:MakeNotification({ Name = "Config", Content = "Config dimuat!", Image = ICON.Logo, Time = 2 })
    end
})

SettingsSec:AddButton({
    Name = "❌ Tutup UI (Close)",
    Callback = function()
        confirmClose()
    end
})

-- // ========== 32. NOTIFIKASI LOAD ==========
OrionLib:MakeNotification({ 
    Name = "🔥 EVADE HUB", 
    Content = "Semua fitur siap digunakan!", 
    Image = ICON.Logo, 
    Time = 4 
})

print("[EVADE HUB] Loaded — Orion UI")
print("📌 Buka menu dan aktifkan fitur yang diinginkan!")
print("📌 Klik bubble logo untuk buka UI lagi")
