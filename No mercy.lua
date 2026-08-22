-- StarterPlayerScripts -> LocalScript
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function makeInvisible(character)
    task.wait(0.5) -- Tunggu character load
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            -- Jangan ubah transparansi untuk local player (kamu masih lihat)
            -- Tapi nonaktifkan casting bayangan
            part.CastShadow = false
            
            -- Untuk pemain lain, gunakan RemoteEvent jika perlu
            -- Atau set massless agar tidak bertabrakan secara visual
            part.Massless = true
        end
    end
    
    -- Sembunyikan nama tag
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    -- Sembunyikan accessories
    for _, accessory in pairs(character:GetChildren()) do
        if accessory:IsA("Accessory") then
            local handle = accessory:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 1
            end
        end
    end
end

if player.Character then
    makeInvisible(player.Character)
end

player.CharacterAdded:Connect(makeInvisible)
