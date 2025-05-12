local XArithmetic = require("XFormula/XArithmetic")

local XBigWorldConditionArithmetic = XClass(XArithmetic, "XBigWorldConditionArithmetic")
function XBigWorldConditionArithmetic:Ctor()
    self.OperatorLevel["&"] = 0
    self.OperatorLevel["|"] = 0
    self.OperatorPattern["%&"] = "&"
    self.OperatorPattern["%|"] = "|"
    self.ConditionArgs = false
    self.Desc = false
    ---@type XTableCondition
    self.Config = false
end

function XBigWorldConditionArithmetic:GetValue(left, right, operator)
    if "&" == operator then
        return self:CheckCondition(left) and self:CheckCondition(right)
    elseif "|" == operator then
        return self:CheckCondition(left) or self:CheckCondition(right)
    else
        return XBigWorldConditionArithmetic.Super.GetValue(self, left, right, operator)
    end
end

function XBigWorldConditionArithmetic:SetConfig(config)
    self.Config = config
end

function XBigWorldConditionArithmetic:SetConditionArgs(value)
    self.ConditionArgs = value
end

function XBigWorldConditionArithmetic:ClearDesc()
    self.Desc = nil
end

function XBigWorldConditionArithmetic:GetDesc()
    return self.Desc
end

function XBigWorldConditionArithmetic:CheckCondition(id)
    if type(id) == "boolean" then
        return id
    end
    local result, desc = XMVCA.XBigWorldService:CheckCondition(id, table.unpack(self.ConditionArgs or {}))
    -- 记录首次条件不通过的描述
    if result == false and self.Desc == nil then
        self.Desc = desc
    end
    return result
end

function XBigWorldConditionArithmetic:Calculate(expression)
    local result, size = XBigWorldConditionArithmetic.Super.Calculate(self, expression)
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


---@class XBigWorldCondition Dlc用条件检查
local XBigWorldCondition = XClass(nil, "XBigWorldCondition")

function XBigWorldCondition:Ctor()
    --组合条件
    self._Formula = false
    self._RangeTypeMin = 10000000
    self._RangeTypeMax = 99999999
    self:InitFunc()
end

function XBigWorldCondition:OnRelease()
    self:InitFunc()
end

function XBigWorldCondition:InitFunc()
    self._TypeId2Func = {}
end

function XBigWorldCondition:RegisterConditionFunc(conditionType, func)
    if self._TypeId2Func[conditionType] then
        return XLog.Error("如果热更可以忽略报错，类型 = " .. conditionType .. "的CheckCondition方法已存在!")
    end
    self._TypeId2Func[conditionType] = func
end

--- 检查条件是否满足
---@param condition XTableCondition
---@return boolean, string
--------------------------
function XBigWorldCondition:CheckCondition(condition, ...)
    local typeId = condition.Type

    -- 0代表公式专用，没有范围设置，主要是要与服务器逻辑同步
    if typeId == 0 then
        return self:CheckComplexCondition(condition, ...)
    end
    --只检测目标范围的ConditionType
    if typeId >= self._RangeTypeMin and typeId < self._RangeTypeMax then
        local check = self._TypeId2Func[typeId]
        if not check then
            XLog.Error("暂未实现类型 = " .. typeId .. "的CheckCondition方法!")
            return false, ""
        end
        return check(condition, ...)
    end
    
    return XConditionManager.CheckConditionByTemplate(condition, ...)
end

--- 复杂组合条件检测
---@param condition XTableCondition
---@return boolean, string
--------------------------
function XBigWorldCondition:CheckComplexCondition(condition, ...)
    if not self._Formula then
        self._Formula = require("XFormula/XConditionFormula").New()
        self._Formula:ChangeArithmetic(XBigWorldConditionArithmetic.New())
    end
    self._Formula:SetConfig(condition)
    local result, desc = self._Formula:GetResult(condition.Formula, { ... })
    if not string.IsNilOrEmpty(condition.Desc) then
        desc = condition.Desc
    end
    return result, desc
end

return XBigWorldCondition