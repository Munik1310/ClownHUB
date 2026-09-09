-- ╔══════════════════════════════════════════════════════════════╗
-- ║         Cake Island PRO v5.0 — Modular Architecture          ║
-- ║         Loader Script (Bootstraps Core Logic & UI)           ║
-- ╚══════════════════════════════════════════════════════════════╝

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- Prevent duplicate executions
if CoreGui:FindFirstChild("CakeIslandSidebarPRO") then
    CoreGui.CakeIslandSidebarPRO:Destroy()
end

print("[Cake Island PRO]: Initializing modular loader...")

-- Modular source URLs (replace raw links with your actual GitHub raw links if hosted externally)
-- For local/instant execution, we wrap the UI and Logic tables together.

-- Main.lua (Загрузчик)
local success, errorMessage = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Munik1310/ClownHUB/refs/heads/main/GUI.luau"))()
end)

if not success then
    warn("[ClownHUB]: Ошибка загрузки интерфейса: " .. tostring(errorMessage))
else
    print("[ClownHUB]: Интерфейс успешно запущен!")
end
