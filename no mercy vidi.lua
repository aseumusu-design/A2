-- ============================================================
-- ESP MODIFIKASI : Label hanya untuk Pumpkin & Window
-- ============================================================

-- Fungsi ESP Players (tanpa label)
local function ESPPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team then
            local teamName = player.Team.Name
            if teamName == "Killer" and Settings.ESP.Killer then
                HighlightObj(player.Character, Color3.fromRGB(255, 0, 0))
                -- Hapus LabelObj, hanya highlight
                -- LabelObj(player.Character, player.Name .. "\n[KILLER]", Color3.fromRGB(255, 0, 0))
            elseif teamName == "Survivors" and Settings.ESP.Survivor then
                HighlightObj(player.Character, Color3.fromRGB(0, 255, 0))
                -- LabelObj(player.Character, player.Name .. "\n[SURVIVOR]", Color3.fromRGB(0, 255, 0))
            else
                Unhighlight(player.Character)
                Unlabel(player.Character)
            end
        end
    end
end

-- Fungsi ESP Generators (tanpa label)
local function ESPGenerators()
    if not Settings.ESP.Generator then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                HighlightObj(obj, Color3.fromRGB(203, 132, 66))
                -- LabelObj(obj, "Generator", Color3.fromRGB(203, 132, 66))
            end
        end
    end)
end

-- Fungsi ESP Gates (tanpa label)
local function ESPGates()
    if not Settings.ESP.Gate then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Gate" then
                HighlightObj(obj, Color3.fromRGB(255, 255, 255))
                -- LabelObj(obj, "Gate", Color3.fromRGB(255, 255, 255))
            end
        end
    end)
end

-- Fungsi ESP Hooks (tanpa label)
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
                -- LabelObj(nearest, "CLOSEST HOOK", Color3.fromRGB(255, 255, 0)) -- tanpa label
            end
        else
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    if obj:FindFirstChild("Model") then
                        for _, part in ipairs(obj.Model:GetDescendants()) do
                            if part:IsA("MeshPart") then HighlightObj(part, Color3.fromRGB(255, 0, 0)) end
                        end
                    end
                    -- LabelObj(obj, "Hook", Color3.fromRGB(255, 0, 0))
                end
            end
        end
    end)
end

-- Fungsi ESP Pallets (tanpa label)
local function ESPPallets()
    if not Settings.ESP.Pallet then return end
    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Palletwrong" then
                HighlightObj(obj, Color3.fromRGB(255, 255, 0))
                -- LabelObj(obj, "Pallet", Color3.fromRGB(255, 255, 0))
            end
        end
    end)
end

-- ===== KHUSUS PUMPKIN & WINDOW : TETAP PAKAI LABEL =====
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
                LabelObj(obj, "Pumpkin", Color3.fromRGB(255, 140, 0))  -- TETAP ADA LABEL
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
                LabelObj(obj, "Window", Color3.fromRGB(173, 216, 230))  -- TETAP ADA LABEL
            end
        end
    end)
end

-- Loop ESP utama (panggil semua fungsi)
local function ESPTick()
    -- ... kode sebelumnya ...
    ESPPlayers()
    ESPGenerators()
    ESPGates()
    ESPHooks()
    ESPPallets()
    ESPPumpkins()   -- dengan label
    ESPWindows()    -- dengan label
end
