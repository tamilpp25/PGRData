local XUiNewYearDrawLog = XLuaUiManager.Register(XLuaUi, "UiNewYearDrawLog")

function XUiNewYearDrawLog:OnStart(id)
    self.Id = id
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnTanchuangClose()
    end
    self:InitBaseRulePanel()
end

function XUiNewYearDrawLog:InitBaseRulePanel()
    local cfg = XSignInConfigs.GetSignDrawNewYearConfig(self.Id)
    local baseRules = cfg.RuleTitle
    local baseRuleTitles = cfg.RuleContent
    self:SetRuleData(baseRules, baseRuleTitles, self.Panel1)
end

function XUiNewYearDrawLog:SetRuleData(rules, ruleTitles, panel)
    local PanelObj = {}
    PanelObj.Transform = panel.transform
    XTool.InitUiObject(PanelObj)
    PanelObj.PanelTxt.gameObject:SetActiveEx(false)
    for k,v in pairs(rules) do
        local go = CS.UnityEngine.Object.Instantiate(PanelObj.PanelTxt, PanelObj.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        local description =
        XTool.InitUiObject(tmpObj)
        tmpObj.TxtRule.HrefListener = function(link, content)
            self:ClickLink(link)
        end
        local str = rules[k]
        if string.find(str, "<a href=")  then
            str = string.sub(str, 2, string.len(str) - 1)
            local strs = string.Split(str, '""')
            str = string.format("%s%s%s%s%s", strs[1], '"', strs[2], '"', strs[3])
        end
        tmpObj.TxtRuleTittle.text = ruleTitles[k]
        tmpObj.TxtRule.text = str
        tmpObj.TxtRuleTittle.text = string.gsub(tmpObj.TxtRuleTittle.text, "\\n", "\n")
        tmpObj.TxtRule.text = string.gsub(tmpObj.TxtRule.text, "\\n", "\n")
        tmpObj.GameObject:SetActiveEx(true)
    end
end

function XUiNewYearDrawLog:OnBtnTanchuangClose()
    self:Close()
end

function XUiNewYearDrawLog:ClickLink(url)
    CS.UnityEngine.Application.OpenURL(url)
end