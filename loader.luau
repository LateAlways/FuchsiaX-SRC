local placeVersion = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Updated
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LateAlways/FuchsiaX-SRC/refs/heads/main/apiscript/newuilib.lua"))().new(0,0)
local FinishedLoading = false
UI:ShowSplashScreen(function() return FinishedLoading end, true)

if table.find({648362523, 834829150, 1410026010, 987684187, 1426048327, 834827615, 901462028, 694768217}, game.PlaceId) then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/LateAlways/FuchsiaX-SRC/refs/heads/main/games/bp.luau"))(...)
else
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Fuchsia X",Text = "This game is not supported by Fuchsia X", Duration=30})
end

FinishedLoading = true
