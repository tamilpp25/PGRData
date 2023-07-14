local XUiPanelRule = XClass(nil, "XUiPanelRule")

function XUiPanelRule:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiPanelRule:RefreshUiShow(gachaConfig)
    if self.GachaConfig then
        return
    end
    self.GachaConfig = gachaConfig

    local rule = self.OrganizeRule or XGachaConfigs.GetGachaRuleCfgById(self.GachaConfig.Id)
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

function XUiPanelRule:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelRule:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelRule