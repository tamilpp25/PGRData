-- 模拟器内部条件控制器
---@class XRogueSimConditionSubControl : XControl
---@field private _Model XRogueSimModel
---@field _MainControl XRogueSimControl
local XRogueSimConditionSubControl = XClass(XControl, "XRogueSimConditionSubControl")
function XRogueSimConditionSubControl:OnInit()
    --初始化内部变量
    self.ConditionFormula = nil
end

function XRogueSimConditionSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRogueSimConditionSubControl:RemoveAgencyEvent()

end

function XRogueSimConditionSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self.ConditionFormula = nil
end

-- 获取条件描述
---@param conditionId number
---@return string
function XRogueSimConditionSubControl:GetConditionDesc(conditionId)
    local template = self._Model:GetRogueSimConditionConfig(conditionId)
    if not template then
        XLog.Error("XRogueSimConditionSubControl:GetConditionDesc error: template is nil, conditionId is " .. conditionId)
        return ""
    end
    return template.Desc or ""
end

function XRogueSimConditionSubControl:CheckCondition(conditionId, ...)
    local template = self._Model:GetRogueSimConditionConfig(conditionId)
    if not template then
        XLog.Error("XRogueSimConditionSubControl:CheckCondition error: template is nil, conditionId is " .. conditionId)
        return false
    end
    local methodName = "ConditionType" .. template.Type
    if not self[methodName] then
        XLog.Error("XRogueSimConditionSubControl:CheckCondition error: methodName is " .. methodName)
        return false
    end
    return self[methodName](self, template, ...)
end

-- 表达式条件类型
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType0(condition, ...)
    local args = { ... }
    if not self.ConditionFormula then
        ---@type XRogueSimConditionFormula
        self.ConditionFormula = require("XModule/XRogueSim/XEntity/Formula/XRogueSimConditionFormula").New()
    end
    -- 便于在内部提示配置错误
    self.ConditionFormula:SetConfig(condition)
    local result, desc = self.ConditionFormula:GetResult(condition.Formula, args, handler(self, self.CheckCondition))
    if condition.Desc then
        desc = condition.Desc
    end
    return result, desc
end

-- 指定类型货物的库存大于、等于、小于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType3(condition)
    if #condition.Params < 3 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local commodityId = condition.Params[1]
    local camp = condition.Params[2]
    local targetStock = condition.Params[3]
    local curStock = self._MainControl.ResourceSubControl:GetCommodityActualCount(commodityId)
    if not self._Model:CompareInt(curStock, targetStock, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 当前回合数大于、小于、等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType4(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local camp = condition.Params[1]
    local targetTurn = condition.Params[2]
    local curTurn = self._MainControl:GetCurTurnNumber()
    if not self._Model:CompareInt(curTurn, targetTurn, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 是否已获得指定道具
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType5(condition)
    if #condition.Params < 1 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local propId = condition.Params[1]
    local count = self._MainControl.MapSubControl:GetOwnPropCountByPropId(propId)
    if count < 1 then
        return false, condition.Desc
    end
    return true, ""
end

-- 是否已触发/未触发指定事件
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType6(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local isTrigger = condition.Params[1] == 1
    local eventId = condition.Params[2]
    local triggerCount = self._MainControl:GetStatisticsValue(XEnumConst.RogueSim.StatisticsType.EventTrigger, eventId)
    if isTrigger then
        if triggerCount > 0 then
            return true, ""
        end
    else
        if triggerCount < 1 then
            return true, ""
        end
    end
    return false, condition.Desc
end

-- 主城达到/未达到指定等级
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType7(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local camp = condition.Params[1]
    local level = condition.Params[2]
    local curLevel = self._MainControl:GetCurMainLevel()
    if camp == 1 then
        if curLevel >= level then
            return true, ""
        end
    else
        if curLevel < level then
            return true, ""
        end
    end
    return false, condition.Desc, curLevel, level
end

-- 指定类型货物当前的指定属性大于/小于/等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType8(condition)
    if #condition.Params < 4 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local commodityId = condition.Params[1]
    local attrType = condition.Params[2]
    local camp = condition.Params[3]
    local targetValue = condition.Params[4]
    local curValue = self._MainControl.BuffSubControl:GetCommodityActualAttr(commodityId, attrType)
    if not self._Model:CompareInt(curValue, targetValue, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 获得指定标签的道具数量大于、小于、等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType9(condition)
    if #condition.Params < 3 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local tag = condition.Params[1]
    local camp = condition.Params[2]
    local targetCount = condition.Params[3]
    local curCount = self._MainControl.MapSubControl:GetOwnPropCountByTag(tag)
    if not self._Model:CompareInt(curCount, targetCount, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 已探索的城邦数量大于、小于、等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType10(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local camp = condition.Params[1]
    local targetCount = condition.Params[2]
    local curCount = self._MainControl.MapSubControl:GetOwnCityCount()
    if not self._Model:CompareInt(curCount, targetCount, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 已完成的城邦任务数量大于、小于、等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType11(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local camp = condition.Params[1]
    local targetCount = condition.Params[2]
    local curCount = self._MainControl:GetFinishedTaskCount()
    if not self._Model:CompareInt(curCount, targetCount, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 指定资源的拥有数目大于、等于、小于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType13(condition)
    if #condition.Params < 3 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local resourceId = condition.Params[1]
    local camp = condition.Params[2]
    local targetCount = condition.Params[3]
    local curCount = self._MainControl.ResourceSubControl:GetResourceOwnCount(resourceId)
    if not self._Model:CompareInt(curCount, targetCount, camp) then
        return false, condition.Desc
    end
    return true, ""
end

-- 探索过指定城邦Id
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType14(condition)
    if #condition.Params < 1 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local ownCityConfigIds = self._MainControl.MapSubControl:GetOwnCityConfigIds()
    local targetCount = 0
    local curCount = 0
    for _, cityId in pairs(condition.Params) do
        targetCount = targetCount + 1
        if table.contains(ownCityConfigIds, cityId) then
            curCount = curCount + 1
        end
    end
    if curCount == targetCount then
        return true, ""
    else
        return false, condition.Desc, curCount, targetCount
    end
end

-- 累计获得金币大于、小于、等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType15(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local camp = condition.Params[1]
    local targetCount = condition.Params[2]
    local curCount = self._MainControl:GetStatisticsValue(XEnumConst.RogueSim.StatisticsType.GoldAdd)
    if not self._Model:CompareInt(curCount, targetCount, camp) then
        return false, condition.Desc, curCount, targetCount
    end
    return true, ""
end

-- 累计生产货物(包括所有货物)数量大于、小于、等于指定值
---@param condition XTableRogueSimCondition
function XRogueSimConditionSubControl:ConditionType16(condition)
    if #condition.Params < 2 then
        XLog.Error("config params len error ! template id:" .. condition.Id)
        return false, condition.Desc
    end
    local camp = condition.Params[1]
    local targetCount = condition.Params[2]
    local curCount = 0
    for _, commodityId in ipairs(XEnumConst.RogueSim.CommodityIds) do
        curCount = curCount + self._MainControl:GetStatisticsValue(XEnumConst.RogueSim.StatisticsType.CommodityProduce, commodityId)
    end
    if not self._Model:CompareInt(curCount, targetCount, camp) then
        return false, condition.Desc, curCount, targetCount
    end
    return true, ""
end

return XRogueSimConditionSubControl
