--[[
    ██╗███████╗███╗   ███╗███████╗██████╗ 
    ██║██╔════╝████╗ ████║╚════██║██╔══██╗
    ██║█████╗  ██╔████╔██║    ██╔╝██████╔╝
    ██║██╔══╝  ██║╚██╔╝██║   ██╔╝ ██╔══██╗
    ██║███████╗██║ ╚═╝ ██║   ██║  ██║  ██║
    ╚═╝╚══════╝╚═╝     ╚═╝   ╚═╝  ╚═╝  ╚═╝
    
    IEM7R — Rhythm Auto-Player v5.0
    © IEM7R | dc:siberguvenlik | All rights reserved
    Key System + Keybind UI + Accuracy Control + Lane State Machine
]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UIS                = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")
local VIM                = game:GetService("VirtualInputManager")
local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════
-- THEME (SYNOX HUB Glassmorphism)
-- ═══════════════════════════════════════════════════════════════
local T = {
    Bg           = Color3.fromRGB(25, 25, 30),
    BgTrans      = 0.15,
    Outer        = Color3.fromRGB(35, 35, 42),
    OuterTrans   = 0.45,
    OuterStroke  = Color3.fromRGB(80, 80, 95),
    Panel        = Color3.fromRGB(30, 30, 38),
    PanelTrans   = 0.25,
    PanelStroke  = Color3.fromRGB(60, 60, 75),
    TitleBar     = Color3.fromRGB(20, 20, 26),
    Accent       = Color3.fromRGB(0, 180, 216),
    AccentDark   = Color3.fromRGB(0, 140, 170),
    AccentGlow   = Color3.fromRGB(0, 200, 240),
    TextPri      = Color3.fromRGB(220, 220, 230),
    TextSec      = Color3.fromRGB(150, 150, 165),
    TextMuted    = Color3.fromRGB(100, 100, 115),
    TextAccent   = Color3.fromRGB(0, 200, 230),
    Card         = Color3.fromRGB(32, 32, 40),
    CardTrans    = 0.3,
    CardHover    = Color3.fromRGB(38, 38, 48),
    CardStroke   = Color3.fromRGB(55, 55, 68),
    BtnPri       = Color3.fromRGB(0, 160, 195),
    BtnPriHov    = Color3.fromRGB(0, 185, 220),
    BtnSec       = Color3.fromRGB(45, 45, 55),
    BtnDanger    = Color3.fromRGB(200, 50, 50),
    Green        = Color3.fromRGB(50, 205, 50),
    Red          = Color3.fromRGB(200, 50, 50),
    Yellow       = Color3.fromRGB(255, 200, 50),
    Orange       = Color3.fromRGB(255, 140, 50),
    Scroll       = Color3.fromRGB(60, 60, 75),
    Corner       = UDim.new(0, 8),
    CornerSm     = UDim.new(0, 5),
    CornerLg     = UDim.new(0, 12),
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════
local function C(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" and k ~= "Children" then i[k] = v end
    end
    if props.Children then for _, ch in ipairs(props.Children) do ch.Parent = i end end
    if props.Parent then i.Parent = props.Parent end
    return i
end

local function Tw(inst, dur, props)
    local tw = TweenService:Create(inst, TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Corner(p, r) return C("UICorner", {CornerRadius = r or T.Corner, Parent = p}) end
local function Stroke(p, col, th, tr) return C("UIStroke", {Color = col or T.OuterStroke, Thickness = th or 1, Transparency = tr or 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p}) end
local function Pad(p, t, r, b, l) return C("UIPadding", {PaddingTop = UDim.new(0,t or 8), PaddingRight = UDim.new(0,r or 8), PaddingBottom = UDim.new(0,b or 8), PaddingLeft = UDim.new(0,l or 8), Parent = p}) end

-- ═══════════════════════════════════════════════════════════════
-- CONFIG STATE
-- ═══════════════════════════════════════════════════════════════
local CFG = {
    enabled       = false,
    toggleKey     = Enum.KeyCode.RightShift,
    uiToggleKey   = Enum.KeyCode.RightControl,
    -- Accuracy distribution (must sum to 100)
    perfectPct    = 75,
    goodPct       = 15,
    okayPct       = 7,
    badPct        = 3,
    -- Timing offsets for each judgement tier (seconds delay from perfect)
    perfectDelay  = 0,
    goodDelay     = 0.035,
    okayDelay     = 0.070,
    badDelay      = 0.120,
    -- Hit zone
    hitAbove      = 140,
    hitBelow      = 30,
    tapFrames     = 2,
    holdRelBuf    = 10,
    recycleJump   = 150,
    rescanInt     = 90,
    humanize      = true,
    humanizeMs    = 0.0012,
    -- Lane key overrides: {[1]=Enum.KeyCode.X, [2]=Enum.KeyCode.C, ...}
    -- nil = use auto-detected, set value = manual override
    laneKeyOverrides = {},
}

local KEY_LOOKUP = {
    F=Enum.KeyCode.F, J=Enum.KeyCode.J, D=Enum.KeyCode.D, K=Enum.KeyCode.K,
    X=Enum.KeyCode.X, C=Enum.KeyCode.C, N=Enum.KeyCode.N, M=Enum.KeyCode.M,
    S=Enum.KeyCode.S, L=Enum.KeyCode.L, A=Enum.KeyCode.A, Z=Enum.KeyCode.Z,
    V=Enum.KeyCode.V, B=Enum.KeyCode.B,
}

local KC_NAMES = {}
for name, code in pairs(KEY_LOOKUP) do KC_NAMES[code] = name end
-- add more for toggle keys
for _, v in ipairs(Enum.KeyCode:GetEnumItems()) do
    if not KC_NAMES[v] then KC_NAMES[v] = v.Name end
end

-- ═══════════════════════════════════════════════════════════════
-- ENGINE STATE
-- ═══════════════════════════════════════════════════════════════
local rhythmRoot   = nil
local engineLanes  = {}
local engineCount  = 0
local laneState    = {}
local noteData     = {}
local frameTick    = 0
local stats        = {perfect=0, good=0, okay=0, bad=0, miss=0, total=0, holds=0}
local keyValidated = false
local validatedKeyText = ""  -- stores the key text after successful validation

-- ═══════════════════════════════════════════════════════════════
-- SCREENGUI
-- ═══════════════════════════════════════════════════════════════
local SG = C("ScreenGui", {
    Name = "RhythmAutoV5_" .. HttpService:GenerateGUID(false):sub(1,8),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
})
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = PlayerGui end



-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM UI (IEM7R Branded)
-- ═══════════════════════════════════════════════════════════════
local KeyFrame = C("Frame", {
    Name = "KeySystem",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 400, 0, 380),
    BackgroundColor3 = T.Bg,
    BackgroundTransparency = T.BgTrans,
    BorderSizePixel = 0,
    Visible = not (_G.SynoxKeyVerified or (getgenv and getgenv().SynoxKeyVerified)),
    Parent = SG,
})
Corner(KeyFrame, T.CornerLg)
Stroke(KeyFrame, T.OuterStroke, 1.5, 0.3)

-- Key title bar
local KeyTitle = C("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = T.TitleBar,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Parent = KeyFrame,
})
Corner(KeyTitle, T.Corner)
C("Frame", {Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,1,-10), BackgroundColor3=T.TitleBar, BackgroundTransparency=0.1, BorderSizePixel=0, Parent=KeyTitle})

C("TextLabel", {
    Size = UDim2.new(0.7, 0, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "🔑  IEM7R — Key System",
    TextColor3 = T.TextPri,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = KeyTitle,
})

-- Accent line under title
C("Frame", {Size=UDim2.new(0, 50, 0, 2), Position=UDim2.new(0,14,1,-2), BackgroundColor3=T.Accent, BackgroundTransparency=0.3, BorderSizePixel=0, Parent=KeyTitle})

-- Key content
local KeyContent = C("Frame", {
    Size = UDim2.new(1, -24, 1, -50),
    Position = UDim2.new(0, 12, 0, 44),
    BackgroundTransparency = 1,
    Parent = KeyFrame,
})

-- IEM7R Logo Image (loaded from GitHub or Roblox asset)
local LOGO_URLS = {
    "https://raw.githubusercontent.com/emrself/mining/main/iem7r_logo.png",
    "https://raw.githubusercontent.com/emrself/mining/main/iem7r_logo.jpg",
    "https://cdn.jsdelivr.net/gh/emrself/mining@main/iem7r_logo.png",
    "https://cdn.jsdelivr.net/gh/emrself/mining@main/iem7r_logo.jpg",
}
local LOGO_LOCAL_PATH = "iem7r_logo.png"
local LOGO_ROBLOX_ID  = ""  -- Set rbxassetid://XXXXX if uploaded to Roblox

-- Logo container (image + text fallback)
local LogoContainer = C("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    Parent = KeyContent,
})

local LogoImage = C("ImageLabel", {
    Name = "LogoImage",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 120, 0, 50),
    BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Fit,
    Image = "",
    Visible = false,
    Parent = LogoContainer,
})

-- Text fallback logo (shown if image fails to load)
local LogoText = C("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "IEM7R",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 32,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Center,
    Parent = LogoContainer,
})

-- Try loading logo
task.spawn(function()
    -- Method 1: Roblox asset ID (fastest, most reliable)
    if LOGO_ROBLOX_ID ~= "" then
        LogoImage.Image = LOGO_ROBLOX_ID
        LogoImage.Visible = true
        LogoText.Visible = false
        return
    end

    -- Method 2: Download from GitHub/CDN → writefile → getcustomasset
    for _, logoUrl in ipairs(LOGO_URLS) do
        if LogoImage.Visible then break end
        pcall(function()
            local imageData = game:HttpGet(logoUrl)
            if imageData and #imageData > 100 then
                writefile(LOGO_LOCAL_PATH, imageData)
                local asset = getcustomasset(LOGO_LOCAL_PATH)
                if asset then
                    LogoImage.Image = asset
                    LogoImage.Visible = true
                    LogoText.Visible = false
                end
            end
        end)
    end

    -- Method 3: If already downloaded previously, try loading cached
    if not LogoImage.Visible then
        pcall(function()
            if isfile and isfile(LOGO_LOCAL_PATH) then
                local asset = getcustomasset(LOGO_LOCAL_PATH)
                if asset then
                    LogoImage.Image = asset
                    LogoImage.Visible = true
                    LogoText.Visible = false
                end
            end
        end)
    end

    -- If all methods fail, text logo stays visible (already default)
end)

-- Subtitle: dc:siberguvenlik
C("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 62),
    BackgroundTransparency = 1,
    Text = "dc:siberguvenlik",
    TextColor3 = T.Accent,
    TextSize = 11,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Center,
    Parent = KeyContent,
})

-- Separator line
C("Frame", {Size=UDim2.new(0.5, 0, 0, 1), AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,82), BackgroundColor3=T.CardStroke, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=KeyContent})

-- Description
C("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 90),
    BackgroundTransparency = 1,
    Text = "Enter your license key to continue.\nJoin our Discord to get a key.",
    TextColor3 = T.TextSec,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    Parent = KeyContent,
})

-- Key input box
local KeyInputBox = C("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    Position = UDim2.new(0, 0, 0, 126),
    BackgroundColor3 = T.Card,
    BackgroundTransparency = T.CardTrans,
    BorderSizePixel = 0,
    Parent = KeyContent,
})
Corner(KeyInputBox, T.CornerSm)
Stroke(KeyInputBox, T.CardStroke, 1, 0.6)

local KeyInput = C("TextBox", {
    Size = UDim2.new(1, -16, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "Enter key here...",
    PlaceholderColor3 = T.TextMuted,
    TextColor3 = T.TextPri,
    TextSize = 14,
    Font = Enum.Font.Code,
    ClearTextOnFocus = false,
    Parent = KeyInputBox,
})

-- Key status label
local KeyStatus = C("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0, 170),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = T.Red,
    TextSize = 11,
    Font = Enum.Font.GothamSemibold,
    Parent = KeyContent,
})

-- Verify button
local KeyBtn = C("TextButton", {
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.new(0, 0, 0, 194),
    BackgroundColor3 = T.BtnPri,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Text = "VERIFY KEY",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Parent = KeyContent,
})
Corner(KeyBtn, T.CornerSm)

KeyBtn.MouseEnter:Connect(function() Tw(KeyBtn, 0.2, {BackgroundColor3 = T.BtnPriHov}) end)
KeyBtn.MouseLeave:Connect(function() Tw(KeyBtn, 0.2, {BackgroundColor3 = T.BtnPri}) end)

-- Discord Copy button (copies Discord invite to clipboard)
local DiscordBtn = C("TextButton", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 234),
    BackgroundColor3 = Color3.fromRGB(88, 101, 242),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Text = "📋 Copy Discord Invite  —  Get Your Key",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.GothamSemibold,
    AutoButtonColor = false,
    Parent = KeyContent,
})
Corner(DiscordBtn, T.CornerSm)

DiscordBtn.MouseEnter:Connect(function() Tw(DiscordBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(110, 120, 255)}) end)
DiscordBtn.MouseLeave:Connect(function() Tw(DiscordBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}) end)

DiscordBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/hHQ97ATpR9") end)
    DiscordBtn.Text = "✓ Discord link copied to clipboard!"
    DiscordBtn.TextColor3 = Color3.fromRGB(130, 255, 130)
    task.wait(2)
    DiscordBtn.Text = "📋 Copy Discord Invite  —  Get Your Key"
    DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

-- Copyright footer in key frame
C("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 272),
    BackgroundTransparency = 1,
    Text = "© SYNOXHUB  |  dc:siberguvenlik  |  All rights reserved",
    TextColor3 = T.TextMuted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center,
    Parent = KeyContent,
})

-- ═══════════════════════════════════════════════════════════════
-- KEY VALIDATION LOGIC (Multi-CDN Proxy — NO direct GitHub hit)
-- ═══════════════════════════════════════════════════════════════
local validKeys = {}

-- CDN proxy URLs — jsDelivr and Statically are free CDNs that mirror GitHub
-- They DON'T count against GitHub's rate limit at all
local KEY_URLS = {
    "https://raw.githubusercontent.com/emrself/mining/main/keys.txt", -- GitHub raw (most reliable from executor)
    "https://cdn.jsdelivr.net/gh/emrself/mining@main/keys.txt",       -- jsDelivr CDN (fallback)
    "https://cdn.statically.io/gh/emrself/mining/main/keys.txt",      -- Statically CDN (fallback 2)
}

local function fetchKeysFromUrl(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and res and #res > 0 then
        return res
    end
    return nil
end

local function parseKeys(rawText)
    local keys = {}
    for line in rawText:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            keys[trimmed:lower()] = true
        end
    end
    return keys
end

local function fetchKeys()
    for _, url in ipairs(KEY_URLS) do
        local raw = fetchKeysFromUrl(url)
        if raw then
            validKeys = parseKeys(raw)
            return true
        end
    end
    return false
end

-- Returns fresh keys table or nil on all failures
local function fetchFreshKeys()
    for _, url in ipairs(KEY_URLS) do
        local raw = fetchKeysFromUrl(url)
        if raw then
            return parseKeys(raw)
        end
    end
    return nil
end

local function validateKey(input)
    local trimmed = input:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then return false end
    return validKeys[trimmed:lower()] == true
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN HUB UI (Hidden until key validated)
-- ═══════════════════════════════════════════════════════════════
local OuterFrame = C("Frame", {
    Name = "HubOuter",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 542, 0, 432),
    BackgroundColor3 = T.Outer,
    BackgroundTransparency = T.OuterTrans,
    BorderSizePixel = 0,
    Visible = false,
    Parent = SG,
})
Corner(OuterFrame, T.CornerLg)
Stroke(OuterFrame, T.OuterStroke, 1.5, 0.3)

local MainFrame = C("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 530, 0, 420),
    BackgroundColor3 = T.Bg,
    BackgroundTransparency = T.BgTrans,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = OuterFrame,
})
Corner(MainFrame, T.Corner)
Stroke(MainFrame, T.PanelStroke, 1, 0.5)

-- Accent glow line
C("Frame", {Size=UDim2.new(1,0,0,3), Position=UDim2.new(0,0,0,36), BackgroundColor3=T.Accent, BackgroundTransparency=0.6, BorderSizePixel=0, ZIndex=5, Parent=MainFrame})

-- Title bar
local HubTitleBar = C("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = T.TitleBar,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = MainFrame,
})
Corner(HubTitleBar, T.Corner)
C("Frame", {Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,1,-10), BackgroundColor3=T.TitleBar, BackgroundTransparency=0.1, BorderSizePixel=0, ZIndex=10, Parent=HubTitleBar})

C("TextLabel", {
    Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,14,0,0),
    BackgroundTransparency=1, Text="🎵  IEM7R — Rhythm Auto v5.0", TextColor3=T.TextPri,
    TextSize=15, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11, Parent=HubTitleBar
})
C("Frame", {Size=UDim2.new(0,50,0,2), Position=UDim2.new(0,14,1,-2), BackgroundColor3=T.Accent, BackgroundTransparency=0.3, BorderSizePixel=0, ZIndex=12, Parent=HubTitleBar})

-- Status badge in title bar (always visible)
local StatusBadge = C("Frame", {
    Size=UDim2.new(0, 72, 0, 22), Position=UDim2.new(1, -152, 0.5, -11),
    BackgroundColor3=Color3.fromRGB(40, 40, 50), BackgroundTransparency=0.3,
    BorderSizePixel=0, ZIndex=13, Parent=HubTitleBar,
})
Corner(StatusBadge, UDim.new(0, 6))

-- Status dot (green=ON, yellow=OFF)
local BadgeDot = C("Frame", {
    Size=UDim2.new(0, 8, 0, 8), Position=UDim2.new(0, 7, 0.5, -4),
    BackgroundColor3=T.Yellow, BorderSizePixel=0, ZIndex=14, Parent=StatusBadge,
})
Corner(BadgeDot, UDim.new(1, 0))

-- Status text
local BadgeText = C("TextLabel", {
    Size=UDim2.new(1, -22, 1, 0), Position=UDim2.new(0, 20, 0, 0),
    BackgroundTransparency=1, Text="OFF", TextColor3=T.Yellow,
    TextSize=11, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=14, Parent=StatusBadge,
})

-- Function to update status badge
local function updateStatusBadge()
    if CFG.enabled then
        BadgeText.Text = "ON"
        BadgeText.TextColor3 = T.Green
        BadgeDot.BackgroundColor3 = T.Green
        StatusBadge.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
    else
        BadgeText.Text = "OFF"
        BadgeText.TextColor3 = T.Yellow
        BadgeDot.BackgroundColor3 = T.Yellow
        StatusBadge.BackgroundColor3 = Color3.fromRGB(50, 45, 20)
    end
end

-- Close btn
local HubClose = C("TextButton", {
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-38,0.5,-15),
    BackgroundColor3=T.BtnSec, BackgroundTransparency=0.4, Text="X", TextColor3=Color3.fromRGB(200,200,210),
    TextSize=16, Font=Enum.Font.GothamBold, BorderSizePixel=0, ZIndex=14, AutoButtonColor=false, Parent=HubTitleBar
})
Corner(HubClose, T.CornerSm)
HubClose.MouseEnter:Connect(function() Tw(HubClose, 0.2, {BackgroundColor3=T.BtnDanger, BackgroundTransparency=0.1, TextColor3=Color3.fromRGB(255,255,255)}) end)
HubClose.MouseLeave:Connect(function() Tw(HubClose, 0.2, {BackgroundColor3=T.BtnSec, BackgroundTransparency=0.4, TextColor3=Color3.fromRGB(200,200,210)}) end)

-- Minimize btn
local HubMin = C("TextButton", {
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-72,0.5,-15),
    BackgroundColor3=T.BtnSec, BackgroundTransparency=0.4, Text="-", TextColor3=Color3.fromRGB(200,200,210),
    TextSize=20, Font=Enum.Font.GothamBold, BorderSizePixel=0, ZIndex=14, AutoButtonColor=false, Parent=HubTitleBar
})
Corner(HubMin, T.CornerSm)
HubMin.MouseEnter:Connect(function() Tw(HubMin, 0.2, {BackgroundColor3=Color3.fromRGB(60,60,75), BackgroundTransparency=0.2, TextColor3=Color3.fromRGB(255,255,255)}) end)
HubMin.MouseLeave:Connect(function() Tw(HubMin, 0.2, {BackgroundColor3=T.BtnSec, BackgroundTransparency=0.4, TextColor3=Color3.fromRGB(200,200,210)}) end)

-- Dragging
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
HubTitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = inp.Position; startPos = OuterFrame.Position
        inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
HubTitleBar.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
end)
UIS.InputChanged:Connect(function(inp)
    if inp == dragInput and dragging then
        local d = inp.Position - dragStart
        OuterFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════════════════════════
local ContentArea = C("Frame", {
    Size = UDim2.new(1, 0, 1, -36),
    Position = UDim2.new(0, 0, 0, 36),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = MainFrame,
})

local TabBar = C("Frame", {
    Size = UDim2.new(1, -16, 0, 34),
    Position = UDim2.new(0, 8, 0, 6),
    BackgroundTransparency = 1,
    Parent = ContentArea,
})
C("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=TabBar})

local PageContainer = C("Frame", {
    Size = UDim2.new(1, -16, 1, -72),
    Position = UDim2.new(0, 8, 0, 44),
    BackgroundColor3 = T.Panel,
    BackgroundTransparency = T.PanelTrans,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = ContentArea,
})
Corner(PageContainer, T.Corner)
Stroke(PageContainer, T.PanelStroke, 1, 0.6)

-- ═══════════════════════════════════════════════════════════════
-- COPYRIGHT FOOTER BAR
-- ═══════════════════════════════════════════════════════════════
local FooterBar = C("Frame", {
    Size = UDim2.new(1, -16, 0, 24),
    Position = UDim2.new(0, 8, 1, -26),
    BackgroundTransparency = 1,
    Parent = ContentArea,
})

-- Copyright text left
C("TextLabel", {
    Size = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "© IEM7R  |  dc:siberguvenlik",
    TextColor3 = T.TextMuted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = FooterBar,
})

-- Discord link right (clickable)
local FooterDiscord = C("TextButton", {
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "🔗 Discord  |  All rights reserved",
    TextColor3 = T.TextMuted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    AutoButtonColor = false,
    Parent = FooterBar,
})
FooterDiscord.MouseEnter:Connect(function() FooterDiscord.TextColor3 = T.Accent end)
FooterDiscord.MouseLeave:Connect(function() FooterDiscord.TextColor3 = T.TextMuted end)
FooterDiscord.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/hHQ97ATpR9") end)
    FooterDiscord.Text = "✓ Discord copied!"
    task.wait(1.5)
    FooterDiscord.Text = "🔗 Discord  |  All rights reserved"
end)

-- Pages
local pages = {}
local tabBtns = {}
local tabNames = {"🏠 Home", "⚙ Settings", "🎯 Accuracy"}

for idx, name in ipairs(tabNames) do
    local page = C("ScrollingFrame", {
        Name = "Page"..idx,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Scroll,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = (idx == 1),
        Parent = PageContainer,
    })
    Pad(page, 10, 10, 10, 10)
    C("UIListLayout", {Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, Parent=page})
    pages[idx] = page

    local btn = C("TextButton", {
        Size = UDim2.new(0, 130, 1, 0),
        BackgroundColor3 = idx==1 and Color3.fromRGB(40,40,50) or T.Panel,
        BackgroundTransparency = idx==1 and 0.2 or 0.5,
        Text = name,
        TextColor3 = idx==1 and T.TextAccent or T.TextSec,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = idx,
        Parent = TabBar,
    })
    Corner(btn, T.CornerSm)
    Stroke(btn, T.CardStroke, 1, 0.6)
    tabBtns[idx] = btn
end

local function switchTab(targetIdx)
    for i, page in ipairs(pages) do
        page.Visible = (i == targetIdx)
        local btn = tabBtns[i]
        if i == targetIdx then
            Tw(btn, 0.25, {BackgroundColor3=Color3.fromRGB(40,40,50), BackgroundTransparency=0.2, TextColor3=T.TextAccent})
        else
            Tw(btn, 0.25, {BackgroundColor3=T.Panel, BackgroundTransparency=0.5, TextColor3=T.TextSec})
        end
    end
end
for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- ═══════════════════════════════════════════════════════════════
-- HOME PAGE
-- ═══════════════════════════════════════════════════════════════
local homePage = pages[1]

-- Status card
local StatusCard = C("Frame", {Size=UDim2.new(1,0,0,60), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, LayoutOrder=1, Parent=homePage})
Corner(StatusCard, T.CornerSm); Stroke(StatusCard, T.CardStroke, 1, 0.6); Pad(StatusCard, 8, 10, 8, 10)

C("TextLabel", {Size=UDim2.new(1,0,0,14), BackgroundTransparency=1, Text="STATUS", TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=StatusCard})
local StatusVal = C("TextLabel", {Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,16), BackgroundTransparency=1, Text="⏸ Waiting for key...", TextColor3=T.Yellow, TextSize=13, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=StatusCard})
local StatusDetail = C("TextLabel", {Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,36), BackgroundTransparency=1, Text="0 lanes | Toggle: RightShift | UI: RightControl", TextColor3=T.TextSec, TextSize=10, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=StatusCard})

-- Stats row
local StatsRow = C("Frame", {Size=UDim2.new(1,0,0,55), BackgroundTransparency=1, LayoutOrder=2, Parent=homePage})

local function makeStatCard(name, parent, posX, color)
    local card = C("Frame", {Size=UDim2.new(0.24,-4,1,0), Position=UDim2.new(posX,0,0,0), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, Parent=parent})
    Corner(card, T.CornerSm); Stroke(card, T.CardStroke, 1, 0.6); Pad(card, 6, 8, 6, 8)
    C("TextLabel", {Size=UDim2.new(1,0,0,12), BackgroundTransparency=1, Text=name:upper(), TextColor3=T.TextMuted, TextSize=9, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=card})
    local val = C("TextLabel", {Name="Val", Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,14), BackgroundTransparency=1, Text="0", TextColor3=color, TextSize=18, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=card})
    return val
end

local perfVal  = makeStatCard("Perfect", StatsRow, 0, T.AccentGlow)
local goodVal  = makeStatCard("Good", StatsRow, 0.25, T.Green)
local okayVal  = makeStatCard("Okay", StatsRow, 0.50, T.Yellow)
local badVal   = makeStatCard("Bad", StatsRow, 0.75, T.Orange)

-- Lane info card
local LaneCard = C("Frame", {Size=UDim2.new(1,0,0,95), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, LayoutOrder=3, Parent=homePage})
Corner(LaneCard, T.CornerSm); Stroke(LaneCard, T.CardStroke, 1, 0.6); Pad(LaneCard, 8, 10, 8, 10)
C("TextLabel", {Size=UDim2.new(1,0,0,12), BackgroundTransparency=1, Text="DETECTED LANES", TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=LaneCard})
local LaneVal = C("TextLabel", {Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,18), BackgroundTransparency=1, Text="Not detected yet", TextColor3=T.TextAccent, TextSize=13, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=LaneCard})
local LaneDebug = C("TextLabel", {Size=UDim2.new(1,0,0,42), Position=UDim2.new(0,0,0,38), BackgroundTransparency=1, Text="", TextColor3=T.TextMuted, TextSize=8, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, Parent=LaneCard})

-- Total / combo card
local TotalCard = C("Frame", {Size=UDim2.new(1,0,0,40), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, LayoutOrder=4, Parent=homePage})
Corner(TotalCard, T.CornerSm); Stroke(TotalCard, T.CardStroke, 1, 0.6); Pad(TotalCard, 6, 10, 6, 10)
local TotalVal = C("TextLabel", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="Total: 0  |  Holds: 0  |  Miss: 0", TextColor3=T.TextSec, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=TotalCard})

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS PAGE
-- ═══════════════════════════════════════════════════════════════
local settingsPage = pages[2]

-- Helper: keybind button
local function makeKeybindRow(label, currentKey, order, parent, onChange)
    local row = C("Frame", {Size=UDim2.new(1,0,0,38), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, LayoutOrder=order, Parent=parent})
    Corner(row, T.CornerSm); Stroke(row, T.CardStroke, 1, 0.6); Pad(row, 6, 10, 6, 10)
    C("TextLabel", {Size=UDim2.new(0.55,0,1,0), BackgroundTransparency=1, Text=label, TextColor3=T.TextPri, TextSize=12, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})

    local kbBtn = C("TextButton", {
        Size=UDim2.new(0.4,0,0,26), Position=UDim2.new(0.58,0,0.5,-13),
        BackgroundColor3=T.BtnSec, BackgroundTransparency=0.3, Text=KC_NAMES[currentKey] or "?",
        TextColor3=T.TextAccent, TextSize=12, Font=Enum.Font.Code, BorderSizePixel=0, AutoButtonColor=false, Parent=row
    })
    Corner(kbBtn, T.CornerSm)

    local listening = false
    kbBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        kbBtn.Text = "Press a key..."
        kbBtn.TextColor3 = T.Yellow

        local conn
        conn = UIS.InputBegan:Connect(function(inp, gp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                local newKey = inp.KeyCode
                if newKey ~= Enum.KeyCode.Unknown then
                    kbBtn.Text = KC_NAMES[newKey] or newKey.Name
                    kbBtn.TextColor3 = T.TextAccent
                    listening = false
                    conn:Disconnect()
                    if onChange then onChange(newKey) end
                end
            end
        end)
    end)

    return kbBtn
end

C("TextLabel", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="KEYBINDS", TextColor3=T.TextMuted, TextSize=11, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1, Parent=settingsPage})

makeKeybindRow("Toggle Auto-Player", CFG.toggleKey, 2, settingsPage, function(k) CFG.toggleKey = k end)
makeKeybindRow("Toggle UI (Show/Hide)", CFG.uiToggleKey, 3, settingsPage, function(k) CFG.uiToggleKey = k end)

-- ═══════════════════════════════════════════════════════════════
-- LANE KEYBINDS (dynamic, up to 4 lanes)
-- ═══════════════════════════════════════════════════════════════
C("TextLabel", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="LANE KEYBINDS  (click to override, auto-detected at runtime)", TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=4, Parent=settingsPage})

local laneKbRows = {}  -- [1..4] = {row, label, btn, autoLabel}
local laneLabels = {"Lane 1 (Left)", "Lane 2", "Lane 3", "Lane 4 (Right)"}
local laneColors = {Color3.fromRGB(80,220,120), Color3.fromRGB(0,180,216), Color3.fromRGB(200,160,255), Color3.fromRGB(255,140,80)}

for li = 1, 4 do
    local row = C("Frame", {Size=UDim2.new(1,0,0,42), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, LayoutOrder=4+li, Visible=false, Parent=settingsPage})
    Corner(row, T.CornerSm); Stroke(row, T.CardStroke, 1, 0.6); Pad(row, 6, 10, 6, 10)

    -- Lane color indicator
    C("Frame", {Size=UDim2.new(0,4,0,24), Position=UDim2.new(0,-4,0.5,-12), BackgroundColor3=laneColors[li], BorderSizePixel=0, Parent=row})

    local lbl = C("TextLabel", {Size=UDim2.new(0.35,0,0,14), Position=UDim2.new(0,4,0,0), BackgroundTransparency=1, Text=laneLabels[li], TextColor3=T.TextPri, TextSize=12, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})

    local autoLbl = C("TextLabel", {Size=UDim2.new(0.25,0,0,12), Position=UDim2.new(0,4,0,18), BackgroundTransparency=1, Text="Auto: ?", TextColor3=T.TextMuted, TextSize=9, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})

    local kbBtn = C("TextButton", {
        Size=UDim2.new(0.28,0,0,28), Position=UDim2.new(0.50,0,0.5,-14),
        BackgroundColor3=T.BtnSec, BackgroundTransparency=0.3, Text="Auto",
        TextColor3=T.TextAccent, TextSize=13, Font=Enum.Font.Code, BorderSizePixel=0, AutoButtonColor=false, Parent=row
    })
    Corner(kbBtn, T.CornerSm)

    -- Reset to auto button
    local resetBtn = C("TextButton", {
        Size=UDim2.new(0.16,0,0,22), Position=UDim2.new(0.82,0,0.5,-11),
        BackgroundColor3=Color3.fromRGB(55,55,65), BackgroundTransparency=0.3, Text="Reset",
        TextColor3=T.TextMuted, TextSize=9, Font=Enum.Font.Gotham, BorderSizePixel=0, AutoButtonColor=false, Parent=row
    })
    Corner(resetBtn, T.CornerSm)

    local listening = false
    kbBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        kbBtn.Text = "Press..."
        kbBtn.TextColor3 = T.Yellow

        local conn
        conn = UIS.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode ~= Enum.KeyCode.Unknown then
                local newKey = inp.KeyCode
                kbBtn.Text = KC_NAMES[newKey] or newKey.Name
                kbBtn.TextColor3 = laneColors[li]
                CFG.laneKeyOverrides[li] = newKey
                listening = false
                conn:Disconnect()
                -- Re-apply to engine
                if rhythmRoot then
                    engineLanes, engineCount = discoverLanes(rhythmRoot); initLS()
                    local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
                    LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
                end
            end
        end)
    end)

    resetBtn.MouseButton1Click:Connect(function()
        CFG.laneKeyOverrides[li] = nil
        kbBtn.Text = "Auto"
        kbBtn.TextColor3 = T.TextAccent
        -- Re-apply
        if rhythmRoot then
            engineLanes, engineCount = discoverLanes(rhythmRoot); initLS()
            local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
            LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
        end
    end)

    laneKbRows[li] = {row=row, label=lbl, btn=kbBtn, autoLabel=autoLbl, resetBtn=resetBtn}
end

-- Function to read live KeyHint.Text directly from receptor
local function readLiveKeyHint(laneIdx)
    if not engineLanes[laneIdx] then return "" end
    local rec = engineLanes[laneIdx].receptor
    if not rec then return "" end
    local kh = rec:FindFirstChild("KeyHint")
    if kh and kh:IsA("TextLabel") then return kh.Text or "" end
    return ""
end

-- Function to update lane keybind UI when lanes are discovered
local function updateLaneKeybindUI()
    for li = 1, 4 do
        local lkr = laneKbRows[li]
        if li <= engineCount then
            lkr.row.Visible = true
            local ld = engineLanes[li]
            if ld then
                local liveText = readLiveKeyHint(li)
                local override = CFG.laneKeyOverrides[li]

                if override then
                    -- Manual override active
                    lkr.btn.Text = KC_NAMES[override] or override.Name
                    lkr.btn.TextColor3 = laneColors[li]
                    if liveText ~= "" then
                        lkr.autoLabel.Text = "GUI: " .. liveText:upper() .. " (overridden → " .. (KC_NAMES[override] or "?") .. ")"
                    else
                        lkr.autoLabel.Text = "GUI: waiting... (overridden → " .. (KC_NAMES[override] or "?") .. ")"
                    end
                else
                    -- Using auto-detected or fallback
                    if liveText ~= "" then
                        lkr.autoLabel.Text = "GUI: " .. liveText:upper() .. " ✓"
                        lkr.autoLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
                    else
                        lkr.autoLabel.Text = "GUI: empty (using fallback: " .. (ld.keyName or "?") .. ")"
                        lkr.autoLabel.TextColor3 = T.Yellow
                    end
                    lkr.btn.Text = ld.keyName or "Auto"
                    lkr.btn.TextColor3 = T.TextAccent
                end
            end
        else
            lkr.row.Visible = false
        end
    end
end

-- Refresh button: re-reads KeyHint texts from game GUI and re-discovers lanes
local refreshBtn = C("TextButton", {
    Size=UDim2.new(1,0,0,30), BackgroundColor3=T.BtnPri, BackgroundTransparency=0.15,
    Text="🔄 Refresh Keys from Game GUI", TextColor3=Color3.fromRGB(255,255,255),
    TextSize=12, Font=Enum.Font.GothamSemibold, BorderSizePixel=0, AutoButtonColor=false,
    LayoutOrder=9, Parent=settingsPage,
})
Corner(refreshBtn, T.CornerSm)
refreshBtn.MouseEnter:Connect(function() Tw(refreshBtn, 0.2, {BackgroundColor3=T.BtnPriHov}) end)
refreshBtn.MouseLeave:Connect(function() Tw(refreshBtn, 0.2, {BackgroundColor3=T.BtnPri}) end)

refreshBtn.MouseButton1Click:Connect(function()
    if not rhythmRoot then
        refreshBtn.Text = "⚠ No Rhythm UI found!"
        refreshBtn.TextColor3 = T.Red
        task.wait(1.5)
        refreshBtn.Text = "🔄 Refresh Keys from Game GUI"
        refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
        return
    end

    refreshBtn.Text = "⏳ Reading receptors..."

    -- Force clear non-overridden lane keys so discoverLanes reads fresh
    engineLanes, engineCount = discoverLanes(rhythmRoot); initLS()
    local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
    LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
    updateLaneKeybindUI()

    -- Show what was found
    local found = {}
    for li = 1, engineCount do
        local live = readLiveKeyHint(li)
        if live ~= "" then table.insert(found, live:upper()) else table.insert(found, "?") end
    end
    refreshBtn.Text = "✓ GUI Keys: " .. table.concat(found, "  ")
    refreshBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
    task.wait(2)
    refreshBtn.Text = "🔄 Refresh Keys from Game GUI"
    refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
end)

-- Auto-polling: when lanes are found but KeyHint is empty, poll every 0.5s for up to 15s
local function startKeyHintPolling()
    task.spawn(function()
        for attempt = 1, 30 do  -- 30 * 0.5s = 15 seconds max
            task.wait(0.5)
            if not rhythmRoot or not rhythmRoot.Parent then return end
            if engineCount == 0 then return end

            local allFilled = true
            for li = 1, engineCount do
                local live = readLiveKeyHint(li)
                if live == "" then allFilled = false; break end
            end

            if allFilled then
                -- All KeyHints now have text, re-discover with real keys
                engineLanes, engineCount = discoverLanes(rhythmRoot); initLS()
                local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
                LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
                updateLaneKeybindUI()
                return
            end
        end
    end)
end

C("TextLabel", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text="HIT ZONE TUNING", TextColor3=T.TextMuted, TextSize=11, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=10, Parent=settingsPage})

-- Helper: slider
local function makeSlider(label, min, max, default, order, parent, unit, onChange)
    local row = C("Frame", {Size=UDim2.new(1,0,0,48), BackgroundColor3=T.Card, BackgroundTransparency=T.CardTrans, BorderSizePixel=0, LayoutOrder=order, Parent=parent})
    Corner(row, T.CornerSm); Stroke(row, T.CardStroke, 1, 0.6); Pad(row, 6, 10, 6, 10)

    local valLabel = C("TextLabel", {
        Size=UDim2.new(0.3,0,0,16), Position=UDim2.new(0.68,0,0,0),
        BackgroundTransparency=1, Text=tostring(default)..(unit or ""), TextColor3=T.TextAccent,
        TextSize=12, Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Right, Parent=row
    })
    C("TextLabel", {Size=UDim2.new(0.65,0,0,16), BackgroundTransparency=1, Text=label, TextColor3=T.TextPri, TextSize=12, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})

    local track = C("Frame", {Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,28), BackgroundColor3=Color3.fromRGB(50,50,60), BorderSizePixel=0, Parent=row})
    Corner(track, UDim.new(0,3))

    local fill = C("Frame", {Size=UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3=T.Accent, BorderSizePixel=0, Parent=track})
    Corner(fill, UDim.new(0,3))

    local knob = C("Frame", {
        Size=UDim2.new(0,14,0,14), Position=UDim2.new((default-min)/(max-min),-7,0.5,-7),
        BackgroundColor3=T.AccentGlow, BorderSizePixel=0, Parent=track
    })
    Corner(knob, UDim.new(1,0))
    Stroke(knob, T.Bg, 2, 0)

    local sliding = false
    local function update(inputX)
        local relX = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + relX * (max - min) + 0.5)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -7, 0.5, -7)
        valLabel.Text = tostring(val) .. (unit or "")
        if onChange then onChange(val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true; update(inp.Position.X)
        end
    end)
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            update(inp.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    return valLabel
end

makeSlider("Hit Zone Above", 8, 200, CFG.hitAbove, 11, settingsPage, "px", function(v) CFG.hitAbove = v end)
makeSlider("Hit Zone Below", 8, 100, CFG.hitBelow, 12, settingsPage, "px", function(v) CFG.hitBelow = v end)
makeSlider("Tap Hold Frames", 1, 6, CFG.tapFrames, 13, settingsPage, "f", function(v) CFG.tapFrames = v end)

-- ═══════════════════════════════════════════════════════════════
-- ACCURACY PAGE
-- ═══════════════════════════════════════════════════════════════
local accPage = pages[3]

C("TextLabel", {Size=UDim2.new(1,0,0,34), BackgroundTransparency=1, Text="Adjust accuracy distribution.\nLower Perfect % to look more human.", TextColor3=T.TextSec, TextSize=11, Font=Enum.Font.Gotham, TextWrapped=true, LayoutOrder=1, Parent=accPage})

local accWarn = C("TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text="Sum: 100% ✓", TextColor3=T.Green, TextSize=11, Font=Enum.Font.GothamSemibold, LayoutOrder=2, Parent=accPage})

local function updateAccSum()
    local sum = CFG.perfectPct + CFG.goodPct + CFG.okayPct + CFG.badPct
    if sum == 100 then
        accWarn.Text = "Sum: " .. sum .. "% ✓"
        accWarn.TextColor3 = T.Green
    else
        accWarn.Text = "Sum: " .. sum .. "% — Should be 100%!"
        accWarn.TextColor3 = T.Red
    end
end

makeSlider("Perfect %", 0, 100, CFG.perfectPct, 3, accPage, "%", function(v) CFG.perfectPct = v; updateAccSum() end)
makeSlider("Good %", 0, 100, CFG.goodPct, 4, accPage, "%", function(v) CFG.goodPct = v; updateAccSum() end)
makeSlider("Okay %", 0, 100, CFG.okayPct, 5, accPage, "%", function(v) CFG.okayPct = v; updateAccSum() end)
makeSlider("Bad / Miss %", 0, 100, CFG.badPct, 6, accPage, "%", function(v) CFG.badPct = v; updateAccSum() end)

C("TextLabel", {Size=UDim2.new(1,0,0,14), BackgroundTransparency=1, Text="DELAY TUNING (seconds added per tier)", TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=10, Parent=accPage})

makeSlider("Good Delay", 0, 100, math.floor(CFG.goodDelay*1000), 11, accPage, "ms", function(v) CFG.goodDelay = v/1000 end)
makeSlider("Okay Delay", 0, 150, math.floor(CFG.okayDelay*1000), 12, accPage, "ms", function(v) CFG.okayDelay = v/1000 end)
makeSlider("Bad Delay", 0, 250, math.floor(CFG.badDelay*1000), 13, accPage, "ms", function(v) CFG.badDelay = v/1000 end)

-- ═══════════════════════════════════════════════════════════════
-- ENGINE (v4 Lane State Machine — integrated)
-- ═══════════════════════════════════════════════════════════════
local function resolveKey(text)
    if not text or text == "" then return nil, nil end
    local k = text:upper():gsub("%s+", "")
    return KEY_LOOKUP[k], k
end

local function discoverLanes(root)
    local recFrame = root:FindFirstChild("Receptors")
    if not recFrame then return {}, 0 end

    -- Collect real receptor frames (filter out UI layouts, decorations)
    local allRecs = {}
    for _, c in ipairs(recFrame:GetChildren()) do
        if c:IsA("Frame") and c.AbsoluteSize.X > 5 and c.AbsoluteSize.Y > 5 then
            table.insert(allRecs, c)
        end
    end

    -- Sort by visual X position (left to right) — NOT by name index
    table.sort(allRecs, function(a, b)
        return a.AbsolutePosition.X < b.AbsolutePosition.X
    end)

    local result = {}
    local count = #allRecs
    for order, rec in ipairs(allRecs) do
        local kc, kn
        local hint = rec:FindFirstChild("KeyHint")
        if hint and hint:IsA("TextLabel") and hint.Text ~= "" then kc, kn = resolveKey(hint.Text) end
        if not kc then
            if count == 2 then
                kc = ({Enum.KeyCode.F, Enum.KeyCode.J})[order]; kn = ({"F","J"})[order]
            elseif count == 4 then
                kc = ({Enum.KeyCode.D,Enum.KeyCode.F,Enum.KeyCode.J,Enum.KeyCode.K})[order]
                kn = ({"D","F","J","K"})[order]
            else kc = Enum.KeyCode.F; kn = "?" end
        end
        table.insert(result, {receptor=rec, keyCode=kc, keyName=kn or "?", idx=order})
    end
    -- Apply manual overrides from CFG
    for order, entry in ipairs(result) do
        local override = CFG.laneKeyOverrides[order]
        if override then
            entry.keyCode = override
            entry.keyName = KC_NAMES[override] or override.Name
        end
    end
    return result, count
end

-- Build mapping from game lane index → engine lane order
local laneIdxMap = {}
local function buildLaneIdxMap()
    laneIdxMap = {}
    for order, ld in ipairs(engineLanes) do
        local ri = ld.receptor.Name:match("(%d+)$")
        if ri then laneIdxMap[tonumber(ri)] = order end
    end
    for i = 1, engineCount do
        if not laneIdxMap[i] then laneIdxMap[i] = i end
    end
end

local function initLS()
    laneState = {}
    for i = 1, engineCount do laneState[i] = {pressed=false, pressFrame=0, activeNote=nil, isHold=false, tapRelease=0} end
    buildLaneIdxMap()
end

local function recY(i)
    local ld = engineLanes[i]; if not ld then return 0 end
    local p = ld.receptor.AbsolutePosition; local s = ld.receptor.AbsoluteSize
    return p.Y + s.Y/2
end
local function recX(i)
    local ld = engineLanes[i]; if not ld then return 0 end
    local p = ld.receptor.AbsolutePosition; local s = ld.receptor.AbsoluteSize
    return p.X + s.X/2
end

local function isActive(n) return n and n.Parent and n.Visible and n.Parent.Name ~= "OffscreenPool" end
local function hasTail(n) local t = n:FindFirstChild("Tail"); return t and t.Visible and t:IsA("ImageLabel") and t.AbsoluteSize.Y > 8, t end
local function tailDone(n, ry) local t = n:FindFirstChild("Tail"); if not t or not t.Visible or t.AbsoluteSize.Y < 5 then return true end; return t.AbsolutePosition.Y >= (ry - CFG.holdRelBuf) end


local function assignLane(n)
    if not n or not n.Parent or n.Parent.Name == "OffscreenPool" then return nil end

    -- Method 1: Use tagged lane index from parent folder (most reliable)
    local taggedLane = n:GetAttribute("_autoLane")
    if taggedLane and taggedLane > 0 then
        -- Map game lane index to our engine lane order
        local mapped = laneIdxMap[taggedLane]
        if mapped and mapped >= 1 and mapped <= engineCount then return mapped end
    end

    -- Method 2: Check parent folder name directly
    local p = n.Parent
    while p and p ~= game do
        local li = p.Name:match("^Lane(%d+)$")
        if li then
            local mapped = laneIdxMap[tonumber(li)]
            if mapped and mapped >= 1 and mapped <= engineCount then return mapped end
        end
        p = p.Parent
    end

    -- Method 3: Fallback to X-proximity
    local nx = n.AbsolutePosition.X + n.AbsoluteSize.X/2
    local best, bd = nil, math.huge
    for i = 1, engineCount do
        local rx = recX(i)
        if rx > 0 then
            local d = math.abs(nx - rx)
            if d < bd then bd = d; best = i end
        end
    end
    if bd > 200 then return nil end
    return best
end

local function collectNotes(root)
    local r = {}
    local lf = root:FindFirstChild("Lanes"); if not lf then return r end

    -- Recursive scan: find ALL frames with a visible Head child (notes)
    -- Tag each note with its lane folder index if found
    local function scan(parent, laneIdx)
        for _, ch in ipairs(parent:GetChildren()) do
            if ch:IsA("Frame") and isActive(ch) then
                local h = ch:FindFirstChild("Head")
                if h and h.Visible then
                    -- This is a note (has a Head) — tag with lane index
                    ch:SetAttribute("_autoLane", laneIdx or 0)
                    table.insert(r, ch)
                else
                    -- Check if this is a Lane folder
                    local li = ch.Name:match("^Lane(%d+)$")
                    if li then
                        scan(ch, tonumber(li))
                    else
                        scan(ch, laneIdx)
                    end
                end
            end
        end
    end
    scan(lf, nil)

    -- Also scan root directly for stray notes
    for _, ch in ipairs(root:GetChildren()) do
        if ch:IsA("Frame") and ch.Name ~= "Receptors" and ch.Name ~= "Lanes" and isActive(ch) then
            local h = ch:FindFirstChild("Head")
            if h and h.Visible then
                ch:SetAttribute("_autoLane", 0)
                table.insert(r, ch)
            end
        end
    end
    return r
end

-- Accuracy roll: returns delay to add
local function rollAccuracy()
    local roll = math.random(1, 100)
    local p = CFG.perfectPct
    local g = p + CFG.goodPct
    local o = g + CFG.okayPct

    if roll <= p then
        stats.perfect += 1
        return CFG.perfectDelay, "perfect"
    elseif roll <= g then
        stats.good += 1
        return CFG.goodDelay, "good"
    elseif roll <= o then
        stats.okay += 1
        return CFG.okayDelay, "okay"
    else
        stats.bad += 1
        return CFG.badDelay, "bad"
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PLATFORM DETECTION & INPUT (emulator + mobile + PC)
-- ═══════════════════════════════════════════════════════════════
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local IS_EMULATOR = UIS.TouchEnabled and UIS.MouseEnabled -- touch + mouse = emulator

-- Detect available input functions
local hasKeypress = typeof(keypress) == "function"
local hasKeyrelease = typeof(keyrelease) == "function"
local hasFiretouch = typeof(firetouchinterest) == "function"
local hasFireclick = typeof(fireclick) == "function"
local hasVIM = pcall(function() return VIM.SendKeyEvent end)
-- Get GUI inset for accurate screen coordinates
local GuiService = game:GetService("GuiService")
local guiInset = GuiService:GetGuiInset() -- Vector2: top-left inset (Roblox top bar)

local function getReceptorScreenPos(ld)
    local pos = ld.receptor.AbsolutePosition
    local sz = ld.receptor.AbsoluteSize
    -- AbsolutePosition is viewport-relative, add inset for screen coordinates
    return pos.X + sz.X/2, pos.Y + sz.Y/2 + guiInset.Y
end

local function pressK(kc, laneIdx)
    if CFG.humanize then
        local off = (math.random()*2-1)*CFG.humanizeMs
        if off > 0 then task.wait(off) end
    end

    local ld = laneIdx and engineLanes[laneIdx]

    if IS_MOBILE or IS_EMULATOR then
        -- MOBILE/EMULATOR: Click receptor center (simulates touch) + keyboard
        if ld and ld.receptor and hasVIM then
            pcall(function()
                local cx, cy = getReceptorScreenPos(ld)
                -- Move mouse to receptor first, then click
                VIM:SendMouseMoveEvent(cx, cy, game)
                VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            end)
        end
        if ld and ld.receptor and hasFiretouch then
            pcall(function() firetouchinterest(ld.receptor, ld.receptor, 0) end)
            -- Also touch all children (ReceptorVisual, etc)
            for _, child in ipairs(ld.receptor:GetDescendants()) do
                pcall(function() firetouchinterest(child, child, 0) end)
            end
        end
        if ld and ld.receptor and hasFireclick then
            pcall(function() fireclick(ld.receptor) end)
        end
        -- Also send key event (some games accept both)
        if hasVIM then
            pcall(function() VIM:SendKeyEvent(true, kc, false, game) end)
        end
        if hasKeypress then
            pcall(function() keypress(kc) end)
        end
    else
        -- PC: keyboard input
        if hasVIM then
            VIM:SendKeyEvent(true, kc, false, game)
        elseif hasKeypress then
            pcall(function() keypress(kc) end)
        end
    end
end

local function releaseK(kc, laneIdx)
    local ld = laneIdx and engineLanes[laneIdx]

    if IS_MOBILE or IS_EMULATOR then
        -- MOBILE/EMULATOR: Release click + keyboard
        if ld and ld.receptor and hasVIM then
            pcall(function()
                local cx, cy = getReceptorScreenPos(ld)
                VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
            end)
        end
        if ld and ld.receptor and hasFiretouch then
            pcall(function() firetouchinterest(ld.receptor, ld.receptor, 1) end)
        end
        if hasVIM then
            pcall(function() VIM:SendKeyEvent(false, kc, false, game) end)
        end
        if hasKeyrelease then
            pcall(function() keyrelease(kc) end)
        end
    else
        -- PC: keyboard release
        if hasVIM then
            VIM:SendKeyEvent(false, kc, false, game)
        elseif hasKeyrelease then
            pcall(function() keyrelease(kc) end)
        end
    end
end

local debugNoteTotal = 0
local debugInfo = "" -- full pipeline debug string

local function processFrame()
    if not CFG.enabled or not rhythmRoot or not rhythmRoot.Parent or engineCount == 0 then return end
    local notes = collectNotes(rhythmRoot)

    debugNoteTotal = #notes

    -- Debug: track lane 1 pipeline
    local d1_assigned = 0
    local d1_inzone = 0
    local d1_pressed = 0
    local d1_noteX = "-"
    local d1_noteY = "-"
    local d1_recY = math.floor(recY(1))
    local d1_recX = math.floor(recX(1))
    local d2_assigned = 0

    local laneHit = {}
    for _, note in ipairs(notes) do
        local li = assignLane(note)
        if not li then continue end

        -- Debug: count assignments
        if li == 1 then
            d1_assigned += 1
            d1_noteX = tostring(math.floor(note.AbsolutePosition.X + note.AbsoluteSize.X/2))
        elseif li == 2 then
            d2_assigned += 1
        end

        local ny = note.AbsolutePosition.Y + note.AbsoluteSize.Y/2
        local nd = noteData[note]
        if nd and math.abs(ny - nd.prevY) > CFG.recycleJump then noteData[note] = nil; nd = nil end

        -- NO SKIP on first frame — immediately check zone
        if not nd then
            noteData[note] = {prevY = ny, firstFrame = true}
            nd = noteData[note]
        end

        local prevY = nd.prevY
        local vel = nd.firstFrame and 0 or (ny - prevY)
        local ry = recY(li)
        local zt = ry - CFG.hitAbove
        local zb = ry + CFG.hitBelow
        local inZone = false

        -- Standard zone check
        if ny >= zt and ny <= zb then inZone = true end
        -- Velocity skip-over detection
        if not inZone and vel > 0 and prevY < zt and ny > zb then inZone = true end
        -- Predictive: will enter zone next frame
        if not inZone and vel > 0 then local pr = ny+vel; if ny < zt and pr >= zt and pr <= zb then inZone = true end end
        -- Slightly past receptor
        if not inZone and ny > ry and ny <= zb + 8 then inZone = true end
        -- MOBILE CATCH-ALL: note exists above receptor and is visible (hasn't passed yet)
        if not inZone and ny < ry and ny > ry - 300 then inZone = true end

        -- Debug: track lane 1 hit zone
        if li == 1 then
            d1_noteY = tostring(math.floor(ny))
            if inZone then d1_inzone += 1 end
        end

        if inZone then
            local isH = hasTail(note)
            local dist = math.abs(ny - ry)
            local ex = laneHit[li]
            if not ex or dist < ex.dist then laneHit[li] = {note=note, dist=dist, isHold=isH} end
        end
        nd.prevY = ny
        nd.firstFrame = false
    end

    for i = 1, engineCount do
        local st = laneState[i]
        local hit = laneHit[i]
        local ld = engineLanes[i]

        if hit then
            if not st.pressed then
                local delay, tier = rollAccuracy()
                if delay > 0 then task.wait(delay) end
                stats.total += 1
                if i == 1 then d1_pressed += 1 end
                pressK(ld.keyCode, i)
                st.pressed = true; st.pressFrame = frameTick; st.activeNote = hit.note; st.isHold = hit.isHold
                st.tapRelease = hit.isHold and 0 or (frameTick + CFG.tapFrames)
                if hit.isHold then stats.holds += 1 end
            elseif st.activeNote ~= hit.note then
                releaseK(ld.keyCode, i)
                local delay, tier = rollAccuracy()
                if delay > 0 then task.wait(delay) end
                stats.total += 1
                if i == 1 then d1_pressed += 1 end
                pressK(ld.keyCode, i)
                st.pressed = true; st.pressFrame = frameTick; st.activeNote = hit.note; st.isHold = hit.isHold
                st.tapRelease = hit.isHold and 0 or (frameTick + CFG.tapFrames)
                if hit.isHold then stats.holds += 1 end
            elseif st.isHold then
                if tailDone(hit.note, recY(i)) then
                    releaseK(ld.keyCode, i); st.pressed = false; st.activeNote = nil; st.isHold = false; st.tapRelease = 0
                end
            end
        else
            if st.pressed then
                if st.isHold then
                    if st.activeNote and isActive(st.activeNote) then
                        if tailDone(st.activeNote, recY(i)) then
                            releaseK(ld.keyCode, i); st.pressed=false; st.activeNote=nil; st.isHold=false; st.tapRelease=0
                        end
                    else releaseK(ld.keyCode, i); st.pressed=false; st.activeNote=nil; st.isHold=false; st.tapRelease=0 end
                else
                    if st.tapRelease > 0 and frameTick >= st.tapRelease then
                        releaseK(ld.keyCode, i); st.pressed=false; st.activeNote=nil; st.tapRelease=0
                    end
                end
            end
        end
    end

    -- Build lane 1 debug string
    debugInfo = "L1: assign="..d1_assigned.." zone="..d1_inzone.." press="..d1_pressed
    debugInfo = debugInfo.." nX="..d1_noteX.." nY="..d1_noteY.." rX="..d1_recX.." rY="..d1_recY
    debugInfo = debugInfo.." | L2: assign="..d2_assigned.." total="..debugNoteTotal

    if frameTick % 60 == 0 then
        for inst in pairs(noteData) do if not isActive(inst) then noteData[inst] = nil end end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- KEYHINT WATCHER
-- ═══════════════════════════════════════════════════════════════
local function watchHints(root)
    local rf = root:FindFirstChild("Receptors"); if not rf then return end
    local function hook(rec)
        local kh = rec:FindFirstChild("KeyHint")
        if kh and kh:IsA("TextLabel") then
            kh:GetPropertyChangedSignal("Text"):Connect(function()
                task.wait(0.05); engineLanes, engineCount = discoverLanes(root); initLS()
                local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
                LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
                updateLaneKeybindUI()
            end)
        end
    end
    for _, c in ipairs(rf:GetChildren()) do
        if c:IsA("Frame") and c.Name:match("^Receptor%d+$") then hook(c) end
    end
    rf.ChildAdded:Connect(function(ch)
        if ch:IsA("Frame") and ch.Name:match("^Receptor%d+$") then
            task.wait(0.15); engineLanes, engineCount = discoverLanes(root); initLS(); hook(ch)
            local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
            LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
            updateLaneKeybindUI()
        end
    end)
    rf.ChildRemoved:Connect(function(ch)
        if ch:IsA("Frame") and ch.Name:match("^Receptor%d+$") then
            task.wait(0.15)
            for i = 1, engineCount do if laneState[i] and laneState[i].pressed and engineLanes[i] then releaseK(engineLanes[i].keyCode, i) end end
            engineLanes, engineCount = discoverLanes(root); initLS(); noteData = {}
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- UI UPDATE LOOP
-- ═══════════════════════════════════════════════════════════════
local function updateUI()
    perfVal.Text = tostring(stats.perfect)
    goodVal.Text = tostring(stats.good)
    okayVal.Text = tostring(stats.okay)
    badVal.Text  = tostring(stats.bad)
    TotalVal.Text = "Total: "..stats.total.."  |  Holds: "..stats.holds.."  |  Miss: "..stats.miss
    StatusDetail.Text = engineCount.." lanes | Toggle: "..KC_NAMES[CFG.toggleKey].." | UI: "..KC_NAMES[CFG.uiToggleKey]

    if CFG.enabled then
        StatusVal.Text = "⚡ Auto-Player ACTIVE"
        StatusVal.TextColor3 = T.Green
    else
        StatusVal.Text = "⏸ Auto-Player PAUSED"
        StatusVal.TextColor3 = T.Yellow
    end

    -- Debug: show per-lane info + available methods
    local dbg = {}
    for i = 1, engineCount do
        local ld = engineLanes[i]
        local rx = ld and math.floor(recX(i)) or 0
        local pr = laneState[i] and laneState[i].pressed and "P" or "-"
        local kn = ld and ld.keyName or "?"
        table.insert(dbg, "L"..i..":"..kn.."(x"..rx..")"..pr)
    end
    local mt = IS_EMULATOR and "EMU" or (IS_MOBILE and "MOB" or "PC")
    mt = mt.." FT:"..(hasFiretouch and "Y" or "N")
    mt = mt.." KP:"..(hasKeypress and "Y" or "N")
    mt = mt.." VM:"..(hasVIM and "Y" or "N")
    LaneDebug.Text = "["..mt.."] "..debugInfo
end

-- ═══════════════════════════════════════════════════════════════
-- INPUT HANDLER
-- ═══════════════════════════════════════════════════════════════
UIS.InputBegan:Connect(function(inp, gp)
    if not keyValidated then return end
    if inp.KeyCode == CFG.toggleKey then
        CFG.enabled = not CFG.enabled
        updateStatusBadge()
        if not CFG.enabled then
            for i = 1, engineCount do
                if laneState[i] and laneState[i].pressed and engineLanes[i] then
                    releaseK(engineLanes[i].keyCode, i)
                    laneState[i].pressed = false; laneState[i].activeNote = nil
                end
            end
            noteData = {}
        end
    elseif inp.KeyCode == CFG.uiToggleKey then
        if OuterFrame.Visible then
            -- Smooth close animation
            Tw(OuterFrame, 0.3, {Size = UDim2.new(0, 542, 0, 0)})
            task.wait(0.3)
            OuterFrame.Visible = false
            OuterFrame.Size = UDim2.new(0, 542, 0, 432)
        else
            -- Smooth open animation
            OuterFrame.Visible = true
            OuterFrame.Size = UDim2.new(0, 542, 0, 0)
            Tw(OuterFrame, 0.3, {Size = UDim2.new(0, 542, 0, 432)})
        end
    end
end)

-- X button: Close GUI with fade animation (script keeps running, toggle key reopens)
HubClose.MouseButton1Click:Connect(function()
    Tw(OuterFrame, 0.25, {Size = UDim2.new(0, 542, 0, 0)})
    task.wait(0.25)
    OuterFrame.Visible = false
    OuterFrame.Size = UDim2.new(0, 542, 0, 432) -- reset size for next open
end)

-- - button: Minimize (instant hide, script runs hidden, toggle key reopens)
HubMin.MouseButton1Click:Connect(function()
    OuterFrame.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════
-- MOBILE UI (floating toggle buttons + responsive scaling)
-- ═══════════════════════════════════════════════════════════════
if IS_MOBILE then
    -- Scale down the hub for mobile screens
    local viewSize = workspace.CurrentCamera.ViewportSize
    local scale = math.min(viewSize.X / 600, viewSize.Y / 500, 1)
    if scale < 1 then
        OuterFrame.Size = UDim2.new(0, math.floor(542 * scale), 0, math.floor(432 * scale))
    end

    -- Floating toggle button (always on screen)
    local MobileToggle = C("TextButton", {
        Name = "MobileToggle",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 120),
        Size = UDim2.new(0, 56, 0, 56),
        BackgroundColor3 = Color3.fromRGB(50, 45, 20),
        BackgroundTransparency = 0.15,
        Text = "OFF",
        TextColor3 = T.Yellow,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 50,
        Visible = false, -- shown after key validation
        Parent = SG,
    })
    Corner(MobileToggle, UDim.new(1, 0)) -- circle
    Stroke(MobileToggle, Color3.fromRGB(80, 70, 30), 2, 0.3)

    -- Floating UI button
    local MobileUI = C("TextButton", {
        Name = "MobileUI",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 185),
        Size = UDim2.new(0, 56, 0, 56),
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BackgroundTransparency = 0.15,
        Text = "UI",
        TextColor3 = Color3.fromRGB(180, 180, 200),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 50,
        Visible = false, -- shown after key validation
        Parent = SG,
    })
    Corner(MobileUI, UDim.new(1, 0)) -- circle
    Stroke(MobileUI, Color3.fromRGB(50, 50, 70), 2, 0.3)

    -- Update mobile toggle button appearance
    local function updateMobileToggle()
        if CFG.enabled then
            MobileToggle.Text = "ON"
            MobileToggle.TextColor3 = T.Green
            MobileToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
            Stroke(MobileToggle, T.Green, 2, 0.4)
        else
            MobileToggle.Text = "OFF"
            MobileToggle.TextColor3 = T.Yellow
            MobileToggle.BackgroundColor3 = Color3.fromRGB(50, 45, 20)
            Stroke(MobileToggle, Color3.fromRGB(80, 70, 30), 2, 0.3)
        end
    end

    -- Toggle ON/OFF
    MobileToggle.MouseButton1Click:Connect(function()
        CFG.enabled = not CFG.enabled
        updateStatusBadge()
        updateMobileToggle()
        if not CFG.enabled then
            for i = 1, engineCount do
                if laneState[i] and laneState[i].pressed and engineLanes[i] then
                    releaseK(engineLanes[i].keyCode, i)
                    laneState[i].pressed = false; laneState[i].activeNote = nil
                end
            end
            noteData = {}
        end
    end)

    -- Toggle UI visibility
    MobileUI.MouseButton1Click:Connect(function()
        OuterFrame.Visible = not OuterFrame.Visible
    end)

    -- Make mobile buttons draggable
    for _, btn in ipairs({MobileToggle, MobileUI}) do
        local dragConn
        local btnDragging = false
        local btnDragStart, btnStartPos
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch then
                btnDragging = true; btnDragStart = inp.Position; btnStartPos = btn.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then btnDragging = false end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if btnDragging and inp.UserInputType == Enum.UserInputType.Touch then
                local d = inp.Position - btnDragStart
                btn.Position = UDim2.new(
                    btnStartPos.X.Scale, btnStartPos.X.Offset + d.X,
                    btnStartPos.Y.Scale, btnStartPos.Y.Offset + d.Y
                )
            end
        end)
    end

    -- Show mobile buttons after key validation (hooked later)
    local origShow = nil
    task.spawn(function()
        while not keyValidated do task.wait(0.5) end
        MobileToggle.Visible = true
        MobileUI.Visible = true
        updateMobileToggle()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════════════════
local function startEngine()
    local searchF = 0
    RunService.RenderStepped:Connect(function()
        frameTick += 1
        if not rhythmRoot then
            searchF += 1
            if searchF % 30 == 0 then
                local ui = PlayerGui:FindFirstChild("RhythmServiceUI")
                if ui then
                    local root = ui:FindFirstChild("RhythmRoot")
                    if root then
                        rhythmRoot = root
                        engineLanes, engineCount = discoverLanes(root); initLS()
                        local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
                        LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
                        updateLaneKeybindUI()
                        watchHints(root)
                        startKeyHintPolling()
                    end
                end
            end
            return
        end
        if not rhythmRoot.Parent then
            for i = 1, engineCount do if laneState[i] and laneState[i].pressed and engineLanes[i] then releaseK(engineLanes[i].keyCode, i) end end
            rhythmRoot = nil; engineLanes = {}; engineCount = 0; laneState = {}; noteData = {}; searchF = 0
            return
        end
        if frameTick % CFG.rescanInt == 0 then
            local nl, nc = discoverLanes(rhythmRoot)
            if nc ~= engineCount then
                for i = 1, engineCount do if laneState[i] and laneState[i].pressed and engineLanes[i] then releaseK(engineLanes[i].keyCode, i) end end
                engineLanes = nl; engineCount = nc; initLS(); noteData = {}
                local kn = {}; for _, ld in ipairs(engineLanes) do table.insert(kn, ld.keyName) end
                LaneVal.Text = engineCount .. " lanes → " .. table.concat(kn, "  ")
                updateLaneKeybindUI()
                watchHints(rhythmRoot)
            else engineLanes = nl end
        end
        if not CFG.enabled then return end
        processFrame()
        if frameTick % 30 == 0 then updateUI() end
    end)
    LocalPlayer.CharacterAdded:Connect(function()
        for i = 1, engineCount do if laneState[i] and laneState[i].pressed and engineLanes[i] then releaseK(engineLanes[i].keyCode, i) end end
        laneState = {}; noteData = {}; rhythmRoot = nil; searchF = 0
        stats = {perfect=0, good=0, okay=0, bad=0, miss=0, total=0, holds=0}
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM FLOW
-- ═══════════════════════════════════════════════════════════════
KeyBtn.MouseButton1Click:Connect(function()
    KeyBtn.Text = "VERIFYING..."
    KeyStatus.Text = ""
    KeyStatus.TextColor3 = T.TextSec

    task.wait(0.3)
    fetchKeys()

    if validateKey(KeyInput.Text) then
        KeyStatus.Text = "✓ Key accepted!"
        KeyStatus.TextColor3 = T.Green
        keyValidated = true
        validatedKeyText = KeyInput.Text

        task.wait(0.5)
        -- Fade out key frame
        Tw(KeyFrame, 0.4, {BackgroundTransparency = 1})
        for _, desc in ipairs(KeyFrame:GetDescendants()) do
            pcall(function()
                if desc:IsA("TextLabel") or desc:IsA("TextBox") or desc:IsA("TextButton") then
                    Tw(desc, 0.4, {TextTransparency = 1})
                end
                if desc:IsA("Frame") or desc:IsA("TextButton") then
                    Tw(desc, 0.4, {BackgroundTransparency = 1})
                end
                if desc:IsA("UIStroke") then
                    Tw(desc, 0.4, {Transparency = 1})
                end
            end)
        end
        task.wait(0.5)
        KeyFrame.Visible = false

        -- Show main hub
        OuterFrame.Visible = true
        OuterFrame.Size = UDim2.new(0, 0, 0, 0)
        Tw(OuterFrame, 0.5, {Size = UDim2.new(0, 542, 0, 432)})

        -- Start engine
        startEngine()

        -- ═══════════════════════════════════════════════════════
        -- BACKGROUND KEY RE-VALIDATION
        -- Progressive: first check 30s, then every 90s ±15s
        -- raw.githubusercontent.com is CDN-cached → ~40 req/hr, safe
        -- HTTP errors = skip | Invalid key = kick
        -- ═══════════════════════════════════════════════════════
        task.spawn(function()
            local FIRST_CHECK   = 60       -- first recheck after 60s
            local BASE_INTERVAL = 60       -- then every 60 seconds
            local JITTER        = 0        -- no jitter, fixed 60s
            local httpFailCount = 0
            local MAX_HTTP_FAILS = 3       -- after 3 consecutive HTTP fails, disable
            local isFirstCheck  = true

            while keyValidated do
                -- Progressive: fast first check, then regular interval
                local interval
                if isFirstCheck then
                    interval = FIRST_CHECK
                    isFirstCheck = false
                else
                    interval = BASE_INTERVAL + math.random(-JITTER, JITTER)
                end
                task.wait(interval)

                if not keyValidated then break end

                -- Auto-purge jsDelivr cache (fire & forget, no waiting)
                pcall(function()
                    game:HttpGet("https://purge.jsdelivr.net/gh/emrself/mining@main/keys.txt")
                end)
                task.wait(1) -- tiny wait for purge to propagate

                -- Re-fetch via CDN proxy chain (jsDelivr → Statically → raw)
                local freshKeys = fetchFreshKeys()

                if freshKeys then
                    httpFailCount = 0  -- reset on success

                    -- Validate stored key against fresh list
                    local storedKey = validatedKeyText:match("^%s*(.-)%s*$")
                    if storedKey and storedKey ~= "" and freshKeys[storedKey:lower()] then
                        -- Key still valid, update cached list
                        validKeys = freshKeys
                    else
                        -- KEY REVOKED OR CHANGED → SHUTDOWN
                        keyValidated = false
                        CFG.enabled = false

                        -- Release all keys
                        for i = 1, engineCount do
                            if laneState[i] and laneState[i].pressed and engineLanes[i] then
                                releaseK(engineLanes[i].keyCode, i)
                            end
                        end

                        -- Destroy UI
                        pcall(function() SG:Destroy() end)

                        -- Kick player
                        pcall(function()
                            LocalPlayer:Kick("\n\n🔑 License key revoked or expired.\nYour key is no longer valid.\n\nGet a new key from the official source.")
                        end)
                        break
                    end
                else
                    -- ALL CDN proxies failed (network down, all CDNs down)
                    httpFailCount += 1

                    if httpFailCount >= MAX_HTTP_FAILS then
                        CFG.enabled = false
                        pcall(function()
                            StatusVal.Text = "⚠ Key check failed — auto disabled"
                            StatusVal.TextColor3 = T.Orange
                        end)
                    end
                end
            end
        end)
    else
        KeyStatus.Text = "X Invalid key! Try again."
        KeyStatus.TextColor3 = T.Red
        KeyBtn.Text = "VERIFY KEY"
        Tw(KeyInputBox, 0.1, {Position = UDim2.new(0.02, 0, 0, 126)})
        task.wait(0.1)
        Tw(KeyInputBox, 0.1, {Position = UDim2.new(-0.02, 0, 0, 126)})
        task.wait(0.1)
        Tw(KeyInputBox, 0.15, {Position = UDim2.new(0, 0, 0, 126)})
    end
end)

-- Auto-bypass if already verified in Synox Hub
if _G.SynoxKeyVerified or (getgenv and getgenv().SynoxKeyVerified) then
    task.spawn(function()
        KeyFrame.Visible = false
        OuterFrame.Visible = true
        OuterFrame.Size = UDim2.new(0, 0, 0, 0)
        Tw(OuterFrame, 0.5, {Size = UDim2.new(0, 542, 0, 432)})
        keyValidated = true
        validatedKeyText = _G.SynoxKey or (getgenv and getgenv().SynoxKey) or "HUB-VERIFIED"
        startEngine()
    end)
end

