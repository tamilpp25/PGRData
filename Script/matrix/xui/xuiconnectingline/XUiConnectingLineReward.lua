---@field private _Control XConnectingLineControl
---@class XUiConnectingLineReward:XLuaUi
local XUiConnectingLineReward = XLuaUiManager.Register(XLuaUi, "UiConnectingLineReward")

function XUiConnectingLineReward:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnClickClose)
end

function XUiConnectingLineReward:OnStart()
    local uiData = self._Control:GetUiDataReward()
    local textArray = uiData.TextArray
    self.Text2.text = textArray[1] or ""
    self.Text3.text = textArray[2] or ""
end

function XUiConnectingLineReward:OnClickClose()
    self._Control:RequestReward()
    self:Close()
end

return XUiConnectingLineReward
