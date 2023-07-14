local XRuleViewModel = require("XEntity/XCommon/XRule/XRuleViewModel")
local XRuleDropItemViewModel = XClass(XRuleViewModel, "XRuleDropItemViewModel")

function XRuleDropItemViewModel:Ctor()
    self.ViewType = RuleViewType.DropItem
    self.GoodSwitchBtnName = "unknow"
    self.ProbabilityBtnName = "unknow"
    self.GoodGroupDatas = {}
    self.ProbabilityGroupDatas = {}
end

function XRuleDropItemViewModel:SetGoodSwitchBtnName(name)
    self.GoodSwitchBtnName = name
end

function XRuleDropItemViewModel:GetGoodSwitchBtnName(name)
    return self.GoodSwitchBtnName
end

function XRuleDropItemViewModel:SetProbabilityBtnName(name)
    self.ProbabilityBtnName = name
end

function XRuleDropItemViewModel:GetProbabilityBtnName(name)
    return self.ProbabilityBtnName
end

function XRuleDropItemViewModel:CreateGoodGroup(index, title)
    if title == nil then title = "unknow" end
    self.GoodGroupDatas[index] = self.GoodGroupDatas[index] or {}
    self.GoodGroupDatas[index].Title = title
    return self.GoodGroupDatas[index]
end

function XRuleDropItemViewModel:AddGoodData(groupIndex, goodId, count)
    if count == nil then count = 1 end
    local group = self.GoodGroupDatas[groupIndex]
    if group == nil then group = self:CreateGoodGroup(groupIndex, "unknow") end
    group.GoodDatas = group.GoodDatas or {}
    table.insert(group.GoodDatas, {
        TemplateId = goodId,
        Count = count,
    })
end

function XRuleDropItemViewModel:GetGoodDatas(groupIndex)
    return self.GoodGroupDatas[groupIndex] or {}
end

function XRuleDropItemViewModel:CreateProbailityGroup(index, title)
    if title == nil then title = "unknow" end
    self.ProbabilityGroupDatas[index] = self.ProbabilityGroupDatas[index] or {}
    self.ProbabilityGroupDatas[index].Title = title
    return self.ProbabilityGroupDatas[index]
end

function XRuleDropItemViewModel:AddProbabilityData(groupIndex, name, probability, isSpecial)
    local group = self.ProbabilityGroupDatas[groupIndex]
    if group == nil then group = self:CreateProbailityGroup(groupIndex, "unknow") end
    group.ProbabilityDatas = group.ProbabilityDatas or {}
    table.insert(group.ProbabilityDatas, {
        Name = name,
        Probability = probability,
        IsSpecial = isSpecial
    })
end

function XRuleDropItemViewModel:GetProbabilityDatas(groupIndex)
    return self.ProbabilityGroupDatas[groupIndex] or {}
end

function XRuleDropItemViewModel:GetGoodGroupDatas()
    return self.GoodGroupDatas
end

function XRuleDropItemViewModel:GetProbabilityGroupDatas()
    return self.ProbabilityGroupDatas
end

return XRuleDropItemViewModel
