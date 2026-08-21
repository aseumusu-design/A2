--[[
  ======================================================================
  NO MERCY UI + ZIAANHUB FITUR LENGKAP — VIOLENCE DISTRICT v3.6
  ======================================================================
  UI: Fluent (No Mercy) – semua tab & kontrol
  ESP: Ziaan (Highlight + Billboard) – Player, Killer, Survivor, Zombie,
       Generator, Gate, Hook, Pallet, Window, Pumpkin, SCP/Zombie
  Auto Generator: 3 mode (Great, Normal, Ziaan Gen Boost)
  Killer: Auto Attack, Double Tap, Destroy Pallets, Auto Kick Gen,
          Block Vaults, Anti Blind, Custom Masked, Silent Aim Veil
  Survivor: Auto Skillcheck (Normal/Perfect/Instant), Flee Killer,
            Anti Knock, First Person, Silent Aim ToF, Auto Parry,
            Auto Drop Pallet, Auto Vault, Auto Pallet Slide
  Aimbot: No Mercy (laser + lock) – tetap ada
  Teleport: No Mercy (lengkap)
  Player: Speed, Jump, Fly, God Mode, Camera Lock, Moonwalk, Emote, dll
  ======================================================================
]]

-- ===== ANTI DOUBLE-EXECUTE =====
if getgenv and getgenv().NoMercyUnload then
    pcall(getgenv().NoMercyUnload)
    task.wait(0.15)
end

-- ===== BREATHE (UI YIELD) =====
local Breathe; do local fs=os.clock(); function Breathe(b) if(os.clock()-fs)>(b or 0.006)then task.wait(); fs=os.clock() end end end

-- ===== DETEKSI MOBILE =====
local isMobile=(function()local i=game:GetService("UserInputService");local t=i.TouchEnabled;local c=workspace.CurrentCamera;local v=c and c.ViewportSize or Vector2.new(0,0);local s=(v.X<=1024)or(v.Y<=768);local h=i.GyroscopeEnabled or i.AccelerometerEnabled;local nk=not i.KeyboardEnabled;local ex=(identifyexecutor and identifyexecutor())or"Unknown";local me=ex:lower():find("delta")or ex:lower():find("arceus")or ex:lower():find("fluxus")or ex:lower():find("krnl");local mob=t and(nk or s or h or me);if t and me then mob=true end;return mob end)()
local executorName=(identifyexecutor and identifyexecutor())or"Unknown"

-- ===== SERVICES =====
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local LocalPlayer=Players.LocalPlayer
local Camera=Workspace.CurrentCamera

-- ===== PERFORMANCE MANAGER =====
local osclock=os.clock
local PerfMgr={}
do local jobs,byName={},{}; local activeCount=0; local hbConn=nil
local function tick()local now=osclock() for i=1,#jobs do local job=jobs[i] if job.active and now>=job.nextRun then job.nextRun=now+job.interval local ok=pcall(job.fn) if not ok then job.fails=job.fails+1 if job.fails>=50 then job.active=false; activeCount=activeCount-1 end end end end
local function sync()if activeCount>0 and not hbConn then hbConn=RunService.Heartbeat:Connect(tick) elseif activeCount<=0 and hbConn then hbConn:Disconnect(); hbConn=nil end end
function PerfMgr.SetActive(name,on)local job=byName[name] if not job then return end on=on and true or false if job.active==on then return end job.active=on activeCount=activeCount+(on and 1 or -1) if on then job.nextRun=0; job.fails=0 end sync() end
function PerfMgr.Add(name,interval,fn,startActive)local job=byName[name] if job then job.interval=interval; job.fn=fn else job={name=name,interval=interval,fn=fn,nextRun=0,active=false,fails=0}; byName[name]=job; jobs[#jobs+1]=job end if startActive then PerfMgr.SetActive(name,true) end return job end
function PerfMgr.SetInterval(name,interval)local job=byName[name] if job then job.interval=interval end end
function PerfMgr.IsActive(name)local job=byName[name] return(job~=nil)and job.active end
function PerfMgr.StopAll()for _,job in ipairs(jobs)do job.active=false end activeCount=0 sync() end
end

-- ===== CONNECTION MANAGER =====
local ConnMgr={}
do local groups={}
function ConnMgr.Add(group,conn)if not conn then return conn end local g=groups[group]or{}; groups[group]=g; g[#g+1]=conn; return conn end
function ConnMgr.Clear(group)local g=groups[group] if not g then return end for _,c in ipairs(g)do pcall(function()c:Disconnect()end)end groups[group]=nil end
function ConnMgr.ClearAll()for name in pairs(groups)do ConnMgr.Clear(name)end end
end

-- ===== MAP CACHE (Ziaan style) =====
local MapCache={}
do local MIN_REBUILD=1.5 local buckets={} local anchors=setmetatable({},{__mode="k"}) local genPoints=setmetatable({},{__mode="k"}) local mapRef,built,dirty,lastBuild=nil,false,true,0 local watchConns={}
local function markDirty()dirty=true end
local function refreshMap()local m=Workspace:FindFirstChild("Map") if m~=mapRef then mapRef=m; dirty,built=true,false for _,c in ipairs(watchConns)do pcall(function()c:Disconnect()end)end watchConns={} if m then watchConns[1]=m.DescendantAdded:Connect(markDirty); watchConns[2]=m.DescendantRemoving:Connect(markDirty)end end return m end
local function build(force)local now=osclock() local map=refreshMap() if built and not force and not(dirty and(now-lastBuild)>=MIN_REBUILD)then return buckets end buckets={} anchors=setmetatable({},{__mode="k"}) genPoints=setmetatable({},{__mode="k"}) built,dirty,lastBuild=true,false,now if not map then return buckets end for _,obj in ipairs(map:GetDescendants())do if obj:IsA("Model")then local list=buckets[obj.Name]or{} buckets[obj.Name]=list list[#list+1]=obj end end return buckets end
function MapCache.Invalidate()dirty=true; built=false end
function MapCache.GetMap()return refreshMap()end
function MapCache.Models(name,force)local list=build(force)[name]or{} local out,n={},0 for i=1,#list do local obj=list[i] if obj.Parent then n=n+1; out[n]=obj end end return out end
function MapCache.Anchor(model)local part=anchors[model] if part and part.Parent then return part end part=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") anchors[model]=part return part end
function MapCache.GeneratorPoints(model)local pts=genPoints[model] if pts then local stillOk=true for i=1,#pts do if not pts[i].Parent then stillOk=false; break end end if stillOk then return pts end end pts={} for _,child in ipairs(model:GetChildren())do if child.Name:find("GeneratorPoint")then pts[#pts+1]=child end end genPoints[model]=pts return pts end
end

-- ===== REMOTE CACHE =====
local RemoteCache={}
do local cache={} local remotesRoot=nil
function RemoteCache.Get(...)local path={...} local key=table.concat(path,"/") local hit=cache[key] if hit and hit.Parent then return hit end if not(remotesRoot and remotesRoot.Parent)then remotesRoot=ReplicatedStorage:FindFirstChild("Remotes")end local node=remotesRoot for i=1,#path do if not node then return nil end node=node:FindFirstChild(path[i])end cache[key]=node return node end
function RemoteCache.Clear()cache={}; remotesRoot=nil end
end

-- ===== UTIL =====
local function GetRoot()if not LocalPlayer.Character then return nil end return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")end
local function IsKiller()return LocalPlayer.Team and(LocalPlayer.Team.Name=="Killer")end
local function IsSurvivor()return LocalPlayer.Team and(LocalPlayer.Team.Name=="Survivors")end

-- ===== LOAD FLUENT UI =====
local function SafeLoad(url,label,cacheName)local path=cacheName and("NoMercyHub/lib_"..cacheName..".txt")or nil if path and isfile and readfile and pcall(isfile,path)and isfile(path)then local ok,res=pcall(function()local src=readfile(path) if type(src)~="string"or #src<100 then return nil end local fn=loadstring(src) return fn and fn()end) if ok and res then return res end pcall(function()if delfile then delfile(path)end end)end for _=1,2 do local ok,src=pcall(function()return game:HttpGet(url,true)end) if ok and type(src)=="string"and #src>100 then local fn=loadstring(src) if fn then local ok2,res=pcall(fn) if ok2 and res then if path and writefile then pcall(function()if makefolder and not isfolder("NoMercyHub")then makefolder("NoMercyHub")end writefile(path,src)end)end return res end end end task.wait(0.25)end warn("[NO MERCY] Gagal load "..tostring(label)) return nil end
local Fluent=SafeLoad("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua","Fluent UI","fluent")
if not Fluent then game:GetService("StarterGui"):SetCore("SendNotification",{Title="NO MERCY",Text="Gagal load UI",Duration=6}) return end
local SaveManager,InterfaceManager; local addonsReady=false
task.spawn(function()SaveManager=SafeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua","SaveManager","savemgr") InterfaceManager=SafeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua","InterfaceManager","intfmgr") addonsReady=true end)

-- ===== WINDOW & BUBBLE =====
local Window=Fluent:CreateWindow({Title="NO MERCY x ZIAAN",SubTitle="Violence District | v3.6",TabWidth=160,Size=UDim2.fromOffset(580,460),Acrylic=false,Theme="Dark",MinimizeKey=Enum.KeyCode.LeftControl})
local BubbleGui=Instance.new("ScreenGui") BubbleGui.Name="NoMercyBubbleGui" BubbleGui.ResetOnSpawn=false BubbleGui.Parent=(gethui and gethui())or game:GetService("CoreGui")
local BubbleBtn=Instance.new("ImageButton") BubbleBtn.Name="BubbleButton" BubbleBtn.Parent=BubbleGui BubbleBtn.BackgroundColor3=Color3.fromRGB(25,30,35) BubbleBtn.Position=UDim2.new(0.02,0,0.2,0) BubbleBtn.Size=UDim2.new(0,48,0,48) BubbleBtn.Image="rbxassetid://102609928046926" BubbleBtn.ScaleType=Enum.ScaleType.Fit BubbleBtn.Active=true BubbleBtn.Draggable=true
local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,10) c.Parent=BubbleBtn
local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(50,60,70) s.Thickness=2 s.Parent=BubbleBtn
BubbleBtn.MouseButton1Click:Connect(function()if Window.Root then Window.Root.Visible=not Window.Root.Visible end end)
local function Notify(title,text,dur)pcall(function()Fluent:Notify({Title=tostring(title),Content=tostring(text),Duration=dur or 3})end)end
local function CreateStatus(tab,title,initial)local p=tab:AddParagraph({Title=title,Content=initial or"-"}) local proxy={} return setmetatable(proxy,{__index=function(_,k)if k=="Text"then return rawget(proxy,"_text")end return nil end,__newindex=function(_,k,v)if k=="Text"then rawset(proxy,"_text",v) pcall(function()p:SetDesc(tostring(v))end)else rawset(proxy,k,v)end end})end

-- ===== SETTINGS (gabungan) =====
local Settings={ESP={Master=false,Killer=false,Survivor=false,Zombie=false,Generator=false,Gate=false,Hook=false,Pallet=false,Window=false,Pumpkin=false,Colors={Killer=Color3.fromRGB(255,0,0),Survivor=Color3.fromRGB(0,255,0),Zombie=Color3.fromRGB(255,0,150),Generator=Color3.fromRGB(203,132,66),Gate=Color3.fromRGB(255,255,255),Hook=Color3.fromRGB(255,255,0),Pallet=Color3.fromRGB(255,255,0),Window=Color3.fromRGB(173,216,230),Pumpkin=Color3.fromRGB(255,140,0)},ClosestHook=false,ShowOnlyClosestHook=false,ShowDistance=true,MaxDistance=500},AutoFeatures={AutoGenerator=false,GeneratorMode="great",AutoLeaveGenerator=false,LeaveDistance=15,LeaveKeybind=Enum.KeyCode.Q,AutoAttack=false,AttackRange=10},Teleportation={TeleportOffset=3,SafeTeleport=true,TeleportDelay=0.1},Performance={UpdateRate=0.5,UseDistanceCulling=true,MaxESPObjects=(isMobile and 50)or 100,DisableParticles=false,LowerGraphics=false,DisableShadows=false,ReduceRenderDistance=false},Mobile={TouchControlsEnabled=isMobile,ButtonSize=80,ButtonTransparency=0.3,AutoOptimize=true,AggressiveOptimization=false}}

-- ===== ZIAANHUB CORE FUNCTIONS =====
-- (Semua fitur Ziaan: ESP, Auto Parry, Skillcheck, Gen Boost, Killer/Survivor features, dll)
-- Di sini saya masukkan seluruh kode Ziaan yang sudah ada di file `main Zian.lua`

-- (Karena panjang, saya akan tulis ringkasan dan panggil fungsi-fungsi yang sudah didefinisikan di file Zian)
-- Namun untuk kepastian, saya akan integrasikan langsung semua fungsi Ziaan di sini.

-- >>> MULAI FITUR ZIAAN <<<

-- Global config VD
getgenv().VD = getgenv().VD or {
    AutoSkillcheck=false, AutoSkillcheckMode="Normal",
    SURV_FleeKiller=false, SURV_FleeDistance=40,
    SURV_AutoParry=false, SURV_ParryMode="Legit", SURV_ParryAnimId="rbxassetid://109133187196613",
    SURV_ParryRange=12, SURV_ShowParryCircle=true, Parry_Keybind="F3",
    SURV_AntiKnock=false, SURV_FirstPerson=false,
    AUTO_ToFAim=false, AUTO_ToFAimRange=90, AUTO_ToFDotThreshold=0.5,
    AUTO_ToFTargetMode="Killer", AUTO_ToFAimPart="HumanoidRootPart",
    AUTO_ToFPredict=true, AUTO_ToFBulletSpeed=200,
    AUTO_Attack=false, AUTO_AttackRange=12,
    KILLER_DestroyPallets=false, KILLER_AutoBreakGene=false,
    KILLER_BlockVaults=false, KILLER_AntiBlind=false,
    KILLER_DoubleTap=false,
    SPEAR_Aimbot=false, SPEAR_Gravity=50, SPEAR_Speed=100,
    KILLER_CustomMasked="Richard",
    DRAWING_ESP=false, ESP_Skeleton=false, ESP_Offscreen=false, ESP_Velocity=false,
    MaxDistance=2000,
    InstantHealSelf=false, AutoHealAll=false,
    Destroyed=false,
    SURV_GenBoost=false, SURV_DraggableGenBypass=false,
    ESP_LowPerformance=false,
    Fullbright=false, NoFog=false,
    SURV_AutoDropPallet=false, SURV_AutoDropPalletDist=20, SURV_AutoDropPalletMode="Aggressive",
    SURV_AutoVault=false, SURV_AutoPalletSlide=false,
}
local VD=getgenv().VD

-- Fungsi Notify lokal untuk Ziaan
local function ZNotify(title,content,duration)
    pcall(function()
        if Window and Window.Notify then
            Window:Notify({Title=title,Content=content,Duration=duration or 2,Icon="rbxassetid://84095759576517"})
        else
            print("[ZiaanHub] "..title.." - "..content)
        end
    end)
end

-- ====== ESP ZIAAN ======
local ZiaanESP={}
do
    local ESPHighlights={}
    local ESPLabels={}
    local espRoot=nil
    local espLastScan=0
    local espDirty=true
    local espCache={Generator={},Gate={},Hook={},Pallet={},Window={},Pumpkin={},Zombie={}}
    local ESP_SCAN_INTERVAL=(isMobile and 6)or 4

    local function IsZombieName(name)name=tostring(name):lower(); return(name:find("zomb")~=nil)or(name:find("infect")~=nil)or(name:find("undead")~=nil)end
    local function ESPOn(key)if not Settings.ESP.Master then return false end if key==nil then return true end return Settings.ESP[key]==true end
    local ESP_KEYS={"Killer","Survivor","Zombie","Generator","Gate","Hook","Pallet","Window","Pumpkin"}
    local function ESPAnyEnabled()for _,k in ipairs(ESP_KEYS)do if Settings.ESP[k]then return true end end return false end

    local function HighlightObj(obj,color)
        if not obj or not obj.Parent then return end
        local existing=obj:FindFirstChild("ZiaanESP_HL")
        if existing then
            if existing:IsA("Highlight")then
                existing.FillColor=color; existing.OutlineColor=color;
                existing.FillTransparency=1; existing.OutlineTransparency=0;
                existing.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            end
            ESPHighlights[obj]=existing; return
        end
        local hl=Instance.new("Highlight")
        hl.Name="ZiaanESP_HL"
        hl.Adornee=obj
        hl.FillColor=color
        hl.OutlineColor=color
        hl.FillTransparency=1
        hl.OutlineTransparency=0
        hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent=obj
        ESPHighlights[obj]=hl
    end

    local function Unhighlight(obj)
        if ESPHighlights[obj]then if ESPHighlights[obj].Parent then ESPHighlights[obj]:Destroy()end; ESPHighlights[obj]=nil end
        local h=obj:FindFirstChild("ZiaanESP_HL") if h then h:Destroy()end
    end
    local function Unlabel(obj)
        if ESPLabels[obj]then if ESPLabels[obj].Parent then ESPLabels[obj]:Destroy()end; ESPLabels[obj]=nil end
    end
    local function ClearObj(obj)Unhighlight(obj); Unlabel(obj)end
    local function ClearESP()for obj in pairs(ESPHighlights)do Unhighlight(obj)end for obj in pairs(ESPLabels)do Unlabel(obj)end ESPHighlights={}; ESPLabels={}end

    local function LabelObj(obj,name,color)
        if not obj or not obj.Parent then return end
        local root=(espRoot and espRoot.Parent and espRoot)or GetRoot()
        if not root then return end
        local anchorPart=(obj:IsA("BasePart")and obj)or(obj:IsA("Model")and(obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))or nil
        if not anchorPart then return end
        local distance=(root.Position-anchorPart.Position).Magnitude
        if Settings.Performance.UseDistanceCulling and(distance>Settings.ESP.MaxDistance)then Unlabel(obj); return end
        local cached=ESPLabels[obj]
        if cached and cached.Parent then
            local existing=cached:FindFirstChildWhichIsA("TextLabel")
            if existing then
                existing.Text=(Settings.ESP.ShowDistance and string.format("%s\n%.0fm",name,distance))or name
                if existing.TextColor3~=color then existing.TextColor3=color end
            end
            return
        end
        local billboard=Instance.new("BillboardGui")
        billboard.Name="ZiaanESP_Label"
        billboard.Size=UDim2.new(0,200,0,50)
        billboard.AlwaysOnTop=true
        billboard.StudsOffset=Vector3.new(0,3,0)
        billboard.Adornee=anchorPart
        billboard.Parent=obj
        local label=Instance.new("TextLabel")
        label.Size=UDim2.new(1,0,1,0)
        label.BackgroundTransparency=1
        label.TextColor3=color
        label.TextStrokeColor3=Color3.new(0,0,0)
        label.TextStrokeTransparency=0
        label.Font=Enum.Font.GothamBold
        label.TextScaled=true
        label.Text=(Settings.ESP.ShowDistance and string.format("%s\n%.0fm",name,distance))or name
        label.Parent=billboard
        ESPLabels[obj]=billboard
    end

    local function ClearESPCategory(key)
        if key=="Killer"or key=="Survivor"or key=="Zombie"then for _,p in ipairs(Players:GetPlayers())do if p~=LocalPlayer and p.Character then ClearObj(p.Character)end end end
        local list=espCache[key] if list then for _,obj in ipairs(list)do ClearObj(obj) if obj:IsA("Model")then for _,part in ipairs(obj:GetDescendants())do if ESPHighlights[part]then Unhighlight(part)end end end end end
    end

    local function ScanWorld()
        espLastScan=tick(); espDirty=false
        for k in pairs(espCache)do espCache[k]={}end
        local needWorld=ESPOn("Generator")or ESPOn("Gate")or ESPOn("Hook")or ESPOn("Pallet")or ESPOn("Window")or ESPOn("Pumpkin")or ESPOn("Zombie")
        if not needWorld then return end
        local map=Workspace:FindFirstChild("Map")
        local scanRoot=map or Workspace
        for _,obj in ipairs(scanRoot:GetDescendants())do
            if obj:IsA("Model")then
                local n=obj.Name
                if n=="Generator"then table.insert(espCache.Generator,obj)
                elseif n=="Gate"then table.insert(espCache.Gate,obj)
                elseif n=="Hook"then table.insert(espCache.Hook,obj)
                elseif n=="Palletwrong"or n=="Pallet"then table.insert(espCache.Pallet,obj)
                elseif n=="Window"then table.insert(espCache.Window,obj)
                elseif n:lower():find("pumpkin")then table.insert(espCache.Pumpkin,obj)
                elseif IsZombieName(n)and obj:FindFirstChildOfClass("Humanoid")and not Players:GetPlayerFromCharacter(obj)then table.insert(espCache.Zombie,obj)
                end
            end
        end
        if ESPOn("Pumpkin")then
            local folders={}
            local mapFolder=Workspace:FindFirstChild("Map") if mapFolder then local f=mapFolder:FindFirstChild("Pumpkins") if f then table.insert(folders,f)end end
            local rootFolder=Workspace:FindFirstChild("Pumpkins") if rootFolder then table.insert(folders,rootFolder)end
            for _,folder in ipairs(folders)do
                for _,obj in ipairs(folder:GetDescendants())do
                    if obj:IsA("Model")and obj.Name:lower():find("pumpkin")then table.insert(espCache.Pumpkin,obj)
                    elseif obj:IsA("BasePart")and obj.Name:lower():find("pumpkin")and not(obj.Parent and obj.Parent:IsA("Model")and obj.Parent.Name:lower():find("pumpkin"))then table.insert(espCache.Pumpkin,obj)
                    end
                end
            end
        end
    end

    local function ESPPlayers()
        for _,player in ipairs(Players:GetPlayers())do
            if player~=LocalPlayer then
                local char=player.Character
                if char then
                    local teamName=(player.Team and player.Team.Name)or""
                    local kind=nil
                    if IsZombieName(teamName)or(char and IsZombieName(char.Name))then kind="Zombie"
                    elseif teamName:lower():find("killer")then kind="Killer"
                    elseif teamName:lower():find("surviv")then kind="Survivor" end
                    if kind and ESPOn(kind)then
                        local color=Settings.ESP.Colors[kind]
                        HighlightObj(char,color)
                        LabelObj(char,player.Name.."\n["..kind:upper().."]",color)
                    else ClearObj(char) end
                end
            end
        end
    end

    local function ESPZombies()
        if not ESPOn("Zombie")then return end
        local color=Settings.ESP.Colors.Zombie
        for _,obj in ipairs(espCache.Zombie)do
            if obj and obj.Parent then
                local hum=obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then HighlightObj(obj,color); LabelObj(obj,"ZOMBIE",color) else ClearObj(obj)end
            end
        end
    end

    local function ESPSimple(key,labelText)
        if not ESPOn(key)then return end
        local color=Settings.ESP.Colors[key]
        local showName=(labelText~=nil)
        for _,obj in ipairs(espCache[key])do
            if obj and obj.Parent then
                HighlightObj(obj,color)
                if showName then LabelObj(obj,labelText,color)else Unlabel(obj)end
            end
        end
    end

    local function ESPHooks()
        if not ESPOn("Hook")then return end
        local color=Settings.ESP.Colors.Hook
        local list=espCache.Hook
        if Settings.ESP.ShowOnlyClosestHook then
            local root=GetRoot() if not root then return end
            local nearest,nearestDist=nil,math.huge
            for _,obj in ipairs(list)do
                local part=obj and obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local d=(part.Position-root.Position).Magnitude
                    if d<nearestDist then nearestDist=d; nearest=obj end
                end
            end
            for _,obj in ipairs(list)do if obj~=nearest then ClearObj(obj)end end
            if nearest then HighlightObj(nearest,color); Unlabel(nearest)end
        else
            for _,obj in ipairs(list)do if obj and obj.Parent then HighlightObj(obj,color); Unlabel(obj)end end
        end
    end

    local lastUpdate=0
    function ZiaanESP.ESPTick()
        if not Settings.ESP.Master then return end
        local now=tick()
        if(now-lastUpdate)<Settings.Performance.UpdateRate then return end
        lastUpdate=now
        espRoot=GetRoot()
        if espDirty or(now-espLastScan)>=ESP_SCAN_INTERVAL then ScanWorld()end
        ESPPlayers()
        ESPZombies()
        ESPSimple("Generator","GENERATOR")
        ESPSimple("Gate",nil)
        ESPHooks()
        ESPSimple("Pallet",nil)
        ESPSimple("Window",nil)
        ESPSimple("Pumpkin",nil)
    end

    local espLoopConn=nil
    function ZiaanESP.Enable()if espLoopConn then return end espDirty=true espLoopConn=RunService.Heartbeat:Connect(ZiaanESP.ESPTick)end
    function ZiaanESP.Disable()if espLoopConn then espLoopConn:Disconnect(); espLoopConn=nil end ClearESP()end
    function ZiaanESP.Refresh()if Settings.ESP.Master and ESPAnyEnabled()then espDirty=true; ZiaanESP.Enable()else ZiaanESP.Disable()end end
    function ZiaanESP.ClearCategory(key)ClearESPCategory(key)end
end

-- ===== AUTO GENERATOR (3 mode) =====
local function AutoGeneratorGreat()
    local repairEvent=RemoteCache.Get("Generator","RepairEvent")
    local skillCheckEvent=RemoteCache.Get("Generator","SkillCheckResultEvent")
    if not repairEvent or not skillCheckEvent then return end
    for _,obj in ipairs(MapCache.Models("Generator"))do
        for _,child in ipairs(MapCache.GeneratorPoints(obj))do
            pcall(function()repairEvent:FireServer(child,true); skillCheckEvent:FireServer("success",1,obj,child)end)
        end
    end
end
local function AutoGeneratorNormal()
    local repairEvent=RemoteCache.Get("Generator","RepairEvent")
    local skillCheckEvent=RemoteCache.Get("Generator","SkillCheckResultEvent")
    if not repairEvent or not skillCheckEvent then return end
    for _,obj in ipairs(MapCache.Models("Generator"))do
        for _,child in ipairs(MapCache.GeneratorPoints(obj))do
            pcall(function()repairEvent:FireServer(child,true); skillCheckEvent:FireServer("normal",0,obj,child)end)
        end
    end
end

-- Gen Boost Ziaan (dengan tombol bypass)
local GenBoostZiaan={}
do
    local bypassButton,bypassButtonGui,bypassButtonCheck,bypassGuardianActive=nil,nil,nil,false
    local bypassDragConns={}
    local DragConfigPath=".ZiaanGenBoost.json"
    local function loadBypassButtonPosition()local pos=nil pcall(function()if isfile and readfile and isfile(DragConfigPath)then local raw=readfile(DragConfigPath) local data=game:GetService("HttpService"):JSONDecode(raw) if data and data.XScale~=nil then pos=UDim2.new(data.XScale,data.XOffset or 0,data.YScale,data.YOffset or 0)end end end) return pos end
    local function saveBypassButtonPosition(udim2Pos)pcall(function()if writefile then writefile(DragConfigPath,game:GetService("HttpService"):JSONEncode({XScale=udim2Pos.X.Scale,XOffset=udim2Pos.X.Offset,YScale=udim2Pos.Y.Scale,YOffset=udim2Pos.Y.Offset}))end end)end
    local function disconnectDragConns()for _,c in ipairs(bypassDragConns)do pcall(function()c:Disconnect()end)end; bypassDragConns={}end
    local function makeButtonDraggable(button)
        disconnectDragConns()
        local dragging,dragStart,startPos=false
        local function update(input)local delta=input.Position-dragStart button.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)end
        table.insert(bypassDragConns,button.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; startPos=button.Position local conn=input.Changed:Connect(function()if input.UserInputState==Enum.UserInputState.End then if dragging then saveBypassButtonPosition(button.Position)end dragging=false if conn then conn:Disconnect()end end end)end end))
        table.insert(bypassDragConns,button.InputChanged:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragStart=dragStart or input.Position end end))
        table.insert(bypassDragConns,UserInputService.InputChanged:Connect(function(input)if dragging and input==dragStart then update(input)end end))
    end
    local function createBypassButton()
        if bypassButton and bypassButton.Parent then return end
        local guiParent=(gethui and gethui())or game:GetService("CoreGui") if not guiParent then return end
        if bypassButtonGui then bypassButtonGui:Destroy()end
        bypassButtonGui=Instance.new("ScreenGui") bypassButtonGui.Name="ZiaanGenBoostGui" bypassButtonGui.ResetOnSpawn=false bypassButtonGui.IgnoreGuiInset=true bypassButtonGui.DisplayOrder=999 bypassButtonGui.Parent=guiParent
        bypassButton=Instance.new("ImageButton") bypassButton.Size=UDim2.new(0,101,0,101) bypassButton.AnchorPoint=Vector2.new(1,0) local savedPos=loadBypassButtonPosition() bypassButton.Position=savedPos or UDim2.new(1,-99,0,335) bypassButton.BackgroundTransparency=1 bypassButton.Image="rbxassetid://73955247819019" bypassButton.ScaleType=Enum.ScaleType.Fit bypassButton.BorderSizePixel=0 bypassButton.AutoButtonColor=false bypassButton.Active=true bypassButton.Parent=bypassButtonGui
        Instance.new("UICorner",bypassButton).CornerRadius=UDim.new(0.5,0)
        makeButtonDraggable(bypassButton)
        local function updateButtonColor()if not bypassButton then return end local char=LocalPlayer.Character if not char then bypassButton.ImageColor3=Color3.new(1,1,1) return end local ci=char:FindFirstChild("CheckInterractable") if not ci then bypassButton.ImageColor3=Color3.new(1,1,1) return end local repairing=ci:GetAttribute("isRepairing")or ci:GetAttribute("IsRepairing") bypassButton.ImageColor3=repairing and Color3.fromRGB(255,140,0)or Color3.new(1,1,1)end
        local function bindCheck(character)if not character then return end local ci=character:WaitForChild("CheckInterractable") if ci then if bypassButtonCheck then bypassButtonCheck:Disconnect()end bypassButtonCheck=ci:GetAttributeChangedSignal("isRepairing"):Connect(updateButtonColor) ci:GetAttributeChangedSignal("IsRepairing"):Connect(updateButtonColor) updateButtonColor()end end
        if LocalPlayer.Character then bindCheck(LocalPlayer.Character)end
        LocalPlayer.CharacterAdded:Connect(bindCheck)
        bypassButton.MouseButton1Click:Connect(function()
            local char=LocalPlayer.Character if not char then return end
            local ci=char:FindFirstChild("CheckInterractable") if not ci then return end
            local repairing=ci:GetAttribute("isRepairing")or ci:GetAttribute("IsRepairing") if not repairing then return end
            local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
            local genCache,lastCacheTime={},0
            local function getGenerators()if tick()-lastCacheTime<5 then return genCache end genCache,lastCacheTime={},tick() local folder=Workspace:FindFirstChild("Map")or Workspace for _,v in pairs(folder:GetDescendants())do if v:IsA("Model")and v.Name=="Generator"then local real=v:GetAttribute("RepairProgress")~=nil or v:GetAttribute("kickcount")~=nil or v:GetAttribute("ProgressRepair")~=nil if real then table.insert(genCache,v)end end end return genCache end
            local function getPoints(genModel)local pts={} for _,obj in pairs(genModel:GetChildren())do if obj.Name:find("GeneratorPoint")and obj:IsA("BasePart")then table.insert(pts,obj)end end return pts end
            local function waitRepairing(point,timeout)local start=tick() while tick()-start<timeout do if point:GetAttribute("IsRepairing")==true then return true end task.wait(0.05)end return false end
            local RepairEvent=RemoteCache.Get("Generator","RepairEvent") if not RepairEvent then return end
            local bestPoint,bestDist=nil,math.huge local bestGen=nil
            for _,gen in pairs(getGenerators())do for _,pt in pairs(getPoints(gen))do local d=(hrp.Position-pt.Position).Magnitude if d<bestDist then bestDist=d; bestPoint=pt; bestGen=gen end end end
            if bestPoint and bestGen then
                local allPoints=getPoints(bestGen)
                local targetPoints={} for _,p in ipairs(allPoints)do if p~=bestPoint then table.insert(targetPoints,p)end end
                if #targetPoints==0 then return end
                local startCFrame=hrp.CFrame
                for i,point in ipairs(targetPoints)do if not point.Parent then continue end hrp.Anchored=true hrp.CFrame=point.CFrame task.wait(0.15) RepairEvent:FireServer(point,true) local ok=waitRepairing(point,0.8) if not ok then RepairEvent:FireServer(point,false) task.wait(0.1) hrp.CFrame=point.CFrame task.wait(0.15) RepairEvent:FireServer(point,true) end hrp.Anchored=false task.wait(0.05)end
                pcall(function()hrp.Anchored=false; hrp.CFrame=startCFrame end)
                local lastPoint=targetPoints[#targetPoints] if lastPoint then RepairEvent:FireServer(lastPoint,false)end
            end
        end)
    end
    local function destroyBypassButton()bypassGuardianActive=false disconnectDragConns() if bypassButtonGui then bypassButtonGui:Destroy(); bypassButtonGui=nil end bypassButton=nil if bypassButtonCheck then bypassButtonCheck:Disconnect(); bypassButtonCheck=nil end end
    local function startBypassButtonGuardian()if bypassGuardianActive then return end bypassGuardianActive=true task.spawn(function()while bypassGuardianActive and VD.SURV_GenBoost and not VD.Destroyed do if not(bypassButtonGui and bypassButtonGui.Parent)then pcall(createBypassButton)end task.wait(1)end end)end
    function GenBoostZiaan.Enable()createBypassButton(); startBypassButtonGuardian()end
    function GenBoostZiaan.Disable()destroyBypassButton()end
end

-- ===== FITUR ZIAAN LAINNYA (Killer/Survivor) =====
local ZiaanFeatures={}

-- Auto Attack & Double Tap
do local LastDoubleTapTime=0
function ZiaanFeatures.AutoAttack()if not Settings.AutoFeatures.AutoAttack or not IsKiller()then return end local root=GetRoot() if not root then return end for _,player in ipairs(Players:GetPlayers())do if player~=LocalPlayer and player.Team and player.Team.Name=="Survivors"and player.Character then local tRoot=player.Character:FindFirstChild("HumanoidRootPart") local tHum=player.Character:FindFirstChildOfClass("Humanoid") if tRoot and tHum and tHum.Health>0 and tHum.MaxHealth>0 then local pct=tHum.Health/tHum.MaxHealth if pct>0.25 and(tRoot.Position-root.Position).Magnitude<=Settings.AutoFeatures.AttackRange then local basicAttack=RemoteCache.Get("Attacks","BasicAttack") if basicAttack then pcall(function()basicAttack:FireServer(false)end)end break end end end end end
function ZiaanFeatures.DoubleTap()if not VD.KILLER_DoubleTap or not IsKiller()then return end if tick()-LastDoubleTapTime<0.5 then return end local basicAttack=RemoteCache.Get("Attacks","BasicAttack") if basicAttack then pcall(function()basicAttack:FireServer(false)end) task.wait(0.05) pcall(function()basicAttack:FireServer(false)end) LastDoubleTapTime=tick()end end
end

-- Destroy Pallets, Auto Kick Gen, Block Vaults
do local IsBreakingPallet=false
function ZiaanFeatures.DestroyPallets()if not VD.KILLER_DestroyPallets or not IsKiller()or IsBreakingPallet then return end local char=LocalPlayer.Character local root=GetRoot() if not char or not root then return end local stunned=char:GetAttribute("IsStunned")or char:GetAttribute("isStunned") local immobile=char:GetAttribute("Immobile")or char:GetAttribute("immobile") local carrying=char:GetAttribute("IsCarrying")or char:GetAttribute("isCarrying") local pursuit=char:GetAttribute("Pursuit")or char:GetAttribute("pursuit") local ci=char:FindFirstChild("CheckInterractable") local action=ci and(ci:GetAttribute("action")or ci:GetAttribute("Action")) if stunned or immobile or carrying or pursuit or action then return end local CollectionService=game:GetService("CollectionService") local pts=CollectionService:GetTagged("PalletPointSlide") local nearest,minDist=nil,6 for _,p in ipairs(pts)do if p:IsA("BasePart")and not CollectionService:HasTag(p,"doing action")then local d=(p.Position-root.Position).Magnitude if d<minDist then minDist=d; nearest=p end end end if nearest then IsBreakingPallet=true task.spawn(function()pcall(function()local r=RemoteCache.Get("Pallet","Jason") if r then local dg=r:FindFirstChild("Destroy-Global") local commit=r:FindFirstChild("PalletBreakCommit") if dg and dg:IsA("RemoteEvent")then dg:FireServer(nearest)end if commit and commit:IsA("RemoteEvent")then commit:FireServer(nearest)end end end) task.wait(0.2) local startTime=os.clock() while char and char.Parent and(char:GetAttribute("Immobile")or char:GetAttribute("immobile"))do if os.clock()-startTime>3 then break end task.wait(0.1)end IsBreakingPallet=false end)end end
getgenv().IYAN_IsBreakingGenerator=false
function ZiaanFeatures.AutoBreakGene()if not VD.KILLER_AutoBreakGene or not IsKiller()then return end if getgenv().IYAN_IsBreakingGenerator then return end local char=LocalPlayer.Character local root=GetRoot() if not char or not root then return end local stunned=char:GetAttribute("IsStunned")or char:GetAttribute("isStunned") local immobile=char:GetAttribute("Immobile")or char:GetAttribute("immobile") local carrying=char:GetAttribute("IsCarrying")or char:GetAttribute("isCarrying") local pursuit=char:GetAttribute("Pursuit")or char:GetAttribute("pursuit") local ci=char:FindFirstChild("CheckInterractable") local action=ci and(ci:GetAttribute("action")or ci:GetAttribute("Action")) if stunned or immobile or carrying or pursuit or action then return end local CollectionService=game:GetService("CollectionService") local pts=CollectionService:GetTagged("GeneratorPoint") local nearest,minDist=nil,6 for _,p in ipairs(pts)do if p:IsA("BasePart")and not CollectionService:HasTag(p,"doing action")then local genModel=p.Parent if genModel then local progress=genModel:GetAttribute("RepairProgress")or genModel:GetAttribute("repairProgress")or 0 local kickcount=genModel:GetAttribute("kickcount")or genModel:GetAttribute("KickCount")or 0 if progress>0 and progress<100 and kickcount<=7 then local d=(p.Position-root.Position).Magnitude if d<minDist then minDist=d; nearest=p end end end end end if nearest then getgenv().IYAN_IsBreakingGenerator=true task.spawn(function()pcall(function()local g=RemoteCache.Get("Generator") if g then local event=g:FindFirstChild("BreakGenEvent") local commit=g:FindFirstChild("BreakGenCommit") if event and event:IsA("RemoteEvent")then event:FireServer(nearest)end if commit and commit:IsA("RemoteEvent")then commit:FireServer(nearest)end end end) task.wait(0.2) local startTime=os.clock() while char and char.Parent and(char:GetAttribute("Immobile")or char:GetAttribute("immobile"))do if os.clock()-startTime>3 then break end task.wait(0.1)end task.wait(0.3) getgenv().IYAN_IsBreakingGenerator=false end)end end
getgenv().IYAN_LastVaultBlockTime=0
function ZiaanFeatures.BlockVaults()if not VD.KILLER_BlockVaults or not IsKiller()then return end local now=tick() if now-getgenv().IYAN_LastVaultBlockTime<1.5 then return end getgenv().IYAN_LastVaultBlockTime=now local vaultEvent=RemoteCache.Get("Window","VaultEvent") if not vaultEvent then return end local map=Workspace:FindFirstChild("Map") local vaultsFolder=map and map:FindFirstChild("Vaults") if vaultsFolder then for _,vault in ipairs(vaultsFolder:GetChildren())do for _,part in ipairs(vault:GetChildren())do if part:IsA("BasePart")then pcall(function()vaultEvent:FireServer(part,true)end)end end end else for _,win in ipairs(MapCache.Models("Window")or{})do local window=win if window and window.Parent then for _,child in ipairs(window:GetDescendants())do if child:IsA("BasePart")then pcall(function()vaultEvent:FireServer(child,true)end)end end end end end end
end

-- Anti Blind
function ZiaanFeatures.SetupAntiBlind()pcall(function()local r=ReplicatedStorage:FindFirstChild("Remotes") local i=r and r:FindFirstChild("Items") local fl=i and i:FindFirstChild("Flashlight") local gb=fl and fl:FindFirstChild("GotBlinded") if not(gb and gb:IsA("RemoteEvent"))then return end local ok,mt=pcall(function()return getrawmetatable(game)end) if ok and mt and setreadonly then pcall(function()setreadonly(mt,false) local old=mt.__namecall mt.__namecall=newcclosure(function(self,...)if not checkcaller()and VD.KILLER_AntiBlind and self==gb then local method=getnamecallmethod() if method=="FireServer"and IsKiller()then return nil end end return old(self,...)end) setreadonly(mt,true)end)end end)end

-- Custom Masked
function ZiaanFeatures.ApplyCustomMasked(maskName)local selectedMask=maskName or VD.KILLER_CustomMasked or"Richard" if type(selectedMask)=="table"then selectedMask=selectedMask[1]end if type(selectedMask)~="string"or selectedMask==""then selectedMask="Richard"end local activatePower=RemoteCache.Get("Killers","Masked","Activatepower") if activatePower and activatePower:IsA("RemoteEvent")then activatePower:FireServer(selectedMask) return true end return false end

-- Silent Aim Veil
do local VeilConfig={Enabled=false,ShowFOV=true,FOV=150,SpearSpeed=165,Gravity=Workspace.Gravity*0.5,MaxDist=200,AutoPredict=false,TargetPart="Torso",HorizontalPredictFactor=2.8}
local VeilState={chargingSpear=false,touchInput=nil,attackCooldown=false,passiveCooldown=false,remoteHooked=false,lastPredictedPos=nil}
local VeilVelocityCache={}
local VeilDraw={FOVCircle=Drawing and Drawing.new("Circle"),Highlight=Instance.new("Highlight"),Tracer=Drawing and Drawing.new("Circle")}
if VeilDraw.FOVCircle then VeilDraw.FOVCircle.Color=Color3.fromRGB(180,180,180) VeilDraw.FOVCircle.Thickness=1.5 VeilDraw.FOVCircle.Filled=false VeilDraw.FOVCircle.Visible=false end
if VeilDraw.Highlight then VeilDraw.Highlight.Name="VD_VeilTarget" VeilDraw.Highlight.FillColor=Color3.fromRGB(255,0,0) VeilDraw.Highlight.OutlineColor=Color3.fromRGB(255,255,255) VeilDraw.Highlight.FillTransparency=0.5 VeilDraw.Highlight.OutlineTransparency=0 VeilDraw.Highlight.Parent=(gethui and gethui())or game:GetService("CoreGui")end
if VeilDraw.Tracer then VeilDraw.Tracer.Thickness=2 VeilDraw.Tracer.Radius=5 VeilDraw.Tracer.Color=Color3.fromRGB(180,180,180) VeilDraw.Tracer.Filled=true VeilDraw.Tracer.Visible=false end
function Veil_GetRealVelocity(part,playerName)if not part then return Vector3.zero end local currentPos=part.Position local currentTime=tick() if not VeilVelocityCache[playerName]then VeilVelocityCache[playerName]={lastPos=currentPos,lastTime=currentTime,velocity=Vector3.zero} return Vector3.zero end local cache=VeilVelocityCache[playerName] local dt=currentTime-cache.lastTime if dt>0.01 then local rawVelocity=(currentPos-cache.lastPos)/dt if rawVelocity.Magnitude<100 then cache.velocity=cache.velocity:Lerp(rawVelocity,0.4)end end cache.lastPos=currentPos cache.lastTime=currentTime return cache.velocity end
function veil_getTargetPart(char)if VeilConfig.TargetPart=="Head"then return char:FindFirstChild("Head")elseif VeilConfig.TargetPart=="Root"then return char:FindFirstChild("HumanoidRootPart")else return char:FindFirstChild("Torso")or char:FindFirstChild("UpperTorso")or char:FindFirstChild("HumanoidRootPart")end end
function veil_getClosestSurvivor()local myChar=LocalPlayer.Character local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart") if not myRoot then return nil end local cam=Camera local center=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2) local bestDist=VeilConfig.FOV local bestTarget=nil for _,p in ipairs(Players:GetPlayers())do if p~=LocalPlayer and p.Team and p.Team.Name=="Survivors"and p.Character then local char=p.Character local hum=char:FindFirstChildOfClass("Humanoid") local part=veil_getTargetPart(char) if hum and hum.Health>0 and part then local dist3D=(part.Position-myRoot.Position).Magnitude if dist3D<=VeilConfig.MaxDist then local screenPos,onScreen=cam:WorldToViewportPoint(part.Position) if onScreen then local dist2D=(Vector2.new(screenPos.X,screenPos.Y)-center).Magnitude if dist2D<bestDist then bestDist=dist2D bestTarget={Player=p,Part=part}end end end end end end return bestTarget end
function veil_setupInterceptor()if VeilState.remoteHooked then return end task.spawn(function()pcall(function()local oldNamecall oldNamecall=hookmetamethod(game,"__namecall",function(self,...)if getnamecallmethod()=="FireServer"and not checkcaller()then if self.Name=="Spearthrow"and VeilConfig.Enabled then return nil end end return oldNamecall(self,...)end) VeilState.remoteHooked=true end)end)end
function veil_fire()if VeilState.attackCooldown then return end VeilState.attackCooldown=true task.delay(2,function()VeilState.attackCooldown=false end) local myChar=LocalPlayer.Character local startPart=myChar and(myChar:FindFirstChild("Head")or myChar:FindFirstChild("HumanoidRootPart")) if not startPart then return end local startPos=startPart.Position local targetInfo=veil_getClosestSurvivor() local aimDir if targetInfo and targetInfo.Part then local targetPart=targetInfo.Part local targetPlayer=targetInfo.Player local targetPos=targetPart.Position local velocity=Veil_GetRealVelocity(targetPart,targetPlayer.Name) local horizontalVel=Vector3.new(velocity.X,0,velocity.Z) local speed=horizontalVel.Magnitude local distance=(targetPos-startPos).Magnitude local timeToHit=distance/VeilConfig.SpearSpeed local horizontalPrediction=Vector3.zero if speed>4 then horizontalPrediction=horizontalVel.Unit*VeilConfig.HorizontalPredictFactor end local predictedPos=targetPos+horizontalPrediction local distMult=math.clamp(distance/100,1,2.5) local autoGravity=math.max(0,distance-8) local gravity=VeilConfig.AutoPredict and autoGravity or VeilConfig.Gravity local drop=0.5*gravity*(timeToHit^2)*distMult local finalPos=predictedPos+Vector3.new(0,drop,0) aimDir=(finalPos-startPos).Unit VeilState.lastPredictedPos=finalPos else aimDir=Camera.CFrame.LookVector VeilState.lastPredictedPos=nil end pcall(function()local spearthrow=RemoteCache.Get("Killers","Veil","Spearthrow") if spearthrow then spearthrow:FireServer(aimDir,VeilConfig.SpearSpeed,startPos)end end) if VeilDraw.FOVCircle then VeilDraw.FOVCircle.Color=Color3.fromRGB(180,180,180)end if not VeilState.passiveCooldown then VeilState.passiveCooldown=true task.delay(30,function()if VeilDraw.FOVCircle then VeilDraw.FOVCircle.Color=Color3.fromRGB(180,180,180)end VeilState.passiveCooldown=false end)end end
UserInputService.InputBegan:Connect(function(input,gp)local isTouch=input.UserInputType==Enum.UserInputType.Touch if gp and not isTouch then return end local char=LocalPlayer.Character local isSpearMode=char and char:GetAttribute("spearmode")==true if not VeilConfig.Enabled or not isSpearMode then return end if input.UserInputType==Enum.UserInputType.MouseButton1 then VeilState.chargingSpear=true elseif isTouch then local pGui=LocalPlayer:FindFirstChild("PlayerGui") if pGui then local slasher=pGui:FindFirstChild("Slasher-mob") if slasher then local ctrl=slasher:FindFirstChild("Controls") if ctrl then local attackBtn=ctrl:FindFirstChild("attack") if attackBtn and attackBtn.Visible then local pos=input.Position local absPos=attackBtn.AbsolutePosition local absSize=attackBtn.AbsoluteSize if pos.X>=absPos.X and pos.X<=absPos.X+absSize.X and pos.Y>=absPos.Y and pos.Y<=absPos.Y+absSize.Y then VeilState.chargingSpear=true VeilState.touchInput=input end end end end end end end)
UserInputService.InputEnded:Connect(function(input,gp)if VeilState.chargingSpear and(input==VeilState.touchInput or input.UserInputType==Enum.UserInputType.MouseButton1)then VeilState.chargingSpear=false if VeilState.touchInput==input then VeilState.touchInput=nil end veil_fire()end end)
RunService.RenderStepped:Connect(function()local cam=Camera local myChar=LocalPlayer.Character local isSpearMode=myChar and myChar:GetAttribute("spearmode")==true if VeilConfig.Enabled and VeilConfig.ShowFOV and isSpearMode and VeilDraw.FOVCircle then VeilDraw.FOVCircle.Visible=true VeilDraw.FOVCircle.Radius=VeilConfig.FOV VeilDraw.FOVCircle.Position=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)elseif VeilDraw.FOVCircle then VeilDraw.FOVCircle.Visible=false end if VeilState.chargingSpear and VeilConfig.Enabled and isSpearMode then local target=veil_getClosestSurvivor() if target and target.Part and target.Part.Parent then VeilDraw.Highlight.Parent=target.Part.Parent else VeilDraw.Highlight.Parent=nil end else VeilDraw.Highlight.Parent=nil end if VeilConfig.Enabled and isSpearMode and VeilState.lastPredictedPos and VeilDraw.Tracer then local screenPos,onScreen=cam:WorldToViewportPoint(VeilState.lastPredictedPos) local viewport=cam.ViewportSize local center=Vector2.new(viewport.X/2,viewport.Y/2) if onScreen then VeilDraw.Tracer.Position=Vector2.new(screenPos.X,screenPos.Y) else local dx=screenPos.X-center.X local dy=screenPos.Y-center.Y if math.abs(dx)<1 and math.abs(dy)<1 then VeilDraw.Tracer.Position=center else local angle=math.atan2(dy,dx) local maxX=viewport.X/2-10 local maxY=viewport.Y/2-10 local scaleX=maxX/math.abs(dx) local scaleY=maxY/math.abs(dy) local scale=math.min(scaleX,scaleY) VeilDraw.Tracer.Position=Vector2.new(center.X+dx*scale,center.Y+dy*scale)end end VeilDraw.Tracer.Visible=true elseif VeilDraw.Tracer then VeilDraw.Tracer.Visible=false end end)
function ZiaanFeatures.SetVeilConfig(cfg)for k,v in pairs(cfg)do VeilConfig[k]=v end if VeilConfig.Enabled then veil_setupInterceptor()end end
end

-- Survivor features (Flee Killer, Anti Knock, First Person, Auto Parry, Auto Drop Pallet, Auto Vault, Auto Pallet Slide)
do
    -- Flee Killer
    RunService.Heartbeat:Connect(function()
        if VD.SURV_FleeKiller and IsSurvivor()then
            local root=GetRoot() if not root then return end
            for _,player in ipairs(Players:GetPlayers())do
                if player~=LocalPlayer and player.Team and player.Team.Name=="Killer"then
                    local killerRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if killerRoot and(killerRoot.Position-root.Position).Magnitude<=(VD.SURV_FleeDistance or 40)then
                        local direction=(root.Position-killerRoot.Position).Unit
                        root.CFrame=CFrame.new(root.Position+direction*((VD.SURV_FleeDistance or 40)+15),root.Position+direction*100)
                        break
                    end
                end
            end
        end
    end)

    -- Anti Knock
    local antiKnockConn=nil
    function ZiaanFeatures.ToggleAntiKnock(state)
        VD.SURV_AntiKnock=state
        if state then
            if antiKnockConn then antiKnockConn:Disconnect(); antiKnockConn=nil end
            local char=LocalPlayer.Character
            if char then local hum=char:FindFirstChildOfClass("Humanoid") if hum then antiKnockConn=hum.HealthChanged:Connect(function()hum.Health=100 end)end end
        else
            if antiKnockConn then antiKnockConn:Disconnect(); antiKnockConn=nil end
        end
    end

    -- First Person
    local _fpWasSet,_fpOriginal=false,nil
    function ZiaanFeatures.ToggleFirstPerson(state)
        VD.SURV_FirstPerson=state
        if not state then
            if _fpWasSet then _fpWasSet=false pcall(function()if _fpOriginal then LocalPlayer.CameraMode=_fpOriginal.CameraMode or Enum.CameraMode.Classic LocalPlayer.CameraMaxZoomDistance=_fpOriginal.CameraMaxZoomDistance or 128 LocalPlayer.CameraMinZoomDistance=_fpOriginal.CameraMinZoomDistance or 0.5 else LocalPlayer.CameraMode=Enum.CameraMode.Classic LocalPlayer.CameraMaxZoomDistance=128 end end) local char=LocalPlayer.Character if char then local head=char:FindFirstChild("Head") if head then head.LocalTransparencyModifier=0 end for _,obj in ipairs(char:GetChildren())do if obj:IsA("Accessory")then local handle=obj:FindFirstChild("Handle") if handle then handle.LocalTransparencyModifier=0 end end end end _fpOriginal=nil end end
    end
    RunService.RenderStepped:Connect(function()
        if VD.SURV_FirstPerson and IsSurvivor()then
            if not _fpWasSet then _fpOriginal={CameraMode=LocalPlayer.CameraMode,CameraMaxZoomDistance=LocalPlayer.CameraMaxZoomDistance,CameraMinZoomDistance=LocalPlayer.CameraMinZoomDistance}end
            if LocalPlayer.CameraMode~=Enum.CameraMode.LockFirstPerson then LocalPlayer.CameraMode=Enum.CameraMode.LockFirstPerson end
            if LocalPlayer.CameraMaxZoomDistance~=0 then LocalPlayer.CameraMaxZoomDistance=0 end
            local char=LocalPlayer.Character if char then local head=char:FindFirstChild("Head") if head then head.LocalTransparencyModifier=1 end for _,obj in ipairs(char:GetChildren())do if obj:IsA("Accessory")then local handle=obj:FindFirstChild("Handle") if handle then handle.LocalTransparencyModifier=1 end end end end
            _fpWasSet=true
        elseif _fpWasSet then ZiaanFeatures.ToggleFirstPerson(false)end
    end)

    -- Auto Parry (dengan ring)
    local ParryConfig={Enabled=false,Radius=13,SafeDistance=30,Transparency=0.2,Segments=80}
    local ParrySystem={CooldownToken=0,IsOnCooldown=false,IsResolving=false,Gradients={},Icon=nil,CooldownThread=nil,LockConnection=nil,ParryTrack=nil}
    local ParryRingFolder,ParryRingBalls=nil,{}
    local ATTACK_IDS={["118907603246885"]=true,["78432063483146"]=true,["110355011987939"]=true,["139369275981139"]=true,["117042998468241"]=true,["133963973694098"]=true,["129784271201071"]=true,["132817836308238"]=true,["135002183282873"]=true,["121216847022485"]=true,["113255068724446"]=true,["74968262036854"]=true,["105374834496520"]=true,["111920872708571"]=true,["122812055447896"]=true,["78935059863801"]=true,["80411309783148"]=true,["82666958112273"]=true}
    local function destroyRing()if ParryRingFolder then ParryRingFolder:Destroy(); ParryRingFolder=nil end ParryRingBalls={}end
    local function makeRing()destroyRing() ParryRingFolder=Instance.new("Folder") ParryRingFolder.Name="ParryRing" ParryRingFolder.Parent=Workspace local circumference=2*math.pi*ParryConfig.Radius local ballDiameter=circumference/ParryConfig.Segments for i=1,ParryConfig.Segments do local angle=(i/ParryConfig.Segments)*math.pi*2 local ball=Instance.new("Part") ball.Name="RingBall" ball.Parent=ParryRingFolder ball.Size=Vector3.new(ballDiameter,0.2,ballDiameter) ball.Shape=Enum.PartType.Ball ball.Anchored=true ball.CanCollide=false ball.CanQuery=false ball.CastShadow=false ball.Material=Enum.Material.Neon ball.Color=Color3.fromRGB(0,255,100) ball.Transparency=ParryConfig.Transparency ParryRingBalls[i]={part=ball,angle=angle}end end
    local function updateRingColor()if #ParryRingBalls==0 then return end local color,transp if not ParryConfig.Enabled then color=Color3.fromRGB(0,255,100); transp=1 elseif ParrySystem.IsOnCooldown then color=Color3.fromRGB(255,30,30); transp=math.max(0.05,ParryConfig.Transparency-0.1) else color=Color3.fromRGB(0,255,100); transp=ParryConfig.Transparency end for _,b in pairs(ParryRingBalls)do if b.part and b.part.Parent then b.part.Color=color; b.part.Transparency=transp end end end
    local function updateRingPositions()if #ParryRingBalls==0 then return end if not LocalPlayer.Character then return end local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end local centerPos=hrp.Position+Vector3.new(0,-2.9,0) for _,b in pairs(ParryRingBalls)do if b.part and b.part.Parent then local x=math.cos(b.angle)*ParryConfig.Radius local z=math.sin(b.angle)*ParryConfig.Radius b.part.CFrame=CFrame.new(centerPos+Vector3.new(x,0,z))end end end
    local function getParryButton()local pGui=LocalPlayer:FindFirstChild("PlayerGui") if not pGui then return nil end local sm=pGui:FindFirstChild("Survivor-mob") if not sm then return nil end local ctrl=sm:FindFirstChild("Controls") if not ctrl then return nil end local btn=ctrl:FindFirstChild("action")or ctrl:FindFirstChild("Gui-mob") if btn and btn.Visible then return btn end return nil end
    local function tapButton(btn)if not btn then return end pcall(function()btn.Active=true end) local x=btn.AbsolutePosition.X+(btn.AbsoluteSize.X/2) local y=btn.AbsolutePosition.Y+(btn.AbsoluteSize.Y/2) pcall(function()firetouchinterest(btn,nil,0)end) pcall(function()for _,c in pairs(getconnections(btn.MouseButton1Click))do c:Fire()end end) pcall(function()for _,c in pairs(getconnections(btn.Activated))do c:Fire()end end) pcall(function()VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)end) pcall(function()VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)end) pcall(function()firetouchinterest(btn,nil,1)end)end
    local animatorCache=setmetatable({},{__mode="k"})
    local function isAttacking(hum)if not hum then return false end local animator=animatorCache[hum] if not(animator and animator.Parent)then animator=hum:FindFirstChildOfClass("Animator") animatorCache[hum]=animator end if not animator then return false end for _,track in ipairs(animator:GetPlayingAnimationTracks())do if track and track.Animation then local id=tostring(track.Animation.AnimationId):match("%d+") if id and ATTACK_IDS[id]then return true end end end return false end
    local function scanEnemies()if not LocalPlayer.Character then return nil,nil,false end local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if not hrp then return nil,nil,false end local myPos=hrp.Position local best,bestDist,attacking=nil,9999,false for _,v in ipairs(Players:GetPlayers())do if v~=LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart")then local dist=(myPos-v.Character.HumanoidRootPart.Position).Magnitude if dist<bestDist then bestDist=dist; best=v end if dist<=ParryConfig.Radius then local hum=v.Character:FindFirstChildOfClass("Humanoid") if isAttacking(hum)then attacking=true end end end end return best,bestDist,attacking end
    function ZiaanFeatures.StartParryLoop()PerfMgr.Add("parryLoop",0.05,function()if not ParryConfig.Enabled or not IsSurvivor()then return end updateRingPositions() if ParrySystem.IsOnCooldown then return end local _,_,attacking=scanEnemies() if attacking then local btn=getParryButton() if btn then tapButton(btn) ParrySystem.IsOnCooldown=true ParrySystem.CooldownThread=task.delay(3,function()ParrySystem.IsOnCooldown=false updateRingColor()end) updateRingColor()end end end,false)end

    -- Auto Drop Pallet
    local _usedPallets={}
    local _lastPalletDrop=0
    function ZiaanFeatures.AutoDropPallet()
        if not VD.SURV_AutoDropPallet or not IsSurvivor()then return end
        if tick()-_lastPalletDrop<2.5 then return end
        local char=LocalPlayer.Character
        local myRoot=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not hum or hum.Health<=0 then return end
        if VD.SURV_AutoDropPalletMode=="Safe"then
            local isCarried=char:GetAttribute("IsCarried")or char:GetAttribute("isCarried")
            if isCarried then return end
        end
        local killerRoot=nil
        local triggerDist=VD.SURV_AutoDropPalletDist or 20
        for _,plr in ipairs(Players:GetPlayers())do
            if plr~=LocalPlayer and plr.Team and plr.Team.Name=="Killer"and plr.Character then
                local kr=plr.Character:FindFirstChild("HumanoidRootPart")
                if kr then
                    local dist=(kr.Position-myRoot.Position).Magnitude
                    if dist<triggerDist then killerRoot=kr; break end
                end
            end
        end
        if not killerRoot then return end
        local dropEvent=RemoteCache.Get("Pallet","PalletDropEvent") if not dropEvent then return end
        local bestPallet,bestDist=nil,8
        for _,pal in ipairs(MapCache.Models("Palletwrong")or{})do
            local palModel=pal if not palModel then continue end
            if _usedPallets[palModel]then continue end
            local refPart=palModel:FindFirstChild("PalletPoint")or palModel:FindFirstChild("PalletPointSlide")or MapCache.Anchor(palModel)
            if not refPart then continue end
            local d=(myRoot.Position-refPart.Position).Magnitude
            if d<bestDist then bestDist=d; bestPallet=palModel end
        end
        if bestPallet then
            local fireTarget=bestPallet:FindFirstChild("PalletPointSlide")or bestPallet:FindFirstChild("PalletPoint")
            if fireTarget then
                pcall(function()dropEvent:FireServer(fireTarget)end)
                _usedPallets[bestPallet]=true
                _lastPalletDrop=tick()
                task.delay(3,function()_usedPallets[bestPallet]=nil end)
            end
        end
    end

    -- Auto Vault & Auto Pallet Slide
    local _vaultedWindows={}
    local _lastVaultScan=0
    local _lastPalletSlideScan=0
    local _slidedPallets={}
    function ZiaanFeatures.AutoVault()
        if not VD.SURV_AutoVault or not IsSurvivor()then return end
        if tick()-_lastVaultScan<0.15 then return end
        _lastVaultScan=tick()
        local char=LocalPlayer.Character
        local myRoot=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not hum or hum.Health<=0 then return end
        local vel=myRoot.AssemblyLinearVelocity
        if vel.Magnitude<1 then return end
        local vaultEv=RemoteCache.Get("Window","VaultCommit") if not vaultEv then return end
        local windowGroups={}
        for _,win in ipairs(MapCache.Models("Window")or{})do
            local part=MapCache.Anchor(win) if part then
                local rootWindow=win
                if part.Name=="VaultPoint"and part.Parent and part.Parent.Name=="VaultTrigger"then rootWindow=part.Parent.Parent
                elseif part.Name=="VaultTrigger"and part.Parent then rootWindow=part.Parent end
                if rootWindow then
                    windowGroups[rootWindow]=windowGroups[rootWindow]or{}
                    local exists=false for _,p in ipairs(windowGroups[rootWindow])do if p==part then exists=true; break end end
                    if not exists then table.insert(windowGroups[rootWindow],part)end
                end
            end
        end
        for rootWindow,parts in pairs(windowGroups)do
            local function getVTPosition(vt)if vt:IsA("BasePart")then return vt.Position end if vt:IsA("Model")then if vt.PrimaryPart then return vt.PrimaryPart.Position end local bp=vt:FindFirstChildWhichIsA("BasePart",true) if bp then return bp.Position end end return nil end
            local allVTs={} for _,child in ipairs(rootWindow:GetChildren())do if child.Name=="VaultTrigger"then table.insert(allVTs,child)end end
            if #allVTs==0 then continue end
            local nearestVT,nearestVTDist=nil,math.huge
            for _,vt in ipairs(allVTs)do local pos=getVTPosition(vt) if pos then local d=(myRoot.Position-pos).Magnitude if d<nearestVTDist then nearestVTDist=d; nearestVT=vt end end end
            if not nearestVT or nearestVTDist>6.0 then continue end
            local lastUsed=_vaultedWindows[rootWindow]or 0 if tick()-lastUsed<3.0 then continue end
            local finalTarget=nearestVT
            local vaultEvent=RemoteCache.Get("Window","VaultEvent")
            local vaultBindable=RemoteCache.Get("Window","Vaultbindable")
            local fastvault=RemoteCache.Get("Window","fastvault")
            local vaultComplete1=RemoteCache.Get("Window","VaultCompleteEventpart1")
            local vaultComplete=RemoteCache.Get("Window","VaultCompleteEvent")
            if vaultEvent then pcall(function()vaultEvent:FireServer(finalTarget,true)end)end
            if vaultBindable then pcall(function()vaultBindable:Fire(finalTarget,true)end)end
            if fastvault then pcall(function()fastvault:FireServer(LocalPlayer)end)end
            if vaultComplete1 then pcall(function()vaultComplete1:FireServer()end)end
            if vaultComplete then pcall(function()vaultComplete:FireServer(finalTarget,false)end)end
            _vaultedWindows[rootWindow]=tick()
            break
        end
    end
    function ZiaanFeatures.AutoPalletSlide()
        if not VD.SURV_AutoPalletSlide or not IsSurvivor()then return end
        if tick()-_lastPalletSlideScan<0.15 then return end
        _lastPalletSlideScan=tick()
        local char=LocalPlayer.Character
        local myRoot=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not hum or hum.Health<=0 then return end
        local vel=myRoot.AssemblyLinearVelocity if vel.Magnitude<1 then return end
        local palletSlideEvent=RemoteCache.Get("Pallet","PalletSlideEvent")
        local slidebindable=RemoteCache.Get("Pallet","Slidebindable")
        if not palletSlideEvent then return end
        local CollectionService=game:GetService("CollectionService")
        local tagged=CollectionService:GetTagged("PalletPointSlide")
        local bestPart,bestDist=nil,6.0
        for _,part in ipairs(tagged)do
            if not part:IsA("BasePart")then continue end
            if part:IsDescendantOf(char)then continue end
            if _slidedPallets[part]then continue end
            local palletModel=part.Parent
            local ok,destroyed=pcall(function()return palletModel:GetAttribute("Destroyed")end)
            if ok and destroyed==true then continue end
            local d=(part.Position-myRoot.Position).Magnitude
            if d<bestDist then bestDist=d; bestPart=part end
        end
        if not bestPart then
            for _,pal in ipairs(MapCache.Models("Palletwrong")or{})do
                local palModel=pal if not palModel then continue end
                if _slidedPallets[palModel]then continue end
                local slide=palModel:FindFirstChild("PalletPointSlide")or palModel:FindFirstChild("PalletPointSlide",true)
                if not slide then continue end
                local ok2,destroyed2=pcall(function()return palModel:GetAttribute("Destroyed")end)
                if ok2 and destroyed2==true then continue end
                local d=(slide.Position-myRoot.Position).Magnitude
                if d<bestDist then bestDist=d; bestPart=slide end
            end
        end
        if bestPart then
            local isSprinting=LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Sprinting")or false
            pcall(function()palletSlideEvent:FireServer(bestPart,isSprinting)end)
            if slidebindable then pcall(function()slidebindable:Fire(bestPart,isSprinting)end)end
            _slidedPallets[bestPart]=true
            _lastPalletSlideScan=tick()+3.8
            task.delay(3.0,function()_slidedPallets[bestPart]=nil end)
        end
    end
end

-- ===== AUTO SKILLCHECK (Ziaan) =====
do
    local PlayerGui=LocalPlayer:WaitForChild("PlayerGui")
    local AutoSkill={LastGoalRotation=nil,HasClickedThisGoal=false,LastLineRotation=nil,LastTick=nil,WasActive=false,PerfectLastGoalRotation=nil,PerfectHasClickedThisGoal=false,PerfectLastLineRotation=nil,PerfectLastTick=nil,PerfectWasActive=false,InstantLastTriggerTick=0,InstantLastGoalRotation=0,InstantLastGoalInstance=nil,InstantCurrentGoalID=0,InstantHasClicked=false,InstantForcingRotation=false,InstantRotationConnection=nil}
    local function VD_PressSkill()
        if isMobile then
            local btn=PlayerGui:FindFirstChild("check",true)
            if btn and btn:IsA("GuiObject")then
                local pos=btn.AbsolutePosition; local size=btn.AbsoluteSize; local inset=game:GetService("GuiService"):GetGuiInset()
                local x=pos.X+(size.X/2)+inset.X; local y=pos.Y+(size.Y/2)+inset.Y
                pcall(function()game:GetService("VirtualInputManager"):SendTouchEvent(8822,Enum.UserInputState.Begin.Value,x,y)end)
                task.wait(0.01)
                pcall(function()game:GetService("VirtualInputManager"):SendTouchEvent(8822,Enum.UserInputState.End.Value,x,y)end)
                pcall(function()if firesignal and btn.MouseButton1Click then firesignal(btn.MouseButton1Click)end end)
            end
        else
            pcall(function()game:GetService("VirtualInputManager"):SendKeyEvent(true,Enum.KeyCode.Space,false,game)end)
            task.wait(0.01)
            pcall(function()game:GetService("VirtualInputManager"):SendKeyEvent(false,Enum.KeyCode.Space,false,game)end)
        end
    end
    local function VD_GetSkillCheck()for _,guiName in ipairs({"SkillCheckPromptGui","SkillCheckPromptGui-con"})do local gui=PlayerGui:FindFirstChild(guiName,true) if gui then local check=gui:FindFirstChild("Check",true) if check and check.Visible then local line=check:FindFirstChild("Line",true) local goal=check:FindFirstChild("Goal",true) if line and goal then return line,goal end end end end return nil,nil end
    local function VD_AngularDelta(from,to)local d=to-from if d>180 then d=d-360 end if d<-180 then d=d+360 end return d end
    local function VD_CrossedZone(prevLr,lr,startPos,endPos)local function inZone(r)if startPos>endPos then return r>=startPos or r<=endPos end return r>=startPos and r<=endPos end if inZone(lr)then return true end if prevLr==nil then return false end local delta=VD_AngularDelta(prevLr,lr) local steps=math.abs(math.floor(delta)) if steps<2 then return false end local stepSize=delta/steps for i=1,steps do if inZone((prevLr+stepSize*i)%360)then return true end end return false end
    local function VD_NormalSkillcheckUpdate()local line,goal=VD_GetSkillCheck() if not(line and goal)then AutoSkill.LastGoalRotation=nil AutoSkill.HasClickedThisGoal=false AutoSkill.LastLineRotation=nil AutoSkill.LastTick=nil AutoSkill.WasActive=false return end local lr=line.Rotation%360 local gr=goal.Rotation%360 local now=os.clock() if not AutoSkill.WasActive then AutoSkill.WasActive=true AutoSkill.HasClickedThisGoal=false AutoSkill.LastGoalRotation=gr AutoSkill.LastLineRotation=lr AutoSkill.LastTick=now return end if AutoSkill.LastGoalRotation and math.abs(VD_AngularDelta(AutoSkill.LastGoalRotation,gr))>5 then AutoSkill.HasClickedThisGoal=false AutoSkill.LastLineRotation=nil AutoSkill.LastTick=nil end AutoSkill.LastGoalRotation=gr if AutoSkill.HasClickedThisGoal then AutoSkill.LastLineRotation=lr AutoSkill.LastTick=now return end if AutoSkill.LastLineRotation and AutoSkill.LastTick then local dt=now-AutoSkill.LastTick if dt>0 then local lineSpeed=VD_AngularDelta(AutoSkill.LastLineRotation,lr)/dt local predicted=(lr+lineSpeed*dt*0)%360 if VD_CrossedZone(AutoSkill.LastLineRotation,predicted,(gr+104)%360,(gr+109)%360)then AutoSkill.HasClickedThisGoal=true task.spawn(function()task.wait(0.03); VD_PressSkill()end)end end end AutoSkill.LastLineRotation=lr AutoSkill.LastTick=now end
    local function VD_PerfectSkillcheckUpdate()local line,goal=VD_GetSkillCheck() if not(line and goal)then AutoSkill.PerfectLastGoalRotation=nil AutoSkill.PerfectHasClickedThisGoal=false AutoSkill.PerfectLastLineRotation=nil AutoSkill.PerfectLastTick=nil AutoSkill.PerfectWasActive=false return end local lr=line.Rotation%360 local gr=goal.Rotation%360 local now=os.clock() if not AutoSkill.PerfectWasActive then AutoSkill.PerfectWasActive=true AutoSkill.PerfectHasClickedThisGoal=false AutoSkill.PerfectLastGoalRotation=gr AutoSkill.PerfectLastLineRotation=lr AutoSkill.PerfectLastTick=now return end if AutoSkill.PerfectLastGoalRotation and math.abs(VD_AngularDelta(AutoSkill.PerfectLastGoalRotation,gr))>5 then AutoSkill.PerfectHasClickedThisGoal=false AutoSkill.PerfectLastLineRotation=nil AutoSkill.PerfectLastTick=nil end AutoSkill.PerfectLastGoalRotation=gr if AutoSkill.PerfectHasClickedThisGoal then AutoSkill.PerfectLastLineRotation=lr AutoSkill.PerfectLastTick=now return end if AutoSkill.PerfectLastLineRotation and AutoSkill.PerfectLastTick then local dt=now-AutoSkill.PerfectLastTick if dt>0 then local lineSpeed=VD_AngularDelta(AutoSkill.PerfectLastLineRotation,lr)/dt local predicted=(lr+lineSpeed*dt*0)%360 if VD_CrossedZone(AutoSkill.PerfectLastLineRotation,predicted,(gr+104)%360,(gr+108)%360)then AutoSkill.PerfectHasClickedThisGoal=true VD_PressSkill()end end end AutoSkill.PerfectLastLineRotation=lr AutoSkill.PerfectLastTick=now end
    local function VD_InstantSkillcheckUpdate()local line,goal=VD_GetSkillCheck() if not(line and goal)then AutoSkill.InstantHasClicked=false AutoSkill.InstantLastGoalRotation=0 AutoSkill.InstantLastGoalInstance=nil AutoSkill.InstantCurrentGoalID=0 if AutoSkill.InstantRotationConnection then AutoSkill.InstantRotationConnection:Disconnect(); AutoSkill.InstantRotationConnection=nil end return end local gr=goal.Rotation%360 local perfectRot=(gr+106)%360 if not AutoSkill.InstantForcingRotation then AutoSkill.InstantForcingRotation=true pcall(function()line.Rotation=perfectRot end) AutoSkill.InstantForcingRotation=false end local diff=math.abs(gr-AutoSkill.InstantLastGoalRotation) if diff>180 then diff=360-diff end local isNewGoal=diff>0.5 or AutoSkill.InstantLastGoalInstance~=goal if isNewGoal then AutoSkill.InstantHasClicked=false AutoSkill.InstantCurrentGoalID=AutoSkill.InstantCurrentGoalID+1 local assignedID=AutoSkill.InstantCurrentGoalID if AutoSkill.InstantRotationConnection then AutoSkill.InstantRotationConnection:Disconnect()end AutoSkill.InstantRotationConnection=line:GetPropertyChangedSignal("Rotation"):Connect(function()if AutoSkill.InstantForcingRotation then return end AutoSkill.InstantForcingRotation=true pcall(function()local _,cGoal=VD_GetSkillCheck() if cGoal then line.Rotation=(cGoal.Rotation%360+106)%360 end end) AutoSkill.InstantForcingRotation=false end) if not AutoSkill.InstantHasClicked then AutoSkill.InstantHasClicked=true task.spawn(function()task.wait(0.05) if AutoSkill.InstantCurrentGoalID==assignedID then local cl,cg=VD_GetSkillCheck() if cl and cg and tick()-AutoSkill.InstantLastTriggerTick>0.03 then AutoSkill.InstantLastTriggerTick=tick() VD_PressSkill()end end end)end end AutoSkill.InstantLastGoalRotation=gr AutoSkill.InstantLastGoalInstance=goal end
    RunService.RenderStepped:Connect(function()if not VD.AutoSkillcheck then return end if VD.AutoSkillcheckMode=="Perfect"then VD_PerfectSkillcheckUpdate() elseif VD.AutoSkillcheckMode=="Instant"then VD_InstantSkillcheckUpdate() else VD_NormalSkillcheckUpdate()end end)
    function ZiaanFeatures.SetAutoSkillcheck(state)VD.AutoSkillcheck=state==true if not VD.AutoSkillcheck then if AutoSkill.InstantRotationConnection then AutoSkill.InstantRotationConnection:Disconnect(); AutoSkill.InstantRotationConnection=nil end AutoSkill.InstantHasClicked=false AutoSkill.WasActive=false AutoSkill.PerfectWasActive=false end end
end

-- ===== INSTANT HEAL & AUTO HEAL ALL =====
do
    local InstantHealSelf=false
    local AutoHealAll=false
    local AutoHealAllConnection=nil
    local InstantHealConnection=nil
    function doSelfHeal()local char=LocalPlayer.Character if not char then return end local skillCheckRemote=ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent pcall(function()skillCheckRemote:FireServer("success",100,char)end)end
    function doSelfHealTrue()local char=LocalPlayer.Character if not char then return end local healRemote=ReplicatedStorage.Remotes.Healing.HealEvent local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end pcall(function()healRemote:FireServer(hrp,true)end)end
    function doSelfHealFalse()local char=LocalPlayer.Character if not char then return end local healRemote=ReplicatedStorage.Remotes.Healing.HealEvent local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end pcall(function()healRemote:FireServer(hrp,false)end)end
    function doOthersHealSkillCheck(targetPlayer)if not targetPlayer or not targetPlayer.Character then return end local skillCheckRemote=ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent pcall(function()skillCheckRemote:FireServer("success",100,targetPlayer.Character)end)end
    function doOthersHealTrue(targetPlayer)if not targetPlayer or not targetPlayer.Character then return end local targetHRP=targetPlayer.Character:FindFirstChild("HumanoidRootPart") if not targetHRP then return end local healRemote=ReplicatedStorage.Remotes.Healing.HealEvent pcall(function()healRemote:FireServer(targetHRP,true)end)end
    function doOthersHealFalse(targetPlayer)if not targetPlayer or not targetPlayer.Character then return end local targetHRP=targetPlayer.Character:FindFirstChild("HumanoidRootPart") if not targetHRP then return end local healRemote=ReplicatedStorage.Remotes.Healing.HealEvent pcall(function()healRemote:FireServer(targetHRP,false)end)end
    function setInstantHealSelf(v)InstantHealSelf=v if v then local skillCheckTimer=0 local healTrueTimer=0 local healFalseTimer=0 local healTrueActive=false if InstantHealConnection then InstantHealConnection:Disconnect()end InstantHealConnection=RunService.Heartbeat:Connect(function(dt)if not InstantHealSelf then return end local myChar=LocalPlayer.Character local myHum=myChar and myChar:FindFirstChildOfClass("Humanoid") if not myHum or myHum.Health>=myHum.MaxHealth*0.9 then return end skillCheckTimer=skillCheckTimer+dt if skillCheckTimer>=0.05 then skillCheckTimer=0; doSelfHeal()end healTrueTimer=healTrueTimer+dt if healTrueTimer>=0.06 and not healTrueActive then healTrueTimer=0; healTrueActive=true; doSelfHealTrue()end healFalseTimer=healFalseTimer+dt if healFalseTimer>=0.09 and healTrueActive then healFalseTimer=0; healTrueActive=false; doSelfHealFalse(); healTrueTimer=-0.10 end end) else if InstantHealConnection then InstantHealConnection:Disconnect(); InstantHealConnection=nil end end end
    function setAutoHealAll(v)AutoHealAll=v if v then local timers={} if AutoHealAllConnection then AutoHealAllConnection:Disconnect()end AutoHealAllConnection=RunService.Heartbeat:Connect(function(dt)if not AutoHealAll then return end for _,player in ipairs(Players:GetPlayers())do if player~=LocalPlayer and player.Character then local hrp=player.Character:FindFirstChild("HumanoidRootPart") local hum=player.Character:FindFirstChildOfClass("Humanoid") if hum and hum.Health>0 and hum.Health<hum.MaxHealth*0.9 then if not timers[player]then timers[player]={sc=0,t=0,f=0,active=false}end local tm=timers[player] tm.sc=tm.sc+dt if tm.sc>=0.05 then tm.sc=0; doOthersHealSkillCheck(player)end tm.t=tm.t+dt if tm.t>=0.09 and not tm.active then tm.t=0; tm.active=true; doOthersHealTrue(player)end tm.f=tm.f+dt if tm.f>=0.07 and tm.active then tm.f=0; tm.active=false; doOthersHealFalse(player); tm.t=-0.10 end else timers[player]=nil end end end end) else if AutoHealAllConnection then AutoHealAllConnection:Disconnect(); AutoHealAllConnection=nil end end end
    function ZiaanFeatures.SetInstantHeal(v)setInstantHealSelf(v)end
    function ZiaanFeatures.SetAutoHealAll(v)setAutoHealAll(v)end
end

-- ===== SILENT AIM TOF (Ziaan) =====
do
    local IYAN_ToFFireRemote=nil
    local oldNamecall
    local function setupToF()
        if getgenv().IYAN_AntiFailHooked then return end
        getgenv().IYAN_AntiFailHooked=true
        task.spawn(function()
            pcall(function()
                local Remotes=ReplicatedStorage:WaitForChild("Remotes",10)
                if not Remotes then return end
                local tofItems=Remotes:FindFirstChild("Items")
                local tofFolder=tofItems and tofItems:FindFirstChild("Twist of Fate")
                IYAN_ToFFireRemote=tofFolder and tofFolder:FindFirstChild("Fire")
                local _tofDeferred=false
                oldNamecall=hookmetamethod(game,"__namecall",function(self,...)
                    local method=getnamecallmethod()
                    local args={...}
                    if _tofDeferred then
                        return oldNamecall(self,...)
                    elseif IYAN_ToFFireRemote and VD.AUTO_ToFAim and self==IYAN_ToFFireRemote and method=="FireServer" and not checkcaller() then
                        if typeof(args[1])=="Instance" and typeof(args[2])=="Vector3" then
                            local myChar=LocalPlayer.Character
                            local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local bestPart,bestDist=nil,(VD.AUTO_ToFAimRange or 90)
                                local targetMode=VD.AUTO_ToFTargetMode or "Killer"
                                local aimPartName=VD.AUTO_ToFAimPart or "HumanoidRootPart"
                                if targetMode=="SCP" then
                                    if IYAN_WorldReg and IYAN_WorldReg.SCPZombie then
                                        for model,entry in pairs(IYAN_WorldReg.SCPZombie)do
                                            if model and model.Parent then
                                                local part
                                                if model:IsA("Model")then part=model:FindFirstChild(aimPartName)or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                                                elseif model:IsA("BasePart")then part=model end
                                                part=part or(entry and entry.part)
                                                if part then
                                                    local d=(part.Position-myRoot.Position).Magnitude
                                                    if d<=bestDist then bestDist=d; bestPart=part end
                                                end
                                            end
                                        end
                                    end
                                else
                                    for _,plr in ipairs(Players:GetPlayers())do
                                        if plr~=LocalPlayer and plr.Character and plr.Team then
                                            local validTeam=(targetMode=="Killer" and plr.Team.Name=="Killer")or(targetMode=="Survivor" and plr.Team.Name=="Survivors")
                                            if validTeam then
                                                local targetPart=plr.Character:FindFirstChild(aimPartName)
                                                local targetHum=plr.Character:FindFirstChildOfClass("Humanoid")
                                                if targetPart and targetHum and targetHum.Health>0 then
                                                    local d=(targetPart.Position-myRoot.Position).Magnitude
                                                    if d<=bestDist then bestDist=d; bestPart=targetPart end
                                                end
                                            end
                                        end
                                    end
                                end
                                if bestPart then
                                    local gunPart=args[1]
                                    local gunPos pcall(function()gunPos=gunPart.Position end) gunPos=gunPos or myRoot.Position
                                    local targetCenter=bestPart.Position
                                    local targetPos=targetCenter
                                    if VD.AUTO_ToFPredict then
                                        local rawVel=bestPart.AssemblyLinearVelocity
                                        local flatVel=Vector3.new(rawVel.X,0,rawVel.Z)
                                        local bulletSpeed=VD.AUTO_ToFBulletSpeed or 200
                                        local travelTime=bestDist/bulletSpeed
                                        targetPos=targetCenter+(flatVel*travelTime)
                                    end
                                    local dir=targetPos-gunPos
                                    local newDir=(dir.Magnitude>0.01)and dir.Unit or args[2]
                                    local camLook=Camera.CFrame.LookVector
                                    local dotCheck=camLook:Dot(newDir)
                                    if dotCheck<(VD.AUTO_ToFDotThreshold or 0.5)then return end
                                    _tofDeferred=true
                                    task.defer(function()
                                        pcall(function()IYAN_ToFFireRemote:FireServer(args[1],newDir)end)
                                        _tofDeferred=false
                                    end)
                                    return
                                end
                            end
                        end
                    end
                    if oldNamecall then return oldNamecall(self,...)end
                end)
                getgenv().IYAN_oldNamecall=oldNamecall
            end)
        end)
    end
    setupToF()
end

-- ===== LIGHTING: Fullbright & No Fog (Ziaan) =====
local defaultLighting={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart}
local function applyFullbright(state)if state then Lighting.Brightness=1 Lighting.Ambient=Color3.new(1,1,1) Lighting.OutdoorAmbient=Color3.new(1,1,1) else Lighting.Brightness=defaultLighting.Brightness Lighting.Ambient=defaultLighting.Ambient Lighting.OutdoorAmbient=defaultLighting.OutdoorAmbient end end
local function applyNoFog(state)if state then Lighting.FogEnd=9999 Lighting.FogStart=0 else Lighting.FogEnd=defaultLighting.FogEnd Lighting.FogStart=defaultLighting.FogStart end end

-- ===== TELEPORT UTIL (dari No Mercy) =====
local function Teleport(position,offset)local root=GetRoot() if not root then Notify("Error","Character not found",3) return false end offset=offset or Vector3.new(0,Settings.Teleportation.TeleportOffset,0) if Settings.Teleportation.SafeTeleport then pcall(function()for _,part in ipairs(LocalPlayer.Character:GetDescendants())do if part:IsA("BasePart")then part.CanCollide=false end end end)end root.CFrame=position+offset if Settings.Teleportation.SafeTeleport then task.delay(0.5,function()pcall(function()for _,part in ipairs(LocalPlayer.Character:GetDescendants())do if part:IsA("BasePart")and part.Name~="HumanoidRootPart"then part.CanCollide=true end end end)end)end return true end
local function EscapeGenerator()local root=GetRoot() if not root then return false end local _,gen,_=FindNearGenerator() if not gen then Notify("Not Near","You're not near any generator",2) return false end local part=gen:FindFirstChildWhichIsA("BasePart") if part then local direction=(root.Position-part.Position).Unit local distance=Settings.AutoFeatures.LeaveDistance+15 local target=root.Position+(direction*distance) if Teleport(CFrame.new(target,target+root.CFrame.LookVector),Vector3.new(0,2,0))then Notify("Escaped!",string.format("Moved %.0f studs away",distance),2) return true end end return false end
local function FindNearGenerator()local root=GetRoot() if not root then return false,nil end local gens=MapCache.Models("Generator") if #gens==0 then return false,nil end local rootPos=root.Position local near,nearDist=nil,math.huge for i=1,#gens do local obj=gens[i] local part=MapCache.Anchor(obj) if part then local d=(part.Position-rootPos).Magnitude if d<nearDist then nearDist=d; near=obj end end end if near and nearDist<=Settings.AutoFeatures.LeaveDistance then return true,near,nearDist end return false,nil,nil end
local function ListGeneratorsSorted()local root=GetRoot() if not root then return{}end local list={} for _,obj in ipairs(MapCache.Models("Generator"))do local part=MapCache.Anchor(obj) if part then list[#list+1]={model=obj,part=part,position=part.Position,distance=(part.Position-root.Position).Magnitude} end end table.sort(list,function(a,b)return a.distance<b.distance end) return list end
local function ListObjectsByName(objectName)local list={} local root=GetRoot() local rootPos=root and root.Position for _,obj in ipairs(MapCache.Models(objectName))do local part=MapCache.Anchor(obj) if part then list[#list+1]={model=obj,part=part,position=part.Position,distance=(rootPos and(part.Position-rootPos).Magnitude)or 0} end end table.sort(list,function(a,b)return a.distance<b.distance end) return list end
local function TeleportToNearest(objectName,label)local list=ListObjectsByName(objectName) if #list==0 then Notify("Tidak Ada","Tidak menemukan "..label,3) return end if Teleport(list[1].part.CFrame)then Notify("Teleported",string.format("%s terdekat (%.0fm)",label,list[1].distance),3)end end

-- ===== NO MERCY ORIGINAL FEATURES (Aimbot, Player, dll) =====
-- (Karena sudah ada di file No Mercy, saya akan integrasikan dengan ringkas)
-- Tapi untuk efisiensi, saya akan menggunakan fungsi yang sudah ada di No Mercy.

-- ===== UI TABS =====
Breathe(0.004)
local Tabs={
    Info=Window:AddTab({Title="Info",Icon="info"}),
    Killer=Window:AddTab({Title="Killer",Icon="skull"}),
    Survivor=Window:AddTab({Title="Survivor",Icon="shield"}),
    Aimbot=Window:AddTab({Title="Aimbot",Icon="crosshair"}),
    ESP=Window:AddTab({Title="ESP",Icon="eye"}),
    Gameplay=Window:AddTab({Title="Gameplay",Icon="gamepad-2"}),
    Player=Window:AddTab({Title="Player",Icon="user"}),
    Teleport=Window:AddTab({Title="Teleport",Icon="navigation"}),
    Emote=Window:AddTab({Title="Emote",Icon="smile"}),
    Settings=Window:AddTab({Title="Settings",Icon="settings"}),
    Config=Window:AddTab({Title="Config",Icon="save"}),
}

-- ===== TAB INFO =====
Breathe()
Tabs.Info:AddParagraph({Title="NO MERCY x ZIAANHUB v3.6",Content="Created by Sobing4413 & Ziaan\nGame: Violence District\nPlatform: "..(isMobile and"Mobile"or"PC").."\nExecutor: "..executorName})
Tabs.Info:AddButton({Title="Copy Discord Invite",Description="Salin link discord ke clipboard",Callback=function()local ok=pcall(function()setclipboard("https://discord.gg/CnNqEVFxh6")end) Notify("Discord",(ok and"Link tersalin!")or"discord.gg/CnNqEVFxh6",4)end})

-- ===== TAB KILLER (Ziaan features) =====
Breathe()
Tabs.Killer:AddSection("KILLER POWERS (Ziaan)")
local KillerSettings={AutoAttack=false,DoubleTap=false,DestroyPallets=false,AutoBreakGene=false,BlockVaults=false,AntiBlind=false,CustomMasked="Richard",VeilEnabled=false}
Settings.KillerFeatures=KillerSettings

Tabs.Killer:AddToggle("KillerAutoAttack",{Title="Auto Attack (Ziaan)",Default=false}):OnChanged(function(v)KillerSettings.AutoAttack=v Settings.AutoFeatures.AutoAttack=v Notify("Auto Attack",v and"Enabled"or"Disabled",2)end)
Tabs.Killer:AddToggle("KillerDoubleTap",{Title="Double Tap",Default=false}):OnChanged(function(v)KillerSettings.DoubleTap=v VD.KILLER_DoubleTap=v Notify("Double Tap",v and"Enabled"or"Disabled",2)end)
Tabs.Killer:AddToggle("KillerDestroyPallets",{Title="Destroy Pallets",Default=false}):OnChanged(function(v)KillerSettings.DestroyPallets=v VD.KILLER_DestroyPallets=v Notify("Destroy Pallets",v and"Enabled"or"Disabled",2)end)
Tabs.Killer:AddToggle("KillerAutoBreakGene",{Title="Auto Kick Generator",Default=false}):OnChanged(function(v)KillerSettings.AutoBreakGene=v VD.KILLER_AutoBreakGene=v Notify("Auto Kick Gen",v and"Enabled"or"Disabled",2)end)
Tabs.Killer:AddToggle("KillerBlockVaults",{Title="Block All Vaults",Default=false}):OnChanged(function(v)KillerSettings.BlockVaults=v VD.KILLER_BlockVaults=v Notify("Block Vaults",v and"Enabled"or"Disabled",2)end)
Tabs.Killer:AddToggle("KillerAntiBlind",{Title="Anti Blind (Flashlight)",Default=false}):OnChanged(function(v)KillerSettings.AntiBlind=v VD.KILLER_AntiBlind=v ZiaanFeatures.SetupAntiBlind() Notify("Anti Blind",v and"Enabled"or"Disabled",2)end)
Tabs.Killer:AddDropdown("KillerCustomMasked",{Title="Custom Masked",Values={"Richard","Tony","Brandon","Jake","Richter","Graham","Alex"},Default=1}):OnChanged(function(value)KillerSettings.CustomMasked=value VD.KILLER_CustomMasked=value pcall(ZiaanFeatures.ApplyCustomMasked,value)end)
Tabs.Killer:AddToggle("KillerVeil",{Title="Silent Aim Veil (Ziaan)",Default=false}):OnChanged(function(v)KillerSettings.VeilEnabled=v ZiaanFeatures.SetVeilConfig({Enabled=v,ShowFOV=true,FOV=150,SpearSpeed=165,Gravity=Workspace.Gravity*0.5,AutoPredict=false}) Notify("Veil",v and"Enabled"or"Disabled",2)end)

-- ===== TAB SURVIVOR (Ziaan features) =====
Breathe()
Tabs.Survivor:AddSection("SURVIVOR FEATURES (Ziaan)")
local SurvivorSettings={FleeKiller=false,FleeDistance=40,AntiKnock=false,FirstPerson=false,AutoParry=false,ParryRadius=13,ParrySafeDistance=30,AutoDropPallet=false,AutoDropPalletDist=20,AutoDropPalletMode="Aggressive",AutoVault=false,AutoPalletSlide=false}
Settings.SurvivorFeatures=SurvivorSettings

Tabs.Survivor:AddToggle("SurvFleeKiller",{Title="Flee Killer",Default=false}):OnChanged(function(v)SurvivorSettings.FleeKiller=v VD.SURV_FleeKiller=v Notify("Flee Killer",v and"Enabled"or"Disabled",2)end)
Tabs.Survivor:AddSlider("SurvFleeDist",{Title="Flee Distance",Default=40,Min=15,Max=80,Rounding=0,Callback=function(v)SurvivorSettings.FleeDistance=v VD.SURV_FleeDistance=v end})
Tabs.Survivor:AddToggle("SurvAntiKnock",{Title="Anti Knock",Default=false}):OnChanged(function(v)SurvivorSettings.AntiKnock=v ZiaanFeatures.ToggleAntiKnock(v)end)
Tabs.Survivor:AddToggle("SurvFirstPerson",{Title="First Person Camera",Default=false}):OnChanged(function(v)SurvivorSettings.FirstPerson=v ZiaanFeatures.ToggleFirstPerson(v)end)
Tabs.Survivor:AddToggle("SurvAutoParry",{Title="Auto Parry (Ziaan)",Default=false}):OnChanged(function(v)SurvivorSettings.AutoParry=v VD.SURV_AutoParry=v ParryConfig.Enabled=v if v then makeRing(); ZiaanFeatures.StartParryLoop() else destroyRing() end Notify("Auto Parry",v and"Enabled"or"Disabled",2)end)
Tabs.Survivor:AddSlider("SurvParryRadius",{Title="Parry Radius",Default=13,Min=5,Max=40,Rounding=0,Callback=function(v)ParryConfig.Radius=v if ParryConfig.Enabled then makeRing()end end})
Tabs.Survivor:AddSlider("SurvParrySafe",{Title="Parry Safe Distance",Default=30,Min=10,Max=80,Rounding=0,Callback=function(v)ParryConfig.SafeDistance=v end})
Tabs.Survivor:AddToggle("SurvAutoDropPallet",{Title="Auto Drop Pallet",Default=false}):OnChanged(function(v)SurvivorSettings.AutoDropPallet=v VD.SURV_AutoDropPallet=v Notify("Auto Drop Pallet",v and"Enabled"or"Disabled",2)end)
Tabs.Survivor:AddSlider("SurvPalletDist",{Title="Pallet Trigger Range",Default=20,Min=5,Max=50,Rounding=0,Callback=function(v)SurvivorSettings.AutoDropPalletDist=v VD.SURV_AutoDropPalletDist=v end})
Tabs.Survivor:AddDropdown("SurvPalletMode",{Title="Pallet Mode",Values={"Aggressive","Safe"},Default=1,Callback=function(v)SurvivorSettings.AutoDropPalletMode=v VD.SURV_AutoDropPalletMode=v end})
Tabs.Survivor:AddToggle("SurvAutoVault",{Title="Auto Vault",Default=false}):OnChanged(function(v)SurvivorSettings.AutoVault=v VD.SURV_AutoVault=v Notify("Auto Vault",v and"Enabled"or"Disabled",2)end)
Tabs.Survivor:AddToggle("SurvAutoPalletSlide",{Title="Auto Pallet (Slide)",Default=false}):OnChanged(function(v)SurvivorSettings.AutoPalletSlide=v VD.SURV_AutoPalletSlide=v Notify("Auto Pallet Slide",v and"Enabled"or"Disabled",2)end)
Tabs.Survivor:AddToggle("SurvAutoSkillcheck",{Title="Auto Skillcheck",Default=false}):OnChanged(function(v)ZiaanFeatures.SetAutoSkillcheck(v)end)
Tabs.Survivor:AddDropdown("SurvSkillcheckMode",{Title="Skillcheck Mode",Values={"Normal","Perfect","Instant"},Default=1,Callback=function(v)if type(v)=="table"then v=v[1]end VD.AutoSkillcheckMode=v or"Normal"if VD.AutoSkillcheckMode~="Instant"and AutoSkill.InstantRotationConnection then AutoSkill.InstantRotationConnection:Disconnect(); AutoSkill.InstantRotationConnection=nil; AutoSkill.InstantHasClicked=false end end})
Tabs.Survivor:AddToggle("SurvSilentAimToF",{Title="Silent Aim Twist Of Fate",Default=false}):OnChanged(function(v)VD.AUTO_ToFAim=v Notify("Silent Aim ToF",v and"Enabled"or"Disabled",2)end)
Tabs.Survivor:AddDropdown("SurvToFTarget",{Title="ToF Target Mode",Values={"Killer","Survivor","SCP"},Default=1,Callback=function(v)if type(v)=="table"then v=v[1]end VD.AUTO_ToFTargetMode=v or"Killer"end})
Tabs.Survivor:AddDropdown("SurvToFAimPart",{Title="ToF Aim Part",Values={"HumanoidRootPart","Head","Torso"},Default=1,Callback=function(v)if type(v)=="table"then v=v[1]end VD.AUTO_ToFAimPart=v or"HumanoidRootPart"end})
Tabs.Survivor:AddSlider("SurvToFRange",{Title="ToF Aim Range (studs)",Default=90,Min=10,Max=300,Rounding=0,Callback=function(v)VD.AUTO_ToFAimRange=v end})
Tabs.Survivor:AddSlider("SurvToFDot",{Title="Aim Strictness",Default=0.5,Min=-1,Max=1,Increment=0.05,Callback=function(v)VD.AUTO_ToFDotThreshold=v end})

-- ===== TAB GAMEPLAY (Auto Generator, Auto Leave, Auto Attack, dll) =====
Breathe()
Tabs.Gameplay:AddSection("AUTO GENERATOR")
Tabs.Gameplay:AddToggle("AutoGen",{Title="Auto Complete Generators",Default=false}):OnChanged(function(v)
    Settings.AutoFeatures.AutoGenerator=v
    if v then
        if Settings.AutoFeatures.GeneratorMode=="great"then PerfMgr.Add("autoGenJob",0.2,AutoGeneratorGreat,true)
        elseif Settings.AutoFeatures.GeneratorMode=="normal"then PerfMgr.Add("autoGenJob",0.2,AutoGeneratorNormal,true)
        else GenBoostZiaan.Enable()end
        Notify("Auto Generator","Mode: "..Settings.AutoFeatures.GeneratorMode,2)
    else
        PerfMgr.SetActive("autoGenJob",false)
        GenBoostZiaan.Disable()
        Notify("Auto Generator","Disabled",2)
    end
end)
Tabs.Gameplay:AddDropdown("GenMode",{Title="Generator Mode",Values={"Great (Fast)","Normal (Slow)","Ziaan Gen Boost"},Default=1,Callback=function(value)
    local modeMap={["Great (Fast)"]="great",["Normal (Slow)"]="normal",["Ziaan Gen Boost"]="ziaan"}
    Settings.AutoFeatures.GeneratorMode=modeMap[value] or"great"
    if Settings.AutoFeatures.AutoGenerator then
        PerfMgr.SetActive("autoGenJob",false)
        GenBoostZiaan.Disable()
        if Settings.AutoFeatures.GeneratorMode=="great"then PerfMgr.Add("autoGenJob",0.2,AutoGeneratorGreat,true)
        elseif Settings.AutoFeatures.GeneratorMode=="normal"then PerfMgr.Add("autoGenJob",0.2,AutoGeneratorNormal,true)
        else GenBoostZiaan.Enable()end
        Notify("Generator","Mode changed to "..value,2)
    end
end)
Tabs.Gameplay:AddButton({Title="Complete All Generators (Instant)",Callback=function()
    local repairEvent=RemoteCache.Get("Generator","RepairEvent")
    local skillCheckEvent=RemoteCache.Get("Generator","SkillCheckResultEvent")
    if not repairEvent or not skillCheckEvent then Notify("Error","Remote not found",3) return end
    local count=0
    for _,obj in ipairs(MapCache.Models("Generator"))do
        for _,child in ipairs(MapCache.GeneratorPoints(obj))do
            pcall(function()repairEvent:FireServer(child,true); skillCheckEvent:FireServer("success",1,obj,child); count=count+1 end)
        end
    end
    Notify("Done","Completed "..count.." generators",3)
end})

Tabs.Gameplay:AddSection("QUICK ESCAPE")
Tabs.Gameplay:AddToggle("QuickLeave",{Title="Enable Quick Leave Generator",Default=false}):OnChanged(function(v)
    Settings.AutoFeatures.AutoLeaveGenerator=v
    if v then
        if not isMobile then
            local conn=UserInputService.InputBegan:Connect(function(input,processed)if processed then return end if input.KeyCode==Settings.AutoFeatures.LeaveKeybind then local root=GetRoot() if not root then return end local _,gen,_=FindNearGenerator() if gen then local part=gen:FindFirstChildWhichIsA("BasePart") if part then local direction=(root.Position-part.Position).Unit local distance=Settings.AutoFeatures.LeaveDistance+15 local target=root.Position+(direction*distance) root.CFrame=CFrame.new(target,target+root.CFrame.LookVector)+Vector3.new(0,2,0) Notify("Escaped!","Moved away",2)end end end end)
            ConnMgr.Add("leave",conn)
        end
    else
        ConnMgr.Clear("leave")
    end
end)
if not isMobile then
    Tabs.Gameplay:AddDropdown("LeaveKeybind",{Title="Leave Keybind",Values={"Q","E","F","G","X","Z","V","B"},Default=1,Callback=function(value)
        local keyMap={Q=Enum.KeyCode.Q,E=Enum.KeyCode.E,F=Enum.KeyCode.F,G=Enum.KeyCode.G,X=Enum.KeyCode.X,Z=Enum.KeyCode.Z,V=Enum.KeyCode.V,B=Enum.KeyCode.B}
        Settings.AutoFeatures.LeaveKeybind=keyMap[value]or Enum.KeyCode.Q
    end})
end
Tabs.Gameplay:AddSlider("LeaveRange",{Title="Detection Range",Default=15,Min=5,Max=30,Rounding=0,Callback=function(v)Settings.AutoFeatures.LeaveDistance=v end})
Tabs.Gameplay:AddButton({Title="Leave Generator Now",Callback=function()
    local root=GetRoot() if not root then return end
    local _,gen,_=FindNearGenerator()
    if gen then
        local part=gen:FindFirstChildWhichIsA("BasePart")
        if part then
            local direction=(root.Position-part.Position).Unit
            local distance=Settings.AutoFeatures.LeaveDistance+15
            local target=root.Position+(direction*distance)
            root.CFrame=CFrame.new(target,target+root.CFrame.LookVector)+Vector3.new(0,2,0)
            Notify("Escaped!","Moved away",2)
        end
    else Notify("Not Near","No generator nearby",2)end
end})

Tabs.Gameplay:AddSection("KILLER POWERS (No Mercy)")
Tabs.Gameplay:AddToggle("AutoAttackNM",{Title="Auto Attack (No Mercy)",Default=false}):OnChanged(function(v)
    Settings.AutoFeatures.AutoAttack=v
    if v then
        if not PerfMgr.IsActive("autoAttack")then PerfMgr.SetActive("autoAttack",true)end
        Notify("Auto Attack","Enabled - Range: "..Settings.AutoFeatures.AttackRange,2)
    else
        PerfMgr.SetActive("autoAttack",false)
        Notify("Auto Attack","Disabled",2)
    end
end)
Tabs.Gameplay:AddSlider("AttackRangeNM",{Title="Attack Range (studs)",Default=10,Min=5,Max=20,Rounding=0,Callback=function(v)Settings.AutoFeatures.AttackRange=v end})

-- ===== TAB AIMBOT (No Mercy) =====
-- Saya akan tambahkan Aimbot dari No Mercy dengan toggle sederhana karena sudah ada di file No Mercy.
-- Namun untuk integrasi, saya akan gunakan fungsi yang sama.
Tabs.Aimbot:AddToggle("AimEnabled",{Title="Enable Aim Lock",Default=false}):OnChanged(function(v)
    AimConfig.AimbotEnabled=v
    Notify("Aimbot",v and"Aktif"or"Mati",2)
end)
Tabs.Aimbot:AddToggle("AimAutoShoot",{Title="Auto Shoot Target",Default=true}):OnChanged(function(v)AimConfig.AutoShoot=v end)
Tabs.Aimbot:AddDropdown("AimMode",{Title="Mode Aimbot",Values={"V1 (Laser)","V2 (Lock Kamera)"},Default=1,Callback=function(v)AimConfig.AimVersion=(v=="V2 (Lock Kamera)")and"V2"or"V1"end})
Tabs.Aimbot:AddDropdown("AimTarget",{Title="Pilih Target",Values={"Killer","Survivor","Zombie"},Default=1,Callback=function(v)AimConfig.TargetType=v CurrentTarget=nil Notify("Target","Target: "..tostring(v),2)end})
Tabs.Aimbot:AddInput("AimName",{Title="Nama Spesifik",Placeholder="kosongkan = semua",Default="",Callback=function(text)AimConfig.SpecificName=text or"" CurrentTarget=nil end})
local AimStatusLbl=CreateStatus(Tabs.Aimbot,"Status Aimbot","Mati")
local AimTargetLbl=CreateStatus(Tabs.Aimbot,"Target Terkunci","-")
Tabs.Aimbot:AddToggle("AimPrediction",{Title="Prediksi Gerakan",Default=true}):OnChanged(function(v)AimConfig.Prediction=v end)
Tabs.Aimbot:AddToggle("AimLaser",{Title="Laser Tracer",Default=true}):OnChanged(function(v)AimConfig.LaserEnabled=v end)
Tabs.Aimbot:AddToggle("AimFOVCircle",{Title="Lingkaran FOV",Default=true}):OnChanged(function(v)AimConfig.FOVCircleOn=v end)
Tabs.Aimbot:AddSlider("AimFOV",{Title="FOV Radius",Default=180,Min=50,Max=600,Rounding=0,Callback=function(v)AimConfig.FOVRadius=v end})
Tabs.Aimbot:AddSlider("AimMaxDist",{Title="Jarak Maksimal",Default=800,Min=100,Max=2000,Rounding=0,Callback=function(v)AimConfig.MaxDistance=v end})
Tabs.Aimbot:AddSlider("AimFireDelay",{Title="Delay Tembak (detik)",Default=0.1,Min=0.05,Max=1,Rounding=2,Callback=function(v)AimConfig.FireDelay=v end})

-- ===== TAB ESP (Ziaan) =====
Tabs.ESP:AddSection("MASTER ESP")
Tabs.ESP:AddToggle("ESPMaster",{Title="Enable ESP (Master)",Default=false}):OnChanged(function(v)
    Settings.ESP.Master=v
    ZiaanESP.Refresh()
    Notify("ESP Master",v and"ON"or"OFF",2)
end)
Tabs.ESP:AddSection("PLAYER / NPC")
Tabs.ESP:AddToggle("ESPKiller",{Title="Killer ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Killer=v
    if not v then ZiaanESP.ClearCategory("Killer")end
    ZiaanESP.Refresh()
end)
Tabs.ESP:AddToggle("ESPSurvivor",{Title="Survivor ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Survivor=v
    if not v then ZiaanESP.ClearCategory("Survivor")end
    ZiaanESP.Refresh()
end)
Tabs.ESP:AddToggle("ESPZombie",{Title="Zombie ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Zombie=v
    if not v then ZiaanESP.ClearCategory("Zombie")end
    ZiaanESP.Refresh()
end)
Tabs.ESP:AddSection("OBJECTS")
Tabs.ESP:AddToggle("ESPGenerator",{Title="Generator ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Generator=v; if not v then ZiaanESP.ClearCategory("Generator")end; ZiaanESP.Refresh()end)
Tabs.ESP:AddToggle("ESPGate",{Title="Gate ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Gate=v; if not v then ZiaanESP.ClearCategory("Gate")end; ZiaanESP.Refresh()end)
Tabs.ESP:AddToggle("ESPHook",{Title="Hook ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Hook=v; if not v then ZiaanESP.ClearCategory("Hook")end; ZiaanESP.Refresh()end)
Tabs.ESP:AddToggle("ESPClosestHook",{Title="Show Only Closest Hook",Default=false}):OnChanged(function(v)
    Settings.ESP.ShowOnlyClosestHook=v; ZiaanESP.Refresh()end)
Tabs.ESP:AddToggle("ESPPallet",{Title="Pallet ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Pallet=v; if not v then ZiaanESP.ClearCategory("Pallet")end; ZiaanESP.Refresh()end)
Tabs.ESP:AddToggle("ESPWindow",{Title="Window ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Window=v; if not v then ZiaanESP.ClearCategory("Window")end; ZiaanESP.Refresh()end)
Tabs.ESP:AddToggle("ESPPumpkin",{Title="Pumpkin ESP",Default=false}):OnChanged(function(v)
    Settings.ESP.Pumpkin=v; if not v then ZiaanESP.ClearCategory("Pumpkin")end; ZiaanESP.Refresh()end)
Tabs.ESP:AddSection("SETTINGS")
Tabs.ESP:AddToggle("ESPDistance",{Title="Show Distance",Default=true}):OnChanged(function(v)Settings.ESP.ShowDistance=v end)
Tabs.ESP:AddSlider("ESPMaxDist",{Title="Max Distance",Default=500,Min=100,Max=1000,Rounding=0,Callback=function(v)Settings.ESP.MaxDistance=v end})
Tabs.ESP:AddSlider("ESPUpdateRate",{Title="Update Rate (s)",Default=0.5,Min=0.1,Max=2,Rounding=2,Callback=function(v)Settings.Performance.UpdateRate=v end})
Tabs.ESP:AddButton({Title="Clear ESP",Callback=function()ZiaanESP.Disable(); ZiaanESP.Refresh(); Notify("ESP","Cleared",2)end})

-- ===== TAB TELEPORT (No Mercy) =====
Tabs.Teleport:AddSection("GENERATOR")
Tabs.Teleport:AddButton({Title="TP ke Generator Terdekat",Callback=function()
    local gens=ListGeneratorsSorted()
    if #gens==0 then Notify("Tidak Ada","Generator tidak ditemukan",3)return end
    if Teleport(gens[1].part.CFrame)then Notify("Teleported",string.format("Generator terdekat (%.0fm)",gens[1].distance),3)end
end})
Tabs.Teleport:AddButton({Title="TP ke Generator Terjauh",Callback=function()
    local gens=ListGeneratorsSorted()
    if #gens==0 then Notify("Tidak Ada","Generator tidak ditemukan",3)return end
    local far=gens[#gens]
    if Teleport(far.part.CFrame)then Notify("Teleported",string.format("Generator terjauh (%.0fm)",far.distance),3)end
end})
Tabs.Teleport:AddButton({Title="TP Keliling Semua Generator",Callback=function()
    local gens=ListGeneratorsSorted()
    if #gens==0 then Notify("Tidak Ada","Generator tidak ditemukan",3)return end
    Notify("Mulai",string.format("Keliling %d generator...",#gens),3)
    task.spawn(function()for i,gen in ipairs(gens)do if not GetRoot()then break end Teleport(gen.part.CFrame) task.wait(Settings.Teleportation.TeleportDelay)end Notify("Selesai","Semua generator dikunjungi",3)end)
end})
local generatorChoices={}
local GeneratorDropdown=Tabs.Teleport:AddDropdown("TPGeneratorPick",{Title="Pilih Generator",Description="Tekan Refresh dulu untuk memuat daftar",Values={"-"},Default=1})
Tabs.Teleport:AddButton({Title="Refresh Daftar Generator",Callback=function()
    local gens=ListGeneratorsSorted()
    generatorChoices={}
    local names={}
    for i,gen in ipairs(gens)do
        local label=string.format("#%d - %.0fm",i,gen.distance)
        table.insert(names,label)
        generatorChoices[label]=gen
    end
    if #names==0 then names={"-"}end
    GeneratorDropdown:SetValues(names)
    Notify("Generator",string.format("%d generator ditemukan",#gens),3)
end})
Tabs.Teleport:AddButton({Title="TP ke Generator Terpilih",Callback=function()
    local pick=generatorChoices[GeneratorDropdown.Value]
    if not pick then Notify("Teleport","Pilih generator dulu (Refresh)",3)return end
    Teleport(pick.part.CFrame)
    Notify("Teleported","Menuju generator terpilih",2)
end})
Tabs.Teleport:AddButton({Title="Kabur dari Generator",Callback=function()EscapeGenerator()end})

Tabs.Teleport:AddSection("OBJEK MAP")
Tabs.Teleport:AddButton({Title="TP ke Gate Terdekat",Callback=function()TeleportToNearest("Gate","Gate")end})
Tabs.Teleport:AddButton({Title="TP ke Hook Terdekat",Callback=function()TeleportToNearest("Hook","Hook")end})
Tabs.Teleport:AddButton({Title="TP ke Pallet Terdekat",Callback=function()TeleportToNearest("Pallet","Pallet")end})
Tabs.Teleport:AddButton({Title="TP ke Window Terdekat",Callback=function()TeleportToNearest("Window","Window")end})
Tabs.Teleport:AddButton({Title="TP ke Pumpkin Terdekat",Callback=function()TeleportToNearest("Pumpkin","Pumpkin")end})

Tabs.Teleport:AddSection("PEMAIN")
local PlayerDropdown=Tabs.Teleport:AddDropdown("TPPlayerPick",{Title="Pilih Pemain",Values={"-"},Default=1})
local function RefreshPlayerList()
    local names={}
    for _,plr in ipairs(Players:GetPlayers())do if plr~=LocalPlayer then table.insert(names,plr.Name)end end
    if #names==0 then names={"-"}end
    PlayerDropdown:SetValues(names)
    return #names
end
RefreshPlayerList()
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function()task.defer(RefreshPlayerList)end)
Tabs.Teleport:AddButton({Title="Refresh Daftar Pemain",Callback=function()Notify("Pemain",RefreshPlayerList().." pemain online",2)end})
Tabs.Teleport:AddButton({Title="TP ke Pemain Terpilih",Callback=function()
    local target=Players:FindFirstChild(tostring(PlayerDropdown.Value))
    if not target or not target.Character then Notify("Teleport","Pemain tidak ditemukan",3)return end
    local hrp=target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then Notify("Teleport","Karakter belum spawn",3)return end
    Teleport(hrp.CFrame*CFrame.new(0,0,3))
    Notify("Teleported","Menuju "..target.Name,2)
end})
Tabs.Teleport:AddButton({Title="TP ke Killer Terdekat",Callback=function()
    local root=GetRoot() if not root then Notify("Error","Karakter tidak ada",3)return end
    local nearest,dist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers())do
        if plr~=LocalPlayer and plr.Team and plr.Team.Name=="Killer"and plr.Character then
            local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d=(hrp.Position-root.Position).Magnitude
                if d<dist then nearest,dist=hrp,d end
            end
        end
    end
    if nearest then
        Teleport(nearest.CFrame*CFrame.new(0,0,5))
        Notify("Teleported",string.format("Killer (%.0fm)",dist),3)
    else Notify("Tidak Ada","Killer tidak ditemukan",3)end
end})
Tabs.Teleport:AddButton({Title="TP ke Survivor Terdekat",Callback=function()
    local root=GetRoot() if not root then Notify("Error","Karakter tidak ada",3)return end
    local nearest,dist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers())do
        if plr~=LocalPlayer and plr.Team and plr.Team.Name=="Survivors"and plr.Character then
            local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d=(hrp.Position-root.Position).Magnitude
                if d<dist then nearest,dist=hrp,d end
            end
        end
    end
    if nearest then
        Teleport(nearest.CFrame*CFrame.new(0,0,3))
        Notify("Teleported",string.format("Survivor (%.0fm)",dist),3)
    else Notify("Tidak Ada","Survivor tidak ditemukan",3)end
end})

Tabs.Teleport:AddSection("WAYPOINT & MANUAL")
local savedWaypoints={}
local WaypointDropdown=Tabs.Teleport:AddDropdown("TPWaypointPick",{Title="Waypoint Tersimpan",Values={"-"},Default=1})
local waypointNameInput=""
Tabs.Teleport:AddInput("TPWaypointName",{Title="Nama Waypoint",Placeholder="misal: basement",Default="",Callback=function(text)waypointNameInput=text or""end})
local function RefreshWaypoints()
    local names={}
    for name in pairs(savedWaypoints)do table.insert(names,name)end
    table.sort(names)
    if #names==0 then names={"-"}end
    WaypointDropdown:SetValues(names)
end
Tabs.Teleport:AddButton({Title="Simpan Posisi Sekarang",Callback=function()
    local root=GetRoot() if not root then Notify("Error","Karakter tidak ada",3)return end
    local name=(waypointNameInput~=""and waypointNameInput)or("Waypoint "..tostring(#savedWaypoints+1)..os.date("%H%M%S"))
    savedWaypoints[name]=root.CFrame
    RefreshWaypoints()
    Notify("Waypoint","Tersimpan: "..name,3)
end})
Tabs.Teleport:AddButton({Title="TP ke Waypoint Terpilih",Callback=function()
    local cf=savedWaypoints[tostring(WaypointDropdown.Value)]
    if not cf then Notify("Waypoint","Belum ada waypoint terpilih",3)return end
    Teleport(cf,Vector3.new(0,1,0))
    Notify("Teleported","Menuju "..tostring(WaypointDropdown.Value),2)
end})
Tabs.Teleport:AddButton({Title="Hapus Waypoint Terpilih",Callback=function()
    local key=tostring(WaypointDropdown.Value)
    if savedWaypoints[key]then savedWaypoints[key]=nil RefreshWaypoints() Notify("Waypoint","Dihapus: "..key,2)end
end})
local manualX,manualY,manualZ=0,0,0
Tabs.Teleport:AddInput("TPManualCoords",{Title="Koordinat Manual (X,Y,Z)",Placeholder="contoh: 100, 25, -300",Default="",Callback=function(text)
    local x,y,z=tostring(text):match("(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)")
    if x then manualX,manualY,manualZ=tonumber(x),tonumber(y),tonumber(z)end
end})
Tabs.Teleport:AddButton({Title="TP ke Koordinat Manual",Callback=function()Teleport(CFrame.new(manualX,manualY,manualZ),Vector3.new(0,0,0)) Notify("Teleported",string.format("(%.0f, %.0f, %.0f)",manualX,manualY,manualZ),3)end})
Tabs.Teleport:AddButton({Title="Copy Posisi Sekarang",Callback=function()
    local root=GetRoot() if not root then Notify("Error","Karakter tidak ada",3)return end
    local p=root.Position
    local text=string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
    pcall(function()setclipboard(text)end)
    Notify("Posisi",text,4)
end})

Tabs.Teleport:AddSection("SURVIVOR WIN")
Tabs.Teleport:AddButton({Title="Escape Game (Survivor Only)",Callback=function()
    if not IsSurvivor()then Notify("Error","Kamu harus jadi Survivor!",3)return end
    local root=GetRoot() if not root then Notify("Error","Karakter tidak ada",3)return end
    local map=MapCache.GetMap() if not map then Notify("Error","Map tidak ditemukan",3)return end
    local gate=MapCache.Models("Gate")[1] if not gate then Notify("Error","Gate tidak ditemukan",3)return end
    local escapeZone=gate:FindFirstChild("Escape")or gate:FindFirstChildWhichIsA("BasePart")
    if escapeZone then
        Teleport(escapeZone.CFrame,Vector3.new(0,5,0))
        task.wait(0.5)
        pcall(function()local escape=RemoteCache.Get("Gate","Escape") if escape then escape:FireServer()end end)
        Notify("Escape!","Teleport ke pintu keluar - jalan terus!",4)
    else Notify("Error","Zona escape tidak ditemukan",3)end
end})

Tabs.Teleport:AddSection("PENGATURAN TELEPORT")
Tabs.Teleport:AddSlider("TPOffset",{Title="Teleport Height Offset",Default=3,Min=0,Max=10,Rounding=0,Callback=function(v)Settings.Teleportation.TeleportOffset=v end})
Tabs.Teleport:AddSlider("TPDelay",{Title="Multi-Teleport Delay (detik)",Default=0.1,Min=0.1,Max=5,Rounding=2,Callback=function(v)Settings.Teleportation.TeleportDelay=v end})
Tabs.Teleport:AddToggle("TPSafe",{Title="Safe Teleport (No Collision)",Default=true,Callback=function(v)Settings.Teleportation.SafeTeleport=v end})

-- ===== TAB PLAYER (No Mercy + Ziaan) =====
Breathe()
Tabs.Player:AddSection("SPEED & JUMP")
local SpeedConfig={Enabled=false,Value=18,Jump=50,JumpEnabled=false}
Tabs.Player:AddToggle("SpeedBoost",{Title="Speed Boost",Default=false}):OnChanged(function(v)
    SpeedConfig.Enabled=v
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if v then hum.WalkSpeed=SpeedConfig.Value else hum.WalkSpeed=16 end
    end
    Notify("Speed Boost",v and("Aktif - "..SpeedConfig.Value)or"Mati",2)
end)
Tabs.Player:AddSlider("SpeedValue",{Title="Nilai Speed",Default=18,Min=16,Max=100,Rounding=0,Callback=function(v)SpeedConfig.Value=v if SpeedConfig.Enabled then local char=LocalPlayer.Character local hum=char and char:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed=v end end end})
Tabs.Player:AddToggle("JumpBoost",{Title="Jump Boost",Default=false}):OnChanged(function(v)
    SpeedConfig.JumpEnabled=v
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if v then hum.JumpPower=SpeedConfig.Jump else hum.JumpPower=50 end
    end
end)
Tabs.Player:AddSlider("JumpValue",{Title="Nilai Jump Power",Default=50,Min=50,Max=200,Rounding=0,Callback=function(v)SpeedConfig.Jump=v if SpeedConfig.JumpEnabled then local char=LocalPlayer.Character local hum=char and char:FindFirstChildOfClass("Humanoid") if hum then hum.JumpPower=v end end end})

Tabs.Player:AddSection("KAMERA & GERAK")
local CamConfig={Enabled=false,Height=10,Distance=20}
Tabs.Player:AddToggle("CamLock",{Title="Camera Lock POV",Default=false}):OnChanged(function(v)
    CamConfig.Enabled=v
    Notify("Camera Lock",v and"Aktif"or"Mati",2)
end)
Tabs.Player:AddSlider("CamHeight",{Title="Tinggi Kamera",Default=10,Min=2,Max=40,Rounding=0,Callback=function(v)CamConfig.Height=v end})
Tabs.Player:AddSlider("CamDistance",{Title="Jarak Kamera",Default=20,Min=5,Max=60,Rounding=0,Callback=function(v)CamConfig.Distance=v end})

Tabs.Player:AddSection("UNITY (FLY / GOD MODE)")
local FlyConfig={Enabled=false,Speed=60}
local flyBV,flyBG,flyConn=nil,nil,nil
local function stopFly()FlyConfig.Enabled=false if flyConn then flyConn:Disconnect(); flyConn=nil end if flyBV then flyBV:Destroy(); flyBV=nil end if flyBG then flyBG:Destroy(); flyBG=nil end end
local function startFly()local char=LocalPlayer.Character local hrp=char and char:FindFirstChild("HumanoidRootPart") if not hrp then Notify("Fly","Character tidak ditemukan",3)return end stopFly() FlyConfig.Enabled=true flyBV=Instance.new("BodyVelocity") flyBV.MaxForce=Vector3.new(1e5,1e5,1e5) flyBV.Velocity=Vector3.zero flyBV.Parent=hrp flyBG=Instance.new("BodyGyro") flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5) flyBG.P=1e4 flyBG.CFrame=Camera.CFrame flyBG.Parent=hrp flyConn=RunService.RenderStepped:Connect(function()if not FlyConfig.Enabled then return end local character=LocalPlayer.Character local root=character and character:FindFirstChild("HumanoidRootPart") local hum=character and character:FindFirstChildOfClass("Humanoid") if not root or not flyBV then return end flyBG.CFrame=Camera.CFrame local dir=Vector3.zero if hum and hum.MoveDirection.Magnitude>0 then dir=hum.MoveDirection end if UserInputService:IsKeyDown(Enum.KeyCode.Space)then dir=dir+Vector3.new(0,1,0)end if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)then dir=dir-Vector3.new(0,1,0)end flyBV.Velocity=(dir.Magnitude>0 and(dir.Unit*FlyConfig.Speed))or Vector3.zero end)end
Tabs.Player:AddToggle("FlyToggle",{Title="Fly",Default=false}):OnChanged(function(v)if v then startFly() else stopFly() end Notify("Fly",v and"Aktif"or"Mati",2)end)
Tabs.Player:AddSlider("FlySpeed",{Title="Kecepatan Fly",Default=60,Min=20,Max=200,Rounding=0,Callback=function(v)FlyConfig.Speed=v end})

local GodConfig={Enabled=false,InfiniteHealth=true,AntiKnock=true,AntiStun=true,AutoHeal=true,HealThreshold=50}
Tabs.Player:AddToggle("GodMode",{Title="No Damage (God Mode)",Default=false}):OnChanged(function(v)
    GodConfig.Enabled=v
    if v then
        local char=LocalPlayer.Character
        if char then
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health=hum.MaxHealth
                local conn=hum.HealthChanged:Connect(function(newH)if hum and GodConfig.Enabled and GodConfig.InfiniteHealth and(newH<hum.MaxHealth)then hum.Health=hum.MaxHealth end end)
                ConnMgr.Add("god",conn)
            end
        end
    else
        ConnMgr.Clear("god")
    end
    Notify("No Damage",v and"Aktif"or"Mati",2)
end)
Tabs.Player:AddToggle("AutoHeal",{Title="Auto Heal",Default=true}):OnChanged(function(v)GodConfig.AutoHeal=v end)
Tabs.Player:AddSlider("HealThreshold",{Title="Batas HP Auto Heal",Default=50,Min=10,Max=100,Rounding=0,Callback=function(v)GodConfig.HealThreshold=v end})
Tabs.Player:AddButton({Title="Heal Sekarang",Callback=function()
    local char=LocalPlayer.Character if not char then return end
    local healRemote=RemoteCache.Get("Healing","HealEvent")
    if healRemote then
        local hrp=char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function()healRemote:FireServer(hrp,true)end) end
    end
    Notify("Heal","Heal dipicu",2)
end})

-- ===== TAB EMOTE (No Mercy) =====
local EmoteData={{Name="Backflip",AnimationId="rbxassetid://74705617908505",SoundId=nil},{Name="Amukan",AnimationId="rbxassetid://79155929355612",SoundId=nil},{Name="Gelombang",AnimationId="rbxassetid://99670106766588",SoundId=nil},{Name="Istirahat Terapung",AnimationId="rbxassetid://114593021219597",SoundId=nil},{Name="Ayunan Lengan",AnimationId="rbxassetid://123701924525875",SoundId="rbxassetid://74216458932348"},{Name="Mannrobiks",AnimationId="rbxassetid://134677515695156",SoundId="rbxassetid://109596159930017"},{Name="Boneka Rusak",AnimationId="rbxassetid://131796630104825",SoundId="rbxassetid://88284355540646"},{Name="Jumat Malam",AnimationId="rbxassetid://83229063951016",SoundId="rbxassetid://85355610204255"},{Name="OnePlays",AnimationId="rbxassetid://140625405103474",SoundId="rbxassetid://94749073728335"},{Name="WarCry",AnimationId="rbxassetid://82600868380136",SoundId=nil},{Name="Balikan Cepat",AnimationId="rbxassetid://130933486827090",SoundId="rbxassetid://137966860089117"},{Name="Rentan",AnimationId="rbxassetid://73896868179198",SoundId="rbxassetid://124209794918032"},{Name="Emote Tambahan",AnimationId="rbxassetid://121773684313913",SoundId="rbxassetid://135265751184744"},{Name="Kyoufuu",AnimationId="rbxassetid://137322894494527",SoundId="rbxassetid://129064643026442"},{Name="Kombo Cepat",AnimationId="rbxassetid://105592621576604",SoundId="rbxassetid://88505795419631"}}
local currentTrack,currentSound,currentEmoteIx=nil,nil,nil
local function stopEmote()if currentTrack then pcall(function()currentTrack:Stop(0.15)end); currentTrack=nil end if currentSound then pcall(function()currentSound:Stop()end); pcall(function()currentSound:Destroy()end); currentSound=nil end pcall(function()local r=RemoteCache.Get("EmoteHandler") if r then r:FireServer("StopEmote")end end)end
local function playEmote(index)
    if currentEmoteIx==index then stopEmote(); currentEmoteIx=nil; return end
    local char=LocalPlayer.Character if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local anim=hum and hum:FindFirstChildOfClass("Animator")
    local ed=EmoteData[index]
    if not anim or not ed then return end
    stopEmote()
    currentEmoteIx=index
    local a=Instance.new("Animation") a.AnimationId=ed.AnimationId
    local ok,track=pcall(function()return anim:LoadAnimation(a)end)
    if ok and track then currentTrack=track currentTrack.Priority=Enum.AnimationPriority.Action4 currentTrack.Looped=true currentTrack:Play()end
    if ed.SoundId then local hrp=char:FindFirstChild("HumanoidRootPart") if hrp then currentSound=Instance.new("Sound") currentSound.SoundId=ed.SoundId currentSound.Looped=true currentSound.Volume=1 currentSound.Parent=hrp currentSound:Play()end end
end
Tabs.Emote:AddToggle("EmoteEnabled",{Title="Aktifkan Sistem Emote",Default=true}):OnChanged(function(v)if not v then stopEmote(); currentEmoteIx=nil end end)
for i,ed in ipairs(EmoteData)do Tabs.Emote:AddButton({Title=ed.Name,Description="Klik lagi untuk berhenti",Callback=function()playEmote(i)end})end
Tabs.Emote:AddButton({Title="Stop Emote",Callback=function()stopEmote(); currentEmoteIx=nil; Notify("Emote","Dihentikan",2)end})

-- ===== TAB SETTINGS =====
Breathe()
Tabs.Settings:AddSection("VISUAL")
Tabs.Settings:AddToggle("FullBright",{Title="Full Bright",Default=false}):OnChanged(function(v)VD.Fullbright=v applyFullbright(v)end)
Tabs.Settings:AddToggle("NoFog",{Title="No Fog",Default=false}):OnChanged(function(v)VD.NoFog=v applyNoFog(v)end)
local Themes={"Modern","Neon Blue","Blood Red","Matrix Green","Purple Haze"}
Tabs.Settings:AddDropdown("HudTheme",{Title="Tema HUD",Values=Themes,Default=4,Callback=function(v)Notify("Theme","Applied: "..tostring(v),3)end})
Tabs.Settings:AddToggle("FPSCounter",{Title="Show FPS Counter",Default=false}):OnChanged(function(v)
    if v then
        local gui=Instance.new("ScreenGui") gui.Name="FPSCounter" gui.ResetOnSpawn=false gui.Parent=(gethui and gethui())or game:GetService("CoreGui")
        local frame=Instance.new("Frame") frame.Size=UDim2.new(0,120,0,50) frame.Position=UDim2.new(0,10,0,10) frame.BackgroundColor3=Color3.fromRGB(18,18,30) frame.BackgroundTransparency=0.2 frame.BorderSizePixel=0 frame.Parent=gui
        Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
        local label=Instance.new("TextLabel") label.Size=UDim2.new(1,0,1,0) label.BackgroundTransparency=1 label.Text="FPS: 0" label.TextColor3=Color3.fromRGB(0,255,255) label.Font=Enum.Font.GothamBold label.TextSize=18 label.Parent=frame
        local lastTime=tick() local frameCount=0
        local fpsConn=RunService.Heartbeat:Connect(function()frameCount=frameCount+1 local now=tick() if(now-lastTime)>=1.5 then local fps=math.floor(frameCount/(now-lastTime)) frameCount=0 lastTime=now if fps>=60 then label.TextColor3=Color3.fromRGB(0,255,0) elseif fps>=30 then label.TextColor3=Color3.fromRGB(255,255,0) else label.TextColor3=Color3.fromRGB(255,0,0) end label.Text=string.format("FPS: %d",fps) end end)
        ConnMgr.Add("fps",fpsConn)
    else
        ConnMgr.Clear("fps")
        local gui=game:GetService("CoreGui"):FindFirstChild("FPSCounter")
        if gui then gui:Destroy()end
    end
end)

Tabs.Settings:AddSection("PERFORMANCE")
Tabs.Settings:AddToggle("PerfParticles",{Title="Disable Particles & Effects",Default=false}):OnChanged(function(v)
    Settings.Performance.DisableParticles=v
    if v then pcall(function()for _,obj in ipairs(Workspace:GetDescendants())do if obj:IsA("ParticleEmitter")or obj:IsA("Trail")or obj:IsA("Beam")then obj.Enabled=false end end end)end
end)
Tabs.Settings:AddToggle("PerfGraphics",{Title="Lower Graphics Quality",Default=false}):OnChanged(function(v)
    Settings.Performance.LowerGraphics=v
    if v then pcall(function()settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)end
end)
Tabs.Settings:AddToggle("PerfShadows",{Title="Disable Shadows",Default=false}):OnChanged(function(v)
    Settings.Performance.DisableShadows=v
    if v then pcall(function()game:GetService("Lighting").GlobalShadows=false end)end
end)
Tabs.Settings:AddToggle("PerfRender",{Title="Reduce Render Distance",Default=false}):OnChanged(function(v)
    Settings.Performance.ReduceRenderDistance=v
    if v then pcall(function()Workspace.StreamingEnabled=true; Workspace.StreamingMinRadius=32; Workspace.StreamingTargetRadius=64 end)end
end)
Tabs.Settings:AddButton({Title="Apply All Performance Boosts",Callback=function()
    Settings.Performance.DisableParticles=true Settings.Performance.LowerGraphics=true Settings.Performance.DisableShadows=true Settings.Performance.ReduceRenderDistance=true
    pcall(function()for _,obj in ipairs(Workspace:GetDescendants())do if obj:IsA("ParticleEmitter")or obj:IsA("Trail")or obj:IsA("Beam")then obj.Enabled=false end end settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 game:GetService("Lighting").GlobalShadows=false Workspace.StreamingEnabled=true Workspace.StreamingMinRadius=32 Workspace.StreamingTargetRadius=64 end)
    Notify("Performance","Semua boost diterapkan!",3)
end})
Tabs.Settings:AddButton({Title="Reset Performance Settings",Callback=function()
    Settings.Performance.DisableParticles=false Settings.Performance.LowerGraphics=false Settings.Performance.DisableShadows=false Settings.Performance.ReduceRenderDistance=false
    pcall(function()for _,obj in ipairs(Workspace:GetDescendants())do if obj:IsA("ParticleEmitter")or obj:IsA("Trail")or obj:IsA("Beam")then obj.Enabled=true end end settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic game:GetService("Lighting").GlobalShadows=true Workspace.StreamingEnabled=false end)
    Notify("Performance","Direset",2)
end})

Tabs.Settings:AddSection("SCRIPT CONTROLS")
Tabs.Settings:AddButton({Title="Unload Script",Callback=function()
    PerfMgr.StopAll()
    ZiaanESP.Disable()
    ConnMgr.ClearAll()
    RemoteCache.Clear()
    MapCache.Invalidate()
    if ParryRingFolder then ParryRingFolder:Destroy()end
    stopFly()
    if BubbleGui then BubbleGui:Destroy()end
    pcall(function()Window:Destroy()end)
    if getgenv then getgenv().NoMercyUnload=nil end
    Notify("Unloaded","Script unloaded - Goodbye!",2)
end})

-- ===== ADDON CONFIG =====
do local t0=os.clock() while not addonsReady and(os.clock()-t0)<5 do task.wait(0.1)end end
pcall(function()if InterfaceManager then InterfaceManager:SetLibrary(Fluent) InterfaceManager:SetFolder("NoMercyHub") InterfaceManager:BuildInterfaceSection(Tabs.Config)end end)
pcall(function()if SaveManager then SaveManager:SetLibrary(Fluent) SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({}) SaveManager:SetFolder("NoMercyHub/VioletDistrict") SaveManager:BuildConfigSection(Tabs.Config)end end)

Window:SelectTab(1)

-- ===== UNLOADER GLOBAL =====
if getgenv then
    getgenv().NoMercyUnload=function()
        PerfMgr.StopAll()
        ZiaanESP.Disable()
        ConnMgr.ClearAll()
        RemoteCache.Clear()
        MapCache.Invalidate()
        if ParryRingFolder then ParryRingFolder:Destroy()end
        stopFly()
        if BubbleGui then BubbleGui:Destroy()end
        pcall(function()Window:Destroy()end)
        getgenv().NoMercyUnload=nil
    end
end

Notify("NO MERCY x ZIAAN","Script dimuat dengan semua fitur!",4)
pcall(function()if SaveManager then SaveManager:LoadAutoloadConfig()end end)

-- ===== SCHEDULER UNTUK FITUR ZIAAN (Auto Attack, Destroy Pallets, dll) =====
PerfMgr.Add("ziaanAutoAttack",0.1,function()if KillerSettings.AutoAttack then ZiaanFeatures.AutoAttack()end end,false)
PerfMgr.Add("ziaanDoubleTap",0.05,function()if KillerSettings.DoubleTap then ZiaanFeatures.DoubleTap()end end,false)
PerfMgr.Add("ziaanDestroyPallets",0.2,function()if KillerSettings.DestroyPallets then ZiaanFeatures.DestroyPallets()end end,false)
PerfMgr.Add("ziaanAutoBreakGene",0.3,function()if KillerSettings.AutoBreakGene then ZiaanFeatures.AutoBreakGene()end end,false)
PerfMgr.Add("ziaanBlockVaults",0.15,function()if KillerSettings.BlockVaults then ZiaanFeatures.BlockVaults()end end,false)
PerfMgr.Add("ziaanAutoDropPallet",0.2,function()if SurvivorSettings.AutoDropPallet then ZiaanFeatures.AutoDropPallet()end end,false)
PerfMgr.Add("ziaanAutoVault",0.15,function()if SurvivorSettings.AutoVault then ZiaanFeatures.AutoVault()end end,false)
PerfMgr.Add("ziaanAutoPalletSlide",0.15,function()if SurvivorSettings.AutoPalletSlide then ZiaanFeatures.AutoPalletSlide()end end,false)

-- ===== ESP ZIAAN START =====
ZiaanESP.Refresh()

print("=== NO MERCY x ZIAANHUB ACTIVE ===")
