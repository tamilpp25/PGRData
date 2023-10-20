---@class XUiBfrtGridReward : XUiNode
---@field _Control
local XUiBfrtGridReward = XClass(XUiNode, "XUiBfrtGridReward")

function XUiBfrtGridReward:OnStart()
    self:InitReward()
    self:AddBtnListener()
end

--region Refresh
function XUiBfrtGridReward:InitReward()
    ---@type XUiGridCommon
    self._RewardGrid = XUiGridCommon.New(nil, self.GridCommon)
end

function XUiBfrtGridReward:RefreshItem(bfrtRewardId, index, itemId)
    local isRecv = XDataCenter.BfrtManager.CheckCourseRewardIsRecv(bfrtRewardId, index)
    local canRecv = XDataCenter.BfrtManager.CheckCourseRewardCanRecv(bfrtRewardId, index)
    self._RewardGrid:Refresh(itemId)
    self.PanelEffect.gameObject:SetActiveEx(canRecv and not isRecv)
    self.PanelFinish.gameObject:SetActiveEx(isRecv)
end
--endregion

--region Ui - BtnListener
function XUiBfrtGridReward:AddBtnListener()
    XUiHelper.RegisterClickEvent(self._RewardGrid, self.BtnClick, self._RewardGrid.OnBtnClickClick)
end
--endregion

return XUiBfrtGridReward