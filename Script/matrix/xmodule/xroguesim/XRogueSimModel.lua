--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local RogueSimTableKey = {
    RogueSimActivity = { CacheType = XConfigUtil.CacheType.Normal },
    RogueSimIllustrate = {},
    RogueSimStage = { CacheType = XConfigUtil.CacheType.Normal },
    RogueSimResource = {},
    RogueSimCommodity = {},
    RogueSimCommodityProduction = {},
    RogueSimCommodityPriceRate = {},
    RogueSimMainLevel = {},
    RogueSimCityLevel = {},
    RogueSimBuff = {},
    RogueSimBuilding = {},
    RogueSimBuildingBluePrint = {},
    RogueSimEvent = {},
    RogueSimEventOption = {},
    RogueSimProp = {},
    RogueSimReward = {},
    RogueSimRewardDrop = {},
    RogueSimTech = {},
    RogueSimTechLevel = {},
    RogueSimTip = {},
    RogueSimTask = {},
    RogueSimToken = {},
    RogueSimVolatility = {},
    RogueSimCondition = {},
    RogueSimEffect = {},
    RogueSimLoadingTips = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimCommodityBubble = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimCommodityBubbleGroup = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimPropRare = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimPropShowLabel = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimScoreTitle = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimClientConfig =
    {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key"
    },
}
local RogueSimMapTableKey = {
    RogueSimArea = {},
    RogueSimLandform = {},
    RogueSimTerrain = {},
}

---@class XRogueSimModel : XModel
---@field ActivityData XRogueSimActivity
local XRogueSimModel = XClass(XModel, "XRogueSimModel")
function XRogueSimModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:InitEnumConst()

    self._ConfigUtil:InitConfigByTableKey("RogueSim", RogueSimTableKey)
    self._ConfigUtil:InitConfigByTableKey("RogueSim/RogueSimMap", RogueSimMapTableKey)

    -- 区域格子文件夹内的配置表
    self.RogueSimAreaGridTableKey = {}
    local paths = CS.XTableManager.GetPaths("Share/RogueSim/RogueSimMap/RogueSimAreaGrid")
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        self.RogueSimAreaGridTableKey[key] = { TableDefindName = "XTableRogueSimAreaGrid" }
    end)
    self._ConfigUtil:InitConfigByTableKey("RogueSim/RogueSimMap/RogueSimAreaGrid", self.RogueSimAreaGridTableKey)

    -- 是否初始化主城等级
    self.IsInitMainLevel = false
    -- 组对应着主城等级配置Id列表 key是组Id value是Id列表
    self.levelGroupToMainLevelIdList = {}
    -- 组对应着最大等级 key是组Id value是等级
    self.levelGroupToMaxMainLevel = {}
    -- 组和等级对应着主城等级配置Id key1是组Id key2是level value是配置Id
    self.levelGroupAndLevelToMainLevelId = {}

    -- 是否初始化城邦等级
    self.IsInitCityLevel = false
    -- 等级组和城邦Id对应城邦等级配置Id列表
    self.levelGroupAndCityIdToCityLevelIdList = {}
    -- 等级组和城邦Id对应最大等级
    self.levelGroupAndCityIdToMaxCityLevel = {}
    -- 等级组和城邦Id和等级对应城邦等级配置Id
    self.levelGroupAndCityIdAndLevelToCityLevelId = {}

    -- 是否初始化货物生产配置
    self.IsInitCommodityProduction = false
    -- 货物Id和生产力(人口)对应配置Id
    self.CommodityIdAndPopulationToConfigId = {}

    -- 是否是正在进行回合结束(回合结束时会有事件奖励掉落，该奖励不需要入队奖励弹框的)
    self.IsRoundEnd = false
    -- 弹框数据
    self.PopupData = nil
    -- 下一个目标弹框类型
    self.NextTargetPopupType = nil

    -- 回合结算信息
    ---@type XRogueSimTurnSettleData
    self.TurnSettleData = nil
    -- 关卡结算信息
    ---@type XRogueSimStageSettleData
    self.StageSettleData = nil
    -- 临时生产和销售数据
    ---@type XRogueSimTempProduceAndSellData
    self.TempProduceAndSellData = nil

    -- 是否正在进行临时背包奖励请求
    self.IsTempBagReward = false

    -- 跳过货物已满确认提示
    self.IsSkipCommodityFullConfirmTips = false
    -- 跳过有可购买区域确认提示
    self.IsSkipBuyAreaConfirmTips = false
    -- 跳过有可探索格子确认提示
    self.IsSkipExploreGridConfirmTips = false
end

function XRogueSimModel:ClearPrivate()
    --这里执行内部数据清理
    self.IsRoundEnd = false
    self:ClearAllPopupData()
    self.TurnSettleData = nil
    self.StageSettleData = nil
    self.TempProduceAndSellData = nil
    self.IsTempBagReward = false
end

function XRogueSimModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self.IsRoundEnd = false
    self:ClearAllPopupData()
    self.TurnSettleData = nil
    self.StageSettleData = nil
    self.TempProduceAndSellData = nil
    self.IsTempBagReward = false
    self.IsSkipCommodityFullConfirmTips = false
    self.IsSkipBuyAreaConfirmTips = false
    self.IsSkipExploreGridConfirmTips = false
end

--region 枚举定义

function XRogueSimModel:InitEnumConst()
    self.StageType = {
        Teach = 1,  -- 教学关
        Normal = 2, -- 普通关
    }
    -- 统计类型
    self.StatisticsType = {
        CommoditySale = 1,    -- 商品销售统计
        CommodityProduce = 2, -- 商品生产统计
        EventTrigger = 3,     -- 事件触发
        GoldAdd = 4,          -- 金币增加统计
        GoldInTurnAdd = 5,    -- 回合内金币增加统计
        ExpAdd = 6,           -- 经验增加统计
    }
    -- 任务状态
    self.TaskState = {
        Activated = 1,
        Achieved = 2,
        Finished = 3,
    }
    -- 杂项加成
    self.MiscAdd = {
        BuildingDiscount = 1,              -- 建筑折扣
        TechDiscount = 2,                  -- 科技点亮折扣
        MainDiscount = 3,                  -- 主城升级折扣
        ExploreExpFixAdd = 4,              -- 繁荣度获取效率提升（固定值）
        ExploreExpRateAdd = 5,             -- 繁荣度获取效率提升（万分比）
        ActionPoint = 6,                   -- 行动点上限 （已废弃）
        ExploreGoldFixAdd = 7,             -- 探索金币获取效率提升（固定值）
        ExploreGoldRateAdd = 8,            -- 探索金币获取效率提升（万分比）
        BuildingGoldRateAdd = 9,           -- 建筑金币获取效率提升（万分比）

        BuildingRefreshRewardFixAdd = 18,  -- 建筑类型【XRogueSimBuildingType.RefreshReward】获取Reward效率提升（固定值）
        BuildingRefreshRewardRateAdd = 19, -- 建筑类型【XRogueSimBuildingType.RefreshReward】获取取Reward效率提升（万分比值）

        BuyAreaDiscount = 100000,          -- 全局购买区域折扣
        BuyAreaDiscountEnd = 199999,       -- 区域单独购买折扣结束

        BuyBuildingDiscount = 200000,      -- 全局建造建筑折扣
        BuyBuildingDiscountEnd = 299999,   -- 区域单独建造建筑折扣结束
    }
    -- 资源属性类型
    self.CommodityAttrType = {
        Stock = 0,                -- 库存
        StockLimit = 1,           -- 库存上限
        StockLimitAdd = 2,        -- 库存上限加成
        PriceRateLockMax = 3,     -- 波动上限锁定
        PriceRateLockMin = 4,     -- 波动下限锁定
        StockTurnFixAdd = 5,      -- 库存回合开始时固定增减属性
        StockTurnRatioAdd = 6,    -- 库存回合开始时比率增减属性

        Price = 100,              -- 结算售价
        PriceBase = 101,          -- 基础售价
        PriceCrit = 102,          -- 售价暴击率
        PriceCritHurt = 103,      -- 售价暴伤率

        Produce = 200,            -- 结算产量
        ProduceBase = 201,        -- 基础产量
        ProduceCrit = 202,        -- 产量暴击率
        ProduceCritHurt = 203,    -- 产量暴伤率

        PriceAddBase = 1001,      -- 售价基础加成
        PriceAddFixed = 1002,     -- 售价固定加成
        PriceAddRatioA = 1003,    -- 售价比率加成
        PriceAddRatioB = 1004,    -- 售价波动（2级比率加成）
        PriceCritAdd = 1005,      -- 售价暴击率加成
        PriceCritHurtAdd = 1006,  -- 售价暴伤率加成
        PriceMaxRateAdd = 1007,   -- 市场波动上限加成
        PriceMinRateAdd = 1008,   -- 市场波动下限加成
        PriceMaxRateFix = 1009,   -- 市场波动上限固定
        PriceMinRateFix = 1010,   -- 市场波动下限固定
        PriceRateAddition = 1011, -- 市场波动放大加成

        ProduceAddBase = 2001,    -- 产量基础加成
        ProduceAddFixed = 2002,   -- 产量固定加成
        ProduceAddRatioA = 2003,  -- 产量比率加成
        ProduceAddRatioB = 2004,  -- 产量波动（2级比率加成） 预留
        ProduceCritAdd = 2005,    -- 产量暴击率加成
        ProduceCritHurtAdd = 2006,-- 产量暴伤率加成
        -- 产量比率加成，效果与2003一样，专门给BUFF类型25用
        ProduceAddRatioASpStart = 10000,
        ProduceAddRatioASpEnd = 10010,
        -- 循环生产/销售效果，专门给BUFF类型32用
        LoopSellOrProduceEffectStart = 20000,
        LoopSellOrProduceEffectEnd = 29999,
    }
    -- 条件操作类型
    self.ConditionOperateType = {
        None = 0,
        Greater = 1,      -- 大于
        GreaterEqual = 2, -- 大于等于
        Equal = 3,        -- 等于
        LessEqual = 4,    -- 小于等于
        Less = 5,         -- 小于
    }
    -- 效果类型
    self.EffectType = {
        Type1 = 1,   -- 修改指定数量的指定货物
        Type15 = 15, -- 修改指定数量的指定资源
        Type16 = 16, -- 建筑蓝图补货
    }
    self.ObtainBuildingAreaType = {
        AllArea = 1,   -- 全区域
        OwnerArea = 2, -- 指定区域计算
    }
    -- 建筑类型
    self.BuildingType = {
        Normal = 1,        -- 普通建筑
        RefreshEvent = 2,  -- 刷新事件
        RefreshReward = 3, -- 刷新奖励
    }
end

--endregion

--region 服务端信息更新和获取

function XRogueSimModel:NotifyRogueSimData(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XRogueSim/XEntity/XRogueSimActivity").New()
    end
    self.ActivityData:NotifyRogueSimData(data)
end

-- 获取关卡数据
---@return XRogueSimStage
function XRogueSimModel:GetStageData()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStageData()
end

-- 获取关卡记录数据
function XRogueSimModel:GetStageRecord(stageId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStageRecord(stageId)
end

-- 获取地图数据
function XRogueSimModel:GetMapData()
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetMapData()
end

-- 获取单个Buff数据通过自增Id
function XRogueSimModel:GetBuffDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetBuffDataById(id)
end

-- 获取单个奖励数据通过自增Id
function XRogueSimModel:GetRewardDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetRewardDataById(id)
end

-- 获取单个事件数据通过自增Id
function XRogueSimModel:GetEventDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetEventDataById(id)
end

-- 获取单个建筑数据通过自增Id
function XRogueSimModel:GetBuildingDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetBuildingDataById(id)
end

-- 获取单个城邦数据通过自增Id
function XRogueSimModel:GetCityDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetCityDataById(id)
end

-- 获取单个道具数据通过自增Id
function XRogueSimModel:GetPropDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetPropDataById(id)
end

-- 获取单个任务数据通过自增Id
function XRogueSimModel:GetTaskDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetTaskDataById(id)
end

-- 获取货物加成信息通过货物Id
function XRogueSimModel:GetCommodityAddsById(commodityId)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetCommodityAdds(commodityId)
end

-- 检查关卡数据是否为空
function XRogueSimModel:CheckStageDataEmpty()
    if not self:GetStageData() then
        return true
    end
    return false
end

-- 检查关卡是否通过
function XRogueSimModel:CheckStageIsPass(stageId)
    if self.ActivityData then
        return self.ActivityData:CheckFinishedStageId(stageId)
    end
    return false
end

--endregion

--region 活动表相关

---@return XTableRogueSimActivity
function XRogueSimModel:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimActivity, curActivityId)
end

-- 获取活动时间Id
function XRogueSimModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

-- 获取活动游戏时间Id
function XRogueSimModel:GetActivityGameTimeId()
    local config = self:GetActivityConfig()
    return config and config.GameTimeId or 0
end

-- 获取活动关卡Id列表
function XRogueSimModel:GetActivityStageIds()
    local config = self:GetActivityConfig()
    return config and config.StageIds or {}
end

--endregion

--region 图鉴表相关

---@return XTableRogueSimIllustrate[]
function XRogueSimModel:GetRogueSimIllustrateConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimIllustrate)
end

---@return XTableRogueSimIllustrate
function XRogueSimModel:GetRogueSimIllustrateConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimIllustrate, id)
end

--endregion

--region 关卡表相关

---@return XTableRogueSimStage[]
function XRogueSimModel:GetRogueSimStageConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimStage)
end

---@return XTableRogueSimStage
function XRogueSimModel:GetRogueSimStageConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimStage, id)
end

-- 获取关卡时间Id
function XRogueSimModel:GetRogueSimStageTimeId(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.TimeId or 0
end

-- 获取关卡名称
function XRogueSimModel:GetRogueSimStageName(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.Name or ""
end

-- 获取关卡名称贴图
function XRogueSimModel:GetRogueSimStageNameIcon(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.NameIcon or ""
end

-- 获取关卡最大回合数
function XRogueSimModel:GetRogueSimStageMaxTurnCount(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.MaxTurnCount or 0
end

-- 获取关卡类型
function XRogueSimModel:GetRogueSimStageType(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.Type or 0
end

-- 获取关卡前置关卡
function XRogueSimModel:GetRogueSimStagePreStageId(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.PreStageId or 0
end

--endregion

--region 资源表相关

---@return XTableRogueSimResource[]
function XRogueSimModel:GetRogueSimResourceConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimResource)
end

---@return XTableRogueSimResource
function XRogueSimModel:GetRogueSimResourceConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimResource, id)
end

--endregion

--region 货物表相关

---@return XTableRogueSimCommodity[]
function XRogueSimModel:GetRogueSimCommodityConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimCommodity)
end

---@return XTableRogueSimCommodity
function XRogueSimModel:GetRogueSimCommodityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodity, id)
end

--endregion

--region 货物生产表相关

function XRogueSimModel:InitCommodityProduction()
    if self.IsInitCommodityProduction then
        return
    end
    local configs = self:GetRogueSimCommodityProductionConfigs()
    for _, config in ipairs(configs) do
        local commodityId = config.CommodityId
        local population = config.Population
        if not self.CommodityIdAndPopulationToConfigId[commodityId] then
            self.CommodityIdAndPopulationToConfigId[commodityId] = {}
        end
        self.CommodityIdAndPopulationToConfigId[commodityId][population] = config.Id
    end
    self.IsInitCommodityProduction = true
end

-- 获取货物生产配置Id
---@param commodityId number 货物Id
---@param population number 人口(生产力)
function XRogueSimModel:GetCommodityProductionId(commodityId, population)
    self:InitCommodityProduction()
    if not XTool.IsNumberValid(commodityId) or not population then
        XLog.Error(string.format("GetCommodityProductionId error, invalid input. commodity:%s, population:%s", commodityId, population))
        return 0
    end
    if population <= 0 then
        return 0
    end
    local productions = self.CommodityIdAndPopulationToConfigId[commodityId]
    if not productions then
        XLog.Error(string.format("RogueSimCommodityProduction表中不存在CommodityId为:%s 的配置", commodityId))
        return 0
    end
    -- 找到最接近的生产力
    local minPopulation = 0
    for pop, _ in pairs(productions) do
        if pop <= population and pop > minPopulation then
            minPopulation = pop
        end
    end
    return productions[minPopulation] or 0
end

---@return XTableRogueSimCommodityProduction[]
function XRogueSimModel:GetRogueSimCommodityProductionConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimCommodityProduction)
end

---@return XTableRogueSimCommodityProduction
function XRogueSimModel:GetRogueSimCommodityProductionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodityProduction, id)
end

--endregion

--region 货物价格波动表相关

---@return XTableRogueSimCommodityPriceRate
function XRogueSimModel:GetRogueSimCommodityPriceRateConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodityPriceRate, id)
end

--endregion

--region 主城等级表相关

function XRogueSimModel:InitMainLevel()
    if self.IsInitMainLevel then
        return
    end
    local configs = self:GetRogueSimMainLevelConfigs()
    local levelGroup, level
    for id, config in ipairs(configs) do
        levelGroup = config.LevelGroup
        level = config.Level
        if not self.levelGroupToMainLevelIdList[levelGroup] then
            self.levelGroupToMainLevelIdList[levelGroup] = {}
        end
        table.insert(self.levelGroupToMainLevelIdList[levelGroup], id)

        if not self.levelGroupAndLevelToMainLevelId[levelGroup] then
            self.levelGroupAndLevelToMainLevelId[levelGroup] = {}
        end
        self.levelGroupAndLevelToMainLevelId[levelGroup][level] = id

        if not self.levelGroupToMaxMainLevel[levelGroup] or self.levelGroupToMaxMainLevel[levelGroup] < level then
            self.levelGroupToMaxMainLevel[levelGroup] = level
        end
    end
    self.IsInitMainLevel = true
end

-- 获取主城最大等级
function XRogueSimModel:GetMaxMainLevel(levelGroup)
    self:InitMainLevel()
    return self.levelGroupToMaxMainLevel[levelGroup] or 0
end

-- 获取主城等级列表
function XRogueSimModel:GetMainLevelIdList(levelGroup)
    self:InitMainLevel()
    return self.levelGroupToMainLevelIdList[levelGroup] or {}
end

-- 获取主城等级配置Id
function XRogueSimModel:GetMainLevelId(levelGroup, level)
    self:InitMainLevel()
    if not self.levelGroupAndLevelToMainLevelId[levelGroup] then
        XLog.Error("RogueSimMainLevel表中不存在LevelGroup为" .. levelGroup .. "的配置")
        return
    end
    return self.levelGroupAndLevelToMainLevelId[levelGroup][level] or 0
end

---@return XTableRogueSimMainLevel[]
function XRogueSimModel:GetRogueSimMainLevelConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimMainLevel)
end

---@return XTableRogueSimMainLevel
function XRogueSimModel:GetRogueSimMainLevelConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimMainLevel, id)
end

--endregion

--region Buff表相关

---@return XTableRogueSimBuff
function XRogueSimModel:GetRogueSimBuffConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimBuff, id)
end

--endregion

--region 奖励表相关

---@return XTableRogueSimReward
function XRogueSimModel:GetRogueSimRewardConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimReward, id)
end

---@return XTableRogueSimRewardDrop
function XRogueSimModel:GetRogueSimRewardDropConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimRewardDrop, id)
end

--endregion

--region 道具表相关

---@return XTableRogueSimProp[]
function XRogueSimModel:GetRogueSimPropConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimProp)
end

---@return XTableRogueSimProp
function XRogueSimModel:GetRogueSimPropConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimProp, id)
end

---@return XTableRogueSimPropRare
function XRogueSimModel:GetRogueSimPropRareConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimPropRare, id)
end

---@return XTableRogueSimPropShowLabel
function XRogueSimModel:GetRogueSimPropShowLabelConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimPropShowLabel, id)
end

--endregion

--region 事件表相关

---@return XTableRogueSimEvent
function XRogueSimModel:GetRogueSimEventConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimEvent, id)
end

---@return XTableRogueSimEventOption
function XRogueSimModel:GetRogueSimEventOptionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimEventOption, id)
end

--endregion

--region 建筑表相关

---@return XTableRogueSimBuilding[]
function XRogueSimModel:GetRogueSimBuildingConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimBuilding)
end

---@return XTableRogueSimBuilding
function XRogueSimModel:GetRogueSimBuildingConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimBuilding, id)
end

--endregion

--region 建筑蓝图表相关

---@return XTableRogueSimBuildingBluePrint
function XRogueSimModel:GetRogueSimBuildingBluePrintConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimBuildingBluePrint, id)
end

--endregion

--region 城邦等级表相关

-- 初始化城邦等级
function XRogueSimModel:InitCityLevel()
    if self.IsInitCityLevel then
        return
    end
    local configs = self:GetRogueSimCityLevelConfigs()
    local levelGroup, cityId, level
    for id, config in pairs(configs) do
        levelGroup, cityId, level = config.LevelGroup, config.CityId, config.Level

        self.levelGroupAndCityIdToCityLevelIdList[levelGroup] = self.levelGroupAndCityIdToCityLevelIdList[levelGroup] or {}
        self.levelGroupAndCityIdToCityLevelIdList[levelGroup][cityId] = self.levelGroupAndCityIdToCityLevelIdList[levelGroup][cityId] or {}
        table.insert(self.levelGroupAndCityIdToCityLevelIdList[levelGroup][cityId], id)

        self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup] = self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup] or {}
        self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup][cityId] = self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup][cityId] or {}
        self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup][cityId][level] = id

        self.levelGroupAndCityIdToMaxCityLevel[levelGroup] = self.levelGroupAndCityIdToMaxCityLevel[levelGroup] or {}
        if not self.levelGroupAndCityIdToMaxCityLevel[levelGroup][cityId] or self.levelGroupAndCityIdToMaxCityLevel[levelGroup][cityId] < level then
            self.levelGroupAndCityIdToMaxCityLevel[levelGroup][cityId] = level
        end
    end
    self.IsInitCityLevel = true
end

-- 获取城邦最大等级
function XRogueSimModel:GetMaxCityLevel(levelGroup, cityId)
    self:InitCityLevel()
    return self.levelGroupAndCityIdToMaxCityLevel[levelGroup][cityId] or 0
end

-- 获取城邦等级列表
function XRogueSimModel:GetCityLevelIdList(levelGroup, cityId)
    self:InitCityLevel()
    return self.levelGroupAndCityIdToCityLevelIdList[levelGroup][cityId] or {}
end

-- 获取城邦等级配置Id
function XRogueSimModel:GetCityLevelConfigId(levelGroup, cityId, level)
    self:InitCityLevel()
    if not self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup] then
        XLog.Error("RogueSimCityLevel表中不存在LevelGroup为" .. levelGroup .. "的配置")
        return
    end
    if not self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup][cityId] then
        XLog.Error("RogueSimCityLevel表中不存在CityId为" .. cityId .. "的配置")
        return
    end
    return self.levelGroupAndCityIdAndLevelToCityLevelId[levelGroup][cityId][level] or 0
end

---@return XTableRogueSimCityLevel[]
function XRogueSimModel:GetRogueSimCityLevelConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimCityLevel)
end

---@return XTableRogueSimCityLevel
function XRogueSimModel:GetRogueSimCityLevelConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCityLevel, id)
end

--endregion

--region 任务表相关

---@return XTableRogueSimTask
function XRogueSimModel:GetRogueSimTaskConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTask, id)
end

--endregion

--region 信物表相关

---@return XTableRogueSimToken
function XRogueSimModel:GetRogueSimTokenConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimToken, id)
end

--endregion

--region 波动表相关

---@return XTableRogueSimVolatility
function XRogueSimModel:GetRogueSimVolatilityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimVolatility, id)
end

--endregion

--region 条件表相关

---@return XTableRogueSimCondition
function XRogueSimModel:GetRogueSimConditionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCondition, id)
end

-- 比较两个数值
function XRogueSimModel:CompareInt(num1, num2, op)
    if op == self.ConditionOperateType.Greater then
        return num1 > num2
    elseif op == self.ConditionOperateType.GreaterEqual then
        return num1 >= num2
    elseif op == self.ConditionOperateType.Equal then
        return num1 == num2
    elseif op == self.ConditionOperateType.LessEqual then
        return num1 <= num2
    elseif op == self.ConditionOperateType.Less then
        return num1 < num2
    end
    return false
end

-- 介于两个数值之间
function XRogueSimModel:IsBetween(percent, down, up)
    percent = percent * XEnumConst.RogueSim.Denominator
    if percent >= down and percent <= up then
        return true
    end
    return false
end

-- 位运算
function XRogueSimModel:CountBit(num)
    local count = 0
    while num > 0 do
        if (num & 1) == 1 then
            count = count + 1
        end
        num = num >> 1
    end
    return count
end

--endregion

--region 效果表相关

---@return XTableRogueSimEffect
function XRogueSimModel:GetRogueSimEffectConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimEffect, id)
end

--endregion

--region 科技表相关

---@return XTableRogueSimTech[]
function XRogueSimModel:GetRogueSimTechConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimTech)
end

---@return XTableRogueSimTech
function XRogueSimModel:GetRogueSimTechConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTech, id)
end

---@return XTableRogueSimTechLevel[]
function XRogueSimModel:GetRogueSimTechLevelConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimTechLevel)
end

---@return XTableRogueSimTechLevel
function XRogueSimModel:GetRogueSimTechLevelConfig(lv)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTechLevel, lv)
end

--endregion

--region 客户端配置表相关

function XRogueSimModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimClientConfig, key)
    if not config then
        return nil
    end
    return config.Params and config.Params[index] or ""
end

function XRogueSimModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimClientConfig, key)
    if not config then
        return nil
    end
    return config.Params
end

--endregion

--region loading表相关

-- 获取所有loading表
---@return XTableRogueSimLoadingTips[]
function XRogueSimModel:GetLoadingTipsConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimLoadingTips)
end

--endregion

--region 货物气泡表相关

---@return XTableRogueSimCommodityBubble
function XRogueSimModel:GetCommodityBubbleConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodityBubble, id)
end

---@return XTableRogueSimCommodityBubbleGroup
function XRogueSimModel:GetCommodityBubbleGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodityBubbleGroup, id)
end

--endregion

--region 传闻相关

-- 获取传闻表
---@return XTableRogueSimTip
function XRogueSimModel:GetRogueSimTipConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTip, id)
end

--endregion

--region 地图表相关

---@return XTableRogueSimArea[]
function XRogueSimModel:GetRogueSimAreaConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimMapTableKey.RogueSimArea)
end

---@return XTableRogueSimArea
function XRogueSimModel:GetRogueSimAreaConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimMapTableKey.RogueSimArea, id)
end

---@return XTableRogueSimLandform[]
function XRogueSimModel:GetRogueSimLandformConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimMapTableKey.RogueSimLandform)
end

---@return XTableRogueSimLandform
function XRogueSimModel:GetRogueSimLandformConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimMapTableKey.RogueSimLandform, id)
end

---@return XTableRogueSimTerrain[]
function XRogueSimModel:GetRogueSimTerrainConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimMapTableKey.RogueSimTerrain)
end

---@return XTableRogueSimTerrain
function XRogueSimModel:GetRogueSimTerrainConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimMapTableKey.RogueSimTerrain, id)
end

--endregion

--region 地图格子表相关

---@return XTableRogueSimAreaGrid[]
function XRogueSimModel:GetRogueSimAreaGridConfigs(id)
    local key = self.RogueSimAreaGridTableKey["RogueSimAreaGrid" .. id]
    local config = self._ConfigUtil:GetByTableKey(key)
    if not config then
        XLog.ErrorTableDataNotFound("XRogueSimModel.GetRogueSimAreaGridConfigs", "areaId",
            "Share/RogueSim/RogueSimMap/RogueSimAreaGrid/", "areaId", tostring(id))
        return
    end

    return config
end

--endregion

--region 分数称号相关

---@return XTableRogueSimScoreTitle[]
function XRogueSimModel:GetRogueSimScoreTitleConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimScoreTitle)
end

--endregion

--region 弹框相关

-- 根据弹框类型入队弹框数据
function XRogueSimModel:EnqueuePopupData(popupType, ...)
    self.PopupData = self.PopupData or {}
    self.PopupData[popupType] = self.PopupData[popupType] or {}

    local popupHandlers = {
        [XEnumConst.RogueSim.PopupType.Reward] = self.AddRewardData,
        [XEnumConst.RogueSim.PopupType.PropSelect] = self.AddPropSelectData,
        [XEnumConst.RogueSim.PopupType.Task] = self.AddCityTaskData,
        [XEnumConst.RogueSim.PopupType.TurnReward] = self.AddTurnRewardData,
        [XEnumConst.RogueSim.PopupType.MainLevelUp] = self.AddMainLevelUpData,
        [XEnumConst.RogueSim.PopupType.CityLevelUp] = self.AddCityLevelUpData,
        [XEnumConst.RogueSim.PopupType.NewTips] = self.AddNewTipsData,
    }

    local handler = popupHandlers[popupType]
    if handler then
        handler(self, popupType, ...)
    end
end

-- 添加奖励数据
function XRogueSimModel:AddRewardData(popupType, rewardId, rewardItems)
    if not XTool.IsNumberValid(rewardId) or XTool.IsTableEmpty(rewardItems) or self.IsRoundEnd then
        return
    end
    -- 建筑掉落的事件不弹框
    if self:CheckIsBuildingEvent(rewardItems) then
        return
    end
    -- 奖励类型为建筑时不弹框
    for _, rewardItem in pairs(rewardItems) do
        if rewardItem.Type == XEnumConst.RogueSim.RewardType.Building then
            return
        end
    end
    table.insert(self.PopupData[popupType], { RewardId = rewardId, RewardItems = rewardItems })
end

-- 检查是否是建筑掉落的事件
function XRogueSimModel:CheckIsBuildingEvent(rewardItems)
    if XTool.IsTableEmpty(rewardItems) then
        return false
    end
    local stageData = self:GetStageData()
    if not stageData then
        return false
    end
    local rewardItem = rewardItems[1]
    if rewardItem.Type == XEnumConst.RogueSim.RewardType.Event then
        local eventData = stageData:GetEventDataById(rewardItem.ObjectId)
        if eventData then
            local buildingData = stageData:GetBuildingDataByGridId(eventData:GetGridId())
            return buildingData ~= nil
        end
    end
    return false
end

-- 添加道具选择数据
function XRogueSimModel:AddPropSelectData(popupType, reward)
    if reward and XTool.IsNumberValid(reward.Source) and not self.IsRoundEnd then
        table.insert(self.PopupData[popupType], { Reward = reward })
    end
end

-- 添加城邦任务数据
function XRogueSimModel:AddCityTaskData(popupType, cityTaskData)
    if cityTaskData then
        for _, taskData in pairs(cityTaskData) do
            if taskData.State == self.TaskState.Finished then
                table.insert(self.PopupData[popupType], { TaskData = taskData })
            end
        end
    end
end

-- 添加回合奖励数据
function XRogueSimModel:AddTurnRewardData(popupType, commodityInfo, resourceInfo)
    if commodityInfo then
        for id, num in pairs(commodityInfo) do
            table.insert(self.PopupData[popupType], { ItemId = id, Num = num, Type = XEnumConst.RogueSim.RewardType.Commodity })
        end
    end
    if resourceInfo then
        for id, num in pairs(resourceInfo) do
            table.insert(self.PopupData[popupType], { ItemId = id, Num = num, Type = XEnumConst.RogueSim.RewardType.Resource })
        end
    end
end

-- 添加主城等级提升数据
function XRogueSimModel:AddMainLevelUpData(popupType, data)
    table.insert(self.PopupData[popupType], data)
end

-- 添加城邦等级提升数据
function XRogueSimModel:AddCityLevelUpData(popupType, data)
    table.insert(self.PopupData[popupType], data)
end

-- 添加新提示数据
function XRogueSimModel:AddNewTipsData(popupType, turnNumber, tipId)
    if XTool.IsNumberValid(turnNumber) and XTool.IsNumberValid(tipId) then
        self.PopupData[popupType][turnNumber] = self.PopupData[popupType][turnNumber] or {}
        table.insert(self.PopupData[popupType][turnNumber], tipId)
    end
end

-- 根据弹框类型出队弹框数据
function XRogueSimModel:DequeuePopupData(popupType, ...)
    if not self.PopupData or not self.PopupData[popupType] then
        return nil
    end

    local popupHandlers = {
        [XEnumConst.RogueSim.PopupType.Reward] = self.GetRewardData,
        [XEnumConst.RogueSim.PopupType.PropSelect] = self.GetPropSelectData,
        [XEnumConst.RogueSim.PopupType.TurnReward] = self.GetAllPopupData,
        [XEnumConst.RogueSim.PopupType.NewTips] = self.GetAllPopupData,
        [XEnumConst.RogueSim.PopupType.Task] = self.GetFirstPopupData,
        [XEnumConst.RogueSim.PopupType.MainLevelUp] = self.GetFirstPopupData,
        [XEnumConst.RogueSim.PopupType.CityLevelUp] = self.GetFirstPopupData,
    }

    local handler = popupHandlers[popupType]
    return handler and handler(self, popupType, ...) or nil
end

-- 获取奖励数据
function XRogueSimModel:GetRewardData(popupType, rewardId)
    if XTool.IsNumberValid(rewardId) then
        for i, data in ipairs(self.PopupData[popupType]) do
            if data.RewardId == rewardId then
                return table.remove(self.PopupData[popupType], i)
            end
        end
    end
    return table.remove(self.PopupData[popupType], 1)
end

-- 获取道具选择数据
---@param gridId number 格子Id 可以为0
---@param source number 来源Id
function XRogueSimModel:GetPropSelectData(popupType, gridId, source)
    gridId = gridId or 0
    if XTool.IsNumberValid(source) then
        for i, data in ipairs(self.PopupData[popupType]) do
            if data.Reward.GridId == gridId and data.Reward.Source == source then
                return table.remove(self.PopupData[popupType], i)
            end
        end
    end
    return table.remove(self.PopupData[popupType], 1)
end

-- 获取所有的弹框数据并清空
function XRogueSimModel:GetAllPopupData(popupType)
    local data = self.PopupData[popupType] or {}
    self.PopupData[popupType] = nil
    return data
end

-- 获取第一个数据并移除
function XRogueSimModel:GetFirstPopupData(popupType)
    return table.remove(self.PopupData[popupType], 1)
end

-- 检查弹框数据是否为空
function XRogueSimModel:CheckPopupDataEmpty(popupType)
    return not self.PopupData or not self.PopupData[popupType] or XTool.IsTableEmpty(self.PopupData[popupType])
end

-- 根据类型清空弹框数据
function XRogueSimModel:ClearPopupDataByType(popupType)
    if self.PopupData then
        self.PopupData[popupType] = nil
    end
end

-- 清空弹框数据
function XRogueSimModel:ClearAllPopupData()
    self.PopupData = nil
    self.NextTargetPopupType = nil
end

--endregion

--region 本地信息相关

-- 获取引导记录key
function XRogueSimModel:GetGuideRecordKey()
    local activityId = self.ActivityData and self.ActivityData:GetActivityId() or 0
    return string.format("XRogueSimModel_GetGuideRecordKey_%s_%s", XPlayer.Id, activityId)
end

--endregion

return XRogueSimModel
