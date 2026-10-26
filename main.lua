-- Prison Life Script (Clean Version)
-- Dibuat biar bisa dikontrol sendiri

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==================== SETTINGS ====================
local Settings = {
    Aimbot = false,
    SilentAim = true,
    AutoShoot = false,
    Noclip = false,
    Speed = false,
    Jump = false,
    Invisible = false,
    ESP = true,
    Fly = false,
    GodMode = false,

    -- Nilai
    WalkSpeed = 55,
    JumpPower = 90,
    AimbotFOV = 180,
    AimbotSmooth = 0.18,
    TeamCheck = true,
    FlySpeed = 60,
}
getgenv().Settings = Settings

-- Variables
local Holding = false
local Target = nil
local BodyVelocity, BodyGyro = nil, nil
local Flying = false
local OriginalTransparency = {}
local OriginalCanCollide = {}
local ESPObjects = {}

-- Hapus GUI lama kalau ada
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("PrisonLifeClean")
    if old then old:Destroy() end
end)

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrisonLifeClean"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 190, 0, 420)
Main.Position = UDim2.new(0, 15, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "Prison Life | Clean"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local function MakeToggle(text, key, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 27)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = text .. (Settings[key] and ": ON" or ": OFF")
    btn.TextColor3 = Settings[key] and Color3.fromRGB(70, 255, 70) or Color3.fromRGB(255, 70, 70)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = text .. (Settings[key] and ": ON" or ": OFF")
        btn.TextColor3 = Settings[key] and Color3.fromRGB(70, 255, 70) or Color3.fromRGB(255, 70, 70)
    end)
end

MakeToggle("Aimbot", "Aimbot", 40)
MakeToggle("Silent Aim", "SilentAim", 72)
MakeToggle("Auto Shoot", "AutoShoot", 104)
MakeToggle("Noclip", "Noclip", 136)
MakeToggle("Speed", "Speed", 168)
MakeToggle("Jump Tinggi", "Jump", 200)
MakeToggle("Invisible", "Invisible", 232)
MakeToggle("ESP", "ESP", 264)
MakeToggle("Fly", "Fly", 296)
MakeToggle("God Mode", "GodMode", 328)

-- ==================== TOMBOL FLY (HP) ====================
local FlyUp = Instance.new("TextButton")
FlyUp.Size = UDim2.new(0, 58, 0, 58)
FlyUp.Position = UDim2.new(1, -75, 0.5, -70)
FlyUp.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FlyUp.Text = "↑"
FlyUp.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyUp.Font = Enum.Font.GothamBold
FlyUp.TextSize = 22
FlyUp.Visible = false
FlyUp.Parent = ScreenGui
Instance.new("UICorner", FlyUp).CornerRadius = UDim.new(0, 12)

local FlyDown = Instance.new("TextButton")
FlyDown.Size = UDim2.new(0, 58, 0, 58)
FlyDown.Position = UDim2.new(1, -75, 0.5, 5)
FlyDown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FlyDown.Text = "↓"
FlyDown.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyDown.Font = Enum.Font.GothamBold
FlyDown.TextSize = 22
FlyDown.Visible = false
FlyDown.Parent = ScreenGui
Instance.new("UICorner", FlyDown).CornerRadius = UDim.new(0, 12)

local FlyHoldingUp, FlyHoldingDown = false, false
FlyUp.MouseButton1Down:Connect(function() FlyHoldingUp = true end)
FlyUp.MouseButton1Up:Connect(function() FlyHoldingUp = false end)
FlyDown.MouseButton1Down:Connect(function() FlyHoldingDown = true end)
FlyDown.MouseButton1Up:Connect(function() FlyHoldingDown = false end)

-- ==================== SILENT AIM ====================
pcall(function()
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__index = newcclosure(function(self, key)
        if Settings.SilentAim and Target and Target.Character and Target.Character:FindFirstChild("Head") then
            if self == Mouse then
                if key == "Hit" then
                    return Target.Character.Head.CFrame
                elseif key == "Target" then
                    return Target.Character.Head
                end
            end
        end
        return oldIndex(self, key)
    end)
end)

-- ==================== CARI TARGET ====================
local function GetClosest()
    local closest, dist = nil, Settings.AimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not (Settings.TeamCheck and plr.Team == LocalPlayer.Team) then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if d < dist then
                            closest = plr
                            dist = d
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ==================== ESP ====================
local function ClearESP(plr)
    if ESPObjects[plr] then
        for _, obj in pairs(ESPObjects[plr]) do
            pcall(function() obj:Destroy() end)
        end
        ESPObjects[plr] = nil
    end
end

local function CreateESP(plr)
    if plr == LocalPlayer then return end
    ClearESP(plr)

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 40, 40)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.55
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 130, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = billboard

    ESPObjects[plr] = {highlight = highlight, billboard = billboard, label = label}
end

RunService.RenderStepped:Connect(function()
    if not Settings.ESP then
        for _, data in pairs(ESPObjects) do
            if data.highlight then data.highlight.Adornee = nil end
            if data.billboard then data.billboard.Adornee = nil end
        end
        return
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer then
            if not ESPObjects[plr] then
                CreateESP(plr)
            end

            local data = ESPObjects[plr]
            if data and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                data.highlight.Adornee = plr.Character
                data.highlight.Parent = plr.Character
                data.billboard.Adornee = plr.Character.HumanoidRootPart
                data.billboard.Parent = plr.Character.HumanoidRootPart
                data.label.Text = plr.Name .. " | " .. math.floor(plr.Character.Humanoid.Health)

                if Settings.TeamCheck and plr.Team == LocalPlayer.Team then
                    data.highlight.FillColor = Color3.fromRGB(40, 255, 40)
                else
                    data.highlight.FillColor = Color3.fromRGB(255, 40, 40)
                end
            else
                if data then
                    data.highlight.Adornee = nil
                    data.billboard.Adornee = nil
                end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    if Settings.ESP then CreateESP(plr) end
end)
Players.PlayerRemoving:Connect(ClearESP)

-- ==================== FLY ====================
local function StartFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local root = char.HumanoidRootPart
    local hum = char.Humanoid

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.Parent = root

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.P = 3000
    BodyGyro.Parent = root

    hum.PlatformStand = true
    Flying = true
    FlyUp.Visible = true
    FlyDown.Visible = true
end

local function StopFly()
    if BodyVelocity then pcall(function() BodyVelocity:Destroy() end) end
    if BodyGyro then pcall(function() BodyGyro:Destroy() end) end
    BodyVelocity, BodyGyro = nil, nil

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
    Flying = false
    FlyUp.Visible = false
    FlyDown.Visible = false
end

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    Target = GetClosest()

    -- Aimbot
    if Settings.Aimbot and Holding and Target and Target.Character and Target.Character:FindFirstChild("Head") then
        local head = Target.Character.Head
        local screenPos = Camera:WorldToViewportPoint(head.Position)
        pcall(function()
            mousemoverel(
                (screenPos.X - Mouse.X) * Settings.AimbotSmooth,
                (screenPos.Y - Mouse.Y) * Settings.AimbotSmooth
            )
        end)
    end

    -- Fly
    if Settings.Fly then
        if not Flying then StartFly() end

        if BodyVelocity and BodyGyro and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dir = Vector3.zero
            local camCF = Camera.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
            if FlyHoldingUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if FlyHoldingDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir + Vector3.new(0, -1, 0) end

            if dir.Magnitude > 0 then
                BodyVelocity.Velocity = dir.Unit * Settings.FlySpeed
            else
                BodyVelocity.Velocity = Vector3.zero
            end
            BodyGyro.CFrame = camCF
        end
    else
        if Flying then StopFly() end
    end
end)

-- Character properties
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end

    local hum = char.Humanoid
    local root = char:FindFirstChild("HumanoidRootPart")

    -- Speed & Jump
    hum.WalkSpeed = Settings.Speed and Settings.WalkSpeed or 16
    hum.JumpPower = Settings.Jump and Settings.JumpPower or 50

    -- God Mode
    if Settings.GodMode then
        hum.Health = hum.MaxHealth
        if not char:FindFirstChildOfClass("ForceField") then
            local ff = Instance.new("ForceField")
            ff.Visible = false
            ff.Parent = char
        end
    else
        local ff = char:FindFirstChildOfClass("ForceField")
        if ff then ff:Destroy() end
    end

    -- Noclip
    if root then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if Settings.Noclip then
                    if OriginalCanCollide[part] == nil then
                        OriginalCanCollide[part] = part.CanCollide
                    end
                    part.CanCollide = false
                else
                    if OriginalCanCollide[part] \~= nil then
                        part.CanCollide = OriginalCanCollide[part]
                        OriginalCanCollide[part] = nil
                    end
                end
            end
        end
    end

    -- Invisible
    if Settings.Invisible then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") then
                if OriginalTransparency[v] == nil then
                    OriginalTransparency[v] = v.Transparency
                end
                v.Transparency = 1
            end
        end
    else
        for v, trans in pairs(OriginalTransparency) do
            if v and v.Parent then
                v.Transparency = trans
            end
        end
        OriginalTransparency = {}
    end
end)

-- Input
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
        Holding = false
    end
end)

-- Auto Shoot
task.spawn(function()
    while true do
        task.wait(0.09)
        if Settings.AutoShoot and Holding and Target then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
            end
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.03)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

-- Saat respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.8)
    OriginalTransparency = {}
    OriginalCanCollide = {}
    if Settings.Fly then
        StopFly()
        task.wait(0.2)
        StartFly()
    end
    if Settings.ESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr \~= LocalPlayer then CreateESP(plr) end
        end
    end
end)

-- Init ESP
for _, plr in pairs(Players:GetPlayers()) do
    if plr \~= LocalPlayer then CreateESP(plr) end
end

print("✅ Prison Life Clean Script Loaded")
