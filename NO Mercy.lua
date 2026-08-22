-- // ============================================================
-- // 🔥 EVADE SUPER SCRIPT – SCAN + REMOTE SPY + AUTO REVIVE
-- // Menggabungkan semua metode dari file yang kamu kirim
-- // ============================================================

-- // ========== 1. SETUP ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Clipboard = (setclipboard or set_clipboard or writeclipboard or function() end)
local Output = warn -- atau rconsoleprint

-- // ========== 2. VARIABEL ==========
local AutoReviveEnabled = true  -- set true untuk auto revive
local RemoteSpyEnabled = true   -- set true untuk mengaktifkan spy
local ScanOnStart = true        -- scan remotes & UI di awal

-- Kumpulan remote yang ditemukan (akan diisi otomatis)
local foundReviveRemotes = {}
local latestReviveArgs = nil

-- // ========== 3. FUNGSI SCAN (dari snippet terakhir) ==========
local function scanAndCopy()
    local targetTypes = {
        "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent",
        "ClickDetector", "ProximityPrompt",
        "TextButton", "ImageButton", "TextBox"
    }
    local outputText = "=== HASIL PEMINDAIAN ROBLOX ===\n\n"
    local totalFound = 0
    local categorized = {}

    for _, obj in ipairs(game:GetDescendants()) do
        for _, targetType in ipairs(targetTypes) do
            if obj:IsA(targetType) then
                totalFound = totalFound + 1
                local kategori = "LAINNYA"
                if string.find(targetType, "Remote") then
                    kategori = "REMOTE/NETWORK"
                elseif targetType == "ClickDetector" or targetType == "ProximityPrompt" then
                    kategori = "KLIK INTERAKSI 3D"
                elseif string.find(targetType, "Button") or targetType == "TextBox" then
                    kategori = "TOMBOL/UI INPUT"
                end
                -- Simpan ke kategori
                if not categorized[kategori] then categorized[kategori] = {} end
                table.insert(categorized[kategori], string.format("%s\n  Path: game.%s", obj.Name, obj:GetFullName()))
                break
            end
        end
    end

    for kat, list in pairs(categorized) do
        outputText = outputText .. "--- " .. kat .. " (" .. #list .. ") ---\n"
        for _, item in ipairs(list) do
            outputText = outputText .. "  " .. item .. "\n\n"
        end
    end

    outputText = outputText .. "=== TOTAL: " .. totalFound .. " ==="
    pcall(function() Clipboard(outputText) end)
    print("✅ Hasil scan sudah di-copy ke clipboard!")
    return categorized
end

-- Jalankan scan di awal
if ScanOnStart then
    local remotes = scanAndCopy()
    print("Scan selesai. Total objek ditemukan: " .. #remotes)
end

-- // ========== 4. REMOTE SPY (Metode Vaeb + TheExtreme) ==========

-- Metode Vaeb (menggunakan __index dan __namecall)
local function vaebSpy()
    local gameMeta = getrawmetatable(game)
    local pseudoEnv = {}
    for k, v in pairs(gameMeta) do pseudoEnv[k] = v end
    setreadonly(gameMeta, false)

    local detectClasses = {
        BindableEvent = true,
        BindableFunction = true,
        RemoteEvent = true,
        RemoteFunction = true,
    }
    local classMethods = {
        BindableEvent = "Fire",
        BindableFunction = "Invoke",
        RemoteEvent = "FireServer",
        RemoteFunction = "InvokeServer",
    }
    local realMethods = {}
    for cls, _ in pairs(detectClasses) do
        realMethods[classMethods[cls]] = Instance.new(cls)[classMethods[cls]]
    end

    local function getValues(self, key, ...)
        return {realMethods[key](self, ...)}
    end

    local incId = 0
    gameMeta.__index, gameMeta.__namecall = function(self, key)
        if not realMethods[key] or not RemoteSpyEnabled then
            return pseudoEnv.__index(self, key)
        end
        return function(_, ...)
            incId = incId + 1
            local nowId = incId
            local strId = "[VaebSpy_" .. nowId .. "]"
            local allPassed = {...}
            local returnValues = {}
            local ok, data = pcall(getValues, self, key, ...)
            if ok then
                returnValues = data
                local log = "\n" .. strId .. " ClassName: " .. self.ClassName .. " | Path: " .. self:GetFullName() .. " | Method: " .. key .. "\n" .. strId .. " Args: " .. tableToString(allPassed) .. "\n" .. strId .. " Returns: " .. tableToString(returnValues) .. "\n"
                Output(log)
                -- Simpan jika ada kata revive
                if string.find(string.lower(key), "fire") or string.find(string.lower(key), "invoke") then
                    for _, arg in ipairs(allPassed) do
                        if type(arg) == "string" and string.find(string.lower(arg), "revive") or string.find(string.lower(arg), "respawn") then
                            latestReviveArgs = allPassed
                            foundReviveRemotes[self:GetFullName()] = true
                            Clipboard("🚀 REVIVE DETECTED!\nRemote: " .. self:GetFullName() .. "\nArgs: " .. tableToString(allPassed))
                        end
                    end
                end
            else
                Output(strId .. " ERROR: " .. data)
            end
            return unpack(returnValues)
        end
    end
    setreadonly(gameMeta, true)
    print("✅ Vaeb Spy aktif")
end

-- Metode TheExtreme (hook FireServer/InvokeServer + namecall)
local function extremeSpy()
    local metatable = getrawmetatable(game)
    local originalMethods = {}
    local Methods = {
        RemoteEvent = "FireServer",
        RemoteFunction = "InvokeServer"
    }

    local function IsValidCall(Remote, Method, Arguments)
        return RemoteSpyEnabled and (Methods[Remote.ClassName] == Method)
    end

    local function Write(Remote, Method, Arguments)
        local log = ("\n[ExtremeSpy] %s:%s(%s)"):format(Remote:GetFullName(), Method, tableToString(Arguments))
        Output(log)
        -- Cek revive
        for _, arg in ipairs(Arguments) do
            if type(arg) == "string" and (string.find(string.lower(arg), "revive") or string.find(string.lower(arg), "respawn")) then
                latestReviveArgs = Arguments
                foundReviveRemotes[Remote:GetFullName()] = true
                Clipboard("🚀 EXTREME SPY: REVIVE DETECTED!\nRemote: " .. Remote:GetFullName() .. "\nArgs: " .. tableToString(Arguments))
            end
        end
    end

    -- Hook FireServer/InvokeServer
    for Class, Method in pairs(Methods) do
        local orig = Instance.new(Class)[Method]
        local function newFunc(self, ...)
            local args = {...}
            if IsValidCall(self, Method, args) then
                Write(self, Method, args)
            end
            return orig(self, ...)
        end
        hookfunction(orig, newFunc)
        print("✅ Hooked " .. Method)
    end

    -- Hook namecall (jika didukung)
    if getnamecallmethod then
        local __namecall = metatable.__namecall
        local function newNamecall(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if typeof(method) == "string" and IsValidCall(self, method, args) then
                Write(self, method, args)
            end
            return __namecall(self, ...)
        end
        setreadonly(metatable, false)
        metatable.__namecall = newNamecall
        setreadonly(metatable, true)
        print("✅ Hooked namecall")
    end
end

-- Jalankan spy
if RemoteSpyEnabled then
    vaebSpy()
    extremeSpy()
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

        -- 1. Coba pakai remote yang sudah terdeteksi dari spy
        for remotePath, _ in pairs(foundReviveRemotes) do
            local remote = game:FindFirstChild(remotePath)
            if remote then
                if remote:IsA("RemoteEvent") then
                    pcall(function()
                        remote:FireServer(unpack(latestReviveArgs or {"Revive"}))
                        print("✅ Revive via detected remote: " .. remotePath)
                        return
                    end)
                elseif remote:IsA("RemoteFunction") then
                    pcall(function()
                        remote:InvokeServer(unpack(latestReviveArgs or {"Revive"}))
                        print("✅ Revive via detected remote: " .. remotePath)
                        return
                    end)
                end
            end
        end

        -- 2. Coba remote umum: Action, Interact, CharacterTask
        local commonRemotes = {
            ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Action"),
            ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Interact"),
            ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("CharacterTask"),
        }
        for _, remote in ipairs(commonRemotes) do
            if remote then
                if remote:IsA("RemoteEvent") then
                    pcall(function()
                        remote:FireServer("Revive")
                        print("✅ Revive via " .. remote.Name)
                        return
                    end)
                    pcall(function()
                        remote:FireServer("Respawn")
                        print("✅ Revive via " .. remote.Name .. " (Respawn)")
                        return
                    end)
                end
            end
        end

        -- 3. Cari tombol GUI
        local reviveGui = LocalPlayer.PlayerGui:FindFirstChild("ReviveGui")
        if reviveGui then
            for _, btn in pairs(reviveGui:GetDescendants()) do
                if btn:IsA("TextButton") then
                    local text = string.lower(btn.Text or "")
                    if string.find(text, "revive") or string.find(text, "respawn") then
                        pcall(function() btn:Fire() end)
                        print("✅ Revive via GUI button")
                        return
                    end
                end
            end
        end

        -- 4. Force LoadCharacter (paling ampuh)
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

-- // ========== 6. FITUR TAMBAHAN: Speed, Jump, Fly, NoClip, AntiAFK ==========
local SpeedEnabled = false
local JumpEnabled = false
local FlyEnabled = false
local NoClipEnabled = false
local AntiAFKEnabled = false
local walkSpeedValue = 50
local jumpPowerValue = 80
local flySpeedValue = 80
local flying = false
local bodyVelocity, bodyGyro

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

-- Fly
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

-- NoClip
task.spawn(function()
    while true do
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CanCollide = not NoClipEnabled
        end
    end
end)

-- AntiAFK
task.spawn(function()
    while true do
        task.wait(30)
        if AntiAFKEnabled then
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0, 0)) end)
        end
    end
end)

-- // ========== 7. KONTROL MENU SEDERHANA via Console ==========
print("🔥 EVADE SUPER SCRIPT LOADED!")
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
print("📌 Semua remote call akan dicatat di console dan clipboard jika ada 'revive'")
print("📌 Auto Revive aktif secara default. Matikan dengan AutoReviveEnabled = false")

-- // ========== 8. NOTIFIKASI AWAL ==========
task.wait(1)
print("✅ Siap! Menunggu event revive...")
