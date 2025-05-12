local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiArenaContributeTipsReward : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtRank UnityEngine.UI.Text
---@field ListReward UnityEngine.RectTransform
---@field GridReward UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field _Control XArenaControl
local XUiArenaContributeTipsReward = XClass(XUiNode, "XUiArenaContributeTipsReward")

-- region 生命周期

function XUiArenaContributeTipsReward:OnStart(regionType)
    self._RegionType = regionType
    ---@type XUiGridCommon[]
    self._RewardGridList = {}

    self:_InitUi()
end

-- endregion

function XUiArenaContributeTipsReward:Refresh(challengeId)
    local regionType = self._RegionType

    self.TxtTitle.text = self._Control:GetRankRegionText(regionType)
    if (not self._Control:CheckCanDownRank(challengeId) and regionType == XEnumConst.Arena.RegionType.Down)
        or (not self._Control:CheckCanUpRank(challengeId) and regionType == XEnumConst.Arena.RegionType.Up) then
        self.TxtRank.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = self._Control:GetRankNotRegionDescText(regionType)
        self:_CloseAllRewardGrid()
    else
        local rewardId = self._Control:GetRankRegionRewardId(regionType, challengeId)
        local rewardList = XTool.IsNumberValid(rewardId) and XRewardManager.GetRewardList(rewardId) or nil

        self.TxtRank.gameObject:SetActiveEx(true)
        self.TxtTips.gameObject:SetActiveEx(false)
        self.TxtRank.text = self._Control:GetRankRegionDescText(regionType, challengeId)
        self:_RefreshRewardGrids(rewardList)
    end
end

-- region 私有方法

function XUiArenaContributeTipsReward:_Init()
    if self._RegionType then
        self.TxtTitle.text = self._Control:GetRankRegionColorText(self._RegionType)
    end
end

function XUiArenaContributeTipsReward:_RefreshRewardGrids(rewardList)
    if not XTool.IsTableEmpty(rewardList) then
        for i, reward in pairs(rewardList) do
            local grid = self._RewardGridList[i]

            if not grid then
                local gridObject = XUiHelper.Instantiate(self.GridReward, self.ListReward)

                grid = XUiGridCommon.New(gridObject)
                grid.RootUi = self.Parent
                self._RewardGridList[i] = grid
            end

            grid.GameObject:SetActiveEx(true)
            grid:Refresh(reward)
        end
        for i = #rewardList + 1, #self._RewardGridList do
            self._RewardGridList[i].GameObject:SetActiveEx(false)
        end
    else
        self:_CloseAllRewardGrid()
    end
end

function XUiArenaContributeTipsReward:_CloseAllRewardGrid()
    for _, grid in pairs(self._RewardGridList) do
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiArenaContributeTipsReward:_InitUi()
    self.GridReward.gameObject:SetActiveEx(false)
end

-- endregion

return XUiArenaContributeTipsReward
