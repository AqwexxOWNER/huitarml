--[[
    huita.rml | TRIDENT SURVIVAL V5 
    Optimized for Mobile (Codex/Delta)
]]

-- 1. Ожидание загрузки игры
if not game:IsLoaded() then game.Loaded:Wait() end

-- 2. Защита от повторного запуска
if _G.HuitaLoaded then return end
_G.HuitaLoaded = true

-- 3. Библиотека интерфейса (Легкая версия)
local KavoLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = KavoLib.CreateLib("huita.rml | TRIDENT V5", "Midnight")

-- 4. Переменные
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

_G.SilentAim = false
_G.AutoShot = false
_G.FOV_Radius = 100
_G.FOV_Visible = false
_G.SpeedBypass = false
_G.SpeedValue = 16
_G.ESP_Items = false
_G.ESP_Totems = false

-- 5. Функции поиска цели
local function GetClosestTarget()
    local target = nil
    local dist = _G.FOV_Radius
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= Player and v.Character and v.Character:FindFirstChild("Head") then
            local pos, vis = Camera:WorldToViewportPoint(v.Character.Head.Position)
            if vis then
                local mag = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if mag < dist then
                    target = v.Character.Head
                    dist = mag
                end
            end
        end
    end
    return target
end

-- 6. Отрисовка FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Transparency = 1

-- 7. Метаметод Байпасс (Silent Aim)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if _G.SilentAim and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList") then
        local t = GetClosestTarget()
        if t then
            if method == "Raycast" then
                args[2] = (t.Position - args[1]).Unit * 1000
            else
                args[1] = Ray.new(Camera.CFrame.Position, (t.Position - Camera.CFrame.Position).Unit * 1000)
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

mt.__index = newcclosure(function(t, k)
    if not checkcaller() and t:IsA("Humanoid") and t.Parent == Player.Character then
        if k == "WalkSpeed" then return 16 end
    end
    return oldIndex(t, k)
end)
setreadonly(mt, true)

-- 8. Создание вкладок
local Combat = Window:NewTab("Combat")
local CombatSec = Combat:NewSection("Silent Aim & FOV")

CombatSec:NewToggle("Enable Silent Aim", "Perfect hits", function(state)
    _G.SilentAim = state
end)

CombatSec:NewToggle("Auto Shot", "Fires automatically", function(state)
    _G.AutoShot = state
end)

CombatSec:NewToggle("Show FOV Circle", "Visible radius", function(state)
    _G.FOV_Visible = state
end)

CombatSec:NewSlider("FOV Radius", "Adjust aim area", 500, 30, function(s)
    _G.FOV_Radius = s
end)

local Visuals = Window:NewTab("Visuals")
local VisSec = Visuals:NewSection("ESP World")

VisSec:NewToggle("Show Items", "Highlight guns/armor", function(state)
    _G.ESP_Items = state
end)

VisSec:NewToggle("Show Totems", "Highlight bases", function(state)
    _G.ESP_Totems = state
end)

local Misc = Window:NewTab("Misc")
local MiscSec = Misc:NewSection("Movement")

MiscSec:NewToggle("Speed Bypass", "Unlock WalkSpeed", function(state)
    _G.SpeedBypass = state
end)

MiscSec:NewSlider("Speed Value", "Max safe speed ~80", 120, 16, function(s)
    _G.SpeedValue = s
end)

-- 9. Циклы и Мобильные кнопки
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = _G.FOV_Visible
    FOVCircle.Radius = _G.FOV_Radius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    if _G.SpeedBypass and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = _G.SpeedValue
    end
    
    if _G.SilentAim and _G.AutoShot then
        if GetClosestTarget() then mouse1click() end
    end
end)

-- Кнопка RML для мобилок (Открытие меню)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.Text = "RML"
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
local Corner = Instance.new("UICorner", OpenBtn)
Corner.CornerRadius = UDim.new(1, 0)

OpenBtn.MouseButton1Click:Connect(function()
    -- Эмуляция нажатия RightShift для открытия Kavo UI
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
end)

-- Кнопка SLIDE
local SlideBtn = Instance.new("TextButton", ScreenGui)
SlideBtn.Size = UDim2.new(0, 70, 0, 70)
SlideBtn.Position = UDim2.new(0.85, -35, 0.5, -35)
SlideBtn.Text = "SLIDE"
SlideBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SlideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
local Corner2 = Instance.new("UICorner", SlideBtn)
Corner2.CornerRadius = UDim.new(1, 0)

SlideBtn.MouseButton1Click:Connect(function()
    if _G.SpeedBypass and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Player.Character.HumanoidRootPart
        Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        hrp.Velocity = hrp.CFrame.LookVector * (_G.SpeedValue * 2.5)
        Player.Character.Humanoid.PlatformStand = true
        task.wait(0.35)
        Player.Character.Humanoid.PlatformStand = false
    end
end)
