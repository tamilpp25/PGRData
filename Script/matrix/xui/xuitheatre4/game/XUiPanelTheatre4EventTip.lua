-- 事件弹框
---@class XUiPanelTheatre4EventTip : XUiNode
---@field private _Control XTheatre4Control
local XUiPanelTheatre4EventTip = XClass(XUiNode, "XUiPanelTheatre4EventTip")

function XUiPanelTheatre4EventTip:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnHide, self.OnBtnHideClick)
    self._Control:RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

---@param fate XTheatre4Fate
function XUiPanelTheatre4EventTip:Refresh(fate)
    self.FateUid = fate:GetFateEventId()
    
    local eventId = fate:GetEventId()
    self.EventId = eventId
    -- 事件图片
    local eventIcon = self._Control:GetEventIcon(eventId)
    if eventIcon then
        self.ImgEvent:SetSprite(eventIcon)
    end
    -- 未翻开事件描述
    local timeLeft = fate:GetEventTimeLeft()
    local strTimeLeft = XUiHelper.GetText("Theatre4EventRemainTime", timeLeft)
    self.TextTargetDesc.text = self._Control:GetEventUnOpenDesc(eventId) .. strTimeLeft
end

function XUiPanelTheatre4EventTip:OnBtnHideClick()
    -- TODO 隐藏事件弹框 播放动画
end

function XUiPanelTheatre4EventTip:OnBtnClick()
    self._Control:OpenEventUi(self.EventId, nil, nil, self.FateUid, function()
        self:Close()
        self._Control:CheckNeedOpenNextPopup()
    end)
end

return XUiPanelTheatre4EventTip
