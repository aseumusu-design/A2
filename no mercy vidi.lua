-- =========================================================================
-- AUTO HEAL + "CURI HEAL" DARI PLAYER LAIN (VIOLENCE DISTRICT)
-- =========================================================================
-- Cara kerja:
-- 1. Cari player terdekat (selain diri sendiri) yang masih hidup.
-- 2. Kirim remote heal dengan argumen player tersebut.
-- 3. Player lain tetap di tempatnya, tidak bergerak.
-- 4. Jika berhasil, HP kamu bertambah.
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui") or CoreGui

-- ==================== AUTO DETECT HEAL REMOTE ====================
local function findHealRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end

    -- Daftar kemungkinan path remote heal (yang mungkin menerima argumen player)
    local possiblePaths = {
        {"Healing", "HealAnimRec"},
        {"Healing", "Heal"},
        {"Heal"},
        {"HealPlayer"},
        {"Healing", "StartHeal"},
        {"Heal", "HealPlayer"},
        {"HealRemote"},
        {"RemoteHeal"},
        {"HealEvent"},
        {"HealOther"},
        {"HealTarget"},
        {"HealPlayerRemote"},
        {"Medic", "Heal"},
        {"Medic", "HealPlayer"},
        {"Health", "Heal"},
        {"Health", "HealOther"},
    }

    for _, path in ipairs(possiblePaths) do
        local current = remotes
        local found = true
        for _, key in ipairs(path) do
            current = current:FindFirstChild(key)
            if not current then
                found = false
                break
            end
        end
        if found and current then
            return current
        end
    end

    -- Fallback: cari remote dengan nama mengandung "heal"
    local function recursiveSearch(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                if name:find("heal") or name:find("health") or name:find("regen") or name:find("medic") then
                    return child
                end
            end
            local found = recursiveSearch(child)
            if found then return found end
        end
        return nil
    end

    return recursiveSearch(ReplicatedStorage)
end

local healRemote = findHealRemote()
local healRemoteName = healRemote and healRemote.Name or "Tidak ditemukan"

print("🔍 Remote heal ditemukan: " .. healRemoteName)

-- ==================== KONFIGURASI ====================
local Config = {
    Cooldown = 5,
    HealDuration = 2.5,
    AutoHeal = true,
    HealThreshold = 0.30,
    TargetMode = "Nearest", -- "Nearest" atau "Selected"
    SelectedTarget = nil,
}

local isHealing = false
local lastHealTime = 0
local healProgress = 0
local isAutoHealEnabled = true

-- ==================== CARI PLAYER TERDEKAT ====================
local function getNearestPlayer()
    if not player.Character then return nil end
    local myPos = player.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end

    local nearest, nearestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myPos.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

-- ==================== FUNGSI HEAL (CURI HEAL DARI PLAYER LAIN) ====================
local function heal()
    if isHealing then
        notify("⏳ Sedang healing...", Color3.fromRGB(255,200,0))
        return
    end

    local now = tick()
    if now - lastHealTime < Config.Cooldown then
        local remaining = math.ceil(Config.Cooldown - (now - lastHealTime))
        notify("⏳ Cooldown " .. remaining .. "s", Color3.fromRGB(255,200,0))
        return
    end

    -- Tentukan target
    local targetPlayer = Config.SelectedTarget or getNearestPlayer()
    if not targetPlayer then
        notify("❌ Tidak ada player lain!", Color3.fromRGB(255,0,0))
        return
    end

    if not healRemote then
        notify("❌ Remote heal tidak ditemukan!", Color3.fromRGB(255,0,0))
        return
    end

    isHealing = true
    healProgress = 0

    -- === KIRIM HEAL DENGAN ARGUMEN PLAYER LAIN ===
    local success = false
    local targetChar = targetPlayer.Character

    pcall(function()
        -- Coba berbagai format argument
        if healRemote.FireServer then
            -- Kirim dengan target player atau karakter
            healRemote:FireServer(targetPlayer)     -- player object
            -- atau healRemote:FireServer(targetChar) -- character
            success = true
        elseif healRemote.OnClientEvent then
            firesignal(healRemote.OnClientEvent, targetPlayer)
            success = true
        elseif healRemote.InvokeServer then
            healRemote:InvokeServer(targetPlayer)
            success = true
        end
    end)

    -- Jika gagal, coba argumen lain (karakter)
    if not success then
        pcall(function()
            if healRemote.FireServer then
                healRemote:FireServer(targetChar)
                success = true
            end
        end)
    end

    if success then
        notify("💚 Heal dari " .. targetPlayer.Name .. "!", Color3.fromRGB(50,255,100))
    else
        notify("⚠️ Gagal mengirim heal remote!", Color3.fromRGB(255,200,0))
    end

    -- Progress bar (simulasi)
    local startTime = tick()
    while tick() - startTime < Config.HealDuration and isHealing do
        healProgress = (tick() - startTime) / Config.HealDuration
        updateProgressBar()
        task.wait()
    end

    healProgress = 1
    updateProgressBar()

    isHealing = false
    lastHealTime = tick()
    notify("✅ Heal selesai!", Color3.fromRGB(0,255,100))
end

-- ==================== NOTIFIKASI ====================
local function notify(text, color)
    color = color or Color3.fromRGB(255,255,255)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Heal",
            Text = text,
            Duration = 3,
        })
    end)
end

-- ==================== UI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoHealGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 260, 0, 150)
container.Position = UDim2.new(0.5, -130, 0.82, 0)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
container.BackgroundTransparency = 0.15
container.BorderSizePixel = 0
container.Parent = screenGui
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)

-- Tombol HEAL
local healBtn = Instance.new("TextButton", container)
healBtn.Size = UDim2.new(0.8, 0, 0, 40)
healBtn.Position = UDim2.new(0.1, 0, 0.05, 0)
healBtn.BackgroundColor3 = Color3.fromRGB(35, 200, 90)
healBtn.Text = "❤️ HEAL (Curi)"
healBtn.TextColor3 = Color3.fromRGB(255,255,255)
healBtn.TextSize = 16
healBtn.Font = Enum.Font.GothamBold
healBtn.BorderSizePixel = 0
Instance.new("UICorner", healBtn).CornerRadius = UDim.new(0, 8)

-- Progress bar
local progressBg = Instance.new("Frame", container)
progressBg.Size = UDim2.new(0.8, 0, 0, 8)
progressBg.Position = UDim2.new(0.1, 0, 0.45, 0)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
progressBg.BorderSizePixel = 0
Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 4)

local progressFill = Instance.new("Frame", progressBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
progressFill.BorderSizePixel = 0
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 4)

-- Status label
local statusLabel = Instance.new("TextLabel", container)
statusLabel.Size = UDim2.new(0.8, 0, 0, 18)
statusLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Siap heal (curi dari player lain)"
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Cooldown label
local cdLabel = Instance.new("TextLabel", container)
cdLabel.Size = UDim2.new(0.8, 0, 0, 16)
cdLabel.Position = UDim2.new(0.1, 0, 0.6, 0)
cdLabel.BackgroundTransparency = 1
cdLabel.Text = ""
cdLabel.TextColor3 = Color3.fromRGB(255,200,0)
cdLabel.TextSize = 11
cdLabel.Font = Enum.Font.Gotham
cdLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Target info
local targetLabel = Instance.new("TextLabel", container)
targetLabel.Size = UDim2.new(0.8, 0, 0, 16)
targetLabel.Position = UDim2.new(0.1, 0, 0.75, 0)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target: Nearest"
targetLabel.TextColor3 = Color3.fromRGB(150,150,200)
targetLabel.TextSize = 10
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Toggle Auto Heal
local autoBtn = Instance.new("TextButton", container)
autoBtn.Size = UDim2.new(0.3, 0, 0, 20)
autoBtn.Position = UDim2.new(0.05, 0, 0.88, 0)
autoBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
autoBtn.Text = "Auto: ON"
autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoBtn.TextSize = 10
autoBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 4)

autoBtn.MouseButton1Click:Connect(function()
    isAutoHealEnabled = not isAutoHealEnabled
    autoBtn.Text = isAutoHealEnabled and "Auto: ON" or "Auto: OFF"
    autoBtn.BackgroundColor3 = isAutoHealEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

-- Tombol target mode
local targetBtn = Instance.new("TextButton", container)
targetBtn.Size = UDim2.new(0.3, 0, 0, 20)
targetBtn.Position = UDim2.new(0.65, 0, 0.88, 0)
targetBtn.BackgroundColor3 = Color3.fromRGB(60,60,80)
targetBtn.Text = "Nearest"
targetBtn.TextColor3 = Color3.fromRGB(255,255,255)
targetBtn.TextSize = 10
targetBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", targetBtn).CornerRadius = UDim.new(0, 4)

local modes = {"Nearest", "Selected"}
targetBtn.MouseButton1Click:Connect(function()
    local idx = table.find(modes, Config.TargetMode) or 1
    idx = idx % #modes + 1
    Config.TargetMode = modes[idx]
    targetBtn.Text = Config.TargetMode
    targetLabel.Text = "Target: " .. Config.TargetMode
    if Config.TargetMode == "Selected" then
        notify("Pilih player dari daftar (klik nama)", Color3.fromRGB(255,200,0))
    end
end)

-- ==================== PLAYER LIST (untuk pilih target manual) ====================
local listFrame = Instance.new("Frame", container)
listFrame.Size = UDim2.new(0.8, 0, 0, 60)
listFrame.Position = UDim2.new(0.1, 0, 0.62, 0)
listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
listFrame.BorderSizePixel = 0
listFrame.Visible = false
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)

local scrollList = Instance.new("ScrollingFrame", listFrame)
scrollList.Size = UDim2.new(1, 0, 1, 0)
scrollList.BackgroundTransparency = 1
scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollList.ScrollBarThickness = 3

local layout = Instance.new("UIListLayout", scrollList)
layout.SortOrder = Enum.SortOrder.Name
layout.Padding = UDim.new(0, 2)

local function updatePlayerList()
    for _, child in ipairs(scrollList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton", scrollList)
            btn.Size = UDim2.new(1, -5, 0, 20)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(220,220,220)
            btn.TextSize = 10
            btn.Font = Enum.Font.Gotham
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

            btn.MouseButton1Click:Connect(function()
                Config.SelectedTarget = plr
                targetLabel.Text = "Target: " .. plr.Name
                listFrame.Visible = false
                notify("✅ Target: " .. plr.Name, Color3.fromRGB(0,255,100))
            end)
        end
    end

    local count = #Players:GetPlayers() - 1
    scrollList.CanvasSize = UDim2.new(0, 0, 0, math.max(count * 22, 60))
end

task.spawn(function()
    while true do
        task.wait(2)
        if Config.TargetMode == "Selected" and listFrame.Visible then
            updatePlayerList()
        end
    end
end)

-- ==================== UPDATE PROGRESS BAR ====================
local function updateProgressBar()
    local width = math.clamp(healProgress * 100, 0, 100)
    progressFill.Size = UDim2.new(width / 100, 0, 1, 0)
    statusLabel.Text = isHealing and "Healing... " .. math.floor(healProgress * 100) .. "%" or "Siap heal"
    progressFill.BackgroundColor3 = healProgress >= 1 and Color3.fromRGB(50, 255, 100) or Color3.fromRGB(255, 200, 50)
end

-- ==================== UPDATE COOLDOWN ====================
task.spawn(function()
    while true do
        task.wait(0.3)
        if not isHealing then
            local now = tick()
            local remaining = Config.Cooldown - (now - lastHealTime)
            cdLabel.Text = remaining > 0 and "⏳ " .. math.ceil(remaining) .. "s" or "✅ Siap"
        else
            cdLabel.Text = "⏳ Healing..."
        end
    end
end)

-- ==================== AUTO HEAL LOOP ====================
RunService.Heartbeat:Connect(function()
    if not isAutoHealEnabled then return end
    if isHealing then return end
    if not player.Character then return end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = health / maxHealth

    if healthPercent <= Config.HealThreshold and health > 0 then
        heal()
    end
end)

-- ==================== EVENT ====================
healBtn.MouseButton1Click:Connect(function()
    if Config.TargetMode == "Selected" and not Config.SelectedTarget then
        listFrame.Visible = not listFrame.Visible
        if listFrame.Visible then updatePlayerList() end
        return
    end
    heal()
end)

-- Klik kanan untuk toggle list (jika mode Selected)
healBtn.MouseButton2Click:Connect(function()
    if Config.TargetMode == "Selected" then
        listFrame.Visible = not listFrame.Visible
        if listFrame.Visible then updatePlayerList() end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.H then
        heal()
    end
end)

-- ==================== INISIALISASI ====================
updateProgressBar()
notify("🩹 Auto Heal siap! Tekan H atau klik HEAL.", Color3.fromRGB(0,255,100))
print("✅ Auto Heal (Curi Heal) loaded!")
print("   Remote heal ditemukan: " .. healRemoteName)
