--  Buff控制器 包括 Effect系统
---@class XRogueSimBuffSubControl : XControl
---@field private _Model XRogueSimModel
---@field _MainControl XRogueSimControl
local XRogueSimBuffSubControl = XClass(XControl, "XRogueSimBuffSubControl")
function XRogueSimBuffSubControl:OnInit()
    --初始化内部变量
end

function XRogueSimBuffSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRogueSimBuffSubControl:RemoveAgencyEvent()

end

function XRogueSimBuffSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--region Buff相关

-- 获取BuffId
---@param id number 自增Id
function XRogueSimBuffSubControl:GetBuffIdById(id)
    local buffData = self._Model:GetBuffDataById(id)
    if not buffData then
        return 0
    end
    return buffData:GetBuffId()
end

-- 获取Buff剩余回合数
---@param id number 自增Id
function XRogueSimBuffSubControl:GetBuffRemainingTurnById(id)
    local buffData = self._Model:GetBuffDataById(id)
    if not buffData then
        return 0
    end
    return buffData:GetRemainingTurn()
end

-- 获取buff名称
function XRogueSimBuffSubControl:GetBuffName(id)
    local config = self._Model:GetRogueSimBuffConfig(id)
    return config and config.Name or ""
end

-- 获取Buff图片
function XRogueSimBuffSubControl:GetBuffIcon(id)
    local config = self._Model:GetRogueSimBuffConfig(id)
    return config and config.Icon or ""
end

-- 获取Buff描述
function XRogueSimBuffSubControl:GetBuffDesc(id)
    local config = self._Model:GetRogueSimBuffConfig(id)
    local desc = config and config.Desc or ""
    return XUiHelper.ReplaceUnicodeSpace(desc)
end

-- 获取Buff参数
function XRogueSimBuffSubControl:GetBuffParams(id)
    local config = self._Model:GetRogueSimBuffConfig(id)
    return config and config.Params or {}
end

-- 获取Buff类型
function XRogueSimBuffSubControl:GetBuffType(id)
    local config = self._Model:GetRogueSimBuffConfig(id)
    return config and config.Type or 0
end

-- 获取buffIds通过来源类型
---@param sourceType number 来源类型
---@return number[] buff自增Id
function XRogueSimBuffSubControl:GetBuffIdsBySourceType(sourceType)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local buffIds = {}
    local buffData = stageData:GetBuffData()
    for _, buff in pairs(buffData) do
        if buff:GetSource() == sourceType then
            table.insert(buffIds, buff:GetId())
        end
    end
    table.sort(buffIds, function(a, b)
        return a > b
    end)
    return buffIds
end

-- 获取战斗界面显示的Buffs
-- 排序 先事件 > 全局波动
function XRogueSimBuffSubControl:GetBattleInterfaceShowBuffs()
    local eventBuffs = self:GetBuffIdsBySourceType(XEnumConst.RogueSim.SourceType.Event)
    local volatilityBuffs = self:GetBuffIdsBySourceType(XEnumConst.RogueSim.SourceType.Volatility)
    return XTool.MergeArray(eventBuffs, volatilityBuffs)
end

-- 获取回合开始显示的Buffs
-- 排序 先事件 > 全局波动
function XRogueSimBuffSubControl:GetRoundStartShowBuffs()
    local eventBuffs = self:GetBuffIdsBySourceType(XEnumConst.RogueSim.SourceType.Event)
    local volatilityBuffs = self:GetBuffIdsBySourceType(XEnumConst.RogueSim.SourceType.Volatility)
    return XTool.MergeArray(eventBuffs, volatilityBuffs)
end

-- 获取buff自增Id列表通过buffId、来源、标识
---@param buffId number buff配置Id
---@param source number 来源
---@param identify number 标识
---@return number[] buff自增Id
function XRogueSimBuffSubControl:GetBuffIdsByBuffIdAndSourceAndIdentify(buffId, source, identify)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local buffIds = {}
    local buffData = stageData:GetBuffData()
    for _, buff in pairs(buffData) do
        if buff:GetBuffId() == buffId and buff:GetSource() == source and buff:GetIdentify() == identify then
            table.insert(buffIds, buff:GetId())
        end
    end
    return buffIds
end

--endregion

--region Effect相关

-- 获取Effect类型
function XRogueSimBuffSubControl:GetEffectType(id)
    local config = self._Model:GetRogueSimEffectConfig(id)
    return config and config.Type or 0
end

-- 获取Effect参数
function XRogueSimBuffSubControl:GetEffectParams(id)
    local config = self._Model:GetRogueSimEffectConfig(id)
    return config and config.Params or {}
end

--endregion

--region Buff加成相关

-- 获取货物实际加成
function XRogueSimBuffSubControl:GetCommodityActualAttr(commodityId, attrType)
    local commodityAdds = self._Model:GetCommodityAddsById(commodityId)
    if not commodityAdds then
        return 0
    end
    return commodityAdds:GetAttr(attrType)
end

-- 获取库存上限加成
function XRogueSimBuffSubControl:GetStockLimitAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.StockLimitAdd)
end

-- 获取波动上限锁定
function XRogueSimBuffSubControl:GetPriceRateLockMax(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceRateLockMax)
end

-- 获取售价基础加成
function XRogueSimBuffSubControl:GetPriceAddBase(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceAddBase)
end

-- 获取售价固定加成
function XRogueSimBuffSubControl:GetPriceAddFixed(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceAddFixed)
end

-- 获取售价比率加成（万分比）
function XRogueSimBuffSubControl:GetPriceAddRatioA(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceAddRatioA)
end

-- 获取售价波动（万分比）
function XRogueSimBuffSubControl:GetPriceAddRatioB(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceAddRatioB)
end

-- 获取售价总波动（万分比）
function XRogueSimBuffSubControl:GetPriceTotalRatio(commodityId)
    local priceRate = 0
    -- 波动上限锁定
    local priceRateLockMax = self:GetPriceRateLockMax(commodityId)
    if priceRateLockMax > 0 then
        priceRate = self._MainControl.ResourceSubControl:GetCommodityMaxPriceRate(commodityId)
        -- 上限锁定的情况下需要加上市场波动上限加成
        priceRate = priceRate + self:GetPriceMaxRateAdd(commodityId)
    else
        priceRate = self._MainControl.ResourceSubControl:GetCommodityPriceRate(commodityId)
    end
    return priceRate + self:GetPriceAddRatioB(commodityId)
end

-- 获取售价暴击率加成
function XRogueSimBuffSubControl:GetPriceCriticalAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceCritAdd)
end

-- 获取售价暴击率总加成
function XRogueSimBuffSubControl:GetPriceTotalCritical(commodityId)
    local priceCritical = self._MainControl.ResourceSubControl:GetCommoditySellCriticalChanceRate(commodityId)
    return priceCritical + self:GetPriceCriticalAdd(commodityId)
end

-- 获取售价暴伤率加成
function XRogueSimBuffSubControl:GetPriceCriticalHurtAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceCritHurtAdd)
end

-- 获取售价暴伤率总加成
function XRogueSimBuffSubControl:GetPriceTotalCriticalHurt(commodityId)
    local priceCriticalHurt = self._MainControl.ResourceSubControl:GetCommoditySellCriticalBonusRate(commodityId)
    return priceCriticalHurt + self:GetPriceCriticalHurtAdd(commodityId)
end

-- 获取市场波动上限加成
function XRogueSimBuffSubControl:GetPriceMaxRateAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceMaxRateAdd)
end

-- 获取市场波动下限加成
function XRogueSimBuffSubControl:GetPriceMinRateAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.PriceMinRateAdd)
end

-- 获取产量基础加成
function XRogueSimBuffSubControl:GetProduceAddBase(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.ProduceAddBase)
end

-- 获取产量固定加成
function XRogueSimBuffSubControl:GetProduceAddFixed(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.ProduceAddFixed)
end

-- 获取产量比率加成（万分比）
function XRogueSimBuffSubControl:GetProduceAddRatioA(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.ProduceAddRatioA)
end

-- 获取产量波动（万分比）
function XRogueSimBuffSubControl:GetProduceAddRatioB(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.ProduceAddRatioB)
end

-- 获取产量暴击率加成
function XRogueSimBuffSubControl:GetProduceCriticalAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.ProduceCritAdd)
end

-- 获取产量暴击率总加成
function XRogueSimBuffSubControl:GetProduceTotalCritical(commodityId)
    local produceCritical = self._MainControl.ResourceSubControl:GetCommodityProduceCriticalChanceRate(commodityId)
    return produceCritical + self:GetProduceCriticalAdd(commodityId)
end

-- 获取产量暴伤率加成
function XRogueSimBuffSubControl:GetProduceCriticalHurtAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, XEnumConst.RogueSim.CommodityAttrType.ProduceCritHurtAdd)
end

-- 获取产量暴伤率总加成
function XRogueSimBuffSubControl:GetProduceTotalCriticalHurt(commodityId)
    local produceCriticalHurt = self._MainControl.ResourceSubControl:GetCommodityProduceCriticalBonusRate(commodityId)
    return produceCriticalHurt + self:GetProduceCriticalHurtAdd(commodityId)
end

--endregion

--region 折扣相关

-- 获取杂项实际加成
function XRogueSimBuffSubControl:GetMiscActualAdd(addType)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetMiscAdd(addType)
end

-- 获取建筑折扣后的价格
function XRogueSimBuffSubControl:GetBuildingDiscountPrice(curPrice)
    -- 获取建筑折扣（万分比）
    local buildingDiscount = self:GetMiscActualAdd(XEnumConst.RogueSim.MiscAdd.BuildingDiscount)
    if not XTool.IsNumberValid(buildingDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * buildingDiscount / 10000)
    return curPrice - discountPrice
end

-- 获取科技点亮折扣后的价格
function XRogueSimBuffSubControl:GetTechDiscountPrice(curPrice)
    -- 获取科技点亮折扣（万分比）
    local techDiscount = self:GetMiscActualAdd(XEnumConst.RogueSim.MiscAdd.TechDiscount)
    if not XTool.IsNumberValid(techDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * techDiscount / 10000)
    return curPrice - discountPrice
end

-- 获取主城升级折扣后的价格
function XRogueSimBuffSubControl:GetMainDiscountPrice(curPrice)
    -- 获取主城升级折扣（万分比）
    local mainDiscount = self:GetMiscActualAdd(XEnumConst.RogueSim.MiscAdd.MainDiscount)
    if not XTool.IsNumberValid(mainDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * mainDiscount / 10000)
    return curPrice - discountPrice
end

-- 获取行动点上限
function XRogueSimBuffSubControl:GetActionPointMiscAddLimit(curActionPoint)
    local limit = self:GetMiscActualAdd(XEnumConst.RogueSim.MiscAdd.ActionPoint)
    if not XTool.IsNumberValid(limit) then
        return curActionPoint
    end
    -- 总上限值最小为0
    return (curActionPoint + limit < 0) and 0 or (curActionPoint + limit)
end

--endregion

--region 累计buff加成相关

-- 根据buffId获取Buff累计加成(百分比)
---@param buffId number buff配置Id
function XRogueSimBuffSubControl:GetBuffCumulativeAdd(buffId, ...)
    local config = self._Model:GetRogueSimBuffConfig(buffId)
    if not config then
        return nil
    end
    local methodName = "CumulativeAdd" .. config.Type
    if not self[methodName] then
        return nil
    end
    return self[methodName](self, config, ...)
end

-- 成长数值每加一定值，则属性加成数值增加
---@param config XTableRogueSimBuff
function XRogueSimBuffSubControl:CumulativeAdd8(config)
    local commodityId = config.Params[2]
    local targetCount = config.Params[3]
    local add = config.Params[5]
    local growthValue = self._MainControl:GetStatisticsValue(XEnumConst.RogueSim.StatisticsType.CommoditySale, commodityId)
    local multiple = math.floor(growthValue / targetCount)
    return multiple > 0 and multiple * add / 100 or 0
end

-- 主城每升1级，货物的某种属性提升一定值
---@param config XTableRogueSimBuff
function XRogueSimBuffSubControl:CumulativeAdd15(config)
    local add = config.Params[3]
    local curMainLevel = self._MainControl:GetCurMainLevel()
    return curMainLevel * add / 100
end

-- 每完成一个城邦任务，货物的某种属性提升一定值
---@param config XTableRogueSimBuff
function XRogueSimBuffSubControl:CumulativeAdd16(config)
    local add = config.Params[3]
    local taskCount = self._MainControl:GetFinishedTaskCount()
    return taskCount * add / 100
end

-- 间隔回合触发效果
---@param config XTableRogueSimBuff
---@param identify number 标识
function XRogueSimBuffSubControl:CumulativeAdd21(config, identify)
    local buffId = config.Params[3]
    -- 只处理类型为7的buff
    if self:GetBuffType(buffId) ~= 7 then
        return nil
    end
    local source = XEnumConst.RogueSim.SourceType.Prop
    local ids = self:GetBuffIdsByBuffIdAndSourceAndIdentify(buffId, source, identify)
    local count = #ids
    local buffParams = self:GetBuffParams(buffId)
    local add = buffParams[3] or 0
    local attrType = buffParams[2] or 0
    -- 库存上限加成不需要显示百分比
    if attrType == XEnumConst.RogueSim.CommodityAttrType.StockLimitAdd then
        return count * add, true
    end
    return count * add / 100
end

--endregion

return XRogueSimBuffSubControl
