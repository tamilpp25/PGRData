local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridMatchReward = XClass(nil, "XUiGridMatchReward")

function XUiGridMatchReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnFinish.CallBack = function()
        self:OnBtnFinishClick()
    end

end


function XUiGridMatchReward:Refresh(rewardData)
    self.RewardData = rewardData
    local gridType = rewardData.GridType
    local grid = XEliminateGameConfig.GetEliminateGameGridByType(gridType)

    self.TxtName.text = CS.XTextManager.GetText("Eliminate")
    self.ImgIcon:SetSprite(grid.TypePic)
    local isRewarded = XDataCenter.EliminateGameManager.IsRewarded(rewardData.GameId, rewardData.Id)
    local isFinish = XDataCenter.EliminateGameManager.IsRewardFinish(rewardData)
    self.PanelReceiveRewards.gameObject:SetActiveEx(isFinish and not isRewarded)
    self.PanelFinish.gameObject:SetActiveEx(isRewarded)
    self.PanelNor.gameObject:SetActiveEx(not isRewarded and not isFinish)

    if not self.RewarDItem then
        self.RewardItem = XUiGridCommon.New(self.RootUi, self.GridCommon)
    end

    local rewards = XRewardManager.GetRewardList(rewardData.RewardId)
    if not rewards then
        self.GridCommon.gameObject:SetActiveEx(false)
    else
        self.GridCommon.gameObject:SetActiveEx(true)
        self.RewardItem:Refresh(rewards[1])
    end
end

function XUiGridMatchReward:OnBtnFinishClick()
    local isRewarded = XDataCenter.EliminateGameManager.IsRewarded(self.RewardData.GameId, self.RewardData.Id)
    local isFinish = XDataCenter.EliminateGameManager.IsRewardFinish(self.RewardData)
    if isFinish and not isRewarded then
        XDataCenter.EliminateGameManager.RequestEliminateGameGetReward(self.RewardData.GameId, self.RewardData.Id)
    end
end

return XUiGridMatchReward