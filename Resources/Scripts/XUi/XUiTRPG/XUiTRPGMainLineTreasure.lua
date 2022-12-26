--区域探索主线奖励界面
local XUiTRPGMainLineTreasure = XClass(nil, "XUiTRPGMainLineTreasure")

function XUiTRPGMainLineTreasure:Ctor(rootUi, chapterId, nodeId, clickCb)
    self.RootUi = rootUi
    self.ChapterId = chapterId
    self.NodeId = nodeId
    self.ClickCb = clickCb
end

function XUiTRPGMainLineTreasure:UpdateBfrtRewards()
    local chapterId = self.Chapter.ChapterId
    local taskId = XDataCenter.BfrtManager.GetBfrtTaskId(chapterId)
    local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(taskId)
    local rewardId = taskConfig.RewardId
    local rewards = XRewardManager.GetRewardList(rewardId)

    self.BfrtRewardGrids = self.BfrtRewardGrids or {}
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.BfrtRewardGrids[i]
        if not grid then
            local go = i == 1 and self.GridCommonPopUp or CS.UnityEngine.Object.Instantiate(self.GridCommonPopUp)
            grid = XUiGridCommon.New(self, go)
            self.BfrtRewardGrids[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.Transform:SetParent(self.PanelBfrtRewrds, false)
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.BfrtRewardGrids do
        self.BfrtRewardGrids[i].GameObject:SetActiveEx(false)
    end
end