---@class XUiTheatre3PreviewGridReward : XUiNode
---@field _Control XTheatre3Control
local XUiTheatre3PreviewGridReward = XClass(XUiNode, "XUiTheatre3PreviewGridReward")

function XUiTheatre3PreviewGridReward:OnStart()
    
end

function XUiTheatre3PreviewGridReward:Refresh(rewardId, needCount)
    self._RewardId = rewardId
    self.TxtNum.text = needCount
    local rewardItems = XRewardManager.GetRewardList(self._RewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    local gridCommon = XUiGridCommon.New(self.RootUi, self.GridReward)
    gridCommon:Refresh(rewardGoodsList[1])
    if gridCommon.BtnClick then
        XUiHelper.RegisterClickEvent(gridCommon, gridCommon.BtnClick, function ()
            self:OnClickReward()
        end)
    end
end

--region Ui - BtnListener
function XUiTheatre3PreviewGridReward:OnClickReward()
    if not XTool.IsNumberValid(self._RewardId) then
        return
    end
    local rewardList = XRewardManager.GetRewardList(self._RewardId)
    XLuaUiManager.Open("UiTheatre3Tips", rewardList[1].TemplateId)
end
--endregion

return XUiTheatre3PreviewGridReward