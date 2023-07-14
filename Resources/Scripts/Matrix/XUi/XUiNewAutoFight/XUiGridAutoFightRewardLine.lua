local XUiGridAutoFightRewardLine = XClass(nil, "XUiGridAutoFightRewardLine")

function XUiGridAutoFightRewardLine:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridReward.gameObject:SetActiveEx(false)
    self.RewardGrids = {}
end

function XUiGridAutoFightRewardLine:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridAutoFightRewardLine:Refresh(sweepRewards, index, isShow)
    self.TxtOrder.text = index < 10 and "0" .. index or index
    local rewardGoodsList = sweepRewards.RewardGoods or {}
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for idx, item in ipairs(rewards) do
        local grid = self.RewardGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            grid.GameObject:SetActiveEx(true)
            self.RewardGrids[idx] = grid
        end
        grid:Refresh(item, nil, nil, true)
    end

    for i = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[i].GameObject:SetActiveEx(false)
    end
    if isShow then
        self:Show()
    end
end

function XUiGridAutoFightRewardLine:Show()
    self.Root.gameObject:SetActiveEx(true)
end

return XUiGridAutoFightRewardLine