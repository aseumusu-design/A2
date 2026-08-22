-- [[ CUSTOM UI LIBRARY (FIXED & FULL FEATURES) ]] --
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Library = {}

-- 1. Fungsi Intro Animasi Bubble
function Library.ShowIntro(titleText)
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "LibraryIntro"
    IntroGui.Parent = CoreGui
    
    local Bubble = Instance.new("Frame")
    Bubble.Size = UDim2.new(0, 0, 0, 0)
    Bubble.Position = UDim2.new(0.5, 0, 0.5, 0)
    Bubble.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Bubble.BorderSizePixel = 0
    Bubble.Parent = IntroGui
    
    local BubbleCorner = Instance.new("UICorner")
    BubbleCorner.CornerRadius = UDim.new(1, 0)
    BubbleCorner.Parent = Bubble
    
    local BubbleStroke = Instance.new("UIStroke")
    BubbleStroke.Color = Color3.fromRGB(0, 170, 255)
    BubbleStroke.Thickness = 2
    BubbleStroke.Parent = Bubble
    
    local IntroText = Instance.new("TextLabel")
    IntroText.Size = UDim2.new(1, 0, 1, 0)
    IntroText.BackgroundTransparency = 1
    IntroText.Text = titleText or "LOADING..."
    IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
    IntroText.TextSize = 14
    IntroText.Font = Enum.Font.SourceSansBold
    IntroText.TextTransparency = 1
    IntroText.Parent = Bubble
    
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Bubble.Visible = true
    TweenService:Create(Bubble, tweenInfo, {Size = UDim2.new(0, 180, 0, 60), Position = UDim2.new(0.5, -90, 0.5, -30)}):Play()
    
    task.wait(0.4)
    TweenService:Create(IntroText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    
    task.wait(2)
    TweenService:Create(IntroText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(Bubble, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    
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
            local filePath = "MyUILibraryConfigs/" + ConfigName
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
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 10)
    TopCorner.Parent = TopBar
    
    local FixCorner = Instance.new("Frame")
    FixCorner.Size = UDim2.new(1, 0, 0, 5)
    FixCorner.Position = UDim2.new(0, 0, 1, -5)
    FixCorner.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    FixCorner.BorderSizePixel = 0
    FixCorner.Parent = TopBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.SourceSansBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Text = windowTitle or "My UI Library"
    Title.Parent = TopBar
    
    -- Tombol Minimize (-)
    local MinButton = Instance.new("TextButton")
    MinButton.Size = UDim2.new(0, 30, 0, 25)
    MinButton.Position = UDim2.new(1, -35, 0.5, -12.5)
    MinButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MinButton.Text = "-"
    MinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinButton.TextSize = 16
    MinButton.Font = Enum.Font.SourceSansBold
    MinButton.Parent = TopBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinButton
    
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TopBar and child ~= MainCorner then
                child.Visible = not minimized
            end
        end
        MainFrame.Size = minimized and UDim2.new(0, 500, 0, 35) or UDim2.new(0, 500, 0, 320)
    end)
    
    -- Dragging Window
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
    TabBar.Size = UDim2.new(0, 130, 1, -45)
    TabBar.Position = UDim2.new(0, 10, 0, 40)
    TabBar.BackgroundTransparency = 1
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.ScrollBarThickness = 2
    TabBar.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.Parent = TabBar
    
    local ContentHolder = Instance.new("Frame")
    ContentHolder.Size = UDim2.new(1, -155, 1, -45)
    ContentHolder.Position = UDim2.new(0, 145, 0, 40)
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
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
        TabButton.TextSize = 13
        TabButton.Font = Enum.Font.SourceSansSemibold
        TabButton.Parent = TabBar
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabButton
        
        -- Fungsi pilih tab
        local function selectTab()
            for _, p in ipairs(ContentHolder:GetChildren()) do
                p.Visible = false
            end
            for _, b in ipairs(TabBar:GetChildren()) do
                if b:IsA("TextButton") then
                    b.TextColor3 = Color3.fromRGB(180, 180, 180)
                    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                end
            end
            Page.Visible = true
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        end
        
        TabButton.MouseButton1Click:Connect(selectTab)
        
        -- Otomatis buka tab pertama kali dibuat
        if firstTab then
            firstTab = false
            selectTab()
        end
        
        -- 1. Button + Icon
        function Tab:AddButton(buttonText, iconId, callback)
            callback = callback or function() end
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Button.AutoButtonColor = false
            Button.Text = "       " .. buttonText
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.TextSize = 13
            Button.Font = Enum.Font.SourceSansSemibold
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
                pcall(callback)
            end)
        end
        
        -- 2. Toggle
        function Tab:AddToggle(toggleId, toggleText, defaultState, callback)
            local state = SavedData[toggleId] ~= nil and SavedData[toggleId] or (defaultState or false)
            callback = callback or function() end
            pcall(callback, state)
            
            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Text = ""
            ToggleFrame.Parent = Page
            
            local TglCorner = Instance.new("UICorner")
            TglCorner.CornerRadius = UDim.new(0, 6)
            TglCorner.Parent = ToggleFrame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = toggleText
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.TextSize = 13
            Label.Font = Enum.Font.SourceSansSemibold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            
            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 20, 0, 20)
            Indicator.Position = UDim2.new(1, -30, 0.5, -10)
            Indicator.BackgroundColor3 = state and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
            Indicator.BorderSizePixel = 0
            Indicator.Parent = ToggleFrame
            
            local IndCorner = Instance.new("UICorner")
            IndCorner.CornerRadius = UDim.new(0, 4)
            IndCorner.Parent = Indicator
            
            ToggleFrame.MouseButton1Click:Connect(function()
                state = not state
                Indicator.BackgroundColor3 = state and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
                SavedData[toggleId] = state
                SaveConfig()
                pcall(callback, state)
            end)
        end
        
        -- 3. Slider
        function Tab:AddSlider(sliderId, sliderText, minVal, maxVal, defaultVal, callback)
            minVal = minVal or 0
            maxVal = maxVal or 100
            local val = SavedData[sliderId] ~= nil and SavedData[sliderId] or (defaultVal or minVal)
            callback = callback or function() end
            pcall(callback, val)
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            SliderFrame.BorderSizePixel = 0
            SliderFrame.Parent = Page
            
            local SldCorner = Instance.new("UICorner")
            SldCorner.CornerRadius = UDim.new(0, 6)
            SldCorner.Parent = SliderFrame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = sliderText .. ": " .. tostring(val)
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.TextSize = 13
            Label.Font = Enum.Font.SourceSansSemibold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame
            
            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 0, 32)
            SliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            SliderBar.BorderSizePixel = 0
            SliderBar.Parent = SliderFrame
            
            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(0, 3)
            BarCorner.Parent = SliderBar
            
            local FillBar = Instance.new("Frame")
            FillBar.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
            FillBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            FillBar.BorderSizePixel = 0
            FillBar.Parent = SliderBar
            
            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 3)
            FillCorner.Parent = FillBar
            
            local draggingSlider = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                val = math.floor(minVal + ((maxVal - minVal) * pos))
                FillBar.Size = UDim2.new(pos, 0, 1, 0)
                Label.Text = sliderText .. ": " .. tostring(val)
                SavedData[sliderId] = val
                SaveConfig()
                pcall(callback, val)
            end
            
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end
        
        return Tab
    end
    
    return Window
end

-- ==========================================
-- CONTOH PENGGUNAAN / EKSEKUSI
-- ==========================================
Library.ShowIntro("PANEL MANDIRI")
task.wait(2.5)

local Window = Library:CreateWindow("Panel Mandiri", "ConfigKu.json")
local TabUtama = Window:AddTab("Utama")

-- Menambahkan Tombol, Toggle, dan Slider ke Tab Utama
TabUtama:AddButton("Tombol Info", "rbxassetid://6023426915", function()
    print("Tombol berhasil diklik!")
end)

TabUtama:AddToggle("toggle_farm", "Aktifkan Auto Farm", false, function(state)
    print("Auto Farm status:", state)
end)

TabUtama:AddSlider("slider_ws", "Kecepatan Jalan", 16, 200, 16, function(val)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)
