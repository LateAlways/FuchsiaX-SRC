--!native
local Drawing = setmetatable({
	Fonts = table.freeze({UI=0,
		System=1,
		Plex=2,
		Monospace=3})
}, {__newindex=function(t,i,v) if i == "Fonts" then return error("Fonts is not writable.") else return rawset(t, i, v) end end})

local DrawingContainer = Instance.new("ScreenGui", game:GetService("CoreGui"))
DrawingContainer.IgnoreGuiInset = true
DrawingContainer.DisplayOrder = 999
DrawingContainer.ResetOnSpawn = false
DrawingContainer.Name = "DrawingLib"

local ZIndex = 1000

function Drawing.new(drawingtype: "Line" | "Text" | "Circle" | "Square" | "Triangle" | "Quad")
	if drawingtype == nil then error("Argument \"type\" cannot be nil.") end
	
	local onPropertyChange = function() end
	local thisZIndex = ZIndex
	local self = {}
	
	
	self.Visible = false
	self.Transparency = 0
	self.Color = Color3.fromRGB(0, 0, 0)
	
	if drawingtype == "Line" then
		self.Thickness = 1
		self.From = Vector2.zero
		self.To = Vector2.zero
		
		local Line = Instance.new("Frame")
		Line.Name = "Line"
		Line.AnchorPoint = Vector2.new(0.5, 0.5)
		Line.Size = UDim2.fromScale(0,0)
		Line.BackgroundColor3 = self.Color
		Line.BorderSizePixel = 0
		Line.Visible = false
		Line.Parent = DrawingContainer
		Line.ZIndex = thisZIndex
		
		function self:Remove()
			table.clear(self)
			Line:Destroy()
		end
		
		onPropertyChange = function()
			Line.Visible = self.Visible
			Line.BackgroundTransparency = self.Transparency
			Line.BackgroundColor3 = self.Color
			Line.ZIndex = thisZIndex
			Line.Size = UDim2.new(0, ((self.To.X - self.From.X) ^ 2 + (self.To.Y - self.From.Y) ^ 2) ^ 0.5, 0, self.Thickness) -- Get the size using the distance formula
			Line.Position = UDim2.new(0, (self.From.X + self.To.X) / 2, 0, (self.From.Y + self.To.Y) / 2) -- Get the position using the midpoint formula
			Line.Rotation = math.atan2(self.To.Y - self.From.Y, self.To.X - self.From.X) * (180 / math.pi) -- Get the rotation using atan2, convert radians to degrees
		end
	elseif drawingtype == "Text" then
		local TextBounds = Vector2.zero
		self.TextBounds = nil
		self.Text = ""
		self.Size = 1
		self.Center = false
		self.Outline = false
		self.OutlineColor = Color3.fromRGB(0,0,0)
		self.Position = Vector2.zero
		self.Font = 0
		
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Name = "Text"
		TextLabel.Size = UDim2.fromScale(0,0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.BorderSizePixel = 0
		
		
		TextLabel.Text = self.Text
		TextLabel.TextSize = self.Size
		TextLabel.ZIndex = thisZIndex
		TextLabel.TextXAlignment = if not self.Center then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
		TextLabel.TextYAlignment = if not self.Center then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
		TextLabel.TextStrokeColor3 = self.OutlineColor
		TextLabel.TextStrokeTransparency = if self.Outline then 1 else 1
		TextLabel.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
		TextLabel.TextColor3 = self.Color
		TextLabel.Font = if self.Font == 0 then Enum.Font.Arial else Enum.Font.SourceSans
		
		TextBounds = TextLabel.TextBounds
		
		TextLabel.Visible = false
		TextLabel.Parent = DrawingContainer
		
		function self:Remove()
			table.clear(self)
			TextLabel:Destroy()
		end
		
		onPropertyChange = function()
			TextLabel.Text = self.Text
			TextLabel.TextSize = self.Size
			TextLabel.TextColor3 = self.Color
			TextLabel.TextXAlignment = if not self.Center then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
			TextLabel.TextYAlignment = if not self.Center then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
			TextLabel.TextStrokeColor3 = self.OutlineColor
			TextLabel.TextStrokeTransparency = if self.Outline then 1 else 1
			TextLabel.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
			TextLabel.Font = if self.Font == 0 then Enum.Font.Arial else Enum.Font.SourceSans
			TextLabel.Visible = self.Visible
			TextLabel.ZIndex = thisZIndex
			
			TextBounds = TextLabel.TextBounds
		end

		self.Destroy = self.Remove
		
		return setmetatable({}, {__newindex = function(t, i, v)
			if i == "TextBounds" then
				error("TextBounds is not writable.")
				return
			end
			local r = rawset(self, i, v)
			onPropertyChange()
			return r
		end, __index = function(t, i)
			if i == "TextBounds" then
				return TextBounds
			end
			return rawget(self, i)
		end})
	elseif drawingtype == "Circle" then
		self.Thickness = 1
		self.NumSides = 1
		self.Radius = 1
		self.Filled = false
		self.Position = Vector2.zero
		
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		UICorner.Parent = Frame
		UICorner.Name = "Round"
		UICorner.CornerRadius = UDim.new(0.5, 0)
		Frame.Name = "Circle"
		Frame.AnchorPoint = Vector2.new(0.5,0.5)
		Frame.Size = UDim2.fromOffset(0,0)
		Frame.BackgroundColor3 = self.Color
		Frame.BackgroundTransparency = 0
		Frame.BorderSizePixel = 0
		Frame.Visible = false
		Frame.Parent = DrawingContainer
		Frame.ZIndex = thisZIndex
		
		function self:Remove()
			table.clear(self)
			Frame:Destroy()
			UICorner:Destroy()
		end
		
		onPropertyChange = function()
			Frame.Size = UDim2.fromOffset(self.Radius*2, self.Radius*2)
			Frame.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
			Frame.BackgroundColor3 = self.Color
			Frame.BackgroundTransparency = self.Transparency
			Frame.BorderSizePixel = self.Thickness
			Frame.BorderColor3 = self.Color
			Frame.Visible = self.Visible
			Frame.ZIndex = thisZIndex
		end
	elseif drawingtype == "Square" then
		self.Thickness = 1
		self.Size = Vector2.zero
		self.Position = Vector2.zero
		self.Filled = false
		
		local Square = Instance.new("Frame")
		Square.Name = "Square"
		Square.Size = UDim2.fromScale(0,0)
		Square.BackgroundColor3 = self.Color
		Square.BackgroundTransparency = 0
		Square.BorderSizePixel = 0
		Square.Visible = false
		Square.Parent = DrawingContainer
		Square.ZIndex = thisZIndex
		
		local tltr= Drawing.new("Line")
		tltr.From = self.Position
		tltr.To = self.Position+Vector2.new(self.Size.X, 0)
		tltr.Thickness = self.Thickness
		tltr.Color = self.Color
		local tlbl = Drawing.new("Line")
		tlbl.From = self.Position
		tlbl.To = self.Position+Vector2.new(0, self.Size.Y)
		tlbl.Thickness = self.Thickness
		tlbl.Color = self.Color
		local trbr = Drawing.new("Line")
		trbr.From = self.Position+Vector2.new(self.Size.X, 0)
		trbr.To = self.Position+self.Size
		trbr.Thickness = self.Thickness
		trbr.Color = self.Color
		local blbr = Drawing.new("Line")
		blbr.From = self.Position+Vector2.new(0, self.Size.Y)
		blbr.To = self.Position+self.Size
		blbr.Thickness = self.Thickness
		blbr.Color = self.Color

		
		function self:Remove()
			table.clear(self)
			Square:Destroy()
			tltr:Remove()
			tlbl:Remove()
			trbr:Remove()
			blbr:Remove()
		end
		
		onPropertyChange = function()
			if not self.Filled then
			tltr.From = self.Position
			tltr.To = self.Position+Vector2.new(self.Size.X, 0)
			tltr.Thickness = self.Thickness
			tltr.Color = self.Color
			tltr.Visible = self.Visible
			tltr.Transparency = self.Transparency
			
			tlbl.From = self.Position
			tlbl.To = self.Position+Vector2.new(0, self.Size.Y)
			tlbl.Thickness = self.Thickness
			tlbl.Color = self.Color
			tlbl.Visible = self.Visible
			tlbl.Transparency = self.Transparency
			
			trbr.From = self.Position+Vector2.new(self.Size.X, 0)
			trbr.To = self.Position+self.Size
			trbr.Thickness = self.Thickness
			trbr.Color = self.Color
			trbr.Visible = self.Visible
			trbr.Transparency = self.Transparency
			
			blbr.From = self.Position+Vector2.new(0, self.Size.Y)
			blbr.To = self.Position+self.Size
			blbr.Thickness = self.Thickness
			blbr.Color = self.Color
			blbr.Visible = self.Visible
			blbr.Transparency = self.Transparency
			else
			tltr.Visible = false
			tlbl.Visible = false
			trbr.Visible = false
			blbr.Visible = false
			
			Square.Size = UDim2.fromOffset(self.Size.X, self.Size.Y)
			Square.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
			Square.BackgroundColor3 = self.Color
			Square.BackgroundTransparency = self.Transparency
			Square.BorderSizePixel = self.Thickness
			Square.BorderColor3 = self.Color
			Square.Visible = self.Visible and self.Filled
			Square.ZIndex = thisZIndex
			end
		end
	elseif drawingtype == "Triangle" then
		self.Thickness = 1
		self.PointA = Vector2.zero
		self.PointB = Vector2.zero
		self.PointC = Vector2.zero
		self.Filled = false
		
		local ab = Drawing.new("Line")
		ab.From = self.PointA
		ab.To = self.PointB
		local bc = Drawing.new("Line")
		bc.From = self.PointB
		bc.To = self.PointC
		local ca = Drawing.new("Line")
		ca.From = self.PointC
		ca.To = self.PointA
		
		onPropertyChange = function()
			ab.Thickness = self.Thickness
			bc.Thickness = self.Thickness
			ca.Thickness = self.Thickness
			
			ab.Transparency = self.Transparency
			bc.Transparency = self.Transparency
			ca.Transparency = self.Transparency
			
			ab.Color = self.Color
			bc.Color = self.Color
			ca.Color = self.Color
			
			ab.Visible = self.Visible
			bc.Visible = self.Visible
			ca.Visible = self.Visible
			
			ab.From = self.PointA
			ab.To = self.PointB
			bc.From = self.PointB
			bc.To = self.PointC
			ca.From = self.PointC
			ca.To = self.PointA
		end
		
		function self:Remove()
			table.clear(self)
			ab:Remove()
			bc:Remove()
			ca:Remove()
		end
	elseif drawingtype == "Quad" then
		self.PointA = Vector2.zero
		self.PointB = Vector2.zero
		self.PointC = Vector2.zero
		self.PointD = Vector2.zero
		
		local ab = Drawing.new("Line")
		ab.From = self.PointA
		ab.To = self.PointB
		local bc = Drawing.new("Line")
		bc.From = self.PointB
		bc.To = self.PointC
		local cd = Drawing.new("Line")
		cd.From = self.PointC
		cd.To = self.PointD
		local da = Drawing.new("Line")
		da.From = self.PointD
		da.To = self.PointA
		
		onPropertyChange = function()
			ab.Thickness = self.Thickness
			bc.Thickness = self.Thickness
			cd.Thickness = self.Thickness
			da.Thickness = self.Thickness

			ab.Transparency = self.Transparency
			bc.Transparency = self.Transparency
			cd.Transparency = self.Transparency
			da.Transparency = self.Transparency

			ab.Color = self.Color
			bc.Color = self.Color
			cd.Color = self.Color
			da.Color = self.Color

			ab.Visible = self.Visible
			bc.Visible = self.Visible
			cd.Visible = self.Visible
			da.Visible = self.Visible
			
			da.From = self.PointD
			da.To = self.PointA
			cd.From = self.PointC
			cd.To = self.PointD
			bc.From = self.PointB
			bc.To = self.PointC
			ab.From = self.PointA
			ab.To = self.PointB
		end
		
		function self:Remove()
			table.clear(self)
			ab:Remove()
			bc:Remove()
			cd:Remove()
			da:Remove()
		end
	else
		error("Unknown type")
	end
	
	if not self.Remove then error("Error in module. Type did not declare a :Remove method") end

	thisZIndex = ZIndex
	ZIndex += 1

	self.Destroy = self.Remove

	return setmetatable({}, {
		__index=self,
		__newindex=function(t, i, v)
			local r = rawset(self, i, v)
			onPropertyChange()
			return r
		end,
	})
end

return Drawing