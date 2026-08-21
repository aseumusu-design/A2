-- ============================================================
-- FITUR ESP + TELEPORT GATE (Mentahan dari Violence District)
-- ============================================================

-- ===== 1. SERVICE & VARIABEL GLOBAL =====
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Pengaturan ESP (sesuaikan sesuai kebutuhan)
local Settings = {
    ESP = {
        Killer = false,
        Survivor = false,
        Generator = false,
        Gate = false,
        Hook = false,
        Pallet = false,
        Window = false,
        Pumpkin = false,
        ShowOnlyClosestHook = false,
        ShowDistance = true,
        MaxDistance = 500,
    },
    Performance = {
        UpdateRate = 0.5,
        UseDistanceCulling = true,
        MaxESPObjects = 100,
    },
    Teleportation = {
        TeleportOffset = 3,
        SafeTeleport = true,
    }
}

-- ===== 2. FUNGSI UTIL =====
local function IsValid(obj)
    return obj and (typeof(obj) == "Instance") and (obj.Parent ~= nil)
end

local function SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    return ok and result or nil
end

local function GetRoot()
    if not LocalPlayer.Character then return nil end
    return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- ===== 3. FUNGSI TELEPORT =====
local function Teleport(position, offset)
    local root = GetRoot()
    if not root then return false end
    offset = offset or Vector3.new(0, Settings.Teleportation.TeleportOffset, 0)
    if Settings.Teleportation.SafeTeleport then
        SafeCall(function()
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    root.CFrame = position + offset
    if Settings.Teleportation.SafeTeleport then
        task.delay(0.5, function()
            SafeCall(function()
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end)
        end)
    end
    return true
end

-- ===== 4. FUNGSI ESP DASAR =====
local ESPHighlights = {}
local ESPLabels = {}

local function HighlightObj(obj, color)
    if not IsValid(obj) then return end
    if obj:FindFirstChild("H") then return end
    SafeCall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "H"
        highlight.Adornee = obj
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = obj
        ESPHighlights[obj] = highlight
    end)
end

local function Unhighlight(obj)
    if ESPHighlights[obj] then
        SafeCall(function()
            if IsValid(ESPHighlights[obj]) then ESPHighlights[obj]:Destroy() end
        end)
        ESPHighlights[obj] = nil
    end
    local h = obj:FindFirstChild("H")
    if h then h:Destroy() end
end

local function LabelObj(obj, name, color)
    if not IsValid(obj) then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local anchorPart = (obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj) or nil
    if not anchorPart then return end
    local root = LocalPlayer.Character.HumanoidRootPart
    local distance = (root.Position - anchorPart.Position).Magnitude

    if Settings.Performance.UseDistanceCulling and (distance > Settings.ESP.MaxDistance) then
        if ESPLabels[obj] then
            SafeCall(function() if IsValid(ESPLabels[obj]) then ESPLabels[obj]:Destroy() end end)
            ESPLabels[obj] = nil
        end
        return
    end

    if ESPLabels[obj] and IsValid(ESPLabels[obj]) then
        local existing = ESPLabels[obj]:FindFirstChild("TextLabel")
        if existing and Settings.ESP.ShowDistance then
            existing.Text = string.format("%s\n%.0fm", name, distance)
        elseif existing then
            existing.Text = name
        end
        return
    end

    SafeCall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = anchorPart
        billboard.Parent = obj

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Text = (Settings.ESP.ShowDistance and string.format("%s\n%.0fm", name, distance)) or name
        label.Parent = billboard

        ESPLabels[obj] = billboard
    end)
end

local function Unlabel(obj)
    if ESPLabels[obj] then
        SafeCall(function()
            if IsValid(ESPLabels[obj]) then ESPLabels[obj]:Destroy() end
        end)
        ESPLabels[obj] = nil
    end
end

local function ClearESP()
    for obj in pairs(ESPHighlights) do Unhighlight(obj) end
    for obj in pairs(ESPLabels) do Unlabel(obj) end
    ESPHighlights = {}
    ESPLabels = {}
end

-- ===== 5. FUNGSI ESP PER JENIS =====
local function ESPPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team then
            local teamName = player.Team.Name
            if teamName == "Killer" and Settings.ESP.Killer then
                HighlightObj(player.Character, Color3.fromRGB(255, 0, 0))
                LabelObj(player.Character, player.Name .. "\n[KILLER]", Color3.fromRGB(255, 0, 0))
            elseif teamName == "Survivors" and Settings.ESP.Survivor then
                HighlightObj(player.Character, Color3.fromRGB(0, 255, 0))
                LabelObj(player.Character, player.Name .. "\n[SURVIVOR]", Color3.fromRGB(0, 255, 0))
            else
                Unhighlight(player.Character)
                Unlabel(player.Character)
            end
        end
    end
end

local function ESPGenerators()
    if not Settings.ESP.Generator then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                HighlightObj(obj, Color3.fromRGB(203, 132, 66))
                LabelObj(obj, "Generator", Color3.fromRGB(203, 132, 66))
            end
        end
    end)
end

local function ESPGates()
    if not Settings.ESP.Gate then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Gate" then
                HighlightObj(obj, Color3.fromRGB(255, 255, 255))
                LabelObj(obj, "Gate", Color3.fromRGB(255, 255, 255))
            end
        end
    end)
end

local function ESPHooks()
    if not Settings.ESP.Hook then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        if Settings.ESP.ShowOnlyClosestHook then
            local root = GetRoot()
            if not root then return end
            local nearest, nearestDist = nil, math.huge
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = obj
                        end
                    end
                end
            end
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    Unhighlight(obj)
                    Unlabel(obj)
                end
            end
            if nearest then
                if nearest:FindFirstChild("Model") then
                    for _, part in ipairs(nearest.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then HighlightObj(part, Color3.fromRGB(255, 255, 0)) end
                    end
                end
                LabelObj(nearest, "CLOSEST HOOK", Color3.fromRGB(255, 255, 0))
            end
        else
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    if obj:FindFirstChild("Model") then
                        for _, part in ipairs(obj.Model:GetDescendants()) do
                            if part:IsA("MeshPart") then HighlightObj(part, Color3.fromRGB(255, 0, 0)) end
                        end
                    end
                    LabelObj(obj, "Hook", Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end)
end

local function ESPPallets()
    if not Settings.ESP.Pallet then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Palletwrong" then
                HighlightObj(obj, Color3.fromRGB(255, 255, 0))
                LabelObj(obj, "Pallet", Color3.fromRGB(255, 255, 0))
            end
        end
    end)
end

local function ESPWindows()
    if not Settings.ESP.Window then return end
    SafeCall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Window" then
                HighlightObj(obj, Color3.fromRGB(173, 216, 230))
                LabelObj(obj, "Window", Color3.fromRGB(173, 216, 230))
            end
        end
    end)
end

local function ESPPumpkins()
    if not Settings.ESP.Pumpkin then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        local pumpkins = map:FindFirstChild("Pumpkins")
        if not pumpkins then return end
        for _, obj in ipairs(pumpkins:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Pumpkin") then
                HighlightObj(obj, Color3.fromRGB(255, 140, 0))
                LabelObj(obj, "Pumpkin", Color3.fromRGB(255, 140, 0))
            end
        end
    end)
end

-- ===== 6. LOOP ESP UTAMA =====
local lastUpdate = 0
local espLoopConn = nil

local function ESPTick()
    local now = tick()
    if (now - lastUpdate) < Settings.Performance.UpdateRate then return end
    lastUpdate = now

    -- Bersihkan referensi mati
    for obj in pairs(ESPHighlights) do
        if not IsValid(obj) or not IsValid(ESPHighlights[obj]) then ESPHighlights[obj] = nil end
    end
    for obj in pairs(ESPLabels) do
        if not IsValid(obj) or not IsValid(ESPLabels[obj]) then ESPLabels[obj] = nil end
    end

    local count = 0
    for _ in pairs(ESPHighlights) do count = count + 1 end
    if count >= Settings.Performance.MaxESPObjects then return end

    -- Panggil semua ESP
    ESPPlayers()
    ESPGenerators()
    ESPGates()
    ESPHooks()
    ESPPallets()
    ESPWindows()
    ESPPumpkins()
end

local function EnableESP()
    if espLoopConn then return end
    espLoopConn = RunService.Heartbeat:Connect(ESPTick)
    print("[ESP] Activated")
end

local function DisableESP()
    if espLoopConn then
        espLoopConn:Disconnect()
        espLoopConn = nil
    end
    ClearESP()
    print("[ESP] Deactivated")
end

-- ===== 7. FUNGSI TELEPORT KE GATE TERDEKAT =====
local function TeleportToNearestGate()
    local root = GetRoot()
    if not root then
        print("Character not found")
        return false
    end
    local map = Workspace:FindFirstChild("Map")
    if not map then
        print("Map not found")
        return false
    end
    local nearestPart, nearestDist = nil, math.huge
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - root.Position).Magnitude
                if dist < nearestDist then
                    nearestPart = part
                    nearestDist = dist
                end
            end
        end
    end
    if nearestPart then
        Teleport(nearestPart.CFrame)
        print(string.format("Teleported to nearest gate (%.0f studs)", nearestDist))
        return true
    else
        print("No gate found")
        return false
    end
end

-- ============================================================
-- CONTOH PENGGUNAAN
-- ============================================================
-- Aktifkan ESP (misal untuk semua objek)
Settings.ESP.Killer = true
Settings.ESP.Survivor = true
Settings.ESP.Generator = true
Settings.ESP.Gate = true
Settings.ESP.Hook = true
Settings.ESP.Pallet = true
Settings.ESP.Window = true
Settings.ESP.Pumpkin = true
EnableESP()

-- Teleport ke gate terdekat (panggil kapan saja)
TeleportToNearestGate()

-- Matikan ESP jika diperlukan
-- DisableESP()
