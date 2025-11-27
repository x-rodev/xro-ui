local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local IsLocal,Assets,LocalPlayer = false,{},PlayerService.LocalPlayer
local MainAssetFolder = IsLocal and ReplicatedStorage.BracketV33
	or InsertService:LoadLocalAsset("rbxassetid://10827276896")

local function GetAsset(AssetPath)
	AssetPath = AssetPath:split("/")
	local Asset = MainAssetFolder
	for Index,Name in pairs(AssetPath) do
		Asset = Asset[Name]
	end return Asset:Clone()
end

local function TableToColor(Table)
	if type(Table) ~= "table" then return Table end
	return Color3.fromHSV(Table[1],Table[2],Table[3])
end
local function ColorToString(Color)
	return ("%i,%i,%i"):format(Color.R * 255,Color.G * 255,Color.B * 255)
end
local function Scale(Value,InputMin,InputMax,OutputMin,OutputMax)
	return OutputMin + (Value - InputMin) * (OutputMax - OutputMin) / (InputMax - InputMin)
end
local function DeepCopy(Original)
	local Copy = {}
	for Index,Value in pairs(Original) do
		if type(Value) == "table" then
			Value = DeepCopy(Value)
		end
		Copy[Index] = Value
	end
	return Copy
end
local function Proxify(Table) local Proxy,Events = {},{}
	local ChangedEvent = Instance.new("BindableEvent")
	Table.Changed = ChangedEvent.Event
	Proxy.Internal = Table

	function Table:GetPropertyChangedSignal(Property)
		local PropertyEvent = Instance.new("BindableEvent")
		Events[Property] = Events[Property] or {}
		table.insert(Events[Property],PropertyEvent)
		return PropertyEvent.Event
	end

	setmetatable(Proxy,{
		__index = function(Self,Key)
			return Table[Key]
		end,
		__newindex = function(Self,Key,Value)
			local OldValue = Table[Key]
			Table[Key] = Value

			ChangedEvent:Fire(Key,Value,OldValue)
			if Events[Key] then
				for Index,Event in ipairs(Events[Key]) do
					Event:Fire(Value,OldValue)
				end
			end
		end
	})

	return Proxy
end

local function GetType(Object,Default,Type,UseProxify)
	if typeof(Object) == Type then
		return UseProxify and Proxify(Object) or Object
	end
	return UseProxify and Proxify(Default) or Default
end
local function GetTextBounds(Text,Font,Size)
	return TextService:GetTextSize(Text,Size.Y,Font,Vector2.new(Size.X,1e6))
end

local function MakeDraggable(Dragger, Object, OnTick, OnStop)
    local StartPosition, StartDrag = nil, nil
    local IsDragging = false
    local TouchStartId = nil
    
    local function HandleInputBegan(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
           Input.UserInputType == Enum.UserInputType.Touch then
            
            if Input.UserInputType == Enum.UserInputType.Touch then
                TouchStartId = Input.KeyCode
            end
            
            StartPosition = UserInputService:GetMouseLocation()
            StartDrag = Object.Position
            IsDragging = true
        end
    end
    
    local function HandleInputChanged(Input)
        if IsDragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or 
           (Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState == Enum.UserInputState.Change)) then
            
            if Input.UserInputType == Enum.UserInputType.Touch and TouchStartId then
                if Input.KeyCode ~= TouchStartId then
                    return
                end
            end
            
            local Mouse = UserInputService:GetMouseLocation()
            local Delta = Mouse - StartPosition
            
            OnTick(StartDrag + UDim2.fromOffset(Delta.X, Delta.Y))
        end
    end
    
    local function HandleInputEnded(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton1) or 
           (Input.UserInputType == Enum.UserInputType.Touch and TouchStartId) then
            
            if Input.UserInputType == Enum.UserInputType.Touch then
                if TouchStartId and Input.KeyCode ~= TouchStartId then
                    return
                end
            end
            
            IsDragging = false
            StartPosition, StartDrag = nil, nil
            TouchStartId = nil
            
            if OnStop then 
                OnStop(Object.Position) 
            end
        end
    end
    
    Dragger.InputBegan:Connect(HandleInputBegan)
    Dragger.InputEnded:Connect(HandleInputEnded)
    UserInputService.InputChanged:Connect(HandleInputChanged)
end

-- Enhanced function to make UI elements more touch-friendly
local function OptimizeForMobile(Element, IsDraggableElement)
    if UserInputService.TouchEnabled then
        -- Make touch targets larger for better usability
        if IsDraggableElement then
            local currentSize = Element.AbsoluteSize
            local minSize = 44 -- Recommended minimum touch target size
            
            if currentSize.X < minSize or currentSize.Y < minSize then
                local padding = math.max(minSize - currentSize.X, minSize - currentSize.Y)
                Element.Size = UDim2.new(
                    Element.Size.X.Scale, 
                    Element.Size.X.Offset + padding,
                    Element.Size.Y.Scale, 
                    Element.Size.Y.Offset + padding
                )
            end
        end
        
        -- Add visual feedback for touch interactions
        local feedback = Instance.new("Frame")
        feedback.Name = "TouchFeedback"
        feedback.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        feedback.BackgroundTransparency = 0.8
        feedback.Size = UDim2.new(1, 0, 1, 0)
        feedback.ZIndex = Element.ZIndex + 1
        feedback.Parent = Element
        feedback.Visible = false
        
        Element.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                feedback.Visible = true
                
                -- Animate the feedback
                feedback.BackgroundTransparency = 0.8
                local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                game:GetService("TweenService"):Create(
                    feedback, 
                    tweenInfo, 
                    {BackgroundTransparency = 0.9}
                ):Play()
            end
        end)
        
        Element.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.Touch then
                -- Animate out then hide
                local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = game:GetService("TweenService"):Create(
                    feedback, 
                    tweenInfo, 
                    {BackgroundTransparency = 1}
                )
                tween:Play()
                
                tween.Completed:Connect(function()
                    feedback.Visible = false
                end)
            end
        end)
    end
end
local function MakeResizeable(Dragger, Object, MinSize, OnTick, OnStop)
    local StartPosition, StartSize = nil, nil
    local IsResizing = false
    local TouchInputId = nil
    
    local function HandleInputBegan(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
           Input.UserInputType == Enum.UserInputType.Touch then
            
            if Input.UserInputType == Enum.UserInputType.Touch then
                TouchInputId = Input.KeyCode
            end
            
            StartPosition = UserInputService:GetMouseLocation()
            StartSize = Object.AbsoluteSize
            IsResizing = true
        end
    end
    
    local function HandleInputChanged(Input)
        if IsResizing and (Input.UserInputType == Enum.UserInputType.MouseMovement or 
           (Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState == Enum.UserInputState.Change)) then
            
            if Input.UserInputType == Enum.UserInputType.Touch and TouchInputId then
                if Input.KeyCode ~= TouchInputId then
                    return
                end
            end
            
            local Mouse = UserInputService:GetMouseLocation()
            local Delta = Mouse - StartPosition
            
            local Size = StartSize + Delta
            local SizeX = math.max(MinSize.X, Size.X)
            local SizeY = math.max(MinSize.Y, Size.Y)
            
            OnTick(UDim2.fromOffset(SizeX, SizeY))
        end
    end
    
    local function HandleInputEnded(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton1) or 
           (Input.UserInputType == Enum.UserInputType.Touch and TouchInputId) then
            
            if Input.UserInputType == Enum.UserInputType.Touch then
                if TouchInputId and Input.KeyCode ~= TouchInputId then
                    return
                end
            end
            
            IsResizing = false
            StartPosition, StartSize = nil, nil
            TouchInputId = nil
            
            if OnStop then 
                OnStop(Object.Size) 
            end
        end
    end
    
    Dragger.InputBegan:Connect(HandleInputBegan)
    Dragger.InputEnded:Connect(HandleInputEnded)
    UserInputService.InputChanged:Connect(HandleInputChanged)
end

local function ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	for Index,Object in pairs(ScreenAsset:GetChildren()) do
		if Object.Name == "OptionContainer"
			or Object.Name == "Palette" then
			Object.Visible = false
		end
	end
	for Index,Object in pairs(ScreenAsset.Window.TabContainer:GetChildren()) do
		if Object:IsA("ScrollingFrame")
			and Object ~= TabAsset then
			Object.Visible = false
		else
			Object.Visible = true
		end
	end
	for Index,Object in pairs(ScreenAsset.Window.TabButtonContainer:GetChildren()) do
		if Object:IsA("TextButton") then
			Object.Highlight.Visible = Object == TabButtonAsset
		end
	end
end
local function GetLongestSide(TabAsset)
	if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y
		>= TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
		return TabAsset.LeftSide
	else
		return TabAsset.RightSide
	end
end
local function GetShortestSide(TabAsset)
	if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y
		<= TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
		return TabAsset.LeftSide
	else
		return TabAsset.RightSide
	end
end
local function ChooseTabSide(TabAsset,Mode)
	if Mode == "Left" then
		return TabAsset.LeftSide
	elseif Mode == "Right" then
		return TabAsset.RightSide
	else
		return GetShortestSide(TabAsset)
	end
end

local function FindElementByFlag(Elements,Flag)
	for Index,Element in pairs(Elements) do
		if Element.Flag == Flag then
			return Element
		end
	end
end
local function GetConfigs(FolderName)
	if not isfolder(FolderName) then makefolder(FolderName) end
	if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end

	local Configs = {}
	for Index,Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
		Config = Config:gsub(FolderName .. "\\Configs\\","")
		Config = Config:gsub(".json","")
		Configs[#Configs + 1] = Config
	end
	return Configs
end
local function ConfigsToList(FolderName)
	if not isfolder(FolderName) then makefolder(FolderName) end
	if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end
	if not isfile(FolderName .. "\\AutoLoads.json") then writefile(FolderName .. "\\AutoLoads.json","[]") end

	local Configs = {}
	local AutoLoads = HttpService:JSONDecode(
		readfile(FolderName .. "\\AutoLoads.json")
	) local AutoLoad = AutoLoads[tostring(game.GameId)]

	for Index,Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
		Config = Config:gsub(FolderName .. "\\Configs\\","")
		Config = Config:gsub(".json","")
		Configs[#Configs + 1] = {
			Name = Config,Mode = "Button",
			Value = Config == AutoLoad
		}
	end

	return Configs
end

function Assets:Screen()
	local ScreenAsset = GetAsset("Screen/Bracket")
	if not IsLocal then sethiddenproperty(ScreenAsset,"OnTopOfCoreBlur",true) end
	ScreenAsset.Name = "Bracket " .. game:GetService("HttpService"):GenerateGUID(false)
	ScreenAsset.Parent = IsLocal and LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui
	
	-- Create mobile toggle button
	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Name = "MobileToggle"
	ToggleButton.Size = UDim2.new(0, 60, 0, 60)
	ToggleButton.Position = UDim2.new(0, 10, 0.5, -30)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	ToggleButton.BorderSizePixel = 2
	ToggleButton.BorderColor3 = Color3.fromRGB(255, 127, 64)
	ToggleButton.Text = "☰"
	ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleButton.TextSize = 32
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.ZIndex = 1000
	ToggleButton.Active = true
	ToggleButton.Parent = ScreenAsset
	
	-- Add corner rounding
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = ToggleButton
	
	-- Add stroke for better visibility
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(255, 127, 64)
	Stroke.Thickness = 2
	Stroke.Parent = ToggleButton
	
	-- Make draggable with touch support
	MakeDraggable(ToggleButton, ToggleButton, function(Position)
		ToggleButton.Position = Position
	end)
	
	-- Optimize for mobile
	if UserInputService.TouchEnabled then
		OptimizeForMobile(ToggleButton, true)
	end
	
	return {ScreenAsset = ScreenAsset, TableToColor = TableToColor, ToggleButton = ToggleButton}
end
function Assets:Window(ScreenAsset,Window)
	local WindowAsset = GetAsset("Window/Window")

	Window.Background = WindowAsset.Background
	Window.RainbowHue,Window.RainbowSpeed = 0,10
	Window.Colorable,Window.Elements,Window.Flags = {},{},{}

	WindowAsset.Parent = ScreenAsset
	WindowAsset.Visible = Window.Enabled
	WindowAsset.Title.Text = Window.Name
	WindowAsset.Position = Window.Position
	WindowAsset.Size = Window.Size

	MakeDraggable(WindowAsset.Drag,WindowAsset,function(Position)
		Window.Position = Position
	end)
	MakeResizeable(WindowAsset.Resize,WindowAsset,Vector2.new(296,296),function(Size)
		Window.Size = Size
	end)

	local Month = tonumber(os.date("%m"))
	if Month == 12 or Month == 1 then task.spawn(Assets.Snowflakes,WindowAsset) end
	WindowAsset.TabButtonContainer.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		WindowAsset.TabButtonContainer.CanvasSize = UDim2.fromOffset(
			WindowAsset.TabButtonContainer.ListLayout.AbsoluteContentSize.X,0
		)
	end)
	
	-- Set up mobile toggle button click handler
	local ToggleButton = ScreenAsset:FindFirstChild("MobileToggle")
	if ToggleButton then
		local toggleTouchStart, toggleStartTime = nil, nil
		local toggleIsDragging = false
		
		ToggleButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
			   Input.UserInputType == Enum.UserInputType.Touch then
				toggleTouchStart = Input.Position
				toggleStartTime = tick()
				toggleIsDragging = false
			end
		end)
		
		ToggleButton.InputChanged:Connect(function(Input)
			if toggleTouchStart and (Input.UserInputType == Enum.UserInputType.MouseMovement or 
			   Input.UserInputType == Enum.UserInputType.Touch) then
				local Delta = (Input.Position - toggleTouchStart).Magnitude
				if Delta > 10 then
					toggleIsDragging = true
				end
			end
		end)
		
		ToggleButton.InputEnded:Connect(function(Input)
			if (Input.UserInputType == Enum.UserInputType.MouseButton1 or 
			    Input.UserInputType == Enum.UserInputType.Touch) and toggleTouchStart then
				local Duration = tick() - toggleStartTime
				-- Only toggle if it was a tap (not a drag) and quick
				if not toggleIsDragging and Duration < 0.3 then
					Window.Enabled = not Window.Enabled
				end
				toggleTouchStart = nil
				toggleIsDragging = false
			end
		end)
		
		-- Set initial button appearance
		ToggleButton.Text = Window.Enabled and "✕" or "☰"
		ToggleButton.BackgroundColor3 = Window.Enabled and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
	end

	UserInputService.InputChanged:Connect(function(Input)
		if WindowAsset.Visible and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Mouse = UserInputService:GetMouseLocation()
			ScreenAsset.ToolTip.Position = UDim2.fromOffset(
				Mouse.X + 5,Mouse.Y - 5
			)
		end
	end)
	RunService.RenderStepped:Connect(function()
		Window.RainbowHue = os.clock() % Window.RainbowSpeed / Window.RainbowSpeed
	end)

	Window:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
		WindowAsset.Visible = Enabled

		if not IsLocal then RunService:SetRobloxGuiFocused(Enabled and Window.Blur) end
		if not Enabled then
			for Index,Object in pairs(ScreenAsset:GetChildren()) do
				if Object.Name == "Palette" or Object.Name == "OptionContainer" then
					Object.Visible = false
				end
			end
		end
		
		-- Update toggle button appearance when window visibility changes
		local ToggleButton = ScreenAsset:FindFirstChild("MobileToggle")
		if ToggleButton then
			ToggleButton.Text = Enabled and "✕" or "☰"
			ToggleButton.BackgroundColor3 = Enabled and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
		end
	end)
	Window:GetPropertyChangedSignal("Blur"):Connect(function(Blur)
		if not IsLocal then RunService:SetRobloxGuiFocused(Window.Enabled and Blur) end
	end)
	Window:GetPropertyChangedSignal("Name"):Connect(function(Name)
		WindowAsset.Title.Text = Name
	end)
	Window:GetPropertyChangedSignal("Position"):Connect(function(Position)
		WindowAsset.Position = Position
	end)
	Window:GetPropertyChangedSignal("Size"):Connect(function(Size)
		WindowAsset.Size = Size
	end)
	Window:GetPropertyChangedSignal("Color"):Connect(function(Color)
		for Object,ColorConfig in pairs(Window.Colorable) do
			pcall(function()
				if ColorConfig[1] and Object and ColorConfig[2] then
					Object[ColorConfig[2]] = Color
				end
			end)
		end
	end)

	function Window:SetValue(Flag,Value)
		for Index,Element in pairs(Window.Elements) do
			if Element.Flag == Flag then
				Element.Value = Value
			end
		end
	end
	function Window:GetValue(Flag)
		for Index,Element in pairs(Window.Elements) do
			if Element.Flag == Flag then
				return Element.Value
			end
		end
	end

	function Window:Watermark(Watermark)
		Watermark = GetType(Watermark,{},"table",true)
		Watermark.Enabled = GetType(Watermark.Enabled,false,"boolean")
		Watermark.Title = GetType(Watermark.Title,"Hello World!","string")
		Watermark.Flag = GetType(Watermark.Flag,"UI/Watermark/Position","string")

		ScreenAsset.Watermark.Visible = Watermark.Enabled
		ScreenAsset.Watermark.Text = Watermark.Title

		ScreenAsset.Watermark.Size = UDim2.fromOffset(
			ScreenAsset.Watermark.TextBounds.X + 6,
			ScreenAsset.Watermark.TextBounds.Y + 6
		)

		MakeDraggable(ScreenAsset.Watermark,ScreenAsset.Watermark,function(Position)
			ScreenAsset.Watermark.Position = Position
		end,function(Position)
			Watermark.Value = {
				Position.X.Scale,Position.X.Offset,
				Position.Y.Scale,Position.Y.Offset
			}
		end)

		Watermark:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
			ScreenAsset.Watermark.Visible = Enabled
		end)
		Watermark:GetPropertyChangedSignal("Title"):Connect(function(Title)
			ScreenAsset.Watermark.Text = Title
			ScreenAsset.Watermark.Size = UDim2.fromOffset(
				ScreenAsset.Watermark.TextBounds.X + 6,
				ScreenAsset.Watermark.TextBounds.Y + 6
			)
		end)
		Watermark:GetPropertyChangedSignal("Value"):Connect(function(Value)
			if type(Value) ~= "table" then return end
			ScreenAsset.Watermark.Position = UDim2.new(
				Value[1],Value[2],
				Value[3],Value[4]
			)
			Window.Flags[Watermark.Flag] = {
				Value[1],Value[2],
				Value[3],Value[4]
			}
		end)

		Window.Elements[#Window.Elements + 1] = Watermark
		Window.Watermark = Watermark
		return Watermark
	end
	function Window:KeybindList(KeybindList)
		KeybindList = GetType(KeybindList,{},"table",true)
		KeybindList.Enabled = GetType(KeybindList.Enabled,false,"boolean")
		--KeybindList.Title = GetType(KeybindList.Title,"","string")

		KeybindList.Position = GetType(KeybindList.Position,UDim2.new(0,10,0.5,-123),"UDim2")
		KeybindList.Size = GetType(KeybindList.Size,UDim2.new(0,121,0,246),"UDim2")
		KeybindList.List = ScreenAsset.KeybindList.List

		ScreenAsset.KeybindList.Visible = KeybindList.Enabled
		--ScreenAsset.KeybindList.Title.Text = KeybindList.Title

		MakeDraggable(ScreenAsset.KeybindList.Drag,ScreenAsset.KeybindList,function(Position)
			KeybindList.Position = Position
		end)
		MakeResizeable(ScreenAsset.KeybindList.Resize,ScreenAsset.KeybindList,Vector2.new(121,246),function(Size)
			KeybindList.Size = Size
		end)

		--[[KeybindList:GetPropertyChangedSignal("Title"):Connect(function(Title)
			ScreenAsset.KeybindList.Title.Text = Title
		end)]]
		KeybindList:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
			ScreenAsset.KeybindList.Visible = Enabled
		end)
		KeybindList:GetPropertyChangedSignal("Position"):Connect(function(Position)
			ScreenAsset.KeybindList.Position = Position
		end)
		KeybindList:GetPropertyChangedSignal("Size"):Connect(function(Size)
			ScreenAsset.KeybindList.Size = Size
		end)

		WindowAsset.Background.Changed:Connect(function(Property)
			if Property == "Image" then
				ScreenAsset.KeybindList.Background.Image = WindowAsset.Background.Image
			elseif Property == "ImageColor3" then
				ScreenAsset.KeybindList.Background.ImageColor3 = WindowAsset.Background.ImageColor3
			elseif Property == "ImageTransparency" then
				ScreenAsset.KeybindList.Background.ImageTransparency = WindowAsset.Background.ImageTransparency
			elseif Property == "TileSize" then
				ScreenAsset.KeybindList.Background.TileSize = WindowAsset.Background.TileSize
			end
		end)

		for Index, Element in pairs(Window.Elements) do
			if type(Element.WaitingForBind) == "boolean" and not Element.IgnoreList then
				Element.ListMimic = {}
				Element.ListMimic.Asset = GetAsset("KeybindList/KeybindMimic")
				Element.ListMimic.Asset.Title.Text = Element.Name or Element.Toggle.Name
				Element.ListMimic.Asset.Parent = ScreenAsset.KeybindList.List

				Element.ListMimic.ColorConfig = {false,"BackgroundColor3"}
				Window.Colorable[Element.ListMimic.Asset.Tick] = Element.ListMimic.ColorConfig
			end
		end

		Window.Elements[#Window.Elements + 1] = KeybindList
		Window.KeybindList = KeybindList
		return KeybindList
	end

	function Window:SaveConfig(FolderName,Name)
		local Config = {}
		for Index,Element in pairs(Window.Elements) do
			if Element.Flag and not Element.IgnoreFlag then
				Config[Element.Flag] = Window.Flags[Element.Flag]
			end
		end
		writefile(
			FolderName .. "\\Configs\\" .. Name .. ".json",
			HttpService:JSONEncode(Config)
		)
	end
	function Window:LoadConfig(FolderName,Name)
		if table.find(GetConfigs(FolderName),Name) then
			local DecodedJSON = HttpService:JSONDecode(
				readfile(FolderName .. "\\Configs\\" .. Name .. ".json")
			)
			for Flag,Value in pairs(DecodedJSON) do
				local Element = FindElementByFlag(Window.Elements,Flag)
				if Element ~= nil then Element.Value = Value end
			end
		end
	end
	function Window:DeleteConfig(FolderName,Name)
		if table.find(GetConfigs(FolderName),Name) then
			delfile(FolderName .. "\\Configs\\" .. Name .. ".json")
		end
	end
	function Window:GetAutoLoadConfig(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
		end

		local AutoLoads = HttpService:JSONDecode(
			readfile(FolderName .. "\\AutoLoads.json")
		) local AutoLoad = AutoLoads[tostring(game.GameId)]

		if table.find(GetConfigs(FolderName),AutoLoad) then
			return AutoLoad
		end
	end
	function Window:AddToAutoLoad(FolderName,Name)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
		end

		local AutoLoads = HttpService:JSONDecode(
			readfile(FolderName .. "\\AutoLoads.json")
		) AutoLoads[tostring(game.GameId)] = Name

		writefile(FolderName .. "\\AutoLoads.json",
			HttpService:JSONEncode(AutoLoads)
		)
	end
	function Window:RemoveFromAutoLoad(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
			return
		end

		local AutoLoads = HttpService:JSONDecode(
			readfile(FolderName .. "\\AutoLoads.json")
		) AutoLoads[tostring(game.GameId)] = nil

		writefile(FolderName .. "\\AutoLoads.json",
			HttpService:JSONEncode(AutoLoads)
		)
	end
	function Window:AutoLoadConfig(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfile(FolderName .. "\\AutoLoads.json") then
			writefile(FolderName .. "\\AutoLoads.json","[]")
		end

		local AutoLoads = HttpService:JSONDecode(
			readfile(FolderName .. "\\AutoLoads.json")
		) local AutoLoad = AutoLoads[tostring(game.GameId)]

		if table.find(GetConfigs(FolderName),AutoLoad) then
			Window:LoadConfig(FolderName,AutoLoad)
		end
	end

	return WindowAsset
end
function Assets:Tab(ScreenAsset,WindowAsset,Window,Tab)
	local TabButtonAsset,TabAsset = GetAsset("Tab/TabButton"),GetAsset("Tab/Tab")

	Tab.ColorConfig = {true,"BackgroundColor3"}
	Window.Colorable[TabButtonAsset.Highlight] = Tab.ColorConfig

	TabAsset.Parent = WindowAsset.TabContainer
	TabButtonAsset.Parent = WindowAsset.TabButtonContainer

	TabAsset.Visible = false
	TabButtonAsset.Text = Tab.Name
	TabButtonAsset.Highlight.BackgroundColor3 = Window.Color
	TabButtonAsset.Size = UDim2.new(0,TabButtonAsset.TextBounds.X + 12,1,-1)
	TabButtonAsset.Parent = WindowAsset.TabButtonContainer

	TabAsset.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local Side = GetLongestSide(TabAsset)
		TabAsset.CanvasSize = UDim2.fromOffset(0,Side.ListLayout.AbsoluteContentSize.Y + 21)
	end)
	TabAsset.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local Side = GetLongestSide(TabAsset)
		TabAsset.CanvasSize = UDim2.fromOffset(0,Side.ListLayout.AbsoluteContentSize.Y + 21)
	end)
	TabButtonAsset.MouseButton1Click:Connect(function()
		ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	end)

	if #WindowAsset.TabContainer:GetChildren() == 1 then
		ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	end

	Tab:GetPropertyChangedSignal("Name"):Connect(function(Name)
		TabButtonAsset.Text = Name
		TabButtonAsset.Size = UDim2.new(
			0,TabButtonAsset.TextBounds.X + 12,
			1,-1
		)
	end)

	return TabAsset
end
function Assets:Section(Parent,Section)
	local SectionAsset = GetAsset("Section/Section")

	SectionAsset.Parent = Parent
	SectionAsset.Title.Text = Section.Name
	SectionAsset.Title.Size = UDim2.fromOffset(
		SectionAsset.Title.TextBounds.X + 6,2
	)

	SectionAsset.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SectionAsset.Size = UDim2.new(1,0,0,SectionAsset.Container.ListLayout.AbsoluteContentSize.Y + 15)
	end)

	Section:GetPropertyChangedSignal("Name"):Connect(function(Name)
		SectionAsset.Title.Text = Name
		SectionAsset.Title.Size = UDim2.fromOffset(
			Section.Title.TextBounds.X + 6,2
		)
	end)

	return SectionAsset.Container
end
function Assets:ToolTip(Parent,ScreenAsset,Text)
	Parent.MouseEnter:Connect(function()
		ScreenAsset.ToolTip.Text = Text
		ScreenAsset.ToolTip.Size = UDim2.fromOffset(
			ScreenAsset.ToolTip.TextBounds.X + 6,
			ScreenAsset.ToolTip.TextBounds.Y + 6
		) ScreenAsset.ToolTip.Visible = true
	end)
	Parent.MouseLeave:Connect(function()
		ScreenAsset.ToolTip.Visible = false
	end)
end
function Assets.Snowflakes(WindowAsset)
	local ParticleEmitter = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/rParticle/master/Main.lua"))()
	local Emitter = ParticleEmitter.new(WindowAsset.Background,WindowAsset.Snowflake)
	local NewRandom = Random.new() Emitter.SpawnRate = 20

	Emitter.OnSpawn = function(Particle)
		local RandomPosition = NewRandom:NextNumber()
		local RandomSize = NewRandom:NextInteger(10,50)
		local RandomYVelocity = NewRandom:NextInteger(10,50)
		local RandomXVelocity = NewRandom:NextInteger(-50,50)

		Particle.Object.ImageTransparency = RandomSize / 50
		Particle.Object.Size = UDim2.fromOffset(RandomSize,RandomSize)
		Particle.Velocity = Vector2.new(RandomXVelocity,RandomYVelocity)
		Particle.Position = Vector2.new(RandomPosition * WindowAsset.Background.AbsoluteSize.X,0)
		Particle.MaxAge = 20 task.wait(0.5) Particle.Object.Visible = true
	end

	Emitter.OnUpdate = function(Particle,Delta)
		Particle.Position += Particle.Velocity * Delta
	end
end
function Assets:Divider(Parent,Divider)
	local DividerAsset = GetAsset("Divider/Divider")

	DividerAsset.Parent = Parent
	DividerAsset.Title.Text = Divider.Text

	DividerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		if DividerAsset.Title.TextBounds.X > 0 then
			DividerAsset.Size = UDim2.new(1,0,0,DividerAsset.Title.TextBounds.Y)
			DividerAsset.Left.Size = UDim2.new(0.5,-(DividerAsset.Title.TextBounds.X / 2) - 6,0,2)
			DividerAsset.Right.Size = UDim2.new(0.5,-(DividerAsset.Title.TextBounds.X / 2) - 6,0,2)
		else
			DividerAsset.Size = UDim2.new(1,0,0,14)
			DividerAsset.Left.Size = UDim2.new(1,0,0,2)
			DividerAsset.Right.Size = UDim2.new(1,0,0,2)
		end
	end)

	Divider:GetPropertyChangedSignal("Text"):Connect(function(Text)
		DividerAsset.Title.Text = Text
	end)
end
function Assets:Label(Parent,Label)
	local LabelAsset = GetAsset("Label/Label")

	LabelAsset.Parent = Parent
	LabelAsset.Text = Label.Text

	LabelAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
		LabelAsset.Size = UDim2.new(1,0,0,LabelAsset.TextBounds.Y)
	end)

	Label:GetPropertyChangedSignal("Text"):Connect(function(Text)
		LabelAsset.Text = Text
	end)
end
function Assets:Button(Parent,ScreenAsset,Window,Button)
	local ButtonAsset = GetAsset("Button/Button")

	Button.ColorConfig = {false,"BorderColor3"}
	-- ColorConfig removed to prevent errors

	Button.Connection = ButtonAsset.MouseButton1Click:Connect(Button.Callback)

	ButtonAsset.Parent = Parent
	ButtonAsset.Title.Text = Button.Name
	ButtonAsset.Active = true

	-- Mobile-friendly press feedback (BorderColor3 removed)
	local function HandlePress()
		Button.ColorConfig[1] = true
		-- Visual feedback handled by UI library
	end
	local function HandleRelease()
		Button.ColorConfig[1] = false
		-- Visual feedback handled by UI library
	end

	ButtonAsset.MouseButton1Down:Connect(HandlePress)
	ButtonAsset.MouseButton1Up:Connect(HandleRelease)
	ButtonAsset.MouseLeave:Connect(HandleRelease)
	
	-- Touch support
	ButtonAsset.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			HandlePress()
		end
	end)
	ButtonAsset.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			HandleRelease()
		end
	end)
	ButtonAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		ButtonAsset.Size = UDim2.new(1,0,0,ButtonAsset.Title.TextBounds.Y + 2)
	end)

	Button:GetPropertyChangedSignal("Name"):Connect(function(Name)
		ButtonAsset.Title.Text = Name
	end)
	Button:GetPropertyChangedSignal("Callback"):Connect(function(Callback)
		Button.Connection:Disconnect()
		Button.Connection = ButtonAsset.MouseButton1Click:Connect(Callback)
	end)

	function Button:ToolTip(Text)
		Assets:ToolTip(ButtonAsset,ScreenAsset,Text)
	end
end
function Assets:Toggle(Parent,ScreenAsset,Window,Toggle)
	local ToggleAsset = GetAsset("Toggle/Toggle")

	Toggle.ColorConfig = {Toggle.Value,"BackgroundColor3"}
	Window.Colorable[ToggleAsset.Tick] = Toggle.ColorConfig

	ToggleAsset.Parent = Parent
	ToggleAsset.Active = true
	ToggleAsset.Title.Text = Toggle.Name
	pcall(function()
		local color = Toggle.Value and Window.Color or Color3.fromRGB(60,60,60)
		if typeof(color) == "table" then
			color = Color3.fromRGB(color[1] or 0, color[2] or 255, color[3] or 0)
		end
		ToggleAsset.Tick.BackgroundColor3 = color
	end)

	-- Works for both mouse and touch
	ToggleAsset.MouseButton1Click:Connect(function()
		Toggle.Value = not Toggle.Value
	end)
	ToggleAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		ToggleAsset.Size = UDim2.new(1,0,0,ToggleAsset.Title.TextBounds.Y)
		ToggleAsset.Layout.Size = UDim2.new(1,-ToggleAsset.Title.TextBounds.X - 18,1,0)
	end)

	Toggle:GetPropertyChangedSignal("Name"):Connect(function(Name)
		ToggleAsset.Title.Text = Name
	end)
	Toggle:GetPropertyChangedSignal("Value"):Connect(function(Value)
		Toggle.ColorConfig[1] = Value
		pcall(function()
			local color = Value and Window.Color or Color3.fromRGB(60,60,60)
			if typeof(color) == "table" then
				color = Color3.fromRGB(color[1] or 0, color[2] or 255, color[3] or 0)
			end
			ToggleAsset.Tick.BackgroundColor3 = color
		end)
		Window.Flags[Toggle.Flag] = Value
		Toggle.Callback(Value)
	end)

	function Toggle:ToolTip(Text)
		Assets:ToolTip(ToggleAsset,ScreenAsset,Text)
	end

	return ToggleAsset
end
function Assets:Slider(Parent,ScreenAsset,Window,Slider)
    local SliderAsset = Slider.Wide
        and GetAsset("Slider/HighSlider")
        or GetAsset("Slider/Slider")

    Slider.ColorConfig = {true,"BackgroundColor3"}
    Window.Colorable[SliderAsset.Background.Bar] = Slider.ColorConfig

    Slider.Active = false
    Slider.Value = tonumber(string.format("%." .. Slider.Precise .. "f",Slider.Value))
    Slider.TouchInputId = nil -- Track touch input for mobile

    SliderAsset.Parent = Parent
    SliderAsset.Title.Text = Slider.Name
    SliderAsset.Background.Bar.BackgroundColor3 = Window.Color
    SliderAsset.Background.Bar.Size = UDim2.fromScale(Scale(Slider.Value,Slider.Min,Slider.Max,0,1),1)
    SliderAsset.Value.PlaceholderText = #Slider.Unit == 0 and Slider.Value or Slider.Value .. " " .. Slider.Unit

    -- Add touch area extension for mobile (invisible but functional)
    if UserInputService.TouchEnabled then
        local touchArea = Instance.new("Frame")
        touchArea.Name = "MobileTouchArea"
        touchArea.BackgroundTransparency = 1
        touchArea.Size = UDim2.new(1, 20, 1, 20) -- Slightly larger touch area
        touchArea.Position = UDim2.new(0, -10, 0, -10) -- Centered on slider
        touchArea.ZIndex = SliderAsset.ZIndex
        touchArea.Parent = SliderAsset
        
        -- Forward input events to the slider
        touchArea.InputBegan:Connect(function(Input)
            SliderAsset.InputBegan:Fire(Input)
        end)
        touchArea.InputEnded:Connect(function(Input)
            SliderAsset.InputEnded:Fire(Input)
        end)
        touchArea.InputChanged:Connect(function(Input)
            SliderAsset.InputChanged:Fire(Input)
        end)
    end

    local function AttachToMouse(Input)
        local ScaleX = math.clamp((Input.Position.X - SliderAsset.Background.AbsolutePosition.X) / SliderAsset.Background.AbsoluteSize.X,0,1)
        Slider.Value = Scale(ScaleX,0,1,Slider.Min,Slider.Max)
    end

    if Slider.Wide then
        SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
            SliderAsset.Value.Size = UDim2.new(0,SliderAsset.Value.TextBounds.X,1,0)
            SliderAsset.Title.Size = UDim2.new(1,-SliderAsset.Value.Size.X.Offset + 12,1,0)
            SliderAsset.Size = UDim2.new(1,0,0,SliderAsset.Title.TextBounds.Y + 2)
        end)
        SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
            SliderAsset.Value.Size = UDim2.new(0,SliderAsset.Value.TextBounds.X,1,0)
            SliderAsset.Title.Size = UDim2.new(1,-SliderAsset.Value.Size.X.Offset + 12,1,0)
        end)
    else
        SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
            SliderAsset.Value.Size = UDim2.fromOffset(SliderAsset.Value.TextBounds.X,16)
            SliderAsset.Title.Size = UDim2.new(1,-SliderAsset.Value.Size.X.Offset,0,16)
            SliderAsset.Size = UDim2.new(1,0,0,SliderAsset.Title.TextBounds.Y + 8)
        end)
        SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
            SliderAsset.Value.Size = UDim2.fromOffset(SliderAsset.Value.TextBounds.X,16)
            SliderAsset.Title.Size = UDim2.new(1,-SliderAsset.Value.Size.X.Offset,0,16)
        end)
    end

    SliderAsset.Value.FocusLost:Connect(function()
        if not tonumber(SliderAsset.Value.Text) then
            SliderAsset.Value.Text = Slider.Value
        elseif tonumber(SliderAsset.Value.Text) <= Slider.Min then
            SliderAsset.Value.Text = Slider.Min
        elseif tonumber(SliderAsset.Value.Text) >= Slider.Max then
            SliderAsset.Value.Text = Slider.Max
        end
        Slider.Value = SliderAsset.Value.Text
        SliderAsset.Value.Text = ""
    end)

    -- Enhanced input handling for mobile
    SliderAsset.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or 
           Input.UserInputType == Enum.UserInputType.Touch then
            
            -- For touch, track the specific touch ID
            if Input.UserInputType == Enum.UserInputType.Touch then
                Slider.TouchInputId = Input
            end
            
            AttachToMouse(Input)
            Slider.Active = true
            
            -- Capture input for mobile
            if Input.UserInputType == Enum.UserInputType.Touch then
                local contextActionService = game:GetService("ContextActionService")
                contextActionService:BindAction("CaptureSliderTouch", function() 
                    return Enum.ContextActionResult.Sink 
                end, false, unpack(Enum.PlayerActions:GetEnumItems()))
            end
        end
    end)
    
    SliderAsset.InputEnded:Connect(function(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseButton1) or 
           (Input.UserInputType == Enum.UserInputType.Touch and Slider.TouchInputId) then
            
            -- For touch, make sure we're releasing the same touch that started
            if Input.UserInputType == Enum.UserInputType.Touch then
                if Slider.TouchInputId and Input.KeyCode ~= Slider.TouchInputId.KeyCode then
                    return -- Different touch, ignore
                end
            end
            
            Slider.Active = false
            Slider.TouchInputId = nil
            
            -- Release input capture
            if Input.UserInputType == Enum.UserInputType.Touch then
                local contextActionService = game:GetService("ContextActionService")
                contextActionService:UnbindAction("CaptureSliderTouch")
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(Input)
        if Slider.Active and (Input.UserInputType == Enum.UserInputType.MouseMovement or 
           (Input.UserInputType == Enum.UserInputType.Touch and Slider.TouchInputId and Input.UserInputState == Enum.UserInputState.Change)) then
            
            -- For touch, make sure we're tracking the same touch that started
            if Input.UserInputType == Enum.UserInputType.Touch and Slider.TouchInputId then
                if Input.KeyCode ~= Slider.TouchInputId.KeyCode then
                    return -- Different touch, ignore
                end
            end
            
            AttachToMouse(Input)
        end
    end)

    Slider:GetPropertyChangedSignal("Name"):Connect(function(Name)
        SliderAsset.Title.Text = Name
    end)
    Slider:GetPropertyChangedSignal("Value"):Connect(function(Value)
        Value = tonumber(string.format("%." .. Slider.Precise .. "f",Value))
        SliderAsset.Background.Bar.Size = UDim2.fromScale(Scale(Value,Slider.Min,Slider.Max,0,1),1)
        SliderAsset.Value.PlaceholderText = #Slider.Unit == 0
            and Value or Value .. " " .. Slider.Unit

        Window.Flags[Slider.Flag] = Value
        Slider.Callback(Value)
    end)

    function Slider:ToolTip(Text)
        Assets:ToolTip(SliderAsset,ScreenAsset,Text)
    end
end
function Assets:Textbox(Parent,ScreenAsset,Window,Textbox)
	local TextboxAsset = GetAsset("Textbox/Textbox")
	Textbox.EnterPressed = false

	TextboxAsset.Parent = Parent
	TextboxAsset.Active = true
	TextboxAsset.Title.Text = Textbox.Name
	TextboxAsset.Background.Input.Text = Textbox.Value
	TextboxAsset.Background.Input.PlaceholderText = Textbox.Placeholder
	TextboxAsset.Background.Input.TextEditable = true
	TextboxAsset.Background.Input.ClearTextOnFocus = false
	TextboxAsset.Title.Visible = not Textbox.HideName

	TextboxAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		TextboxAsset.Title.Size = Textbox.HideName and UDim2.fromScale(1,0)
			or UDim2.new(1,0,0,TextboxAsset.Title.TextBounds.Y + 2)

		TextboxAsset.Background.Position = UDim2.new(0.5,0,0,TextboxAsset.Title.Size.Y.Offset)
		TextboxAsset.Size = UDim2.new(1,0,0,TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
	end)
	TextboxAsset.Background.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local TextBounds = GetTextBounds(
			TextboxAsset.Background.Input.Text,
			TextboxAsset.Background.Input.Font.Name,
			Vector2.new(TextboxAsset.Background.Input.AbsoluteSize.X,TextboxAsset.Background.Input.TextSize)
		)

		TextboxAsset.Background.Size = UDim2.new(1,0,0,TextBounds.Y + 2)
		TextboxAsset.Size = UDim2.new(1,0,0,TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
	end)

	TextboxAsset.Background.Input.Focused:Connect(function()
		TextboxAsset.Background.Input.Text = Textbox.Value
	end)
	TextboxAsset.Background.Input.FocusLost:Connect(function(EnterPressed)
		local Input = TextboxAsset.Background.Input

		Textbox.EnterPressed = EnterPressed
		Textbox.Value = Input.Text Textbox.EnterPressed = false
	end)

	Textbox:GetPropertyChangedSignal("Name"):Connect(function(Name)
		TextboxAsset.Title.Text = Name
	end)
	Textbox:GetPropertyChangedSignal("Placeholder"):Connect(function(PlaceHolder)
		TextboxAsset.Background.Input.PlaceholderText = PlaceHolder
	end)
	Textbox:GetPropertyChangedSignal("Value"):Connect(function(Value)
		local Input = TextboxAsset.Background.Input
		Input.Text = Textbox.AutoClear and "" or Value
		if Textbox.PasswordMode then Input.Text = string.rep(utf8.char(8226),#Input.Text) end

		TextboxAsset.Background.Size = UDim2.new(1,0,0,Input.TextSize + 2)
		TextboxAsset.Size = UDim2.new(1,0,0,TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)

		Window.Flags[Textbox.Flag] = Value
		Textbox.Callback(Value,Textbox.EnterPressed)
	end)

	function Textbox:ToolTip(Text)
		Assets:ToolTip(TextboxAsset,ScreenAsset,Text)
	end
end
function Assets:Keybind(Parent,ScreenAsset,Window,Keybind)
	local KeybindAsset = GetAsset("Keybind/Keybind")
	Keybind.WaitingForBind = false

	KeybindAsset.Parent = Parent
	KeybindAsset.Active = true
	KeybindAsset.Title.Text = Keybind.Name
	KeybindAsset.Value.Text = "[ " .. Keybind.Value .. " ]"

	KeybindAsset.MouseButton1Click:Connect(function()
		KeybindAsset.Value.Text = "[ ... ]"
		Keybind.WaitingForBind = true
	end)
	KeybindAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		KeybindAsset.Size = UDim2.new(1,0,0,KeybindAsset.Title.TextBounds.Y)
	end)
	KeybindAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
		KeybindAsset.Value.Size = UDim2.new(0,KeybindAsset.Value.TextBounds.X,1,0)
		KeybindAsset.Title.Size = UDim2.new(1,-KeybindAsset.Value.Size.X.Offset,1,0)
	end)

	if type(Window.KeybindList) == "table" and not Keybind.IgnoreList then
		Keybind.ListMimic = {}
		Keybind.ListMimic.Asset = GetAsset("KeybindList/KeybindMimic")
		Keybind.ListMimic.Asset.Title.Text = Keybind.Name
		Keybind.ListMimic.Asset.Visible = Keybind.Value ~= "NONE"
		Keybind.ListMimic.Asset.Parent = Window.KeybindList.List

		Keybind.ListMimic.ColorConfig = {false,"BackgroundColor3"}
		Window.Colorable[Keybind.ListMimic.Asset.Tick] = Keybind.ListMimic.ColorConfig
	end

	UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
		if GameProcessedEvent then return end
		local Key = Input.KeyCode.Name
		if Keybind.WaitingForBind and Input.UserInputType.Name == "Keyboard" then
			Keybind.Value = Key
		elseif Input.UserInputType.Name == "Keyboard" then
			if Key == Keybind.Value then
				Keybind.Toggle = not Keybind.Toggle
				if Keybind.ListMimic then
					Keybind.ListMimic.ColorConfig[1] = true
					Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Window.Color
				end
				Keybind.Callback(Keybind.Value,true,Keybind.Toggle)
			end
		end
		if Keybind.Mouse then Key = Input.UserInputType.Name
			if Keybind.WaitingForBind and (Key == "MouseButton1"
				or Key == "MouseButton2" or Key == "MouseButton3") then
				Keybind.Value = Key
			elseif Key == "MouseButton1"
				or Key == "MouseButton2"
				or Key == "MouseButton3" then
				if Key == Keybind.Value then
					Keybind.Toggle = not Keybind.Toggle
					if Keybind.ListMimic then
						Keybind.ListMimic.ColorConfig[1] = true
						Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Window.Color
					end
					Keybind.Callback(Keybind.Value,true,Keybind.Toggle)
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
		if GameProcessedEvent then return end
		local Key = Input.KeyCode.Name
		if Input.UserInputType.Name == "Keyboard" then
			if Key == Keybind.Value then
				if Keybind.ListMimic then
					Keybind.ListMimic.ColorConfig[1] = false
					Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Color3.fromRGB(60,60,60)
				end
				Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
			end
		end
		if Keybind.Mouse then Key = Input.UserInputType.Name
			if Key == "MouseButton1"
				or Key == "MouseButton2"
				or Key == "MouseButton3" then
				if Key == Keybind.Value then
					if Keybind.ListMimic then
						Keybind.ListMimic.ColorConfig[1] = false
						Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Color3.fromRGB(60,60,60)
					end
					Keybind.Callback(Keybind.Value,false,Keybind.Toggle)
				end
			end
		end
	end)

	Keybind:GetPropertyChangedSignal("Name"):Connect(function(Name)
		KeybindAsset.Title.Text = Name
	end)
	Keybind:GetPropertyChangedSignal("Value"):Connect(function(Value,OldValue)
		if table.find(Keybind.Blacklist,Value) then
			if Keybind.DoNotClear then
				Keybind.Internal.Value = OldValue
				Value = OldValue
			else
				Keybind.Internal.Value = "NONE"
				Value = "NONE"
			end
		end

		KeybindAsset.Value.Text = "[ " .. tostring(Value) .. " ]"
		if Keybind.ListMimic then
			Keybind.ListMimic.Asset.Visible = Value ~= "NONE"
			Keybind.ListMimic.Asset.Layout.TKeybind.Text = "[ " .. tostring(Value) .. " ]"
		end

		Keybind.WaitingForBind = false
		Window.Flags[Keybind.Flag] = Value
		Keybind.Callback(Value,false,Keybind.Toggle)
	end)

	function Keybind:ToolTip(Text)
		Assets:ToolTip(KeybindAsset,ScreenAsset,Text)
	end
end
function Assets:ToggleKeybind(Parent,ScreenAsset,Window,Keybind,Toggle)
	local KeybindAsset = GetAsset("Keybind/TKeybind")
	Keybind.WaitingForBind = false
	Keybind.Toggle = Toggle

	KeybindAsset.Parent = Parent
	KeybindAsset.Text = "[ " .. Keybind.Value .. " ]"

	KeybindAsset.MouseButton1Click:Connect(function()
		KeybindAsset.Text = "[ ... ]"
		Keybind.WaitingForBind = true
	end)
	KeybindAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
		KeybindAsset.Size = UDim2.new(0,KeybindAsset.TextBounds.X,1,0)
	end)

	if type(Window.KeybindList) == "table" and not Keybind.IgnoreList then
		Keybind.ListMimic = {}
		Keybind.ListMimic.Asset = GetAsset("KeybindList/KeybindMimic")
		Keybind.ListMimic.Asset.Title.Text = Toggle.Name
		Keybind.ListMimic.Asset.Visible = Keybind.Value ~= "NONE"
		Keybind.ListMimic.Asset.Parent = Window.KeybindList.List

		Keybind.ListMimic.ColorConfig = {false,"BackgroundColor3"}
		Window.Colorable[Keybind.ListMimic.Asset.Tick] = Keybind.ListMimic.ColorConfig
	end

	UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
		if GameProcessedEvent then return end
		local Key = Input.KeyCode.Name
		if Keybind.WaitingForBind and Input.UserInputType.Name == "Keyboard" then
			Keybind.Value = Key
		elseif Input.UserInputType.Name == "Keyboard" then
			if Key == Keybind.Value then
				if not Keybind.DisableToggle then Toggle.Value = not Toggle.Value end
				Keybind.Callback(Keybind.Value,true,Toggle.Value)
			end
		end
		if Keybind.Mouse then Key = Input.UserInputType.Name
			if Keybind.WaitingForBind and (Key == "MouseButton1"
				or Key == "MouseButton2" or Key == "MouseButton3") then
				Keybind.Value = Key
			elseif Key == "MouseButton1"
				or Key == "MouseButton2"
				or Key == "MouseButton3" then
				if Key == Keybind.Value then
					if not Keybind.DisableToggle then Toggle.Value = not Toggle.Value end
					Keybind.Callback(Keybind.Value,true,Toggle.Value)
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
		if GameProcessedEvent then return end
		local Key = Input.KeyCode.Name
		if Input.UserInputType.Name == "Keyboard" then
			if Key == Keybind.Value then
				Keybind.Callback(Keybind.Value,false,Toggle.Value)
			end
		end
		if Keybind.Mouse then Key = Input.UserInputType.Name
			if Key == "MouseButton1"
				or Key == "MouseButton2"
				or Key == "MouseButton3" then
				if Key == Keybind.Value then
					Keybind.Callback(Keybind.Value,false,Toggle.Value)
				end
			end
		end
	end)

	Toggle:GetPropertyChangedSignal("Value"):Connect(function(Value)
		if Keybind.ListMimic then
			Keybind.ListMimic.ColorConfig[1] = Value
			Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Value
			and Window.Color or Color3.fromRGB(60,60,60)
		end
	end)

	Keybind:GetPropertyChangedSignal("Value"):Connect(function(Value,OldValue)
		if table.find(Keybind.Blacklist,Value) then
			if Keybind.DoNotClear then
				Keybind.Internal.Value = OldValue
				Value = OldValue
			else
				Keybind.Internal.Value = "NONE"
				Value = "NONE"
			end
		end

		KeybindAsset.Text = "[ " .. tostring(Value) .. " ]"
		if Keybind.ListMimic then
			Keybind.ListMimic.Asset.Visible = Value ~= "NONE"
			Keybind.ListMimic.Asset.Layout.TKeybind.Text = "[ " .. tostring(Value) .. " ]"
		end

		Keybind.WaitingForBind = false
		Window.Flags[Keybind.Flag] = Value
		Keybind.Callback(Value,false,Toggle.Value)
	end)
end
function Assets:Dropdown(Parent,ScreenAsset,Window,Dropdown)
	local OptionContainerAsset = GetAsset("Dropdown/OptionContainer")
	local DropdownAsset = GetAsset("Dropdown/Dropdown")

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Name = "ScrollingFrame"
	ScrollingFrame.Size = UDim2.new(1,0,1,0)
	ScrollingFrame.Position = UDim2.new(0,0,0,0)
	ScrollingFrame.BackgroundTransparency = 1
	ScrollingFrame.BorderSizePixel = 0
	ScrollingFrame.ScrollBarThickness = 6
	ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	ScrollingFrame.ScrollingEnabled = true
	ScrollingFrame.ElasticBehavior = Enum.ElasticBehavior.Always
	ScrollingFrame.Visible = true
	ScrollingFrame.Active = true
	ScrollingFrame.ZIndex = 101

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Name = "ListLayout"
	ListLayout.Padding = UDim.new(0,2)
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ScrollingFrame

	for _,Child in pairs(OptionContainerAsset:GetChildren()) do
		if Child:IsA("GuiObject") and Child.Name ~= "ListLayout" then
			Child.Parent = ScrollingFrame
		end
	end

	local OldListLayout = OptionContainerAsset:FindFirstChild("ListLayout")
	if OldListLayout then
		OldListLayout:Destroy()
	end

	ScrollingFrame.Parent = OptionContainerAsset

	Dropdown.Internal.Value = {}
	local ContainerRender = nil

	DropdownAsset.Parent = Parent
	OptionContainerAsset.Parent = ScreenAsset
	OptionContainerAsset.Visible = false
	OptionContainerAsset.ZIndex = 100
	OptionContainerAsset.Active = true
	OptionContainerAsset.ClipsDescendants = true

	DropdownAsset.Title.Text = Dropdown.Name
	DropdownAsset.Title.Visible = not Dropdown.HideName
	DropdownAsset.Title.TextColor3 = Color3.fromRGB(255,255,255)
	if DropdownAsset.Background and DropdownAsset.Background:FindFirstChild("Value") then
		DropdownAsset.Background.Value.TextColor3 = Color3.fromRGB(200,200,200)
		DropdownAsset.Background.Value.TextStrokeTransparency = 0.8
	end

	local function ToggleDropdown()
		if not OptionContainerAsset.Visible and ListLayout.AbsoluteContentSize.Y ~= 0 then
			OptionContainerAsset.Visible = true
			local DropdownPosition = UDim2.fromOffset(
				DropdownAsset.Background.AbsolutePosition.X + 1,
				DropdownAsset.Background.AbsolutePosition.Y + DropdownAsset.Background.AbsoluteSize.Y + 2
			)

			local MaxHeight = 150
			local ContentHeight = ListLayout.AbsoluteContentSize.Y
			local ActualHeight = math.min(ContentHeight,MaxHeight)

			OptionContainerAsset.Position = DropdownPosition
			OptionContainerAsset.Size = UDim2.fromOffset(
				DropdownAsset.Background.AbsoluteSize.X - 2,
				ActualHeight
			)

			ScrollingFrame.Size = UDim2.new(1,0,1,0)
			ScrollingFrame.CanvasSize = UDim2.fromOffset(0,ContentHeight)

			if UserInputService.TouchEnabled then
				local CloseTouchArea = Instance.new("TextButton")
				CloseTouchArea.Name = "MobileCloseArea"
				CloseTouchArea.BackgroundTransparency = 1
				CloseTouchArea.Size = UDim2.new(1,0,1,0)
				CloseTouchArea.ZIndex = 5
				CloseTouchArea.Parent = ScreenAsset
				CloseTouchArea.MouseButton1Click:Connect(function()
					OptionContainerAsset.Visible = false
					CloseTouchArea:Destroy()
				end)
			end
		else
			OptionContainerAsset.Visible = false
			local CloseArea = ScreenAsset:FindFirstChild("MobileCloseArea")
			if CloseArea then
				CloseArea:Destroy()
			end
		end
	end

	local DropdownTouchStart, DropdownStartTime = nil, nil
	local DropdownIsDragging = false

	DropdownAsset.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			DropdownTouchStart = Input.Position
			DropdownStartTime = tick()
			DropdownIsDragging = false
		end
	end)

	DropdownAsset.InputChanged:Connect(function(Input)
		if DropdownTouchStart and (Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = (Input.Position - DropdownTouchStart).Magnitude
			if Delta > 5 then
				DropdownIsDragging = true
			end
		end
	end)

	DropdownAsset.InputEnded:Connect(function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch) and DropdownTouchStart then
			local Duration = tick() - DropdownStartTime
			if not DropdownIsDragging and Duration < 0.3 then
				ToggleDropdown()
			end
			DropdownTouchStart = nil
			DropdownIsDragging = false
		end
	end)

	DropdownAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		DropdownAsset.Title.Size = Dropdown.HideName and UDim2.fromScale(1,0)
			or UDim2.new(1,0,0,DropdownAsset.Title.TextBounds.Y + 2)

		DropdownAsset.Background.Position = UDim2.new(0.5,0,0,DropdownAsset.Title.Size.Y.Offset)
		DropdownAsset.Size = UDim2.new(1,0,0,DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
	end)

	ScrollingFrame.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollingFrame.CanvasSize = UDim2.fromOffset(0,ScrollingFrame.ListLayout.AbsoluteContentSize.Y + 4)
	end)

	local function RefreshSelected()
		table.clear(Dropdown.Internal.Value)

		for Index,Option in pairs(Dropdown.List) do
			if Option.Value then
				table.insert(Dropdown.Internal.Value,Option.Name)
			end
		end

		Window.Flags[Dropdown.Flag] = Dropdown.Internal.Value
		DropdownAsset.Background.Value.Text = #Dropdown.Internal.Value == 0
			and "..." or table.concat(Dropdown.Internal.Value,", ")
	end

	local function SetValue(Option,Value)
		Option.Value = Value
		Option.ColorConfig[1] = Value
		Option.Object.Tick.BackgroundColor3 = Value
			and Window.Color or Color3.fromRGB(60,60,60)
	end

	local function AddOption(Option,AddToList,Order)
		Option = GetType(Option,{},"table",true)
		Option.Name = GetType(Option.Name,"Option","string")
		Option.Mode = GetType(Option.Mode,"Button","string")
		Option.Value = GetType(Option.Value,false,"boolean")
		Option.Callback = GetType(Option.Callback,function() end,"function")

	local OptionAsset = GetAsset("Dropdown/Option")
	Option.Object = OptionAsset

	OptionAsset.LayoutOrder = Order
	OptionAsset.ZIndex = 102
	OptionAsset.Active = true
	OptionAsset.Visible = true
	OptionAsset.BackgroundTransparency = 0.95
	OptionAsset.BackgroundColor3 = Color3.fromRGB(30,30,30)
	
	if OptionAsset:FindFirstChild("Title") then
		OptionAsset.Title.Text = Option.Name
		OptionAsset.Title.ZIndex = 103
		OptionAsset.Title.TextColor3 = Color3.fromRGB(255,255,255)
		OptionAsset.Title.TextTransparency = 0
		OptionAsset.Title.TextStrokeTransparency = 0.5
		OptionAsset.Title.TextStrokeColor3 = Color3.fromRGB(0,0,0)
		OptionAsset.Title.Visible = true
		OptionAsset.Title.BackgroundTransparency = 1
		OptionAsset.Title.TextSize = 14
	end
	
	if OptionAsset:FindFirstChild("Tick") then
		OptionAsset.Tick.BackgroundColor3 = Option.Value
			and Window.Color or Color3.fromRGB(60,60,60)
		OptionAsset.Tick.ZIndex = 103
		OptionAsset.Tick.Visible = true
	end
	
	OptionAsset.Parent = ScrollingFrame

	Option.ColorConfig = {Option.Value,"BackgroundColor3"}
		Window.Colorable[OptionAsset.Tick] = Option.ColorConfig
		if AddToList then table.insert(Dropdown.List,Option) end

		local OptionTouchStart, OptionStartTime = nil, nil
		local OptionIsDragging = false

		local function SelectOption()
			Option.Value = not Option.Value
		end

		OptionAsset.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
				OptionTouchStart = Input.Position
				OptionStartTime = tick()
				OptionIsDragging = false
			end
		end)

		OptionAsset.InputChanged:Connect(function(Input)
			if OptionTouchStart and (Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch) then
				local Delta = (Input.Position - OptionTouchStart).Magnitude
				if Delta > 10 then
					OptionIsDragging = true
				end
			end
		end)

		OptionAsset.InputEnded:Connect(function(Input)
			if (Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch) and OptionTouchStart then
				local Duration = tick() - OptionStartTime
				if not OptionIsDragging and Duration < 0.3 then
					SelectOption()
				end
				OptionTouchStart = nil
				OptionIsDragging = false
			end
		end)

		if UserInputService.TouchEnabled then
			OptimizeForMobile(OptionAsset,false)
		end

		OptionAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			OptionAsset.Layout.Size = UDim2.new(1,-OptionAsset.Title.TextBounds.X - 22,1,0)
		end)

		Option:GetPropertyChangedSignal("Name"):Connect(function(Name)
			OptionAsset.Title.Text = Name
		end)
		Option:GetPropertyChangedSignal("Value"):Connect(function(Value)
			if Option.Mode == "Button" then
				for Index,OldOption in pairs(Dropdown.List) do
					SetValue(OldOption.Internal,false)
				end Option.Internal.Value = true
				Value = Option.Internal.Value
				OptionContainerAsset.Visible = false
			end

			RefreshSelected()
			Option.ColorConfig[1] = Value
			Option.Object.Tick.BackgroundColor3 = Value
				and Window.Color or Color3.fromRGB(60,60,60)
			Option.Callback(Dropdown.Value,Option)
		end)

		for Index,Value in pairs(Option.Internal) do
			if string.find(Index,"Colorpicker") then
				Option[Index] = GetType(Option[Index],{},"table",true)
				Option[Index].Flag = GetType(Option[Index].Flag,
					Dropdown.Flag .. "/" .. Option.Name .. "/Colorpicker","string")

				Option[Index].Value = GetType(Option[Index].Value,{1,1,1,0,false},"table")
				Option[Index].Callback = GetType(Option[Index].Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Option[Index]
				Window.Flags[Option[Index].Flag] = Option[Index].Value

				Assets:ToggleColorpicker(OptionAsset.Layout,ScreenAsset,Window,Option[Index])
			end
		end

		return Option
	end

	for Index,Option in pairs(Dropdown.List) do
		Dropdown.List[Index] = AddOption(Option,false,Index)
	end for Index,Option in pairs(Dropdown.List) do
		if Option.Value then Option.Value = true end
	end RefreshSelected()

	function Dropdown:BulkAdd(Table)
		for Index,Option in pairs(Table) do
			AddOption(Option,true,Index)
		end
	end
	function Dropdown:AddOption(Option)
		AddOption(Option,true,#Dropdown.List)
	end

	function Dropdown:Clear()
		for Index,Option in pairs(Dropdown.List) do
			Option.Object:Destroy()
		end table.clear(Dropdown.List)
	end
	function Dropdown:RemoveOption(Name)
		for Index,Option in pairs(Dropdown.List) do
			if Option.Name == Name then
				Option.Object:Destroy()
				table.remove(Dropdown.List,Index)
			end
		end
		for Index,Option in pairs(Dropdown.List) do
			Option.Object.LayoutOrder = Index
		end
	end
	function Dropdown:RefreshToPlayers(ToggleMode)
		local Players = {}
		for Index,Player in pairs(PlayerService:GetPlayers()) do
			if Player == LocalPlayer then continue end
			table.insert(Players,{Name = Player.Name,
				Mode = ToggleMode == "Toggle" or "Button"
			})
		end
		Dropdown:Clear()
		Dropdown:BulkAdd(Players)
	end

	Dropdown:GetPropertyChangedSignal("Name"):Connect(function(Name)
		DropdownAsset.Title.Text = Name
	end)
	Dropdown:GetPropertyChangedSignal("Value"):Connect(function(Value)
		if type(Value) ~= "table" then return end
		if #Value == 0 then RefreshSelected() return end

		for Index,Option in pairs(Dropdown.List) do
			if table.find(Value,Option.Name) then
				Option.Value = true
			else
				if Option.Mode ~= "Button" then
					Option.Value = false
				end
			end
		end
	end)

	function Dropdown:ToolTip(Text)
		Assets:ToolTip(DropdownAsset,ScreenAsset,Text)
	end
end
function Assets:Colorpicker(Parent,ScreenAsset,Window,Colorpicker)
	local ColorpickerAsset = GetAsset("Colorpicker/Colorpicker")
	local PaletteAsset = GetAsset("Colorpicker/Palette")

	Colorpicker.ColorConfig = {Colorpicker.Value[5],"BackgroundColor3"}
	Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig
	local PaletteRender,SVRender,HueRender,AlphaRender = nil,nil,nil,nil


	ColorpickerAsset.Parent = Parent
	ColorpickerAsset.Active = true
	PaletteAsset.Parent = ScreenAsset
	PaletteAsset.Active = true
	PaletteAsset.SVPicker.Active = true
	PaletteAsset.Hue.Active = true
	PaletteAsset.Alpha.Active = true
	PaletteAsset.Rainbow.Active = true

	ColorpickerAsset.Title.Text = Colorpicker.Name
	PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
		and Window.Color or Color3.fromRGB(60,60,60)


	ColorpickerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		ColorpickerAsset.Size = UDim2.new(1,0,0,ColorpickerAsset.Title.TextBounds.Y)
	end)

	ColorpickerAsset.MouseButton1Click:Connect(function()
		if not PaletteAsset.Visible then
			PaletteAsset.Visible = true
			PaletteRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then PaletteRender:Disconnect() end
				PaletteAsset.Position = UDim2.fromOffset(
					(ColorpickerAsset.Color.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 21,
					ColorpickerAsset.Color.AbsolutePosition.Y + 50
				)
			end)
		else
			PaletteAsset.Visible = false
		end
	end)

	PaletteAsset.Rainbow.MouseButton1Click:Connect(function()
		Colorpicker.Value[5] = not Colorpicker.Value[5]
		Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(60,60,60)
	end)
	PaletteAsset.SVPicker.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if SVRender then SVRender:Disconnect() end
			SVRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then SVRender:Disconnect() end
				local Mouse = UserInputService:GetMouseLocation()
				local ColorX = math.clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X,0,PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X
				local ColorY = math.clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + 36),0,PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y

				Colorpicker.Value[2] = ColorX
				Colorpicker.Value[3] = 1 - ColorY
				Colorpicker.Value = Colorpicker.Value
			end)
		end
	end)
	PaletteAsset.SVPicker.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if SVRender then SVRender:Disconnect() end
		end
	end)
	PaletteAsset.Hue.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if HueRender then HueRender:Disconnect() end
			HueRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then HueRender:Disconnect() end
				local Mouse = UserInputService:GetMouseLocation()
				local ColorX = math.clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X,0,PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
				Colorpicker.Value[1] = 1 - ColorX
				Colorpicker.Value = Colorpicker.Value
			end)
		end
	end)
	PaletteAsset.Hue.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if HueRender then HueRender:Disconnect() end
		end
	end)
	PaletteAsset.Alpha.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if AlphaRender then AlphaRender:Disconnect() end
			AlphaRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then AlphaRender:Disconnect() end
				local Mouse = UserInputService:GetMouseLocation()
				local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X,0,PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
				Colorpicker.Value[4] = math.floor(ColorX * 10^2) / (10^2) -- idk %.2f little bit broken with this
				Colorpicker.Value = Colorpicker.Value
			end)
		end
	end)
	PaletteAsset.Alpha.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if AlphaRender then AlphaRender:Disconnect() end
		end
	end)

	PaletteAsset.RGB.RGBBox.FocusLost:Connect(function(Enter)
		if not Enter then return end
		local ColorString = string.split(string.gsub(PaletteAsset.RGB.RGBBox.Text," ",""),",")
		local Hue,Saturation,Value = Color3.fromRGB(ColorString[1],ColorString[2],ColorString[3]):ToHSV()
		PaletteAsset.RGB.RGBBox.Text = ""
		Colorpicker.Value[1] = Hue
		Colorpicker.Value[2] = Saturation
		Colorpicker.Value[3] = Value
		Colorpicker.Value = Colorpicker.Value
	end)
	PaletteAsset.HEX.HEXBox.FocusLost:Connect(function(Enter)
		if not Enter then return end
		local Hue,Saturation,Value = Color3.fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
		PaletteAsset.RGB.RGBBox.Text = ""
		Colorpicker.Value[1] = Hue
		Colorpicker.Value[2] = Saturation
		Colorpicker.Value[3] = Value
		Colorpicker.Value = Colorpicker.Value
	end)

	RunService.Heartbeat:Connect(function()
		if Colorpicker.Value[5] then
			if PaletteAsset.Visible then
				Colorpicker.Value[1] = Window.RainbowHue
				Colorpicker.Value = Colorpicker.Value
			else 
				Colorpicker.Value[1] = Window.RainbowHue
				Colorpicker.Value[6] = TableToColor(Colorpicker.Value)
				ColorpickerAsset.Color.BackgroundColor3 = Colorpicker.Value[6]
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value
				Colorpicker.Callback(Colorpicker.Value,Colorpicker.Value[6])
			end
		end
	end)

	Colorpicker:GetPropertyChangedSignal("Name"):Connect(function(Name)
		ColorpickerAsset.Title.Text = Name
	end)
	Colorpicker:GetPropertyChangedSignal("Value"):Connect(function(Value)
		Value[6] = TableToColor(Value)
		Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
		ColorpickerAsset.Color.BackgroundColor3 = Value[6]

		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(60,60,60)

		PaletteAsset.SVPicker.BackgroundColor3 = Color3.fromHSV(Value[1],1,1)
		PaletteAsset.SVPicker.Pin.Position = UDim2.fromScale(Value[2],1 - Value[3])
		PaletteAsset.Hue.Pin.Position = UDim2.fromScale(1 - Value[1],0.5)

		PaletteAsset.Alpha.Pin.Position = UDim2.fromScale(Value[4],0.5)
		PaletteAsset.Alpha.Value.Text = Value[4]
		PaletteAsset.Alpha.BackgroundColor3 = Value[6]

		PaletteAsset.RGB.RGBBox.PlaceholderText = ColorToString(Value[6])
		PaletteAsset.HEX.HEXBox.PlaceholderText = Value[6]:ToHex()
		Window.Flags[Colorpicker.Flag] = Value
		Colorpicker.Callback(Value,Value[6])
	end) Colorpicker.Value = Colorpicker.Value

	function Colorpicker:ToolTip(Text)
		Assets:ToolTip(ColorpickerAsset,ScreenAsset,Text)
	end
end
function Assets:ToggleColorpicker(Parent,ScreenAsset,Window,Colorpicker)
	local ColorpickerAsset = GetAsset("Colorpicker/TColorpicker")
	local PaletteAsset = GetAsset("Colorpicker/Palette")

	Colorpicker.ColorConfig = {Colorpicker.Value[5],"BackgroundColor3"}
	Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig
	local PaletteRender,SVRender,HueRender,AlphaRender = nil,nil,nil,nil

	ColorpickerAsset.Parent = Parent
	ColorpickerAsset.Active = true
	PaletteAsset.Parent = ScreenAsset
	PaletteAsset.Active = true
	PaletteAsset.SVPicker.Active = true
	PaletteAsset.Hue.Active = true
	PaletteAsset.Alpha.Active = true
	PaletteAsset.Rainbow.Active = true

	PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
		and Window.Color or Color3.fromRGB(60,60,60)

	ColorpickerAsset.MouseButton1Click:Connect(function()
		if not PaletteAsset.Visible then
			PaletteAsset.Visible = true
			PaletteRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then PaletteRender:Disconnect() end
				PaletteAsset.Position = UDim2.fromOffset(
					(ColorpickerAsset.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 21,
					ColorpickerAsset.AbsolutePosition.Y + 50
				)
			end)
		else
			PaletteAsset.Visible = false
		end
	end)

	PaletteAsset.Rainbow.MouseButton1Click:Connect(function()
		Colorpicker.Value[5] = not Colorpicker.Value[5]
		Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(60,60,60)
	end)
	PaletteAsset.SVPicker.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if SVRender then SVRender:Disconnect() end
			SVRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then SVRender:Disconnect() end
				local Mouse = UserInputService:GetMouseLocation()
				local ColorX = math.clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X,0,PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X

				local ColorY = math.clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + 36),0,PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y
				Colorpicker.Value[2] = ColorX
				Colorpicker.Value[3] = 1 - ColorY
				Colorpicker.Value = Colorpicker.Value
			end)
		end
	end)
	PaletteAsset.SVPicker.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if SVRender then SVRender:Disconnect() end
		end
	end)
	PaletteAsset.Hue.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if HueRender then HueRender:Disconnect() end
			HueRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then HueRender:Disconnect() end
				local Mouse = UserInputService:GetMouseLocation()
				local ColorX = math.clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X,0,PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
				Colorpicker.Value[1] = 1 - ColorX
				Colorpicker.Value = Colorpicker.Value
			end)
		end
	end)
	PaletteAsset.Hue.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if HueRender then HueRender:Disconnect() end
		end
	end)
	PaletteAsset.Alpha.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if AlphaRender then AlphaRender:Disconnect() end
			AlphaRender = RunService.RenderStepped:Connect(function()
				if not PaletteAsset.Visible then AlphaRender:Disconnect() end
				local Mouse = UserInputService:GetMouseLocation()
				local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X,0,PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
				Colorpicker.Value[4] = math.floor(ColorX * 10^2) / (10^2) -- idk %.2f little bit broken with this
				Colorpicker.Value = Colorpicker.Value
			end)
		end
	end)
	PaletteAsset.Alpha.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if AlphaRender then AlphaRender:Disconnect() end
		end
	end)

	PaletteAsset.RGB.RGBBox.FocusLost:Connect(function(Enter)
		if not Enter then return end
		local ColorString = string.split(string.gsub(PaletteAsset.RGB.RGBBox.Text," ",""),",")
		local Hue,Saturation,Value = Color3.fromRGB(ColorString[1],ColorString[2],ColorString[3]):ToHSV()
		PaletteAsset.RGB.RGBBox.Text = ""
		Colorpicker.Value[1] = Hue
		Colorpicker.Value[2] = Saturation
		Colorpicker.Value[3] = Value
		Colorpicker.Value = Colorpicker.Value
	end)
	PaletteAsset.HEX.HEXBox.FocusLost:Connect(function(Enter)
		if not Enter then return end
		local Hue,Saturation,Value = Color3.fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
		PaletteAsset.RGB.RGBBox.Text = ""
		Colorpicker.Value[1] = Hue
		Colorpicker.Value[2] = Saturation
		Colorpicker.Value[3] = Value
		Colorpicker.Value = Colorpicker.Value
	end)

	RunService.Heartbeat:Connect(function()
		if Colorpicker.Value[5] then
			if PaletteAsset.Visible then
				Colorpicker.Value[1] = Window.RainbowHue
				Colorpicker.Value = Colorpicker.Value
			else 
				Colorpicker.Value[1] = Window.RainbowHue
				Colorpicker.Value[6] = TableToColor(Colorpicker.Value)
				ColorpickerAsset.BackgroundColor3 = Colorpicker.Value[6]
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value
				Colorpicker.Callback(Colorpicker.Value,Colorpicker.Value[6])
			end
		end
	end)
	Colorpicker:GetPropertyChangedSignal("Value"):Connect(function(Value)
		Value[6] = TableToColor(Value)
		Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
		ColorpickerAsset.BackgroundColor3 = Value[6]

		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(60,60,60)

		PaletteAsset.SVPicker.BackgroundColor3 = Color3.fromHSV(Value[1],1,1)
		PaletteAsset.SVPicker.Pin.Position = UDim2.fromScale(Value[2],1 - Value[3])
		PaletteAsset.Hue.Pin.Position = UDim2.fromScale(1 - Value[1],0.5)

		PaletteAsset.Alpha.Pin.Position = UDim2.fromScale(Value[4],0.5)
		PaletteAsset.Alpha.Value.Text = Value[4]
		PaletteAsset.Alpha.BackgroundColor3 = Value[6]

		PaletteAsset.RGB.RGBBox.PlaceholderText = ColorToString(Value[6])
		PaletteAsset.HEX.HEXBox.PlaceholderText = Value[6]:ToHex()
		Window.Flags[Colorpicker.Flag] = Value
		Colorpicker.Callback(Value,Value[6])
	end) Colorpicker.Value = Colorpicker.Value
end

local Bracket = Assets:Screen()
function Bracket:Window(Window)
	Window = GetType(Window,{},"table",true)
	Window.Blur = GetType(Window.Blur,false,"boolean")
	Window.Name = GetType(Window.Name,"Window","string")
	Window.Enabled = GetType(Window.Enabled,true,"boolean")
	Window.Color = GetType(Window.Color,Color3.new(1,0.5,0.25),"Color3")
	Window.Position = GetType(Window.Position,UDim2.new(0.5,-248,0.5,-248),"UDim2")
	Window.Size = GetType(Window.Size,UDim2.new(0,496,0,496),"UDim2")
	local WindowAsset = Assets:Window(Bracket.ScreenAsset,Window)

	function Window:Tab(Tab)
		Tab = GetType(Tab,{},"table",true)
		Tab.Name = GetType(Tab.Name,"Tab","string")
		local TabAsset = Assets:Tab(Bracket.ScreenAsset,WindowAsset,Window,Tab)

		function Tab:AddConfigSection(FolderName,Side)
			local ConfigSection = Tab:Section({Name = "Config System",Side = Side}) do
				local ConfigList,ConfigDropdown = ConfigsToList(FolderName),nil
				local ALConfig = Window:GetAutoLoadConfig(FolderName)

				local function UpdateList(Name) ConfigDropdown:Clear()
					ConfigList = ConfigsToList(FolderName) ConfigDropdown:BulkAdd(ConfigList)
					ConfigDropdown.Value = {}
					--ConfigDropdown.Value = {Name or (ConfigList[#ConfigList] and ConfigList[#ConfigList].Name)}
				end

				local ConfigTextbox = ConfigSection:Textbox({HideName = true,Placeholder = "Config Name",IgnoreFlag = true})
				ConfigSection:Button({Name = "Create",Callback = function()
					Window:SaveConfig(FolderName,ConfigTextbox.Value) UpdateList(ConfigTextbox.Value)
				end})

				ConfigSection:Divider({Text = "Configs"})

				ConfigDropdown = ConfigSection:Dropdown({HideName = true,IgnoreFlag = true,List = ConfigList})
				--ConfigDropdown.Value = {ConfigList[#ConfigList] and ConfigList[#ConfigList].Name}

				ConfigSection:Button({Name = "Save",Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:SaveConfig(FolderName,ConfigDropdown.Value[1])
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Load",Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:LoadConfig(FolderName,ConfigDropdown.Value[1])
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Delete",Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:DeleteConfig(FolderName,ConfigDropdown.Value[1])
						UpdateList()
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Refresh",Callback = UpdateList})

				local ConfigDivider = ConfigSection:Divider({Text = not ALConfig and "AutoLoad Config"
					or "AutoLoad Config\n<font color=\"rgb(189,189,189)\">[ " .. ALConfig .. " ]</font>"})

				ConfigSection:Button({Name = "Set AutoLoad Config",Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:AddToAutoLoad(FolderName,ConfigDropdown.Value[1])
						ConfigDivider.Text = "AutoLoad Config\n<font color=\"rgb(189,189,189)\">[ " .. ConfigDropdown.Value[1] .. " ]</font>"
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Clear AutoLoad Config",Callback = function()
					Window:RemoveFromAutoLoad(FolderName)
					ConfigDivider.Text = "AutoLoad Config"
				end})
			end
		end

		function Tab:Divider(Divider)
			Divider = GetType(Divider,{},"table",true)
			Divider.Text = GetType(Divider.Text,"","string")
			Assets:Divider(ChooseTabSide(TabAsset,Divider.Side),Divider)
			return Divider
		end
		function Tab:Label(Label)
			Label = GetType(Label,{},"table",true)
			Label.Text = GetType(Label.Text,"Label","string")
			Assets:Label(ChooseTabSide(TabAsset,Label.Side),Label)
			return Label
		end
		function Tab:Button(Button)
			Button = GetType(Button,{},"table",true)
			Button.Name = GetType(Button.Name,"Button","string")
			Button.Callback = GetType(Button.Callback,function() end,"function")
			Assets:Button(ChooseTabSide(TabAsset,Button.Side),Bracket.ScreenAsset,Window,Button)
			return Button
		end
		function Tab:Toggle(Toggle)
			Toggle = GetType(Toggle,{},"table",true)
			Toggle.Name = GetType(Toggle.Name,"Toggle","string")
			Toggle.Flag = GetType(Toggle.Flag,Toggle.Name,"string")

			Toggle.Value = GetType(Toggle.Value,false,"boolean")
			Toggle.Callback = GetType(Toggle.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Toggle
			Window.Flags[Toggle.Flag] = Toggle.Value

			local ToggleAsset = Assets:Toggle(ChooseTabSide(TabAsset,Toggle.Side),Bracket.ScreenAsset,Window,Toggle)
			function Toggle:Keybind(Keybind)
				Keybind = GetType(Keybind,{},"table",true)
				Keybind.Flag = GetType(Keybind.Flag,Toggle.Flag .. "/Keybind","string")

				Keybind.Value = GetType(Keybind.Value,"NONE","string")
				Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
				Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
				Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
				Window.Elements[#Window.Elements + 1] = Keybind
				Window.Flags[Keybind.Flag] = Keybind.Value

				Assets:ToggleKeybind(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Keybind,Toggle)
				return Keybind
			end
			function Toggle:Colorpicker(Colorpicker)
				Colorpicker = GetType(Colorpicker,{},"table",true)
				Colorpicker.Flag = GetType(Colorpicker.Flag,Toggle.Flag .. "/Colorpicker","string")

				Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
				Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Colorpicker
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value

				Assets:ToggleColorpicker(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Colorpicker)
				return Colorpicker
			end
			return Toggle
		end
		function Tab:Slider(Slider)
			Slider = GetType(Slider,{},"table",true)
			Slider.Name = GetType(Slider.Name,"Slider","string")
			Slider.Flag = GetType(Slider.Flag,Slider.Name,"string")

			Slider.Min = GetType(Slider.Min,0,"number")
			Slider.Max = GetType(Slider.Max,100,"number")
			Slider.Precise = GetType(Slider.Precise,0,"number")
			Slider.Unit = GetType(Slider.Unit,"","string")
			Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
			Slider.Callback = GetType(Slider.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Slider
			Window.Flags[Slider.Flag] = Slider.Value

			Assets:Slider(ChooseTabSide(TabAsset,Slider.Side),Bracket.ScreenAsset,Window,Slider)
			return Slider
		end
		function Tab:Textbox(Textbox)
			Textbox = GetType(Textbox,{},"table",true)
			Textbox.Name = GetType(Textbox.Name,"Textbox","string")
			Textbox.Flag = GetType(Textbox.Flag,Textbox.Name,"string")

			Textbox.Value = GetType(Textbox.Value,"","string")
			Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean")
			Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
			Textbox.Callback = GetType(Textbox.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Textbox
			Window.Flags[Textbox.Flag] = Textbox.Value

			Assets:Textbox(ChooseTabSide(TabAsset,Textbox.Side),Bracket.ScreenAsset,Window,Textbox)
			return Textbox
		end
		function Tab:Keybind(Keybind)
			Keybind = GetType(Keybind,{},"table",true)
			Keybind.Name = GetType(Keybind.Name,"Keybind","string")
			Keybind.Flag = GetType(Keybind.Flag,Keybind.Name,"string")

			Keybind.Value = GetType(Keybind.Value,"NONE","string")
			Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
			Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
			Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
			Window.Elements[#Window.Elements + 1] = Keybind
			Window.Flags[Keybind.Flag] = Keybind.Value

			Assets:Keybind(ChooseTabSide(TabAsset,Keybind.Side),Bracket.ScreenAsset,Window,Keybind)
			return Keybind
		end
		function Tab:Dropdown(Dropdown)
			Dropdown = GetType(Dropdown,{},"table",true)
			Dropdown.Name = GetType(Dropdown.Name,"Dropdown","string")
			Dropdown.Flag = GetType(Dropdown.Flag,Dropdown.Name,"string")
			Dropdown.List = GetType(Dropdown.List,{},"table")
			Window.Elements[#Window.Elements + 1] = Dropdown
			Window.Flags[Dropdown.Flag] = Dropdown.Value

			Assets:Dropdown(ChooseTabSide(TabAsset,Dropdown.Side),Bracket.ScreenAsset,Window,Dropdown)
			return Dropdown
		end
		function Tab:Colorpicker(Colorpicker)
			Colorpicker = GetType(Colorpicker,{},"table",true)
			Colorpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string")
			Colorpicker.Flag = GetType(Colorpicker.Flag,Colorpicker.Name,"string")

			Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
			Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
			Window.Elements[#Window.Elements + 1] = Colorpicker
			Window.Flags[Colorpicker.Flag] = Colorpicker.Value

			Assets:Colorpicker(ChooseTabSide(TabAsset,Colorpicker.Side),Bracket.ScreenAsset,Window,Colorpicker)
			return Colorpicker
		end
		function Tab:Section(Section)
			Section = GetType(Section,{},"table",true)
			Section.Name = GetType(Section.Name,"Section","string")
			local SectionContainer = Assets:Section(ChooseTabSide(TabAsset,Section.Side),Section)

			function Section:Divider(Divider)
				Divider = GetType(Divider,{},"table",true)
				Divider.Text = GetType(Divider.Text,"","string")
				Assets:Divider(SectionContainer,Divider)
				return Divider
			end
			function Section:Label(Label)
				Label = GetType(Label,{},"table",true)
				Label.Text = GetType(Label.Text,"Label","string")
				Assets:Label(SectionContainer,Label)
				return Label
			end
			function Section:Button(Button)
				Button = GetType(Button,{},"table",true)
				Button.Name = GetType(Button.Name,"Button","string")
				Button.Callback = GetType(Button.Callback,function() end,"function")
				Assets:Button(SectionContainer,Bracket.ScreenAsset,Window,Button)
				return Button
			end
			function Section:Toggle(Toggle)
				Toggle = GetType(Toggle,{},"table",true)
				Toggle.Name = GetType(Toggle.Name,"Toggle","string")
				Toggle.Flag = GetType(Toggle.Flag,Toggle.Name,"string")

				Toggle.Value = GetType(Toggle.Value,false,"boolean")
				Toggle.Callback = GetType(Toggle.Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Toggle
				Window.Flags[Toggle.Flag] = Toggle.Value

				local ToggleAsset = Assets:Toggle(SectionContainer,Bracket.ScreenAsset,Window,Toggle)
				function Toggle:Keybind(Keybind)
					Keybind = GetType(Keybind,{},"table",true)
					Keybind.Flag = GetType(Keybind.Flag,Toggle.Flag .. "/Keybind","string")

					Keybind.Value = GetType(Keybind.Value,"NONE","string")
					Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
					Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
					Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
					Window.Elements[#Window.Elements + 1] = Keybind
					Window.Flags[Keybind.Flag] = Keybind.Value

					Assets:ToggleKeybind(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Keybind,Toggle)
					return Keybind
				end
				function Toggle:Colorpicker(Colorpicker)
					Colorpicker = GetType(Colorpicker,{},"table",true)
					Colorpicker.Flag = GetType(Colorpicker.Flag,Toggle.Flag .. "/Colorpicker","string")

					Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
					Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
					Window.Elements[#Window.Elements + 1] = Colorpicker
					Window.Flags[Colorpicker.Flag] = Colorpicker.Value

					Assets:ToggleColorpicker(ToggleAsset.Layout,Bracket.ScreenAsset,Window,Colorpicker)
					return Colorpicker
				end
				return Toggle
			end
			function Section:Slider(Slider)
				Slider = GetType(Slider,{},"table",true)
				Slider.Name = GetType(Slider.Name,"Slider","string")
				Slider.Flag = GetType(Slider.Flag,Slider.Name,"string")

				Slider.Min = GetType(Slider.Min,0,"number")
				Slider.Max = GetType(Slider.Max,100,"number")
				Slider.Precise = GetType(Slider.Precise,0,"number")
				Slider.Unit = GetType(Slider.Unit,"","string")
				Slider.Value = GetType(Slider.Value,Slider.Max / 2,"number")
				Slider.Callback = GetType(Slider.Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Slider
				Window.Flags[Slider.Flag] = Slider.Value

				Assets:Slider(SectionContainer,Bracket.ScreenAsset,Window,Slider)
				return Slider
			end
			function Section:Textbox(Textbox)
				Textbox = GetType(Textbox,{},"table",true)
				Textbox.Name = GetType(Textbox.Name,"Textbox","string")
				Textbox.Flag = GetType(Textbox.Flag,Textbox.Name,"string")

				Textbox.Value = GetType(Textbox.Value,"","string")
				Textbox.NumbersOnly = GetType(Textbox.NumbersOnly,false,"boolean")
				Textbox.Placeholder = GetType(Textbox.Placeholder,"Input here","string")
				Textbox.Callback = GetType(Textbox.Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Textbox
				Window.Flags[Textbox.Flag] = Textbox.Value

				Assets:Textbox(SectionContainer,Bracket.ScreenAsset,Window,Textbox)
				return Textbox
			end
			function Section:Keybind(Keybind)
				Keybind = GetType(Keybind,{},"table",true)
				Keybind.Name = GetType(Keybind.Name,"Keybind","string")
				Keybind.Flag = GetType(Keybind.Flag,Keybind.Name,"string")

				Keybind.Value = GetType(Keybind.Value,"NONE","string")
				Keybind.Mouse = GetType(Keybind.Mouse,false,"boolean")
				Keybind.Callback = GetType(Keybind.Callback,function() end,"function")
				Keybind.Blacklist = GetType(Keybind.Blacklist,{"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},"table")
				Window.Elements[#Window.Elements + 1] = Keybind
				Window.Flags[Keybind.Flag] = Keybind.Value

				Assets:Keybind(SectionContainer,Bracket.ScreenAsset,Window,Keybind)
				return Keybind
			end
			function Section:Dropdown(Dropdown)
				Dropdown = GetType(Dropdown,{},"table",true)
				Dropdown.Name = GetType(Dropdown.Name,"Dropdown","string")
				Dropdown.Flag = GetType(Dropdown.Flag,Dropdown.Name,"string")
				Dropdown.List = GetType(Dropdown.List,{},"table")
				Window.Elements[#Window.Elements + 1] = Dropdown
				Window.Flags[Dropdown.Flag] = Dropdown.Value

				Assets:Dropdown(SectionContainer,Bracket.ScreenAsset,Window,Dropdown)
				return Dropdown
			end
			function Section:Colorpicker(Colorpicker)
				Colorpicker = GetType(Colorpicker,{},"table",true)
				Colorpicker.Name = GetType(Colorpicker.Name,"Colorpicker","string")
				Colorpicker.Flag = GetType(Colorpicker.Flag,Colorpicker.Name,"string")

				Colorpicker.Value = GetType(Colorpicker.Value,{1,1,1,0,false},"table")
				Colorpicker.Callback = GetType(Colorpicker.Callback,function() end,"function")
				Window.Elements[#Window.Elements + 1] = Colorpicker
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value

				Assets:Colorpicker(SectionContainer,Bracket.ScreenAsset,Window,Colorpicker)
				return Colorpicker
			end
			return Section
		end
		return Tab
	end
	return Window
end

-- NDHandle = NotificationDescriptionHandle
function Bracket:Notification(Notification)
	Notification = GetType(Notification,{},"table")
	Notification.Title = GetType(Notification.Title,"Title","string")
	Notification.Description = GetType(Notification.Description,"Description","string")

	local NotificationAsset = GetAsset("Notification/ND")
	NotificationAsset.Parent = Bracket.ScreenAsset.NDHandle
	NotificationAsset.Title.Text = Notification.Title
	NotificationAsset.Description.Text = Notification.Description
	NotificationAsset.Title.Size = UDim2.new(1,0,0,NotificationAsset.Title.TextBounds.Y)
	NotificationAsset.Description.Size = UDim2.new(1,0,0,NotificationAsset.Description.TextBounds.Y)

	NotificationAsset.Size = UDim2.fromOffset(
		(NotificationAsset.Title.TextBounds.X > NotificationAsset.Description.TextBounds.X
			and NotificationAsset.Title.TextBounds.X or NotificationAsset.Description.TextBounds.X) + 24,
		NotificationAsset.ListLayout.AbsoluteContentSize.Y + 8
	)

	if Notification.Duration then
		task.spawn(function()
			for Time = Notification.Duration,1,-1 do
				NotificationAsset.Title.Close.Text = Time
				task.wait(1)
			end
			NotificationAsset.Title.Close.Text = 0

			NotificationAsset:Destroy()
			if Notification.Callback then
				Notification.Callback()
			end
		end)
	else
		NotificationAsset.Title.Close.MouseButton1Click:Connect(function()
			NotificationAsset:Destroy()
		end)
	end
end

-- NLHandle = NotificationLineHandle
function Bracket:Notification2(Notification)
	Notification = GetType(Notification,{},"table")
	Notification.Title = GetType(Notification.Title,"Title","string")
	Notification.Duration = GetType(Notification.Duration,5,"number")
	Notification.Color = GetType(Notification.Color,Color3.new(1,0.5,0.25),"Color3")

	local NotificationAsset = GetAsset("Notification/NL")
	NotificationAsset.Parent = Bracket.ScreenAsset.NLHandle
	NotificationAsset.Main.Title.Text = Notification.Title
	NotificationAsset.Main.GLine.BackgroundColor3 = Notification.Color

	NotificationAsset.Main.Size = UDim2.fromOffset(
		NotificationAsset.Main.Title.TextBounds.X + 10,
		NotificationAsset.Main.Title.TextBounds.Y + 6
	)
	NotificationAsset.Size = UDim2.fromOffset(0,
		NotificationAsset.Main.Size.Y.Offset + 4
	)

	local function TweenSize(X,Y,Callback)
		NotificationAsset:TweenSize(
			UDim2.fromOffset(X,Y),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Linear,
			0.25,false,Callback
		)
	end

	TweenSize(NotificationAsset.Main.Size.X.Offset + 4,NotificationAsset.Main.Size.Y.Offset + 4,function()
		task.wait(Notification.Duration) TweenSize(0,NotificationAsset.Main.Size.Y.Offset + 4,function()
			NotificationAsset:Destroy() if Notification.Callback then Notification.Callback() end
		end)
	end)
end

return Bracket
