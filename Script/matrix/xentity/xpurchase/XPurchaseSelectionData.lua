--- 用于点击礼包详情时记录随机、自选组的选择信息
---@class XPurchaseSelectionData
---@field RandomBoxChoices function
---@field SelfChoices function
local XPurchaseSelectionData = XClass(nil, 'XPurchaseSelectionData')

function XPurchaseSelectionData:SetRandomChoice(templateId, isjoin)
    if self.RandomBoxChoices == nil then
        self.RandomBoxChoices = {}
    end

    local isin, index = table.contains(self.RandomBoxChoices, templateId)

    if isjoin then
        if isin then
            XLog.Error(tostring(templateId)..'已经在选择列表中，但仍尝试加入选择')
        else
            table.insert(self.RandomBoxChoices, templateId)
        end
    else
        if not isin then
            XLog.Error(tostring(templateId)..'不在选择列表中，但尝试移除选择')
        else
            table.remove(self.RandomBoxChoices, index)
        end
    end
end

function XPurchaseSelectionData:SetSelfChoice(groupId, templateId)
    if self.SelfChoices == nil then
        self.SelfChoices = {}
    end

    self.SelfChoices[groupId] = templateId
end

function XPurchaseSelectionData:CheckRandomChoiceIsSelect(templateId)
    if self.RandomBoxChoices == nil then
        return false
    end

    return table.contains(self.RandomBoxChoices, templateId)
end

function XPurchaseSelectionData:CheckSelfChoiceIsSelect(groupId, templateId)
    if self.SelfChoices == nil then
        return false
    end

    return self.SelfChoices[groupId] == templateId
end

function XPurchaseSelectionData:ClearRandomBoxChoices()
    self.RandomBoxChoices = nil
end

return XPurchaseSelectionData