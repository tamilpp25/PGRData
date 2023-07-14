local this = {}


function this.Init(go)
    this.GameObject = go
    this.Transform = go.transform
    local ruleConfig = XDataCenter.FireworksManager.GetRules()
    XTool.InitUiObject(this)
    this.PanelTxt.gameObject:SetActiveEx(false)
    for i = 1, #ruleConfig.RuleTitle do
        local go = CS.UnityEngine.Object.Instantiate(this.PanelTxt.gameObject)
        go.transform:SetParent(this.PanelContent, false)
        local item = {}
        item.GameObject = go
        item.Transform = go.transform
        XTool.InitUiObject(item)
        item.GameObject:SetActiveEx(true)
        item.TxtRuleTittle.text = ruleConfig.RuleTitle[i]
        local toReplace = ruleConfig.RuleContent[i]
        toReplace = string.gsub(toReplace, "\\n", "\n")
        item.TxtRule.text = toReplace
    end
end

function this.Refresh()

end

function this.Show()
    this.GameObject:SetActiveEx(true)
end

function this.Hide()
    this.GameObject:SetActiveEx(false)
end

return this