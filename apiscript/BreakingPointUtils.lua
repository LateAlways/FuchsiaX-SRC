local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Utilities = {}

function Utilities.GetClosestPlayerToMouse(filterfunc)
    local Closest = {nil, nil}
    local MousePos = Vector2.new(Mouse.X, Mouse.Y)
    for _, Player in Players:GetPlayers() do
        local Character = Player.Character
        if Character and Character.PrimaryPart and (if filterfunc then filterfunc(Player) else true) then
            local Vector, Visible = Camera:WorldToScreenPoint(Character.PrimaryPart.Position)
            if Visible then
                local Distance = (MousePos - Vector2.new(Vector.X, Vector.Y)).Magnitude
                if Closest[1] == nil or Distance < Closest[1] then
                    Closest = {Distance, Player}
                end
            end
        end
    end
    return Closest[2]
end

function Utilities.GetClosestPlayerToCharacter(filterfunc)
    local Closest = {nil, nil}
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return nil end
    for _, Player in Players:GetPlayers() do
        local Character = Player.Character
        if Character and Character.PrimaryPart and (if filterfunc then filterfunc(Player) else true) then
            local Distance = (Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
            if Closest[1] == nil or Distance < Closest[1] then
                Closest = {Distance, Player}
            end
        end
    end
    return Closest[2]
end

function Utilities.GetClosestPartOfAvatar(Character, From)
    local Closest = {nil, nil}
    if not From then return nil end
    for _, part in Character:GetChildren() do
        if part:IsA("Part") and part.Position then
            local Distance = (part.Position - From.Position).Magnitude
            if Closest[1] == nil or Distance < Closest[1] then
                Closest = {Distance, part}
            end
        end
    end
    return Closest[2]
end

function Utilities.GetKnife()
    return (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Blade")) or LocalPlayer.Backpack:FindFirstChild("Blade")
end

function Utilities.PlayerJump()
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character:FindFirstChild("Humanoid") and (LocalPlayer.Character.Humanoid.Jump or LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Jumping or LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then return false end
    LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    return true
end

function Utilities.isMoving()
    return LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude ~= 0
end

return Utilities