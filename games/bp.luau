local FUCHSIAX_PROD = true
local TEST_AUTOMOVE = false

-- Breaking Point
local bpAPI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LateAlways/FuchsiaX-SRC/refs/heads/main/apiscript/bpAPI.lua"))()
local Pathfinder = loadstring(game:HttpGet("https://raw.githubusercontent.com/LateAlways/FuchsiaX-SRC/refs/heads/main/apiscript/simplepath.lua"))()
local BPUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LateAlways/FuchsiaX-SRC/refs/heads/main/apiscript/BreakingPointUtils.lua"))()

if getgenv().fx_settings and getgenv().fx_settings.SaveSettings then
   getgenv().fx_settings.SaveSettings()
end
if getgenv().fx_settings and getgenv().fx_settings.Fullbright and getgenv().fx_settings.Fullbright.Connection and getgenv().fx_settings.Fullbright.Connection.Disconnect then
   getgenv().fx_settings.Fullbright.Connection:Disconnect()
end
if getgenv().fx_settings and getgenv().fx_settings.Connections then
   for _, Connection in getgenv().fx_settings.Connections do
      Connection:Disconnect()
   end
end

local queueteleport = queue_on_teleport or queueonteleport

local AutoThrowKeybind
getgenv().fx_settings = {
   Connections = {},
   Global = {
      StabLegit = true,
      ThrowLegit = true,
      AntiCheapAimbot = false,
      LoadOnTP = true,
   },
   KillAura = {
      Enabled = false,
      Range = 20,
      Toggle = nil,
      Run = nil,
   },
   AlwaysHit = {
      Enabled = false,
      HeadshotChance = 50,
      Toggle = nil,
   },
   Fullbright = {
      Enabled = false,
      Connection = { Disconnect = function() end },
      Toggle = nil,
   },
   AntiAFK = {
      Enabled = false,
      Toggle = nil,
   },
   AutoThrow = {
      Enabled = false,
      HeadshotChance = 50,
      KeybindThrowOnce = "E",
      Toggle = nil,
      Run = nil,
   },
   AutoPlay = {
      Enabled = false,
      HeadshotChance = 50,
      Toggle = nil,
   },
   SaveSettings = function()
      getgenv().fx_settings.AutoThrow.KeybindThrowOnce = AutoThrowKeybind.CurrentKeybind

      local saveable = {}
      for Module, Config in getgenv().fx_settings do
         if Module == "Connections" or Module == "SaveSettings" then continue end
         saveable[Module] = {}
         for Option, Value in Config do
            if Option ~= "Run" and Option ~= "Toggle" and Option ~= "Enabled" and Option ~= "Connection" then
               saveable[Module][Option] = Value
            end
         end
      end

      writefile("FuchsiaX/fx_v3_bp.json", game:GetService("HttpService"):JSONEncode(saveable))
   end
}
local function addConnection(connection)
   table.insert(getgenv().fx_settings.Connections, connection)
end


local function TryLoadingSettings()
   if isfile("FuchsiaX/fx_v3_bp.json") then
      local Decoded = game:GetService("HttpService"):JSONDecode(readfile("FuchsiaX/fx_v3_bp.json"))
      for Module, Config in Decoded do
         if getgenv().fx_settings[Module] then
            for Option, Value in Config do
               if getgenv().fx_settings[Module][Option] ~= nil then
                  getgenv().fx_settings[Module][Option] = Value
               end
            end
         end
      end
   end
end

TryLoadingSettings()

if not queueteleport and getgenv().fx_settings.Global.LoadOnTP then
   getgenv().fx_settings.Global.LoadOnTP = false
   Notification:ShowNotification(
      "Auto-Load on Teleport is\ndisabled because your\nexecutor does not support it.",
      10
   )
   getgenv().fx_settings.SaveSettings()
end

local VirtualUser = cloneref(game:GetService("VirtualUser"))
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Remote = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteKey = "IIlIla"

local LocalPlayer = Players.LocalPlayer
local LocalBackpack = LocalPlayer.Backpack
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalPrimaryPart = LocalCharacter.PrimaryPart

local AgentParameters = { WaypointSpacing = 0.25 }
local Agent = Pathfinder.new(LocalCharacter, AgentParameters)
addConnection(LocalPlayer.CharacterAdded:Connect(function(Character)
   LocalCharacter = Character
   while true do
      task.wait()
      local Success = pcall(function()
         Agent = Pathfinder.new(LocalCharacter, AgentParameters)
      end)
      if Success then
         break
      end
   end
end))

addConnection(LocalPlayer.Idled:Connect(function()
   if getgenv().fx_settings.AntiAFK.Enabled or getgenv().fx_settings.AutoPlay.Enabled then
      VirtualUser:CaptureController()
      VirtualUser:ClickButton2(Vector2.new())
      Notification:ShowNotification("Anti-AFK: Future kick prevented.", 3)
   end
end))

local LocalBlade
getgenv().fx_modules = {
   PredictPosition = function(TargetPart, LocalBlade)
      -- di^2 + (Vp*t)^2 = (Vc*t)^2
      -- di^2 + Vp^2*t^2 = Vc^2*t^2
      -- di^2 = t^2 * (Vc^2-Vp^2)
      -- t = sqrt(di^2/(Vc^2-Vp^2))
      local Distance = (LocalBlade.Handle.Position - TargetPart.Position) -- di
      local PlayerVelocity = TargetPart.AssemblyLinearVelocity -- Vp
      local KnifeSpeed = 4.5 / RunService.Heartbeat:Wait() -- Vc
      local KnifeSpeed2 = KnifeSpeed * KnifeSpeed -- Vc^2
      local TimeToReach2 = Distance
         * Distance
         / (-PlayerVelocity * PlayerVelocity + Vector3.new(KnifeSpeed2, KnifeSpeed2, KnifeSpeed2)) -- t^2
      local TimeToReach =
         Vector3.new(math.sqrt(TimeToReach2.X), math.sqrt(TimeToReach2.Y), math.sqrt(TimeToReach2.Z)) -- t

      local PredictedPositionOffset = PlayerVelocity * (TimeToReach * 0.8)

      local AngleCFrame = CFrame.lookAt(LocalBlade.Handle.Position, TargetPart.Position + PredictedPositionOffset)
      return CFrame.new(TargetPart.Position + PredictedPositionOffset) * (AngleCFrame - AngleCFrame.Position),
         TimeToReach.Magnitude
   end,
}

local TryingToUnequipWhenPossible = false
local function EquipKnife()
   if LocalBackpack:FindFirstChild("Blade") then
      TryingToUnequipWhenPossible = false
      LocalBackpack.Blade.Parent = LocalCharacter
      LocalBlade = LocalCharacter.Blade
   end
end

local AutoThrowing = false
local Stabbing = false
local function isGoodTimeToUnequip()
   return not AutoThrowing and not Stabbing
end

local function UnequipKnife()
   if LocalCharacter:FindFirstChild("Blade") and isGoodTimeToUnequip() then
      LocalCharacter.Blade.Parent = LocalBackpack
   elseif not isGoodTimeToUnequip() and not TryingToUnequipWhenPossible then
      TryingToUnequipWhenPossible = false
      task.wait()
      TryingToUnequipWhenPossible = true
      task.spawn(function()
         repeat
            task.wait()
         until isGoodTimeToUnequip() or not TryingToUnequipWhenPossible
         if TryingToUnequipWhenPossible then
            TryingToUnequipWhenPossible = false
            UnequipKnife()
         end
      end)
   end
end

local PlayersKilling = {}
getgenv().fx_settings.KillAura.Run = function(StabLegit, AntiCheapAimbot)
   if not bpAPI.logicAPI.hasKnife() or bpAPI.logicAPI.isSit() then
      return
   end
   LocalBlade = BPUtils.GetKnife()
   LocalPrimaryPart = LocalCharacter.PrimaryPart
   for _, Player in Players:GetPlayers() do
      local UserId = Player.UserId
      if not Player.Character or Player == LocalPlayer or table.find(PlayersKilling, UserId) then
         continue
      end

      local Character = Player.Character
      local Humanoid = Character and Character:FindFirstChild("Humanoid")
      local PrimaryPart = Character and Character.PrimaryPart
      local Backpack = Player.Backpack

      if not Character or not Humanoid or not PrimaryPart or not Backpack then
         continue
      end

      if
         not PrimaryPart.Anchored
         and bpAPI.logicAPI.getDuo() ~= Player
         and bpAPI.logicAPI.hasKnife(Player)
         and not bpAPI.logicAPI.isSit(Player)
         and bpAPI.logicAPI.isInGlass(PrimaryPart)
      then
         local ClosestPart = BPUtils.GetClosestPartOfAvatar(Character, LocalBlade.Handle)
         if
            (ClosestPart.Position - LocalPrimaryPart.Position).Magnitude <= getgenv().fx_settings.KillAura.Range
         then
            Stabbing = true
            if AntiCheapAimbot then
               EquipKnife()
            end
            table.insert(PlayersKilling, UserId)
            task.spawn(function()
               repeat
                  ClosestPart = BPUtils.GetClosestPartOfAvatar(Character, LocalBlade.Handle)
                  --LocalPrimaryPart.CFrame = CFrame.lookAt(LocalPrimaryPart.Position, Vector3.new(ClosestPart.Position.X, LocalPrimaryPart.Position.Y, ClosestPart.Position.Z))
                  Remote:FireServer(43, ClosestPart, Player, RemoteKey)
                  task.wait()
               until not Player.Character
                  or Player.Character.Parent == Workspace.deadbodies
                  or not bpAPI.logicAPI.hasKnife(Player)
                  or bpAPI.logicAPI.isSit(Player)
                  or not bpAPI.logicAPI.isInGlass(PrimaryPart)
                  or (ClosestPart.Position - LocalPrimaryPart.Position).Magnitude
                     > getgenv().fx_settings.KillAura.Range
               table.remove(PlayersKilling, table.find(PlayersKilling, UserId))
               if
                  StabLegit
                  and (ClosestPart.Position - LocalPrimaryPart.Position).Magnitude < getgenv().fx_settings.KillAura.Range
                  and #PlayersKilling <= 1
               then
                  task.spawn(bpAPI.animationAPI.stab)
               end
               if #PlayersKilling == 0 then
                  Stabbing = false
                  if AntiCheapAimbot then
                     UnequipKnife()
                  end
               end
            end)
         end
      end
   end
end

local function KillAura()
   while getgenv().fx_settings.KillAura.Enabled do
      task.wait()
      if not FUCHSIAX_PROD then
         getgenv().fx_settings.KillAura.Run(
            getgenv().fx_settings.Global.StabLegit,
            getgenv().fx_settings.Global.AntiCheapAimbot
         )
      else
         local Success, Error = pcall(
            getgenv().fx_settings.KillAura.Run,
            getgenv().fx_settings.Global.StabLegit,
            getgenv().fx_settings.Global.AntiCheapAimbot
         )
         if not Success then
            rconsoleprint(table.concat({ "KillAura: ", Error }))
         end
      end
   end
end

getgenv().fx_settings.AutoThrow.Run = function()
   if getgenv().fx_settings.AutoPlay.Enabled then return "Failed to throw.\nAuto-Pilot is enabled." end
   LocalBlade = BPUtils.GetKnife()
   LocalPrimaryPart = LocalCharacter.PrimaryPart
   if not bpAPI.logicAPI.hasKnife() or bpAPI.logicAPI.isSit() then
      return "You don't have a knife\nor are currently sit."
   end
   local ClosestPlayer = BPUtils.GetClosestPlayerToMouse(function(plr)
      return plr ~= LocalPlayer
         and plr.Character
         and plr.Character.Parent ~= Workspace.deadbodies
         and bpAPI.logicAPI.hasKnife(plr)
         and bpAPI.logicAPI.allow(plr)
   end)
   if not ClosestPlayer then
      return "No target player found."
   end
   local Character = ClosestPlayer.Character
   local Humanoid = Character:FindFirstChild("Humanoid")
   local PrimaryPart = Character.PrimaryPart
   local Backpack = ClosestPlayer.Backpack
   LocalPrimaryPart = LocalCharacter.PrimaryPart
   if
      not Character
      or not Humanoid
      or not PrimaryPart
      or not Backpack
      or (not LocalBlade and not getgenv().fx_settings.Global.AntiCheapAimbot)
   then
      return "Failed to throw."
   end

   local TargetPart
   if math.random(0, 100) <= getgenv().fx_settings.AutoThrow.HeadshotChance then
      TargetPart = Character.Head
   else
      TargetPart = Character.PrimaryPart
   end

   AutoThrowing = true
   if getgenv().fx_settings.Global.AntiCheapAimbot then
      EquipKnife()
   end
   if getgenv().fx_settings.Global.ThrowLegit then
      bpAPI.animationAPI.throw()
   end

   LocalBlade = BPUtils.GetKnife()
   local TargetCFrame, TimeToReach = getgenv().fx_modules.PredictPosition(TargetPart, LocalBlade)

   bpAPI.logicAPI.throw(TargetCFrame)
   task.wait(TimeToReach)
   Remote:FireServer(43, TargetPart, ClosestPlayer, RemoteKey, true)

   task.spawn(function()
      AutoThrowing = false
      if getgenv().fx_settings.Global.AntiCheapAimbot then
         UnequipKnife()
      end
   end)
end

local function AutoThrow()
   while getgenv().fx_settings.AutoThrow.Enabled do
      task.wait()
      if not FUCHSIAX_PROD then
         getgenv().fx_settings.AutoThrow.Run()
      else
         local Success, Error = pcall(getgenv().fx_settings.AutoThrow.Run)
         if not Success then
            rconsoleprint(table.concat({ "AutoThrow: ", Error }))
         end
      end
   end
end

local function AlwaysHit()
   local run = function()
      LocalPrimaryPart = LocalCharacter.PrimaryPart
      local ClosestToMouse = BPUtils.GetClosestPlayerToMouse(function(plr)
         return plr ~= LocalPlayer
            and plr.Character
            and plr.Character.Parent ~= Workspace.deadbodies
            and bpAPI.logicAPI.hasKnife(plr)
            and bpAPI.logicAPI.allow(plr)
      end)
      if ClosestToMouse and ClosestToMouse.Character then
         if math.random(0, 100) <= getgenv().fx_settings.AlwaysHit.HeadshotChance then
            Remote:FireServer(43, ClosestToMouse.Character.Head, ClosestToMouse, RemoteKey, true)
         else
            Remote:FireServer(43, ClosestToMouse.Character.PrimaryPart, ClosestToMouse, RemoteKey, true)
         end
      end
   end

   while getgenv().fx_settings.AlwaysHit.Enabled do
      task.wait()
      if not FUCHSIAX_PROD then
         run()
      else
         local Success, Error = pcall(run)
         if not Success then
            rconsoleprint(table.concat({ "AlwaysHit: ", Error }))
         end
      end
   end
end

local function AutoPlay()
   local function ValidatePositions(...)
      for _, pos in { ... } do
         if not bpAPI.logicAPI.isInGlass(pos) then
            return false
         end
      end
      return true
   end

   local function randominvert(num)
      if math.random() < 0.5 then
         return -1*num
      else
         return num
      end
   end

   local function canMove()
      return bpAPI.logicAPI.isInGlass(LocalPrimaryPart)
            and not bpAPI.logicAPI.isSit()
            and bpAPI.logicAPI.hasKnife()
         or TEST_AUTOMOVE
   end

   local function MoveTo(Character, TargetPosition)
      local Humanoid = Character:FindFirstChild("Humanoid")

      if Humanoid and bpAPI.logicAPI.isInGlass(TargetPosition) then
         local Done = false
         local Connection = Humanoid.MoveToFinished:Connect(function()
            Done = true
         end)
         repeat
            Humanoid:MoveTo(TargetPosition)
            task.wait()
         until Done or Humanoid.WalkToPoint ~= TargetPosition
         Connection:Disconnect()
      end
   end

   local function PathfindTo(Character, TargetPosition)
      local Done = false
      local Connections = {}

      Connections[1] = Agent.Reached:Connect(function()
         Done = true
      end)
      Connections[2] = Agent.Error:Connect(function(Error)
         Done = true
         rconsoleprint(Error)
      end)
      Connections[3] = LocalPlayer.CharacterRemoving:Connect(function()
         Done = true
      end)
      local Success = false
      repeat
         pcall(function()
            Success = Agent:Run(TargetPosition)
         end)
         task.wait()
      until Success
      repeat
         task.wait()
      until Done
         or Agent._status == "Idle"
         or not LocalCharacter
         or not LocalPrimaryPart
         or (LocalPrimaryPart.Position - TargetPosition).Magnitude <= 0.5
         or not Agent._agent
         or not getgenv().fx_settings.AutoPlay.Enabled
      if Agent._status ~= "Idle" then
         pcall(Agent.Stop, Agent)
      end
      for _, Connection in Connections do
         Connection:Disconnect()
      end
   end

   local function CreateRandomPositionAroundPlayer()
      local minradius = 8
      local maxradius = 14

      local x = randominvert(math.random(minradius, maxradius))
      local y = randominvert(math.random(minradius, maxradius))

      local targetPos = Vector3.new(x, 0, y)

      local relativePos = LocalPrimaryPart.Position

      if not ValidatePositions(relativePos + targetPos) then
         return CreateRandomPositionAroundPlayer()
      end
      return relativePos + targetPos
   end

   local function randomrange(min, max)
      return math.random() * (max - min) + min
   end

   local Moves = {
      adad = function()
         if not canMove() then
            return
         end
         local radius = 2

         local tPlr = BPUtils.GetClosestPlayerToCharacter(function(plr)
            return plr ~= LocalPlayer
               and plr.Character
               and plr.Character.Parent ~= Workspace.deadbodies
               and bpAPI.logicAPI.hasKnife(plr)
               and bpAPI.logicAPI.allow(plr)
         end)
         if not tPlr and LocalPrimaryPart then
            tPlr = { Character = { PrimaryPart = { Position = CreateRandomPositionAroundPlayer() } } }
         elseif not LocalPrimaryPart then
            return false
         end
         local relativePos = LocalPrimaryPart.Position
         local PlrToLocalPlr = relativePos - tPlr.Character.PrimaryPart.Position
         local Perpendicular = Vector3.new(PlrToLocalPlr.Z, 0, -PlrToLocalPlr.X).Unit

         if
            not ValidatePositions(relativePos + Perpendicular * radius, relativePos - Perpendicular * radius)
         then
            return false
         end

         PathfindTo(LocalCharacter, relativePos + Perpendicular * radius)
         PathfindTo(LocalCharacter, relativePos - Perpendicular * radius)
         PathfindTo(LocalCharacter, relativePos + Perpendicular * radius)
         PathfindTo(LocalCharacter, relativePos - Perpendicular * radius)

         return true
      end,
      walkfakewalk = function()
         if not canMove() then
            return
         end
         local minradius = 12
         local maxradius = 14

         local t = randominvert(randomrange(minradius, maxradius))

         local tPlr = BPUtils.GetClosestPlayerToCharacter(function(plr)
            return plr ~= LocalPlayer
               and plr.Character
               and plr.Character.Parent ~= Workspace.deadbodies
               and bpAPI.logicAPI.hasKnife(plr)
               and bpAPI.logicAPI.allow(plr)
         end)
         if not tPlr and LocalPrimaryPart then
            tPlr = { Character = { PrimaryPart = { Position = CreateRandomPositionAroundPlayer() } } }
         elseif not LocalPrimaryPart then
            return false
         end
         local relativePos = LocalPrimaryPart.Position
         local PlrToLocalPlr = relativePos - tPlr.Character.PrimaryPart.Position
         local Perpendicular = Vector3.new(PlrToLocalPlr.Z, 0, -PlrToLocalPlr.X).Unit

         if
            not ValidatePositions(
               relativePos + Perpendicular * t / 4,
               relativePos,
               relativePos + Perpendicular * t
            )
         then
            return false
         end

         PathfindTo(LocalCharacter, relativePos + Perpendicular * t / 4)
         PathfindTo(LocalCharacter, relativePos)
         PathfindTo(LocalCharacter, relativePos + Perpendicular * t)

         return true
      end,
      walkspinright = function()
         if not canMove() then
            return
         end
         local distance = 8
         local spindistance = 1.1

         local tPlr = BPUtils.GetClosestPlayerToCharacter(function(plr)
            return plr ~= LocalPlayer
               and plr.Character
               and plr.Character.Parent ~= Workspace.deadbodies
               and bpAPI.logicAPI.hasKnife(plr)
               and bpAPI.logicAPI.allow(plr)
         end)
         if not tPlr and LocalPrimaryPart then
            tPlr = { Character = { PrimaryPart = { Position = CreateRandomPositionAroundPlayer() } } }
         elseif not LocalPrimaryPart then
            return false
         end
         local relativePos = LocalPrimaryPart.Position
         local PlrToLocalPlr = relativePos - tPlr.Character.PrimaryPart.Position
         local Perpendicular = Vector3.new(PlrToLocalPlr.Z, 0, -PlrToLocalPlr.X).Unit
         local relativePos2 = relativePos - Perpendicular * 3

         if
            not ValidatePositions(
               relativePos - Perpendicular * 3,
               relativePos2 + Vector3.new(spindistance / 2, 0, -spindistance / 2),
               relativePos2 + Vector3.new(spindistance, 0, 0),
               relativePos2 + Vector3.new(spindistance / 2, 0, spindistance / 2),
               relativePos2 + Vector3.new(0, 0, spindistance),
               relativePos2 + Vector3.new(-spindistance / 2, 0, spindistance / 2),
               relativePos2 + Vector3.new(-spindistance, 0, 0),
               relativePos2 + Vector3.new(-spindistance / 2, 0, -spindistance / 2),
               relativePos2 + Vector3.new(0, 0, -spindistance),
               relativePos2 + Vector3.new(spindistance / 2, 0, 0),
               relativePos - Perpendicular * distance
            )
         then
            return false
         end

         PathfindTo(LocalCharacter, relativePos - Perpendicular * 3)

         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance / 2, 0, -spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance, 0, 0))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance / 2, 0, spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(0, 0, spindistance))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance / 2, 0, spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance, 0, 0))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance / 2, 0, -spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(0, 0, -spindistance))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance / 2, 0, 0))
         PathfindTo(LocalCharacter, relativePos - Perpendicular * distance)

         return true
      end,
      walkspinleft = function()
         if not canMove() then
            return
         end
         local distance = 8
         local spindistance = 1.1

         local tPlr = BPUtils.GetClosestPlayerToCharacter(function(plr)
            return plr ~= LocalPlayer
               and plr.Character
               and plr.Character.Parent ~= Workspace.deadbodies
               and bpAPI.logicAPI.hasKnife(plr)
               and bpAPI.logicAPI.allow(plr)
         end)
         if not tPlr and LocalPrimaryPart then
            tPlr = { Character = { PrimaryPart = { Position = CreateRandomPositionAroundPlayer() } } }
         elseif not LocalPrimaryPart then
            return false
         end
         local relativePos = LocalPrimaryPart.Position
         local PlrToLocalPlr = relativePos - tPlr.Character.PrimaryPart.Position
         local Perpendicular = Vector3.new(PlrToLocalPlr.Z, 0, -PlrToLocalPlr.X).Unit
         local relativePos2 = relativePos + Perpendicular * -3

         if
            not ValidatePositions(
               relativePos2,
               relativePos2 + Vector3.new(spindistance / 2, 0, -spindistance / 2),
               relativePos2 + Vector3.new(spindistance, 0, 0),
               relativePos2 + Vector3.new(spindistance / 2, 0, spindistance / 2),
               relativePos2 + Vector3.new(0, 0, spindistance),
               relativePos2 + Vector3.new(-spindistance / 2, 0, spindistance / 2),
               relativePos2 + Vector3.new(-spindistance, 0, 0),
               relativePos2 + Vector3.new(-spindistance / 2, 0, -spindistance / 2),
               relativePos2 + Vector3.new(0, 0, -spindistance),
               relativePos2 + Vector3.new(spindistance / 2, 0, 0),
               relativePos - Perpendicular * distance
            )
         then
            return false
         end

         PathfindTo(LocalCharacter, relativePos2)

         MoveTo(LocalCharacter, relativePos2 + Vector3.new(0, 0, -spindistance))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance / 2, 0, -spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance, 0, 0))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance / 2, 0, spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(0, 0, spindistance))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance / 2, 0, spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance, 0, 0))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(spindistance / 2, 0, -spindistance / 2))
         MoveTo(LocalCharacter, relativePos2 + Vector3.new(-spindistance / 2, 0, -spindistance / 2))
         PathfindTo(LocalCharacter, relativePos + Perpendicular * distance)
         return true
      end,
      jump = function()
         if not canMove() then
            return
         end
         BPUtils.PlayerJump()

         repeat
            task.wait()
         until LocalCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Landed
            or LocalCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Running
         return true
      end,
      wait = function()
         local minwait = 0.5
         local maxwait = 1
         task.wait(randomrange(minwait, maxwait))
         return true
      end
   }

   local function unstuck()
      if not canMove() then
         return
      end
      local minradius = 8
      local maxradius = 14

      local x = randominvert(math.random(minradius, maxradius))
      local y = randominvert(math.random(minradius, maxradius))

      local targetPos = Vector3.new(x, 0, y)

      local relativePos = LocalPrimaryPart.Position

      if not ValidatePositions(relativePos + targetPos) then
         return false
      end

      PathfindTo(LocalCharacter, relativePos + targetPos)

      return true
   end

   local MovesKeys = {}
   for Move, _ in Moves do
      if Move == "walkspinleft" or Move == "walkspinright" then
         continue
      end
      table.insert(MovesKeys, Move)
   end

   local function Throw(...)
      rconsoleprint(table.concat({ "AutoPlay: ", ... }))
   end

   local function shuffle(t)
      local Shuffled = {}
      for _, Move in MovesKeys do
         local Position = math.random(1, #Shuffled + 1)
         table.insert(Shuffled, Position, Move)
      end
      return Shuffled
   end

   local Tasks = {
      AntiAFK = function() end,
      Movement = function()
         LocalPrimaryPart = LocalCharacter.PrimaryPart
         if not canMove() then
            return
         end
         if not LocalPrimaryPart then
            return
         end
         if table.find(MovesKeys, "walkspinleft") then
            table.remove(MovesKeys, table.find(MovesKeys, "walkspinleft"))
         end
         if table.find(MovesKeys, "walkspinright") then
            table.remove(MovesKeys, table.find(MovesKeys, "walkspinright"))
         end

         if math.random() < 0.5 then
            table.insert(MovesKeys, "walkspinleft")
         else
            table.insert(MovesKeys, "walkspinright")
         end

         local Shuffled
         repeat
            Shuffled = shuffle(MovesKeys)
         until Shuffled[1] ~= "jump" and Shuffled[1] ~= "wait"

         for _, Move in Shuffled do
            local MoveSuccessOrError = Moves[Move]()
            if not MoveSuccessOrError then
               if Move == "walkspinleft" then
                  Moves["walkspinright"]()
               elseif Move == "walkspinright" then
                  Moves["walkspinleft"]()
               else
                  MoveSuccessOrError = false
                  repeat
                     task.wait()
                     MoveSuccessOrError = unstuck()
                  until MoveSuccessOrError == true
               end
            end
         end
      end,
      AutoThrow = function()
         if
            not bpAPI.logicAPI.hasKnife()
            or bpAPI.logicAPI.isSit()
            or bpAPI.logicAPI.hasWon()
            or bpAPI.logicAPI.isThrowing()
            or not bpAPI.logicAPI.isInGlass(LocalPrimaryPart)
         then
            return
         end
         LocalBlade = BPUtils.GetKnife()
         LocalPrimaryPart = LocalCharacter.PrimaryPart
         local ClosestPlayer = BPUtils.GetClosestPlayerToCharacter(function(plr)
            return plr ~= LocalPlayer
               and plr.Character
               and plr.Character.Parent ~= Workspace.deadbodies
               and bpAPI.logicAPI.hasKnife(plr)
               and bpAPI.logicAPI.allow(plr)
         end)
         if not ClosestPlayer then
            return
         end
         local Character = ClosestPlayer.Character
         local Humanoid = Character:FindFirstChild("Humanoid")
         local PrimaryPart = Character.PrimaryPart
         local Backpack = ClosestPlayer.Backpack
         if
            not Character
            or not Humanoid
            or not PrimaryPart
            or not Backpack
            or (not LocalBlade and not getgenv().fx_settings.Global.AntiCheapAimbot)
         then
            return
         end
         local TargetPart

         if math.random(0, 100) <= getgenv().fx_settings.AutoPlay.HeadshotChance then
            TargetPart = Character.Head
         else
            TargetPart = Character.PrimaryPart
         end

         LocalBlade = BPUtils.GetKnife()
         local TargetCFrame, TimeToReach = getgenv().fx_modules.PredictPosition(TargetPart, LocalBlade)

         local RaycastParams = RaycastParams.new()
         RaycastParams.FilterDescendantsInstances = { workspace:FindFirstChild("chairs"), workspace:FindFirstChild("table") }
         RaycastParams.FilterType = Enum.RaycastFilterType.Include

         local RayHit = Workspace:Raycast(
            LocalBlade.Handle.Position,
            TargetCFrame.Position - LocalBlade.Handle.Position,
            RaycastParams
         )
         AutoThrowing = true
         if getgenv().fx_settings.Global.AntiCheapAimbot then
            EquipKnife()
         end

         if getgenv().fx_settings.Global.ThrowLegit then
            task.spawn(bpAPI.animationAPI.throw)
            task.wait(0.25)
         end
         if RayHit then
            BPUtils.PlayerJump()
            task.wait(0.25)
         elseif getgenv().fx_settings.Global.ThrowLegit then
            task.wait(0.25)
         end
         if LocalBlade and LocalBlade:FindFirstChild("Handle") then
            LocalBlade = BPUtils.GetKnife()
            TargetCFrame, TimeToReach = getgenv().fx_modules.PredictPosition(TargetPart, LocalBlade)
            RayHit = Workspace:Raycast(
               LocalBlade.Handle.Position,
               TargetCFrame.Position - LocalBlade.Handle.Position,
               RaycastParams
            )

            if RayHit then
               TargetPart = Character.Head
               LocalBlade = BPUtils.GetKnife()
               TargetCFrame, TimeToReach = getgenv().fx_modules.PredictPosition(TargetPart, LocalBlade)
            end

            bpAPI.logicAPI.throw(TargetCFrame)
            task.wait(TimeToReach)
            Remote:FireServer(43, TargetPart, ClosestPlayer, RemoteKey, true)

            task.spawn(function()
               AutoThrowing = false
               if getgenv().fx_settings.Global.AntiCheapAimbot then
                  UnequipKnife()
               end
            end)
         end
      end,
      KillAura = function()
         getgenv().fx_settings.KillAura.Run(
            getgenv().fx_settings.Global.StabLegit,
            getgenv().fx_settings.Global.AntiCheapAimbot
         )
      end,
   }

   for TaskName, Task in Tasks do
      task.spawn(function()
         local InitialState
         if getgenv().fx_settings[TaskName] then
            InitialState = getgenv().fx_settings[TaskName].Enabled
            getgenv().fx_settings[TaskName].Enabled = false
            if getgenv().fx_settings[TaskName].Toggle then
               getgenv().fx_settings[TaskName].Toggle:Set(false)
            end
         end
         while getgenv().fx_settings.AutoPlay.Enabled do
            task.wait()
            if not FUCHSIAX_PROD then
               Task()
            else
               local Success, Error = pcall(Task)
               if not Success then
                  Throw(Error)
               end
            end
         end
         if InitialState then
            getgenv().fx_settings[TaskName].Enabled = InitialState
            if getgenv().fx_settings[TaskName].Toggle then
               getgenv().fx_settings[TaskName].Toggle:Set(InitialState)
            end
         end
      end)
   end
end

local doFullbright = function()
   if getgenv().fx_settings.Fullbright.Enabled then
      Lighting.Brightness = 2
      Lighting.ClockTime = 14
      Lighting.FogEnd = 100000
      Lighting.GlobalShadows = false
      Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
   end
end

local function RegisterFullbright()
   if getgenv().fx_settings.Fullbright.Connection then
      getgenv().fx_settings.Fullbright.Connection:Disconnect()
   end
   getgenv().fx_settings.Fullbright.Connection = Lighting.Changed:Connect(doFullbright)
   doFullbright()
end

local function UnregisterFullbright()
   if getgenv().fx_settings.Fullbright.Connection then
      getgenv().fx_settings.Fullbright.Connection:Disconnect()
   end
   Lighting.Brightness = 0
   Lighting.ClockTime = 1
   Lighting.FogEnd = 150
   Lighting.GlobalShadows = false
   Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Fuchsia X v3 - Breaking Point",
   LoadingTitle = "Loading Fuchsia X v3...",
   Theme = "Amethyst",
   ConfigurationSaving = {
      Enabled = false
   },
})


local CombatTab = Window:CreateTab("Combat", 0)
CombatTab:CreateSection("Combat Features")

getgenv().fx_settings.KillAura.Toggle = CombatTab:CreateToggle({
   Name = "Kill Aura",
   CurrentValue = getgenv().fx_settings.KillAura.Enabled,
   Callback = function(Value)
      if not getgenv().fx_settings.AutoPlay.Enabled then
         getgenv().fx_settings.KillAura.Enabled = Value
         if Value then
            KillAura()
         end
      elseif Value then
         getgenv().fx_settings.KillAura.Toggle:Set(false)
         Notification:ShowNotification("Kill Aura cannot be enabled\nwhile Auto-Pilot is enabled.", 3)
      end
   end,
})

getgenv().fx_settings.AlwaysHit.Toggle = CombatTab:CreateToggle({
   Name = "Always Hit \226\154\160",
   CurrentValue = getgenv().fx_settings.AlwaysHit.Enabled,
   Callback = function(Value)
      getgenv().fx_settings.AlwaysHit.Enabled = Value
      if Value then
            AlwaysHit()
      end
   end,
})

CombatTab:CreateSlider({
   Name = "Always-Hit Headshot Chance",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = getgenv().fx_settings.AlwaysHit.HeadshotChance,
   Callback = function(Value)
      getgenv().fx_settings.AlwaysHit.HeadshotChance = Value
   end,
})


local ClientTab = Window:CreateTab("Client", 0)
ClientTab:CreateSection("Client Features")

getgenv().fx_settings.Fullbright.Toggle = ClientTab:CreateToggle({
   Name = "Fullbright",
   CurrentValue = getgenv().fx_settings.Fullbright.Enabled,
   Callback = function(Value)
      getgenv().fx_settings.Fullbright.Enabled = Value
      if Value then
            RegisterFullbright()
      else
            UnregisterFullbright()
      end
   end,
})

getgenv().fx_settings.AntiAFK.Toggle = ClientTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = getgenv().fx_settings.AntiAFK.Enabled,
   Callback = function(Value)
      if getgenv().fx_settings.AutoPlay.Enabled then
         if not Value then
            return
         end
         getgenv().fx_settings.AntiAFK.Enabled = false
         getgenv().fx_settings.AntiAFK.Toggle:Set(false)
         Notification:ShowNotification("Anti-AFK cannot be enabled\nwhile Auto-Pilot is enabled.", 3)
      else
         getgenv().fx_settings.AntiAFK.Enabled = Value
      end
   end,
})


local AutoThrowTab = Window:CreateTab("Auto-Throw", 0)
AutoThrowTab:CreateSection("Auto-Throw Features")

getgenv().fx_settings.AutoThrow.Toggle = AutoThrowTab:CreateToggle({
   Name = "Auto-Throw",
   CurrentValue = getgenv().fx_settings.AutoThrow.Enabled,
   Callback = function(Value)
      if not getgenv().fx_settings.AutoPlay.Enabled then
         getgenv().fx_settings.AutoThrow.Enabled = Value
         if Value then
            AutoThrow()
         end
      elseif Value then
         getgenv().fx_settings.AutoThrow.Toggle:Set(false)
         Notification:ShowNotification("Auto-Throw cannot be\nenabled while\nAuto-Pilot is enabled.", 3)
      end
   end,
})

AutoThrowKeybind = AutoThrowTab:CreateKeybind({
   Name = "Throw Once",
   CurrentKeybind = getgenv().fx_settings.AutoThrow.KeybindThrowOnce,
   Callback = function()
      local result = getgenv().fx_settings.AutoThrow.Run()
      getgenv().fx_settings.AutoThrow.KeybindThrowOnce = AutoThrowKeybind.CurrentKeybind
      if result then
         Notification:ShowNotification(result, 3)
      end
   end,
})

AutoThrowTab:CreateSlider({
   Name = "Auto-Throw Headshot Chance",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = getgenv().fx_settings.AutoThrow.HeadshotChance,
   Callback = function(Value)
      getgenv().fx_settings.AutoThrow.HeadshotChance = Value
   end,
})


local AutoPilotTab = Window:CreateTab("Auto-Pilot", 0)
AutoPilotTab:CreateSection("Auto-Pilot Features")

getgenv().fx_settings.AutoPlay.Toggle = AutoPilotTab:CreateToggle({
   Name = "Auto-Pilot",
   CurrentValue = getgenv().fx_settings.AutoPlay.Enabled,
   Callback = function(Value)
      getgenv().fx_settings.AutoPlay.Enabled = Value
      if Value then
            AutoPlay()
      end
   end,
})

AutoPilotTab:CreateSlider({
   Name = "Auto-Pilot Headshot Chance",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = getgenv().fx_settings.AutoPlay.HeadshotChance,
   Callback = function(Value)
      getgenv().fx_settings.AutoPlay.HeadshotChance = Value
   end,
})


local SettingsTab = Window:CreateTab("Settings", 0)
SettingsTab:CreateButton({
   Name = "Save Settings",
   Callback = function()
      getgenv().fx_settings.SaveSettings()
      Notification:ShowNotification("Settings saved successfully.", 1)
   end,
})

SettingsTab:CreateSection("Configuration")
SettingsTab:CreateToggle({
   Name = "Stab Legit",
   CurrentValue = getgenv().fx_settings.Global.StabLegit,
   Callback = function(Value)
      getgenv().fx_settings.Global.StabLegit = Value
   end,
})

SettingsTab:CreateToggle({
   Name = "Throw Legit",
   CurrentValue = getgenv().fx_settings.Global.ThrowLegit,
   Callback = function(Value)
      getgenv().fx_settings.Global.ThrowLegit = Value
   end,
})

SettingsTab:CreateToggle({
   Name = "Anti Cheap Aimbot",
   CurrentValue = getgenv().fx_settings.Global.AntiCheapAimbot,
   Callback = function(Value)
      getgenv().fx_settings.Global.AntiCheapAimbot = Value
   end,
})

if queueteleport then
   SettingsTab:CreateToggle({
      Name = "Load on Teleport",
      CurrentValue = getgenv().fx_settings.Global.LoadOnTP,
      Callback = function(Value)
            getgenv().fx_settings.Global.LoadOnTP = Value
      end,
   })
end

local TeleportCheck = false
LocalPlayer.OnTeleport:Connect(function(State)
   if getgenv().fx_settings.Global.LoadOnTP and not TeleportCheck and queueteleport then
      TeleportCheck = true
      queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/LateAlways/FuchsiaX-SRC/refs/heads/main/loader.luau'))()")
   end
end)

Notification:ShowNotification("Loaded successfully.", 5)
