-- X-Ro Notification System v3
-- Matches xroui.lua styling with bottom-right corner positioning
-- Created for X-Ro v3

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local XroNotify = {}
XroNotify.Notifications = {}
XroNotify.MaxNotifications = 5
XroNotify.NotificationSpacing = 10
XroNotify.NotificationHeight = 70

-- Create ScreenGui container
local function CreateNotificationContainer()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XroNotifications"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    
    -- Try to parent to CoreGui, fallback to PlayerGui
    local success = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    return screenGui
end

local NotificationContainer = CreateNotificationContainer()

-- Update notification positions
local function UpdateNotificationPositions()
    local yOffset = -10
    
    for i = #XroNotify.Notifications, 1, -1 do
        local notification = XroNotify.Notifications[i]
        if notification and notification.Frame then
            local targetPosition = UDim2.new(1, -310, 1, yOffset - XroNotify.NotificationHeight)
            
            local tween = TweenService:Create(
                notification.Frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = targetPosition}
            )
            tween:Play()
            
            yOffset = yOffset - (XroNotify.NotificationHeight + XroNotify.NotificationSpacing)
        end
    end
end

-- Remove notification
local function RemoveNotification(notification)
    for i, notif in ipairs(XroNotify.Notifications) do
        if notif == notification then
            table.remove(XroNotify.Notifications, i)
            break
        end
    end
    
    if notification.Frame then
        -- Fade out animation
        local tween = TweenService:Create(
            notification.Frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(1, 50, notification.Frame.Position.Y.Scale, notification.Frame.Position.Y.Offset),
                BackgroundTransparency = 1
            }
        )
        
        -- Fade out all children
        for _, child in pairs(notification.Frame:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(
                    child,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {TextTransparency = 1}
                ):Play()
            elseif child:IsA("Frame") or child:IsA("ImageLabel") then
                TweenService:Create(
                    child,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1}
                ):Play()
            end
        end
        
        tween:Play()
        tween.Completed:Connect(function()
            notification.Frame:Destroy()
        end)
    end
    
    UpdateNotificationPositions()
end

-- Create notification
function XroNotify:Notify(options)
    -- Parse options
    local title = options.Title or options.title or "Notification"
    local description = options.Description or options.description or options.Text or options.text or ""
    local duration = options.Duration or options.duration or options.Time or options.time or 3
    local type = options.Type or options.type or "Info"
    
    -- Remove oldest notification if max reached
    if #XroNotify.Notifications >= XroNotify.MaxNotifications then
        RemoveNotification(XroNotify.Notifications[1])
    end
    
    -- Color based on type
    local accentColor = Color3.fromRGB(255, 127, 64) -- X-Ro orange
    if type:lower() == "error" then
        accentColor = Color3.fromRGB(255, 70, 70)
    elseif type:lower() == "success" then
        accentColor = Color3.fromRGB(70, 255, 100)
    elseif type:lower() == "warning" then
        accentColor = Color3.fromRGB(255, 200, 70)
    end
    
    -- Create notification frame
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Notification"
    notifFrame.Size = UDim2.new(0, 300, 0, XroNotify.NotificationHeight)
    notifFrame.Position = UDim2.new(1, 50, 1, -10 - XroNotify.NotificationHeight) -- Start off-screen
    notifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = NotificationContainer
    
    -- Add corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notifFrame
    
    -- Add accent border
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Size = UDim2.new(0, 3, 1, 0)
    border.Position = UDim2.new(0, 0, 0, 0)
    border.BackgroundColor3 = accentColor
    border.BorderSizePixel = 0
    border.Parent = notifFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 6)
    borderCorner.Parent = border
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -50, 0, 20)
    titleLabel.Position = UDim2.new(0, 15, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = notifFrame
    
    -- Add description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -50, 0, 35)
    descLabel.Position = UDim2.new(0, 15, 0, 28)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextWrapped = true
    descLabel.Parent = notifFrame
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "Close"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notifFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Close button hover effect
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(
            closeButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}
        ):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(
            closeButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}
        ):Play()
    end)
    
    -- Progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "Progress"
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = accentColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = notifFrame
    
    -- Create notification object
    local notification = {
        Frame = notifFrame,
        ProgressBar = progressBar,
        StartTime = tick(),
        Duration = duration
    }
    
    table.insert(XroNotify.Notifications, notification)
    
    -- Slide in animation
    local slideIn = TweenService:Create(
        notifFrame,
        TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -310, 1, -10 - XroNotify.NotificationHeight)}
    )
    slideIn:Play()
    
    UpdateNotificationPositions()
    
    -- Progress bar animation
    local progressTween = TweenService:Create(
        progressBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 0, 0, 2)}
    )
    progressTween:Play()
    
    -- Auto remove after duration
    task.delay(duration, function()
        if notification.Frame then
            RemoveNotification(notification)
        end
    end)
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        RemoveNotification(notification)
    end)
    
    return notification
end

-- Alias for compatibility
function XroNotify.new(options)
    return XroNotify:Notify(options)
end

return XroNotify
