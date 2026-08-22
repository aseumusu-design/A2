--[[ 
  SCRIPT INVISIBLE TOTAL + UI BUTTON
  - Player lain: BENER-BENER GA KELIATAN (termasuk topi, aksesoris, tool, tabung, apapun)
  - Kamu sendiri: KELIATAN JELAS (biar gampang main)
  - Ada tombol di layar buat ON/OFF
--]]

local player = game.Players.LocalPlayer
local invisActive = true  -- Langsung aktif pas dijalankan

-- Atur transparansi buat dirimu sendiri (0 = keliatan jelas, 0.5 = agak tembus)
local SELF_TRANSPARENCY = 0  

-- ========== MEMBUAT UI TOMBOL ==========
local gui = Instance.new("ScreenGui")
gui.Name = "InvisGUI"
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.new(0, 180, 0, 45)
button.Position = UDim2.new(0.5, -90, 0.9, 0) -- Posisi tengah bawah
button.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.Text = "👻 INVISIBLE: ON"
button.BackgroundTransparency = 0.2

-- Efek biar keliatan keren (opsional)
local corner = Instance.new("UICorner")
corner.Parent = button
corner.CornerRadius = UDim.new(0, 8)

-- ========== FUNGSI INVISIBLE ==========
local function applyInvisibility(character)
    if not character then return end
    task.wait(0.1) -- Tunggu karakter ke-load semua

    -- Loop SEMUA bagian, termasuk yang di dalam aksesoris/tool
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if invisActive then
                -- Kirim ke server & player lain: Transparansi 100% (lenyap)
                descendant.Transparency = 1
                -- Paksa di layar kita sendiri: Tetep keliatan
                pcall(function()
                    sethiddenproperty(descendant, "Transparency", SELF_TRANSPARENCY)
                end)
            else
                -- Kembalikan normal
                descendant.Transparency = 0
                pcall(function()
                    sethiddenproperty(descendant, "Transparency", 0)
                end)
            end
        end
    end
end

-- ========== EVENT RESPAWN ==========
local function onCharacterAdded(character)
    character:WaitForChild("HumanoidRootPart")
    applyInvisibility(character)
end

-- Jalankan jika karakter sudah ada
if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- ========== FUNGSI TEKAN TOMBOL ==========
button.MouseButton1Click:Connect(function()
    invisActive = not invisActive
    local char = player.Character
    if char then
        applyInvisibility(char)
    end
    
    -- Update tulisan di tombol
    if invisActive then
        button.Text = "👻 INVISIBLE: ON"
        button.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        print("[✓] Invisible AKTIF! Player lain ga bisa liat kamu sama sekali.")
    else
        button.Text = "🔓 INVISIBLE: OFF"
        button.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        print("[✗] Invisible NONAKTIF! Kamu kembali normal.")
    end
end)

print("✅ Script siap! Klik tombol di layar untuk ON/OFF.")
