--[[
    huita.rml | TRIDENT SURVIVAL V5 FIXED
    Optimized for Codex, Delta and Mobile Executors
]]

-- Ждем пока игра полностью загрузится
if not game:IsLoaded() then game.Loaded:Wait() end

-- Проверка на дубликаты
if _G.ScriptLoaded then return end
_G.ScriptLoaded = true

local function Notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- Загрузка Orion Lib с защитой от ошибок
local success, OrionLib = pcall(function()
    return loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
end)

if not success or not OrionLib then
    Notify("Error", "Library failed to load. Check your internet or executor.")
    return
end

local Window = OrionLib:MakeWindow({
    Name = "huita.rml | TRIDENT V5", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "huita_configs",
    IntroText = "Trident Bypass Active"
})

-- ПЕРЕМЕННЫЕ
_G.SilentAim = false
_G.AutoShot = false
_G.FOV_Visible = false
_G.FOV_Radius = 100
_G.ESP_Players = false
_G.ESP_Items = false
_G.ESP_Totems = false
_G.SpeedHackEnabled = false
_G.WalkSpeedValue = 16

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ==========================================
-- [ МОБИЛЬНОЕ УПРАВЛЕНИЕ (КНОПКИ) ]
-- ==========================================
local function SetupMobileUI()
    local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    
    -- Кнопка RML (Открытие меню)
    local OpenBtn = Instance.new("TextButton", ScreenGui)
    OpenBtn.Name = "RML_Toggle"
    OpenBtn.Size = UDim2.new(0, 45, 0, 45)
    OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
    OpenBtn.Text = "RML"
    OpenBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenBtn.BackgroundTransparency = 0.2
    local Corner = Instance.new("UICorner", OpenBtn)
    Corner.CornerRadius = UDim.new(1, 0)
    
    OpenBtn.MouseButton1Click:Connect(function()
        local orion = game:GetService("CoreGui"):FindFirstChild("Orion")
        if orion and orion:FindFirstChild("Main") then
            orion.Main.Visible = not orion.Main.Visible
        end
    end)

    -- Кнопка SLIDE
    local SlideBtn = Instance.new("TextButton", ScreenGui)
    SlideBtn.Size = UDim2.new(0, 70, 0, 70)
    SlideBtn.Position = UDim2.new(0.85, -35, 0.5, -35)
    SlideBtn.Text = "SLIDE"
    SlideBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SlideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    local Corner2 = Instance.new("UICorner", SlideBtn)
    Corner2.CornerRadius = UDim.new(1, 0)

    SlideBtn.MouseButton1Click:Connect(function()
        if _G.SpeedHackEnabled and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = Player.Character.HumanoidRootPart
            local hum = Player.Character.Humanoid
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            hrp.Velocity = hrp.CFrame.LookVector * (_G.WalkSpeedValue * 2.5)
            hum.PlatformStand = true
            task.wait(0.35)
            hum.PlatformStand = false
        end
    end)
end

if UIS.TouchEnabled then SetupMobileUI() end

-- ==========================================
-- [ BYPASS & COMBAT LOGIC ]
-- ==========================================

-- Идеальный поиск цели
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

-- Метаметод Bypass
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if _G.SilentAim and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList") then
        local target = GetClosestTarget()
        if target then
            if method == "Raycast" then
                args[2] = (target.Position - args[1]).Unit * 1000
            else
                args[1] = Ray.new(Camera.CFrame.Position, (target.Position - Camera.CFrame.Position).Unit * 1000)
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

mt.__index = newcclosure(function(t, k)
    if not checkcaller() and t:IsA("Humanoid") and Player.Character and t.Parent == Player.Character then
        if k == "WalkSpeed" then return 16 end
        if k == "JumpPower" then return 50 end
    end
    return oldIndex(t, k)
end)
setreadonly(mt, true)

-- ==========================================
-- [ TABS & INTERFACE ]
-- ==========================================

local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483345998"})
local VisualTab = Window:MakeTab({Name = "Visual", Icon = "rbxassetid://4483345998"})
local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998"})

CombatTab:AddToggle({Name = "Silent Aim", Default = false, Callback = function(v) _G.SilentAim = v end})
CombatTab:AddSlider({Name = "FOV Radius", Min = 30, Max = 500, Default = 100, Callback = function(v) _G.FOV_Radius = v end})

VisualTab:AddToggle({Name = "Show Items", Default = false, Callback = function(v) _G.ESP_Items = v end})
VisualTab:AddToggle({Name = "Show Totems", Default = false, Callback = function(v) _G.ESP_Totems = v end})

MiscTab:AddToggle({Name = "Speed Bypass", Default = false, Callback = function(v) _G.SpeedHackEnabled = v end})
MiscTab:AddSlider({Name = "Speed", Min = 16, Max = 85, Default = 16, Callback = function(v) _G.WalkSpeedValue = v end})

-- Цикл обновления
RunService.RenderStepped:Connect(function()
    if _G.SpeedHackEnabled and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
    end
end)

OrionLib:Init()
Notify("huita.rml", "Script Loaded Successfully!")

