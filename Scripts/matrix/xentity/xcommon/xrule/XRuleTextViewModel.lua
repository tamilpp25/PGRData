local XRuleViewModel = require("XEntity/XCommon/XRule/XRuleViewModel")
local XRuleTextViewModel = XClass(XRuleViewModel, "XRuleTextViewModel")

function XRuleTextViewModel:Ctor()
    self.ViewType = RuleViewType.Text
end

function XRuleTextViewModel:AddRuleData(title, ruleDesc)
    self.RuleDatas = self.RuleDatas or {}
    table.insert(self.RuleDatas, {
        Title = title,
        RuleDesc = ruleDesc
    })
end

return XRuleTextViewModel
