local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelGachaAlphaDetail : XUiNode
---@field Parent XUiGachaAlphaLog
local XUiPanelGachaAlphaDetail = XClass(XUiNode, "XUiPanelGachaAlphaDetail")

function XUiPanelGachaAlphaDetail:RefreshUiShow(gachaConfig)
    if self._GachaConfig then
        return
    end
    self._GachaConfig = gachaConfig

    local list = XDataCenter.GachaManager.GetGachaProbShowById(gachaConfig.Id)
    for _, v in ipairs(list) do
        local tempTrans = v.IsRare and self.RewardSp or self.RewardNor
        local go = CS.UnityEngine.Object.Instantiate(tempTrans, tempTrans.parent)
        go.gameObject:SetActiveEx(true)
        local gridReward = {}
        gridReward.Transform = go
        XTool.InitUiObject(gridReward)
        ---@type XUiGridCommon
        local gridIcon = XUiGridCommon.New(self.Parent, gridReward.GridCostItem)
        gridIcon:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
            XLuaUiManager.Open("UiGachaAlphaTip", data, hideSkipBtn, rootUiName, lackNum)
        end)
        local fashionId = tonumber(XGachaConfigs.GetClientConfig("WeaponFashionId", self._GachaConfig.CourseRewardId))
        gridIcon:SetCustomWeaopnFashionId(fashionId, XUiHelper.GetText("GachaAlphaFashionDesc"))
        gridIcon:Refresh({ TemplateId = v.TemplateId })

        for _, probability in ipairs(v.ProbShow) do
            local probGo = CS.UnityEngine.Object.Instantiate(gridReward.RewardProb, gridReward.RewardProb.transform.parent)
            probGo.gameObject:SetActiveEx(true)
            local gridProb = {}
            gridProb.Transform = probGo
            XTool.InitUiObject(gridProb)
            gridProb.TxtCount.text = probability
        end
    end
end

return XUiPanelGachaAlphaDetail