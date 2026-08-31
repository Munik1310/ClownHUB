-- Используем pcall, чтобы скрипт не падал при ошибках окружения
local success, err = pcall(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Удаляем старое меню, если оно уже висит
    if PlayerGui:FindFirstChild("FastCheatUI") then
        PlayerGui.FastCheatUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FastCheatUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = mainFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(80, 80, 120)
    uiStroke.Thickness = 1.5
    uiStroke.Parent = mainFrame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "⚡ QUICK CHEAT"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    -- Функция кнопки
    local function createButton(name, posY, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 220, 0, 35)
        btn.Position = UDim2.new(0.5, -110, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = mainFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(50, 50, 70),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(35, 35, 45),
                TextColor3 = Color3.fromRGB(200, 200, 200)
            }):Play()
        end)

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    createButton("Включить Function 1", 55, function()
        print("Функция 1 активна!")
    end)

    createButton("Включить Function 2", 100, function()
        print("Функция 2 активна!")
    end)

    createButton("Закрыть меню", 145, function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.3)
        screenGui:Destroy()
    end)

    -- Появление
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, 200),
        Position = UDim2.new(0.5, -130, 0.5, -100)
    }):Play()
end)

if not success then
    warn("Ошибка запуска интерфейса: " .. tostring(err))
end
