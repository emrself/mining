-- SYNOX HUB - MM2 FULL EDITION v5.0
-- Self-contained | All features | No external deps

-- ================================================================
-- SERVICES & CONFIG
-- ================================================================
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local TeleportService=game:GetService("TeleportService")
local HttpService=game:GetService("HttpService")
local RepStore=game:GetService("ReplicatedStorage")
local CollectionService=game:GetService("CollectionService")
local GuiService=game:GetService("GuiService")
local VirtualUser; pcall(function() VirtualUser=game:GetService("VirtualUser") end)

local LP=Players.LocalPlayer
if not LP then
    pcall(function() Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end)
    LP=Players.LocalPlayer
end
local Camera=workspace.CurrentCamera
local dead=false
local conns={}

local CONFIG={
    KeySystemEnabled=true,
    KeyCheckURL="https://raw.githubusercontent.com/emrself/mining/main/keys.txt",
    DiscordLink="https://discord.gg/hHQ97ATpR9",
    DefaultHotkey=Enum.KeyCode.RightControl,
}
local KEY_FOLDER="Synox"
local KEY_FILE=KEY_FOLDER.."/key.dat"

-- ================================================================
-- UNIVERSAL HTTP GET
-- ================================================================
local function fetchText(url)
    if typeof(game.HttpGet)=="function" then
        local s,r=pcall(function() return game:HttpGet(url) end)
        if s and type(r)=="string" and #r>0 then return r end
    end
    if typeof(httpget)=="function" then
        local s,r=pcall(function() return httpget(url) end)
        if s and type(r)=="string" and #r>0 then return r end
    end
    local req=(syn and syn.request) or (http and http.request) or http_request or request
    if typeof(req)=="function" then
        local s,r=pcall(function() return req({Url=url,Method="GET"}) end)
        if s and r and r.Body and type(r.Body)=="string" and #r.Body>0 then return r.Body end
    end
    return nil
end

-- ================================================================
-- KEY PERSISTENCE
local function ensureFolder() pcall(function() if typeof(isfolder)=="function" and not isfolder(KEY_FOLDER) and typeof(makefolder)=="function" then makefolder(KEY_FOLDER) end end) end
local function saveKey(k)
    pcall(function()
        if typeof(writefile)=="function" then
            local ok=pcall(function() ensureFolder(); writefile(KEY_FILE,k) end)
            if not ok then pcall(function() writefile("synox_key.dat",k) end) end
        end
    end)
end
local function loadSavedKey()
    local s,r=pcall(function()
        if typeof(isfile)=="function" and typeof(readfile)=="function" then
            if isfile(KEY_FILE) then return readfile(KEY_FILE):match("^%s*(.-)%s*$") end
            if isfile("synox_key.dat") then return readfile("synox_key.dat"):match("^%s*(.-)%s*$") end
        end
        return nil
    end)
    return s and r or nil
end
local function deleteSavedKey()
    pcall(function()
        if typeof(delfile)=="function" and typeof(isfile)=="function" then
            if isfile(KEY_FILE) then delfile(KEY_FILE) end
            if isfile("synox_key.dat") then delfile("synox_key.dat") end
        end
    end)
end
local function validateKey(ik)
    if not ik or ik=="" then return false end
    local resp=fetchText(CONFIG.KeyCheckURL)
    if not resp then return false end
    local LF=string.char(10)
    local CR=string.char(13)
    local pos=1
    while pos<=#resp do
        local nl=string.find(resp,LF,pos,true)
        local seg
        if nl then seg=string.sub(resp,pos,nl-1); pos=nl+1
        else seg=string.sub(resp,pos); pos=#resp+1 end
        local clean=string.gsub(seg,CR,"")
        local trimmed=string.match(clean,"^%s*(.-)%s*$")
        if trimmed and trimmed==ik then return true end
    end
    return false
end

-- ================================================================
-- THEME
-- ================================================================
local T={
    Bg=Color3.fromRGB(25,25,30), BgT=0.15,
    Outer=Color3.fromRGB(35,35,42), OuterT=0.45, OuterStroke=Color3.fromRGB(80,80,95), OuterStrokeT=0.3,
    Panel=Color3.fromRGB(30,30,38), PanelT=0.25, PanelStroke=Color3.fromRGB(60,60,75),
    Card=Color3.fromRGB(32,32,40), CardT=0.3, CardHov=Color3.fromRGB(38,38,48), CardStroke=Color3.fromRGB(55,55,68),
    TitleBg=Color3.fromRGB(20,20,26), TitleBgT=0.1,
    Accent=Color3.fromRGB(0,180,216), AccentGlow=Color3.fromRGB(0,200,240),
    TextPri=Color3.fromRGB(220,220,230), TextSec=Color3.fromRGB(150,150,165),
    TextMut=Color3.fromRGB(100,100,115), TextAcc=Color3.fromRGB(0,200,230),
    TabAct=Color3.fromRGB(40,40,50), TabActT=0.2,
    TabIn=Color3.fromRGB(30,30,38), TabInT=0.5, TabStroke=Color3.fromRGB(55,55,68),
    TogOn=Color3.fromRGB(0,180,216), TogOff=Color3.fromRGB(55,55,65),
    Knob=Color3.fromRGB(240,240,245),
    BtnExec=Color3.fromRGB(45,180,50), BtnExecH=Color3.fromRGB(55,210,60),
    BtnPri=Color3.fromRGB(0,160,195), BtnPriH=Color3.fromRGB(0,185,220),
    BtnDng=Color3.fromRGB(200,50,50),
    Green=Color3.fromRGB(50,205,50), Yellow=Color3.fromRGB(255,200,50), Red=Color3.fromRGB(200,50,50),
    Scroll=Color3.fromRGB(60,60,75), ThumbBg=Color3.fromRGB(230,230,235), InputBg=Color3.fromRGB(22,22,28),
    ChipBg=Color3.fromRGB(38,38,48), ChipHov=Color3.fromRGB(50,50,65),
    SliderBg=Color3.fromRGB(35,35,45), SliderFill=Color3.fromRGB(0,180,216),
    FT=Enum.Font.GothamBold, FH=Enum.Font.GothamSemibold, FB=Enum.Font.Gotham,
    TBH=36, TABH=38, CR=UDim.new(0,8), CRS=UDim.new(0,5), CRL=UDim.new(0,12),
}

-- ================================================================
-- GUI CONTAINER SELECTION & CLEANUP
-- ================================================================
local function getGuiContainer()
    if typeof(gethui)=="function" then
        local s,h=pcall(gethui)
        if s and h then return h end
    end
    if typeof(syn)=="table" and typeof(syn.protect_gui)=="function" then
        return game:GetService("CoreGui")
    end
    local s,cg=pcall(function() return game:GetService("CoreGui") end)
    if s and cg then
        local ok=pcall(function() local t=Instance.new("Folder"); t.Parent=cg; t:Destroy() end)
        if ok then return cg end
    end
    local pg=LP and (LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui",5))
    return pg or game:GetService("CoreGui")
end

local GuiContainer=getGuiContainer()

-- Cleanup previous instances
pcall(function()
    for _,c in ipairs(GuiContainer:GetChildren()) do
        if c.Name=="SynoxMM2" or c.Name=="SynoxESP" then
            pcall(function() c:Destroy() end)
        end
    end
end)

-- UI CORE
local SG=Instance.new("ScreenGui"); SG.Name="SynoxMM2"; SG.ResetOnSpawn=false; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset=true
if typeof(syn)=="table" and typeof(syn.protect_gui)=="function" then
    pcall(function() syn.protect_gui(SG) end)
end
SG.Parent=GuiContainer

local function C(c,p) local o=Instance.new(c); local par; for k,v in pairs(p or {}) do if k=="Parent" then par=v else o[k]=v end end; if par then o.Parent=par end; return o end
local function Corner(o,r) C("UICorner",{CornerRadius=r or T.CR,Parent=o}) end
local function Stroke(o,c,th,tr) local s=C("UIStroke",{Color=c or T.CardStroke,Thickness=th or 1,Transparency=tr or 0.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=o}); return s end
local function Pad(o,l,t,r,b) C("UIPadding",{PaddingLeft=UDim.new(0,l),PaddingTop=UDim.new(0,t),PaddingRight=UDim.new(0,r),PaddingBottom=UDim.new(0,b),Parent=o}) end
local function Grad(o,c1,c2,rot) C("UIGradient",{Color=ColorSequence.new(c1,c2),Rotation=rot or 90,Parent=o}) end
local function Tw(o,d,p) local tw=TS:Create(o,TweenInfo.new(d,Enum.EasingStyle.Quint),p); tw:Play(); return tw end
local function Ripple(btn,pos)
    pcall(function()
        local r=C("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,pos.X-btn.AbsolutePosition.X,0,pos.Y-btn.AbsolutePosition.Y),Size=UDim2.new(0,0,0,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.85,BorderSizePixel=0,ZIndex=btn.ZIndex+1,Parent=btn})
        Corner(r,UDim.new(1,0))
        local ms=math.max(btn.AbsoluteSize.X,btn.AbsoluteSize.Y)*2.5
        Tw(r,0.5,{Size=UDim2.new(0,ms,0,ms),BackgroundTransparency=1})
        task.delay(0.5,function() r:Destroy() end)
    end)
end

-- ================================================================
-- KEY NAMES
local KEY_NAMES={}
for _,v in ipairs(Enum.KeyCode:GetEnumItems()) do KEY_NAMES[v]=v.Name end
KEY_NAMES[Enum.KeyCode.LeftShift]="LShift"
KEY_NAMES[Enum.KeyCode.RightShift]="RShift"
KEY_NAMES[Enum.KeyCode.LeftControl]="LCtrl"
KEY_NAMES[Enum.KeyCode.RightControl]="RCtrl"
KEY_NAMES[Enum.KeyCode.LeftAlt]="LAlt"
KEY_NAMES[Enum.KeyCode.RightAlt]="RAlt"
KEY_NAMES[Enum.KeyCode.Space]="Space"
KEY_NAMES[Enum.KeyCode.Backspace]="BkSp"
KEY_NAMES[Enum.KeyCode.Return]="Enter"
KEY_NAMES[Enum.KeyCode.CapsLock]="Caps"
KEY_NAMES[Enum.KeyCode.RightBracket]="]"
KEY_NAMES[Enum.KeyCode.LeftBracket]="["

-- ================================================================
-- NOTIFICATION SYSTEM
-- ================================================================
local NF=C("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,300,0,0),BackgroundTransparency=1,Parent=SG})
C("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,Parent=NF})
local nSeq=0
local function Notify(title,msg,dur,typ)
    nSeq=nSeq+1; dur=dur or 3
    local ac=typ=="success" and T.Green or typ=="error" and T.Red or typ=="warning" and T.Yellow or T.Accent
    local nc=C("Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=nSeq,ClipsDescendants=true,Parent=NF}); Corner(nc,T.CRS); Stroke(nc,T.CardStroke,1,0.5)
    C("Frame",{Size=UDim2.new(0,3,0.7,0),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=ac,BorderSizePixel=0,Parent=nc})
    C("TextLabel",{Size=UDim2.new(1,-50,0,18),Position=UDim2.new(0,16,0,10),BackgroundTransparency=1,Text=title,TextColor3=T.TextPri,TextSize=14,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,Parent=nc})
    C("TextLabel",{Size=UDim2.new(1,-50,0,16),Position=UDim2.new(0,16,0,30),BackgroundTransparency=1,Text=msg,TextColor3=T.TextSec,TextSize=12,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=nc})
    local pb=C("Frame",{Size=UDim2.new(1,-20,0,3),AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-6),BackgroundColor3=T.SliderBg,BorderSizePixel=0,Parent=nc}); Corner(pb,UDim.new(1,0))
    local pf=C("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=ac,BorderSizePixel=0,Parent=pb}); Corner(pf,UDim.new(1,0))
    local xb=C("TextButton",{Size=UDim2.new(0,20,0,20),AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,8),BackgroundTransparency=1,Text="X",TextColor3=T.TextMut,TextSize=12,Font=T.FT,Parent=nc})
    nc.BackgroundTransparency=1; Tw(nc,0.3,{BackgroundTransparency=T.CardT})
    Tw(pf,dur,{Size=UDim2.new(0,0,1,0)})
    local closed=false
    local function cl() if closed then return end; closed=true; Tw(nc,0.25,{BackgroundTransparency=1}); task.delay(0.3,function() pcall(function() nc:Destroy() end) end) end
    xb.MouseButton1Click:Connect(cl); task.delay(dur+0.2,cl)
end

-- ================================================================
-- STATE TABLE
-- ================================================================
local MM2={
    -- ESP
    ESP_Enabled=false, ESP_Names=false, ESP_Roles=false, ESP_Chams=false, ESP_Fill=false,
    ESP_Skeleton=false, ESP_Tracers=false, ESP_3DBox=false, ESP_MaxDist=0,
    ESP_TracerFrom="Bottom", Coin_ESP=false, Gun_ESP=false, Gun_ESP_Dist=false, Trap_ESP=false,
    Footsteps=false,
    -- Combat
    Aimbot=false, Silent_Aim=false, Show_FOV=false, Aim_FOV=120,
    Auto_Kill=false, Gun_Walls=false, Knife_Walls=false, Instant_Knife=false,
    Auto_Grab_Gun=false,
    -- Movement
    Speed_Enabled=false, Speed_Value=16, Fly_Enabled=false, Fly_Speed=50,
    InfiniteJump=false, Noclip=false, JumpPower_Enabled=false, JumpPower_Value=50,
    UnlockCam=false, FOV_Value=70,
    -- Coins
    Auto_Collect_Coins=false, Collect_Speed=16,
    -- Fling
    Fling_Power=10000, Fling_Duration=1, Fling_Enabled=false,
    Auto_Fling_Murderer=false, Auto_Fling_Sheriff=false,
    -- Visual
    Fullbright=false, NoFog=false, FPS_Boost=false, Kill_Feed=false,
    -- Safety
    Anti_Trap=false, Anti_Fling=false, AntiAFK=true, Murderer_Alert=false,
    -- Runtime
    Murderer=nil, Sheriff=nil, Innocents={},
    tagOwners={}, snapAt=-10,
}

-- ================================================================
-- KEYBIND SYSTEM
-- ================================================================
local listeningBind=nil
local keybinds={}
local toggleCallbacks={}
local toggleStates={}
local toggleSetters={}

-- ================================================================
-- ROLE DETECTION (CollectionService + CRC)
-- ================================================================
local CRC; pcall(function() CRC=require(RepStore:WaitForChild("Modules",3):WaitForChild("CurrentRoundClient",3)) end)
local function roundData(plr) return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name] end
local function getHRP(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end

local function refreshTags()
    for _,tag in ipairs({"Weapon_Gun","Weapon_Knife"}) do
        local m=MM2.tagOwners[tag]; if m then table.clear(m) else m={}; MM2.tagOwners[tag]=m end
        for _,t in ipairs(CollectionService:GetTagged(tag)) do local p=t.Parent; if p then m[p]=true end end
    end
end
refreshTags()
local function playerHasTagged(plr,tag)
    local m=MM2.tagOwners[tag]; if not m then return false end
    local ch=plr.Character; if ch and m[ch] then return true end
    local bp=plr:FindFirstChildOfClass("Backpack"); if bp and m[bp] then return true end
    return false
end
local function charHasWeapon(ch,kind)
    for _,t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then
            if kind=="Gun" and (t.Name=="Gun" or t:FindFirstChild("Shoot") or t:FindFirstChild("GunClient")) then return true end
            if kind=="Knife" and (t.Name=="Knife" or t:FindFirstChild("Events") or t:FindFirstChild("KnifeClient")) then return true end
        end
    end
    return false
end
local function computeRole(plr)
    local d=roundData(plr); local r=d and d.Role
    if r=="Murderer" then return "Murderer" end
    if r=="Sheriff" or r=="Hero" then return r end
    local ch=plr.Character
    if playerHasTagged(plr,"Weapon_Gun") or (ch and charHasWeapon(ch,"Gun")) then return "Hero" end
    if playerHasTagged(plr,"Weapon_Knife") or (ch and charHasWeapon(ch,"Knife")) then return "Murderer" end
    return r or "Innocent"
end
local function computeAlive(plr)
    local d=roundData(plr); if d and d.Dead==true then return false end
    local ch=plr.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    return ch and hum and hum.Health>0 and getHRP(ch) and true or false
end
local roleCache,aliveCache,cacheStamp={},{},0
local function sweepCaches()
    local now=os.clock()
    if now-cacheStamp>0.08 then table.clear(roleCache); table.clear(aliveCache); cacheStamp=now; refreshTags() end
end
local function roleOf(plr) sweepCaches(); local v=roleCache[plr]; if v==nil then v=computeRole(plr); roleCache[plr]=v end; return v end
local function alive(plr) sweepCaches(); local v=aliveCache[plr]; if v==nil then v=computeAlive(plr); aliveCache[plr]=v end; return v end
local function myRole() return roleOf(LP) end
local function isGunRole(r) return r=="Sheriff" or r=="Hero" end
local function findMurderer() for _,p in ipairs(Players:GetPlayers()) do if roleOf(p)=="Murderer" then return p end end end
local function findWeapon(n) local ch=LP.Character; local bp=LP:FindFirstChildOfClass("Backpack"); return (ch and ch:FindFirstChild(n)) or (bp and bp:FindFirstChild(n)) end
local function equip(tool) local ch=LP.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid"); if tool and hum and tool.Parent~=ch then pcall(function() hum:EquipTool(tool) end) end end

-- ================================================================
-- ROLE COLORS
-- ================================================================
local ROLE_COLORS={Murderer=Color3.fromRGB(255,50,50),Sheriff=Color3.fromRGB(50,120,255),Hero=Color3.fromRGB(50,120,255),Innocent=Color3.fromRGB(0,220,120)}
local function roleColor(r) return ROLE_COLORS[r] or T.TextSec end

-- ================================================================
-- DRAWING / ESP SYSTEM
-- ================================================================
local hasDrawing=false
pcall(function() local probe=Drawing.new("Line"); probe:Remove(); hasDrawing=true end)

local EspGui=Instance.new("ScreenGui")
EspGui.Name="SynoxESP"
EspGui.ResetOnSpawn=false
EspGui.IgnoreGuiInset=false
EspGui.DisplayOrder=998
if typeof(syn)=="table" and typeof(syn.protect_gui)=="function" then pcall(function() syn.protect_gui(EspGui) end) end
EspGui.Parent=GuiContainer
local espObj={}
local coinHL,gunHL,trapHL={},{},{}

local function newLine(thickness)
    if hasDrawing then
        local l=Drawing.new("Line"); l.Thickness=thickness; l.Transparency=1; l.Visible=false; return l
    end
    local f=C("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,Visible=false,ZIndex=3,Parent=EspGui})
    return {_f=f,_thick=thickness,Visible=false,Color=Color3.new(1,1,1),Transparency=1,From=Vector2.new(0,0),To=Vector2.new(0,0),
        Remove=function(self) pcall(function() self._f:Destroy() end) end}
end
local function setLine(l,from,to,color,vis)
    if hasDrawing then l.From=from; l.To=to; l.Color=color; l.Visible=vis; return end
    l.Visible=vis; l._f.Visible=vis; l._f.BackgroundColor3=color
    if vis then
        local d=to-from; local mag=d.Magnitude
        l._f.Position=UDim2.fromOffset((from.X+to.X)*0.5,(from.Y+to.Y)*0.5)
        l._f.Size=UDim2.fromOffset(math.max(mag,1),math.max(l._thick,1))
        l._f.Rotation=math.deg(math.atan2(d.Y,d.X))
    end
end
local function removeLine(l) if l then pcall(function() l:Remove() end) end end

local function createESP(plr)
    if plr==LP or espObj[plr] then return end
    local e={}
    -- Billboard
    e.bb=C("BillboardGui",{AlwaysOnTop=true,Size=UDim2.new(4,0,5.5,0),StudsOffset=Vector3.new(0,0.5,0),ResetOnSpawn=false,Parent=nil})
    -- Box outline
    e.box=C("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Parent=e.bb})
    e.boxStroke=C("UIStroke",{Color=Color3.new(1,1,1),Thickness=1.5,Transparency=0.2,Parent=e.box})
    Corner(e.box,UDim.new(0,3))
    -- Fill
    e.fill=C("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.85,BorderSizePixel=0,Visible=false,Parent=e.bb})
    Corner(e.fill,UDim.new(0,3))
    -- Name label
    e.name=C("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,-18),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=13,Font=T.FH,TextStrokeTransparency=0.5,Visible=false,Parent=e.bb})
    -- Role label
    e.role=C("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,4),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=11,Font=T.FB,TextStrokeTransparency=0.5,Visible=false,Parent=e.bb})
    -- Distance label
    e.dist=C("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,18),BackgroundTransparency=1,TextColor3=T.TextMut,TextSize=10,Font=T.FB,TextStrokeTransparency=0.5,Visible=false,Parent=e.bb})
    -- Chams (Highlight)
    local hlOk,hlInst=pcall(function() return C("Highlight",{FillColor=Color3.new(1,1,1),FillTransparency=0.7,OutlineColor=Color3.new(1,1,1),OutlineTransparency=0.3,Enabled=false}) end)
    e.hl=hlOk and hlInst or nil
    -- Tracer line
    e.tracer=newLine(1.5)
    -- Skeleton lines (simplified: head-torso, torso-larm, torso-rarm, torso-lleg, torso-rleg)
    e.skel={}
    for i=1,5 do e.skel[i]=newLine(1) end
    espObj[plr]=e
end

local function colorESP(plr)
    local e=espObj[plr]; if not e then return end
    local r=roleOf(plr); local c=roleColor(r)
    e.boxStroke.Color=c; e.fill.BackgroundColor3=c; e.name.TextColor3=c; e.role.TextColor3=c
    e.role.Text=r; e.name.Text=plr.DisplayName
    if e.hl then e.hl.FillColor=c; e.hl.OutlineColor=c end
end

local function updateESP(plr)
    local e=espObj[plr]; if not e then return end
    local ch=plr.Character; local hrp=ch and getHRP(ch); local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    local show=MM2.ESP_Enabled and ch and hrp and hum and hum.Health>0
    -- Max distance check
    if show and MM2.ESP_MaxDist>0 then
        local myhrp=getHRP(LP.Character)
        if myhrp then local d=(myhrp.Position-hrp.Position).Magnitude; if d>MM2.ESP_MaxDist then show=false end end
    end
    if show then
        e.bb.Adornee=hrp; if not e.bb.Parent then e.bb.Parent=EspGui end
        colorESP(plr)
        e.box.Visible=true
        e.fill.Visible=MM2.ESP_Fill
        e.name.Visible=MM2.ESP_Names
        e.role.Visible=MM2.ESP_Roles
        e.dist.Visible=MM2.ESP_Names
        if MM2.ESP_Names then
            local myhrp=getHRP(LP.Character)
            if myhrp then e.dist.Text=math.floor((myhrp.Position-hrp.Position).Magnitude).."m" end
        end
        -- Chams
        if e.hl then
            e.hl.Enabled=MM2.ESP_Chams
            if MM2.ESP_Chams then e.hl.Adornee=ch; if not e.hl.Parent then e.hl.Parent=ch end end
        end
        -- Tracer
        if MM2.ESP_Tracers then
            local v,on=Camera:WorldToViewportPoint(hrp.Position)
            if on and v.Z>0 then
                local vp=Camera.ViewportSize
                local from
                if MM2.ESP_TracerFrom=="Top" then from=Vector2.new(vp.X/2,0)
                elseif MM2.ESP_TracerFrom=="Center" then from=Vector2.new(vp.X/2,vp.Y/2)
                else from=Vector2.new(vp.X/2,vp.Y) end
                local c=roleColor(roleOf(plr))
                setLine(e.tracer,from,Vector2.new(v.X,v.Y),c,true)
            else setLine(e.tracer,Vector2.new(0,0),Vector2.new(0,0),Color3.new(1,1,1),false) end
        else setLine(e.tracer,Vector2.new(0,0),Vector2.new(0,0),Color3.new(1,1,1),false) end
        -- Skeleton
        if MM2.ESP_Skeleton then
            local head=ch:FindFirstChild("Head")
            local torso=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
            local la=ch:FindFirstChild("LeftUpperArm") or ch:FindFirstChild("Left Arm")
            local ra=ch:FindFirstChild("RightUpperArm") or ch:FindFirstChild("Right Arm")
            local ll=ch:FindFirstChild("LeftUpperLeg") or ch:FindFirstChild("Left Leg")
            local rl=ch:FindFirstChild("RightUpperLeg") or ch:FindFirstChild("Right Leg")
            local c=roleColor(roleOf(plr))
            local function skelLine(idx,p1,p2)
                if p1 and p2 then
                    local v1,o1=Camera:WorldToViewportPoint(p1.Position)
                    local v2,o2=Camera:WorldToViewportPoint(p2.Position)
                    if o1 and o2 and v1.Z>0 and v2.Z>0 then
                        setLine(e.skel[idx],Vector2.new(v1.X,v1.Y),Vector2.new(v2.X,v2.Y),c,true); return
                    end
                end
                setLine(e.skel[idx],Vector2.new(0,0),Vector2.new(0,0),c,false)
            end
            skelLine(1,head,torso); skelLine(2,torso,la); skelLine(3,torso,ra); skelLine(4,torso,ll); skelLine(5,torso,rl)
        else for i=1,5 do setLine(e.skel[i],Vector2.new(0,0),Vector2.new(0,0),Color3.new(1,1,1),false) end end
    else
        e.bb.Adornee=nil; if e.bb.Parent then e.bb.Parent=nil end
        if e.hl then e.hl.Enabled=false; if e.hl.Parent then e.hl.Parent=nil end end
        setLine(e.tracer,Vector2.new(0,0),Vector2.new(0,0),Color3.new(1,1,1),false)
        for i=1,5 do setLine(e.skel[i],Vector2.new(0,0),Vector2.new(0,0),Color3.new(1,1,1),false) end
    end
end

local function ClearESP()
    for plr,e in pairs(espObj) do
        pcall(function() e.bb:Destroy() end); if e.hl then pcall(function() e.hl:Destroy() end) end
        removeLine(e.tracer); for i=1,5 do removeLine(e.skel[i]) end
    end
    table.clear(espObj)
end
local function RefESP()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then createESP(p) end end
end

-- Coin/Gun/Trap ESP
local function RefCoin()
    for _,h in ipairs(coinHL) do pcall(function() h:Destroy() end) end; table.clear(coinHL)
    if not MM2.Coin_ESP then return end
    for _,o in ipairs(workspace:GetDescendants()) do
        if (o.Name=="Coin" or o.Name=="CoinVisual") and (o:IsA("BasePart") or o:IsA("MeshPart")) then
            pcall(function()
                local h=C("Highlight",{FillColor=Color3.fromRGB(255,215,0),FillTransparency=0.5,OutlineColor=Color3.fromRGB(255,215,0),OutlineTransparency=0.3,Adornee=o,Parent=o})
                table.insert(coinHL,h)
            end)
        end
    end
end
local function RefGun()
    for _,h in ipairs(gunHL) do pcall(function() h:Destroy() end) end; table.clear(gunHL)
    if not MM2.Gun_ESP then return end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Tool") and (o.Name=="Gun" or o:FindFirstChild("Shoot") or o:FindFirstChild("GunClient")) and o.Parent==workspace then
            pcall(function()
                local h=C("Highlight",{FillColor=Color3.fromRGB(50,120,255),FillTransparency=0.5,OutlineColor=Color3.fromRGB(50,120,255),OutlineTransparency=0.3,Adornee=o,Parent=o})
                table.insert(gunHL,h)
            end)
            if MM2.Gun_ESP_Dist then
                pcall(function()
                    local bb=C("BillboardGui",{AlwaysOnTop=true,Size=UDim2.new(0,100,0,20),StudsOffset=Vector3.new(0,3,0),Adornee=o:FindFirstChild("Handle") or o,Parent=o})
                    local dl=C("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="GUN",TextColor3=Color3.fromRGB(50,120,255),TextSize=14,Font=T.FT,TextStrokeTransparency=0.4,Parent=bb})
                    table.insert(gunHL,bb)
                end)
            end
        end
    end
end
local function RefTrap()
    for _,h in ipairs(trapHL) do pcall(function() h:Destroy() end) end; table.clear(trapHL)
    if not MM2.Trap_ESP then return end
    for _,o in ipairs(workspace:GetDescendants()) do
        if (o.Name:lower():find("trap") or o.Name:lower():find("bear")) and o:IsA("BasePart") then
            pcall(function()
                local h=C("Highlight",{FillColor=Color3.fromRGB(255,100,0),FillTransparency=0.5,OutlineColor=Color3.fromRGB(255,100,0),OutlineTransparency=0.3,Adornee=o,Parent=o})
                table.insert(trapHL,h)
            end)
        end
    end
end
local function ClearCoin() for _,h in ipairs(coinHL) do pcall(function() h:Destroy() end) end; table.clear(coinHL) end
local function ClearGun() for _,h in ipairs(gunHL) do pcall(function() h:Destroy() end) end; table.clear(gunHL) end
local function ClearTrap() for _,h in ipairs(trapHL) do pcall(function() h:Destroy() end) end; table.clear(trapHL) end

-- ================================================================
-- COMBAT SYSTEM
-- ================================================================
local snapping=false
local KNIFE_PARTS={"HumanoidRootPart","UpperTorso","LowerTorso","Torso","Head"}

local function knifeKill(ev,targetChar)
    if not (ev and targetChar) then return end
    local ht=ev:FindFirstChild("HandleTouched"); local ks=ev:FindFirstChild("KnifeStabbed")
    if not ht then return end; if ks then ks:FireServer() end
    for _,pn in ipairs(KNIFE_PARTS) do local part=targetChar:FindFirstChild(pn); if part then ht:FireServer(part); return end end
end

local function aimPointFor(ch)
    local part=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or getHRP(ch)
    return part and part.Position
end

local function snapShot(target)
    if snapping then return false end
    local gun=findWeapon("Gun"); if not gun then return false end
    local shoot=gun:FindFirstChild("Shoot"); if not shoot then return false end
    local myHrp=getHRP(LP.Character); local tChar=target and target.Character; local tHrp=tChar and getHRP(tChar)
    if not (myHrp and tHrp) then return false end
    if os.clock()-MM2.snapAt<3.25 then return false end
    snapping=true
    local home=myHrp.CFrame; local homeVel=myHrp.AssemblyLinearVelocity
    local fired=false
    pcall(function()
        equip(gun)
        task.wait(0.15)
        local aim=aimPointFor(tChar)
        if not aim then snapping=false; return end
        local side=(home.Position-aim); side=Vector3.new(side.X,0,side.Z)
        if side.Magnitude<0.5 then side=tHrp.CFrame.LookVector; side=Vector3.new(side.X,0,side.Z) end
        if side.Magnitude<0.5 then side=Vector3.new(0,0,1) end; side=side.Unit
        local snapPos=aim+side*5
        myHrp.CFrame=CFrame.new(snapPos,aim); myHrp.AssemblyLinearVelocity=Vector3.zero
        task.wait(0.1)
        local origin=myHrp.CFrame
        local att=myHrp:FindFirstChild("GunRaycastAttachment")
        if att then origin=att.WorldCFrame end
        local chest=aimPointFor(tChar) or aim
        shoot:FireServer(origin,CFrame.new(chest)); MM2.snapAt=os.clock(); fired=true
        task.wait(0.2)
    end)
    RS.Heartbeat:Wait()
    local h=getHRP(LP.Character); if h then h.CFrame=home; h.AssemblyLinearVelocity=homeVel; h.AssemblyAngularVelocity=Vector3.zero end
    snapping=false; return fired
end

local function fovTarget()
    local mr=myRole(); local center=UIS:GetMouseLocation(); local best,bd
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) then
            local pr=roleOf(p); local isEnemy=(mr=="Murderer") or (isGunRole(mr) and pr=="Murderer") or (pr=="Murderer")
            if isEnemy then
                local hrp=getHRP(p.Character)
                if hrp then local v,on=Camera:WorldToViewportPoint(hrp.Position)
                    if on and v.Z>0 then local d=(Vector2.new(v.X,v.Y)-center).Magnitude
                        if d<=MM2.Aim_FOV and (not bd or d<bd) then bd,best=d,p end
                    end
                end
            end
        end
    end
    return best
end

-- FOV Circle
local FovCircle=C("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(240,240),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,Parent=EspGui})
C("UICorner",{CornerRadius=UDim.new(1,0),Parent=FovCircle}); C("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Transparency=0.25,Parent=FovCircle})

-- Silent Aim Hook
local silentAimTarget
pcall(function()
    if typeof(hookmetamethod)~="function" then return end
    local oldNC; oldNC=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
        if dead then return oldNC(self,...) end
        local method=getnamecallmethod()
        if method=="FireServer" and MM2.Silent_Aim then
            local name=self.Name
            if name=="Shoot" or name=="GunFired" then
                local tgt=fovTarget()
                if tgt then
                    local ch=tgt.Character; local hrp=ch and getHRP(ch)
                    if hrp then
                        local args={...}
                        if #args>=2 then args[2]=CFrame.new(hrp.Position); return oldNC(self,unpack(args)) end
                    end
                end
            end
        end
        return oldNC(self,...)
    end))
end)

-- ================================================================
-- GRAB GUN
-- ================================================================
local function GrabGun()
    local myHrp=getHRP(LP.Character); if not myHrp then return end
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Tool") and (o.Name=="Gun" or o:FindFirstChild("Shoot")) and o.Parent==workspace then
            local h=o:FindFirstChild("Handle"); if h then
                local home=myHrp.CFrame; myHrp.CFrame=h.CFrame; task.wait(0.15)
                pcall(function() LP.Character.Humanoid:EquipTool(o) end); task.wait(0.1)
                myHrp.CFrame=home
                Notify("Auto Grab","Grabbed the gun!",2,"success"); return
            end
        end
    end
end

-- ================================================================
-- FLING SYSTEM
-- ================================================================
local function FlingPlayer(target)
    local ch=LP.Character; if not ch then return end
    local hrp=getHRP(ch); local hum=ch:FindFirstChildOfClass("Humanoid"); if not (hrp and hum) then return end
    local tch=target.Character; local thrp=tch and getHRP(tch); if not thrp then return end
    local home=hrp.CFrame
    local bav=C("BodyAngularVelocity",{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),AngularVelocity=Vector3.new(0,MM2.Fling_Power,0),P=math.huge,Name="SynoxFling",Parent=hrp})
    local t0=os.clock()
    while os.clock()-t0<MM2.Fling_Duration and not dead do
        local th=getHRP(target.Character); if not th then break end
        hrp.CFrame=th.CFrame; hrp.AssemblyLinearVelocity=Vector3.zero
        RS.Heartbeat:Wait()
    end
    pcall(function() bav:Destroy() end)
    local h2=getHRP(LP.Character); if h2 then h2.CFrame=home; h2.AssemblyLinearVelocity=Vector3.zero; h2.AssemblyAngularVelocity=Vector3.zero end
end
local function FlingAll()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and alive(p) then FlingPlayer(p) end end
end

-- ================================================================
-- MOVEMENT SYSTEM
-- ================================================================
local flyBV,flyBG
local function EnableFly()
    local ch=LP.Character; if not ch then return end
    local hrp=getHRP(ch); if not hrp then return end
    flyBV=C("BodyVelocity",{MaxForce=Vector3.new(math.huge,math.huge,math.huge),Velocity=Vector3.zero,Name="SynoxFly",Parent=hrp})
    flyBG=C("BodyGyro",{MaxTorque=Vector3.new(math.huge,math.huge,math.huge),D=200,P=10000,Name="SynoxFlyGyro",Parent=hrp})
end
local function DisableFly()
    pcall(function() if flyBV then flyBV:Destroy(); flyBV=nil end end)
    pcall(function() if flyBG then flyBG:Destroy(); flyBG=nil end end)
end
local function UpdFly()
    if not MM2.Fly_Enabled then return end
    local ch=LP.Character; if not ch then return end
    local hrp=getHRP(ch); if not hrp then return end
    if not flyBV or not flyBV.Parent then EnableFly() end
    if flyBG then flyBG.CFrame=Camera.CFrame end
    local dir=Vector3.zero; local cf=Camera.CFrame
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
    if dir.Magnitude>0 then dir=dir.Unit end
    if flyBV then flyBV.Velocity=dir*MM2.Fly_Speed end
end

-- ================================================================
-- VISUAL SYSTEM
-- ================================================================
local ogLighting={}
local function TogFull(on)
    if on then
        ogLighting.Ambient=Lighting.Ambient; ogLighting.Brightness=Lighting.Brightness; ogLighting.OutdoorAmbient=Lighting.OutdoorAmbient
        Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=2; Lighting.OutdoorAmbient=Color3.new(1,1,1)
    else
        if ogLighting.Ambient then Lighting.Ambient=ogLighting.Ambient; Lighting.Brightness=ogLighting.Brightness; Lighting.OutdoorAmbient=ogLighting.OutdoorAmbient end
    end
end
local ogFog={}
local function TogFog(on)
    if on then
        ogFog.Start=Lighting.FogStart; ogFog.End=Lighting.FogEnd; ogFog.Color=Lighting.FogColor
        Lighting.FogStart=1e9; Lighting.FogEnd=1e10
    else
        if ogFog.Start then Lighting.FogStart=ogFog.Start; Lighting.FogEnd=ogFog.End; Lighting.FogColor=ogFog.Color end
    end
end
local function FPSBoost()
    if MM2.FPS_Boost then
        for _,v in ipairs(workspace:GetDescendants()) do
            pcall(function() if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end end)
            pcall(function() if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end end)
            pcall(function() if v:IsA("MeshPart") then v.TextureID="" end end)
        end
        for _,v in ipairs(Lighting:GetDescendants()) do pcall(function() if v:IsA("PostEffect") then v.Enabled=false end end) end
        Notify("FPS Boost","Textures stripped",3,"success")
    end
end

-- ================================================================
-- KILL FEED
-- ================================================================
local kfPlayers={}
local function initKillFeed()
    for _,p in ipairs(Players:GetPlayers()) do kfPlayers[p]=alive(p) end
end
local function checkKillFeed()
    if not MM2.Kill_Feed then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local now=alive(p); local was=kfPlayers[p]
            if was==true and now==false then
                local killer=findMurderer()
                local kn=killer and killer.DisplayName or "Unknown"
                Notify("Kill Feed",p.DisplayName.." was killed by "..kn,4,"error")
            end
            kfPlayers[p]=now
        end
    end
end

-- ================================================================
-- GAME LOOPS
-- ================================================================
table.insert(conns, RS.Heartbeat:Connect(function()
    if dead then return end
    -- Aimbot
    if MM2.Aimbot then
        local t=fovTarget()
        if t then local th=t.Character and (t.Character:FindFirstChild("Head") or getHRP(t.Character))
            if th then Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,th.Position),0.45) end
        end
    end
    -- FOV Circle
    if MM2.Show_FOV and (MM2.Aimbot or MM2.Silent_Aim) then
        FovCircle.Visible=true; FovCircle.Size=UDim2.fromOffset(MM2.Aim_FOV*2,MM2.Aim_FOV*2)
        local mp=UIS:GetMouseLocation(); local ins=GuiService:GetGuiInset()
        FovCircle.Position=UDim2.fromOffset(mp.X-ins.X,mp.Y-ins.Y)
    else FovCircle.Visible=false end
    -- Update all ESP
    for plr,_ in pairs(espObj) do updateESP(plr) end
    -- Fly
    UpdFly()
    -- Speed
    if MM2.Speed_Enabled then local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=MM2.Speed_Value end end end
    -- Noclip
    if MM2.Noclip then local c=LP.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end
    -- JumpPower
    if MM2.JumpPower_Enabled then local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=MM2.JumpPower_Value end end end
    -- Unlock Camera
    if MM2.UnlockCam then Camera.CameraType=Enum.CameraType.Custom; pcall(function() LP.CameraMaxZoomDistance=10000 end) end
    -- FOV
    Camera.FieldOfView=MM2.FOV_Value
    -- Anti-Fling
    if MM2.Anti_Fling then local c=LP.Character; if c then local h=getHRP(c); if h then if h.Velocity.Magnitude>200 then h.Velocity=Vector3.zero end; for _,v in ipairs(h:GetChildren()) do if (v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("BodyForce")) and v.Name~="SynoxFly" and v.Name~="SynoxFlyGyro" then v:Destroy() end end end end end
    -- Anti-Trap
    if MM2.Anti_Trap then local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then if h.WalkSpeed<16 and not MM2.Speed_Enabled then h.WalkSpeed=16 end; if h.JumpPower<50 and not MM2.JumpPower_Enabled then h.JumpPower=50 end end end end
    -- Kill Feed
    checkKillFeed()
end))

table.insert(conns, UIS.JumpRequest:Connect(function() if MM2.InfiniteJump then local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end end))
table.insert(conns, LP.Idled:Connect(function() if MM2.AntiAFK then pcall(function() VirtualUser:Button2Down(Vector2.new(0,0),Camera.CFrame); task.wait(1); VirtualUser:Button2Up(Vector2.new(0,0),Camera.CFrame) end) end end))

-- Background tasks
task.spawn(function() while not dead do if MM2.Auto_Collect_Coins then local c=LP.Character; local h=c and getHRP(c); if h then for _,o in ipairs(workspace:GetDescendants()) do if (o.Name=="Coin" or o.Name=="CoinVisual") and (o:IsA("BasePart") or o:IsA("MeshPart")) and o:IsDescendantOf(workspace) then local d=(h.Position-o.Position).Magnitude; if d<250 then local op=h.CFrame; h.CFrame=o.CFrame; task.wait(1/MM2.Collect_Speed); h.CFrame=op; task.wait(1/MM2.Collect_Speed) end end end end end; task.wait(0.5) end end)
task.spawn(function() while not dead do if MM2.Murderer_Alert and findMurderer() then local m=findMurderer(); local mh=LP.Character and getHRP(LP.Character); local kh=m and m.Character and getHRP(m.Character); if mh and kh then local d=(mh.Position-kh.Position).Magnitude; if d<30 then Notify("DANGER","Murderer ("..m.DisplayName..") "..math.floor(d).."m away!",2,"error") end end end; task.wait(3) end end)
task.spawn(function() while not dead do if MM2.Auto_Fling_Murderer then local m=findMurderer(); if m and m~=LP and alive(m) then FlingPlayer(m) end end; task.wait(2) end end)
task.spawn(function() while not dead do if MM2.Auto_Fling_Sheriff then for _,p in ipairs(Players:GetPlayers()) do if p~=LP and alive(p) and isGunRole(roleOf(p)) then FlingPlayer(p); break end end end; task.wait(2) end end)
task.spawn(function() while not dead do if MM2.Auto_Grab_Gun then GrabGun() end; task.wait(1.5) end end)
task.spawn(function() while not dead do
    if MM2.Auto_Kill then
        local mr=myRole()
        if mr=="Murderer" then
            local knife=findWeapon("Knife"); local ev=knife and knife:FindFirstChild("Events")
            if ev then equip(knife)
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=LP and alive(p) and MM2.Auto_Kill then knifeKill(ev,p.Character) end
                end
            end
            task.wait(0.05)
        elseif isGunRole(mr) then
            local m=findMurderer(); if m and alive(m) then
                if MM2.Gun_Walls then snapShot(m) else
                    local gun=findWeapon("Gun"); if gun then local shoot=gun:FindFirstChild("Shoot"); if shoot then
                        equip(gun); local hrp=getHRP(LP.Character); local thrp=getHRP(m.Character)
                        if hrp and thrp and os.clock()-MM2.snapAt>3.25 then
                            local att=hrp:FindFirstChild("GunRaycastAttachment")
                            local origin=att and att.WorldCFrame or hrp.CFrame
                            shoot:FireServer(origin,CFrame.new(thrp.Position)); MM2.snapAt=os.clock()
                        end
                    end end
                end
            end
            task.wait(0.05)
        else task.wait(0.1) end
    else task.wait(0.08) end
end end)

-- ESP refresh loops
table.insert(conns, Players.PlayerAdded:Connect(function() task.wait(2); if MM2.ESP_Enabled then RefESP() end end))
table.insert(conns, Players.PlayerRemoving:Connect(function(p) if espObj[p] then local e=espObj[p]; pcall(function() e.bb:Destroy() end); pcall(function() e.hl:Destroy() end); removeLine(e.tracer); for i=1,5 do removeLine(e.skel[i]) end; espObj[p]=nil end end))
table.insert(conns, LP.CharacterAdded:Connect(function() task.wait(2); if MM2.ESP_Enabled then RefESP() end; if MM2.Coin_ESP then RefCoin() end; if MM2.Gun_ESP then RefGun() end; if MM2.Trap_ESP then RefTrap() end; if MM2.Fullbright then TogFull(true) end; if MM2.NoFog then TogFog(true) end; initKillFeed() end))
task.spawn(function() while not dead do if MM2.ESP_Enabled then RefESP() end; if MM2.Coin_ESP then RefCoin() end; if MM2.Gun_ESP then RefGun() end; if MM2.Trap_ESP then RefTrap() end; task.wait(5) end end)
initKillFeed()

-- ================================================================
-- SERVER HOP / REJOIN
-- ================================================================
local function rejoin() Notify("SYNOX","Rejoining...",2,"info"); pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end) end
local function serverHop()
    Notify("SYNOX","Finding server...",2,"info")
    task.spawn(function()
        local ok,res=pcall(function() return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100") end)
        if ok then
            local ok2,d=pcall(function() return HttpService:JSONDecode(res) end)
            if ok2 and d and d.data then
                for _,sv in ipairs(d.data) do
                    if sv.id and sv.id~=game.JobId and (sv.maxPlayers or 0)-(sv.playing or 0)>=1 then
                        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,sv.id,LP) end); return
                    end
                end
            end
        end
        Notify("SYNOX","No servers found, trying fallback...",3,"warning")
        pcall(function() TeleportService:Teleport(game.PlaceId,LP) end)
    end)
end

-- ================================================================
-- UI CONSTRUCTION
-- ================================================================
local function showKeySystem(onOK)
    if not CONFIG.KeySystemEnabled then onOK(); return end
    local saved=loadSavedKey()
    if saved and saved~="" then
        local valid=validateKey(saved)
        if valid then Notify("SYNOX HUB","Key verified, loading hub...",2,"success"); onOK(); return
        else deleteSavedKey(); Notify("SYNOX HUB","Key changed on server, enter new key.",3,"warning") end
    end

    local KO=C("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(5,5,8),BackgroundTransparency=0.08,BorderSizePixel=0,ZIndex=100,Parent=SG})
    local KOut=C("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,440,0,400),BackgroundColor3=T.Outer,BackgroundTransparency=T.OuterT,BorderSizePixel=0,ZIndex=101,ClipsDescendants=true,Parent=KO})
    Corner(KOut,T.CRL); Stroke(KOut,T.OuterStroke,1.5,T.OuterStrokeT)
    local KP=C("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(1,-12,1,-12),BackgroundColor3=T.Bg,BackgroundTransparency=T.BgT,BorderSizePixel=0,ZIndex=102,ClipsDescendants=true,Parent=KOut})
    Corner(KP,T.CR); Stroke(KP,T.PanelStroke,1,0.45)
    local KTB=C("Frame",{Size=UDim2.new(1,0,0,T.TBH),BackgroundColor3=T.TitleBg,BackgroundTransparency=T.TitleBgT,BorderSizePixel=0,ZIndex=110,Parent=KP}); Corner(KTB,T.CR)
    C("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=T.TitleBg,BackgroundTransparency=T.TitleBgT,BorderSizePixel=0,ZIndex=110,Parent=KTB})
    C("TextLabel",{Size=UDim2.new(0.8,0,1,0),Position=UDim2.new(0,18,0,0),BackgroundTransparency=1,Text="SYNOX HUB - KEY SYSTEM",TextColor3=T.TextPri,TextSize=17,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=111,Parent=KTB})
    C("Frame",{Size=UDim2.new(0,80,0,2),Position=UDim2.new(0,18,1,-2),BackgroundColor3=T.Accent,BackgroundTransparency=0.3,BorderSizePixel=0,ZIndex=112,Parent=KTB})
    local KGl=C("Frame",{Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,0,T.TBH),BackgroundColor3=T.Accent,BackgroundTransparency=0.55,BorderSizePixel=0,ZIndex=105,Parent=KP}); Grad(KGl,T.AccentGlow,Color3.new(0,0,0),0)
    local KC=C("Frame",{Size=UDim2.new(1,-40,1,-(T.TBH+24)),Position=UDim2.new(0,20,0,T.TBH+12),BackgroundTransparency=1,ZIndex=103,Parent=KP})
    local lr=C("Frame",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(0,64,0,64),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=T.Accent,BackgroundTransparency=0.75,BorderSizePixel=0,ZIndex=104,Parent=KC}); Corner(lr,UDim.new(1,0)); Stroke(lr,T.Accent,2,0.25)
    C("TextLabel",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(1,0,1,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1,Text="KEY",TextColor3=T.TextAcc,TextSize=18,Font=T.FT,ZIndex=105,Parent=lr})
    C("TextLabel",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(1,0,0,24),Position=UDim2.new(0.5,0,0,72),BackgroundTransparency=1,Text="Key Verification Required",TextColor3=T.TextPri,TextSize=18,Font=T.FT,ZIndex=104,Parent=KC})
    C("TextLabel",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(1,0,0,18),Position=UDim2.new(0.5,0,0,100),BackgroundTransparency=1,Text="Get your key from our Discord server",TextColor3=T.TextMut,TextSize=13,Font=T.FB,ZIndex=104,Parent=KC})
    local KIC=C("Frame",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(1,0,0,42),Position=UDim2.new(0.5,0,0,128),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,ZIndex=104,Parent=KC}); Corner(KIC,T.CRS)
    local kSt=Stroke(KIC,T.CardStroke,1.5,0.35)
    local KIn=C("TextBox",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="",PlaceholderText="Enter your key here...",TextColor3=T.TextPri,PlaceholderColor3=T.TextMut,TextSize=15,Font=T.FB,ClearTextOnFocus=false,ZIndex=105,Parent=KIC})
    local VBtn=C("TextButton",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(1,0,0,40),Position=UDim2.new(0.5,0,0,182),BackgroundColor3=T.BtnExec,BorderSizePixel=0,Text="✓  Verify Key",TextColor3=Color3.new(1,1,1),TextSize=15,Font=T.FT,AutoButtonColor=false,ZIndex=104,Parent=KC}); Corner(VBtn,T.CRS)
    VBtn.MouseEnter:Connect(function() Tw(VBtn,0.2,{BackgroundColor3=T.BtnExecH}) end)
    VBtn.MouseLeave:Connect(function() Tw(VBtn,0.2,{BackgroundColor3=T.BtnExec}) end)

    local DBtn=C("TextButton",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(1,0,0,36),Position=UDim2.new(0.5,0,0,232),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,Text="🔗  Get Key (Discord)",TextColor3=T.TextAcc,TextSize=13,Font=T.FH,AutoButtonColor=false,ZIndex=104,Parent=KC}); Corner(DBtn,T.CRS); Stroke(DBtn,T.Accent,1,0.5)
    DBtn.MouseEnter:Connect(function() Tw(DBtn,0.2,{BackgroundColor3=T.CardHov,BackgroundTransparency=0.15}) end)
    DBtn.MouseLeave:Connect(function() Tw(DBtn,0.2,{BackgroundColor3=T.Card,BackgroundTransparency=T.CardT}) end)

    local KSt=C("TextLabel",{AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(1,0,0,16),Position=UDim2.new(0.5,0,0,276),BackgroundTransparency=1,Text="",TextColor3=T.TextMut,TextSize=12,Font=T.FB,ZIndex=104,Parent=KC})
    DBtn.MouseButton1Click:Connect(function()
        Ripple(DBtn,Vector2.new(DBtn.AbsolutePosition.X+DBtn.AbsoluteSize.X/2,DBtn.AbsolutePosition.Y+DBtn.AbsoluteSize.Y/2))
        pcall(function() setclipboard(CONFIG.DiscordLink) end)
        KSt.TextColor3=T.Accent
        KSt.Text="Discord link copied to clipboard!"
    end)
    local function shake() Tw(KIC,0.06,{Position=UDim2.new(0.5,10,0,128)}); task.delay(0.06,function() Tw(KIC,0.06,{Position=UDim2.new(0.5,-10,0,128)}) end); task.delay(0.12,function() Tw(KIC,0.06,{Position=UDim2.new(0.5,6,0,128)}) end); task.delay(0.18,function() Tw(KIC,0.08,{Position=UDim2.new(0.5,0,0,128)}) end) end
    local function tryV()
        local ik=KIn.Text:match("^%s*(.-)%s*$"); if ik=="" then KSt.TextColor3=T.Red; KSt.Text="Please enter a key!"; shake(); return end
        VBtn.Text="Verifying..."; Tw(VBtn,0.15,{BackgroundColor3=T.Yellow}); KSt.TextColor3=T.TextAcc; KSt.Text="Checking..."
        task.delay(0.6,function()
            if validateKey(ik) then
                saveKey(ik)
                KSt.TextColor3=T.Green; KSt.Text="Key verified! Loading..."; VBtn.Text="✓ Verified!"; Tw(VBtn,0.2,{BackgroundColor3=T.Green})
                task.delay(1,function() Tw(KOut,0.45,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}); Tw(KO,0.5,{BackgroundTransparency=1}); task.delay(0.55,function() KO:Destroy(); onOK() end) end)
            else KSt.TextColor3=T.Red; KSt.Text="Invalid key!"; VBtn.Text="Verify Key"; Tw(VBtn,0.15,{BackgroundColor3=T.BtnExec}); Tw(kSt,0.15,{Color=T.Red}); shake(); task.delay(1,function() Tw(kSt,0.3,{Color=T.CardStroke}) end) end
        end)
    end
    VBtn.MouseButton1Click:Connect(function()
        Ripple(VBtn,Vector2.new(VBtn.AbsolutePosition.X+VBtn.AbsoluteSize.X/2,VBtn.AbsolutePosition.Y+VBtn.AbsoluteSize.Y/2))
        tryV()
    end)
    KIn.FocusLost:Connect(function(ep) if ep then tryV() end end)
    KOut.Size=UDim2.new(0,440,0,400)
    KOut.BackgroundTransparency=T.OuterT
    KO.BackgroundTransparency=0.08
end

-- ================================================================
-- MAIN UI BUILD
-- ================================================================
local OF,MF,XB -- outer, main, close btn
local function buildUI()
    -- Outer Frame (Transparent glass shell)
    OF=C("Frame",{Name="Outer",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,680,0,520),BackgroundColor3=T.Outer,BackgroundTransparency=T.OuterT,BorderSizePixel=0,ZIndex=10,ClipsDescendants=true,Parent=SG})
    Corner(OF,T.CRL); Stroke(OF,T.OuterStroke,1.5,T.OuterStrokeT)

    -- Main Frame
    MF=C("Frame",{Name="Main",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(1,-12,1,-12),BackgroundColor3=T.Bg,BackgroundTransparency=T.BgT,BorderSizePixel=0,ZIndex=11,ClipsDescendants=true,Parent=OF})
    Corner(MF,T.CR); Stroke(MF,T.PanelStroke,1,0.5)

    -- Accent glow line
    local gl=C("Frame",{Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,0,T.TBH),BackgroundColor3=T.Accent,BackgroundTransparency=0.6,BorderSizePixel=0,ZIndex=15,Parent=MF})
    Grad(gl,T.AccentGlow,Color3.new(0,0,0),0)

    -- Title Bar
    local TB=C("Frame",{Name="TitleBar",Size=UDim2.new(1,0,0,T.TBH),BackgroundColor3=T.TitleBg,BackgroundTransparency=T.TitleBgT,BorderSizePixel=0,ZIndex=20,Parent=MF})
    Corner(TB,T.CR)
    C("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=T.TitleBg,BackgroundTransparency=T.TitleBgT,BorderSizePixel=0,ZIndex=20,Parent=TB})

    C("TextLabel",{Size=UDim2.new(0.6,0,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text="SYNOX HUB  •  MM2",TextColor3=T.TextPri,TextSize=15,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21,Parent=TB})
    C("Frame",{Size=UDim2.new(0,60,0,2),Position=UDim2.new(0,14,1,-2),BackgroundColor3=T.Accent,BackgroundTransparency=0.3,BorderSizePixel=0,ZIndex=22,Parent=TB})

    -- Close & Minimize buttons
    XB=C("TextButton",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-38,0.5,-15),BackgroundColor3=Color3.fromRGB(45,45,55),BackgroundTransparency=0.5,Text="X",TextColor3=T.TextSec,TextSize=14,Font=T.FB,BorderSizePixel=0,ZIndex=22,AutoButtonColor=false,Parent=TB})
    Corner(XB,T.CRS)
    local MB=C("TextButton",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-72,0.5,-15),BackgroundColor3=Color3.fromRGB(45,45,55),BackgroundTransparency=0.5,Text="─",TextColor3=T.TextSec,TextSize=14,Font=T.FB,BorderSizePixel=0,ZIndex=22,AutoButtonColor=false,Parent=TB})
    Corner(MB,T.CRS)

    XB.MouseEnter:Connect(function() Tw(XB,0.2,{BackgroundColor3=T.BtnDng,BackgroundTransparency=0.2,TextColor3=Color3.new(1,1,1)}) end)
    XB.MouseLeave:Connect(function() Tw(XB,0.2,{BackgroundColor3=Color3.fromRGB(45,45,55),BackgroundTransparency=0.5,TextColor3=T.TextSec}) end)
    MB.MouseEnter:Connect(function() Tw(MB,0.2,{BackgroundColor3=Color3.fromRGB(60,60,75),BackgroundTransparency=0.2}) end)
    MB.MouseLeave:Connect(function() Tw(MB,0.2,{BackgroundColor3=Color3.fromRGB(45,45,55),BackgroundTransparency=0.5}) end)
    MB.MouseButton1Click:Connect(function() OF.Visible=false end)
    XB.MouseButton1Click:Connect(function()
        pcall(function()
            dead=true
            OF.Visible=false
            SG:Destroy()
        end)
    end)

    -- Dragging
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
    TB.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=OF.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    TB.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
    table.insert(conns,UIS.InputChanged:Connect(function(input) if input==dragInput and dragging then local d=input.Position-dragStart; OF.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end))

    -- Content Area
    local CA=C("Frame",{Name="Content",Size=UDim2.new(1,0,1,-T.TBH),Position=UDim2.new(0,0,0,T.TBH),BackgroundTransparency=1,ClipsDescendants=true,Parent=MF})

    -- Tab Bar
    local TBar=C("Frame",{Name="TabBar",Size=UDim2.new(1,-20,0,T.TABH),Position=UDim2.new(0,10,0,6),BackgroundTransparency=1,Parent=CA})
    C("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=TBar})

    -- Page Container
    local PC=C("Frame",{Name="Pages",Size=UDim2.new(1,-20,1,-(T.TABH+18)),Position=UDim2.new(0,10,0,T.TABH+12),BackgroundColor3=T.Panel,BackgroundTransparency=T.PanelT,BorderSizePixel=0,ClipsDescendants=true,Parent=CA})
    Corner(PC,T.CR)
    Stroke(PC,T.PanelStroke,1,0.6)

    -- Tab System
    local tabs={}
    local activeTab=nil
    local tabIcons={Home="🏠",ESP="👁️",Combat="⚔️",Movement="⚡",Teleport="📍",Visual="🎨",Settings="⚙️"}

    local function MP(name,vis)
        local page=C("ScrollingFrame",{Name=name,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=T.Scroll,ScrollBarImageTransparency=0.5,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=vis or false,ClipsDescendants=true,Parent=PC})
        C("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder,Parent=page})
        Pad(page,10,12,10,12)
        return page
    end

    local function selectTab(name)
        if activeTab==name then return end; activeTab=name
        for n,t in pairs(tabs) do
            local isActive=(n==name)
            t.page.Visible=isActive
            Tw(t.btn,0.25,{BackgroundColor3=isActive and T.TabAct or T.TabIn,BackgroundTransparency=isActive and T.TabActT or T.TabInT})
            if t.tt then Tw(t.tt,0.25,{TextColor3=isActive and T.TextAcc or T.TextSec}) end
            if t.al then Tw(t.al,0.25,{BackgroundTransparency=isActive and 0.2 or 1}) end
            local s=t.btn:FindFirstChildOfClass("UIStroke")
            if s then Tw(s,0.25,{Color=isActive and T.Accent or T.TabStroke,Transparency=isActive and 0.4 or 0.6}) end
        end
    end

    local function addTab(name,ord)
        local isFirst=(ord==1)
        local btn=C("TextButton",{Size=UDim2.new(0,86,0,32),BackgroundColor3=isFirst and T.TabAct or T.TabIn,BackgroundTransparency=isFirst and T.TabActT or T.TabInT,Text="",BorderSizePixel=0,AutoButtonColor=false,LayoutOrder=ord,Parent=TBar})
        Corner(btn,T.CRS); Stroke(btn,isFirst and T.Accent or T.TabStroke,1,isFirst and 0.4 or 0.6)
        local tt=C("TextLabel",{Name="TT",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(1,0,1,0),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1,Text=(tabIcons[name] or "").."  "..name,TextColor3=isFirst and T.TextAcc or T.TextSec,TextSize=11,Font=T.FH,Parent=btn})
        local al=C("Frame",{Name="AL",Size=UDim2.new(0.6,0,0,2),Position=UDim2.new(0.2,0,1,-3),BackgroundColor3=T.Accent,BackgroundTransparency=isFirst and 0.2 or 1,BorderSizePixel=0,Parent=btn})
        local page=MP(name,isFirst)
        tabs[name]={btn=btn,tt=tt,al=al,page=page}
        btn.MouseButton1Click:Connect(function()
            Ripple(btn,Vector2.new(btn.AbsolutePosition.X+btn.AbsoluteSize.X/2,btn.AbsolutePosition.Y+btn.AbsoluteSize.Y/2))
            selectTab(name)
        end)
        btn.MouseEnter:Connect(function() if activeTab~=name then Tw(btn,0.15,{BackgroundTransparency=0.3}) end end)
        btn.MouseLeave:Connect(function() if activeTab~=name then Tw(btn,0.15,{BackgroundTransparency=T.TabInT}) end end)
        return page
    end

    -- Widget Builders
    local function SH(parent,txt,ord)
        local r=C("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,LayoutOrder=ord,Parent=parent})
        C("TextLabel",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,5,0,0),BackgroundTransparency=1,Text=txt,TextColor3=T.TextMut,TextSize=11,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,Parent=r})
        C("Frame",{Size=UDim2.new(1,-80,0,1),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),BackgroundColor3=T.CardStroke,BackgroundTransparency=0.5,BorderSizePixel=0,Parent=r})
    end

    local function CT(parent,id,name,desc,default,cb,ord)
        local row=C("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=ord,Parent=parent})
        Corner(row,T.CRS); local s=Stroke(row,T.CardStroke,1,0.6)
        C("Frame",{Size=UDim2.new(0,3,0.6,0),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=row})
        C("TextLabel",{Size=UDim2.new(0.45,0,0,18),Position=UDim2.new(0,18,0,8),BackgroundTransparency=1,Text=name,TextColor3=T.TextPri,TextSize=15,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        C("TextLabel",{Size=UDim2.new(0.45,0,0,14),Position=UDim2.new(0,18,0,28),BackgroundTransparency=1,Text=desc,TextColor3=T.TextMut,TextSize=11,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local state=default or false
        toggleStates[id]=state
        local tg=C("Frame",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,42,0,22),Position=UDim2.new(1,-60,0.5,0),BackgroundColor3=state and T.TogOn or T.TogOff,BorderSizePixel=0,Parent=row}); Corner(tg,UDim.new(1,0))
        local kn=C("Frame",{AnchorPoint=Vector2.new(0,0.5),Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,state and 23 or 3,0.5,0),BackgroundColor3=T.Knob,BorderSizePixel=0,Parent=tg}); Corner(kn,UDim.new(1,0))
        local chip=C("TextButton",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,36,0,22),Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=T.ChipBg,BackgroundTransparency=0.2,Text="...",TextColor3=T.TextMut,TextSize=11,Font=T.FH,BorderSizePixel=0,AutoButtonColor=false,Parent=row}); Corner(chip,T.CRS)
        toggleCallbacks[id]={chip=chip,setS=function(v) state=v; toggleStates[id]=v; Tw(tg,0.2,{BackgroundColor3=v and T.TogOn or T.TogOff}); Tw(kn,0.2,{Position=UDim2.new(0,v and 23 or 3,0.5,0)}); if cb then cb(v) end end,getS=function() return state end}
        toggleSetters[id]=toggleCallbacks[id].setS
        local function toggle() state=not state; toggleStates[id]=state; Tw(tg,0.2,{BackgroundColor3=state and T.TogOn or T.TogOff}); Tw(kn,0.2,{Position=UDim2.new(0,state and 23 or 3,0.5,0)}); if cb then cb(state) end end
        tg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then toggle() end end)
        row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then toggle() end end)
        row.MouseEnter:Connect(function() Tw(row,0.15,{BackgroundColor3=T.CardHov,BackgroundTransparency=0.2}); Tw(s,0.15,{Color=T.Accent,Transparency=0.4}) end)
        row.MouseLeave:Connect(function() Tw(row,0.15,{BackgroundColor3=T.Card,BackgroundTransparency=T.CardT}); Tw(s,0.15,{Color=T.CardStroke,Transparency=0.6}) end)
        chip.MouseButton1Click:Connect(function() if listeningBind==id then listeningBind=nil; chip.Text=KEY_NAMES[keybinds[id]] or "..."; Tw(chip,0.15,{BackgroundColor3=T.ChipBg}) else listeningBind=id; chip.Text="[?]"; Tw(chip,0.2,{BackgroundColor3=T.Accent}) end end)
        chip.MouseEnter:Connect(function() if listeningBind~=id then Tw(chip,0.1,{BackgroundColor3=T.ChipHov}) end end)
        chip.MouseLeave:Connect(function() if listeningBind~=id then Tw(chip,0.1,{BackgroundColor3=T.ChipBg}) end end)
    end

    local function CBt(parent,name,desc,cb,ord,col)
        local row=C("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=ord,Parent=parent})
        Corner(row,T.CRS); local s=Stroke(row,T.CardStroke,1,0.6)
        C("TextLabel",{Size=UDim2.new(0.55,0,0,16),Position=UDim2.new(0,18,0,7),BackgroundTransparency=1,Text=name,TextColor3=T.TextPri,TextSize=14,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        C("TextLabel",{Size=UDim2.new(0.55,0,0,14),Position=UDim2.new(0,18,0,24),BackgroundTransparency=1,Text=desc,TextColor3=T.TextMut,TextSize=10,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local btn=C("TextButton",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,84,0,28),Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=col or T.BtnExec,BorderSizePixel=0,Text="Execute",TextColor3=Color3.new(1,1,1),TextSize=12,Font=T.FH,AutoButtonColor=false,Parent=row}); Corner(btn,T.CRS)
        btn.MouseButton1Click:Connect(function()
            Ripple(btn,Vector2.new(btn.AbsolutePosition.X+btn.AbsoluteSize.X/2,btn.AbsolutePosition.Y+btn.AbsoluteSize.Y/2))
            if cb then cb() end
            Tw(btn,0.1,{BackgroundColor3=T.Green})
            task.delay(0.3,function() Tw(btn,0.2,{BackgroundColor3=col or T.BtnExec}) end)
        end)
        row.MouseEnter:Connect(function() Tw(row,0.15,{BackgroundColor3=T.CardHov,BackgroundTransparency=0.2}); Tw(s,0.15,{Color=T.Accent,Transparency=0.4}) end)
        row.MouseLeave:Connect(function() Tw(row,0.15,{BackgroundColor3=T.Card,BackgroundTransparency=T.CardT}); Tw(s,0.15,{Color=T.CardStroke,Transparency=0.6}) end)
        btn.MouseEnter:Connect(function() Tw(btn,0.1,{BackgroundTransparency=0.15}) end)
        btn.MouseLeave:Connect(function() Tw(btn,0.1,{BackgroundTransparency=0}) end)
    end

    local function CS(parent,name,min,max,default,cb,ord,fmt)
        local row=C("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=ord,Parent=parent})
        Corner(row,T.CRS); local s=Stroke(row,T.CardStroke,1,0.6)
        C("TextLabel",{Size=UDim2.new(0.4,0,0,16),Position=UDim2.new(0,18,0,6),BackgroundTransparency=1,Text=name,TextColor3=T.TextPri,TextSize=14,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local vl=C("TextLabel",{AnchorPoint=Vector2.new(1,0),Size=UDim2.new(0,60,0,16),Position=UDim2.new(1,-14,0,6),BackgroundTransparency=1,Text=fmt and fmt(default) or tostring(default),TextColor3=T.TextAcc,TextSize=13,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Right,Parent=row})
        local track=C("Frame",{Size=UDim2.new(1,-36,0,6),AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,34),BackgroundColor3=T.SliderBg,BorderSizePixel=0,Parent=row}); Corner(track,UDim.new(1,0))
        local pct=(default-min)/(max-min)
        local fill=C("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=T.SliderFill,BorderSizePixel=0,Parent=track}); Corner(fill,UDim.new(1,0))
        local knob=C("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0,14,0,14),Position=UDim2.new(pct,0,0.5,0),BackgroundColor3=T.Knob,BorderSizePixel=0,ZIndex=14,Parent=track}); Corner(knob,UDim.new(1,0))
        local sliding=false
        local function upd(ix)
            local rel=math.clamp((ix-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local v=math.floor(min+(max-min)*rel+0.5)
            fill.Size=UDim2.new(rel,0,1,0); knob.Position=UDim2.new(rel,0,0.5,0)
            vl.Text=fmt and fmt(v) or tostring(v); if cb then cb(v) end
        end
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; upd(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
        row.MouseEnter:Connect(function() Tw(row,0.15,{BackgroundColor3=T.CardHov,BackgroundTransparency=0.2}); Tw(s,0.15,{Color=T.Accent,Transparency=0.4}) end)
        row.MouseLeave:Connect(function() Tw(row,0.15,{BackgroundColor3=T.Card,BackgroundTransparency=T.CardT}); Tw(s,0.15,{Color=T.CardStroke,Transparency=0.6}) end)
    end

    local function CD(parent,name,options,default,cb,ord)
        local row=C("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=ord,Parent=parent})
        Corner(row,T.CRS); local s=Stroke(row,T.CardStroke,1,0.6)
        C("TextLabel",{Size=UDim2.new(0.4,0,1,0),Position=UDim2.new(0,18,0,0),BackgroundTransparency=1,Text=name,TextColor3=T.TextPri,TextSize=14,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local cur=default or options[1]
        local btn=C("TextButton",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,120,0,28),Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=T.ChipBg,BorderSizePixel=0,Text=cur,TextColor3=T.TextAcc,TextSize=12,Font=T.FH,AutoButtonColor=false,Parent=row}); Corner(btn,T.CRS); Stroke(btn,T.Accent,1,0.6)
        local idx=1; for i,v in ipairs(options) do if v==cur then idx=i end end
        btn.MouseButton1Click:Connect(function()
            Ripple(btn,Vector2.new(btn.AbsolutePosition.X+btn.AbsoluteSize.X/2,btn.AbsolutePosition.Y+btn.AbsoluteSize.Y/2))
            idx=idx%#options+1; cur=options[idx]; btn.Text=cur; if cb then cb(cur) end
        end)
        row.MouseEnter:Connect(function() Tw(row,0.15,{BackgroundColor3=T.CardHov,BackgroundTransparency=0.2}); Tw(s,0.15,{Color=T.Accent,Transparency=0.4}) end)
        row.MouseLeave:Connect(function() Tw(row,0.15,{BackgroundColor3=T.Card,BackgroundTransparency=T.CardT}); Tw(s,0.15,{Color=T.CardStroke,Transparency=0.6}) end)
        btn.MouseEnter:Connect(function() Tw(btn,0.1,{BackgroundColor3=T.ChipHov}) end)
        btn.MouseLeave:Connect(function() Tw(btn,0.1,{BackgroundColor3=T.ChipBg}) end)
    end

    -- ================================================================
    -- CREATE TABS & POPULATE
    -- ================================================================
    local homeP=addTab("Home",1)
    local espP=addTab("ESP",2)
    local combatP=addTab("Combat",3)
    local moveP=addTab("Movement",4)
    local tpP=addTab("Teleport",5)
    local visualP=addTab("Visual",6)
    local settP=addTab("Settings",7)
    selectTab("Home")

    -- HOME TAB (Synox Hub style with avatar, stats, status)
    -- Profile Card
    local profCard=C("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=1,Parent=homeP}); Corner(profCard,T.CRS); Stroke(profCard,T.CardStroke,1,0.55)
    -- Avatar ring
    local avRing=C("Frame",{Size=UDim2.new(0,55,0,55),Position=UDim2.new(0,12,0.5,-27),BackgroundColor3=T.Accent,BackgroundTransparency=0.7,BorderSizePixel=0,Parent=profCard}); Corner(avRing,UDim.new(1,0)); Stroke(avRing,T.Accent,2,0.3)
    -- Avatar image
    local avImg=C("ImageLabel",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0,47,0,47),Position=UDim2.new(0.5,0,0.5,0),BackgroundColor3=Color3.fromRGB(40,40,50),BorderSizePixel=0,Image="rbxthumb://type=AvatarHeadShot&id="..tostring(LP.UserId).."&w=150&h=150",Parent=avRing}); Corner(avImg,UDim.new(1,0))
    -- Username
    C("TextLabel",{Size=UDim2.new(0.6,0,0,18),Position=UDim2.new(0,78,0,14),BackgroundTransparency=1,Text="@"..LP.Name,TextColor3=T.TextPri,TextSize=14,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=profCard})
    -- Version line
    C("TextLabel",{Size=UDim2.new(0.6,0,0,14),Position=UDim2.new(0,78,0,34),BackgroundTransparency=1,Text="SYNOX HUB v5.0 - MM2 Edition",TextColor3=T.TextMut,TextSize=10,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,Parent=profCard})
    -- Online dot + text
    local onDot=C("Frame",{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0,78,0,55),BackgroundColor3=T.Green,BorderSizePixel=0,Parent=profCard}); Corner(onDot,UDim.new(1,0))
    C("TextLabel",{Size=UDim2.new(0.4,0,0,12),Position=UDim2.new(0,89,0,53),BackgroundTransparency=1,Text="Online",TextColor3=T.Green,TextSize=10,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,Parent=profCard})

    -- Stats Row (Ping, FPS, Role)
    local statsRow=C("Frame",{Size=UDim2.new(1,0,0,48),BackgroundTransparency=1,LayoutOrder=2,Parent=homeP})
    -- Ping card
    local pingC=C("Frame",{Size=UDim2.new(0.32,-4,1,0),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,Parent=statsRow}); Corner(pingC,T.CRS); Stroke(pingC,T.CardStroke,1,0.55); Pad(pingC,6,6,6,6)
    C("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text="PING",TextColor3=T.TextMut,TextSize=9,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=pingC})
    local pingV=C("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,13),BackgroundTransparency=1,Text="0 ms",TextColor3=T.TextAcc,TextSize=17,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,Parent=pingC})
    -- FPS card
    local fpsC=C("Frame",{Size=UDim2.new(0.32,-4,1,0),Position=UDim2.new(0.34,0,0,0),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,Parent=statsRow}); Corner(fpsC,T.CRS); Stroke(fpsC,T.CardStroke,1,0.55); Pad(fpsC,6,6,6,6)
    C("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text="FPS",TextColor3=T.TextMut,TextSize=9,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=fpsC})
    local fpsV=C("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,13),BackgroundTransparency=1,Text="60",TextColor3=T.TextAcc,TextSize=17,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,Parent=fpsC})
    -- Role card
    local roleC=C("Frame",{Size=UDim2.new(0.34,0,1,0),Position=UDim2.new(0.66,0,0,0),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,Parent=statsRow}); Corner(roleC,T.CRS); Stroke(roleC,T.CardStroke,1,0.55); Pad(roleC,6,6,6,6)
    C("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text="ROLE",TextColor3=T.TextMut,TextSize=9,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=roleC})
    local roleV=C("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,13),BackgroundTransparency=1,Text="Waiting...",TextColor3=T.TextAcc,TextSize=17,Font=T.FT,TextXAlignment=Enum.TextXAlignment.Left,Parent=roleC})

    -- Status section
    local statusSec=C("Frame",{Size=UDim2.new(1,0,0,55),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=3,Parent=homeP}); Corner(statusSec,T.CRS); Stroke(statusSec,T.CardStroke,1,0.55); Pad(statusSec,8,8,8,8)
    C("TextLabel",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,Text="STATUS",TextColor3=T.TextMut,TextSize=9,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=statusSec})
    C("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,14),BackgroundTransparency=1,Text="Connected - All Systems Online",TextColor3=T.Green,TextSize=11,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=statusSec})
    C("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,30),BackgroundTransparency=1,Text="50+ features loaded | Key verified | MM2 detected",TextColor3=T.TextSec,TextSize=10,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,Parent=statusSec})

    -- Discord card
    local discCard=C("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=4,Parent=homeP}); Corner(discCard,T.CRS); Stroke(discCard,T.CardStroke,1,0.55); Pad(discCard,10,10,10,10)
    C("TextLabel",{Size=UDim2.new(0.5,0,0,16),BackgroundTransparency=1,Text="Discord",TextColor3=T.TextPri,TextSize=13,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=discCard})
    local cpyBtn=C("TextButton",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,100,0,26),Position=UDim2.new(1,0,0.5,0),BackgroundColor3=Color3.fromRGB(88,101,242),BackgroundTransparency=0.15,Text="Copy Link",TextColor3=Color3.new(1,1,1),TextSize=11,Font=T.FH,BorderSizePixel=0,AutoButtonColor=false,Parent=discCard}); Corner(cpyBtn,T.CRS)
    cpyBtn.MouseButton1Click:Connect(function() pcall(function() setclipboard(CONFIG.DiscordLink) end); cpyBtn.Text="Copied!"; task.delay(1.5,function() cpyBtn.Text="Copy Link" end) end)
    cpyBtn.MouseEnter:Connect(function() Tw(cpyBtn,0.2,{BackgroundTransparency=0}) end)
    cpyBtn.MouseLeave:Connect(function() Tw(cpyBtn,0.2,{BackgroundTransparency=0.15}) end)

    -- Live stats updater
    local lastFPSt=os.clock()
    local frameCount=0
    task.spawn(function()
        while not dead do
            -- Ping
            pcall(function()
                local Stats=game:GetService("Stats")
                local p=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                pingV.Text=p.." ms"
            end)
            -- FPS
            frameCount=frameCount+1
            local now=os.clock()
            if now-lastFPSt>=1 then
                fpsV.Text=tostring(frameCount)
                frameCount=0; lastFPSt=now
            end
            -- Role
            pcall(function()
                local r=myRole()
                roleV.Text=r
                roleV.TextColor3=roleColor(r)
            end)
            task.wait(1)
        end
    end)

    -- ESP TAB
    SH(espP,"PLAYER ESP",1)
    CT(espP,"esp","Player ESP","Box ESP around all players",MM2.ESP_Enabled,function(v) MM2.ESP_Enabled=v; if v then RefESP() else ClearESP() end end,2)
    CT(espP,"espnames","Name Labels","Show player names on ESP",MM2.ESP_Names,function(v) MM2.ESP_Names=v end,3)
    CT(espP,"esproles","Role Tags","Show Murderer/Sheriff/Innocent",MM2.ESP_Roles,function(v) MM2.ESP_Roles=v end,4)
    CT(espP,"espchams","Chams","Highlight players through walls",MM2.ESP_Chams,function(v) MM2.ESP_Chams=v end,5)
    CT(espP,"espfill","ESP Fill","Fill ESP boxes with color",MM2.ESP_Fill,function(v) MM2.ESP_Fill=v end,6)
    CT(espP,"espskel","Skeleton","Draw bone lines on players",MM2.ESP_Skeleton,function(v) MM2.ESP_Skeleton=v end,7)
    CT(espP,"esptracers","Tracers","Lines from screen to players",MM2.ESP_Tracers,function(v) MM2.ESP_Tracers=v end,8)
    CS(espP,"ESP Max Distance",0,2000,MM2.ESP_MaxDist,function(v) MM2.ESP_MaxDist=v end,9,function(v) return v==0 and "INF" or v.."m" end)
    CD(espP,"Tracer Origin",{"Bottom","Top","Center"},MM2.ESP_TracerFrom,function(v) MM2.ESP_TracerFrom=v end,10)
    SH(espP,"OBJECT ESP",11)
    CT(espP,"coinesp","Coin ESP","Highlight coins in map",MM2.Coin_ESP,function(v) MM2.Coin_ESP=v; if v then RefCoin() else ClearCoin() end end,12)
    CT(espP,"gunesp","Gun ESP","Highlight dropped guns",MM2.Gun_ESP,function(v) MM2.Gun_ESP=v; if v then RefGun() else ClearGun() end end,13)
    CT(espP,"gunespdist","Gun Distance","Show distance to gun",MM2.Gun_ESP_Dist,function(v) MM2.Gun_ESP_Dist=v; RefGun() end,14)
    CT(espP,"trapesp","Trap ESP","Highlight bear traps",MM2.Trap_ESP,function(v) MM2.Trap_ESP=v; if v then RefTrap() else ClearTrap() end end,15)
    CT(espP,"footsteps","Footsteps","Track player movement trails",MM2.Footsteps,function(v) MM2.Footsteps=v end,16)

    -- COMBAT TAB
    SH(combatP,"AIMING",1)
    CT(combatP,"aimbot","Aimbot","Lock camera to nearest enemy",MM2.Aimbot,function(v) MM2.Aimbot=v end,2)
    CT(combatP,"silentaim","Silent Aim","Redirect shots to nearest enemy",MM2.Silent_Aim,function(v) MM2.Silent_Aim=v end,3)
    CT(combatP,"showfov","Show FOV Circle","Display aim FOV radius",MM2.Show_FOV,function(v) MM2.Show_FOV=v end,4)
    CS(combatP,"Aim FOV",30,500,MM2.Aim_FOV,function(v) MM2.Aim_FOV=v end,5)
    SH(combatP,"WEAPONS",6)
    CT(combatP,"gunwalls","Gun Through Walls","Teleport-shoot-return",MM2.Gun_Walls,function(v) MM2.Gun_Walls=v end,7)
    CT(combatP,"knifewalls","Knife Through Walls","Remote knife kill",MM2.Knife_Walls,function(v) MM2.Knife_Walls=v end,8)
    CT(combatP,"instantknife","Instant Knife","Instant knife on RMB",MM2.Instant_Knife,function(v) MM2.Instant_Knife=v end,9)
    CT(combatP,"autokill","Auto Kill","Auto eliminate enemies",MM2.Auto_Kill,function(v) MM2.Auto_Kill=v end,10)
    CT(combatP,"autograb","Auto Grab Gun","Auto pickup dropped guns",MM2.Auto_Grab_Gun,function(v) MM2.Auto_Grab_Gun=v end,11)
    SH(combatP,"FLING",12)
    CT(combatP,"autoflingm","Auto Fling Murderer","Fling murderer continuously",MM2.Auto_Fling_Murderer,function(v) MM2.Auto_Fling_Murderer=v end,13)
    CT(combatP,"autoflings","Auto Fling Sheriff","Fling sheriff continuously",MM2.Auto_Fling_Sheriff,function(v) MM2.Auto_Fling_Sheriff=v end,14)
    CS(combatP,"Fling Power",1000,50000,MM2.Fling_Power,function(v) MM2.Fling_Power=v end,15)
    CS(combatP,"Fling Duration",0.5,5,MM2.Fling_Duration,function(v) MM2.Fling_Duration=v end,16,function(v) return string.format("%.1fs",v) end)
    SH(combatP,"ACTIONS",17)
    CBt(combatP,"Fling Target","Fling selected player",function()
        local t=fovTarget(); if t then FlingPlayer(t); Notify("Fling","Flung "..t.DisplayName,2,"success") else Notify("Fling","No target in FOV",2,"warning") end
    end,18,T.BtnExec)
    CBt(combatP,"Fling All","Fling every player",function() FlingAll(); Notify("Fling","Flung all players",2,"success") end,19,T.BtnDng)

    -- MOVEMENT TAB
    SH(moveP,"LOCOMOTION",1)
    CT(moveP,"speed","Speed Hack","Override walk speed",MM2.Speed_Enabled,function(v) MM2.Speed_Enabled=v; if not v then local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end end end end,2)
    CS(moveP,"Walk Speed",16,250,MM2.Speed_Value,function(v) MM2.Speed_Value=v end,3)
    CT(moveP,"fly","Fly","Fly around the map",MM2.Fly_Enabled,function(v) MM2.Fly_Enabled=v; if v then EnableFly() else DisableFly() end end,4)
    CS(moveP,"Fly Speed",10,500,MM2.Fly_Speed,function(v) MM2.Fly_Speed=v end,5)
    CT(moveP,"noclip","Noclip","Walk through walls",MM2.Noclip,function(v) MM2.Noclip=v end,6)
    CT(moveP,"infjump","Infinite Jump","Jump in mid-air",MM2.InfiniteJump,function(v) MM2.InfiniteJump=v end,7)
    CT(moveP,"jumppower","Jump Power","Override jump power",MM2.JumpPower_Enabled,function(v) MM2.JumpPower_Enabled=v; if not v then local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=50 end end end end,8)
    CS(moveP,"Jump Power",50,300,MM2.JumpPower_Value,function(v) MM2.JumpPower_Value=v end,9)
    SH(moveP,"CAMERA",10)
    CT(moveP,"unlockcam","Unlock Camera","Unlimited zoom distance",MM2.UnlockCam,function(v) MM2.UnlockCam=v; if not v then pcall(function() LP.CameraMaxZoomDistance=128 end) end end,11)
    CS(moveP,"FOV",30,120,MM2.FOV_Value,function(v) MM2.FOV_Value=v end,12)
    SH(moveP,"COINS",13)
    CT(moveP,"autocoins","Auto Collect Coins","TP to coins and collect",MM2.Auto_Collect_Coins,function(v) MM2.Auto_Collect_Coins=v end,14)
    CS(moveP,"Collect Speed",4,60,MM2.Collect_Speed,function(v) MM2.Collect_Speed=v end,15,function(v) return v.."/s" end)

    -- TELEPORT TAB
    SH(tpP,"PLAYER TELEPORT",1)
    -- Build player buttons
    local function buildTpList()
        for _,c in ipairs(tpP:GetChildren()) do if c:IsA("Frame") and c.LayoutOrder>10 then c:Destroy() end end
        local ord=11
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP then
                ord=ord+1
                CBt(tpP,"TP: "..p.DisplayName,"Teleport to "..p.Name,function()
                    local myhrp=getHRP(LP.Character); local thrp=p.Character and getHRP(p.Character)
                    if myhrp and thrp then myhrp.CFrame=thrp.CFrame*CFrame.new(0,0,3); Notify("Teleport","Teleported to "..p.DisplayName,2,"success")
                    else Notify("Teleport","Player not found",2,"error") end
                end,ord,T.BtnExec)
            end
        end
    end
    CBt(tpP,"Refresh Player List","Reload player teleport list",function() buildTpList() end,2,T.BtnPri)
    SH(tpP,"SERVER",3)
    CBt(tpP,"Server Hop","Join a different server",function() serverHop() end,4,T.BtnExec)
    CBt(tpP,"Rejoin Server","Reconnect to this server",function() rejoin() end,5,T.BtnPri)
    buildTpList()

    -- VISUAL TAB
    SH(visualP,"RENDERING",1)
    CT(visualP,"fullbright","Fullbright","Maximum lighting",MM2.Fullbright,function(v) MM2.Fullbright=v; TogFull(v) end,2)
    CT(visualP,"nofog","No Fog","Remove fog effects",MM2.NoFog,function(v) MM2.NoFog=v; TogFog(v) end,3)
    CT(visualP,"fpsboost","FPS Boost","Strip textures and effects",MM2.FPS_Boost,function(v) MM2.FPS_Boost=v; FPSBoost() end,4)
    SH(visualP,"INFORMATION",5)
    CT(visualP,"killfeed","Kill Feed","Show who killed who",MM2.Kill_Feed,function(v) MM2.Kill_Feed=v end,6)
    CT(visualP,"murdalert","Murderer Alert","Warn when murderer is near",MM2.Murderer_Alert,function(v) MM2.Murderer_Alert=v end,7)

    -- SETTINGS TAB
    SH(settP,"INFO",1)
    -- Version card
    local verCard=C("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=2,Parent=settP}); Corner(verCard,T.CRS); Stroke(verCard,T.CardStroke,1,0.55); Pad(verCard,10,10,10,10)
    C("TextLabel",{Size=UDim2.new(0.5,0,0,16),BackgroundTransparency=1,Text="Version",TextColor3=T.TextPri,TextSize=13,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=verCard})
    C("TextLabel",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,80,0,16),Position=UDim2.new(1,0,0.5,0),BackgroundTransparency=1,Text="v5.0.0",TextColor3=T.TextAcc,TextSize=12,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Right,Parent=verCard})
    -- Key status card
    local keyCard=C("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=3,Parent=settP}); Corner(keyCard,T.CRS); Stroke(keyCard,T.CardStroke,1,0.55); Pad(keyCard,10,10,10,10)
    C("TextLabel",{Size=UDim2.new(0.5,0,0,16),BackgroundTransparency=1,Text="Key Status",TextColor3=T.TextPri,TextSize=13,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=keyCard})
    local keyBadge=C("TextLabel",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,80,0,22),Position=UDim2.new(1,0,0.5,0),BackgroundColor3=T.Green,BackgroundTransparency=0.8,Text="Verified",TextColor3=T.Green,TextSize=11,Font=T.FH,BorderSizePixel=0,Parent=keyCard}); Corner(keyBadge,UDim.new(0,3))
    -- Clear key button card
    local clrCard=C("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=4,Parent=settP}); Corner(clrCard,T.CRS); Stroke(clrCard,T.CardStroke,1,0.55); Pad(clrCard,10,10,10,10)
    C("TextLabel",{Size=UDim2.new(0.5,0,0,16),BackgroundTransparency=1,Text="Clear Saved Key",TextColor3=T.TextPri,TextSize=13,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=clrCard})
    local clrBtn=C("TextButton",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,80,0,26),Position=UDim2.new(1,0,0.5,0),BackgroundColor3=T.BtnDng,BackgroundTransparency=0.3,Text="Clear",TextColor3=Color3.new(1,1,1),TextSize=11,Font=T.FH,BorderSizePixel=0,AutoButtonColor=false,Parent=clrCard}); Corner(clrBtn,T.CRS)
    clrBtn.MouseButton1Click:Connect(function() deleteSavedKey(); keyBadge.Text="Cleared"; keyBadge.TextColor3=T.Yellow; keyBadge.BackgroundColor3=T.Yellow; Notify("Settings","Saved key cleared. Re-login next run.",3,"warning"); task.delay(2,function() keyBadge.Text="Verified"; keyBadge.TextColor3=T.Green; keyBadge.BackgroundColor3=T.Green end) end)
    clrBtn.MouseEnter:Connect(function() Tw(clrBtn,0.15,{BackgroundTransparency=0}) end)
    clrBtn.MouseLeave:Connect(function() Tw(clrBtn,0.15,{BackgroundTransparency=0.3}) end)

    SH(settP,"PROTECTION",5)

    CT(settP,"antiafk","Anti-AFK","Prevent idle kick",MM2.AntiAFK,function(v) MM2.AntiAFK=v end,6)
    CT(settP,"antitrap","Anti-Trap","Prevent trap slowdown",MM2.Anti_Trap,function(v) MM2.Anti_Trap=v end,7)
    CT(settP,"antifling","Anti-Fling","Block fling attempts",MM2.Anti_Fling,function(v) MM2.Anti_Fling=v end,8)

    -- Hotkey Rebind
    SH(settP,"HOTKEY",9)
    local hkCard=C("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=T.Card,BackgroundTransparency=T.CardT,BorderSizePixel=0,LayoutOrder=10,Parent=settP}); Corner(hkCard,T.CRS); Stroke(hkCard,T.CardStroke,1,0.55)
    C("TextLabel",{Size=UDim2.new(0.5,0,0,18),Position=UDim2.new(0,18,0,10),BackgroundTransparency=1,Text="Toggle Hub Hotkey",TextColor3=T.TextPri,TextSize=15,Font=T.FH,TextXAlignment=Enum.TextXAlignment.Left,Parent=hkCard})
    C("TextLabel",{Size=UDim2.new(0.5,0,0,14),Position=UDim2.new(0,18,0,30),BackgroundTransparency=1,Text="Click chip then press any key",TextColor3=T.TextMut,TextSize=11,Font=T.FB,TextXAlignment=Enum.TextXAlignment.Left,Parent=hkCard})
    local hkChip=C("TextButton",{AnchorPoint=Vector2.new(1,0.5),Size=UDim2.new(0,90,0,28),Position=UDim2.new(1,-14,0.5,0),BackgroundColor3=T.ChipBg,BackgroundTransparency=0.2,Text=KEY_NAMES[CONFIG.DefaultHotkey] or "RCtrl",TextColor3=T.TextAcc,TextSize=13,Font=T.FH,BorderSizePixel=0,AutoButtonColor=false,Parent=hkCard}); Corner(hkChip,T.CRS); Stroke(hkChip,T.Accent,1,0.5)
    local hkListening=false
    hkChip.MouseButton1Click:Connect(function()
        if hkListening then hkListening=false; hkChip.Text=KEY_NAMES[CONFIG.DefaultHotkey] or "RCtrl"; Tw(hkChip,0.2,{BackgroundColor3=T.ChipBg}); return end
        hkListening=true; hkChip.Text="[Press Key]"; Tw(hkChip,0.2,{BackgroundColor3=T.Accent})
    end)
    hkChip.MouseEnter:Connect(function() if not hkListening then Tw(hkChip,0.15,{BackgroundColor3=T.ChipHov}) end end)
    hkChip.MouseLeave:Connect(function() if not hkListening then Tw(hkChip,0.15,{BackgroundColor3=T.ChipBg}) end end)

    SH(settP,"ACTIONS",7)
    CBt(settP,"Clear Saved Key","Delete cached key",function() deleteSavedKey(); Notify("Key Cache","Saved key cleared!",3,"info") end,8,T.BtnPri)
    CBt(settP,"Reset Character","Kill your character",function() local c=LP.Character; if c then local h=c:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end end end,9,T.BtnPri)
    CBt(settP,"Destroy Hub","Remove SYNOX HUB completely",function()
        dead=true; for _,cn in ipairs(conns) do if cn and cn.Connected then cn:Disconnect() end end; conns={}
        ClearESP(); ClearCoin(); ClearGun(); ClearTrap(); DisableFly(); TogFull(false); TogFog(false)
        local ch=LP.Character; if ch then local hm=ch:FindFirstChildOfClass("Humanoid"); if hm then hm.WalkSpeed=16; hm.JumpPower=50 end end
        pcall(function() LP.CameraMaxZoomDistance=128 end); Camera.FieldOfView=70
        Tw(MF,0.2,{BackgroundTransparency=1}); Tw(OF,0.4,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1})
        task.delay(0.45,function() SG:Destroy(); pcall(function() EspGui:Destroy() end) end); Notify("SYNOX","Hub destroyed!",4,"info")
    end,10,T.BtnDng)

    -- ================================================================
    -- KEYBIND LISTENER
    -- ================================================================
    table.insert(conns, UIS.InputBegan:Connect(function(input,gpe)
        if gpe then return end

        -- Keybind assignment
        if listeningBind then
            local kc=input.KeyCode; if kc==Enum.KeyCode.Unknown then return end
            if kc==Enum.KeyCode.Escape or kc==Enum.KeyCode.Backspace then
                local id=listeningBind; listeningBind=nil; keybinds[id]=nil
                local ref=toggleCallbacks[id]; if ref then ref.chip.Text="..."; Tw(ref.chip,0.2,{BackgroundColor3=T.ChipBg}) end; return
            end
            local id=listeningBind; listeningBind=nil; keybinds[id]=kc
            local ref=toggleCallbacks[id]; if ref then ref.chip.Text=KEY_NAMES[kc] or kc.Name; Tw(ref.chip,0.2,{BackgroundColor3=T.ChipBg}) end; return
        end

        -- Hotkey rebind
        if hkListening then
            local kc=input.KeyCode; if kc==Enum.KeyCode.Unknown then return end
            if kc==Enum.KeyCode.Escape then hkListening=false; hkChip.Text=KEY_NAMES[CONFIG.DefaultHotkey] or "RCtrl"; Tw(hkChip,0.2,{BackgroundColor3=T.ChipBg}); return end
            hkListening=false; CONFIG.DefaultHotkey=kc; hkChip.Text=KEY_NAMES[kc] or kc.Name; Tw(hkChip,0.2,{BackgroundColor3=T.ChipBg})
            Notify("Hotkey","Hub toggle: "..(KEY_NAMES[kc] or kc.Name),2,"success"); return
        end

        -- Hub toggle
        if input.KeyCode==CONFIG.DefaultHotkey then OF.Visible=not OF.Visible; return end

        -- Feature keybinds
        for id,kc in pairs(keybinds) do
            if input.KeyCode==kc then local ref=toggleCallbacks[id]; if ref and ref.setS and ref.getS then ref.setS(not ref.getS()) end end
        end

        -- Instant Knife on RMB
        if MM2.Instant_Knife and input.UserInputType==Enum.UserInputType.MouseButton2 then
            local knife=findWeapon("Knife"); local ev=knife and knife:FindFirstChild("Events")
            if ev then equip(knife); local t=fovTarget(); if t then knifeKill(ev,t.Character) end end
        end
    end))

    -- Close button
    XB.MouseButton1Click:Connect(function()
        dead=true; for _,cn in ipairs(conns) do if cn and cn.Connected then cn:Disconnect() end end; conns={}
        ClearESP(); ClearCoin(); ClearGun(); ClearTrap(); DisableFly(); TogFull(false); TogFog(false)
        local ch=LP.Character; if ch then local hm=ch:FindFirstChildOfClass("Humanoid"); if hm then hm.WalkSpeed=16; hm.JumpPower=50 end end
        pcall(function() LP.CameraMaxZoomDistance=128 end); Camera.FieldOfView=70
        Tw(MF,0.2,{BackgroundTransparency=1}); Tw(OF,0.4,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1})
        task.delay(0.45,function() SG:Destroy(); pcall(function() EspGui:Destroy() end) end)
    end)

    -- Intro animation
    OF.Size=UDim2.new(0,680,0,520)
    OF.BackgroundTransparency=T.OuterT
    Notify("SYNOX HUB","MM2 Full Edition v5.0 loaded! 50+ features.",4,"success")
end

-- ================================================================
-- LAUNCH
-- ================================================================
local ok,err=pcall(function() showKeySystem(buildUI) end)
if not ok then warn("[SYNOX MM2 ERROR]: "..tostring(err)) end
