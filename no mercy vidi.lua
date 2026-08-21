--[[
    NO MERCY x ZIAAN HUB — VIOLENCE DISTRICT  v3.5 (FLUENT UI)
    Game: Violence District (Roblox)
    Author: Sobing4413 | Discord: https://discord.gg/CnNqEVFxh6

    v3.6: Android Lite + fallback loader UI dan optimasi startup
    v3.5: ESP Killer/Player dan Generator memakai renderer Ziaan Hub v3
    v3.0: UI dipindah ke Fluent UI Library (dawid-scripts/Fluent)
    + bubble button logo ninja + SaveManager/InterfaceManager
    + MENU TELEPORT lengkap (generator, gate, hook, pallet, window,
      pemain, waypoint tersimpan, TP klik posisi, escape game).
    Semua logika fitur lama (ESP, Aimbot, Parry, Fly, dsb) tetap sama.
]]


-- ===== BAGIAN 0 : ANTI DOUBLE-EXECUTE & UI YIELD BUDGET (v3.4) =====
-- Kalau script pernah dijalankan, bersihkan dulu instance lama supaya tidak
-- ada dua set loop/GUI yang jalan bersamaan (penyebab utama lag menumpuk).
if getgenv and getgenv().NoMercyUnload then
    pcall(getgenv().NoMercyUnload)
    task.wait(0.15)
end

-- Breathe(): memberi nafas ke render thread saat membangun UI.
-- Tanpa ini, ratusan elemen Fluent dibuat dalam SATU frame -> executor freeze
-- -> Roblox dianggap "not responding" dan menutup game (terutama di HP).
local Breathe
do
    local frameStart = os.clock()
    function Breathe(budget)
        if (os.clock() - frameStart) > (budget or 0.006) then
            task.wait()
            frameStart = os.clock()
        end
    end
end

-- ===== BAGIAN 1 : UTILITAS DASAR & DETEKSI PLATFORM =====

local char   = string.char
local byte   = string.byte
local sub    = string.sub
local bit    = bit32 or bit
local bxor   = bit.bxor
local concat = table.concat
local insert = table.insert

-- Jejak fungsi XOR dari obfuscator (tidak lagi dipakai runtime,
-- karena semua string sudah didekripsi).
local function xorDecrypt(data, key)
    local result = {}
    for i = 1, #data do
        insert(result, char(bxor(byte(sub(data, i, i + 1)), byte(sub(key, 1 + (i % #key), 1 + (i % #key) + 1))) % 256))
    end
    return concat(result)
end

-- Deteksi apakah ini perangkat mobile (HP/tablet)
local function detectMobile()
    local inputService = game:GetService("UserInputService")
    local touchEnabled  = inputService.TouchEnabled
    local camera        = workspace.CurrentCamera
    local viewportSize  = (camera and camera.ViewportSize) or Vector2.new(0, 0)
    local smallScreen   = (viewportSize.X <= 1024) or (viewportSize.Y <= 768)
    local hasSensors    = inputService.GyroscopeEnabled or inputService.AccelerometerEnabled
    local noKeyboard    = not inputService.KeyboardEnabled
    local executor      = (identifyexecutor and identifyexecutor()) or "Unknown"
    local mobileExec    = executor:lower():find("delta")
                       or executor:lower():find("arceus")
                       or executor:lower():find("fluxus")
                       or executor:lower():find("krnl")
    local isMobile = touchEnabled and (noKeyboard or smallScreen or hasSensors or mobileExec)
    if touchEnabled and mobileExec then
        isMobile = true
    end
    return isMobile
end

local isMobile     = detectMobile()
local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"

print("=== Violence District v1 ===")
print("Platform: " .. ((isMobile and "Mobile") or "PC"))
print("Executor: " .. executorName)
print("===================================================")

-- ===== BAGIAN 2 : SERVICE ROBLOX =====

local Players            = game:GetService("Players")
local Workspace          = game:GetService("Workspace")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local LocalPlayer        = Players.LocalPlayer

-- ===== BAGIAN 2B : PERFORMANCE MANAGER =====
-- Scheduler (satu Heartbeat untuk semua pekerjaan berkala), connection manager,
-- cache objek map & remote. Semua fitur lama memakai infrastruktur ini supaya
-- tidak ada loop/coroutine yang jalan tanpa kebutuhan.

local osclock = os.clock

local PerfMgr = {}
do
    local jobs, byName = {}, {}
    local activeCount = 0
    local hbConn = nil

    local function tick()
        local now = osclock()
        for i = 1, #jobs do
            local job = jobs[i]
            if job.active and now >= job.nextRun then
                job.nextRun = now + job.interval
                local ok = pcall(job.fn)
                if not ok then
                    job.fails = job.fails + 1
                    if job.fails >= 50 then
                        job.active = false
                        activeCount = activeCount - 1
                    end
                end
            end
        end
    end

    local function sync()
        if activeCount > 0 and not hbConn then
            hbConn = RunService.Heartbeat:Connect(tick)
        elseif activeCount <= 0 and hbConn then
            hbConn:Disconnect()
            hbConn = nil
        end
    end

    function PerfMgr.SetActive(name, on)
        local job = byName[name]
        if not job then return end
        on = on and true or false
        if job.active == on then return end
        job.active = on
        activeCount = activeCount + (on and 1 or -1)
        if on then job.nextRun = 0; job.fails = 0 end
        sync()
    end

    function PerfMgr.Add(name, interval, fn, startActive)
        local job = byName[name]
        if job then
            job.interval = interval
            job.fn = fn
        else
            job = { name = name, interval = interval, fn = fn, nextRun = 0, active = false, fails = 0 }
            byName[name] = job
            jobs[#jobs + 1] = job
        end
        if startActive then PerfMgr.SetActive(name, true) end
        return job
    end

    function PerfMgr.SetInterval(name, interval)
        local job = byName[name]
        if job then job.interval = interval end
    end

    function PerfMgr.IsActive(name)
        local job = byName[name]
        return (job ~= nil) and job.active
    end

    function PerfMgr.StopAll()
        for _, job in ipairs(jobs) do job.active = false end
        activeCount = 0
        sync()
    end
end

-- Connection manager: semua koneksi opsional dikelompokkan supaya bisa dibersihkan.
local ConnMgr = {}
do
    local groups = {}
    function ConnMgr.Add(group, conn)
        if not conn then return conn end
        local g = groups[group]
        if not g then g = {}; groups[group] = g end
        g[#g + 1] = conn
        return conn
    end
    function ConnMgr.Clear(group)
        local g = groups[group]
        if not g then return end
        for _, c in ipairs(g) do pcall(function() c:Disconnect() end) end
        groups[group] = nil
    end
    function ConnMgr.ClearAll()
        for name in pairs(groups) do ConnMgr.Clear(name) end
    end
end

-- Cache objek Map: satu traversal per rebuild, hasil dipakai semua fitur
-- (teleport, auto generator, escape, dsb). Rebuild hanya kalau map berubah
-- dan minimal berjarak MIN_REBUILD detik.
local MapCache = {}
do
    local MIN_REBUILD = 1.5
    local buckets = {}
    local anchors = setmetatable({}, { __mode = "k" })
    local genPoints = setmetatable({}, { __mode = "k" })
    local mapRef, built, dirty, lastBuild = nil, false, true, 0
    local watchConns = {}

    local function markDirty() dirty = true end

    local function refreshMap()
        local m = Workspace:FindFirstChild("Map")
        if m ~= mapRef then
            mapRef = m
            dirty, built = true, false
            for _, c in ipairs(watchConns) do pcall(function() c:Disconnect() end) end
            watchConns = {}
            if m then
                watchConns[1] = m.DescendantAdded:Connect(markDirty)
                watchConns[2] = m.DescendantRemoving:Connect(markDirty)
            end
        end
        return m
    end

    local function build(force)
        local now = osclock()
        local map = refreshMap()
        if built and not force and not (dirty and (now - lastBuild) >= MIN_REBUILD) then
            return buckets
        end
        buckets = {}
        anchors = setmetatable({}, { __mode = "k" })
        genPoints = setmetatable({}, { __mode = "k" })
        built, dirty, lastBuild = true, false, now
        if not map then return buckets end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") then
                local list = buckets[obj.Name]
                if not list then list = {}; buckets[obj.Name] = list end
                list[#list + 1] = obj
            end
        end
        return buckets
    end

    function MapCache.Invalidate() dirty = true; built = false end
    function MapCache.GetMap() return refreshMap() end

    -- Daftar model bernama <name> (hanya yang masih valid di dunia)
    function MapCache.Models(name, force)
        local list = build(force)[name]
        if not list then return {} end
        local out, n = {}, 0
        for i = 1, #list do
            local obj = list[i]
            if obj.Parent then n = n + 1; out[n] = obj end
        end
        return out
    end

    -- BasePart representatif dari sebuah model (di-cache)
    function MapCache.Anchor(model)
        local part = anchors[model]
        if part and part.Parent then return part end
        part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        anchors[model] = part
        return part
    end

    -- Anak "GeneratorPoint" dari sebuah generator (di-cache)
    function MapCache.GeneratorPoints(model)
        local pts = genPoints[model]
        if pts then
            local stillOk = true
            for i = 1, #pts do
                if not pts[i].Parent then stillOk = false; break end
            end
            if stillOk then return pts end
        end
        pts = {}
        for _, child in ipairs(model:GetChildren()) do
            if child.Name:find("GeneratorPoint") then pts[#pts + 1] = child end
        end
        genPoints[model] = pts
        return pts
    end
end

-- Cache remote (ReplicatedStorage.Remotes.<a>.<b>...), hindari FindFirstChild berulang.
local RemoteCache = {}
do
    local cache = {}
    local remotesRoot = nil
    function RemoteCache.Get(...)
        local path = { ... }
        local key = table.concat(path, "/")
        local hit = cache[key]
        if hit and hit.Parent then return hit end
        if not (remotesRoot and remotesRoot.Parent) then
            remotesRoot = ReplicatedStorage:FindFirstChild("Remotes")
        end
        local node = remotesRoot
        for i = 1, #path do
            if not node then return nil end
            node = node:FindFirstChild(path[i])
        end
        cache[key] = node
        return node
    end
    function RemoteCache.Clear() cache = {}; remotesRoot = nil end
end



-- ===== BAGIAN A : LOAD FLUENT UI LIBRARY =====

-- Loader aman + CACHE KE DISK.
-- Execute pertama tetap download; execute berikutnya dibaca dari file lokal
-- (0 request HTTP) sehingga UI muncul hampir instan.
local SafeLoad
do
local LIB_DIR = "NoMercyHub"
local function ensureFolder()
    if makefolder and isfolder and not isfolder(LIB_DIR) then pcall(makefolder, LIB_DIR) end
end

function SafeLoad(url, label, cacheName)
    local path = cacheName and (LIB_DIR .. "/lib_" .. cacheName .. ".txt") or nil

    -- 1) coba cache lokal dulu
    if path and isfile and readfile and pcall(isfile, path) and isfile(path) then
        local ok, res = pcall(function()
            local src = readfile(path)
            if type(src) ~= "string" or #src < 100 then return nil end
            local fn = loadstring(src)
            return fn and fn()
        end)
        if ok and res then return res end
        pcall(function() if delfile then delfile(path) end end)
    end

    -- 2) download (maks 2 percobaan, tanpa jeda panjang)
    for _ = 1, 2 do
        local ok, src = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(src) == "string" and #src > 100 then
            local fn = loadstring(src)
            if fn then
                local ok2, res = pcall(fn)
                if ok2 and res then
                    if path and writefile then
                        pcall(function() ensureFolder(); writefile(path, src) end)
                    end
                    return res
                end
            end
        end
        task.wait(0.25)
    end
    warn("[NO MERCY] Gagal load " .. tostring(label))
    return nil
end
end

-- Beberapa executor Android gagal mengikuti redirect URL release GitHub.
-- Coba release dulu, lalu fallback ke source raw agar UI tetap muncul.
local Fluent = SafeLoad("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "Fluent UI", "fluent")
if not Fluent then
    Fluent = SafeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua", "Fluent UI fallback", "fluent_fallback")
end
if not Fluent then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "NO MERCY", Text = "Gagal load UI, coba execute ulang", Duration = 6 })
    return
end

-- SaveManager & InterfaceManager di-load di BACKGROUND (tidak memblokir UI).
local SaveManager, InterfaceManager
local addonsReady = false
if isMobile then
    -- Addon config tidak diperlukan di HP; hindari dua request dan ratusan UI item.
    addonsReady = true
else
    task.spawn(function()
        SaveManager      = SafeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", "SaveManager", "savemgr")
        InterfaceManager = SafeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "InterfaceManager", "intfmgr")
        addonsReady = true
    end)
end

local Window = Fluent:CreateWindow({
    Title = "NO MERCY",
    SubTitle = "Violence District | Android Lite v3.6",
    TabWidth = 125,
    Size = UDim2.fromOffset(470, 380),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

-- Bubble logo dihapus untuk mengurangi GUI instance dan pemakaian memori Android.
local BubbleGui, BubbleBtn = nil, nil

-- Notifikasi lewat Fluent (menggantikan sistem notifikasi lama)
local function Notify(title, text, duration)
    pcall(function()
        Fluent:Notify({ Title = tostring(title), Content = tostring(text), Duration = duration or 3 })
    end)
end

-- Label status: proxy dengan properti .Text supaya kode lama tetap jalan
local function CreateStatus(tab, title, initial)
    local paragraph = tab:AddParagraph({ Title = title, Content = initial or "-" })
    local proxy = {}
    return setmetatable(proxy, {
        __index = function(_, key)
            if key == "Text" then return rawget(proxy, "_text") end
            return nil
        end,
        __newindex = function(_, key, value)
            if key == "Text" then
                rawset(proxy, "_text", value)
                pcall(function() paragraph:SetDesc(tostring(value)) end)
            else
                rawset(proxy, key, value)
            end
        end,
    })
end

-- ===== BAGIAN 3 : TEMA WARNA UI =====

local Themes = {
    ["Modern"] = {
        ["Name"]="Modern", ["Background"]=Color3.fromRGB(10,10,18), ["Surface"]=Color3.fromRGB(18,18,30),
        ["SurfaceAlt"]=Color3.fromRGB(25,25,42), ["Accent"]=Color3.fromRGB(255,0,102), ["AccentAlt"]=Color3.fromRGB(0,255,255),
        ["Text"]=Color3.fromRGB(230,230,255), ["TextDim"]=Color3.fromRGB(140,140,180), ["Border"]=Color3.fromRGB(255,0,102),
        ["Toggle"]=Color3.fromRGB(255,0,102), ["ToggleOff"]=Color3.fromRGB(60,60,80), ["Slider"]=Color3.fromRGB(0,255,255),
        ["Glow"]=Color3.fromRGB(255,0,102), ["TabActive"]=Color3.fromRGB(255,0,102), ["TabInactive"]=Color3.fromRGB(30,30,50),
        ["Notification"]=Color3.fromRGB(255,0,102),
    },
    ["Neon Blue"] = {
        ["Name"]="Neon Blue", ["Background"]=Color3.fromRGB(8,12,22), ["Surface"]=Color3.fromRGB(14,20,36),
        ["SurfaceAlt"]=Color3.fromRGB(20,28,48), ["Accent"]=Color3.fromRGB(0,150,255), ["AccentAlt"]=Color3.fromRGB(0,220,255),
        ["Text"]=Color3.fromRGB(220,235,255), ["TextDim"]=Color3.fromRGB(120,150,190), ["Border"]=Color3.fromRGB(0,150,255),
        ["Toggle"]=Color3.fromRGB(0,150,255), ["ToggleOff"]=Color3.fromRGB(40,50,70), ["Slider"]=Color3.fromRGB(0,220,255),
        ["Glow"]=Color3.fromRGB(0,150,255), ["TabActive"]=Color3.fromRGB(0,150,255), ["TabInactive"]=Color3.fromRGB(20,28,48),
        ["Notification"]=Color3.fromRGB(0,150,255),
    },
    ["Blood Red"] = {
        ["Name"]="Blood Red", ["Background"]=Color3.fromRGB(14,8,8), ["Surface"]=Color3.fromRGB(24,12,12),
        ["SurfaceAlt"]=Color3.fromRGB(36,18,18), ["Accent"]=Color3.fromRGB(220,20,20), ["AccentAlt"]=Color3.fromRGB(255,80,60),
        ["Text"]=Color3.fromRGB(255,220,220), ["TextDim"]=Color3.fromRGB(180,120,120), ["Border"]=Color3.fromRGB(220,20,20),
        ["Toggle"]=Color3.fromRGB(220,20,20), ["ToggleOff"]=Color3.fromRGB(60,30,30), ["Slider"]=Color3.fromRGB(255,80,60),
        ["Glow"]=Color3.fromRGB(220,20,20), ["TabActive"]=Color3.fromRGB(220,20,20), ["TabInactive"]=Color3.fromRGB(30,14,14),
        ["Notification"]=Color3.fromRGB(220,20,20),
    },
    ["Matrix Green"] = {
        ["Name"]="Matrix Green", ["Background"]=Color3.fromRGB(5,12,7), ["Surface"]=Color3.fromRGB(10,20,10),
        ["SurfaceAlt"]=Color3.fromRGB(15,30,15), ["Accent"]=Color3.fromRGB(0,220,60), ["AccentAlt"]=Color3.fromRGB(0,255,120),
        ["Text"]=Color3.fromRGB(200,255,200), ["TextDim"]=Color3.fromRGB(100,180,120), ["Border"]=Color3.fromRGB(0,220,60),
        ["Toggle"]=Color3.fromRGB(0,220,60), ["ToggleOff"]=Color3.fromRGB(20,50,30), ["Slider"]=Color3.fromRGB(0,255,120),
        ["Glow"]=Color3.fromRGB(220,60,0), ["TabActive"]=Color3.fromRGB(0,220,60), ["TabInactive"]=Color3.fromRGB(10,24,14),
        ["Notification"]=Color3.fromRGB(0,250,130),
    },
    ["Purple Haze"] = {
        ["Name"]="Purple Haze", ["Background"]=Color3.fromRGB(12,8,18), ["Surface"]=Color3.fromRGB(20,14,30),
        ["SurfaceAlt"]=Color3.fromRGB(30,20,45), ["Accent"]=Color3.fromRGB(160,60,255), ["AccentAlt"]=Color3.fromRGB(220,120,255),
        ["Text"]=Color3.fromRGB(230,220,255), ["TextDim"]=Color3.fromRGB(150,130,180), ["Border"]=Color3.fromRGB(160,60,255),
        ["Toggle"]=Color3.fromRGB(160,60,255), ["ToggleOff"]=Color3.fromRGB(50,30,70), ["Slider"]=Color3.fromRGB(220,120,255),
        ["Glow"]=Color3.fromRGB(160,60,255), ["TabActive"]=Color3.fromRGB(160,60,255), ["TabInactive"]=Color3.fromRGB(22,16,34),
        ["Notification"]=Color3.fromRGB(160,80,255),
    },
}

local Theme = Themes["Matrix Green"]

-- Listener tema: dipanggil saat tema berganti
local themeListeners = {}
local function AddThemeListener(listener)
    insert(themeListeners, listener)
end

local function SetTheme(themeName)
    if Themes[themeName] then
        Theme = Themes[themeName]
        for _, listener in ipairs(themeListeners) do
            pcall(listener, Theme)
        end
    end
end


-- ===== BAGIAN 4 : UI LIBRARY (helper + komponen) =====

local UI = {}
UI.__index = UI

local function SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then return nil end
    return result
end

local function IsValid(obj)
    return obj and (typeof(obj) == "Instance") and (obj.Parent ~= nil)
end

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

local function AddPadding(parent, top, bottom, left, right)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, top or 4)
    pad.PaddingBottom = UDim.new(0, bottom or 6)
    pad.PaddingLeft = UDim.new(0, left or 8)
    pad.PaddingRight = UDim.new(0, right or 8)
    pad.Parent = parent
    return pad
end

local function AddGradient(parent, fromColor, toColor, rotation)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, fromColor),
        ColorSequenceKeypoint.new(1, toColor),
    })
    grad.Rotation = rotation or 90
    grad.Parent = parent
    return grad
end

local function Tween(instance, properties, duration)
    local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- ===== BAGIAN 8 : KONFIGURASI (Settings) =====

local Settings = {
    ESP = {
        Master = false,   -- MASTER ON/OFF: kalau false semua ESP mati
        Killer = false, Survivor = false, Zombie = false, Generator = false, Gate = false,
        Hook = false, Pallet = false, Window = false, Pumpkin = false,
        Colors = {
            Killer    = Color3.fromRGB(255, 0, 0),
            Survivor  = Color3.fromRGB(0, 255, 0),
            Zombie    = Color3.fromRGB(255, 0, 150),
            Generator = Color3.fromRGB(203, 132, 66),
            Gate      = Color3.fromRGB(255, 255, 255),
            Hook      = Color3.fromRGB(255, 255, 0),
            Pallet    = Color3.fromRGB(255, 255, 0),
            Window    = Color3.fromRGB(173, 216, 230),
            Pumpkin   = Color3.fromRGB(255, 140, 0),
        },
        ClosestHook = false, ShowOnlyClosestHook = false, ShowDistance = true,
        MaxDistance = 500,
    },
    AutoFeatures = {
        AutoGenerator = false, GeneratorMode = "great", AutoLeaveGenerator = false,
        LeaveDistance = 15, LeaveKeybind = Enum.KeyCode.Q,
        AutoAttack = false, AttackRange = 10,
    },
    Teleportation = {
        TeleportOffset = 3, SafeTeleport = true, TeleportDelay = 0.1,
    },
    Performance = {
        UpdateRate = 0.5, UseDistanceCulling = true,
        MaxESPObjects = (isMobile and 50) or 100,
        DisableParticles = false, LowerGraphics = false,
        DisableShadows = false, ReduceRenderDistance = false,
    },
    Mobile = {
        TouchControlsEnabled = isMobile, ButtonSize = 80,
        ButtonTransparency = 0.3, AutoOptimize = true,
        AggressiveOptimization = false,
    },
}

-- State & koneksi runtime
local ESPHighlights = {}   -- object -> Highlight
local ESPLabels = {}       -- object -> BillboardGui
local lastUpdate = 0
local espLoopConn = nil
local leaveConn = nil
local autoAttackConn = nil
local mobileControls = nil
local fpsActive = false
local fpsGui = nil

-- ===== BAGIAN 9 : FUNGSI UTIL GAME =====

local function IsKiller()
    return LocalPlayer.Team and (LocalPlayer.Team.Name == "Killer")
end

local function IsSurvivor()
    return LocalPlayer.Team and (LocalPlayer.Team.Name == "Survivors")
end

-- ===== BAGIAN 10 : OPTIMASI PERFORMANCE =====

local function MobileOptimize()
    if not isMobile then return end
    local lighting = game:GetService("Lighting")
    SafeCall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        lighting.GlobalShadows = false
        lighting.FogEnd = 100
        lighting.Brightness = 2
        for _, child in ipairs(lighting:GetChildren()) do
            if child:IsA("PostEffect") then child.Enabled = false end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then obj.Enabled = false
            elseif obj:IsA("Trail") then obj.Enabled = false
            elseif obj:IsA("Beam") then obj.Enabled = false
            elseif (obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")) then obj.Enabled = false
            end
        end
        Workspace.StreamingEnabled = true
        Workspace.StreamingMinRadius = 32
        Workspace.StreamingTargetRadius = 64
        if Workspace:FindFirstChild("Terrain") then
            Workspace.Terrain.Decoration = false
        end
    end)
end

local function AggressiveOptimize()
    if not isMobile then return end
    MobileOptimize()
    SafeCall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then obj.Transparency = 1
            elseif obj:IsA("SurfaceAppearance") then obj.Parent = nil
            end
        end
        Settings.Performance.UpdateRate = 1
        Settings.Performance.MaxESPObjects = 25
    end)
end

local function ApplyPerf()
    local lighting = game:GetService("Lighting")
    if Settings.Performance.DisableParticles then
        SafeCall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = false
                end
            end
        end)
    end
    if Settings.Performance.LowerGraphics then
        SafeCall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end
    if Settings.Performance.DisableShadows then
        SafeCall(function()
            lighting.GlobalShadows = false
            lighting.FogEnd = 100
        end)
    end
    if Settings.Performance.ReduceRenderDistance then
        SafeCall(function()
            Workspace.StreamingEnabled = true
            Workspace.StreamingMinRadius = 32
            Workspace.StreamingTargetRadius = 64
        end)
    end
end

local function ResetPerf()
    local lighting = game:GetService("Lighting")
    SafeCall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = true
            end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        lighting.GlobalShadows = true
        lighting.FogEnd = 100000
        for _, child in ipairs(lighting:GetChildren()) do
            if child:IsA("PostEffect") then child.Enabled = true end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then obj.Transparency = 0 end
        end
    end)
end

-- ===== BAGIAN 11 : TELEPORT & GENERATOR =====

local function GetRoot()
    if not LocalPlayer.Character then return nil end
    return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Cari generator terdekat dalam jarak "LeaveDistance"
local function FindNearGenerator()
    local root = GetRoot()
    if not root then return false, nil end
    local gens = MapCache.Models("Generator")
    if #gens == 0 then return false, nil end
    local rootPos = root.Position
    local nearest, nearestDist = nil, math.huge
    for i = 1, #gens do
        local obj = gens[i]
        local part = MapCache.Anchor(obj)
        if part then
            local dist = (part.Position - rootPos).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    if nearest and (nearestDist <= Settings.AutoFeatures.LeaveDistance) then
        return true, nearest, nearestDist
    end
    return false, nil, nil
end

local function Teleport(position, offset)
    local root = GetRoot()
    if not root then
        Notify("Error", "Character not found", 3)
        return false
    end
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

-- Kabur dari generator: teleport menjauh searah pandangan
local function EscapeGenerator()
    local root = GetRoot()
    if not root then return false end
    local _, gen, _ = FindNearGenerator()
    if not gen then
        Notify("Not Near", "You're not near any generator", 2)
        return false
    end
    local part = gen:FindFirstChildWhichIsA("BasePart")
    if part then
        local direction = (root.Position - part.Position).Unit
        local distance = Settings.AutoFeatures.LeaveDistance + 15
        local target = root.Position + (direction * distance)
        local lookCFrame = CFrame.new(target, target + root.CFrame.LookVector)
        if Teleport(lookCFrame, Vector3.new(0, 2, 0)) then
            Notify("Escaped!", string.format("Moved %.0f studs away", distance), 2)
            return true
        end
    end
    return false
end

-- Kumpulkan semua generator di map
local function ListGenerators()
    local list = {}
    for _, obj in ipairs(MapCache.Models("Generator")) do
        local part = MapCache.Anchor(obj)
        if part then
            insert(list, { model = obj, part = part, position = part.Position })
        end
    end
    return list
end

-- Daftar generator diurutkan dari yang terdekat
local function ListGeneratorsSorted()
    local root = GetRoot()
    if not root then return {} end
    local list = ListGenerators()
    for _, gen in ipairs(list) do
        gen.distance = (gen.position - root.Position).Magnitude
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

-- ===== BAGIAN 12 : AUTO LEAVE & AUTO ATTACK =====

local function EnableLeave()
    if leaveConn then return end
    if not isMobile then
        leaveConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Settings.AutoFeatures.LeaveKeybind then
                EscapeGenerator()
            end
        end)
        Notify("Auto Leave", string.format("Press %s to leave generator", Settings.AutoFeatures.LeaveKeybind.Name), 3)
    else
        Notify("Mobile Mode", "Use the LEAVE button to escape generators", 3)
    end
end

local function DisableLeave()
    if leaveConn then
        leaveConn:Disconnect()
        leaveConn = nil
    end
    Notify("Auto Leave", "Disabled", 2)
end

-- Cari survivor terdekat yang masuk jangkauan serangan (hanya Killer)
local function FindNearestSurvivor()
    if not IsKiller() then return nil, nil end
    local root = GetRoot()
    if not root then return nil, nil end
    local nearest, nearestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local part = player.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local dist = (part.Position - root.Position).Magnitude
                if dist < nearestDist and dist <= Settings.AutoFeatures.AttackRange then
                    nearestDist = dist
                    nearest = player
                end
            end
        end
    end
    return nearest, nearestDist
end

-- Lakukan serangan dasar (fire remote "BasicAttack")
local function DoAttack()
    if not IsKiller() then return end
    local target, _ = FindNearestSurvivor()
    if not target then return end
    local basicAttack = RemoteCache.Get("Attacks", "BasicAttack")
    if basicAttack then
        pcall(function() basicAttack:FireServer(false) end)
    end
end

-- Auto attack pakai scheduler (bukan Heartbeat tiap frame). 0.1 detik = 10 serangan/detik,
-- lebih dari cukup dan jauh lebih ringan daripada FireServer tiap frame.
PerfMgr.Add("autoAttack", 0.1, function()
    if not Settings.AutoFeatures.AutoAttack then return end
    DoAttack()
end)

local function EnableAutoAttack()
    if not IsKiller() then
        Notify("Error", "You must be the Killer to use Auto Attack!", 3)
        return
    end
    if PerfMgr.IsActive("autoAttack") then return end
    PerfMgr.SetActive("autoAttack", true)
    Notify("Auto Attack", string.format("Enabled - Range: %d studs", Settings.AutoFeatures.AttackRange), 3)
end

local function DisableAutoAttack()
    PerfMgr.SetActive("autoAttack", false)
    if autoAttackConn then
        autoAttackConn:Disconnect()
        autoAttackConn = nil
    end
    Notify("Auto Attack", "Disabled", 2)
end

-- ===== BAGIAN 13 : ESP (Highlight + Label) — OPTIMIZED =====
-- Perubahan penting:
--  * Ada MASTER toggle (Settings.ESP.Master). Kalau master OFF, semua ESP mati
--    walaupun sub-toggle (Killer/Survivor/Zombie/dll) masih ON.
--  * Dunia di-scan SEKALI per interval (cache), bukan 7x GetDescendants tiap tick.
--    Ini yang bikin script berat sebelumnya.
--  * Player/Zombie diproses dalam satu pass supaya tidak saling menghapus highlight.

local ESP_SCAN_INTERVAL = (isMobile and 6) or 4   -- detik antar scan berat (world)
local espCache = { Generator = {}, Gate = {}, Hook = {}, Pallet = {}, Window = {}, Pumpkin = {}, Zombie = {} }
local espLastScan = 0
local espDirty = true

local function IsZombieName(name)
    name = tostring(name):lower()
    return (name:find("zomb") ~= nil) or (name:find("infect") ~= nil) or (name:find("undead") ~= nil)
end

-- master gate
local function ESPOn(key)
    if not Settings.ESP.Master then return false end
    if key == nil then return true end
    return Settings.ESP[key] == true
end

local ESP_KEYS = { "Killer", "Survivor", "Zombie", "Generator", "Gate", "Hook", "Pallet", "Window", "Pumpkin" }
local function ESPAnyEnabled()
    for _, k in ipairs(ESP_KEYS) do
        if Settings.ESP[k] then return true end
    end
    return false
end

local function HighlightObj(obj, color)
    if not IsValid(obj) then return end
    local existing = obj:FindFirstChild("H")
    if existing then
        if existing:IsA("Highlight") then
            if existing.FillColor ~= color then existing.FillColor = color end
            if existing.OutlineColor ~= color then existing.OutlineColor = color end
            -- OUTLINE ONLY: badan/objek tidak diisi warna, cuma garis pinggir
            existing.FillTransparency = 1
            existing.OutlineTransparency = 0
            existing.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
        ESPHighlights[obj] = existing
        return
    end
    SafeCall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "H"
        highlight.Adornee = obj
        highlight.FillColor = color
        highlight.OutlineColor = color
        -- OUTLINE ONLY (garis pinggir saja, tanpa isi)
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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
    SafeCall(function()
        if IsValid(obj) then
            local h = obj:FindFirstChild("H")
            if h then h:Destroy() end
        end
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

local function ClearObj(obj)
    Unhighlight(obj)
    Unlabel(obj)
end

local espRoot = nil   -- root pemain, di-cache per tick ESP (hindari FindFirstChild per objek)
local function LabelObj(obj, name, color)
    if not IsValid(obj) then return end
    local root = (espRoot and espRoot.Parent and espRoot) or GetRoot()
    if not root then return end
    local anchorPart = (obj:IsA("BasePart") and obj) or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or nil
    if not anchorPart then return end
    local distance = (root.Position - anchorPart.Position).Magnitude

    -- Culling jarak
    if Settings.Performance.UseDistanceCulling and (distance > Settings.ESP.MaxDistance) then
        Unlabel(obj)
        return
    end

    -- update label yang sudah ada
    local cached = ESPLabels[obj]
    if cached and IsValid(cached) then
        local existing = cached:FindFirstChildWhichIsA("TextLabel")
        if existing then
            existing.Text = (Settings.ESP.ShowDistance and string.format("%s\n%.0fm", name, distance)) or name
            if existing.TextColor3 ~= color then existing.TextColor3 = color end
        end
        return
    end

    SafeCall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPLabel"
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

local function ClearESP()
    for obj in pairs(ESPHighlights) do Unhighlight(obj) end
    for obj in pairs(ESPLabels) do Unlabel(obj) end
    ESPHighlights = {}
    ESPLabels = {}
end

local function ClearESPCategory(key)
    if key == "Killer" or key == "Survivor" or key == "Zombie" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then ClearObj(p.Character) end
        end
    end
    local list = espCache[key]
    if list then
        for _, obj in ipairs(list) do
            ClearObj(obj)
            if obj:IsA("Model") then
                for _, part in ipairs(obj:GetDescendants()) do
                    if ESPHighlights[part] then Unhighlight(part) end
                end
            end
        end
    end
end

-- ---------- WORLD SCAN (satu kali per interval, satu traversal) ----------
local function ScanWorld()
    espLastScan = tick()
    espDirty = false
    for k in pairs(espCache) do espCache[k] = {} end

    local needWorld = ESPOn("Generator") or ESPOn("Gate") or ESPOn("Hook")
        or ESPOn("Pallet") or ESPOn("Window") or ESPOn("Pumpkin") or ESPOn("Zombie")
    if not needWorld then return end

    SafeCall(function()
        local map = Workspace:FindFirstChild("Map")
        local scanRoot = map or Workspace
        for _, obj in ipairs(scanRoot:GetDescendants()) do
            if obj:IsA("Model") then
                local n = obj.Name
                local nLow = nil
                if n == "Generator" then
                    insert(espCache.Generator, obj)
                elseif n == "Gate" then
                    insert(espCache.Gate, obj)
                elseif n == "Hook" then
                    insert(espCache.Hook, obj)
                elseif n == "Palletwrong" or n == "Pallet" then
                    insert(espCache.Pallet, obj)
                elseif n == "Window" then
                    insert(espCache.Window, obj)
                elseif (function()
                        nLow = n:lower()
                        return nLow:find("pumpkin") ~= nil
                    end)() then
                    insert(espCache.Pumpkin, obj)
                elseif IsZombieName(nLow or n) and obj:FindFirstChildOfClass("Humanoid")
                    and not Players:GetPlayerFromCharacter(obj) then
                    insert(espCache.Zombie, obj)
                end
            end
        end
        -- ---- PUMPKIN (diambil dari burner-clean.lua) ----
        -- Pumpkin biasanya ada di dalam folder "Pumpkins", dan kadang cuma
        -- BasePart (bukan Model), jadi dicari khusus supaya pasti ke-ESP.
        if ESPOn("Pumpkin") then
            local seenPumpkin = {}
            for _, obj in ipairs(espCache.Pumpkin) do seenPumpkin[obj] = true end
            local function AddPumpkin(obj)
                if obj and not seenPumpkin[obj] then
                    seenPumpkin[obj] = true
                    insert(espCache.Pumpkin, obj)
                end
            end
            local pumpkinFolders = {}
            local mapFolder = Workspace:FindFirstChild("Map")
            if mapFolder then
                local f = mapFolder:FindFirstChild("Pumpkins")
                if f then insert(pumpkinFolders, f) end
            end
            local rootFolder = Workspace:FindFirstChild("Pumpkins")
            if rootFolder then insert(pumpkinFolders, rootFolder) end
            for _, folder in ipairs(pumpkinFolders) do
                for _, obj in ipairs(folder:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("pumpkin") then
                        AddPumpkin(obj)
                    elseif obj:IsA("BasePart") and obj.Name:lower():find("pumpkin")
                        and not (obj.Parent and obj.Parent:IsA("Model")
                                 and obj.Parent.Name:lower():find("pumpkin")) then
                        AddPumpkin(obj)
                    end
                end
                -- kalau nama anak tidak mengandung "Pumpkin", ambil anak langsungnya
                if #espCache.Pumpkin == 0 then
                    for _, obj in ipairs(folder:GetChildren()) do
                        if obj:IsA("Model") or obj:IsA("BasePart") then AddPumpkin(obj) end
                    end
                end
            end
        end

        -- Window kadang di luar folder Map
        if map then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Model") then
                    if obj.Name == "Window" then insert(espCache.Window, obj)
                    elseif IsZombieName(obj.Name) and obj:FindFirstChildOfClass("Humanoid")
                        and not Players:GetPlayerFromCharacter(obj) then
                        insert(espCache.Zombie, obj)
                    end
                end
            end
        end
    end)
end

-- ---------- PLAYER / ZOMBIE (satu pass) ----------
local function TeamKind(player)
    local teamName = (player.Team and player.Team.Name) or ""
    local low = teamName:lower()
    if IsZombieName(low) or (player.Character and IsZombieName(player.Character.Name)) then return "Zombie" end
    if low:find("killer") then return "Killer" end
    if low:find("surviv") then return "Survivor" end
    return nil
end

local function ESPPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local kind = TeamKind(player)
                if kind and ESPOn(kind) then
                    local color = Settings.ESP.Colors[kind]
                    HighlightObj(char, color)
                    LabelObj(char, player.Name .. "\n[" .. kind:upper() .. "]", color)
                else
                    ClearObj(char)
                end
            end
        end
    end
end

local function ESPZombies()
    if not ESPOn("Zombie") then return end
    local color = Settings.ESP.Colors.Zombie
    for _, obj in ipairs(espCache.Zombie) do
        if IsValid(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                HighlightObj(obj, color)
                LabelObj(obj, "ZOMBIE", color)
            else
                ClearObj(obj)
            end
        end
    end
end

-- ---------- OBJECT ESP (pakai cache) ----------
-- Objek map: HANYA outline pinggir, TANPA nama.
-- Nama hanya untuk player (Killer/Survivor/Zombie) dan Generator.
local function ESPSimple(key, labelText)
    if not ESPOn(key) then return end
    local color = Settings.ESP.Colors[key]
    local showName = (labelText ~= nil)
    for _, obj in ipairs(espCache[key]) do
        if IsValid(obj) then
            HighlightObj(obj, color)
            if showName then LabelObj(obj, labelText, color) else Unlabel(obj) end
        end
    end
end

local function ESPHooks()
    if not ESPOn("Hook") then return end
    local color = Settings.ESP.Colors.Hook
    local list = espCache.Hook
    if Settings.ESP.ShowOnlyClosestHook then
        local root = GetRoot()
        if not root then return end
        local nearest, nearestDist = nil, math.huge
        for _, obj in ipairs(list) do
            local part = IsValid(obj) and obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - root.Position).Magnitude
                if dist < nearestDist then nearestDist = dist; nearest = obj end
            end
        end
        for _, obj in ipairs(list) do
            if obj ~= nearest then ClearObj(obj) end
        end
        if nearest then
            HighlightObj(nearest, color)
            Unlabel(nearest)
        end
    else
        for _, obj in ipairs(list) do
            if IsValid(obj) then
                HighlightObj(obj, color)
                Unlabel(obj)
            end
        end
    end
end

-- Loop ESP utama (dibatasi UpdateRate)
local function ESPTick()
    if not Settings.ESP.Master then return end

    local now = tick()
    if (now - lastUpdate) < Settings.Performance.UpdateRate then return end
    lastUpdate = now
    espRoot = GetRoot()

    local count = 0
    for obj, hl in pairs(ESPHighlights) do
        if not IsValid(obj) or not IsValid(hl) then ESPHighlights[obj] = nil else count = count + 1 end
    end
    for obj in pairs(ESPLabels) do
        if not IsValid(obj) or not IsValid(ESPLabels[obj]) then ESPLabels[obj] = nil end
    end

    if espDirty or (now - espLastScan) >= ESP_SCAN_INTERVAL then ScanWorld() end

    ESPPlayers()
    if count >= Settings.Performance.MaxESPObjects then return end

    ESPZombies()
    ESPSimple("Generator", "GENERATOR")
    ESPSimple("Gate", nil)
    ESPHooks()
    ESPSimple("Pallet", nil)
    ESPSimple("Window", nil)
    ESPSimple("Pumpkin", nil)
end

local function EnableESP(silent)
    if espLoopConn then return end
    espDirty = true
    espLoopConn = RunService.Heartbeat:Connect(ESPTick)
    if not silent then Notify("ESP", "ESP loop aktif", 2) end
end

local function DisableESP(silent)
    if espLoopConn then
        espLoopConn:Disconnect()
        espLoopConn = nil
    end
    ClearESP()
    if not silent then Notify("ESP", "Semua ESP dimatikan", 2) end
end

-- dipanggil setiap kali toggle berubah: loop hanya jalan kalau master ON + ada sub aktif
local function RefreshESP(silent)
    if Settings.ESP.Master and ESPAnyEnabled() then
        espDirty = true
        EnableESP(true)
    else
        DisableESP(true)
    end
    if not silent then end
end

-- ===== ZIAN ESP V3 (dipakai sebagai renderer ESP utama) =====
-- Renderer ini memakai satu folder Highlight/Billboard dan loop ter-throttle,
-- sehingga tidak membuat Billboard baru di dalam setiap karakter/map object.
local ZianESP = {}
do
    local folder, playerJob, worldJob
    local dead = false

    local function alive(x)
        return x and x.Parent ~= nil
    end

    local function rootPart(model)
        if not alive(model) then return nil end
        return model.PrimaryPart
            or model:FindFirstChild("HumanoidRootPart", true)
            or model:FindFirstChild("HitBox", true)
            or model:FindFirstChildWhichIsA("BasePart", true)
    end

    local function getFolder()
        if folder and folder.Parent then return folder end
        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        local old = parent:FindFirstChild("IYAN_VisualESP")
        if old then old:Destroy() end
        folder = Instance.new("Folder")
        folder.Name = "IYAN_VisualESP"
        folder.Parent = parent
        return folder
    end

    local function remove(name)
        local x = getFolder():FindFirstChild(name)
        if x then x:Destroy() end
    end

    local function drawHighlight(name, adornee, color, player)
        if not alive(adornee) then return end
        local f = getFolder()
        local h = f:FindFirstChild(name)
        if not h then
            h = Instance.new("Highlight")
            h.Name = name
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = f
        end
        h.Adornee = adornee
        h.FillColor, h.OutlineColor = color, color
        h.FillTransparency = player and 0.95 or 0.98
        h.OutlineTransparency = player and 0.3 or 0.5
        h.Enabled = true
    end

    local function drawTag(name, part, text, color)
        if not alive(part) or text == "" then remove(name); return end
        local f = getFolder()
        local tag = f:FindFirstChild(name)
        if not tag then
            tag = Instance.new("BillboardGui")
            tag.Name, tag.AlwaysOnTop, tag.LightInfluence = name, true, 0
            tag.Size = UDim2.fromOffset(220, 22)
            tag.Parent = f
            local label = Instance.new("TextLabel")
            label.Name, label.BackgroundTransparency = "Label", 1
            label.Size = UDim2.fromScale(1, 1)
            label.Font, label.TextScaled = Enum.Font.GothamBold, false
            label.TextSize, label.TextStrokeTransparency = 12, 0.55
            label.Parent = tag
        end
        tag.Adornee = part
        local label = tag:FindFirstChild("Label")
        label.Text, label.TextColor3 = text, color
    end

    local function role(p)
        local team = (p.Team and p.Team.Name or ""):lower()
        if team:find("killer") then return "Killer" end
        if team:find("spect") then return "Spectator" end
        return "Survivor"
    end

    local function playerColor(kind)
        return Settings.ESP.Colors[kind] or Color3.new(1, 1, 1)
    end

    local function updatePlayers()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c, kind = p.Character, role(p)
                local enabled = Settings.ESP.Master and Settings.ESP[kind]
                local key = "IYAN_Player_" .. tostring(p.UserId)
                if c and enabled then
                    local part = rootPart(c)
                    local color = playerColor(kind)
                    drawHighlight(key .. "_HL", c, color, true)
                    local text = p.Name .. "\n[" .. kind:upper() .. "]"
                    local mine, theirs = GetRoot(), rootPart(c)
                    if Settings.ESP.ShowDistance and mine and theirs then
                        text = text .. string.format("\n%.0fm", (mine.Position - theirs.Position).Magnitude)
                    end
                    drawTag(key .. "_TAG", part, text, color)
                else
                    remove(key .. "_HL"); remove(key .. "_TAG")
                end
            end
        end
    end

    local function updateWorld()
        local seen = {}
        if not Settings.ESP.Master then return end
        local map = Workspace:FindFirstChild("Map")
        local map1 = Workspace:FindFirstChild("Map1")
        for _, scan in ipairs({ map, map1 }) do
            if scan then
                for _, obj in ipairs(scan:GetDescendants()) do
                    if obj:IsA("Model") then
                        local key, setting, label = nil, nil, nil
                        if obj.Name == "Generator" then key, setting, label = "Generator", "Generator", "GENERATOR"
                        elseif obj.Name == "Gate" then key, setting = "Gate", "Gate"
                        elseif obj.Name == "Hook" then key, setting = "Hook", "Hook"
                        elseif obj.Name == "Palletwrong" or obj.Name == "Pallet" then key, setting = "Pallet", "Pallet"
                        elseif obj.Name == "Window" then key, setting = "Window", "Window" end
                        if key and Settings.ESP[setting] then
                            local part = rootPart(obj)
                            local color = Settings.ESP.Colors[key]
                            local id = obj:GetDebugId()
                            local highlightName = "IYAN_World_" .. key .. "_" .. id
                            local tagName = "IYAN_WorldTag_" .. key .. "_" .. id
                            seen[highlightName], seen[tagName] = true, true
                            drawHighlight(highlightName, obj, color, false)
                            if label then
                                local pct = tonumber(obj:GetAttribute("RepairProgress")) or 0
                                if pct <= 1 then pct = pct * 100 end
                                pct = math.clamp(pct, 0, 100)
                                local repairers = tonumber(obj:GetAttribute("PlayersRepairingCount")) or 0
                                local paused = obj:GetAttribute("ProgressPaused") == true
                                label = string.format("GENERATOR %d%%", pct)
                                if repairers > 0 then label = label .. " (" .. repairers .. "p)" end
                                if paused then label = label .. " [PAUSE]" end
                            end
                            drawTag(tagName, part, label or "", color)
                        end
                    end
                end
            end
        end
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child.Name:sub(1, 11) == "IYAN_World_" or child.Name:sub(1, 14) == "IYAN_WorldTag_" then
                    if not seen[child.Name] then child:Destroy() end
                end
            end
        end
    end

    function ZianESP.Refresh()
        if dead then return end
        updatePlayers()
        updateWorld()
    end
    function ZianESP.Clear()
        if folder then folder:ClearAllChildren() end
    end
    function ZianESP.Enable()
        if playerJob then return end
        dead = false
        playerJob = PerfMgr.Add("zianESPPlayers", 0.25, updatePlayers, true)
        worldJob = PerfMgr.Add("zianESPWorld", 0.5, updateWorld, true)
        ZianESP.Refresh()
    end
    function ZianESP.Disable()
        PerfMgr.SetActive("zianESPPlayers", false)
        PerfMgr.SetActive("zianESPWorld", false)
        playerJob, worldJob = nil, nil
        ZianESP.Clear()
    end
end

-- Semua kontrol ESP lama sekarang mengarah ke renderer Zian v3.
local OldClearESP, OldEnableESP, OldDisableESP = ClearESP, EnableESP, DisableESP
ClearESP = function() ZianESP.Clear(); OldClearESP() end
EnableESP = function(silent) ZianESP.Enable(); if not silent then Notify("ESP", "Zian ESP v3 aktif", 2) end end
DisableESP = function(silent) ZianESP.Disable(); OldDisableESP(true); if not silent then Notify("ESP", "ESP dimatikan", 2) end end
RefreshESP = function(silent)
    if Settings.ESP.Master and ESPAnyEnabled() then EnableESP(true) else DisableESP(true) end
    if not silent then ZianESP.Refresh() end
end

-- ===== BAGIAN 14 : MOBILE CONTROLS & FPS COUNTER =====

local function BuildMobileControls()
    -- Tombol floating LEAVE/TP GEN dihapus: pada Android tombol ini menutup
    -- layar permainan dan menambah GUI instance setiap kali script dijalankan.
    return
    --[[ legacy mobile controls
    if not isMobile then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileControls"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Tombol LEAVE (kabur dari generator)
    local leaveBtn = Instance.new("TextButton")
    leaveBtn.Name = "LeaveGenerator"
    leaveBtn.Size = UDim2.new(0, Settings.Mobile.ButtonSize, 0, Settings.Mobile.ButtonSize)
    leaveBtn.Position = UDim2.new(1, -100, 0.5, -40)
    leaveBtn.BackgroundColor3 = Theme.Accent
    leaveBtn.BackgroundTransparency = Settings.Mobile.ButtonTransparency
    leaveBtn.Text = "LEAVE"
    leaveBtn.TextColor3 = Color3.new(1, 1, 1)
    leaveBtn.TextScaled = true
    leaveBtn.Font = Enum.Font.GothamBold
    leaveBtn.Parent = gui
    AddCorner(leaveBtn, 10)
    leaveBtn.MouseButton1Click:Connect(function() EscapeGenerator() end)

    -- Tombol TP GEN (teleport ke generator terdekat)
    local tpBtn = Instance.new("TextButton")
    tpBtn.Name = "TeleportGen"
    tpBtn.Size = UDim2.new(0, Settings.Mobile.ButtonSize, 0, Settings.Mobile.ButtonSize)
    tpBtn.Position = UDim2.new(1, -100, 0.5, 60)
    tpBtn.BackgroundColor3 = Theme.AccentAlt
    tpBtn.BackgroundTransparency = Settings.Mobile.ButtonTransparency
    tpBtn.Text = "TP GEN"
    tpBtn.TextColor3 = Color3.new(1, 1, 1)
    tpBtn.TextScaled = true
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.Parent = gui
    AddCorner(tpBtn, 10)
    tpBtn.MouseButton1Click:Connect(function()
        local gens = ListGeneratorsSorted()
        if #gens > 0 then
            Teleport(gens[1].part.CFrame)
            Notify("Teleported!", "Moved to closest generator", 2)
        end
    end)

    local ok = pcall(function()
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    if ok then
        Notify("Mobile Controls", "Touch controls enabled!", 3)
    mobileControls = gui
    ]]
end

local function BuildFPSCounter()
    if fpsGui then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "FPSCounter"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 120, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Theme.Surface
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    AddCorner(frame, 8)
    AddStroke(frame, Theme.Accent, 1, 0.5)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "FPS: 0"
    label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.Parent = frame

    -- Drag frame FPS
    local dragging = false
    local lastInput, startPos, startFramePos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startFramePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            lastInput = input
        end
    end)
    ConnMgr.Add("fps", UserInputService.InputChanged:Connect(function(input)
        if input == lastInput and dragging then
            local delta = input.Position - startPos
            frame.Position = UDim2.new(startFramePos.X.Scale, startFramePos.X.Offset + delta.X, startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
        end
    end))

    -- Hitung & tampilkan FPS tiap 1.5 detik
    local lastTime = tick()
    local frameCount = 0
    ConnMgr.Add("fps", RunService.Heartbeat:Connect(function()
        if not fpsActive then return end
        frameCount = frameCount + 1
        local now = tick()
        if (now - lastTime) >= 1.5 then
            local fps = math.floor(frameCount / (now - lastTime))
            frameCount = 0
            lastTime = now
            if fps >= 60 then label.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif fps >= 30 then label.TextColor3 = Color3.fromRGB(255, 255, 0)
            else label.TextColor3 = Color3.fromRGB(255, 0, 0) end
            label.Text = string.format("FPS: %d", fps)
        end
    end))

    pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    fpsGui = gui
    fpsActive = true
    Notify("FPS Counter", "Enabled - Drag to move!", 3)
end

local function DisableFPS()
    fpsActive = false
    ConnMgr.Clear("fps")
    if fpsGui then
        fpsGui:Destroy()
        fpsGui = nil
    end
end


-- ===== BAGIAN 14B : FITUR TAMBAHAN (AIMBOT / PARRY / MOONWALK / PLAYER) =====

local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")
local HttpService         = game:GetService("HttpService")
local Lighting            = game:GetService("Lighting")
local Camera              = Workspace.CurrentCamera

local FeatureGui = Instance.new("ScreenGui")
FeatureGui.Name = "NM_FeatureGui"
FeatureGui.ResetOnSpawn = false
FeatureGui.IgnoreGuiInset = true
FeatureGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SafeCall(function() FeatureGui.Parent = game:GetService("CoreGui") end)
if not FeatureGui.Parent then FeatureGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ---------- AIMBOT ----------
local TARGET_COLORS = {
    Killer   = Color3.fromRGB(255, 60, 60),
    Survivor = Color3.fromRGB(52, 152, 219),
    Zombie   = Color3.fromRGB(46, 204, 113),
}

local AimConfig = {
    AimbotEnabled = false,
    AimVersion    = "V1",          -- V1 = laser saja, V2 = lock kamera
    TargetType    = "Killer",      -- HANYA: Killer / Survivor / Zombie
    SpecificName  = "",
    MaxDistance   = 800,
    Prediction    = true,
    AutoShoot     = true,
    FireDelay     = 0.1,
    LaserEnabled  = true,
    FOVCircleOn   = true,
    FOVRadius     = 180,
}

local CurrentTarget, LastFireTime = nil, 0
local AimStatusLbl, AimTargetLbl = nil, nil

local LaserPart = Instance.new("Part")
LaserPart.Name = "NM_LaserTracer"
LaserPart.Anchored = true
LaserPart.CanCollide = false
LaserPart.CanQuery = false
LaserPart.CanTouch = false
LaserPart.Material = Enum.Material.Neon
LaserPart.Transparency = 1
LaserPart.Parent = Workspace

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVCircle"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, AimConfig.FOVRadius * 2, 0, AimConfig.FOVRadius * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false
FOVFrame.Parent = FeatureGui
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVFrame)
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.8
FOVStroke.Transparency = 0.2

local function ClassifyTarget(char, plr)
    local n = (char and char.Name or ""):lower()
    local t = (plr and plr.Team and plr.Team.Name or ""):lower()
    if n:find("zomb") or n:find("infect") or n:find("undead") or t:find("zomb") then return "Zombie" end
    if n:find("kill") or n:find("monster") or n:find("slasher") or n:find("murder") or t:find("kill") then return "Killer" end
    if plr then return "Survivor" end
    return "Zombie"
end

local function IsAliveChar(char)
    if not char or not char.Parent then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return (h ~= nil) and (h.Health > 0) and (char:FindFirstChild("Head") ~= nil)
end

local function MatchesFilter(p, char, kind)
    if AimConfig.TargetType == "Survivor" and AimConfig.SpecificName ~= "" and p then
        return p.Name:lower() == AimConfig.SpecificName:lower()
    end
    return kind == AimConfig.TargetType
end

local function FindBestTarget()
    local origin = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local function consider(char, plr)
        if not IsAliveChar(char) then return end
        local kind = ClassifyTarget(char, plr)
        if not MatchesFilter(plr, char, kind) then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then return end
        local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if mouseDist > AimConfig.FOVRadius then return end
        local dist = (head.Position - origin).Magnitude
        if dist <= AimConfig.MaxDistance and dist < bestScore then
            best = { player = plr, char = char, kind = kind, name = (plr and plr.Name) or char.Name }
            bestScore = dist
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then consider(p.Character, p) end
    end
    -- NPC (zombie) juga bisa jadi target
    if AimConfig.TargetType == "Zombie" then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                consider(obj, nil)
            end
        end
    end
    return best
end

local function GetPredictPos(char)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    if not AimConfig.Prediction then return head.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity then
        local travelTime = (Camera.CFrame.Position - head.Position).Magnitude / 700
        return head.Position + (hrp.AssemblyLinearVelocity * travelTime)
    end
    return head.Position
end

local function FireWeapon(targetPos)
    local now = tick()
    if (now - LastFireTime) < AimConfig.FireDelay then return end
    LastFireTime = now
    local char = LocalPlayer.Character
    if not char then return end
    local tof = char:FindFirstChild("Twist of Fate")
    local gun = tof and tof:FindFirstChild("Right Arm") and tof["Right Arm"]:FindFirstChild("EmperorGun")
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    remote = remote and remote:FindFirstChild("Items")
    remote = remote and remote:FindFirstChild("Twist of Fate")
    remote = remote and remote:FindFirstChild("Fire")
    if gun and remote then
        local from = (gun:IsA("BasePart") and gun.Position) or Camera.CFrame.Position
        local dir = (targetPos - from).Unit
        pcall(function() remote:FireServer(gun, Vector3.new(dir.X, dir.Y, dir.Z)) end)
    end
end

-- ---------- AUTO PARRY (full) ----------
local ParryConfig = {
    Enabled      = false,
    SafeDistance = 30,
    Radius       = 13,
    Transparency = 0.2,
    Segments     = 80,
}

local ATTACK_IDS = {
    ["118907603246885"] = true, ["78432063483146"]  = true,
    ["110355011987939"] = true, ["139369275981139"] = true,
    ["117042998468241"] = true, ["133963973694098"] = true,
    ["129784271201071"] = true, ["132817836308238"] = true,
    ["135002183282873"] = true, ["121216847022485"] = true,
    ["113255068724446"] = true, ["74968262036854"]  = true,
    ["105374834496520"] = true, ["111920872708571"] = true,
    ["122812055447896"] = true, ["78935059863801"]  = true,
    ["80411309783148"]  = true, ["82666958112273"]  = true,
}

local canParry = true
local ringFolder, ringBalls = nil, {}
local ParryStatusLbl = nil

local function destroyRing()
    if ringFolder then ringFolder:Destroy(); ringFolder = nil end
    ringBalls = {}
end

local function makeRing()
    destroyRing()
    ringFolder = Instance.new("Folder")
    ringFolder.Name = "ParryRing"
    ringFolder.Parent = Workspace
    local circumference = 2 * math.pi * ParryConfig.Radius
    local ballDiameter = circumference / ParryConfig.Segments
    for i = 1, ParryConfig.Segments do
        local angle = (i / ParryConfig.Segments) * math.pi * 2
        local ball = Instance.new("Part")
        ball.Name = "RingBall"
        ball.Parent = ringFolder
        ball.Size = Vector3.new(ballDiameter, 0.2, ballDiameter)
        ball.Shape = Enum.PartType.Ball
        ball.Anchored = true
        ball.CanCollide = false
        ball.CanQuery = false
        ball.CastShadow = false
        ball.Material = Enum.Material.Neon
        ball.Color = Color3.fromRGB(0, 255, 100)
        ball.Transparency = ParryConfig.Transparency
        ringBalls[i] = { part = ball, angle = angle }
    end
end

local function updateRingColor()
    if #ringBalls == 0 then return end
    local color, transp
    if not ParryConfig.Enabled then
        color = Color3.fromRGB(0, 255, 100); transp = 1
    elseif canParry then
        color = Color3.fromRGB(0, 255, 100); transp = ParryConfig.Transparency
    else
        color = Color3.fromRGB(255, 30, 30); transp = math.max(0.05, ParryConfig.Transparency - 0.1)
    end
    for _, b in pairs(ringBalls) do
        if b.part and b.part.Parent then
            b.part.Color = color
            b.part.Transparency = transp
        end
    end
end

local function updateRingPositions()
    if #ringBalls == 0 then return end
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local centerPos = hrp.Position + Vector3.new(0, -2.9, 0)
    for _, b in pairs(ringBalls) do
        if b.part and b.part.Parent then
            local x = math.cos(b.angle) * ParryConfig.Radius
            local z = math.sin(b.angle) * ParryConfig.Radius
            b.part.CFrame = CFrame.new(centerPos + Vector3.new(x, 0, z))
        end
    end
end

local function getParryButton()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil end
    local sm = pGui:FindFirstChild("Survivor-mob")
    if not sm then return nil end
    local ctrl = sm:FindFirstChild("Controls")
    if not ctrl then return nil end
    local btn = ctrl:FindFirstChild("action") or ctrl:FindFirstChild("Gui-mob")
    if btn and btn.Visible then return btn end
    return nil
end

local function tapButton(btn)
    if not btn then return end
    pcall(function() btn.Active = true end)
    local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
    local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
    pcall(function() firetouchinterest(btn, nil, 0) end)
    pcall(function() for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end end)
    pcall(function() for _, c in pairs(getconnections(btn.Activated)) do c:Fire() end end)
    pcall(function() VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
    pcall(function() VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
    pcall(function() firetouchinterest(btn, nil, 1) end)
end

local animatorCache = setmetatable({}, { __mode = "k" })
local function isAttacking(hum)
    if not hum then return false end
    local animator = animatorCache[hum]
    if not (animator and animator.Parent) then
        animator = hum:FindFirstChildOfClass("Animator")
        animatorCache[hum] = animator
    end
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track and track.Animation then
            local id = tostring(track.Animation.AnimationId):match("%d+")
            if id and ATTACK_IDS[id] then return true end
        end
    end
    return false
end

local function scanEnemies()
    if not LocalPlayer.Character then return nil, nil, false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, false end
    local myPos = hrp.Position
    local best, bestDist, attacking = nil, 9999, false
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myPos - v.Character.HumanoidRootPart.Position).Magnitude
            if dist < bestDist then bestDist = dist; best = v end
            if dist <= ParryConfig.Radius then
                local hum = v.Character:FindFirstChildOfClass("Humanoid")
                if isAttacking(hum) then attacking = true end
            end
        end
    end
    return best, bestDist, attacking
end

-- ---------- MOONWALK (jangan diubah) ----------
local MoonwalkConfig = { Enabled = false, SwaySpeed = 15 }
local moonwalkCounter = 0

local function moonwalkLoop(dt)
    if not MoonwalkConfig.Enabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    if not character:FindFirstChild("HumanoidRootPart") then return end
    if not character:FindFirstChildOfClass("Humanoid") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local camLook = Camera.CFrame.LookVector
    local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
    if humanoid.MoveDirection.Magnitude > 0 then
        moonwalkCounter = moonwalkCounter + (dt * MoonwalkConfig.SwaySpeed)
        local swayOffset = math.sin(moonwalkCounter) * 0.4
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatLook) * CFrame.Angles(0, swayOffset + math.rad(180), 0)
    end
end

-- ---------- CAMERA LOCK POV ----------
local CamConfig = { Enabled = false, Height = 10, Distance = 20 }
local camLastDir = Vector3.new(1, 0, 0)

local function camLoop()
    if not CamConfig.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local currentCF = Camera.CFrame
    local rotationOnly = currentCF - currentCF.Position
    local toCam = currentCF.Position - rootPart.Position
    local flatDir = Vector3.new(toCam.X, 0, toCam.Z)
    if flatDir.Magnitude > 0.5 then camLastDir = flatDir.Unit end
    local newPos = rootPart.Position + Vector3.new(camLastDir.X * CamConfig.Distance, CamConfig.Height, camLastDir.Z * CamConfig.Distance)
    Camera.CFrame = CFrame.new(newPos) * rotationOnly
end

-- ---------- SPEED BOOST / UNITY ----------
local SpeedConfig = { Enabled = false, Value = 18, Jump = 50, JumpEnabled = false }
local SyncSpeedJob   -- diisi di bawah (mengaktifkan/mematikan job speed)

-- Job speed/jump: hanya aktif kalau salah satu fitur menyala (lihat SyncSpeedJob).
PerfMgr.Add("speedJump", 0.2, function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if SpeedConfig.Enabled then
        if hum.WalkSpeed ~= SpeedConfig.Value then hum.WalkSpeed = SpeedConfig.Value end
    elseif hum.WalkSpeed ~= 16 then
        hum.WalkSpeed = 16
    end
    if SpeedConfig.JumpEnabled then
        if not hum.UseJumpPower then hum.UseJumpPower = true end
        if hum.JumpPower ~= SpeedConfig.Jump then hum.JumpPower = SpeedConfig.Jump end
    end
end)

SyncSpeedJob = function()
    local need = SpeedConfig.Enabled or SpeedConfig.JumpEnabled
    PerfMgr.SetActive("speedJump", need)
    if not need then
        -- kembalikan WalkSpeed default sekali saja saat fitur dimatikan
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end end) end
    end
end

-- ---------- GOD MODE / NO DAMAGE ----------
local GodConfig = {
    Enabled = false, InfiniteHealth = true, AntiKnock = true,
    AntiStun = true, AutoHeal = true, HealThreshold = 50,
}
local GodHealthConn = nil

local function godDoHeal()
    SafeCall(function()
        local healRemote = RemoteCache.Get("Healing", "HealAnimRec")
        if healRemote then pcall(function() firesignal(healRemote.OnClientEvent, true) end) end
        local collisionRemote = RemoteCache.Get("Collision", "DisableCollision")
        if collisionRemote then pcall(function() firesignal(collisionRemote.OnClientEvent) end) end
    end)
end

local function enableGodMode()
    PerfMgr.SetActive("godMode", true)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if GodConfig.InfiniteHealth then
        if GodHealthConn then GodHealthConn:Disconnect(); GodHealthConn = nil end
        hum.Health = hum.MaxHealth
        GodHealthConn = hum.HealthChanged:Connect(function(newH)
            if hum and GodConfig.Enabled and GodConfig.InfiniteHealth and (newH < hum.MaxHealth) then
                hum.Health = hum.MaxHealth
            end
        end)
    end
end

local function disableGodMode()
    PerfMgr.SetActive("godMode", false)
    if GodHealthConn then GodHealthConn:Disconnect(); GodHealthConn = nil end
end

PerfMgr.Add("godMode", 0.1, function()
    do
        if GodConfig.Enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if GodConfig.InfiniteHealth and (hum.Health < hum.MaxHealth) then hum.Health = hum.MaxHealth end
                if GodConfig.AutoHeal and (hum.Health < GodConfig.HealThreshold) then godDoHeal() end
                if GodConfig.AntiKnock then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local vel = hrp.AssemblyLinearVelocity
                        if vel.Magnitude > 50 then hrp.AssemblyLinearVelocity = vel * 0.5 end
                        if vel.Y < -30 then hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z) end
                    end
                end
                if GodConfig.AntiStun then
                    if hum.PlatformStand then hum.PlatformStand = false end
                    if hum.Sit then hum.Sit = false end
                    if hum:GetState() == Enum.HumanoidStateType.Physics then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            end
        end
    end
end)

-- ---------- FLY ----------
local FlyConfig = { Enabled = false, Speed = 60 }
local flyBV, flyBG, flyConn = nil, nil, nil

local function stopFly()
    FlyConfig.Enabled = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end

local function startFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then Notify("Fly", "Character tidak ditemukan", 3); return end
    stopFly()
    FlyConfig.Enabled = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1e4
    flyBG.CFrame = Camera.CFrame
    flyBG.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not FlyConfig.Enabled then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not flyBV then return end
        flyBG.CFrame = Camera.CFrame
        local dir = Vector3.zero
        if hum and hum.MoveDirection.Magnitude > 0 then
            dir = hum.MoveDirection
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        flyBV.Velocity = (dir.Magnitude > 0 and (dir.Unit * FlyConfig.Speed)) or Vector3.zero
    end)
end

-- ---------- FULL BRIGHT / NO FOG ----------
local FBConfig, FBDefaults, savedEffects = { FullBright = false, NoFog = false }, nil, {}

local function toggleFullBright(on)
    FBConfig.FullBright = on
    if on then
        if not FBDefaults then
            FBDefaults = {
                Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
                GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient,
                Ambient = Lighting.Ambient, ColorShift_Bottom = Lighting.ColorShift_Bottom,
                ColorShift_Top = Lighting.ColorShift_Top, ShadowSoftness = Lighting.ShadowSoftness,
                ExposureCompensation = Lighting.ExposureCompensation,
            }
        end
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e9
        Lighting.FogStart = 1e9
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.ShadowSoftness = 0
        Lighting.ExposureCompensation = 0.5
    elseif FBDefaults then
        for key, value in pairs(FBDefaults) do Lighting[key] = value end
    end
end

local function toggleNoFog(on)
    FBConfig.NoFog = on
    if on then
        Lighting.FogEnd = 1e15
        Lighting.FogStart = 1e15
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("BloomEffect") or v:IsA("BlurEffect")
               or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
                insert(savedEffects, v)
                v.Parent = nil
            end
        end
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
        for _, v in ipairs(savedEffects) do
            if v and (v.Parent == nil) then v.Parent = Lighting end
        end
        savedEffects = {}
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if GodConfig.Enabled then task.wait(1); enableGodMode() end
end)

-- ---------- SHARE SETTING (JSON) ----------
local function ExportConfig()
    local cfg = {
        ESP = {
            Master = Settings.ESP.Master,
            Killer = Settings.ESP.Killer, Survivor = Settings.ESP.Survivor, Zombie = Settings.ESP.Zombie,
            Generator = Settings.ESP.Generator, Gate = Settings.ESP.Gate, Hook = Settings.ESP.Hook,
            Pallet = Settings.ESP.Pallet, Window = Settings.ESP.Window, Pumpkin = Settings.ESP.Pumpkin,
            ShowDistance = Settings.ESP.ShowDistance, MaxDistance = Settings.ESP.MaxDistance,
        },
        Aim = {
            Enabled = AimConfig.AimbotEnabled, Version = AimConfig.AimVersion, Target = AimConfig.TargetType,
            AutoShoot = AimConfig.AutoShoot, FOVRadius = AimConfig.FOVRadius, MaxDistance = AimConfig.MaxDistance,
            Prediction = AimConfig.Prediction, Laser = AimConfig.LaserEnabled, FOVCircle = AimConfig.FOVCircleOn,
        },
        Parry  = { Enabled = ParryConfig.Enabled, Radius = ParryConfig.Radius, SafeDistance = ParryConfig.SafeDistance },
        Player = {
            Speed = SpeedConfig.Enabled, SpeedValue = SpeedConfig.Value,
            Jump = SpeedConfig.JumpEnabled, JumpValue = SpeedConfig.Jump,
            God = GodConfig.Enabled, CamLock = CamConfig.Enabled, Moonwalk = MoonwalkConfig.Enabled,
            Fly = FlyConfig.Enabled, FlySpeed = FlyConfig.Speed,
        },
        Visual = { FullBright = FBConfig.FullBright, NoFog = FBConfig.NoFog },
    }
    local ok, json = pcall(function() return HttpService:JSONEncode(cfg) end)
    return ok and json or nil
end

local function ImportConfig(json)
    local ok, cfg = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(cfg) ~= "table" then
        Notify("Import Gagal", "Format JSON tidak valid", 3)
        return false
    end
    if cfg.ESP then
        for key, value in pairs(cfg.ESP) do
            if Settings.ESP[key] ~= nil then Settings.ESP[key] = value end
        end
        if Settings.ESP.Killer or Settings.ESP.Survivor or Settings.ESP.Zombie then EnableESP() end
    end
    if cfg.Aim then
        AimConfig.AimbotEnabled = cfg.Aim.Enabled and true or false
        AimConfig.AimVersion    = cfg.Aim.Version or AimConfig.AimVersion
        if cfg.Aim.Target == "Killer" or cfg.Aim.Target == "Survivor" or cfg.Aim.Target == "Zombie" then
            AimConfig.TargetType = cfg.Aim.Target
        end
        AimConfig.AutoShoot   = cfg.Aim.AutoShoot and true or false
        AimConfig.FOVRadius   = tonumber(cfg.Aim.FOVRadius) or AimConfig.FOVRadius
        AimConfig.MaxDistance = tonumber(cfg.Aim.MaxDistance) or AimConfig.MaxDistance
        AimConfig.Prediction  = cfg.Aim.Prediction and true or false
        AimConfig.LaserEnabled = cfg.Aim.Laser and true or false
        AimConfig.FOVCircleOn  = cfg.Aim.FOVCircle and true or false
    end
    if cfg.Parry then
        ParryConfig.Radius       = tonumber(cfg.Parry.Radius) or ParryConfig.Radius
        ParryConfig.SafeDistance = tonumber(cfg.Parry.SafeDistance) or ParryConfig.SafeDistance
        ParryConfig.Enabled      = cfg.Parry.Enabled and true or false
        if ParryConfig.Enabled then makeRing() else destroyRing() end
    end
    if cfg.Player then
        SpeedConfig.Enabled     = cfg.Player.Speed and true or false
        SpeedConfig.Value       = tonumber(cfg.Player.SpeedValue) or SpeedConfig.Value
        SpeedConfig.JumpEnabled = cfg.Player.Jump and true or false
        SpeedConfig.Jump        = tonumber(cfg.Player.JumpValue) or SpeedConfig.Jump
        GodConfig.Enabled       = cfg.Player.God and true or false
        if GodConfig.Enabled then enableGodMode() else disableGodMode() end
        CamConfig.Enabled       = cfg.Player.CamLock and true or false
        MoonwalkConfig.Enabled  = cfg.Player.Moonwalk and true or false
        FlyConfig.Speed         = tonumber(cfg.Player.FlySpeed) or FlyConfig.Speed
        if cfg.Player.Fly then startFly() else stopFly() end
        if SyncSpeedJob then SyncSpeedJob() end
    end
    if cfg.Visual then
        toggleFullBright(cfg.Visual.FullBright and true or false)
        toggleNoFog(cfg.Visual.NoFog and true or false)
    end
    Notify("Import Sukses", "Setting pemain diterapkan", 3)
    return true
end

-- ---------- MAIN LOOP (aimbot + parry + moonwalk + camera lock) — OPTIMIZED ----------
-- Tetap satu koneksi RenderStepped, tapi pekerjaan berat di-throttle:
--   * scan musuh untuk parry: 20x/detik (bukan tiap frame)
--   * pencarian target aimbot: ~12x/detik saat belum ada target
--   * update teks status UI: 5x/detik dan hanya kalau teksnya berubah
--   * property UI (Visible/Size/Color) hanya ditulis kalau nilainya berubah
local MainLoopConn = nil

do
local PARRY_SCAN_INTERVAL    = 0.05
local TARGET_SEARCH_INTERVAL = 0.08
local LABEL_UPDATE_INTERVAL  = 0.2

local lastParryScan, lastTargetSearch, lastLabelUpdate = 0, 0, 0
local cachedKiller, cachedDist, cachedAttacking = nil, nil, false
local lastRingState, lastFovVisible, lastFovRadius = nil, nil, -1  -- do-block: variabel bantu loop tidak menambah beban scope utama
local lastAimStatus, lastAimTarget = nil, nil

local function SetAimStatus(text)
    if AimStatusLbl and lastAimStatus ~= text then
        lastAimStatus = text
        AimStatusLbl.Text = text
    end
end

local function SetAimTargetText(text)
    if AimTargetLbl and lastAimTarget ~= text then
        lastAimTarget = text
        AimTargetLbl.Text = text
    end
end

local function MainStep(dt)
    local now = osclock()

    if CamConfig.Enabled then pcall(camLoop) end
    if MoonwalkConfig.Enabled then pcall(moonwalkLoop, dt) end

    if ParryConfig.Enabled then
        updateRingPositions()
        local ringState = (canParry and "ready") or "cooldown"
        if ringState ~= lastRingState then
            lastRingState = ringState
            updateRingColor()
        end

        if (now - lastParryScan) >= PARRY_SCAN_INTERVAL then
            lastParryScan = now
            cachedKiller, cachedDist, cachedAttacking = scanEnemies()
        end

        if cachedKiller and canParry and cachedAttacking then
            local btn = getParryButton()
            if btn then
                tapButton(btn)
                canParry = false
                if ParryStatusLbl then ParryStatusLbl.Text = "Status: 🔴 COOLDOWN" end
            end
        end
        if (not canParry) and cachedDist and (cachedDist >= ParryConfig.SafeDistance) then
            canParry = true
            if ParryStatusLbl then ParryStatusLbl.Text = "Status: 🟢 SIAP" end
        end
    elseif lastRingState ~= nil then
        lastRingState = nil
        updateRingColor()
    end

    local fovVisible = AimConfig.AimbotEnabled and AimConfig.FOVCircleOn
    if fovVisible ~= lastFovVisible then
        lastFovVisible = fovVisible
        FOVFrame.Visible = fovVisible
    end
    if fovVisible and (AimConfig.FOVRadius ~= lastFovRadius) then
        lastFovRadius = AimConfig.FOVRadius
        FOVFrame.Size = UDim2.new(0, AimConfig.FOVRadius * 2, 0, AimConfig.FOVRadius * 2)
    end

    if not AimConfig.AimbotEnabled then
        if LaserPart.Transparency ~= 1 then LaserPart.Transparency = 1 end
        if (now - lastLabelUpdate) >= LABEL_UPDATE_INTERVAL then
            lastLabelUpdate = now
            SetAimStatus("Status: Mati")
        end
        return
    end

    if not (CurrentTarget and IsAliveChar(CurrentTarget.char)
            and MatchesFilter(CurrentTarget.player, CurrentTarget.char, CurrentTarget.kind)) then
        CurrentTarget = nil
        if (now - lastTargetSearch) >= TARGET_SEARCH_INTERVAL then
            lastTargetSearch = now
            CurrentTarget = FindBestTarget()
        end
    end

    if CurrentTarget then
        local pos = GetPredictPos(CurrentTarget.char)
        if pos then
            if AimConfig.LaserEnabled then
                local tof = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Twist of Fate")
                local gun = tof and tof:FindFirstChild("Right Arm") and tof["Right Arm"]:FindFirstChild("EmperorGun")
                local from = (gun and gun:IsA("BasePart") and gun.Position) or Camera.CFrame.Position
                local length = (pos - from).Magnitude
                local color = TARGET_COLORS[CurrentTarget.kind] or Color3.fromRGB(255, 255, 255)
                if LaserPart.Transparency ~= 0.25 then LaserPart.Transparency = 0.25 end
                if LaserPart.Color ~= color then LaserPart.Color = color end
                LaserPart.CFrame = CFrame.lookAt(from, pos) * CFrame.new(0, 0, -length / 2)
                LaserPart.Size = Vector3.new(0.08, 0.08, length)
            elseif LaserPart.Transparency ~= 1 then
                LaserPart.Transparency = 1
            end
            if AimConfig.AimVersion == "V2" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, pos)
            end
            if AimConfig.AutoShoot then FireWeapon(pos) end
            if (now - lastLabelUpdate) >= LABEL_UPDATE_INTERVAL then
                lastLabelUpdate = now
                SetAimStatus("Status: LOCK ON 🔒")
                SetAimTargetText("Target: " .. CurrentTarget.name .. " (" .. CurrentTarget.kind .. ")")
            end
        end
    else
        if LaserPart.Transparency ~= 1 then LaserPart.Transparency = 1 end
        if (now - lastLabelUpdate) >= LABEL_UPDATE_INTERVAL then
            lastLabelUpdate = now
            SetAimStatus("Status: mencari...")
            SetAimTargetText("Target: -")
        end
    end
end

-- Loop utama TIDUR total kalau semua fitur realtime OFF.
-- Hemat CPU besar saat script cuma dibuka tanpa fitur aktif.
local function mainLoopNeeded()
    return (CamConfig and CamConfig.Enabled)
        or (MoonwalkConfig and MoonwalkConfig.Enabled)
        or (ParryConfig and ParryConfig.Enabled)
        or (AimConfig and AimConfig.AimbotEnabled)
end

local function syncMainLoop()
    local need = mainLoopNeeded()
    if need and not MainLoopConn then
        MainLoopConn = RunService.RenderStepped:Connect(MainStep)
    elseif (not need) and MainLoopConn then
        MainLoopConn:Disconnect()
        MainLoopConn = nil
        pcall(function()
            if FOVFrame then FOVFrame.Visible = false end
            if LaserPart then LaserPart.Transparency = 1 end
        end)
        lastFovVisible, lastRingState = nil, nil
        SetAimStatus("Status: Mati")
    end
end

-- pengecekan ringan 4x/detik lewat scheduler bersama (bukan tiap frame)
PerfMgr.Add("mainLoopWatch", 0.25, syncMainLoop, true)
syncMainLoop()
end



-- ===== BAGIAN B : MEMBANGUN INTERFACE (FLUENT) =====

Breathe(0.004)
local Tabs = {
    Info     = Window:AddTab({ Title = "Info",     Icon = "info" }),
    Killer   = Window:AddTab({ Title = "Killer",   Icon = "skull" }),
    Aimbot   = Window:AddTab({ Title = "Aimbot",   Icon = "crosshair" }),
    Parry    = Window:AddTab({ Title = "Parry & Moonwalk", Icon = "swords" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    ESP      = Window:AddTab({ Title = "ESP",      Icon = "eye" }),
    Gameplay = Window:AddTab({ Title = "Gameplay", Icon = "gamepad-2" }),
    Player   = Window:AddTab({ Title = "Player",   Icon = "user" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Config   = Window:AddTab({ Title = "Config",   Icon = "save" }),
}

-- ---------- TAB : KILLER (placeholder) ----------
Breathe()
Tabs.Killer:AddSection("KILLER")
Breathe()
Tabs.Killer:AddParagraph({
    Title = "Coming Soon",
    Content = "Menu khusus Killer masih kosong. Fitur akan ditambahkan di update berikutnya.",
})

-- ---------- TAB : INFO ----------
Breathe()
Tabs.Info:AddParagraph({
    Title = "NO MERCY HUB v3",
    Content = "Created by Sobing4413\nGame: Violence District\nPlatform: " .. ((isMobile and "Mobile") or "PC") .. "\nExecutor: " .. executorName,
})
Breathe()
Tabs.Info:AddParagraph({
    Title = "Discord",
    Content = "discord.gg/CnNqEVFxh6 — update, support & request fitur.",
})
Tabs.Info:AddButton({
    Title = "Copy Discord Invite",
    Description = "Salin link discord ke clipboard",
    Callback = function()
        local ok = pcall(function() setclipboard("https://discord.gg/CnNqEVFxh6") end)
        Notify("Discord", (ok and "Link tersalin!") or "discord.gg/CnNqEVFxh6", 4)
    end,
})
Breathe()
Tabs.Info:AddParagraph({
    Title = "Fitur",
    Content = "• Aimbot & Auto Parry\n• ESP pemain & objek\n• Menu Teleport lengkap\n• Auto generator & auto attack\n• Fly / God Mode / Speed\n• Performance booster & mobile control",
})

-- ---------- TAB : AIMBOT ----------
Tabs.Aimbot:AddToggle("AimEnabled", { Title = "Enable Aim Lock", Default = false }):OnChanged(function(value)
    AimConfig.AimbotEnabled = value
    Notify("Aimbot", (value and "Aktif") or "Mati", 2)
end)
Tabs.Aimbot:AddToggle("AimAutoShoot", { Title = "Auto Shoot Target", Default = true }):OnChanged(function(value)
    AimConfig.AutoShoot = value
end)
Tabs.Aimbot:AddDropdown("AimMode", {
    Title = "Mode Aimbot", Values = { "V1 (Laser)", "V2 (Lock Kamera)" }, Default = 1,
}):OnChanged(function(value)
    AimConfig.AimVersion = (value == "V2 (Lock Kamera)") and "V2" or "V1"
end)
Tabs.Aimbot:AddDropdown("AimTarget", {
    Title = "Pilih Target", Values = { "Killer", "Survivor", "Zombie" }, Default = 1,
}):OnChanged(function(value)
    AimConfig.TargetType = value
    CurrentTarget = nil
    Notify("Target", "Target: " .. tostring(value), 2)
end)
Tabs.Aimbot:AddInput("AimName", {
    Title = "Nama Spesifik", Placeholder = "kosongkan = semua", Default = "",
    Callback = function(text)
        AimConfig.SpecificName = text or ""
        CurrentTarget = nil
    end,
})
AimStatusLbl = CreateStatus(Tabs.Aimbot, "Status Aimbot", "Mati")
AimTargetLbl = CreateStatus(Tabs.Aimbot, "Target Terkunci", "-")

Tabs.Aimbot:AddToggle("AimPrediction", { Title = "Prediksi Gerakan", Default = true }):OnChanged(function(v) AimConfig.Prediction = v end)
Tabs.Aimbot:AddToggle("AimLaser", { Title = "Laser Tracer", Default = true }):OnChanged(function(v) AimConfig.LaserEnabled = v end)
Tabs.Aimbot:AddToggle("AimFOVCircle", { Title = "Lingkaran FOV", Default = true }):OnChanged(function(v) AimConfig.FOVCircleOn = v end)
Tabs.Aimbot:AddSlider("AimFOV", { Title = "FOV Radius", Default = 180, Min = 50, Max = 600, Rounding = 0,
    Callback = function(v) AimConfig.FOVRadius = v end })
Tabs.Aimbot:AddSlider("AimMaxDist", { Title = "Jarak Maksimal", Default = 800, Min = 100, Max = 2000, Rounding = 0,
    Callback = function(v) AimConfig.MaxDistance = v end })
Tabs.Aimbot:AddSlider("AimFireDelay", { Title = "Delay Tembak (detik)", Default = 0.1, Min = 0.05, Max = 1, Rounding = 2,
    Callback = function(v) AimConfig.FireDelay = v end })

-- ---------- TAB : AUTO PARRY ----------
Tabs.Parry:AddToggle("ParryEnabled", { Title = "Enable Auto Parry", Default = false }):OnChanged(function(value)
    ParryConfig.Enabled = value
    if value then makeRing() else destroyRing() end
    Notify("Auto Parry", (value and "Aktif") or "Mati", 2)
end)
ParryStatusLbl = CreateStatus(Tabs.Parry, "Status Parry", "🟢 SIAP")
Tabs.Parry:AddSlider("ParryRadius", { Title = "Radius Ring", Default = 13, Min = 5, Max = 40, Rounding = 0,
    Callback = function(v) ParryConfig.Radius = v; if ParryConfig.Enabled then makeRing() end end })
Tabs.Parry:AddSlider("ParrySafe", { Title = "Jarak Aman (reset)", Default = 30, Min = 10, Max = 80, Rounding = 0,
    Callback = function(v) ParryConfig.SafeDistance = v end })
Tabs.Parry:AddSlider("ParryTrans", { Title = "Transparansi Ring", Default = 0.2, Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) ParryConfig.Transparency = v; updateRingColor() end })
Tabs.Parry:AddSlider("ParrySegments", { Title = "Jumlah Bola Ring", Default = 80, Min = 20, Max = 120, Rounding = 0,
    Callback = function(v) ParryConfig.Segments = v; if ParryConfig.Enabled then makeRing() end end })
Tabs.Parry:AddButton({
    Title = "Reset Cooldown Parry",
    Callback = function()
        canParry = true
        if ParryStatusLbl then ParryStatusLbl.Text = "🟢 SIAP" end
        Notify("Auto Parry", "Cooldown direset", 2)
    end,
})

-- ---------- MOONWALK (digabung dengan Parry) ----------
Breathe()
Tabs.Parry:AddSection("MOONWALK")

-- Jendela kecil (bubble) pintas ON/OFF moonwalk
local MoonBubbleGui, MoonBubbleBtn
local MoonwalkToggleRef
local function SetMoonwalkBubble(visible)
    if visible and not MoonBubbleGui then
        MoonBubbleGui = Instance.new("ScreenGui")
        MoonBubbleGui.Name = "NoMercyMoonwalkBubble"
        MoonBubbleGui.ResetOnSpawn = false
        MoonBubbleGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 132, 0, 56)
        frame.Position = UDim2.new(0.02, 0, 0.4, 0)
        frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = MoonBubbleGui
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 10); fc.Parent = frame
        local fs = Instance.new("UIStroke"); fs.Color = Color3.fromRGB(60, 70, 90); fs.Thickness = 2; fs.Parent = frame

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, 0, 0, 20)
        title.Text = "MOONWALK"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextColor3 = Color3.fromRGB(200, 210, 230)
        title.Parent = frame

        MoonBubbleBtn = Instance.new("TextButton")
        MoonBubbleBtn.Size = UDim2.new(1, -16, 0, 26)
        MoonBubbleBtn.Position = UDim2.new(0, 8, 0, 22)
        MoonBubbleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
        MoonBubbleBtn.Text = "ON"
        MoonBubbleBtn.Font = Enum.Font.GothamBold
        MoonBubbleBtn.TextSize = 14
        MoonBubbleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MoonBubbleBtn.AutoButtonColor = true
        MoonBubbleBtn.Parent = frame
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = MoonBubbleBtn

        MoonBubbleBtn.MouseButton1Click:Connect(function()
            MoonwalkConfig.Enabled = not MoonwalkConfig.Enabled
            if MoonBubbleBtn then
                MoonBubbleBtn.Text = (MoonwalkConfig.Enabled and "ON") or "OFF"
                MoonBubbleBtn.BackgroundColor3 = (MoonwalkConfig.Enabled and Color3.fromRGB(0, 170, 90))
                    or Color3.fromRGB(120, 40, 40)
            end
        end)
    end
    if MoonBubbleGui then
        MoonBubbleGui.Enabled = visible and true or false
        if MoonBubbleBtn then
            MoonBubbleBtn.Text = (MoonwalkConfig.Enabled and "ON") or "OFF"
            MoonBubbleBtn.BackgroundColor3 = (MoonwalkConfig.Enabled and Color3.fromRGB(0, 170, 90))
                or Color3.fromRGB(120, 40, 40)
        end
    end
end

MoonwalkToggleRef = Tabs.Parry:AddToggle("Moonwalk", { Title = "Moonwalk", Default = false })
MoonwalkToggleRef:OnChanged(function(value)
    MoonwalkConfig.Enabled = value
    SetMoonwalkBubble(value)
    Notify("Moonwalk", (value and "Aktif + pintas bubble muncul") or "Mati", 2)
end)
Tabs.Parry:AddSlider("MoonwalkSway", { Title = "Kecepatan Sway Moonwalk", Default = 15, Min = 5, Max = 40, Rounding = 0,
    Callback = function(v) MoonwalkConfig.SwaySpeed = v end })
Breathe()
Tabs.Parry:AddParagraph({
    Title = "Pintas Moonwalk",
    Content = "Kalau Moonwalk diaktifkan, muncul jendela kecil ON/OFF yang bisa digeser buat hidup-matiin moonwalk cepat.",
})

-- ---------- TAB : TELEPORT (MENU LENGKAP) ----------

-- Helper umum: kumpulkan model dengan nama tertentu di Map
local function ListObjectsByName(objectName)
    local list = {}
    local root = GetRoot()
    local rootPos = root and root.Position
    for _, obj in ipairs(MapCache.Models(objectName)) do
        local part = MapCache.Anchor(obj)
        if part then
            insert(list, {
                model = obj,
                part = part,
                position = part.Position,
                distance = (rootPos and (part.Position - rootPos).Magnitude) or 0,
            })
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

local function TeleportToNearest(objectName, label)
    local list = ListObjectsByName(objectName)
    if #list == 0 then Notify("Tidak Ada", "Tidak menemukan " .. label, 3); return end
    if Teleport(list[1].part.CFrame) then
        Notify("Teleported", string.format("%s terdekat (%.0fm)", label, list[1].distance), 3)
    end
end

Breathe()
Tabs.Teleport:AddSection("GENERATOR")
Tabs.Teleport:AddButton({
    Title = "TP ke Generator Terdekat",
    Callback = function()
        local gens = ListGeneratorsSorted()
        if #gens == 0 then Notify("Tidak Ada", "Generator tidak ditemukan", 3); return end
        if Teleport(gens[1].part.CFrame) then
            Notify("Teleported", string.format("Generator terdekat (%.0fm)", gens[1].distance), 3)
        end
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Generator Terjauh",
    Callback = function()
        local gens = ListGeneratorsSorted()
        if #gens == 0 then Notify("Tidak Ada", "Generator tidak ditemukan", 3); return end
        local far = gens[#gens]
        if Teleport(far.part.CFrame) then
            Notify("Teleported", string.format("Generator terjauh (%.0fm)", far.distance), 3)
        end
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP Keliling Semua Generator",
    Callback = function()
        local gens = ListGeneratorsSorted()
        if #gens == 0 then Notify("Tidak Ada", "Generator tidak ditemukan", 3); return end
        Notify("Mulai", string.format("Keliling %d generator...", #gens), 3)
        task.spawn(function()
            for i, gen in ipairs(gens) do
                if not GetRoot() then break end
                Teleport(gen.part.CFrame)
                task.wait(Settings.Teleportation.TeleportDelay)
            end
            Notify("Selesai", "Semua generator dikunjungi", 3)
        end)
    end,
})

-- Dropdown generator: pilih generator ke berapa lalu TP
local generatorChoices = {}
local GeneratorDropdown = Tabs.Teleport:AddDropdown("TPGeneratorPick", {
    Title = "Pilih Generator",
    Description = "Tekan Refresh dulu untuk memuat daftar",
    Values = { "-" },
    Default = 1,
})
Tabs.Teleport:AddButton({
    Title = "Refresh Daftar Generator",
    Callback = function()
        local gens = ListGeneratorsSorted()
        generatorChoices = {}
        local names = {}
        for i, gen in ipairs(gens) do
            local label = string.format("#%d - %.0fm", i, gen.distance)
            insert(names, label)
            generatorChoices[label] = gen
        end
        if #names == 0 then names = { "-" } end
        GeneratorDropdown:SetValues(names)
        Notify("Generator", string.format("%d generator ditemukan", #gens), 3)
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Generator Terpilih",
    Callback = function()
        local pick = generatorChoices[GeneratorDropdown.Value]
        if not pick then Notify("Teleport", "Pilih generator dulu (Refresh)", 3); return end
        Teleport(pick.part.CFrame)
        Notify("Teleported", "Menuju generator terpilih", 2)
    end,
})
Tabs.Teleport:AddButton({
    Title = "Kabur dari Generator",
    Callback = function() EscapeGenerator() end,
})

Breathe()
Tabs.Teleport:AddSection("OBJEK MAP")
Tabs.Teleport:AddButton({ Title = "TP ke Gate Terdekat",   Callback = function() TeleportToNearest("Gate", "Gate") end })
Tabs.Teleport:AddButton({ Title = "TP ke Hook Terdekat",   Callback = function() TeleportToNearest("Hook", "Hook") end })
Tabs.Teleport:AddButton({ Title = "TP ke Pallet Terdekat", Callback = function() TeleportToNearest("Pallet", "Pallet") end })
Tabs.Teleport:AddButton({ Title = "TP ke Window Terdekat", Callback = function() TeleportToNearest("Window", "Window") end })
Tabs.Teleport:AddButton({ Title = "TP ke Pumpkin Terdekat", Callback = function() TeleportToNearest("Pumpkin", "Pumpkin") end })

Breathe()
Tabs.Teleport:AddSection("PEMAIN")
local PlayerDropdown = Tabs.Teleport:AddDropdown("TPPlayerPick", {
    Title = "Pilih Pemain",
    Values = { "-" },
    Default = 1,
})
local function RefreshPlayerList()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then insert(names, plr.Name) end
    end
    if #names == 0 then names = { "-" } end
    PlayerDropdown:SetValues(names)
    return #names
end
RefreshPlayerList()
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function() task.defer(RefreshPlayerList) end)

Tabs.Teleport:AddButton({
    Title = "Refresh Daftar Pemain",
    Callback = function() Notify("Pemain", RefreshPlayerList() .. " pemain online", 2) end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Pemain Terpilih",
    Callback = function()
        local target = Players:FindFirstChild(tostring(PlayerDropdown.Value))
        if not target or not target.Character then Notify("Teleport", "Pemain tidak ditemukan", 3); return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then Notify("Teleport", "Karakter belum spawn", 3); return end
        Teleport(hrp.CFrame * CFrame.new(0, 0, 3))
        Notify("Teleported", "Menuju " .. target.Name, 2)
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Killer Terdekat",
    Callback = function()
        local root = GetRoot()
        if not root then Notify("Error", "Karakter tidak ada", 3); return end
        local nearest, dist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Killer" and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < dist then nearest, dist = hrp, d end
                end
            end
        end
        if nearest then
            Teleport(nearest.CFrame * CFrame.new(0, 0, 5))
            Notify("Teleported", string.format("Killer (%.0fm)", dist), 3)
        else
            Notify("Tidak Ada", "Killer tidak ditemukan", 3)
        end
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Survivor Terdekat",
    Callback = function()
        local root = GetRoot()
        if not root then Notify("Error", "Karakter tidak ada", 3); return end
        local nearest, dist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Survivors" and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < dist then nearest, dist = hrp, d end
                end
            end
        end
        if nearest then
            Teleport(nearest.CFrame * CFrame.new(0, 0, 3))
            Notify("Teleported", string.format("Survivor (%.0fm)", dist), 3)
        else
            Notify("Tidak Ada", "Survivor tidak ditemukan", 3)
        end
    end,
})

Breathe()
Tabs.Teleport:AddSection("WAYPOINT & MANUAL")
local savedWaypoints = {}
local WaypointDropdown = Tabs.Teleport:AddDropdown("TPWaypointPick", {
    Title = "Waypoint Tersimpan", Values = { "-" }, Default = 1,
})
local waypointNameInput = ""
Tabs.Teleport:AddInput("TPWaypointName", {
    Title = "Nama Waypoint", Placeholder = "misal: basement", Default = "",
    Callback = function(text) waypointNameInput = text or "" end,
})
local function RefreshWaypoints()
    local names = {}
    for name in pairs(savedWaypoints) do insert(names, name) end
    table.sort(names)
    if #names == 0 then names = { "-" } end
    WaypointDropdown:SetValues(names)
end
Tabs.Teleport:AddButton({
    Title = "Simpan Posisi Sekarang",
    Callback = function()
        local root = GetRoot()
        if not root then Notify("Error", "Karakter tidak ada", 3); return end
        local name = (waypointNameInput ~= "" and waypointNameInput) or ("Waypoint " .. tostring(#savedWaypoints + 1) .. os.date("%H%M%S"))
        savedWaypoints[name] = root.CFrame
        RefreshWaypoints()
        Notify("Waypoint", "Tersimpan: " .. name, 3)
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Waypoint Terpilih",
    Callback = function()
        local cf = savedWaypoints[tostring(WaypointDropdown.Value)]
        if not cf then Notify("Waypoint", "Belum ada waypoint terpilih", 3); return end
        Teleport(cf, Vector3.new(0, 1, 0))
        Notify("Teleported", "Menuju " .. tostring(WaypointDropdown.Value), 2)
    end,
})
Tabs.Teleport:AddButton({
    Title = "Hapus Waypoint Terpilih",
    Callback = function()
        local key = tostring(WaypointDropdown.Value)
        if savedWaypoints[key] then
            savedWaypoints[key] = nil
            RefreshWaypoints()
            Notify("Waypoint", "Dihapus: " .. key, 2)
        end
    end,
})
local manualX, manualY, manualZ = 0, 0, 0
Tabs.Teleport:AddInput("TPManualCoords", {
    Title = "Koordinat Manual (X,Y,Z)", Placeholder = "contoh: 100, 25, -300", Default = "",
    Callback = function(text)
        local x, y, z = tostring(text):match("(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)")
        if x then manualX, manualY, manualZ = tonumber(x), tonumber(y), tonumber(z) end
    end,
})
Tabs.Teleport:AddButton({
    Title = "TP ke Koordinat Manual",
    Callback = function()
        Teleport(CFrame.new(manualX, manualY, manualZ), Vector3.new(0, 0, 0))
        Notify("Teleported", string.format("(%.0f, %.0f, %.0f)", manualX, manualY, manualZ), 3)
    end,
})
Tabs.Teleport:AddButton({
    Title = "Copy Posisi Sekarang",
    Callback = function()
        local root = GetRoot()
        if not root then Notify("Error", "Karakter tidak ada", 3); return end
        local p = root.Position
        local text = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        pcall(function() setclipboard(text) end)
        Notify("Posisi", text, 4)
    end,
})

Breathe()
Tabs.Teleport:AddSection("SURVIVOR WIN")
Tabs.Teleport:AddButton({
    Title = "Escape Game (Survivor Only)",
    Callback = function()
        if not IsSurvivor() then Notify("Error", "Kamu harus jadi Survivor!", 3); return end
        local root = GetRoot()
        if not root then Notify("Error", "Karakter tidak ada", 3); return end
        local map = MapCache.GetMap()
        if not map then Notify("Error", "Map tidak ditemukan", 3); return end
        local gate = MapCache.Models("Gate")[1]
        if not gate then Notify("Error", "Gate tidak ditemukan", 3); return end
        local escapeZone = gate:FindFirstChild("Escape") or gate:FindFirstChildWhichIsA("BasePart")
        if escapeZone then
            Teleport(escapeZone.CFrame, Vector3.new(0, 5, 0))
            task.wait(0.5)
            SafeCall(function()
                local escape = RemoteCache.Get("Gate", "Escape")
                if escape then escape:FireServer() end
            end)
            Notify("Escape!", "Teleport ke pintu keluar - jalan terus!", 4)
        else
            Notify("Error", "Zona escape tidak ditemukan", 3)
        end
    end,
})

Breathe()
Tabs.Teleport:AddSection("PENGATURAN TELEPORT")
Tabs.Teleport:AddSlider("TPOffset", { Title = "Teleport Height Offset", Default = 3, Min = 0, Max = 10, Rounding = 0,
    Callback = function(v) Settings.Teleportation.TeleportOffset = v end })
Tabs.Teleport:AddSlider("TPDelay", { Title = "Multi-Teleport Delay (detik)", Default = 0.1, Min = 0.1, Max = 5, Rounding = 2,
    Callback = function(v) Settings.Teleportation.TeleportDelay = v end })
Tabs.Teleport:AddToggle("TPSafe", { Title = "Safe Teleport (No Collision)", Default = true }):OnChanged(function(v)
    Settings.Teleportation.SafeTeleport = v
end)

-- ---------- TAB : ESP ----------
Breathe()
Tabs.ESP:AddSection("MASTER ESP")
Breathe()
Tabs.ESP:AddParagraph({ Title = "Cara pakai", Content = "Master ESP wajib ON. Kalau Master OFF, semua ESP (Killer / Survivor / Zombie / Object) tetap MATI walau toggle-nya masih hidup." })
Tabs.ESP:AddToggle("ESPMaster", { Title = "Enable ESP (Master ON/OFF)", Default = false }):OnChanged(function(value)
    Settings.ESP.Master = value
    if value then
        if ESPAnyEnabled() then
            RefreshESP(true)
            Notify("ESP", "Master ESP ON", 2)
        else
            Notify("ESP", "Master ON — nyalakan minimal 1 toggle ESP di bawah", 3)
        end
    else
        DisableESP(true)
        Notify("ESP", "Master ESP OFF — semua ESP dimatikan", 2)
    end
end)

Breathe()
Tabs.ESP:AddSection("PLAYER / NPC ESP")
Tabs.ESP:AddToggle("ESPKiller", { Title = "Killer ESP", Default = false }):OnChanged(function(value)
    Settings.ESP.Killer = value
    if not value then ClearESPCategory("Killer") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPSurvivor", { Title = "Survivor ESP", Default = false }):OnChanged(function(value)
    Settings.ESP.Survivor = value
    if not value then ClearESPCategory("Survivor") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPZombie", { Title = "Zombie ESP (Player + NPC)", Default = false }):OnChanged(function(value)
    Settings.ESP.Zombie = value
    if not value then ClearESPCategory("Zombie") end
    RefreshESP()
end)

Breathe()
Tabs.ESP:AddSection("WARNA ESP")
local ESP_COLOR_CATEGORIES = { "Killer", "Survivor", "Zombie", "Generator", "Gate", "Hook", "Pallet", "Window", "Pumpkin" }
local ESP_COLOR_LIST = {
    { Name = "Merah",   Color = Color3.fromRGB(255, 0, 0) },
    { Name = "Hijau",   Color = Color3.fromRGB(0, 255, 0) },
    { Name = "Biru",    Color = Color3.fromRGB(0, 120, 255) },
    { Name = "Kuning",  Color = Color3.fromRGB(255, 255, 0) },
    { Name = "Ungu",    Color = Color3.fromRGB(128, 0, 255) },
    { Name = "Orange",  Color = Color3.fromRGB(255, 128, 0) },
    { Name = "Pink",    Color = Color3.fromRGB(255, 105, 180) },
    { Name = "Putih",   Color = Color3.fromRGB(255, 255, 255) },
    { Name = "Cyan",    Color = Color3.fromRGB(0, 255, 255) },
    { Name = "Magenta", Color = Color3.fromRGB(255, 0, 255) },
}
local espColorCategory = "Killer"
local espColorNames = {}
for _, entry in ipairs(ESP_COLOR_LIST) do insert(espColorNames, entry.Name) end

Tabs.ESP:AddDropdown("ESPColorCategory", { Title = "Kategori", Values = ESP_COLOR_CATEGORIES, Default = 1 })
    :OnChanged(function(value) espColorCategory = value end)
Tabs.ESP:AddDropdown("ESPColorValue", { Title = "Warna", Values = espColorNames, Default = 1 })
    :OnChanged(function(value)
        for _, entry in ipairs(ESP_COLOR_LIST) do
            if entry.Name == value then
                Settings.ESP.Colors[espColorCategory] = entry.Color
                ClearESP()
                Notify("Warna ESP", espColorCategory .. " => " .. value, 2)
                break
            end
        end
    end)

Breathe()
Tabs.ESP:AddSection("OBJECT ESP")
Tabs.ESP:AddToggle("ESPGenerator", { Title = "Generator ESP", Default = false }):OnChanged(function(v)
    Settings.ESP.Generator = v
    if not v then ClearESPCategory("Generator") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPGate", { Title = "Gate ESP", Default = false }):OnChanged(function(v)
    Settings.ESP.Gate = v
    if not v then ClearESPCategory("Gate") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPHook", { Title = "Hook ESP", Default = false }):OnChanged(function(v)
    Settings.ESP.Hook = v
    if not v then ClearESPCategory("Hook") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPClosestHook", { Title = "Show Only Closest Hook", Default = false }):OnChanged(function(v)
    Settings.ESP.ShowOnlyClosestHook = v
    ClearESPCategory("Hook")
    if ESPOn("Hook") then ESPHooks() end
end)
Tabs.ESP:AddToggle("ESPPallet", { Title = "Pallet ESP", Default = false }):OnChanged(function(v)
    Settings.ESP.Pallet = v
    if not v then ClearESPCategory("Pallet") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPWindow", { Title = "Window ESP", Default = false }):OnChanged(function(v)
    Settings.ESP.Window = v
    if not v then ClearESPCategory("Window") end
    RefreshESP()
end)
Tabs.ESP:AddToggle("ESPPumpkin", { Title = "Pumpkin ESP", Default = false }):OnChanged(function(v)
    Settings.ESP.Pumpkin = v
    if not v then ClearESPCategory("Pumpkin") end
    RefreshESP()
end)

Breathe()
Tabs.ESP:AddSection("ESP SETTINGS")
Tabs.ESP:AddToggle("ESPDistance", { Title = "Show Distance", Default = true }):OnChanged(function(v) Settings.ESP.ShowDistance = v end)
Tabs.ESP:AddSlider("ESPMaxDist", { Title = "Max Distance", Default = 500, Min = 100, Max = 1000, Rounding = 0,
    Callback = function(v) Settings.ESP.MaxDistance = v end })
Tabs.ESP:AddSlider("ESPUpdateRate", { Title = "Update Rate (detik)", Default = 0.5, Min = 0.1, Max = 2, Rounding = 2,
    Callback = function(v) Settings.Performance.UpdateRate = v end })
Tabs.ESP:AddSlider("ESPMaxObjects", { Title = "Max ESP Objects", Default = (isMobile and 50) or 100, Min = 25, Max = 500, Rounding = 0,
    Callback = function(v) Settings.Performance.MaxESPObjects = v end })
Tabs.ESP:AddButton({ Title = "Clear All ESP", Callback = function() ClearESP(); Notify("ESP", "Semua ESP dibersihkan", 2) end })
Tabs.ESP:AddButton({ Title = "Refresh ESP", Callback = function()
    ClearESP()
    if Settings.ESP.Master and ESPAnyEnabled() then ZianESP.Refresh() end
    Notify("ESP", (Settings.ESP.Master and "ESP di-refresh") or "Master ESP masih OFF", 2)
end })

-- ---------- TAB : GAMEPLAY ----------
Breathe()
Tabs.Gameplay:AddSection("AUTO FEATURES (ZIAAN V3)")
Tabs.Gameplay:AddParagraph({
    Title = "Generator V3",
    Content = "Mode Great mengirim hasil skill-check sukses dengan scheduler ringan. Generator ESP menampilkan progress dan jarak di tab ESP.",
})
Tabs.Gameplay:AddToggle("AutoGenerator", { Title = "Auto Complete Generators", Default = false }):OnChanged(function(value)
    Settings.AutoFeatures.AutoGenerator = value
    PerfMgr.SetActive("autoGenerator", value)
    Notify("Auto Generator", (value and "Aktif") or "Mati", 2)
end)
Tabs.Gameplay:AddDropdown("GeneratorMode", { Title = "Generator Mode", Values = { "Great (Fast)", "Normal (Slow)" }, Default = 1 })
    :OnChanged(function(value)
        Settings.AutoFeatures.GeneratorMode = (value == "Great (Fast)") and "great" or "normal"
    end)

Breathe()
Tabs.Gameplay:AddSection("QUICK ESCAPE")
Tabs.Gameplay:AddToggle("QuickLeave", { Title = "Enable Quick Leave Generator", Default = false }):OnChanged(function(value)
    Settings.AutoFeatures.AutoLeaveGenerator = value
    if value then EnableLeave() else DisableLeave() end
end)
if not isMobile then
    Tabs.Gameplay:AddDropdown("LeaveKeybind", { Title = "Leave Keybind", Values = { "Q", "E", "F", "G", "X", "Z", "V", "B" }, Default = 1 })
        :OnChanged(function(value)
            local keyMap = { Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, F = Enum.KeyCode.F, G = Enum.KeyCode.G,
                             X = Enum.KeyCode.X, Z = Enum.KeyCode.Z, V = Enum.KeyCode.V, B = Enum.KeyCode.B }
            Settings.AutoFeatures.LeaveKeybind = keyMap[value]
            if Settings.AutoFeatures.AutoLeaveGenerator then DisableLeave(); EnableLeave() end
            Notify("Keybind", "Leave key: " .. tostring(value), 2)
        end)
end
Tabs.Gameplay:AddSlider("LeaveRange", { Title = "Detection Range (studs)", Default = 15, Min = 5, Max = 30, Rounding = 0,
    Callback = function(v) Settings.AutoFeatures.LeaveDistance = v end })
Tabs.Gameplay:AddButton({ Title = "Leave Generator Now", Callback = function() EscapeGenerator() end })

Breathe()
Tabs.Gameplay:AddSection("MANUAL ACTIONS")
Tabs.Gameplay:AddButton({
    Title = "Complete All Generators (Instant)",
    Callback = function()
        local map = MapCache.GetMap()
        if not map then Notify("Error", "Map tidak ditemukan", 3); return end
        local completed = 0
        SafeCall(function()
            local repairEvent     = RemoteCache.Get("Generator", "RepairEvent")
            local skillCheckEvent = RemoteCache.Get("Generator", "SkillCheckResultEvent")
            if not repairEvent or not skillCheckEvent then return end
            for _, obj in ipairs(MapCache.Models("Generator")) do
                for _, child in ipairs(MapCache.GeneratorPoints(obj)) do
                    pcall(function()
                        for i = 1, 10 do
                            repairEvent:FireServer(child, true)
                            skillCheckEvent:FireServer("success", 1, obj, child)
                        end
                        completed = completed + 1
                    end)
                end
            end
        end)
        if completed > 0 then
            Notify("Selesai", string.format("%d generator selesai", completed), 4)
        else
            Notify("Gagal", "Generator tidak ditemukan", 3)
        end
    end,
})

Breathe()
Tabs.Gameplay:AddSection("KILLER POWERS")
Tabs.Gameplay:AddToggle("AutoAttack", { Title = "Auto Attack Nearby Survivors", Default = false }):OnChanged(function(value)
    Settings.AutoFeatures.AutoAttack = value
    if value then EnableAutoAttack() else DisableAutoAttack() end
end)
Tabs.Gameplay:AddSlider("AttackRange", { Title = "Auto Attack Range (studs)", Default = 10, Min = 5, Max = 20, Rounding = 0,
    Callback = function(v) Settings.AutoFeatures.AttackRange = v end })
Tabs.Gameplay:AddButton({
    Title = "Activate Killer Power",
    Callback = function()
        SafeCall(function()
            local activate = RemoteCache.Get("Killers", "Killer", "ActivatePower")
            if activate then activate:FireServer(); Notify("Power", "Killer power dipicu", 2) end
        end)
    end,
})
Tabs.Gameplay:AddButton({
    Title = "Basic Attack (Killer)",
    Callback = function()
        SafeCall(function()
            local basicAttack = RemoteCache.Get("Attacks", "BasicAttack")
            if basicAttack then basicAttack:FireServer(false); Notify("Attack", "Basic attack", 2) end
        end)
    end,
})

-- ---------- TAB : PLAYER ----------
Breathe()
Tabs.Player:AddSection("SPEED & JUMP")
Tabs.Player:AddToggle("SpeedBoost", { Title = "Speed Boost", Default = false }):OnChanged(function(value)
    SpeedConfig.Enabled = value
    SyncSpeedJob()
    Notify("Speed Boost", (value and ("Aktif - " .. SpeedConfig.Value)) or "Mati", 2)
end)
Tabs.Player:AddSlider("SpeedValue", { Title = "Nilai Speed", Default = 18, Min = 16, Max = 100, Rounding = 0,
    Callback = function(v) SpeedConfig.Value = v end })
Tabs.Player:AddToggle("JumpBoost", { Title = "Jump Boost", Default = false }):OnChanged(function(v)
    SpeedConfig.JumpEnabled = v
    SyncSpeedJob()
end)
Tabs.Player:AddSlider("JumpValue", { Title = "Nilai Jump Power", Default = 50, Min = 50, Max = 200, Rounding = 0,
    Callback = function(v) SpeedConfig.Jump = v end })

Breathe()
Tabs.Player:AddSection("KAMERA & GERAK")
Tabs.Player:AddToggle("CamLock", { Title = "Camera Lock POV", Default = false }):OnChanged(function(value)
    CamConfig.Enabled = value
    Notify("Camera Lock", (value and "Aktif") or "Mati", 2)
end)
Tabs.Player:AddSlider("CamHeight", { Title = "Tinggi Kamera", Default = 10, Min = 2, Max = 40, Rounding = 0,
    Callback = function(v) CamConfig.Height = v end })
Tabs.Player:AddSlider("CamDistance", { Title = "Jarak Kamera", Default = 20, Min = 5, Max = 60, Rounding = 0,
    Callback = function(v) CamConfig.Distance = v end })

Breathe()
Tabs.Player:AddSection("UNITY (FLY / GOD MODE)")
Tabs.Player:AddToggle("FlyToggle", { Title = "Fly", Default = false }):OnChanged(function(value)
    if value then startFly() else stopFly() end
    Notify("Fly", (value and "Aktif") or "Mati", 2)
end)
Tabs.Player:AddSlider("FlySpeed", { Title = "Kecepatan Fly", Default = 60, Min = 20, Max = 200, Rounding = 0,
    Callback = function(v) FlyConfig.Speed = v end })
Tabs.Player:AddToggle("GodMode", { Title = "No Damage (God Mode)", Default = false }):OnChanged(function(value)
    GodConfig.Enabled = value
    if value then enableGodMode() else disableGodMode() end
    Notify("No Damage", (value and "Aktif") or "Mati", 2)
end)
Tabs.Player:AddToggle("AutoHeal", { Title = "Auto Heal", Default = true }):OnChanged(function(v) GodConfig.AutoHeal = v end)
Tabs.Player:AddSlider("HealThreshold", { Title = "Batas HP Auto Heal", Default = 50, Min = 10, Max = 100, Rounding = 0,
    Callback = function(v) GodConfig.HealThreshold = v end })
Tabs.Player:AddButton({ Title = "Heal Sekarang", Callback = function() godDoHeal(); Notify("Heal", "Heal dipicu", 2) end })
Tabs.Player:AddButton({
    Title = "Scan Generator Terdekat",
    Callback = function()
        local gens = ListGeneratorsSorted()
        if #gens == 0 then Notify("Generator", "Tidak ditemukan", 3); return end
        Notify("Generator", string.format("%d generator, terdekat %.0fm", #gens, gens[1].distance), 4)
    end,
})

-- ---------- TAB : SETTINGS ----------
Breathe()
Tabs.Settings:AddSection("VISUAL")
Tabs.Settings:AddToggle("FullBright", { Title = "Full Bright", Default = false }):OnChanged(function(v) toggleFullBright(v) end)
Tabs.Settings:AddToggle("NoFog", { Title = "No Fog", Default = false }):OnChanged(function(v) toggleNoFog(v) end)
Tabs.Settings:AddDropdown("HudTheme", {
    Title = "Tema HUD (mobile/FPS)",
    Values = { "Modern", "Neon Blue", "Blood Red", "Matrix Green", "Purple Haze" },
    Default = 4,
}):OnChanged(function(value) SetTheme(value); Notify("Theme", "Applied: " .. tostring(value), 3) end)
Tabs.Settings:AddToggle("FPSCounter", { Title = "Show FPS Counter", Default = false }):OnChanged(function(value)
    if value then BuildFPSCounter() else DisableFPS(); Notify("FPS Counter", "Disabled", 2) end
end)

Breathe()
Tabs.Settings:AddSection("PERFORMANCE")
Tabs.Settings:AddToggle("PerfParticles", { Title = "Disable Particles & Effects", Default = false }):OnChanged(function(v)
    Settings.Performance.DisableParticles = v; ApplyPerf()
end)
Tabs.Settings:AddToggle("PerfGraphics", { Title = "Lower Graphics Quality", Default = false }):OnChanged(function(v)
    Settings.Performance.LowerGraphics = v; ApplyPerf()
end)
Tabs.Settings:AddToggle("PerfShadows", { Title = "Disable Shadows", Default = false }):OnChanged(function(v)
    Settings.Performance.DisableShadows = v; ApplyPerf()
end)
Tabs.Settings:AddToggle("PerfRender", { Title = "Reduce Render Distance", Default = false }):OnChanged(function(v)
    Settings.Performance.ReduceRenderDistance = v; ApplyPerf()
end)
Tabs.Settings:AddToggle("PerfCulling", { Title = "Use Distance Culling (ESP)", Default = true }):OnChanged(function(v)
    Settings.Performance.UseDistanceCulling = v
end)
Tabs.Settings:AddButton({
    Title = "Apply All Performance Boosts",
    Callback = function()
        Settings.Performance.DisableParticles = true
        Settings.Performance.LowerGraphics = true
        Settings.Performance.DisableShadows = true
        Settings.Performance.ReduceRenderDistance = true
        Settings.Performance.UseDistanceCulling = true
        ApplyPerf()
        Notify("Performance", "Semua boost diterapkan!", 3)
    end,
})
Tabs.Settings:AddButton({
    Title = "Reset Performance Settings",
    Callback = function()
        Settings.Performance.DisableParticles = false
        Settings.Performance.LowerGraphics = false
        Settings.Performance.DisableShadows = false
        Settings.Performance.ReduceRenderDistance = false
        ResetPerf()
        Notify("Performance", "Direset", 2)
    end,
})

if isMobile then
    Tabs.Settings:AddSection("MOBILE")
    Tabs.Settings:AddToggle("TouchControls", { Title = "Enable Touch Controls", Default = true }):OnChanged(function(value)
        Settings.Mobile.TouchControlsEnabled = value
        if value and not mobileControls then
            BuildMobileControls()
        elseif not value and mobileControls then
            mobileControls:Destroy()
            mobileControls = nil
        end
    end)
    Tabs.Settings:AddToggle("MobileAutoOpt", { Title = "Auto Mobile Optimization", Default = true }):OnChanged(function(value)
        Settings.Mobile.AutoOptimize = value
        if value then MobileOptimize() else ResetPerf() end
    end)
    Tabs.Settings:AddSlider("MobileBtnSize", { Title = "Button Size", Default = 80, Min = 60, Max = 120, Rounding = 0,
        Callback = function(value)
            Settings.Mobile.ButtonSize = value
            if mobileControls then mobileControls:Destroy(); BuildMobileControls() end
        end })
    Tabs.Settings:AddSlider("MobileBtnTrans", { Title = "Button Transparency", Default = 0.3, Min = 0, Max = 0.8, Rounding = 2,
        Callback = function(value)
            Settings.Mobile.ButtonTransparency = value
            if mobileControls then
                for _, child in ipairs(mobileControls:GetChildren()) do
                    if child:IsA("TextButton") then child.BackgroundTransparency = value end
                end
            end
        end })
    Tabs.Settings:AddToggle("UltraPerf", { Title = "ULTRA Performance Mode", Default = false }):OnChanged(function(value)
        Settings.Mobile.AggressiveOptimization = value
        if value then
            AggressiveOptimize()
            Notify("ULTRA MODE", "Maximum FPS boost!", 4)
        else
            ResetPerf()
            if Settings.Mobile.AutoOptimize then MobileOptimize() end
        end
    end)
end

Breathe()
Tabs.Settings:AddSection("SHARE CONFIG (JSON)")
local shareJson = ""
Tabs.Settings:AddButton({
    Title = "Export Setting (Copy JSON)",
    Callback = function()
        local json = ExportConfig()
        if not json then Notify("Export", "Gagal membuat JSON", 3); return end
        shareJson = json
        local ok = pcall(function() setclipboard(json) end)
        Notify("Export", (ok and "JSON tersalin ke clipboard!") or "Lihat console (F9)", 4)
        print("[SHARE CONFIG] " .. json)
    end,
})
Tabs.Settings:AddInput("ShareJsonBox", {
    Title = "JSON", Placeholder = "tempel JSON teman di sini", Default = "",
    Callback = function(text) shareJson = text or "" end,
})
Tabs.Settings:AddButton({
    Title = "Import Setting (dari kotak JSON)",
    Callback = function()
        if shareJson == "" then Notify("Import", "Kotak JSON masih kosong", 3); return end
        ImportConfig(shareJson)
    end,
})

Breathe()
Tabs.Settings:AddSection("SCRIPT CONTROLS")
Tabs.Settings:AddButton({
    Title = "Unload Script",
    Callback = function()
        PerfMgr.StopAll()
        DisableESP(); ClearESP(); DisableAutoAttack(); DisableLeave(); DisableFPS(); ResetPerf()
        destroyRing(); stopFly(); disableGodMode()
        if MainLoopConn then MainLoopConn:Disconnect(); MainLoopConn = nil end
        ConnMgr.ClearAll()
        RemoteCache.Clear()
        MapCache.Invalidate()
        toggleFullBright(false); toggleNoFog(false)
        if LaserPart then LaserPart:Destroy() end
        if FeatureGui then FeatureGui:Destroy() end
        if mobileControls then mobileControls:Destroy() end
        if BubbleGui then BubbleGui:Destroy() end
        pcall(function() Window:Destroy() end)
        if getgenv then getgenv().NoMercyUnload = nil end
        Notify("Unloaded", "Script unloaded - Goodbye!", 2)
    end,
})

-- ---------- CONFIG / INTERFACE MANAGER (aman kalau addon gagal load) ----------
-- Addon di-load paralel di background; tunggu maksimal 5 detik lalu lanjut.
do
    local t0 = os.clock()
    while not addonsReady and (os.clock() - t0) < 5 do task.wait(0.1) end
end
pcall(function()
    if InterfaceManager then
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:SetFolder("NoMercyHub")
        InterfaceManager:BuildInterfaceSection(Tabs.Config)
    end
end)
pcall(function()
    if SaveManager then
        SaveManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        SaveManager:SetFolder("NoMercyHub/VioletDistrict")
        SaveManager:BuildConfigSection(Tabs.Config)
    end
end)

Window:SelectTab(1)

-- Daftarkan unloader global supaya execute ulang tidak menumpuk instance.
if getgenv then
    getgenv().NoMercyUnload = function()
        pcall(function() PerfMgr.StopAll() end)
        pcall(function() DisableESP(true); ClearESP(); DisableAutoAttack(); DisableLeave(); DisableFPS() end)
        pcall(function() destroyRing(); stopFly(); disableGodMode() end)
        pcall(function() if MainLoopConn then MainLoopConn:Disconnect(); MainLoopConn = nil end end)
        pcall(function() ConnMgr.ClearAll(); RemoteCache.Clear(); MapCache.Invalidate() end)
        pcall(function() if LaserPart then LaserPart:Destroy() end end)
        pcall(function() if FeatureGui then FeatureGui:Destroy() end end)
        pcall(function() if mobileControls then mobileControls:Destroy() end end)
        pcall(function() if BubbleGui then BubbleGui:Destroy() end end)
        pcall(function() Window:Destroy() end)
        getgenv().NoMercyUnload = nil
    end
end

Notify("NO MERCY", "Script dimuat (v3.4 turbo start)", 4)
pcall(function() if SaveManager then SaveManager:LoadAutoloadConfig() end end)

-- ===== BAGIAN 16 : LOOP AUTO-GENERATOR =====

-- Auto generator: job scheduler, hanya jalan saat toggle ON.
-- Remote & daftar GeneratorPoint di-cache (tidak ada GetDescendants tiap 0.2 detik).
PerfMgr.Add("autoGenerator", 0.2, function()
    if not Settings.AutoFeatures.AutoGenerator then return end
    local repairEvent     = RemoteCache.Get("Generator", "RepairEvent")
    local skillCheckEvent = RemoteCache.Get("Generator", "SkillCheckResultEvent")
    if not repairEvent or not skillCheckEvent then return end
    local great  = (Settings.AutoFeatures.GeneratorMode == "great")
    local result = great and "success" or "normal"
    local amount = great and 1 or 0
    for _, obj in ipairs(MapCache.Models("Generator")) do
        for _, child in ipairs(MapCache.GeneratorPoints(obj)) do
            pcall(function()
                repairEvent:FireServer(child, true)
                skillCheckEvent:FireServer(result, amount, obj, child)
            end)
        end
    end
end)

-- ===== BAGIAN 17 : INISIALISASI MOBILE =====

-- Lazy init mobile: tidak memblokir thread utama saat startup.
if isMobile then
    task.delay(1, function()
        BuildMobileControls()
        if Settings.Mobile.AutoOptimize then
            task.delay(0.5, function()
                MobileOptimize()
                Notify("Mobile Mode", "Auto-optimizations applied!", 4)
            end)
        end
    end)
end
