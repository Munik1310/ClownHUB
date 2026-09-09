-- ╔══════════════════════════════════════════════════════════════╗
-- ║        CLOWN HUB — Blox Fruits Interface (GUI)               ║
-- ║        Интегрирован с Logic.luau и UIShadow                  ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Подключение логики из GitHub
-- ╔══════════════════════════════════════════════════════════════╗
-- ║        CLOWN HUB — Safe Loader & GUI Integration             ║
-- ╚══════════════════════════════════════════════════════════════╝

local Logic
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Munik1310/ClownHUB/refs/heads/main/Logic.luau"))()
end)

if success and type(result) == "table" then
    Logic = result
else
    warn("[ClownHUB]: Не удалось загрузить Logic.luau. Используются значения по умолчанию.")
    Logic = {
        Config = { SelectedMob = "Bandit", FarmHeight = 25, WalkSpeed = 100 },
        State = { AutoFarmMobs = false, FastAttack = false, KillAura = false, FruitEsp = false, WaterImmunity = false, SpeedBoost = false },
        ToggleFruitESP = function() end,
        StoreAllFruits = function() end,
    }
end

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local TeleportService   = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- Настройки GUI
local uiCfg = {
    minimized = false,
    scale     = 1.0,
}

-- Палитра
local C = {
    bg0   = Color3.fromRGB(12,  12,  16),
    bg1   = Color3.fromRGB(20,  20,  26),
    bg2   = Color3.fromRGB(30,  30,  40),
    bg3   = Color3.fromRGB(45,  45,  58),
    t1    = Color3.fromRGB(255, 255, 255),
    t2    = Color3.fromRGB(185, 185, 200),
    t3    = Color3.fromRGB(120, 120, 135),
    grn   = Color3.fromRGB(46,  204, 113),
    white = Color3.fromRGB(255, 255, 255),
}

local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function addShadow(p, transparency)
    local s = Instance.new("UIStroke")
    s.Transparency = transparency or 0.85
    s.Color = Color3.fromRGB(0, 0, 0)
    s.Thickness = 2.5
    s.Parent = p
    return s
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

-- Создание ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "ClownHubBloxFruits"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = uiCfg.scale
uiScale.Parent = gui

-- ══ СВОРАЧИВАЕМАЯ ПЛАШКА (PILL) ══════════════════════════════
local pill = Instance.new("Frame")
pill.Size = UDim2.new(0, 150, 0, 42)
pill.Position = UDim2.new(0, 40, 0, 80)
pill.BackgroundColor3 = C.bg1
pill.BorderSizePixel = 0
pill.Visible = false
pill.Active = true
pill.ZIndex = 100
pill.Parent = gui
corner(pill, 21)
addShadow(pill, 0.6)

local pillDot = Instance.new("Frame")
pillDot.Size = UDim2.new(0, 10, 0, 10)
pillDot.Position = UDim2.new(0, 16, 0.5, -5)
pillDot.BackgroundColor3 = C.grn
pillDot.BorderSizePixel = 0
pillDot.Parent = pill
corner(pillDot, 5)

local pillTxt = Instance.new("TextButton")
pillTxt.Size = UDim2.new(1, -34, 1, 0)
pillTxt.Position = UDim2.new(0, 34, 0, 0)
pillTxt.BackgroundTransparency = 1
pillTxt.TextColor3 = C.t1
pillTxt.Text = "CLOWN HUB"
pillTxt.Font = Enum.Font.GothamBold
pillTxt.TextSize = 13
pillTxt.TextXAlignment = Enum.TextXAlignment.Left
pillTxt.Parent = pill

-- Бесшовный Drag для окон
local function makeDraggable(frame)
    local dragging, dragStart, startPos = false, nil, nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(pill)

-- ══ ОСНОВНОЕ ОКНО ═════════════════════════════════════════
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 620, 0, 420)
mainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
mainFrame.BackgroundColor3 = C.bg0
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = gui
corner(mainFrame, 12)
addShadow(mainFrame, 0.5)
makeDraggable(mainFrame)

-- Сайдбар
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.BackgroundColor3 = C.bg1
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
corner(sidebar, 12)

local sideFix = Instance.new("Frame")
sideFix.Size = UDim2.new(0, 15, 1, 0)
sideFix.Position = UDim2.new(1, -15, 0, 0)
sideFix.BackgroundColor3 = C.bg1
sideFix.BorderSizePixel = 0
sideFix.Parent = sidebar

local sideHeader = Instance.new("Frame")
sideHeader.Size = UDim2.new(1, 0, 0, 65)
sideHeader.BackgroundTransparency = 1
sideHeader.Parent = sidebar

local brandLbl = Instance.new("TextLabel")
brandLbl.Size = UDim2.new(1, -20, 0, 22)
brandLbl.Position = UDim2.new(0, 16, 0, 16)
brandLbl.BackgroundTransparency = 1
brandLbl.TextColor3 = C.t1
brandLbl.Text = "CLOWN HUB"
brandLbl.Font = Enum.Font.GothamBold
brandLbl.TextSize = 16
brandLbl.TextXAlignment = Enum.TextXAlignment.Left
brandLbl.Parent = sideHeader

local subBrandLbl = Instance.new("TextLabel")
subBrandLbl.Size = UDim2.new(1, -20, 0, 16)
subBrandLbl.Position = UDim2.new(0, 16, 0, 38)
subBrandLbl.BackgroundTransparency = 1
subBrandLbl.TextColor3 = C.t3
subBrandLbl.Text = "BLOX FRUITS EDITION"
subBrandLbl.Font = Enum.Font.GothamBold
subBrandLbl.TextSize = 10
subBrandLbl.TextXAlignment = Enum.TextXAlignment.Left
subBrandLbl.Parent = sideHeader

local navList = Instance.new("ScrollingFrame")
navList.Size = UDim2.new(1, 0, 1, -70)
navList.Position = UDim2.new(0, 0, 0, 70)
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

-- Контент
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -180, 1, 0)
contentArea.Position = UDim2.new(0, 180, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundTransparency = 1
topBar.Parent = contentArea

local currentTabLbl = Instance.new("TextLabel")
currentTabLbl.Size = UDim2.new(1, -90, 1, 0)
currentTabLbl.Position = UDim2.new(0, 20, 0, 0)
currentTabLbl.BackgroundTransparency = 1
currentTabLbl.TextColor3 = C.t1
currentTabLbl.Text = "Auto Farm"
currentTabLbl.Font = Enum.Font.GothamBold
currentTabLbl.TextSize = 17
currentTabLbl.TextXAlignment = Enum.TextXAlignment.Left
currentTabLbl.Parent = topBar

-- Кнопки управления окном
local winControls = Instance.new("Frame")
winControls.Size = UDim2.new(0, 70, 0, 32)
winControls.Position = UDim2.new(1, -80, 0, 14)
winControls.BackgroundTransparency = 1
winControls.Parent = topBar

local function createWinBtn(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30)
    b.BackgroundColor3 = C.bg1
    b.TextColor3 = C.t2
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.BorderSizePixel = 0
    corner(b, 8)
    return b
end

local minimizeBtn = createWinBtn("-")
minimizeBtn.Position = UDim2.new(0, 0, 0, 0)
minimizeBtn.Parent = winControls

local closeBtn = createWinBtn("×")
closeBtn.Position = UDim2.new(0, 36, 0, 0)
closeBtn.Parent = winControls

closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

minimizeBtn.MouseButton1Click:Connect(function()
    uiCfg.minimized = true
    mainFrame.Visible = false
    pill.Visible = true
end)

pillTxt.MouseButton1Click:Connect(function()
    uiCfg.minimized = false
    pill.Visible = false
    mainFrame.Visible = true
end)

local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, 0, 1, -60)
pagesContainer.Position = UDim2.new(0, 0, 0, 60)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = contentArea

local tabs = {}

local function addTab(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = C.bg3
    page.Visible = false
    page.Parent = pagesContainer

    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 10)
    l.Parent = page
    pad(page, 5, 20, 20, 20)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 38)
    btn.BackgroundColor3 = C.bg1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = navList
    corner(btn, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.t2
    lbl.Text = name
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
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

-- ══ ЭЛЕМЕНТЫ УПРАВЛЕНИЯ С ПРИВЯЗКОЙ К LOGIC ═════════════════

local function makeSwitch(parent, text, initial, callback)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 50)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    corner(wrap, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -65, 1, 0)
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
    pillBg.Position = UDim2.new(1, -54, 0.5, -12)
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
end

local function makeButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = C.bg1
    btn.BorderSizePixel = 0
    btn.TextColor3 = C.t1
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    corner(btn, 10)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, tw, {BackgroundColor3 = C.bg3}):Play()
        task.delay(0.15, function()
            TweenService:Create(btn, tw, {BackgroundColor3 = C.bg1}):Play()
        end)
        if callback then callback() end
    end)
end

local function makeBoxInput(parent, label, default, callback)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 58)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.Parent = parent
    corner(wrap, 10)
    pad(wrap, 8, 8, 16, 16)

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
    box.Size = UDim2.new(1, 0, 0, 22)
    box.Position = UDim2.new(0, 0, 0, 18)
    box.BackgroundTransparency = 1
    box.TextColor3 = C.t1
    box.Text = tostring(default)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 14
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = wrap

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
end

-- ══ НАПОЛНЕНИЕ ВЛАДОК ФУНКЦИЯМИ ════════════════════════════

-- 1. Auto Farm
local farmPage = addTab("Auto Farm")

makeSwitch(farmPage, "Auto Farm Select Mob", Logic.State.AutoFarmMobs, function(on)
    Logic.State.AutoFarmMobs = on
end)

makeBoxInput(farmPage, "Имя моба (Mob Name)", Logic.Config.SelectedMob, function(val)
    Logic.Config.SelectedMob = val
end)

makeBoxInput(farmPage, "Высота фарма над мобом", Logic.Config.FarmHeight, function(val)
    local n = tonumber(val)
    if n then Logic.Config.FarmHeight = n end
end)

-- 2. Combat & Fast Attack
local combatPage = addTab("Combat & Aura")

makeSwitch(combatPage, "Fast Attack (Ускоренная атака)", Logic.State.FastAttack, function(on)
    Logic.State.FastAttack = on
end)

makeSwitch(combatPage, "Kill Aura (Атака вокруг)", Logic.State.KillAura, function(on)
    Logic.State.KillAura = on
end)

-- 3. Teleports
local telePage = addTab("Teleports")

makeButton(telePage, "Телепорт: First Sea (Первое море)", function()
    TeleportService:Teleport(2753915549, player)
end)

makeButton(telePage, "Телепорт: Second Sea (Второе море)", function()
    TeleportService:Teleport(4442272183, player)
end)

makeButton(telePage, "Телепорт: Third Sea (Третье море)", function()
    TeleportService:Teleport(7449423635, player)
end)

-- 4. Fruits & ESP
local fruitPage = addTab("Fruits & ESP")

makeSwitch(fruitPage, "Fruit ESP (Подсветка фруктов)", Logic.State.FruitEsp, function(on)
    Logic.ToggleFruitESP(on)
end)

makeButton(fruitPage, "Auto Store All Fruits (Сохранить в инвентарь)", function()
    Logic.StoreAllFruits()
end)

-- 5. Character
local playerPage = addTab("Character")

makeSwitch(playerPage, "Water Immunity (Хождение по воде)", Logic.State.WaterImmunity, function(on)
    Logic.State.WaterImmunity = on
end)

makeSwitch(playerPage, "WalkSpeed Boost", Logic.State.SpeedBoost, function(on)
    Logic.State.SpeedBoost = on
end)

makeBoxInput(playerPage, "Скорость бега", Logic.Config.WalkSpeed, function(val)
    local n = tonumber(val)
    if n then Logic.Config.WalkSpeed = n end
end)

print("[CLOWN HUB]: Fully connected UI and Logic successfully initialized!")
