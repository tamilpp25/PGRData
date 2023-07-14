local XUiChessPursuitPanelRankRewardGrid = XClass(nil, "XUiChessPursuitPanelRankRewardGrid")

function XUiChessPursuitPanelRankRewardGrid:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridRewardList = {}
    XTool.InitUiObject(self)
    self.GridReward.gameObject:SetActive(false)
end

function XUiChessPursuitPanelRankRewardGrid:Refresh(groupId, mapGroupRewardId)
    local rewardShowId = XChessPursuitConfig.GetMapGroupRewardRewardShowId(mapGroupRewardId)
    local rewardList = XRewardManager.GetRewardList(rewardShowId)
    local myScore = XDataCenter.ChessPursuitManager.GetChessPursuitMyScore()

    for i = 1, #rewardList do
        local grid = self.GridRewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            self.GridRewardList[i] = grid
        end

        grid:Refresh(rewardList[i])
        grid.GameObject:SetActiveEx(true)
    end

    for i = #rewardList + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end

    local startRange = XChessPursuitConfig.GetMapGroupRewardStartRange(mapGroupRewardId)
    local endRange = XChessPursuitConfig.GetMapGroupRewardEndRange(mapGroupRewardId)
    self.TxtScore.text = startRange .. "-" .. endRange

    local isCur = myScore >= startRange and myScore <= endRange
    self.PanelCurRank.gameObject:SetActive(isCur)
end

return XUiChessPursuitPanelRankRewardGrid

