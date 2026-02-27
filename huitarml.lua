--[[
    huita.rml | TRIDENT SURVIVAL V5 PRIVATE
    Features: Silent Aim, AutoShot, World ESP, Bypasses, Configs
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "huita.rml | TRIDENT V5", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "huita_configs",
    IntroText = "Elite Bypass Loading..."
})

-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
_G.SilentAim = false
_G.AutoShot = false
_G.FOV_Visible = false
_G.FOV_Radius = 100
_G.HitboxEnabled = false
_G.HitboxValue = 2
_G.ESP_Players = false
_G.ESP_Bots = false
_G.ESP_Items = false
_G.ESP_Totems = false
_G.SpeedHackEnabled = false
_G.WalkSpeedValue = 16
_G.JumpPowerValue = 50
_G.SlideCooldown = false

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ОТРИСОВКА FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Color = Color3.fromRGB(0, 255, 255)

-- ФУНКЦИЯ ПОИСКА ЦЕЛИ
local function GetTarget()
    local closestTarget = nil
    local maxDist = _G.FOV_Radius

    -- Поиск игроков
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= Player and v.Character and v.Character:FindFirstChild("Head") then
            local pos, onScreen = Camera:WorldToViewportPoint(v.Character.Head.Position)
            if onScreen then
                local mousePos = UIS:GetMouseLocation()
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < maxDist then
                    closestTarget = v.Character.Head
                    maxDist = dist
                end
            end
        end
    end

    -- Поиск ботов (NPC)
    if _G.ESP_Bots then
        for _, v in pairs(workspace:GetChildren()) do
            if v:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(v) then
                local head = v:FindFirstChild("Head") or v:FindFirstChild("UpperTorso")
                if head then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                        if dist < maxDist then
                            closestTarget = head
                            maxDist = dist
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- [ METAMETHOD BYPASS SYSTEM ]
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

-- Silent Aim Bypass
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if _G.SilentAim and (method == "Raycast" or method == "FindPartOnRayWithIgnoreList") then
        local target = GetTarget()
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

-- Speed/Jump Bypass
mt.__index = newcclosure(function(t, k)
    if not checkcaller() and Player.Character and t == Player.Character:FindFirstChild("Humanoid") then
        if k == "WalkSpeed" then return 16 end
        if k == "JumpPower" then return 50 end
    end
    return oldIndex(t, k)
end)
setreadonly(mt, true)

-- [ WORLD ESP FUNCTIONS ]
local function CreateLabel(obj, text, color)
    local label = Drawing.new("Text")
    label.Visible = false
    label.Center = true
    label.Outline = true
    label.Size = 14
    label.Color = color
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if obj and obj.Parent then
            local pos, vis = Camera:WorldToViewportPoint(obj.Position)
            if vis then
                label.Position = Vector2.new(pos.X, pos.Y)
                label.Text = text .. " [" .. math.floor((obj.Position - Camera.CFrame.Position).Magnitude) .. "m]"
                label.Visible = true
            else label.Visible = false end
        else
            label:Remove()
            conn:Disconnect()
        end
    end)
end

-- Сканирование карты
task.spawn(function()
    while task.wait(3) do
        if _G.ESP_Items or _G.ESP_Totems then
            for _, v in pairs(workspace:GetChildren()) do
                if _G.ESP_Totems and v.Name:find("Totem") then
                    CreateLabel(v, "TOTEM", Color3.fromRGB(255, 255, 0))
                elseif _G.ESP_Items and (v.Name:find("Axe") or v.Name:find("Gun") or v.Name:find("Armor")) then
                    CreateLabel(v, v.Name, Color3.fromRGB(0, 255, 255))
                end
            end
        end
    end
end)

-- [ UI TABS ]
local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483345998"})
local VisualTab = Window:MakeTab({Name = "Visual", Icon = "rbxassetid://4483345998"})
local MiscTab = Window:MakeTab({Name = "Misc", Icon = "rbxassetid://4483345998"})
local ConfigTab = Window:MakeTab({Name = "Config", Icon = "rbxassetid://4483345998"})

-- Combat Settings
CombatTab:AddToggle({Name = "Perfect Silent Aim", Default = false, Flag = "sa_t", Callback = function(v) _G.SilentAim = v end})
CombatTab:AddToggle({Name = "Auto Shot", Default = false, Flag = "as_t", Callback = function(v) _G.AutoShot = v end})
CombatTab:AddToggle({Name = "Show FOV", Default = false, Flag = "fov_v", Callback = function(v) _G.FOV_Visible = v end})
CombatTab:AddSlider({Name = "FOV Radius", Min = 30, Max = 600, Default = 100, Flag = "fov_r", Callback = function(v) _G.FOV_Radius = v end})

-- Visual Settings
VisualTab:AddToggle({Name = "Players ESP", Default = false, Flag = "esp_p", Callback = function(v) _G.ESP_Players = v end})
VisualTab:AddToggle({Name = "Bots (NPC) ESP", Default = false, Flag = "esp_b", Callback = function(v) _G.ESP_Bots = v end})
VisualTab:AddToggle({Name = "Items (Guns/Armor) ESP", Default = false, Flag = "esp_i", Callback = function(v) _G.ESP_Items = v end})
VisualTab:AddToggle({Name = "Totems ESP", Default = false, Flag = "esp_t", Callback = function(v) _G.ESP_Totems = v end})

-- Misc Settings
MiscTab:AddToggle({Name = "Speed/Jump Bypass", Default = false, Flag = "sh_e", Callback = function(v) _G.SpeedHackEnabled = v end})
MiscTab:AddSlider({Name = "Speed", Min = 16, Max = 120, Default = 16, Flag = "ws_v", Callback = function(v) _G.WalkSpeedValue = v end})
MiscTab:AddSlider({Name = "Jump Power", Min = 50, Max = 200, Default = 50, Flag = "jp_v", Callback = function(v) _G.JumpPowerValue = v end})

-- [ LOGIC LOOPS ]
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = _G.FOV_Visible
    FOVCircle.Radius = _G.FOV_Radius
    FOVCircle.Position = UIS:GetMouseLocation()

    if _G.SilentAim and _G.AutoShot then
        if GetTarget() then mouse1click() end
    end

    if _G.SpeedHackEnabled and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
        Player.Character.Humanoid.JumpPower = _G.JumpPowerValue
    end
end)

-- Slide Mechanics
local function DoSlide()
    if _G.SpeedHackEnabled and not _G.SlideCooldown then
        _G.SlideCooldown = true
        local hrp = Player.Character.HumanoidRootPart
        Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        hrp.Velocity = hrp.CFrame.LookVector * (_G.WalkSpeedValue * 2.3)
        Player.Character.Humanoid.PlatformStand = true
        task.wait(0.4)
        Player.Character.Humanoid.PlatformStand = false
        task.wait(0.2)
        _G.SlideCooldown = false
    end
end

-- Keybinds
UIS.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        local main = game:GetService("CoreGui").Orion.Main
        main.Visible = not main.Visible
    elseif i.KeyCode == Enum.KeyCode.C then
        DoSlide()
    end
end)

-- Mobile Button
if UIS.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    local SlideBtn = Instance.new("TextButton", ScreenGui)
    SlideBtn.Size = UDim2.new(0, 80, 0, 80)
    SlideBtn.Position = UDim2.new(0.85, -40, 0.5, -40)
    SlideBtn.Text = "SLIDE"
    SlideBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SlideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    local Corner = Instance.new("UICorner", SlideBtn)
    Corner.CornerRadius = UDim.new(0, 50)
    SlideBtn.MouseButton1Click:Connect(DoSlide)
end

-- [ CONFIG SYSTEM ]
local function UpdateConfigs()
    if not isfolder("huita_configs") then makefolder("huita_configs") end
    local files = {}
    for _, v in pairs(listfiles("huita_configs")) do table.insert(files, v:split("\\")[2]) end
    return files
end

local ConfigDropdown = ConfigTab:AddDropdown({Name = "Configs", Options = UpdateConfigs(), Callback = function(v) _G.SelectedConfig = v end})
ConfigTab:AddButton({Name = "Refresh List", Callback = function() ConfigDropdown:Refresh(UpdateConfigs(), true) end})
ConfigTab:AddButton({Name = "Save Current", Callback = function() OrionLib:SaveConfig() ConfigDropdown:Refresh(UpdateConfigs(), true) end})
ConfigTab:AddButton({Name = "Load Selected", Callback = function() if _G.SelectedConfig then OrionLib:LoadConfig(_G.SelectedConfig) end end})

OrionLib:Init()

