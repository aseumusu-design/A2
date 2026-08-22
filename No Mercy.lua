--[[
  ZiaanHub X - Violence District v1.4.7 (Optimized ESP + Fullbright/No Fog)
  Updated for smooth & low-lag ESP
  FIX: Drawing ESP performance improvements
  AUTO PARRY REPLACED with new improved version (WalkSpeed sequence, Legit/Aggressive, animations)
  ADDED: Fullbright & No Fog toggles in Visual tab
  ADDED: Auto Drop Pallet in Survivor Misc tab
  ADDED: Auto Vault & Auto Pallet (Slide) in Survivor Misc -> Movement tab
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
    local Teams             = game:GetService("Teams")
    local GuiService        = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local TweenService      = game:GetService("TweenService")
    local CollectionService = game:GetService("CollectionService")
    local HttpService       = game:GetService("HttpService")

    local LocalPlayer       = Players.LocalPlayer
    local Camera            = Workspace.CurrentCamera

    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local UI = {}

    -- ============================================================
    -- FIX: Define VD_Notify EARLY so it's available in all callbacks
    -- ============================================================
    local function VD_Notify(title, content, duration)
        pcall(function()
            if Window and Window.Notify then
                Window:Notify({ Title = title, Content = content, Duration = duration or 2, Icon = "rbxassetid://84095759576517" })
            else
                print("[ZiaanHub] " .. title .. " - " .. content)
            end
        end)
    end

    -- ============================================================
    -- NO MERCY ANIMATION INTRO
    -- Kept outside the feature system so it never delays callbacks.
    -- ============================================================
    local function GetAnimationGuiParent()
        if gethui then
            local ok, hui = pcall(gethui)
            if ok and hui then return hui end
        end
        return game:GetService("CoreGui")
    end

    local function ShowNoMercyIntro()
        local parent = GetAnimationGuiParent()
        if not parent then return end

        local gui = Instance.new("ScreenGui")
        gui.Name = "NoMercyWelcome"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        gui.Parent = parent
        pcall(function()
            if syn and syn.protect_gui then syn.protect_gui(gui) end
        end)

        local holder = Instance.new("Frame")
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.fromScale(0.5, 0.5)
        holder.Size = UDim2.fromOffset(280, 250)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 999
        holder.Parent = gui

        local logo = Instance.new("ImageLabel")
        logo.AnchorPoint = Vector2.new(0.5, 0.5)
        logo.Position = UDim2.fromScale(0.5, 0.38)
        logo.Size = UDim2.fromOffset(0, 0)
        logo.BackgroundTransparency = 1
        logo.Image = "rbxassetid://102609928046926"
        logo.ZIndex = 999
        logo.Parent = holder
        Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)

        local ring = Instance.new("UIStroke")
        ring.Color = Color3.new(1, 1, 1)
        ring.Thickness = 3
        ring.Transparency = 1
        ring.Parent = logo

        local label = Instance.new("TextLabel")
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.Position = UDim2.fromScale(0.5, 0.72)
        label.Size = UDim2.new(1, 0, 0, 40)
        label.BackgroundTransparency = 1
        label.Text = "WELCOME NO MERCY"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 18
        label.Font = Enum.Font.GothamBold
        label.TextTransparency = 1
        label.ZIndex = 999
        label.Parent = holder

        local tween = TweenService:Create(logo, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(150, 150)
        })
        tween:Play()
        TweenService:Create(ring, TweenInfo.new(0.4), { Transparency = 0 }):Play()
        TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        tween.Completed:Wait()
        task.wait(1.1)
        TweenService:Create(logo, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        }):Play()
        TweenService:Create(ring, TweenInfo.new(0.3), { Transparency = 1 }):Play()
        TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        task.wait(0.4)
        if gui and gui.Parent then gui:Destroy() end
    end

    ShowNoMercyIntro()

    -- Load ModernV2 (the latest UI library used by the animation build)
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
        else
            local fallbackOk, fallbackResult = pcall(function()
                local source = game:HttpGet("https://ziaanclient.vercel.app/zilux")
                local fn, compileErr = loadstring(source)
                if not fn then error(compileErr) end
                return fn()
            end)
            if fallbackOk then
                ModernV2 = fallbackResult
            end
        end
    end

    -- ============================================================
    -- NO MERCY UI BRIDGE
    -- The feature engine above is retained, but its controls are
    -- rendered by the Orion library from animation_mercy.
    -- ============================================================
    local OrionLib = nil
    pcall(function()
        OrionLib = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Marpiii/UiLib/refs/heads/main/source.lua"
        ))()
    end)

    if OrionLib then
        ModernV2 = {
            AddTheme = function() end,
            CreateMenuIcon = function() return nil end,
            Window = function(_, cfg)
                local w = OrionLib:MakeWindow({
                    Name = cfg.Title or "NO MERCY — VIOLENCE DISTRICT",
                    HidePremium = true,
                    SaveConfig = true,
                    ConfigFolder = "NoMercyVD",
                    IntroEnabled = false,
                    Icon = "rbxassetid://102609928046926",
                })

                function w:AddTab(tabCfg)
                    local tab = w:MakeTab({
                        Name = tabCfg.Name,
                        Icon = tabCfg.Icon,
                        PremiumOnly = false,
                    })
                    -- Orion has no nested tabbox; use labeled sections
                    -- inside the matching No Mercy category tab.
                    function tab:AddCenterTabbox()
                        local box = {}
                        function box:AddTab(subTabCfg)
                            pcall(function()
                                tab:AddSection({ Name = subTabCfg.Name })
                            end)
                            return tab
                        end
                        return box
                    end
                    return tab
                end

                function w:AttachMenuIcon() end
                function w:SetAccount() end
                function w:CreateHomeTab() end
                function w:Notify(notification)
                    OrionLib:MakeNotification({
                        Name = notification.Title or "NO MERCY",
                        Content = notification.Content or "",
                        Image = "rbxassetid://102609928046926",
                        Time = notification.Duration or 3,
                    })
                end
                return w
            end,
        }
    end

    if isMobile then UI.Mobile = true end

    -- UI Theme Config
    local UIConfigPath = "ZiaanHub_UI_Theme.json"
    local ZiaanUI_Solid = false
    local ZiaanUI_Color = "DarkGrey"

    pcall(function()
        if isfile and readfile and isfile(UIConfigPath) then
            local data = HttpService:JSONDecode(readfile(UIConfigPath))
            ZiaanUI_Solid = data.Solid
            ZiaanUI_Color = data.Color or "DarkGrey"
        end
    end)

    if ZiaanUI_Color == "Default" then
        ZiaanUI_Color = "DarkGrey"
    end

    if ModernV2 then
        pcall(function()
            ModernV2:AddTheme({
                Name = "Hitam",
                Accent = Color3.fromRGB(60, 64, 67),
                Outline = Color3.fromRGB(35, 35, 35),
                Text = Color3.fromRGB(60, 64, 67),
                Placeholder = Color3.fromRGB(130, 130, 130),
            })
        end)
    end

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
            Title = "NO MERCY — VIOLENCE DISTRICT",
            Content = "ZiaanHub features • Animation UI",
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
                ConfigFolder = "NoMercy/VD",
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
                {
                    Title = "...",
                    Description = "...",
                },
            },
            UIChangelog = {
                {
                    Title = "ModernV2 Framework",
                    Date = "Latest",
                    Description = "Added Dark Grey Theme + Fullbright & No Fog",
                },
            }
        })
    end

    -- PC CURSOR UNLOCK (ALT key toggle)
    if not isMobile then
        local _cursorOn = false
        local _cursorManual = false

        local function _setCursor(state)
            _cursorOn = state
            _cursorManual = true
            pcall(function()
                UserInputService.MouseIconEnabled = state
                UserInputService.MouseBehavior = state
                    and Enum.MouseBehavior.Default
                    or Enum.MouseBehavior.LockCenter
            end)

            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.AutoRotate = not state
            end
        end

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
                _setCursor(not _cursorOn)
            end
        end)

        task.spawn(function()
            while true do
                if _cursorManual then
                    pcall(function()
                        if _cursorOn then
                            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                            UserInputService.MouseIconEnabled = true
                        else
                            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                            UserInputService.MouseIconEnabled = false
                        end
                    end)
                end
                task.wait(0.1)
            end
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if _cursorOn then _setCursor(true) end
        end)
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

    local MobileESP = {}

    -- UTILITY
    local function clamp(v, min, max)
        return math.max(min, math.min(max, v))
    end

    local Perf = {
        DrawingESPInterval        = 0.1,
        NextDrawingESP            = 0,
    }

    local VD = getgenv().VD

    -- CONFIG SYSTEM
    local function GetSafeGuiParent()
        if gethui then return gethui() end
        local ok, core = pcall(function() return game:GetService("CoreGui") end)
        if ok and core then return core end
        return LocalPlayer:FindFirstChild("PlayerGui")
    end

    local VD_ChamsFolder = nil
    local function GetSafeChamsFolder()
        local pg = GetSafeGuiParent()
        if not pg then return workspace end
        if VD_ChamsFolder and VD_ChamsFolder.Parent then return VD_ChamsFolder end

        local f = pg:FindFirstChild("IYAN_WorkspaceChams")
        if not f then
            f = Instance.new("Folder")
            f.Name = "IYAN_WorkspaceChams"
            f.Parent = pg
        end
        VD_ChamsFolder = f
        return f
    end

    local ConfigFolderName = "ZiaanHubX_VD"

    if makefolder and isfolder and not isfolder(ConfigFolderName) then
        makefolder(ConfigFolderName)
    end

    getgenv().CurrentConfigName = "Default"

    local function GetConfigList()
        local list = {}
        if listfiles and isfolder and isfolder(ConfigFolderName) then
            for _, file in pairs(listfiles(ConfigFolderName)) do
                if file:sub(-5) == ".json" then
                    local filename = file:match("([^/\\]+)%.json$")
                    if filename then
                        table.insert(list, filename)
                    end
                end
            end
        end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end

    local function Ziaan_SaveConfig(name)
        name = (name and name ~= "") and name or getgenv().CurrentConfigName
        if not name or name == "" then name = "Default" end
        local path = ConfigFolderName .. "/" .. name .. ".json"
        pcall(function()
            if writefile then
                writefile(path, HttpService:JSONEncode(VD))
            end
        end)
    end

    local VD_To_Flag = {
        InfiniteJump = "Infinite Jump",
        KILLER_AntiBlind = "Anti Blind (Flashlight)",
        Fullbright = "Fullbright (lighting preset)",
        NoFog = "No Fog",
        AIM_VisCheck = "Visibility Check",
        AutoSkillcheck = "Auto Skillcheck",
        AutoSkillcheckMode = "Skillcheck Mode",
        SpeedValue = "Speed Value",
        AIM_Enabled = "Enable Aimbot",
        SURV_FleeKiller = "Flee Killer",
        SURV_FleeDistance = "Flee Distance",
        SURV_AutoParry      = "Auto Parry",
        SURV_ParryMode      = "Parry Mode",
        SURV_ParryRange     = "Parry Range",
        SURV_ShowParryCircle = "Show Parry Circle",
        Parry_Keybind       = "Parry Keybind",
        SURV_AntiKnock = "Anti Knock",
        MaxDistance = "Max ESP Distance",
        KILLER_DestroyPallets = "Destroy Pallets",
        KILLER_AutoBreakGene  = "Auto Kick Generator",
        KILLER_BlockVaults    = "Block All Vaults",
        KILLER_CustomMasked = "Custom Masked",
        ESP_Offscreen = "ESP Offscreen Arrows",
        KILLER_DoubleTap = "Double Tap",
        ESP_Skeleton = "ESP Skeleton",
        AUTO_ToFAim = "Silent Aim Twist Of Fate",
        AUTO_ToFAimRange = "ToF Aim Range (studs)",
        AUTO_ToFDotThreshold = "Aim Strictness",
        AUTO_AttackRange = "Attack Range",
        DRAWING_ESP = "Master Turn On Drawing ESP",
        AUTO_ToFTargetMode = "ToF Target Mode",
        AUTO_ToFAimPart = "ToF Aim Part",
        AUTO_ToFPredict = "ToF Prediction",
        AUTO_ToFBulletSpeed = "ToF Bullet Speed",
        SPEAR_Speed = "Spear Speed",
        SPEAR_Aimbot = "Silent Aim Veil",
        SURV_FirstPerson = "First Person Camera (Survivor)",
        AUTO_Attack = "Auto Attack",
        ESP_Velocity = "ESP Velocity Arrows",
        InstantHealSelf = "Instant Heal (Self)",
        AutoHealAll = "Auto Heal All",
        ESP_LowPerformance = "Low Performance Mode",
        SURV_AutoDropPallet = "Auto Drop Pallet",
        SURV_AutoDropPalletDist = "Pallet Trigger Range",
        SURV_AutoDropPalletMode = "Auto Drop Pallet Mode",
        SURV_AutoVault = "Auto Vault",
        SURV_AutoPalletSlide = "Auto Pallet (Slide)",
    }

    local function Ziaan_LoadConfig(name)
        name = (name and name ~= "") and name or getgenv().CurrentConfigName
        if not name or name == "" then name = "Default" end
        local path = ConfigFolderName .. "/" .. name .. ".json"
        pcall(function()
            if readfile and isfile and isfile(path) then
                local data = HttpService:JSONDecode(readfile(path))
                for key, value in pairs(data) do
                    VD[key] = value
                    local flagName = VD_To_Flag[key]
                    if flagName and Window and Window.ConfigElements and Window.ConfigElements[flagName] then
                        pcall(function()
                            local elem = Window.ConfigElements[flagName]
                            if elem.Set then elem:Set(value) end
                        end)
                    end
                end
                if getgenv().IYAN_SyncLoadedFeatures then pcall(getgenv().IYAN_SyncLoadedFeatures) end
            end
        end)
    end

    local function Ziaan_DeleteConfig(name)
        name = (name and name ~= "") and name or getgenv().CurrentConfigName
        if not name or name == "" or name == "Default" then return end
        local path = ConfigFolderName .. "/" .. name .. ".json"
        pcall(function()
            if isfile and isfile(path) and delfile then
                delfile(path)
            end
        end)
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
    LocalPlayer.CharacterRemoving:Connect(function(char)
        if char == Character or char == LocalPlayer.Character then
            Character, Humanoid, Root = nil, nil, nil
        end
    end)

    -- HELPERS: TEAM / COLORS
    local TeamColor  = Color3.fromRGB(0, 255, 0)
    local EnemyColor = Color3.fromRGB(255, 0, 0)

    local function isTeammate(player)
        return LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team
    end

    local function getPlayerColor(player)
        return isTeammate(player) and TeamColor or EnemyColor
    end

    -- CENTRALIZED METAMETHOD HOOK (__namecall)
    local IYAN_WorldReg
    local AntiFailHooked = false
    local oldNamecall

    local IYAN_ToFFireRemote = nil

    local function setupAntiFail()
        if getgenv().IYAN_AntiFailHooked then return end
        getgenv().IYAN_AntiFailHooked = true
        task.spawn(function()
            local ok, err = pcall(function()
                local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
                local Events  = ReplicatedStorage:WaitForChild("Events", 10)
                if not Remotes then
                    return
                end

                local tofItems  = Remotes:FindFirstChild("Items")
                local tofFolder = tofItems and tofItems:FindFirstChild("Twist of Fate")
                IYAN_ToFFireRemote = tofFolder and tofFolder:FindFirstChild("Fire")

                local _tofDeferred = false

                oldNamecall      = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    local args   = { ... }

                    if _tofDeferred then
                        return oldNamecall(self, ...)
                    elseif IYAN_ToFFireRemote and VD.AUTO_ToFAim
                    and self == IYAN_ToFFireRemote
                    and method == "FireServer"
                    and not checkcaller() then

                        if typeof(args[1]) == "Instance" and typeof(args[2]) == "Vector3" then
                            local myChar = LocalPlayer.Character
                            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                            if myRoot then
                                local bestPart, bestDist = nil, (VD.AUTO_ToFAimRange or 90)
                                local targetMode = VD.AUTO_ToFTargetMode or "Killer"
                                local aimPartName = VD.AUTO_ToFAimPart or "HumanoidRootPart"

                                if targetMode == "SCP" then
                                    if IYAN_WorldReg and IYAN_WorldReg.SCPZombie then
                                        for model, entry in pairs(IYAN_WorldReg.SCPZombie) do
                                            if model and model.Parent then
                                                local part
                                                if model:IsA("Model") then
                                                    part = model:FindFirstChild(aimPartName) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                                                elseif model:IsA("BasePart") then
                                                    part = model
                                                end
                                                part = part or (entry and entry.part)

                                                if part then
                                                    local d = (part.Position - myRoot.Position).Magnitude
                                                    if d <= bestDist then
                                                        bestDist = d
                                                        bestPart = part
                                                    end
                                                end
                                            end
                                        end
                                    end
                                else
                                    for _, plr in ipairs(Players:GetPlayers()) do
                                        if plr ~= LocalPlayer and plr.Character and plr.Team then
                                            local validTeam = (targetMode == "Killer" and plr.Team.Name == "Killer") or
                                                                (targetMode == "Survivor" and plr.Team.Name == "Survivors")

                                            if validTeam then
                                                local targetPart = plr.Character:FindFirstChild(aimPartName)
                                                local targetHum  = plr.Character:FindFirstChildOfClass("Humanoid")
                                                if targetPart and targetHum and targetHum.Health > 0 then
                                                    local d = (targetPart.Position - myRoot.Position).Magnitude
                                                    if d <= bestDist then
                                                        bestDist = d
                                                        bestPart = targetPart
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end

                                if bestPart then
                                    local gunPart = args[1]
                                    local gunPos
                                    pcall(function() gunPos = gunPart.Position end)
                                    gunPos = gunPos or myRoot.Position

                                    local targetCenter = bestPart.Position
                                    local targetPos = targetCenter

                                    if VD.AUTO_ToFPredict then
                                        local rawVel    = bestPart.AssemblyLinearVelocity
                                        local flatVel   = Vector3.new(rawVel.X, 0, rawVel.Z)
                                        local bulletSpeed = VD.AUTO_ToFBulletSpeed or 200
                                        local travelTime = bestDist / bulletSpeed
                                        targetPos = targetCenter + (flatVel * travelTime)
                                    end

                                    local dir    = targetPos - gunPos
                                    local newDir = (dir.Magnitude > 0.01) and dir.Unit or args[2]

                                    local camLook  = Camera.CFrame.LookVector
                                    local dotCheck = camLook:Dot(newDir)

                                    if dotCheck < (VD.AUTO_ToFDotThreshold or 0.5) then
                                        return
                                    end

                                    _tofDeferred = true
                                    task.defer(function()
                                        pcall(function()
                                            IYAN_ToFFireRemote:FireServer(args[1], newDir)
                                        end)
                                        _tofDeferred = false
                                    end)
                                    return
                                end
                            end
                        end
                    end

                    if oldNamecall then
                        return oldNamecall(self, ...)
                    end
                end)

                getgenv().IYAN_oldNamecall = oldNamecall
            end)
            if not ok then end
        end)
    end
    setupAntiFail()

    -- FIRST PERSON CAMERA
    local _fpWasSet = false
    local _fpOriginal = nil

    local function RestoreFirstPersonCamera()
        if not _fpWasSet then return end
        _fpWasSet = false

        pcall(function()
            if _fpOriginal then
                LocalPlayer.CameraMode = _fpOriginal.CameraMode or Enum.CameraMode.Classic
                LocalPlayer.CameraMaxZoomDistance = _fpOriginal.CameraMaxZoomDistance or 128
                LocalPlayer.CameraMinZoomDistance = _fpOriginal.CameraMinZoomDistance or 0.5
            else
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                LocalPlayer.CameraMaxZoomDistance = 128
            end
        end)

        local char = LocalPlayer.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then head.LocalTransparencyModifier = 0 end
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Accessory") then
                    local handle = obj:FindFirstChild("Handle")
                    if handle then handle.LocalTransparencyModifier = 0 end
                end
            end
        end

        _fpOriginal = nil
    end

    RunService.RenderStepped:Connect(function()
        pcall(function()
            if VD.SURV_FirstPerson then
                local isSurvivor = LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors"
                if isSurvivor then
                    if not _fpWasSet then
                        _fpOriginal = {
                            CameraMode = LocalPlayer.CameraMode,
                            CameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance,
                            CameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance,
                        }
                    end

                    if LocalPlayer.CameraMode ~= Enum.CameraMode.LockFirstPerson then
                        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
                    end
                    if LocalPlayer.CameraMaxZoomDistance ~= 0 then
                        LocalPlayer.CameraMaxZoomDistance = 0
                    end

                    local char = LocalPlayer.Character
                    if char then
                        local head = char:FindFirstChild("Head")
                        if head then
                            head.LocalTransparencyModifier = 1
                        end
                        for _, obj in ipairs(char:GetChildren()) do
                            if obj:IsA("Accessory") then
                                local handle = obj:FindFirstChild("Handle")
                                if handle then
                                    handle.LocalTransparencyModifier = 1
                                end
                            end
                        end
                    end

                    _fpWasSet = true
                elseif _fpWasSet then
                    RestoreFirstPersonCamera()
                end
            elseif _fpWasSet then
                RestoreFirstPersonCamera()
            end
        end)
    end)

    -- VISUAL HIGHLIGHT ESP V2
    do
        if getgenv().IYAN_VD_VisualESP_Cleanup then
            pcall(getgenv().IYAN_VD_VisualESP_Cleanup)
        end

        local LP = LocalPlayer
        local IYAN_Dead = false
        local IYAN_ControlsAdded = false

        local IYAN_ESPState = {
            PlayerMasterESP = false,
            WorldMasterESP = false,
            ESPFillTransparency = 0.95,
            ESPOutlineTransparency = 0.3,
            ESPTextSize = 12,

            SurvivorESP = false,
            KillerESP = false,
            SpectatorESP = false,
            Nametags = false,
            DistanceESP = false,
            SurvivorItemsESP = false,

            SurvivorColor = Color3.fromRGB(0, 255, 0),
            KillerColor = Color3.fromRGB(255, 0, 0),
            SpectatorColor = Color3.fromRGB(255, 255, 255),

            GeneratorESP = false,
            HookESP = false,
            GateESP = false,
            WindowESP = false,
            PalletESP = false,
            SCPZombieESP = false,
            WorldNametags = false,
            WorldDistanceESP = false,

            GeneratorColor = Color3.fromRGB(0, 170, 255),
            HookColor = Color3.fromRGB(255, 0, 0),
            GateColor = Color3.fromRGB(255, 225, 0),
            WindowColor = Color3.fromRGB(255, 255, 255),
            PalletColor = Color3.fromRGB(255, 140, 0),
            SCPZombieColor = Color3.fromRGB(128, 0, 128),
        }

        getgenv().IYAN_VD_VisualESP_State = IYAN_ESPState

        IYAN_WorldReg = {
            Generator = {},
            Hook = {},
            Gate = {},
            Window = {},
            Palletwrong = {},
            SCPZombie = {},
        }

        local IYAN_MapAdd, IYAN_MapRem = {}, {}
        local IYAN_PlayerConns = {}
        local IYAN_Connections = {}
        local IYAN_PalletState = setmetatable({}, { __mode = "k" })
        local IYAN_WindowState = setmetatable({}, { __mode = "k" })
        local IYAN_InstanceIds = setmetatable({}, { __mode = "k" })
        local IYAN_NextId = 0
        local IYAN_PlayerLoopThread = nil
        local IYAN_WorldLoopThread = nil
        local IYAN_ESPFolder = nil

        local IYAN_DisplayNames = {
            ["Motion Tracker"] = true,
            ["Gate"] = true,
            ["Flashlight"] = true,
            ["Bandage"] = true,
            ["Parrying Dagger"] = true,
            ["Adrenaline Shot"] = true,
            ["Twist of Fate"] = true,
            ["Shadow Clone"] = true,
            ["Holy Water"] = true,
            ["WaxBound Candle"] = true,
            ["Riot Shield"] = true,
            ["Emperor"] = true,
            ["AWP"] = true,
        }

        local function IYAN_Alive(inst)
            if not inst then return false end
            local ok, parent = pcall(function() return inst.Parent end)
            return ok and parent ~= nil
        end

        local function IYAN_Clamp(n, lo, hi)
            n = tonumber(n) or lo
            if n < lo then return lo end
            if n > hi then return hi end
            return n
        end

        local function IYAN_PlayerKey(player)
            local id = player and player.UserId
            if id and id ~= 0 then return tostring(id) end
            return tostring(player and player.Name or "Unknown")
        end

        local function IYAN_EspId(inst)
            if not inst then return "nil" end
            local id = IYAN_InstanceIds[inst]
            if id then return id end
            IYAN_NextId = IYAN_NextId + 1
            id = tostring(IYAN_NextId)
            IYAN_InstanceIds[inst] = id
            return id
        end

        local function IYAN_GetESPParent()
            local okCore, core = pcall(function() return game:GetService("CoreGui") end)
            if okCore and core then return core end
            if gethui then
                local okHui, hui = pcall(gethui)
                if okHui and hui then return hui end
            end
            local playerGui = LP and LP:FindFirstChildOfClass("PlayerGui")
            if playerGui then return playerGui end
            return Workspace
        end

        local function IYAN_GetESPFolder()
            if IYAN_ESPFolder and IYAN_ESPFolder.Parent then
                return IYAN_ESPFolder
            end

            local parent = IYAN_GetESPParent()
            local old = parent:FindFirstChild("IYAN_VisualESP") or parent:FindFirstChild("ZiaanHub_ESP")
            if old then old:Destroy() end

            local folder = Instance.new("Folder")
            folder.Name = "IYAN_VisualESP"
            folder.Parent = parent
            IYAN_ESPFolder = folder
            return folder
        end

        local function IYAN_ClearPrefix(prefix, keepName)
            local folder = IYAN_GetESPFolder()
            local keptExact = false
            for _, child in ipairs(folder:GetChildren()) do
                if child.Name:sub(1, #prefix) == prefix then
                    if child.Name == keepName and not keptExact then
                        keptExact = true
                    else
                        child:Destroy()
                    end
                end
            end
        end

        local function IYAN_ValidPart(part)
            return part and IYAN_Alive(part) and part:IsA("BasePart")
        end

        local function IYAN_FirstBasePart(inst)
            if not IYAN_Alive(inst) then return nil end
            if inst:IsA("BasePart") then return inst end
            if inst:IsA("Model") then
                if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") and IYAN_Alive(inst.PrimaryPart) then
                    return inst.PrimaryPart
                end
                local part = inst:FindFirstChildWhichIsA("BasePart", true)
                if IYAN_ValidPart(part) then return part end
            end
            if inst:IsA("Tool") then
                local handle = inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart")
                if IYAN_ValidPart(handle) then return handle end
            end
            return nil
        end

        local function IYAN_GetRole(player)
            local teamName = player.Team and player.Team.Name and player.Team.Name:lower() or ""
            if teamName:find("killer") then return "Killer" end
            if teamName:find("survivor") then return "Survivor" end
            if teamName:find("spect") then return "Spectator" end
            return "Survivor"
        end

        local function IYAN_PlayerRoleEnabled(player)
            local role = IYAN_GetRole(player)
            if role == "Killer" then return IYAN_ESPState.KillerESP end
            if role == "Spectator" then return IYAN_ESPState.SpectatorESP end
            return IYAN_ESPState.SurvivorESP
        end

        local function IYAN_PlayerColor(player)
            local role = IYAN_GetRole(player)
            if role == "Killer" then return IYAN_ESPState.KillerColor end
            if role == "Spectator" then return IYAN_ESPState.SpectatorColor end
            return IYAN_ESPState.SurvivorColor
        end

        getgenv().IYAN_VD_VisualESP_HasPlayerText = function(player)
            if not player or player == LP then return false end
            return IYAN_ESPState.PlayerMasterESP
                and IYAN_PlayerRoleEnabled(player)
                and (IYAN_ESPState.Nametags or IYAN_ESPState.DistanceESP)
        end

        local function IYAN_EnsureHighlight(name, adornee, color, isPlayer)
            if not (adornee and IYAN_Alive(adornee)) then return nil end
            local folder = IYAN_GetESPFolder()
            IYAN_ClearPrefix(name, name)

            local hl = folder:FindFirstChild(name)
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = name
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = folder
            end

            hl.Adornee = adornee
            hl.FillColor = color
            hl.OutlineColor = color
            if isPlayer then
                hl.FillTransparency = IYAN_ESPState.ESPFillTransparency
                hl.OutlineTransparency = IYAN_ESPState.ESPOutlineTransparency
            else
                hl.FillTransparency = 0.98
                hl.OutlineTransparency = 0.5
            end
            hl.Enabled = true
            return hl
        end

        local function IYAN_DestroyChild(name)
            local folder = IYAN_GetESPFolder()
            local child = folder:FindFirstChild(name)
            if child then child:Destroy() end
        end

        local function IYAN_ClearPlayerESP(player)
            if not player or player == LP then return end
            local key = IYAN_PlayerKey(player)
            IYAN_DestroyChild("IYAN_PlayerHL_" .. key)
            IYAN_DestroyChild("IYAN_PlayerTag_" .. key)
            IYAN_DestroyChild("IYAN_PlayerItem_" .. key)
        end

        local function IYAN_ClearAllPlayerESP()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    IYAN_ClearPlayerESP(player)
                end
            end
        end

        local function IYAN_GetSurvivorItem(player)
            local character = player.Character
            if not character then return nil end
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("Tool") or obj:IsA("Accessory") or obj:IsA("Model") then
                    if IYAN_DisplayNames[obj.Name] then
                        return obj.Name
                    end
                end
            end
            return nil
        end

        local function IYAN_GetItemImageId(itemName)
            local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
            if not itemsFolder then return nil end
            local itemObj = itemsFolder:FindFirstChild(itemName)
            if not itemObj then return nil end

            if itemObj:IsA("Decal") or itemObj:IsA("Texture") then return itemObj.Texture end
            local texture = itemObj:FindFirstChildWhichIsA("Decal", true) or itemObj:FindFirstChildWhichIsA("Texture", true)
            if texture then return texture.Texture end
            local namedTexture = itemObj:FindFirstChild("Texture", true)
            if namedTexture and (namedTexture:IsA("Decal") or namedTexture:IsA("Texture")) then
                return namedTexture.Texture
            end
            return nil
        end

        local function IYAN_SetBillboardLine(parent, index, count, data)
            local label = parent:FindFirstChild("Line" .. index)
            if not label then
                label = Instance.new("TextLabel")
                label.Name = "Line" .. index
                label.BackgroundTransparency = 1
                label.BorderSizePixel = 0
                label.Font = Enum.Font.Gotham
                label.TextStrokeTransparency = 0.65
                label.TextStrokeColor3 = Color3.new(0, 0, 0)
                label.Parent = parent
            end
            label.Size = UDim2.new(1, 0, 1 / count, 0)
            label.Position = UDim2.new(0, 0, (index - 1) / count, 0)
            label.TextSize = IYAN_ESPState.ESPTextSize
            label.TextColor3 = data.Color
            label.Text = data.Text
        end

        local function IYAN_PruneBillboardLines(parent, count)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("TextLabel") then
                    local index = tonumber(child.Name:match("%d+"))
                    if index and index > count then
                        child:Destroy()
                    end
                end
            end
        end

        local function IYAN_UpdatePlayerTag(player, character, head, color)
            local key = IYAN_PlayerKey(player)
            local tagName = "IYAN_PlayerTag_" .. key
            local folder = IYAN_GetESPFolder()
            IYAN_ClearPrefix("IYAN_PlayerTag_" .. key, tagName)

            if not IYAN_ValidPart(head) then
                IYAN_DestroyChild(tagName)
                return
            end

            local lines = {}
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
            local distanceText = ""
            if IYAN_ESPState.DistanceESP and root and targetRoot then
                distanceText = "[" .. tostring(math.floor((root.Position - targetRoot.Position).Magnitude)) .. "m]"
            end

            local nameText = IYAN_ESPState.Nametags and player.Name or ""
            local mainLine = ""
            if nameText ~= "" and distanceText ~= "" then
                mainLine = nameText .. " " .. distanceText
            elseif nameText ~= "" then
                mainLine = nameText
            elseif distanceText ~= "" then
                mainLine = distanceText
            end

            if mainLine ~= "" then
                table.insert(lines, { Text = mainLine, Color = color })
            end

            if #lines == 0 then
                IYAN_DestroyChild(tagName)
                return
            end

            local tag = folder:FindFirstChild(tagName)
            if not tag then
                tag = Instance.new("BillboardGui")
                tag.Name = tagName
                tag.AlwaysOnTop = true
                tag.LightInfluence = 0
                tag.MaxDistance = 0
                tag.Parent = folder
            end

            tag.Adornee = head
            tag.Enabled = true
            tag.Size = UDim2.new(0, 220, 0, #lines * 20)
            tag.StudsOffset = Vector3.new(0, 0.4, 0)

            for i, data in ipairs(lines) do
                IYAN_SetBillboardLine(tag, i, #lines, data)
            end
            IYAN_PruneBillboardLines(tag, #lines)
        end

        local function IYAN_UpdatePlayerItemIcon(player, torso)
            local key = IYAN_PlayerKey(player)
            local iconName = "IYAN_PlayerItem_" .. key
            local folder = IYAN_GetESPFolder()
            IYAN_ClearPrefix("IYAN_PlayerItem_" .. key, iconName)

            if not IYAN_ValidPart(torso) then
                IYAN_DestroyChild(iconName)
                return
            end

            local itemName = IYAN_GetSurvivorItem(player)
            local imageId = itemName and IYAN_GetItemImageId(itemName) or nil
            if not imageId then
                IYAN_DestroyChild(iconName)
                return
            end

            local icon = folder:FindFirstChild(iconName)
            if not icon then
                icon = Instance.new("BillboardGui")
                icon.Name = iconName
                icon.AlwaysOnTop = true
                icon.LightInfluence = 0
                icon.MaxDistance = 0
                icon.Size = UDim2.fromOffset(20, 20)
                icon.StudsOffset = Vector3.new(0, 0, -1.6)
                icon.Parent = folder

                local image = Instance.new("ImageLabel")
                image.Name = "ImageLabel"
                image.BackgroundTransparency = 1
                image.Size = UDim2.fromScale(1, 1)
                image.Parent = icon
            end

            icon.Adornee = torso
            icon.Enabled = true
            local image = icon:FindFirstChild("ImageLabel")
            if image then image.Image = imageId end
        end

        local IYAN_ApplyPlayerESP
        IYAN_ApplyPlayerESP = function(player)
            if IYAN_Dead or not player or player == LP then return end
            local character = player.Character
            if not (character and IYAN_Alive(character)) then
                IYAN_ClearPlayerESP(player)
                return
            end

            local key = IYAN_PlayerKey(player)
            local enabled = IYAN_ESPState.PlayerMasterESP and IYAN_PlayerRoleEnabled(player)
            if not enabled then
                IYAN_ClearPlayerESP(player)
                return
            end

            local color = IYAN_PlayerColor(player)
            local head = character:FindFirstChild("Head")
            local torso = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

            IYAN_EnsureHighlight("IYAN_PlayerHL_" .. key, character, color, true)
            IYAN_UpdatePlayerTag(player, character, head, color)

            if IYAN_GetRole(player) == "Survivor" and IYAN_ESPState.SurvivorItemsESP then
                IYAN_UpdatePlayerItemIcon(player, torso)
            else
                IYAN_DestroyChild("IYAN_PlayerItem_" .. key)
            end
        end

        local function IYAN_RefreshAllPlayers()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    pcall(IYAN_ApplyPlayerESP, player)
                end
            end
        end

        local function IYAN_StartPlayerLoop()
            if IYAN_PlayerLoopThread then return end
            IYAN_PlayerLoopThread = task.spawn(function()
                while not IYAN_Dead and IYAN_ESPState.PlayerMasterESP do
                    IYAN_RefreshAllPlayers()
                    task.wait(0.25)
                end
                IYAN_PlayerLoopThread = nil
            end)
        end

        local function IYAN_WatchPlayer(player)
            if player == LP then return end
            if IYAN_PlayerConns[player] then
                for _, conn in ipairs(IYAN_PlayerConns[player]) do
                    if conn then pcall(function() conn:Disconnect() end) end
                end
            end

            IYAN_PlayerConns[player] = {}
            table.insert(IYAN_PlayerConns[player], player.CharacterAdded:Connect(function(char)
                IYAN_ClearPlayerESP(player)
                task.delay(0.15, function()
                    if not IYAN_Dead then pcall(IYAN_ApplyPlayerESP, player) end
                end)
            end))
            table.insert(IYAN_PlayerConns[player], player.CharacterRemoving:Connect(function()
                IYAN_ClearPlayerESP(player)
            end))
            table.insert(IYAN_PlayerConns[player], player:GetPropertyChangedSignal("Team"):Connect(function()
                IYAN_ClearPlayerESP(player)
                pcall(IYAN_ApplyPlayerESP, player)
            end))

            if player.Character then
                pcall(IYAN_ApplyPlayerESP, player)
            end
        end

        local function IYAN_UnwatchPlayer(player)
            IYAN_ClearPlayerESP(player)
            if IYAN_PlayerConns[player] then
                for _, conn in ipairs(IYAN_PlayerConns[player]) do
                    if conn then pcall(function() conn:Disconnect() end) end
                end
            end
            IYAN_PlayerConns[player] = nil
        end

        local function IYAN_PickWorldPart(model, cat)
            if not (model and IYAN_Alive(model)) then return nil end
            if cat == "Generator" then
                local hitbox = model:FindFirstChild("HitBox", true) or model:FindFirstChild("GeneratorPoint", true)
                if IYAN_ValidPart(hitbox) then return hitbox end
            elseif cat == "Palletwrong" then
                local candidates = {
                    model:FindFirstChild("HumanoidRootPart", true),
                    model:FindFirstChild("PrimaryPartPallet", true),
                    model:FindFirstChild("Primary1", true),
                    model:FindFirstChild("Primary2", true),
                    model:FindFirstChild("PalletPoint", true),
                    model:FindFirstChild("PalletPointSlide", true),
                }
                for _, part in ipairs(candidates) do
                    if IYAN_ValidPart(part) then return part end
                end
            elseif cat == "Window" then
                local vault = model:FindFirstChild("VaultPoint", true) or model:FindFirstChild("VaultTrigger", true)
                if IYAN_ValidPart(vault) then return vault end
            elseif cat == "SCPZombie" then
                local root = model:FindFirstChild("HumanoidRootPart", true)
                if IYAN_ValidPart(root) then return root end
                local torso = model:FindFirstChild("UpperTorso", true) or model:FindFirstChild("Torso", true)
                if IYAN_ValidPart(torso) then return torso end
                return nil
            end
            return IYAN_FirstBasePart(model)
        end

        local function IYAN_GeneratorLabel(model)
            local pct = tonumber(model:GetAttribute("RepairProgress")) or 0
            if pct >= 0 and pct <= 1.001 then pct = pct * 100 end
            pct = IYAN_Clamp(pct, 0, 100)

            local repairers = tonumber(model:GetAttribute("PlayersRepairingCount")) or 0
            local paused = model:GetAttribute("ProgressPaused") == true
            local kickcount = tonumber(model:GetAttribute("kickcount")) or 0
            local abyss50 = model:GetAttribute("Abyss50Triggered") == true

            local parts = { "Gen " .. tostring(math.floor(pct + 0.5)) .. "%" }
            if repairers > 0 then table.insert(parts, "(" .. repairers .. "p)") end
            if paused then table.insert(parts, "Pause") end
            if abyss50 then table.insert(parts, "Warn") end
            if kickcount > 0 then table.insert(parts, "K:" .. kickcount) end

            local hue = IYAN_Clamp((pct / 100) * 0.33, 0, 0.33)
            return table.concat(parts, " "), Color3.fromHSV(hue, 1, 1)
        end

        local function IYAN_HasBasePart(model)
            if not (model and IYAN_Alive(model)) then return false end
            return model:FindFirstChildWhichIsA("BasePart", true) ~= nil
        end

        local function IYAN_IsPalletGone(model)
            if not IYAN_Alive(model) then return true end
            if not model:IsDescendantOf(Workspace) then return true end
            if IYAN_PalletState[model] == "DEST" then return true end
            local ok, destroyed = pcall(function() return model:GetAttribute("Destroyed") end)
            if ok and destroyed == true then return true end
            return not IYAN_HasBasePart(model)
        end

        local function IYAN_WorldKey(cat, model)
            return "IYAN_World_" .. cat .. "_" .. IYAN_EspId(model)
        end

        local function IYAN_ClearWorldVisual(cat, model)
            if not model then return end
            IYAN_DestroyChild(IYAN_WorldKey(cat, model) .. "_HL")
            IYAN_DestroyChild(IYAN_WorldKey(cat, model) .. "_Tag")
        end

        local function IYAN_RemoveWorldEntry(cat, model)
            if not IYAN_WorldReg[cat] or not IYAN_WorldReg[cat][model] then return end
            IYAN_ClearWorldVisual(cat, model)
            IYAN_WorldReg[cat][model] = nil
        end

        local function IYAN_EnsureWorldEntry(cat, model)
            if not IYAN_Alive(model) or not IYAN_WorldReg[cat] or IYAN_WorldReg[cat][model] then return end
            if cat == "Palletwrong" and IYAN_IsPalletGone(model) then return end
            local part = IYAN_PickWorldPart(model, cat)
            if not IYAN_ValidPart(part) then return end
            IYAN_WorldReg[cat][model] = { part = part }
        end

        local function IYAN_RegisterWorldDescendant(obj)
            if not IYAN_Alive(obj) then return end
            local validCats = { Generator = true, Hook = true, Gate = true, Window = true, Palletwrong = true }

            if obj:IsA("Model") then
                if validCats[obj.Name] then
                    IYAN_EnsureWorldEntry(obj.Name, obj)
                    return
                end
                local lower = obj.Name:lower()
                if lower:find("scp") or lower:find("zombie") then
                    IYAN_EnsureWorldEntry("SCPZombie", obj)
                end
                return
            end

            if obj:IsA("BasePart") then
                local parent = obj.Parent
                while parent and parent ~= Workspace do
                    if parent:IsA("Model") then
                        if validCats[parent.Name] then
                            IYAN_EnsureWorldEntry(parent.Name, parent)
                            return
                        end
                        local lower = parent.Name:lower()
                        if lower:find("scp") or lower:find("zombie") then
                            IYAN_EnsureWorldEntry("SCPZombie", parent)
                            return
                        end
                    end
                    parent = parent.Parent
                end
            end
        end

        local function IYAN_UnregisterWorldDescendant(obj)
            if not obj then return end
            local validCats = { Generator = true, Hook = true, Gate = true, Window = true, Palletwrong = true }

            if obj:IsA("Model") then
                if validCats[obj.Name] then
                    IYAN_RemoveWorldEntry(obj.Name, obj)
                    return
                end
                local lower = obj.Name:lower()
                if lower:find("scp") or lower:find("zombie") then
                    IYAN_RemoveWorldEntry("SCPZombie", obj)
                end
                return
            end

            if obj:IsA("BasePart") then
                for cat, models in pairs(IYAN_WorldReg) do
                    for model, entry in pairs(models) do
                        if entry.part == obj then
                            IYAN_RemoveWorldEntry(cat, model)
                        end
                    end
                end
            end
        end

        local function IYAN_AttachESPRoot(root)
            if not root or IYAN_MapAdd[root] then return end
            IYAN_MapAdd[root] = root.DescendantAdded:Connect(IYAN_RegisterWorldDescendant)
            IYAN_MapRem[root] = root.DescendantRemoving:Connect(IYAN_UnregisterWorldDescendant)
            for _, descendant in ipairs(root:GetDescendants()) do
                IYAN_RegisterWorldDescendant(descendant)
            end
        end

        local function IYAN_RefreshESPRoots()
            for _, conn in pairs(IYAN_MapAdd) do
                if conn then pcall(function() conn:Disconnect() end) end
            end
            for _, conn in pairs(IYAN_MapRem) do
                if conn then pcall(function() conn:Disconnect() end) end
            end
            IYAN_MapAdd, IYAN_MapRem = {}, {}

            for cat, models in pairs(IYAN_WorldReg) do
                for model in pairs(models) do
                    IYAN_ClearWorldVisual(cat, model)
                end
                IYAN_WorldReg[cat] = {}
            end

            local map = Workspace:FindFirstChild("Map")
            local map1 = Workspace:FindFirstChild("Map1")
            if map then IYAN_AttachESPRoot(map) end
            if map1 then IYAN_AttachESPRoot(map1) end
        end

        local function IYAN_LabelForPallet(model)
            local state = IYAN_PalletState[model] or "UP"
            if state == "DOWN" then return "Pallet (down)" end
            if state == "DEST" then return "Pallet (destroyed)" end
            if state == "SLIDE" then return "Pallet (slide)" end
            return "Pallet"
        end

        local function IYAN_LabelForWindow(model)
            local state = IYAN_WindowState[model] or "READY"
            if state == "BUSY" then return "Window (busy)" end
            return "Window"
        end

        local function IYAN_AnyWorldEnabled()
            return IYAN_ESPState.WorldMasterESP and (
                IYAN_ESPState.GeneratorESP or
                IYAN_ESPState.HookESP or
                IYAN_ESPState.GateESP or
                IYAN_ESPState.WindowESP or
                IYAN_ESPState.PalletESP or
                IYAN_ESPState.SCPZombieESP
            )
        end

        local function IYAN_WorldCategoryData(cat)
            if cat == "Generator" then return IYAN_ESPState.GeneratorESP, IYAN_ESPState.GeneratorColor end
            if cat == "Hook" then return IYAN_ESPState.HookESP, IYAN_ESPState.HookColor end
            if cat == "Gate" then return IYAN_ESPState.GateESP, IYAN_ESPState.GateColor end
            if cat == "Window" then return IYAN_ESPState.WindowESP, IYAN_ESPState.WindowColor end
            if cat == "Palletwrong" then return IYAN_ESPState.PalletESP, IYAN_ESPState.PalletColor end
            if cat == "SCPZombie" then return IYAN_ESPState.SCPZombieESP, IYAN_ESPState.SCPZombieColor end
            return false, Color3.new(1, 1, 1)
        end

        local function IYAN_UpdateWorldTag(cat, model, part, color)
            local key = IYAN_WorldKey(cat, model)
            local tagName = key .. "_Tag"
            local folder = IYAN_GetESPFolder()
            IYAN_ClearPrefix(tagName, tagName)

            if not IYAN_ValidPart(part) or not model then
                IYAN_DestroyChild(tagName)
                return
            end

            local totalPos = Vector3.zero
            local count = 0
            for _, child in ipairs(model:GetDescendants()) do
                if child:IsA("BasePart") and IYAN_Alive(child) then
                    totalPos = totalPos + child.Position
                    count = count + 1
                end
            end

            local centerOffset = Vector3.zero
            if count > 0 then
                local center = totalPos / count
                centerOffset = center - part.Position
            end

            local lines = {}
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local distanceText = ""
            if IYAN_ESPState.WorldDistanceESP and root then
                distanceText = "[" .. tostring(math.floor((root.Position - part.Position).Magnitude)) .. "m]"
            end

            local nameText = ""
            local labelColor = color
            if IYAN_ESPState.WorldNametags then
                if cat == "Generator" then
                    local txt, genColor = IYAN_GeneratorLabel(model)
                    nameText = txt
                    labelColor = genColor
                elseif cat == "Palletwrong" then
                    nameText = IYAN_LabelForPallet(model)
                elseif cat == "Window" then
                    nameText = IYAN_LabelForWindow(model)
                elseif cat == "SCPZombie" then
                    nameText = model.Name
                else
                    nameText = cat
                end
            end

            local mainLine = ""
            if nameText ~= "" and distanceText ~= "" then
                mainLine = nameText .. " " .. distanceText
            elseif nameText ~= "" then
                mainLine = nameText
            elseif distanceText ~= "" then
                mainLine = distanceText
            end

            if mainLine ~= "" then
                table.insert(lines, { Text = mainLine, Color = labelColor })
            end

            if #lines == 0 then
                IYAN_DestroyChild(tagName)
                return
            end

            local tag = folder:FindFirstChild(tagName)
            if not tag then
                tag = Instance.new("BillboardGui")
                tag.Name = tagName
                tag.AlwaysOnTop = true
                tag.LightInfluence = 0
                tag.MaxDistance = 0
                tag.Parent = folder
            end

            tag.Adornee = part
            tag.Enabled = true
            tag.Size = UDim2.new(0, 220, 0, #lines * 20)
            tag.StudsOffset = centerOffset

            for i, data in ipairs(lines) do
                IYAN_SetBillboardLine(tag, i, #lines, data)
            end
            IYAN_PruneBillboardLines(tag, #lines)
        end

        local function IYAN_ClearAllWorldESP()
            for cat, models in pairs(IYAN_WorldReg) do
                for model in pairs(models) do
                    IYAN_ClearWorldVisual(cat, model)
                end
            end
        end

        local function IYAN_StartWorldLoop()
            if IYAN_WorldLoopThread then return end
            IYAN_WorldLoopThread = task.spawn(function()
                while not IYAN_Dead and IYAN_AnyWorldEnabled() do
                    for cat, models in pairs(IYAN_WorldReg) do
                        local enabled, color = IYAN_WorldCategoryData(cat)
                        if enabled and IYAN_ESPState.WorldMasterESP then
                            local n = 0
                            for model, entry in pairs(models) do
                                if cat == "Palletwrong" and IYAN_IsPalletGone(model) then
                                    IYAN_RemoveWorldEntry(cat, model)
                                elseif model and IYAN_Alive(model) then
                                    local part = entry.part
                                    if not IYAN_ValidPart(part) or (model:IsA("Model") and not part:IsDescendantOf(model)) then
                                        entry.part = IYAN_PickWorldPart(model, cat)
                                        part = entry.part
                                    end

                                    if IYAN_ValidPart(part) then
                                        local key = IYAN_WorldKey(cat, model)
                                        IYAN_EnsureHighlight(key .. "_HL", model, color, false)
                                        IYAN_UpdateWorldTag(cat, model, part, color)
                                    else
                                        IYAN_RemoveWorldEntry(cat, model)
                                    end
                                else
                                    IYAN_RemoveWorldEntry(cat, model)
                                end

                                n = n + 1
                                if n % 60 == 0 then task.wait() end
                            end
                        else
                            for model in pairs(models) do
                                IYAN_ClearWorldVisual(cat, model)
                            end
                        end
                    end
                    task.wait(0.25)
                end
                IYAN_WorldLoopThread = nil
            end)
        end

        local function IYAN_Selected(selected, name)
            if type(selected) ~= "table" then return false end
            if selected[name] ~= nil then return selected[name] == true end
            for _, value in pairs(selected) do
                if value == name then return true end
            end
            return false
        end

        getgenv().IYAN_AddVisualESPControls = function(VisualTabRef)
            if not VisualTabRef or IYAN_ControlsAdded then return end
            IYAN_ControlsAdded = true

            local settingsSection = VisualTabRef:AddSection({
                Position = "Center",
                Name = "Highlight ESP Settings",
                Icon = "solar:settings-bold",
                Box = true,
                BoxBorder = true,
                Opened = false,
            })

            settingsSection:AddSlider({
                Name = "ESP Fill Transparency",
                Flag = "IYAN ESP Fill Transparency",
                Min = 0,
                Max = 1,
                Default = IYAN_ESPState.ESPFillTransparency,
                Increment = 0.01,
                Callback = function(value)
                    IYAN_ESPState.ESPFillTransparency = value
                    IYAN_RefreshAllPlayers()
                end,
            })

            settingsSection:AddSlider({
                Name = "ESP Outline Transparency",
                Flag = "IYAN ESP Outline Transparency",
                Min = 0,
                Max = 1,
                Default = IYAN_ESPState.ESPOutlineTransparency,
                Increment = 0.01,
                Callback = function(value)
                    IYAN_ESPState.ESPOutlineTransparency = value
                    IYAN_RefreshAllPlayers()
                end,
            })

            settingsSection:AddSlider({
                Name = "ESP Text Size",
                Flag = "IYAN ESP Text Size",
                Min = 8,
                Max = 22,
                Default = IYAN_ESPState.ESPTextSize,
                Increment = 1,
                Callback = function(value)
                    IYAN_ESPState.ESPTextSize = value
                    IYAN_RefreshAllPlayers()
                end,
            })

            local playerSection = VisualTabRef:AddSection({
                Position = "Center",
                Name = "Player Highlight ESP",
                Icon = "solar:users-group-rounded-bold",
                Box = true,
                BoxBorder = true,
                Opened = false,
            })

            playerSection:AddToggle({
                Name = "Enable Player ESP",
                Flag = "IYAN Enable Player ESP",
                Default = false,
                Callback = function(state)
                    IYAN_ESPState.PlayerMasterESP = state
                    if state then
                        IYAN_StartPlayerLoop()
                        IYAN_RefreshAllPlayers()
                    else
                        IYAN_ClearAllPlayerESP()
                    end
                end,
            })

            playerSection:AddDropdown({
                Name = "Select Player ESP",
                Flag = "IYAN Select Player ESP",
                Values = { "Survivor ESP", "Killer ESP", "Spectator ESP", "Survivor Items ESP" },
                Multi = true,
                AllowNone = true,
                Default = {},
                Callback = function(selected)
                    IYAN_ESPState.SurvivorESP = IYAN_Selected(selected, "Survivor ESP")
                    IYAN_ESPState.KillerESP = IYAN_Selected(selected, "Killer ESP")
                    IYAN_ESPState.SpectatorESP = IYAN_Selected(selected, "Spectator ESP")
                    IYAN_ESPState.SurvivorItemsESP = IYAN_Selected(selected, "Survivor Items ESP")

                    if IYAN_ESPState.PlayerMasterESP then
                        IYAN_StartPlayerLoop()
                        IYAN_RefreshAllPlayers()
                    else
                        IYAN_ClearAllPlayerESP()
                    end
                end,
            })

            playerSection:AddToggle({
                Name = "Player Nametags",
                Flag = "IYAN Player Nametags",
                Default = false,
                Callback = function(state)
                    IYAN_ESPState.Nametags = state
                    if IYAN_ESPState.PlayerMasterESP then
                        IYAN_StartPlayerLoop()
                        IYAN_RefreshAllPlayers()
                    else
                        IYAN_ClearAllPlayerESP()
                    end
                end,
            })

            playerSection:AddToggle({
                Name = "Player Distance ESP",
                Flag = "IYAN Player Distance ESP",
                Default = false,
                Callback = function(state)
                    IYAN_ESPState.DistanceESP = state
                    if IYAN_ESPState.PlayerMasterESP then
                        IYAN_StartPlayerLoop()
                        IYAN_RefreshAllPlayers()
                    else
                        IYAN_ClearAllPlayerESP()
                    end
                end,
            })

            pcall(function() playerSection:AddDivider({ Text = "Colors" }) end)
            playerSection:AddColorPicker({ Name = "Survivor Color", Flag = "IYAN Survivor Color", Default = IYAN_ESPState.SurvivorColor, Callback = function(color) IYAN_ESPState.SurvivorColor = color; IYAN_RefreshAllPlayers() end })
            playerSection:AddColorPicker({ Name = "Killer Color", Flag = "IYAN Killer Color", Default = IYAN_ESPState.KillerColor, Callback = function(color) IYAN_ESPState.KillerColor = color; IYAN_RefreshAllPlayers() end })
            playerSection:AddColorPicker({ Name = "Spectator Color", Flag = "IYAN Spectator Color", Default = IYAN_ESPState.SpectatorColor, Callback = function(color) IYAN_ESPState.SpectatorColor = color; IYAN_RefreshAllPlayers() end })

            local worldSection = VisualTabRef:AddSection({
                Position = "Center",
                Name = "World Highlight ESP",
                Icon = "solar:map-point-wave-bold",
                Box = true,
                BoxBorder = true,
                Opened = false,
            })

            worldSection:AddToggle({
                Name = "Enable World ESP",
                Flag = "IYAN Enable World ESP",
                Default = false,
                Callback = function(state)
                    IYAN_ESPState.WorldMasterESP = state
                    if state then
                        IYAN_RefreshESPRoots()
                        if IYAN_AnyWorldEnabled() then IYAN_StartWorldLoop() end
                    else
                        IYAN_ClearAllWorldESP()
                    end
                end,
            })

            worldSection:AddDropdown({
                Name = "Select World Objects",
                Flag = "IYAN Select World Objects",
                Values = { "Generators", "Hooks", "Gates", "Windows", "Pallets", "SCP / Zombie" },
                Multi = true,
                AllowNone = true,
                Default = {},
                Callback = function(selected)
                    IYAN_ESPState.GeneratorESP = IYAN_Selected(selected, "Generators")
                    IYAN_ESPState.HookESP = IYAN_Selected(selected, "Hooks")
                    IYAN_ESPState.GateESP = IYAN_Selected(selected, "Gates")
                    IYAN_ESPState.WindowESP = IYAN_Selected(selected, "Windows")
                    IYAN_ESPState.PalletESP = IYAN_Selected(selected, "Pallets")
                    IYAN_ESPState.SCPZombieESP = IYAN_Selected(selected, "SCP / Zombie")

                    if IYAN_ESPState.WorldMasterESP and IYAN_AnyWorldEnabled() then
                        IYAN_RefreshESPRoots()
                        IYAN_StartWorldLoop()
                    else
                        IYAN_ClearAllWorldESP()
                    end
                end,
            })

            worldSection:AddToggle({
                Name = "World Nametags",
                Flag = "IYAN World Nametags",
                Default = false,
                Callback = function(state)
                    IYAN_ESPState.WorldNametags = state
                    if IYAN_ESPState.WorldMasterESP and IYAN_AnyWorldEnabled() then IYAN_StartWorldLoop() else IYAN_ClearAllWorldESP() end
                end,
            })

            worldSection:AddToggle({
                Name = "World Distance ESP",
                Flag = "IYAN World Distance ESP",
                Default = false,
                Callback = function(state)
                    IYAN_ESPState.WorldDistanceESP = state
                    if IYAN_ESPState.WorldMasterESP and IYAN_AnyWorldEnabled() then IYAN_StartWorldLoop() else IYAN_ClearAllWorldESP() end
                end,
            })

            pcall(function() worldSection:AddDivider({ Text = "Colors" }) end)
            worldSection:AddColorPicker({ Name = "Generator Color", Flag = "IYAN Generator Color", Default = IYAN_ESPState.GeneratorColor, Callback = function(color) IYAN_ESPState.GeneratorColor = color end })
            worldSection:AddColorPicker({ Name = "Hook Color", Flag = "IYAN Hook Color", Default = IYAN_ESPState.HookColor, Callback = function(color) IYAN_ESPState.HookColor = color end })
            worldSection:AddColorPicker({ Name = "Gate Color", Flag = "IYAN Gate Color", Default = IYAN_ESPState.GateColor, Callback = function(color) IYAN_ESPState.GateColor = color end })
            worldSection:AddColorPicker({ Name = "Window Color", Flag = "IYAN Window Color", Default = IYAN_ESPState.WindowColor, Callback = function(color) IYAN_ESPState.WindowColor = color end })
            worldSection:AddColorPicker({ Name = "Pallet Color", Flag = "IYAN Pallet Color", Default = IYAN_ESPState.PalletColor, Callback = function(color) IYAN_ESPState.PalletColor = color end })
            worldSection:AddColorPicker({ Name = "SCP / Zombie Color", Flag = "IYAN SCP Zombie Color", Default = IYAN_ESPState.SCPZombieColor, Callback = function(color) IYAN_ESPState.SCPZombieColor = color end })
        end

        for _, player in ipairs(Players:GetPlayers()) do
            IYAN_WatchPlayer(player)
        end

        table.insert(IYAN_Connections, Players.PlayerAdded:Connect(IYAN_WatchPlayer))
        table.insert(IYAN_Connections, Players.PlayerRemoving:Connect(IYAN_UnwatchPlayer))
        table.insert(IYAN_Connections, Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Map" or child.Name == "Map1" then
                IYAN_AttachESPRoot(child)
                if IYAN_ESPState.WorldMasterESP and IYAN_AnyWorldEnabled() then IYAN_StartWorldLoop() end
            end
        end))
        table.insert(IYAN_Connections, Workspace.ChildRemoved:Connect(function(child)
            if child.Name == "Map" or child.Name == "Map1" then
                IYAN_RefreshESPRoots()
            end
        end))

        IYAN_RefreshESPRoots()

        getgenv().IYAN_VD_VisualESP_Cleanup = function()
            IYAN_Dead = true
            IYAN_ClearAllPlayerESP()
            IYAN_ClearAllWorldESP()

            for _, conn in ipairs(IYAN_Connections) do
                if conn then pcall(function() conn:Disconnect() end) end
            end
            for _, conns in pairs(IYAN_PlayerConns) do
                for _, conn in ipairs(conns) do
                    if conn then pcall(function() conn:Disconnect() end) end
                end
            end
            for _, conn in pairs(IYAN_MapAdd) do
                if conn then pcall(function() conn:Disconnect() end) end
            end
            for _, conn in pairs(IYAN_MapRem) do
                if conn then pcall(function() conn:Disconnect() end) end
            end
            if IYAN_ESPFolder and IYAN_ESPFolder.Parent then
                IYAN_ESPFolder:Destroy()
            end
        end
    end

    -- =====================================================
    -- NEW AUTO PARRY LOGIC
    -- =====================================================
    local VD_ParryRange = Instance.new("CylinderHandleAdornment")
    VD_ParryRange.Name = "IYAN_ParryRange"
    VD_ParryRange.Radius = VD.SURV_ParryRange or 12
    VD_ParryRange.InnerRadius = math.max(0.1, (VD.SURV_ParryRange or 12) - 0.15)
    VD_ParryRange.Height = 0.01
    VD_ParryRange.Color3 = Color3.fromRGB(80, 80, 80)
    VD_ParryRange.AlwaysOnTop = false
    VD_ParryRange.Adornee = Workspace:FindFirstChildOfClass("Terrain")
    VD_ParryRange.Transparency = 1
    VD_ParryRange.Parent = GetSafeGuiParent()

    local function VD_UpdateParryRange()
        if not VD.SURV_AutoParry or not VD.SURV_ShowParryCircle then
            VD_ParryRange.Transparency = 1
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            VD_ParryRange.Transparency = 1
            return
        end

        local currentMaxDist = VD.SURV_ParryRange or 12
        VD_ParryRange.Transparency = 0.4
        VD_ParryRange.Radius = currentMaxDist
        VD_ParryRange.InnerRadius = math.max(0.1, currentMaxDist - 0.15)

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { char }
        params.FilterType = Enum.RaycastFilterType.Exclude

        local ray = Workspace:Raycast(root.Position, Vector3.new(0, -15, 0), params)
        local groundPos = ray and ray.Position or (root.Position - Vector3.new(0, 3, 0))
        VD_ParryRange.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(math.pi / 2, 0, 0)
    end

    local function HasParryingDagger()
        local char = LocalPlayer.Character
        if not char then return false end
        local dagger = char:FindFirstChild("Parrying Dagger")
        if dagger then return true end
        for _, child in ipairs(char:GetDescendants()) do
            if child.Name == "Parrying Dagger" and (child:IsA("Tool") or child:IsA("Accessory") or child:IsA("Model")) then
                return true
            end
        end
        return false
    end

    local ParryGradients = {}
    local ParryIcon = nil

    local function GetParryUIElements()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return end

        table.clear(ParryGradients)
        ParryIcon = nil

        for _, screenName in ipairs({"Survivor", "Survivor-con"}) do
            local screen = playerGui:FindFirstChild(screenName)
            if screen then
                local gen = screen:FindFirstChild("Gen")
                if gen then
                    local itemFrame = gen:FindFirstChild("ItemFrame")
                    if itemFrame then
                        local gui = itemFrame:FindFirstChild("Gui")
                        if gui then
                            local bar = gui:FindFirstChild("Bar")
                            if bar then
                                local gradient = bar:FindFirstChild("UIGradient")
                                if gradient then
                                    table.insert(ParryGradients, gradient)
                                end
                            end
                        end
                        local icon = itemFrame:FindFirstChild("icon")
                        if icon then ParryIcon = icon end
                    end
                end
            end
        end

        local mobScreen = playerGui:FindFirstChild("Survivor-mob")
        if mobScreen then
            local controls = mobScreen:FindFirstChild("Controls")
            if controls then
                for _, btn in ipairs(controls:GetChildren()) do
                    if btn:IsA("ImageButton") and btn.Name == "Gui-mob" then
                        local bar = btn:FindFirstChild("Bar")
                        if bar then
                            local gradient = bar:FindFirstChild("UIGradient")
                            if gradient then
                                table.insert(ParryGradients, gradient)
                            end
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        local waited = 0
        while #ParryGradients == 0 and waited < 10 do
            task.wait(0.5)
            GetParryUIElements()
            waited = waited + 0.5
        end
    end)

    task.spawn(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return end
        playerGui.ChildAdded:Connect(function(child)
            if child.Name == "Survivor-mob" then
                local controls = child:WaitForChild("Controls", 5)
                if controls then
                    for _, btn in ipairs(controls:GetChildren()) do
                        if btn:IsA("ImageButton") and btn.Name == "Gui-mob" then
                            local bar = btn:FindFirstChild("Bar")
                            if bar then
                                local gradient = bar:FindFirstChild("UIGradient")
                                if gradient then table.insert(ParryGradients, gradient) end
                            end
                        end
                    end
                    controls.ChildAdded:Connect(function(btn)
                        if btn:IsA("ImageButton") and btn.Name == "Gui-mob" then
                            local bar = btn:FindFirstChild("Bar")
                            if bar then
                                local gradient = bar:FindFirstChild("UIGradient")
                                if gradient then table.insert(ParryGradients, gradient) end
                            end
                        end
                    end)
                end
            end
        end)
    end)

    local ParrySystem = {
        CooldownToken = 0,
        IsOnCooldown = false,
        IsResolving = false,
        Gradients = ParryGradients,
        Icon = ParryIcon,
        CooldownThread = nil,
        LockConnection = nil,
        ParryTrack = nil,
    }

    local function SetIconsColor(color)
        if #ParrySystem.Gradients == 0 then
            GetParryUIElements()
        end
        for _, grad in ipairs(ParrySystem.Gradients) do
            if grad and grad.Parent and grad.Parent.Parent then
                local icon = grad.Parent.Parent:FindFirstChild("icon")
                if icon then
                    icon.ImageColor3 = color
                end
                local gui = grad.Parent.Parent:FindFirstChild("Gui")
                if gui then
                    gui.ImageColor3 = color
                end
            end
        end
        if ParryIcon then
            ParryIcon.ImageColor3 = color
        end
    end

    local function PlayCooldownTween(duration)
        if #ParrySystem.Gradients == 0 then
            GetParryUIElements()
        end
        for _, grad in ipairs(ParrySystem.Gradients) do
            if grad and grad.Parent then
                grad.Offset = Vector2.new(0, 0.75)
                local tween = TweenService:Create(grad, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                    Offset = Vector2.new(0, 0.25)
                })
                tween:Play()
                tween.Completed:Connect(function()
                    if not ParrySystem.IsOnCooldown then
                        SetIconsColor(Color3.fromRGB(255,255,255))
                    end
                end)
            end
        end
    end

    local function StartCooldown(duration)
        ParrySystem.CooldownToken = ParrySystem.CooldownToken + 1
        local token = ParrySystem.CooldownToken

        ParrySystem.IsResolving = false
        ParrySystem.IsOnCooldown = true
        SetIconsColor(Color3.fromRGB(77,77,77))
        PlayCooldownTween(duration)

        if ParrySystem.CooldownThread then
            task.cancel(ParrySystem.CooldownThread)
        end
        ParrySystem.CooldownThread = task.delay(duration, function()
            if ParrySystem.CooldownToken == token then
                ParrySystem.IsOnCooldown = false
                SetIconsColor(Color3.fromRGB(255,255,255))
                ParrySystem.CooldownThread = nil
            end
        end)
    end

    local function ResetCooldown()
        if ParrySystem.CooldownThread then
            task.cancel(ParrySystem.CooldownThread)
            ParrySystem.CooldownThread = nil
        end
        ParrySystem.IsOnCooldown = false
        ParrySystem.IsResolving = false
        SetIconsColor(Color3.fromRGB(255,255,255))
        for _, grad in ipairs(ParrySystem.Gradients) do
            if grad and grad.Parent then
                grad.Offset = Vector2.new(0, 0.25)
            end
        end
    end

    local function IsBusy()
        local char = LocalPlayer.Character
        if not char then return true end
        if LocalPlayer:GetAttribute("IsDead") then return true end
        if char:GetAttribute("IsCarried") then return true end
        if char:GetAttribute("IsHooked") then return true end
        if CollectionService:HasTag(char:FindFirstChild("HumanoidRootPart"), "doing action") then return true end

        local ci = char:FindFirstChild("CheckInterractable")
        if ci then
            local actions = {"isVaulting","isSliding","isDroppingPallet","isRepairing","isHealing","isUnhooking","isExiting"}
            for _, act in ipairs(actions) do
                if ci:GetAttribute(act) then return true end
            end
        end
        return false
    end

    local function IsLowHealth()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return true end
        return hum.Health < hum.MaxHealth * 0.5
    end

    local function CanParry()
        if not VD.SURV_AutoParry then return false end
        if not HasParryingDagger() then return false end
        if ParrySystem.IsOnCooldown then return false end
        if ParrySystem.IsResolving then return false end
        if IsBusy() then return false end
        if IsLowHealth() then return false end
        return true
    end

    local function FaceLookDirection()
        local camera = Workspace.CurrentCamera
        if not camera then return end
        local rootPart = Root
        if not rootPart or not rootPart.Parent then return end

        local lookVec = camera.CFrame.LookVector
        local flat = Vector3.new(lookVec.X, 0, lookVec.Z)
        if flat.Magnitude <= 0 then return end

        local targetCF = CFrame.new(rootPart.Position, rootPart.Position + flat.Unit)
        local tween = TweenService:Create(rootPart, TweenInfo.new(0.2, Enum.EasingStyle.Linear), { CFrame = targetCF })
        tween:Play()
        tween.Completed:Connect(function()
            if Humanoid then Humanoid.AutoRotate = true end
            if ParrySystem.LockConnection then ParrySystem.LockConnection:Disconnect() end
            local startTime = tick()
            ParrySystem.LockConnection = RunService.Heartbeat:Connect(function()
                if tick() - startTime >= 0.8 then
                    if ParrySystem.LockConnection then
                        ParrySystem.LockConnection:Disconnect()
                        ParrySystem.LockConnection = nil
                    end
                    return
                end
                if rootPart and rootPart.Parent then
                    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + flat.Unit)
                else
                    if ParrySystem.LockConnection then
                        ParrySystem.LockConnection:Disconnect()
                        ParrySystem.LockConnection = nil
                    end
                end
            end)
        end)
    end

    local function PlayParryAnimation()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end

        local animId = VD.SURV_ParryAnimId or "rbxassetid://109133187196613"
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local track = animator:LoadAnimation(anim)
        if track then
            track.Priority = Enum.AnimationPriority.Action
            track:Play()
            ParrySystem.ParryTrack = track
            task.delay(1.5, function()
                if track and track.IsPlaying then track:Stop() end
                ParrySystem.ParryTrack = nil
            end)
        end
    end

    local function applyWalkSpeedSequence()
        local hum = Humanoid
        if not hum then return end
        local sequence = {
            { speed = 0, duration = 2 },
            { speed = 19, duration = 2 },
            { speed = 18, duration = 1 },
            { speed = 17, duration = math.huge }
        }
        for _, step in ipairs(sequence) do
            if not hum.Parent then break end
            hum.WalkSpeed = step.speed
            if step.duration == math.huge then
                break
            else
                task.wait(step.duration)
            end
        end
    end

    local function DoParry()
        if not CanParry() then return end

        ParrySystem.IsResolving = true
        SetIconsColor(Color3.fromRGB(77,77,77))

        local parryRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Items"):FindFirstChild("Parrying Dagger"):FindFirstChild("parry")
        if parryRemote then
            pcall(function() parryRemote:FireServer() end)
        end

        FaceLookDirection()
        if Humanoid then Humanoid.AutoRotate = false end
        PlayParryAnimation()

        local rootPart = Root
        if rootPart then
            CollectionService:AddTag(rootPart, "doing action")
        end

        local slowRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Mechanics"):FindFirstChild("Slow")
        if slowRemote then
            pcall(function() slowRemote:Fire(0, 1, 0) end)
        end

        task.spawn(applyWalkSpeedSequence)

        task.delay(2, function()
            if ParrySystem.IsResolving then
                ParrySystem.IsResolving = false
                StartCooldown(60)
                if rootPart then
                    CollectionService:RemoveTag(rootPart, "doing action")
                end
            end
        end)
    end

    local function ListenParryResult()
        task.spawn(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end
            local daggerFolder = remotes:FindFirstChild("Items"):FindFirstChild("Parrying Dagger")
            if not daggerFolder then return end
            local parryResult = daggerFolder:FindFirstChild("parryResult")
            if not parryResult then return end

            parryResult.OnClientEvent:Connect(function(success, cooldown)
                if not ParrySystem.IsResolving then return end

                ParrySystem.IsResolving = false
                local duration = tonumber(cooldown)
                if duration and duration > 0 then
                    StartCooldown(duration)
                else
                    if success == true then
                        StartCooldown(90)
                    else
                        StartCooldown(60)
                    end
                end

                local rootPart = Root
                if rootPart then
                    CollectionService:RemoveTag(rootPart, "doing action")
                end
            end)
        end)
    end
    ListenParryResult()

    local VD_ATTACK_ANIMS = {
        ["rbxassetid://113255068724446"] = true,
        ["rbxassetid://74968262036854"] = true,
        ["rbxassetid://110355011987939"] = true,
        ["rbxassetid://139369275981139"] = true,
        ["rbxassetid://132817836308238"] = true,
        ["rbxassetid://129784271201071"] = true,
        ["rbxassetid://133963973694098"] = true,
        ["rbxassetid://117042998468241"] = true,
        ["rbxassetid://105374834496520"] = true,
        ["rbxassetid://111920872708571"] = true,
        ["rbxassetid://78432063483146"] = true,
        ["rbxassetid://118907603246885"] = true,
        ["rbxassetid://138720291317243"] = true,
        ["rbxassetid://115244153053858"] = true,
        ["rbxassetid://130593238885843"] = true,
        ["rbxassetid://122812055447896"] = true,
        ["rbxassetid://78935059863801"] = true,
        ["rbxassetid://135002183282873"] = true,
        ["rbxassetid://121216847022485"] = true,
    }

    local Attached = {}
    local function AttachParrySensor(kChar)
        if not kChar or Attached[kChar] then return end
        Attached[kChar] = true
        local humanoid = kChar:FindFirstChild("Humanoid")
        if not humanoid then
            humanoid = kChar:WaitForChild("Humanoid", 5)
            if not humanoid then return end
        end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = humanoid:WaitForChild("Animator", 5)
            if not animator then return end
        end

        humanoid.ChildAdded:Connect(function(child)
            if child:IsA("Animator") then
                Attached[kChar] = nil
                AttachParrySensor(kChar)
            end
        end)

        kChar.AncestryChanged:Connect(function(_, parent)
            if not parent then
                Attached[kChar] = nil
            end
        end)

        animator.AnimationPlayed:Connect(function(track)
            local animId = track.Animation and track.Animation.AnimationId or ""
            if not VD_ATTACK_ANIMS[animId] then return end

            if not VD.SURV_AutoParry then return end
            if not HasParryingDagger() then return end
            if ParrySystem.IsOnCooldown or ParrySystem.IsResolving then return end

            local myChar = LocalPlayer.Character
            if not myChar then return end
            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            local kHRP = kChar:FindFirstChild("HumanoidRootPart")
            if not myHRP or not kHRP then return end

            local delta = myHRP.Position - kHRP.Position
            local startDistance = delta.Magnitude

            local mode = VD.SURV_ParryMode or "Legit"
            local range = VD.SURV_ParryRange or 12

            if mode == "Aggressive" then
                local aggressiveRadius = range
                local detectionRadius = aggressiveRadius + 3
                if startDistance > detectionRadius then return end
                if startDistance <= aggressiveRadius then
                    DoParry()
                else
                    local tracker
                    local startTime = os.clock()
                    tracker = RunService.Heartbeat:Connect(function()
                        if os.clock() - startTime >= 1.5 or ParrySystem.IsOnCooldown or ParrySystem.IsResolving or not myHRP or not kHRP then
                            if tracker then tracker:Disconnect() end
                            return
                        end
                        local currentDist = (myHRP.Position - kHRP.Position).Magnitude
                        if currentDist <= aggressiveRadius then
                            DoParry()
                            if tracker then tracker:Disconnect() end
                        end
                    end)
                end
            else
                if startDistance > range then return end
                local myPosFlat = Vector3.new(myHRP.Position.X, 0, myHRP.Position.Z)
                local kPosFlat = Vector3.new(kHRP.Position.X, 0, kHRP.Position.Z)
                local flatDelta = myPosFlat - kPosFlat
                if flatDelta.Magnitude > 0 then
                    local flatDirection = flatDelta.Unit
                    local kLookFlat = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z).Unit
                    local isFacing = kLookFlat:Dot(flatDirection)
                    if isFacing < 0.6 then return end
                end
                DoParry()
            end
        end)
    end

    local function TryAttach(p)
        if p ~= LocalPlayer and p.Team and p.Team.Name == "Killer" and p.Character then
            AttachParrySensor(p.Character)
        end
    end

    local function SetupPlayer(p)
        if p == LocalPlayer then return end
        p.CharacterAdded:Connect(function() TryAttach(p) end)
        p:GetPropertyChangedSignal("Team"):Connect(function() TryAttach(p) end)
        if p.Character then TryAttach(p) end
    end

    for _, p in pairs(Players:GetPlayers()) do SetupPlayer(p) end
    Players.PlayerAdded:Connect(SetupPlayer)

    task.spawn(function()
        while true do
            task.wait(5)
            for _, p in pairs(Players:GetPlayers()) do TryAttach(p) end
        end
    end)

    RunService.RenderStepped:Connect(function()
        VD_UpdateParryRange()
    end)

    -- =====================================================
    -- AUTO SKILLCHECK
    -- =====================================================
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local AutoSkill = {
        LastGoalRotation = nil,
        HasClickedThisGoal = false,
        LastLineRotation = nil,
        LastTick = nil,
        WasActive = false,
        PerfectLastGoalRotation = nil,
        PerfectHasClickedThisGoal = false,
        PerfectLastLineRotation = nil,
        PerfectLastTick = nil,
        PerfectWasActive = false,
        InstantLastTriggerTick = 0,
        InstantLastGoalRotation = 0,
        InstantLastGoalInstance = nil,
        InstantCurrentGoalID = 0,
        InstantHasClicked = false,
        InstantForcingRotation = false,
        InstantRotationConnection = nil,
    }

    local function VD_PressSkill()
        if isMobile then
            local btn = PlayerGui:FindFirstChild("check", true)
            if btn and btn:IsA("GuiObject") then
                local pos = btn.AbsolutePosition
                local size = btn.AbsoluteSize
                local inset = GuiService:GetGuiInset()
                local x = pos.X + (size.X / 2) + inset.X
                local y = pos.Y + (size.Y / 2) + inset.Y
                pcall(function() VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.Begin.Value, x, y) end)
                task.wait(0.01)
                pcall(function() VirtualInputManager:SendTouchEvent(8822, Enum.UserInputState.End.Value, x, y) end)
                pcall(function()
                    if firesignal and btn.MouseButton1Click then
                        firesignal(btn.MouseButton1Click)
                    end
                end)
            end
        else
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
            task.wait(0.01)
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
        end
    end

    local function VD_GetSkillCheck()
        for _, guiName in ipairs({ "SkillCheckPromptGui", "SkillCheckPromptGui-con" }) do
            local gui = PlayerGui:FindFirstChild(guiName, true)
            if gui then
                local check = gui:FindFirstChild("Check", true)
                if check and check.Visible then
                    local line = check:FindFirstChild("Line", true)
                    local goal = check:FindFirstChild("Goal", true)
                    if line and goal then return line, goal end
                end
            end
        end
    end

    local function VD_AngularDelta(from, to)
        local d = to - from
        if d > 180 then d = d - 360 end
        if d < -180 then d = d + 360 end
        return d
    end

    local function VD_CrossedZone(prevLr, lr, startPos, endPos)
        local function inZone(r)
            if startPos > endPos then
                return r >= startPos or r <= endPos
            end
            return r >= startPos and r <= endPos
        end
        if inZone(lr) then return true end
        if prevLr == nil then return false end
        local delta = VD_AngularDelta(prevLr, lr)
        local steps = math.abs(math.floor(delta))
        if steps < 2 then return false end
        local stepSize = delta / steps
        for i = 1, steps do
            if inZone((prevLr + stepSize * i) % 360) then return true end
        end
        return false
    end

    local function VD_NormalSkillcheckUpdate()
        local line, goal = VD_GetSkillCheck()
        if not (line and goal) then
            AutoSkill.LastGoalRotation = nil
            AutoSkill.HasClickedThisGoal = false
            AutoSkill.LastLineRotation = nil
            AutoSkill.LastTick = nil
            AutoSkill.WasActive = false
            return
        end

        local lr = line.Rotation % 360
        local gr = goal.Rotation % 360
        local now = os.clock()
        if not AutoSkill.WasActive then
            AutoSkill.WasActive = true
            AutoSkill.HasClickedThisGoal = false
            AutoSkill.LastGoalRotation = gr
            AutoSkill.LastLineRotation = lr
            AutoSkill.LastTick = now
            return
        end
        if AutoSkill.LastGoalRotation and math.abs(VD_AngularDelta(AutoSkill.LastGoalRotation, gr)) > 5 then
            AutoSkill.HasClickedThisGoal = false
            AutoSkill.LastLineRotation = nil
            AutoSkill.LastTick = nil
        end
        AutoSkill.LastGoalRotation = gr
        if AutoSkill.HasClickedThisGoal then
            AutoSkill.LastLineRotation = lr
            AutoSkill.LastTick = now
            return
        end
        if AutoSkill.LastLineRotation and AutoSkill.LastTick then
            local dt = now - AutoSkill.LastTick
            if dt > 0 then
                local lineSpeed = VD_AngularDelta(AutoSkill.LastLineRotation, lr) / dt
                local predicted = (lr + lineSpeed * dt * 0) % 360
                if VD_CrossedZone(AutoSkill.LastLineRotation, predicted, (gr + 104) % 360, (gr + 109) % 360) then
                    AutoSkill.HasClickedThisGoal = true
                    task.spawn(function()
                        task.wait(0.03)
                        VD_PressSkill()
                    end)
                end
            end
        end
        AutoSkill.LastLineRotation = lr
        AutoSkill.LastTick = now
    end

    local function VD_PerfectSkillcheckUpdate()
        local line, goal = VD_GetSkillCheck()
        if not (line and goal) then
            AutoSkill.PerfectLastGoalRotation = nil
            AutoSkill.PerfectHasClickedThisGoal = false
            AutoSkill.PerfectLastLineRotation = nil
            AutoSkill.PerfectLastTick = nil
            AutoSkill.PerfectWasActive = false
            return
        end

        local lr = line.Rotation % 360
        local gr = goal.Rotation % 360
        local now = os.clock()
        if not AutoSkill.PerfectWasActive then
            AutoSkill.PerfectWasActive = true
            AutoSkill.PerfectHasClickedThisGoal = false
            AutoSkill.PerfectLastGoalRotation = gr
            AutoSkill.PerfectLastLineRotation = lr
            AutoSkill.PerfectLastTick = now
            return
        end
        if AutoSkill.PerfectLastGoalRotation and math.abs(VD_AngularDelta(AutoSkill.PerfectLastGoalRotation, gr)) > 5 then
            AutoSkill.PerfectHasClickedThisGoal = false
            AutoSkill.PerfectLastLineRotation = nil
            AutoSkill.PerfectLastTick = nil
        end
        AutoSkill.PerfectLastGoalRotation = gr
        if AutoSkill.PerfectHasClickedThisGoal then
            AutoSkill.PerfectLastLineRotation = lr
            AutoSkill.PerfectLastTick = now
            return
        end
        if AutoSkill.PerfectLastLineRotation and AutoSkill.PerfectLastTick then
            local dt = now - AutoSkill.PerfectLastTick
            if dt > 0 then
                local lineSpeed = VD_AngularDelta(AutoSkill.PerfectLastLineRotation, lr) / dt
                local predicted = (lr + lineSpeed * dt * 0) % 360
                if VD_CrossedZone(AutoSkill.PerfectLastLineRotation, predicted, (gr + 104) % 360, (gr + 108) % 360) then
                    AutoSkill.PerfectHasClickedThisGoal = true
                    VD_PressSkill()
                end
            end
        end
        AutoSkill.PerfectLastLineRotation = lr
        AutoSkill.PerfectLastTick = now
    end

    local function VD_InstantSkillcheckUpdate()
        local line, goal = VD_GetSkillCheck()
        if not (line and goal) then
            AutoSkill.InstantHasClicked = false
            AutoSkill.InstantLastGoalRotation = 0
            AutoSkill.InstantLastGoalInstance = nil
            AutoSkill.InstantCurrentGoalID = 0
            if AutoSkill.InstantRotationConnection then
                AutoSkill.InstantRotationConnection:Disconnect()
                AutoSkill.InstantRotationConnection = nil
            end
            return
        end

        local gr = goal.Rotation % 360
        local perfectRot = (gr + 106) % 360
        if not AutoSkill.InstantForcingRotation then
            AutoSkill.InstantForcingRotation = true
            pcall(function() line.Rotation = perfectRot end)
            AutoSkill.InstantForcingRotation = false
        end

        local diff = math.abs(gr - AutoSkill.InstantLastGoalRotation)
        if diff > 180 then diff = 360 - diff end
        local isNewGoal = diff > 0.5 or AutoSkill.InstantLastGoalInstance ~= goal
        if isNewGoal then
            AutoSkill.InstantHasClicked = false
            AutoSkill.InstantCurrentGoalID = AutoSkill.InstantCurrentGoalID + 1
            local assignedID = AutoSkill.InstantCurrentGoalID
            if AutoSkill.InstantRotationConnection then AutoSkill.InstantRotationConnection:Disconnect() end
            AutoSkill.InstantRotationConnection = line:GetPropertyChangedSignal("Rotation"):Connect(function()
                if AutoSkill.InstantForcingRotation then return end
                AutoSkill.InstantForcingRotation = true
                pcall(function()
                    local _, cGoal = VD_GetSkillCheck()
                    if cGoal then line.Rotation = (cGoal.Rotation % 360 + 106) % 360 end
                end)
                AutoSkill.InstantForcingRotation = false
            end)
            if not AutoSkill.InstantHasClicked then
                AutoSkill.InstantHasClicked = true
                task.spawn(function()
                    task.wait(0.05)
                    if AutoSkill.InstantCurrentGoalID == assignedID then
                        local cl, cg = VD_GetSkillCheck()
                        if cl and cg and tick() - AutoSkill.InstantLastTriggerTick > 0.03 then
                            AutoSkill.InstantLastTriggerTick = tick()
                            VD_PressSkill()
                        end
                    end
                end)
            end
        end
        AutoSkill.InstantLastGoalRotation = gr
        AutoSkill.InstantLastGoalInstance = goal
    end

    RunService.RenderStepped:Connect(function()
        if not VD.AutoSkillcheck then return end
        if VD.AutoSkillcheckMode == "Perfect" then
            VD_PerfectSkillcheckUpdate()
        elseif VD.AutoSkillcheckMode == "Instant" then
            VD_InstantSkillcheckUpdate()
        else
            VD_NormalSkillcheckUpdate()
        end
    end)

    local function VD_SetAutoSkillcheck(state)
        VD.AutoSkillcheck = state == true
        if not VD.AutoSkillcheck then
            if AutoSkill.InstantRotationConnection then
                AutoSkill.InstantRotationConnection:Disconnect()
                AutoSkill.InstantRotationConnection = nil
            end
            AutoSkill.InstantHasClicked = false
            AutoSkill.WasActive = false
            AutoSkill.PerfectWasActive = false
        end
    end

    -- INSTANT HEAL & AUTO HEAL ALL
    InstantHealSelf = false
    AutoHealAll = false
    AutoHealAllConnection = nil
    InstantHealConnection = nil

    function doSelfHeal()
        local char = LocalPlayer.Character
        if not char then return end
        local skillCheckRemote = ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent
        pcall(function() skillCheckRemote:FireServer("success", 100, char) end)
    end

    function doSelfHealTrue()
        local char = LocalPlayer.Character
        if not char then return end
        local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function() healRemote:FireServer(hrp, true) end)
    end

    function doSelfHealFalse()
        local char = LocalPlayer.Character
        if not char then return end
        local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function() healRemote:FireServer(hrp, false) end)
    end

    function doOthersHealSkillCheck(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        local skillCheckRemote = ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent
        pcall(function() skillCheckRemote:FireServer("success", 100, targetPlayer.Character) end)
    end

    function doOthersHealTrue(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end
        local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
        pcall(function() healRemote:FireServer(targetHRP, true) end)
    end

    function doOthersHealFalse(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end
        local healRemote = ReplicatedStorage.Remotes.Healing.HealEvent
        pcall(function() healRemote:FireServer(targetHRP, false) end)
    end

    function setInstantHealSelf(v)
        InstantHealSelf = v
        if v then
            local skillCheckTimer = 0
            local healTrueTimer = 0
            local healFalseTimer = 0
            local healTrueActive = false
            if InstantHealConnection then InstantHealConnection:Disconnect() end
            InstantHealConnection = RunService.Heartbeat:Connect(function(dt)
                if not InstantHealSelf then return end
                local myChar = LocalPlayer.Character
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if not myHum or myHum.Health >= myHum.MaxHealth * 0.9 then return end
                skillCheckTimer = skillCheckTimer + dt
                if skillCheckTimer >= 0.05 then skillCheckTimer = 0; doSelfHeal() end
                healTrueTimer = healTrueTimer + dt
                if healTrueTimer >= 0.06 and not healTrueActive then
                    healTrueTimer = 0; healTrueActive = true; doSelfHealTrue()
                end
                healFalseTimer = healFalseTimer + dt
                if healFalseTimer >= 0.09 and healTrueActive then
                    healFalseTimer = 0; healTrueActive = false; doSelfHealFalse(); healTrueTimer = -0.10
                end
            end)
        else
            if InstantHealConnection then InstantHealConnection:Disconnect(); InstantHealConnection = nil end
        end
    end

    function setAutoHealAll(v)
        AutoHealAll = v
        if v then
            local timers = {}
            if AutoHealAllConnection then AutoHealAllConnection:Disconnect() end
            AutoHealAllConnection = RunService.Heartbeat:Connect(function(dt)
                if not AutoHealAll then return end
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.9 then
                            if not timers[player] then
                                timers[player] = {sc = 0, t = 0, f = 0, active = false}
                            end
                            local tm = timers[player]
                            tm.sc = tm.sc + dt
                            if tm.sc >= 0.05 then tm.sc = 0; doOthersHealSkillCheck(player) end
                            tm.t = tm.t + dt
                            if tm.t >= 0.09 and not tm.active then
                                tm.t = 0; tm.active = true; doOthersHealTrue(player)
                            end
                            tm.f = tm.f + dt
                            if tm.f >= 0.07 and tm.active then
                                tm.f = 0; tm.active = false; doOthersHealFalse(player); tm.t = -0.10
                            end
                        else
                            timers[player] = nil
                        end
                    end
                end
            end)
        else
            if AutoHealAllConnection then AutoHealAllConnection:Disconnect(); AutoHealAllConnection = nil end
        end
    end

    -- SILENT AIM VEIL
    VeilConfig = {
        Enabled              = false,
        ShowFOV              = true,
        FOV                  = 150,
        SpearSpeed           = 165,
        Gravity              = workspace.Gravity * 0.5,
        MaxDist              = 200,
        AutoPredict          = false,
        TargetPart           = "Torso",
        HorizontalPredictFactor = 2.8,
    }

    VeilState = {
        chargingSpear    = false,
        touchInput       = nil,
        attackCooldown   = false,
        passiveCooldown  = false,
        remoteHooked     = false,
        lastPredictedPos = nil,
    }

    VeilVelocityCache = {}

    VeilDraw = {
        FOVCircle = Drawing.new("Circle"),
        Highlight = Instance.new("Highlight"),
        Tracer    = Drawing.new("Circle"),
    }

    VeilDraw.FOVCircle.Color     = Color3.fromRGB(180, 180, 180)
    VeilDraw.FOVCircle.Thickness = 1.5
    VeilDraw.FOVCircle.Filled    = false
    VeilDraw.FOVCircle.Visible   = false

    VeilDraw.Highlight.Name                = "VD_VeilTarget"
    VeilDraw.Highlight.FillColor           = Color3.fromRGB(255, 0, 0)
    VeilDraw.Highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
    VeilDraw.Highlight.FillTransparency    = 0.5
    VeilDraw.Highlight.OutlineTransparency = 0

    VeilDraw.Tracer.Thickness = 2
    VeilDraw.Tracer.Radius    = 5
    VeilDraw.Tracer.Color     = Color3.fromRGB(180, 180, 180)
    VeilDraw.Tracer.Filled    = true
    VeilDraw.Tracer.Visible   = false

    function Veil_GetRealVelocity(part, playerName)
        if not part then return Vector3.zero end
        local currentPos = part.Position
        local currentTime = tick()
        if not VeilVelocityCache[playerName] then
            VeilVelocityCache[playerName] = {lastPos = currentPos, lastTime = currentTime, velocity = Vector3.zero}
            return Vector3.zero
        end
        local cache = VeilVelocityCache[playerName]
        local dt = currentTime - cache.lastTime
        if dt > 0.01 then
            local rawVelocity = (currentPos - cache.lastPos) / dt
            if rawVelocity.Magnitude < 100 then
                cache.velocity = cache.velocity:Lerp(rawVelocity, 0.4)
            end
        end
        cache.lastPos = currentPos
        cache.lastTime = currentTime
        return cache.velocity
    end

    function veil_getTargetPart(char)
        if VeilConfig.TargetPart == "Head" then
            return char:FindFirstChild("Head")
        elseif VeilConfig.TargetPart == "Root" then
            return char:FindFirstChild("HumanoidRootPart")
        else
            return char:FindFirstChild("Torso")
                or char:FindFirstChild("UpperTorso")
                or char:FindFirstChild("HumanoidRootPart")
        end
    end

    function veil_getClosestSurvivor()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local cam      = workspace.CurrentCamera
        local center   = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local bestDist = VeilConfig.FOV
        local bestTarget = nil

        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
                local char = p.Character
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local part = veil_getTargetPart(char)
                if hum and hum.Health > 0 and part then
                    local dist3D = (part.Position - myRoot.Position).Magnitude
                    if dist3D <= VeilConfig.MaxDist then
                        local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist2D < bestDist then
                                bestDist   = dist2D
                                bestTarget = { Player = p, Part = part }
                            end
                        end
                    end
                end
            end
        end
        return bestTarget
    end

    function veil_setupInterceptor()
        if VeilState.remoteHooked then return end
        task.spawn(function()
            pcall(function()
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    if getnamecallmethod() == "FireServer" and not checkcaller() then
                        if self.Name == "Spearthrow" and VeilConfig.Enabled then
                            return nil
                        end
                    end
                    return oldNamecall(self, ...)
                end)
                VeilState.remoteHooked = true
            end)
        end)
    end
    veil_setupInterceptor()

    function veil_fire()
        if VeilState.attackCooldown then return end
        VeilState.attackCooldown = true
        task.delay(2, function() VeilState.attackCooldown = false end)

        local myChar    = LocalPlayer.Character
        local startPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
        if not startPart then return end

        local startPos   = startPart.Position
        local targetInfo = veil_getClosestSurvivor()
        local aimDir

        if targetInfo and targetInfo.Part then
            local targetPart = targetInfo.Part
            local targetPlayer = targetInfo.Player
            local targetPos = targetPart.Position

            local velocity = Veil_GetRealVelocity(targetPart, targetPlayer.Name)
            local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
            local speed = horizontalVel.Magnitude

            local distance = (targetPos - startPos).Magnitude
            local timeToHit = distance / VeilConfig.SpearSpeed

            local horizontalPrediction = Vector3.zero
            if speed > 4 then
                local factor = VeilConfig.HorizontalPredictFactor
                horizontalPrediction = horizontalVel.Unit * factor
            end
            local predictedPos = targetPos + horizontalPrediction

            local distMult = math.clamp(distance / 100, 1, 2.5)
            local autoGravity = math.max(0, distance - 8)
            local gravity = VeilConfig.AutoPredict and autoGravity or VeilConfig.Gravity
            local drop = 0.5 * gravity * (timeToHit ^ 2) * distMult
            local finalPos = predictedPos + Vector3.new(0, drop, 0)

            aimDir = (finalPos - startPos).Unit
            VeilState.lastPredictedPos = finalPos
        else
            aimDir = workspace.CurrentCamera.CFrame.LookVector
            VeilState.lastPredictedPos = nil
        end

        pcall(function()
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if remotes then
                local killers = remotes:FindFirstChild("Killers")
                if killers then
                    local veil = killers:FindFirstChild("Veil")
                    if veil and veil:FindFirstChild("Spearthrow") then
                        veil.Spearthrow:FireServer(aimDir, VeilConfig.SpearSpeed, startPos)
                    end
                end
            end
        end)

        VeilDraw.FOVCircle.Color = Color3.fromRGB(180, 180, 180)
        if not VeilState.passiveCooldown then
            VeilState.passiveCooldown = true
            task.delay(30, function()
                VeilDraw.FOVCircle.Color = Color3.fromRGB(180, 180, 180)
                VeilState.passiveCooldown = false
            end)
        end
    end

    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        local isTouch = input.UserInputType == Enum.UserInputType.Touch
        if gp and not isTouch then return end
        local char = LocalPlayer.Character
        local isSpearMode = char and char:GetAttribute("spearmode") == true
        if not VeilConfig.Enabled then return end
        if not isSpearMode then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            VeilState.chargingSpear = true
        elseif isTouch then
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local slasher = pGui:FindFirstChild("Slasher-mob")
                if slasher then
                    local ctrl = slasher:FindFirstChild("Controls")
                    if ctrl then
                        local attackBtn = ctrl:FindFirstChild("attack")
                        if attackBtn and attackBtn.Visible then
                            local pos     = input.Position
                            local absPos  = attackBtn.AbsolutePosition
                            local absSize = attackBtn.AbsoluteSize
                            if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
                            and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
                                VeilState.chargingSpear = true
                                VeilState.touchInput    = input
                            end
                        end
                    end
                end
            end
        end
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input, gp)
        if VeilState.chargingSpear
        and (input == VeilState.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
            VeilState.chargingSpear = false
            if VeilState.touchInput == input then VeilState.touchInput = nil end
            veil_fire()
        end
    end)

    game:GetService("RunService").RenderStepped:Connect(function()
        local cam         = workspace.CurrentCamera
        local myChar      = LocalPlayer.Character
        local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true

        if VeilConfig.Enabled and VeilConfig.ShowFOV and isSpearMode then
            VeilDraw.FOVCircle.Visible  = true
            VeilDraw.FOVCircle.Radius   = VeilConfig.FOV
            VeilDraw.FOVCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        else
            VeilDraw.FOVCircle.Visible = false
        end

        if VeilState.chargingSpear and VeilConfig.Enabled and isSpearMode then
            local target = veil_getClosestSurvivor()
            if target and target.Part and target.Part.Parent then
                VeilDraw.Highlight.Parent = target.Part.Parent
            else
                VeilDraw.Highlight.Parent = nil
            end
        else
            VeilDraw.Highlight.Parent = nil
        end

        if VeilConfig.Enabled and isSpearMode and VeilState.lastPredictedPos then
            local screenPos, onScreen = cam:WorldToViewportPoint(VeilState.lastPredictedPos)
            local viewport = cam.ViewportSize
            local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

            if onScreen then
                VeilDraw.Tracer.Position = Vector2.new(screenPos.X, screenPos.Y)
            else
                local dx = screenPos.X - center.X
                local dy = screenPos.Y - center.Y
                if math.abs(dx) < 1 and math.abs(dy) < 1 then
                    VeilDraw.Tracer.Position = center
                else
                    local angle = math.atan2(dy, dx)
                    local maxX = viewport.X / 2 - 10
                    local maxY = viewport.Y / 2 - 10
                    local scaleX = maxX / math.abs(dx)
                    local scaleY = maxY / math.abs(dy)
                    local scale = math.min(scaleX, scaleY)
                    local borderPos = Vector2.new(
                        center.X + dx * scale,
                        center.Y + dy * scale
                    )
                    VeilDraw.Tracer.Position = borderPos
                end
            end
            VeilDraw.Tracer.Visible = true
        else
            VeilDraw.Tracer.Visible = false
        end
    end)

    -- ======================================================================
    -- GEN BOOST
    -- ======================================================================
    local DragConfigPath = ".Yeron.vd.drag.json"

    local function loadBypassButtonPosition()
        local pos = nil
        pcall(function()
            if isfile and readfile and isfile(DragConfigPath) then
                local raw = readfile(DragConfigPath)
                local data = HttpService:JSONDecode(raw)
                if data and data.XScale ~= nil and data.XOffset ~= nil and data.YScale ~= nil and data.YOffset ~= nil then
                    pos = UDim2.new(data.XScale, data.XOffset, data.YScale, data.YOffset)
                end
            end
        end)
        return pos
    end

    local function saveBypassButtonPosition(udim2Pos)
        pcall(function()
            if writefile then
                writefile(DragConfigPath, HttpService:JSONEncode({
                    XScale  = udim2Pos.X.Scale,
                    XOffset = udim2Pos.X.Offset,
                    YScale  = udim2Pos.Y.Scale,
                    YOffset = udim2Pos.Y.Offset,
                }))
            end
        end)
    end

    local bypassButton = nil
    local bypassButtonCheck = nil
    local bypassButtonGui = nil
    local bypassButtonDragConns = {}
    local bypassGuardianActive = false

    local function disconnectDragConns()
        for _, c in ipairs(bypassButtonDragConns) do
            pcall(function() c:Disconnect() end)
        end
        bypassButtonDragConns = {}
    end

    local function makeButtonDraggable(button)
        disconnectDragConns()

        local dragging = false
        local dragInput, dragStart, startPos

        local function update(input)
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            button.Position = newPos
        end

        table.insert(bypassButtonDragConns, button.InputBegan:Connect(function(input)
            if not VD.SURV_DraggableGenBypass then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = button.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        if dragging then
                            dragging = false
                            saveBypassButtonPosition(button.Position)
                        end
                        if conn then conn:Disconnect() end
                    end
                end)
            end
        end))

        table.insert(bypassButtonDragConns, button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end))

        table.insert(bypassButtonDragConns, UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                update(input)
            end
        end))
    end

    local function createBypassButton()
        if bypassButton and bypassButton.Parent then return end

        local guiParent = GetSafeGuiParent()
        if not guiParent then return end

        if bypassButtonGui then bypassButtonGui:Destroy() end

        bypassButtonGui = Instance.new("ScreenGui")
        bypassButtonGui.Name = "ZiaanHub_GenBypassGui"
        bypassButtonGui.ResetOnSpawn = false
        bypassButtonGui.IgnoreGuiInset = true
        bypassButtonGui.DisplayOrder = 999
        pcall(function() bypassButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
        bypassButtonGui.Parent = guiParent

        bypassButton = Instance.new("ImageButton")
        bypassButton.Name = "GenBypassButton"
        bypassButton.Size = UDim2.new(0, 101, 0, 101)
        bypassButton.AnchorPoint = Vector2.new(1, 0)

        local savedPos = loadBypassButtonPosition()
        bypassButton.Position = savedPos or UDim2.new(1, -99, 0, 335)

        bypassButton.BackgroundTransparency = 1
        bypassButton.Image = "rbxassetid://73955247819019"
        bypassButton.ScaleType = Enum.ScaleType.Fit
        bypassButton.BorderSizePixel = 0
        bypassButton.AutoButtonColor = false
        bypassButton.Active = true
        bypassButton.Selectable = false
        bypassButton.ZIndex = 2
        bypassButton.Parent = bypassButtonGui

        Instance.new("UICorner", bypassButton).CornerRadius = UDim.new(0.5, 0)

        makeButtonDraggable(bypassButton)

        local function updateButtonColor()
            if not bypassButton then return end
            local char = LocalPlayer.Character
            if not char then
                bypassButton.ImageColor3 = Color3.new(1, 1, 1)
                return
            end
            local ci = char:FindFirstChild("CheckInterractable")
            if not ci then
                bypassButton.ImageColor3 = Color3.new(1, 1, 1)
                return
            end
            local repairing = ci:GetAttribute("isRepairing") or ci:GetAttribute("IsRepairing")
            bypassButton.ImageColor3 = repairing and Color3.fromRGB(255, 140, 0) or Color3.new(1, 1, 1)
        end

        local function bindCheck(character)
            if not character then return end
            local ci = character:WaitForChild("CheckInterractable")
            if ci then
                if bypassButtonCheck then bypassButtonCheck:Disconnect() end
                bypassButtonCheck = ci:GetAttributeChangedSignal("isRepairing"):Connect(updateButtonColor)
                ci:GetAttributeChangedSignal("IsRepairing"):Connect(updateButtonColor)
                updateButtonColor()
            end
        end

        if LocalPlayer.Character then bindCheck(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(bindCheck)

        bypassButton.MouseButton1Click:Connect(function()
            if VD.SURV_DraggableGenBypass then return end
            print("[GenBypass] Tombol diklik")
            local char = LocalPlayer.Character
            if not char then return end
            local ci = char:FindFirstChild("CheckInterractable")
            if not ci then return end
            local repairing = ci:GetAttribute("isRepairing") or ci:GetAttribute("IsRepairing")
            if not repairing then
                print("[GenBypass] Tidak sedang repairing, abaikan")
                return
            end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local genCache, lastCacheTime = {}, 0
            local function getGenerators()
                if tick() - lastCacheTime < 5 then return genCache end
                genCache, lastCacheTime = {}, tick()
                local folder = Workspace:FindFirstChild("Map") or Workspace
                for _, v in pairs(folder:GetDescendants()) do
                    if v:IsA("Model") and v.Name == "Generator" then
                        local real = v:GetAttribute("RepairProgress") ~= nil
                            or v:GetAttribute("kickcount") ~= nil
                            or v:GetAttribute("ProgressRepair") ~= nil
                        if real then
                            table.insert(genCache, v)
                        end
                    end
                end
                print("[GenBypass] Ditemukan "..#genCache.." generator")
                return genCache
            end

            local function getPoints(genModel)
                local pts = {}
                for _, obj in pairs(genModel:GetChildren()) do
                    if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
                        table.insert(pts, obj)
                    end
                end
                return pts
            end

            local function waitRepairing(point, timeout)
                local start = tick()
                while tick() - start < timeout do
                    if point:GetAttribute("IsRepairing") == true then
                        return true
                    end
                    task.wait(0.05)
                end
                return false
            end

            local RepairEvent = nil
            pcall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local genFolder = remotes:FindFirstChild("Generator")
                    if genFolder then
                        RepairEvent = genFolder:FindFirstChild("RepairEvent")
                    end
                end
            end)
            if not RepairEvent then
                print("[GenBypass] RepairEvent tidak ditemukan!")
                return
            end

            local bestPoint, bestDist = nil, math.huge
            local bestGen = nil
            for _, gen in pairs(getGenerators()) do
                for _, pt in pairs(getPoints(gen)) do
                    local d = (hrp.Position - pt.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPoint = pt
                        bestGen = gen
                    end
                end
            end

            if bestPoint and bestGen then
                print("[GenBypass] Titik terdekat: "..bestPoint.Name.." pada "..bestGen.Name.." (diabaikan)")
                local allPoints = getPoints(bestGen)
                local targetPoints = {}
                for _, p in ipairs(allPoints) do
                    if p ~= bestPoint then table.insert(targetPoints, p) end
                end
                if #targetPoints == 0 then
                    print("[GenBypass] Tidak ada titik lain selain titik terdekat, proses dibatalkan")
                    return
                end
                local startCFrame = hrp.CFrame
                print("[GenBypass] Memproses "..#targetPoints.." titik (melewati titik terdekat) di "..bestGen.Name)
                for i, point in ipairs(targetPoints) do
                    if not point.Parent then continue end
                    print("[GenBypass] Titik "..i..": "..point.Name)
                    hrp.Anchored = true
                    hrp.CFrame = point.CFrame
                    task.wait(0.15)
                    if RepairEvent then
                        RepairEvent:FireServer(point, true)
                        print("[GenBypass] FireServer(true) ke "..point.Name)
                    end
                    local ok = waitRepairing(point, 0.8)
                    if not ok then
                        print("[GenBypass] Gagal, mencoba retry...")
                        if RepairEvent then RepairEvent:FireServer(point, false) end
                        task.wait(0.1)
                        hrp.CFrame = point.CFrame
                        task.wait(0.15)
                        if RepairEvent then RepairEvent:FireServer(point, true) end
                        ok = waitRepairing(point, 0.5)
                        if ok then print("[GenBypass] Retry berhasil") else print("[GenBypass] Retry gagal, lanjut ke titik berikutnya") end
                    else
                        print("[GenBypass] IsRepairing berhasil dideteksi")
                    end
                    hrp.Anchored = false
                    task.wait(0.05)
                end
                pcall(function()
                    hrp.Anchored = false
                    hrp.CFrame = startCFrame
                end)
                local lastPoint = targetPoints[#targetPoints]
                if lastPoint and RepairEvent then
                    task.wait(0.1)
                    RepairEvent:FireServer(lastPoint, false)
                    print("[GenBypass] FireServer(false) ke "..lastPoint.Name.." (final)")
                end
                print("[GenBypass] Selesai memproses generator")
            else
                print("[GenBypass] Tidak ada generator terdekat")
            end
        end)
    end

    local function destroyBypassButton()
        bypassGuardianActive = false
        disconnectDragConns()
        if bypassButtonGui then
            bypassButtonGui:Destroy()
            bypassButtonGui = nil
        end
        bypassButton = nil
        if bypassButtonCheck then
            bypassButtonCheck:Disconnect()
            bypassButtonCheck = nil
        end
    end

    local function startBypassButtonGuardian()
        if bypassGuardianActive then return end
        bypassGuardianActive = true
        task.spawn(function()
            while bypassGuardianActive and VD.SURV_GenBoost and not VD.Destroyed do
                if not (bypassButtonGui and bypassButtonGui.Parent) then
                    pcall(createBypassButton)
                end
                task.wait(1)
            end
        end)
    end

    local function startGenBoost()
        if not VD.SURV_GenBoost then return end
        createBypassButton()
        startBypassButtonGuardian()
    end

    local function stopGenBoost()
        destroyBypassButton()
    end

    getgenv().IYAN_SyncLoadedFeatures = function()
        if VD.SURV_GenBoost then startGenBoost() else stopGenBoost() end
    end

    -- ======================================================================
    -- LIGHTING: Fullbright & No Fog
    -- ======================================================================
    local defaultLighting = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
    }

    local function applyFullbright(state)
        if state then
            Lighting.Brightness = 1
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
        else
            Lighting.Brightness = defaultLighting.Brightness
            Lighting.Ambient = defaultLighting.Ambient
            Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
        end
    end

    local function applyNoFog(state)
        if state then
            Lighting.FogEnd = 9999
            Lighting.FogStart = 0
        else
            Lighting.FogEnd = defaultLighting.FogEnd
            Lighting.FogStart = defaultLighting.FogStart
        end
    end

    -- ======================================================================
    -- UI TABS
    -- ======================================================================
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
                if k == "AddToggle" or k == "AddButton" then
                    return function(self, cfg)
                        pcall(function() section[k](section, cfg) end)
                        return adapter
                    end
                end
                if k == "AddDropdown" then
                    return function(self, cfg)
                        local mapped = {}
                        for key, value in pairs(cfg or {}) do mapped[key] = value end
                        mapped.Options = mapped.Options or mapped.Values or {}
                        mapped.Values = nil
                        mapped.Multi = mapped.Multi == true
                        pcall(function() section:AddDropdown(mapped) end)
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
                            local isFloat = false
                            if modernCfg.Increment < 1 or (math.floor(modernCfg.Min) ~= modernCfg.Min) or (math.floor(modernCfg.Max) ~= modernCfg.Max) then
                                isFloat = true
                            end
                            if isFloat then
                                modernCfg.Rounding = 1
                                if modernCfg.Increment <= 0.01 then
                                    modernCfg.Rounding = 2
                                end
                            else
                                modernCfg.Rounding = 0
                            end
                            modernCfg.Callback = function(Value)
                                if cfg.Callback then
                                    pcall(function() cfg.Callback(Value) end)
                                end
                            end
                            pcall(function() section:AddSlider(modernCfg) end)
                        end
                        return adapter
                    end
                end
                if k == "AddTextInput" then
                    return function(self, cfg)
                        local mapped = {}
                        for key, value in pairs(cfg or {}) do mapped[key] = value end
                        mapped.Name = mapped.Name or "Input"
                        mapped.Default = tostring(mapped.Default or "")
                        mapped.Numeric = nil
                        pcall(function() section:AddTextbox(mapped) end)
                        return adapter
                    end
                end
                if k == "AddKeybind" then
                    return function(self, cfg)
                        local mapped = {}
                        for key, value in pairs(cfg or {}) do mapped[key] = value end
                        mapped.Key = mapped.Default or Enum.KeyCode.F3
                        mapped.Default = nil
                        pcall(function() section:AddBind(mapped) end)
                        return adapter
                    end
                end
                if k == "AddColorPicker" then
                    return function(self, cfg)
                        pcall(function() section:AddColorpicker(cfg) end)
                        return adapter
                    end
                end

                if type(section[k]) == "function" then
                    return function(self, ...)
                        return section[k](section, ...)
                    end
                end
                return section[k]
            end
        })
        return adapter
    end

    local function adaptTab(tab)
        local adapter = {}
        setmetatable(adapter, {
            __index = function(t, k)
                if k == "AddSection" then
                    return function(self, cfg)
                        if cfg and cfg.Name then
                            pcall(function() tab:AddDivider({ Text = cfg.Name }) end)
                        end
                        return makeModernAdapter(tab)
                    end
                end
                return tab[k]
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
        local PlayerTabbox2 = addCenterFeatureTabbox(PlayerTab, "Player Features 2", {
            { Key = "Streamer", Name = "Streamer Mode", Icon = "solar:settings-bold" },
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
            { Key = "Movement", Name = "Movement", Icon = "solar:walk-bold" },  -- ADDED
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

        -- Player Teleport
        local TeleportTab = PlayerTabbox1.Teleport
        local tpSection = TeleportTab:AddSection({
            Position = "Center",
            Name = "Teleport",
            Icon = "solar:map-point-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        local function getTeleportPlayerNames()
            local names = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then table.insert(names, p.Name) end
            end
            table.sort(names)
            return names
        end

        local tpPlayerDropdown = tpSection:AddDropdown({
            Name = "Select Player to Teleport",
            Flag = "TP_TargetPlayer",
            Values = getTeleportPlayerNames(),
            Multi = false,
            Callback = function(option)
                if type(option) == "table" then option = option[1] end
                VD.TP_TargetPlayer = option or ""
            end
        })

        tpSection:AddButton({ Name = "Refresh Players", Callback = function()
            pcall(function() tpPlayerDropdown:SetValues(getTeleportPlayerNames()) end)
        end })

        tpSection:AddButton({ Name = "Teleport to Player", Callback = function()
            pcall(function()
                local targetName = VD.TP_TargetPlayer
                if not targetName or targetName == "" then return end
                local player = Players:FindFirstChild(targetName)
                local root = Root
                local targetRoot = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and targetRoot then
                    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                end
            end)
        end })

        tpSection:AddButton({ Name = "TP to Gen", Callback = function() pcall(function() IYAN_TeleportToGenerator(1) end) end })
        tpSection:AddButton({ Name = "TP to Gate", Callback = function() pcall(IYAN_TeleportToGate) end })
        tpSection:AddButton({ Name = "TP to Hook", Callback = function() pcall(IYAN_TeleportToHook) end })

        -- Fling
        local FlingTab = PlayerTabbox1.Fling
        local flingSection = FlingTab:AddSection({
            Position = "Center",
            Name = "Fling",
            Icon = "solar:wind-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        flingSection:AddToggle({ Default = false, Name = "Enable Fling", Flag = "Enable Fling", Callback = function(v) VD.FLING_Enabled = v end })
        flingSection:AddSlider({
            Name = "Fling Strength", Flag = "Fling Strength",
            Min = 1000, Max = 50000, Default = 10000,
            Callback = function(v) VD.FLING_Strength = v end
        })
        flingSection:AddButton({ Name = "Fling Nearest", Callback = function() pcall(function() IYAN_FlingNearest() end) end })
        flingSection:AddButton({ Name = "Fling All", Callback = function() pcall(IYAN_FlingAll) end })

        -- Fun
        local FunTab = PlayerTabbox1.Fun
        local funSection = FunTab:AddSection({
            Position = "Center",
            Name = "Spoof Stats [Visual Only]",
            Icon = "solar:gamepad-bold",
            Box = true,
            BoxBorder = true,
            Opened = true,
        })
        local spoofLevel, spoofGears, spoofScrews = "0", "0", "0"
        funSection:AddTextInput({
            Name = "Set Level",
            Flag = "SpoofLevel",
            Numeric = true,
            Default = "0",
            Callback = function(value) spoofLevel = value end
        })
        funSection:AddTextInput({
            Name = "Set Gears",
            Flag = "SpoofGears",
            Numeric = true,
            Default = "0",
            Callback = function(value) spoofGears = value end
        })
        funSection:AddTextInput({
            Name = "Set Screws",
            Flag = "SpoofScrews",
            Numeric = true,
            Default = "0",
            Callback = function(value) spoofScrews = value end
        })
        funSection:AddButton({
            Name = "Apply Spoof Data",
            Callback = function()
                local p = LocalPlayer
                if p then
                    p:SetAttribute("Level", tonumber(spoofLevel) or 0)
                    p:SetAttribute("Gears", tonumber(spoofGears) or 0)
                    p:SetAttribute("Screws", tonumber(spoofScrews) or 0)
                end
            end
        })

        -- Streamer
        local StreamerTab = PlayerTabbox2.Streamer
        local streamerSection = StreamerTab:AddSection({
            Position = "Center",
            Name = "Streamer Mode",
            Icon = "solar:settings-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        local FakeNameConnection = nil
        local function shouldHideNameObject(object)
            local ok, isTextObj = pcall(function()
                return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
            end)
            if not ok or not isTextObj then
                return false
            end
            local text = ""
            pcall(function() text = tostring(object.Text or "") end)
            return text == LocalPlayer.Name or text == LocalPlayer.DisplayName or text:find(LocalPlayer.Name, 1, true) ~= nil
        end
        local function enableFakeName(enabled)
            if FakeNameConnection then
                pcall(function() FakeNameConnection:Disconnect() end)
                FakeNameConnection = nil
            end
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if not playerGui then
                return
            end
            local function process(object)
                if shouldHideNameObject(object) then
                    object.Visible = not enabled
                end
            end
            for _, descendant in ipairs(playerGui:GetDescendants()) do
                process(descendant)
            end
            if enabled then
                FakeNameConnection = playerGui.DescendantAdded:Connect(function(object)
                    task.defer(process, object)
                end)
            end
        end
        streamerSection:AddToggle({
            Default = false,
            Name = "Hide Name",
            Flag = "Hide Name",
            Callback = function(v)
                pcall(enableFakeName, v)
            end
        })

        -- Survivor General
        local GeneralTab = SurvivorTabbox1.General
        local genSection = GeneralTab:AddSection({
            Position = "Center",
            Name = "General Survivor",
            Icon = "solar:shield-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        genSection:AddToggle({ Default = false, Name = "Auto Skillcheck", Flag = "Auto Skillcheck", Callback = function(v) VD_SetAutoSkillcheck(v) end })
        genSection:AddDropdown({
            Name = "Skillcheck Mode",
            Flag = "Skillcheck Mode",
            Values = { "Normal", "Perfect", "Instant" },
            Default = "Normal",
            Multi = false,
            Callback = function(option)
                if type(option) == "table" then option = option[1] end
                VD.AutoSkillcheckMode = option or "Normal"
                if VD.AutoSkillcheckMode ~= "Instant" and AutoSkill.InstantRotationConnection then
                    AutoSkill.InstantRotationConnection:Disconnect()
                    AutoSkill.InstantRotationConnection = nil
                    AutoSkill.InstantHasClicked = false
                end
            end
        })
        genSection:AddToggle({ Default = false, Name = "Flee Killer", Flag = "Flee Killer", Callback = function(v) VD.SURV_FleeKiller = v end })
        genSection:AddSlider({
            Name = "Flee Distance", Flag = "Flee Distance",
            Min = 15, Max = 80, Default = 40,
            Callback = function(v) VD.SURV_FleeDistance = v end
        })
        local antiKnockConnection = nil
        genSection:AddToggle({
            Default = false,
            Name = "Anti Knock",
            Flag = "Anti Knock",
            Callback = function(v)
                VD.SURV_AntiKnock = v
                if v then
                    if antiKnockConnection then
                        antiKnockConnection:Disconnect()
                        antiKnockConnection = nil
                    end
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            antiKnockConnection = hum.HealthChanged:Connect(function()
                                hum.Health = 100
                            end)
                        end
                    end
                else
                    if antiKnockConnection then
                        antiKnockConnection:Disconnect()
                        antiKnockConnection = nil
                    end
                end
            end
        })
        genSection:AddToggle({ Default = false, Name = "First Person Camera (Survivor)", Flag = "First Person Camera (Survivor)", Callback = function(v)
            VD.SURV_FirstPerson = v
            if not v then
                pcall(RestoreFirstPersonCamera)
            end
        end })

        -- Healing
        local HealingTab = SurvivorTabbox1.Healing
        local healSection = HealingTab:AddSection({
            Position = "Center",
            Name = "Healing",
            Icon = "solar:heart-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        healSection:AddToggle({ Default = false, Name = "Auto Heal Self", Flag = "Instant Heal (Self)", Callback = function(v) setInstantHealSelf(v) end })
        healSection:AddToggle({ Default = false, Name = "Auto Heal All", Flag = "Auto Heal All", Callback = function(v) setAutoHealAll(v) end })

        -- Offensive (ToF)
        local OffensiveTab = SurvivorTabbox1.Offensive
        local offSection = OffensiveTab:AddSection({
            Position = "Center",
            Name = "Silent Aim Twist Of Fate",
            Icon = "solar:target-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        offSection:AddToggle({ Default = false, Name = "Silent Aim Twist Of Fate", Flag = "Silent Aim Twist Of Fate", Callback = function(v) VD.AUTO_ToFAim = v end })
        offSection:AddDropdown({
            Name = "ToF Target Mode",
            Flag = "ToF Target Mode",
            Values = { "Killer", "Survivor", "SCP" },
            Default = VD.AUTO_ToFTargetMode or "Killer",
            Multi = false,
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                VD.AUTO_ToFTargetMode = v or "Killer"
            end
        })
        offSection:AddDropdown({
            Name = "ToF Aim Part",
            Flag = "ToF Aim Part",
            Values = { "HumanoidRootPart", "Head", "Torso" },
            Default = VD.AUTO_ToFAimPart or "HumanoidRootPart",
            Multi = false,
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                VD.AUTO_ToFAimPart = v or "HumanoidRootPart"
            end
        })
        offSection:AddToggle({
            Default = true,
            Name = "ToF Prediction",
            Flag = "ToF Prediction",
            Callback = function(v) VD.AUTO_ToFPredict = v end
        })
        offSection:AddSlider({
            Name = "ToF Bullet Speed",
            Flag = "ToF Bullet Speed",
            Min = 50, Max = 1000, Default = 200,
            Callback = function(v) VD.AUTO_ToFBulletSpeed = v end
        })
        offSection:AddSlider({
            Name = "ToF Aim Range (studs)", Flag = "ToF Aim Range (studs)",
            Min = 10, Max = 300, Default = 90,
            Callback = function(v) VD.AUTO_ToFAimRange = v end
        })
        offSection:AddSlider({
            Name = "Safe FOV (Dot Threshold)", Flag = "Aim Strictness",
            Min = -1, Max = 1, Default = 0.5, Increment = 0.05,
            Callback = function(v) VD.AUTO_ToFDotThreshold = v end
        })

        -- Parry subtab
        local ParryTab = SurvivorTabbox2.Parry
        local parrySection = ParryTab:AddSection({
            Position = "Center",
            Name = "Auto Parry",
            Icon = "solar:sword-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })

        parrySection:AddToggle({
            Name = "Enable Auto Parry",
            Flag = "Auto Parry",
            Default = VD.SURV_AutoParry,
            Callback = function(v)
                VD.SURV_AutoParry = v
                if not v then
                    VD_ParryRange.Transparency = 1
                    ResetCooldown()
                end
            end
        })

        parrySection:AddDropdown({
            Name = "Parry Mode",
            Flag = "Parry Mode",
            Values = { "Legit", "Aggressive" },
            Default = VD.SURV_ParryMode or "Legit",
            Multi = false,
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                VD.SURV_ParryMode = v or "Legit"
            end
        })

        parrySection:AddDropdown({
            Name = "Parry Animation",
            Flag = "Parry Animation",
            Values = {
                "Default",
                "Shield",
                "Robot",
                "Katana",
                "Fish",
                "Watcher"
            },
            Default = "Default",
            Multi = false,
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                local animMap = {
                    Default = "rbxassetid://109133187196613",
                    Shield  = "rbxassetid://75939529748815",
                    Robot   = "rbxassetid://126894569253341",
                    Katana  = "rbxassetid://127096285501517",
                    Fish    = "rbxassetid://123307242865945",
                    Watcher = "rbxassetid://81793464499285",
                }
                VD.SURV_ParryAnimId = animMap[v] or animMap.Default
            end
        })

        parrySection:AddSlider({
            Name = "Parry Range",
            Flag = "Parry Range",
            Min = 2,
            Max = 20,
            Default = VD.SURV_ParryRange or 12,
            Increment = 0.5,
            Callback = function(v)
                VD.SURV_ParryRange = v
                VD_ParryRange.Radius = v
                VD_ParryRange.InnerRadius = math.max(0.1, v - 0.15)
            end
        })

        parrySection:AddKeybind({
            Name = "Toggle Keybind",
            Flag = "Parry Keybind",
            Default = VD.Parry_Keybind or "F3",
            Callback = function()
                VD.SURV_AutoParry = not VD.SURV_AutoParry
                if not VD.SURV_AutoParry then
                    VD_ParryRange.Transparency = 1
                    ResetCooldown()
                end
                pcall(function()
                    if Window and Window.ConfigElements and Window.ConfigElements["Auto Parry"] then
                        Window.ConfigElements["Auto Parry"]:Set(VD.SURV_AutoParry)
                    end
                end)
            end
        })

        parrySection:AddToggle({
            Name = "Show Parry Range Circle",
            Flag = "Show Parry Circle",
            Default = VD.SURV_ShowParryCircle,
            Callback = function(v)
                VD.SURV_ShowParryCircle = v
                if not v then VD_ParryRange.Transparency = 1 end
            end
        })

        -- Gen Boost subtab
        local GenBoostTab = SurvivorTabbox2.GenBoost
        local genBoostSection = GenBoostTab:AddSection({
            Position = "Center",
            Name = "Generator Boost",
            Icon = "solar:plug-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })

        genBoostSection:AddToggle({
            Name = "Gen Boost (BEST)",
            Flag = "Gen_Boost",
            Callback = function(v)
                VD.SURV_GenBoost = v
                if v then
                    startGenBoost()
                else
                    stopGenBoost()
                end
            end
        })

        genBoostSection:AddToggle({
            Name = "Draggable Mode (Gen Bypass Button)",
            Flag = "Draggable_Gen_Bypass",
            Callback = function(v)
                VD.SURV_DraggableGenBypass = v
            end
        })

        -- Auto Drop Pallet subtab
        local PalletTab = SurvivorTabbox2.Pallet
        local palletSection = PalletTab:AddSection({
            Position = "Center",
            Name = "Auto Drop Pallet",
            Icon = "solar:box-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })

        palletSection:AddToggle({
            Name = "Auto Drop Pallet",
            Flag = "Auto_Drop_Pallet",
            Default = false,
            Callback = function(v)
                VD.SURV_AutoDropPallet = v
                if v then
                    VD_Notify("Auto Drop Pallet", "Enabled (" .. (VD.SURV_AutoDropPalletMode or "Aggressive") .. " Mode)", 2)
                else
                    VD_Notify("Auto Drop Pallet", "Disabled", 2)
                end
            end
        })

        palletSection:AddSlider({
            Name = "Killer Detection Range (studs)",
            Flag = "Pallet_Trigger_Range",
            Min = 5,
            Max = 50,
            Default = 20,
            Increment = 1,
            Callback = function(v)
                VD.SURV_AutoDropPalletDist = v
            end
        })

        palletSection:AddDropdown({
            Name = "Mode",
            Flag = "Auto_Drop_Pallet_Mode",
            Values = { "Aggressive", "Safe" },
            Default = "Aggressive",
            Multi = false,
            Callback = function(value)
                if type(value) == "table" then value = value[1] end
                VD.SURV_AutoDropPalletMode = value
                VD_Notify("Auto Drop Pallet", "Mode set to " .. value, 2)
            end
        })

        -- ============================================================
        -- NEW: Movement subtab (Auto Vault & Auto Pallet Slide)
        -- ============================================================
        local MovementTab = SurvivorTabbox2.Movement
        local movementSection = MovementTab:AddSection({
            Position = "Center",
            Name = "Movement",
            Icon = "solar:walk-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })

        movementSection:AddToggle({
            Name = "Auto Vault",
            Flag = "Auto_Vault",
            Default = false,
            Callback = function(v)
                VD.SURV_AutoVault = v
                VD_Notify("Auto Vault", v and "Enabled" or "Disabled", 2)
            end
        })

        movementSection:AddToggle({
            Name = "Auto Pallet (Slide)",
            Flag = "Auto_Pallet_Slide",
            Default = false,
            Callback = function(v)
                VD.SURV_AutoPalletSlide = v
                VD_Notify("Auto Pallet Slide", v and "Enabled" or "Disabled", 2)
            end
        })

        -- Killer General
        local KillerGeneralTab = KillerTabbox1.General
        local kgSection = KillerGeneralTab:AddSection({
            Position = "Center",
            Name = "General Killer",
            Icon = "solar:danger-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        kgSection:AddToggle({ Default = false, Name = "Auto Attack", Flag = "Auto Attack", Callback = function(v) VD.AUTO_Attack = v end })
        kgSection:AddSlider({
            Name = "Attack Range", Flag = "Attack Range",
            Min = 5, Max = 20, Default = 12,
            Callback = function(v) VD.AUTO_AttackRange = v end
        })
        kgSection:AddToggle({ Default = false, Name = "Double Tap", Flag = "Double Tap", Callback = function(v) VD.KILLER_DoubleTap = v end })
        kgSection:AddToggle({ Default = false, Name = "Auto Kick Pallet", Flag = "Destroy Pallets", Callback = function(v) VD.KILLER_DestroyPallets = v end })
        kgSection:AddToggle({ Default = false, Name = "Auto Kick Generator", Flag = "Auto Kick Generator", Callback = function(v) VD.KILLER_AutoBreakGene = v end })
        kgSection:AddToggle({ Default = false, Name = "Block All Vaults", Flag = "Block All Vaults", Callback = function(v) VD.KILLER_BlockVaults = v end })
        kgSection:AddToggle({ Default = false, Name = "Anti Blind (Flashlight)", Flag = "Anti Blind (Flashlight)", Callback = function(v)
            VD.KILLER_AntiBlind = v; pcall(SetupAntiBlind)
        end })

        -- Silent Aim (Veil)
        local SilentAimTab = KillerTabbox1.SilentAim
        local saSection = SilentAimTab:AddSection({
            Position = "Center",
            Name = "Silent Aim Veil",
            Icon = "solar:crosshair-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        saSection:AddToggle({ Default = false, Name = "Silent Aim Veil", Flag = "Silent Aim Veil", Callback = function(v) VeilConfig.Enabled = v end })
        saSection:AddToggle({ Default = true, Name = "Show FOV Circle", Flag = "Show FOV Circle", Callback = function(v) VeilConfig.ShowFOV = v end })
        saSection:AddSlider({ Name = "FOV Radius", Flag = "FOV Radius", Min = 50, Max = 500, Default = 150, Callback = function(v) VeilConfig.FOV = v end })
        saSection:AddToggle({ Default = false, Name = "Auto Predict", Flag = "Auto Predict", Callback = function(v) VeilConfig.AutoPredict = v end })
        saSection:AddSlider({ Name = "Spear Speed", Flag = "Spear Speed", Min = 50, Max = 300, Default = 165, Callback = function(v) VeilConfig.SpearSpeed = v end })
        saSection:AddSlider({ Name = "Gravity", Flag = "Gravity", Min = 0, Max = 300, Default = math.floor(workspace.Gravity * 0.5), Callback = function(v) VeilConfig.Gravity = v end })
        saSection:AddSlider({ Name = "Horizontal Vector", Flag = "Horizontal Vector", Min = 0, Max = 10, Default = 2.8, Decimals = 1, Callback = function(v) VeilConfig.HorizontalPredictFactor = v end })
        saSection:AddDropdown({ Name = "Target Part", Flag = "Target Part", Values = {"Torso", "Head", "Root"}, Default = "Torso", Multi = false, Callback = function(v)
            if type(v) == "table" then v = v[1] end
            VeilConfig.TargetPart = v
        end })

        -- Customization
        local CustomizationTab = KillerTabbox2.Customization
        local custSection = CustomizationTab:AddSection({
            Position = "Center",
            Name = "Custom Masked",
            Icon = "solar:palette-bold",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        local customMaskedMasks = {"Richard", "Tony", "Brandon", "Jake", "Richter", "Graham", "Alex"}
        custSection:AddDropdown({
            Name = "Custom Masked",
            Flag = "Custom Masked",
            Values = customMaskedMasks,
            Multi = false,
            Default = VD.KILLER_CustomMasked or "Richard",
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                VD.KILLER_CustomMasked = v or "Richard"
            end
        })
        custSection:AddButton({
            Name = "Apply Custom Masked",
            Callback = function()
                pcall(IYAN_ApplyCustomMasked, VD.KILLER_CustomMasked)
            end
        })
        custSection:AddButton({
            Name = "Random Custom Masked",
            Callback = function()
                local mask = customMaskedMasks[math.random(1, #customMaskedMasks)]
                VD.KILLER_CustomMasked = mask
                pcall(IYAN_ApplyCustomMasked, mask)
            end
        })

        -- Visual: ESP subtab
        local ESPTab = VisualTabbox.ESP
        local espSection = ESPTab:AddSection({
            Position = "Center",
            Name = "Drawing ESP (PC Only)",
            Icon = "lucide:eye",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })
        espSection:AddToggle({ Default = false, Name = "Master Turn On Drawing ESP", Flag = "Master Turn On Drawing ESP", Callback = function(v) VD.DRAWING_ESP = v end })
        espSection:AddToggle({ Default = false, Name = "Low Performance Mode (disable skeleton & velocity)", Flag = "Low Performance Mode", Callback = function(v)
            VD.ESP_LowPerformance = v
            if v then
                VD.ESP_Skeleton = false
                VD.ESP_Velocity = false
                VD.ESP_Offscreen = false
                pcall(function()
                    if Window and Window.ConfigElements then
                        local skelElem = Window.ConfigElements["ESP Skeleton"]
                        if skelElem and skelElem.Set then skelElem:Set(false) end
                        local velElem = Window.ConfigElements["ESP Velocity Arrows"]
                        if velElem and velElem.Set then velElem:Set(false) end
                        local offElem = Window.ConfigElements["ESP Offscreen Arrows"]
                        if offElem and offElem.Set then offElem:Set(false) end
                    end
                end)
            end
        end })
        espSection:AddSlider({
            Name = "Max ESP Distance", Flag = "Max ESP Distance",
            Min = 500, Max = 5000, Default = 2000,
            Callback = function(v) VD.MaxDistance = v end
        })
        espSection:AddToggle({ Default = false, Name = "ESP Skeleton (PC Only!)", Flag = "ESP Skeleton", Callback = function(v)
            if VD.ESP_LowPerformance and v then
                pcall(function()
                    if Window and Window.Notify then
                        Window:Notify({ Title = "ESP", Content = "Skeleton disabled in Low Performance mode", Duration = 2 })
                    end
                end)
                return
            end
            VD.ESP_Skeleton = v
        end })
        espSection:AddToggle({ Default = false, Name = "ESP Velocity Arrows (PC Only!)", Flag = "ESP Velocity Arrows", Callback = function(v)
            if VD.ESP_LowPerformance and v then
                pcall(function()
                    if Window and Window.Notify then
                        Window:Notify({ Title = "ESP", Content = "Velocity disabled in Low Performance mode", Duration = 2 })
                    end
                end)
                return
            end
            VD.ESP_Velocity = v
        end })
        espSection:AddToggle({ Default = false, Name = "ESP Offscreen Arrows (PC Only!)", Flag = "ESP Offscreen Arrows", Callback = function(v)
            if VD.ESP_LowPerformance and v then
                pcall(function()
                    if Window and Window.Notify then
                        Window:Notify({ Title = "ESP", Content = "Offscreen disabled in Low Performance mode", Duration = 2 })
                    end
                end)
                return
            end
            VD.ESP_Offscreen = v
        end })

        -- Highlight ESP subtab
        local HighlightTab = VisualTabbox.Highlight
        pcall(function()
            if getgenv().IYAN_AddVisualESPControls then
                getgenv().IYAN_AddVisualESPControls(HighlightTab)
            end
        end)

        -- Lighting subtab
        local LightingTab = VisualTabbox.Lighting
        local lightSection = LightingTab:AddSection({
            Position = "Center",
            Name = "Lighting Controls",
            Icon = "lucide:sun",
            Box = true,
            BoxBorder = true,
            Opened = false,
        })

        lightSection:AddToggle({
            Name = "Fullbright",
            Flag = "Fullbright (lighting preset)",
            Default = false,
            Callback = function(state)
                VD.Fullbright = state
                applyFullbright(state)
            end
        })

        lightSection:AddToggle({
            Name = "No Fog",
            Flag = "No Fog",
            Default = false,
            Callback = function(state)
                VD.NoFog = state
                applyNoFog(state)
            end
        })
    end

    -- =====================================================
    -- REMAINING FUNCTIONS (unchanged)
    -- =====================================================
    local IYAN_Cache = {
        Generators  = {},
        Gates       = {},
        Hooks       = {},
        Pallets     = {},
        Windows     = {},
        ClosestHook = nil,
        ExitPos     = nil
    }

    local function IYAN_ScanMap()
        local map = Workspace:FindFirstChild("Map")
        if not map then
            IYAN_Cache = {
                Generators = {}, Zombies = {}, Gates = {}, Hooks = {}, Pallets = {}, Windows = {}, ClosestHook = nil, ExitPos = nil, ExitPart = nil
            }
            return
        end

        local newGens, newZombies, newGates, newHooks, newPallets, newWindows = {}, {}, {}, {}, {}, {}
        local exitPos = nil
        local exitPart = nil

        if map:FindFirstChild("churchbell") then
            exitPart = map:FindFirstChild("churchbell")
            if exitPart:IsA("Model") then exitPart = exitPart.PrimaryPart or exitPart:FindFirstChildWhichIsA("BasePart") end
            if exitPart then exitPos = exitPart.Position else exitPos = Vector3.new(760.98, -20.14, -78.48) end
        end

        local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if finish then
            local fp = finish:IsA("BasePart") and finish or (finish:IsA("Model") and finish:FindFirstChildWhichIsA("BasePart"))
            if fp then exitPos = fp.Position; exitPart = fp end
        end

        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") then
                local part = obj:FindFirstChild("HitBox", true) or obj:FindFirstChild("GeneratorPoint", true) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local n = obj.Name
                    if n == "Generator" then
                        table.insert(newGens, { model = obj, part = part })
                    elseif n == "Gate" or n == "ExitGate" or obj:FindFirstChild("ExitLever") then
                        table.insert(newGates, { model = obj, part = part })
                    elseif n == "Hook" then
                        table.insert(newHooks, { model = obj, part = part })
                    elseif n == "Palletwrong" or n:lower():find("pallet") then
                        table.insert(newPallets, { model = obj, part = part })
                    elseif n == "Window" then
                        table.insert(newWindows, { model = obj, part = part })
                    end
                end
            elseif obj:IsA("BasePart") then
                if not exitPos and obj.Name:lower():find("finish") then
                    exitPos = obj.Position
                    exitPart = obj
                end
                if obj.Name == "VaultTrigger" then
                    table.insert(newWindows, { model = obj.Parent, part = obj })
                end
                if obj.Name == "VaultPoint" and obj.Parent and obj.Parent.Name == "VaultTrigger" then
                    table.insert(newWindows, { model = obj.Parent, part = obj })
                end
                if obj.Name == "PalletPoint" or obj.Name == "PalletPointSlide" then
                    table.insert(newPallets, { model = obj.Parent, part = obj })
                end
            end
        end

        IYAN_Cache.Generators = newGens
        IYAN_Cache.Gates      = newGates
        IYAN_Cache.Hooks      = newHooks
        IYAN_Cache.Pallets    = newPallets
        IYAN_Cache.Windows    = newWindows
        IYAN_Cache.ExitPos    = exitPos
        IYAN_Cache.ExitPart   = exitPart

        local root = Root
        if root and #IYAN_Cache.Hooks > 0 then
            local closest, closestDist = nil, math.huge
            for _, hook in ipairs(IYAN_Cache.Hooks) do
                if hook.part then
                    local d = (hook.part.Position - root.Position).Magnitude
                    if d < closestDist then
                        closestDist = d; closest = hook
                    end
                end
            end
            IYAN_Cache.ClosestHook = closest
        end
    end

    local originalCanCollide = {}

    function IYAN_TeleportToGenerator(index)
        if not IYAN_Cache or not IYAN_Cache.Generators or #IYAN_Cache.Generators == 0 then return false end
        local sorted = {}
        for _, gen in ipairs(IYAN_Cache.Generators) do
            table.insert(sorted, {gen = gen, dist = (Root and (gen.part.Position - Root.Position).Magnitude) or math.huge})
        end
        table.sort(sorted, function(a, b) return a.dist < b.dist end)
        local target = sorted[index or 1]
        if not target then return false end
        return IYAN_TeleportToPosition(target.gen.part.Position)
    end

    function IYAN_TeleportToGate()
        if not IYAN_Cache or not IYAN_Cache.Gates or #IYAN_Cache.Gates == 0 then return false end
        local closest, closestDist = nil, math.huge
        for _, gate in ipairs(IYAN_Cache.Gates) do
            local dist = (Root and (gate.part.Position - Root.Position).Magnitude) or math.huge
            if dist < closestDist then
                closestDist = dist
                closest = gate
            end
        end
        if not closest then return false end
        return IYAN_TeleportToPosition(closest.part.Position)
    end

    function IYAN_TeleportToHook()
        if not IYAN_Cache or not IYAN_Cache.ClosestHook then return false end
        return IYAN_TeleportToPosition(IYAN_Cache.ClosestHook.part.Position)
    end

    function IYAN_TeleportToPosition(pos)
        if not pos then return false end
        local root = Root
        if not root then return false end
        if LocalPlayer.Character then
            root.Anchored = true
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if originalCanCollide[part] == nil then originalCanCollide[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        task.delay(0.3, function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        pcall(function()
                            part.CanCollide = (originalCanCollide[part] ~= nil) and originalCanCollide[part] or true
                        end)
                    end
                end
                root.Anchored = false
            end
            originalCanCollide = {}
        end)
        return true
    end

    local function IYAN_ApplyCustomMasked(maskName)
        local selectedMask = maskName or VD.KILLER_CustomMasked or "Richard"
        if type(selectedMask) == "table" then
            selectedMask = selectedMask[1]
        end
        if type(selectedMask) ~= "string" or selectedMask == "" then
            selectedMask = "Richard"
        end

        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local killers = remotes and remotes:FindFirstChild("Killers")
        local masked = killers and killers:FindFirstChild("Masked")
        local activatePower = masked and masked:FindFirstChild("Activatepower")

        if activatePower and activatePower:IsA("RemoteEvent") then
            activatePower:FireServer(selectedMask)
            return true
        end
        return false
    end

    function SetupAntiBlind()
        pcall(function()
            local r  = ReplicatedStorage:FindFirstChild("Remotes")
            local i  = r and r:FindFirstChild("Items")
            local fl = i and i:FindFirstChild("Flashlight")
            local gb = fl and fl:FindFirstChild("GotBlinded")
            if not (gb and gb:IsA("RemoteEvent")) then return end

            local ok, mt = pcall(function() return getrawmetatable(game) end)
            if ok and mt and setreadonly then
                pcall(function()
                    setreadonly(mt, false)
                    local old = mt.__namecall
                    mt.__namecall = newcclosure(function(self, ...)
                        if not checkcaller() and VD.KILLER_AntiBlind and self == gb then
                            local method = getnamecallmethod()
                            if method == "FireServer" and GetRole() == "Killer" then
                                return nil
                            end
                        end
                        return old(self, ...)
                    end)
                    setreadonly(mt, true)
                end)
            end
        end)
    end
    pcall(SetupAntiBlind)

    function IYAN_FlingNearest()
        if not VD.FLING_Enabled then return end
        local root = Root
        if not root then return end
        local closest, closestDist = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local tr = player.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local dist = (tr.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist; closest = player
                    end
                end
            end
        end
        if closest and closest.Character then
            local tr = closest.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local originalPos = root.CFrame
                for _ = 1, 10 do
                    root.CFrame      = tr.CFrame
                    root.Velocity    = Vector3.new(VD.FLING_Strength, VD.FLING_Strength / 2, VD.FLING_Strength)
                    root.RotVelocity = Vector3.new(9999, 9999, 9999)
                    task.wait()
                end
                root.CFrame      = originalPos
                root.Velocity    = Vector3.zero
                root.RotVelocity = Vector3.zero
            end
        end
    end

    function IYAN_FlingAll()
        if not VD.FLING_Enabled then return end
        local root = Root
        if not root then return end
        local originalPos = root.CFrame
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local tr = player.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    for _ = 1, 5 do
                        root.CFrame      = tr.CFrame
                        root.Velocity    = Vector3.new(VD.FLING_Strength, VD.FLING_Strength / 2, VD.FLING_Strength)
                        root.RotVelocity = Vector3.new(9999, 9999, 9999)
                        task.wait()
                    end
                end
            end
        end
        root.CFrame      = originalPos
        root.Velocity    = Vector3.zero
        root.RotVelocity = Vector3.zero
    end

    local function GetRole()
        if not LocalPlayer.Team then return "Unknown" end
        local name = LocalPlayer.Team.Name
        if name == "Killer" then return "Killer" end
        if name == "Survivors" then return "Survivor" end
        return "Lobby"
    end

    local function IsKiller(player)
        return player and player.Team and player.Team.Name == "Killer"
    end

    local function IsSurvivor(player)
        return player and player.Team and player.Team.Name == "Survivors"
    end

    local function IYAN_AutoAttack()
        if not VD.AUTO_Attack or GetRole() ~= "Killer" then return end
        local root = Root
        if not root then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsSurvivor(player) and player.Character then
                local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local tHum = player.Character:FindFirstChildOfClass("Humanoid")

                if tRoot and tHum and tHum.MaxHealth > 0 then
                    local pct = tHum.Health / tHum.MaxHealth
                    if pct > 0.25 and (tRoot.Position - root.Position).Magnitude <= VD.AUTO_AttackRange then
                        pcall(function()
                            local r = ReplicatedStorage:FindFirstChild("Remotes")
                            local a = r and r:FindFirstChild("Attacks")
                            local b = a and a:FindFirstChild("BasicAttack")
                            if b then b:FireServer(false) end
                        end)
                        break
                    end
                end
            end
        end
    end

    local function IYAN_DoubleTap()
        if not VD.KILLER_DoubleTap or GetRole() ~= "Killer" then return end
        if tick() - LastDoubleTapTime < 0.5 then return end
        pcall(function()
            local r  = ReplicatedStorage:FindFirstChild("Remotes")
            local a  = r and r:FindFirstChild("Attacks")
            local ba = a and a:FindFirstChild("BasicAttack")
            if ba then
                ba:FireServer(false)
                task.wait(0.05)
                ba:FireServer(false)
                LastDoubleTapTime = tick()
            end
        end)
    end
    local LastDoubleTapTime = 0

    local IsBreakingPallet = false
    local function IYAN_DestroyAllPallets()
        if not VD.KILLER_DestroyPallets or GetRole() ~= "Killer" then return end
        if IsBreakingPallet then return end

        local char = LocalPlayer.Character
        local root = Root
        if not char or not root then return end

        local stunned = char:GetAttribute("IsStunned") or char:GetAttribute("isStunned")
        local immobile = char:GetAttribute("Immobile") or char:GetAttribute("immobile")
        local carrying = char:GetAttribute("IsCarrying") or char:GetAttribute("isCarrying")
        local pursuit = char:GetAttribute("Pursuit") or char:GetAttribute("pursuit")
        local ci = char:FindFirstChild("CheckInterractable")
        local action = ci and (ci:GetAttribute("action") or ci:GetAttribute("Action"))

        if stunned or immobile or carrying or pursuit or action then return end

        local CollectionService = game:GetService("CollectionService")
        local pts = CollectionService:GetTagged("PalletPointSlide")
        local nearest, minDist = nil, 6
        for _, p in ipairs(pts) do
            if p:IsA("BasePart") and not CollectionService:HasTag(p, "doing action") then
                local d = (p.Position - root.Position).Magnitude
                if d < minDist then
                    minDist = d
                    nearest = p
                end
            end
        end

        if nearest then
            IsBreakingPallet = true
            task.spawn(function()
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("Remotes")
                    local p = r and r:FindFirstChild("Pallet")
                    local j = p and p:FindFirstChild("Jason")
                    if j then
                        local dg = j:FindFirstChild("Destroy-Global")
                        local commit = j:FindFirstChild("PalletBreakCommit")
                        if dg and dg:IsA("RemoteEvent") then dg:FireServer(nearest) end
                        if commit and commit:IsA("RemoteEvent") then commit:FireServer(nearest) end
                    end
                end)
                task.wait(0.2)
                local startTime = os.clock()
                while char and char.Parent and (char:GetAttribute("Immobile") or char:GetAttribute("immobile")) do
                    if os.clock() - startTime > 3 then break end
                    task.wait(0.1)
                end
                IsBreakingPallet = false
            end)
        end
    end

    getgenv().IYAN_IsBreakingGenerator = false
    function IYAN_AutoBreakGene()
        if not VD.KILLER_AutoBreakGene or GetRole() ~= "Killer" then return end
        if getgenv().IYAN_IsBreakingGenerator then return end

        local char = LocalPlayer.Character
        local root = Root
        if not char or not root then return end

        local stunned = char:GetAttribute("IsStunned") or char:GetAttribute("isStunned")
        local immobile = char:GetAttribute("Immobile") or char:GetAttribute("immobile")
        local carrying = char:GetAttribute("IsCarrying") or char:GetAttribute("isCarrying")
        local pursuit = char:GetAttribute("Pursuit") or char:GetAttribute("pursuit")
        local ci = char:FindFirstChild("CheckInterractable")
        local action = ci and (ci:GetAttribute("action") or ci:GetAttribute("Action"))

        if stunned or immobile or carrying or pursuit or action then return end

        local CollectionService = game:GetService("CollectionService")
        local pts = CollectionService:GetTagged("GeneratorPoint")
        local nearest, minDist = nil, 6
        for _, p in ipairs(pts) do
            if p:IsA("BasePart") and not CollectionService:HasTag(p, "doing action") then
                local genModel = p.Parent
                if genModel then
                    local progress = genModel:GetAttribute("RepairProgress") or genModel:GetAttribute("repairProgress") or 0
                    local kickcount = genModel:GetAttribute("kickcount") or genModel:GetAttribute("KickCount") or 0
                    if progress > 0 and progress < 100 and kickcount <= 7 then
                        local d = (p.Position - root.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            nearest = p
                        end
                    end
                end
            end
        end

        if nearest then
            getgenv().IYAN_IsBreakingGenerator = true
            task.spawn(function()
                pcall(function()
                    local r = ReplicatedStorage:FindFirstChild("Remotes")
                    local g = r and r:FindFirstChild("Generator")
                    if g then
                        local event = g:FindFirstChild("BreakGenEvent")
                        local commit = g:FindFirstChild("BreakGenCommit")
                        if event and event:IsA("RemoteEvent") then event:FireServer(nearest) end
                        if commit and commit:IsA("RemoteEvent") then commit:FireServer(nearest) end
                    end
                end)
                task.wait(0.2)
                local startTime = os.clock()
                while char and char.Parent and (char:GetAttribute("Immobile") or char:GetAttribute("immobile")) do
                    if os.clock() - startTime > 3 then break end
                    task.wait(0.1)
                end
                task.wait(0.3)
                getgenv().IYAN_IsBreakingGenerator = false
            end)
        end
    end

    getgenv().IYAN_LastVaultBlockTime = 0
    function IYAN_BlockAllVaults()
        if not VD.KILLER_BlockVaults or GetRole() ~= "Killer" then return end
        local now = tick()
        if now - getgenv().IYAN_LastVaultBlockTime < 1.5 then return end
        getgenv().IYAN_LastVaultBlockTime = now

        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local vaultEvent = remotes and remotes:FindFirstChild("Window") and remotes.Window:FindFirstChild("VaultEvent")
            if not vaultEvent then return end

            local map = Workspace:FindFirstChild("Map")
            local vaultsFolder = map and map:FindFirstChild("Vaults")

            if vaultsFolder then
                for _, vault in ipairs(vaultsFolder:GetChildren()) do
                    for _, part in ipairs(vault:GetChildren()) do
                        if part:IsA("BasePart") then
                            pcall(function() vaultEvent:FireServer(part, true) end)
                        end
                    end
                end
            else
                for _, win in ipairs(IYAN_Cache.Windows or {}) do
                    local window = win.model
                    if window and window.Parent then
                        for _, child in ipairs(window:GetDescendants()) do
                            if child:IsA("BasePart") then
                                pcall(function() vaultEvent:FireServer(child, true) end)
                            end
                        end
                    end
                end
            end
        end)
    end

    RunService.Heartbeat:Connect(function()
        if VD.SURV_FleeKiller then
            pcall(function()
                local root = Root
                if not root then return end
                if GetRole() == "Killer" then return end
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and IsKiller(player) then
                        local killerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if killerRoot and (killerRoot.Position - root.Position).Magnitude <= (VD.SURV_FleeDistance or 40) then
                            local direction = (root.Position - killerRoot.Position).Unit
                            root.CFrame = CFrame.new(root.Position + direction * ((VD.SURV_FleeDistance or 40) + 15), root.Position + direction * 100)
                            break
                        end
                    end
                end
            end)
        end
    end)

    -- =====================================================
    -- OPTIMIZED DRAWING ESP
    -- =====================================================
    local DrawingESP = { cache = {}, velocityData = {} }

    local function DrawingESP_create()
        local box = SafeDrawing("Square")
        if box then
            box.Filled = false
            box.Thickness = 1
            box.Visible = false
        end
        local healthBg = SafeDrawing("Square")
        if healthBg then
            healthBg.Filled = true
            healthBg.Color = Color3.fromRGB(25, 25, 25)
            healthBg.Visible = false
        end
        local healthBar = SafeDrawing("Square")
        if healthBar then
            healthBar.Filled = true
            healthBar.Visible = false
        end
        local name = SafeDrawing("Text")
        if name then
            name.Size = 14
            name.Font = Drawing.Fonts.UI
            name.Center = true
            name.Outline = true
            name.Visible = false
        end
        local dist = SafeDrawing("Text")
        if dist then
            dist.Size = 12
            dist.Font = Drawing.Fonts.Monospace
            dist.Center = true
            dist.Outline = true
            dist.Color = Color3.fromRGB(180, 180, 180)
            dist.Visible = false
        end
        local skel = {}
        for i = 1, 7 do
            local l = SafeDrawing("Line")
            if l then
                l.Thickness = 1
                l.Visible = false
            end
            skel[i] = l
        end
        local offscreen = SafeDrawing("Triangle")
        if offscreen then
            offscreen.Filled = true
            offscreen.Visible = false
        end
        local velLine = SafeDrawing("Line")
        if velLine then
            velLine.Thickness = 2
            velLine.Color = Color3.fromRGB(0, 255, 255)
            velLine.Visible = false
        end
        local velArrow = SafeDrawing("Triangle")
        if velArrow then
            velArrow.Filled = true
            velArrow.Color = Color3.fromRGB(0, 255, 255)
            velArrow.Visible = false
        end
        return {
            Box = box,
            HealthBg = healthBg,
            HealthBar = healthBar,
            Name = name,
            Dist = dist,
            Skel = skel,
            Offscreen = offscreen,
            VelLine = velLine,
            VelArrow = velArrow,
        }
    end

    local function DrawingESP_hideAll(esp)
        if not esp then return end
        if esp.Box then esp.Box.Visible = false end
        if esp.HealthBg then esp.HealthBg.Visible = false end
        if esp.HealthBar then esp.HealthBar.Visible = false end
        if esp.Name then esp.Name.Visible = false end
        if esp.Dist then esp.Dist.Visible = false end
        if esp.Offscreen then esp.Offscreen.Visible = false end
        if esp.VelLine then esp.VelLine.Visible = false end
        if esp.VelArrow then esp.VelArrow.Visible = false end
        for _, l in ipairs(esp.Skel) do if l then l.Visible = false end end
    end

    local function DrawingESP_render(esp, player, char, cam, screenSize, screenCenter)
        if not esp or not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not head then
            DrawingESP_hideAll(esp)
            return
        end

        local myRoot = Root
        local dist   = myRoot and (root.Position - myRoot.Position).Magnitude or 0
        if dist > VD.MaxDistance then
            DrawingESP_hideAll(esp)
            return
        end

        local isKillerPlayer = IsKiller(player)
        local visible = true
        if VD.AIM_VisCheck or VD.AIM_Enabled then
            local camPos                      = cam.CFrame.Position
            local params                      = RaycastParams.new()
            params.FilterType                 = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = { cam, LocalPlayer.Character, char }
            local ray                         = workspace:Raycast(camPos, head.Position - camPos, params)
            visible                           = (ray == nil)
        end

        local col      = isKillerPlayer
            and (visible and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(255, 65, 65))
            or (visible and Color3.fromRGB(120, 255, 170) or Color3.fromRGB(65, 220, 130))
        local skelCol  = visible and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 255, 255)

        local headPos  = head.Position + Vector3.new(0, 0.5, 0)
        local feetPos  = root.Position - Vector3.new(0, 3, 0)
        local rs       = cam:WorldToViewportPoint(root.Position)
        local hs       = cam:WorldToViewportPoint(headPos)
        local fs       = cam:WorldToViewportPoint(feetPos)
        local onScreen = rs.Z > 0 and rs.X > 0 and rs.X < screenSize.X and rs.Y > 0 and rs.Y < screenSize.Y

        if not onScreen then
            DrawingESP_hideAll(esp)
            if VD.ESP_Offscreen and not VD.ESP_LowPerformance then
                local dx    = rs.X - screenCenter.X
                local dy    = rs.Y - screenCenter.Y
                local angle = math.atan2(dy, dx)
                local edge  = 50
                local aX    = math.clamp(screenCenter.X + math.cos(angle) * (screenSize.X / 2 - edge), edge,
                    screenSize.X - edge)
                local aY    = math.clamp(screenCenter.Y + math.sin(angle) * (screenSize.Y / 2 - edge), edge,
                    screenSize.Y - edge)
                local fwd   = Vector2.new(math.cos(angle), math.sin(angle))
                local right = Vector2.new(-fwd.Y, fwd.X)
                local pos   = Vector2.new(aX, aY)
                local sz    = 12
                if esp.Offscreen then
                    esp.Offscreen.PointA  = pos + fwd * sz
                    esp.Offscreen.PointB  = pos - fwd * sz / 2 - right * sz / 2
                    esp.Offscreen.PointC  = pos - fwd * sz / 2 + right * sz / 2
                    esp.Offscreen.Color   = col
                    esp.Offscreen.Visible = true
                end
            else
                if esp.Offscreen then esp.Offscreen.Visible = false end
            end
            return
        end

        if esp.Offscreen then esp.Offscreen.Visible = false end

        local boxTop    = hs.Y
        local boxBottom = fs.Y
        local boxHeight = math.abs(boxBottom - boxTop)
        local boxWidth  = boxHeight * 0.6
        local cx        = rs.X

        if esp.Box then
            esp.Box.Position = Vector2.new(cx - boxWidth / 2, boxTop)
            esp.Box.Size = Vector2.new(boxWidth, boxHeight)
            esp.Box.Color = col
            esp.Box.Visible = true
        end

        if hum and hum.MaxHealth > 0 and esp.HealthBg and esp.HealthBar then
            local healthPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barWidth = boxWidth * 0.8
            local barHeight = 4
            local barX = cx - barWidth / 2
            local barY = boxBottom + 2
            esp.HealthBg.Position = Vector2.new(barX, barY)
            esp.HealthBg.Size = Vector2.new(barWidth, barHeight)
            esp.HealthBg.Visible = true
            esp.HealthBar.Position = Vector2.new(barX, barY)
            esp.HealthBar.Size = Vector2.new(barWidth * healthPct, barHeight)
            esp.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPct), 255 * healthPct, 0)
            esp.HealthBar.Visible = true
        else
            if esp.HealthBg then esp.HealthBg.Visible = false end
            if esp.HealthBar then esp.HealthBar.Visible = false end
        end

        local visualTextActive = false
        pcall(function()
            local fn = getgenv().IYAN_VD_VisualESP_HasPlayerText
            visualTextActive = type(fn) == "function" and fn(player) == true
        end)

        if esp.Name then
            if visualTextActive then
                esp.Name.Visible = false
            else
                esp.Name.Text = player.Name
                esp.Name.Position = Vector2.new(cx, boxTop - 18)
                esp.Name.Color = col
                esp.Name.Visible = true
            end
        end
        if esp.Dist then
            if visualTextActive then
                esp.Dist.Visible = false
            else
                esp.Dist.Text = math.floor(dist) .. "m"
                esp.Dist.Position = Vector2.new(cx, boxBottom + 2 + (hum and hum.MaxHealth > 0 and 6 or 2))
                esp.Dist.Visible = true
            end
        end

        if VD.ESP_Skeleton and not VD.ESP_LowPerformance and hum then
            local bones = (char:FindFirstChild("Torso") and {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"},
                {"UpperTorso", "RightUpperArm"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LowerTorso", "RightUpperLeg"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
            }) or {
                {"Head", "Torso"},
                {"Torso", "Left Arm"},
                {"Torso", "Right Arm"},
                {"Torso", "Left Leg"},
                {"Torso", "Right Leg"},
            }
            local maxLines = math.min(#bones, #esp.Skel)
            for i = 1, maxLines do
                local b = bones[i]
                if esp.Skel[i] then
                    local p1 = char:FindFirstChild(b[1])
                    local p2 = char:FindFirstChild(b[2])
                    if p1 and p2 then
                        local s1 = cam:WorldToViewportPoint(p1.Position)
                        local s2 = cam:WorldToViewportPoint(p2.Position)
                        if s1.Z > 0 and s2.Z > 0 then
                            esp.Skel[i].From    = Vector2.new(s1.X, s1.Y)
                            esp.Skel[i].To      = Vector2.new(s2.X, s2.Y)
                            esp.Skel[i].Color   = skelCol
                            esp.Skel[i].Visible = true
                        else
                            esp.Skel[i].Visible = false
                        end
                    else
                        esp.Skel[i].Visible = false
                    end
                end
            end
            for i = maxLines + 1, #esp.Skel do
                if esp.Skel[i] then esp.Skel[i].Visible = false end
            end
        else
            for _, l in ipairs(esp.Skel) do if l then l.Visible = false end end
        end

        if VD.ESP_Velocity and not VD.ESP_LowPerformance then
            local vd = DrawingESP.velocityData[player]
            if not vd then
                vd = { pos = root.Position, vel = Vector3.zero, time = tick() }
                DrawingESP.velocityData[player] = vd
            end
            local now = tick()
            local dt = now - vd.time
            if dt > 0.03 then
                local rawVel = (root.Position - vd.pos) / dt
                vd.vel = vd.vel * 0.7 + rawVel * 0.3
                vd.pos = root.Position
                vd.time = now
            end
            local velFlat = Vector3.new(vd.vel.X, 0, vd.vel.Z)
            local velMag = velFlat.Magnitude
            if velMag > 2 then
                local futurePos = root.Position + velFlat.Unit * math.clamp(velMag * 0.4, 5, 20)
                local futureScreen = cam:WorldToViewportPoint(futurePos)
                if futureScreen.Z > 0 then
                    if esp.VelLine then
                        esp.VelLine.From = Vector2.new(rs.X, rs.Y)
                        esp.VelLine.To = Vector2.new(futureScreen.X, futureScreen.Y)
                        esp.VelLine.Visible = true
                    end
                    local dx = futureScreen.X - rs.X
                    local dy = futureScreen.Y - rs.Y
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 5 and esp.VelArrow then
                        local fx, fy = dx / len, dy / len
                        esp.VelArrow.PointA = Vector2.new(futureScreen.X, futureScreen.Y)
                        esp.VelArrow.PointB = Vector2.new(futureScreen.X - fx * 10 + fy * 5, futureScreen.Y - fy * 10 - fx * 5)
                        esp.VelArrow.PointC = Vector2.new(futureScreen.X - fx * 10 - fy * 5, futureScreen.Y - fy * 10 + fx * 5)
                        esp.VelArrow.Visible = true
                    elseif esp.VelArrow then
                        esp.VelArrow.Visible = false
                    end
                else
                    if esp.VelLine then esp.VelLine.Visible = false end
                    if esp.VelArrow then esp.VelArrow.Visible = false end
                end
            else
                if esp.VelLine then esp.VelLine.Visible = false end
                if esp.VelArrow then esp.VelArrow.Visible = false end
            end
        else
            if esp.VelLine then esp.VelLine.Visible = false end
            if esp.VelArrow then esp.VelArrow.Visible = false end
        end
    end

    local function OnRenderStep()
        if VD.Destroyed then
            if DrawingAvailable then
                for _, esp in pairs(DrawingESP.cache) do
                    if esp then
                        SafeRemove(esp.Box)
                        SafeRemove(esp.HealthBg)
                        SafeRemove(esp.HealthBar)
                        SafeRemove(esp.Name)
                        SafeRemove(esp.Dist)
                        SafeRemove(esp.Offscreen)
                        SafeRemove(esp.VelLine)
                        SafeRemove(esp.VelArrow)
                        for _, l in ipairs(esp.Skel) do SafeRemove(l) end
                    end
                end
                DrawingESP.cache = {}
            end
            return
        end

        Camera = Workspace.CurrentCamera or Camera
        local cam = Camera
        if not cam then return end
        local screenSize   = cam.ViewportSize
        local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        local now          = tick()
        local canUpdateESP = now >= Perf.NextDrawingESP
        if canUpdateESP then
            Perf.NextDrawingESP = now + Perf.DrawingESPInterval
        end

        if DrawingAvailable then
            if VD.DRAWING_ESP then
                if canUpdateESP then
                    local validPlayers = {}
                    for _, p in ipairs(Players:GetPlayers()) do validPlayers[p] = true end
                    for player, esp in pairs(DrawingESP.cache) do
                        if not validPlayers[player] then
                            if esp then
                                SafeRemove(esp.Box)
                                SafeRemove(esp.HealthBg)
                                SafeRemove(esp.HealthBar)
                                SafeRemove(esp.Name)
                                SafeRemove(esp.Dist)
                                SafeRemove(esp.Offscreen)
                                SafeRemove(esp.VelLine)
                                SafeRemove(esp.VelArrow)
                                for _, l in ipairs(esp.Skel) do SafeRemove(l) end
                            end
                            DrawingESP.cache[player] = nil
                            DrawingESP.velocityData[player] = nil
                        end
                    end

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            if not DrawingESP.cache[player] then
                                DrawingESP.cache[player] = DrawingESP_create()
                            end
                            DrawingESP_render(DrawingESP.cache[player], player, player.Character, cam, screenSize, screenCenter)
                        end
                    end
                end
            else
                for _, esp in pairs(DrawingESP.cache) do
                    if esp then
                        SafeRemove(esp.Box)
                        SafeRemove(esp.HealthBg)
                        SafeRemove(esp.HealthBar)
                        SafeRemove(esp.Name)
                        SafeRemove(esp.Dist)
                        SafeRemove(esp.Offscreen)
                        SafeRemove(esp.VelLine)
                        SafeRemove(esp.VelArrow)
                        for _, l in ipairs(esp.Skel) do SafeRemove(l) end
                    end
                end
                DrawingESP.cache = {}
            end
        end
    end

    if DrawingAvailable then
        RunService.RenderStepped:Connect(OnRenderStep)
    end

    -- HEARTBEAT LOOP
    RunService.Heartbeat:Connect(function()
        if VD.Destroyed then return end
        pcall(IYAN_AutoAttack)
        pcall(IYAN_DestroyAllPallets)
        pcall(IYAN_AutoBreakGene)
        pcall(IYAN_BlockAllVaults)
        pcall(IYAN_DoubleTap)
    end)

    -- MAP SCAN LOOP
    task.spawn(function()
        while not VD.Destroyed do
            pcall(IYAN_ScanMap)
            task.wait(0.5)
        end
    end)

    -- ============================================================
    -- AUTO DROP PALLET LOGIC (placed here for completeness)
    -- ============================================================
    local _usedPallets = {}
    local _lastPalletDrop = 0
    local _lastPalletScan = 0

    RunService.Heartbeat:Connect(function()
        if not VD.SURV_AutoDropPallet or GetRole() ~= "Survivor" then return end
        if tick() - _lastPalletScan < 0.2 or tick() - _lastPalletDrop < 2.5 then return end
        _lastPalletScan = tick()

        pcall(function()
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not myRoot or not hum or hum.Health <= 0 then return end

            if VD.SURV_AutoDropPalletMode == "Safe" then
                local isCarried = char:GetAttribute("IsCarried") or char:GetAttribute("isCarried")
                if isCarried then return end
            end

            local killerRoot = nil
            local triggerDist = VD.SURV_AutoDropPalletDist or 20
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and IsKiller(plr) and plr.Character then
                    local kr = plr.Character:FindFirstChild("HumanoidRootPart")
                    if kr then
                        local dist = (kr.Position - myRoot.Position).Magnitude
                        if dist < triggerDist then
                            killerRoot = kr
                            break
                        end
                    end
                end
            end
            if not killerRoot then return end

            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local palletFold = remotes and remotes:FindFirstChild("Pallet")
            local dropEvent = palletFold and palletFold:FindFirstChild("PalletDropEvent")
            if not dropEvent then return end

            local bestPallet, bestDist = nil, 8
            for _, pal in ipairs(IYAN_Cache.Pallets) do
                local palModel = pal.model
                if not palModel then continue end
                if _usedPallets[palModel] then continue end
                local refPart = pal.part or palModel:FindFirstChild("PalletPoint") or palModel:FindFirstChild("PalletPointSlide")
                if not refPart then continue end
                local ok, pos = pcall(function() return refPart.Position end)
                if not ok or not pos then continue end
                local d = (myRoot.Position - pos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestPallet = palModel
                end
            end

            if bestPallet then
                local fireTarget = bestPallet:FindFirstChild("PalletPointSlide") or bestPallet:FindFirstChild("PalletPoint")
                if fireTarget then
                    pcall(function() dropEvent:FireServer(fireTarget) end)
                    _usedPallets[bestPallet] = true
                    _lastPalletDrop = tick()
                    task.delay(3, function()
                        _usedPallets[bestPallet] = nil
                    end)
                end
            end
        end)
    end)

    -- ============================================================
    -- AUTO VAULT & AUTO PALLET SLIDE (integrated into the same heartbeat)
    -- ============================================================
    local _vaultedWindows = {}
    local _lastVaultScan = 0
    local _lastPalletSlideScan = 0
    local _slidedPallets = {}

    RunService.Heartbeat:Connect(function()
        -- AUTO VAULT
        if VD.SURV_AutoVault and GetRole() == "Survivor" and tick() - _lastVaultScan > 0.15 then
            _lastVaultScan = tick()
            pcall(function()
                local char = LocalPlayer.Character
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not myRoot or not hum or hum.Health <= 0 then return end

                local vel = myRoot.AssemblyLinearVelocity
                if vel.Magnitude < 1 then return end

                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local winFolder = remotes and remotes:FindFirstChild("Window")
                local vaultEv = winFolder and winFolder:FindFirstChild("VaultCommit")
                if not vaultEv then return end

                local windowGroups = {}
                for _, win in ipairs(IYAN_Cache.Windows or {}) do
                    local part = win.part or win.model
                    if part then
                        local rootWindow = part.Parent
                        if part.Name == "VaultPoint" and part.Parent and part.Parent.Name == "VaultTrigger" then
                            rootWindow = part.Parent.Parent
                        elseif part.Name == "VaultTrigger" and part.Parent then
                            rootWindow = part.Parent
                        end
                        if rootWindow then
                            windowGroups[rootWindow] = windowGroups[rootWindow] or {}
                            local exists = false
                            for _, p in ipairs(windowGroups[rootWindow]) do
                                if p == part then exists = true; break end
                            end
                            if not exists then table.insert(windowGroups[rootWindow], part) end
                        end
                    end
                end

                for rootWindow, parts in pairs(windowGroups) do
                    local function getVTPosition(vt)
                        if vt:IsA("BasePart") then return vt.Position end
                        if vt:IsA("Model") then
                            if vt.PrimaryPart then return vt.PrimaryPart.Position end
                            local bp = vt:FindFirstChildWhichIsA("BasePart", true)
                            if bp then return bp.Position end
                        end
                        return nil
                    end

                    local allVTs = {}
                    for _, child in ipairs(rootWindow:GetChildren()) do
                        if child.Name == "VaultTrigger" then table.insert(allVTs, child) end
                    end
                    if #allVTs == 0 then continue end

                    local nearestVT, nearestVTDist = nil, math.huge
                    for _, vt in ipairs(allVTs) do
                        local pos = getVTPosition(vt)
                        if pos then
                            local d = (myRoot.Position - pos).Magnitude
                            if d < nearestVTDist then
                                nearestVTDist = d
                                nearestVT = vt
                            end
                        end
                    end
                    if not nearestVT or nearestVTDist > 6.0 then continue end

                    local lastUsed = _vaultedWindows[rootWindow] or 0
                    if tick() - lastUsed < 3.0 then continue end

                    local finalTarget = nearestVT
                    local remotes2 = ReplicatedStorage:FindFirstChild("Remotes")
                    local winFold = remotes2 and remotes2:FindFirstChild("Window")
                    if winFold and finalTarget then
                        local vaultEvent = winFold:FindFirstChild("VaultEvent")
                        local vaultBindable = winFold:FindFirstChild("Vaultbindable")
                        local fastvault = winFold:FindFirstChild("fastvault")
                        local vaultComplete1 = winFold:FindFirstChild("VaultCompleteEventpart1")
                        local vaultComplete = winFold:FindFirstChild("VaultCompleteEvent")
                        if vaultEvent then pcall(function() vaultEvent:FireServer(finalTarget, true) end) end
                        if vaultBindable then pcall(function() vaultBindable:Fire(finalTarget, true) end) end
                        if fastvault then pcall(function() fastvault:FireServer(LocalPlayer) end) end
                        if vaultComplete1 then pcall(function() vaultComplete1:FireServer() end) end
                        if vaultComplete then pcall(function() vaultComplete:FireServer(finalTarget, false) end) end
                    end

                    _vaultedWindows[rootWindow] = tick()
                    break
                end
            end)
        end

        -- AUTO PALLET SLIDE
        if VD.SURV_AutoPalletSlide and GetRole() == "Survivor" and tick() - _lastPalletSlideScan > 0.15 then
            _lastPalletSlideScan = tick()
            pcall(function()
                local char = LocalPlayer.Character
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not myRoot or not hum or hum.Health <= 0 then return end

                local vel = myRoot.AssemblyLinearVelocity
                if vel.Magnitude < 1 then return end

                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local palletFold = remotes and remotes:FindFirstChild("Pallet")
                local palletSlideEvent = palletFold and palletFold:FindFirstChild("PalletSlideEvent")
                local slidebindable = palletFold and palletFold:FindFirstChild("Slidebindable")
                if not palletSlideEvent then return end

                local tagged = CollectionService:GetTagged("PalletPointSlide")
                local bestPart, bestDist = nil, 6.0
                for _, part in ipairs(tagged) do
                    if not part:IsA("BasePart") then continue end
                    if part:IsDescendantOf(char) then continue end
                    if _slidedPallets[part] then continue end
                    local palletModel = part.Parent
                    local ok, destroyed = pcall(function() return palletModel:GetAttribute("Destroyed") end)
                    if ok and destroyed == true then continue end
                    local d = (part.Position - myRoot.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPart = part
                    end
                end

                if not bestPart then
                    for _, pal in ipairs(IYAN_Cache.Pallets or {}) do
                        local palModel = pal.model
                        if not palModel then continue end
                        if _slidedPallets[palModel] then continue end
                        local slide = palModel:FindFirstChild("PalletPointSlide") or palModel:FindFirstChild("PalletPointSlide", true)
                        if not slide then continue end
                        local ok2, destroyed2 = pcall(function() return palModel:GetAttribute("Destroyed") end)
                        if ok2 and destroyed2 == true then continue end
                        local d = (slide.Position - myRoot.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestPart = slide
                        end
                    end
                end

                if bestPart then
                    local isSprinting = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Sprinting") or false
                    pcall(function() palletSlideEvent:FireServer(bestPart, isSprinting) end)
                    if slidebindable then pcall(function() slidebindable:Fire(bestPart, isSprinting) end) end
                    _slidedPallets[bestPart] = true
                    _lastPalletSlideScan = tick() + 3.8
                    task.delay(3.0, function() _slidedPallets[bestPart] = nil end)
                end
            end)
        end
    end)

    -- CLEANUP ON DESTROY
end

__ZiaanHub_Init_Main__()
