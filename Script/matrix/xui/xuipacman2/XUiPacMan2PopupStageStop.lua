---@class XUiPacMan2PopupStageStop : XLuaUi
---@field _Control XPacMan2Control
local XUiPacMan2PopupStageStop = XLuaUiManager.Register(XLuaUi, "UiPacMan2PopupStageStop")

function XUiPacMan2PopupStageStop:OnStart(stageId, resume)
    self._Resume = resume
    if not resume then
        XLog.Error("[XUiPacMan2PopupStageStop] 需要恢复游戏的callback")
    end
    self._StageId = stageId
end

function XUiPacMan2PopupStageStop:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.Resume)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.LeaveGame)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.Again)
end

function XUiPacMan2PopupStageStop:Resume()
    self:Close()
    if self._Resume then
        self._Resume()
    end
end

function XUiPacMan2PopupStageStop:LeaveGame()
    self:Close()
    XLuaUiManager.Close("UiPacMan2Game")
end

function XUiPacMan2PopupStageStop:Again()
    if self._StageId then
        self:Close()
        XLuaUiManager.Remove("UiPacMan2Game")
        XScheduleManager.ScheduleNextFrame(function()
            XLuaUiManager.Open("UiPacMan2Game", self._StageId)
        end)
    end
end

return XUiPacMan2PopupStageStop