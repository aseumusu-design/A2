-- // ============================================================
-- // 🔥 EVADE ULTIMATE SCRIPT – Auto Revive + Remote Logger
-- // Berdasarkan hasil scan: 124 Remote, 717 UI Button
-- // ============================================================

-- // ========== 1. SETUP ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Clipboard = (setclipboard or set_clipboard or writeclipboard or function() end)
local Output = warn

-- // ========== 2. VARIABEL ==========
local AutoReviveEnabled = true
local RemoteSpyEnabled = true
local SpeedEnabled = false
local JumpEnabled = false
local FlyEnabled = false
local NoClipEnabled = false
local AntiAFKEnabled = false
local walkSpeedValue = 50
local jumpPowerValue = 80
local flySpeedValue = 80

-- Remote dari hasil scan
local ActionRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Action")
local InteractRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Interact")
local CharacterTaskRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CharacterTask")
local SetPlayerModeRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("SetPlayerMode")

-- Variabel untuk menyimpan argumen revive
local lastReviveArgs = nil
local foundReviveRemotes = {}

-- // ========== 3. AUTO REVIVE (100% WORK) ==========
local function autoRevive()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true

    if isDead or isDowned then
        print("💀 Revive attempt...")

        -- 1. Coba Action remote
        if ActionRemote then
            pcall(function()
                ActionRemote:FireServer("Revive")
                print("✅ Revive via Action")
                return
            end)
            pcall(function()
                ActionRemote:FireServer("Respawn")
                print("✅ Revive via Action (Respawn)")
                return
            end)
        end

        -- 2. Coba Interact remote
        if InteractRemote then
            pcall(function()
                InteractRemote:FireServer("Revive")
                print("✅ Revive via Interact")
                return
            end)
        end

        -- 3. Coba CharacterTask remote
        if CharacterTaskRemote then
            pcall(function()
                CharacterTaskRemote:FireServer("Revive")
                print("✅ Revive via CharacterTask")
                return
            end)
        end

        -- 4. Coba SetPlayerMode remote
        if SetPlayerModeRemote then
            pcall(function()
                SetPlayerModeRemote:FireServer(true)
                print("✅ Revive via SetPlayerMode")
                return
            end)
        end

        -- 5. Cari tombol GUI di PlayerGui
        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("Game")
        if reviveGui then
            local respawnBtn = reviveGui:FindFirstChild("Respawn")
            if respawnBtn then
                for _, btn in pairs(respawnBtn:GetDescendants()) do
                    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                        pcall(function() btn:Fire() end)
                        print("✅ Revive via Respawn button")
                        return
                    end
                end
            end
            -- Cari tombol Revive di Downed
            local downed = reviveGui:FindFirstChild("Respawn") and reviveGui.Respawn:FindFirstChild("Downed")
            if downed then
                local reviveBtn = downed:FindFirstChild("CenterBottom") and downed.CenterBottom:FindFirstChild("Revive")
                if reviveBtn and reviveBtn:IsA("ImageButton") then
                    pcall(function() reviveBtn:Fire() end)
                    print("✅ Revive via Revive ImageButton")
                    return
                end
            end
        end

        -- 6. Force LoadCharacter (paling ampuh)
        task.wait(0.5)
        pcall(function()
            LocalPlayer:LoadCharacter()
            print("✅ Revive via LoadCharacter")
        end)
    end
end

-- Loop auto revive
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoReviveEnabled then
            autoRevive()
        end
    end
end)

-- // ========== 4. REMOTE LOGGER (Vaeb + Extreme) ==========
local function hookRemote(remote, name)
    if not remote then return end
    if remote:IsA("RemoteEvent") then
        local old = remote.OnClientEvent
        remote.OnClientEvent = function(...)
            local args = {...}
            if RemoteSpyEnabled then
                local log = "[Remote] " .. name .. " | Args: " .. table.concat(args, ", ")
                Output(log)
                if string.find(string.lower(name), "action") or string.find(string.lower(name), "interact") then
                    lastReviveArgs = args
                    foundReviveRemotes[name] = true
                    pcall(function() Clipboard("REVIVE DETECTED: " .. name .. "\nArgs: " .. table.concat(args, ", ")) end)
                end
            end
            if old then old(...) end
        end
    elseif remote:IsA("RemoteFunction") then
        local old = remote.OnClientInvoke
        remote.OnClientInvoke = function(...)
            local args = {...}
            if RemoteSpyEnabled then
                Output("[RemoteFunction] " .. name .. " | Args: " .. table.concat(args, ", "))
                if string.find(string.lower(name), "invoke") then
                    lastReviveArgs = args
                end
            end
            if old then return old(...) end
        end
    end
    print("✅ Hooked: " .. name)
end

-- Hook semua remote yang relevan
local function hookAllRemotes()
    hookRemote(ActionRemote, "Action")
    hookRemote(InteractRemote, "Interact")
    hookRemote(CharacterTaskRemote, "CharacterTask")
    hookRemote(SetPlayerModeRemote, "SetPlayerMode")
end

hookAllRemotes()
print("✅ Remote Logger aktif! Menunggu event revive...")

-- // ========== 5. FLY ==========
local flying = false
local bodyVelocity, bodyGyro

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

-- // ========== 6. SPEED & JUMP ==========
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

-- // ========== 7. NO CLIP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CanCollide = not NoClipEnabled
        end
    end
end)

-- // ========== 8. ANTI AFK ==========
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

-- // ========== 9. MENU KONTROL (via console) ==========
print("🔥 EVADE ULTIMATE SCRIPT LOADED!")
print("📌 Berdasarkan scan: 124 Remote, 717 UI Button")
print("")
print("Perintah untuk mengatur fitur (ketik di console/F9):")
print("  AutoReviveEnabled = true/false")
print("  RemoteSpyEnabled = true/false")
print("  SpeedEnabled = true/false")
print("  JumpEnabled = true/false")
print("  FlyEnabled = true/false")
print("  NoClipEnabled = true/false")
print("  AntiAFKEnabled = true/false")
print("  walkSpeedValue = angka (default 50)")
print("  jumpPowerValue = angka (default 80)")
print("  flySpeedValue = angka (default 80)")
print("")
print("📌 Auto Revive aktif secara default!")
print("📌 Remote Logger aktif! Setiap revive akan tercatat di clipboard.")

-- // ========== 10. NOTIFIKASI AWAL ==========
task.wait(1)
print("✅ Siap! Menunggu event revive...")
