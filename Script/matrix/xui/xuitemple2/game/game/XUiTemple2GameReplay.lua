local XUiTemple2Game = require("XUi/XUiTemple2/Game/Game/XUiTemple2Game")

---@class XUiTemple2GameReplay : XLuaUi
---@field _Control XTemple2GameControl
local XUiTemple2GameReplay = XLuaUiManager.Register(XUiTemple2Game, "UiTemple2GameReplay")

function XUiTemple2GameReplay:OnStart(...)
    XUiTemple2Game.OnStart(self, ...)
    self:OnClickStart()
    self.PanelLandBag.gameObject:SetActiveEx(false)
end

function XUiTemple2GameReplay:UpdateGame()
    self._Control:GetGameControl():UpdateGameReplay(self._CheckBoard)
end

return XUiTemple2GameReplay