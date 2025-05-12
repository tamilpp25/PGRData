--- 限时玩法暂停界面
---@class XUiPanelBagOrganizeStop: XUiNode
---@field private _Control XBagOrganizeActivityControl
---@field private _GameControl XBagOrganizeActivityGameControl
local XUiPanelBagOrganizeStop = XClass(XUiNode, 'XUiPanelBagOrganizeStop')

function XUiPanelBagOrganizeStop:OnStart()
    self.BtnStart.CallBack = handler(self, self.OnContinueClick)
    self._GameControl = self._Control.GameControl
end

function XUiPanelBagOrganizeStop:OnEnable()
    self.PanelCountdown.gameObject:SetActiveEx(false)
    self._GameControl.TimelimitControl:PauseTimelimit()
end

function XUiPanelBagOrganizeStop:OnDisable()
end

function XUiPanelBagOrganizeStop:OnContinueClick()
    self:Close()
    self._GameControl.TimelimitControl:ResumeTimelimit()
end


return XUiPanelBagOrganizeStop