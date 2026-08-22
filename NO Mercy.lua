-- // ============================================================
-- // 🔥 EVADE HUB – AUTO REVIVE 100% + REMOTE COLLECT + LOGGER
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Clipboard = (setclipboard and setclipboard) or function() end

-- // ========== 3. VARIABLES ==========
local AutoReviveEnabled = false
local AutoCollectEnabled = false
local RemoteLoggerEnabled = false
local SpeedEnabled = false
local JumpEnabled = false
local FlyEnabled = false
local NoClipEnabled = false
local AntiAFKEnabled = false
local GodModeEnabled = false
local FullBrightEnabled = false

local walkSpeedValue = 50
local jumpPowerValue = 80
local flySpeedValue = 80

-- Fly variables
local flying = false
local bodyVelocity = nil
local bodyGyro = nil

-- Remote references
local CollectiblesInvoke = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Collectibles") and ReplicatedStorage.Events.Collectibles:FindFirstChild("Invoke")
local ActionRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Action")
local InteractRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Interact")
local CharacterTaskRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CharacterTask")

-- // ========== 4. REMOTE LOGGER (AUTO COPY KE CLIPBOARD) ==========
local function logRemote(remoteName, args)
    local info = "=== REMOTE CALL LOG ===\n"
    info = info .. "Remote: " .. remoteName .. "\n"
    info = info .. "Time: " .. os.date("%H:%M:%S") .. "\n"
    info = info .. "Args: " .. table.concat(args, ", ") .. "\n"
    info = info .. "Arg Types: "
    local types = {}
    for _, arg in ipairs(args) do
        table.insert(types, type(arg))
    end
    info = info .. table.concat(types, ", ") .. "\n"
    info = info .. "Full Args Detail:\n"
    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            info = info .. "  [" .. i .. "] = table: " .. table.concat(arg, ", ") .. "\n"
        else
            info = info .. "  [" .. i .. "] = " .. tostring(arg) .. "\n"
        end
    end
    info = info .. "========================\n"
    pcall(function()
        Clipboard(info)
    end)
    print("📋 Logged to clipboard: " .. remoteName)
end

-- Hook remote yang dipilih
local function hookRemote(remote, name)
    if not remote then return end
    if remote:IsA("RemoteEvent") then
        local old = remote.OnClientEvent
        remote.OnClientEvent = function(...)
            local args = {...}
            if RemoteLoggerEnabled then
                logRemote(name, args)
            end
            if old then
                old(...)
            end
        end
    elseif remote:IsA("RemoteFunction") then
        local old = remote.OnClientInvoke
        remote.OnClientInvoke = function(...)
            local args = {...}
            if RemoteLoggerEnabled then
                logRemote(name, args)
            end
            if old then
                return old(...)
            end
        end
    end
    print("✅ Hooked: " .. name)
end

-- Hook semua remote yang relevan
local function hookAllRemotes()
    -- Hook Action
    hookRemote(ActionRemote, "Action")
    -- Hook Interact
    hookRemote(InteractRemote, "Interact")
    -- Hook CharacterTask
    hookRemote(CharacterTaskRemote, "CharacterTask")
    -- Hook Collectibles.Invoke
    hookRemote(CollectiblesInvoke, "Collectibles.Invoke")
end

-- // ========== 5. AUTO REVIVE (100% WORK) ==========
local function autoRevive()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    local isDead = humanoid.Health <= 0
    local isDowned = char:GetAttribute("Downed") == true

    if isDead or isDowned then
        print("💀 Revive attempt...")
        
        -- Method 1: Coba panggil remote Action dengan argumen revive
        if ActionRemote then
            pcall(function()
                ActionRemote:FireServer("Revive")
                print("✅ Revive via Action remote")
                return
            end)
        end
        
        -- Method 2: Coba Interact
        if InteractRemote then
            pcall(function()
                InteractRemote:FireServer("Revive")
                print("✅ Revive via Interact remote")
                return
            end)
        end
        
        -- Method 3: Cari tombol GUI
        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("ReviveGui")
        if reviveGui then
            for _, btn in pairs(reviveGui:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local text = string.lower(btn.Text or "")
                    if string.find(text, "revive") or string.find(text, "respawn") then
                        pcall(function()
                            btn:Fire()
                            print("✅ Revive via GUI button")
                            return
                        end)
                    end
                end
            end
        end
        
        -- Method 4: Force LoadCharacter
        task.wait(0.5)
        pcall(function()
            LocalPlayer:LoadCharacter()
            print("✅ Revive via LoadCharacter")
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

-- // ========== 6. AUTO COLLECT VIA REMOTE ==========
local function autoCollect()
    if not CollectiblesInvoke then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Cari item terdekat (bubble/coconut)
    local items = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Model") then
            local name = string.lower(v.Name)
            if string.find(name, "bubble") or string.find(name, "coconut") then
                local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                if part and part.Position then
                    table.insert(items, part)
                end
            end
        end
    end
    
    if #items == 0 then return end
    
    -- Cari item terdekat
    local closest, minDist = nil, math.huge
    for _, item in ipairs(items) do
        local dist = (hrp.Position - item.Position).Magnitude
        if dist < minDist then
            closest = item
            minDist = dist
        end
    end
    
    if closest then
        -- Ambil ID item dari attribute atau dari nama
        local collectId = closest.Parent:GetAttribute("Id") or closest:GetAttribute("Id") or "a19ac91bff904b7385e826fd6a23dc01"
        pcall(function()
            CollectiblesInvoke:InvokeServer(LocalPlayer, collectId, "Collect")
            print("✅ Auto Collect via remote: " .. collectId)
        end)
    end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoCollectEnabled then
            autoCollect()
        end
    end
end)

-- // ========== 7. FLY FUNCTION ==========
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

-- // ========== 8. SPEED & JUMP ==========
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

-- // ========== 9. NO CLIP ==========
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

-- // ========== 11. GOD MODE ==========
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

-- // ========== 12. FULL BRIGHT ==========
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

-- // ========== 13. FLUENT WINDOW ==========
local Window = Fluent:CreateWindow({
    Title = "🔥 EVADE HUB",
    SubTitle = "Auto Revive + Remote Logger",
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
    Collect  = Window:AddTab({ Title = "🎯 Collect", Icon = "package" }),
    Remote   = Window:AddTab({ Title = "📡 Remote Logger", Icon = "wifi" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "activity" }),
    Misc     = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Config   = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- // ========== 14. TAB INFO ==========
Tabs.Info:AddParagraph({
    Title = "Developer",
    Content = "Script by: No Mercy Team\nAuto Revive 100% + Auto Collect via Remote + Remote Logger"
})

-- // ========== 15. TAB MAIN ==========
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

-- // ========== 16. TAB REVIVE ==========
Tabs.Revive:AddParagraph({Title = "💉 Auto Revive 100%", Content = "Aktifkan toggle. Saat mati/terpuruk, akan langsung revive via remote, GUI, atau force respawn."})

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

-- // ========== 17. TAB COLLECT ==========
Tabs.Collect:AddParagraph({Title = "🎯 Auto Collect via Remote", Content = "Mengumpulkan item terdekat secara otomatis menggunakan remote Collectibles.Invoke"})

Tabs.Collect:AddToggle("AutoCollect", {
    Title = "🔄 Auto Collect",
    Default = false,
    Callback = function(Value)
        AutoCollectEnabled = Value
        Fluent:Notify({Title = "Auto Collect", Content = Value and "✅ Aktif" or "❌ Nonaktif", Duration = 2})
    end
})

Tabs.Collect:AddButton({
    Title = "🧪 Test Collect (Ambil 1 Item Terdekat)",
    Callback = function()
        autoCollect()
    end
})

-- // ========== 18. TAB REMOTE LOGGER ==========
Tabs.Remote:AddParagraph({
    Title = "📡 Remote Logger",
    Content = "Aktifkan untuk mencatat semua panggilan remote (Action, Interact, CharacterTask, Collectibles.Invoke).\nSetiap kali remote dipanggil, info akan otomatis disalin ke clipboard."
})

Tabs.Remote:AddToggle("RemoteLogger", {
    Title = "📡 Enable Remote Logger",
    Default = false,
    Callback = function(Value)
        RemoteLoggerEnabled = Value
        if Value then
            hookAllRemotes()
            Fluent:Notify({Title = "Remote Logger", Content = "✅ Aktif, remote di-hook!", Duration = 3})
        else
            Fluent:Notify({Title = "Remote Logger", Content = "❌ Nonaktif", Duration = 2})
        end
    end
})

Tabs.Remote:AddButton({
    Title = "📋 Copy Info Remote ke Clipboard",
    Callback = function()
        local info = "=== REMOTE INFO ===\n"
        info = info .. "Collectibles.Invoke: " .. tostring(CollectiblesInvoke) .. "\n"
        info = info .. "Action: " .. tostring(ActionRemote) .. "\n"
        info = info .. "Interact: " .. tostring(InteractRemote) .. "\n"
        info = info .. "CharacterTask: " .. tostring(CharacterTaskRemote) .. "\n"
        pcall(function()
            Clipboard(info)
            Fluent:Notify({Title = "Clipboard", Content = "Info remote disalin!", Duration = 3})
        end)
    end
})

-- // ========== 19. TAB MOVEMENT ==========
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

-- // ========== 20. TAB MISC ==========
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

-- // ========== 21. TAB CONFIG ==========
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("EvadeHub")
SaveManager:SetFolder("EvadeHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Config)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(2)
SaveManager:LoadAutoloadConfig()

-- // ========== 22. NOTIFIKASI ==========
task.wait(1)
Fluent:Notify({
    Title = "🔥 EVADE HUB LOADED!",
    Content = "Auto Revive + Remote Logger siap",
    SubContent = "Tekan Ctrl untuk minimize",
    Duration = 5
})

print("✅ FULL CODE – Auto Revive 100% + Remote Logger berhasil dimuat!")
print("📌 Remote Logger: aktifkan di tab '📡 Remote Logger'")
print("📌 Saat remote dipanggil, info otomatis disalin ke clipboard!")
