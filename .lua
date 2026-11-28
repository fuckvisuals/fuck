--[[
	Liquid Glass Menu (iOS style)
	Тип: LocalScript
	Куда класть: StarterPlayer > StarterPlayerScripts

	Управление:
	  Ctrl (левый/правый) — открыть / закрыть меню
	  C                   — включить / выключить WalkSpeed
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

--------------------------------------------------------------------
-- НАСТРОЙКИ
--------------------------------------------------------------------
local CONFIG = {
	WalkKey = Enum.KeyCode.C,
	WalkMin = 16,
	WalkMax = 120,
	WalkDefaultValue = 40, -- скорость при включении

	FovMin = 40,
	FovMax = 120,
	FovDefaultValue = 90, -- FOV при включении

	Smoothness = 8, -- чем больше, тем быстрее переход
	BlurSize = 14,
}

--------------------------------------------------------------------
-- СОСТОЯНИЕ
--------------------------------------------------------------------
local state = {
	walkEnabled = false,
	walkValue = CONFIG.WalkDefaultValue,
	fovEnabled = false,
	fovValue = CONFIG.FovDefaultValue,
	menuOpen = false,
}

local defaultWalk = 16
local defaultFov = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70

--------------------------------------------------------------------
-- ХЕЛПЕРЫ
--------------------------------------------------------------------
local function create(class, props, children)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in pairs(props) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local COLOR_ON = Color3.fromRGB(52, 199, 89) -- iOS green
local COLOR_OFF = Color3.fromRGB(120, 120, 128)
local COLOR_ACCENT = Color3.fromRGB(10, 132, 255) -- iOS blue

--------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("LiquidGlassMenu")
if old then
	old:Destroy()
end

local blur = Lighting:FindFirstChild("LiquidGlassBlur") or Instance.new("BlurEffect")
blur.Name = "LiquidGlassBlur"
blur.Size = 0
blur.Parent = Lighting

local gui = create("ScreenGui", {
	Name = "LiquidGlassMenu",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- Главное стеклянное окно
local main = create("CanvasGroup", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(340, 300),
	BackgroundColor3 = Color3.fromRGB(28, 30, 40),
	BackgroundTransparency = 0.45,
	GroupTransparency = 1,
	Visible = false,
	Parent = gui,
}, {
	corner(28),
	create("UIScale", { Name = "Scale", Scale = 0.9 }),
	-- Градиент «жидкого стекла»: блик сверху-слева, затемнение снизу-справа
	create("UIGradient", {
		Rotation = 55,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(150, 160, 190)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 65, 90)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.75),
			NumberSequenceKeypoint.new(1, 0.6),
		}),
	}),
	-- Светящаяся рамка (рим стекла)
	create("UIStroke", {
		Thickness = 1.6,
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, {
		create("UIGradient", {
			Rotation = 45,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.3, 0.75),
				NumberSequenceKeypoint.new(0.7, 0.85),
				NumberSequenceKeypoint.new(1, 0.15),
			}),
		}),
	}),
})

local scale = main.Scale

-- Верхний блик
create("Frame", {
	Name = "Gloss",
	Size = UDim2.new(1, 0, 0, 90),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.88,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = main,
}, {
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}),
})

-- Шапка (за неё можно таскать окно)
local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 62),
	BackgroundTransparency = 1,
	Parent = main,
}, {
	create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -40, 0, 26),
		BackgroundTransparency = 1,
		Text = "Menu",
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
	}),
	create("TextLabel", {
		Name = "Hint",
		Position = UDim2.fromOffset(20, 38),
		Size = UDim2.new(1, -40, 0, 16),
		BackgroundTransparency = 1,
		Text = "Ctrl — меню   ·   C — WalkSpeed",
		TextColor3 = Color3.fromRGB(235, 235, 245),
		TextTransparency = 0.4,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}),
})

local content = create("Frame", {
	Name = "Content",
	Position = UDim2.fromOffset(0, 66),
	Size = UDim2.new(1, 0, 1, -66),
	BackgroundTransparency = 1,
	Parent = main,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}),
})

--------------------------------------------------------------------
-- ПЕРЕКЛЮЧАТЕЛЬ как в iOS
--------------------------------------------------------------------
local function makeToggle(parent, initial, onChanged)
	local track = create("TextButton", {
		Name = "Toggle",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 12),
		Size = UDim2.fromOffset(51, 31),
		BackgroundColor3 = COLOR_OFF,
		BackgroundTransparency = 0.45,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = parent,
	}, { corner(16) })

	local knob = create("Frame", {
		Name = "Knob",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.fromOffset(27, 27),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		corner(14),
		create("UIStroke", {
			Thickness = 1,
			Color = Color3.new(0, 0, 0),
			Transparency = 0.85,
		}),
	})

	local on = initial
	local pressed = false

	local function render()
		local w = pressed and 33 or 27
		local x = on and (51 - w - 2) or 2
		tween(knob, 0.3, {
			Size = UDim2.fromOffset(w, 27),
			Position = UDim2.fromOffset(x, 2),
		}, Enum.EasingStyle.Back)
		tween(track, 0.25, {
			BackgroundColor3 = on and COLOR_ON or COLOR_OFF,
			BackgroundTransparency = on and 0.1 or 0.45,
		}, Enum.EasingStyle.Quad)
	end

	local api = {}

	function api.Set(value, silent)
		on = value
		render()
		if not silent and onChanged then
			onChanged(on)
		end
	end

	function api.Toggle()
		api.Set(not on)
	end

	track.MouseButton1Down:Connect(function()
		pressed = true
		render()
	end)
	track.MouseButton1Up:Connect(function()
		pressed = false
		render()
	end)
	track.MouseLeave:Connect(function()
		if pressed then
			pressed = false
			render()
		end
	end)
	track.Activated:Connect(api.Toggle)

	render()
	return api
end

--------------------------------------------------------------------
-- СЛАЙДЕР
--------------------------------------------------------------------
local function makeSlider(parent, min, max, initial, onChanged)
	local holder = create("Frame", {
		Name = "Slider",
		Position = UDim2.fromOffset(14, 52),
		Size = UDim2.new(1, -74, 0, 24),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = holder,
	}, { corner(3) })

	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = COLOR_ACCENT,
		BorderSizePixel = 0,
		Parent = bar,
	}, { corner(3) })

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = holder,
	}, {
		corner(10),
		create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.85 }),
	})

	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 52),
		Size = UDim2.fromOffset(44, 24),
		BackgroundTransparency = 1,
		Text = tostring(initial),
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 0.15,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = parent,
	})

	local function setValue(v)
		v = math.clamp(math.floor(v + 0.5), min, max)
		local a = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		valueLabel.Text = tostring(v)
		return v
	end

	local dragging = false

	local function updateFromX(x)
		local a = math.clamp((x - holder.AbsolutePosition.X) / holder.AbsoluteSize.X, 0, 1)
		local v = setValue(min + (max - min) * a)
		onChanged(v)
	end

	holder.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			tween(knob, 0.15, { Size = UDim2.fromOffset(24, 24) })
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging = false
			tween(knob, 0.2, { Size = UDim2.fromOffset(20, 20) })
		end
	end)

	setValue(initial)
end

--------------------------------------------------------------------
-- СТРОКА МЕНЮ (название + переключатель + слайдер)
--------------------------------------------------------------------
local function makeRow(order, title, min, max, initial, onToggle, onSlide)
	local row = create("Frame", {
		Name = title,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 90),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Parent = content,
	}, {
		corner(18),
		create("UIStroke", {
			Thickness = 1,
			Color = Color3.new(1, 1, 1),
			Transparency = 0.85,
		}),
		create("TextLabel", {
			Position = UDim2.fromOffset(14, 12),
			Size = UDim2.new(1, -90, 0, 31),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.GothamMedium,
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})

	local toggle = makeToggle(row, false, onToggle)
	makeSlider(row, min, max, initial, onSlide)
	return toggle
end

local walkToggle = makeRow(1, "WalkSpeed", CONFIG.WalkMin, CONFIG.WalkMax, state.walkValue, function(on)
	state.walkEnabled = on
end, function(v)
	state.walkValue = v
end)

local fovToggle = makeRow(2, "FOV", CONFIG.FovMin, CONFIG.FovMax, state.fovValue, function(on)
	state.fovEnabled = on
end, function(v)
	state.fovValue = v
end)

--------------------------------------------------------------------
-- ПЕРЕТАСКИВАНИЕ ОКНА ЗА ШАПКУ
--------------------------------------------------------------------
do
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local d = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + d.X,
				startPos.Y.Scale,
				startPos.Y.Offset + d.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

--------------------------------------------------------------------
-- ОТКРЫТИЕ / ЗАКРЫТИЕ МЕНЮ
--------------------------------------------------------------------
local function setMenu(open)
	state.menuOpen = open
	if open then
		main.Visible = true
		tween(main, 0.4, { GroupTransparency = 0 })
		tween(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		tween(blur, 0.4, { Size = CONFIG.BlurSize })
	else
		tween(main, 0.25, { GroupTransparency = 1 })
		tween(scale, 0.25, { Scale = 0.92 })
		tween(blur, 0.3, { Size = 0 })
		task.delay(0.26, function()
			if not state.menuOpen then
				main.Visible = false
			end
		end)
	end
end

--------------------------------------------------------------------
-- БИНДЫ
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		setMenu(not state.menuOpen)
	elseif input.KeyCode == CONFIG.WalkKey then
		walkToggle.Toggle()
	end
end)

--------------------------------------------------------------------
-- ПЛАВНОЕ ПРИМЕНЕНИЕ WALKSPEED И FOV
--------------------------------------------------------------------
local lastHumanoid

RunService.RenderStepped:Connect(function(dt)
	local alpha = 1 - math.exp(-dt * CONFIG.Smoothness)

	-- WalkSpeed
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		if hum ~= lastHumanoid then
			lastHumanoid = hum
			defaultWalk = hum.WalkSpeed
		end
		local target = state.walkEnabled and state.walkValue or defaultWalk
		if math.abs(hum.WalkSpeed - target) > 0.05 then
			hum.WalkSpeed = hum.WalkSpeed + (target - hum.WalkSpeed) * alpha
		else
			hum.WalkSpeed = target
		end
	end

	-- FOV
	local cam = workspace.CurrentCamera
	if cam then
		local target = state.fovEnabled and state.fovValue or defaultFov
		if math.abs(cam.FieldOfView - target) > 0.05 then
			cam.FieldOfView = cam.FieldOfView + (target - cam.FieldOfView) * alpha
		else
			cam.FieldOfView = target
		end
	end
end)
