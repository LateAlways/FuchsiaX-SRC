local Drawing = loadstring(game:HttpGet'https://fuchsiax.latealways.dev/apiscript/drawing.lua')()
local UI = {}
local class = {}

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local CurrentCamera = workspace.CurrentCamera
local TweenService = cloneref(game:GetService("TweenService"))

function newtween(object, tweeninfo, properties, onupdate)
    local tweens = {}
    for key, value in properties do
        if typeof(value) == "Vector2" then
            local receiver = Instance.new("Vector3Value")
            receiver.Value = Vector3.new(object[key].X, object[key].Y, 0)
            receiver:GetPropertyChangedSignal("Value"):Connect(function()
                onupdate(key, Vector2.new(receiver.Value.X, receiver.Value.Y))
            end)
            local tween = TweenService:Create(receiver, tweeninfo, {Value = Vector3.new(value.X, value.Y, 0)})
            tween.Completed:Connect(function() receiver:Destroy() end)
            table.insert(tweens, tween)
        end
    end
    for _,tween in ipairs(tweens) do
        tween:Play() 
    end
end

function UI.new(sizeX, sizeY)
    local self = setmetatable({}, {__index=class})
    
    self.sizeX = sizeX
    self.sizeY = sizeY
    
    
    
    return self
end

function UI.Load(settings) -- Material LUA Support
    local self = setmetatable({}, {__index=class})
    
    self.Title = settings.Title
    self.sizeX = settings.SizeX
    self.sizeY = settings.SizeY
    self.FuchsiaXPink = Color3.fromRGB(255, 25, 255)

    function self.New(settings)
        local sectionTitle = settings.Title

        -- Do section

        -- Banner
        -- Button
            -- SetText(str)
            -- GetText()

        -- Toggle
            -- SetText(str)
            -- GetText()
            -- SetState(bool)
            -- GetState()
        -- Slider
            -- SetText(str)
            -- GetText()
            -- GetValue()
            -- SetMin(num)
            -- SetMax(num)
            -- GetMin()
            -- GetMax()
        -- Dropdown
            -- SetText(str)
            -- GetText()
            -- SetOptions(table)
            -- GetOptions()
        -- ChipSet
            -- SetOptions(table)
            -- GetOptions()
        -- DataTable
            -- SetOptions(table)
            -- GetOptions()
        -- ColorPicker
            -- SetText(str)
            -- GetText()
            -- SetColor(color)
            -- GetColor()
        -- Textfield pasword or not too
            -- SetText(str)
            -- GetText()
    end

    return self
end

function class:ShowSplashScreen(listener, coroutined)
    function data()
        local backdrop = Drawing.new("Square")
        backdrop.Size = Vector2.new(self:GetWindowWidth(), 0)
        backdrop.Position = Vector2.new(0, self:GetWindowHeight()/2-backdrop.Size.Y/2)
        newtween(backdrop, TweenInfo.new(1, Enum.EasingStyle.Quint), {Size = Vector2.new(self:GetWindowWidth(), self:GetWindowHeight()/5), Position = Vector2.new(0, self:GetWindowHeight()/2-self:GetWindowHeight()/5/2)}, function(key, val) backdrop[key] = val backdrop.Visible = true end)
        
        local textX = Drawing.new("Text")
        textX.Center = true
        textX.Text = "X"
        textX.Color = Color3.fromRGB(255, 25, 255)
        textX.Size = 40
        
        local text = Drawing.new("Text")
        text.Center = true
        text.Text = "Fuchsia "
        text.Color = Color3.fromRGB(255,255,255)
        text.Size = 40
        text.Position = Vector2.new(self:GetWindowWidth()/2-textX.TextBounds.X/2, self:GetWindowHeight()/2-text.TextBounds.Y/2)
        textX.Position = Vector2.new(self:GetWindowWidth()/2+text.TextBounds.X/2, self:GetWindowHeight()/2-text.TextBounds.Y/2)
        
        backdrop.Visible = true
        textX.Visible = true
        text.Visible = true
        
        backdrop.Filled = true
        if typeof(listener) == "number" then
            task.wait(seconds)
        elseif typeof(listener) == "function" then
            repeat task.wait() until listener()
        end
        newtween(backdrop, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = Vector2.new(self:GetWindowWidth(), 0), Position = Vector2.new(0, self:GetWindowHeight()/2)}, function(key, value)
            backdrop[key] = value
            backdrop.Visible = true
            textX.Visible = true
            text.Visible = true
        end)
        task.wait(0.7)
        backdrop.Visible = false
        text.Visible = false
        textX.Visible = false

        backdrop:Destroy()
        text:Destroy()
        textX:Destroy()
    end
    
    if coroutined then
        task.spawn(data)
    else
        data()
    end
end

local notification = 0
local notifications = {}
function class:ShowNotification(content, time)
    task.spawn(function()
        local notificationID = notification
        notification += 1
        local offsetX = 250
        table.insert(notifications, notificationID)
        local notification = Drawing.new("Square")
        notification.Size = Vector2.new(200, 100)
        notification.Color = Color3.fromRGB(15,15,15)
        notification.Filled = true
        notification.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X-10+offsetX, self:GetWindowHeight()-notification.Size.Y-10-notificationID*(notification.Size.Y+10))
        local notification2 = Drawing.new("Square")
        notification2.Size = notification.Size-Vector2.new(4,4)
        notification2.Color = Color3.fromRGB(20,20,20)
        notification2.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X-10+2+offsetX, self:GetWindowHeight()-notification.Size.Y-10+2-notificationID*(notification.Size.Y+10))

        local titleText = Drawing.new("Text")
        titleText.Text = "Fuchsia "
        titleText.Size = 20
        titleText.Color = Color3.fromRGB(255,255,255)
        titleText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5-notificationID*(notification.Size.Y+10))

        local xText = Drawing.new("Text")
        xText.Text = "X"
        xText.Size = 20
        xText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+titleText.TextBounds.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5-notificationID*(notification.Size.Y+10))
        xText.Color = Color3.fromRGB(255,25,255)

        local contentText = Drawing.new("Text")
        contentText.Text = content
        contentText.Size = 15
	contentText.Center = false
        contentText.Color = Color3.fromRGB(255,255,255)
        contentText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5+titleText.TextBounds.Y-notificationID*(notification.Size.Y+10))

        local progressBar = Drawing.new("Square")
        progressBar.Size = Vector2.new(notification.Size.X, 1)
        progressBar.Color = Color3.fromRGB(255,25,255)
        progressBar.Filled = true
        progressBar.Position = Vector2.new(self:GetWindowWidth()-10-notification.Size.X+offsetX, self:GetWindowHeight()-10-progressBar.Size.Y-notificationID*(notification.Size.Y+10))

        progressBar.Visible = true
        titleText.Visible = true
        notification2.Visible = true
        notification.Visible = true
        xText.Visible = true
        contentText.Visible = true
        local timeleft = time
        local ended = false
        newtween({Value=Vector2.new(250, 0)}, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Value=Vector2.zero}, function(_, offset)
            offsetX = offset.X
        end)
        repeat
            local e = task.wait()
            if timeleft <= 0 then
                timeleft = 0
            else
                timeleft -= e
            end

            if timeleft <= 0 then
                newtween({Value=Vector2.new(0, 0)}, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {Value=Vector2.new(250,0)}, function(_, offset)
                    offsetX = offset.X

                    progressBar.Size = Vector2.new(notification.Size.X*((timeleft/time)), 1)
                    local id = table.find(notifications, notificationID)-1
                    notification.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X-10+offsetX, self:GetWindowHeight()-notification.Size.Y-10-id*(notification.Size.Y+10))
                    notification2.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X-10+2+offsetX, self:GetWindowHeight()-notification.Size.Y-10+2-id*(notification.Size.Y+10))
                    titleText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5-id*(notification.Size.Y+10))
                    xText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+titleText.TextBounds.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5-id*(notification.Size.Y+10))
                    progressBar.Position = Vector2.new(self:GetWindowWidth()-10-notification.Size.X+offsetX, self:GetWindowHeight()-10-progressBar.Size.Y-id*(notification.Size.Y+10))
                    contentText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5+titleText.TextBounds.Y-id*(notification.Size.Y+10))
                end)
                task.wait(0.35)
                break
            end
            
            progressBar.Size = Vector2.new(notification.Size.X*((timeleft/time)), 1)
            local id = table.find(notifications, notificationID)-1
            notification.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X-10+offsetX, self:GetWindowHeight()-notification.Size.Y-10-id*(notification.Size.Y+10))
            notification2.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X-10+2+offsetX, self:GetWindowHeight()-notification.Size.Y-10+2-id*(notification.Size.Y+10))
            titleText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5-id*(notification.Size.Y+10))
            xText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+titleText.TextBounds.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5-id*(notification.Size.Y+10))
            progressBar.Position = Vector2.new(self:GetWindowWidth()-10-notification.Size.X+offsetX, self:GetWindowHeight()-10-progressBar.Size.Y-id*(notification.Size.Y+10))
            contentText.Position = Vector2.new(self:GetWindowWidth()-notification.Size.X+5+offsetX, self:GetWindowHeight()-notification.Size.Y+5+titleText.TextBounds.Y-id*(notification.Size.Y+10))
        until ended
        notification:Destroy()
        notification2:Destroy()
        titleText:Destroy()
        xText:Destroy()
        progressBar:Destroy()
        contentText:Destroy()
        table.remove(notifications, table.find(notifications, notificationID))
    end)
end

function class:GetWindowWidth()
    return CurrentCamera.ViewportSize.X
end

function class:GetWindowHeight()
    return CurrentCamera.ViewportSize.Y
end

return UI