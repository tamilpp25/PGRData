local XArithmetic = require("XFormula/XArithmetic")
local XFormula = require("XFormula/XFormula")

--######################## XConditionArithmetic ########################
local XConditionArithmetic = XClass(XArithmetic, "XConditionArithmetic")

function XConditionArithmetic:Ctor()
    self.OperatorLevel["&"] = 0
    self.OperatorLevel["|"] = 0
    self.OperatorPattern["%&"] = "&"
    self.OperatorPattern["%|"] = "|"
    self.ConditionArgs = nil
    self.Desc = nil
    -- XTableCondition
    self.Config = nil
end

function XConditionArithmetic:GetValue(left, right, operator)
    if "&" == operator then
		return self:CheckCondition(left) and self:CheckCondition(right)
	elseif "|" == operator then
		return self:CheckCondition(left) or self:CheckCondition(right)
    else
        return XConditionArithmetic.Super.GetValue(self, left, right, operator)
	end
end

function XConditionArithmetic:SetConfig(config)
    self.Config = config
end

function XConditionArithmetic:SetConditionArgs(value)
    self.ConditionArgs = value
end

function XConditionArithmetic:ClearDesc()
    self.Desc = nil
end

function XConditionArithmetic:GetDesc()
    return self.Desc
end

function XConditionArithmetic:CheckCondition(id)
    if type(id) == "boolean" then
        return id
    end
    local result, desc = XConditionManager.CheckCondition(id, table.unpack(self.ConditionArgs or {}))
    -- 记录首次条件不通过的描述
    if result == false and self.Desc == nil then
        self.Desc = desc
    end
    return result
end

function XConditionArithmetic:Calculate(expression)
    local result, size = XConditionArithmetic.Super.Calculate(self, expression)
    if size > 0 then
        XLog.Error(string.format("请检查condition配置表id%s公式%s是否配置错误"
        , self.Config.Id, self.Config.Formula))
    end
    -- 特殊处理只有一个条件的情况下
    if type(result) == "number" then
        return self:CheckCondition(result)
    end
    return result
end

--######################## XConditionFormula ########################
local XConditionFormula = XClass(XFormula, "XConditionFormula")

function XConditionFormula:Ctor()
    -- XTableCondition
    self.Config = nil
    self.Arithmetic = XConditionArithmetic.New()
    self.Arithmetic:SetTextValueHandler(handler(self, self.GetValueByName))
end

function XConditionFormula:SetConfig(config)
    self.Config = config
    self.Arithmetic:SetConfig(config)
end

function XConditionFormula:GetValueByName(name)
    if type(name) == "boolean" then
        return name
    end
	if tonumber(name) then
		return tonumber(name)
	end
    XLog.Error(string.format("无法识别的值%s，请检查condition配置表id%s公式%s是否配置错误"
        , name, self.Config.Id, self.Config.Formula))
    return false
end

function XConditionFormula:GetResult(formula, conditionArgs)
    self.Arithmetic:ClearDesc()
    self.Arithmetic:SetConditionArgs(conditionArgs)
    local result = self.Arithmetic:Calculate(formula)
    local desc = self.Arithmetic:GetDesc()
    self.Config = nil
    self.Arithmetic:SetConfig(nil)
    return result, desc
end

return XConditionFormula