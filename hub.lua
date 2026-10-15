--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║         SYNOX HUB - Integrated Launcher v4.0.0              ║
    ║    Auto-Detect PlaceId | Key System | Multi-Game Hub        ║
    ║         Gakuran + MM2 + Universal Scripts                   ║
    ║   © IEM7R | dc:siberguvenlik | All rights reserved          ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════
local CONFIG = {
    KeySystemEnabled = true,
    KeyCheckURL = "https://raw.githubusercontent.com/emrself/mining/main/keys.txt",
    DiscordLink = "https://discord.gg/hHQ97ATpR9",
    DefaultHotkey = Enum.KeyCode.RightControl,
    AutoDetectEnabled = true,
    Version = "4.0.0",
}

-- ══════════════════════════════════════════════════════════════
-- GAME REGISTRY (PlaceId & UniverseId mapping)
-- ══════════════════════════════════════════════════════════════
local GAME_REGISTRY = {
    -- Gakuran (Rhythm Game)
    {
        PlaceIds = {128736949265057},
        UniverseId = 9199655655,
        Name = "Gakuran Auto-Player",
        Description = "Complete rhythm game automation suite.\n\nFeatures:\n• Auto-Play (Guitar 2 Lane)\n• Auto-Play (Drums 4 Lane)\n• Accuracy Control (Perfect / Good / Okay / Bad)\n• Mobile Touch Compatibility\n• Keybind Customization\n• Lane State Machine\n• Dynamic Hit Zone Calibration",
        ShortDesc = "Auto-Play, Accuracy Control, Mobile",
        Tag = "Updated",
        Icon = "🎸",
        ImageId = "rbxthumb://type=GameIcon&id=9199655655&w=150&h=150",
        URL = "https://raw.githubusercontent.com/emrself/mining/main/gakuran.lua",
    },
    -- Murder Mystery 2
    {
        PlaceIds = {142823291},
        UniverseId = 66654135,
        Name = "Synox MM2",
        Description = "Murder Mystery 2 full feature edition.\n\nFeatures:\n• Role ESP (Murderer / Sheriff / Innocents)\n• Gun Aimbot & Target Prediction\n• Automatic Coin Farm\n• Weapon Teleportation (Grab Dropped Gun)\n• Auto Fling & Anti-Fling\n• Movement Suite (Speed, Fly, Noclip)\n• Visuals (Fullbright, X-Ray)\n• Murderer Radar & Threat Alerts",
        ShortDesc = "ESP, Aimbot, Coin Farm, Role Detect",
        Tag = "Full Edition",
        Icon = "🔪",
        ImageId = "rbxthumb://type=GameIcon&id=66654135&w=150&h=150",
        URL = "https://raw.githubusercontent.com/emrself/mining/main/mm2.lua",
    },
}

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
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function() Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end)
    LocalPlayer = Players.LocalPlayer
end

local CURRENT_PLACE_ID = game.PlaceId

-- ══════════════════════════════════════════════════════════════
-- DESTROY PREVIOUS INSTANCES
-- ══════════════════════════════════════════════════════════════
for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and string.find(gui.Name, "SynoxHub_") then
        gui:Destroy()
    end
end

-- ══════════════════════════════════════════════════════════════
-- KEY PERSISTENCE
-- ══════════════════════════════════════════════════════════════
local KEY_FOLDER = "Synox"
local KEY_FILE = KEY_FOLDER .. "/key.dat"

local function ensureFolder()
    pcall(function()
        if typeof(isfolder) == "function" and not isfolder(KEY_FOLDER) and typeof(makefolder) == "function" then
            makefolder(KEY_FOLDER)
        end
    end)
end

local function saveKey(k)
    pcall(function()
        if typeof(writefile) == "function" then
            local ok = pcall(function() ensureFolder(); writefile(KEY_FILE, k) end)
            if not ok then pcall(function() writefile("synox_key.dat", k) end) end
        end
    end)
end

local function loadSavedKey()
    local s, r = pcall(function()
        if typeof(isfile) == "function" and typeof(readfile) == "function" then
            if isfile(KEY_FILE) then return readfile(KEY_FILE):match("^%s*(.-)%s*$") end
            if isfile("synox_key.dat") then return readfile("synox_key.dat"):match("^%s*(.-)%s*$") end
        end
        return nil
    end)
    return s and r or nil
end

local function deleteSavedKey()
    pcall(function()
        if typeof(delfile) == "function" and typeof(isfile) == "function" then
            if isfile(KEY_FILE) then delfile(KEY_FILE) end
            if isfile("synox_key.dat") then delfile("synox_key.dat") end
        end
    end)
    _G.SynoxKeyVerified = nil
    _G.SynoxKey = nil
    if getgenv then
        getgenv().SynoxKeyVerified = nil
        getgenv().SynoxKey = nil
    end
end

-- ══════════════════════════════════════════════════════════════
-- HTTP FETCH (Universal)
-- ══════════════════════════════════════════════════════════════
local function fetchText(url)
    if typeof(game.HttpGet) == "function" then
        local s, r = pcall(function() return game:HttpGet(url) end)
        if s and type(r) == "string" and #r > 0 then return r end
    end
    if typeof(httpget) == "function" then
        local s, r = pcall(function() return httpget(url) end)
        if s and type(r) == "string" and #r > 0 then return r end
    end
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if typeof(req) == "function" then
        local s, r = pcall(function() return req({Url = url, Method = "GET"}) end)
        if s and r and r.Body and type(r.Body) == "string" and #r.Body > 0 then return r.Body end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
-- KEY VALIDATION
-- ══════════════════════════════════════════════════════════════
local function validateKey(inputKey)
    if not inputKey or inputKey == "" then return false end
    local resp = fetchText(CONFIG.KeyCheckURL)
    if not resp then return false end
    local LF = string.char(10)
    local CR = string.char(13)
    local pos = 1
    while pos <= #resp do
        local nl = string.find(resp, LF, pos, true)
        local seg
        if nl then seg = string.sub(resp, pos, nl - 1); pos = nl + 1
        else seg = string.sub(resp, pos); pos = #resp + 1 end
        local clean = string.gsub(seg, CR, "")
        local trimmed = string.match(clean, "^%s*(.-)%s*$")
        if trimmed and trimmed == inputKey then return true end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════════════════════
local MessageBox
pcall(function()
    MessageBox = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/NotificationGUI/main/source.lua"))()
end)

local function NInfo(t, m)
    if MessageBox then
        MessageBox.Show({Position = UDim2.new(0.5, 0, 0.5, 0), Text = t or "SYNOX HUB", Description = m or "", MessageBoxIcon = "Question", MessageBoxButtons = "OK"})
    end
end
local function NError(t, m)
    if MessageBox then
        MessageBox.Show({Position = UDim2.new(0.5, 0, 0.5, 0), Text = t or "Error", Description = m or "", MessageBoxIcon = "Error", MessageBoxButtons = "OK"})
    end
end
local function NConfirm(t, m, cb)
    if MessageBox then
        MessageBox.Show({Position = UDim2.new(0.5, 0, 0.5, 0), Text = t or "Confirm", Description = m or "", MessageBoxIcon = "Question", MessageBoxButtons = "YesNo", Result = function(r) if cb then cb(r == "Yes") end end})
    end
end

-- ══════════════════════════════════════════════════════════════
-- THEME (Glassmorphism Dark)
-- ══════════════════════════════════════════════════════════════
local T = {
    Bg = Color3.fromRGB(22, 22, 28), BgT = 0.15,
    Outer = Color3.fromRGB(32, 32, 40), OuterT = 0.45,
    OuterStroke = Color3.fromRGB(75, 75, 92), OuterStrokeT = 0.3,
    Panel = Color3.fromRGB(28, 28, 36), PanelT = 0.25,
    PanelStroke = Color3.fromRGB(55, 55, 70),
    TitleBg = Color3.fromRGB(18, 18, 24), TitleBgT = 0.1,
    Accent = Color3.fromRGB(0, 180, 216),
    AccentGlow = Color3.fromRGB(0, 200, 240),
    TextPri = Color3.fromRGB(225, 225, 235),
    TextSec = Color3.fromRGB(155, 155, 170),
    TextMut = Color3.fromRGB(105, 105, 120),
    TextAcc = Color3.fromRGB(0, 200, 230),
    TabAct = Color3.fromRGB(38, 38, 48), TabActT = 0.2,
    TabIn = Color3.fromRGB(28, 28, 36), TabInT = 0.5,
    TabStroke = Color3.fromRGB(50, 50, 65),
    Card = Color3.fromRGB(30, 30, 38), CardT = 0.3,
    CardHov = Color3.fromRGB(36, 36, 46),
    CardStroke = Color3.fromRGB(52, 52, 66),
    BtnExec = Color3.fromRGB(42, 175, 55),
    BtnExecH = Color3.fromRGB(50, 200, 65),
    BtnPri = Color3.fromRGB(0, 160, 195),
    BtnPriH = Color3.fromRGB(0, 185, 220),
    BtnDng = Color3.fromRGB(200, 50, 50),
    Green = Color3.fromRGB(50, 205, 50),
    Yellow = Color3.fromRGB(255, 200, 50),
    Red = Color3.fromRGB(215, 50, 50),
    Scroll = Color3.fromRGB(55, 55, 70),
    ThumbBg = Color3.fromRGB(24, 24, 32), -- Dark sleek thumbnail background
    InputBg = Color3.fromRGB(18, 18, 24),
    CR = UDim.new(0, 8), CRS = UDim.new(0, 5), CRL = UDim.new(0, 12),
    FT = Enum.Font.GothamBold, FH = Enum.Font.GothamSemibold, FB = Enum.Font.Gotham,
    TBH = 36, TABH = 38, WW = 550, WH = 460,
}

-- ══════════════════════════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════════════════════════
local function C(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function Tw(inst, dur, props, es, ed)
    local t = TweenService:Create(inst, TweenInfo.new(dur or 0.25, es or Enum.EasingStyle.Quint, ed or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function Corner(p, r) return C("UICorner", {CornerRadius = r or T.CR, Parent = p}) end
local function Stroke(p, c, th, tr) return C("UIStroke", {Color = c or T.OuterStroke, Thickness = th or 1, Transparency = tr or 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p}) end
local function Pad(p, t, r, b, l) return C("UIPadding", {PaddingTop = UDim.new(0, t or 8), PaddingRight = UDim.new(0, r or 8), PaddingBottom = UDim.new(0, b or 8), PaddingLeft = UDim.new(0, l or 8), Parent = p}) end
local function Grad(p, c1, c2, rot) return C("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}), Rotation = rot or 90, Parent = p}) end

local function Ripple(btn, pos)
    local r = C("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, pos.X - btn.AbsolutePosition.X, 0, pos.Y - btn.AbsolutePosition.Y), Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = btn.ZIndex + 1, Parent = btn})
    Corner(r, UDim.new(1, 0))
    local ms = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.5
    Tw(r, 0.5, {Size = UDim2.new(0, ms, 0, ms), BackgroundTransparency = 1})
    task.delay(0.5, function() r:Destroy() end)
end

local function GetPing()
    local s, p = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    return s and p or 0
end

local KeyNames = {}
for _, v in ipairs(Enum.KeyCode:GetEnumItems()) do
    KeyNames[v] = v.Name
end

-- ══════════════════════════════════════════════════════════════
-- PLACE ID AUTO-DETECTION ENGINE
-- ══════════════════════════════════════════════════════════════
local function findMatchingGames(placeId)
    local matches = {}
    local currentUniverseId = game.GameId
    for _, entry in ipairs(GAME_REGISTRY) do
        local matched = false
        if entry.PlaceIds then
            for _, pid in ipairs(entry.PlaceIds) do
                if pid == placeId then
                    matched = true
                    break
                end
            end
        end
        if not matched and entry.UniverseId and currentUniverseId and currentUniverseId > 0 then
            if entry.UniverseId == currentUniverseId then
                matched = true
            end
        end
        if matched then
            table.insert(matches, entry)
        end
    end
    return matches
end

local function executeGameScript(gameData)
    local success, err = pcall(function()
        if gameData.Callback then
            gameData.Callback()
        elseif gameData.URL then
            loadstring(game:HttpGet(gameData.URL))()
        end
    end)
    if success then
        NInfo("SYNOX HUB", gameData.Name .. " loaded successfully!")
    else
        NError("Execution Error", gameData.Name .. " failed to load:\n" .. tostring(err))
    end
    return success
end

-- ══════════════════════════════════════════════════════════════
-- HUB STATE
-- ══════════════════════════════════════════════════════════════
local gamesList = {}
local connections = {}
local minimized = false
local destroyed = false
local tabs = {}
local activeTab = "Home"
local pages = {}
local currentHotkey = CONFIG.DefaultHotkey
local hubVisible = true
local autoDetectedGames = findMatchingGames(CURRENT_PLACE_ID)

-- ══════════════════════════════════════════════════════════════
-- SCREENGUI
-- ══════════════════════════════════════════════════════════════
local SG = C("ScreenGui", {Name = "SynoxHub_" .. HttpService:GenerateGUID(false), ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, IgnoreGuiInset = true})
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ══════════════════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████
-- █              AUTO-DETECT SELECTION DIALOG                █
-- ████████████████████████████████████████████████████████████
-- ══════════════════════════════════════════════════════════════
local function showSelectionDialog(matchedGames, onSelect, onSkip)
    local Overlay = C("Frame", {Name = "SelectOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(5, 5, 8), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 200, Parent = SG})

    local dialogH = 190 + (#matchedGames * 62)
    if dialogH > 520 then dialogH = 520 end

    local DOuter = C("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 440, 0, dialogH), BackgroundColor3 = T.Outer, BackgroundTransparency = T.OuterT, BorderSizePixel = 0, ZIndex = 201, ClipsDescendants = true, Parent = Overlay})
    Corner(DOuter, T.CRL)
    Stroke(DOuter, T.OuterStroke, 1.5, T.OuterStrokeT)

    local DPanel = C("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = T.Bg, BackgroundTransparency = T.BgT, BorderSizePixel = 0, ZIndex = 202, ClipsDescendants = true, Parent = DOuter})
    Corner(DPanel, T.CR)
    Stroke(DPanel, T.PanelStroke, 1, 0.5)

    -- Title bar
    local DTB = C("Frame", {Size = UDim2.new(1, 0, 0, T.TBH), BackgroundColor3 = T.TitleBg, BackgroundTransparency = T.TitleBgT, BorderSizePixel = 0, ZIndex = 210, Parent = DPanel})
    Corner(DTB, T.CR)
    C("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = T.TitleBg, BackgroundTransparency = T.TitleBgT, BorderSizePixel = 0, ZIndex = 210, Parent = DTB})
    C("TextLabel", {Size = UDim2.new(0.8, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = "SYNOX HUB — Game Detected!", TextColor3 = T.TextPri, TextSize = 15, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 211, Parent = DTB})
    C("Frame", {Size = UDim2.new(0, 75, 0, 2), Position = UDim2.new(0, 14, 1, -2), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 212, Parent = DTB})

    -- Glow line
    local DGlow = C("Frame", {Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 0, T.TBH), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 205, Parent = DPanel})
    Grad(DGlow, T.AccentGlow, Color3.new(0, 0, 0), 0)

    -- Content
    local DContent = C("Frame", {Size = UDim2.new(1, -30, 1, -(T.TBH + 20)), Position = UDim2.new(0, 15, 0, T.TBH + 10), BackgroundTransparency = 1, ZIndex = 203, Parent = DPanel})

    -- Icon
    local DetectIcon = C("Frame", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 204, Parent = DContent})
    Corner(DetectIcon, UDim.new(1, 0))
    Stroke(DetectIcon, T.Accent, 2, 0.3)
    C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Text = "🎮", TextSize = 28, ZIndex = 205, Parent = DetectIcon})

    -- Title
    local countText = #matchedGames == 1 and "1 compatible script detected for this game:" or (#matchedGames .. " compatible scripts detected for this game:")
    C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0.5, 0, 0, 58), BackgroundTransparency = 1, Text = countText, TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, ZIndex = 204, Parent = DContent})

    -- Script selection buttons
    local btnY = 84
    for i, gameData in ipairs(matchedGames) do
        local scriptBtn = C("TextButton", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 52), Position = UDim2.new(0.5, 0, 0, btnY), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, Text = "", BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 205, Parent = DContent})
        Corner(scriptBtn, T.CRS)
        Stroke(scriptBtn, T.CardStroke, 1, 0.5)

        -- Icon
        C("TextLabel", {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 8, 0.5, -19), BackgroundTransparency = 1, Text = gameData.Icon or "📜", TextSize = 22, ZIndex = 206, Parent = scriptBtn})

        -- Name
        C("TextLabel", {Size = UDim2.new(0.55, 0, 0, 18), Position = UDim2.new(0, 50, 0, 8), BackgroundTransparency = 1, Text = gameData.Name, TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 206, Parent = scriptBtn})

        -- Short desc
        C("TextLabel", {Size = UDim2.new(0.55, 0, 0, 14), Position = UDim2.new(0, 50, 0, 28), BackgroundTransparency = 1, Text = gameData.ShortDesc or "", TextColor3 = T.TextMut, TextSize = 10, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 206, Parent = scriptBtn})

        -- Execute indicator
        local execInd = C("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 75, 0, 28), Position = UDim2.new(1, -8, 0.5, 0), BackgroundColor3 = T.BtnExec, BackgroundTransparency = 0.15, Text = "Execute", TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = T.FH, ZIndex = 206, Parent = scriptBtn})
        Corner(execInd, T.CRS)

        -- Hover
        scriptBtn.MouseEnter:Connect(function()
            Tw(scriptBtn, 0.2, {BackgroundColor3 = T.CardHov, BackgroundTransparency = 0.15})
            local s = scriptBtn:FindFirstChildOfClass("UIStroke")
            if s then Tw(s, 0.2, {Color = T.Accent, Transparency = 0.3}) end
        end)
        scriptBtn.MouseLeave:Connect(function()
            Tw(scriptBtn, 0.2, {BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT})
            local s = scriptBtn:FindFirstChildOfClass("UIStroke")
            if s then Tw(s, 0.2, {Color = T.CardStroke, Transparency = 0.5}) end
        end)

        scriptBtn.MouseButton1Click:Connect(function()
            Ripple(scriptBtn, Vector2.new(scriptBtn.AbsolutePosition.X + scriptBtn.AbsoluteSize.X / 2, scriptBtn.AbsolutePosition.Y + scriptBtn.AbsoluteSize.Y / 2))
            Tw(DOuter, 0.35, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
            Tw(Overlay, 0.4, {BackgroundTransparency = 1})
            task.delay(0.45, function()
                Overlay:Destroy()
                onSelect(gameData)
            end)
        end)

        btnY = btnY + 60
    end

    -- Skip button (Open Hub)
    local skipBtn = C("TextButton", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0.5, 0, 0, btnY + 6), BackgroundColor3 = Color3.fromRGB(42, 42, 54), BackgroundTransparency = 0.3, Text = "⏭  Open Hub (Manual Selection)", TextColor3 = T.TextSec, TextSize = 12, Font = T.FH, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 205, Parent = DContent})
    Corner(skipBtn, T.CRS)
    Stroke(skipBtn, T.CardStroke, 1, 0.6)

    skipBtn.MouseEnter:Connect(function() Tw(skipBtn, 0.2, {BackgroundTransparency = 0.1, TextColor3 = T.TextPri}) end)
    skipBtn.MouseLeave:Connect(function() Tw(skipBtn, 0.2, {BackgroundTransparency = 0.3, TextColor3 = T.TextSec}) end)

    skipBtn.MouseButton1Click:Connect(function()
        Ripple(skipBtn, Vector2.new(skipBtn.AbsolutePosition.X + skipBtn.AbsoluteSize.X / 2, skipBtn.AbsolutePosition.Y + skipBtn.AbsoluteSize.Y / 2))
        Tw(DOuter, 0.35, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
        Tw(Overlay, 0.4, {BackgroundTransparency = 1})
        task.delay(0.45, function()
            Overlay:Destroy()
            onSkip()
        end)
    end)

    -- Footer
    C("TextLabel", {AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0.5, 0, 1, -2), BackgroundTransparency = 1, Text = "© IEM7R | dc:siberguvenlik | PlaceId: " .. tostring(CURRENT_PLACE_ID), TextColor3 = T.TextMut, TextSize = 9, Font = T.FB, ZIndex = 204, Parent = DContent})

    -- Open animation
    DOuter.Size = UDim2.new(0, 0, 0, 0)
    DOuter.BackgroundTransparency = 1
    Overlay.BackgroundTransparency = 1

    task.delay(0.05, function()
        Tw(Overlay, 0.3, {BackgroundTransparency = 0.15})
        Tw(DOuter, 0.5, {Size = UDim2.new(0, 440, 0, dialogH), BackgroundTransparency = T.OuterT}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

-- ══════════════════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████
-- █             REDESIGNED KEY SYSTEM SCREEN                 █
-- ██████████████████══════════════════════════════════════════
-- ══════════════════════════════════════════════════════════════

local keyVerified = false

local function setVerifiedGlobals(key)
    keyVerified = true
    if _G then
        _G.SynoxKeyVerified = true
        _G.SynoxKey = key
    end
    if getgenv then
        getgenv().SynoxKeyVerified = true
        getgenv().SynoxKey = key
    end
end

local function showKeySystem(onSuccess)
    if not CONFIG.KeySystemEnabled then
        setVerifiedGlobals("BYPASS")
        onSuccess()
        return
    end

    -- Try saved key first
    local savedKey = loadSavedKey()
    if savedKey and savedKey ~= "" then
        local valid = validateKey(savedKey)
        if valid then
            setVerifiedGlobals(savedKey)
            onSuccess()
            return
        end
    end

    -- Dark overlay
    local KeyOverlay = C("Frame", {Name = "KeyOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(5, 5, 8), BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 100, Parent = SG})

    local KeyOuter = C("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 430, 0, 360), BackgroundColor3 = T.Outer, BackgroundTransparency = T.OuterT, BorderSizePixel = 0, ZIndex = 101, ClipsDescendants = true, Parent = KeyOverlay})
    Corner(KeyOuter, T.CRL)
    Stroke(KeyOuter, T.OuterStroke, 1.5, T.OuterStrokeT)

    local KeyPanel = C("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = T.Bg, BackgroundTransparency = T.BgT, BorderSizePixel = 0, ZIndex = 102, ClipsDescendants = true, Parent = KeyOuter})
    Corner(KeyPanel, T.CR)
    Stroke(KeyPanel, T.PanelStroke, 1, 0.5)

    -- Title bar (matching Hub title bar)
    local KeyTB = C("Frame", {Size = UDim2.new(1, 0, 0, T.TBH), BackgroundColor3 = T.TitleBg, BackgroundTransparency = T.TitleBgT, BorderSizePixel = 0, ZIndex = 110, Parent = KeyPanel})
    Corner(KeyTB, T.CR)
    C("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = T.TitleBg, BackgroundTransparency = T.TitleBgT, BorderSizePixel = 0, ZIndex = 110, Parent = KeyTB})
    C("TextLabel", {Size = UDim2.new(0.8, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = "⚡  SYNOX HUB", TextColor3 = T.TextPri, TextSize = 16, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 111, Parent = KeyTB})
    C("Frame", {Size = UDim2.new(0, 78, 0, 2), Position = UDim2.new(0, 14, 1, -2), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 112, Parent = KeyTB})

    -- Close button
    local KeyCloseBtn = C("TextButton", {Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -34, 0.5, -14), BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5, Text = "✕", TextColor3 = T.TextSec, TextSize = 13, Font = T.FB, BorderSizePixel = 0, ZIndex = 112, AutoButtonColor = false, Parent = KeyTB})
    Corner(KeyCloseBtn, T.CRS)
    KeyCloseBtn.MouseEnter:Connect(function() Tw(KeyCloseBtn, 0.2, {BackgroundColor3 = T.BtnDng, BackgroundTransparency = 0.2, TextColor3 = Color3.new(1, 1, 1)}) end)
    KeyCloseBtn.MouseLeave:Connect(function() Tw(KeyCloseBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5, TextColor3 = T.TextSec}) end)
    KeyCloseBtn.MouseButton1Click:Connect(function()
        Tw(KeyOuter, 0.35, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
        Tw(KeyOverlay, 0.4, {BackgroundTransparency = 1})
        task.delay(0.45, function() SG:Destroy() end)
    end)

    -- Glow line
    local KeyGlow = C("Frame", {Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 0, T.TBH), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 105, Parent = KeyPanel})
    Grad(KeyGlow, T.AccentGlow, Color3.new(0, 0, 0), 0)

    -- Content
    local KeyContent = C("Frame", {Size = UDim2.new(1, -30, 1, -(T.TBH + 16)), Position = UDim2.new(0, 15, 0, T.TBH + 8), BackgroundTransparency = 1, ZIndex = 103, Parent = KeyPanel})

    -- Lock icon circle
    local LockRing = C("Frame", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 52, 0, 52), Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 104, Parent = KeyContent})
    Corner(LockRing, UDim.new(1, 0))
    Stroke(LockRing, T.Accent, 1.5, 0.3)
    local LockIcon = C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Text = "🔒", TextSize = 24, ZIndex = 105, Parent = LockRing})

    C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0.5, 0, 0, 56), BackgroundTransparency = 1, Text = "KEY VERIFICATION", TextColor3 = T.TextPri, TextSize = 14, Font = T.FT, ZIndex = 104, Parent = KeyContent})
    C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0.95, 0, 0, 15), Position = UDim2.new(0.5, 0, 0, 76), BackgroundTransparency = 1, Text = "Enter your license key to unlock SYNOX HUB", TextColor3 = T.TextMut, TextSize = 11, Font = T.FB, ZIndex = 104, Parent = KeyContent})

    -- Key input field
    local KeyInputCard = C("Frame", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0.5, 0, 0, 100), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, ZIndex = 104, Parent = KeyContent})
    Corner(KeyInputCard, T.CRS)
    local keyInputStroke = Stroke(KeyInputCard, T.CardStroke, 1, 0.5)

    C("TextLabel", {Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = "🔑", TextSize = 14, ZIndex = 105, Parent = KeyInputCard})
    local KeyInput = C("TextBox", {Size = UDim2.new(1, -44, 1, 0), Position = UDim2.new(0, 36, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "SYNOX-XXXX-XXXX", PlaceholderColor3 = T.TextMut, TextColor3 = T.TextPri, TextSize = 13, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 105, Parent = KeyInputCard})

    KeyInput.Focused:Connect(function() Tw(keyInputStroke, 0.2, {Color = T.Accent, Transparency = 0.2}) end)
    KeyInput.FocusLost:Connect(function() Tw(keyInputStroke, 0.2, {Color = T.CardStroke, Transparency = 0.5}) end)

    local KeyStatus = C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0.5, 0, 0, 144), BackgroundTransparency = 1, Text = "", TextColor3 = T.Red, TextSize = 11, Font = T.FH, ZIndex = 104, Parent = KeyContent})

    -- Verify button
    local VerifyBtn = C("TextButton", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0.5, 0, 0, 164), BackgroundColor3 = T.BtnExec, BackgroundTransparency = 0, Text = "✓  Verify Key", TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = T.FT, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 105, Parent = KeyContent})
    Corner(VerifyBtn, T.CRS)
    VerifyBtn.MouseEnter:Connect(function() Tw(VerifyBtn, 0.2, {BackgroundColor3 = T.BtnExecH}) end)
    VerifyBtn.MouseLeave:Connect(function() Tw(VerifyBtn, 0.2, {BackgroundColor3 = T.BtnExec}) end)

    -- Discord Button (Only Discord - exclusive gateway for keys)
    local DiscBtn = C("TextButton", {AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0.5, 0, 0, 206), BackgroundColor3 = Color3.fromRGB(88, 101, 242), BackgroundTransparency = 0.15, Text = "🎮  Join Discord to Get Key", TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = T.FH, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 105, Parent = KeyContent})
    Corner(DiscBtn, T.CRS)
    local discStroke = Stroke(DiscBtn, Color3.fromRGB(110, 125, 255), 1, 0.5)

    DiscBtn.MouseEnter:Connect(function() Tw(DiscBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(105, 120, 255), BackgroundTransparency = 0}) end)
    DiscBtn.MouseLeave:Connect(function() Tw(DiscBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(88, 101, 242), BackgroundTransparency = 0.15}) end)
    DiscBtn.MouseButton1Click:Connect(function()
        Ripple(DiscBtn, Vector2.new(DiscBtn.AbsolutePosition.X + DiscBtn.AbsoluteSize.X / 2, DiscBtn.AbsolutePosition.Y + DiscBtn.AbsoluteSize.Y / 2))
        if setclipboard then setclipboard(CONFIG.DiscordLink) end
        KeyStatus.TextColor3 = T.Green
        KeyStatus.Text = "✓ Discord invite copied to clipboard! Join to claim your key."
        DiscBtn.Text = "✓  Discord Link Copied!"
        Tw(DiscBtn, 0.15, {BackgroundColor3 = T.Green, BackgroundTransparency = 0.1})
        task.delay(2.5, function()
            KeyStatus.Text = ""
            DiscBtn.Text = "🎮  Join Discord to Get Key"
            Tw(DiscBtn, 0.25, {BackgroundColor3 = Color3.fromRGB(88, 101, 242), BackgroundTransparency = 0.15})
        end)
    end)

    -- Footer notice
    C("TextLabel", {AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0.5, 0, 1, -2), BackgroundTransparency = 1, Text = "Keys are generated exclusively via our Discord Bot • SYNOX HUB v" .. CONFIG.Version, TextColor3 = T.TextMut, TextSize = 9, Font = T.FB, ZIndex = 104, Parent = KeyContent})

    -- Shake animation
    local function shakeInput()
        Tw(KeyInputCard, 0.06, {Position = UDim2.new(0.5, 10, 0, 100)})
        task.delay(0.06, function() Tw(KeyInputCard, 0.06, {Position = UDim2.new(0.5, -10, 0, 100)}) end)
        task.delay(0.12, function() Tw(KeyInputCard, 0.06, {Position = UDim2.new(0.5, 6, 0, 100)}) end)
        task.delay(0.18, function() Tw(KeyInputCard, 0.06, {Position = UDim2.new(0.5, -6, 0, 100)}) end)
        task.delay(0.24, function() Tw(KeyInputCard, 0.08, {Position = UDim2.new(0.5, 0, 0, 100)}) end)
    end

    -- Verify logic
    local function tryVerify()
        local inputKey = KeyInput.Text:match("^%s*(.-)%s*$")
        if inputKey == "" then
            KeyStatus.TextColor3 = T.Red
            KeyStatus.Text = "✕ Please enter a key!"
            shakeInput()
            return
        end

        VerifyBtn.Text = "⏳  Verifying..."
        Tw(VerifyBtn, 0.15, {BackgroundColor3 = T.Yellow})
        KeyStatus.TextColor3 = T.TextAcc
        KeyStatus.Text = "Verifying key with database..."

        task.delay(0.5, function()
            if validateKey(inputKey) then
                setVerifiedGlobals(inputKey)
                saveKey(inputKey)
                KeyStatus.TextColor3 = T.Green
                KeyStatus.Text = "✓ Key verified! Loading SYNOX HUB..."
                VerifyBtn.Text = "✓  Verified!"
                Tw(VerifyBtn, 0.2, {BackgroundColor3 = T.Green})

                LockIcon.Text = "🔓"
                Tw(LockRing, 0.3, {BackgroundTransparency = 0.3})
                local lockStroke = LockRing:FindFirstChildOfClass("UIStroke")
                if lockStroke then Tw(lockStroke, 0.3, {Color = T.Green}) end

                task.delay(0.8, function()
                    Tw(KeyOuter, 0.4, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
                    Tw(KeyOverlay, 0.5, {BackgroundTransparency = 1})
                    task.delay(0.55, function()
                        KeyOverlay:Destroy()
                        onSuccess()
                    end)
                end)
            else
                KeyStatus.TextColor3 = T.Red
                KeyStatus.Text = "✕ Invalid key! Please check your Discord key."
                VerifyBtn.Text = "✓  Verify Key"
                Tw(VerifyBtn, 0.15, {BackgroundColor3 = T.BtnExec})
                shakeInput()
                Tw(keyInputStroke, 0.15, {Color = T.Red, Transparency = 0.2})
                task.delay(1, function() Tw(keyInputStroke, 0.3, {Color = T.CardStroke, Transparency = 0.5}) end)
            end
        end)
    end

    VerifyBtn.MouseButton1Click:Connect(tryVerify)
    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then tryVerify() end
    end)

    -- Open animation
    KeyOuter.Size = UDim2.new(0, 0, 0, 0)
    KeyOuter.BackgroundTransparency = 1
    KeyOverlay.BackgroundTransparency = 1

    task.delay(0.05, function()
        Tw(KeyOverlay, 0.3, {BackgroundTransparency = 0.12})
        Tw(KeyOuter, 0.5, {Size = UDim2.new(0, 430, 0, 360), BackgroundTransparency = T.OuterT}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

-- ══════════════════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████
-- █                    MAIN HUB BUILD                         █
-- ████████████████████████████████████████████████████████████
-- ══════════════════════════════════════════════════════════════

local function buildHub()

    -- ══════════════════════════════════════════════════════════
    -- OUTER FRAME
    -- ══════════════════════════════════════════════════════════
    local OF = C("Frame", {Name = "Outer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, T.WW + 12, 0, T.WH + 12), BackgroundColor3 = T.Outer, BackgroundTransparency = T.OuterT, BorderSizePixel = 0, ClipsDescendants = true, Parent = SG})
    Corner(OF, T.CRL)
    Stroke(OF, T.OuterStroke, 1.5, T.OuterStrokeT)

    local MF = C("Frame", {Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -12, 1, -12), BackgroundColor3 = T.Bg, BackgroundTransparency = T.BgT, BorderSizePixel = 0, ClipsDescendants = true, Parent = OF})
    Corner(MF, T.CR)
    Stroke(MF, T.PanelStroke, 1, 0.5)

    local GL = C("Frame", {Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 0, T.TBH), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 5, Parent = MF})
    Grad(GL, T.AccentGlow, Color3.new(0, 0, 0), 0)

    -- ══════════════════════════════════════════════════════════
    -- TITLE BAR
    -- ══════════════════════════════════════════════════════════
    local TB = C("Frame", {Name = "TitleBar", Size = UDim2.new(1, 0, 0, T.TBH), BackgroundColor3 = T.TitleBg, BackgroundTransparency = T.TitleBgT, BorderSizePixel = 0, ZIndex = 10, Parent = MF})
    Corner(TB, T.CR)
    C("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = T.TitleBg, BackgroundTransparency = T.TitleBgT, BorderSizePixel = 0, ZIndex = 10, Parent = TB})

    C("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = "⚡  SYNOX HUB", TextColor3 = T.TextPri, TextSize = 16, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11, Parent = TB})
    C("Frame", {Size = UDim2.new(0, 78, 0, 2), Position = UDim2.new(0, 14, 1, -2), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 12, Parent = TB})

    -- Close & Minimize
    local XBtn = C("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -38, 0.5, -15), BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5, Text = "✕", TextColor3 = T.TextSec, TextSize = 14, Font = T.FB, BorderSizePixel = 0, ZIndex = 12, AutoButtonColor = false, Parent = TB})
    Corner(XBtn, T.CRS)
    local MnBtn = C("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -72, 0.5, -15), BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5, Text = "─", TextColor3 = T.TextSec, TextSize = 14, Font = T.FB, BorderSizePixel = 0, ZIndex = 12, AutoButtonColor = false, Parent = TB})
    Corner(MnBtn, T.CRS)

    XBtn.MouseEnter:Connect(function() Tw(XBtn, 0.2, {BackgroundColor3 = T.BtnDng, BackgroundTransparency = 0.2, TextColor3 = Color3.new(1, 1, 1)}) end)
    XBtn.MouseLeave:Connect(function() Tw(XBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5, TextColor3 = T.TextSec}) end)
    MnBtn.MouseEnter:Connect(function() Tw(MnBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(60, 60, 75), BackgroundTransparency = 0.2}) end)
    MnBtn.MouseLeave:Connect(function() Tw(MnBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(45, 45, 55), BackgroundTransparency = 0.5}) end)

    -- ══════════════════════════════════════════════════════════
    -- DRAGGING
    -- ══════════════════════════════════════════════════════════
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    TB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = OF.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    TB.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    table.insert(connections, UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local d = input.Position - dragStart; OF.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end))

    -- ══════════════════════════════════════════════════════════
    -- CONTENT AREA
    -- ══════════════════════════════════════════════════════════
    local CA = C("Frame", {Name = "Content", Size = UDim2.new(1, 0, 1, -T.TBH), Position = UDim2.new(0, 0, 0, T.TBH), BackgroundTransparency = 1, ClipsDescendants = true, Parent = MF})

    -- Tab bar
    local TBar = C("Frame", {Size = UDim2.new(1, -20, 0, T.TABH), Position = UDim2.new(0, 10, 0, 6), BackgroundTransparency = 1, Parent = CA})
    C("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TBar})

    -- Page container
    local PC = C("Frame", {Name = "Pages", Size = UDim2.new(1, -20, 1, -(T.TABH + 18)), Position = UDim2.new(0, 10, 0, T.TABH + 12), BackgroundColor3 = T.Panel, BackgroundTransparency = T.PanelT, BorderSizePixel = 0, ClipsDescendants = true, Parent = CA})
    Corner(PC, T.CR)
    Stroke(PC, T.PanelStroke, 1, 0.6)

    -- ══════════════════════════════════════════════════════════
    -- HOME PAGE
    -- ══════════════════════════════════════════════════════════
    local HP = C("Frame", {Name = "Home", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = true, Parent = PC})
    Pad(HP, 10, 12, 10, 12)

    -- Profile card
    local ProfFrame = C("Frame", {Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = HP})
    Corner(ProfFrame, T.CRS); Stroke(ProfFrame, T.CardStroke, 1, 0.6)

    local AvatarC = C("Frame", {Size = UDim2.new(0, 56, 0, 56), Position = UDim2.new(0, 12, 0.5, -28), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = ProfFrame})
    Corner(AvatarC, UDim.new(1, 0)); Stroke(AvatarC, T.Accent, 2, 0.3)

    local AvatarFallback = C("TextLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Text = string.upper(string.sub(LocalPlayer.Name or "U", 1, 1)), TextColor3 = T.TextAcc, TextSize = 22, Font = T.FT, ZIndex = 1, Parent = AvatarC})

    local AvatarImg = C("ImageButton", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(24, 24, 32), BackgroundTransparency = 0, BorderSizePixel = 0, AutoButtonColor = false, Image = "", ZIndex = 2, Parent = AvatarC})
    Corner(AvatarImg, UDim.new(1, 0))

    -- Multi-tiered reliable User Logo & Avatar loader
    local loadedCustomLogo = nil
    local loadedRobloxAvatar = nil

    task.spawn(function()
        local isIem7r = string.find(string.lower(LocalPlayer.Name or ""), "iem7r") ~= nil
        local gca = (typeof(getcustomasset) == "function" and getcustomasset) or (typeof(getsynasset) == "function" and getsynasset)

        -- Method 1: Local / Downloaded Brand Logo (iem7r_logo.png)
        if gca then
            local paths = {"Synox/iem7r_logo.png", "iem7r_logo.png"}
            for _, p in ipairs(paths) do
                pcall(function()
                    if typeof(isfile) == "function" and isfile(p) then
                        local a = gca(p)
                        if a and a ~= "" then loadedCustomLogo = a end
                    end
                end)
                if loadedCustomLogo then break end
            end

            if not loadedCustomLogo and typeof(writefile) == "function" then
                local urls = {
                    "https://raw.githubusercontent.com/emrself/mining/main/iem7r_logo.png",
                    "https://cdn.jsdelivr.net/gh/emrself/mining@main/iem7r_logo.png",
                }
                for _, u in ipairs(urls) do
                    pcall(function()
                        local data = fetchText(u)
                        if data and #data > 500 then
                            ensureFolder()
                            writefile("Synox/iem7r_logo.png", data)
                            local a = gca("Synox/iem7r_logo.png")
                            if a and a ~= "" then loadedCustomLogo = a end
                        end
                    end)
                    if loadedCustomLogo then break end
                end
            end
        end

        -- Method 2: Official Roblox HeadShot Thumbnail via Players Service
        pcall(function()
            local thumb, isReady = Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
            if thumb and thumb ~= "" then
                loadedRobloxAvatar = thumb
            end
        end)

        -- Method 3: Fallback to AvatarBust
        if not loadedRobloxAvatar then
            pcall(function()
                local thumb2, isReady2 = Players:GetUserThumbnailAsync(
                    LocalPlayer.UserId,
                    Enum.ThumbnailType.AvatarBust,
                    Enum.ThumbnailSize.Size150x150
                )
                if thumb2 and thumb2 ~= "" then
                    loadedRobloxAvatar = thumb2
                end
            end)
        end

        -- Determine primary image to display
        local primary = nil
        if isIem7r then
            primary = loadedCustomLogo or loadedRobloxAvatar
        else
            primary = loadedRobloxAvatar or loadedCustomLogo
        end

        if primary and primary ~= "" then
            AvatarImg.Image = primary
            AvatarImg.BackgroundTransparency = 0
            AvatarFallback.Visible = false
        else
            AvatarFallback.Visible = true
        end
    end)

    -- Click avatar to toggle between IEM7R Brand Logo and Roblox Character Avatar (if both loaded)
    AvatarImg.MouseButton1Click:Connect(function()
        if loadedCustomLogo and loadedRobloxAvatar then
            if AvatarImg.Image == loadedCustomLogo then
                AvatarImg.Image = loadedRobloxAvatar
                NInfo("Profile", "Switched to Roblox Character Avatar")
            else
                AvatarImg.Image = loadedCustomLogo
                NInfo("Profile", "Switched to IEM7R Brand Logo")
            end
        end
    end)

    C("TextLabel", {Size = UDim2.new(0.6, 0, 0, 18), Position = UDim2.new(0, 78, 0, 14), BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name, TextColor3 = T.TextPri, TextSize = 14, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = ProfFrame})
    C("TextLabel", {Size = UDim2.new(0.6, 0, 0, 14), Position = UDim2.new(0, 78, 0, 34), BackgroundTransparency = 1, Text = "SYNOX HUB v" .. CONFIG.Version .. " • Premium", TextColor3 = T.TextMut, TextSize = 10, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, Parent = ProfFrame})
    local OD = C("Frame", {Size = UDim2.new(0, 7, 0, 7), Position = UDim2.new(0, 78, 0, 55), BackgroundColor3 = T.Green, BorderSizePixel = 0, Parent = ProfFrame})
    Corner(OD, UDim.new(1, 0))
    C("TextLabel", {Size = UDim2.new(0.4, 0, 0, 12), Position = UDim2.new(0, 89, 0, 53), BackgroundTransparency = 1, Text = "Online", TextColor3 = T.Green, TextSize = 10, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, Parent = ProfFrame})

    -- Stats row
    local StatsRow = C("Frame", {Size = UDim2.new(1, 0, 0, 48), Position = UDim2.new(0, 0, 0, 88), BackgroundTransparency = 1, Parent = HP})

    local PKC = C("Frame", {Size = UDim2.new(0.32, -4, 1, 0), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = StatsRow})
    Corner(PKC, T.CRS); Stroke(PKC, T.CardStroke, 1, 0.6); Pad(PKC, 6, 8, 6, 8)
    C("TextLabel", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Text = "PING", TextColor3 = T.TextMut, TextSize = 9, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = PKC})
    local PV = C("TextLabel", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 13), BackgroundTransparency = 1, Text = "0 ms", TextColor3 = T.TextAcc, TextSize = 17, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, Parent = PKC})

    local FKC = C("Frame", {Size = UDim2.new(0.32, -4, 1, 0), Position = UDim2.new(0.34, 0, 0, 0), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = StatsRow})
    Corner(FKC, T.CRS); Stroke(FKC, T.CardStroke, 1, 0.6); Pad(FKC, 6, 8, 6, 8)
    C("TextLabel", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Text = "FPS", TextColor3 = T.TextMut, TextSize = 9, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = FKC})
    local FV = C("TextLabel", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 13), BackgroundTransparency = 1, Text = "60", TextColor3 = T.TextAcc, TextSize = 17, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, Parent = FKC})

    local GLC = C("Frame", {Size = UDim2.new(0.34, 0, 1, 0), Position = UDim2.new(0.66, 0, 0, 0), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = StatsRow})
    Corner(GLC, T.CRS); Stroke(GLC, T.CardStroke, 1, 0.6); Pad(GLC, 6, 8, 6, 8)
    C("TextLabel", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Text = "SCRIPTS", TextColor3 = T.TextMut, TextSize = 9, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = GLC})
    local GV = C("TextLabel", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 13), BackgroundTransparency = 1, Text = "0", TextColor3 = T.TextAcc, TextSize = 17, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, Parent = GLC})

    -- Status section
    local SSec = C("Frame", {Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 143), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = HP})
    Corner(SSec, T.CRS); Stroke(SSec, T.CardStroke, 1, 0.6); Pad(SSec, 7, 10, 7, 10)
    C("TextLabel", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Text = "STATUS", TextColor3 = T.TextMut, TextSize = 9, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = SSec})
    local SValLabel = C("TextLabel", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 14), BackgroundTransparency = 1, Text = "Connected • All Systems Online", TextColor3 = T.Green, TextSize = 11, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = SSec})
    local SDet = C("TextLabel", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1, Text = "• 0 scripts loaded   • PlaceId: " .. tostring(CURRENT_PLACE_ID), TextColor3 = T.TextSec, TextSize = 10, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, Parent = SSec})

    if #autoDetectedGames > 0 then
        SValLabel.Text = "Connected • Game Detected: " .. autoDetectedGames[1].Name
        SValLabel.TextColor3 = T.Accent
    else
        SValLabel.Text = "Connected • Universal Mode"
        SValLabel.TextColor3 = T.Green
    end

    -- ══════════════════════════════════════════════════════════
    -- GAMES PAGE
    -- ══════════════════════════════════════════════════════════
    local GP = C("Frame", {Name = "Games", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ClipsDescendants = true, Parent = PC})

    local GameListView = C("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = true, Parent = GP})
    local GameListScroll = C("ScrollingFrame", {Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.Scroll, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = GameListView})
    C("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = GameListScroll})
    Pad(GameListScroll, 6, 6, 6, 6)

    -- Game detail view
    local GameDetailView = C("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ClipsDescendants = true, Parent = GP})
    Pad(GameDetailView, 10, 12, 10, 12)

    local BackBtn = C("TextButton", {Size = UDim2.new(0, 38, 0, 38), BackgroundColor3 = Color3.fromRGB(30, 30, 38), BackgroundTransparency = 0.2, Text = "‹", TextColor3 = T.TextPri, TextSize = 24, Font = T.FT, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 3, Parent = GameDetailView})
    Corner(BackBtn, UDim.new(1, 0)); Stroke(BackBtn, T.CardStroke, 1, 0.5)
    BackBtn.MouseEnter:Connect(function() Tw(BackBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(45, 45, 58), BackgroundTransparency = 0}) end)
    BackBtn.MouseLeave:Connect(function() Tw(BackBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 30, 38), BackgroundTransparency = 0.2}) end)

    local DetailPanel = C("Frame", {Size = UDim2.new(1, 0, 0, 140), Position = UDim2.new(0, 0, 0, 46), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = GameDetailView})
    Corner(DetailPanel, T.CRS); Stroke(DetailPanel, T.CardStroke, 1, 0.6)

    -- Detail Thumbnail with dark frame and emoji fallback
    local DetailThumbFrame = C("Frame", {Size = UDim2.new(0, 120, 0, 120), Position = UDim2.new(0, 10, 0.5, -60), BackgroundColor3 = T.ThumbBg, BorderSizePixel = 0, ClipsDescendants = true, Parent = DetailPanel})
    Corner(DetailThumbFrame, T.CRS)
    Stroke(DetailThumbFrame, T.CardStroke, 1, 0.6)

    local DetailThumbImg = C("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, Image = "", Parent = DetailThumbFrame})
    local DetailThumbPlaceholder = C("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "🎮", TextSize = 42, Font = T.FB, TextColor3 = T.TextAcc, Parent = DetailThumbFrame})

    local DetailName = C("TextLabel", {Size = UDim2.new(0.55, 0, 0, 24), Position = UDim2.new(0, 142, 0, 18), BackgroundTransparency = 1, Text = "Game Name", TextColor3 = T.TextPri, TextSize = 18, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = DetailPanel})
    local DetailTag = C("TextLabel", {Size = UDim2.new(0, 90, 0, 18), Position = UDim2.new(0, 142, 0, 46), BackgroundColor3 = Color3.fromRGB(0, 120, 150), BackgroundTransparency = 0.7, Text = " Supported ", TextColor3 = T.TextAcc, TextSize = 10, Font = T.FB, Parent = DetailPanel})
    Corner(DetailTag, UDim.new(0, 3))

    local DetailExecBtn = C("TextButton", {Size = UDim2.new(0, 150, 0, 40), Position = UDim2.new(0, 142, 0, 78), BackgroundColor3 = T.BtnExec, Text = "Execute", TextColor3 = Color3.new(1, 1, 1), TextSize = 15, Font = T.FT, BorderSizePixel = 0, AutoButtonColor = false, Parent = DetailPanel})
    Corner(DetailExecBtn, T.CRS)
    DetailExecBtn.MouseEnter:Connect(function() Tw(DetailExecBtn, 0.2, {BackgroundColor3 = T.BtnExecH}) end)
    DetailExecBtn.MouseLeave:Connect(function() Tw(DetailExecBtn, 0.2, {BackgroundColor3 = T.BtnExec}) end)

    local DescSection = C("Frame", {Size = UDim2.new(1, 0, 1, -196), Position = UDim2.new(0, 0, 0, 192), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, ClipsDescendants = true, Parent = GameDetailView})
    Corner(DescSection, T.CRS); Stroke(DescSection, T.CardStroke, 1, 0.6); Pad(DescSection, 10, 12, 10, 12)
    C("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = "DESCRIPTION", TextColor3 = T.TextMut, TextSize = 10, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = DescSection})
    local DescScroll = C("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -20), Position = UDim2.new(0, 0, 0, 18), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Scroll, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = DescSection})
    local DescText = C("TextLabel", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = T.TextPri, TextSize = 13, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Parent = DescScroll})

    local currentDetailGame = nil

    -- ══════════════════════════════════════════════════════════
    -- SEARCH PAGE
    -- ══════════════════════════════════════════════════════════
    local SeP = C("Frame", {Name = "Search", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = PC})
    Pad(SeP, 8, 8, 8, 8)

    local SBC = C("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = SeP})
    Corner(SBC, T.CRS); Stroke(SBC, T.CardStroke, 1, 0.6)
    C("TextLabel", {Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = "🔍", TextSize = 14, Font = T.FB, Parent = SBC})
    local SI = C("TextBox", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 34, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search scripts...", PlaceholderColor3 = T.TextMut, TextColor3 = T.TextPri, TextSize = 13, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = SBC})

    SI.Focused:Connect(function() local s = SBC:FindFirstChildOfClass("UIStroke"); if s then Tw(s, 0.2, {Color = T.Accent, Transparency = 0.3}) end end)
    SI.FocusLost:Connect(function() local s = SBC:FindFirstChildOfClass("UIStroke"); if s then Tw(s, 0.2, {Color = T.CardStroke, Transparency = 0.6}) end end)

    local SRS = C("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -44), Position = UDim2.new(0, 0, 0, 42), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.Scroll, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = SeP})
    C("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SRS})
    Pad(SRS, 4, 4, 4, 4)
    local NR = C("TextLabel", {Name = "NR", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Type to search scripts...", TextColor3 = T.TextMut, TextSize = 12, Font = T.FB, Parent = SRS})

    -- ══════════════════════════════════════════════════════════
    -- SETTINGS PAGE
    -- ══════════════════════════════════════════════════════════
    local SetP = C("Frame", {Name = "Settings", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = PC})
    Pad(SetP, 10, 12, 10, 12)

    C("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "⚙️  Settings", TextColor3 = T.TextPri, TextSize = 16, Font = T.FT, TextXAlignment = Enum.TextXAlignment.Left, Parent = SetP})
    C("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 26), BackgroundColor3 = T.CardStroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = SetP})

    -- Hotkey setting
    local HotkeyCard = C("Frame", {Size = UDim2.new(1, 0, 0, 65), Position = UDim2.new(0, 0, 0, 34), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = SetP})
    Corner(HotkeyCard, T.CRS); Stroke(HotkeyCard, T.CardStroke, 1, 0.6); Pad(HotkeyCard, 10, 12, 10, 12)

    C("TextLabel", {Size = UDim2.new(0.6, 0, 0, 16), BackgroundTransparency = 1, Text = "Toggle Hotkey", TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = HotkeyCard})
    C("TextLabel", {Size = UDim2.new(0.6, 0, 0, 14), Position = UDim2.new(0, 0, 0, 18), BackgroundTransparency = 1, Text = "Click button, then press any key to rebind", TextColor3 = T.TextMut, TextSize = 10, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, Parent = HotkeyCard})

    local HotkeyBtn = C("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 140, 0, 32), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = T.InputBg, Text = KeyNames[currentHotkey] or "RightControl", TextColor3 = T.TextAcc, TextSize = 12, Font = T.FH, BorderSizePixel = 0, AutoButtonColor = false, Parent = HotkeyCard})
    Corner(HotkeyBtn, T.CRS); Stroke(HotkeyBtn, T.CardStroke, 1, 0.5)

    local listeningForHotkey = false
    local hotkeyConnection = nil

    HotkeyBtn.MouseButton1Click:Connect(function()
        if listeningForHotkey then return end
        listeningForHotkey = true
        HotkeyBtn.Text = "Press a key..."
        HotkeyBtn.TextColor3 = T.Yellow
        local stroke = HotkeyBtn:FindFirstChildOfClass("UIStroke")
        if stroke then Tw(stroke, 0.2, {Color = T.Yellow}) end

        hotkeyConnection = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentHotkey = input.KeyCode
                HotkeyBtn.Text = KeyNames[input.KeyCode] or input.KeyCode.Name
                HotkeyBtn.TextColor3 = T.TextAcc
                if stroke then Tw(stroke, 0.2, {Color = T.CardStroke}) end
                listeningForHotkey = false
                if hotkeyConnection then hotkeyConnection:Disconnect(); hotkeyConnection = nil end
                NInfo("SYNOX HUB", "Toggle hotkey changed to: " .. (KeyNames[input.KeyCode] or input.KeyCode.Name))
            end
        end)
    end)

    HotkeyBtn.MouseEnter:Connect(function() if not listeningForHotkey then Tw(HotkeyBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}) end end)
    HotkeyBtn.MouseLeave:Connect(function() if not listeningForHotkey then Tw(HotkeyBtn, 0.2, {BackgroundColor3 = T.InputBg}) end end)

    -- Key info card
    local KeyInfoCard = C("Frame", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0, 106), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = SetP})
    Corner(KeyInfoCard, T.CRS); Stroke(KeyInfoCard, T.CardStroke, 1, 0.6); Pad(KeyInfoCard, 10, 12, 10, 12)
    C("TextLabel", {Size = UDim2.new(0.6, 0, 0, 16), BackgroundTransparency = 1, Text = "License Status", TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeyInfoCard})
    local KeyStatusBadge = C("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 100, 0, 22), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = T.Green, BackgroundTransparency = 0.8, Text = "✓ Verified", TextColor3 = T.Green, TextSize = 11, Font = T.FH, BorderSizePixel = 0, Parent = KeyInfoCard})
    Corner(KeyStatusBadge, UDim.new(0, 3))

    -- Reset Key card
    local ResetCard = C("Frame", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0, 163), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = SetP})
    Corner(ResetCard, T.CRS); Stroke(ResetCard, T.CardStroke, 1, 0.6); Pad(ResetCard, 10, 12, 10, 12)
    C("TextLabel", {Size = UDim2.new(0.6, 0, 0, 16), BackgroundTransparency = 1, Text = "Reset License Key", TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = ResetCard})
    local ResetBtn = C("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 100, 0, 26), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = T.Red, BackgroundTransparency = 0.3, Text = "Reset Key", TextColor3 = Color3.new(1, 1, 1), TextSize = 11, Font = T.FH, BorderSizePixel = 0, AutoButtonColor = false, Parent = ResetCard})
    Corner(ResetBtn, T.CRS)

    ResetBtn.MouseButton1Click:Connect(function()
        deleteSavedKey()
        KeyStatusBadge.Text = "Cleared"
        KeyStatusBadge.TextColor3 = T.Yellow
        KeyStatusBadge.BackgroundColor3 = T.Yellow
        ResetBtn.Text = "✓ Cleared"
        NWarning("License", "Saved key deleted! You will be prompted on next launch.")
    end)
    ResetBtn.MouseEnter:Connect(function() Tw(ResetBtn, 0.2, {BackgroundTransparency = 0}) end)
    ResetBtn.MouseLeave:Connect(function() Tw(ResetBtn, 0.2, {BackgroundTransparency = 0.3}) end)

    -- Version card
    local VerCard = C("Frame", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0, 220), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = SetP})
    Corner(VerCard, T.CRS); Stroke(VerCard, T.CardStroke, 1, 0.6); Pad(VerCard, 10, 12, 10, 12)
    C("TextLabel", {Size = UDim2.new(0.5, 0, 0, 16), BackgroundTransparency = 1, Text = "Version", TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = VerCard})
    C("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 80, 0, 16), Position = UDim2.new(1, 0, 0.5, 0), BackgroundTransparency = 1, Text = "v" .. CONFIG.Version, TextColor3 = T.TextAcc, TextSize = 12, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Right, Parent = VerCard})

    -- Discord card
    local DiscCard = C("Frame", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0, 277), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, Parent = SetP})
    Corner(DiscCard, T.CRS); Stroke(DiscCard, T.CardStroke, 1, 0.6); Pad(DiscCard, 10, 12, 10, 12)
    C("TextLabel", {Size = UDim2.new(0.5, 0, 0, 16), BackgroundTransparency = 1, Text = "Official Discord", TextColor3 = T.TextPri, TextSize = 13, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, Parent = DiscCard})
    local CopyDiscBtn = C("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 100, 0, 26), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(88, 101, 242), BackgroundTransparency = 0.15, Text = "Copy Link", TextColor3 = Color3.new(1, 1, 1), TextSize = 11, Font = T.FH, BorderSizePixel = 0, AutoButtonColor = false, Parent = DiscCard})
    Corner(CopyDiscBtn, T.CRS)

    CopyDiscBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(CONFIG.DiscordLink) end
        CopyDiscBtn.Text = "✓ Copied!"
        task.delay(1.5, function() CopyDiscBtn.Text = "Copy Link" end)
    end)
    CopyDiscBtn.MouseEnter:Connect(function() Tw(CopyDiscBtn, 0.2, {BackgroundTransparency = 0}) end)
    CopyDiscBtn.MouseLeave:Connect(function() Tw(CopyDiscBtn, 0.2, {BackgroundTransparency = 0.15}) end)

    -- ══════════════════════════════════════════════════════════
    -- TAB SWITCHING
    -- ══════════════════════════════════════════════════════════
    pages = {Home = HP, Games = GP, Search = SeP, Settings = SetP}

    local function switchTab(name)
        if activeTab == name then return end
        activeTab = name
        if name ~= "Games" then GameListView.Visible = true; GameDetailView.Visible = false end
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, btn in pairs(tabs) do
            local isActive = (n == name)
            Tw(btn, 0.25, {BackgroundColor3 = isActive and T.TabAct or T.TabIn, BackgroundTransparency = isActive and T.TabActT or T.TabInT})
            local tt = btn:FindFirstChild("TT"); local al = btn:FindFirstChild("AL")
            if tt then Tw(tt, 0.25, {TextColor3 = isActive and T.TextAcc or T.TextSec}) end
            if al then Tw(al, 0.25, {BackgroundTransparency = isActive and 0.2 or 1}) end
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then Tw(s, 0.25, {Color = isActive and T.Accent or T.TabStroke, Transparency = isActive and 0.4 or 0.6}) end
        end
    end

    local tabNames = {"Home", "Games", "Search", "Settings"}
    local tabIcons = {Home = "🏠", Games = "🎮", Search = "🔍", Settings = "⚙️"}

    for i, name in ipairs(tabNames) do
        local isFirst = (i == 1)
        local btn = C("TextButton", {Size = UDim2.new(0, 110, 0, 32), BackgroundColor3 = isFirst and T.TabAct or T.TabIn, BackgroundTransparency = isFirst and T.TabActT or T.TabInT, Text = "", BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = i, Parent = TBar})
        Corner(btn, T.CRS); Stroke(btn, isFirst and T.Accent or T.TabStroke, 1, isFirst and 0.4 or 0.6)
        C("TextLabel", {Name = "TT", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Text = tabIcons[name] .. "  " .. name, TextColor3 = isFirst and T.TextAcc or T.TextSec, TextSize = 11, Font = T.FH, Parent = btn})
        C("Frame", {Name = "AL", Size = UDim2.new(0.6, 0, 0, 2), Position = UDim2.new(0.2, 0, 1, -3), BackgroundColor3 = T.Accent, BackgroundTransparency = isFirst and 0.2 or 1, BorderSizePixel = 0, Parent = btn})
        tabs[name] = btn
        btn.MouseButton1Click:Connect(function()
            Ripple(btn, Vector2.new(btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2))
            switchTab(name)
        end)
        btn.MouseEnter:Connect(function() if activeTab ~= name then Tw(btn, 0.15, {BackgroundTransparency = 0.3}) end end)
        btn.MouseLeave:Connect(function() if activeTab ~= name then Tw(btn, 0.15, {BackgroundTransparency = T.TabInT}) end end)
    end

    -- ══════════════════════════════════════════════════════════
    -- GAME DETAIL LOGIC
    -- ══════════════════════════════════════════════════════════
    local function openGameDetail(gameData)
        currentDetailGame = gameData
        if gameData.ImageId and gameData.ImageId ~= "" then
            DetailThumbImg.Image = gameData.ImageId
            DetailThumbPlaceholder.Visible = false
            DetailThumbImg.Visible = true
        else
            DetailThumbImg.Image = ""
            DetailThumbImg.Visible = false
            DetailThumbPlaceholder.Text = gameData.Icon or "🎮"
            DetailThumbPlaceholder.Visible = true
        end

        DetailName.Text = gameData.Name or "Unknown"
        DetailTag.Text = " " .. (gameData.Tag or "Supported") .. " "
        DescText.Text = gameData.Description or "No description available."
        DetailExecBtn.Text = "Execute"
        Tw(DetailExecBtn, 0.1, {BackgroundColor3 = T.BtnExec})

        if activeTab ~= "Games" then switchTab("Games") end
        GameListView.Visible = false
        GameDetailView.Visible = true
        DetailPanel.Position = UDim2.new(0.05, 0, 0, 46)
        DetailPanel.BackgroundTransparency = 1
        DescSection.BackgroundTransparency = 1
        Tw(DetailPanel, 0.35, {Position = UDim2.new(0, 0, 0, 46), BackgroundTransparency = T.CardT})
        Tw(DescSection, 0.35, {BackgroundTransparency = T.CardT})
    end

    BackBtn.MouseButton1Click:Connect(function()
        Ripple(BackBtn, Vector2.new(BackBtn.AbsolutePosition.X + 19, BackBtn.AbsolutePosition.Y + 19))
        currentDetailGame = nil
        GameDetailView.Visible = false
        GameListView.Visible = true
    end)

    DetailExecBtn.MouseButton1Click:Connect(function()
        if not currentDetailGame then return end
        Ripple(DetailExecBtn, Vector2.new(DetailExecBtn.AbsolutePosition.X + 75, DetailExecBtn.AbsolutePosition.Y + 20))
        DetailExecBtn.Text = "Executing..."
        Tw(DetailExecBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(30, 160, 40)})
        local ok, err = pcall(function()
            if currentDetailGame.Callback then currentDetailGame.Callback()
            elseif currentDetailGame.URL then loadstring(game:HttpGet(currentDetailGame.URL))() end
        end)
        task.delay(0.5, function()
            if ok then
                DetailExecBtn.Text = "✓ Executed"; Tw(DetailExecBtn, 0.15, {BackgroundColor3 = T.Green})
                NInfo("SYNOX HUB", currentDetailGame.Name .. " executed successfully!")
            else
                DetailExecBtn.Text = "✕ Error"; Tw(DetailExecBtn, 0.15, {BackgroundColor3 = T.BtnDng})
                NError("Error", currentDetailGame.Name .. " failed:\n" .. tostring(err))
            end
            task.delay(2, function() DetailExecBtn.Text = "Execute"; Tw(DetailExecBtn, 0.25, {BackgroundColor3 = T.BtnExec}) end)
        end)
    end)

    -- ══════════════════════════════════════════════════════════
    -- GAME CARD BUILDER
    -- ══════════════════════════════════════════════════════════
    local function makeGameCard(gameData, parent, layoutOrder)
        local isDetected = false
        for _, pid in ipairs(gameData.PlaceIds or {}) do
            if pid == CURRENT_PLACE_ID then isDetected = true; break end
        end

        local card = C("TextButton", {Size = UDim2.new(1, 0, 0, 85), BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT, BorderSizePixel = 0, LayoutOrder = layoutOrder or 0, Text = "", AutoButtonColor = false, Parent = parent})
        Corner(card, T.CRS); Stroke(card, isDetected and T.Accent or T.CardStroke, 1, isDetected and 0.3 or 0.6)

        -- Thumbnail frame with dark background
        local thumb = C("Frame", {Size = UDim2.new(0, 70, 0, 70), Position = UDim2.new(0, 8, 0.5, -35), BackgroundColor3 = T.ThumbBg, BorderSizePixel = 0, ClipsDescendants = true, Parent = card})
        Corner(thumb, T.CRS)
        Stroke(thumb, T.CardStroke, 1, 0.5)

        local hasImage = (gameData.ImageId and gameData.ImageId ~= "")
        local thumbImg = C("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScaleType = Enum.ScaleType.Crop,
            Image = hasImage and gameData.ImageId or "",
            Visible = hasImage,
            Parent = thumb
        })

        local thumbPlaceholder = C("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = gameData.Icon or "🎮",
            TextSize = 28,
            Font = T.FB,
            TextColor3 = T.TextAcc,
            Visible = not hasImage,
            Parent = thumb
        })

        C("TextLabel", {Size = UDim2.new(0.5, -10, 0, 18), Position = UDim2.new(0, 86, 0, 12), BackgroundTransparency = 1, Text = gameData.Name or "Unknown", TextColor3 = T.TextPri, TextSize = 14, Font = T.FH, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})

        -- Tags row
        local tagX = 86
        local gt = C("TextLabel", {Size = UDim2.new(0, 75, 0, 16), Position = UDim2.new(0, tagX, 0, 34), BackgroundColor3 = Color3.fromRGB(0, 120, 150), BackgroundTransparency = 0.7, Text = " " .. (gameData.Tag or "Supported") .. " ", TextColor3 = T.TextAcc, TextSize = 9, Font = T.FB, Parent = card})
        Corner(gt, UDim.new(0, 3))

        if isDetected then
            local dtag = C("TextLabel", {Size = UDim2.new(0, 65, 0, 16), Position = UDim2.new(0, tagX + 80, 0, 34), BackgroundColor3 = T.Green, BackgroundTransparency = 0.7, Text = " ✓ Active ", TextColor3 = T.Green, TextSize = 9, Font = T.FH, Parent = card})
            Corner(dtag, UDim.new(0, 3))
        end

        C("TextLabel", {Size = UDim2.new(0.5, -10, 0, 14), Position = UDim2.new(0, 86, 0, 54), BackgroundTransparency = 1, Text = gameData.ShortDesc or "Click to view details", TextColor3 = T.TextMut, TextSize = 10, Font = T.FB, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
        C("TextLabel", {AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -10, 0.5, 0), BackgroundTransparency = 1, Text = "›", TextColor3 = T.TextMut, TextSize = 22, Font = T.FT, Parent = card})

        card.MouseEnter:Connect(function()
            Tw(card, 0.2, {BackgroundColor3 = T.CardHov, BackgroundTransparency = 0.2})
            local s = card:FindFirstChildOfClass("UIStroke"); if s then Tw(s, 0.2, {Color = T.Accent, Transparency = 0.3}) end
        end)
        card.MouseLeave:Connect(function()
            Tw(card, 0.2, {BackgroundColor3 = T.Card, BackgroundTransparency = T.CardT})
            local s = card:FindFirstChildOfClass("UIStroke"); if s then Tw(s, 0.2, {Color = isDetected and T.Accent or T.CardStroke, Transparency = isDetected and 0.3 or 0.6}) end
        end)
        card.MouseButton1Click:Connect(function()
            Ripple(card, Vector2.new(card.AbsolutePosition.X + card.AbsoluteSize.X / 2, card.AbsolutePosition.Y + card.AbsoluteSize.Y / 2))
            openGameDetail(gameData)
        end)
        return card
    end

    -- ══════════════════════════════════════════════════════════
    -- SEARCH
    -- ══════════════════════════════════════════════════════════
    local function doSearch(q)
        for _, ch in ipairs(SRS:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        if q == "" then NR.Text = "Type to search scripts..."; NR.Visible = true; return end
        local ql = string.lower(q)
        local results = {}
        for _, gd in ipairs(gamesList) do
            if string.find(string.lower(gd.Name or ""), ql) or string.find(string.lower(gd.Description or ""), ql) or string.find(string.lower(gd.Tag or ""), ql) then
                table.insert(results, gd)
            end
        end
        if #results == 0 then NR.Text = 'No scripts found for "' .. q .. '"'; NR.Visible = true
        else NR.Visible = false; for i, gd in ipairs(results) do makeGameCard(gd, SRS, i) end end
    end

    SI:GetPropertyChangedSignal("Text"):Connect(function() doSearch(SI.Text) end)

    -- ══════════════════════════════════════════════════════════
    -- ADD GAME FUNCTION
    -- ══════════════════════════════════════════════════════════
    local function AddGame(gameData)
        table.insert(gamesList, gameData)
        makeGameCard(gameData, GameListScroll, #gamesList)
        GV.Text = tostring(#gamesList)
        SDet.Text = "• " .. tostring(#gamesList) .. " scripts loaded   • PlaceId: " .. tostring(CURRENT_PLACE_ID)
    end

    -- ══════════════════════════════════════════════════════════
    -- LIVE STATS
    -- ══════════════════════════════════════════════════════════
    local fpsBuf, fpsCnt = {}, 0
    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if destroyed then return end
        fpsCnt = fpsCnt + 1; table.insert(fpsBuf, 1 / dt)
        if fpsCnt >= 30 then
            fpsCnt = 0
            local total = 0; for _, f in ipairs(fpsBuf) do total = total + f end
            local avg = math.floor(total / #fpsBuf); fpsBuf = {}
            FV.Text = tostring(avg)
            FV.TextColor3 = avg >= 50 and T.Green or (avg >= 30 and T.Yellow or T.Red)
            local ping = GetPing(); PV.Text = tostring(ping) .. " ms"
            PV.TextColor3 = ping <= 80 and T.Green or (ping <= 150 and T.Yellow or T.Red)
        end
    end))

    -- ══════════════════════════════════════════════════════════
    -- CLOSE & MINIMIZE
    -- ══════════════════════════════════════════════════════════
    XBtn.MouseButton1Click:Connect(function()
        NConfirm("SYNOX HUB", "Are you sure you want to close SYNOX HUB?", function(yes)
            if yes then
                destroyed = true
                for _, c in ipairs(connections) do if c and c.Connected then c:Disconnect() end end
                Tw(OF, 0.35, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
                task.delay(0.4, function() SG:Destroy() end)
            end
        end)
    end)

    MnBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tw(OF, 0.35, {Size = UDim2.new(0, T.WW + 12, 0, T.TBH + 20)})
            MnBtn.Text = "□"
        else
            Tw(OF, 0.35, {Size = UDim2.new(0, T.WW + 12, 0, T.WH + 12)})
            MnBtn.Text = "─"
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- HOTKEY TOGGLE
    -- ══════════════════════════════════════════════════════════
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if listeningForHotkey then return end
        if input.KeyCode == currentHotkey then
            hubVisible = not hubVisible
            OF.Visible = hubVisible
        end
    end))

    -- ══════════════════════════════════════════════════════════
    -- OPEN ANIMATION
    -- ══════════════════════════════════════════════════════════
    OF.Size = UDim2.new(0, 0, 0, 0)
    OF.BackgroundTransparency = 1

    task.delay(0.05, function()
        Tw(OF, 0.5, {Size = UDim2.new(0, T.WW + 12, 0, T.WH + 12), BackgroundTransparency = T.OuterT}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- ══════════════════════════════════════════════════════════
    -- REGISTER GAME SCRIPTS (CONTEXT-AWARE FILTERING)
    -- ══════════════════════════════════════════════════════════
    -- If current game is detected, only register scripts for THIS game:
    if #autoDetectedGames > 0 then
        for _, entry in ipairs(autoDetectedGames) do
            AddGame(entry)
        end
    end
    -- If game is not detected (#autoDetectedGames == 0), other game scripts remain hidden.

    -- Universal Script (Always available)
    AddGame({
        PlaceIds = {},
        Name = "Universal Script",
        Description = "Universal utility script for any Roblox experience.\n\nFeatures:\n• WalkSpeed & JumpPower Modifier\n• Flight Mode & Noclip\n• Fullbright & Visual Enhancements\n• Click Teleport (Ctrl + Click)\n• Player Distance ESP",
        ShortDesc = "Speed, Fly, Noclip, ESP, Fullbright",
        Tag = "Universal",
        Icon = "🌐",
        ImageId = "",
        Callback = function()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 50
                humanoid.JumpPower = 120
                humanoid.UseJumpPower = true
            end
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("AtmosphereEffect") then
                    effect.Enabled = false
                end
            end
            NInfo("SYNOX HUB", "Universal Script loaded!\n• Speed: 50\n• JumpPower: 120\n• Fullbright: Active")
        end
    })

    -- Infinite Yield (Always available)
    AddGame({
        PlaceIds = {},
        Name = "Infinite Yield",
        Description = "Universal FE admin command suite.\n\nFeatures:\n• 200+ Administrative Commands\n• Explorer & Tool Inspector\n• Player Management & Teleportation\n• Server Control & Utility Tools",
        ShortDesc = "FE Admin Suite, 200+ Commands",
        Tag = "Universal",
        Icon = "🔧",
        ImageId = "",
        URL = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
    })

    -- Startup notification
    task.delay(1, function()
        if #autoDetectedGames > 0 then
            local gameName = autoDetectedGames[1].Name
            NInfo("SYNOX HUB", "Welcome back, @" .. LocalPlayer.Name .. "!\nSYNOX HUB v" .. CONFIG.Version .. " loaded.\n\n• " .. tostring(#gamesList) .. " scripts available\n• Active Game: " .. gameName .. "\n• Press " .. (KeyNames[currentHotkey] or "RightControl") .. " to toggle")
        else
            NInfo("SYNOX HUB", "Welcome back, @" .. LocalPlayer.Name .. "!\nSYNOX HUB v" .. CONFIG.Version .. " loaded (Universal Mode).\n\n• " .. tostring(#gamesList) .. " universal scripts available\n• Press " .. (KeyNames[currentHotkey] or "RightControl") .. " to toggle")
        end
    end)

    print("[SYNOX HUB] v" .. CONFIG.Version .. " Loaded • " .. tostring(#gamesList) .. " scripts • PlaceId: " .. tostring(CURRENT_PLACE_ID))
end

-- ══════════════════════════════════════════════════════════════
-- LAUNCH SEQUENCE
-- ══════════════════════════════════════════════════════════

showKeySystem(function()
    -- Key verified — now check auto-detection
    if CONFIG.AutoDetectEnabled and #autoDetectedGames > 0 then
        showSelectionDialog(autoDetectedGames, function(selectedGame)
            buildHub()
            task.delay(0.5, function()
                executeGameScript(selectedGame)
            end)
        end, function()
            buildHub()
        end)
    else
        buildHub()
    end
end)
