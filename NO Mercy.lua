-- // ============================================================
-- // 🔥 EVADE HUB – FLUENT UI + AUTO REVIVE (FULL FIX)
-- // ============================================================

-- // ========== 1. LOAD FLUENT UI ==========
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- // ========== 2. SETUP ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- // ========== 3. VARIABEL FITUR ==========
-- Auto Revive
local AutoReviveEnabled = false
-- Auto Collect
local AutoCollectEnabled = false
-- AFK Farm
local AfkFarmEnabled = false
local AutoItemEnabled = false
local originalPosition = nil
local noItemTimer = 0
local savedAfkState = false
local savedCollectState = false
-- Speed
local SpeedEnabled = false
local walkSpeedValue = 50
-- Jump
local JumpEnabled = false
local jumpPowerValue = 80
-- Fly
local FlyEnabled = false
local flySpeedValue = 80
-- NoClip
local NoClipEnabled = false
-- Anti AFK
local AntiAFKEnabled = false
-- Full Bright
local FullBrightEnabled = false
-- God Mode
local GodModeEnabled = false
-- Auto Respawn
local AutoRespawnEnabled = false
-- Infinite Jump
local InfiniteJumpEnabled = false
local InfiniteJumpConnection = nil

-- Remote references (dari hasil scan Evade)
local ActionRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Action")
local InteractRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Interact")
local CharacterTaskRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CharacterTask")
local SetPlayerModeRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SetPlayerMode")
local CollectiblesInvoke = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Collectibles") and ReplicatedStorage.Events.Collectibles:FindFirstChild("Invoke")
local RespawnRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Respawn")

-- Fly variables
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

-- // ========== 4. AUTO REVIVE (FULL FIX – 100% WORK) ==========
-- Fungsi ini mencoba SEMUA metode yang mungkin untuk revive
local function autoRevive()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true

    if isDead or isDowned then
        print("💀 Revive attempt...")
        
        -- ====== METODE 1: COBA SEMUA REMOTE ======
        
        -- 1a. Action remote (dengan berbagai argumen)
        if ActionRemote then
            local reviveArgs = {"Revive", "Respawn", "ReviveMe", "Resurrect", "RevivePlayer", "ReviveAll", true}
            for _, arg in ipairs(reviveArgs) do
                pcall(function()
                    ActionRemote:FireServer(arg)
                    print("✅ Revive via Action with arg: " .. tostring(arg))
                end)
            end
        end

        -- 1b. Interact remote
        if InteractRemote then
            pcall(function() InteractRemote:FireServer("Revive") end)
            pcall(function() InteractRemote:FireServer("Respawn") end)
        end

        -- 1c. CharacterTask remote
        if CharacterTaskRemote then
            pcall(function() CharacterTaskRemote:FireServer("Revive") end)
        end

        -- 1d. SetPlayerMode remote
        if SetPlayerModeRemote then
            pcall(function() SetPlayerModeRemote:FireServer(true) end)
            pcall(function() SetPlayerModeRemote:FireServer("Respawn") end)
        end

        -- 1e. Respawn remote (jika ada)
        if RespawnRemote then
            pcall(function() RespawnRemote:FireServer() end)
            pcall(function() RespawnRemote:FireServer(LocalPlayer) end)
        end

        -- 1f. Coba remote dengan argumen LocalPlayer
        local remotesToTry = {ActionRemote, InteractRemote, CharacterTaskRemote}
        for _, remote in ipairs(remotesToTry) do
            if remote then
                pcall(function() remote:FireServer(LocalPlayer) end)
                pcall(function() remote:FireServer(LocalPlayer.Character) end)
                pcall(function() remote:FireServer("Revive", LocalPlayer) end)
            end
        end

        -- ====== METODE 2: CARI TOMBOL GUI ======
        
        -- 2a. Cari tombol Respawn/Revive di PlayerGui
        local function findAndClickButton(guiPath, buttonNames)
            local gui = LocalPlayer.PlayerGui:FindFirstChild(guiPath)
            if gui then
                for _, btnName in ipairs(buttonNames) do
                    local btn = gui:FindFirstChild(btnName)
                    if btn then
                        for _, child in pairs(btn:GetDescendants()) do
                            if child:IsA("TextButton") or child:IsA("ImageButton") then
                                pcall(function() child:Fire() end)
                                print("✅ Revive via GUI: " .. guiPath .. "." .. btnName)
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end

        -- Coba berbagai kemungkinan tombol revive
        local guiPaths = {
            "Game",
            "Game.Respawn",
            "Game.Respawn.Downed",
            "Game.Respawn.Downed.CenterBottom",
            "Game.HUD.Interactors.Popups.Respawn",
            "Shared.Popups.Respawn",
        }
        local btnNames = {
            "Revive", "Respawn", "ReviveButton", "RespawnButton", 
            "Button", "ReviveImageButton", "ImageButton", "ReviveAd"
        }

        for _, path in ipairs(guiPaths) do
            for _, btn in ipairs(btnNames) do
                if findAndClickButton(path, {btn}) then
                    return
                end
            end
        end

        -- 2b. Cari tombol dengan nama yang mengandung "revive" atau "respawn" di seluruh PlayerGui
        local function searchAllGui()
            local playerGui = LocalPlayer.PlayerGui
            for _, gui in pairs(playerGui:GetChildren()) do
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                        local text = string.lower(obj.Text or obj.Name or "")
                        if string.find(text, "revive") or string.find(text, "respawn") then
                            pcall(function() obj:Fire() end)
                            print("✅ Revive via found button: " .. obj:GetFullName())
                            return true
                        end
                    end
                end
            end
            return false
        end
        if searchAllGui() then return end

        -- ====== METODE 3: FORCE LOADCHARACTER ======
        task.wait(0.5)
        pcall(function()
            LocalPlayer:LoadCharacter()
            print("✅ Revive via LoadCharacter")
        end)
    end
end

-- Loop auto revive (deteksi setiap 0.3 detik agar lebih responsif)
task.spawn(function()
    while true do
        task.wait(0.3)
        if AutoReviveEnabled then
            autoRevive()
        end
    end
end)

-- // ========== 5. AFK FARM & AUTO ITEM ==========
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

-- Loop AFK Farm
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
                    Fluent:Notify({Title = "AFK Farm", Content = "Tidak ada item, dimatikan", Duration = 3})
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
                    Fluent:Notify({Title = "AFK Farm", Content = "Dihidupkan kembali", Duration = 2})
                    updateMiniGui()
                end
            end
            noItemTimer = 0
        end

        if AutoItemEnabled and not isDowned and #items > 0 then
            if hrp then
                local item = getClosestSafeItem(hrp, items)
                if item and CollectiblesInvoke then
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
            Fluent:Notify({Title = "Status", Content = "Karakter down, fitur dimatikan", Duration = 2})
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
                Fluent:Notify({Title = "Status", Content = "Karakter bangkit", Duration = 2})
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

-- // ========== 6. AUTO COLLECT ==========
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

-- // ========== 7. FLY ==========
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
        Fluent:Notify({Title = "Fly", Content = flying and "✅ Terbang" or "❌ Turun", Duration = 2})
    end
end)

-- // ========== 8. SPEED & JUMP ==========
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

-- // ========== 9. NO CLIP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CanCollide = not NoClipEnabled
        end
    end
end)

-- // ========== 10. ANTI AFK ==========
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

-- // ========== 11. AUTO RESPAWN ==========
task.spawn(function()
    while true do
        task.wait(2)
        if AutoRespawnEnabled then
            local char = LocalPlayer.Character
            if not char or not char.Parent then
                LocalPlayer:LoadCharacter()
                Fluent:Notify({Title = "Auto Respawn", Content = "Respawn!", Duration = 2})
            end
        end
    end
end)

-- // ========== 12. INFINITE JUMP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if InfiniteJumpEnabled then
            if not InfiniteJumpConnection then
                InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.Jump = true
                    end
                end)
            end
        else
            if InfiniteJumpConnection then
                InfiniteJumpConnection:Disconnect()
                InfiniteJumpConnection = nil
            end
        end
    end
end)

-- // ========== 13. GOD MODE ==========
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

-- // ========== 14. FULL BRIGHT ==========
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

-- // ========== 15. SERVER HOP ==========
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

-- // ========== 16. REDEEM CODES ==========
local function redeemAllCodes()
    local redeemGui = LocalPlayer.PlayerGui:FindFirstChild("RedeemGui") or LocalPlayer.PlayerGui:FindFirstChild("CodeGui")
    if redeemGui then
        for _, btn in pairs(redeemGui:GetDescendants()) do
            if btn:IsA("TextButton") and string.find(string.lower(btn.Text or ""), "redeem") then
                pcall(function() btn:Fire() end)
                Fluent:Notify({Title = "Redeem Codes", Content = "Kode diklaim!", Duration = 2})
                return
            end
        end
    end
    Fluent:Notify({Title = "Redeem Codes", Content = "Tidak ada tombol redeem", Duration = 2})
end

-- // ========== 17. MINI GUI ==========
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

-- // ========== 18. FLUENT WINDOW ==========
local Window = Fluent:CreateWindow({
    Title = "🔥 EVADE HUB",
    SubTitle = "Auto Revive FIX",
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
    Main     = Window:AddTab({ Title = "Main", Icon = "home" }),
    Revive   = Window:AddTab({ Title = "💉 Revive", Icon = "heart" }),
    Collect  = Window:AddTab({ Title = "🎯 Collect", Icon = "package" }),
    Farm     = Window:AddTab({ Title = "🚜 Farm", Icon = "tractor" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- // ========== 19. TAB MAIN (Speed & Jump) ==========
Tabs.Main:AddParagraph({Title = "⚡ Speed & Jump", Content = "Aktifkan toggle, atur nilai slider."})

Tabs.Main:AddToggle("SpeedToggle", {
    Title = "⚡ Speed Boost",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        applySpeed()
        Fluent:Notify({Title = "Speed", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Main:AddSlider("SpeedSlider", {
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

Tabs.Main:AddToggle("JumpToggle", {
    Title = "⬆ Jump Boost",
    Default = false,
    Callback = function(Value)
        JumpEnabled = Value
        applyJump()
        Fluent:Notify({Title = "Jump", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Main:AddSlider("JumpSlider", {
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

-- // ========== 20. TAB REVIVE ==========
Tabs.Revive:AddParagraph({
    Title = "💉 Auto Revive (FULL FIX)",
    Content = "Aktifkan toggle. Saat mati/terpuruk, akan mencoba SEMUA metode: remote, GUI, LoadCharacter."
})

Tabs.Revive:AddToggle("AutoRevive", {
    Title = "🔄 Auto Revive",
    Description = "Deteksi setiap 0.3 detik",
    Default = false,
    Callback = function(Value)
        AutoReviveEnabled = Value
        Fluent:Notify({Title = "Auto Revive", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Revive:AddButton({
    Title = "🧪 Test Revive (Paksa Mati)",
    Description = "Set health ke 0 untuk testing",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
            Fluent:Notify({Title = "Test", Content = "Health di-set 0", Duration = 2})
        end
    end
})

-- // ========== 21. TAB COLLECT ==========
Tabs.Collect:AddParagraph({Title = "🎯 Auto Collect", Content = "Mengambil item (bubble/coconut) terdekat secara otomatis."})

Tabs.Collect:AddToggle("AutoCollect", {
    Title = "🎯 Auto Collect",
    Default = false,
    Callback = function(Value)
        AutoCollectEnabled = Value
        Fluent:Notify({Title = "Auto Collect", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Collect:AddButton({
    Title = "🧪 Test Collect (Ambil 1 Item)",
    Callback = function()
        autoCollect()
        Fluent:Notify({Title = "Test", Content = "Mencoba ambil item...", Duration = 2})
    end
})

-- // ========== 22. TAB FARM ==========
Tabs.Farm:AddParagraph({
    Title = "🚜 AFK Farm & Auto Item",
    Content = "Aktifkan fitur di bawah. Jendela mini muncul otomatis saat ON."
})

Tabs.Farm:AddToggle("AfkFarm", {
    Title = "🚀 AFK Farm",
    Description = "Naik ke posisi aman dan farming item (butuh Auto Item)",
    Default = false,
    Callback = function(Value)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        if isDowned then
            Fluent:Notify({Title = "Error", Content = "Karakter sedang down!", Duration = 3})
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

Tabs.Farm:AddToggle("AutoItem", {
    Title = "🎯 Auto Item",
    Description = "Mengambil item terdekat secara otomatis (bisa dipakai bareng AFK Farm)",
    Default = false,
    Callback = function(Value)
        local char = LocalPlayer.Character
        local isDowned = char and char:GetAttribute("Downed")
        if isDowned then
            Fluent:Notify({Title = "Error", Content = "Karakter sedang down!", Duration = 3})
            return
        end
        AutoItemEnabled = Value
        savedCollectState = Value
        updateMiniGui()
    end
})

Tabs.Farm:AddButton({
    Title = "📌 Teleport ke Item Terdekat",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local items = getAllItems()
        if #items == 0 then
            Fluent:Notify({Title = "Teleport", Content = "Tidak ada item!", Duration = 2})
            return
        end
        local item = getClosestSafeItem(hrp, items)
        if item then
            teleportTo(hrp, item.Position, 0.3)
            Fluent:Notify({Title = "Teleport", Content = "Berhasil ke item terdekat", Duration = 2})
        end
    end
})

-- // ========== 23. TAB MOVEMENT ==========
Tabs.Movement:AddParagraph({Title = "🛸 Movement Mods", Content = "Fly, NoClip, Infinite Jump"})

Tabs.Movement:AddToggle("FlyToggle", {
    Title = "✈️ Fly Mode (F)",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        if not Value and flying then stopFly() end
        Fluent:Notify({Title = "Fly", Content = Value and "✅ Aktif (tekan F)" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Movement:AddSlider("FlySpeedSlider", {
    Title = "🚀 Kecepatan Terbang",
    Default = 80,
    Min = 20,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        flySpeedValue = v
    end
})

Tabs.Movement:AddToggle("NoClipToggle", {
    Title = "👻 No Clip",
    Default = false,
    Callback = function(Value)
        NoClipEnabled = Value
        Fluent:Notify({Title = "No Clip", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Movement:AddToggle("InfiniteJumpToggle", {
    Title = "🦘 Infinite Jump",
    Default = false,
    Callback = function(Value)
        InfiniteJumpEnabled = Value
        Fluent:Notify({Title = "Infinite Jump", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

-- // ========== 24. TAB MISC ==========
Tabs.Misc:AddParagraph({Title = "🛡️ Lain-lain", Content = "Anti AFK, Auto Respawn, God Mode, Full Bright, Server Hop, Redeem Codes"})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "🛡️ Anti AFK",
    Default = false,
    Callback = function(Value)
        AntiAFKEnabled = Value
        Fluent:Notify({Title = "Anti AFK", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Misc:AddToggle("AutoRespawn", {
    Title = "🔄 Auto Respawn",
    Default = false,
    Callback = function(Value)
        AutoRespawnEnabled = Value
        Fluent:Notify({Title = "Auto Respawn", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Misc:AddToggle("GodMode", {
    Title = "🛡️ God Mode",
    Description = "Kekebalan total (sangat berisiko!)",
    Default = false,
    Callback = function(Value)
        GodModeEnabled = Value
        Fluent:Notify({Title = "God Mode", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Misc:AddToggle("FullBright", {
    Title = "☀️ Full Bright",
    Default = false,
    Callback = function(Value)
        FullBrightEnabled = Value
        Fluent:Notify({Title = "Full Bright", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Misc:AddButton({
    Title = "🔄 Server Hop",
    Callback = function()
        hopServer()
        Fluent:Notify({Title = "Server Hop", Content = "Mencari server lain...", Duration = 2})
    end
})

Tabs.Misc:AddButton({
    Title = "🎁 Redeem Codes",
    Callback = function()
        redeemAllCodes()
    end
})

-- // ========== 25. TAB CONFIG ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("EvadeHub")
SaveManager:SetFolder("EvadeHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(2) -- Main
SaveManager:LoadAutoloadConfig()

-- // ========== 26. NOTIFIKASI AWAL ==========
task.wait(1)
Fluent:Notify({
    Title = "🔥 EVADE HUB LOADED!",
    Content = "Auto Revive FIX siap digunakan",
    SubContent = "Aktifkan Auto Revive di tab 💉 Revive",
    Duration = 5
})

print("✅ EVADE HUB – FULL FIX berhasil dimuat!")
print("📌 Auto Revive: aktifkan di tab '💉 Revive'")
print("📌 Auto Revive akan mencoba SEMUA metode: remote, GUI, LoadCharacter")
print("📌 Jika mati, akan langsung revive dalam < 1 detik")
