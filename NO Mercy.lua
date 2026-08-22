-- [[ CUSTOM UI LIBRARY (SMOOTH RAYFIELD STYLE & ICONS) ]] --
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Library = {}

-- 1. Intro Animasi Bubble Lebih Smooth & Keren
function Library.ShowIntro(titleText)
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "LibraryIntro"
    IntroGui.Parent = CoreGui
    
    local Bubble = Instance.new("Frame")
    Bubble.Size = UDim2.new(0, 0, 0, 0)
    Bubble.Position = UDim2.new(0.5, 0, 0.5, 0)
    Bubble.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Bubble.BorderSizePixel = 0
    Bubble.Parent = IntroGui
    
    local BubbleCorner = Instance.new("UICorner")
    BubbleCorner.CornerRadius = UDim.new(1, 0)
    BubbleCorner.Parent = Bubble
    
    local BubbleStroke = Instance.new("UIStroke")
    BubbleStroke.Color = Color3.fromRGB(0, 170, 255)
    BubbleStroke.Thickness = 2.5
    BubbleStroke.Parent = Bubble
    
    local IntroText = Instance.new("TextLabel")
    IntroText.Size = UDim2.new(1, 0, 1, 0)
    IntroText.BackgroundTransparency = 1
    IntroText.Text = titleText or "LOADING..."
    IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
    IntroText.TextSize = 15
    IntroText.Font = Enum.Font.GothamBold
    IntroText.TextTransparency = 1
    IntroText.Parent = Bubble
    
    -- Animasi Masuk ala Rayfield (Smooth Elastic/Back)
    Bubble.Visible = true
    local tweenIn = TweenService:Create(Bubble, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 220, 0, 65), 
        Position = UDim2.new(0.5, -110, 0.5, -32.5)
    })
    tweenIn:Play()
    
    task.wait(0.3)
    TweenService:Create(IntroText, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
    
    -- Jeda tampil
    task.wait(2)
    
    -- Animasi Keluar Smooth
    TweenService:Create(IntroText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    local tweenOut = TweenService:Create(Bubble, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0), 
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tweenOut:Play()
    
    task.wait(0.5)
    IntroGui:Destroy()
end

-- 2. Fungsi Utama Membuat Window
function Library:CreateWindow(windowTitle, configFileName)
    local Window = {}
    local ConfigName = configFileName or "MyUIConfig.json"
    local SavedData = {}
    
    if writefile and readfile then
        pcall(function()
            if not isfolder("MyUILibraryConfigs") then
                makefolder("MyUILibraryConfigs")
            end
            local filePath = "MyUILibraryConfigs/" .. ConfigName
            if pcall(readfile, filePath) then
                SavedData = HttpService:JSONDecode(readfile(filePath))
            end
        end)
    end
    
    local function SaveConfig()
        if writefile then
            pcall(function()
                local filePath = "MyUILibraryConfigs/" .. ConfigName
                writefile(filePath, HttpService:JSONEncode(SavedData))
            end)
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CustomUILibrary"
    ScreenGui.Parent = CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 520, 0, 340)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(45, 45, 45)
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 12)
    TopCorner.Parent = TopBar
    
    local FixCorner = Instance.new("Frame")
    FixCorner.Size = UDim2.new(1, 0, 0, 6)
    FixCorner.Position = UDim2.new(0, 0, 1, -6)
    FixCorner.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    FixCorner.BorderSizePixel = 0
    FixCorner.Parent = TopBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(240, 240, 240)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Text = windowTitle or "My UI Library"
    Title.Parent = TopBar
    
    -- Tombol Minimize (-) dengan Efek Hover Smooth
    local MinButton = Instance.new("TextButton")
    MinButton.Size = UDim2.new(0, 32, 0, 26)
    MinButton.Position = UDim2.new(1, -38, 0.5, -13)
    MinButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinButton.TextSize = 16
    MinButton.Font = Enum.Font.GothamBold
    MinButton.Parent = TopBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinButton
    
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TopBar and child ~= MainCorner and child ~= MainStroke then
                child.Visible = not minimized
            end
        end
        local targetSize = minimized and UDim2.new(0, 520, 0, 38) or UDim2.new(0, 520, 0, 340)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    end)
    
    -- Dragging Window Smooth
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local TabBar = Instance.new("ScrollingFrame")
    TabBar.Size = UDim2.new(0, 140, 1, -50)
    TabBar.Position = UDim2.new(0, 12, 0, 44)
    TabBar.BackgroundTransparency = 1
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.ScrollBarThickness = 2
    TabBar.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.Parent = TabBar
    
    local ContentHolder = Instance.new("Frame")
    ContentHolder.Size = UDim2.new(1, -168, 1, -50)
    ContentHolder.Position = UDim2.new(0, 158, 0, 44)
    ContentHolder.BackgroundTransparency = 1
    ContentHolder.Parent = MainFrame
    
    local firstTab = true
    
    function Window:AddTab(tabName)
        local Tab = {}
        
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 2, 0)
        Page.ScrollBarThickness = 4
        Page.Visible = false
        Page.Parent = ContentHolder
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = Page
        
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 32)
        TabButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
        TabButton.Text = "  " .. tabName
        TabButton.TextColor3 = Color3.fromRGB(160, 160, 160)
        TabButton.TextSize = 13
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Parent = TabBar
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabButton
        
        local function selectTab()
            for _, p in ipairs(ContentHolder:GetChildren()) do
                p.Visible = false
            end
            for _, b in ipairs(TabBar:GetChildren()) do
                if b:IsA("TextButton") then
                    TweenService:Create(b, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(160, 160, 160), BackgroundColor3 = Color3.fromRGB(28, 28, 28)}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
        end
        
        TabButton.MouseButton1Click:Connect(selectTab)
        
        if firstTab then
            firstTab = false
            selectTab()
        end
        
        -- Tombol dengan Support Ikon (Info, Player, Closure, Tengkorak, Teleport, Sepatu, Setting)
        function Tab:AddButton(buttonText, iconId, callback)
            callback = callback or function() end
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 36)
            Button.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
            Button.AutoButtonColor = false
            Button.Text = "       " .. buttonText
            Button.TextColor3 = Color3.fromRGB(230, 230, 230)
            Button.TextSize = 13
            Button.Font = Enum.Font.GothamSemibold
            Button.TextXAlignment = Enum.TextXAlignment.Left
            Button.Parent = Page
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 6)
            BtnCorner.Parent = Button
            
            if iconId and iconId ~= "" then
                Button.Text = "          " .. buttonText
                local Icon = Instance.new("ImageLabel")
                Icon.Size = UDim2.new(0, 18, 0, 18)
                Icon.Position = UDim2.new(0, 10, 0.5, -9)
                Icon.BackgroundTransparency = 1
                Icon.Image = iconId
                Icon.Parent = Button
            end
            
            Button.MouseButton1Click:Connect(function()
                -- Efek klik membal halus ala Rayfield
                TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
                task.wait(0.1)
                TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(32, 32, 32)}):Play()
                pcall(callback)
            end)
        end
        
        -- Toggle dengan Animasi Indicator Smooth
        function Tab:AddToggle(toggleId, toggleText, defaultState, callback)
            local state = SavedData[toggleId] ~= nil and SavedData[toggleId] or (defaultState or false)
            callback = callback or function() end
            pcall(callback, state)
            
            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 36)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Text = ""
            ToggleFrame.Parent = Page
            
            local TglCorner = Instance.new("UICorner")
            TglCorner.CornerRadius = UDim.new(0, 6)
            TglCorner.Parent = ToggleFrame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -55, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleText
            Label.TextColor3 = Color3.fromRGB(230, 230, 230)
            Label.TextSize = 13
            Label.Font = Enum.Font.GothamSemibold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            
            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 22, 0, 22)
            Indicator.Position = UDim2.new(1, -32, 0.5, -11)
            Indicator.BackgroundColor3 = state and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 50)
            Indicator.BorderSizePixel = 0
            Indicator.Parent = ToggleFrame
            
            local IndCorner = Instance.new("UICorner")
            IndCorner.CornerRadius = UDim.new(0, 5)
            IndCorner.Parent = Indicator
            
            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                local targetColor = state and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 50)
                TweenService:Create(Indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
                SavedData[toggleId] = state
                SaveConfig()
                pcall(callback, state)
            end)
        end
        
        return Tab
    end
    
    return Window
end

-- ==========================================
-- CONTOH PENGGUNAAN DENGAN IKON LENGKAP
-- ==========================================
Library.ShowIntro("PANEL RAYFIELD STYLE")
task.wait(2.7)

local Window = Library:CreateWindow("Panel Mandiri Pro", "ConfigKu.json")
local TabUtama = Window:AddTab("Menu Utama")

-- Daftar ID Ikon yang bisa kamu pakai (Bisa diganti ID Roblox lainnya):
-- 1. Info: rbxassetid://6023426915
-- 2. Player: rbxassetid://6023426915 (atau ID Player lain)
-- 3. Closure/Tutup: rbxassetid://6031091004
-- 4. Tengkorak: rbxassetid://6023426810
-- 5. Teleport: rbxassetid://6023426846
-- 6. Sepatu (Speed): rbxassetid://6023566892
-- 7. Setting: rbxassetid://6031263148

TabUtama:AddButton("Informasi Game", "rbxassetid://6023426915", function()
    print("Tombol Info ditekan!")
end)

TabUtama:AddButton("Teleport Area", "rbxassetid://6023426846", function()
    print("Tombol Teleport ditekan!")
end)

TabUtama:AddButton("Menu Sepatu (Speed)", "rbxassetid://6023566892", function()
    print("Tombol Sepatu ditekan!")
end)

TabUtama:AddButton("Mode Tengkorak", "rbxassetid://6023426810", function()
    print("Tombol Tengkorak ditekan!")
end)

TabUtama:AddButton("Pengaturan (Setting)", "rbxassetid://6031263148", function()
    print("Tombol Setting ditekan!")
end)

TabUtama:AddToggle("fitur_auto", "Aktifkan Fitur Utama", false, function(state)
    print("Status Toggle:", state)
end)
