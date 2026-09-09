-- ╔══════════════════════════════════════════════════════════════╗
-- ║         Cake Island PRO v5.0 — UI & Logic Script             ║
-- ║         Clean Typography, Dropdown List, Player Stats        ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")
local CoreGui             = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

local startTime = tick()

local cfg = {
    speed        = 60,
    jumpPower    = 50,
    farmHeight   = 180,
    attackDelay  = 0.55,
    healThresh   = 0.55,
    healKey      = Enum.KeyCode.One,
    fruitKey     = Enum.KeyCode.Z,
    selectedMob  = "Baker",
    lootEnabled  = true,
    uiScale      = 1.0,
    minimized    = false,
}

local cakeMobs = {"Baker", "Baking Staff", "Cake Guard", "Head Baker", "Cake Queen", "Chef Apprentice", "Pastry Guard"}

local state = {
    flying    = false,
    autoFarm  = false,
    speedBoost= false,
    jumpBoost = false,
    attackCD  = false,
    killCount = 0,
    lv        = nil, 
    ao        = nil, 
    att       = nil,
}

-- Professional Color Palette (Clean Dark Mode Theme)
local C = {
    bg0   = Color3.fromRGB(15,  15,  18),
    bg1   = Color3.fromRGB(22,  22,  26),
    bg2   = Color3.fromRGB(30,  30,  36),
    bg3   = Color3.fromRGB(40,  40,  48),
    s1    = Color3.fromRGB(50,  50,  60),
    s2    = Color3.fromRGB(70,  70,  85),
    t1    = Color3.fromRGB(245, 245, 247),
    t2    = Color3.fromRGB(170, 170, 180),
    t3    = Color3.fromRGB(110, 110, 120),
    grn   = Color3.fromRGB(46,  204, 113),
    red   = Color3.fromRGB(231, 76,  60),
    amb   = Color3.fromRGB(241, 196, 15),
    white = Color3.fromRGB(255, 255, 255),
}

local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 6) c.Parent = p return c end
local function stroke(p, col, th) local s = Instance.new("UIStroke") s.Color = col or C.s1 s.Thickness = th or 1 s.Parent = p return s end
local function pad(p, t, b, l, r) local u = Instance.new("UIPadding") u.PaddingTop = UDim.new(0, t) u.PaddingBottom = UDim.new(0, b or t) u.PaddingLeft = UDim.new(0, l or t) u.PaddingRight = UDim.new(0, r or t) u.Parent = p return u end

-- ScreenGui placed in CoreGui so it completely avoids Roblox's core menus and topbar scaling quirks
local gui = Instance.new("ScreenGui")
gui.Name = "CakeIslandSidebarPRO"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = cfg.uiScale
uiScale.Parent = gui

-- Draggable Minimized Floating Pill (Fully movable, clean typography)
local pill = Instance.new("Frame")
pill.Size = UDim2.new(0, 130, 0, 36)
pill.Position = UDim2.new(0, 20, 0, 20)
pill.BackgroundColor3 = C.bg1
pill.BorderSizePixel = 0
pill.Visible = false
pill.Active = true
pill.Draggable = true
pill.ZIndex = 50
pill.Parent = gui
corner(pill, 8)
stroke(pill, C.s2, 1)

local pillDot = Instance.new("Frame")
pillDot.Size = UDim2.new(0, 8, 0, 8)
pillDot.Position = UDim2.new(0, 12, 0.5, -4)
pillDot.BackgroundColor3 = C.t3
pillDot.BorderSizePixel = 0
pillDot.Parent = pill
corner(pillDot, 4)

local pillTxt = Instance.new("TextButton")
pillTxt.Size = UDim2.new(1, -28, 1, 0)
pillTxt.Position = UDim2.new(0, 26, 0, 0)
pillTxt.BackgroundTransparency = 1
pillTxt.TextColor3 = C.t1
pillTxt.Text = "Cake Panel"
pillTxt.Font = Enum.Font.GothamMedium
pillTxt.TextSize = 13
pillTxt.TextXAlignment = Enum.TextXAlignment.Left
pillTxt.Parent = pill

-- Main Window Container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 560, 0, 380)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
mainFrame.BackgroundColor3 = C.bg0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui
corner(mainFrame, 10)
stroke(mainFrame, C.s2, 1)

-- Sidebar Panel
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, 0)
sidebar.BackgroundColor3 = C.bg1
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
corner(sidebar, 10)

local sidebarFix = Instance.new("Frame")
sidebarFix.Size = UDim2.new(0, 10, 1, 0)
sidebarFix.Position = UDim2.new(1, -10, 0, 0)
sidebarFix.BackgroundColor3 = C.bg1
sidebarFix.BorderSizePixel = 0
sidebarFix.Parent = sidebar

local sideHeader = Instance.new("Frame")
sideHeader.Size = UDim2.new(1, 0, 0, 55)
sideHeader.BackgroundTransparency = 1
sideHeader.Parent = sidebar

local brandLbl = Instance.new("TextLabel")
brandLbl.Size = UDim2.new(1, -20, 0, 20)
brandLbl.Position = UDim2.new(0, 14, 0, 14)
brandLbl.BackgroundTransparency = 1
brandLbl.TextColor3 = C.t1
brandLbl.Text = "CAKE ISLAND"
brandLbl.Font = Enum.Font.GothamBold
brandLbl.TextSize = 13
brandLbl.TextXAlignment = Enum.TextXAlignment.Left
brandLbl.Parent = sideHeader

local subBrandLbl = Instance.new("TextLabel")
subBrandLbl.Size = UDim2.new(1, -20, 0, 14)
subBrandLbl.Position = UDim2.new(0, 14, 0, 32)
subBrandLbl.BackgroundTransparency = 1
subBrandLbl.TextColor3 = C.t3
subBrandLbl.Text = "PRO v5.0"
subBrandLbl.Font = Enum.Font.Gotham
subBrandLbl.TextSize = 11
subBrandLbl.TextXAlignment = Enum.TextXAlignment.Left
subBrandLbl.Parent = sideHeader

local navList = Instance.new("ScrollingFrame")
navList.Size = UDim2.new(1, 0, 1, -65)
navList.Position = UDim2.new(0, 0, 0, 65)
navList.BackgroundTransparency = 1
navList.BorderSizePixel = 0
navList.CanvasSize = UDim2.new(0, 0, 0, 0)
navList.AutomaticCanvasSize = Enum.AutomaticSize.Y
navList.ScrollBarThickness = 0
navList.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 4)
navLayout.Parent = navList
pad(navList, 0, 0, 8, 8)

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -160, 1, 0)
contentArea.Position = UDim2.new(0, 160, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundTransparency = 1
topBar.Parent = contentArea

local currentTabLbl = Instance.new("TextLabel")
currentTabLbl.Size = UDim2.new(1, -80, 1, 0)
currentTabLbl.Position = UDim2.new(0, 16, 0, 0)
currentTabLbl.BackgroundTransparency = 1
currentTabLbl.TextColor3 = C.t1
currentTabLbl.Text = "Automation"
currentTabLbl.Font = Enum.Font.GothamBold
currentTabLbl.TextSize = 14
currentTabLbl.TextXAlignment = Enum.TextXAlignment.Left
currentTabLbl.Parent = topBar

local winControls = Instance.new("Frame")
winControls.Size = UDim2.new(0, 60, 0, 28)
winControls.Position = UDim2.new(1, -70, 0, 12)
winControls.BackgroundTransparency = 1
winControls.Parent = topBar

local wCtrlLayout = Instance.new("UIListLayout")
wCtrlLayout.FillDirection = Enum.FillDirection.Horizontal
wCtrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
wCtrlLayout.Padding = UDim.new(0, 6)
wCtrlLayout.Parent = winControls

local function winBtn(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 26)
    b.BackgroundColor3 = C.bg1
    b.TextColor3 = C.t2
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.Parent = winControls
    corner(b, 6)
    stroke(b, C.s1, 1)
    return b
end

local minimizeHeaderBtn = winBtn("-")
local closeHeaderBtn = winBtn("X")

closeHeaderBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

minimizeHeaderBtn.MouseButton1Click:Connect(function()
    cfg.minimized = true
    mainFrame.Visible = false
    pill.Visible = true
    pillDot.BackgroundColor3 = state.autoFarm and C.grn or C.t3
end)

pillTxt.MouseButton1Click:Connect(function()
    cfg.minimized = false
    pill.Visible = false
    mainFrame.Visible = true
end)

local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, 0, 1, -50)
pagesContainer.Position = UDim2.new(0, 0, 0, 50)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = contentArea

local tabs = {}

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = C.s1
    p.Visible = false
    p.Parent = pagesContainer

    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 10)
    l.Parent = p
    pad(p, 10, 15, 20, 20)
    return p
end

local function addTab(name)
    local page = createPage()
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.Position = UDim2.new(0, 6, 0, 0)
    btn.BackgroundColor3 = C.bg1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = navList
    corner(btn, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.t2
    lbl.Text = name
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.page.Visible = false
            TweenService:Create(t.btn, tw, {BackgroundColor3 = C.bg1}):Play()
            t.lbl.TextColor3 = C.t2
        end
        page.Visible = true
        TweenService:Create(btn, tw, {BackgroundColor3 = C.bg3}):Play()
        lbl.TextColor3 = C.t1
        currentTabLbl.Text = name
    end)

    table.insert(tabs, {name = name, btn = btn, page = page, lbl = lbl})
    if #tabs == 1 then
        page.Visible = true
        btn.BackgroundColor3 = C.bg3
        lbl.TextColor3 = C.t1
        currentTabLbl.Text = name
    end

    return page
end

-- UI Component builders with clear, readable typography
local function makeSwitch(parent, text, initial, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 42)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
    wrap.Parent = parent
    corner(wrap, 8)
    stroke(wrap, C.s1, 1)
    pad(wrap, 0, 0, 14, 14)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.t1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap

    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0, 36, 0, 20)
    pillBg.Position = UDim2.new(1, -36, 0.5, -10)
    pillBg.BackgroundColor3 = initial and C.grn or C.s1
    pillBg.BorderSizePixel = 0
    pillBg.Parent = wrap
    corner(pillBg, 10)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = initial and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = C.white
    circle.BorderSizePixel = 0
    circle.Parent = pillBg
    corner(circle, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = wrap

    local active = initial
    btn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            TweenService:Create(pillBg, tw, {BackgroundColor3 = C.grn}):Play()
            TweenService:Create(circle, tw, {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TweenService:Create(pillBg, tw, {BackgroundColor3 = C.s1}):Play()
            TweenService:Create(circle, tw, {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
        if callback then callback(active) end
    end)

    return {
        Set = function(val)
            active = val
            pillBg.BackgroundColor3 = active and C.grn or C.s1
            circle.Position = active and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        end,
        Get = function() return active end
    }
end

local function makeBoxInput(parent, label, default, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 52)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
    wrap.Parent = parent
    corner(wrap, 8)
    stroke(wrap, C.s1, 1)
    pad(wrap, 8, 8, 14, 14)

    local lbf = Instance.new("TextLabel")
    lbf.Size = UDim2.new(1, 0, 0, 14)
    lbf.BackgroundTransparency = 1
    lbf.TextColor3 = C.t3
    lbf.Text = label
    lbf.Font = Enum.Font.GothamMedium
    lbf.TextSize = 11
    lbf.TextXAlignment = Enum.TextXAlignment.Left
    lbf.Parent = wrap

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 20)
    box.Position = UDim2.new(0, 0, 0, 18)
    box.BackgroundTransparency = 1
    box.TextColor3 = C.t1
    box.Text = tostring(default)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = wrap

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
    return box
end

-- Scrollable Dropdown List component (no repetitive clicking needed, picks directly from list)
local function makeScrollDropdown(parent, label, list, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 56)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
    wrap.ClipsDescendants = false
    wrap.ZIndex = 5
    wrap.Parent = parent
    corner(wrap, 8)
    stroke(wrap, C.s1, 1)
    pad(wrap, 8, 8, 14, 14)

    local lbf = Instance.new("TextLabel")
    lbf.Size = UDim2.new(1, 0, 0, 14)
    lbf.BackgroundTransparency = 1
    lbf.TextColor3 = C.t3
    lbf.Text = label
    lbf.Font = Enum.Font.GothamMedium
    lbf.TextSize = 11
    lbf.TextXAlignment = Enum.TextXAlignment.Left
    lbf.Parent = wrap

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, -30, 0, 22)
    valLbl.Position = UDim2.new(0, 0, 0, 18)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = C.t1
    valLbl.Text = cfg.selectedMob
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.Parent = wrap

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 22)
    arrow.Position = UDim2.new(1, -20, 0, 18)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = C.t2
    arrow.Text = "v"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 12
    arrow.Parent = wrap

    local dropdownOpen = false
    
    local dropListFrame = Instance.new("ScrollingFrame")
    dropListFrame.Size = UDim2.new(1, 0, 0, 110)
    dropListFrame.Position = UDim2.new(0, 0, 1, 6)
    dropListFrame.BackgroundColor3 = C.bg2
    dropListFrame.BorderSizePixel = 0
    dropListFrame.CanvasSize = UDim2.new(0, 0, 0, #list * 28)
    dropListFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
    dropListFrame.ScrollBarThickness = 3
    dropListFrame.Visible = false
    dropListFrame.ZIndex = 10
    dropListFrame.Parent = wrap
    corner(dropListFrame, 8)
    stroke(dropListFrame, C.s2, 1)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropListFrame

    for _, itemName in ipairs(list) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, 0, 0, 28)
        itemBtn.BackgroundTransparency = 1
        itemBtn.TextColor3 = C.t2
        itemBtn.Text = "  " .. itemName
        itemBtn.Font = Enum.Font.GothamMedium
        itemBtn.TextSize = 12
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.ZIndex = 11
        itemBtn.Parent = dropListFrame

        itemBtn.MouseButton1Click:Connect(function()
            valLbl.Text = itemName
            dropdownOpen = false
            dropListFrame.Visible = false
            arrow.Text = "v"
            if callback then callback(itemName) end
        end)
    end

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(1, 0, 1, 0)
    mainBtn.BackgroundTransparency = 1
    mainBtn.Text = ""
    mainBtn.ZIndex = 6
    mainBtn.Parent = wrap

    mainBtn.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        dropListFrame.Visible = dropdownOpen
        arrow.Text = dropdownOpen and "^" or "v"
    end)

    return wrap
end

-- ══ CREATE TABS ════════════════════════════════

-- Tab 1: Automation & Farming
local farmPage = addTab("Automation")

local farmSwitch = makeSwitch(farmPage, "Auto Farm Mobs", false, function(on)
    state.autoFarm = on
    if on then
        state.killCount = 0
        startTime = tick()
    end
end, 1)

makeScrollDropdown(farmPage, "Target Mob Selection", cakeMobs, function(mob)
    cfg.selectedMob = mob
end, 2)

makeBoxInput(farmPage, "Farm Altitude Offset", cfg.farmHeight, function(val)
    local n = tonumber(val)
    if n then cfg.farmHeight = math.clamp(n, 30, 800) end
end, 3)

makeSwitch(farmPage, "Auto Loot Nearby Drops", cfg.lootEnabled, function(on)
    cfg.lootEnabled = on
end, 4)

-- Tab 2: Universal Player Utilities (Speed, Jump, Fly)
local utilsPage = addTab("Utilities")

local speedSwitch = makeSwitch(utilsPage, "Custom WalkSpeed Boost", false, function(on)
    state.speedBoost = on
end, 1)

makeBoxInput(utilsPage, "WalkSpeed Value", cfg.speed, function(val)
    local n = tonumber(val)
    if n then cfg.speed = math.clamp(n, 16, 300) end
end, 2)

local jumpSwitch = makeSwitch(utilsPage, "Custom JumpPower Boost", false, function(on)
    state.jumpBoost = on
end, 3)

makeBoxInput(utilsPage, "JumpPower Value", cfg.jumpPower, function(val)
    local n = tonumber(val)
    if n then cfg.jumpPower = math.clamp(n, 50, 300) end
end, 4)

-- Tab 3: Player Information Hub (Session uptime, exact execution time, avatar info)
local playerPage = addTab("Player Info")

local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 160)
infoCard.BackgroundColor3 = C.bg1
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 1
infoCard.Parent = playerPage
corner(infoCard, 8)
stroke(infoCard, C.s1, 1)
pad(infoCard, 14, 14, 16, 16)

local avatarIcon = Instance.new("ImageLabel")
avatarIcon.Size = UDim2.new(0, 56, 0, 56)
avatarIcon.BackgroundTransparency = 1
avatarIcon.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
avatarIcon.Parent = infoCard
corner(avatarIcon, 28)
stroke(avatarIcon, C.s2, 1)

local playerNameLbl = Instance.new("TextLabel")
playerNameLbl.Size = UDim2.new(1, -70, 0, 20)
playerNameLbl.Position = UDim2.new(0, 68, 0, 4)
playerNameLbl.BackgroundTransparency = 1
playerNameLbl.TextColor3 = C.t1
playerNameLbl.Text = player.Name .. " (@" .. player.DisplayName .. ")"
playerNameLbl.Font = Enum.Font.GothamBold
playerNameLbl.TextSize = 13
playerNameLbl.TextXAlignment = Enum.TextXAlignment.Left
playerNameLbl.Parent = infoCard

local userIdLbl = Instance.new("TextLabel")
userIdLbl.Size = UDim2.new(1, -70, 0, 16)
userIdLbl.Position = UDim2.new(0, 68, 0, 26)
userIdLbl.BackgroundTransparency = 1
userIdLbl.TextColor3 = C.t3
userIdLbl.Text = "User ID: " .. tostring(player.UserId)
userIdLbl.Font = Enum.Font.Gotham
userIdLbl.TextSize = 11
userIdLbl.TextXAlignment = Enum.TextXAlignment.Left
userIdLbl.Parent = infoCard

local sessionTimeLbl = Instance.new("TextLabel")
sessionTimeLbl.Size = UDim2.new(1, 0, 0, 20)
sessionTimeLbl.Position = UDim2.new(0, 0, 0, 75)
sessionTimeLbl.BackgroundTransparency = 1
sessionTimeLbl.TextColor3 = C.t2
sessionTimeLbl.Text = "Script Active Time: 00:00:00"
sessionTimeLbl.Font = Enum.Font.GothamMedium
sessionTimeLbl.TextSize = 12
sessionTimeLbl.TextXAlignment = Enum.TextXAlignment.Left
sessionTimeLbl.Parent = infoCard

local killsInfoLbl = Instance.new("TextLabel")
killsInfoLbl.Size = UDim2.new(1, 0, 0, 20)
killsInfoLbl.Position = UDim2.new(0, 0, 0, 100)
killsInfoLbl.BackgroundTransparency = 1
killsInfoLbl.TextColor3 = C.t2
killsInfoLbl.Text = "Total Session Kills: 0"
killsInfoLbl.Font = Enum.Font.GothamMedium
killsInfoLbl.TextSize = 12
killsInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
killsInfoLbl.Parent = infoCard

-- Tab 4: Settings & UI Scaling
local settingsPage = addTab("Settings")

makeBoxInput(settingsPage, "Interface Scale Factor", cfg.uiScale, function(val)
    local n = tonumber(val)
    if n then
        cfg.uiScale = math.clamp(n, 0.6, 1.8)
        TweenService:Create(uiScale, tw, {Scale = cfg.uiScale}):Play()
    end
end, 1)

-- ══ CORE LOGIC LOOPS ═══════════════════════════

RunService.Heartbeat:Connect(function()
    -- Update Player Info Tab Stats live
    local elapsed = math.floor(tick() - startTime)
    local hours = math.floor(elapsed / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = elapsed % 60
    sessionTimeLbl.Text = string.format("Script Active Time: %02d:%02d:%02d", hours, mins, secs)
    killsInfoLbl.Text = "Total Session Kills: " .. tostring(state.killCount)

    -- Universal Utilities Loops
    if state.speedBoost and humanoid then
        humanoid.WalkSpeed = cfg.speed
    end
    if state.jumpBoost and humanoid then
        humanoid.JumpPower = cfg.jumpPower
    end

    if not state.autoFarm then return end
    if not character or not rootPart or humanoid.Health <= 0 then return end

    local ray = workspace:Raycast(rootPart.Position, Vector3.new(0, -800, 0), RaycastParams.new())
    local groundY = ray and ray.Position.Y or 0
    local targetY = groundY + cfg.farmHeight
    local pos = rootPart.Position

    if math.abs(pos.Y - targetY) > 3 then
        rootPart.CFrame = CFrame.new(pos.X, targetY, pos.Z)
    end
    rootPart.AssemblyLinearVelocity = Vector3.zero
end)

player.CharacterAdded:Connect(function(c)
    character = c
    humanoid  = c:WaitForChild("Humanoid")
    rootPart  = c:WaitForChild("HumanoidRootPart")
    state.autoFarm = false
    farmSwitch.Set(false)
end)

print("[Cake Island PRO]: UI successfully compiled and loaded.")
