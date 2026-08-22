--[[
  SCRIPT INVISIBLE KHUSUS DELTA EXECUTOR
  - Player lain: HILANG TOTAL (ga liat tubuh, ga liat topi, ga liat senjata)
  - Kamu sendiri: KELIATAN JELAS (biar enak main)
  - Tekan tombol [X] di keyboard untuk ON/OFF
  - Ada tombol UI di layar (bisa diklik)
  - Otomatis aktif pas respawn
--]]

local player = game.Players.LocalPlayer
local invisActive = true  -- Langsung aktif pas dijalankan

-- ========== BUAT UI TOMBOL DI LAYAR ==========
local gui = Instance.new("ScreenGui")
gui.Name = "InvisByDelta"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.new(0, 160, 0, 45)
button.Position = UDim2.new(0.5, -80, 0.92, 0) -- Tengah bawah
button.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Text = "👻 INVISIBLE: ON"
button.BackgroundTransparency = 0.1

-- Bikin sudut melengkung
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

-- ========== FUNGSI INVISIBLE (PAKAI SETHIDDENPROPERTY) ==========
local function applyInvisible(state)
    local char = player.Character
    if not char then return end
    
    -- Loop SEMUA bagian tubuh, aksesoris, dan tool
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                -- 1. Biar player lain ga liat: set Transparency jadi 1
                part.Transparency = 1
                
                -- 2. Biar diri sendiri liat: paksa pake sethiddenproperty (khusus client)
                --    Nilai ini ga akan tersinkronisasi ke server/pemain lain!
                pcall(function()
                    sethiddenproperty(part, "Transparency", 0)
                end)
            else
                -- Matikan mode: balikin normal
                part.Transparency = 0
                pcall(function()
                    sethiddenproperty(part, "Transparency", 0)
                end)
            end
        end
    end
end

-- ========== DETEKSI AKSESORIS / SENJATA BARU ==========
local function setupCharacter(char)
    if not char then return end
    
    -- Terapkan langsung
    task.wait(0.1) -- Tunggu sebentar biar semua part keload
    applyInvisible(invisActive)
    
    -- Pantau jika ada aksesoris/tool baru yang dipasang (misal ambil senjata)
    if char._invisConnection then
        char._invisConnection:Disconnect()
    end
    
    char._invisConnection = char.DescendantAdded:Connect(function(part)
        if invisActive and part:IsA("BasePart") then
            part.Transparency = 1
            pcall(function()
                sethiddenproperty(part, "Transparency", 0)
            end)
        end
    end)
end

-- ========== EVENT RESPAWN ==========
local function onCharacterAdded(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    setupCharacter(char)
end

-- Jalankan jika karakter sudah ada
if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- ========== FUNGSI TEKAN TOMBOL UI ==========
button.MouseButton1Click:Connect(function()
    invisActive = not invisActive
    local char = player.Character
    if char then
        applyInvisible(invisActive)
    end
    
    if invisActive then
        button.Text = "👻 INVISIBLE: ON"
        button.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
        print("[✓] Invisible AKTIF! Player lain ga liat kamu.")
    else
        button.Text = "🔓 INVISIBLE: OFF"
        button.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        print("[✗] Invisible NONAKTIF! Kamu keliatan lagi.")
    end
end)

-- ========== TEKAN TOMBOL [X] DI KEYBOARD ==========
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        -- Simulasi klik tombol UI
        button.MouseButton1Click:Fire()
    end
end)

print("✅ Script Delta siap! Klik tombol di layar atau tekan [X].")
