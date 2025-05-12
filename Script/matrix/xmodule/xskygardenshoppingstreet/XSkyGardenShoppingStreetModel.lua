local XSGGameArea = require("XModule/XSkyGardenShoppingStreet/Data/XSGGameArea")
local XSGGameCustomer = require("XModule/XSkyGardenShoppingStreet/Data/XSGGameCustomer")
local XSGGameMascot = require("XModule/XSkyGardenShoppingStreet/Data/XSGGameMascot")

local XSkyGardenShoppingStreetConfig = require("XModule/XSkyGardenShoppingStreet/XSkyGardenShoppingStreetConfig")
---@class XSkyGardenShoppingStreetModel : XSkyGardenShoppingStreetConfig
local XSkyGardenShoppingStreetModel = XClass(XSkyGardenShoppingStreetConfig, "XSkyGardenShoppingStreetModel")

function XSkyGardenShoppingStreetModel:OnInit()
    XSkyGardenShoppingStreetConfig.OnInit(self)
    --初始化内部变量

    self._InsideShowMaxNum = tonumber(self:GetGlobalConfigByKey("InsideShowMaxNum"))
    self._OutsideShowMaxNum = tonumber(self:GetGlobalConfigByKey("OutsideShowMaxNum"))

    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_ResetAll()
end

function XSkyGardenShoppingStreetModel:ClearPrivate()
    XSkyGardenShoppingStreetConfig.ClearPrivate(self)
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XSkyGardenShoppingStreetModel:ResetAll()
    XSkyGardenShoppingStreetConfig.ResetAll(self)
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self:_ResetAll()
end

----------public start----------
-- todo
function XSkyGardenShoppingStreetModel:IsOpen()
    return true
end

-- todo
function XSkyGardenShoppingStreetModel:GetActivityName()
    return "ShoppingStreetModel"
end

-- 计算整体基础
function XSkyGardenShoppingStreetModel:CalculateProperty()
    local clientType = XMVCA.XSkyGardenShoppingStreet.StageResType
    local customerBase = self._StageBaseResInfo[clientType.InitCustomerNum]
    local enviromentBase = self._StageBaseResInfo[clientType.InitEnvironment]
    if not customerBase or not enviromentBase then return end

    local denominator = 10000
    local shopCustomerNumFixed = 0
    local shopCustomerNumRatio = 0
    local shopEnvironment = 0
    local shopEnvironmentRatio = 0
    local totalCount = self._InsideShowMaxNum + self._OutsideShowMaxNum
    for i = 1, totalCount do
        local areaData = self._StageAreaShops[i]
        shopCustomerNumFixed = shopCustomerNumFixed + areaData:GetCustomerNumFixedBase()
        shopCustomerNumRatio = shopCustomerNumRatio + areaData:GetCustomerNumMultipleBase()
        shopEnvironment = shopEnvironment + areaData:GetEnvironmentFixedBase()
        shopEnvironmentRatio = shopEnvironmentRatio + areaData:GetEnvironmentRatioBase()
    end

    local addCustomerFixed = 0
    local addCustomerRatio = 0
    local addEnviromentFixed = 0
    local addEnviromentRatio = 0
    if self._AttrAdds then
        addCustomerFixed = self._AttrAdds[clientType.AddCustomerFix] or 0
        addCustomerRatio = self._AttrAdds[clientType.AddCustomerRatio] or 0
        addEnviromentFixed = self._AttrAdds[clientType.AddEnvironmentFix] or 0
        addEnviromentRatio = self._AttrAdds[clientType.AddEnvironmentRatio] or 0
    end
    local customerFixedTotal = customerBase + shopCustomerNumFixed + addCustomerFixed
    local customerRatioTotal = shopCustomerNumRatio + addCustomerRatio + denominator
    local customerNum = math.floor(customerFixedTotal * customerRatioTotal / denominator)

    local environmentFixedTotal = enviromentBase + shopEnvironment + addEnviromentFixed
    local environmentRatioTotal = addEnviromentRatio + shopEnvironmentRatio + denominator
    local environmentNum = math.floor(environmentFixedTotal * environmentRatioTotal / denominator)

    if not self.CalculateCache then self.CalculateCache = {} end
    self.CalculateCache[clientType.InitCustomerNum] = customerNum
    self.CalculateCache[clientType.InitEnvironment] = environmentNum
    self.CalculateCache[clientType.AddCustomerFix] = customerFixedTotal
    self.CalculateCache[clientType.AddCustomerRatio] = customerRatioTotal
    self.CalculateCache[clientType.AddEnvironmentFix] = environmentFixedTotal
    self.CalculateCache[clientType.AddEnvironmentRatio] = environmentRatioTotal
    for typeIndex, newValue in pairs(self.CalculateCache) do
        local lastNum = self._StageResInfo[typeIndex] or 0
        if lastNum ~= newValue then
            self._StageResInfo[typeIndex] = newValue
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH, typeIndex,  newValue - lastNum)
        end
    end
end

-- satisfactionNum2MusicPart
function XSkyGardenShoppingStreetModel:_UpdateMusicPart()
    if not XMVCA.XSkyGardenShoppingStreet:IsInGameUi() then return end
    local clientType = XMVCA.XSkyGardenShoppingStreet.StageResType
    local satisfactionNum = self._StageResInfo[clientType.InitFriendly]
    local customerNum = self._StageResInfo[clientType.InitCustomerNum]
    local part = self:GetMusicBySatisfactionAndCustomer(satisfactionNum, customerNum)
    if part ~= self._lastPart then
        XLuaAudioManager.SetMusicSourceFirstBlockIndex(part)
        self._lastPart = part
    end
end

-- 计算目标满意值
function XSkyGardenShoppingStreetModel:CalculateSatisfaction(isCache, isCacheAndUpdateShow)
    local denominator = 10000
    local clientType = XMVCA.XSkyGardenShoppingStreet.StageResType
    local addSatisfactionFixed = 0
    local addSatisfactionRatio = 0
    if self._AttrAdds then
        addSatisfactionFixed = self._AttrAdds[clientType.AddSatisfactionFixed] or 0
        addSatisfactionRatio = self._AttrAdds[clientType.AddSatisfactionRatio] or 0
    end
    local envSatisfactionNum = self._StageResInfo[clientType.EnvironmentSatisfaction] or 0
    local shopSatisfactionNum = self._StageResInfo[clientType.ShopScoreSatisfaction] or 0
    local satisfactionNum = XMath.Clamp(math.floor((shopSatisfactionNum + envSatisfactionNum + addSatisfactionFixed) * (addSatisfactionRatio + denominator) / denominator), 0, self:GetMaxSatisfactionSatisfaction())

    if isCache then
        local lastFriendlyCache = self._InitFriendlyCache
        self._InitFriendlyCache = satisfactionNum
        if isCacheAndUpdateShow then
            self:ClientSatisfactionGrow(self._InitFriendlyCache - lastFriendlyCache)
        end
    else
        local currentSatisfaction = self._StageResInfo[clientType.InitFriendly] or 0
        if satisfactionNum ~= currentSatisfaction then
            self._StageResInfo[clientType.InitFriendly] = satisfactionNum
            self._StageResInfo[clientType.OtherSatisfaction] = satisfactionNum - envSatisfactionNum - shopSatisfactionNum
            self:_UpdateMusicPart()
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH, clientType.InitFriendly, satisfactionNum - currentSatisfaction)
        end
    end
end

--region 数据初始化
-- 设置场景缓存数据
function XSkyGardenShoppingStreetModel:SetSceneStageData(sceneStageData)
    if not sceneStageData then return end
    self.SceneStageData = sceneStageData
end

-- 获取场景数据
function XSkyGardenShoppingStreetModel:GetX3CSceneData(data)
    local isGamePlay = data.IsGameplay
    local shopDatas, billboardData
    if isGamePlay then
        if self.StageDataNow then
            shopDatas = self.StageDataNow.ShopDatas
            billboardData = self.StageDataNow.BillboardData
        end
    else
        if self.StageDataNow then
            shopDatas = self.StageDataNow.ShopDatas
            billboardData = self.StageDataNow.BillboardData
        else
            if self.SceneStageData then
                shopDatas = self.SceneStageData.ShopDatas
                billboardData = self.SceneStageData.BillboardData
            end
        end
    end

    local shopPosData = {}
    if shopDatas then
        for _, shopData in pairs(shopDatas) do
            local shopPosition = shopData.Position
            if shopData.MainType == XMVCA.XSkyGardenShoppingStreet.XSgStreetShopMainType.Outside then
                shopPosition = shopPosition + self._InsideShowMaxNum
            end
            shopPosData[shopPosition] = shopData
        end
    end
    
    local maxStageId = self:GetMaxStageId()
    local stageShopConfig = self:GetStageShopConfigsByStageId(maxStageId)
    for i = 1, self._OutsideShowMaxNum do
        local shopData = shopPosData[self._InsideShowMaxNum + i]
        if not shopData then
            local shopId = stageShopConfig.OutsideShopGroup[i]
            shopPosData[self._InsideShowMaxNum + i] = {
                ShopId = shopId,
                Position = i,
                Level = 0,
                MainType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopMainType.Outside,
            }
        end
    end

    local shopList = {}
    for i = 1, self._InsideShowMaxNum + self._OutsideShowMaxNum do
        local shopData = shopPosData[i]
        if shopData then
            local shopId = shopData.ShopId
            local isInside = shopData.MainType == XMVCA.XSkyGardenShoppingStreet.XSgStreetShopMainType.Inside
            local placeId = self:GetPlaceIdByAreaId(i)
            local shopCfg = XMVCA.XSkyGardenShoppingStreet:GetShopConfigById(shopId, isInside)
            
            local shopLevel = shopData.Level
            local showLevel
            if shopLevel <= 0 then 
                showLevel = 0
            else
                local shopLvCfg = XMVCA.XSkyGardenShoppingStreet:GetShopLevelConfigById(shopId, shopLevel, isInside)
                showLevel = shopLvCfg.ShowLevel
            end

            table.insert(shopList, {
                PlaceId = placeId,
                SceneObjectBaseId = shopCfg.ShopResId,
                Level = showLevel,
            })
        end
    end

    local lightId = 0
    if billboardData then
        local billboardId = billboardData.CurrentBillboardId
        if billboardId > 0 then
            local billboardCfg = self:GetBillboardConfigById(billboardId)
            lightId = billboardCfg.EffectId
        end
    end
    return {
        ShopList = shopList,
        LightId = lightId,
    }
end

function XSkyGardenShoppingStreetModel:SetPassedStageIds(passedStageIds)
    if not passedStageIds then return end
    self.PassedStageIds = passedStageIds
    table.sort(self.PassedStageIds, function(a, b)
        return a < b
    end)
end

function XSkyGardenShoppingStreetModel:GetPassedStageIds()
    return self.PassedStageIds
end

function XSkyGardenShoppingStreetModel:CleanStageDataCache()
    if not self.StageDataCache then return end
    self.StageDataCache = false
    self:_UpdateStageData(self.StageDataNow, true)
end

function XSkyGardenShoppingStreetModel:SetStageDataCache(stageDataCache)
    self.StageDataCache = stageDataCache
end

-- 设置关卡数据
function XSkyGardenShoppingStreetModel:SetStageData(stageData)
    self.StageDataNow = stageData
    if self.StageDataCache then
        self:_UpdateStageData(self.StageDataCache, false)
    else
        self:_UpdateStageData(self.StageDataNow, true)
    end
end

-- 移除所有商铺
function XSkyGardenShoppingStreetModel:_RemoveSceneShop()
    local isInGame = XMVCA.XBigWorldGamePlay:IsInGame()
    if not isInGame then return end

    for i = 1, self._OutsideShowMaxNum + self._InsideShowMaxNum do
        local area = self._StageAreaShops[i]
        local lastShopId = area:GetShopId()
        if lastShopId > 0 then
            local lastAreaId = self:GetAreaIdByShopId(lastShopId, false)
            XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_DESTROY_BUILDING, {
                PlaceId = self:GetPlaceIdByAreaId(lastAreaId),
            })
        end
    end
end

-- 刷新商店数据
function XSkyGardenShoppingStreetModel:_UpdateStageData(stageData, isUpdate)
    if not self._StageAreaShops then
        self._StageAreaShops = {}
        for i = 1, self._InsideShowMaxNum do
            self._StageAreaShops[i] = XSGGameArea.New(i, true)
        end
        for i = 1, self._OutsideShowMaxNum do
            self._StageAreaShops[i + self._InsideShowMaxNum] = XSGGameArea.New(i, false)
        end
    end
    
    if isUpdate then
        self:ResetBase()
    end
    local stageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    if not stageData then
        if not self.StageData then self.StageData = {} end
        self.StageData.StageInit = false
        self._ShopId2Pos = {}
        self._UnlockOutsideShopCount = 0
        for i = 1, #self._StageAreaShops do
            local areaData = self._StageAreaShops[i]
            if not areaData.Reset then
                XLog.Warning("StageAreaShops Reset not found", i)
            else
                areaData:Reset()
            end
        end
    else
        -- 初始化商店区域数据(换关卡)
        if not self.StageData or not self.StageData.StageInit then
            self:ResetBase(true)
            self.StageDataNow = stageData
            local stageId = stageData.StageId
            local stageShopConfig = self:GetStageShopConfigsByStageId(stageId)
            self:_RemoveSceneShop()

            self._ShopId2Pos = {}
            self._UnlockOutsideShopCount = 0
            for i = 1, #self._StageAreaShops do
                local areaData = self._StageAreaShops[i]
                if not areaData.Reset then
                    XLog.Warning("StageAreaShops Reset not found", i)
                else
                    areaData:Reset()
                end
            end
            for _, pos in pairs(stageShopConfig.LockInsidePos) do
                self._StageAreaShops[pos]:SetLock(true)
            end
            for _, pos in pairs(stageShopConfig.LockOutsidePos) do
                self._StageAreaShops[self._InsideShowMaxNum + pos]:SetLock(true)
            end
            for i = 1, self._OutsideShowMaxNum do
                local shopId = stageShopConfig.OutsideShopGroup[i]
                if shopId and shopId > 0 then
                    self:UpdateShopAreaData({
                        ShopId = shopId,
                        Position = i,
                        Level = 0,
                        MainType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopMainType.Outside,
                    }, true, true)
                end
            end

            local config = self:GetStageConfigsByStageId(stageId)
            for key, value in pairs(stageResType) do
                self._StageResInfo[value] = 0
                self._StageBaseResInfo[value] = config[key]
            end
            self:_InitMascot(stageId)
        end
        self.StageData = stageData
        self.StageData.StageInit = true
        self:SetRecommendShopId(stageData.RecommendShopId)
        if self.StageData.PromotionSelectGroups then
            for _, data in ipairs(self.StageData.PromotionSelectGroups) do
                self:UpdatePromotionData(data)
            end
        end
    end

    -- 同步商店数据
    if self.StageData.ShopDatas then
        for i = 1, #self.StageData.ShopDatas do
            local shopData = self.StageData.ShopDatas[i]
            -- 不会增加 同一个shopdatas
            self:UpdateShopAreaData(shopData, true)
        end
        self:CalculateProperty()
    end
    
    self._StageResInfo[stageResType.EnvironmentSatisfaction] = self.StageData.EnvironmentSatisfaction
    self._StageResInfo[stageResType.ShopScoreSatisfaction] = self.StageData.ShopScoreSatisfaction
    self:CalculateSatisfaction()

    self:SetSettleData(self.StageData.LastResultData)
    self:SetBuffsData(self.StageData.BuffDatas, isUpdate, not isUpdate)
    if isUpdate then
        self:SetResourceDatas(self.StageData.ResourceDatas)
        self:SetNewsDatas(self.StageData.NewsDatas)
        self:SetGrapevineDatas(self.StageData.ShopGrapevineDatas)
        self:SetBillboardData(self.StageData.BillboardData)
        self:SetStatisticsData(self.StageData.StatisticsData)
        self:SetTaskDatas(self.StageData.TaskDatas)
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH)
end

-- 刷新商店数据
function XSkyGardenShoppingStreetModel:UpdateShopAreaData(shopData, isSkipEvent, isSkipDataUpdate)
    if not shopData then return end

    local shopPosition = shopData.Position
    local isOutside = shopData.MainType == XMVCA.XSkyGardenShoppingStreet.XSgStreetShopMainType.Outside
    if isOutside then
        shopPosition = shopPosition + self._InsideShowMaxNum
    end
    local areaData = self._StageAreaShops[shopPosition]
    local lastLv = areaData:GetShopLevel()
    areaData:SetAreaData(shopData)
    local shopId = shopData.ShopId
    local hasShop = self._ShopId2Pos[shopId]
    self._ShopId2Pos[shopId] = shopPosition
    local newLv = areaData:GetShopLevel()
    if lastLv == 0 and lastLv ~= newLv and not areaData:IsInside() then
        self._UnlockOutsideShopCount = self._UnlockOutsideShopCount + 1
    end
    local isFound = false
    for i = 1, #self.StageDataNow.ShopDatas do
        local data = self.StageDataNow.ShopDatas[i]
        if data.ShopId == shopId then
            isFound = true
            if not isSkipDataUpdate then
                self.StageDataNow.ShopDatas[i] = shopData
            end
            break
        end
    end
    if not isFound then
        table.insert(self.StageDataNow.ShopDatas, shopData)
    end

    if not isSkipEvent or isOutside then
        local isInGame = XMVCA.XBigWorldGamePlay:IsInGame()
        if isInGame then
            local areaId = self:GetAreaIdByShopId(shopId, false)
            if not hasShop then
                XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CREATE_BUILDING, {
                    PlaceId = self:GetPlaceIdByAreaId(areaId),
                    SceneObjectBaseId = areaData:GetShopResId(),
                })
            end
            local showLevel = areaData:GetShopShowLevel()
            XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_BUILDING_APPEARANCE, {
                PlaceId = self:GetPlaceIdByAreaId(areaId),
                Level = showLevel,
                IsShowProjection = true,
            })
        end

        local isInside = shopPosition <= self._InsideShowMaxNum
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH, shopPosition, isInside)

        self:CalculateProperty()
    end
end

function XSkyGardenShoppingStreetModel:UpdateCurrentTurnInsideBuilds(CurrentTurnInsideBuilds)
    if not self.StageData then return end
    self.StageData.CurrentTurnInsideBuilds = CurrentTurnInsideBuilds
end

-- 拆除商店数据
function XSkyGardenShoppingStreetModel:DestroyShop(ShopId)
    local shopPosition = self._ShopId2Pos[ShopId]
    local areaData = self._StageAreaShops[shopPosition]

    areaData:Reset()
    self._ShopId2Pos[ShopId] = nil
    if self.StageData.CurrentTurnInsideBuilds and table.contains(self.StageData.CurrentTurnInsideBuilds, ShopId) then
        self.StageData.InsideBuildTimes = 0
    end
    for i = 1, #self.StageDataNow.ShopDatas do
        local data = self.StageDataNow.ShopDatas[i]
        if data.ShopId == ShopId then
            table.remove(self.StageDataNow.ShopDatas, i)
            break
        end
    end

    local isInside = shopPosition <= self._InsideShowMaxNum
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH, shopPosition, isInside)
    self:CalculateProperty()
end

function XSkyGardenShoppingStreetModel:ClientSatisfactionGrow(growValue)
    if growValue == 0 then return end

    local clientType = XMVCA.XSkyGardenShoppingStreet.StageResType.InitFriendly
    local currentNum = self._StageResInfo[clientType] or 0
    if currentNum == self._InitFriendlyCache then return end

    local add
    local growValueMax = math.abs(currentNum - self._InitFriendlyCache)
    if self._InitFriendlyCache < currentNum then
        add = -math.min(growValue, growValueMax)
    else
        add = math.min(growValue, growValueMax)
    end

    local growSatisfaction = XMath.Clamp(currentNum + add, 0, self:GetMaxSatisfactionSatisfaction())
    if growSatisfaction == currentNum then return end

    self._StageResInfo[clientType] = growSatisfaction
    self:_UpdateMusicPart()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH, clientType, growSatisfaction - currentNum)
end

-- 资源刷新
function XSkyGardenShoppingStreetModel:SetResourceDatas(resDatas)
    if not resDatas or self.StageDataCache then return end

    local hasChange = false
    local changeType = XMVCA.XSkyGardenShoppingStreet.XSgStreetResourceId.Gold
    local clientType = XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold
    for i = 1, #resDatas do
        local resData = resDatas[i]
        if resData.ResourceId == changeType then
            if self._StageResInfo[clientType] ~= resData.Count then
                self._StageResInfo[clientType] = resData.Count
                hasChange = true
            end
        end
    end
    if hasChange then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH, clientType)
    end
end

-- 客户端操作设置资源数据
function XSkyGardenShoppingStreetModel:ClientAddResourceByAwardGold(shopAwardGold, skipCount)
    if shopAwardGold == 0 then return end
    if not skipCount then
        self._TotalAwardGold = self._TotalAwardGold + shopAwardGold
    end
    local clientType = XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold
    self._StageResInfo[clientType] = self._StageResInfo[clientType] + shopAwardGold
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_RES_REFRESH, clientType, shopAwardGold)
end

-- 客户端操作添加buff
function XSkyGardenShoppingStreetModel:ClientAddBuffByBuffId(buffId)
    if buffId and buffId <= 0 then return end
    local buffCfg = self:GetBuffConfigById(buffId)
    self:_AddBuffData({
        Id = self._buffIdCount,
        BuffId = buffId,
        RemainingTurn = buffCfg.Duration,
        CreateTurn = self:GetRunRound(),
    }, true)
    self._buffIdCount = self._buffIdCount - 1
    self._clientAddBuff[buffId] = (self._clientAddBuff[buffId] or 0) + 1

    if not self._BuffEffectFunc then
        self._BuffEffectFunc = {
            [1] = function(buffConfig)
                local baseNum = self._AttrAdds[buffConfig.Params[1]] or 0
                self._AttrAdds[buffConfig.Params[1]] = baseNum + buffConfig.Params[2]
                self:CalculateProperty()
                self:CalculateSatisfaction(true, true)
            end,
            [2] = function(buffConfig)
                self:ClientAddResourceByAwardGold(buffConfig.Params[1], true)
            end,
        }
    end
    local func = self._BuffEffectFunc[buffCfg.Type]
    if func then func(buffCfg) end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUFF_REFRESH)
end

-- ResetBase
function XSkyGardenShoppingStreetModel:ResetBase(isInit)
    if isInit then
        self.StageDataNow = false
        self._IsShowBillboardInfo = false
        self._FinishShowTargets = false
        self._BillboardData = nil
        if self.StageData then self.StageData.StageInit = false end
    end
    self._NewsDatas = {}
    self._ShopGrapevineDatas = {}
    self.TaskDatas = {}
    self.LimitTaskData = nil
    self.PromotionDatas = {}
    self._StageTaskAllFinish = false
    self._FinishTaskCacheList = {}
    self._AchievedTaskIds = false
end

-- 放弃关卡
function XSkyGardenShoppingStreetModel:GiveupStage()
    self:ResetBase(true)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH)
end

-- 设置buff叠加属性
function XSkyGardenShoppingStreetModel:SetAttrsData(attrAdds)
    self._AttrAdds = attrAdds
    self:CalculateProperty()
    self:CalculateSatisfaction()
end

function XSkyGardenShoppingStreetModel:GetAttrsDataByType(attrType)
    if not self._AttrAdds then return 0 end
    return self._AttrAdds[attrType] or 0
end

-- 设置buff商铺叠加属性
function XSkyGardenShoppingStreetModel:SetShopAttrAdds(shopAttrAdds)
    self._ShopAttrAdds = shopAttrAdds
end

-- 获取buff显示
function XSkyGardenShoppingStreetModel:_AddBuffShow(buffDatas)
    local buffCfg = self:GetBuffConfigById(buffDatas.BuffId)
    if buffCfg.GetShowType ~= 1 then return end

    if not self._ShowGetBuffList then
        self._ShowGetBuffList = {}
    end

    table.insert(self._ShowGetBuffList, buffDatas)
    XMVCA.XSkyGardenShoppingStreet:ShowGetBuff()
end

function XSkyGardenShoppingStreetModel:PopGetShowBuff()
    if not self._ShowGetBuffList or #self._ShowGetBuffList <= 0 then return end
    return table.remove(self._ShowGetBuffList, 1)
end

-- 增加buff数据
function XSkyGardenShoppingStreetModel:_AddBuffData(buffDatas, isNew)
    table.insert(self._GameBuffs, buffDatas)
    if isNew then self:_AddBuffShow(buffDatas) end
end

-- 设置buff数据
function XSkyGardenShoppingStreetModel:SetBuffsData(buffDatas, isUpdate, isForceCache)
    if not isForceCache and self.StageDataCache then return end
    local hasBuffList = false
    if isUpdate and buffDatas and self._GameBuffs then
        for _, buffData in pairs(self._GameBuffs) do
            if not hasBuffList then hasBuffList = {} end
            hasBuffList[buffData.Id] = true
        end
    end

    self._GameBuffs = {}
    if buffDatas then
        for _, buffData in pairs(buffDatas) do
            local isNew = false
            if hasBuffList and not hasBuffList[buffData.Id] then
                if not self._clientAddBuff or not self._clientAddBuff[buffData.BuffId] then
                    isNew = true
                end
            end
            self:_AddBuffData(buffData, isNew)
        end
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUFF_REFRESH)
end

-- 新闻数据
function XSkyGardenShoppingStreetModel:SetNewsDatas(newsDatas)
    self._NewsDatas = {}
    if not newsDatas then return end
    for _, data in ipairs(newsDatas) do
        self._NewsDatas[data.Turn] = data
    end
end

-- 小道消息数据
function XSkyGardenShoppingStreetModel:SetGrapevineDatas(grapevineDatas)
    self._ShopGrapevineDatas = {}
    if not grapevineDatas then return end
    for _, data in ipairs(grapevineDatas) do
        self._ShopGrapevineDatas[data.Turn] = data
    end
end

-- 结算关卡
function XSkyGardenShoppingStreetModel:SetSettleData(settleData)
    self.SettleResultData = settleData
    -- if settleData then
    --     self._TaskOverTurn = settleData.BillboardNextRefreshTurn or 0
    -- else
    --     self._TaskOverTurn = 0
    -- end
end

-- 获取昨日结算信息
function XSkyGardenShoppingStreetModel:GetSettleResultData()
    return self.SettleResultData
end

-- 促销数据
function XSkyGardenShoppingStreetModel:UpdatePromotionData(promotionData)
    self.PromotionDatas[promotionData.Id] = promotionData
end

-- 获取促销数据
function XSkyGardenShoppingStreetModel:GetPromotionData()
    return self.PromotionDatas
end

-- 获取促销数据
function XSkyGardenShoppingStreetModel:FinishPromotion(index)
    self.PromotionDatas[index] = nil
end

-- 是否有促销
function XSkyGardenShoppingStreetModel:HasPromotion()
    return table.nums(self.PromotionDatas) > 0
end

-- 获取已选促销数量
function XSkyGardenShoppingStreetModel:GetSelectedPromotionCount()
    return #self.StageData.PromotionSelectGroups
end

-- 设置推荐商铺
function XSkyGardenShoppingStreetModel:SetRecommendShopId(recommendShopId)
    self._RecommendShopId = recommendShopId
end

-- 获取推荐商店Id
function XSkyGardenShoppingStreetModel:GetRecommendShopId()
    return self._RecommendShopId
end

-- 关卡是否为空
function XSkyGardenShoppingStreetModel:IsStageEmpty()
    return not self.StageData.StageInit
end

-- 是否在运行中
function XSkyGardenShoppingStreetModel:IsStageRunning()
    return self.StageData.StageInit
end

-- 是否在运行中
function XSkyGardenShoppingStreetModel:GetMaxStageId()
    if self._MaxStageId then return self._MaxStageId end

    local stageCfgs = self:GetAllStageConfigs()
    for _, stageCfg in ipairs(stageCfgs) do
        self._MaxStageId = math.max(self._MaxStageId or 0, stageCfg.Id)
    end
    return self._MaxStageId
end

-- 获取目标关卡id
function XSkyGardenShoppingStreetModel:GetTargetStageId()
    local maxStageId = self:GetMaxStageId()
    -- 获取历史最高id + 1，如果没有用第一关
    local history = self:GetPassedStageIds()
    if history and #history > 0 then
        local newTarget = history[#history] + 1
        return math.min(newTarget, maxStageId)
    end
    local newTarget = tonumber(self:GetGlobalConfigByKey("DefaultStageId")) or 1
    return math.min(newTarget, maxStageId)
end

-- 获取当前关卡id
function XSkyGardenShoppingStreetModel:GetCurrentStageId(isSafe)
    if self:IsStageEmpty() and isSafe then
        -- 目标关卡id获取
        return self:GetTargetStageId()
    end
    return self.StageData.StageId
end

function XSkyGardenShoppingStreetModel:GetShopCustomerNumInTurnByShopId(shopId)
    local settleStatisticData = self.SettleResultData.CurrentSettleStatisticData
    if not settleStatisticData then return 0 end
    local nums = settleStatisticData.CustomerNums
    if not nums then return 0 end
    return nums[shopId] or 0
end

function XSkyGardenShoppingStreetModel:GetShopCustomerNumInLastTurnByShopId(shopId)
    local settleStatisticData = self.SettleResultData.LastSettleStatisticData
    if not settleStatisticData then return 0 end
    local nums = settleStatisticData.CustomerNums
    if not nums then return 0 end
    return nums[shopId] or 0
end

function XSkyGardenShoppingStreetModel:GetShopScoreInLastTurnByShopId(shopId)
    local settleStatisticData = self.SettleResultData.LastSettleStatisticData
    if not settleStatisticData then return 0 end
    local nums = settleStatisticData.ShopScoreDatas
    if not nums then return 0 end
    return (nums[shopId] or 0) / 10000
end

-- 设置统计数据
function XSkyGardenShoppingStreetModel:SetStatisticsData(statisticsData)
    self.StatisticsData = statisticsData
end

-- 设置任务数据
function XSkyGardenShoppingStreetModel:SetTaskDatas(taskDatas, isUpdate)
    if not taskDatas then return end

    local XSgStreetTaskState = XMVCA.XSkyGardenShoppingStreet.XSgStreetTaskState
    local XSgStreetTaskSource = XMVCA.XSkyGardenShoppingStreet.XSgStreetTaskSource

    for _, data in pairs(taskDatas) do
        local oldData = self.TaskDatas[data.Id]
        if oldData and oldData.Source == XSgStreetTaskSource.StageTarget then
            if oldData.State == XSgStreetTaskState.Activated and data.State ~= XSgStreetTaskState.Activated then
                if not self._FinishShowTargets then self._FinishShowTargets = {} end
                if not table.contains(self._FinishShowTargets, data.ConfigId) then
                    table.insert(self._FinishShowTargets, data.ConfigId)
                end
            end
        end
        self.TaskDatas[data.Id] = data
        if data.Source == XSgStreetTaskSource.Billboard then
            self.LimitTaskData = data
            self.LimitTaskSchedule = data.Schedule
        end
    end

    -- 检查到达目标的任务
    self._AchievedTaskIds = false
    -- 检查完成所有主线通关
    self._StageTaskAllFinish = true
    for _, data in pairs(self.TaskDatas) do
        if data.Source == XSgStreetTaskSource.Billboard then
            if data.State == XSgStreetTaskState.Achieved then
                self.LimitTaskData.State = XSgStreetTaskState.Finished
                if not self._FinishTaskCacheList[data.Id] then
                    if not self._AchievedTaskIds then self._AchievedTaskIds = {} end
                    table.insert(self._AchievedTaskIds, data.Id)
                end
            end
        else
            if data.State == XSgStreetTaskState.Activated then
                self._StageTaskAllFinish = false
            end
        end
    end

    XMVCA.XSkyGardenShoppingStreet:TryTaskFinish()
end

-- 获取达成的任务ids
function XSkyGardenShoppingStreetModel:GetFinishShowTargets()
    local list = self._FinishShowTargets
    self._FinishShowTargets = false
    return list
end

-- 获取达成的任务ids
function XSkyGardenShoppingStreetModel:GetAchievedTaskIds()
    return self._AchievedTaskIds
end

function XSkyGardenShoppingStreetModel:ClearAchievedTaskIds()
    self._AchievedTaskIds = false
end

-- 获取限时任务
function XSkyGardenShoppingStreetModel:GetLimitTask()
    return self.LimitTaskData
end

function XSkyGardenShoppingStreetModel:GetLimitTaskSchedule()
    return self.LimitTaskSchedule
end

-- 移除任务数据
function XSkyGardenShoppingStreetModel:RemoveTaskDatas(taskIds)
    if not taskIds then return end
    local XSgStreetTaskSource = XMVCA.XSkyGardenShoppingStreet.XSgStreetTaskSource
    for _, taskId in pairs(taskIds) do
        local data = self.TaskDatas[taskId]
        self._FinishTaskCacheList[taskId] = true
        if data and data.Source == XSgStreetTaskSource.Billboard then
            self.TaskDatas[taskId] = nil
        end
    end
end

-- 是否完成所有关卡任务
function XSkyGardenShoppingStreetModel:IsFinishAllStageTask()
    return self._StageTaskAllFinish
end

function XSkyGardenShoppingStreetModel:GetTaskDataById(taskId)
    return self.TaskDatas[taskId]
end

function XSkyGardenShoppingStreetModel:GetTaskDataByConfigId(taskConfigId)
    if not self.TaskDatas then return end
    for _, data in pairs(self.TaskDatas) do
        if data.ConfigId == taskConfigId then
            return data
        end
    end
end

--endregion

--region 自定义数据
function XSkyGardenShoppingStreetModel:GetMaxSatisfactionSatisfaction()
    if not self._MaxSatisfactionSatisfaction then
        self._MaxSatisfactionSatisfaction = tonumber(self:GetGlobalConfigByKey("MaxSatisfactionSatisfaction")) or 100
    end
    return self._MaxSatisfactionSatisfaction
end

--- 获取所有商店区域数据
function XSkyGardenShoppingStreetModel:GetAllShopAreas()
    return self._StageAreaShops
end

-- 获取所有商店区域数据
function XSkyGardenShoppingStreetModel:GetShopAreas(isInside)
    local baseNum = isInside and 0 or self._InsideShowMaxNum
    local startNum = baseNum + 1
    local addNum = isInside and self._InsideShowMaxNum or self._OutsideShowMaxNum
    local endNum = baseNum + addNum
    local list = {}
    for i = startNum, endNum do
        table.insert(list, self._StageAreaShops[i])
    end
    return list
end

-- 通过ui pos获取真实pos
function XSkyGardenShoppingStreetModel:GetAreaIdByUiPos(pos, isInside)
    return isInside and pos or pos + self._InsideShowMaxNum
end

-- 获取某个位置的商店数据
function XSkyGardenShoppingStreetModel:GetShopAreaByUiPos(pos, isInside)
    local realPos = self:GetAreaIdByUiPos(pos, isInside)
    return self._StageAreaShops[realPos]
end

-- 获取某个位置的商店数据
function XSkyGardenShoppingStreetModel:GetShopAreaByShopId(shopId, isInside)
    local pos = self:GetAreaIdByShopId(shopId)
    return self._StageAreaShops[pos]
end

-- 获取PlaceID
function XSkyGardenShoppingStreetModel:GetAreaIdByShopId(shopId)
    return self._ShopId2Pos[shopId]
end

-- 获取UI Pos
function XSkyGardenShoppingStreetModel:GetUiPositionByShopId(shopId, isInside)
    if isInside then
        return self._ShopId2Pos[shopId]
    else
        return self._ShopId2Pos[shopId] - self._InsideShowMaxNum
    end
end

-- 满足资源数量
function XSkyGardenShoppingStreetModel:EnoughStageResById(cost, resId)
    return cost <= self._StageResInfo[resId or XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold]
end

-- 获取资源数据
function XSkyGardenShoppingStreetModel:GetStageResById(resId)
    return self._StageResInfo[resId] or 0
end

-- 是否有新闻或小道消息
function XSkyGardenShoppingStreetModel:HasNewsOrGrapevinesTipsByTurn(turn)
    local checkTurn = turn or self:GetRunRound()
    return self._NewsDatas[checkTurn] or self._ShopGrapevineDatas[checkTurn]
end

-- 获取新闻数据
function XSkyGardenShoppingStreetModel:GetStageNews()
    return self._NewsDatas
end

-- 获取小道消息数据
function XSkyGardenShoppingStreetModel:GetStageGrapevines()
    return self._ShopGrapevineDatas
end

--- 获取buff数据
---@param buffId number buffId
function XSkyGardenShoppingStreetModel:GetStageGameBuff(buffId)
    if not self._GameBuffs then return end
    for _, v in pairs(self._GameBuffs) do
        if v.buffId == buffId then return v end
    end
end

-- buff排序
function XSkyGardenShoppingStreetModel._StageGameBuffsSort(a, b)
    if a.CreateTurn ~= b.CreateTurn then
        return a.CreateTurn > b.CreateTurn
    end
    return a.Id > b.Id
end

-- buff加入过滤
function XSkyGardenShoppingStreetModel:_StageGameBuffDefaultFilterFunc(buffId)
    local buffCfg = self:GetBuffConfigById(buffId)
    return buffCfg.ShowType == 1
end

--- 获取buff数据
function XSkyGardenShoppingStreetModel:GetStageGameBuffs(getCount)
    if not self._GameBuffs then return end
    table.sort(self._GameBuffs, self._StageGameBuffsSort)
    local outPutCount = getCount or #self._GameBuffs
    local count = 0
    local buffs = {}
    for _, serverBuff in pairs(self._GameBuffs) do
        if self:_StageGameBuffDefaultFilterFunc(serverBuff.BuffId) then
            table.insert(buffs, serverBuff)
            count = count + 1
            if count >= outPutCount then break end
        end
    end
    return buffs
end
--endregion

--region 灯带
-- 设置灯带数据
function XSkyGardenShoppingStreetModel:SetBillboardData(billboardData)
    if self._BillboardData and billboardData and not self._IsShowBillboardInfo then
        local isNextTurn = (billboardData.LastRefreshTurn or 0) == self:GetRunRound()
        local lastFinish = self._BillboardData.CurrentTaskId == 0
        local changeToFinish = not isNextTurn and self._BillboardData.CurrentTaskId ~= 0 and billboardData.CurrentTaskId == 0
        self._IsShowBillboardInfo = (isNextTurn and not lastFinish) or changeToFinish
        self._IsFinishBillboardTaskSuccess = not isNextTurn and changeToFinish
        self._EndBillboardId = self._BillboardData.CurrentBillboardId
    end

    self._BillboardData = billboardData
    if billboardData then
        if not self._BillboardRefreshTurn then
            self._BillboardRefreshTurn = tonumber(self:GetGlobalConfigByKey("BillboardRefreshTurn")) or 0
        end
        self._TaskOverTurn = self._BillboardRefreshTurn + (billboardData.LastRefreshTurn or 0)
        self:UpdateBillboardId(billboardData.CurrentBillboardId, billboardData.RandomBillboards)
    else
        self._TaskOverTurn = 0
        self:UpdateBillboardId(-1)
    end
end

-- 任务完成检测灯带任务
function XSkyGardenShoppingStreetModel:TaskFinishCheckBillborad(taskId)
    if not self._BillboardData then return end
    if self._BillboardData.CurrentTaskId == taskId then
        self._IsShowBillboardInfo = true
        self._IsFinishBillboardTaskSuccess = true
        self._EndBillboardId = self._BillboardData.CurrentBillboardId
    end
end

-- 清理完成限时任务
function XSkyGardenShoppingStreetModel:CleanFinishLimitTask()
    self._IsShowBillboardInfo = false
    if self._BillboardData then
        self._BillboardData.CurrentTaskId = 0
    end
end

-- 是否完成限时任务需要显示
function XSkyGardenShoppingStreetModel:IsFinishLimitTask()
    return self._IsShowBillboardInfo
end

-- 获取完成限时任务Id
function XSkyGardenShoppingStreetModel:GetEndBillboardId()
    return self._EndBillboardId
end

-- 限时任务结算是否成功
function XSkyGardenShoppingStreetModel:IsFinishBillboardTaskSuccess()
    return self._IsFinishBillboardTaskSuccess
end

function XSkyGardenShoppingStreetModel:UpdateBillboardTaskId(taskId)
    if not self._BillboardData then return end
    self._BillboardData.CurrentTaskId = taskId or 0
end

-- 设置灯带
function XSkyGardenShoppingStreetModel:UpdateBillboardId(selectBillboardId, randomBillboards)
    if self._BillboardData then
        self._BillboardData.CurrentBillboardId = selectBillboardId
    end
    self._BillboardSelectId = selectBillboardId
    self._RandomBillboards = randomBillboards

    local lightId = 0
    if self._BillboardSelectId and self._BillboardSelectId > 0 then
        local billboardCfg = XMVCA.XSkyGardenShoppingStreet:GetBillboardConfigById(self._BillboardSelectId)
        lightId = billboardCfg.EffectId
    end
    XMVCA.XSkyGardenShoppingStreet:X3CLightChange(lightId)
end

function XSkyGardenShoppingStreetModel:GetBillboardLeftTurn()
    return self._TaskOverTurn - self:GetRunRound()
end

-- 灯带Id
function XSkyGardenShoppingStreetModel:GetStageBillboardsSelectedId()
    return self._BillboardSelectId or 0
end

-- 获取灯带任务列表
function XSkyGardenShoppingStreetModel:GetStageBillboards()
    return self._RandomBillboards
end
--endregion

--------------------------------------------------------------------------------
--region 运营阶段模块
-- 商店建造消耗减少
function XSkyGardenShoppingStreetModel:ShopBuildCostReduceBySubType(subType, cost)
    local shopAttrAdds = self._ShopAttrAdds[subType]
    if not shopAttrAdds then return cost end

    local denominator = 10000
    local XSgStreetShopAttrType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopAttrType
    local addCost = shopAttrAdds[XSgStreetShopAttrType.BuildCostAddRatio] or 0
    local addCostRatio = math.min(denominator, addCost) / denominator
    return math.floor((1 + addCostRatio) * cost)
end

-- 商店升级消耗减少
function XSkyGardenShoppingStreetModel:ShopUpgradeCostReduceBySubType(subType, cost)
    local shopAttrAdds = self._ShopAttrAdds[subType]
    if not shopAttrAdds then return cost end

    local denominator = 10000
    local XSgStreetShopAttrType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopAttrType
    local addCost = shopAttrAdds[XSgStreetShopAttrType.UpgradeCostAddRatio] or 0
    local addCostRatio = math.min(denominator, addCost) / denominator
    return math.floor((1 + addCostRatio) * cost)
end

-- 商店销毁返还
function XSkyGardenShoppingStreetModel:GetShopRemoveReturnAddRatio()
    local num = self._AttrAdds[XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.ShopRemoveReturnAddRatio] or 0
    return num
end

-- 自动不满事件buff
function XSkyGardenShoppingStreetModel:AutoDiscontentEvent()
    local num = self._AttrAdds[XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.DiscontentAutoHandle] or 0
    return num > 0
end

-- 自动反馈事件buff
function XSkyGardenShoppingStreetModel:AutoFeedbackEvent()
    local num = self._AttrAdds[XMVCA.XSkyGardenShoppingStreet.XSgStreetAttrType.FeedbackAutoHandle] or 0
    return num > 0
end

-- 出现过的所有小道消息
function XSkyGardenShoppingStreetModel:GetAllGrapevineIds()
    if not self.StatisticsData then return end
    return self.StatisticsData.AllGrapevineIds
end

-- 获取完成任务次数
function XSkyGardenShoppingStreetModel:GetFinishTaskTimesBySourceType(sourceType)
    if not self.StatisticsData then return 0 end
    return self.StatisticsData.FinishTaskTimeDict[sourceType]
end

-- 单日最高流水金额
function XSkyGardenShoppingStreetModel:GetMaxDailyGold()
    if not self.StatisticsData then return 0 end
    return self.StatisticsData.MaxDailyGold
end

-- 获取促销进度
function XSkyGardenShoppingStreetModel:GetPromotionCount()
    if not self.StatisticsData then return 0 end
    return self.StatisticsData.PromotionTimes
end

-- 获取不满事件数量
function XSkyGardenShoppingStreetModel:GetDiscontentEventCount()
    if not self.StatisticsData then return 0 end
    return self.StatisticsData.DiscontentEventTimes
end

-- 获取突发事件数量
function XSkyGardenShoppingStreetModel:GetEmergencyEventCount()
    if not self.StatisticsData then return 0 end
    return self.StatisticsData.EmergencyEventTimes
end

-- 不满事件处理
function XSkyGardenShoppingStreetModel:DoDiscontentEvent(Id, AwardGold)
    table.insert(self._EventResults, {
        Id = Id,
        -- DiscontentIsClear = true,
    })
    self:ClientAddResourceByAwardGold(AwardGold)
end

-- 突发事件选择
function XSkyGardenShoppingStreetModel:DoEmergencyEvent(Id, EmergencyOptionIndex, buffId)
    table.insert(self._EventResults, {
        Id = Id,
        EmergencyOptionIndex = EmergencyOptionIndex,
    })
    self:ClientAddBuffByBuffId(buffId)
end

-- 反馈处理
function XSkyGardenShoppingStreetModel:DoFeedbackEvent(Id)
    table.insert(self._EventResults, {
        Id = Id,
    })
end

-- 获取回合结算上行数据
function XSkyGardenShoppingStreetModel:GetSettleData()
    local requestData = {
        AwardGold = self._TotalAwardGold,
        EventResults = self._EventResults,
    }
    -- XMessagePack.MarkAsTable(requestData.FeedBackResults)
    return requestData
end

function XSkyGardenShoppingStreetModel:IsRunningGame()
    return self._IsRoundRunning or false
end

function XSkyGardenShoppingStreetModel:StartRunningGame()
    self._IsRoundRunning = true
end

function XSkyGardenShoppingStreetModel:TryStartAutoRunRound()
    if self.StageData.OperatingData == nil then return false end
    self:StartRunRound(self.StageData.OperatingData)
    return true
end

function XSkyGardenShoppingStreetModel:StartRunRound(operatingData)
    self._clientAddBuff = {}
    self._buffIdCount = -1
    -- 后面优化顾客数据
    self._TotalAwardGold = 0
    self._EventResults = {}

    self._Customers = {}
    self._IsRoundRunning = true

    if not operatingData then return end

    local StageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    self._SatisfactionGrowPercentage = 0
    -- self._StartSatisfactionNum = self._StageResInfo[StageResType.InitFriendly]
    self._StageResInfo[StageResType.EnvironmentSatisfaction] = operatingData.EnvironmentSatisfaction
    self._StageResInfo[StageResType.ShopScoreSatisfaction] = operatingData.ShopScoreSatisfaction
    self:CalculateSatisfaction(true)

    local datas = operatingData.CustomerDatas
    if not datas then return end
    for i = 1, #datas do
        local index = i
        if not self._Customers[index] then
            self._Customers[index] = XSGGameCustomer.New()
        end
        self._Customers[index]:SetCustomerData(datas[i])
    end
end

function XSkyGardenShoppingStreetModel:GetCustomerHeadIcon(id)
    local stageId = self:GetCurrentStageId()
    local customerParamCfg = self:GetCustomerParamByStageId(stageId)
    local customerCfgs = self:GetCustomerCfgsByGroup(customerParamCfg.CustomerHeadIconGroup)
    if not customerCfgs then return end
    local maxHead = #customerCfgs
    local headId = (id or 0) % maxHead + 1
    return customerCfgs[headId].HeadIcon
end

function XSkyGardenShoppingStreetModel:GetCustomerFeedHeadIcon(feedbackId, randId)
    local feedbackCfg = self:GetFeedbackConfigsById(feedbackId)
    local customerCfgs = self:GetFeedbackIconByGroupId(feedbackCfg.IconGroupId)
    if not customerCfgs then return end
    local maxHead = #customerCfgs
    local headId = math.random(1, maxHead)
    if randId then
        headId = randId % maxHead + 1
    end
    return customerCfgs[headId]
end

function XSkyGardenShoppingStreetModel:EndRunRound()
    self._IsRoundRunning = false
end

function XSkyGardenShoppingStreetModel:GetRunRound()
    return self.StageData.Turn
end

-- 是否可以建商铺
function XSkyGardenShoppingStreetModel:CanBuildShop(isInside)
    if isInside then
        return not self.StageData.CurrentTurnInsideBuilds or #self.StageData.CurrentTurnInsideBuilds <= 0 -- self.StageData.InsideBuildTimes == 0
    end
    return true
end

-- 是否满足条件建造外圈商铺
function XSkyGardenShoppingStreetModel:CanUnlockOutisdeShop()
    local satisfactionNum = self:GetStageResById(XMVCA.XSkyGardenShoppingStreet.StageResType.InitFriendly)
    local cfg = self:GetUnlockOutsideShopConfigByOutsideShopNum(self._UnlockOutsideShopCount)
    return satisfactionNum >= cfg.NeedSatisfaction, cfg
end

function XSkyGardenShoppingStreetModel:GetCustomerCount()
    return #self._Customers
end

function XSkyGardenShoppingStreetModel:GetCustomerByIndex(index)
    return self._Customers[index]
end
--endregion
--------------------------------------------------------------------------------
----------public end----------

--region 内部初始化
----------private start----------
function XSkyGardenShoppingStreetModel:_InitMascot(stageId)
    if not self._Mascot then
        self._Mascot = XSGGameMascot.New()
    end
    local config = self:GetStageConfigsByStageId(stageId)
    local mascotConfig = self:GetMascotConfig()
    self._Mascot:InitByConfig(config.MascotGroupId, config.MascotLikeGroupId, mascotConfig)
end

function XSkyGardenShoppingStreetModel:ShowLikeMessage()
    if not self._Mascot then return end
    self._Mascot:AddLikeMessageTag()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH)
end

function XSkyGardenShoppingStreetModel:GetMascotData()
    return self._Mascot
end

function XSkyGardenShoppingStreetModel:_ResetAll()
    -- 商店id转位置
    self._ShopId2Pos = {}
    self._StageResInfo = {}
    self._StageBaseResInfo = {}
    self._StageAreaShops = nil
    self._BillboardData = nil
    self._FinishShowTargets = false

    --------------------------------------------------------------------------------
    self.StageData = nil
end
----------private end----------
--endregion


return XSkyGardenShoppingStreetModel