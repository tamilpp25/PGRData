
local XUiHitMousePanelRewardGrid = XClass(nil, "XUiHitMousePanelRewardGrid")

local Vector3 = CS.UnityEngine.Vector3
local XIconGrid = require("XUi/XUiHitMouse/Entities/XUiHitMousePanelRewardIcon")

function XUiHitMousePanelRewardGrid:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.Icon = XIconGrid.New(self.GridReward)
end

function XUiHitMousePanelRewardGrid:SetData(index, rewardId, score, maxScore, parentWidth)
    self.Index = index
    self.RewardId = rewardId
    self.Score = score
    self.Transform.localPosition =
    Vector3(
        self.Score / maxScore * parentWidth + self.Transform.localPosition.x,
        self.Transform.localPosition.y,
        self.Transform.localPosition.z
    )
    self:SetScore()
    self:RefreshIcon()
end

function XUiHitMousePanelRewardGrid:SetScore()
    self.TxtScore.text = self.Score
end

function XUiHitMousePanelRewardGrid:RefreshIcon()
    self.Icon:Refresh(self.Index, self.RewardId)
end

function XUiHitMousePanelRewardGrid:Show()
    self.GameObject:SetActiveEx(true)
end

return XUiHitMousePanelRewardGrid