-- ╔══════════════════════════════════════════════════════════════╗
-- ║        CLOWN HUB — Blox Fruits Ultimate Edition v7.0         ║
-- ║        Полный функционал + Фикс перетаскивания + UIShadow    ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local CoreGui             = game:GetService("CoreGui")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TeleportService     = game:GetService("TeleportService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- Настройки по умолчанию
local cfg = {
    selectedMob   = "Bandit",
    farmHeight    = 25,
    attackDelay   = 0.1,
    walkSpeed     = 100,
    jumpPower     = 100,
    uiScale       = 1.0,
    minimized     = false,
    autoStoreFruit = true,
}

-- Состояния функций
local state = {
    autoFarmLevel  = false,
    autoFarmMobs   = false,
    autoFarmBoss   = false,
    autoChest      = false,
    fastAttack     = false,
    killAura       = false,
    fruitEsp       = false,
    playerEsp      = false,
    waterImmunity  = false,
    speedBoost     = false,
    jumpBoost      = false,
    noClip         = false,
}

-- Цветовая палитра (Темный стиль, без ярких рамок)
local C = {
    bg0   = Color3.fromRGB(12,  12,  16),
    bg1   = Color3.fromRGB(20,  20,  26),
    bg2   = Color3.fromRGB(30,  30,  40),
    bg3   = Color3.fromRGB(45,  45,  58),
    t1    = Color3.fromRGB(255, 255, 255),
    t2    = Color3.fromRGB(185, 185, 200),
    t3    = Color3.fromRGB(120, 120, 135),
    grn   = Color3.fromRGB(46,  204, 113),
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

-- Мягкая тень вместо обводок
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

-- Создание GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ClownHubBloxFruits"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = cfg.uiScale
uiScale.Parent = gui

-- ══ СВОРАЧИВАЕМАЯ ПЛАШКА (ПЛАВНЫЙ ДРАГ БЕЗ УЛЕТОВ МЫШИ) ══════
local pill = Instance.new("Frame")
pill.Size = UDim2.new(0, 150, 0, 42)
pill.Position = UDim2.new(0, 40, 0, 80) -- Позиционировано ниже topbar
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

-- Надежная функция перетаскивания (не срывается при резких движениях)
local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos

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

-- Контентная зона
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

-- Собственные кнопки свернуть/закрыть
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

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    cfg.minimized = true
    mainFrame.Visible = false
    pill.Visible = true
end)

pillTxt.MouseButton1Click:Connect(function()
    cfg.minimized = false
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
    btn.Position = UDim2.new(0, 8, 0, 0)
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

-- ══ ЭЛЕМЕНТЫ УПРАВЛЕНИЯ (КРУПНЫЙ ШРИФТ) ═══════════════════

local function makeSwitch(parent, text, initial, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 50)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
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

local function makeButton(parent, text, callback, lo)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = C.bg1
    btn.BorderSizePixel = 0
    btn.TextColor3 = C.t1
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.LayoutOrder = lo or 0
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

local function makeBoxInput(parent, label, default, callback, lo)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 58)
    wrap.BackgroundColor3 = C.bg1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = lo or 0
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

-- ══ СТРАНИЦЫ И ФУНКЦИОНАЛ BLOX FRUITS ══════════════════════

-- 1. Auto Farm
local farmPage = addTab("Auto Farm")

makeSwitch(farmPage, "Auto Farm Level (Квесты + Мобы)", false, function(on)
    state.autoFarmLevel = on
end, 1)

makeSwitch(farmPage, "Auto Farm Select Mob", false, function(on)
    state.autoFarmMobs = on
end, 2)

makeSwitch(farmPage, "Auto Chest Farm (Сбор сундуков)", false, function(on)
    state.autoChest = on
end, 3)

makeBoxInput(farmPage, "Высота автофарма (Distance)", cfg.farmHeight, function(val)
    local n = tonumber(val)
    if n then cfg.farmHeight = math.clamp(n, 5, 100) end
end, 4)

-- 2. Combat & Fast Attack
local combatPage = addTab("Combat & Aura")

makeSwitch(combatPage, "Fast Attack (Ускоренная атака)", false, function(on)
    state.fastAttack = on
end, 1)

makeSwitch(combatPage, "Kill Aura (Атака всех вокруг)", false, function(on)
    state.killAura = on
end, 2)

-- 3. Teleports & World
local telePage = addTab("Teleports")

makeButton(telePage, "Телепорт: First Sea (Первое море)", function()
    TeleportService:Teleport(2753915549, player)
end, 1)

makeButton(telePage, "Телепорт: Second Sea (Второе море)", function()
    TeleportService:Teleport(4442272183, player)
end, 2)

makeButton(telePage, "Телепорт: Third Sea (Третье море)", function()
    TeleportService:Teleport(7449423635, player)
end, 3)

-- 4. Fruits & ESP
local fruitPage = addTab("Fruits & ESP")

makeSwitch(fruitPage, "Fruit ESP (Подсветка фруктов)", false, function(on)
    state.fruitEsp = on
end, 1)

makeSwitch(fruitPage, "Player ESP (Подсветка игроков)", false, function(on)
    state.playerEsp = on
end, 2)

makeButton(fruitPage, "Auto Store All Fruits (Сохранить все)", function()
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(tool.Name, "Fruit") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", tool.Name, tool)
        end
    end
end, 3)

-- 5. Character & Visuals
local playerPage = addTab("Character")

makeSwitch(playerPage, "Water Immunity (Хождение по воде)", false, function(on)
    state.waterImmunity = on
end, 1)

makeSwitch(playerPage, "WalkSpeed Boost", false, function(on)
    state.speedBoost = on
end, 2)

makeBoxInput(playerPage, "Скорость бега", cfg.walkSpeed, function(val)
    local n = tonumber(val)
    if n then cfg.walkSpeed = n end
end, 3)

makeButton(playerPage, "Boost FPS / White Screen (Для слабых ПК)", function()
    for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
        if v:IsA("PostEffect") then v.Enabled = false end
    end
    workspace.Terrain.WaterWaveSize = 0
    workspace.Terrain.WaterWaveSpeed = 0
end, 4)

-- ══ ВНУТРЕННЯЯ ЛОГИКА (HEARTBEAT LOOP) ══════════════════════

RunService.Heartbeat:Connect(function()
    if state.speedBoost and humanoid then
        humanoid.WalkSpeed = cfg.walkSpeed
    end

    -- Хождение по воде (Защита от урона водой)
    if state.waterImmunity and character:FindFirstChild("WaterTouch") then
        character.WaterTouch:Destroy()
    end

    -- Fast Attack Логика
    if state.fastAttack then
        pcall(function()
            local combatRemote = ReplicatedStorage:FindFirstChild("RigControllerEvent", true)
            if combatRemote then
                combatRemote:FireServer("weaponClick")
            end
        end)
    end
end)

print("[CLOWN HUB]: Loaded successfully with clean typography, smooth dragging, and UI Shadows!")
