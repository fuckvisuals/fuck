
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")

local player = Players.LocalPlayer
local speed = 16
local fov = 70

local function applySpeed(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = speed
end

player.CharacterAdded:Connect(applySpeed)

if player.Character then
    task.spawn(applySpeed, player.Character)
end

local function applyFOV()
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = fov
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyFOV)

local gui = Instance.new("ScreenGui")
gui.Name = "NoxerVisuals"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(340, 260)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
main.BackgroundTransparency = 0.12
main.Active = true
main.Draggable = true

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(150, 170, 200)
stroke.Transparency = 0.65

local function label(text, x, y, w, h, size)
    local l = Instance.new("TextLabel", main)
    l.Position = UDim2.fromOffset(x, y)
    l.Size = UDim2.fromOffset(w, h)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.Font = Enum.Font.GothamMedium
    l.TextColor3 = Color3.fromRGB(240, 240, 250)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

label("NOXER / VISUALS", 20, 12, 300, 30, 19)
label("MOVEMENT & CAMERA", 20, 43, 300, 20, 11)

local function slider(name, y, min, max, default, callback)
    label(name, 20, y, 220, 24, 14)
    local value = label(tostring(default), 280, y, 45, 24, 14)

    local bar = Instance.new("TextButton", main)
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Position = UDim2.fromOffset(20, y + 32)
    bar.Size = UDim2.fromOffset(300, 8)
    bar.BackgroundColor3 = Color3.fromRGB(53, 58, 70)

    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = Color3.fromRGB(130, 175, 255)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function set(v)
        v = math.clamp(math.round(v), min, max)
        value.Text = tostring(v)

        Tween:Create(fill, TweenInfo.new(0.08), {
            Size = UDim2.fromScale((v-min)/(max-min), 1)
        }):Play()

        callback(v)
    end

    local function update(x)
        local percent = math.clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0, 1
        )
        set(min + (max-min)*percent)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    set(default)
    return set
end

local setSpeed = slider("WalkSpeed", 76, 16, 100, 16, function(v)
    speed = v

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = speed
    end
end)

local setFOV = slider("Field of View", 137, 70, 120, 70, function(v)
    fov = v
    applyFOV()
end)

local reset = Instance.new("TextButton", main)
reset.Position = UDim2.fromOffset(20, 199)
reset.Size = UDim2.fromOffset(300, 32)
reset.Text = "Reset Settings"
reset.Font = Enum.Font.GothamMedium
reset.TextSize = 13
reset.TextColor3 = Color3.fromRGB(230, 235, 255)
reset.BackgroundColor3 = Color3.fromRGB(43, 48, 60)

Instance.new("UICorner", reset).CornerRadius = UDim.new(0, 9)

reset.MouseButton1Click:Connect(function()
    setSpeed(16)
    setFOV(70)
end)

label("RIGHT SHIFT  •  RESPAWN PERSISTENCE", 20, 237, 300, 15, 10)

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)
