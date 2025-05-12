--- 控制武器、角色详情跳转、是否已领取等显示
---@class XUiGridWheelchairManualStepRewardGet: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelchairManualStepRewardGet = XClass(XUiNode, 'XUiGridWheelchairManualStepRewardGet')


function XUiGridWheelchairManualStepRewardGet:OnStart(skipUiName, templateId, content, planId, planIndex)
    self._SkipUiName = skipUiName
    self._TemplateId = templateId
    self.GridBtn.CallBack = handler(self, self.OnBtnClickEvent)
    self:Refresh(content, planId, planIndex) 
end

function XUiGridWheelchairManualStepRewardGet:Refresh(content, planId, planIndex)
    self._PlanId = planId
    self._PlanIndex = planIndex
    self.GridBtn:SetNameByGroup(0, content)
    self.GridBtn:SetNameByGroup(1, XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanTitle'), self._PlanIndex))
    self:RefreshState()
end

function XUiGridWheelchairManualStepRewardGet:RefreshState()
    local isGetReward = self._Control:CheckPlanIsGetReward(self._PlanId)
    self.TagOn.gameObject:SetActiveEx(not isGetReward)
    self.TagOff.gameObject:SetActiveEx(isGetReward)
end

function XUiGridWheelchairManualStepRewardGet:OnBtnClickEvent()
    XLuaUiManager.Open(self._SkipUiName, self._TemplateId)
end

return XUiGridWheelchairManualStepRewardGet