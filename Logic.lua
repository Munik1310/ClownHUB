-- ╔══════════════════════════════════════════════════════════════╗
-- ║         CLOWN HUB — Blox Fruits Backend Logic                ║
-- ║         Файл: Logic.luau (Обработка фарм-системы и ремоутов)  ║
-- ╚══════════════════════════════════════════════════════════════╝

local Logic = {}

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local CommF       = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- Переменные конфигурации и состояний
Logic.Config = {
    FarmHeight   = 25,
    WalkSpeed    = 100,
    SelectedMob  = "Bandit",
}

Logic.State = {
    AutoFarmLevel = false,
    AutoFarmMobs  = false,
    AutoChest     = false,
    FastAttack    = false,
    KillAura      = false,
    FruitEsp      = false,
    PlayerEsp     = false,
    WaterImmunity = false,
    SpeedBoost    = false,
}

local espStorage = {}

-- 1. Функция безопасной перемещалки (Tween)
local function tweenTo(targetCFrame, speed)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local dist = (targetCFrame.Position - root.Position).Magnitude
    local time = dist / (speed or 250)

    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- 2. Поиск ближайшего моба из списка
local function getTargetMob(mobName)
    local closest, minDistance = nil, math.huge
    local enemies = Workspace:FindFirstChild("Enemies")
    
    if enemies then
        for _, mob in ipairs(enemies:GetChildren()) do
            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                if mobName == nil or mob.Name == mobName then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
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

-- 3. Fast Attack & Kill Aura (Прямая отсылка пакетов удара)
local function hitEnemies(target)
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("RigControllerEvent", true)
        local combatModule = ReplicatedStorage:FindFirstChild("CombatFramework", true)
        
        if net then
            net:FireServer("weaponClick")
        end
        
        if combatModule then
            local registerAttack = require(combatModule)
            if typeof(registerAttack) == "table" and registerAttack.activeController then
                registerAttack.activeController:attack()
            end
        end
    end)
end

-- 4. Основной игровой цикл
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    local root = char.HumanoidRootPart
    local hum = char.Humanoid

    -- Скорость бега
    if Logic.State.SpeedBoost then
        hum.WalkSpeed = Logic.Config.WalkSpeed
    end

    -- Защита от воды
    if Logic.State.WaterImmunity then
        local water = char:FindFirstChild("WaterTouch")
        if water then water:Destroy() end
    end

    -- Автофарм выборочных мобов
    if Logic.State.AutoFarmMobs then
        local target = getTargetMob(Logic.Config.SelectedMob)
        if target then
            local targetPos = target.HumanoidRootPart.CFrame * CFrame.new(0, Logic.Config.FarmHeight, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            root.CFrame = targetPos
            root.AssemblyLinearVelocity = Vector3.zero
            
            if Logic.State.FastAttack then
                hitEnemies(target)
            end
        end
    end

    -- Kill Aura
    if Logic.State.KillAura then
        for _, mob in ipairs(Workspace.Enemies:GetChildren()) do
            if mob:FindFirstChild("HumanoidRootPart") and (mob.HumanoidRootPart.Position - root.Position).Magnitude <= 50 then
                hitEnemies(mob)
            end
        end
    end
end)

-- 5. Функционал ESP
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

-- 6. Автоматическое сохранение фруктов в инвентарь
function Logic.StoreAllFruits()
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") and string.find(item.Name, "Fruit") then
            CommF:InvokeServer("StoreFruit", item.Name, item)
        end
    end
end

return Logic
