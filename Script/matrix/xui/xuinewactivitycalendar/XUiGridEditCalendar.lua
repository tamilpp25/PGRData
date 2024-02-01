local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")

---@class XUiGridEditCalendar : XUiMainPanelBase
---@field _Control XNewActivityCalendarControl
---@field BtnUp XUiComponent.XUiButton
---@field TogHell UnityEngine.UI.Toggle
local XUiGridEditCalendar = XClass(XUiMainPanelBase, "XUiGridEditCalendar")

function XUiGridEditCalendar:OnStart(upCallBack, showCallBack)
    self.UpCallBack = upCallBack
    self.ShowCallBack = showCallBack
    XUiHelper.RegisterClickEvent(self, self.BtnUp, self.OnBtnUpClick)
    XUiHelper.RegisterClickEvent(self, self.TogHell, self.OnTogHellClick)

    self:InitTheme()
end

function XUiGridEditCalendar:Refresh(mainId, index, isShow)
    self.MainId = mainId
    self.Index = index
    self.IsShow = isShow
    -- 活动名
    self.TxtWord.text = self._Control:GetCalendarWeekName(mainId)
    -- 刷新按钮状态
    self:RefreshBtnStatus()
end

function XUiGridEditCalendar:RefreshBtnStatus()
    local isShowUp = self.Index > 1 and self.IsShow
    self.BtnUp:SetButtonState(isShowUp and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.TogHell.isOn = self.IsShow
end

function XUiGridEditCalendar:OnBtnUpClick()
    if self.Index <= 1 or not self.IsShow then
        return
    end
    if self.UpCallBack then
        self.UpCallBack(self.Index)
    end
end

function XUiGridEditCalendar:OnTogHellClick()
    local curIsShow = self.TogHell.isOn
    if curIsShow ~= self.IsShow and self.ShowCallBack then
        self.ShowCallBack(self.Index, curIsShow)
    end
end

return XUiGridEditCalendar