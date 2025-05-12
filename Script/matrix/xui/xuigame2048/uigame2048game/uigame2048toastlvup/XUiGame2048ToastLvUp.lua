--- Fever等级提升提示横幅
---@class XUiGame2048ToastLvUp: XLuaUi
---@field private _Control XGame2048Control
---@field private _GameControl XGame2048GameControl
local XUiGame2048ToastLvUp = XLuaUiManager.Register(XLuaUi, 'UiGame2048ToastLvUp')

function XUiGame2048ToastLvUp:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self.TxtUp.gameObject:SetActiveEx(false)
    
    local boardId = self._GameControl.TurnControl:GetCurBoardCfgId()

    if XTool.IsNumberValid(boardId) then
        ---@type XTableGame2048Board
        local boardCfg = self._Control:GetGame2048BoardCfgById(boardId)

        if boardCfg and not string.IsNilOrEmpty(boardCfg.Tips) then
            self.TxtUp.gameObject:SetActiveEx(true)
            self.TxtUp.text = boardCfg.Tips
        end
    end
    
    self:StartStayTimer()
end

function XUiGame2048ToastLvUp:OnDestroy()
    self:StopStayTimer()
end

function XUiGame2048ToastLvUp:StopStayTimer()
    if self._StayTimerId then
        XScheduleManager.UnSchedule(self._StayTimerId)
        self._StayTimerId = nil
    end
end

function XUiGame2048ToastLvUp:StartStayTimer()
    self:StopStayTimer()
    
    self._StayTimerId = XScheduleManager.ScheduleOnce(handler(self, self.Close), self._Control:GetClientConfigNum('UiToastLvUpStayTime') * XScheduleManager.SECOND)
end

return XUiGame2048ToastLvUp