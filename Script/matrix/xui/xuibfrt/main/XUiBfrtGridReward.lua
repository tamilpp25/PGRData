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
    
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "Effect01")
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "Effect02")
    end
end

function XUiBfrtGridReward:RefreshItem(bfrtRewardId, index, itemId)
    local isRecv = XDataCenter.BfrtManager.CheckCourseRewardIsRecv(bfrtRewardId, index)
    local canRecv = XDataCenter.BfrtManager.CheckCourseRewardCanRecv(bfrtRewardId, index)
    self._RewardGrid:Refresh(itemId)
    local rewardId = XDataCenter.BfrtManager.GetBfrtReward(bfrtRewardId).RewardIds[index]
    if XTool.IsNumberValid(rewardId) then
        local rewardGoodList = XRewardManager.GetRewardList(rewardId)
        for _, rewardGood in ipairs(rewardGoodList) do
            if rewardGood.TemplateId == itemId then
                self.PanelTxt.gameObject:SetActiveEx(true)
                self.TxtCount.text = XUiHelper.GetText("ShopGridCommonCount", rewardGood.Count)
            end
        end
    end
    self.PanelEffect.gameObject:SetActiveEx(canRecv and not isRecv)
    self.PanelFinish.gameObject:SetActiveEx(isRecv)
    self:CloseFlashEffect()
end

function XUiBfrtGridReward:OpenFlashEffect()
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(true)
    end
end

function XUiBfrtGridReward:CloseFlashEffect()
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - BtnListener
function XUiBfrtGridReward:AddBtnListener()
    XUiHelper.RegisterClickEvent(self._RewardGrid, self.BtnClick, self._RewardGrid.OnBtnClickClick)
end
--endregion

return XUiBfrtGridReward