--[[
    huita.rml | TRIDENT V5 PRIVATE ULTIMATE
    - Wallbang (Shoot through mountains)
    - Silent Aim + FOV Tracers
    - Chams & ESP (Players, Totems, Items)
    - Speed Bypass (Velocity Method)
    - Long Neck & Hitboxes
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ГЛОБАЛЬНЫЕ НАСТРОЙКИ
_G.SilentAim = false
_G.Wallbang = false
_G.FOV_Radius = 150
_G.FOV_Visible = true
_G.ChamsEnabled = false
_G.HitboxEnabled = false
_G.HitboxSize = 5
_G.LongNeck = false
_G.SpeedBypass = false
_G.SpeedValue = 45
_G.ESP_Items = false
_G.ESP_Totems = false

-- ==========================================
-- [ РИСОВАНИЕ (FOV & LINES) ]
-- ==========================================

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Filled = false
FOVCircle.Transparency = 1

local TargetLine = Drawing.new("Line")
TargetLine.Thickness = 1
TargetLine.Color = Color3.fromRGB(255, 0, 0)
TargetLine.Transparency = 1

-- ==========================================
-- [ ЛОГИКА АИМА И ОБХОДА (METATABLE) ]
-- ==========================================

local function GetTarget()
    local target = nil
    local dist = _G.FOV_Radius
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= Player and v.Character and v.Character:FindFirstChild("Head") then
            local pos, vis = Camera:WorldToViewportPoint(v.Character.Head.Position)
            if vis then
                local mag = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                if mag < dist then target = v.Character.Head; dist = mag end
            end
        end
    end
    return target
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

-- Обход проверки скорости и высоты
mt.__index = newcclosure(function(t, k)
    if not checkcaller() and t:IsA("Humanoid") and t.Parent == Player.Character then
        if k == "WalkSpeed" then return 16 end
        if k == "JumpPower" then return 50 end
    end
    return oldIndex(t, k)
end)

-- Silent Aim & Wallbang Bypass
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if _G.SilentAim and (method == "Raycast" or method == "FindPartOnRay") then
        local t = GetTarget()
        if t then
            if method == "Raycast" then
                args[2] = (t.Position - args[1]).Unit * 1000
                -- WALLBANG: Игнорируем объекты карты (горы, камни)
                if _G.Wallbang then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {workspace:FindFirstChild("Map"), workspace:FindFirstChild("Buildings")}
                    args[3] = params
                end
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- ==========================================
-- [ КАСТОМНЫЙ НЕОНОВЫЙ ИНТЕРФЕЙС ]
-- ==========================================

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 220, 0, 350)
Main.Position = UDim2.new(0.5, -110, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Main.Visible = false
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(0, 255, 255)

local Holder = Instance.new("ScrollingFrame", Main)
Holder.Size = UDim2.new(1, 0, 0.85, 0)
Holder.Position = UDim2.new(0, 0, 0.12, 0)
Holder.BackgroundTransparency = 1
Holder.ScrollBarThickness = 0
local Layout = Instance.new("UIListLayout", Holder)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.Padding = UDim.new(0, 5)

local function AddToggle(name, callback)
    local B = Instance.new("TextButton", Holder)
    B.Size = UDim2.new(0.9, 0, 0, 32)
    B.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    B.Text = name .. ": OFF"
    B.TextColor3 = Color3.fromRGB(150, 150, 150)
    B.Font = Enum.Font.Gotham
    Instance.new("UICorner", B)
    local act = false
    B.MouseButton1Click:Connect(function()
        act = not act
        B.Text = name .. (act and ": ON" or ": OFF")
        B.TextColor3 = act and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(150, 150, 150)
        callback(act)
    end)
end

-- Кнопки
AddToggle("Silent Aim", function(v) _G.SilentAim = v end)
AddToggle("Wallbang (Mountains)", function(v) _G.Wallbang = v end)
AddToggle("Chams (Wallhack)", function(v) _G.ChamsEnabled = v end)
AddToggle("Head Hitbox", function(v) _G.HitboxEnabled = v end)
AddToggle("Long Neck", function(v) _G.LongNeck = v end)
AddToggle("Speed Bypass", function(v) _G.SpeedBypass = v end)
AddToggle("ESP Items/Totems", function(v) _G.ESP_Items = v; _G.ESP_Totems = v end)

-- Мобильные кнопки управления
local Rml = Instance.new("TextButton", ScreenGui)
Rml.Size = UDim2.new(0, 45, 0, 45)
Rml.Position = UDim2.new(0, 10, 0.4, 0)
Rml.Text = "RML"
Rml.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
Instance.new("UICorner", Rml).CornerRadius = UDim.new(1, 0)
Rml.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

local Slide = Instance.new("TextButton", ScreenGui)
Slide.Size = UDim2.new(0, 60, 0, 60)
Slide.Position = UDim2.new(0.85, -30, 0.5, -30)
Slide.Text = "SLIDE"
Slide.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Slide.TextColor3 = Color3.fromRGB(0, 255, 255)
Instance.new("UICorner", Slide).CornerRadius = UDim.new(1, 0)

-- ==========================================
-- [ ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ ]
-- ==========================================

RunService.RenderStepped:Connect(function()
    -- FOV & Lines
    local t = GetTarget()
    FOVCircle.Visible = _G.FOV_Visible
    FOVCircle.Radius = _G.FOV_Radius
    FOVCircle.Position = UIS:GetMouseLocation()

    if t and _G.SilentAim then
        local tPos = Camera:WorldToViewportPoint(t.Position)
        TargetLine.Visible = true
        TargetLine.From = UIS:GetMouseLocation()
        TargetLine.To = Vector2.new(tPos.X, tPos.Y)
    else
        TargetLine.Visible = false
    end

    -- Chams & Hitboxes
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= Player and p.Character then
            -- Chams
            if _G.ChamsEnabled then
                if not p.Character:FindFirstChild("Highlight") then
                    Instance.new("Highlight", p.Character).FillColor = Color3.fromRGB(0, 255, 255)
                end
            elseif p.Character:FindFirstChild("Highlight") then
                p.Character.Highlight:Destroy()
            end
            -- Hitbox
            if _G.HitboxEnabled and p.Character:FindFirstChild("Head") then
                p.Character.Head.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                p.Character.Head.Transparency = 0.5
                p.Character.Head.CanCollide = false
            end
        end
    end

    -- Speed Bypass (Translate Method)
    if _G.SpeedBypass and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        local hum = Player.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 then
            Player.Character:TranslateBy(hum.MoveDirection * (_G.SpeedValue / 100))
        end
    end

    -- Long Neck
    if Player.Character and Player.Character:FindFirstChild("Neck", true) then
        local neck = Player.Character:FindFirstChild("Neck", true)
        neck.C0 = _G.LongNeck and CFrame.new(0, 1.2, 0) * CFrame.new(0, 10, 0) or CFrame.new(0, 1.2, 0)
    end
end)

-- Slide Button Logic
Slide.MouseButton1Click:Connect(function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Player.Character.HumanoidRootPart
        local v = Instance.new("BodyVelocity", hrp)
        v.MaxForce = Vector3.new(1e5, 0, 1e5)
        v.Velocity = hrp.CFrame.LookVector * 120
        game.Debris:AddItem(v, 0.3)
    end
end)

-- ESP World Items
task.spawn(function()
    while task.wait(5) do
        if _G.ESP_Items or _G.ESP_Totems then
            for _, obj in pairs(workspace:GetChildren()) do
                if (_G.ESP_Totems and obj.Name:find("Totem")) or (_G.ESP_Items and obj.Name:find("Gun")) then
                    if not obj:FindFirstChild("Highlight") then
                        Instance.new("Highlight", obj).FillColor = Color3.fromRGB(255, 0, 0)
                    end
                end
            end
        end
    end
end)
