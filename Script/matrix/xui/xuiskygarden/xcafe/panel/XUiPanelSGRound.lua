---@class XUiPanelSGRound : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiSkyGardenCafeGame
local XUiPanelSGRound = XClass(XUiNode, "XUiPanelSGRound")

function XUiPanelSGRound:OnStart(total)
    self._TotalRound = total
    self._CurRound = self._Control:GetBattle():GetBattleInfo():GetRound()
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGRound:Refresh(curRound)
    if self._CurRound == curRound then
        self.ImgBgBar.fillAmount = curRound / self._TotalRound
        self:StopTimer()
        return
    end
    self:StopTimer()
    
    local cur = self._CurRound
    self.Timer = self:Tween(0.5, function(dt)
        self.ImgBgBar.fillAmount = ((curRound - cur) * dt + cur) / self._TotalRound
    end, function() 
        self._CurRound = curRound
    end)
end

function XUiPanelSGRound:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = false
end

function XUiPanelSGRound:InitUi()
    local total = self._TotalRound
    for i = 1, total do
        local ui = i == 1 and self.GridRound or XUiHelper.Instantiate(self.GridRound, self.ListTimeRound)
        ---@type UiObject
        local uiObject = ui.transform:GetComponent("UiObject")
        uiObject:GetObject("TxtTime1").text = string.format(self._Control:GetRoundText(), i)
        uiObject:GetObject("ImgZs01").gameObject:SetActiveEx(i ~= total)
    end
    self.ImgBgBar.fillAmount = self._Control:GetBattle():GetBattleInfo():GetRound() / self._TotalRound
end

function XUiPanelSGRound:InitCb()
end

return XUiPanelSGRound