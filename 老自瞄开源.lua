local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/951357nvjn/dyzs/refs/heads/main/winduiYI.lua"))()
WindUI.Transparency = 0.3
WindUI:SetTheme("Dark")

function gradient(text, startColor, endColor)
    local result = ""
    local chars = {}
    for uchar in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, uchar)
    end
    local length = #chars
    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = startColor.R + (endColor.R - startColor.R) * t
        local g = startColor.G + (endColor.G - startColor.G) * t
        local b = startColor.B + (endColor.B - startColor.B) * t
        result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>',
            math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), chars[i])
    end
    return result
end

local Window = WindUI:CreateWindow({
    Icon = "moon",
    Title = gradient("YI_自瞄透视", Color3.fromHex("#00CCFF"), Color3.fromHex("#66E0FF")),
    Author = gradient("@灰", Color3.fromHex("#00CCFF"), Color3.fromHex("#66E0FF")),
    Folder = "YI_HUB",
    Size = UDim2.fromOffset(520, 410),
    Background = "https://raw.githubusercontent.com/951357nvjn/dyzs/6b5682604a4f2199446368c2107401aea3b0ef72/Screenshot_2026_0227_141347.png",
    BackgroundImageTransparency = 0.25,
    Theme = "Dark",
    User = {Enabled = false},
    SideBarWidth = 160,
    ScrollBarEnabled = true
})

local buttonConfig = {
    Title = gradient("YI_HUB", Color3.fromHex("#00CCFF"), Color3.fromHex("#66E0FF")),
    Icon = "moon",
    StrokeThickness = 2,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#66E0FF")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("#00CCFF")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#0099CC"))
    }),
    Draggable = true,
}
Window:EditOpenButton(buttonConfig)

local windowFrame = Window and (Window.UIElements and Window.UIElements.Main or Window.Frame or Window.Gui or Window)
if windowFrame then
    local stroke = Instance.new("UIStroke")
    stroke.Name = "RainbowStroke"
    stroke.Thickness = 2
    stroke.Color = Color3.new(1, 1, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local grad = Instance.new("UIGradient")
    grad.Name = "RainbowGradient"
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHex("#66E0FF")),
        ColorSequenceKeypoint.new(0.3, Color3.fromHex("#00CCFF")),
        ColorSequenceKeypoint.new(0.7, Color3.fromHex("#0099CC")),
        ColorSequenceKeypoint.new(1, Color3.fromHex("#0066CC"))
    })
    grad.Enabled = true
    grad.Offset = Vector2.new(0, 0)
    grad.Parent = stroke
    stroke.Parent = windowFrame

    task.spawn(function()
        local rotationSpeed = 40
        while stroke and stroke.Parent do
            task.wait(0.01)
            grad.Rotation = (grad.Rotation + rotationSpeed * 0.1) % 360
        end
    end)
end

local MainSection = Window:Section({ Title = "功能菜单", Opened = true })
local Tabs = {
    Aimbot = MainSection:Tab({ Title = "自瞄", Icon = "target" }),
    ESP = MainSection:Tab({ Title = "透视", Icon = "eye" })
}

local aimbot = Tabs.Aimbot
local AimbotSettings = {
    Enabled = false,
    TargetPart = "Head",
    TeamCheck = false,
    WallCheck = false,
    CircleEnabled = false,
    CircleRadius = 100,
    CircleThickness = 2,
    CircleColor = "彩色"
}

local Colors = {
    ["红"] = Color3.fromRGB(255,0,0), ["橙"] = Color3.fromRGB(255,150,0), ["黄"] = Color3.fromRGB(255,255,15),
    ["绿"] = Color3.fromRGB(0,255,0), ["青"] = Color3.fromRGB(0,255,219), ["蓝"] = Color3.fromRGB(0,0,255),
    ["紫"] = Color3.fromRGB(183,0,255), ["彩色"] = nil,
}

local Circle = Drawing.new("Circle")
Circle.Filled = false
Circle.Visible = false

local function getCircleColor()
    if AimbotSettings.CircleColor ~= "彩色" and Colors[AimbotSettings.CircleColor] then
        return Colors[AimbotSettings.CircleColor]
    else
        return Color3.fromHSV((tick() % 5) / 5, 1, 1)
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if AimbotSettings.CircleEnabled then
        Circle.Visible = true
        Circle.Position = workspace.CurrentCamera.ViewportSize / 2
        Circle.Radius = AimbotSettings.CircleRadius
        Circle.Thickness = AimbotSettings.CircleThickness
        Circle.Color = getCircleColor()
    else
        Circle.Visible = false
    end
end)

local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if AimbotSettings.TeamCheck and player.Team == LocalPlayer.Team then return false end
    local part = player.Character:FindFirstChild(AimbotSettings.TargetPart)
    if not part then return false end
    if AimbotSettings.WallCheck then
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character, player.Character}
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, params)
        if result and result.Instance ~= part then return false end
    end
    return true
end

local function getClosestInCircle()
    local closest = nil
    local minDist = math.huge
    local center = Camera.ViewportSize / 2
    for _, p in pairs(game.Players:GetPlayers()) do
        if isValidTarget(p) then
            local head = p.Character:FindFirstChild(AimbotSettings.TargetPart)
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if screenDist <= AimbotSettings.CircleRadius and screenDist < minDist then
                        minDist = screenDist
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

game:GetService("RunService").Heartbeat:Connect(function()
    if AimbotSettings.Enabled then
        local target = getClosestInCircle()
        if target then
            local part = target.Character:FindFirstChild(AimbotSettings.TargetPart)
            if part then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            end
        end
    end
end)

aimbot:Toggle({ Title = "开启自瞄", Value = false, Callback = function(s) AimbotSettings.Enabled = s end })
aimbot:Toggle({ Title = "自瞄圆圈", Value = false, Callback = function(s) AimbotSettings.CircleEnabled = s end })
aimbot:Dropdown({ Title = "瞄准部位", Values = { "Head", "HumanoidRootPart" }, Value = "Head", Callback = function(v) AimbotSettings.TargetPart = v end })
aimbot:Toggle({ Title = "队伍验证", Value = false, Callback = function(s) AimbotSettings.TeamCheck = s end })
aimbot:Toggle({ Title = "墙体检测", Value = false, Callback = function(s) AimbotSettings.WallCheck = s end })
aimbot:Slider({ Title = "圆圈大小", Value = { Min = 30, Max = 500, Default = 100 }, Callback = function(v) AimbotSettings.CircleRadius = v end })
aimbot:Slider({ Title = "圆圈厚度", Value = { Min = 1, Max = 10, Default = 2 }, Callback = function(v) AimbotSettings.CircleThickness = v end })
aimbot:Dropdown({ Title = "圆圈颜色", Values = { "红", "橙", "黄", "绿", "青", "蓝", "紫", "彩色" }, Value = "彩色", Callback = function(v) AimbotSettings.CircleColor = v end })

local Workspace, RunService, Players, CoreGui = cloneref and cloneref(game:GetService("Workspace")) or game:GetService("Workspace"),
    cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService"),
    cloneref and cloneref(game:GetService("Players")) or game:GetService("Players"),
    game:GetService("CoreGui")

local ESP = {
    Enabled = false, TeamCheck = true, MaxDistance = 2000, FontSize = 11,
    FadeOut = { OnDistance = true, OnDeath = false, OnLeave = false },
    Options = { Teamcheck = true, TeamcheckRGB = Color3.fromRGB(119, 120, 255), Friendcheck = true, FriendcheckRGB = Color3.fromRGB(119, 120, 255), Highlight = true, HighlightRGB = Color3.fromRGB(119, 120, 255) },
    Drawing = {
        Chams = { Enabled = false, Thermal = false, FillRGB = Color3.fromRGB(119, 120, 255), Fill_Transparency = 100, OutlineRGB = Color3.fromRGB(119, 120, 255), Outline_Transparency = 0, VisibleCheck = true },
        Names = { Enabled = false, RGB = Color3.fromRGB(255, 255, 255) },
        Flags = { Enabled = false },
        Distances = { Enabled = false, Position = "Text", RGB = Color3.fromRGB(255, 255, 255) },
        Weapons = { Enabled = false, WeaponTextRGB = Color3.fromRGB(119, 120, 255), Outlined = false, Gradient = false, GradientRGB1 = Color3.fromRGB(255, 255, 255), GradientRGB2 = Color3.fromRGB(119, 120, 255) },
        Healthbar = { Enabled = false, HealthText = true, Lerp = false, HealthTextRGB = Color3.fromRGB(255, 255, 255), Width = 1.25, Gradient = false, GradientRGB1 = Color3.fromRGB(200, 0, 0), GradientRGB2 = Color3.fromRGB(60, 60, 125), GradientRGB3 = Color3.fromRGB(119, 120, 255) },
        Boxes = { Animate = true, RotationSpeed = 300, Gradient = true, GradientRGB1 = Color3.fromRGB(140, 180, 255), GradientRGB2 = Color3.fromRGB(180, 120, 255), GradientFill = false, GradientFillRGB1 = Color3.fromRGB(119, 120, 255), GradientFillRGB2 = Color3.fromRGB(0,0,0), Filled = { Enabled = false, Transparency = 0.75, RGB = Color3.fromRGB(119, 120, 255) }, Full = { Enabled = false, RGB = Color3.fromRGB(255,255,255) }, Corner = { Enabled = false, RGB = Color3.fromRGB(255,255,255) } }
    },
    Connections = { RunService = RunService },
    Fonts = {}
}

local lplayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local Cam = Workspace.CurrentCamera
local RotationAngle, Tick = -45, tick()

local Functions = {}
do
    function Functions:Create(Class, Properties)
        local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
        for Property, Value in pairs(Properties) do _Instance[Property] = Value end
        return _Instance
    end
    function Functions:FadeOutOnDist(element, distance)
        local transparency = math.max(0.1, 1 - (distance / ESP.MaxDistance))
        if element:IsA("TextLabel") then element.TextTransparency = 1 - transparency
        elseif element:IsA("ImageLabel") then element.ImageTransparency = 1 - transparency
        elseif element:IsA("UIStroke") then element.Transparency = 1 - transparency
        elseif element:IsA("Frame") then element.BackgroundTransparency = 1 - transparency
        elseif element:IsA("Highlight") then element.FillTransparency = 1; element.OutlineTransparency = 1 - transparency end
    end
    function Functions:GetRainbow()
        local t = tick() * 1.5
        local r = 0.7 + 0.3 * math.sin(t * 2 + 0)
        local g = 0.7 + 0.3 * math.sin(t * 2 + 2)
        local b = 0.9 + 0.1 * math.sin(t * 2 + 4)
        return Color3.new(r, g, b)
    end
end

local ScreenGui = Functions:Create("ScreenGui", { Parent = CoreGui, Name = "ESPHolder" })

local function DupeCheck(plr)
    if ScreenGui:FindFirstChild(plr.Name) then ScreenGui[plr.Name]:Destroy() end
end

local function ESPRender(plr)
    coroutine.wrap(DupeCheck)(plr)
    local Name = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, -11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
    local Distance = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
    local Weapon = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
    local Box = Functions:Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, BorderSizePixel = 0})
    local Outline = Functions:Create("UIStroke", {Parent = Box, Enabled = true, Transparency = 0, Color = Color3.fromRGB(255,255,255), Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter})
    local Gradient2 = Functions:Create("UIGradient", {Parent = Outline, Enabled = true, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 180, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 120, 255))})})
    local Healthbar = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0})
    local BehindHealthbar = Functions:Create("Frame", {Parent = ScreenGui, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0})
    local HealthbarGradient = Functions:Create("UIGradient", {Parent = Healthbar, Enabled = ESP.Drawing.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, ESP.Drawing.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, ESP.Drawing.Healthbar.GradientRGB3)}})
    local HealthText = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
    local Chams = Functions:Create("Highlight", {Parent = ScreenGui, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(255,255,255), DepthMode = "AlwaysOnTop"})
    local LeftTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local LeftSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local RightTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local RightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local BottomSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local BottomDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local BottomRightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local BottomRightDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, Position = UDim2.new(0, 0, 0, 0)})
    local Flag1 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
    local Flag2 = Functions:Create("TextLabel", {Parent = ScreenGui, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})

    local function UpdateESP()
        local Connection = RunService.RenderStepped:Connect(function()
            if not ESP.Enabled then
                Box.Visible = false; Name.Visible = false; Distance.Visible = false; Weapon.Visible = false
                Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                LeftTop.Visible = false; LeftSide.Visible = false; BottomSide.Visible = false; BottomDown.Visible = false
                RightTop.Visible = false; RightSide.Visible = false; BottomRightSide.Visible = false; BottomRightDown.Visible = false
                Flag1.Visible = false; Chams.Enabled = false; Flag2.Visible = false
                return
            end
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local HRP = plr.Character.HumanoidRootPart
                local Humanoid = plr.Character:WaitForChild("Humanoid")
                local Pos, OnScreen = Cam:WorldToScreenPoint(HRP.Position)
                local Dist = (Cam.CFrame.Position - HRP.Position).Magnitude / 3.5714285714
                if OnScreen and Dist <= ESP.MaxDistance then
                    local Size = HRP.Size.Y
                    local scaleFactor = (Size * Cam.ViewportSize.Y) / (Pos.Z * 2)
                    local w, h = 3 * scaleFactor, 4.5 * scaleFactor
                    local neon = Functions:GetRainbow()
                    if ESP.FadeOut.OnDistance then
                        Functions:FadeOutOnDist(Box, Dist); Functions:FadeOutOnDist(Outline, Dist); Functions:FadeOutOnDist(Name, Dist)
                        Functions:FadeOutOnDist(Distance, Dist); Functions:FadeOutOnDist(Weapon, Dist); Functions:FadeOutOnDist(Healthbar, Dist)
                        Functions:FadeOutOnDist(BehindHealthbar, Dist); Functions:FadeOutOnDist(HealthText, Dist); Functions:FadeOutOnDist(LeftTop, Dist)
                        Functions:FadeOutOnDist(LeftSide, Dist); Functions:FadeOutOnDist(BottomSide, Dist); Functions:FadeOutOnDist(BottomDown, Dist)
                        Functions:FadeOutOnDist(RightTop, Dist); Functions:FadeOutOnDist(RightSide, Dist); Functions:FadeOutOnDist(BottomRightSide, Dist)
                        Functions:FadeOutOnDist(BottomRightDown, Dist); Functions:FadeOutOnDist(Chams, Dist); Functions:FadeOutOnDist(Flag1, Dist)
                        Functions:FadeOutOnDist(Flag2, Dist)
                    end
                    if ESP.TeamCheck and plr ~= lplayer and ((lplayer.Team ~= plr.Team and plr.Team) or (not lplayer.Team and not plr.Team)) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                        Chams.Adornee = plr.Character
                        Chams.Enabled = ESP.Drawing.Chams.Enabled
                        Chams.FillTransparency = 1
                        Chams.OutlineColor = neon
                        Chams.OutlineTransparency = 0

                        local offset = 2
                        local lineThickness = 1
                        LeftTop.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        LeftTop.Position = UDim2.new(0, Pos.X - w/2 + offset, 0, Pos.Y - h/2 + offset)
                        LeftTop.Size = UDim2.new(0, w/5, 0, lineThickness)
                        LeftTop.BackgroundColor3 = neon
                        LeftSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        LeftSide.Position = UDim2.new(0, Pos.X - w/2 + offset, 0, Pos.Y - h/2 + offset)
                        LeftSide.Size = UDim2.new(0, lineThickness, 0, h/5)
                        LeftSide.BackgroundColor3 = neon
                        BottomSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        BottomSide.Position = UDim2.new(0, Pos.X - w/2 + offset, 0, Pos.Y + h/2 - offset)
                        BottomSide.Size = UDim2.new(0, lineThickness, 0, h/5)
                        BottomSide.AnchorPoint = Vector2.new(0,1)
                        BottomSide.BackgroundColor3 = neon
                        BottomDown.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        BottomDown.Position = UDim2.new(0, Pos.X - w/2 + offset, 0, Pos.Y + h/2 - offset)
                        BottomDown.Size = UDim2.new(0, w/5, 0, lineThickness)
                        BottomDown.AnchorPoint = Vector2.new(0,1)
                        BottomDown.BackgroundColor3 = neon
                        RightTop.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        RightTop.Position = UDim2.new(0, Pos.X + w/2 - offset, 0, Pos.Y - h/2 + offset)
                        RightTop.Size = UDim2.new(0, w/5, 0, lineThickness)
                        RightTop.AnchorPoint = Vector2.new(1,0)
                        RightTop.BackgroundColor3 = neon
                        RightSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        RightSide.Position = UDim2.new(0, Pos.X + w/2 - offset, 0, Pos.Y - h/2 + offset)
                        RightSide.Size = UDim2.new(0, lineThickness, 0, h/5)
                        RightSide.AnchorPoint = Vector2.new(1,0)
                        RightSide.BackgroundColor3 = neon
                        BottomRightSide.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        BottomRightSide.Position = UDim2.new(0, Pos.X + w/2 - offset, 0, Pos.Y + h/2 - offset)
                        BottomRightSide.Size = UDim2.new(0, lineThickness, 0, h/5)
                        BottomRightSide.AnchorPoint = Vector2.new(1,1)
                        BottomRightSide.BackgroundColor3 = neon
                        BottomRightDown.Visible = ESP.Drawing.Boxes.Corner.Enabled
                        BottomRightDown.Position = UDim2.new(0, Pos.X + w/2 - offset, 0, Pos.Y + h/2 - offset)
                        BottomRightDown.Size = UDim2.new(0, w/5, 0, lineThickness)
                        BottomRightDown.AnchorPoint = Vector2.new(1,1)
                        BottomRightDown.BackgroundColor3 = neon

                        Box.Position = UDim2.new(0, Pos.X - w/2, 0, Pos.Y - h/2)
                        Box.Size = UDim2.new(0, w, 0, h)
                        Box.Visible = ESP.Drawing.Boxes.Full.Enabled
                        Box.BackgroundTransparency = 1
                        Outline.Color = neon
                        RotationAngle = RotationAngle + (tick() - Tick) * ESP.Drawing.Boxes.RotationSpeed * math.cos(math.pi / 4 * tick() - math.pi / 2)
                        if ESP.Drawing.Boxes.Animate then Gradient2.Rotation = RotationAngle else Gradient2.Rotation = 0 end
                        Tick = tick()

                        local health = Humanoid.Health / Humanoid.MaxHealth
                        local healthBarSpacing = 4
                        local healthBarX = Pos.X - w/2 - ESP.Drawing.Healthbar.Width - healthBarSpacing
                        Healthbar.Visible = ESP.Drawing.Healthbar.Enabled
                        Healthbar.Position = UDim2.new(0, healthBarX, 0, Pos.Y - h/2 + h * (1 - health))
                        Healthbar.Size = UDim2.new(0, ESP.Drawing.Healthbar.Width, 0, h * health)
                        Healthbar.BackgroundColor3 = neon
                        HealthbarGradient.Enabled = false
                        BehindHealthbar.Visible = ESP.Drawing.Healthbar.Enabled
                        BehindHealthbar.Position = UDim2.new(0, healthBarX, 0, Pos.Y - h/2)
                        BehindHealthbar.Size = UDim2.new(0, ESP.Drawing.Healthbar.Width, 0, h)
                        if ESP.Drawing.Healthbar.HealthText then
                            local healthPercentage = math.floor(Humanoid.Health / Humanoid.MaxHealth * 100)
                            HealthText.Position = UDim2.new(0, healthBarX, 0, Pos.Y - h/2 + h * (1 - healthPercentage / 100) + 3)
                            HealthText.Text = tostring(healthPercentage)
                            HealthText.Visible = Humanoid.Health < Humanoid.MaxHealth
                            HealthText.TextColor3 = Color3.new(1,1,1)
                        end

                        Name.Visible = ESP.Drawing.Names.Enabled
                        Name.Text = plr.Name
                        Name.Position = UDim2.new(0, Pos.X, 0, Pos.Y - h/2 - 9)
                        Name.TextColor3 = Color3.new(1,1,1)

                        local bottomY = Pos.Y + h/2 + 10
                        Distance.Visible = ESP.Drawing.Distances.Enabled
                        if Distance.Visible then
                            Distance.Text = math.floor(Dist) .. "m"
                            Distance.Position = UDim2.new(0, Pos.X - 30, 0, bottomY)
                            Distance.TextColor3 = Color3.new(1,1,1)
                        end

                        Weapon.Visible = ESP.Drawing.Weapons.Enabled
                        if Weapon.Visible then
                            local tool = plr.Character:FindFirstChildOfClass("Tool")
                            Weapon.Text = tool and tool.Name or "none"
                            Weapon.Position = UDim2.new(0, Pos.X + 30, 0, bottomY)
                            Weapon.TextColor3 = Color3.new(1,1,1)
                        end
                    else
                        Box.Visible = false; Name.Visible = false; Distance.Visible = false; Weapon.Visible = false
                        Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                        LeftTop.Visible = false; LeftSide.Visible = false; BottomSide.Visible = false; BottomDown.Visible = false
                        RightTop.Visible = false; RightSide.Visible = false; BottomRightSide.Visible = false; BottomRightDown.Visible = false
                        Flag1.Visible = false; Chams.Enabled = false; Flag2.Visible = false
                    end
                else
                    Box.Visible = false; Name.Visible = false; Distance.Visible = false; Weapon.Visible = false
                    Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                    LeftTop.Visible = false; LeftSide.Visible = false; BottomSide.Visible = false; BottomDown.Visible = false
                    RightTop.Visible = false; RightSide.Visible = false; BottomRightSide.Visible = false; BottomRightDown.Visible = false
                    Flag1.Visible = false; Chams.Enabled = false; Flag2.Visible = false
                end
            else
                Box.Visible = false; Name.Visible = false; Distance.Visible = false; Weapon.Visible = false
                Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                LeftTop.Visible = false; LeftSide.Visible = false; BottomSide.Visible = false; BottomDown.Visible = false
                RightTop.Visible = false; RightSide.Visible = false; BottomRightSide.Visible = false; BottomRightDown.Visible = false
                Flag1.Visible = false; Chams.Enabled = false; Flag2.Visible = false
            end
        end)
    end
    UpdateESP()
end

for _, v in pairs(Players:GetPlayers()) do
    if v.Name ~= lplayer.Name then coroutine.wrap(ESPRender)(v) end
end
Players.PlayerAdded:Connect(function(v) coroutine.wrap(ESPRender)(v) end)

local espTab = Tabs.ESP
local espGroup = espTab:Section({ Title = "透视设置", Opened = true })

espGroup:Toggle({ Title = "ESP 总开关", Value = ESP.Enabled, Callback = function(s) ESP.Enabled = s end })
espGroup:Toggle({ Title = "队伍检测", Value = ESP.TeamCheck, Callback = function(s) ESP.TeamCheck = s end })
espGroup:Toggle({ Title = "名字显示", Value = ESP.Drawing.Names.Enabled, Callback = function(s) ESP.Drawing.Names.Enabled = s end })
espGroup:Toggle({ Title = "距离显示", Value = ESP.Drawing.Distances.Enabled, Callback = function(s) ESP.Drawing.Distances.Enabled = s end })
espGroup:Toggle({ Title = "武器显示", Value = ESP.Drawing.Weapons.Enabled, Callback = function(s) ESP.Drawing.Weapons.Enabled = s end })
espGroup:Toggle({ Title = "血量条", Value = ESP.Drawing.Healthbar.Enabled, Callback = function(s) ESP.Drawing.Healthbar.Enabled = s end })
espGroup:Toggle({ Title = "方框", Value = ESP.Drawing.Boxes.Full.Enabled, Callback = function(s) ESP.Drawing.Boxes.Full.Enabled = s end })
espGroup:Toggle({ Title = "角标", Value = ESP.Drawing.Boxes.Corner.Enabled, Callback = function(s) ESP.Drawing.Boxes.Corner.Enabled = s end })
espGroup:Toggle({ Title = "高亮描边", Value = ESP.Drawing.Chams.Enabled, Callback = function(s) ESP.Drawing.Chams.Enabled = s end })

WindUI:Notify({ Title = "欢迎", Content = "用户 " .. game.Players.LocalPlayer.Name .. " 已载入脚本", Duration = 4 })