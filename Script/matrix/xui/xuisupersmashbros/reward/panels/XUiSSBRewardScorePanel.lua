
local XUiSSBRewardScorePanel = XClass(nil, "XUiSSBRewardScorePanel")
local ScoreItemScript = require("XUi/XUiSuperSmashBros/Reward/Grids/XUiSSBRewardScoreGrid")
function XUiSSBRewardScorePanel:Ctor(content, grid)
    self.Content = content
    self.Grid = grid
    self.ScoreItems = {}
    self.Grid.gameObject:SetActiveEx(false)
end

function XUiSSBRewardScorePanel:Refresh(modeId, rootUi)
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
    if not mode then return end
    local allReward = mode:GetAllRewardCfgs()
    for level, rewardCfg in pairs(allReward or {}) do
        local scoreItem = self:GetScoreItem(level)
        scoreItem.GameObject:SetActiveEx(false)
        scoreItem:Refresh(rewardCfg, rootUi)
    end
    for index = #allReward + 1, #self.ScoreItems do
        self.ScoreItems[index].GameObject:SetActiveEx(false)
    end
end

function XUiSSBRewardScorePanel:GetScoreItem(level)
    if not self.ScoreItems[level] then
        local prefab = CS.UnityEngine.Object.Instantiate(self.Grid, self.Content)
        local item = ScoreItemScript.New(prefab)
        self.ScoreItems[level] = item
    end
    return self.ScoreItems[level]
end

return XUiSSBRewardScorePanel