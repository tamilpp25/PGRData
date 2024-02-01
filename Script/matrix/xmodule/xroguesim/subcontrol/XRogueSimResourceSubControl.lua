-- 资源控制器 包括 生产、贸易
---@class XRogueSimResourceSubControl : XControl
---@field private _Model XRogueSimModel
---@field _MainControl XRogueSimControl
local XRogueSimResourceSubControl = XClass(XControl, "XRogueSimResourceSubControl")
function XRogueSimResourceSubControl:OnInit()
    --初始化内部变量
end

function XRogueSimResourceSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRogueSimResourceSubControl:RemoveAgencyEvent()

end

function XRogueSimResourceSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--region 资源相关

-- 获取资源已拥有的数量
function XRogueSimResourceSubControl:GetResourceOwnCount(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetResourceCount(id)
end

-- 获取资源名称
function XRogueSimResourceSubControl:GetResourceName(id)
    local config = self._Model:GetRogueSimResourceConfig(id)
    return config and config.Name or ""
end

-- 获取资源描述
function XRogueSimResourceSubControl:GetResourceDesc(id)
    local config = self._Model:GetRogueSimResourceConfig(id)
    return config and config.Desc or ""
end

-- 获取资源图片
function XRogueSimResourceSubControl:GetResourceIcon(id)
    local config = self._Model:GetRogueSimResourceConfig(id)
    return config and config.Icon or ""
end

--endregion

--region 货物相关

-- 获取货物已拥有的数量
function XRogueSimResourceSubControl:GetCommodityOwnCount(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetCommodityCount(id)
end

-- 获取产出货物Id
function XRogueSimResourceSubControl:GetProductCommodityId()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetProductCommodityId()
end

-- 获取货物出售数量
---@param id number 货物Id
function XRogueSimResourceSubControl:GetSellPlanCount(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetSellPlanCount(id)
end

-- 获取货物价格波动
---@param id number 货物Id
function XRogueSimResourceSubControl:GetCommodityPriceRate(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetCommodityPriceRate(id)
end

-- 获取货物实际数量 已拥有的 - 待出售的
function XRogueSimResourceSubControl:GetCommodityActualCount(id)
    local ownCount = self:GetCommodityOwnCount(id)
    local sellPlanCount = self:GetSellPlanCount(id)
    local count = ownCount - sellPlanCount
    if count >= 0 then
        return count
    end
    return 0
end

-- 获取货物出售的实际数量
---@param id number 货物Id
function XRogueSimResourceSubControl:GetSellPlanActualCount(id)
    local ownCount = self:GetCommodityOwnCount(id)
    local sellPlanCount = self:GetSellPlanCount(id)
    local count = ownCount - sellPlanCount
    if count >= 0 then
        return sellPlanCount
    end
    return ownCount
end

-- 获取货物图片
function XRogueSimResourceSubControl:GetCommodityIcon(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.Icon or ""
end

-- 获取货物名称
function XRogueSimResourceSubControl:GetCommodityName(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.Name or ""
end

-- 获取货物初始最大数量
function XRogueSimResourceSubControl:GetCommodityMaxCount(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.MaxCount or 0
end

-- 获取生产消耗资源数量
function XRogueSimResourceSubControl:GetCommodityCostResourceCount(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.CostResourceCount or 0
end

-- 获取货物产量
function XRogueSimResourceSubControl:GetCommodityProduction(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.Production or 0
end

-- 获取货物产量加成率（万分比）
function XRogueSimResourceSubControl:GetCommodityProduceIncreaseRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.ProduceIncreaseRate or 0
end

-- 获取货物生产暴击率（万分比）
function XRogueSimResourceSubControl:GetCommodityProduceCriticalChanceRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.ProduceCriticalChanceRate or 0
end

-- 获取货物生产暴击产量加成率（万分比）
function XRogueSimResourceSubControl:GetCommodityProduceCriticalBonusRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.ProduceCriticalBonusRate or 0
end

-- 获取货物出售价格
function XRogueSimResourceSubControl:GetCommodityPrice(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.Price or 0
end

-- 获取货物出售价格加成率（万分比）
function XRogueSimResourceSubControl:GetCommodityPriceIncreaseRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.PriceIncreaseRate or 0
end

-- 获取货物出售暴击率（万分比）
function XRogueSimResourceSubControl:GetCommoditySellCriticalChanceRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.SellCriticalChanceRate or 0
end

-- 获取货物出售暴击价格加成率（万分比）
function XRogueSimResourceSubControl:GetCommoditySellCriticalBonusRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.SellCriticalBonusRate or 0
end

-- 获取货物出售价格波动上限
function XRogueSimResourceSubControl:GetCommodityMaxPriceRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.MaxPriceRate or 0
end

-- 获取货物出售价格波动下限
function XRogueSimResourceSubControl:GetCommodityMinPriceRate(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.MinPriceRate or 0
end

-- 获取警告百分比
function XRogueSimResourceSubControl:GetCommodityWarningPercent(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.WarningPercent or {}
end

-- 获取警告文本
function XRogueSimResourceSubControl:GetCommodityWarningText(id, index)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    local text = config and config.WarningText or {}
    return text[index] or ""
end

-- 获取警告颜色
function XRogueSimResourceSubControl:GetCommodityWarningColor(id, index)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    local color = config and config.WarningColor or {}
    return XUiHelper.Hexcolor2Color(color[index] or "323232")
end

-- 获取气泡组Id
function XRogueSimResourceSubControl:GetCommodityBubbleGroupId(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.BubbleGroupId or 0
end

-- 获取货物总上限值 初始最大值 + Effect效果加成
function XRogueSimResourceSubControl:GetCommodityTotalLimit(id)
    -- 初始最大值
    local maxCount = self:GetCommodityMaxCount(id)
    -- 加成
    local addCount = self._MainControl.BuffSubControl:GetStockLimitAdd(id)
    return maxCount + addCount
end

-- 获取进度信息 1 进度值 2 颜色值 3 描述
function XRogueSimResourceSubControl:GetCommodityProgressData(id)
    local count = self:GetCommodityActualCount(id)
    local limit = self:GetCommodityTotalLimit(id)
    count = count > limit and limit or count
    local progress = count / limit
    -- 警告百分比
    local warningPercent = self:GetCommodityWarningPercent(id)
    local curIndex = 1
    for index, percent in pairs(warningPercent) do
        if progress * 100 >= percent then
            curIndex = index
        end
    end
    local color = self:GetCommodityWarningColor(id, curIndex)
    local desc = self:GetCommodityWarningText(id, curIndex)
    return progress, color, desc
end

-- 获取总货物价格 基本价格 * 价格加成 * 波动 注意：不计算货物的特殊属性
function XRogueSimResourceSubControl:GetCommodityTotalPrice(id)
    -- 基础价格 = 配置价格 + 基础价格加成
    local price = self:GetCommodityPrice(id) + self._MainControl.BuffSubControl:GetPriceAddBase(id)
    -- 价格加成
    local priceRate = 1 + self._MainControl.BuffSubControl:GetPriceAddRatioA(id) / 10000
    -- 波动
    local fluctuation = 1 + self._MainControl.BuffSubControl:GetPriceTotalRatio(id) / 10000
    -- 产量固定加成
    local addFixed = self._MainControl.BuffSubControl:GetPriceAddFixed(id)
    return math.floor(price * priceRate * fluctuation) + addFixed
end

-- 获取总生产效率 基本产量 * 产量加成 注意：不计算货物的特殊属性
function XRogueSimResourceSubControl:GetCommodityTotalProduceRate(id)
    -- 基础per产量 = 配置per产量 + 基础per产量加成
    local produce = self:GetCommodityProduction(id) + self._MainControl.BuffSubControl:GetProduceAddBase(id)
    -- 人口产量值 （人数/产量）
    local population = self:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Population)
    local costResourceCount = self:GetCommodityCostResourceCount(id)
    -- 产量加成
    local produceRate = 1 + self._MainControl.BuffSubControl:GetProduceAddRatioA(id) / 10000
    -- 波动
    local fluctuation = 1 + self._MainControl.BuffSubControl:GetProduceAddRatioB(id) / 10000
    -- 产量固定加成
    local addFixed = self._MainControl.BuffSubControl:GetProduceAddFixed(id)
    return math.floor(produce * (population / costResourceCount) * produceRate * fluctuation) + addFixed
end

-- 获取出售货物Id(出售货物数量大于0)
function XRogueSimResourceSubControl:GetSellCommodityIds()
    local commodityIds = {}
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local sellCount = self:GetSellPlanCount(id)
        if XTool.IsNumberValid(sellCount) then
            table.insert(commodityIds, id)
        end
    end
    return commodityIds
end

-- 检测预估产量是否超出储存上限
function XRogueSimResourceSubControl:CheckProduceRateIsExceedLimit(id)
    local produceRate = self:GetCommodityTotalProduceRate(id)
    local actualCount = self:GetCommodityActualCount(id)
    local limitCount = self:GetCommodityTotalLimit(id)
    return produceRate + actualCount > limitCount
end

-- 检测货物容量是否已达上限
function XRogueSimResourceSubControl:CheckCommodityIsExceedLimit(id)
    local actualCount = self:GetCommodityActualCount(id)
    local limitCount = self:GetCommodityTotalLimit(id)
    return actualCount >= limitCount
end

-- 检测实际出售信息是否有变动
function XRogueSimResourceSubControl:CheckActualSellCountIsChange(info)
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local count = info[id] or 0
        if count ~= self:GetSellPlanCount(id) then
            return true
        end
    end
    return false
end

--endregion

--region 货物气泡相关

-- 获取气泡价格组
function XRogueSimResourceSubControl:GetBubblePrice(id)
    local config = self._Model:GetCommodityBubbleGroupConfig(id)
    return config and config.Price or {}
end

-- 获取气泡特殊价格组
function XRogueSimResourceSubControl:GetBubbleSpecialPrice(id)
    local config = self._Model:GetCommodityBubbleGroupConfig(id)
    return config and config.SpecialPrice or {}
end

-- 获取气泡产量组
function XRogueSimResourceSubControl:GetBubbleProduction(id)
    local config = self._Model:GetCommodityBubbleGroupConfig(id)
    return config and config.Production or {}
end

-- 获取气泡特殊产量组
function XRogueSimResourceSubControl:GetBubbleSpecialProduction(id)
    local config = self._Model:GetCommodityBubbleGroupConfig(id)
    return config and config.SpecialProduction or {}
end

-- 获取气泡价格提示组
function XRogueSimResourceSubControl:GetCommodityPriceBubbleGroup(id)
    local prices = self:GetBubblePrice(id)
    local specialPrices = self:GetBubbleSpecialPrice(id)
    return XTool.MergeArray(prices, specialPrices)
end

-- 获取气泡产量提示组
function XRogueSimResourceSubControl:GetCommodityProductionBubbleGroup(id)
    local productions = self:GetBubbleProduction(id)
    local specialProductions = self:GetBubbleSpecialProduction(id)
    return XTool.MergeArray(productions, specialProductions)
end

-- 获取气泡名称
function XRogueSimResourceSubControl:GetCommodityBubbleName(id)
    local config = self._Model:GetCommodityBubbleConfig(id)
    return config and config.Name or ""
end

-- 获取气泡方法名
function XRogueSimResourceSubControl:GetCommodityBubbleMethodName(id)
    local config = self._Model:GetCommodityBubbleConfig(id)
    return config and config.MethodName or ""
end

-- 货物基础价格
function XRogueSimResourceSubControl:GetCommodityPriceBubble(id)
    return self:GetCommodityPrice(id) + self._MainControl.BuffSubControl:GetPriceAddBase(id)
end

-- 货物价格加成
function XRogueSimResourceSubControl:GetCommodityPriceAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceAddRatioA(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物价格波动
function XRogueSimResourceSubControl:GetCommodityPriceFluctuationBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceTotalRatio(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物价格固定加成
function XRogueSimResourceSubControl:GetCommodityPriceAddFixedBubble(id)
    return self._MainControl.BuffSubControl:GetPriceAddFixed(id)
end

-- 货物价格暴击率
function XRogueSimResourceSubControl:GetCommodityPriceCritAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceTotalCritical(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物价格暴击伤害
function XRogueSimResourceSubControl:GetCommodityPriceCritHurtAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceTotalCriticalHurt(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量
function XRogueSimResourceSubControl:GetCommodityProductionBubble(id)
    return self:GetCommodityProduction(id) + self._MainControl.BuffSubControl:GetProduceAddBase(id)
end

-- 货物产量加成
function XRogueSimResourceSubControl:GetCommodityProductionAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceAddRatioA(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量波动
function XRogueSimResourceSubControl:GetCommodityProductionFluctuationBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceAddRatioB(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量暴击率
function XRogueSimResourceSubControl:GetCommodityProductionCritAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceTotalCritical(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量暴击伤害
function XRogueSimResourceSubControl:GetCommodityProductionCritHurtAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceTotalCriticalHurt(id) / 100
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 先转换然后添加后缀
function XRogueSimResourceSubControl:ConvertNumberToIntegerWithSuffix(value, suffix)
    value = self:ConvertNumberToInteger(value, 1)
    if not suffix then
        suffix = "%"
    end
    return string.format("%s%s", value, suffix)
end

-- 保留digit位小数并将小数为0的数转为整数
---@param value number
---@param digit number 保留几位小数
---@return number
function XRogueSimResourceSubControl:ConvertNumberToInteger(value, digit)
    value = getRoundingValue(value, digit)
    local _, decimal = math.modf(value)
    if decimal == 0 then
        return math.floor(value)
    end
    return value
end

--endregion

return XRogueSimResourceSubControl
