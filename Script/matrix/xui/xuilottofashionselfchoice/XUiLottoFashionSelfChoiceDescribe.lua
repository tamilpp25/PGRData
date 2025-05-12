local XUiLottoFashionSelfChoiceDescribe = XLuaUiManager.Register(XLuaUi, "UiLottoFashionSelfChoiceDescribe")

function XUiLottoFashionSelfChoiceDescribe:OnAwake()
    self:InitButton()
end

function XUiLottoFashionSelfChoiceDescribe:InitButton()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiLottoFashionSelfChoiceDescribe:OnStart(lottoPrimaryId)
    lottoPrimaryId = lottoPrimaryId or XDataCenter.LottoManager.GetCurSelfChoiceLottoPrimaryId()
    local config = XLottoConfigs.GetLottoPrimaryCfgById(lottoPrimaryId)

    local XUiGridRulePanel = require("XUi/XUiLottoFashionSelfChoice/Grid/XUiGridRulePanel")
    for k, title in pairs(config.RuleTitleList) do
        local go = k == 1 and self.GridRulePanel or XUiHelper.Instantiate(self.GridRulePanel, self.GridRulePanel.parent)
        local grid = XUiGridRulePanel.New(go, self)
        grid:Refresh(title, config.RuleTextList[k])
    end
end