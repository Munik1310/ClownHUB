-- ╔══════════════════════════════════════════════════════════════╗
-- ║           CLOWN HUB — Blox Fruits Standalone v9.0            ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    character = c
    humanoid  = c:WaitForChild("Humanoid")
    rootPart  = c:WaitForChild("HumanoidRootPart")
end)

-- ══ НАСТРОЙКИ И СОСТОЯНИЕ ═════════════════════════════════════
local Logic = {
    Config = {
        SelectedMob = "Bandit",
        FarmHeight  = 12,
        WalkSpeed   = 100,
        TweenSpeed  = 350,
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

local activeTween = nil
local espStorage  = {}

-- ══ РАБОЧИЕ ФУНКЦИИ (ОБХОД АНТИЧИТА И АТАКА) ════════════════════

local function equipWeapon()
    if not character:FindFirstChildOfClass("Tool") then
        local tool = player.Backpack:FindFirstChildOfClass("Tool")
        if tool then
            humanoid:EquipTool(tool)
        end
    end
end

local function safeMoveTo(targetCFrame)
    if not rootPart then return end
    local distance = (targetCFrame.Position - rootPart.Position).Magnitude
    if distance < 4 then
        rootPart.CFrame = targetCFrame
        return
    end

    local time = distance / Logic.Config.TweenSpeed
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    if activeTween then activeTween:Cancel() end
    activeTween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    activeTween:Play()
end

local function getTargetMob(mobName)
    local closest, minDistance = nil, math.huge
    local enemies = Workspace:FindFirstChild("Enemies")
    
    if enemies and rootPart then
        for _, mob in ipairs(enemies:GetChildren()) do
            local mobHum = mob:FindFirstChild("Humanoid")
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobHum and mobHum.Health > 0 and mobRoot then
                if mobName == "" or string.find(string.lower(mob.Name), string.lower(mobName)) then
                    local dist = (rootPart.Position - mobRoot.Position).Magnitude
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

local function performAttack()
    equipWeapon()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(500, 500))
    
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("RigControllerEvent", true)
        if net then
            net:FireServer("weaponClick")
        end
    end)
end

-- ══ ОСНОВНОЙ ЦИКЛ ВЫПОЛНЕНИЯ ══════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if character and rootPart and humanoid and humanoid.Health > 0 then
            
            if Logic.State.SpeedBoost then
                humanoid.WalkSpeed = Logic.Config.WalkSpeed
            end

            if Logic.State.WaterImmunity then
                local water = character:FindFirstChild("WaterTouch")
                if water then water:Destroy() end
            end

            if Logic.State.AutoFarmMobs then
                local target = getTargetMob(Logic.Config.SelectedMob)
                if target and target:FindFirstChild("HumanoidRootPart") then
                    local targetPos = target.HumanoidRootPart.CFrame * CFrame.new(0, Logic.Config.FarmHeight, 0)
                    safeMoveTo(targetPos)
                    
                    if Logic.State.FastAttack then
                        performAttack()
                    end
                end
            elseif activeTween then
                activeTween:Cancel()
                activeTween = nil
            end

            if Logic.State.KillAura then
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, mob in ipairs(enemies:GetChildren()) do
                        local mRoot = mob:FindFirstChild("HumanoidRootPart")
                        local mHum = mob:FindFirstChild("Humanoid")
                        if mRoot and mHum and mHum.Health > 0 then
                            if (mRoot.Position - rootPart.Position).Magnitude <= 40 then
                                performAttack()
                                break
                            end
                        end
                    end
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
                if string.find(item.Name, "Fruit") and (item:IsA("Tool") or item:IsA("Model")) and not espStorage[item] then
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

-- ══ ИНТЕРФЕЙС (GUI) ═══════════════════════════════════════════
local C = {
    bg0 = Color3.fromRGB(12, 12, 16), bg1 = Color3.fromRGB(20, 20, 26),
    bg3 = Color3.fromRGB(45, 45, 58), t1  = Color3.fromRGB(255, 255, 255),
    t2  = Color3.fromRGB(185, 185, 200), grn = Color3.fromRGB(46, 204, 113)
}

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p end
local function pad(p, t, b, l, r) local u = Instance.new("UIPadding") u.PaddingTop = UDim.new(0, t) u.PaddingBottom = UDim.new(0, b or t) u.PaddingLeft = UDim.new(0, l or t) u.PaddingRight = UDim.new(0, r or t) u.Parent = p end

local gui = Instance.new("ScreenGui")
gui.Name = "ClownHubBloxFruits"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 580, 0, 380)
mainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
mainFrame.BackgroundColor3 = C.bg0
mainFrame.Active = true
mainFrame.Parent = gui
corner(mainFrame, 12)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, 0)
sidebar.BackgroundColor3 = C.bg1
sidebar.Parent = mainFrame
corner(sidebar, 12)

local navList = Instance.new("ScrollingFrame")
navList.Size = UDim2.new(1, 0, 1, -40)
navList.Position = UDim2.new(0, 0, 0, 40)
navList.BackgroundTransparency = 1
navList.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 6)
navLayout.Parent = navList
pad(navList, 10, 10, 10, 10)

local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, -160, 1, 0)
pagesContainer.Position = UDim2.new(0, 160, 0, 0)
pagesContainer.BackgroundTransparency = 1
pagesContainer.Parent = mainFrame

local tabs = {}
local function addTab(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = pagesContainer

    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 10)
    l.Parent = page
    pad(page, 15, 15, 15, 15)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = C.bg1
    btn.TextColor3 = C.t2
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = navList
    corner(btn, 8)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.page.Visible = false
            t.btn.BackgroundColor3 = C.bg1
        end
        page.Visible = true
        btn.BackgroundColor3 = C.bg3
    end)

    table.insert(tabs, {page = page, btn = btn})
    if #tabs == 1 then page.Visible = true btn.BackgroundColor3 = C.bg3 end
    return page
end

local function makeSwitch(parent, text, initial, callback)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 44)
    wrap.BackgroundColor3 = C.bg1
    wrap.Parent = parent
    corner(wrap, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.t1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap

    local pillBg = Instance.new("Frame")
    pillBg.Size = UDim2.new(0, 40, 0, 22)
    pillBg.Position = UDim2.new(1, -50, 0.5, -11)
    pillBg.BackgroundColor3 = initial and C.grn or C.bg3
    pillBg.Parent = wrap
    corner(pillBg, 11)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = wrap

    local active = initial
    btn.MouseButton1Click:Connect(function()
        active = not active
        pillBg.BackgroundColor3 = active and C.grn or C.bg3
        if callback then callback(active) end
    end)
end

local function makeBoxInput(parent, label, default, callback)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 48)
    wrap.BackgroundColor3 = C.bg1
    wrap.Parent = parent
    corner(wrap, 8)
    pad(wrap, 6, 6, 12, 12)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 1, 0)
    box.BackgroundTransparency = 1
    box.TextColor3 = C.t1
    box.Text = tostring(default)
    box.PlaceholderText = label
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = wrap

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
end

-- НАПОЛНЕНИЕ ВКЛАДОК
local farmPage = addTab("Auto Farm")
makeSwitch(farmPage, "Auto Farm Select Mob", Logic.State.AutoFarmMobs, function(on) Logic.State.AutoFarmMobs = on end)
makeSwitch(farmPage, "Fast Attack", Logic.State.FastAttack, function(on) Logic.State.FastAttack = on end)
makeBoxInput(farmPage, "Имя моба", Logic.Config.SelectedMob, function(val) Logic.Config.SelectedMob = val end)

local combatPage = addTab("Combat")
makeSwitch(combatPage, "Kill Aura", Logic.State.KillAura, function(on) Logic.State.KillAura = on end)

local fruitPage = addTab("Fruits")
makeSwitch(fruitPage, "Fruit ESP", Logic.State.FruitEsp, function(on) Logic.ToggleFruitESP(on) end)

local playerPage = addTab("Player")
makeSwitch(playerPage, "Water Immunity", Logic.State.WaterImmunity, function(on) Logic.State.WaterImmunity = on end)
makeSwitch(playerPage, "WalkSpeed Boost", Logic.State.SpeedBoost, function(on) Logic.State.SpeedBoost = on end)

print("[CLOWN HUB]: Loaded and active!")
