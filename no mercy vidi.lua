--[[ 
  INVISIBLE TOTAL + UI PAKAI LOCALTRANSPARENCYMODIFIER
  - Player lain: GA LIAT APAPUN (termasuk tabung, topi, tool)
  - Kamu sendiri: KELIATAN JELAS (bisa diatur)
  - UI ditempel di CoreGui (BIAR PASTI MUNCUL)
  - Otomatis handle aksesoris baru yang dipasang
--]]

local player = game.Players.LocalPlayer
local invisActive = true  -- Langsung aktif

-- ATUR KELIATAN BUAT DIRI SENDIRI:
-- 0 = Jelas (Normal) | 0.3 = Agak Tembus | 1 = Ikut Ilang (ga rekomen)
local LOCAL_VISIBILITY = 0  

-- ========== BUAT UI TOMBOL (DI COREGUI) ==========
local coreGui = game:GetService("CoreGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InvisUI"
screenGui.Parent = coreGui  -- NEMPEL DI COREGUI BIAR GAK DIHAPUS GAME

local button = Instance.new("TextButton")
button.Parent = screenGui
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.92, 0) -- Tengah bawah
button.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.TextSize = 20
button.Text = "👻 INVISIBLE: ON"
button.BackgroundTransparency = 0.1

-- Bikin sudut melengkung
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

-- Efek shadow biar keliatan
local shadow = Instance.new("UIShadow")
shadow.Parent = button

-- ========== FUNGSI INVISIBLE HEBAT ==========
local function applyInvisible(state)
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if state then
        -- 1. SET SEMUA BAGIAN (termasuk aksesoris/tabung) jadi 100% transparan buat SERVER
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
        
        -- 2. PAKSA di layar kita: tetep keliatan jelas pake LocalTransparencyModifier
        --    Nilai ini cuma berlaku di client kita, GA KESYNC ke server!
        humanoid.LocalTransparencyModifier = LOCAL_VISIBILITY
        
        -- 3. DETECT aksesoris/tabung baru yang dipasang belakangan
        if not char._invisConnection then
            char._invisConnection = char.DescendantAdded:Connect(function(desc)
                if state and desc:IsA("BasePart") then
                    desc.Transparency = 1
                end
            end)
        end
    else
        -- MATIKAN INVISIBLE (kembali normal)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
        humanoid.LocalTransparencyModifier = 0
        
        if char._invisConnection then
            char._invisConnection:Disconnect()
            char._invisConnection = nil
        end
    end
end

-- ========== EVENT RESPAWN ==========
local function onCharacterAdded(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    
    -- Hapus koneksi lama biar ga dobel
    if char._invisConnection then
        char._invisConnection:Disconnect()
        char._invisConnection = nil
    end
    
    applyInvisible(invisActive)
end

-- Jalankan jika karakter sudah ada
if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- ========== FUNGSI KLIK TOMBOL ==========
button.MouseButton1Click:Connect(function()
    invisActive = not invisActive
    applyInvisible(invisActive)
    
    -- Update tampilan tombol
    if invisActive then
        button.Text = "👻 INVISIBLE: ON"
        button.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        print("[✓] Mode INVISIBLE AKTIF! Player lain cuma lihat angin.")
    else
        button.Text = "🔓 INVISIBLE: OFF"
        button.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        print("[✗] Mode INVISIBLE NONAKTIF! Kamu normal lagi.")
    end
end)

print("✅ Script siap! Tombol ada di layar bagian bawah.")
