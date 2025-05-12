---@class XUiGridWheelchairManualMainTab: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelchairManualMainTab = XClass(XUiNode, 'XUiGridWheelchairManualMainTab')

function XUiGridWheelchairManualMainTab:OnStart(tabId)
    self.TabId = tabId
    self.GridBtn:SetNameByGroup(0, self._Control:GetManualTabMainTitle(self.TabId))
    
    -- 设置副标题文本
    local secondTitleContent = self._Control:GetManualTabSecondTitle(self.TabId)
    self.GridBtn:SetNameByGroup(1, secondTitleContent)
    self.StateControl:ChangeState(string.IsNilOrEmpty(secondTitleContent) and 'HideSecondTitle' or 'ShowSecondTitle')
    
    self.GridBtn:SetRawImage(self._Control:GetManualTabImage(self.TabId))
    self.TabType = XMVCA.XWheelchairManual:GetManualTabTypeAndPanelUrl(self.TabId)
    
    self.ReddotEvent = self:AddRedPointEvent(self, self.OnReddotEvent, self, { XMVCA.XWheelchairManual:GetRedPointConditionTypeByTabType(self.TabType) })
end

function XUiGridWheelchairManualMainTab:OnClickEvent()
    self:RefreshReddot()
end

function XUiGridWheelchairManualMainTab:OnReddotEvent(count)
    self.GridBtn:ShowReddot(count >= 0)
end

function XUiGridWheelchairManualMainTab:SetSecondTitle(content)
    self.StateControl:ChangeState(string.IsNilOrEmpty(content) and 'HideSecondTitle' or 'ShowSecondTitle')
    self.GridBtn:SetNameByGroup(1, content)
end

---@param state UiButtonState
function XUiGridWheelchairManualMainTab:SetButtonState(state)
    self.GridBtn:SetButtonState(state)
end

function XUiGridWheelchairManualMainTab:RefreshReddot()
    XRedPointManager.Check(self.ReddotEvent)
end

return XUiGridWheelchairManualMainTab