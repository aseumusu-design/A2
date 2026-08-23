--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              NEXUS UI LIBRARY - EXAMPLE USAGE                 ║
    ║         Full Demo with All 60 Icons & Components              ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- Load the library (replace with your actual URL or local path)
local NexusUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/NexusUI/main/NexusUI_Library.lua"))()

-- ═══════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════════════════════════

local Window = NexusUI:CreateWindow({
    Title = "NEXUS HUB",
    SubTitle = "v2.0 • Premium",
    Theme = "Dark", -- Options: Dark, Midnight, Crimson, Forest, Void
    Size = UDim2.new(0, 780, 0, 520)
})

-- ═══════════════════════════════════════════════════════════════
-- TABS WITH 60 UNIQUE ICONS
-- ═══════════════════════════════════════════════════════════════

-- Tab 1: Farm (Icons 21-30)
local FarmTab = Window:Tab({ 
    Name = "Auto Farm", 
    Icon = NexusUI.Icons[21].Icon, -- 🌾
    Description = "Farming automation tools"
})

-- Tab 2: Speed (Icons 31-40)
local SpeedTab = Window:Tab({ 
    Name = "Movement", 
    Icon = NexusUI.Icons[31].Icon, -- 🏃
    Description = "Speed & movement hacks"
})

-- Tab 3: Combat (Icons 11-20)
local CombatTab = Window:Tab({ 
    Name = "Combat", 
    Icon = NexusUI.Icons[11].Icon, -- ⚔️
    Description = "Combat & aimbot tools"
})

-- Tab 4: Visual (Icons 41-50)
local VisualTab = Window:Tab({ 
    Name = "Visual", 
    Icon = NexusUI.Icons[41].Icon, -- 👁️
    Description = "ESP & visual enhancements"
})

-- Tab 5: Misc (Icons 51-60)
local MiscTab = Window:Tab({ 
    Name = "Misc", 
    Icon = NexusUI.Icons[51].Icon, -- 💰
    Description = "Utility & misc features"
})

-- Tab 6: Settings (Icon 2)
local SettingsTab = Window:Tab({ 
    Name = "Settings", 
    Icon = NexusUI.Icons[2].Icon, -- ⚙️
    Description = "Configuration options"
})

-- ═══════════════════════════════════════════════════════════════
-- FARM TAB COMPONENTS
-- ═══════════════════════════════════════════════════════════════

FarmTab:Section("🌾 Auto Farm")

FarmTab:Toggle({
    Text = "Enable Auto Farm",
    Default = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        print("Auto Farm:", Value)
        if Value then
            NexusUI:Notify({
                Title = "Auto Farm",
                Message = "Auto farming started!",
                Type = "Success",
                Duration = 3
            })
        end
    end
})

FarmTab:Toggle({
    Text = "Auto Collect Drops",
    Default = false,
    Flag = "AutoCollect",
    Callback = function(Value)
        print("Auto Collect:", Value)
    end
})

FarmTab:Toggle({
    Text = "Auto Sell Items",
    Default = false,
    Flag = "AutoSell",
    Callback = function(Value)
        print("Auto Sell:", Value)
    end
})

FarmTab:Slider({
    Text = "Farm Speed Multiplier",
    Min = 1,
    Max = 10,
    Default = 1,
    Increment = 0.5,
    Suffix = "x",
    Flag = "FarmSpeed",
    Callback = function(Value)
        print("Farm Speed:", Value)
    end
})

FarmTab:Dropdown({
    Text = "Farm Mode",
    Options = {"Normal", "Fast", "Extreme", "Legit"},
    Default = "Normal",
    Flag = "FarmMode",
    Callback = function(Value)
        print("Farm Mode:", Value)
        NexusUI:Notify({
            Title = "Farm Mode",
            Message = "Switched to " .. Value .. " mode",
            Type = "Info",
            Duration = 2
        })
    end
})

FarmTab:Section("🌲 Resource Farm")

FarmTab:Toggle({
    Text = "Auto Chop Trees",
    Default = false,
    Flag = "AutoChop",
    Callback = function(Value)
        print("Auto Chop:", Value)
    end
})

FarmTab:Toggle({
    Text = "Auto Mine Rocks",
    Default = false,
    Flag = "AutoMine",
    Callback = function(Value)
        print("Auto Mine:", Value)
    end
})

FarmTab:Toggle({
    Text = "Auto Fish",
    Default = false,
    Flag = "AutoFish",
    Callback = function(Value)
        print("Auto Fish:", Value)
    end
})

-- ═══════════════════════════════════════════════════════════════
-- SPEED TAB COMPONENTS
-- ═══════════════════════════════════════════════════════════════

SpeedTab:Section("🏃 Speed Hacks")

SpeedTab:Toggle({
    Text = "Enable Speed Hack",
    Default = false,
    Flag = "SpeedHack",
    Callback = function(Value)
        print("Speed Hack:", Value)
        if Value then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Window:GetFlag("WalkSpeed") or 50
        else
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
})

SpeedTab:Slider({
    Text = "Walk Speed",
    Min = 16,
    Max = 500,
    Default = 50,
    Suffix = " studs",
    Flag = "WalkSpeed",
    Callback = function(Value)
        if Window:GetFlag("SpeedHack") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

SpeedTab:Toggle({
    Text = "Fly Mode",
    Default = false,
    Flag = "FlyMode",
    Callback = function(Value)
        print("Fly Mode:", Value)
        if Value then
            NexusUI:Notify({
                Title = "Fly Mode",
                Message = "Press SPACE to go up, LEFT SHIFT to go down",
                Type = "Info",
                Duration = 4
            })
        end
    end
})

SpeedTab:Slider({
    Text = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Suffix = " studs",
    Flag = "FlySpeed",
    Callback = function(Value)
        print("Fly Speed:", Value)
    end
})

SpeedTab:Keybind({
    Text = "Fly Toggle Key",
    Default = "F",
    Flag = "FlyKey",
    Callback = function(Key)
        print("Fly Key pressed:", Key)
    end
})

SpeedTab:Section("🚀 Teleport")

SpeedTab:Button({
    Text = "Teleport to Spawn",
    Icon = NexusUI.Icons[34].Icon, -- ⚡
    Callback = function()
        print("Teleporting to spawn...")
        NexusUI:Notify({
            Title = "Teleport",
            Message = "Teleported to spawn!",
            Type = "Success"
        })
    end
})

SpeedTab:Button({
    Text = "Teleport to Safe Zone",
    Icon = NexusUI.Icons[53].Icon, -- 🚪
    Callback = function()
        print("Teleporting to safe zone...")
    end
})

-- ═══════════════════════════════════════════════════════════════
-- COMBAT TAB COMPONENTS
-- ═══════════════════════════════════════════════════════════════

CombatTab:Section("⚔️ Aimbot")

CombatTab:Toggle({
    Text = "Enable Aimbot",
    Default = false,
    Flag = "Aimbot",
    Callback = function(Value)
        print("Aimbot:", Value)
    end
})

CombatTab:Toggle({
    Text = "Silent Aim",
    Default = false,
    Flag = "SilentAim",
    Callback = function(Value)
        print("Silent Aim:", Value)
    end
})

CombatTab:Toggle({
    Text = "Team Check",
    Default = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        print("Team Check:", Value)
    end
})

CombatTab:Slider({
    Text = "Aimbot FOV",
    Min = 10,
    Max = 500,
    Default = 150,
    Suffix = "°",
    Flag = "AimFOV",
    Callback = function(Value)
        print("Aim FOV:", Value)
    end
})

CombatTab:Slider({
    Text = "Aim Smoothness",
    Min = 1,
    Max = 100,
    Default = 50,
    Suffix = "%",
    Flag = "AimSmooth",
    Callback = function(Value)
        print("Aim Smooth:", Value)
    end
})

CombatTab:Dropdown({
    Text = "Aim Part",
    Options = {"Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Legs"},
    Default = "Head",
    Flag = "AimPart",
    Callback = function(Value)
        print("Aim Part:", Value)
    end
})

CombatTab:Section("🛡️ Combat Misc")

CombatTab:Toggle({
    Text = "Auto Parry",
    Default = false,
    Flag = "AutoParry",
    Callback = function(Value)
        print("Auto Parry:", Value)
    end
})

CombatTab:Toggle({
    Text = "Anti-Aim",
    Default = false,
    Flag = "AntiAim",
    Callback = function(Value)
        print("Anti-Aim:", Value)
    end
})

CombatTab:Keybind({
    Text = "Aimbot Key",
    Default = "Q",
    Flag = "AimKey",
    Callback = function(Key)
        print("Aim Key:", Key)
    end
})

-- ═══════════════════════════════════════════════════════════════
-- VISUAL TAB COMPONENTS
-- ═══════════════════════════════════════════════════════════════

VisualTab:Section("👁️ ESP Settings")

VisualTab:Toggle({
    Text = "Player ESP",
    Default = false,
    Flag = "PlayerESP",
    Callback = function(Value)
        print("Player ESP:", Value)
    end
})

VisualTab:Toggle({
    Text = "Box ESP",
    Default = false,
    Flag = "BoxESP",
    Callback = function(Value)
        print("Box ESP:", Value)
    end
})

VisualTab:Toggle({
    Text = "Tracer ESP",
    Default = false,
    Flag = "TracerESP",
    Callback = function(Value)
        print("Tracer ESP:", Value)
    end
})

VisualTab:Toggle({
    Text = "Name ESP",
    Default = false,
    Flag = "NameESP",
    Callback = function(Value)
        print("Name ESP:", Value)
    end
})

VisualTab:Toggle({
    Text = "Distance ESP",
    Default = false,
    Flag = "DistanceESP",
    Callback = function(Value)
        print("Distance ESP:", Value)
    end
})

VisualTab:Toggle({
    Text = "Health ESP",
    Default = false,
    Flag = "HealthESP",
    Callback = function(Value)
        print("Health ESP:", Value)
    end
})

VisualTab:ColorPicker({
    Text = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(Color)
        print("ESP Color:", Color)
    end
})

VisualTab:Section("🗺️ World Visuals")

VisualTab:Toggle({
    Text = "Full Bright",
    Default = false,
    Flag = "FullBright",
    Callback = function(Value)
        print("Full Bright:", Value)
        if Value then
            game.Lighting.Brightness = 10
            game.Lighting.ClockTime = 12
        else
            game.Lighting.Brightness = 2
        end
    end
})

VisualTab:Toggle({
    Text = "No Fog",
    Default = false,
    Flag = "NoFog",
    Callback = function(Value)
        print("No Fog:", Value)
        if Value then
            game.Lighting.FogEnd = 100000
        end
    end
})

VisualTab:Slider({
    Text = "Field of View",
    Min = 30,
    Max = 120,
    Default = 70,
    Suffix = "°",
    Flag = "FOV",
    Callback = function(Value)
        game.Workspace.CurrentCamera.FieldOfView = Value
    end
})

-- ═══════════════════════════════════════════════════════════════
-- MISC TAB COMPONENTS
-- ═══════════════════════════════════════════════════════════════

MiscTab:Section("💰 Economy")

MiscTab:Toggle({
    Text = "Auto Buy Items",
    Default = false,
    Flag = "AutoBuy",
    Callback = function(Value)
        print("Auto Buy:", Value)
    end
})

MiscTab:Toggle({
    Text = "Infinite Money",
    Default = false,
    Flag = "InfMoney",
    Callback = function(Value)
        print("Inf Money:", Value)
    end
})

MiscTab:Section("🤖 Automation")

MiscTab:Toggle({
    Text = "Anti-AFK",
    Default = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        print("Anti-AFK:", Value)
    end
})

MiscTab:Toggle({
    Text = "Auto Quest",
    Default = false,
    Flag = "AutoQuest",
    Callback = function(Value)
        print("Auto Quest:", Value)
    end
})

MiscTab:Section("🛠️ Utilities")

MiscTab:Button({
    Text = "Rejoin Server",
    Icon = NexusUI.Icons[9].Icon, -- ↻
    Callback = function()
        NexusUI:Notify({
            Title = "Server",
            Message = "Rejoining server...",
            Type = "Warning"
        })
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

MiscTab:Button({
    Text = "Server Hop",
    Icon = NexusUI.Icons[38].Icon, -- ⛵
    Callback = function()
        print("Server hopping...")
        NexusUI:Notify({
            Title = "Server",
            Message = "Hopping to new server...",
            Type = "Info"
        })
    end
})

MiscTab:Input({
    Text = "Target Player",
    Placeholder = "Enter player name...",
    Flag = "TargetPlayer",
    Callback = function(Text)
        print("Target:", Text)
    end
})

MiscTab:Button({
    Text = "Copy Player List",
    Icon = NexusUI.Icons[52].Icon, -- 🔑
    Callback = function()
        local players = {}
        for _, p in pairs(game.Players:GetPlayers()) do
            table.insert(players, p.Name)
        end
        print("Players:", table.concat(players, ", "))
        NexusUI:Notify({
            Title = "Players",
            Message = #players .. " players in server",
            Type = "Success"
        })
    end
})

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS TAB COMPONENTS
-- ═══════════════════════════════════════════════════════════════

SettingsTab:Section("⚙️ UI Settings")

SettingsTab:Dropdown({
    Text = "Theme",
    Options = {"Dark", "Midnight", "Crimson", "Forest", "Void"},
    Default = "Dark",
    Callback = function(Value)
        print("Theme changed to:", Value)
        NexusUI:Notify({
            Title = "Theme",
            Message = "Theme set to " .. Value,
            Type = "Success"
        })
    end
})

SettingsTab:Slider({
    Text = "UI Scale",
    Min = 50,
    Max = 150,
    Default = 100,
    Suffix = "%",
    Flag = "UIScale",
    Callback = function(Value)
        print("UI Scale:", Value .. "%")
    end
})

SettingsTab:Toggle({
    Text = "Show Notifications",
    Default = true,
    Flag = "ShowNotifs",
    Callback = function(Value)
        print("Notifications:", Value)
    end
})

SettingsTab:Toggle({
    Text = "Sound Effects",
    Default = true,
    Flag = "SoundFX",
    Callback = function(Value)
        print("Sound FX:", Value)
    end
})

SettingsTab:Section("💾 Configuration")

SettingsTab:Button({
    Text = "Save Config",
    Icon = "💾",
    Callback = function()
        -- Save flags to file or datastore
        print("Saving config...")
        print("Flags:", Window.Flags)
        NexusUI:Notify({
            Title = "Config Saved",
            Message = "All settings saved successfully!",
            Type = "Success",
            Duration = 3
        })
    end
})

SettingsTab:Button({
    Text = "Load Config",
    Icon = "📂",
    Callback = function()
        print("Loading config...")
        NexusUI:Notify({
            Title = "Config Loaded",
            Message = "Settings restored from save!",
            Type = "Success"
        })
    end
})

SettingsTab:Button({
    Text = "Reset to Default",
    Icon = "↺",
    Callback = function()
        print("Resetting config...")
        NexusUI:Notify({
            Title = "Reset",
            Message = "All settings reset to default!",
            Type = "Warning"
        })
    end
})

SettingsTab:Keybind({
    Text = "Toggle UI Key",
    Default = "RightShift",
    Flag = "ToggleUI",
    Callback = function()
        Window:ToggleVisibility()
    end
})

SettingsTab:Label({
    Text = "Nexus UI Library v2.0 | Made with ❤️",
    Color = NexusUI.CurrentTheme.TextDark
})

-- ═══════════════════════════════════════════════════════════════
-- WELCOME NOTIFICATION
-- ═══════════════════════════════════════════════════════════════

task.wait(1)
NexusUI:Notify({
    Title = "🎉 Nexus Hub Loaded!",
    Message = "Welcome " .. game.Players.LocalPlayer.Name .. "! Press RightShift to toggle UI.",
    Type = "Success",
    Duration = 5
})

NexusUI:Notify({
    Title = "💡 Tip",
    Message = "Use the Farm tab to start auto farming resources!",
    Type = "Info",
    Duration = 4
})
