---@class XSkyGardenShoppingStreetConfig : XModel
local XSkyGardenShoppingStreetConfig = XClass(XModel, "XSkyGardenShoppingStreetConfig")

local TableKey = {
    SgStreetArea = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.IntAll, },
    SgStreetBgmSection = {},
    SgStreetBillboard = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetBuff = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetConfig = { Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String, CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetCustomer = {},
    SgStreetCustomerEventEmergency = {},
    SgStreetCustomerParam = {},
    SgStreetEnvironmentSatisfaction = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetFeedback = {},
    SgStreetFeedbackIconGroup = {},
    SgStreetGrapevine = {},
    SgStreetInsideShopDessert = {},
    SgStreetInsideShopDessertGoods = {},
    SgStreetInsideShopFood = {},
    SgStreetInsideShopFoodChef = {},
    SgStreetInsideShopFoodGoods = {},
    SgStreetInsideShopGrocery = {},
    SgStreetInsideShopGroceryGoods = {},
    SgStreetMascot = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetNews = {},
    SgStreetOutSideShopBuildCondition = {},
    SgStreetPromotion = {},
    SgStreetPromotionRandom = {},
    SgStreetReview = {},
    SgStreetShop = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.IntAll, },
    SgStreetShopAttr = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetShopFactorStar = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetShopLv = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.IntAll, },
    SgStreetShopLvBranchAdd = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetShopScoreSatisfaction = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetStage = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetStageDesc = {},
    SgStreetStageRes = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetStageShop = { CacheType = XConfigUtil.CacheType.Normal, },
    SgStreetTask = {},
}

function XSkyGardenShoppingStreetConfig:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("BigWorld/SkyGarden/ShoppingStreet", TableKey)
end

function XSkyGardenShoppingStreetConfig:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XSkyGardenShoppingStreetConfig:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

function XSkyGardenShoppingStreetConfig:_CheckShopLevelConfig()
    if self._LevelConfigHelperMap then return end

    self._LevelConfigHelperMap = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetShopLv)
    for id, config in pairs(configs) do
        local shopId = config.ShopId
        if not self._LevelConfigHelperMap[shopId] then
            self._LevelConfigHelperMap[shopId] = {}
        end
        self._LevelConfigHelperMap[shopId][config.Level] = id
    end
end

--region --------config start-----------
--- 获取区域配置
---@param areaId ui区域id
---@return XTableSgStreetArea 区域配置
function XSkyGardenShoppingStreetConfig:GetAreaConfigById(areaId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetArea, areaId)
end

--- 获取灯带配置
---@param id 灯带Id
---@return XTableSgStreetBillboard 灯带配置
function XSkyGardenShoppingStreetConfig:GetBillboardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetBillboard, id)
end

--- 获取Buff配置
---@param buffId buffId
---@return XTableSgStreetBuff 灯带配置
function XSkyGardenShoppingStreetConfig:GetBuffConfigById(buffId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetBuff, buffId)
end

--- 获取全局配置
---@param key 配置key
---@return any 配置值
function XSkyGardenShoppingStreetConfig:GetGlobalConfigByKey(key, isArray)
    local t = self._ConfigUtil:GetByTableKey(TableKey.SgStreetConfig)
    if not t then return nil end
    local config = t[key]
    if not config then return nil end
    if isArray then
        return config.Values
    end
    return config.Values[1]
end

--- 获取客户参数配置
---@param stageId number 阶段id
---@return XTableSgStreetCustomerParam
function XSkyGardenShoppingStreetConfig:GetCustomerParamByStageId(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetCustomerParam, stageId)
end

-- 突发事件配置
---@param id突发事件id
---@return XTableSgStreetStage 所有阶段配置
function XSkyGardenShoppingStreetConfig:GetCustomerEventEmergencyById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetCustomerEventEmergency, id)
end

-- 阶段配置
---@return XTableSgStreetStage 所有阶段配置
function XSkyGardenShoppingStreetConfig:GetAllStageConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SgStreetStage)
end

-- 描述解析配置
---@param descTypeId 描述类型Id
---@return XTableSgStreetStageDesc 描述解析配置
function XSkyGardenShoppingStreetConfig:GetStageDescConfigsById(descTypeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetStageDesc, descTypeId)
end

-- 阶段配置
---@return XTableSgStreetStageRes 资源显示配置
function XSkyGardenShoppingStreetConfig:GetStageResConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SgStreetStageRes)
end

-- 阶段内配置
---@param stageId 阶段id
---@return XTableSgStreetStage 阶段配置
function XSkyGardenShoppingStreetConfig:GetStageConfigsByStageId(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetStage, stageId)
end

--- 获取阶段内商品配置
---@param stageId 阶段id
---@return XTableSgStreetStageShop 阶段内商店配置
function XSkyGardenShoppingStreetConfig:GetStageShopConfigsByStageId(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetStageShop, stageId)
end

--- 获取阶段目标配置
---@param taskId 任务id
---@return XTableSgStreetTask 目标配置
function XSkyGardenShoppingStreetConfig:GetStageTaskConfigsById(taskId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetTask, taskId)
end

--- 获取吉祥物配置
---@return XTableSgStreetMascot 吉祥物配置
function XSkyGardenShoppingStreetConfig:GetMascotConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.SgStreetMascot)
end

--- 获取新闻配置
---@param newsId 新闻id
---@return XTableSgStreetNews 新闻配置
function XSkyGardenShoppingStreetConfig:GetNewsConfigById(newsId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetNews, newsId)
end

--- 获取促销配置
---@param promotionId 促销id
---@return XTableSgStreetPromotion 促销配置
function XSkyGardenShoppingStreetConfig:GetPromotionConfigById(promotionId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetPromotion, promotionId)
end

--- 获取建议配置
---@param id number 建议id
---@return XTableSgStreetReview 建议配置
function XSkyGardenShoppingStreetConfig:GetReviewConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetReview, id)
end

--- 获取阶段内商品配置
---@param bid 商店id
---@param isInside 是否内部商店
---@return XTableSgStreetInsideShop 商店配置
function XSkyGardenShoppingStreetConfig:GetShopConfigById(bid, isInside)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetShop, bid)
end

--- 获取所有属性显示的配置
---@return XTableSgStreetShopAttr 属性配置
function XSkyGardenShoppingStreetConfig:GetShopAttrConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SgStreetShopAttr)
end

--- 获取属性显示的配置
---@param attrShowId 属性显示id
---@return XTableSgStreetShopAttr 属性配置
function XSkyGardenShoppingStreetConfig:GetShopAttrConfigById(attrShowId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetShopAttr, attrShowId)
end

--- 获取商店内商品配置
---@param shopId 商店id
---@param lv 等级
---@param isInside 是否内部商店
---@return XTableSgStreetInsideShopLv 商店内商品配置
function XSkyGardenShoppingStreetConfig:GetShopLevelConfigById(shopId, lv, isInside)
    self:_CheckShopLevelConfig()
    local id = self._LevelConfigHelperMap[shopId][lv]
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetShopLv, id)
end

--- 获取商店升级分支配置
---@param branchId 分支id
---@return XTableSgStreetShopLvBranchAdd 商店升级分支配置
function XSkyGardenShoppingStreetConfig:GetShopLvBranchConfigsByBranchId(branchId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetShopLvBranchAdd, branchId)
end

--- 获取食品商店商品配置
---@param shopId 商店id
---@return XTableSgStreetInsideShopFood 食品商店商品配置
function XSkyGardenShoppingStreetConfig:GetShopFoodConfigsByShopId(shopId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopFood, shopId)
end

--- 获取食品商店材料配置
---@param goodId 材料id
---@return XTableSgStreetInsideShopFoodGoods 食品商店材料配置
function XSkyGardenShoppingStreetConfig:GetShopFoodGoodsConfigsByGoodId(goodId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopFoodGoods, goodId)
end

--- 获取食品商店厨师配置
---@param chefId 厨师id
---@return XTableSgStreetInsideShopFoodChef 食品商店厨师配置
function XSkyGardenShoppingStreetConfig:GetShopFoodChefConfigsByChefId(chefId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopFoodChef, chefId)
end

--- 获取杂货铺商店商品配置
---@param shopId 商店id
---@return XTableSgStreetInsideShopGrocery 杂货铺商店商品配置
function XSkyGardenShoppingStreetConfig:GetShopGroceryConfigsByShopId(shopId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopGrocery, shopId)
end

--- 获取杂货铺商店商品配置
---@param goodId 材料id
---@return XTableSgStreetInsideShopGroceryGoods 杂货铺商店材料配置
function XSkyGardenShoppingStreetConfig:GetShopGroceryGoodsConfigsByGoodId(goodId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopGroceryGoods, goodId)
end

--- 获取反馈配置
---@param feebackId 商店id
---@return XTableSgStreetFeedback 反馈配置
function XSkyGardenShoppingStreetConfig:GetFeedbackConfigsById(feebackId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetFeedback, feebackId)
end

--- 获取反馈头像组配置
---@param groupId 反馈头像组id
---@return XTableSgStreetFeedbackIconGroup 反馈头像组配置
function XSkyGardenShoppingStreetConfig:GetFeedbackIconByGroupId(groupId)
    if not self._GroupIconPath then
        self._GroupIconPath = {}
        local iconGroups = self._ConfigUtil:GetByTableKey(TableKey.SgStreetFeedbackIconGroup)
        for _, iconGroupCfg in pairs(iconGroups) do
            if not self._GroupIconPath[iconGroupCfg.Group] then
                self._GroupIconPath[iconGroupCfg.Group] = {}
            end
            table.insert(self._GroupIconPath[iconGroupCfg.Group], iconGroupCfg.HeadIcon)
        end
    end
    return self._GroupIconPath[groupId]
end

--- 获取小道消息配置
---@param grapevineId 小道消息id
---@return XTableSgStreetGrapevine 小道消息配置
function XSkyGardenShoppingStreetConfig:GetGrapevineConfigById(grapevineId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetGrapevine, grapevineId)
end

--- 获取甜品商店商品配置
---@param shopId 商店id
---@return XTableSgStreetInsideShopDessert 甜品商店商品配置
function XSkyGardenShoppingStreetConfig:GetShopDessertConfigsByShopId(shopId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopDessert, shopId)
end

--- 获取甜品商店商品配置
---@param goodId 材料id
---@return XTableSgStreetInsideShopDessertGoods 甜品商店材料配置
function XSkyGardenShoppingStreetConfig:GetShopDessertGoodsConfigsByGoodId(goodId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetInsideShopDessertGoods, goodId)
end

--endregion --------config end-----------

--- 获取商店最大等级
--- @param shopId 商店id
--- @return 最大等级
function XSkyGardenShoppingStreetConfig:GetShopMaxLevel(shopId)
    self:_CheckShopLevelConfig()
    return #self._LevelConfigHelperMap[shopId]
end

--- 获取场景位置PlaceId
--- @param areaId 区域id
--- @return PlaceId
function XSkyGardenShoppingStreetConfig:GetPlaceIdByAreaId(areaId)
    if not self._AreaId2PlaceId then
        self._AreaId2PlaceId = {}
        local areaConfigs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetArea)
        for _, config in pairs(areaConfigs) do
            self._AreaId2PlaceId[config.Id] = config.PlaceId
        end
    end
    return self._AreaId2PlaceId[areaId] or 0
end

--- 获取商店星级
---@param shopId 商店id
---@param customerFactor 顾客因子
function XSkyGardenShoppingStreetConfig:GetShopCustomerStar(shopId, customerFactor)
    local shopStarConfig = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgStreetShopFactorStar, shopId)
    if not shopStarConfig then return 0 end
    local factorGroup = shopStarConfig.CustomerFactor
    if not factorGroup then return 0 end
    local count = #factorGroup
    if count <= 0 then return 0 end

    local inc = 0
    for groupIndex, factorNum in pairs(factorGroup) do
        if customerFactor >= factorNum and (not factorGroup[inc] or factorNum > factorGroup[inc]) then
            inc = groupIndex
        end
    end
    local starGroup = shopStarConfig.CustomerFactorStar
    if inc <= 0 or inc > #starGroup then return 0 end
    return starGroup[inc]
end

-- 获取属性配置
function XSkyGardenShoppingStreetConfig:GetAttrConfigByAttrAddType(attrType)
    if not self._AttrTypeList then
        self._AttrTypeList = {}
        local attrsConfigs = self:GetShopAttrConfigs()
        for attrIndexId, attrConfig in pairs(attrsConfigs) do
            self._AttrTypeList[attrConfig.Type] = attrIndexId
        end
    end
    if not self._AttrTypeList[attrType] then return end
    return self:GetShopAttrConfigById(self._AttrTypeList[attrType])
end

--- 获取环境满意度
---@param enviromentNum 环境值
---@return satisfactionNum 满意度
function XSkyGardenShoppingStreetConfig:GetEnvironmentSatisfactionByEnv(enviromentNum)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetEnvironmentSatisfaction)
    local cfgsTotal = #cfgs
    for i = cfgsTotal, 1, -1 do
        if enviromentNum >= cfgs[i].Environment then
            return cfgs[i].Satisfaction
        end
    end
    return 0
end

--- 获取环境满意度
---@param score 评分
---@return satisfactionNum 满意度
function XSkyGardenShoppingStreetConfig:GetShopSatisfactionByScore(score)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetShopScoreSatisfaction)
    local cfgsTotal = #cfgs
    for i = cfgsTotal, 1, -1 do
        if score >= cfgs[i].ShopScore then
            return cfgs[i].Satisfaction
        end
    end
    return 0
end

--- 获取顾客配置通关组id
---@param groupId 关卡组id
---@return customerCfgs 顾客配置
function XSkyGardenShoppingStreetConfig:GetCustomerCfgsByGroup(groupId)
    if self._CustomerGroupConfigs then
        return self._CustomerGroupConfigs[groupId]
    end
    self._CustomerGroupConfigs = {}
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetCustomer)
    for _, config in pairs(cfgs) do
        local groupId = config.Group
        if not self._CustomerGroupConfigs[groupId] then
            self._CustomerGroupConfigs[groupId] = {}
        end
        table.insert(self._CustomerGroupConfigs[groupId], config)
    end
    return self._CustomerGroupConfigs[groupId]
end

-- 获取满意度解锁配置
function XSkyGardenShoppingStreetConfig:GetUnlockOutsideShopConfigByOutsideShopNum(outsideNum)
    if not self._OutsideNum then
        self._OutsideNum = {}
        local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetOutSideShopBuildCondition)
        for _, config in pairs(cfgs) do
            self._OutsideNum[config.Id] = config
        end

        table.sort(self._OutsideNum, function(a, b)
            if a.NeedSatisfaction ~= b.NeedSatisfaction then
                return a.NeedSatisfaction < b.NeedSatisfaction
            end
            return a.Id < b.Id
        end)
    end
    for i = #self._OutsideNum, 1, -1 do
        local config = self._OutsideNum[i]
        if outsideNum + 1 >= config.BuildNum then
            return config
        end
    end
    return self._OutsideNum[1]
end

function XSkyGardenShoppingStreetConfig:GetShopIdByPromotionId(promotionId)
    if not self._PromotionId2ShopId then
        self._PromotionId2ShopId = {}

        local shop2Group = {}
        local shopConfigs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetShop)
        for _, shopCfg in pairs(shopConfigs) do
            if shopCfg.TurnPromotionGroupId and shopCfg.TurnPromotionGroupId > 0 then
                shop2Group[shopCfg.TurnPromotionGroupId] = shopCfg.Id
            end
            if shopCfg.BuildPromotionGroupId and shopCfg.BuildPromotionGroupId > 0 then
                shop2Group[shopCfg.BuildPromotionGroupId] = shopCfg.Id
            end
        end

        local promotionRandomCfgs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetPromotionRandom)
        for _, promotionRandomCfg in pairs(promotionRandomCfgs) do
            self._PromotionId2ShopId[promotionRandomCfg.PromotionId] = shop2Group[promotionRandomCfg.GroupId]
        end
    end
    return self._PromotionId2ShopId[promotionId]
end

function XSkyGardenShoppingStreetConfig:GetMusicBySatisfactionAndCustomer(satisfactionNum, CustomerNum)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SgStreetBgmSection)
    local cfgsTotal = #cfgs
    for i = cfgsTotal, 1, -1 do
        if satisfactionNum >= cfgs[i].Satisfaction and CustomerNum >= cfgs[i].CustomerNum then
            return cfgs[i].BgmSection
        end
    end
    return cfgs[1].BgmSection
end

return XSkyGardenShoppingStreetConfig