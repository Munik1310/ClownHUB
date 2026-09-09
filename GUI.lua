-- ╔══════════════════════════════════════════════════════════════╗
-- ║        CLOWN HUB — Standalone Blox Fruits Script v8.0        ║
-- ║        GUI + Полная боевая логика в одном файле              ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Workspace         = game:GetService("Workspace")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    character = c
    humanoid  = c:WaitForChild("Humanoid")
    rootPart  = c:WaitForChild("HumanoidRootPart")
end)

-- ══ ЕДИНАЯ СИСТЕМА СОСТОЯНИЙ И НАСТРОЕК ═══════════════════════
local Logic = {
    Config = {
        SelectedMob = "Bandit",
        FarmHeight  = 25,
        WalkSpeed   = 100,
        UiScale     = 1.0,
    },
    State = {
        AutoFarmMobs = false,
        FastAttack   = false,
        KillAura     = false,
        FruitEsp     = false,
        WaterImmunity= false,
        SpeedBoost   = false,
    }
}

local espStorage = {}

-- ══ ФУНКЦИОНАЛ ЛОГИКИ И АТАКИ ═════════════════════════════════

local function getTargetMob(mobName)
    local closest, minDistance = nil, math.huge
    local enemies = Workspace:FindFirstChild("Enemies")
    
    if enemies and rootPart then
        for _, mob in ipairs(enemies:GetChildren()) do
            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                if mobName == "" or string.find(string.lower(mob.Name), string.lower(mobName)) then
                    local dist = (rootPart.Position - mob.HumanoidRootPart.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closest = mob
                    end
                end
            end
        end
    end
    return closest
end

local function hitEnemies()
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("RigControllerEvent", true)
        if net then
            net:FireServer("weaponClick")
        end
    end)
end

-- Основной постоянный цикл выполнения
RunService.Heartbeat:Connect(function()
    if not character or not rootPart or not humanoid or humanoid.Health <= 0 then return end

    -- Буст скорости
    if Logic.State.SpeedBoost then
        humanoid.WalkSpeed = Logic.Config.WalkSpeed
    end

    -- Защита от воды
    if Logic.State.WaterImmunity then
        local water = character:FindFirstChild("WaterTouch")
        if water then water:Destroy() end
    end

    -- Автофарм мобов
    if Logic.State.AutoFarmMobs then
        local target = getTargetMob(Logic.Config.SelectedMob)
        if target and target:FindFirstChild("HumanoidRootPart") then
            rootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, Logic.Config.FarmHeight, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rootPart.AssemblyLinearVelocity = Vector3.zero
            
            if Logic.State.FastAttack then
                hitEnemies()
            end
        end
    end

    -- Kill Aura
    if Logic.State.KillAura then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, mob in ipairs(enemies:GetChildren()) do
                if mob:FindFirstChild("HumanoidRootPart") and (mob.HumanoidRootPart.Position - rootPart.Position).Magnitude <= 50 then
                    hitEnemies()
                end
            end
        end
    end
end)

function Logic.ToggleFruitESP(enable)
    Logic.State.FruitEsp = enable
    if not enable then
        for _, highlight in pairs(espStorage) do
            if highlight then highlight:Destroy() end
        end
        espStorage = {}
        return
    end

    task.spawn(function()
        while Logic.State.FruitEsp do
            for _, item in ipairs(Workspace:GetChildren()) do
                if string.find(item.Name, "Fruit") and item:IsA("Tool") and not espStorage[item] then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(255, 0, 100)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.Parent = item
                    espStorage[item] = h
                end
            end
            task.wait(2)
        end
    end)
end

function Logic.StoreAllFruits()
    local commF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
    for _, item in ipairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and string.find(item.Name, "Fruit") then
            commF:InvokeServer("StoreFruit", item.Name, item)
        end
    end
end

-- ══ ПОСТРОЕНИЕ ГРАФИЧЕСКОГО ИНТЕРФЕЙСА (GUI) ═══════════════════

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

local gui = Instance.new("ScreenGui")
gui.Name = "ClownHubBloxFruits"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = Logic.Config.UiScale
uiScale.Parent = gui

-- ПЛАШКА СВОРАЧИВАНИЯ (PILL)
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

local pillTxt = Instance.new("TextButton")
pillTxt.Size = UDim2.new(1, 0, 1, 0)
pillTxt.BackgroundTransparency = 1
pillTxt.TextColor3 = C.t1
pillTxt.Text = "  CLOWN HUB"
pillTxt.Font = Enum.Font.GothamBold
pillTxt.TextSize = 13
pillTxt.Parent = pill

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

-- ОСНОВНОЕ ОКНО
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

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.BackgroundColor3 = C.bg1
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
corner(sidebar, 12)

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

local winControls = Instance.new("Frame")
winControls.Size = UDim2.new(0, 70, 0, 32)
winControls.Position = UDim2.new(1, -80, 0, 14)
winControls.BackgroundTransparency = 1
winControls.Parent = topBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.BackgroundColor3 = C.bg1
minimizeBtn.TextColor3 = C.t2
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = winControls
corner(minimizeBtn, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(0, 36, 0, 0)
closeBtn.BackgroundColor3 = C.bg1
closeBtn.TextColor3 = C.t2
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = winControls
corner(closeBtn, 8)

closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    pill.Visible = true
end)

pillTxt.MouseButton1Click:Connect(function()
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

-- ИНТЕРАКТИВНЫЕ КОМПОНЕНТЫ

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

-- НАПОЛНЕНИЕ ВКЛАДОК

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

local combatPage = addTab("Combat & Aura")

makeSwitch(combatPage, "Fast Attack (Ускоренная атака)", Logic.State.FastAttack, function(on)
    Logic.State.FastAttack = on
end)

makeSwitch(combatPage, "Kill Aura (Атака вокруг)", Logic.State.KillAura, function(on)
    Logic.State.KillAura = on
end)

local telePage = addTab("Teleports")

makeButton(telePage, "Телепорт: First Sea", function() TeleportService:Teleport(2753915549, player) end)
makeButton(telePage, "Телепорт: Second Sea", function() TeleportService:Teleport(4442272183, player) end)
makeButton(telePage, "Телепорт: Third Sea", function() TeleportService:Teleport(7449423635, player) end)

local fruitPage = addTab("Fruits & ESP")

makeSwitch(fruitPage, "Fruit ESP (Подсветка фруктов)", Logic.State.FruitEsp, function(on)
    Logic.ToggleFruitESP(on)
end)

makeButton(fruitPage, "Auto Store All Fruits", function()
    Logic.StoreAllFruits()
end)

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

print("[CLOWN HUB]: Loaded successfully as Standalone Script!")
