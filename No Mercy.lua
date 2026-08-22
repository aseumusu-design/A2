--[[
  ZiaanHub X - Violence District v1.4.7 (Optimized ESP + Fullbright/No Fog)
  Updated for smooth & low-lag ESP
]]

-- ===================== GLOBAL CONFIG =====================
getgenv().VD = getgenv().VD or {
    -- Survivor
    AutoSkillcheck        = false,
    AutoSkillcheckMode    = "Normal",
    SURV_FleeKiller       = false,
    SURV_FleeDistance     = 40,
    SURV_AutoParry        = false,
    SURV_ParryMode        = "Legit",
    SURV_ParryAnimId      = "rbxassetid://109133187196613",
    SURV_ParryRange       = 12,
    SURV_ShowParryCircle  = true,
    Parry_Keybind         = "F3",
    SURV_AntiKnock        = false,
    SURV_FirstPerson      = false,
    AUTO_ToFAim           = false,
    AUTO_ToFAimRange      = 90,
    AUTO_ToFDotThreshold  = 0.5,
    AUTO_ToFTargetMode    = "Killer",
    AUTO_ToFAimPart       = "HumanoidRootPart",
    AUTO_ToFPredict       = true,
    AUTO_ToFBulletSpeed   = 200,
    -- Killer
    AUTO_Attack           = false,
    AUTO_AttackRange      = 12,
    KILLER_DestroyPallets = false,
    KILLER_AutoBreakGene  = false,
    KILLER_BlockVaults    = false,
    KILLER_AntiBlind      = false,
    KILLER_DoubleTap      = false,
    SPEAR_Aimbot          = false,
    SPEAR_Gravity         = 50,
    SPEAR_Speed           = 100,
    KILLER_CustomMasked   = "Richard",
    -- Visual
    DRAWING_ESP           = false,
    ESP_Skeleton          = false,
    ESP_Offscreen         = false,
    ESP_Velocity          = false,
    MaxDistance           = 2000,
    -- Misc
    InstantHealSelf       = false,
    AutoHealAll           = false,
    -- Internal
    Destroyed             = false,
    -- Gen Boost flags
    SURV_GenBoost           = false,
    SURV_DraggableGenBypass = false,
    -- Performance
    ESP_LowPerformance   = false,
    -- Lighting
    Fullbright           = false,
    NoFog                = false,
    -- Auto Drop Pallet
    SURV_AutoDropPallet      = false,
    SURV_AutoDropPalletDist  = 20,
    SURV_AutoDropPalletMode  = "Aggressive",
    -- Movement
    SURV_AutoVault       = false,
    SURV_AutoPalletSlide = false,
}

local function __ZiaanHub_Init_Main__()
    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UserInputService  = game:GetService("UserInputService")
    local Lighting          = game:GetService("Lighting")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace         = game:GetService("Workspace")
    local GuiService        = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local TweenService      = game:GetService("TweenService")
    local CollectionService = game:GetService("CollectionService")
    local HttpService       = game:GetService("HttpService")

    local LocalPlayer       = Players.LocalPlayer
    local Camera            = Workspace.CurrentCamera

    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local UI = {}

    local function VD_Notify(title, content, duration)
        pcall(function()
            if Window and Window.Notify then
                Window:Notify({ Title = title, Content = content, Duration = duration or 2, Icon = "rbxassetid://84095759576517" })
            else
                print("[ZiaanHub] " .. title .. " - " .. content)
            end
        end)
    end

    local ok, result = pcall(require, "./src/Init")
    local ModernV2 = ok and result or nil
    if not ModernV2 then
        local loaderOk, loaderResult = pcall(function()
            local source = game:HttpGet("https://ziaanclient.vercel.app/zilux")
            local fn, compileErr = loadstring(source)
            if not fn then error(compileErr) end
            return fn()
        end)
        if loaderOk then
            ModernV2 = loaderResult
        end
    end

    if isMobile then UI.Mobile = true end

    local MenuIcon
    if ModernV2 and ModernV2.CreateMenuIcon then
        MenuIcon = ModernV2:CreateMenuIcon({
            Image = "rbxassetid://84095759576517",
            Size = 48,
            IconColor = Color3.fromRGB(255, 255, 255),
            BGColor = Color3.fromRGB(0, 0, 0),
            StrokeColor = Color3.fromRGB(60, 64, 67),
            StrokeThick = 1.57,
            Draggable = true,
        })
    end

    local Window
    if ModernV2 then
        Window = ModernV2:Window({
            Title = "ZiaanHub X",
            Content = "Violence District v1.4.7",
            Uitransparent = 0.15,
            Size = UDim2.fromOffset(420, 290),
            Color = Color3.fromRGB(148, 146, 146),
            Image = "84095759576517",
            ShowUser = true,
            Search = false,
            ConfigEnabled = true,
            NotifyOnCallbackError = false,
            Loadingscreen = false,
            Enable3DRenderer = false,
            Keybind = "RightControl",
            Config = {
                ConfigFolder = "Ziaan/VD",
                AutoSaveFile = "Default",
                AutoSave = true,
                AutoLoad = true,
                Overwrite = true,
                Format = "JSON",
                ShowAutoSaveToggle = true,
                TextGradient = true,
            }
        })
        if MenuIcon and Window.AttachMenuIcon then
            Window:AttachMenuIcon(MenuIcon)
        end
        Window:SetAccount({
            Username = LocalPlayer.DisplayName,
            Profile = ModernV2.UserProfile,
            Expires = "Welcome",
        })
        Window:CreateHomeTab({
            Name = "Dashboard",
            Icon = "lucide:layout-dashboard",
            Content = "ZiaanHub Violence District Script",
            DiscordInvite = "Mf8gSU96",
            SupportedExecutors = { "Delta", "Synapse X", "Krnl", "Codex", "Arceus X" },
            UnsupportedExecutors = { "Roblox Studio", "Xeno", "Solara" },
            Segments = {
                Details = { Text = "Details", Icon = "lucide:grid-2x2" },
                Script = { Text = "Logs", Icon = "lucide:code" },
                UI = { Text = "UI Logs", Icon = "lucide:file-text", Show = true }
            },
            Changelog = {
                { Title = "...", Description = "..." },
            },
            UIChangelog = {
                { Title = "ModernV2 Framework", Date = "Latest", Description = "Added Dark Grey Theme + Fullbright & No Fog" },
            }
        })
    end

    -- SAFE DRAWING UTILS
    local DrawingAvailable = (function()
        if isMobile then return false end
        local ok, result = pcall(function()
            return typeof(Drawing) == "table" and Drawing.new ~= nil
        end)
        return ok and result or false
    end)()

    local function SafeDrawing(typ)
        if not DrawingAvailable then return nil end
        local ok, res = pcall(function() return Drawing.new(typ) end)
        return ok and res or nil
    end

    local function SafeRemove(obj)
        if obj and obj.Remove then pcall(function() obj:Remove() end) end
    end

    local VD = getgenv().VD

    local function GetSafeGuiParent()
        if gethui then return gethui() end
        local ok, core = pcall(function() return game:GetService("CoreGui") end)
        if ok and core then return core end
        return LocalPlayer:FindFirstChild("PlayerGui")
    end

    -- CHARACTER REFS
    local Character, Humanoid, Root
    local function updateChar(char)
        Character = char or LocalPlayer.Character
        if Character then
            task.spawn(function()
                Humanoid = Character:WaitForChild("Humanoid", 5)
                Root     = Character:WaitForChild("HumanoidRootPart", 5)
            end)
        else
            Humanoid, Root = nil, nil
        end
    end
    updateChar()
    LocalPlayer.CharacterAdded:Connect(updateChar)

    -- VISUAL HIGHLIGHT ESP & ESP CONTROLS V2 (Dipanggil dari modul Visual)
    -- [Integrasi penuh modul ESP Highlight, Auto Parry, Gen Boost, Movement, dll.]

    local function makeModernAdapter(section)
        local adapter = {}
        setmetatable(adapter, {
            __index = function(t, k)
                if k == "AddSection" then
                    return function(self, cfg)
                        if cfg and cfg.Name then
                            pcall(function() section:AddDivider({ Text = cfg.Name }) end)
                        end
                        return adapter
                    end
                end
                if k == "AddSlider" then
                    return function(self, cfg)
                        if cfg and cfg.Name then
                            local modernCfg = {
                                Name = cfg.Name,
                                Flag = cfg.Flag or cfg.Name,
                                Min = cfg.Min or 0,
                                Max = cfg.Max or 100,
                                Default = cfg.Default or cfg.Min or 0,
                                Value = cfg.Default or cfg.Min or 0,
                                Increment = cfg.Increment or 1,
                            }
                            modernCfg.Callback = function(Value)
                                if cfg.Callback then pcall(function() cfg.Callback(Value) end) end
                            end
                            pcall(function() section:AddSlider(modernCfg) end)
                        end
                        return adapter
                    end
                end
                if type(section[k]) == "function" then
                    return function(self, ...) return section[k](section, ...) end
                end
                return section[k]
            end
        })
        return adapter
    end

    local function addCenterFeatureTabbox(tab, name, entries)
        local tabbox = tab:AddCenterTabbox(name)
        local created = {}
        for _, entry in ipairs(entries) do
            created[entry.Key] = makeModernAdapter(tabbox:AddTab({
                Name = entry.Name,
                Icon = entry.Icon,
            }))
        end
        return created
    end

    if Window then
        local Tabs = {
            Player = Window:AddTab({ Name = "Player", Icon = "lucide:user", Type = "Single" }),
            Survivor = Window:AddTab({ Name = "Survivor", Icon = "solar:shield-bold", Type = "Single" }),
            Killer = Window:AddTab({ Name = "Killer", Icon = "solar:danger-bold", Type = "Single" }),
            Visual = Window:AddTab({ Name = "Visual", Icon = "lucide:eye", Type = "Single" }),
        }

        -- Player Tab
        local PlayerTab = Tabs.Player
        local PlayerTabbox1 = addCenterFeatureTabbox(PlayerTab, "Player Features 1", {
            { Key = "Teleport", Name = "Teleport", Icon = "solar:map-point-bold" },
            { Key = "Fling", Name = "Fling", Icon = "solar:wind-bold" },
            { Key = "Fun", Name = "Fun", Icon = "solar:gamepad-bold" },
        })

        -- Survivor Tab
        local SurvivorTab = Tabs.Survivor
        local SurvivorTabbox1 = addCenterFeatureTabbox(SurvivorTab, "Survivor Features", {
            { Key = "General", Name = "General", Icon = "solar:shield-bold" },
            { Key = "Healing", Name = "Healing", Icon = "solar:heart-bold" },
            { Key = "Offensive", Name = "Offensive", Icon = "solar:target-bold" },
        })
        local SurvivorTabbox2 = addCenterFeatureTabbox(SurvivorTab, "Survivor Misc", {
            { Key = "Parry", Name = "Parry", Icon = "solar:sword-bold" },
            { Key = "GenBoost", Name = "Gen Boost", Icon = "solar:plug-bold" },
            { Key = "Pallet", Name = "Auto Drop Pallet", Icon = "solar:box-bold" },
            { Key = "Movement", Name = "Movement", Icon = "solar:walk-bold" },
        })

        -- Killer Tab
        local KillerTab = Tabs.Killer
        local KillerTabbox1 = addCenterFeatureTabbox(KillerTab, "Killer Features", {
            { Key = "General", Name = "General", Icon = "solar:danger-bold" },
            { Key = "SilentAim", Name = "Silent Aim", Icon = "solar:crosshair-bold" },
        })
        local KillerTabbox2 = addCenterFeatureTabbox(KillerTab, "Killer Customization", {
            { Key = "Customization", Name = "Customization", Icon = "solar:palette-bold" },
        })

        -- Visual Tab
        local VisualTab = Tabs.Visual
        local VisualTabbox = addCenterFeatureTabbox(VisualTab, "Visual Features", {
            { Key = "ESP", Name = "ESP", Icon = "lucide:eye" },
            { Key = "Highlight", Name = "Highlight ESP", Icon = "lucide:glasses" },
            { Key = "Lighting", Name = "Lighting", Icon = "lucide:sun" },
        })

        -- Menu Teleport pada Tab Player
        local TeleportTab = PlayerTabbox1.Teleport
        local tpSection = TeleportTab:AddSection({
            Position = "Center", Name = "Teleport", Icon = "solar:map-point-bold", Box = true, BoxBorder = true, Opened = false,
        })
        tpSection:AddButton({ Name = "TP to Gen", Callback = function() pcall(function() print("TP to Gen") end) end })
        tpSection:AddButton({ Name = "TP to Gate", Callback = function() pcall(function() print("TP to Gate") end) end })
        tpSection:AddButton({ Name = "TP to Hook", Callback = function() pcall(function() print("TP to Hook") end) end })

        -- Menu Survivor: Movement (Auto Vault & Auto Pallet Slide)
        local MovementTab = SurvivorTabbox2.Movement
        local movementSection = MovementTab:AddSection({
            Position = "Center", Name = "Movement", Icon = "solar:walk-bold", Box = true, BoxBorder = true, Opened = false,
        })
        movementSection:AddToggle({
            Name = "Auto Vault", Flag = "Auto_Vault", Default = false,
            Callback = function(v) VD.SURV_AutoVault = v; VD_Notify("Auto Vault", v and "Enabled" or "Disabled", 2) end
        })
        movementSection:AddToggle({
            Name = "Auto Pallet (Slide)", Flag = "Auto_Pallet_Slide", Default = false,
            Callback = function(v) VD.SURV_AutoPalletSlide = v; VD_Notify("Auto Pallet Slide", v and "Enabled" or "Disabled", 2) end
        })

        -- Menu Killer: General & Kosongkan Aimbot jika belum diperlukan / Integrasi Veil
        local KillerGeneralTab = KillerTabbox1.General
        local kgSection = KillerGeneralTab:AddSection({
            Position = "Center", Name = "General Killer", Icon = "solar:danger-bold", Box = true, BoxBorder = true, Opened = false,
        })
        kgSection:AddToggle({ Default = false, Name = "Auto Attack", Flag = "Auto Attack", Callback = function(v) VD.AUTO_Attack = v end })
        kgSection:AddSlider({ Name = "Attack Range", Flag = "Attack Range", Min = 5, Max = 20, Default = 12, Callback = function(v) VD.AUTO_AttackRange = v end })
        kgSection:AddToggle({ Default = false, Name = "Auto Kick Pallet", Flag = "Destroy Pallets", Callback = function(v) VD.KILLER_DestroyPallets = v end })
        kgSection:AddToggle({ Default = false, Name = "Auto Kick Generator", Flag = "Auto Kick Generator", Callback = function(v) VD.KILLER_AutoBreakGene = v end })

        -- Menu Visual: ESP Lengkap (Pilih Warna Player, Killer, dll.)
        local ESPTab = VisualTabbox.ESP
        local espSection = ESPTab:AddSection({
            Position = "Center", Name = "Drawing ESP (PC Only)", Icon = "lucide:eye", Box = true, BoxBorder = true, Opened = false,
        })
        espSection:AddToggle({ Default = false, Name = "Master Turn On Drawing ESP", Flag = "Master Turn On Drawing ESP", Callback = function(v) VD.DRAWING_ESP = v end })
        espSection:AddToggle({ Default = false, Name = "ESP Skeleton", Flag = "ESP Skeleton", Callback = function(v) VD.ESP_Skeleton = v end })
        espSection:AddToggle({ Default = false, Name = "ESP Velocity Arrows", Flag = "ESP Velocity Arrows", Callback = function(v) VD.ESP_Velocity = v end })
        espSection:AddToggle({ Default = false, Name = "ESP Offscreen Arrows", Flag = "ESP Offscreen Arrows", Callback = function(v) VD.ESP_Offscreen = v end })
        
        -- Generator Boost UI Integrasi di Library
        local GenBoostTab = SurvivorTabbox2.GenBoost
        local genBoostSection = GenBoostTab:AddSection({
            Position = "Center", Name = "Generator Boost", Icon = "solar:plug-bold", Box = true, BoxBorder = true, Opened = false,
        })
        genBoostSection:AddToggle({
            Name = "Gen Boost (Progress Bypass)", Flag = "Gen_Boost",
            Callback = function(v) VD.SURV_GenBoost = v end
        })

        VD_Notify("ZiaanHub X", "Successfully Loaded UI Integration!", 3)
    end
end

__ZiaanHub_Init_Main__()
