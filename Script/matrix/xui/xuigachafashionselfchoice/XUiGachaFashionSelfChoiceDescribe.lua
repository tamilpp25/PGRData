local XUiGachaFashionSelfChoiceDescribe = XLuaUiManager.Register(XLuaUi, "UiGachaFashionSelfChoiceDescribe")

function XUiGachaFashionSelfChoiceDescribe:OnAwake()
    self:InitButton()
end

function XUiGachaFashionSelfChoiceDescribe:InitButton()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiGachaFashionSelfChoiceDescribe:OnStart(activityId)
    local config = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityConfig()
    self.ActivityConfig = config

    local XUiGridRulePanel = require("XUi/XUiGachaFashionSelfChoice/Grid/XUiGridRulePanel")
    for k, title in pairs(config.RuleTitle) do
        local go = k == 1 and self.GridRulePanel or XUiHelper.Instantiate(self.GridRulePanel, self.GridRulePanel.parent)
        local grid = XUiGridRulePanel.New(go, self)
        grid:Refresh(title, config.RuleText[k])
    end
end