---@class XUiTheatre4EventConfirm : XUiNode
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4Event
---@field BtnSure XUiComponent.XUiButton
local XUiTheatre4EventConfirm = XClass(XUiNode, "XUiTheatre4EventConfirm")

function XUiTheatre4EventConfirm:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
end

function XUiTheatre4EventConfirm:Refresh(eventId)
    self.EventId = eventId
    -- 描述
    self.TxtContent.text = self._Control:GetEventDesc(eventId)
    -- 确认按钮文本
    local confirmContent = self._Control:GetEventConfirmContent(eventId)
    self.BtnSure:SetNameByGroup(0, confirmContent)
end

function XUiTheatre4EventConfirm:OnBtnSureClick()
    if self.Parent:IsBattleEvent(self.EventId) then
        self.Parent:EnterBattle()
        return
    end
    self.Parent:HandleEvent()
end

return XUiTheatre4EventConfirm
