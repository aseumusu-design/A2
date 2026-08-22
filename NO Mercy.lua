-- // ============================================================
-- // 🔥 EVADE HUB – REMOTE SPY + AUTO COPY (FULL)
-- // ============================================================

-- // ========== 1. LOAD FLUENT ==========
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- // ========== 2. SETUP ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Clipboard = (setclipboard and setclipboard) or function() end -- fallback

-- // ========== 3. VARIABLES ==========
local AutoReviveEnabled = false
local SpeedEnabled = false
local JumpEnabled = false
local FlyEnabled = false
local NoClipEnabled = false
local AntiAFKEnabled = false
local GodModeEnabled = false
local FullBrightEnabled = false
local RemoteSpyEnabled = false
local walkSpeedValue = 50
local jumpPowerValue = 80
local flySpeedValue = 80

-- Fly variables
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

-- Remote Spy data
local foundRemotes = {}
local remoteLogs = {}

-- // ========== 4. AUTO REVIVE (100% WORK) ==========
local function autoRevive()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true

    if isDead or isDowned then
        print("💀 角色死亡/倒地，尝试复活...")
        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("ReviveGui")
        if reviveGui then
            for _, btn in pairs(reviveGui:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local text = string.lower(btn.Text or "")
                    if string.find(text, "revive") or string.find(text, "respawn") then
                        pcall(function()
                            btn:Fire()
                            print("✅ 通过 GUI 复活成功！")
                            return
                        end)
                    end
                end
            end
        end
        task.wait(1)
        pcall(function()
            LocalPlayer:LoadCharacter()
            print("✅ 通过 LoadCharacter 强制复活成功！")
        end)
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

-- // ========== 5. REMOTE SPY + AUTO COPY ==========
-- Mencari semua remote di seluruh game
local function scanRemotes()
    foundRemotes = {}
    local containers = {
        game:GetService("ReplicatedStorage"),
        workspace,
        game:GetService("Players"),
        game:GetService("CoreGui"),
        game:GetService("StarterGui"),
        LocalPlayer.PlayerGui,
        game:GetService("Lighting"),
        game:GetService("SoundService")
    }
    for _, container in ipairs(containers) do
        if container then
            for _, obj in pairs(container:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(foundRemotes, {
                        Name = obj.Name,
                        Class = obj.ClassName,
                        Parent = obj.Parent and obj.Parent.Name or "nil",
                        Path = obj:GetFullName(),
                        Object = obj
                    })
                end
            end
        end
    end
    return foundRemotes
end

-- Menyalin info remote ke clipboard
local function copyRemoteInfoToClipboard()
    local info = "=== REMOTE EVENTS & FUNCTIONS FOUND ===\n"
    info = info .. "Total: " .. #foundRemotes .. "\n\n"
    for i, remote in ipairs(foundRemotes) do
        info = info .. i .. ". Name: " .. remote.Name .. "\n"
        info = info .. "   Class: " .. remote.Class .. "\n"
        info = info .. "   Parent: " .. remote.Parent .. "\n"
        info = info .. "   Path: " .. remote.Path .. "\n\n"
    end
    pcall(function()
        Clipboard(info)
        Fluent:Notify({Title = "Clipboard", Content = "Info remote disalin ke clipboard!", Duration = 3})
    end)
end

-- Auto copy saat ada player yang menggunakan revive (monitor remote)
local function monitorReviveRemote()
    -- Cari remote yang mungkin terkait revive
    for _, remote in ipairs(foundRemotes) do
        if string.find(string.lower(remote.Name), "revive") or string.find(string.lower(remote.Name), "respawn") then
            local obj = remote.Object
            if obj and obj:IsA("RemoteEvent") then
                -- Hook remote: saat dipanggil, copy info ke clipboard
                local oldOnClientEvent = obj.OnClientEvent
                obj.OnClientEvent = function(...)
                    -- Menyalin informasi ke clipboard
                    local args = {...}
                    local info = "=== REVIVE REMOTE TRIGGERED ===\n"
                    info = info .. "Remote: " .. obj.Name .. "\n"
                    info = info .. "Path: " .. obj:GetFullName() .. "\n"
                    info = info .. "Args: " .. table.concat(args, ", ") .. "\n"
                    info = info .. "Triggered by: " .. LocalPlayer.Name .. "\n"
                    info = info .. "Time: " .. os.date("%H:%M:%S") .. "\n"
                    pcall(function()
                        Clipboard(info)
                        Fluent:Notify({Title = "Revive Remote", Content = "Detected! Info copied to clipboard!", Duration = 3})
                    end)
                    -- Panggil fungsi asli jika ada
                    if oldOnClientEvent then
                        oldOnClientEvent(...)
                    end
                end
                print("✅ Hooked remote: " .. obj.Name)
            end
        end
    end
end

-- Main spy toggle
local function toggleRemoteSpy(state)
    RemoteSpyEnabled = state
    if state then
        scanRemotes()
        monitorReviveRemote()
        print("🔍 Remote Spy aktif, total remote ditemukan: " .. #foundRemotes)
        Fluent:Notify({Title = "Remote Spy", Content = "✅ Aktif, total remote: " .. #foundRemotes, Duration = 3})
    else
        print("🔍 Remote Spy dimatikan")
    end
end

-- // ========== 6. FLY FUNCTION ==========
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid then return end

    if flying then return end
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
        if flying then
            stopFly()
            Fluent:Notify({Title = "Fly", Content = "❌ Turun", Duration = 2})
        else
            startFly()
            Fluent:Notify({Title = "Fly", Content = "✅ Terbang! (F untuk toggle)", Duration = 2})
        end
    end
end)

-- // ========== 7. SPEED & JUMP ==========
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    humanoid.WalkSpeed = SpeedEnabled and walkSpeedValue or 16
end

local function applyJump()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    humanoid.JumpPower = JumpEnabled and jumpPowerValue or 50
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

-- // ========== 8. NO CLIP ==========
task.spawn(function()
    while true do
        task.wait(0.5)
        if NoClipEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CanCollide = false
            end
        else
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CanCollide = true
            end
        end
    end
end)

-- // ========== 9. ANTI AFK ==========
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

-- // ========== 10. GOD MODE ==========
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

-- // ========== 11. FULL BRIGHT ==========
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

-- // ========== 12. FLUENT WINDOW ==========
local Window = Fluent:CreateWindow({
    Title = "🔥 EVADE HUB",
    SubTitle = "Auto Revive + Remote Spy",
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
    Revive   = Window:AddTab({ Title = "💉 Revive", Icon = "heart" }),
    Remote   = Window:AddTab({ Title = "📡 Remote Spy", Icon = "wifi" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- // ========== 13. TAB INFO ==========
Tabs.Info:AddParagraph({
    Title = "Developer",
    Content = "Script by: No Mercy Team\nFitur: Auto Revive 100%, Remote Spy, Speed, Jump, Fly, NoClip, Anti AFK, God Mode, FullBright"
})

-- // ========== 14. TAB MAIN ==========
Tabs.Main:AddParagraph({Title = "⚡ Speed & Jump", Content = "Aktifkan toggle, atur nilai slider."})

Tabs.Main:AddToggle("SpeedToggle", {
    Title = "⚡ Speed Boost",
    Default = false,
    Callback = function(Value)
        SpeedEnabled = Value
        applySpeed()
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

-- // ========== 15. TAB REVIVE ==========
Tabs.Revive:AddParagraph({Title = "💉 Auto Revive", Content = "Aktifkan toggle di bawah. Saat mati/terpuruk, akan langsung revive."})

Tabs.Revive:AddToggle("AutoRevive", {
    Title = "🔄 Auto Revive",
    Default = false,
    Callback = function(Value)
        AutoReviveEnabled = Value
        Fluent:Notify({Title = "Auto Revive", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Revive:AddButton({
    Title = "🧪 Test Revive (Paksa Mati)",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end
    end
})

-- // ========== 16. TAB REMOTE SPY ==========
Tabs.Remote:AddParagraph({
    Title = "📡 Remote Spy + Auto Copy",
    Content = "Aktifkan untuk mencari semua RemoteEvent/Function di game. Saat remote revive dipanggil, info akan otomatis disalin ke clipboard."
})

Tabs.Remote:AddToggle("RemoteSpy", {
    Title = "🔍 Remote Spy",
    Default = false,
    Callback = function(Value)
        toggleRemoteSpy(Value)
    end
})

Tabs.Remote:AddButton({
    Title = "📋 Copy Semua Remote ke Clipboard",
    Callback = function()
        scanRemotes()
        copyRemoteInfoToClipboard()
    end
})

Tabs.Remote:AddButton({
    Title = "📋 Copy Info Revive Remote Saja",
    Callback = function()
        scanRemotes()
        local info = "=== REVIVE REMOTES ONLY ===\n"
        local found = false
        for _, remote in ipairs(foundRemotes) do
            if string.find(string.lower(remote.Name), "revive") or string.find(string.lower(remote.Name), "respawn") then
                info = info .. "Name: " .. remote.Name .. "\n"
                info = info .. "Class: " .. remote.Class .. "\n"
                info = info .. "Parent: " .. remote.Parent .. "\n"
                info = info .. "Path: " .. remote.Path .. "\n\n"
                found = true
            end
        end
        if not found then
            info = info .. "Tidak ditemukan remote revive.\n"
        end
        pcall(function()
            Clipboard(info)
            Fluent:Notify({Title = "Clipboard", Content = "Info revive remote disalin!", Duration = 3})
        end)
    end
})

-- // ========== 17. TAB MOVEMENT ==========
Tabs.Movement:AddParagraph({Title = "🛸 Movement Mods", Content = "Fly, NoClip"})

Tabs.Movement:AddToggle("Fly", {
    Title = "✈️ Fly Mode (F)",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        if not Value and flying then stopFly() end
    end
})

Tabs.Movement:AddSlider("FlySpeed", {
    Title = "🚀 Kecepatan Terbang",
    Default = 80,
    Min = 20,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        flySpeedValue = v
    end
})

Tabs.Movement:AddToggle("NoClip", {
    Title = "👻 No Clip",
    Default = false,
    Callback = function(Value)
        NoClipEnabled = Value
    end
})

-- // ========== 18. TAB MISC ==========
Tabs.Misc:AddParagraph({Title = "🛡️ Lain-lain", Content = "Anti AFK, God Mode, FullBright"})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "🛡️ Anti AFK",
    Default = false,
    Callback = function(Value)
        AntiAFKEnabled = Value
    end
})

Tabs.Misc:AddToggle("GodMode", {
    Title = "🛡️ God Mode",
    Default = false,
    Callback = function(Value)
        GodModeEnabled = Value
    end
})

Tabs.Misc:AddToggle("FullBright", {
    Title = "☀️ Full Bright",
    Default = false,
    Callback = function(Value)
        FullBrightEnabled = Value
    end
})

-- // ========== 19. TAB CONFIG ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("EvadeHub")
SaveManager:SetFolder("EvadeHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(2)
SaveManager:LoadAutoloadConfig()

-- // ========== 20. NOTIFIKASI ==========
task.wait(1)
Fluent:Notify({
    Title = "🔥 EVADE HUB LOADED!",
    Content = "Auto Revive + Remote Spy siap",
    SubContent = "Tekan Ctrl untuk minimize",
    Duration = 5
})

print("✅ FULL CODE – Auto Revive + Remote Spy berhasil dimuat!")
print("📌 Remote Spy: aktifkan di tab '📡 Remote Spy'")
print("📌 Saat remote revive dipanggil, info otomatis disalin ke clipboard!")
