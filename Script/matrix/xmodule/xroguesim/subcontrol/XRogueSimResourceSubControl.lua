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

-- 检查资源是否足够
---@param id number 资源Id
---@param count number 需要的资源数量
---@param isShowTips boolean 是否显示提示
function XRogueSimResourceSubControl:CheckResourceIsEnough(id, count, isShowTips)
    local ownCount = self:GetResourceOwnCount(id)
    if ownCount < count then
        if isShowTips then
            local name = self:GetResourceName(id)
            local tip = self._MainControl:GetClientConfig("ResourceNotEnoughTip")
            XUiManager.TipMsg(string.format(tip, name))
        end
        return false
    end
    return true
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

-- 获取货物生产力
---@param id number 货物Id
function XRogueSimResourceSubControl:GetProducePlanCount(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetProducePlanCount(id)
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

-- 获取货物出售预设比例
---@param id number 货物Id
function XRogueSimResourceSubControl:GetSellPlanPresetCount(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetSellPlanPresetCount(id)
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

-- 获取货物价格波动配置Id
---@param id number 货物Id
function XRogueSimResourceSubControl:GetCommodityPriceRateId(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetCommodityPriceRateId(id)
end

-- 获取货物出售的实际数量 TODO 待删除
---@param id number 货物Id
function XRogueSimResourceSubControl:GetSellPlanActualCount(id)
    local ownCount = self:GetCommodityOwnCount(id)
    local sellPlanCount = self:GetSellPlanCount(id)
    return math.min(ownCount, sellPlanCount)
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

-- 获取货物奖励名称
function XRogueSimResourceSubControl:GetCommodityRewardName(id)
    local config = self._Model:GetRogueSimCommodityConfig(id)
    return config and config.RewardName or ""
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
---@param id number 货物Id
---@param population number 人口数量(生产力)
function XRogueSimResourceSubControl:GetCommodityProduction(id, population)
    local configId = self._Model:GetCommodityProductionId(id, population)
    if configId <= 0 then
        return 0
    end
    local config = self._Model:GetRogueSimCommodityProductionConfig(configId)
    return config and config.Production or 0
end

-- 获取货物产量分数
---@param id number 货物Id
---@param population number 人口数量(生产力)
function XRogueSimResourceSubControl:GetCommodityProductionScore(id, population)
    local configId = self._Model:GetCommodityProductionId(id, population)
    if configId <= 0 then
        return 0
    end
    local config = self._Model:GetRogueSimCommodityProductionConfig(configId)
    if XEnumConst.RogueSim.IsDebug and config then
        XLog.Debug(string.format("<color=#F1D116>RogueSim:</color> 货物Id: %s, 产量分数: %s", id, config.Score or 0))
    end
    return config and config.Score or 0
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

-- 获取货物出售价格波动上限
function XRogueSimResourceSubControl:GetCommodityMaxPriceRate(id)
    local config = self._Model:GetRogueSimCommodityPriceRateConfig(id)
    return config and config.MaxPriceRate or 0
end

-- 获取货物总上限值 初始最大值 + Effect效果加成
function XRogueSimResourceSubControl:GetCommodityTotalLimit(id)
    -- 初始最大值
    local maxCount = self:GetCommodityMaxCount(id)
    -- 加成
    local addCount = self._MainControl.BuffSubControl:GetStockLimitAdd(id)
    return maxCount + math.floor(maxCount * addCount / XEnumConst.RogueSim.Denominator)
end

-- 获取进度信息 1 进度值 2 颜色值 3 描述
function XRogueSimResourceSubControl:GetCommodityProgressData(id)
    local count = self:GetCommodityOwnCount(id)
    local limit = self:GetCommodityTotalLimit(id)
    count = count > limit and limit or count
    local progress = count / limit
    -- 警告百分比
    local warningPercent = self:GetCommodityWarningPercent(id)
    local curIndex = 1
    for index, percent in pairs(warningPercent) do
        if progress * XEnumConst.RogueSim.Percentage >= percent then
            curIndex = index
        end
    end
    local color = self:GetCommodityWarningColor(id, curIndex)
    local desc = self:GetCommodityWarningText(id, curIndex)
    return progress, color, desc
end

-- 获取货物出售进度值
function XRogueSimResourceSubControl:GetCommoditySellProgress(id)
    local sellCount = self._MainControl:GetActualCommoditySellCount(id)
    local limitCount = self:GetCommodityTotalLimit(id)
    sellCount = sellCount > limitCount and limitCount or sellCount
    return sellCount / limitCount
end

-- 获取总货物价格 基本价格 * 价格加成 * 波动 注意：不计算货物的特殊属性
function XRogueSimResourceSubControl:GetCommodityTotalPrice(id)
    -- 基础价格 = 配置价格 + 基础价格加成
    local price = self:GetCommodityPrice(id) + self._MainControl.BuffSubControl:GetPriceAddBase(id)
    -- 价格加成
    local priceRate = 1 + self._MainControl.BuffSubControl:GetPriceAddRatioA(id) / XEnumConst.RogueSim.Denominator
    -- 波动
    local fluctuation = 1 + self._MainControl.BuffSubControl:GetPriceTotalRatio(id) / XEnumConst.RogueSim.Denominator
    -- 产量固定加成
    local addFixed = self._MainControl.BuffSubControl:GetPriceAddFixed(id)
    return math.floor((price * priceRate * fluctuation) + XEnumConst.RogueSim.Inaccurate) + addFixed
end

-- 获取总生产效率 基本产量 * 产量加成 注意：不计算货物的特殊属性
---@param id number 货物Id
function XRogueSimResourceSubControl:GetCommodityTotalProduceRate(id)
    -- 分配的人口数量（生产力）
    local population = self._MainControl:GetActualCommodityPopulationCount(id)
    -- 基础per产量 = 配置per产量 + 基础per产量加成
    local produce = self:GetCommodityProduction(id, population) + self._MainControl.BuffSubControl:GetProduceAddBase(id)
    -- 产量加成
    local produceRate = 1 + self._MainControl.BuffSubControl:GetProduceAddRatioA(id) / XEnumConst.RogueSim.Denominator
    -- 波动
    local fluctuation = 1 + self._MainControl.BuffSubControl:GetProduceAddRatioB(id) / XEnumConst.RogueSim.Denominator
    -- 产量固定加成
    local addFixed = self._MainControl.BuffSubControl:GetProduceAddFixed(id)
    return math.floor((produce * produceRate * fluctuation) + XEnumConst.RogueSim.Inaccurate) + addFixed
end

-- 获取出售货物Id(出售货物数量大于0) -- TODO 待删除
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

-- 获取货物评分和背景颜色
---@param commodityId number 货物Id
function XRogueSimResourceSubControl:GetCommodityProduceScoreAndColor(commodityId)
    -- 当前分配的生产力
    local curPopulation = self._MainControl:GetActualCommodityPopulationCount(commodityId)

    local scores = {
        -- 属性评分
        self:GetCommodityAttributeScore(commodityId),
        -- 波动评分
        self:GetCommodityFluctuationScore(commodityId),
        -- 城邦等级评分
        self:GetCityLevelScore(commodityId),
        -- 藏品评分
        self:GetPropScore(commodityId),
        -- 自建建筑评分
        self:GetBuildingScore(commodityId),
        -- 生产力评分
        self:GetCommodityProductionScore(commodityId, curPopulation)
    }

    -- 总评分
    local totalScore = 0
    for _, score in pairs(scores) do
        totalScore = totalScore + score
    end

    return math.floor(totalScore), self:GetCommodityScoreBgColor(totalScore)
end

-- 获取货物属性评分
---@param commodityId number 货物Id
function XRogueSimResourceSubControl:GetCommodityAttributeScore(commodityId)
    local attributeTypes = self._MainControl:GetClientConfigParams("CommodityAttributeType")
    local attributeScores = self._MainControl:GetClientConfigParams("CommodityAttributeScore")
    local totalScore = 0
    for index, attributeType in pairs(attributeTypes) do
        local score = tonumber(attributeScores[index]) or 0
        local value = self._MainControl.BuffSubControl:GetCommodityActualAttr(commodityId, tonumber(attributeType))
        totalScore = totalScore + value / XEnumConst.RogueSim.Percentage * score
        if XEnumConst.RogueSim.IsDebug and score > 0 and value ~= 0 then
            XLog.Debug(string.format("<color=#F1D116>RogueSim:</color> 货物Id: %s, 属性类型: %s, 属性值: %s, 属性评分: %s", commodityId, attributeType, value, value / XEnumConst.RogueSim.Percentage * score))
        end
    end
    return totalScore
end

-- 获取货物波动评分
---@param commodityId number 货物Id
function XRogueSimResourceSubControl:GetCommodityFluctuationScore(commodityId)
    local totalRatio = self._MainControl.BuffSubControl:GetPriceTotalRatio(commodityId)
    local score = self._MainControl:GetClientConfig("CommodityFluctuationScore")
    score = tonumber(score) or 0
    if XEnumConst.RogueSim.IsDebug and score > 0 and totalRatio ~= 0 then
        XLog.Debug(string.format("<color=#F1D116>RogueSim:</color> 货物Id: %s, 波动评分: %s", commodityId, totalRatio / XEnumConst.RogueSim.Percentage * score))
    end
    return totalRatio / XEnumConst.RogueSim.Percentage * score
end

-- 获取城邦等级评分
---@param commodityId number 货物Id
function XRogueSimResourceSubControl:GetCityLevelScore(commodityId)
    local cityData = self._MainControl.MapSubControl:GetCityData()
    local totalScore = 0
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            local cityLevelConfigId = self._MainControl.MapSubControl:GetCityLevelConfigIdById(data:GetId(), data:GetLevel())
            local score = self._MainControl.MapSubControl:GetCityLevelActualScore(cityLevelConfigId, commodityId)
            totalScore = totalScore + score
        end
    end
    if XEnumConst.RogueSim.IsDebug and totalScore > 0 then
        XLog.Debug(string.format("<color=#F1D116>RogueSim:</color> 货物Id: %s, 城邦等级评分: %s", commodityId, totalScore))
    end
    return totalScore
end

-- 获取藏品评分
---@param commodityId number 货物Id
function XRogueSimResourceSubControl:GetPropScore(commodityId)
    local propInfo = self._MainControl.MapSubControl:GetOwnPropInfo()
    local totalScore = 0
    for _, info in pairs(propInfo) do
        local score = self._MainControl.MapSubControl:GetPropActualScore(info.PropId, commodityId)
        totalScore = totalScore + score
    end
    if XEnumConst.RogueSim.IsDebug and totalScore > 0 then
        XLog.Debug(string.format("<color=#F1D116>RogueSim:</color> 货物Id: %s, 藏品评分: %s", commodityId, totalScore))
    end
    return totalScore
end

-- 获取自建建筑评分
---@param commodityId number 货物Id
function XRogueSimResourceSubControl:GetBuildingScore(commodityId)
    local buildingData = self._MainControl.MapSubControl:GetBuildingData()
    local totalScore = 0
    for _, data in pairs(buildingData) do
        if data:GetIsBuildByBluePrint() then
            local score = self._MainControl.MapSubControl:GetBuildingActualScore(data:GetConfigId(), commodityId)
            totalScore = totalScore + score
        end
    end
    if XEnumConst.RogueSim.IsDebug and totalScore > 0 then
        XLog.Debug(string.format("<color=#F1D116>RogueSim:</color> 货物Id: %s, 自建建筑评分: %s", commodityId, totalScore))
    end
    return totalScore
end

-- 获取货物分数背景颜色
---@param score number 分数
function XRogueSimResourceSubControl:GetCommodityScoreBgColor(score)
    local intervals = {
        self._MainControl:GetClientConfigParams("CommodityScoreInterval1"),
        self._MainControl:GetClientConfigParams("CommodityScoreInterval2"),
        self._MainControl:GetClientConfigParams("CommodityScoreInterval3")
    }
    local colors = {
        XUiHelper.Hexcolor2Color(intervals[1][3]),
        XUiHelper.Hexcolor2Color(intervals[2][3]),
        XUiHelper.Hexcolor2Color(intervals[3][3])
    }
    for i, interval in ipairs(intervals) do
        if score >= tonumber(interval[1]) and (i == #intervals or score < tonumber(interval[2])) then
            return colors[i]
        end
    end
    return colors[1]
end

-- 获取货物实际数量 已拥有的 - 待出售的
function XRogueSimResourceSubControl:GetCommodityActualCount(id)
    local ownCount = self:GetCommodityOwnCount(id)
    local sellCount = self._MainControl:GetActualCommoditySellCount(id)
    local count = ownCount - sellCount
    return math.max(count, 0)
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

-- 检测拥有的货物数量是否已达上限
function XRogueSimResourceSubControl:CheckCommodityOwnIsFull(id)
    local ownCount = self:GetCommodityOwnCount(id)
    local limitCount = self:GetCommodityTotalLimit(id)
    return ownCount >= limitCount
end

-- 检测实际出售信息是否有变动 -- TODO 待删除
function XRogueSimResourceSubControl:CheckActualSellCountIsChange(info)
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local count = info[id] or 0
        if count ~= self:GetSellPlanCount(id) then
            return true
        end
    end
    return false
end

-- 检查货物是否已满通过地形Id
---@field landformId number 地形Id
---@return boolean, number 是否已满, 货物Id
function XRogueSimResourceSubControl:CheckCommodityIsFullByLandformId(landformId)
    for _, commodityId in pairs(XEnumConst.RogueSim.CommodityIds) do
        local landformIds = self._MainControl:GetClientConfigParams(string.format("LandformIdsCommodity%s", commodityId))
        for _, id in pairs(landformIds) do
            if tonumber(id) == landformId and self:CheckCommodityOwnIsFull(commodityId) then
                return true, commodityId
            end
        end
    end
    return false, 0
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

-- 获取气泡参数名称列表
function XRogueSimResourceSubControl:GetCommodityBubbleParamNames(id)
    local config = self._Model:GetCommodityBubbleConfig(id)
    return config and config.ParamNames or {}
end

-- 货物基础价格
function XRogueSimResourceSubControl:GetCommodityPriceBubble(id)
    return self:GetCommodityPrice(id) + self._MainControl.BuffSubControl:GetPriceAddBase(id)
end

-- 货物价格加成
function XRogueSimResourceSubControl:GetCommodityPriceAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceAddRatioA(id) / XEnumConst.RogueSim.Percentage
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物价格波动
function XRogueSimResourceSubControl:GetCommodityPriceFluctuationBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceTotalRatio(id) / XEnumConst.RogueSim.Percentage
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物价格固定加成
function XRogueSimResourceSubControl:GetCommodityPriceAddFixedBubble(id)
    return self._MainControl.BuffSubControl:GetPriceAddFixed(id)
end

-- 货物价格暴击率
function XRogueSimResourceSubControl:GetCommodityPriceCritAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceTotalCritical(id) / XEnumConst.RogueSim.Percentage
    -- 价格暴击率最小值为0
    value = value < 0 and 0 or value
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物价格暴击伤害
function XRogueSimResourceSubControl:GetCommodityPriceCritHurtAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetPriceTotalCriticalHurt(id) / XEnumConst.RogueSim.Percentage
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量
function XRogueSimResourceSubControl:GetCommodityProductionBubble(id)
    local population = self._MainControl:GetActualCommodityPopulationCount(id)
    return self:GetCommodityProduction(id, population) + self._MainControl.BuffSubControl:GetProduceAddBase(id)
end

-- 货物产量加成
function XRogueSimResourceSubControl:GetCommodityProductionAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceAddRatioA(id) / XEnumConst.RogueSim.Percentage
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量波动
function XRogueSimResourceSubControl:GetCommodityProductionFluctuationBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceAddRatioB(id) / XEnumConst.RogueSim.Percentage
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量暴击率
function XRogueSimResourceSubControl:GetCommodityProductionCritAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceTotalCritical(id) / XEnumConst.RogueSim.Percentage
    -- 产量暴击率最小值为0
    value = value < 0 and 0 or value
    return self:ConvertNumberToIntegerWithSuffix(value)
end

-- 货物产量暴击伤害
function XRogueSimResourceSubControl:GetCommodityProductionCritHurtAddBubble(id)
    local value = self._MainControl.BuffSubControl:GetProduceTotalCriticalHurt(id) / XEnumConst.RogueSim.Percentage
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

--region 临时背包数据

-- 获取是否正在进行临时背包奖励请求
function XRogueSimResourceSubControl:GetIsTempBagReward()
    return self._Model.IsTempBagReward or false
end

-- 获取临时背包数据
function XRogueSimResourceSubControl:GetTemporaryBagData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetTemporaryBagData()
end

-- 获取临时背包数据通过Id
function XRogueSimResourceSubControl:GetTemporaryBagDataById(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetTemporaryBagDataById(id)
end

-- 获取临时背包货物数量通过Id
function XRogueSimResourceSubControl:GetTemporaryBagCommodityCountById(id)
    local data = self:GetTemporaryBagDataById(id)
    return data and data:GetCount() or 0
end

-- 获取临时背包所有货物Id
function XRogueSimResourceSubControl:GetTemporaryBagCommodityIds()
    local temporaryBagData = self:GetTemporaryBagData()
    if not temporaryBagData then
        return {}
    end
    local commodityIds = {}
    for _, data in pairs(temporaryBagData) do
        if data:GetCount() > 0 then
            table.insert(commodityIds, data:GetId())
        end
    end
    return commodityIds
end

-- 获取临时背包RewardDropId列表长度
function XRogueSimResourceSubControl:GetTemporaryBagRewardDropIdCount()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    local rewardDropIds = stageData:GetTemporaryBagRewardDropIds()
    return table.nums(rewardDropIds)
end

--endregion

return XRogueSimResourceSubControl
