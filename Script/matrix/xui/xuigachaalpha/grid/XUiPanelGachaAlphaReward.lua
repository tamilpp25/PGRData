local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelGachaAlphaReward : XUiNode
---@field Parent XUiGachaAlphaLog
local XUiPanelGachaAlphaReward = XClass(XUiNode, "XUiPanelGachaAlphaReward")

function XUiPanelGachaAlphaReward:RefreshUiShow(gachaConfig)
    if self._GachaConfig then
        return
    end

    self._GachaConfig = gachaConfig
    local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareLevel(gachaConfig.Id)
    -- 生成奖励格子
    for i, group in pairs(rewardRareLevelList) do
        local parent = self["PanelItem" .. i]
        for _, v in pairs(group) do
            local go = CS.UnityEngine.Object.Instantiate(self.GridItem, parent)
            go.gameObject:SetActiveEx(true)
            ---@type XUiGridCommon
            local item = XUiGridCommon.New(self.Parent, go)
            local fashionId = tonumber(XGachaConfigs.GetClientConfig("WeaponFashionId", self._GachaConfig.CourseRewardId))
            item:SetCustomWeaopnFashionId(fashionId, XUiHelper.GetText("GachaAlphaFashionDesc"))
            item:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                XLuaUiManager.Open("UiGachaAlphaTip", data, hideSkipBtn, rootUiName, lackNum)
            end)

            local tmpData = {}
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count

            local curCount
            if v.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
        end
    end
end

return XUiPanelGachaAlphaReward