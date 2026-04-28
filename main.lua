local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

local antoralib = {
    Themes = {
        Classic = {
            ["Color Hub 1"] = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(25, 25, 25)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(32.5, 32.5, 32.5)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(25, 25, 25))
            }),
            ["Color Hub 2"] = Color3.fromRGB(30, 30, 30),
            ["Color Stroke"] = Color3.fromRGB(40, 40, 40),
            ["Color Theme"] = Color3.fromRGB(88, 101, 242),
            ["Color Text"] = Color3.fromRGB(243, 243, 243),
            ["Color Dark Text"] = Color3.fromRGB(180, 180, 180),
            ["antora Icon"] = "rbxassetid://102016808317696"
        }
    },
    Info = {
        Version = "Funcs&Stuff v5.0"
    },
    Save = {
        UISize = {550, 350},
        TabSize = 160,
        Theme = "Classic"
    },
    Settings = {},
    Connection = {},
    Instances = {},
    Elements = {},
    Options = {},
    Flags = {},
    Tabs = {},
    Icons = loadstring(game:HttpGet("https://pastebin.com/raw/La8CxEK7"))()
}

local ViewportSize = workspace.CurrentCamera.ViewportSize
local UIScale = ViewportSize.Y / 450

local Settings = antoralib.Settings
local Flags = antoralib.Flags

local SetProps, SetChildren, InsertTheme, Create do
	InsertTheme = function(Instance, Type)
		table.insert(antoralib.Instances, {
			Instance = Instance,
			Type = Type
		})
		return Instance
	end
	SetChildren = function(Instance, Children)
		if Children then
			table.foreach(Children, function(_,Child)
				Child.Parent = Instance
			end)
		end
		return Instance
	end
	SetProps = function(Instance, Props)
		if Props then
			table.foreach(Props, function(prop, value)
				Instance[prop] = value
			end)
		end
		return Instance
	end
	Create = function(...)
		local args = {...}
		if type(args) ~= "table" then return end
		local new = Instance.new(args[1])
		local Children = {}
		if type(args[2]) == "table" then
			SetProps(new, args[2])
			SetChildren(new, args[3])
			Children = args[3] or {}
		elseif typeof(args[2]) == "Instance" then
			new.Parent = args[2]
			SetProps(new, args[3])
			SetChildren(new, args[4])
			Children = args[4] or {}
		end
		return new
	end
	local function Save(file)
		if readfile and isfile and isfile(file) then
			local decode = HttpService:JSONDecode(readfile(file))
			if type(decode) == "table" then
				if rawget(decode, "UISize") then antoralib.Save["UISize"] = decode["UISize"] end
				if rawget(decode, "TabSize") then antoralib.Save["TabSize"] = decode["TabSize"] end
				if rawget(decode, "Theme") and VerifyTheme(decode["Theme"]) then antoralib.Save["Theme"] = decode["Theme"] end
			end
		end
	end
	pcall(Save, "Antora Library.json")
end

local Funcs = {} do
	function Funcs:InsertCallback(tab, func)
		if type(func) == "function" then
			table.insert(tab, func)
		end
		return func
	end
	function Funcs:FireCallback(tab, ...)
		for _,v in ipairs(tab) do
			if type(v) == "function" then
				task.spawn(v, ...)
			end
		end
	end
	function Funcs:ToggleVisible(Obj, Bool)
		Obj.Visible = Bool ~= nil and Bool or Obj.Visible
	end
	function Funcs:ToggleParent(Obj, Parent)
		if Bool ~= nil then
			Obj.Parent = Bool
		else
			Obj.Parent = not Obj.Parent and Parent
		end
	end
	function Funcs:GetConnectionFunctions(ConnectedFuncs, func)
		local Connected = { Function = func, Connected = true }
		function Connected:Disconnect()
			if self.Connected then
				table.remove(ConnectedFuncs, table.find(ConnectedFuncs, self.Function))
				self.Connected = false
			end
		end
		function Connected:Fire(...)
			if self.Connected then
				task.spawn(self.Function, ...)
			end
		end
		return Connected
	end
	function Funcs:GetCallback(Configs, index)
		local func = Configs[index] or Configs.Callback or function()end
		if type(func) == "table" then
			return ({function(Value) func[1][func[2]] = Value end})
		end
		return {func}
	end
end

local Connections, Connection = {}, antoralib.Connection do
	local function NewConnectionList(List)
		if type(List) ~= "table" then return end
		for _,CoName in ipairs(List) do
			local ConnectedFuncs, Connect = {}, {}
			Connection[CoName] = Connect
			Connections[CoName] = ConnectedFuncs
			Connect.Name = CoName
			function Connect:Connect(func)
				if type(func) == "function" then
					table.insert(ConnectedFuncs, func)
					return Funcs:GetConnectionFunctions(ConnectedFuncs, func)
				end
			end
			function Connect:Once(func)
				if type(func) == "function" then
					local Connected;
					local _NFunc;_NFunc = function(...)
						task.spawn(func, ...)
						Connected:Disconnect()
					end
					Connected = Funcs:GetConnectionFunctions(ConnectedFuncs, _NFunc)
					return Connected
				end
			end
		end
	end
	function Connection:FireConnection(CoName, ...)
		local Connection = type(CoName) == "string" and Connections[CoName] or Connections[CoName.Name]
		for _,Func in pairs(Connection) do
			task.spawn(Func, ...)
		end
	end
	NewConnectionList({"FlagsChanged", "ThemeChanged", "FileSaved", "ThemeChanging", "OptionAdded"})
end

local GetFlag, SetFlag, CheckFlag do
	CheckFlag = function(Name)
		return type(Name) == "string" and Flags[Name] ~= nil
	end
	GetFlag = function(Name)
		return type(Name) == "string" and Flags[Name]
	end
	SetFlag = function(Flag, Value)
		if Flag and (Value ~= Flags[Flag] or type(Value) == "table") then
			Flags[Flag] = Value
			Connection:FireConnection("FlagsChanged", Flag, Value)
		end
	end
	local db
	Connection.FlagsChanged:Connect(function(Flag, Value)
		local ScriptFile = Settings.ScriptFile
		if not db and ScriptFile and writefile then
			db=true;task.wait(0.1);db=false
			local Success, Encoded = pcall(function()
				return HttpService:JSONEncode(Flags)
			end)
			if Success then
				local Success = pcall(writefile, ScriptFile, Encoded)
				if Success then
					Connection:FireConnection("FileSaved", "Script-Flags", ScriptFile, Encoded)
				end
			end
		end
	end)
end

local ScreenGui = Create("ScreenGui", CoreGui, {
	Name = "Antora Library",
}, {
	Create("UIScale", {
		Scale = UIScale,
		Name = "Scale"
	})
})

local ScreenFind = CoreGui:FindFirstChild(ScreenGui.Name)
if ScreenFind and ScreenFind ~= ScreenGui then
	ScreenFind:Destroy()
end

local function GetStr(val)
	if type(val) == "function" then
		return val()
	end
	return val
end

local function ConnectSave(Instance, func)
	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do task.wait()
			end
		end
		func()
	end)
end

local function CreateTween(Configs)
	local Instance = Configs[1] or Configs.Instance
	local Prop = Configs[2] or Configs.Prop
	local NewVal = Configs[3] or Configs.NewVal
	local Time = Configs[4] or Configs.Time or 0.5
	local TweenWait = Configs[5] or Configs.wait or false
	local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quint)
	local Tween = TweenService:Create(Instance, TweenInfo, {[Prop] = NewVal})
	Tween:Play()
	if TweenWait then
		Tween.Completed:Wait()
	end
	return Tween
end

local function MakeDrag(Instance)
	task.spawn(function()
		SetProps(Instance, {
			Active = true,
			AutoButtonColor = false
		})
		local DragStart, StartPos, InputOn
		local function Update(Input)
			local delta = Input.Position - DragStart
			local Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X / UIScale, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y / UIScale)
			CreateTween({Instance, "Position", Position, 0.35})
		end
		Instance.MouseButton1Down:Connect(function()
			InputOn = true
		end)
		Instance.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				StartPos = Instance.Position
				DragStart = Input.Position
				while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do RunService.Heartbeat:Wait()
					if InputOn then
						Update(Input)
					end
				end
				InputOn = false
			end
		end)
	end)
	return Instance
end

local function VerifyTheme(Theme)
	for name,_ in pairs(antoralib.Themes) do
		if name == Theme then
			return true
		end
	end
	return false
end

local function SaveJson(FileName, save)
	if writefile then
		local json = HttpService:JSONEncode(save)
		writefile(FileName, json)
	end
end

local Theme = antoralib.Themes[antoralib.Save.Theme]

local function AddEle(Name, Func)
	antoralib.Elements[Name] = Func
end

local function Make(Ele, Instance, props, ...)
	local Element = antoralib.Elements[Ele](Instance, props, ...)
	return Element
end

AddEle("Corner", function(parent, CornerRadius)
	local New = SetProps(Create("UICorner", parent, {
		CornerRadius = CornerRadius or UDim.new(0, 17)
	}))
	return New
end)

AddEle("Stroke", function(parent, props, ...)
	local args = {...}
	local New = InsertTheme(SetProps(Create("UIStroke", parent, {
		Color = args[1] or Theme["Color Stroke"],
		Thickness = args[2] or 1,
		ApplyStrokeMode = "Border"
	}), props), "Stroke")
	return New
end)

AddEle("Button", function(parent, props, ...)
	local args = {...}
	local New = InsertTheme(SetProps(Create("TextButton", parent, {
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme["Color Hub 2"],
		AutoButtonColor = false
	}), props), "Frame")
	New.MouseEnter:Connect(function()
		New.BackgroundTransparency = 0.4
	end)
	New.MouseLeave:Connect(function()
		New.BackgroundTransparency = 0
	end)
	if args[1] then
		New.Activated:Connect(args[1])
	end
	return New
end)

AddEle("Gradient", function(parent, props, ...)
	local args = {...}
	local New = InsertTheme(SetProps(Create("UIGradient", parent, {
		Color = Theme["Color Hub 1"]
	}), props), "Gradient")
	return New
end)

local function ButtonFrame(Instance, Title, Description, HolderSize)
	local TitleL = InsertTheme(Create("TextLabel", {
		Font = Enum.Font.GothamMedium,
		TextColor3 = Theme["Color Text"],
		Size = UDim2.new(1, -20),
		AutomaticSize = "Y",
		Position = UDim2.new(0, 0, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		TextTruncate = "AtEnd",
		TextSize = 10,
		TextXAlignment = "Left",
		Text = "",
		RichText = true
	}), "Text")
	local DescL = InsertTheme(Create("TextLabel", {
		Font = Enum.Font.Gotham,
		TextColor3 = Theme["Color Dark Text"],
		Size = UDim2.new(1, -20),
		AutomaticSize = "Y",
		Position = UDim2.new(0, 12, 0, 15),
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 8,
		TextXAlignment = "Left",
		Text = "",
		RichText = true
	}), "DarkText")
	local Frame = Make("Button", Instance, {
		Size = UDim2.new(1, 0, 0, 25),
		AutomaticSize = "Y",
		Name = "Option"
	})
	Make("Corner", Frame, UDim.new(0, 6))
	local LabelHolder = Create("Frame", Frame, {
		AutomaticSize = "Y",
		BackgroundTransparency = 1,
		Size = HolderSize,
		Position = UDim2.new(0, 10, 0),
		AnchorPoint = Vector2.new(0, 0)
	}, {
		Create("UIListLayout", {
			SortOrder = "LayoutOrder",
			VerticalAlignment = "Center",
			Padding = UDim.new(0, 2)
		}),
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 5),
			PaddingTop = UDim.new(0, 5)
		}),
		TitleL,
		DescL,
	})
	local Label = {}
	function Label:SetTitle(NewTitle)
		if type(NewTitle) == "string" and NewTitle:gsub(" ", ""):len() > 0 then
			TitleL.Text = NewTitle
		end
	end
	function Label:SetDesc(NewDesc)
		if type(NewDesc) == "string" and NewDesc:gsub(" ", ""):len() > 0 then
			DescL.Visible = true
			DescL.Text = NewDesc
			LabelHolder.Position = UDim2.new(0, 10, 0)
			LabelHolder.AnchorPoint = Vector2.new(0, 0)
		else
			DescL.Visible = false
			DescL.Text = ""
			LabelHolder.Position = UDim2.new(0, 10, 0.5)
			LabelHolder.AnchorPoint = Vector2.new(0, 0.5)
		end
	end
	Label:SetTitle(Title)
	Label:SetDesc(Description)
	return Frame, Label
end

local function GetColor(Instance)
	if Instance:IsA("Frame") then
		return "BackgroundColor3"
	elseif Instance:IsA("ImageLabel") then
		return "ImageColor3"
	elseif Instance:IsA("TextLabel") then
		return "TextColor3"
	elseif Instance:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	elseif Instance:IsA("UIStroke") then
		return "Color"
	end
	return ""
end

function antoralib:GetIcon(index)
	if type(index) ~= "string" or index:find("rbxassetid://") or #index == 0 then
		return index
	end
	local firstMatch = nil
	index = string.lower(index):gsub("lucide", ""):gsub("-", "")
	for Name, Icon in self.Icons do
		Name = Name:gsub("lucide", ""):gsub("-", "")
		if Name == index then
			return Icon
		elseif not firstMatch and Name:find(index, 1, true) then
			firstMatch = Icon
		end
	end
	return firstMatch or index
end

function antoralib:SetTheme(NewTheme)
	if not VerifyTheme(NewTheme) then return end
	antoralib.Save.Theme = NewTheme
	SaveJson("Antora Library.json", antoralib.Save)
	Theme = antoralib.Themes[NewTheme]
	Connection:FireConnection("ThemeChanged", NewTheme)
	table.foreach(antoralib.Instances, function(_,Val)
		if Val.Type == "Gradient" then
			Val.Instance.Color = Theme["Color Hub 1"]
		elseif Val.Type == "Frame" then
			Val.Instance.BackgroundColor3 = Theme["Color Hub 2"]
		elseif Val.Type == "Stroke" then
			Val.Instance[GetColor(Val.Instance)] = Theme["Color Stroke"]
		elseif Val.Type == "Theme" then
			Val.Instance[GetColor(Val.Instance)] = Theme["Color Theme"]
		elseif Val.Type == "Text" then
			Val.Instance[GetColor(Val.Instance)] = Theme["Color Text"]
		elseif Val.Type == "DarkText" then
			Val.Instance[GetColor(Val.Instance)] = Theme["Color Dark Text"]
		elseif Val.Type == "ScrollBar" then
			Val.Instance[GetColor(Val.Instance)] = Theme["Color Theme"]
		end
	end)
end

function antoralib:SetScale(NewScale)
	NewScale = ViewportSize.Y / math.clamp(NewScale, 300, 2000)
	UIScale, ScreenGui.Scale.Scale = NewScale, NewScale
end

function antoralib:MakeWindow(Configs)
	local WTitle = Configs[1] or Configs.Name or Configs.Title or "Antora Library"
	local WMiniText = Configs[2] or Configs.SubTitle or "by: unkinou"
	Settings.ScriptFile = Configs[3] or Configs.SaveFolder or false
	local function LoadFile()
		local File = Settings.ScriptFile
		if type(File) ~= "string" then return end
		if not readfile or not isfile then return end
		local s, r = pcall(isfile, File)
		if s and r then
			local s, _Flags = pcall(readfile, File)
			if s and type(_Flags) == "string" then
				local s,r = pcall(function() return HttpService:JSONDecode(_Flags) end)
				Flags = s and r or {}
			end
		end
	end;LoadFile()
	local UISizeX, UISizeY = unpack(antoralib.Save.UISize)

	-- Liquid Glass: blur no mundo
	local Lighting = game:GetService("Lighting")
	if not Lighting:FindFirstChild("AntoraBlur") then
		local BlurEffect = Instance.new("BlurEffect")
		BlurEffect.Size = 24
		BlurEffect.Name = "AntoraBlur"
		BlurEffect.Parent = Lighting
	end

	local MainFrame = InsertTheme(Create("ImageButton", ScreenGui, {
		Size = UDim2.fromOffset(UISizeX, UISizeY),
		Position = UDim2.new(0.5, -UISizeX/2, 0.5, -UISizeY/2),
		BackgroundTransparency = 0.55,
		BackgroundColor3 = Color3.fromRGB(210, 220, 255),
		Name = "Hub"
	}), "Main")

	-- Gradiente liquid glass
	Create("UIGradient", MainFrame, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(220, 230, 255)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(200, 215, 245)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(180, 200, 240)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0.65),
		}),
		Rotation = 135
	})

	-- Borda vidro branca
	Create("UIStroke", MainFrame, {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 1.2,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})

	-- Reflexo no topo
	local GlassReflect = Create("Frame", MainFrame, {
		Size = UDim2.new(1, 0, 0.3, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		ZIndex = 2
	})
	Create("UIGradient", GlassReflect, {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90
	})
	Make("Corner", GlassReflect)

	MakeDrag(MainFrame)
	local MainCorner = Make("Corner", MainFrame)
	local Components = Create("Folder", MainFrame, {
		Name = "Components"
	})
	local DropdownHolder = Create("Folder", ScreenGui, {
		Name = "Dropdown"
	})
    local TopBar = Create("Frame", Components, {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Name = "Top Bar"
    })
    local Label = Create("ImageLabel", TopBar, {
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 7, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = Theme["antora Icon"]
    })
    local Title = InsertTheme(Create("TextLabel", TopBar, {
        Position = UDim2.new(0, 40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        AutomaticSize = "XY",
        Text = WTitle,
        TextXAlignment = "Left",
        TextSize = 14,
        TextColor3 = Theme["Color Text"],
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Name = "Title"
    }, {
        InsertTheme(Create("TextLabel", {
            Size = UDim2.fromScale(0, 1),
            AutomaticSize = "X",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(1, 5, 0.9, 0),
            Text = WMiniText,
            TextColor3 = Color3.fromRGB(40, 40, 40),
            BackgroundTransparency = 1,
            TextXAlignment = "Left",
            TextYAlignment = "Bottom",
            TextSize = 10,
            Font = Enum.Font.Gotham,
            Name = "SubTitle"
        }), "DarkText")
    }), "Text")
	local MainScroll = InsertTheme(Create("ScrollingFrame", Components, {
		Size = UDim2.new(0, antoralib.Save.TabSize, 1, -TopBar.Size.Y.Offset),
		ScrollBarImageColor3 = Color3.fromRGB(255, 75, 129),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		ScrollBarThickness = 1.5,
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 0.2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = "Y",
		ScrollingDirection = "Y",
		BorderSizePixel = 0,
		Name = "Tab Scroll"
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10)
		}), Create("UIListLayout", {
			Padding = UDim.new(0, 5)
		})
	}), "ScrollBar")
	local Containers = Create("Frame", Components, {
		Size = UDim2.new(1, -MainScroll.Size.X.Offset, 1, -TopBar.Size.Y.Offset),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Name = "Containers"
	})

	local Window, FirstTab = {}, false

	function Window:Set(Val1, Val2)
		if type(Val1) == "string" and type(Val2) == "string" then
			Title.Text = Val1
			Title.SubTitle.Text = Val2
		elseif type(Val1) == "string" then
			Title.Text = Val1
		end
	end

	function Window:AddMinimizeButton(Configs)
	local Button = MakeDrag(Create("ImageButton", ScreenGui, {
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.fromScale(0.15, 0.15),
		AnchorPoint = Vector2.new(0.5, 0.5), -- Centralizar para crescer reto
		BackgroundTransparency = 1,
		BackgroundColor3 = Theme["Color Hub 2"],
		AutoButtonColor = false
	}))
	
	-- UIScale para animação de tamanho
	local ButtonScale = Create("UIScale", Button, {
		Scale = 1
	})
	
	local Stroke, Corner
	if Configs and Configs.Corner then
		Corner = Make("Corner", Button)
		SetProps(Corner, Configs.Corner)
	end
	if Configs and Configs.Stroke then
		Stroke = Make("Stroke", Button)
		SetProps(Stroke, Configs.Stroke)
	end
	if Configs and Configs.Button then
		SetProps(Button, Configs.Button)
	end
	
	local isAnimating = false
	
	-- Função para criar partículas
	local function createParticles()
		local particleCount = 12
		for i = 1, particleCount do
			local angle = (360 / particleCount) * i
			local randomBrightness = math.random(200, 255) -- Brilho aleatório mais intenso
			local particle = Create("Frame", Button, {
				Size = UDim2.fromOffset(6, 6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, randomBrightness * 0.4, randomBrightness * 0.6), -- Mais rosa
				BackgroundTransparency = 0,
				ZIndex = -1 -- Atrás da imagem
			})
			Make("Corner", particle, UDim.new(1, 0))
			
			-- Gradiente rosa mais vibrante
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 150)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 120))
			})
			gradient.Parent = particle
			
			-- Calcular direção
			local radian = math.rad(angle)
			local distance = math.random(40, 70)
			local endX = 0.5 + (math.cos(radian) * distance / 60)
			local endY = 0.5 + (math.sin(radian) * distance / 60)
			
			-- Tempo aleatório para cada partícula
			local duration = math.random(60, 100) / 100 -- 0.6 a 1.0 segundos
			
			-- Animação de explosão
			task.spawn(function()
				local moveTween = CreateTween({particle, "Position", UDim2.fromScale(endX, endY), duration})
				local fadeTween = CreateTween({particle, "BackgroundTransparency", 1, duration})
				local sizeTween = CreateTween({particle, "Size", UDim2.fromOffset(2, 2), duration})
				
				moveTween:Play()
				fadeTween:Play()
				sizeTween:Play()
				
				fadeTween.Completed:Wait()
				particle:Destroy()
			end)
		end
	end
	
	Button.Activated:Connect(function()
		if isAnimating then return end
		isAnimating = true
		
		-- Criar partículas
		createParticles()
		
		-- Animação de aumentar + balançar para esquerda
		local scaleUp = CreateTween({ButtonScale, "Scale", 1.15, 0.12})
		local shakeLeft = CreateTween({Button, "Rotation", -8, 0.12})
		scaleUp:Play()
		shakeLeft:Play()
		scaleUp.Completed:Wait()
		
		-- Balançar para direita
		local shakeRight = CreateTween({Button, "Rotation", 8, 0.08})
		shakeRight:Play()
		shakeRight.Completed:Wait()
		
		-- Alternar visibilidade
		MainFrame.Visible = not MainFrame.Visible
		
		-- Balançar de volta ao centro + diminuir
		local shakeCenter = CreateTween({Button, "Rotation", 0, 0.15})
		local scaleDown = CreateTween({ButtonScale, "Scale", 1, 0.18})
		shakeCenter:Play()
		scaleDown:Play()
		scaleDown.Completed:Wait()
		
		isAnimating = false
	end)
	
	return {
		Stroke = Stroke,
		Corner = Corner,
		Button = Button,
		Scale = ButtonScale
	}
end

	local ContainerList = {}
	function Window:MakeTab(paste, Configs)
		if type(paste) == "table" then Configs = paste end
		local TName = Configs[1] or Configs.Title or "Tab!"
		local TIcon = Configs[2] or Configs.Icon or ""
		TIcon = antoralib:GetIcon(TIcon)
		if not TIcon:find("rbxassetid://") or TIcon:gsub("rbxassetid://", ""):len() < 6 then
			TIcon = false
		end
		local TabSelect = Make("Button", MainScroll, {
			Size = UDim2.new(1, 0, 0, 24)
		})Make("Corner", TabSelect)
		local LabelTitle = InsertTheme(Create("TextLabel", TabSelect, {
			Size = UDim2.new(1, TIcon and -25 or -15, 1),
			Position = UDim2.fromOffset(TIcon and 25 or 15),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = TName,
			TextColor3 = Theme["Color Text"],
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = (FirstTab and 0.3) or 0,
			TextTruncate = "AtEnd"
		}), "Text")
		local LabelIcon = InsertTheme(Create("ImageLabel", TabSelect, {
			Position = UDim2.new(0, 8, 0.5),
			Size = UDim2.new(0, 13, 0, 13),
			AnchorPoint = Vector2.new(0, 0.5),
			Image = TIcon or "",
			BackgroundTransparency = 1,
			ImageTransparency = (FirstTab and 0.3) or 0
		}), "Text")
		local Selected = InsertTheme(Create("Frame", TabSelect, {
    Size = FirstTab and UDim2.new(0, 4, 0, 4) or UDim2.new(0, 4, 0, 13),
    Position = UDim2.new(0, 1, 0.5),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = FirstTab and 1 or 0
		}), "Theme")
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(253, 77, 123)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 46, 98))
		})
		gradient.Rotation = 90
		gradient.Parent = Selected
		Make("Corner", Selected, UDim.new(0.5, 0))
		local Container = InsertTheme(Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 1),
			AnchorPoint = Vector2.new(0, 1),
			ScrollBarThickness = 1.5,
			BackgroundTransparency = 1,
			ScrollBarImageTransparency = 0.2,
			ScrollBarImageColor3 = Color3.fromRGB(255, 75, 129),
			AutomaticCanvasSize = "Y",
			ScrollingDirection = "Y",
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			Name = ("Container %i [ %s ]"):format(#ContainerList + 1, TName)
		}, {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10)
			}), Create("UIListLayout", {
				Padding = UDim.new(0, 5)
			})
		}), "ScrollBar")
		table.insert(ContainerList, Container)
		if not FirstTab then Container.Parent = Containers end
		local function Tabs()
			if Container.Parent then return end
			for _,Frame in pairs(ContainerList) do
				if Frame:IsA("ScrollingFrame") and Frame ~= Container then
					Frame.Parent = nil
				end
			end
			Container.Parent = Containers
			Container.Size = UDim2.new(1, 0, 1, 150)
			table.foreach(antoralib.Tabs, function(_,Tab)
				if Tab.Cont ~= Container then
					Tab.func:Disable()
				end
			end)
			CreateTween({Container, "Size", UDim2.new(1, 0, 1, 0), 0.3})
			CreateTween({LabelTitle, "TextTransparency", 0, 0.35})
			CreateTween({LabelIcon, "ImageTransparency", 0, 0.35})
			CreateTween({Selected, "Size", UDim2.new(0, 4, 0, 13), 0.35})
			CreateTween({Selected, "BackgroundTransparency", 0, 0.35})
		end
		TabSelect.Activated:Connect(Tabs)
		FirstTab = true
		local Tab = {}
		table.insert(antoralib.Tabs, {TabInfo = {Name = TName, Icon = TIcon}, func = Tab, Cont = Container})
		Tab.Cont = Container
		function Tab:Disable()
			Container.Parent = nil
			CreateTween({LabelTitle, "TextTransparency", 0.3, 0.35})
			CreateTween({LabelIcon, "ImageTransparency", 0.3, 0.35})
			CreateTween({Selected, "Size", UDim2.new(0, 4, 0, 4), 0.35})
			CreateTween({Selected, "BackgroundTransparency", 1, 0.35})
		end
		function Tab:Enable()
			Tabs()
		end
		function Tab:Visible(Bool)
			Funcs:ToggleVisible(TabSelect, Bool)
			Funcs:ToggleParent(Container, Bool, Containers)
		end
		function Tab:Destroy() TabSelect:Destroy() Container:Destroy() end
		function Tab:AddSection(Configs)
			local SectionName = type(Configs) == "string" and Configs or Configs[1] or Configs.Name or Configs.Title or Configs.Section
			local SectionFrame = Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Name = "Option"
			})
			local SectionLabel = InsertTheme(Create("TextLabel", SectionFrame, {
				Font = Enum.Font.GothamBold,
				Text = SectionName,
				TextColor3 = Theme["Color Text"],
				Size = UDim2.new(1, -25, 1, 0),
				Position = UDim2.new(0, 5),
				BackgroundTransparency = 1,
				TextTruncate = "AtEnd",
				TextSize = 14,
				TextXAlignment = "Left"
			}), "Text")
			local Section = {}
			table.insert(antoralib.Options, {type = "Section", Name = SectionName, func = Section})
			function Section:Visible(Bool)
				if Bool == nil then SectionFrame.Visible = not SectionFrame.Visible return end
				SectionFrame.Visible = Bool
			end
			function Section:Destroy()
				SectionFrame:Destroy()
			end
			function Section:Set(New)
				if New then
					SectionLabel.Text = GetStr(New)
				end
			end
			return Section
		end
		function Tab:AddParagraph(Configs)
			local PName = Configs[1] or Configs.Title or "Paragraph"
			local PDesc = Configs[2] or Configs.Text or ""
			local Frame, LabelFunc = ButtonFrame(Container, PName, PDesc, UDim2.new(1, -20))
			local Paragraph = {}
			function Paragraph:Visible(...) Funcs:ToggleVisible(Frame, ...) end
			function Paragraph:Destroy() Frame:Destroy() end
			function Paragraph:SetTitle(Val)
				LabelFunc:SetTitle(GetStr(Val))
			end
			function Paragraph:SetDesc(Val)
				LabelFunc:SetDesc(GetStr(Val))
			end
			function Paragraph:Set(Val1, Val2)
				if Val1 and Val2 then
					LabelFunc:SetTitle(GetStr(Val1))
					LabelFunc:SetDesc(GetStr(Val2))
				elseif Val1 then
					LabelFunc:SetDesc(GetStr(Val1))
				end
			end
			return Paragraph
		end
		function Tab:AddButton(Configs)
			local BName = Configs[1] or Configs.Name or Configs.Title or "Button!"
			local BDescription = Configs.Desc or Configs.Description or ""
			local Callback = Funcs:GetCallback(Configs, 2)
			local FButton, LabelFunc = ButtonFrame(Container, BName, BDescription, UDim2.new(1, -20))
			local ButtonIcon = Create("ImageLabel", FButton, {
				Size = UDim2.new(0, 14, 0, 14),
				Position = UDim2.new(1, -10, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://10709791437"
			})
			FButton.Activated:Connect(function()
				Funcs:FireCallback(Callback)
			end)
			local Button = {}
			function Button:Visible(...) Funcs:ToggleVisible(FButton, ...) end
			function Button:Destroy() FButton:Destroy() end
			function Button:Callback(...) Funcs:InsertCallback(Callback, ...) end
			function Button:Set(Val1, Val2)
				if type(Val1) == "string" and type(Val2) == "string" then
					LabelFunc:SetTitle(Val1)
					LabelFunc:SetDesc(Val2)
				elseif type(Val1) == "string" then
					LabelFunc:SetTitle(Val1)
				elseif type(Val1) == "function" then
					Callback = Val1
				end
			end
			return Button
		end
		function Tab:AddToggle(Configs)
			local TName = Configs[1] or Configs.Name or Configs.Title or "Toggle"
			local TDesc = Configs.Desc or Configs.Description or ""
			local Callback = Funcs:GetCallback(Configs, 3)
			local Flag = Configs[4] or Configs.Flag or false
			local Default = Configs[2] or Configs.Default or false
			if CheckFlag(Flag) then Default = GetFlag(Flag) end
			local Button, LabelFunc = ButtonFrame(Container, TName, TDesc, UDim2.new(1, -38))
			local ToggleHolder = InsertTheme(Create("Frame", Button, {
				Size = UDim2.new(0, 35, 0, 18),
				Position = UDim2.new(1, -10, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Theme["Color Stroke"]
			}), "Stroke")Make("Corner", ToggleHolder, UDim.new(0.5, 0))
			local Slider = Create("Frame", ToggleHolder, {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.8, 0, 0.8, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5)
			})
			local Toggle = InsertTheme(Create("Frame", Slider, {
    Size = UDim2.new(0, 12, 0, 12),
    Position = UDim2.new(0, 0, 0.5),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1
			}), "Theme")
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(253, 77, 123)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 46, 98))
			})
			gradient.Rotation = 0
			gradient.Parent = Toggle
			Make("Corner", Toggle, UDim.new(0.5, 0))
			local WaitClick
			local function SetToggle(Val)
				if WaitClick then return end
				WaitClick, Default = true, Val
				SetFlag(Flag, Default)
				Funcs:FireCallback(Callback, Default)
				if Default then
					CreateTween({Toggle, "Position", UDim2.new(1, 0, 0.5), 0.25})
					CreateTween({Toggle, "BackgroundTransparency", 0, 0.25})
					CreateTween({Toggle, "AnchorPoint", Vector2.new(1, 0.5), 0.25, Wait or false})
				else
					CreateTween({Toggle, "Position", UDim2.new(0, 0, 0.5), 0.25})
					CreateTween({Toggle, "BackgroundTransparency", 0.8, 0.25})
					CreateTween({Toggle, "AnchorPoint", Vector2.new(0, 0.5), 0.25, Wait or false})
				end
				WaitClick = false
			end;task.spawn(SetToggle, Default)
			Button.Activated:Connect(function()
				SetToggle(not Default)
			end)
			local Toggle = {}
			function Toggle:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Toggle:Destroy() Button:Destroy() end
			function Toggle:Callback(...) Funcs:InsertCallback(Callback, ...)() end
			function Toggle:Set(Val1, Val2)
				if type(Val1) == "string" and type(Val2) == "string" then
					LabelFunc:SetTitle(Val1)
					LabelFunc:SetDesc(Val2)
				elseif type(Val1) == "string" then
					LabelFunc:SetTitle(Val1, false, true)
				elseif type(Val1) == "boolean" then
					if WaitClick and Val2 then
						repeat task.wait() until not WaitClick
					end
					task.spawn(SetToggle, Val1)
				elseif type(Val1) == "function" then
					Callback = Val1
				end
			end
			return Toggle
		end
		function Tab:AddDropdown(Configs)
			local DName = Configs[1] or Configs.Name or Configs.Title or "Dropdown"
			local DDesc = Configs.Desc or Configs.Description or ""
			local DOptions = Configs[2] or Configs.Options or {}
			local OpDefault = Configs[3] or Configs.Default or {}
			local Flag = Configs[5] or Configs.Flag or false
			local DMultiSelect = Configs.MultiSelect or false
			local Callback = Funcs:GetCallback(Configs, 4)
			local Button, LabelFunc = ButtonFrame(Container, DName, DDesc, UDim2.new(1, -180))
			local SelectedFrame = InsertTheme(Create("Frame", Button, {
				Size = UDim2.new(0, 150, 0, 18),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Theme["Color Stroke"]
			}), "Stroke")Make("Corner", SelectedFrame, UDim.new(0, 4))
			local ActiveLabel = InsertTheme(Create("TextLabel", SelectedFrame, {
				Size = UDim2.new(0.85, 0, 0.85, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Theme["Color Text"],
				Text = "..."
			}), "Text")
			local Arrow = Create("ImageLabel", SelectedFrame, {
				Size = UDim2.new(0, 15, 0, 15),
				Position = UDim2.new(0, -5, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				Image = "rbxassetid://10709791523",
				BackgroundTransparency = 1
			})
			local NoClickFrame = Create("TextButton", DropdownHolder, {
				Name = "AntiClick",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Visible = false,
				Text = ""
			})
			local DropFrame = Create("Frame", NoClickFrame, {
				Size = UDim2.new(SelectedFrame.Size.X, 0, 0),
				BackgroundTransparency = 0.1,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0, 1),
				Name = "DropdownFrame",
				ClipsDescendants = true,
				Active = true
			})Make("Corner", DropFrame)Make("Stroke", DropFrame)Make("Gradient", DropFrame, {Rotation = 60})
			local ScrollFrame = InsertTheme(Create("ScrollingFrame", DropFrame, {
				ScrollBarImageColor3 = Color3.fromRGB(255, 75, 129),
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 1.5,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				ScrollingDirection = "Y",
				AutomaticCanvasSize = "Y",
				Active = true
			}, {
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5)
				}), Create("UIListLayout", {
					Padding = UDim.new(0, 4)
				})
			}), "ScrollBar")
			local ScrollSize, WaitClick = 5
			local function Disable()
				WaitClick = true
				CreateTween({Arrow, "Rotation", 0, 0.2})
				CreateTween({DropFrame, "Size", UDim2.new(0, 152, 0, 0), 0.2, true})
				CreateTween({Arrow, "ImageColor3", Color3.fromRGB(255, 255, 255), 0.2})
				Arrow.Image = "rbxassetid://10709791523"
				NoClickFrame.Visible = false
				WaitClick = false
			end
			local function GetFrameSize()
				return UDim2.fromOffset(152, ScrollSize)
			end
			local function CalculateSize()
				local Count = 0
				for _,Frame in pairs(ScrollFrame:GetChildren()) do
					if Frame:IsA("Frame") or Frame.Name == "Option" then
						Count = Count + 1
					end
				end
				ScrollSize = (math.clamp(Count, 0, 10) * 25) + 10
				if NoClickFrame.Visible then
					NoClickFrame.Visible = true
					CreateTween({DropFrame, "Size", GetFrameSize(), 0.2, true})
				end
			end
			local function Minimize()
    if WaitClick then return end
    WaitClick = true
    if NoClickFrame.Visible then
        Arrow.Image = "rbxassetid://10709791523"
        CreateTween({Arrow, "ImageColor3", Color3.fromRGB(255, 255, 255), 0.2})
        CreateTween({DropFrame, "Size", UDim2.new(0, 152, 0, 0), 0.2, true})
        NoClickFrame.Visible = false
    else
        NoClickFrame.Visible = true
        Arrow.Image = "rbxassetid://10709790948"
        CreateTween({Arrow, "ImageColor3", Color3.fromRGB(255, 255, 255), 0.2})
        CreateTween({DropFrame, "Size", GetFrameSize(), 0.2, true})
    end
    WaitClick = false
end
			local function CalculatePos()
				local FramePos = SelectedFrame.AbsolutePosition
				local ScreenSize = ScreenGui.AbsoluteSize
				local ClampX = math.clamp((FramePos.X / UIScale), 0, ScreenSize.X / UIScale - DropFrame.Size.X.Offset)
				local ClampY = math.clamp((FramePos.Y / UIScale) , 0, ScreenSize.Y / UIScale)
				local NewPos = UDim2.fromOffset(ClampX, ClampY)
				local AnchorPoint = FramePos.Y > ScreenSize.Y / 1.4 and 1 or ScrollSize > 80 and 0.5 or 0
				DropFrame.AnchorPoint = Vector2.new(0, AnchorPoint)
				CreateTween({DropFrame, "Position", NewPos, 0.1})
			end
			local AddNewOptions, GetOptions, AddOption, RemoveOption, Selected do
				local Default = type(OpDefault) ~= "table" and {OpDefault} or OpDefault
				local MultiSelect = DMultiSelect
				local Options = {}
				Selected = MultiSelect and {} or CheckFlag(Flag) and GetFlag(Flag) or Default[1]
				if MultiSelect then
					for index, Value in pairs(CheckFlag(Flag) and GetFlag(Flag) or Default) do
						if type(index) == "string" and (DOptions[index] or table.find(DOptions, index)) then
							Selected[index] = Value
						elseif DOptions[Value] then
							Selected[Value] = true
						end
					end
				end
				local function CallbackSelected()
					SetFlag(Flag, MultiSelect and Selected or tostring(Selected))
					Funcs:FireCallback(Callback, Selected)
				end
				local function UpdateLabel()
					if MultiSelect then
						local list = {}
						for index, Value in pairs(Selected) do
							if Value then
								table.insert(list, index)
							end
						end
						ActiveLabel.Text = #list > 0 and table.concat(list, ", ") or "..."
					else
						ActiveLabel.Text = tostring(Selected or "...")
					end
				end
				local function UpdateSelected()
					if MultiSelect then
						for _,v in pairs(Options) do
							local nodes, Stats = v.nodes, v.Stats
							CreateTween({nodes[2], "BackgroundTransparency", Stats and 0 or 0.8, 0.35})
							CreateTween({nodes[2], "Size", Stats and UDim2.fromOffset(4, 12) or UDim2.fromOffset(4, 4), 0.35})
							CreateTween({nodes[3], "TextTransparency", Stats and 0 or 0.4, 0.35})
						end
					else
						for _,v in pairs(Options) do
							local Slt = v.Value == Selected
							local nodes = v.nodes
							CreateTween({nodes[2], "BackgroundTransparency", Slt and 0 or 1, 0.35})
							CreateTween({nodes[2], "Size", Slt and UDim2.fromOffset(4, 14) or UDim2.fromOffset(4, 4), 0.35})
							CreateTween({nodes[3], "TextTransparency", Slt and 0 or 0.4, 0.35})
						end
					end
					UpdateLabel()
				end
				local function Select(Option)
					if MultiSelect then
						Option.Stats = not Option.Stats
						Option.LastCB = tick()
						Selected[Option.Name] = Option.Stats
						CallbackSelected()
					else
						Option.LastCB = tick()
						Selected = Option.Value
						CallbackSelected()
					end
					UpdateSelected()
				end
				AddOption = function(index, Value)
					local Name = tostring(type(index) == "string" and index or Value)
					if Options[Name] then return end
					Options[Name] = {
						index = index,
						Value = Value,
						Name = Name,
						Stats = false,
						LastCB = 0
					}
					if MultiSelect then
						local Stats = Selected[Name]
						Selected[Name] = Stats or false
						Options[Name].Stats = Stats
					end
					local Button = Make("Button", ScrollFrame, {
						Name = "Option",
						Size = UDim2.new(1, 0, 0, 21),
						Position = UDim2.new(0, 0, 0.5),
						AnchorPoint = Vector2.new(0, 0.5)
					})Make("Corner", Button, UDim.new(0, 4))
					local IsSelected = InsertTheme(Create("Frame", Button, {
    Position = UDim2.new(0, 1, 0.5),
    Size = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0, 0.5)
					}), "Theme")
					local gradient = Instance.new("UIGradient")
					gradient.Color = ColorSequence.new({
					  ColorSequenceKeypoint.new(0, Color3.fromRGB(253, 77, 123)),
					  ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 46, 98))
					})
					gradient.Rotation = 90
					gradient.Parent = IsSelected
					Make("Corner", IsSelected, UDim.new(0.5, 0))
					local OptioneName = InsertTheme(Create("TextLabel", Button, {
						Size = UDim2.new(1, 0, 1),
						Position = UDim2.new(0, 10),
						Text = Name,
						TextColor3 = Theme["Color Text"],
						Font = Enum.Font.GothamBold,
						TextXAlignment = "Left",
						BackgroundTransparency = 1,
						TextTransparency = 0.4
					}), "Text")
					Button.Activated:Connect(function()
						Select(Options[Name])
					end)
					Options[Name].nodes = {Button, IsSelected, OptioneName}
				end
				RemoveOption = function(index, Value)
					local Name = tostring(type(index) == "string" and index or Value)
					if Options[Name] then
						if MultiSelect then Selected[Name] = nil else Selected = nil end
						Options[Name].nodes[1]:Destroy()
						table.clear(Options[Name])
						Options[Name] = nil
					end
				end
				GetOptions = function()
					return Options
				end
				AddNewOptions = function(List, Clear)
					if Clear then
						table.foreach(Options, RemoveOption)
					end
					table.foreach(List, AddOption)
					CallbackSelected()
					UpdateSelected()
				end
				table.foreach(DOptions, AddOption)
				CallbackSelected()
				UpdateSelected()
			end
			Button.Activated:Connect(Minimize)
			NoClickFrame.MouseButton1Down:Connect(Disable)
			NoClickFrame.MouseButton1Click:Connect(Disable)
			MainFrame:GetPropertyChangedSignal("Visible"):Connect(Disable)
			SelectedFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(CalculatePos)
			Button.Activated:Connect(CalculateSize)
			ScrollFrame.ChildAdded:Connect(CalculateSize)
			ScrollFrame.ChildRemoved:Connect(CalculateSize)
			CalculatePos()
			CalculateSize()
			local Dropdown = {}
			function Dropdown:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Dropdown:Destroy() Button:Destroy() end
			function Dropdown:Callback(...) Funcs:InsertCallback(Callback, ...)(Selected) end
			function Dropdown:Add(...)
				local NewOptions = {...}
				if type(NewOptions[1]) == "table" then
					table.foreach(NewOptions[1], function(_,Name)
						AddOption(Name)
					end)
				else
					table.foreach(NewOptions, function(_,Name)
						AddOption(Name)
					end)
				end
			end
			function Dropdown:Remove(Option)
				for index, Value in pairs(GetOptions()) do
					if type(Option) == "number" and index == Option or Value.Name == "Option" then
						RemoveOption(index, Value.Value)
					end
				end
			end
			function Dropdown:Select(Option)
				if type(Option) == "string" then
					for _,Val in pairs(Options) do
						if Val.Name == Option then
							Select(Val)
						end
					end
				elseif type(Option) == "number" then
					for ind,Val in pairs(Options) do
						if ind == Option then
							Select(Val)
						end
					end
				end
			end
			function Dropdown:Set(Val1, Clear)
				if type(Val1) == "table" then
					AddNewOptions(Val1, not Clear)
				elseif type(Val1) == "function" then
					Callback = Val1
				end
			end
			return Dropdown
		end
		function Tab:AddSlider(Configs)
			local SName = Configs[1] or Configs.Name or Configs.Title or "Slider!"
			local SDesc = Configs.Desc or Configs.Description or ""
			local Min = Configs[2] or Configs.MinValue or Configs.Min or 10
			local Max = Configs[3] or Configs.MaxValue or Configs.Max or 100
			local Increase = Configs[4] or Configs.Increase or 1
			local Callback = Funcs:GetCallback(Configs, 6)
			local Flag = Configs[7] or Configs.Flag or false
			local Default = Configs[5] or Configs.Default or 25
			if CheckFlag(Flag) then Default = GetFlag(Flag) end
			Min, Max = Min / Increase, Max / Increase
			local Button, LabelFunc = ButtonFrame(Container, SName, SDesc, UDim2.new(1, -180))
			local SliderHolder = Create("TextButton", Button, {
				Size = UDim2.new(0.45, 0, 1),
				Position = UDim2.new(1),
				AnchorPoint = Vector2.new(1, 0),
				AutoButtonColor = false,
				Text = "",
				BackgroundTransparency = 1
			})
			local SliderBar = InsertTheme(Create("Frame", SliderHolder, {
				BackgroundColor3 = Theme["Color Stroke"],
				Size = UDim2.new(1, -20, 0, 6),
				Position = UDim2.new(0.5, 0, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5)
			}), "Stroke")Make("Corner", SliderBar)
			local Indicator = InsertTheme(Create("Frame", SliderBar, {
    Size = UDim2.fromScale(0.3, 1),
    BorderSizePixel = 0,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			}), "Theme")
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
			  ColorSequenceKeypoint.new(0, Color3.fromRGB(253, 77, 123)),
			  ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 46, 98))
			})
			gradient.Rotation = 0
			gradient.Parent = Indicator
			Make("Corner", Indicator)
			local SliderIcon = Create("Frame", SliderBar, {
				Size = UDim2.new(0, 6, 0, 12),
				BackgroundColor3 = Color3.fromRGB(220, 220, 220),
				Position = UDim2.fromScale(0.3, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 0.2
			})Make("Corner", SliderIcon)
			local LabelVal = InsertTheme(Create("TextLabel", SliderHolder, {
				Size = UDim2.new(0, 14, 0, 14),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0, 0, 0.5),
				BackgroundTransparency = 1,
				TextColor3 = Theme["Color Text"],
				Font = Enum.Font.GothamMedium,
				TextSize = 12
			}), "Text")
			local UIScale = Create("UIScale", LabelVal)
			local BaseMousePos = Create("Frame", SliderBar, {
				Position = UDim2.new(0, 0, 0.5, 0),
				Visible = false
			})
			local function UpdateLabel(NewValue)
				local Number = tonumber(NewValue * Increase)
				Number = math.floor(Number * 100) / 100
				Default, LabelVal.Text = Number, tostring(Number)
				Funcs:FireCallback(Callback, Default)
			end
			local function ControlPos()
				local MousePos = Player:GetMouse()
				local APos = MousePos.X - BaseMousePos.AbsolutePosition.X
				local ConfigureDpiPos = APos / SliderBar.AbsoluteSize.X
				SliderIcon.Position = UDim2.new(math.clamp(ConfigureDpiPos, 0, 1), 0, 0.5, 0)
			end
			local function UpdateValues()
				Indicator.Size = UDim2.new(SliderIcon.Position.X.Scale, 0, 1, 0)
				local SliderPos = SliderIcon.Position.X.Scale
				local NewValue = math.floor(((SliderPos * Max) / Max) * (Max - Min) + Min)
				UpdateLabel(NewValue)
			end
			SliderHolder.MouseButton1Down:Connect(function()
				CreateTween({SliderIcon, "Transparency", 0, 0.3})
				Container.ScrollingEnabled = false
				while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do task.wait()
					ControlPos()
				end
				CreateTween({SliderIcon, "Transparency", 0.2, 0.3})
				Container.ScrollingEnabled = true
				SetFlag(Flag, Default)
			end)
			local function SetSlider(NewValue)
				if type(NewValue) ~= "number" then return end
				local Min, Max = Min * Increase, Max * Increase
				local SliderPos = (NewValue - Min) / (Max - Min)
				SetFlag(Flag, NewValue)
				CreateTween({ SliderIcon, "Position", UDim2.fromScale(math.clamp(SliderPos, 0, 1), 0.5), 0.3, true })
			end;SetSlider(Default)
			SliderIcon:GetPropertyChangedSignal("Position"):Connect(UpdateValues)UpdateValues()
			local Slider = {}
			function Slider:Set(NewVal1, NewVal2)
				if NewVal1 and NewVal2 then
					LabelFunc:SetTitle(NewVal1)
					LabelFunc:SetDesc(NewVal2)
				elseif type(NewVal1) == "string" then
					LabelFunc:SetTitle(NewVal1)
				elseif type(NewVal1) == "function" then
					Callback = NewVal1
				elseif type(NewVal1) == "number" then
					SetSlider(NewVal1)
				end
			end
			function Slider:Callback(...) Funcs:InsertCallback(Callback, ...)(tonumber(Default)) end
			function Slider:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Slider:Destroy() Button:Destroy() end
			return Slider
		end
		function Tab:AddTextBox(Configs)
			local TName = Configs[1] or Configs.Name or Configs.Title or "Text Box"
			local TDesc = Configs.Desc or Configs.Description or ""
			local TDefault = Configs[2] or Configs.Default or ""
			local TPlaceholderText = Configs[5] or Configs.PlaceholderText or "Input"
			local TClearText = Configs[3] or Configs.ClearText or false
			local Callback = Funcs:GetCallback(Configs, 4)
			if type(TDefault) ~= "string" or TDefault:gsub(" ", ""):len() < 1 then
				TDefault = false
			end
			local Button, LabelFunc = ButtonFrame(Container, TName, TDesc, UDim2.new(1, -38))
			local SelectedFrame = InsertTheme(Create("Frame", Button, {
				Size = UDim2.new(0, 150, 0, 18),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Theme["Color Stroke"]
			}), "Stroke")Make("Corner", SelectedFrame, UDim.new(0, 4))
			local TextBoxInput = InsertTheme(Create("TextBox", SelectedFrame, {
				Size = UDim2.new(0.85, 0, 0.85, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
				TextColor3 = Theme["Color Text"],
				ClearTextOnFocus = TClearText,
				PlaceholderText = TPlaceholderText,
				Text = ""
			}), "Text")
			local Pencil = Create("ImageLabel", SelectedFrame, {
				Size = UDim2.new(0, 12, 0, 12),
				Position = UDim2.new(0, -5, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				Image = "",
				BackgroundTransparency = 1
			})
			local TextBox = {}
			local function Input()
				local Text = TextBoxInput.Text
				if Text:gsub(" ", ""):len() > 0 then
					if TextBox.OnChanging then Text = TextBox.OnChanging(Text) or Text end
					Funcs:FireCallback(Callback, Text)
					TextBoxInput.Text = Text
				end
			end
			TextBoxInput.FocusLost:Connect(Input)Input()
			TextBoxInput.FocusLost:Connect(function()
				CreateTween({Pencil, "ImageColor3", Color3.fromRGB(255, 255, 255), 0.2})
			end)
			TextBoxInput.Focused:Connect(function()
				CreateTween({Pencil, "ImageColor3", Theme["Color Theme"], 0.2})
			end)
			TextBox.OnChanging = false
			function TextBox:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function TextBox:Destroy() Button:Destroy() end
			return TextBox
		end
		
        function Tab:AddGameSupport(Configs)
	local PlaceId = Configs.LogoID or Configs.PlaceId or Configs.GameId or 0
	local LastUpdateDate = Configs.LastUpdate or nil

	local function parseDate(dateStr)
		if not dateStr then return nil end
		local day, month, year = dateStr:match("(%d+)/(%d+)/(%d+)")
		if day and month and year then
			return os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day), hour=0, min=0})
		end
		return os.time()
	end

	local function DataAtualizacao(dataInicio)
		if not dataInicio then return "undefined" end
		
		local agora = os.time()
		local diff = agora - dataInicio

		if diff < 60 then
			return diff .. " seconds ago"
		elseif diff < 3600 then
			local minutos = math.floor(diff / 60)
			return minutos == 1 and "1 minute ago" or minutos .. " minutes ago"
		elseif diff < 86400 then
			local horas = math.floor(diff / 3600)
			return horas == 1 and "1 hour ago" or horas .. " hours ago"
		else
			local dias = math.floor(diff / 86400)
			if dias < 7 then
				return dias == 1 and "1 day ago" or dias .. " days ago"
			elseif dias < 30 then
				local semanas = math.floor(dias / 7)
				return semanas == 1 and "1 week ago" or semanas .. " weeks ago"
			elseif dias < 365 then
				local meses = math.floor(dias / 30)
				return meses == 1 and "1 month ago" or meses .. " months ago"
			else
				local anos = math.floor(dias / 365)
				return anos == 1 and "1 year ago" or anos .. " years ago"
			end
		end
	end

	local updateTimestamp = parseDate(LastUpdateDate)

	-- Container principal
	local GameSupportHolder = Create("Frame", Container, {
		Size = UDim2.new(1, 0, 0, 55),
		Name = "Option",
		BackgroundTransparency = 1,
		ClipsDescendants = false
	})

	-- TopBar
	local TopBar = InsertTheme(Create("TextButton", GameSupportHolder, {
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundColor3 = Theme["Color Hub 2"],
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = false
	}), "Frame")
	Make("Corner", TopBar, UDim.new(0, 8))

	local GameIcon = Create("ImageLabel", TopBar, {
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(0, 7, 0, 7),
		Image = "",
		BackgroundTransparency = 1
	})
	Make("Corner", GameIcon, UDim.new(0, 6))
	Make("Stroke", GameIcon)

	local GameTitle = InsertTheme(Create("TextLabel", TopBar, {
		Size = UDim2.new(1, -90, 0, 20),
		Position = UDim2.new(0, 54, 0, 10),
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 12,
		Text = "Loading...",
		TextTruncate = "AtEnd"
	}), "Text")

	local CreatorLabel = InsertTheme(Create("TextLabel", TopBar, {
		Size = UDim2.new(1, -90, 0, 16),
		Position = UDim2.new(0, 54, 0, 30),
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(180, 180, 180),
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 9,
		Text = "By: Loading...",
		TextTruncate = "AtEnd"
	}), "DarkText")

	local ArrowIcon = Create("ImageLabel", TopBar, {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -30, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Image = "rbxassetid://10709791523",
		BackgroundTransparency = 1,
		Rotation = 180
	})

	-- Painel expansível
	local ExpandPanel = InsertTheme(Create("Frame", GameSupportHolder, {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 47),
		BackgroundColor3 = Theme["Color Hub 2"],
		ClipsDescendants = true,
		BorderSizePixel = 0
	}), "Frame")
	Make("Corner", ExpandPanel, UDim.new(0, 8))

	local PanelContent = Create("Frame", ExpandPanel, {
		Size = UDim2.new(1, -14, 1, -20),
		Position = UDim2.new(0, 7, 0, 12),
		BackgroundTransparency = 1
	}, {
		Create("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder
		})
	})

	local UpdateLabel = InsertTheme(Create("TextLabel", PanelContent, {
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 10,
		Text = "Last Update: " .. DataAtualizacao(updateTimestamp),
		LayoutOrder = 1,
		RichText = true,
		TextTransparency = 1
	}), "DarkText")

	local LinkLabelPrefix = InsertTheme(Create("TextLabel", PanelContent, {
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 10,
		Text = "Link: ",
		LayoutOrder = 2,
		RichText = true,
		TextTransparency = 1
	}), "DarkText")

	local CopyButtonContainer = Create("Frame", ExpandPanel, {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 1, -36),
		BackgroundTransparency = 1
	})

    local CopyButton = InsertTheme(Create("TextButton", CopyButtonContainer, {
        Size = UDim2.new(0.45, 0, 0, 24),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "Copy Game Link",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Theme["Color Text"],
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        AutoButtonColor = false,
        TextTransparency = 1
    }), "Frame")
    Make("Corner", CopyButton, UDim.new(0, 6))

    local CopyButtonStroke = Create("UIStroke", CopyButton, {
        Color = Color3.fromRGB(60, 60, 60),
        Thickness = 1,
        Transparency = 0.7
    })

    CopyButton.MouseEnter:Connect(function()
        local tween1 = TweenService:Create(CopyButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        })
        local tween2 = TweenService:Create(CopyButtonStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Color = Color3.fromRGB(80, 80, 80)
        })
        tween1:Play()
        tween2:Play()
    end)

    CopyButton.MouseLeave:Connect(function()
        local tween1 = TweenService:Create(CopyButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        })
        local tween2 = TweenService:Create(CopyButtonStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Color = Color3.fromRGB(60, 60, 60)
        })
        tween1:Play()
        tween2:Play()
    end)
	Make("Corner", CopyButton, UDim.new(0, 6))

	local isExpanded = false
	local isAnimating = false
	local gameLink = ""

	local function setGameInfo(placeId)
		task.spawn(function()
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(placeId, Enum.InfoType.Asset)
			end)

			if success and info then
				GameIcon.Image = "rbxassetid://" .. (info.IconImageAssetId or "")
				GameTitle.Text = info.Name or "Unknown"
				CreatorLabel.Text = "By: " .. (info.Creator and info.Creator.Name or "Unknown")
				gameLink = "https://www.roblox.com/games/" .. placeId
				LinkLabelPrefix.Text = 'Link: <font color="rgb(100,150,255)"><u>'..gameLink..'</u></font>'
			end
		end)
	end

	if updateTimestamp then
		task.spawn(function()
			while GameSupportHolder.Parent do
				local timeAgo = DataAtualizacao(updateTimestamp)
				UpdateLabel.Text = 'Last Update: '..timeAgo
				task.wait(30)
			end
		end)
	end

	local function togglePanel()
		if isAnimating then return end
		isAnimating = true
		isExpanded = not isExpanded

		if isExpanded then
			CreateTween({GameSupportHolder, "Size", UDim2.new(1,0,0,145), 0.35})
			CreateTween({ExpandPanel, "Size", UDim2.new(1,0,0,90), 0.35})
			CreateTween({ArrowIcon, "Rotation", 360, 0.35})

			-- Aparecer elementos rapidamente
			CreateTween({UpdateLabel, "TextTransparency", 0, 0.15})
			CreateTween({LinkLabelPrefix, "TextTransparency", 0, 0.15})
			CreateTween({CopyButton, "TextTransparency", 0, 0.15})
		else
			-- Sumir rapidamente
			CreateTween({UpdateLabel, "TextTransparency", 1, 0.1})
			CreateTween({LinkLabelPrefix, "TextTransparency", 1, 0.1})
			CreateTween({CopyButton, "TextTransparency", 1, 0.1})

			CreateTween({GameSupportHolder, "Size", UDim2.new(1,0,0,55), 0.35})
			CreateTween({ExpandPanel, "Size", UDim2.new(1,0,0,0), 0.35})
			CreateTween({ArrowIcon, "Rotation", 180, 0.35})
		end

		task.wait(0.35)
		isAnimating = false
	end

	TopBar.Activated:Connect(togglePanel)

	CopyButton.Activated:Connect(function()
		if gameLink == "" then return end
		setclipboard(gameLink)
	end)

	if PlaceId > 0 then
		setGameInfo(PlaceId)
	end

	local GameSupport = {}

	function GameSupport:Destroy()
		GameSupportHolder:Destroy()
	end

	function GameSupport:Visible(...)
		Funcs:ToggleVisible(GameSupportHolder, ...)
	end

	function GameSupport:Expand()
		if not isExpanded then togglePanel() end
	end

	function GameSupport:Collapse()
		if isExpanded then togglePanel() end
	end

	return GameSupport
end

function Tab:AddServerInfo(Configs)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")
	local TweenService = game:GetService("TweenService")
	
	-- Obter versão do script (se fornecida)
	local ScriptVersion = Configs.ScriptVersion or "Nil"
	
	-- Container principal (fundo cinza claro) - ALTURA AUMENTADA
	local ServerInfoHolder = Create("Frame", Container, {
		Size = UDim2.new(1, 0, 0, 490),
		Name = "ServerInfo",
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
		ClipsDescendants = false
	})
	Make("Corner", ServerInfoHolder, UDim.new(0, 8))

	-- Layout principal
	local MainLayout = Create("UIListLayout", ServerInfoHolder, {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center
	})

	local MainPadding = Create("UIPadding", ServerInfoHolder, {
		PaddingTop = UDim.new(0, 15),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12)
	})

	-- ==================== LOGO ====================
	local LogoContainer = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		ClipsDescendants = false
	})

	-- Imagem de fundo atrás do logo
	local LogoBackground = Create("ImageLabel", LogoContainer, {
    Size = UDim2.fromOffset(576, 146),
    Position = UDim2.new(0.5, 0, 0, -31),  -- Y negativo para subir
    AnchorPoint = Vector2.new(0.5, 0),     -- meio horizontal, topo vertical
    BackgroundTransparency = 1,
    Image = "rbxassetid://106706117462124",
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 1
})


	-- Logo principal
	local Logo = Create("ImageLabel", LogoContainer, {
		Size = UDim2.fromOffset(560, 140),
		Position = UDim2.new(0.5, -280, 0.5, -70),
		BackgroundTransparency = 1,
		Image = "rbxassetid://120841455936754",
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2
	})

	-- ==================== SCRIPT INFO ====================
	local ScriptInfoHeaderContainer = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1
	})

	local ScriptInfoHeaderAccent = Create("Frame", ScriptInfoHeaderContainer, {
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 75, 129),
		BorderSizePixel = 0
	})
	Make("Corner", ScriptInfoHeaderAccent, UDim.new(1, 0))

	local ScriptInfoHeader = InsertTheme(Create("TextLabel", ScriptInfoHeaderContainer, {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 13,
		Text = "SCRIPT INFO"
	}), "Text")

	-- ==================== INFO BANNER ====================
	local InfoBanner = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		LayoutOrder = 2
	})
	Make("Corner", InfoBanner, UDim.new(0, 8))

	-- Borda sutil
	local BannerStroke = Create("UIStroke", InfoBanner, {
		Color = Color3.fromRGB(255, 75, 129),
		Thickness = 1,
		Transparency = 0.7
	})

	local BannerShadow = Create("ImageLabel", InfoBanner, {
		Size = UDim2.new(1, 6, 1, 6),
		Position = UDim2.new(0, -3, 0, -3),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.7,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = 0
	})

	local BannerPadding = Create("UIPadding", InfoBanner, {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12)
	})

	-- Texto de mensagem
	local MessageText = InsertTheme(Create("TextLabel", InfoBanner, {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextXAlignment = "Center",
		Text = "This is a free script. If you paid for it, you've probably been scammed.",
		TextWrapped = true
	}), "Text")

	-- Container da versão do script (LADO ESQUERDO)
	local VersionContainer = Create("Frame", InfoBanner, {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 16),
		BackgroundTransparency = 1
	})

	local VersionLabel = InsertTheme(Create("TextLabel", VersionContainer, {
		Size = UDim2.new(0, 90, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		Text = "Funcs&Stuff:"
	}), "Text")

	local VersionValue = InsertTheme(Create("TextLabel", VersionContainer, {
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(0, 64, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 75, 129),
		TextXAlignment = "Left",
		Text = ScriptVersion
	}), "Text")

	-- Container do Creator (LADO ESQUERDO)
	local CreatorContainer = Create("Frame", InfoBanner, {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 34),
		BackgroundTransparency = 1
	})

	local CreatorLabel = InsertTheme(Create("TextLabel", CreatorContainer, {
		Size = UDim2.new(0, 55, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		Text = "Creator:"
	}), "Text")

	-- Botão do nome do criador
	local CreatorButton = Create("TextButton", CreatorContainer, {
		Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 75, 129),
		Text = "rbnwonknui",
		TextXAlignment = "Left",
		AutoButtonColor = false
	})

	-- Feedback de cópia
	local CopyFeedback = InsertTheme(Create("TextLabel", CreatorContainer, {
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 125, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = Color3.fromRGB(100, 255, 100),
		TextXAlignment = "Left",
		Text = "✓ Link copied!",
		Visible = false
	}), "Text")

	-- Animação de hover no botão
	CreatorButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(CreatorButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			TextColor3 = Color3.fromRGB(255, 95, 149)
		})
		tween:Play()
	end)

	CreatorButton.MouseLeave:Connect(function()
		CopyFeedback.Visible = false
		local tween = TweenService:Create(CreatorButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			TextColor3 = Color3.fromRGB(255, 75, 129)
		})
		tween:Play()
	end)

	-- Copiar link ao clicar
	CreatorButton.MouseButton1Click:Connect(function()
		setclipboard("https://scriptblox.com/u/rbnwonknui")
		CopyFeedback.Visible = true
		
		-- Animação de clique
		local clickTween = TweenService:Create(CreatorButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
			TextColor3 = Color3.fromRGB(235, 55, 109)
		})
		clickTween:Play()
		clickTween.Completed:Connect(function()
			local backTween = TweenService:Create(CreatorButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
				TextColor3 = Color3.fromRGB(255, 95, 149)
			})
			backTween:Play()
		end)
		
		-- Esconder feedback após 2 segundos
		task.delay(2, function()
			CopyFeedback.Visible = false
		end)
	end)

	-- ==================== PLAYER INFO PANEL ====================
	local PlayerHeaderContainer = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 3
	})

	local PlayerHeaderAccent = Create("Frame", PlayerHeaderContainer, {
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 75, 129),
		BorderSizePixel = 0
	})
	Make("Corner", PlayerHeaderAccent, UDim.new(1, 0))

	local PlayerHeader = InsertTheme(Create("TextLabel", PlayerHeaderContainer, {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 13,
		Text = "PLAYER INFO"
	}), "Text")

	local PlayerInfoPanel = InsertTheme(Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		LayoutOrder = 4
	}), "Frame")
	Make("Corner", PlayerInfoPanel, UDim.new(0, 8))

	local PlayerPanelStroke = Create("UIStroke", PlayerInfoPanel, {
		Color = Color3.fromRGB(255, 75, 129),
		Thickness = 1,
		Transparency = 0.7
	})

	local PlayerPanelShadow = Create("ImageLabel", PlayerInfoPanel, {
		Size = UDim2.new(1, 6, 1, 6),
		Position = UDim2.new(0, -3, 0, -3),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.7,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = 0
	})

	local PlayerInfoContent = Create("Frame", PlayerInfoPanel, {
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1
	})

	local PlayerInfoLayout = Create("UIListLayout", PlayerInfoContent, {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	-- FPS
	local FPSContainer = Create("Frame", PlayerInfoContent, {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 1
	})

	local FPSIcon = Create("ImageLabel", FPSContainer, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://129508130650899",
		ScaleType = Enum.ScaleType.Fit
	})

	local FPSLabel = InsertTheme(Create("TextLabel", FPSContainer, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(100, 255, 100),
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 11,
		Text = "FPS: 0"
	}), "Text")

	-- Ping
	local PingContainer = Create("Frame", PlayerInfoContent, {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 2
	})

	local PingIcon = Create("ImageLabel", PingContainer, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://84672581284713",
		ScaleType = Enum.ScaleType.Fit
	})

	local PingLabel = InsertTheme(Create("TextLabel", PingContainer, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.fromRGB(100, 255, 100),
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 11,
		Text = "Ping: 0"
	}), "Text")

	-- Executor
	local ExecutorContainer = Create("Frame", PlayerInfoContent, {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 3
	})

	local ExecutorIcon = Create("ImageLabel", ExecutorContainer, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://120651216042959",
		ScaleType = Enum.ScaleType.Fit
	})

	local ExecutorLabel = InsertTheme(Create("TextLabel", ExecutorContainer, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.Gotham,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 11,
		Text = "Executor:"
	}), "Text")

	-- ==================== SERVER INFO PANEL ====================
	local ServerHeaderContainer = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 5
	})

	local ServerHeaderAccent = Create("Frame", ServerHeaderContainer, {
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 75, 129),
		BorderSizePixel = 0
	})
	Make("Corner", ServerHeaderAccent, UDim.new(1, 0))

	local ServerHeader = InsertTheme(Create("TextLabel", ServerHeaderContainer, {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 13,
		Text = "SERVER INFO"
	}), "Text")

	local ServerInfoPanel = InsertTheme(Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		LayoutOrder = 6
	}), "Frame")
	Make("Corner", ServerInfoPanel, UDim.new(0, 8))

	local ServerPanelStroke = Create("UIStroke", ServerInfoPanel, {
		Color = Color3.fromRGB(255, 75, 129),
		Thickness = 1,
		Transparency = 0.7
	})

	local ServerPanelShadow = Create("ImageLabel", ServerInfoPanel, {
		Size = UDim2.new(1, 6, 1, 6),
		Position = UDim2.new(0, -3, 0, -3),
		BackgroundTransparency = 1,
		Image = "rbxassetid://5554236805",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.7,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		ZIndex = 0
	})

	local ServerInfoContent = Create("Frame", ServerInfoPanel, {
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1
	})

	local ServerInfoLayout = Create("UIListLayout", ServerInfoContent, {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	-- Region
	local RegionContainer = Create("Frame", ServerInfoContent, {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 1
	})

	local RegionIcon = Create("ImageLabel", RegionContainer, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://120794955899997",
		ScaleType = Enum.ScaleType.Fit
	})

	local RegionLabel = InsertTheme(Create("TextLabel", RegionContainer, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.Gotham,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 11,
		Text = "Region: BR"
	}), "Text")

	-- Players
	local PlayersContainer = Create("Frame", ServerInfoContent, {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 2
	})

	local PlayersIcon = Create("ImageLabel", PlayersContainer, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://125463309381304",
		ScaleType = Enum.ScaleType.Fit
	})

	local PlayersLabel = InsertTheme(Create("TextLabel", PlayersContainer, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.Gotham,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 11,
		Text = "Players: 0"
	}), "Text")

	-- Max Players
	local MaxPlayersContainer = Create("Frame", ServerInfoContent, {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		LayoutOrder = 3
	})

	local MaxPlayersIcon = Create("ImageLabel", MaxPlayersContainer, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://101838318173327",
		ScaleType = Enum.ScaleType.Fit
	})

	local MaxPlayersLabel = InsertTheme(Create("TextLabel", MaxPlayersContainer, {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = Enum.Font.Gotham,
		TextColor3 = Theme["Color Text"],
		TextXAlignment = "Left",
		BackgroundTransparency = 1,
		TextSize = 11,
		Text = "Max Players: " .. Players.MaxPlayers
	}), "Text")

	-- ==================== SERVER ACTIONS BUTTONS ====================
	local ButtonsContainer = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 7
	})

	local ButtonsLayout = Create("UIListLayout", ButtonsContainer, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center
	})

	-- Função para animar mudança de cor
	local function animateColor(object, property, targetColor)
		local tween = TweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			[property] = targetColor
		})
		tween:Play()
	end

	-- Função para criar botão
	local function CreateServerButton(name, order, callback)
		local Button = InsertTheme(Create("TextButton", ButtonsContainer, {
			Size = UDim2.new(0.32, -4, 1, 0),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextColor3 = Theme["Color Text"],
			TextSize = 10,
			Text = name,
			LayoutOrder = order,
			AutoButtonColor = false
		}), "Frame")
		Make("Corner", Button, UDim.new(0, 6))

		local ButtonStroke = Create("UIStroke", Button, {
			Color = Color3.fromRGB(60, 60, 60),
			Thickness = 1,
			Transparency = 0.7
		})

		local Icon = Create("ImageLabel", Button, {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(1, -14, 0.5, -6),
			BackgroundTransparency = 1,
			Image = "rbxassetid://10709791437",
			ImageColor3 = Color3.fromRGB(255, 75, 129),
			ScaleType = Enum.ScaleType.Fit
		})

		Button.MouseEnter:Connect(function()
			animateColor(Button, "BackgroundColor3", Color3.fromRGB(30, 30, 30))
			animateColor(ButtonStroke, "Color", Color3.fromRGB(80, 80, 80))
		end)

		Button.MouseLeave:Connect(function()
			animateColor(Button, "BackgroundColor3", Color3.fromRGB(20, 20, 20))
			animateColor(ButtonStroke, "Color", Color3.fromRGB(60, 60, 60))
		end)

		Button.MouseButton1Click:Connect(callback)

		return Button
	end

	-- Server Rejoin
	CreateServerButton("Server Rejoin", 1, function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
	end)

	-- Server Hop
	CreateServerButton("Server Hop", 2, function()
		local servers = nil
		pcall(function()
			servers = game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
		end)

		if type(servers) == "table" then
			local jobIds = {}
			for i, v in pairs(servers) do
				if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= game.JobId then
					table.insert(jobIds, v.id)
				end
			end
			
			if #jobIds > 0 then
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, jobIds[math.random(1, #jobIds)])
			end
		end
	end)

	-- Server Ascending
	CreateServerButton("Server Ascending", 3, function()
		local Http = game:GetService("HttpService")
		local TPS = game:GetService("TeleportService")
		local Api = "https://games.roblox.com/v1/games/"

		local _place = game.PlaceId
		local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"

		function ListServers(cursor)
			local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
			return Http:JSONDecode(Raw)
		end

		local Server, Next
		repeat
			local Servers = ListServers(Next)
			Server = Servers.data[1]
			Next = Servers.nextPageCursor
		until Server

		TPS:TeleportToPlaceInstance(_place, Server.id, game.Players.LocalPlayer)
	end)

	-- ==================== DESTROY GUI BUTTON ====================
	local DestroyButtonContainer = Create("Frame", ServerInfoHolder, {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 8
	})

	local Theme = antoralib.Themes[antoralib.Save.Theme]
	local DestroyButton = InsertTheme(Create("TextButton", DestroyButtonContainer, {
		Size = UDim2.new(0.95, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme["Color Text"],
		TextSize = 10,
		Text = "Close Hub",
		AutoButtonColor = false
	}), "Frame")
	Make("Corner", DestroyButton, UDim.new(0, 6))

	local DestroyStroke = Create("UIStroke", DestroyButton, {
		Color = Color3.fromRGB(60, 60, 60),
		Thickness = 1,
		Transparency = 0.7
	})

	local DestroyIcon = Create("ImageLabel", DestroyButton, {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -14, 0.5, -6),
		BackgroundTransparency = 1,
		Image = "rbxassetid://10709791437",
		ImageColor3 = Color3.fromRGB(255, 75, 129),
		ScaleType = Enum.ScaleType.Fit
	})

	-- Animações do botão Destroy
	DestroyButton.MouseEnter:Connect(function()
		animateColor(DestroyButton, "BackgroundColor3", Color3.fromRGB(30, 30, 30))
		animateColor(DestroyStroke, "Color", Color3.fromRGB(80, 80, 80))
	end)

	DestroyButton.MouseLeave:Connect(function()
		animateColor(DestroyButton, "BackgroundColor3", Color3.fromRGB(20, 20, 20))
		animateColor(DestroyStroke, "Color", Color3.fromRGB(60, 60, 60))
	end)

	-- Função para destruir o GUI
	DestroyButton.MouseButton1Click:Connect(function()
		-- Animação antes de destruir
		local fadeOut = TweenService:Create(ServerInfoHolder, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1
		})
		fadeOut:Play()
		
		-- Procurar e destruir o ScreenGui principal
		local ScreenGui = ServerInfoHolder:FindFirstAncestorOfClass("ScreenGui")
		if ScreenGui then
			task.wait(0.3)
			ScreenGui:Destroy()
		end
	end)

	-- Funções auxiliares
	local function getPing()
		return Stats.Network.ServerStatsItem['Data Ping']:GetValue()
	end

	local lastFrameTime = tick()
	local frameCount = 0
	local currentFPS = 0

	local function getExecutor()
		if identifyexecutor then
			return identifyexecutor()
		elseif getexecutorname then
			return getexecutorname()
		elseif get_hui_ani then
			return get_hui_ani()
		else
			return "Roblox Player"
		end
	end

	-- Obter região
	task.spawn(function()
		local success, region = pcall(function()
			return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(Players.LocalPlayer)
		end)
		if success and region then
			RegionLabel.Text = "Region: " .. region
		else
			RegionLabel.Text = "Region: Unknown"
		end
	end)

	-- Definir Executor
	ExecutorLabel.Text = "Executor: " .. getExecutor()

	-- Loop FPS
	task.spawn(function()
		while ServerInfoHolder.Parent do
			frameCount = frameCount + 1
			local currentTime = tick()
			local deltaTime = currentTime - lastFrameTime
			
			if deltaTime >= 1 then
				currentFPS = math.floor(frameCount / deltaTime)
				frameCount = 0
				lastFrameTime = currentTime
				FPSLabel.Text = "FPS: " .. currentFPS
				
				if currentFPS >= 60 then
					animateColor(FPSLabel, "TextColor3", Color3.fromRGB(100, 255, 100))
				elseif currentFPS >= 30 then
					animateColor(FPSLabel, "TextColor3", Color3.fromRGB(255, 200, 100))
				else
					animateColor(FPSLabel, "TextColor3", Color3.fromRGB(255, 100, 100))
				end
			end
			
			RunService.RenderStepped:Wait()
		end
	end)

	-- Loop Ping
	task.spawn(function()
		while ServerInfoHolder.Parent do
			local currentPing = getPing()
			local pingValue = math.floor(currentPing)
			
			if pingValue > 999 then
				PingLabel.Text = "Ping: 999+"
				animateColor(PingLabel, "TextColor3", Color3.fromRGB(255, 100, 100))
			else
				PingLabel.Text = "Ping: " .. pingValue .. " ms"
				
				if pingValue <= 90 then
					animateColor(PingLabel, "TextColor3", Color3.fromRGB(100, 255, 100))
				elseif pingValue <= 150 then
					animateColor(PingLabel, "TextColor3", Color3.fromRGB(255, 200, 100))
				else
					animateColor(PingLabel, "TextColor3", Color3.fromRGB(255, 100, 100))
				end
			end
			
			task.wait()
		end
	end)

	-- Loop Players
	task.spawn(function()
		while ServerInfoHolder.Parent do
			local playerCount = #Players:GetPlayers()
			PlayersLabel.Text = "Players: " .. playerCount
			task.wait(2)
		end
	end)

	local ServerInfo = {}

	function ServerInfo:Destroy()
		ServerInfoHolder:Destroy()
	end

	function ServerInfo:Visible(...)
		Funcs:ToggleVisible(ServerInfoHolder, ...)
	end

	function ServerInfo:GetFPS()
		return currentFPS
	end

	function ServerInfo:GetPing()
		return getPing()
	end

	function ServerInfo:GetPlayerCount()
		return #Players:GetPlayers()
	end

	return ServerInfo
end

	-- Notification creation function
function Window:Notify(opts)
	opts = opts or {}
	local title = opts.Title or opts[1] or "Notification"
	local content = opts.Content or opts[2] or ""
	local image = opts.Image or opts[3] or ""
	local duration = opts.Duration or opts[4] or 5

	-- Criar NotificationHolder corretamente e só uma vez
	if not Window.NotificationHolder or not Window.NotificationHolder.Parent then
		Window.NotificationHolder = Create("Frame", ScreenGui, {
			Name = "NotificationHolder",
			Size = UDim2.new(0, 280, 1, 0),
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1
		}, {
			Create("UIPadding", {
				PaddingBottom = UDim.new(0, 20)
			}),
			Create("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8)
			})
		})
	end
	local NotificationHolder = Window.NotificationHolder

	local notifFrame = Create("Frame", NotificationHolder, {
		Size = UDim2.new(0.85, 0, 0, 60),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 999999
	})

	local notifScale = Create("UIScale", notifFrame, {
		Scale = 1
	})

	local notifButton = Create("TextButton", notifFrame, {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false,
		Text = "",
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(28, 28, 30)
	})
	Make("Corner", notifButton, UDim.new(0, 9))

	local holder = Create("Frame", notifButton, {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4)
		}),
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 40)
		})
	})

	local notifTitle = Create("TextLabel", holder, {
		Size = UDim2.new(1, 0, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		BackgroundTransparency = 1,
		TextSize = 14,
		Text = title,
		Font = Enum.Font.BuilderSansBold,
		RichText = true,
		TextColor3 = Color3.fromRGB(255, 255, 255)
	})

	local notifContent = Create("TextLabel", holder, {
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 12,
		Text = content,
		Font = Enum.Font.BuilderSans,
		RichText = true,
		TextColor3 = Color3.fromRGB(200, 200, 200)
	})

	local notifIcon = Create("ImageLabel", notifButton, {
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = Color3.fromRGB(232, 233, 235)
	})

	local notifTimer = Create("TextLabel", notifButton, {
		Size = UDim2.new(0, 40, 0, 16),
		Position = UDim2.new(1, -10, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		TextSize = 10,
		Text = "",
		Font = Enum.Font.BuilderSans,
		TextColor3 = Color3.fromRGB(175, 175, 175)
	})

	-- Verificar se é um asset ID válido
	if not image:find("rbxassetid://") or image == "" then
		notifIcon.Visible = false
		holder.UIPadding.PaddingLeft = UDim.new(0, 15)
	end

	local closing = false
	local pressed = false

	-- Função de formatação de tempo (igual ao Redz)
	local function formatTime(seconds)
		local hours = math.floor(seconds / 3600)
		local minutes = math.floor((seconds % 3600) / 60)
		seconds = math.floor((seconds % 60) * 10) / 10

		if hours > 0 then
			return string.format("%dh %dm %ds", hours, minutes, math.floor(seconds))
		elseif minutes > 0 then
			return string.format("%dm %ds", minutes, math.floor(seconds))
		else
			return tostring(seconds)
		end
	end

	local function closeNotification()
		if closing then return end
		closing = true

		local closeTween = CreateTween({notifButton, "Position", UDim2.fromScale(3, 0), 0.8, true})
		closeTween:Play()
		closeTween.Completed:Wait()
		notifFrame:Destroy()
	end

	-- Animação de entrada (igual ao Redz)
	notifButton.Position = UDim2.fromScale(3, 0)
	CreateTween({notifButton, "Position", UDim2.fromScale(0, 0), 0.35})

	-- Tweens de escala (igual ao Redz)
	local scaleUpTween = CreateTween({notifScale, "Scale", 1.22, 0.35})
	local scaleDownTween = CreateTween({notifScale, "Scale", 1.00, 0.35})

	-- Eventos do mouse (comportamento correto)
	notifButton.MouseButton1Down:Connect(function()
		scaleUpTween:Play()
		pressed = true
	end)

	notifButton.MouseButton1Up:Connect(function()
		scaleDownTween:Play()
		pressed = false
	end)

	notifButton.MouseLeave:Connect(function()
		if pressed then
			scaleDownTween:Play()
			pressed = false
		end
	end)

	-- Timer (lógica correta com pausa)
	task.spawn(function()
		while duration > 0 do
			notifTimer.Text = formatTime(duration)
			
			-- Se pressionado, aguarda até soltar
			if pressed == true then
				repeat
					task.wait()
				until pressed == false
			end
			
			duration -= task.wait()
		end

		closeNotification()
	end)

	local Notification = {}
	
	function Notification:Close()
		closeNotification()
	end
	
	function Notification:Destroy()
		closeNotification()
	end
	
	function Notification:Visible(bool)
		if bool == nil then
			notifFrame.Visible = not notifFrame.Visible
		else
			notifFrame.Visible = bool
		end
	end
	
	function Notification:SetTitle(newTitle)
		notifTitle.Text = newTitle
	end
	
	function Notification:SetContent(newContent)
		notifContent.Text = newContent
	end

	return Notification
end

		return Tab
	end
	
	return Window
end

return antoralib