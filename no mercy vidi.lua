--[[ 
  SCRIPT INVISIBLE ROBLOX (SERVER-SIDE HIDDEN)
  - Player lain: GA KELIATAN SAMA SEKALI (transparansi 100% di mata mereka)
  - Kamu sendiri: Masih keliatan (bisa diatur tingkat transparansinya)
  - Aktif otomatis saat spawn / respawn
  - Tekan tombol [X] untuk ON / OFF
--]]

local player = game.Players.LocalPlayer
local invisActive = true  -- Set true biar otomatis aktif pas dijalankan

-- ATUR TINGKAT TRANSPARANSI BUAT DIRI SENDIRI:
-- 0 = Jelas (keliatan normal) | 0.3 = Agak tembus pandang | 1 = Ikut ilang (ga rekomen)
local SELF_TRANSPARENCY = 0  

-- Fungsi utama untuk menerapkan efek invisible
local function applyInvisibility(character)
    if not character then return end
    
    -- Tunggu sebentar biar semua part karakter keload
    task.wait(0.1)
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if invisActive then
                -- 1. Kirim ke server & player lain: Transparency = 1 (Mereka ga liat)
                part.Transparency = 1
                
                -- 2. Paksa di layar kita sendiri: Tetep keliatan sesuai setting
                --    Nilai ini TIDAK akan tersinkronisasi ke server.
                sethiddenproperty(part, "Transparency", SELF_TRANSPARENCY)
            else
                -- Matikan mode invisible
                part.Transparency = 0
                sethiddenproperty(part, "Transparency", 0)
            end
        end
    end
end

-- Event saat karakter spawn / respawn
local function onCharacterAdded(character)
    character:WaitForChild("HumanoidRootPart")  -- Tunggu sampai karakter benar-benar muncul
    applyInvisibility(character)
end

-- Eksekusi jika karakter sudah ada
if player.Character then
    onCharacterAdded(player.Character)
end

-- Hubungkan ke event respawn
player.CharacterAdded:Connect(onCharacterAdded)

-- Toggle (ON/OFF) dengan menekan tombol X
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        invisActive = not invisActive
        local char = player.Character
        if char then
            applyInvisibility(char)
        end
        
        if invisActive then
            print("[✓] INVISIBLE AKTIF! Player lain ga bisa liat kamu.")
        else
            print("[✗] INVISIBLE NONAKTIF! Kamu kembali normal.")
        end
    end
end)

-- Notifikasi di layar kamu
print("Script Invisible berjalan! Tekan [X] untuk toggle.")
