--===================================== XUiGridGachaCanLiverRuleContent =============================
local XUiGridGachaCanLiverRuleContent = XClass(XUiNode, 'XUiGridGachaCanLiverRuleContent')

function XUiGridGachaCanLiverRuleContent:SetContent(title, content)
    self.TxtRuleTitle.text = title
    self.TxtRule.text = content
end

--===================================== XUiPanelGachaCanLiverRuleLog =============================
---@class XUiPanelGachaCanLiverRuleLog: XUiNode
---@field _Control XGachaCanLiverControl
---@field RootUi XLuaUi
local XUiPanelGachaCanLiverRuleLog = XClass(XUiNode, "XUiPanelGachaCanLiverRuleLog")

function XUiPanelGachaCanLiverRuleLog:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiPanelGachaCanLiverRuleLog:RefreshUiShow(gachaConfig)
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
        local grid = XUiGridGachaCanLiverRuleContent.New(go, self)
        grid:Open()
        grid:SetContent(string.gsub(baseRuleTitles[k], "\\n", "\n"), string.gsub(baseRules[k], "\\n", "\n"))
    end
end

return XUiPanelGachaCanLiverRuleLog