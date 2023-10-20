local XUiCerberusGameDetail = require("XUi/XUiCerberusGame/XUiCerberusGameDetail")
local XUiCerberusGameDetailV2P9 = XLuaUiManager.Register(XUiCerberusGameDetail, "UiCerberusGameDetailV2P9")

function XUiCerberusGameDetailV2P9:RefreshUi()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.XStoryPoint:GetXStage().StageId)
    self.TxtName.text = stageCfg.Name
    self.TxtTitle.text = self.XStoryPoint:GetConfig().Title

    -- 首通奖励
    local rewards = {}
    local rewardId = stageCfg.FirstRewardShow
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end

    if rewards then
        for i, item in pairs(rewards) do
            local grid = self.GridReward[i] 
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.GridCommon.parent)
                grid = XUiGridCommon.New(self, ui)
                self.GridReward[i] = grid
            end
            grid:Refresh(item)
            grid:SetReceived(self.XStoryPoint:GetIsPassed())
            grid.GameObject:SetActive(true)
        end
    end
    self.GridCommon.gameObject:SetActive(false)
end

return XUiCerberusGameDetailV2P9