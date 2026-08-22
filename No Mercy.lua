local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Buat RemoteEvent
local ghostEvent = Instance.new("RemoteEvent")
ghostEvent.Name = "GhostToggleEvent"
ghostEvent.Parent = ReplicatedStorage

-- Catatan siapa yang sedang ghost
local ghostStates = {}

-- Terima toggle dari client
ghostEvent.OnServerEvent:Connect(function(player, isGhost)
	ghostStates[player.UserId] = isGhost
	
	-- Kirim ke semua pemain lain
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			ghostEvent:FireClient(p, player.UserId, isGhost)
		end
	end
end)

-- Pemain baru join? Kasih tahu siapa yang lagi ghost
Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(2)
	for userId, isGhost in pairs(ghostStates) do
		if isGhost then
			ghostEvent:FireClient(newPlayer, userId, true)
		end
	end
end)

-- Bersihin data kalau pemain leave
Players.PlayerRemoving:Connect(function(player)
	ghostStates[player.UserId] = nil
end)
