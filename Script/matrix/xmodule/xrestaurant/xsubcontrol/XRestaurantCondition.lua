
---@class XRestaurantCondition 厨房任务条件组
---@field _Model XRestaurantModel
local XRestaurantCondition = XClass(nil, "XRestaurantCondition")

function XRestaurantCondition:Ctor(model)
    self._Model = model
    self:OnInit()
end

function XRestaurantCondition:OnInit()
    local dict = {}
    for key, conditionType in pairs(XMVCA.XRestaurant.ConditionType) do
        dict[conditionType] = handler(self, self["Check" .. key])
    end
    
    self._ConditionFunc = dict
end

function XRestaurantCondition:CheckCondition(id, conditionValue, ...)
    local template = self._Model:GetConditionTemplate(id)
    if not template then
        return false, ""
    end
    local func = self._ConditionFunc[template.Type]
    if not func then
        XLog.Error("不存在类型-" .. template.Type .. "的判断条件")
        return false, ""
    end
    return func(template, conditionValue, ...)
end


--- 检查获得收银台奖励
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckCashierReward(template, conditionValue, ...)
    local target = template.Params[1] or 0
    return conditionValue >= target, template.Desc
end

--- 检查交付产品
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckSubmitProduct(template, conditionValue, ...)
    local target = template.Params[2] or 0
    return conditionValue >= target, template.Desc
end

--- 检查拍照是否完成
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckPhoto(template, conditionValue, ...)
    return conditionValue == 1, template.Desc
end

--- 检查产品生产
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckProductAdd(template, conditionValue, ...)
    local target = template.Params[2] or 0
    return target <= conditionValue, template.Desc
end

--- 检查消耗产品
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckProductConsume(template, conditionValue, ...)
    local target = template.Params[2] or 0
    return target <= conditionValue, template.Desc
end

--- 检查是否使用某个区域Buff
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckSectionBuff(template, conditionValue, ...)
    --local target = template.Params[1] or -1
    return conditionValue > 0, template.Desc
end

--- 检查是否使用某个区域Buff
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckHotSaleProductAdd(template, conditionValue, ...)
    local target = template.Params[1] or 0
    return target <= conditionValue, template.Desc
end

--- 检查是否使用某个区域Buff
---@param template XTableRestaurantCondition
---@param conditionValue number
---@return boolean, string
--------------------------
function XRestaurantCondition:CheckHotSaleProductConsume(template, conditionValue, ...)
    local target = template.Params[1] or 0
    return target <= conditionValue, template.Desc
end

function XRestaurantCondition:Release()
    self._ConditionFunc = nil
end

return XRestaurantCondition