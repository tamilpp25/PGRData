local XArithmetic = require("XFormula/XArithmetic")
---@class XRogueSimConditionFormula : XArithmetic
local XRogueSimConditionFormula = XClass(XArithmetic, "XRogueSimConditionFormula")

function XRogueSimConditionFormula:Ctor()
    self.OperatorLevel["&"] = 0
    self.OperatorLevel["|"] = 0
    self.OperatorPattern["%&"] = "&"
    self.OperatorPattern["%|"] = "|"
    self.ConditionArgs = nil
    self.Desc = nil

    ---@type XTableRogueSimCondition
    self.Config = nil
    self.ComputeFunc = nil
    self:SetTextValueHandler(handler(self, self.GetValueByName))
end

function XRogueSimConditionFormula:GetValue(left, right, operator)
    if "&" == operator then
        return self:CheckCondition(left) and self:CheckCondition(right)
    elseif "|" == operator then
        return self:CheckCondition(left) or self:CheckCondition(right)
    else
        return self.Super.GetValue(self, left, right, operator)
    end
end

function XRogueSimConditionFormula:Calculate(expression)
    local result, size = self.Super.Calculate(self, expression)
    if size > 0 then
        XLog.Error(string.format("请检查RogueSimCondition配置表id%s公式%s是否配置错误", self.Config.Id, self.Config.Formula))
    end
    -- 特殊处理只有一个条件的情况下
    if type(result) == "number" then
        return self:CheckCondition(result)
    end
    return result
end

function XRogueSimConditionFormula:GetValueByName(name)
    if type(name) == "boolean" then
        return name
    end
    if tonumber(name) then
        return tonumber(name)
    end
    XLog.Error(string.format("无法识别的值%s，请检查RogueSimCondition配置表id%s公式%s是否配置错误", name, self.Config.Id, self.Config.Formula))
    return false
end

function XRogueSimConditionFormula:SetConfig(config)
    self.Config = config
end

function XRogueSimConditionFormula:SetConditionArgs(conditionArgs)
    self.ConditionArgs = conditionArgs
end

function XRogueSimConditionFormula:SetComputeFunc(computeFunc)
    self.ComputeFunc = computeFunc
end

function XRogueSimConditionFormula:ClearDesc()
    self.Desc = nil
end

function XRogueSimConditionFormula:GetDesc()
    return self.Desc
end

function XRogueSimConditionFormula:CheckCondition(id)
    if type(id) == "boolean" then
        return id
    end
    local result, desc
    if self.ComputeFunc then
        result, desc = self.ComputeFunc(id, table.unpack(self.ConditionArgs or {}))
    else
        result, desc = XConditionManager.CheckCondition(id, table.unpack(self.ConditionArgs or {}))
    end
    -- 记录首次条件不通过的描述
    if result == false and self.Desc == nil then
        self.Desc = desc
    end
    return result
end

function XRogueSimConditionFormula:GetResult(formula, conditionArgs, computeFunc)
    self:ClearDesc()
    self:SetConditionArgs(conditionArgs)
    self:SetComputeFunc(computeFunc)
    local result = self:Calculate(formula)
    local desc = self:GetDesc()
    self.Config = nil
    return result, desc
end

return XRogueSimConditionFormula
