---@class XUiPanelGachaLuciaRule : XUiNode
---@field Parent XUiGachaLuciaLog
local XUiPanelGachaLuciaRule = XClass(XUiNode, "XUiPanelGachaLuciaRule")

function XUiPanelGachaLuciaRule:RefreshUiShow(gachaConfig)
    if self._GachaConfig then
        return
    end
    self._GachaConfig = gachaConfig

    local rule = self.OrganizeRule or XGachaConfigs.GetGachaRuleCfgById(self._GachaConfig.Id)
    local baseRules = rule.BaseRules
    local baseRuleTitles = rule.BaseRuleTitles

    self.PanelTxt.gameObject:SetActiveEx(false)
    for k, _ in pairs(baseRules) do
        local go = CS.UnityEngine.Object.Instantiate(self.PanelTxt, self.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        tmpObj.TxtRuleTitle.text = string.gsub(baseRuleTitles[k], "\\n", "\n")
        tmpObj.TxtRule.text = string.gsub(baseRules[k], "\\n", "\n")
        tmpObj.GameObject:SetActiveEx(true)
    end
end

return XUiPanelGachaLuciaRule