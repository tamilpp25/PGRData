RuleViewType = RuleViewType or {
    Text = 1, -- 文本
    DropItem = 2, -- 掉落物品&相关概率
}

local XRuleViewModel = XClass(nil, "XRuleViewModel")

function XRuleViewModel:Ctor()
    self.Title = ""
    self.ViewType = nil
    self.RuleDatas = nil
end

function XRuleViewModel:GetTitle()
    return self.Title
end

function XRuleViewModel:SetTitle(value)
    self.Title = value
end

function XRuleViewModel:GetType()
    return self.ViewType
end

function XRuleViewModel:GetRuleDatas()
    return self.RuleDatas
end

function XRuleViewModel:SetRuleDatas(value)
    self.RuleDatas = value
end

-- 看子类实现
function XRuleViewModel:AddRuleData(...)
    
end

return XRuleViewModel