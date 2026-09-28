--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                   IEM7R MENU — AUTOEXEC                    ║
    ║         Glassmorphism | Dark Gray | Transparent             ║
    ║        Full Keybind System | ESP | TP | Item List           ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Xeno Autoexec — No key required
    Drops into iem8r/autoexec/ and runs on inject
    All keybinds configurable from Settings tab
--]]

-- ══════════════════════════════════════════════════════════════
-- ANTI-DUPLICATE (prevent double-load on re-inject)
-- ══════════════════════════════════════════════════════════════
if _G.IEM7R_LOADED then
    -- Already running, destroy old GUI silently
    pcall(function()
        if _G.IEM7R_GUI and _G.IEM7R_GUI.Parent then
            _G.IEM7R_GUI:Destroy()
        end
    end)
end
_G.IEM7R_LOADED = true

-- ══════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
-- THEME (Synox Glassmorphism)
-- ══════════════════════════════════════════════════════════════
local Theme = {
    Background = Color3.fromRGB(25, 25, 30),
    BackgroundTransparency = 0.15,
    OuterFrame = Color3.fromRGB(35, 35, 42),
    OuterFrameTransparency = 0.45,
    OuterStroke = Color3.fromRGB(80, 80, 95),
    OuterStrokeTransparency = 0.3,
    Panel = Color3.fromRGB(30, 30, 38),
    PanelTransparency = 0.25,
    PanelStroke = Color3.fromRGB(60, 60, 75),
    TitleBar = Color3.fromRGB(20, 20, 26),
    TitleBarTransparency = 0.1,
    Accent = Color3.fromRGB(0, 180, 216),
    AccentDark = Color3.fromRGB(0, 140, 170),
    AccentGlow = Color3.fromRGB(0, 200, 240),
    AccentSoft = Color3.fromRGB(0, 120, 150),
    TextPrimary = Color3.fromRGB(220, 220, 230),
    TextSecondary = Color3.fromRGB(150, 150, 165),
    TextMuted = Color3.fromRGB(100, 100, 115),
    TextAccent = Color3.fromRGB(0, 200, 230),
    TabActive = Color3.fromRGB(40, 40, 50),
    TabActiveTransparency = 0.2,
    TabInactive = Color3.fromRGB(30, 30, 38),
    TabInactiveTransparency = 0.5,
    TabStroke = Color3.fromRGB(55, 55, 68),
    Card = Color3.fromRGB(32, 32, 40),
    CardTransparency = 0.3,
    CardHover = Color3.fromRGB(38, 38, 48),
    CardStroke = Color3.fromRGB(55, 55, 68),
    ButtonPrimary = Color3.fromRGB(0, 160, 195),
    ButtonPrimaryHover = Color3.fromRGB(0, 185, 220),
    ButtonSecondary = Color3.fromRGB(45, 45, 55),
    ButtonSecondaryHover = Color3.fromRGB(55, 55, 68),
    ButtonDanger = Color3.fromRGB(200, 50, 50),
    ButtonDangerHover = Color3.fromRGB(230, 60, 60),
    StatusOnline = Color3.fromRGB(50, 205, 50),
    StatusOffline = Color3.fromRGB(200, 50, 50),
    StatusWarning = Color3.fromRGB(255, 200, 50),
    ScrollBar = Color3.fromRGB(60, 60, 75),
    ScrollBarTransparency = 0.5,
    Separator = Color3.fromRGB(50, 50, 62),
    SeparatorTransparency = 0.5,
    CornerRadius = UDim.new(0, 8),
    CornerRadiusSmall = UDim.new(0, 5),
    CornerRadiusLarge = UDim.new(0, 12),
    FontTitle = Enum.Font.GothamBold,
    FontHeading = Enum.Font.GothamSemibold,
    FontBody = Enum.Font.Gotham,
    FontMono = Enum.Font.Code,
    TitleBarHeight = 36,
    WindowWidth = 540,
    WindowHeight = 460,
}

-- ══════════════════════════════════════════════════════════════
-- ITEM ESP CONFIG
-- ══════════════════════════════════════════════════════════════
local TP_OFFSET = Vector3.new(0, 5, 0)

local itemColors = {
    Safe    = Color3.fromRGB(0, 255, 0),
    Key     = Color3.fromRGB(255, 255, 0),
    Airdrop = Color3.fromRGB(170, 0, 255),
    PARTS   = Color3.fromRGB(255, 165, 0),
    Cache   = Color3.fromRGB(0, 170, 255),
    Mines   = Color3.fromRGB(255, 0, 0),
    Flare   = Color3.fromRGB(255, 105, 180),
}

local keywords = {"Safe", "Key", "Airdrop", "Cache", "PARTS", "Flare"}

local blacklistWords = {
    "circle", "light", "dust", "particle", "leaderboard", "spawn", "grass", "tree"
}

-- ══════════════════════════════════════════════════════════════
-- KEYBIND SYSTEM (all configurable from Settings tab)
-- ══════════════════════════════════════════════════════════════
local Keybinds = {
    ToggleMenu     = Enum.KeyCode.Insert,
    ToggleESP      = Enum.KeyCode.Return,
    ListUp         = Enum.KeyCode.J,
    ListDown       = Enum.KeyCode.K,
    Teleport       = Enum.KeyCode.P,
    TabNext        = Enum.KeyCode.G,
    TabPrev        = Enum.KeyCode.H,
}

local keybindNames = {
    "ToggleMenu", "ToggleESP", "ListUp", "ListDown", "Teleport", "TabNext", "TabPrev"
}

local keybindDescriptions = {
    ToggleMenu  = "Show/Hide Menu",
    ToggleESP   = "Toggle ESP On/Off",
    ListUp      = "Select Previous Item",
    ListDown    = "Select Next Item",
    Teleport    = "Teleport to Selected",
    TabNext     = "Next Tab",
    TabPrev     = "Previous Tab",
}

local defaultKeybinds = {
    ToggleMenu  = Enum.KeyCode.Insert,
    ToggleESP   = Enum.KeyCode.Return,
    ListUp      = Enum.KeyCode.J,
    ListDown    = Enum.KeyCode.K,
    Teleport    = Enum.KeyCode.P,
    TabNext     = Enum.KeyCode.G,
    TabPrev     = Enum.KeyCode.H,
}

local waitingForKeybind = nil

-- ══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local Util = {}

function Util.Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" and prop ~= "Children" then
            instance[prop] = value
        end
    end
    if properties.Children then
        for _, child in ipairs(properties.Children) do
            child.Parent = instance
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Util.Tween(instance, duration, properties, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        duration or 0.25,
        easingStyle or Enum.EasingStyle.Quint,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Util.AddCorner(parent, radius)
    return Util.Create("UICorner", {
        CornerRadius = radius or Theme.CornerRadius,
        Parent = parent
    })
end

function Util.AddStroke(parent, color, thickness, transparency)
    return Util.Create("UIStroke", {
        Color = color or Theme.OuterStroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

function Util.AddPadding(parent, top, right, bottom, left)
    return Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 8),
        PaddingRight = UDim.new(0, right or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft = UDim.new(0, left or 8),
        Parent = parent
    })
end

function Util.AddGradient(parent, color1, color2, rotation)
    return Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1),
            ColorSequenceKeypoint.new(1, color2)
        }),
        Rotation = rotation or 90,
        Parent = parent
    })
end

function Util.Ripple(button, position)
    local ripple = Util.Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, position.X - button.AbsolutePosition.X, 0, position.Y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        ZIndex = button.ZIndex + 1,
        Parent = button
    })
    Util.AddCorner(ripple, UDim.new(1, 0))
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    Util.Tween(ripple, 0.5, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1})
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

function Util.GetPing()
    local success, ping = pcall(function()
        return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    return success and ping or 0
end

-- ══════════════════════════════════════════════════════════════
-- ITEM HELPERS
-- ══════════════════════════════════════════════════════════════
local function isBlacklisted(name)
    local n = string.lower(name)
    for _, w in ipairs(blacklistWords) do
        if string.find(n, w) then return true end
    end
    return false
end

local function hasKeyword(name)
    for _, k in ipairs(keywords) do
        if string.find(name, k) then return true end
    end
    return false
end

local function getItemTypeFromName(name)
    local n = string.lower(name)
    if string.find(n, "flare") then return "Flare" end
    if string.find(n, "airdrop") then return "Airdrop" end
    if string.find(n, "key") or string.find(n, "cle") then return "Key" end
    if string.find(n, "safe") or string.find(n, "coffre") then return "Safe" end
    if string.find(n, "parts") then return "PARTS" end
    if string.find(n, "cache") then return "Cache" end
    return nil
end

local function isMine(obj)
    return (obj.Parent and obj.Parent.Name == "Mines") or (obj:FindFirstAncestor("Mines") ~= nil)
end

local function isTeleportable(o)
    if o:IsA("BasePart") then return true end
    if o:IsA("Model") then
        return o.PrimaryPart ~= nil or o:FindFirstChildWhichIsA("BasePart", true) ~= nil
    end
    return false
end

local function getTeleportPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
-- SCREENGUI
-- ══════════════════════════════════════════════════════════════
local ScreenGui = Util.Create("ScreenGui", {
    Name = "IEM7R_Menu_" .. HttpService:GenerateGUID(false),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
})

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

_G.IEM7R_GUI = ScreenGui

-- ══════════════════════════════════════════════════════════════
-- MAIN HUB FRAME (visible immediately, no key)
-- ══════════════════════════════════════════════════════════════
local OuterFrame = Util.Create("Frame", {
    Name = "OuterFrame",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, Theme.WindowWidth + 12, 0, Theme.WindowHeight + 12),
    BackgroundColor3 = Theme.OuterFrame,
    BackgroundTransparency = Theme.OuterFrameTransparency,
    BorderSizePixel = 0,
    Visible = true,
    Parent = ScreenGui
})
Util.AddCorner(OuterFrame, Theme.CornerRadiusLarge)
Util.AddStroke(OuterFrame, Theme.OuterStroke, 1.5, Theme.OuterStrokeTransparency)

local MainFrame = Util.Create("Frame", {
    Name = "MainFrame",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, Theme.WindowWidth, 0, Theme.WindowHeight),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = Theme.BackgroundTransparency,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = OuterFrame
})
Util.AddCorner(MainFrame, Theme.CornerRadius)
Util.AddStroke(MainFrame, Theme.PanelStroke, 1, 0.5)

-- Accent glow line
Util.Create("Frame", {
    Size = UDim2.new(1, 0, 0, 3),
    Position = UDim2.new(0, 0, 0, Theme.TitleBarHeight),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    ZIndex = 5,
    Parent = MainFrame,
    Children = {
        Util.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.AccentGlow),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            }),
            Rotation = 0,
        })
    }
})

-- ══════════════════════════════════════════════════════════════
-- TITLE BAR
-- ══════════════════════════════════════════════════════════════
local TitleBar = Util.Create("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, Theme.TitleBarHeight),
    BackgroundColor3 = Theme.TitleBar,
    BackgroundTransparency = Theme.TitleBarTransparency,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = MainFrame
})
Util.AddCorner(TitleBar, Theme.CornerRadius)

Util.Create("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = Theme.TitleBar,
    BackgroundTransparency = Theme.TitleBarTransparency,
    BorderSizePixel = 0,
    ZIndex = 10,
    Parent = TitleBar
})

Util.Create("TextLabel", {
    Size = UDim2.new(0.6, 0, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "IEM7R",
    TextColor3 = Theme.TextPrimary,
    TextSize = 16,
    Font = Theme.FontTitle,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
    Parent = TitleBar
})

-- Title accent underline
Util.Create("Frame", {
    Size = UDim2.new(0, 50, 0, 2),
    Position = UDim2.new(0, 14, 1, -2),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    ZIndex = 12,
    Parent = TitleBar
})

-- Version tag
Util.Create("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),
    Size = UDim2.new(0, 80, 0, 16),
    Position = UDim2.new(1, -90, 0.5, 0),
    BackgroundTransparency = 1,
    Text = "v1.0 • Auto",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    Font = Theme.FontBody,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 11,
    Parent = TitleBar
})

-- Close & Minimize
local CloseBtn = Util.Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(45, 45, 55),
    BackgroundTransparency = 0.5,
    Text = "✕",
    TextColor3 = Theme.TextSecondary,
    TextSize = 14,
    Font = Theme.FontBody,
    BorderSizePixel = 0,
    ZIndex = 12,
    AutoButtonColor = false,
    Parent = TitleBar
})
Util.AddCorner(CloseBtn, Theme.CornerRadiusSmall)

local MinBtn = Util.Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -72, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(45, 45, 55),
    BackgroundTransparency = 0.5,
    Text = "─",
    TextColor3 = Theme.TextSecondary,
    TextSize = 14,
    Font = Theme.FontBody,
    BorderSizePixel = 0,
    ZIndex = 12,
    AutoButtonColor = false,
    Parent = TitleBar
})
Util.AddCorner(MinBtn, Theme.CornerRadiusSmall)

CloseBtn.MouseEnter:Connect(function()
    Util.Tween(CloseBtn, 0.2, {BackgroundColor3 = Theme.ButtonDanger, BackgroundTransparency = 0.2})
    Util.Tween(CloseBtn, 0.2, {TextColor3 = Color3.fromRGB(255, 255, 255)})
end)
CloseBtn.MouseLeave:Connect(function()
    Util.Tween(CloseBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5})
    Util.Tween(CloseBtn, 0.2, {TextColor3 = Theme.TextSecondary})
end)
MinBtn.MouseEnter:Connect(function()
    Util.Tween(MinBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(60, 60, 75), BackgroundTransparency = 0.2})
end)
MinBtn.MouseLeave:Connect(function()
    Util.Tween(MinBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5})
end)

-- ══════════════════════════════════════════════════════════════
-- DRAGGING
-- ══════════════════════════════════════════════════════════════
local dragging = false
local dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = OuterFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        OuterFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ══════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ══════════════════════════════════════════════════════════════
local ContentArea = Util.Create("Frame", {
    Name = "ContentArea",
    Size = UDim2.new(1, 0, 1, -Theme.TitleBarHeight),
    Position = UDim2.new(0, 0, 0, Theme.TitleBarHeight),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = MainFrame
})

-- ══════════════════════════════════════════════════════════════
-- TAB BAR
-- ══════════════════════════════════════════════════════════════
local TabBar = Util.Create("Frame", {
    Name = "TabBar",
    Size = UDim2.new(1, -20, 0, 38),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = ContentArea
})

Util.Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = TabBar
})

local tabNames = {"ESP", "Items", "Settings"}
local tabIcons = {ESP = "👁️", Items = "📦", Settings = "⚙️"}

-- ══════════════════════════════════════════════════════════════
-- PAGE CONTAINER
-- ══════════════════════════════════════════════════════════════
local PageContainer = Util.Create("Frame", {
    Name = "PageContainer",
    Size = UDim2.new(1, -20, 1, -56),
    Position = UDim2.new(0, 10, 0, 52),
    BackgroundColor3 = Theme.Panel,
    BackgroundTransparency = Theme.PanelTransparency,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = ContentArea
})
Util.AddCorner(PageContainer, Theme.CornerRadius)
Util.AddStroke(PageContainer, Theme.PanelStroke, 1, 0.6)

-- ══════════════════════════════════════════════════════════════
-- ESP PAGE
-- ══════════════════════════════════════════════════════════════
local ESPPage = Util.Create("Frame", {
    Name = "ESPPage",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = true,
    Parent = PageContainer
})
Util.AddPadding(ESPPage, 10, 12, 10, 12)

-- ESP Status Card
local ESPStatusCard = Util.Create("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Theme.Card,
    BackgroundTransparency = Theme.CardTransparency,
    BorderSizePixel = 0,
    Parent = ESPPage
})
Util.AddCorner(ESPStatusCard, Theme.CornerRadiusSmall)
Util.AddStroke(ESPStatusCard, Theme.CardStroke, 1, 0.6)
Util.AddPadding(ESPStatusCard, 8, 10, 8, 10)

Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundTransparency = 1,
    Text = "ESP STATUS",
    TextColor3 = Theme.TextMuted,
    TextSize = 10,
    Font = Theme.FontHeading,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ESPStatusCard
})

local ESPStatusValue = Util.Create("TextLabel", {
    Name = "ESPStatusValue",
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.new(0, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "⬤ OFFLINE",
    TextColor3 = Theme.StatusOffline,
    TextSize = 18,
    Font = Theme.FontTitle,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ESPStatusCard
})

-- ESP Toggle Button
local ESPToggleBtn = Util.Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    Position = UDim2.new(0, 0, 0, 65),
    BackgroundColor3 = Theme.ButtonPrimary,
    BackgroundTransparency = 0.15,
    Text = "🔘 Toggle ESP  [" .. Keybinds.ToggleESP.Name .. "]",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Theme.FontHeading,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Parent = ESPPage
})
Util.AddCorner(ESPToggleBtn, Theme.CornerRadiusSmall)
Util.AddStroke(ESPToggleBtn, Theme.Accent, 1, 0.5)

ESPToggleBtn.MouseEnter:Connect(function()
    Util.Tween(ESPToggleBtn, 0.2, {BackgroundColor3 = Theme.ButtonPrimaryHover, BackgroundTransparency = 0})
end)
ESPToggleBtn.MouseLeave:Connect(function()
    Util.Tween(ESPToggleBtn, 0.2, {BackgroundColor3 = Theme.ButtonPrimary, BackgroundTransparency = 0.15})
end)

-- Stats Row (Ping + FPS)
local StatsRow = Util.Create("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 112),
    BackgroundTransparency = 1,
    Parent = ESPPage
})

local PingCard = Util.Create("Frame", {
    Size = UDim2.new(0.48, 0, 1, 0),
    BackgroundColor3 = Theme.Card,
    BackgroundTransparency = Theme.CardTransparency,
    BorderSizePixel = 0,
    Parent = StatsRow
})
Util.AddCorner(PingCard, Theme.CornerRadiusSmall)
Util.AddStroke(PingCard, Theme.CardStroke, 1, 0.6)
Util.AddPadding(PingCard, 6, 10, 6, 10)

Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
    Text = "PING", TextColor3 = Theme.TextMuted, TextSize = 9,
    Font = Theme.FontHeading, TextXAlignment = Enum.TextXAlignment.Left, Parent = PingCard
})
local PingValue = Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 14),
    BackgroundTransparency = 1, Text = "0 ms", TextColor3 = Theme.TextAccent,
    TextSize = 18, Font = Theme.FontTitle, TextXAlignment = Enum.TextXAlignment.Left, Parent = PingCard
})

local FPSCard = Util.Create("Frame", {
    Size = UDim2.new(0.48, 0, 1, 0),
    Position = UDim2.new(0.52, 0, 0, 0),
    BackgroundColor3 = Theme.Card,
    BackgroundTransparency = Theme.CardTransparency,
    BorderSizePixel = 0,
    Parent = StatsRow
})
Util.AddCorner(FPSCard, Theme.CornerRadiusSmall)
Util.AddStroke(FPSCard, Theme.CardStroke, 1, 0.6)
Util.AddPadding(FPSCard, 6, 10, 6, 10)

Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
    Text = "FPS", TextColor3 = Theme.TextMuted, TextSize = 9,
    Font = Theme.FontHeading, TextXAlignment = Enum.TextXAlignment.Left, Parent = FPSCard
})
local FPSValue = Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 14),
    BackgroundTransparency = 1, Text = "60", TextColor3 = Theme.TextAccent,
    TextSize = 18, Font = Theme.FontTitle, TextXAlignment = Enum.TextXAlignment.Left, Parent = FPSCard
})

-- Item count
local ItemCountLabel = Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0, 170),
    BackgroundTransparency = 1,
    Text = "Items detected: 0",
    TextColor3 = Theme.TextSecondary,
    TextSize = 12,
    Font = Theme.FontBody,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = ESPPage
})

-- ══════════════════════════════════════════════════════════════
-- ITEMS PAGE
-- ══════════════════════════════════════════════════════════════
local ItemsPage = Util.Create("Frame", {
    Name = "ItemsPage",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = PageContainer
})
Util.AddPadding(ItemsPage, 8, 8, 8, 8)

-- TP Control Row
local TPControlRow = Util.Create("Frame", {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundTransparency = 1,
    Parent = ItemsPage
})

local TPBtnUp = Util.Create("TextButton", {
    Size = UDim2.new(0.3, -4, 1, 0),
    BackgroundColor3 = Theme.ButtonSecondary,
    BackgroundTransparency = 0.3,
    Text = "▲ Prev",
    TextColor3 = Theme.TextPrimary,
    TextSize = 12,
    Font = Theme.FontHeading,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Parent = TPControlRow
})
Util.AddCorner(TPBtnUp, Theme.CornerRadiusSmall)
Util.AddStroke(TPBtnUp, Theme.CardStroke, 1, 0.6)

local TPBtnTP = Util.Create("TextButton", {
    Size = UDim2.new(0.4, -4, 1, 0),
    Position = UDim2.new(0.3, 2, 0, 0),
    BackgroundColor3 = Theme.ButtonPrimary,
    BackgroundTransparency = 0.15,
    Text = "⚡ TELEPORT",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    Font = Theme.FontTitle,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Parent = TPControlRow
})
Util.AddCorner(TPBtnTP, Theme.CornerRadiusSmall)
Util.AddStroke(TPBtnTP, Theme.Accent, 1, 0.5)

local TPBtnDown = Util.Create("TextButton", {
    Size = UDim2.new(0.3, -4, 1, 0),
    Position = UDim2.new(0.7, 2, 0, 0),
    BackgroundColor3 = Theme.ButtonSecondary,
    BackgroundTransparency = 0.3,
    Text = "▼ Next",
    TextColor3 = Theme.TextPrimary,
    TextSize = 12,
    Font = Theme.FontHeading,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Parent = TPControlRow
})
Util.AddCorner(TPBtnDown, Theme.CornerRadiusSmall)
Util.AddStroke(TPBtnDown, Theme.CardStroke, 1, 0.6)

for _, btn in ipairs({TPBtnUp, TPBtnDown}) do
    btn.MouseEnter:Connect(function()
        Util.Tween(btn, 0.15, {BackgroundColor3 = Theme.ButtonSecondaryHover, BackgroundTransparency = 0.1})
    end)
    btn.MouseLeave:Connect(function()
        Util.Tween(btn, 0.15, {BackgroundColor3 = Theme.ButtonSecondary, BackgroundTransparency = 0.3})
    end)
end
TPBtnTP.MouseEnter:Connect(function()
    Util.Tween(TPBtnTP, 0.15, {BackgroundColor3 = Theme.ButtonPrimaryHover, BackgroundTransparency = 0})
end)
TPBtnTP.MouseLeave:Connect(function()
    Util.Tween(TPBtnTP, 0.15, {BackgroundColor3 = Theme.ButtonPrimary, BackgroundTransparency = 0.15})
end)

-- Items Scroll
local ItemsScroll = Util.Create("ScrollingFrame", {
    Name = "ItemsScroll",
    Size = UDim2.new(1, 0, 1, -42),
    Position = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.ScrollBar,
    ScrollBarImageTransparency = Theme.ScrollBarTransparency,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = ItemsPage
})

local ItemsLayout = Util.Create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = ItemsScroll
})
Util.AddPadding(ItemsScroll, 4, 4, 4, 4)

-- ══════════════════════════════════════════════════════════════
-- SETTINGS PAGE
-- ══════════════════════════════════════════════════════════════
local SettingsPage = Util.Create("Frame", {
    Name = "SettingsPage",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = PageContainer
})

local SettingsScroll = Util.Create("ScrollingFrame", {
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.ScrollBar,
    ScrollBarImageTransparency = Theme.ScrollBarTransparency,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = SettingsPage
})

Util.Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = SettingsScroll
})
Util.AddPadding(SettingsScroll, 8, 8, 8, 8)

Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    Text = "⚙️ KEYBIND CONFIGURATION",
    TextColor3 = Theme.TextAccent,
    TextSize = 14,
    Font = Theme.FontTitle,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 0,
    Parent = SettingsScroll
})

Util.Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "Click a keybind button, then press any key to assign",
    TextColor3 = Theme.TextMuted,
    TextSize = 11,
    Font = Theme.FontBody,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1,
    Parent = SettingsScroll
})

Util.Create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Theme.Separator,
    BackgroundTransparency = Theme.SeparatorTransparency,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    Parent = SettingsScroll
})

local keybindButtons = {}

local function createKeybindRow(bindName, layoutOrder)
    local row = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        BorderSizePixel = 0,
        LayoutOrder = layoutOrder,
        Parent = SettingsScroll
    })
    Util.AddCorner(row, Theme.CornerRadiusSmall)
    Util.AddStroke(row, Theme.CardStroke, 1, 0.6)

    Util.Create("TextLabel", {
        Size = UDim2.new(0.55, -10, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = keybindDescriptions[bindName] or bindName,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        Font = Theme.FontHeading,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })

    local kbBtn = Util.Create("TextButton", {
        Size = UDim2.new(0.4, -10, 0, 28),
        Position = UDim2.new(0.58, 0, 0.5, -14),
        BackgroundColor3 = Theme.ButtonSecondary,
        BackgroundTransparency = 0.3,
        Text = "[" .. Keybinds[bindName].Name .. "]",
        TextColor3 = Theme.TextAccent,
        TextSize = 12,
        Font = Theme.FontMono,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = row
    })
    Util.AddCorner(kbBtn, Theme.CornerRadiusSmall)
    Util.AddStroke(kbBtn, Theme.CardStroke, 1, 0.6)

    keybindButtons[bindName] = kbBtn

    kbBtn.MouseEnter:Connect(function()
        Util.Tween(kbBtn, 0.15, {BackgroundColor3 = Theme.ButtonSecondaryHover, BackgroundTransparency = 0.1})
    end)
    kbBtn.MouseLeave:Connect(function()
        if waitingForKeybind ~= bindName then
            Util.Tween(kbBtn, 0.15, {BackgroundColor3 = Theme.ButtonSecondary, BackgroundTransparency = 0.3})
        end
    end)

    kbBtn.MouseButton1Click:Connect(function()
        if waitingForKeybind and keybindButtons[waitingForKeybind] then
            local prevBtn = keybindButtons[waitingForKeybind]
            prevBtn.Text = "[" .. Keybinds[waitingForKeybind].Name .. "]"
            Util.Tween(prevBtn, 0.15, {BackgroundColor3 = Theme.ButtonSecondary})
            local prevStroke = prevBtn:FindFirstChildOfClass("UIStroke")
            if prevStroke then Util.Tween(prevStroke, 0.15, {Color = Theme.CardStroke}) end
        end

        waitingForKeybind = bindName
        kbBtn.Text = "[ Press Key... ]"
        Util.Tween(kbBtn, 0.15, {BackgroundColor3 = Theme.AccentDark, BackgroundTransparency = 0.1})
        local stroke = kbBtn:FindFirstChildOfClass("UIStroke")
        if stroke then Util.Tween(stroke, 0.15, {Color = Theme.Accent}) end
    end)

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Util.Tween(row, 0.15, {BackgroundColor3 = Theme.CardHover, BackgroundTransparency = 0.2})
        end
    end)
    row.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Util.Tween(row, 0.15, {BackgroundColor3 = Theme.Card, BackgroundTransparency = Theme.CardTransparency})
        end
    end)

    return row
end

for i, bindName in ipairs(keybindNames) do
    createKeybindRow(bindName, i + 2)
end

-- Reset button
local ResetBindsBtn = Util.Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = Theme.ButtonDanger,
    BackgroundTransparency = 0.3,
    Text = "🔄 Reset All Keybinds",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    Font = Theme.FontHeading,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    LayoutOrder = #keybindNames + 5,
    Parent = SettingsScroll
})
Util.AddCorner(ResetBindsBtn, Theme.CornerRadiusSmall)

ResetBindsBtn.MouseEnter:Connect(function()
    Util.Tween(ResetBindsBtn, 0.15, {BackgroundColor3 = Theme.ButtonDangerHover, BackgroundTransparency = 0.1})
end)
ResetBindsBtn.MouseLeave:Connect(function()
    Util.Tween(ResetBindsBtn, 0.15, {BackgroundColor3 = Theme.ButtonDanger, BackgroundTransparency = 0.3})
end)

ResetBindsBtn.MouseButton1Click:Connect(function()
    for name, key in pairs(defaultKeybinds) do
        Keybinds[name] = key
        if keybindButtons[name] then
            keybindButtons[name].Text = "[" .. key.Name .. "]"
        end
    end
    waitingForKeybind = nil
    if espEnabled then
        ESPToggleBtn.Text = "🔘 ESP ACTIVE  [" .. Keybinds.ToggleESP.Name .. "]"
    else
        ESPToggleBtn.Text = "🔘 Toggle ESP  [" .. Keybinds.ToggleESP.Name .. "]"
    end
end)

-- ══════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ══════════════════════════════════════════════════════════════
local Pages = {ESP = ESPPage, Items = ItemsPage, Settings = SettingsPage}
local Tabs = {}
local activeTab = "ESP"
local tabOrder = {"ESP", "Items", "Settings"}
local tabIndex = 1

local function switchTab(tabName)
    if activeTab == tabName then return end
    activeTab = tabName
    for i, t in ipairs(tabOrder) do
        if t == tabName then tabIndex = i end
    end
    for name, page in pairs(Pages) do
        page.Visible = (name == tabName)
    end
    for name, tabBtn in pairs(Tabs) do
        if name == tabName then
            Util.Tween(tabBtn, 0.25, {BackgroundColor3 = Theme.TabActive, BackgroundTransparency = Theme.TabActiveTransparency})
            local txt = tabBtn:FindFirstChild("TabText")
            local acc = tabBtn:FindFirstChild("AccentLine")
            if txt then Util.Tween(txt, 0.25, {TextColor3 = Theme.TextAccent}) end
            if acc then Util.Tween(acc, 0.25, {BackgroundTransparency = 0.2}) end
            local stroke = tabBtn:FindFirstChildOfClass("UIStroke")
            if stroke then Util.Tween(stroke, 0.25, {Color = Theme.Accent, Transparency = 0.4}) end
        else
            Util.Tween(tabBtn, 0.25, {BackgroundColor3 = Theme.TabInactive, BackgroundTransparency = Theme.TabInactiveTransparency})
            local txt = tabBtn:FindFirstChild("TabText")
            local acc = tabBtn:FindFirstChild("AccentLine")
            if txt then Util.Tween(txt, 0.25, {TextColor3 = Theme.TextSecondary}) end
            if acc then Util.Tween(acc, 0.25, {BackgroundTransparency = 1}) end
            local stroke = tabBtn:FindFirstChildOfClass("UIStroke")
            if stroke then Util.Tween(stroke, 0.25, {Color = Theme.TabStroke, Transparency = 0.6}) end
        end
    end
end

for i, tabName in ipairs(tabNames) do
    local isFirst = (i == 1)
    local tabBtn = Util.Create("TextButton", {
        Name = "Tab_" .. tabName,
        Size = UDim2.new(0, 145, 0, 32),
        BackgroundColor3 = isFirst and Theme.TabActive or Theme.TabInactive,
        BackgroundTransparency = isFirst and Theme.TabActiveTransparency or Theme.TabInactiveTransparency,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = i,
        Parent = TabBar
    })
    Util.AddCorner(tabBtn, Theme.CornerRadiusSmall)
    Util.AddStroke(tabBtn, isFirst and Theme.Accent or Theme.TabStroke, 1, isFirst and 0.4 or 0.6)

    Util.Create("TextLabel", {
        Name = "TabText",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Text = tabIcons[tabName] .. "  " .. tabName,
        TextColor3 = isFirst and Theme.TextAccent or Theme.TextSecondary,
        TextSize = 12,
        Font = Theme.FontHeading,
        Parent = tabBtn
    })

    Util.Create("Frame", {
        Name = "AccentLine",
        Size = UDim2.new(0.6, 0, 0, 2),
        Position = UDim2.new(0.2, 0, 1, -3),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = isFirst and 0.2 or 1,
        BorderSizePixel = 0,
        Parent = tabBtn
    })

    Tabs[tabName] = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        Util.Ripple(tabBtn, Vector2.new(
            tabBtn.AbsolutePosition.X + tabBtn.AbsoluteSize.X / 2,
            tabBtn.AbsolutePosition.Y + tabBtn.AbsoluteSize.Y / 2
        ))
        switchTab(tabName)
    end)

    tabBtn.MouseEnter:Connect(function()
        if activeTab ~= tabName then
            Util.Tween(tabBtn, 0.15, {BackgroundTransparency = 0.3})
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if activeTab ~= tabName then
            Util.Tween(tabBtn, 0.15, {BackgroundTransparency = Theme.TabInactiveTransparency})
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- MINIMIZE / CLOSE
-- ══════════════════════════════════════════════════════════════
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Util.Tween(OuterFrame, 0.35, {
            Size = UDim2.new(0, Theme.WindowWidth + 12, 0, Theme.TitleBarHeight + 16)
        })
        ContentArea.Visible = false
    else
        ContentArea.Visible = true
        Util.Tween(OuterFrame, 0.35, {
            Size = UDim2.new(0, Theme.WindowWidth + 12, 0, Theme.WindowHeight + 12)
        })
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    OuterFrame.Visible = false
end)

-- ══════════════════════════════════════════════════════════════
-- ESP / LIST / TP LOGIC
-- ══════════════════════════════════════════════════════════════
local espEnabled = false
local espAdded = {}
local espObjects = {}
local espIndex = 1
local listRows = {}

local function clearListUI()
    listRows = {}
    for _, c in ipairs(ItemsScroll:GetChildren()) do
        if c:IsA("Frame") and c.Name == "ItemRow" then
            c:Destroy()
        end
    end
end

local function scrollToSelected()
    local row = listRows[espIndex]
    if not row then return end
    local y = row.AbsolutePosition.Y - ItemsScroll.AbsolutePosition.Y + ItemsScroll.CanvasPosition.Y
    local targetY = math.max(0, y - 50)
    ItemsScroll.CanvasPosition = Vector2.new(0, targetY)
end

local function rebuildListUI()
    clearListUI()

    if not espEnabled then
        local row = Util.Create("Frame", {
            Name = "ItemRow",
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = Theme.Card,
            BackgroundTransparency = Theme.CardTransparency,
            BorderSizePixel = 0,
            Parent = ItemsScroll
        })
        Util.AddCorner(row, Theme.CornerRadiusSmall)
        Util.Create("TextLabel", {
            Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1, Text = "  ESP is currently OFF",
            TextColor3 = Theme.TextMuted, TextSize = 12,
            Font = Theme.FontBody, TextXAlignment = Enum.TextXAlignment.Left, Parent = row
        })
        table.insert(listRows, row)
        ItemsScroll.CanvasSize = UDim2.new(0, 0, 0, ItemsLayout.AbsoluteContentSize.Y + 12)
        return
    end

    if #espObjects == 0 then
        local row = Util.Create("Frame", {
            Name = "ItemRow",
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = Theme.Card,
            BackgroundTransparency = Theme.CardTransparency,
            BorderSizePixel = 0,
            Parent = ItemsScroll
        })
        Util.AddCorner(row, Theme.CornerRadiusSmall)
        Util.Create("TextLabel", {
            Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1, Text = "  ESP ON — No teleportable items found",
            TextColor3 = Theme.TextSecondary, TextSize = 12,
            Font = Theme.FontBody, TextXAlignment = Enum.TextXAlignment.Left, Parent = row
        })
        table.insert(listRows, row)
        ItemsScroll.CanvasSize = UDim2.new(0, 0, 0, ItemsLayout.AbsoluteContentSize.Y + 12)
        return
    end

    for i, o in ipairs(espObjects) do
        local itemType = getItemTypeFromName(o.Name)
        local baseColor = (itemType and itemColors[itemType]) or Color3.fromRGB(220, 220, 220)
        local isSelected = (i == espIndex)

        local row = Util.Create("Frame", {
            Name = "ItemRow",
            Size = UDim2.new(1, -8, 0, 32),
            BackgroundColor3 = isSelected and Theme.TabActive or Theme.Card,
            BackgroundTransparency = isSelected and 0.15 or Theme.CardTransparency,
            BorderSizePixel = 0,
            LayoutOrder = i,
            Parent = ItemsScroll
        })
        Util.AddCorner(row, Theme.CornerRadiusSmall)
        if isSelected then
            Util.AddStroke(row, Theme.Accent, 1, 0.3)
        else
            Util.AddStroke(row, Theme.CardStroke, 1, 0.7)
        end

        -- Color dot
        local dot = Util.Create("Frame", {
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(0, 10, 0.5, -4),
            BackgroundColor3 = baseColor,
            BorderSizePixel = 0,
            Parent = row
        })
        Util.AddCorner(dot, UDim.new(1, 0))

        local prefix = isSelected and "▶ " or ""
        Util.Create("TextLabel", {
            Size = UDim2.new(0.6, -30, 1, 0),
            Position = UDim2.new(0, 24, 0, 0),
            BackgroundTransparency = 1,
            Text = prefix .. o.Name,
            TextColor3 = isSelected and baseColor or baseColor:Lerp(Color3.new(1,1,1), 0.35),
            TextSize = 12,
            Font = isSelected and Theme.FontHeading or Theme.FontBody,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        })

        if itemType then
            local tag = Util.Create("TextLabel", {
                Size = UDim2.new(0, 60, 0, 16),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0),
                BackgroundColor3 = baseColor,
                BackgroundTransparency = 0.75,
                Text = itemType,
                TextColor3 = baseColor,
                TextSize = 9,
                Font = Theme.FontBody,
                Parent = row
            })
            Util.AddCorner(tag, UDim.new(0, 3))
        end

        table.insert(listRows, row)
    end

    task.defer(function()
        ItemsScroll.CanvasSize = UDim2.new(0, 0, 0, ItemsLayout.AbsoluteContentSize.Y + 12)
        scrollToSelected()
    end)
end

local function addESPVisual(o)
    if espAdded[o] then return end
    local itemType = getItemTypeFromName(o.Name)
    local color = itemColors[itemType] or Color3.new(1,1,1)
    if isMine(o) then color = itemColors.Mines end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.8
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.Parent = o

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.ClipsDescendants = false
    billboard.LightInfluence = 0
    billboard.Active = true
    billboard.AlwaysOnTop = true
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
    billboard.Size = UDim2.new(0, 220, 0, 40)
    billboard.Parent = o

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.Parent = billboard

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 1, -10)
    dot.BorderSizePixel = 0
    dot.BackgroundColor3 = color
    dot.Parent = holder
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, -10)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.2
    label.TextWrapped = true
    label.Text = o.Name
    label.Parent = holder

    espAdded[o] = {highlight, billboard}
end

local function sortEspObjects()
    table.sort(espObjects, function(a, b)
        local ta = getItemTypeFromName(a.Name) or "ZZZ"
        local tb = getItemTypeFromName(b.Name) or "ZZZ"
        if ta ~= tb then return ta < tb end
        return string.lower(a.Name) < string.lower(b.Name)
    end)
end

local function enableESP()
    espObjects = {}
    espIndex = 1
    for _, o in ipairs(workspace:GetDescendants()) do
        if hasKeyword(o.Name) and not isBlacklisted(o.Name) then
            if o:IsA("BasePart") or o:IsA("Model") then
                addESPVisual(o)
                if (not isMine(o)) and isTeleportable(o) then
                    table.insert(espObjects, o)
                end
            end
        end
    end
    sortEspObjects()
    ItemCountLabel.Text = "Items detected: " .. tostring(#espObjects)
    ESPStatusValue.Text = "⬤ ONLINE"
    ESPStatusValue.TextColor3 = Theme.StatusOnline
    rebuildListUI()
end

local function disableESP()
    for _, items in pairs(espAdded) do
        for _, obj in ipairs(items) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    espAdded = {}
    espObjects = {}
    espIndex = 1
    ItemCountLabel.Text = "Items detected: 0"
    ESPStatusValue.Text = "⬤ OFFLINE"
    ESPStatusValue.TextColor3 = Theme.StatusOffline
    rebuildListUI()
end

local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        enableESP()
        ESPToggleBtn.Text = "🔘 ESP ACTIVE  [" .. Keybinds.ToggleESP.Name .. "]"
        Util.Tween(ESPToggleBtn, 0.2, {BackgroundColor3 = Theme.StatusOnline})
        task.delay(0.4, function()
            Util.Tween(ESPToggleBtn, 0.2, {BackgroundColor3 = Theme.ButtonPrimary})
        end)
    else
        disableESP()
        ESPToggleBtn.Text = "🔘 Toggle ESP  [" .. Keybinds.ToggleESP.Name .. "]"
    end
end

local function teleportToSelected()
    if not espEnabled then return end
    if #espObjects == 0 then return end
    local o = espObjects[espIndex]
    if not o or not o.Parent or not o:IsDescendantOf(workspace) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local p = getTeleportPart(o)
    if not p then return end
    hrp.CFrame = p.CFrame + TP_OFFSET
end

local function cleanupMissing()
    if not espEnabled then return end
    local changed = false
    for i = #espObjects, 1, -1 do
        local o = espObjects[i]
        if (not o) or (not o.Parent) or (not o:IsDescendantOf(workspace)) then
            table.remove(espObjects, i)
            changed = true
        end
    end
    for o, items in pairs(espAdded) do
        if (not o) or (not o.Parent) or (not o:IsDescendantOf(workspace)) then
            for _, obj in ipairs(items) do
                if obj and obj.Parent then obj:Destroy() end
            end
            espAdded[o] = nil
            changed = true
        end
    end
    if #espObjects == 0 then
        espIndex = 1
    else
        if espIndex > #espObjects then espIndex = #espObjects end
        if espIndex < 1 then espIndex = 1 end
    end
    if changed then
        sortEspObjects()
        ItemCountLabel.Text = "Items detected: " .. tostring(#espObjects)
        rebuildListUI()
    end
end

-- Connect button clicks
ESPToggleBtn.MouseButton1Click:Connect(function()
    Util.Ripple(ESPToggleBtn, Vector2.new(
        ESPToggleBtn.AbsolutePosition.X + ESPToggleBtn.AbsoluteSize.X / 2,
        ESPToggleBtn.AbsolutePosition.Y + ESPToggleBtn.AbsoluteSize.Y / 2
    ))
    toggleESP()
end)

TPBtnUp.MouseButton1Click:Connect(function()
    if espEnabled and #espObjects > 0 then
        espIndex = espIndex - 1
        if espIndex < 1 then espIndex = #espObjects end
        rebuildListUI()
        scrollToSelected()
    end
end)

TPBtnDown.MouseButton1Click:Connect(function()
    if espEnabled and #espObjects > 0 then
        espIndex = espIndex + 1
        if espIndex > #espObjects then espIndex = 1 end
        rebuildListUI()
        scrollToSelected()
    end
end)

TPBtnTP.MouseButton1Click:Connect(function()
    Util.Ripple(TPBtnTP, Vector2.new(
        TPBtnTP.AbsolutePosition.X + TPBtnTP.AbsoluteSize.X / 2,
        TPBtnTP.AbsolutePosition.Y + TPBtnTP.AbsoluteSize.Y / 2
    ))
    teleportToSelected()
end)

-- ══════════════════════════════════════════════════════════════
-- MASTER INPUT HANDLER
-- ══════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- Keybind reassignment mode
    if waitingForKeybind then
        local bindName = waitingForKeybind
        waitingForKeybind = nil
        Keybinds[bindName] = input.KeyCode

        local btn = keybindButtons[bindName]
        if btn then
            btn.Text = "[" .. input.KeyCode.Name .. "]"
            Util.Tween(btn, 0.15, {BackgroundColor3 = Theme.ButtonSecondary})
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then Util.Tween(stroke, 0.15, {Color = Theme.CardStroke}) end
        end

        if bindName == "ToggleESP" then
            if espEnabled then
                ESPToggleBtn.Text = "🔘 ESP ACTIVE  [" .. input.KeyCode.Name .. "]"
            else
                ESPToggleBtn.Text = "🔘 Toggle ESP  [" .. input.KeyCode.Name .. "]"
            end
        end
        return
    end

    -- Toggle Menu
    if input.KeyCode == Keybinds.ToggleMenu then
        OuterFrame.Visible = not OuterFrame.Visible
        return
    end

    -- Toggle ESP
    if input.KeyCode == Keybinds.ToggleESP then
        toggleESP()
        return
    end

    -- Tab navigation
    if input.KeyCode == Keybinds.TabPrev then
        tabIndex = tabIndex - 1
        if tabIndex < 1 then tabIndex = #tabOrder end
        switchTab(tabOrder[tabIndex])
        return
    end

    if input.KeyCode == Keybinds.TabNext then
        tabIndex = tabIndex + 1
        if tabIndex > #tabOrder then tabIndex = 1 end
        switchTab(tabOrder[tabIndex])
        return
    end

    -- List navigation + TP
    if espEnabled and #espObjects > 0 then
        if input.KeyCode == Keybinds.ListUp then
            espIndex = espIndex - 1
            if espIndex < 1 then espIndex = #espObjects end
            rebuildListUI()
            scrollToSelected()
        elseif input.KeyCode == Keybinds.ListDown then
            espIndex = espIndex + 1
            if espIndex > #espObjects then espIndex = 1 end
            rebuildListUI()
            scrollToSelected()
        elseif input.KeyCode == Keybinds.Teleport then
            teleportToSelected()
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- LIVE FPS / PING
-- ══════════════════════════════════════════════════════════════
local fpsBuffer = {}
local fpsCounter = 0

RunService.RenderStepped:Connect(function(dt)
    fpsCounter = fpsCounter + 1
    table.insert(fpsBuffer, 1 / dt)

    if fpsCounter >= 30 then
        fpsCounter = 0
        local total = 0
        for _, f in ipairs(fpsBuffer) do total = total + f end
        local avg = math.floor(total / #fpsBuffer)
        fpsBuffer = {}

        FPSValue.Text = tostring(avg)
        if avg >= 50 then
            FPSValue.TextColor3 = Theme.StatusOnline
        elseif avg >= 30 then
            FPSValue.TextColor3 = Theme.StatusWarning
        else
            FPSValue.TextColor3 = Theme.StatusOffline
        end

        local ping = Util.GetPing()
        PingValue.Text = tostring(ping) .. " ms"
        if ping <= 80 then
            PingValue.TextColor3 = Theme.StatusOnline
        elseif ping <= 150 then
            PingValue.TextColor3 = Theme.StatusWarning
        else
            PingValue.TextColor3 = Theme.StatusOffline
        end
    end
end)

-- Cleanup loop
task.spawn(function()
    while true do
        task.wait(0.25)
        cleanupMissing()
    end
end)

-- ══════════════════════════════════════════════════════════════
-- OPEN ANIMATION (no key, straight in)
-- ══════════════════════════════════════════════════════════════
OuterFrame.Size = UDim2.new(0, 0, 0, 0)
OuterFrame.BackgroundTransparency = 1
MainFrame.BackgroundTransparency = 1

task.delay(0.05, function()
    Util.Tween(OuterFrame, 0.5, {
        Size = UDim2.new(0, Theme.WindowWidth + 12, 0, Theme.WindowHeight + 12),
        BackgroundTransparency = Theme.OuterFrameTransparency
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(0.15, function()
        Util.Tween(MainFrame, 0.35, {
            BackgroundTransparency = Theme.BackgroundTransparency
        })
    end)
end)

rebuildListUI()

print("[IEM7R] Autoexec loaded — " .. LocalPlayer.Name)
print("[IEM7R] Press Insert to toggle menu")

-- BY iem7r
