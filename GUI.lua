-- ╔══════════════════════════════════════════════════════════════╗
-- ║         Cake Island PRO v6.0 — Ultimate Refactor             ║
-- ║         UI & Logic Code (Залей этот код в свой GUI.luau)     ║
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
    flying     = false,
    autoFarm   = false,
    speedBoost = false,
    jumpBoost  = false,
    attackCD   = false,
    killCount  = 0,
}

-- Ультра-премиальная темная палитра без обводок
local C = {
    bg0   = Color3.fromRGB(12,  14,  18),
    bg1   = Color3.fromRGB(20,  23,  29),
    bg2   = Color3.fromRGB(29,  33,  41),
    bg3   = Color3.fromRGB(43,  48,  58),
    t1    = Color3.fromRGB(255, 255, 255),
    t2    = Color3.fromRGB(180, 180, 195),
    t3    = Color3.fromRGB(115, 115, 130),
    accent = Color3.fromRGB(255, 184, 92),
    accentSoft = Color3.fromRGB(109, 78, 44),
    grn   = Color3.fromRGB(56,  210, 125),
    red   = Color3.fromRGB(231, 76,  60),
    white = Color3.fromRGB(255, 255, 255),
}

local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(p, r) 
    local c = Instance.new("UICorner") 
    c.CornerRadius = UDim.new(0, r or 8) 
    c.Parent = p 
    return c 
end

-- Roblox не имеет встроенного UIShadow, поэтому используем отдельный слой позади элемента.
local function addShadow(p, transparency)
    local shadow = Instance.new("Frame")
    shadow.Name = "UIShadow"
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, -4, 0, 5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = transparency or 0.85
    shadow.BorderSizePixel = 0
    shadow.ZIndex = math.max(p.ZIndex - 1, 0)
    shadow.Parent = p
    corner(shadow, 12)
    return shadow
end

local function pad(p, t, b, l, r) 
    local u = Instance.new("UIPadding") 
    u.PaddingTop = UDim.new(0, t) 
    u.PaddingBottom = UDim.new(0, b or t) 
    u.PaddingLeft = UDim.new(0, l or t) 
    u.PaddingRight = UDim.new(0, r or t) 
    u.Parent = p 
    return u 
end

local gui = Instance.new("ScreenGui")
gui.Name = "CakeIslandSidebarPRO"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = cfg.uiScale
uiScale.Parent = gui

-- ══ СВОРАЧИВАЕМАЯ КНОПКА (PILL) С ПЛАВНЫМ ПЕРЕПАСОМ ═══════
local pill = Instance.new("Frame")
pill.Size = UDim2.new(0, 140, 0, 40)
pill.Position = UDim2.new(0, 30, 0, 30)
pill.BackgroundColor3 = C.bg1
pill.BorderSizePixel = 0
pill.Visible = false
pill.Active = true
pill.ZIndex = 100
pill.Parent = gui
corner(pill, 20)
addShadow(pill, 0.7)

local pillDot = Instance.new("Frame")
pillDot.Size = UDim2.new(0, 10, 0, 10)
pillDot.Position = UDim2.new(0, 14, 0.5, -5)
pillDot.BackgroundColor3 = C.t3
pillDot.BorderSizePixel = 0
pillDot.Parent = pill
corner(pillDot, 5)

local pillTxt = Instance.new("TextButton")
pillTxt.Size = UDim2.new(1, -30, 1, 0)
pillTxt.Position = UDim2.new(0, 30, 0, 0)
pillTxt.BackgroundTransparency = 1
pillTxt.TextColor3 = C.t1
pillTxt.Text = "CAKE HUB"
pillTxt.Font = Enum.Font.GothamBold
pillTxt.TextSize = 13
pillTxt.TextXAlignment = Enum.TextXAlignment.Left
pillTxt.Parent = pill

-- Плавное кастомное перетаскивание без багов с улетом мышки
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(pill)

-- ══ ОСНОВНОЕ ОКНО ═════════════════════════════════════════
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.9, 0, 0.78, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = C.bg0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = gui
corner(mainFrame, 12)
addShadow(mainFrame, 0.6)
makeDraggable(mainFrame)

local windowLimit = Instance.new("UISizeConstraint")
windowLimit.MinSize = Vector2.new(320, 360)
windowLimit.MaxSize = Vector2.new(760, 540)
windowLimit.Parent = mainFrame

-- Сайдбар
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 168, 1, 0)
sidebar.BackgroundColor3 = C.bg1
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
corner(sidebar, 12)

-- Убираем лишний угол у сайдбара
local sidebarFix = Instance.new("Frame")
sidebarFix.Size = UDim2.new(0, 12, 1, 0)
sidebarFix.Position = UDim2.new(1, -12, 0, 0)
sidebarFix.BackgroundColor3 = C.bg1
sidebarFix.BorderSizePixel = 0
sidebarFix.Parent = sidebar

local sideHeader = Instance.new("Frame")
sideHeader.Size = UDim2.new(1, 0, 0, 65)
sideHeader.BackgroundTransparency = 1
sideHeader.Parent = sidebar

local brandLbl = Instance.new("TextLabel")
brandLbl.Size = UDim2.new(1, -24, 0, 22)
brandLbl.Position = UDim2.new(0, 16, 0, 16)
brandLbl.BackgroundTransparency = 1
brandLbl.TextColor3 = C.t1
brandLbl.Text = "CLOWN HUB"
brandLbl.Font = Enum.Font.GothamBold
brandLbl.TextSize = 15
brandLbl.TextXAlignment = Enum.TextXAlignment.Left
brandLbl.Parent = sideHeader

local subBrandLbl = Instance.new("TextLabel")
subBrandLbl.Size = UDim2.new(1, -24, 0, 16)
subBrandLbl.Position = UDim2.new(0, 16, 0, 38)
subBrandLbl.BackgroundTransparency = 1
subBrandLbl.TextColor3 = C.t3
subBrandLbl.Text = "CAKE ISLAND PRO"
subBrandLbl.Font = Enum.Font.GothamBold
subBrandLbl.TextSize = 10
subBrandLbl.TextXAlignment = Enum.TextXAlignment.Left
subBrandLbl.Parent = sideHeader

local navList = Instance.new("ScrollingFrame")
navList.Size = UDim2.new(1, 0, 1, -75)
navList.Position = UDim2.new(0, 0, 0, 75)
navList.BackgroundTransparency = 1
navList.BorderSizePixel = 0
navList.CanvasSize = UDim2.new(0, 0, 0, 0)
navList.AutomaticCanvasSize = Enum.AutomaticSize.Y
navList.ScrollBarThickness = 0
navList.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 6)
navLayout.Parent = navList
pad(navList, 0, 0, 10, 10)

-- Контентная область
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -168, 1, 0)
contentArea.Position = UDim2.new(0, 168, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 68)
topBar.BackgroundTransparency = 1
topBar.Parent = contentArea

local currentTabLbl = Instance.new("TextLabel")
currentTabLbl.Size = UDim2.new(1, -90, 1, 0)
currentTabLbl.Position = UDim2.new(0, 20, 0, 0)
currentTabLbl.BackgroundTransparency = 1
currentTabLbl.TextColor3 = C.t1
currentTabLbl.Text = "Automation"
currentTabLbl.Font = Enum.Font.GothamBold
currentTabLbl.TextSize = 16
currentTabLbl.TextYAlignment = Enum.TextYAlignment.Bottom
currentTabLbl.TextXAlignment = Enum.TextXAlignment.Left
currentTabLbl.Parent = topBar

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -40, 0, 16)
statusLbl.Position = UDim2.new(0, 20, 0, 43)
statusLbl.BackgroundTransparency = 1
statusLbl.TextColor3 = C.t3
statusLbl.Text = "READY  •  CAKE ISLAND"
statusLbl.Font = Enum.Font.GothamMedium
statusLbl.TextSize = 10
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = topBar

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(0, 34, 0, 3)
accentLine.Position = UDim2.new(0, 20, 0, 8)
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel = 0
accentLine.Parent = topBar
corner(accentLine, 2)

-- Кнопки сворачивания и закрытия (внутри нашего GUI, стандартные Роблокса не задействованы)
local winControls = Instance.new("Frame")
winControls.Size = UDim2.new(0, 70, 0, 32)
winControls.Position = UDim2.new(1, -85, 0, 14)
winControls.BackgroundTransparency = 1
winControls.Parent = topBar

local wCtrlLayout = Instance.new("UIListLayout")
wCtrlLayout.FillDirection = Enum.FillDirection.Horizontal
wCtrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
wCtrlLayout.Padding = UDim.new(0, 8)
wCtrlLayout.Parent = winControls

local function winBtn(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30)
    b.BackgroundColor3 = C.bg1
    b.TextColor3 = C.t2
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = winControls
    corner(b, 8)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, tw, {BackgroundColor3 = C.bg3, TextColor3 = C.t1}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, tw, {BackgroundColor3 = C.bg1, TextColor3 = C.t2}):Play()
    end)
    return b
end

local minimizeHeaderBtn = winBtn("-")
local closeHeaderBtn = winBtn("×")

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
pagesContainer.Size = UDim2.new(1, 0, 1, -68)
pagesContainer.Position = UDim2.new(0, 0, 0, 68)
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
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = C.bg3
    p.Visible = false
    p.Parent = pagesContainer

    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 12)
    l.Parent = p
    pad(p, 10, 20, 24, 24)
    return p
end

local function addTab(name)
    local page = createPage()
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 40)
    btn.Position = UDim2.new(0, 8, 0, 0)
    btn.BackgroundColor3 = C.bg1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = navList
    corner(btn, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.t2
    lbl.Text = name
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    btn.MouseEnter:Connect(function()
        if page.Visible then return end
        TweenService:Create(btn, tw, {BackgroundColor3 = C.bg2}):Play()
        TweenService:Create(lbl, tw, {TextColor3 = C.t1}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if page.Visible then return end
        TweenService:Create(btn, tw, {BackgroundColor3 = C.bg1}):Play()
        TweenService:Create(lbl, tw, {TextColor3 = C.t2}):Play()
    end)

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

-- ══ КОМПОНЕНТЫ ИНТЕРФЕЙСА (Крупный жирный шрифт, без обводок) ══════

local function makeSwitch(parent, text, initial, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 50)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
    wrap.Parent = parent
    corner(wrap, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.t1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap

    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0, 44, 0, 24)
    pillBg.Position = UDim2.new(1, -56, 0.5, -12)
    pillBg.BackgroundColor3 = initial and C.grn or C.bg3
    pillBg.BorderSizePixel = 0
    pillBg.Parent = wrap
    corner(pillBg, 12)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = initial and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    circle.BackgroundColor3 = C.white
    circle.BorderSizePixel = 0
    circle.Parent = pillBg
    corner(circle, 9)

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
            TweenService:Create(circle, tw, {Position = UDim2.new(1, -21, 0.5, -9)}):Play()
        else
            TweenService:Create(pillBg, tw, {BackgroundColor3 = C.bg3}):Play()
            TweenService:Create(circle, tw, {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
        end
        if callback then callback(active) end
    end)

    return {
        Set = function(val)
            active = val
            pillBg.BackgroundColor3 = active and C.grn or C.bg3
            circle.Position = active and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        end,
        Get = function() return active end
    }
end

local function makeBoxInput(parent, label, default, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 60)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
    wrap.Parent = parent
    corner(wrap, 10)
    pad(wrap, 10, 10, 16, 16)

    local lbf = Instance.new("TextLabel")
    lbf.Size = UDim2.new(1, 0, 0, 16)
    lbf.BackgroundTransparency = 1
    lbf.TextColor3 = C.t3
    lbf.Text = label
    lbf.Font = Enum.Font.GothamBold
    lbf.TextSize = 11
    lbf.TextXAlignment = Enum.TextXAlignment.Left
    lbf.Parent = wrap

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 24)
    box.Position = UDim2.new(0, 0, 0, 20)
    box.BackgroundColor3 = C.bg2
    box.BackgroundTransparency = 0
    box.BorderSizePixel = 0
    box.TextColor3 = C.t1
    box.Text = tostring(default)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 14
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = wrap
    corner(box, 6)
    pad(box, 0, 0, 8, 8)

    box.Focused:Connect(function()
        TweenService:Create(box, tw, {BackgroundColor3 = C.accentSoft}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, tw, {BackgroundColor3 = C.bg2}):Play()
    end)

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
    return box
end

-- Встроенный удобный выпадающий список прямо в интерфейсе (без кликов по 10 раз)
local function makeScrollDropdown(parent, label, list, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 64)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
    wrap.ClipsDescendants = false
    wrap.ZIndex = 10
    wrap.Parent = parent
    corner(wrap, 10)
    pad(wrap, 10, 10, 16, 16)

    local lbf = Instance.new("TextLabel")
    lbf.Size = UDim2.new(1, 0, 0, 16)
    lbf.BackgroundTransparency = 1
    lbf.TextColor3 = C.t3
    lbf.Text = label
    lbf.Font = Enum.Font.GothamBold
    lbf.TextSize = 11
    lbf.TextXAlignment = Enum.TextXAlignment.Left
    lbf.Parent = wrap

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, -30, 0, 24)
    valLbl.Position = UDim2.new(0, 0, 0, 20)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = C.t1
    valLbl.Text = cfg.selectedMob
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 14
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.Parent = wrap

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 24)
    arrow.Position = UDim2.new(1, -20, 0, 20)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = C.t2
    arrow.Text = "v"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.Parent = wrap

    local dropdownOpen = false
    
    local dropListFrame = Instance.new("ScrollingFrame")
    dropListFrame.Size = UDim2.new(1, 0, 0, 130)
    dropListFrame.Position = UDim2.new(0, 0, 1, 8)
    dropListFrame.BackgroundColor3 = C.bg2
    dropListFrame.BorderSizePixel = 0
    dropListFrame.CanvasSize = UDim2.new(0, 0, 0, #list * 32)
    dropListFrame.ScrollBarThickness = 3
    dropListFrame.Visible = false
    dropListFrame.ZIndex = 20
    dropListFrame.Parent = wrap
    corner(dropListFrame, 8)
    addShadow(dropListFrame, 0.5)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropListFrame

    for _, itemName in ipairs(list) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, 0, 0, 32)
        itemBtn.BackgroundColor3 = C.bg2
        itemBtn.BackgroundTransparency = 0
        itemBtn.TextColor3 = C.t2
        itemBtn.Text = "  " .. itemName
        itemBtn.Font = Enum.Font.GothamBold
        itemBtn.TextSize = 13
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.ZIndex = 21
        itemBtn.Parent = dropListFrame

        itemBtn.MouseEnter:Connect(function()
            TweenService:Create(itemBtn, tw, {BackgroundColor3 = C.bg3, TextColor3 = C.t1}):Play()
        end)
        itemBtn.MouseLeave:Connect(function()
            TweenService:Create(itemBtn, tw, {BackgroundColor3 = C.bg2, TextColor3 = C.t2}):Play()
        end)

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
    mainBtn.ZIndex = 11
    mainBtn.Parent = wrap

    mainBtn.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        dropListFrame.Visible = dropdownOpen
        arrow.Text = dropdownOpen and "^" or "v"
    end)

    return wrap
end

-- ══ ВКЛАДКИ И ФУНКЦИОНАЛ ══════════════════════════════════

-- 1. Automation
local farmPage = addTab("Automation")

local farmSwitch = makeSwitch(farmPage, "Auto Farm Mobs", false, function(on)
    state.autoFarm = on
    statusLbl.Text = on and "ACTIVE  •  AUTO FARM" or "READY  •  CAKE ISLAND"
    statusLbl.TextColor3 = on and C.grn or C.t3
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

-- 2. Utilities (Универсальные функции бега и прыжков)
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

-- 3. Player Info (Информация об игроке, аватарка, точное время запуска)
local playerPage = addTab("Player Info")

local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 180)
infoCard.BackgroundColor3 = C.bg1
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 1
infoCard.Parent = playerPage
corner(infoCard, 10)
pad(infoCard, 16, 16, 18, 18)

local avatarIcon = Instance.new("ImageLabel")
avatarIcon.Size = UDim2.new(0, 60, 0, 60)
avatarIcon.BackgroundTransparency = 1
avatarIcon.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
avatarIcon.Parent = infoCard
corner(avatarIcon, 30)

local playerNameLbl = Instance.new("TextLabel")
playerNameLbl.Size = UDim2.new(1, -75, 0, 22)
playerNameLbl.Position = UDim2.new(0, 75, 0, 6)
playerNameLbl.BackgroundTransparency = 1
playerNameLbl.TextColor3 = C.t1
playerNameLbl.Text = player.Name
playerNameLbl.Font = Enum.Font.GothamBold
playerNameLbl.TextSize = 15
playerNameLbl.TextXAlignment = Enum.TextXAlignment.Left
playerNameLbl.Parent = infoCard

local userIdLbl = Instance.new("TextLabel")
userIdLbl.Size = UDim2.new(1, -75, 0, 18)
userIdLbl.Position = UDim2.new(0, 75, 0, 32)
userIdLbl.BackgroundTransparency = 1
userIdLbl.TextColor3 = C.t3
userIdLbl.Text = "ID: " .. tostring(player.UserId)
userIdLbl.Font = Enum.Font.GothamBold
userIdLbl.TextSize = 12
userIdLbl.TextXAlignment = Enum.TextXAlignment.Left
userIdLbl.Parent = infoCard

local sessionTimeLbl = Instance.new("TextLabel")
sessionTimeLbl.Size = UDim2.new(1, 0, 0, 22)
sessionTimeLbl.Position = UDim2.new(0, 0, 0, 85)
sessionTimeLbl.BackgroundTransparency = 1
sessionTimeLbl.TextColor3 = C.t2
sessionTimeLbl.Text = "Active Time: 00:00:00"
sessionTimeLbl.Font = Enum.Font.GothamBold
sessionTimeLbl.TextSize = 13
sessionTimeLbl.TextXAlignment = Enum.TextXAlignment.Left
sessionTimeLbl.Parent = infoCard

local killsInfoLbl = Instance.new("TextLabel")
killsInfoLbl.Size = UDim2.new(1, 0, 0, 22)
killsInfoLbl.Position = UDim2.new(0, 0, 0, 115)
killsInfoLbl.BackgroundTransparency = 1
killsInfoLbl.TextColor3 = C.t2
killsInfoLbl.Text = "Session Kills: 0"
killsInfoLbl.Font = Enum.Font.GothamBold
killsInfoLbl.TextSize = 13
killsInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
killsInfoLbl.Parent = infoCard

-- 4. Settings
local settingsPage = addTab("Settings")

makeBoxInput(settingsPage, "Interface Scale Factor", cfg.uiScale, function(val)
    local n = tonumber(val)
    if n then
        cfg.uiScale = math.clamp(n, 0.6, 1.8)
        TweenService:Create(uiScale, tw, {Scale = cfg.uiScale}):Play()
    end
end, 1)

-- ══ ЛОГИКА РАБОТЫ СКРИПТА ══════════════════════════════════

RunService.Heartbeat:Connect(function()
    local elapsed = math.floor(tick() - startTime)
    local hours = math.floor(elapsed / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = elapsed % 60
    sessionTimeLbl.Text = string.format("Active Time: %02d:%02d:%02d", hours, mins, secs)
    killsInfoLbl.Text = "Session Kills: " .. tostring(state.killCount)

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

print("[Clown HUB]: Loaded successfully with clean typography and modern UX.")
