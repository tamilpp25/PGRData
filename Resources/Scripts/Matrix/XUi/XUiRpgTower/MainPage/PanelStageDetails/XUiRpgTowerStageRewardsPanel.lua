--兵法蓝图主界面：关卡详细面板
local XUiRpgTowerStageRewardsPanel = XClass(nil, "XUiRpgTowerStageRewardsPanel")
function XUiRpgTowerStageRewardsPanel:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.GridCommon.gameObject:SetActiveEx(false)
    self.RewardsGrid = {}
end
--================
--刷新奖励数据
--================
function XUiRpgTowerStageRewardsPanel:RefreshRewards(rStage)
    local rewardId = rStage:GetStageRewardId()
    local isPass = rStage:GetIsPass()
    if self.ImgEmpty then self.ImgEmpty.gameObject:SetActiveEx(isPass) end
    self:ResetRewards()
    if not isPass then self:ShowRewards(rewardId) end
end
--================
--重置奖励显示
--================
function XUiRpgTowerStageRewardsPanel:ResetRewards()
    for i = 1, #self.RewardsGrid do
        self.RewardsGrid[i].GameObject:SetActiveEx(false)
    end
end
--================
--显示奖励
--================
function XUiRpgTowerStageRewardsPanel:ShowRewards(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            if not self.RewardsGrid[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                self.RewardsGrid[i] = XUiGridCommon.New(self.RootUi, ui)
                self.RewardsGrid[i].Transform:SetParent(self.PanelDropContent, false)
            end
            self.RewardsGrid[i]:Refresh(item)
            self.RewardsGrid[i].GameObject:SetActiveEx(true)
        end
    end
end
return XUiRpgTowerStageRewardsPanel