--  Buff控制器 包括 Effect系统
---@class XRogueSimBuffSubControl : XControl
---@field private _Model XRogueSimModel
---@field _MainControl XRogueSimControl
local XRogueSimBuffSubControl = XClass(XControl, "XRogueSimBuffSubControl")
function XRogueSimBuffSubControl:OnInit()
    --初始化内部变量
    -- 累计加成类型
    self.CumulativeAddType = {
        Percentage = 1,  -- 百分比
        Fixed = 2,       -- 固定值
        Effective = 3,   -- 有效
        Ineffective = 4, -- 无效
    }
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

-- 获取所有Buff数据
function XRogueSimBuffSubControl:GetAllBuffData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    return stageData:GetBuffData()
end

-- 获取buffIds通过来源类型
---@param sourceType number 来源类型
---@return number[] buff自增Id
function XRogueSimBuffSubControl:GetBuffIdsBySourceType(sourceType)
    local buffIds = {}
    local buffData = self:GetAllBuffData()
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
    local buffIds = {}
    local buffData = self:GetAllBuffData()
    for _, buff in pairs(buffData) do
        if buff:GetBuffId() == buffId and buff:GetSource() == source and buff:GetIdentify() == identify then
            table.insert(buffIds, buff:GetId())
        end
    end
    return buffIds
end

-- 获取buff创建回合数通过buffId、来源、标识
---@param buffId number buff配置Id
---@param source number 来源
---@param identify number 标识
function XRogueSimBuffSubControl:GetBuffCreateTurnByBuffIdAndSourceAndIdentify(buffId, source, identify)
    local buffIds = self:GetBuffIdsByBuffIdAndSourceAndIdentify(buffId, source, identify)
    if XTool.IsTableEmpty(buffIds) then
        return 0
    end
    local buffData = self._Model:GetBuffDataById(buffIds[1])
    return buffData and buffData:GetCreateTurn() or 0
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
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.StockLimitAdd)
end

-- 获取波动上限锁定
function XRogueSimBuffSubControl:GetPriceRateLockMax(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceRateLockMax)
end

-- 获取售价基础加成
function XRogueSimBuffSubControl:GetPriceAddBase(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceAddBase)
end

-- 获取售价固定加成
function XRogueSimBuffSubControl:GetPriceAddFixed(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceAddFixed)
end

-- 获取售价比率加成（万分比）
function XRogueSimBuffSubControl:GetPriceAddRatioA(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceAddRatioA)
end

-- 获取售价波动（万分比）
function XRogueSimBuffSubControl:GetPriceAddRatioB(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceAddRatioB)
end

-- 获取售价总波动（万分比）
function XRogueSimBuffSubControl:GetPriceTotalRatio(commodityId)
    local priceRate = 0
    -- 波动上限锁定
    local priceRateLockMax = self:GetPriceRateLockMax(commodityId)
    if priceRateLockMax > 0 then
        -- 随机上限
        local priceRateConfigId = self._MainControl.ResourceSubControl:GetCommodityPriceRateId(commodityId)
        if priceRateConfigId > 0 then
            -- 直接读取配置表上限
            priceRate = self._MainControl.ResourceSubControl:GetCommodityMaxPriceRate(priceRateConfigId)
        end
        -- 上限锁定的情况下需要加上市场波动上限加成
        priceRate = priceRate + self:GetPriceMaxRateAdd(commodityId)
    else
        priceRate = self._MainControl.ResourceSubControl:GetCommodityPriceRate(commodityId)
    end
    return priceRate + self:GetPriceAddRatioB(commodityId)
end

-- 获取售价暴击率加成
function XRogueSimBuffSubControl:GetPriceCriticalAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceCritAdd)
end

-- 获取售价暴击率总加成
function XRogueSimBuffSubControl:GetPriceTotalCritical(commodityId)
    local priceCritical = self._MainControl.ResourceSubControl:GetCommoditySellCriticalChanceRate(commodityId)
    return priceCritical + self:GetPriceCriticalAdd(commodityId)
end

-- 获取售价暴伤率加成
function XRogueSimBuffSubControl:GetPriceCriticalHurtAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceCritHurtAdd)
end

-- 获取售价暴伤率总加成
function XRogueSimBuffSubControl:GetPriceTotalCriticalHurt(commodityId)
    local priceCriticalHurt = self._MainControl.ResourceSubControl:GetCommoditySellCriticalBonusRate(commodityId)
    return priceCriticalHurt + self:GetPriceCriticalHurtAdd(commodityId)
end

-- 获取市场波动上限加成
function XRogueSimBuffSubControl:GetPriceMaxRateAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceMaxRateAdd)
end

-- 获取市场波动下限加成
function XRogueSimBuffSubControl:GetPriceMinRateAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.PriceMinRateAdd)
end

-- 获取产量基础加成
function XRogueSimBuffSubControl:GetProduceAddBase(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.ProduceAddBase)
end

-- 获取产量固定加成
function XRogueSimBuffSubControl:GetProduceAddFixed(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.ProduceAddFixed)
end

-- 获取产量比率加成（万分比）
function XRogueSimBuffSubControl:GetProduceAddRatioA(commodityId)
    -- 产量比率加成A
    local produceAddRatioA = self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.ProduceAddRatioA)
    -- 产量比率加成A_SP
    local produceAddRatioASp = self:GetProduceAddRatioASp(commodityId)
    -- 循环生产/销售效果加成
    local loopSellOrProduceRatio = self:GetLoopSellOrProduceRatio(commodityId, self._Model.CommodityAttrType.ProduceAddRatioA)
    return produceAddRatioA + produceAddRatioASp + loopSellOrProduceRatio
end

-- 获取产量比率加成（万分比）SP
function XRogueSimBuffSubControl:GetProduceAddRatioASp(commodityId)
    local populationCount = self._MainControl:GetCommodityPopulationCount()
    if populationCount <= 0 then
        return 0
    end
    local attrType = self._Model.CommodityAttrType.ProduceAddRatioASpStart + populationCount
    return self:GetCommodityActualAttr(commodityId, attrType)
end

-- 获取循环生产/销售效果加成（万分比）
---@param commodityId number 货物Id
---@param attrType number 属性类型
function XRogueSimBuffSubControl:GetLoopSellOrProduceRatio(commodityId, attrType)
    if not self._MainControl:CheckIsLoopSellOrProduceEffect(commodityId) then
        return 0
    end
    local type = self._Model.CommodityAttrType.LoopSellOrProduceEffectStart + attrType
    return self:GetCommodityActualAttr(commodityId, type)
end

-- 获取产量波动（万分比）
function XRogueSimBuffSubControl:GetProduceAddRatioB(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.ProduceAddRatioB)
end

-- 获取产量暴击率加成
function XRogueSimBuffSubControl:GetProduceCriticalAdd(commodityId)
    -- 产量暴击率加成
    local produceCriticalAdd = self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.ProduceCritAdd)
    -- 循环生产/销售效果加成
    local loopSellOrProduceRatio = self:GetLoopSellOrProduceRatio(commodityId, self._Model.CommodityAttrType.ProduceCritAdd)
    return produceCriticalAdd + loopSellOrProduceRatio
end

-- 获取产量暴击率总加成
function XRogueSimBuffSubControl:GetProduceTotalCritical(commodityId)
    local produceCritical = self._MainControl.ResourceSubControl:GetCommodityProduceCriticalChanceRate(commodityId)
    return produceCritical + self:GetProduceCriticalAdd(commodityId)
end

-- 获取产量暴伤率加成
function XRogueSimBuffSubControl:GetProduceCriticalHurtAdd(commodityId)
    return self:GetCommodityActualAttr(commodityId, self._Model.CommodityAttrType.ProduceCritHurtAdd)
end

-- 获取产量暴伤率总加成
function XRogueSimBuffSubControl:GetProduceTotalCriticalHurt(commodityId)
    local produceCriticalHurt = self._MainControl.ResourceSubControl:GetCommodityProduceCriticalBonusRate(commodityId)
    return produceCriticalHurt + self:GetProduceCriticalHurtAdd(commodityId)
end

--endregion

--region 折扣相关

-- 获取杂项实际加成
---@param miscAddType number 杂项加成类型
function XRogueSimBuffSubControl:GetMiscActualValue(miscAddType)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetMiscAdd(miscAddType)
end

-- 获取区域杂项实际加成
---@param areaId number 区域Id
---@param miscAddType number 杂项加成类型
function XRogueSimBuffSubControl:GetAreaMiscActualValue(areaId, miscAddType)
    return self:GetMiscActualValue(miscAddType) + self:GetMiscActualValue(miscAddType + areaId)
end

-- 获取建筑折扣后的价格
---@param buildingId number 建筑Id
---@param curPrice number 当前价格
function XRogueSimBuffSubControl:GetBuildingDiscountPrice(buildingId, curPrice)
    -- 获取建筑折扣（万分比）
    local buildingDiscount = self:GetMiscActualValue(self._Model.MiscAdd.BuildingDiscount) +
        self:GetAreaMiscActualValue(buildingId, self._Model.MiscAdd.BuyBuildingDiscount)
    if not XTool.IsNumberValid(buildingDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * buildingDiscount / XEnumConst.RogueSim.Denominator)
    curPrice = math.max(curPrice - discountPrice, 0)
    return curPrice
end

-- 获取科技点亮折扣后的价格
---@param curPrice number 当前价格
function XRogueSimBuffSubControl:GetTechDiscountPrice(curPrice)
    -- 获取科技点亮折扣（万分比）
    local techDiscount = self:GetMiscActualValue(self._Model.MiscAdd.TechDiscount)
    if not XTool.IsNumberValid(techDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * techDiscount / XEnumConst.RogueSim.Denominator)
    curPrice = math.max(curPrice - discountPrice, 0)
    return curPrice
end

-- 获取主城升级折扣后的价格
---@param curPrice number 当前价格
function XRogueSimBuffSubControl:GetMainDiscountPrice(curPrice)
    -- 获取主城升级折扣（万分比）
    local mainDiscount = self:GetMiscActualValue(self._Model.MiscAdd.MainDiscount)
    if not XTool.IsNumberValid(mainDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * mainDiscount / XEnumConst.RogueSim.Denominator)
    curPrice = math.max(curPrice - discountPrice, 0)
    return curPrice
end

-- 获取区域折扣后的价格
---@param areaId number 区域Id
---@param curPrice number 当前价格
function XRogueSimBuffSubControl:GetAreaDiscountPrice(areaId, curPrice)
    -- 获取区域折扣（万分比）
    local areaDiscount = self:GetAreaMiscActualValue(areaId, self._Model.MiscAdd.BuyAreaDiscount)
    if not XTool.IsNumberValid(areaDiscount) then
        return curPrice
    end
    local discountPrice = math.floor(curPrice * areaDiscount / XEnumConst.RogueSim.Denominator)
    curPrice = math.max(curPrice - discountPrice, 0)
    return curPrice
end

-- 获取建筑产出的数量
---@param buildingId number 建筑Id
---@param curCount number 当前数量
function XRogueSimBuffSubControl:GetBuildingOutputCount(buildingId, curCount)
    local buildingType = self._MainControl.MapSubControl:GetBuildingType(buildingId)
    if buildingType ~= self._Model.BuildingType.RefreshReward then
        return curCount
    end
    local refreshRewardGroupId = self._MainControl.MapSubControl:GetBuildingRefreshRewardGroupId(buildingId)
    if XTool.IsNumberValid(refreshRewardGroupId) then
        local addRate = self:GetMiscActualValue(self._Model.MiscAdd.BuildingRefreshRewardRateAdd)
        local addFix = self:GetMiscActualValue(self._Model.MiscAdd.BuildingRefreshRewardFixAdd)
        return math.floor(curCount * (1 + addRate / XEnumConst.RogueSim.Denominator) + addFix)
    end
    return curCount
end

--endregion

--region 累计buff加成相关

-- 获取道具Buff累计加成描述
---@param buffId number buff配置Id
---@param identify number 标识
function XRogueSimBuffSubControl:GetPropBuffCumulativeAddDesc(buffId, identify)
    local source = XEnumConst.RogueSim.SourceType.Prop
    local cumulativeAdd, cumulativeType = self:GetBuffCumulativeAdd(buffId, source, identify)
    if not cumulativeAdd then
        return ""
    end
    cumulativeType = cumulativeType or self.CumulativeAddType.Percentage
    local addDesc = self._MainControl:GetClientConfig("PropBuffCumulativeMarkupTip", cumulativeType)
    return string.format(addDesc, cumulativeAdd)
end

-- 根据buffId获取Buff累计加成
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
    local statisticsType = config.Params[1]
    local commodityId = config.Params[2]
    local targetCount = config.Params[3]
    local add = config.Params[5]
    local upLimit = config.Params[6]
    local growthValue = self._MainControl:GetStatisticsValue(statisticsType, commodityId)
    local multiple = math.min(math.floor(growthValue / targetCount), upLimit)
    return multiple > 0 and multiple * add / XEnumConst.RogueSim.Percentage or 0
end

-- 主城每升1级，货物的某种属性提升一定值
---@param config XTableRogueSimBuff
function XRogueSimBuffSubControl:CumulativeAdd15(config)
    local add = config.Params[3]
    local curMainLevel = self._MainControl:GetCurMainLevel()
    return curMainLevel * add / XEnumConst.RogueSim.Percentage
end

-- 每完成一个城邦任务，货物的某种属性提升一定值
---@param config XTableRogueSimBuff
function XRogueSimBuffSubControl:CumulativeAdd16(config)
    local add = config.Params[3]
    local taskCount = self._MainControl:GetFinishedTaskCount()
    return taskCount * add / XEnumConst.RogueSim.Percentage
end

-- 间隔回合触发效果
---@param config XTableRogueSimBuff
---@param source number 来源
---@param identify number 标识
function XRogueSimBuffSubControl:CumulativeAdd21(config, source, identify)
    local buffId = config.Params[3]
    -- 只处理类型为7的buff
    if self:GetBuffType(buffId) ~= 7 then
        return nil
    end
    local ids = self:GetBuffIdsByBuffIdAndSourceAndIdentify(buffId, source, identify)
    local count = #ids
    local buffParams = self:GetBuffParams(buffId)
    local add = buffParams[3] or 0
    return count * add / XEnumConst.RogueSim.Percentage
end

-- 获得所有城邦总星级数*X的属性加成
---@param config XTableRogueSimBuff
function XRogueSimBuffSubControl:CumulativeAdd26(config)
    local add = config.Params[2]
    local totalLevel = self._MainControl.MapSubControl:GetAllCityTotalLevel()
    return totalLevel * add / XEnumConst.RogueSim.Percentage
end

-- 间隔固定回合后，下回合所有商品的单价波动加成获得百分比加成
---@param config XTableRogueSimBuff
---@param source number 来源
---@param identify number 标识
function XRogueSimBuffSubControl:CumulativeAdd27(config, source, identify)
    local interval = config.Params[1]
    local curTurnNumber = self._MainControl:GetCurTurnNumber()
    local buffCreateTurn = self:GetBuffCreateTurnByBuffIdAndSourceAndIdentify(config.Id, source, identify)
    local overTurn = curTurnNumber - buffCreateTurn
    if overTurn % (interval + 1) == 0 then
        return 0, self.CumulativeAddType.Effective
    end
    return 0, self.CumulativeAddType.Ineffective
end

-- 【城邦/主城】获得已建造建筑数量×配置系数的属性加成
---@param config XTableRogueSimBuff
---@param source number 来源
---@param identify number 标识
function XRogueSimBuffSubControl:CumulativeAdd28(config, source, identify)
    local areaType = config.Params[1]
    local buildId = config.Params[2]
    local add = config.Params[3]
    local targetAreaId = 0
    if areaType == self._Model.ObtainBuildingAreaType.OwnerArea then
        local gridId = (source == XEnumConst.RogueSim.SourceType.City) and identify or self._MainControl:GetMainGridId()
        targetAreaId = self._MainControl:GetAreaIdByGridId(gridId)
    end
    local buildingCount = self._MainControl.MapSubControl:GetBuildingsCountByAreaId(areaType, targetAreaId, buildId)
    return buildingCount * add / XEnumConst.RogueSim.Percentage
end

--endregion

return XRogueSimBuffSubControl
