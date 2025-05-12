local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelRepeatChallengeShowGoods
---@field Parent XUiFubenRepeatChallenge
local XUiPanelRepeatChallengeShowGoods = XClass(XUiNode, 'XUiPanelRepeatChallengeShowGoods')

function XUiPanelRepeatChallengeShowGoods:OnStart()
    self:InitShowGoods()
end

function XUiPanelRepeatChallengeShowGoods:OnEnable()
    --self:PlayAnimation('PanelRewardEnable')
end

function XUiPanelRepeatChallengeShowGoods:InitShowGoods()
    self.GridReward.gameObject:SetActiveEx(false)
    --通用处理
    local activityRewardId = XDataCenter.FubenRepeatChallengeManager.GetShowRewardId()

    if XTool.IsNumberValid(activityRewardId) then
        local showItems = XRewardManager.GetRewardListNotCount(activityRewardId)
        XUiHelper.RefreshCustomizedList(self.GridReward.transform.parent, self.GridReward, showItems and #showItems or 0, function(index, obj)
            local gridCommont = XUiGridCommon.New(nil, obj)
            gridCommont:Refresh(showItems[index])
        end)
    end
end

return XUiPanelRepeatChallengeShowGoods