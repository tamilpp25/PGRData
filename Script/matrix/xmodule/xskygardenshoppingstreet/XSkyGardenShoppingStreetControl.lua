---@class XSkyGardenShoppingStreetControl : XControl
---@field private _Model XSkyGardenShoppingStreetModel
local XSkyGardenShoppingStreetControl = XClass(XControl, "XSkyGardenShoppingStreetControl")

--region 框架
function XSkyGardenShoppingStreetControl:OnInit()
    --初始化内部变量
    self._PrefsSaveNewsKey = XPlayer.Id .. "_SS_NewsStatus"
    self._PrefsSaveSpeedKey = XPlayer.Id .. "_SS_GameSpeed"
end

function XSkyGardenShoppingStreetControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XSkyGardenShoppingStreetControl:RemoveAgencyEvent()

end

function XSkyGardenShoppingStreetControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end
--endregion

--------------------------------------------------------------------------------
--region 服务器协议
-- 进入关卡统计
function XSkyGardenShoppingStreetControl:SgStreetStageEnterRequest(cb)
    XNetwork.Call(
        "SgStreetStageEnterRequest",
        nil,
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then cb() end
        end
    )
end

-- 选择关卡
function XSkyGardenShoppingStreetControl:SgStreetStageStartRequest(stageId, cb)
    self:SetLastShowNewsId(0)
    XNetwork.Call(
        "SgStreetStageStartRequest",
        { StageId = stageId, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:SetStageData(res.StageData, true)
            if cb then cb() end
        end
    )
end

-- 关卡放弃
function XSkyGardenShoppingStreetControl:SgStreetStageGiveUpRequest(stageId, cb)
    XNetwork.Call(
        "SgStreetStageGiveUpRequest",
        { StageId = stageId, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:GiveupStage()
            if cb then cb() end
        end
    )
end

-- 运营开始
function XSkyGardenShoppingStreetControl:SgStreetOperatingStartRequest(cb)
    XNetwork.Call(
        "SgStreetOperatingStartRequest",
        nil,
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:StartRunRound(res.OperatingData)
            if cb then cb() end
        end
    )
end

-- 运营结算
function XSkyGardenShoppingStreetControl:SgStreetOperatingSettleRequest(cb)
    local data = self._Model:GetSettleData()
    XNetwork.Call(
        "SgStreetOperatingSettleRequest",
        { SettleParam = data, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:SetSettleData(res.SettleData)
            if cb then cb() end
        end
    )
end

-- 商店建造
function XSkyGardenShoppingStreetControl:SgStreetShopBuildRequest(ShopId, Position, cb)
    XNetwork.Call(
        "SgStreetShopBuildRequest",
        { ShopId = ShopId, Position = Position, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:UpdateShopAreaData(res.ShopData)
            self._Model:UpdateCurrentTurnInsideBuilds(res.CurrentTurnInsideBuilds)
            local shopAreaData = self._Model:GetShopAreaByShopId(ShopId)

            local areaId = self._Model:GetAreaIdByShopId(ShopId)
            self:X3CBuildingChange(areaId,  shopAreaData:GetShopShowLevel(), false)
            if cb then cb() end

            local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
            self:X3CPlayShopEffect(areaId, X3CEShopEffectType.ShopCreate)

            local isInside = shopAreaData:IsInside()
            if not isInside and self:HasPromotion() then
                XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetSale")
            end
        end
    )
end

-- 商店拆除
function XSkyGardenShoppingStreetControl:SgStreetShopRemoveRequest(ShopId, cb)
    XNetwork.Call(
        "SgStreetShopRemoveRequest",
        { ShopId = ShopId, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            local areaId = self._Model:GetAreaIdByShopId(ShopId)
            local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
            self:X3CPlayShopEffect(areaId, X3CEShopEffectType.ShopDestroy)
            -- self:X3CBuildingDestroy(areaId)
            -- 商店拆除
            self._Model:DestroyShop(ShopId)
            self._Model:UpdateCurrentTurnInsideBuilds(res.CurrentTurnInsideBuilds)
            if cb then cb(areaId) end
        end
    )
end

-- 商店升级
function XSkyGardenShoppingStreetControl:SgStreetShopUpgradeRequest(ShopId, BranchId, cb)
    XNetwork.Call(
        "SgStreetShopUpgradeRequest",
        { ShopId = ShopId, BranchId = BranchId, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:UpdateShopAreaData(res.ShopData)
            local shopAreaData = self._Model:GetShopAreaByShopId(ShopId)
            local areaId = self._Model:GetAreaIdByShopId(ShopId)
            local showLevel = shopAreaData:GetShopShowLevel()
            self:X3CBuildingChange(areaId, showLevel, false)

            local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
            self:X3CPlayShopEffect(areaId, X3CEShopEffectType.ShopUpdate, showLevel)
            if cb then cb() end
        end
    )
end

-- 商店设置食品
function XSkyGardenShoppingStreetControl:SgStreetShopSetupFoodRequest(ShopId, ChefId, GoodsCountList, GoldCount, cb)
    XNetwork.Call(
        "SgStreetShopSetupFoodRequest",
        { ShopId = ShopId, ChefId = ChefId, GoodsCountList = GoodsCountList, GoldCount = GoldCount, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:UpdateShopAreaData(res.ShopData)
            if cb then cb() end
        end
    )
end

-- 商店设置商品
function XSkyGardenShoppingStreetControl:SgStreetShopSetupGroceryRequest(ShopId, ShelfDataList, cb)
    XNetwork.Call(
        "SgStreetShopSetupGroceryRequest",
        { ShopId = ShopId, ShelfDataList = ShelfDataList, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:UpdateShopAreaData(res.ShopData)
            if cb then cb() end
        end
    )
end

-- 商店设置甜品
function XSkyGardenShoppingStreetControl:SgStreetShopSetupDessertRequest(ShopId, GoodsIdList, GoldCount, cb)
    XNetwork.Call(
        "SgStreetShopSetupDessertRequest",
        { ShopId = ShopId, GoodsIdList = GoodsIdList, GoldCount = GoldCount, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:UpdateShopAreaData(res.ShopData)
            if cb then cb() end
        end
    )
end

-- 商店设置推荐商店
function XSkyGardenShoppingStreetControl:SgStreetShopSetRecommendRequest(ShopId, cb)
    XNetwork.Call(
        "SgStreetShopSetRecommendRequest",
        { ShopId = ShopId, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:SetRecommendShopId(ShopId)
            if cb then cb() end
        end
    )
end

-- 商店设置促销
function XSkyGardenShoppingStreetControl:SgStreetPromotionSelectRequest(SelectGroupId, Index, promotionId, cb)
    XNetwork.Call(
        "SgStreetPromotionSelectRequest",
        { SelectGroupId = SelectGroupId, Index = Index, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:FinishPromotion(SelectGroupId)
            local shopId = self._Model:GetShopIdByPromotionId(promotionId)
            if shopId then
                local areaId = self._Model:GetAreaIdByShopId(shopId)
                local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
                self:X3CPlayShopEffect(areaId, X3CEShopEffectType.ShopSale)
            end
            if cb then cb() end
        end
    )
end

-- 商店设置灯带
function XSkyGardenShoppingStreetControl:SgStreetBillboardSelectRequest(BillboardId, cb)
    XNetwork.Call(
        "SgStreetBillboardSelectRequest",
        { BillboardId = BillboardId, },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据
            self._Model:UpdateBillboardId(BillboardId)
            self._Model:UpdateBillboardTaskId(res.TaskId)
            if cb then cb() end
        end
    )
end

--endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--region 配置
--- 获取灯带配置
---@param id 灯带Id
---@return XTableSgStreetBillboard 灯带配置
function XSkyGardenShoppingStreetControl:GetBillboardConfigById(id)
    return self._Model:GetBillboardConfigById(id)
end

--- 获取Buff配置
---@param buffId buffId
---@return XTableSgStreetBuff 灯带配置
function XSkyGardenShoppingStreetControl:GetBuffConfigById(buffId)
    return self._Model:GetBuffConfigById(buffId)
end

--- 获取全局配置
---@param key 配置key
---@return any 配置值
function XSkyGardenShoppingStreetControl:GetGlobalConfigByKey(key)
    return self._Model:GetGlobalConfigByKey(key)
end

-- 突发事件配置
---@param id突发事件id
---@return XTableSgStreetStage 所有阶段配置
function XSkyGardenShoppingStreetControl:GetCustomerEventEmergencyById(id)
    return self._Model:GetCustomerEventEmergencyById(id)
end

-- 阶段配置
---@return XTableSgStreetStage 所有阶段配置
function XSkyGardenShoppingStreetControl:GetAllStageConfigs()
    return self._Model:GetAllStageConfigs()
end

-- 阶段配置
---@return XTableSgStreetStageRes 资源显示配置
function XSkyGardenShoppingStreetControl:GetStageResConfigs()
    return self._Model:GetStageResConfigs()
end

-- 阶段内配置
---@param stageId 阶段id
---@return XTableSgStreetStage 阶段配置
function XSkyGardenShoppingStreetControl:GetStageConfigsByStageId(stageId)
    return self._Model:GetStageConfigsByStageId(stageId)
end

--- 获取阶段内商品配置
---@param stageId 阶段id
---@return XTableSgStreetStageShop 阶段内商店配置
function XSkyGardenShoppingStreetControl:GetStageShopConfigsByStageId(stageId)
    return self._Model:GetStageShopConfigsByStageId(stageId)
end

--- 获取阶段目标配置
---@param taskId 任务id
---@return XTableSgStreetTask 目标配置
function XSkyGardenShoppingStreetControl:GetStageTaskConfigsById(taskId)
    return self._Model:GetStageTaskConfigsById(taskId)
end

--- 获取新闻配置
---@param newsId 新闻id
---@return XTableSgStreetNews 新闻配置
function XSkyGardenShoppingStreetControl:GetNewsConfigById(newsId)
    return self._Model:GetNewsConfigById(newsId)
end

--- 获取促销配置
---@param promotionId 促销id
---@return XTableSgStreetPromotion 促销配置
function XSkyGardenShoppingStreetControl:GetPromotionConfigById(promotionId)
    return self._Model:GetPromotionConfigById(promotionId)
end

--- 获取建议配置
---@param id number 建议id
---@return XTableSgStreetReview 建议配置
function XSkyGardenShoppingStreetControl:GetReviewConfigById(id)
    return self._Model:GetReviewConfigById(id)
end

--- 获取阶段内商品配置
---@param bid 商店id
---@param isInside 是否内部商店
---@return XTableSgStreetInsideShop 商店配置
function XSkyGardenShoppingStreetControl:GetShopConfigById(bid, isInside)
    return self._Model:GetShopConfigById(bid, isInside)
end

--- 获取所有属性显示的配置
---@return XTableSgStreetShopAttr 属性配置
function XSkyGardenShoppingStreetControl:GetShopAttrConfigs()
    return self._Model:GetShopAttrConfigs()
end

--- 获取商店内商品配置
---@param shopId 商店id
---@param lv 等级
---@param isInside 是否内部商店
---@return XTableSgStreetInsideShopLv 商店内商品配置
function XSkyGardenShoppingStreetControl:GetShopLevelConfigById(shopId, lv, isInside)
    return self._Model:GetShopLevelConfigById(shopId, lv, isInside)
end

--- 获取商店星级
---@param shopId 商店id
---@param customerFactor 顾客因子
function XSkyGardenShoppingStreetControl:GetShopCustomerStar(shopId, customerFactor)
    return self._Model:GetShopCustomerStar(shopId, customerFactor)
end

--- 获取食品商店商品配置
---@param shopId 商店id
---@return table 食品商店商品配置
function XSkyGardenShoppingStreetControl:GetShopFoodConfigsByShopId(shopId)
    return self._Model:GetShopFoodConfigsByShopId(shopId)
end

--- 获取食品商店材料配置
---@param goodId 材料id
---@return table 食品商店材料配置
function XSkyGardenShoppingStreetControl:GetShopFoodGoodsConfigsByGoodId(goodId)
    return self._Model:GetShopFoodGoodsConfigsByGoodId(goodId)
end

--- 获取食品商店厨师配置
---@param chefId 厨师id
---@return table 食品商店厨师配置
function XSkyGardenShoppingStreetControl:GetShopFoodChefConfigsByChefId(chefId)
    return self._Model:GetShopFoodChefConfigsByChefId(chefId)
end

--- 获取杂货铺商店商品配置
---@param shopId 商店id
---@return table 杂货铺商店商品配置
function XSkyGardenShoppingStreetControl:GetShopGroceryConfigsByShopId(shopId)
    return self._Model:GetShopGroceryConfigsByShopId(shopId)
end

--- 获取杂货铺商店商品配置
---@param goodId 材料id
---@return table 杂货铺商店材料配置
function XSkyGardenShoppingStreetControl:GetShopGroceryGoodsConfigsByGoodId(goodId)
    return self._Model:GetShopGroceryGoodsConfigsByGoodId(goodId)
end

--- 获取反馈配置
---@param feebackId 商店id
---@return XTableSgStreetFeedback 反馈配置
function XSkyGardenShoppingStreetControl:GetFeedbackConfigsById(feebackId)
    return self._Model:GetFeedbackConfigsById(feebackId)
end

--- 获取小道消息配置
---@param grapevineId 小道消息id
---@return XTableSgStreetGrapevine 小道消息配置
function XSkyGardenShoppingStreetControl:GetGrapevineConfigById(grapevineId)
    return self._Model:GetGrapevineConfigById(grapevineId)
end

--- 获取甜品商店商品配置
---@param shopId 商店id
---@return table 甜品商店商品配置
function XSkyGardenShoppingStreetControl:GetShopDessertConfigsByShopId(shopId)
    return self._Model:GetShopDessertConfigsByShopId(shopId)
end

--- 获取甜品商店商品配置
---@param goodId 材料id
---@return table 甜品商店材料配置
function XSkyGardenShoppingStreetControl:GetShopDessertGoodsConfigsByGoodId(goodId)
    return self._Model:GetShopDessertGoodsConfigsByGoodId(goodId)
end

--- 获取促销商店id
---@param promotionId 促销id
---@return number 商店id
function XSkyGardenShoppingStreetControl:GetShopIdByPromotionId(promotionId)
    return self._Model:GetShopIdByPromotionId(promotionId)
end
--endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--region X3C调用
--- 创建顾客
---@param NpcId number 顾客唯一Id
function XSkyGardenShoppingStreetControl:X3CCustomerCreate(NpcId)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CREATE_CUSTOMER)
end

--- 销毁顾客
---@param NpcId number 顾客唯一Id
function XSkyGardenShoppingStreetControl:X3CCustomerDestroy(NpcId)
    local isInGame = XMVCA.XBigWorldGamePlay:IsInGame()
    if not isInGame then return end
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_DESTROY_CUSTOMER, {
        NpcId = NpcId,
    })
end

--- 运行顾客任务
---@param NpcId number 顾客唯一Id
---@param TaskAreaId number 任务位置Id
function XSkyGardenShoppingStreetControl:X3CCustomRunTask(NpcId, TaskAreaId, isEnterShop)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    local placeId = self._Model:GetPlaceIdByAreaId(TaskAreaId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_RUN_CUSTOMER_TASK, {
        NpcId = NpcId,
        TaskPlaceId = placeId,
        IsEnterShop = isEnterShop or false,
    })
end

--- 创建建筑
---@param AreaId number 位置
---@param SceneObjectBaseId number 建筑Id
function XSkyGardenShoppingStreetControl:X3CBuildingCreate(AreaId, SceneObjectBaseId)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    local placeId = self._Model:GetPlaceIdByAreaId(AreaId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CREATE_BUILDING, {
        PlaceId = placeId,
        SceneObjectBaseId = SceneObjectBaseId,
    })
end

--- 销毁建筑
---@param AreaId number 位置
function XSkyGardenShoppingStreetControl:X3CBuildingDestroy(AreaId)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    local placeId = self._Model:GetPlaceIdByAreaId(AreaId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_DESTROY_BUILDING, {
        PlaceId = placeId,
    })
end

--- 改变建筑外观
---@param AreaId number 位置
---@param Level number 等级
---@param IsShowProjection boolean 是否显示投影
function XSkyGardenShoppingStreetControl:X3CBuildingChange(AreaId, ShowLevel, IsShowProjection)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    local placeId = self._Model:GetPlaceIdByAreaId(AreaId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_BUILDING_APPEARANCE, {
        PlaceId = placeId,
        Level = ShowLevel,
        IsShowProjection = IsShowProjection,
    })
end

-- 获取镜头PlaceId
function XSkyGardenShoppingStreetControl:GetCameraPlaceId(index)
    if not self._CameraPlaceIndexCache then self._CameraPlaceIndexCache = {} end
    if not self._CameraPlaceIndexCache[index] then
        self._CameraPlaceIndexCache[index] = tonumber(self._Model:GetGlobalConfigByKey("VirtualCameraId" .. index))
    end
    return self._CameraPlaceIndexCache[index]
end

--- 设置虚拟摄像机通过id
function XSkyGardenShoppingStreetControl:X3CSetVirtualCameraByCameraIndex(cameraIndex, Index, Duration, isFoce)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    local cameraPlaceId = self:GetCameraPlaceId(cameraIndex)
    if not isFoce and self._LastCameraPlaceId == cameraPlaceId and self._LastCameraIndex == Index then return end
    self._LastCameraPlaceId = cameraPlaceId
    self._LastCameraIndex = Index

    local durationTime = Duration
    if not durationTime then
        if cameraIndex == 1 then
            durationTime = tonumber(self:GetGlobalConfigByKey("CameraSwitchMainCameraTime")) or 0
        else
            durationTime = tonumber(self:GetGlobalConfigByKey("CameraSwitchGamePlayCameraTime")) or 0
        end
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_VIRTUAL_CAMERA, {
        PlaceId = 0,
        Index = Index or 1,
        Duration = durationTime,
        VirtualCameraId = cameraPlaceId,
        IsFromBase = true,
    })
    if cameraIndex == 2 then
        XMVCA.XBigWorldGamePlay:SetCameraPhysicalMode(true, 3)
    else
        XMVCA.XBigWorldGamePlay:SetCameraPhysicalMode(false, 0)
    end
end

--- 设置虚拟摄像机
---@param AreaId number 位置
---@param Index number X3CCameraPosIndex 索引
---@param Duration number 持续时间
function XSkyGardenShoppingStreetControl:X3CSetVirtualCamera(AreaId, Index, Duration)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    if self._LastCameraPlaceId == AreaId and self._LastCameraIndex == Index then return end

    local IsFromBase = true
    local durationTime = 0
    if Duration then
        durationTime = Duration
    else
        if self._LastCameraPlaceId == AreaId then
            local posIndexType = XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex
            local midType = posIndexType.Middle
            local leftType = posIndexType.Left
            if self._LastCameraIndex == midType and Index == leftType then
                durationTime = tonumber(self:GetGlobalConfigByKey("CameraSwitchLeftTime")) or 0
                IsFromBase = false
            elseif self._LastCameraIndex == leftType and Index == midType then
                durationTime = tonumber(self:GetGlobalConfigByKey("CameraSwitchMiddleTime")) or 0
                IsFromBase = false
            end
        else
            durationTime = tonumber(self:GetGlobalConfigByKey("CameraSwitchTime")) or 0
        end
    end
    self._LastCameraPlaceId = AreaId
    self._LastCameraIndex = Index

    local placeId = self._Model:GetPlaceIdByAreaId(AreaId)
    XMVCA.XBigWorldGamePlay:SetCameraPhysicalMode(false, 0)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_VIRTUAL_CAMERA, {
        PlaceId = placeId,
        Index = Index or 1,
        Duration = durationTime,
        VirtualCameraId = 0,
        IsFromBase = IsFromBase,
    })
end

--- 设置状态
---@param State number 状态 0 正常，1 编辑，2 进行中
function XSkyGardenShoppingStreetControl:X3CSetStageStatus(State)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_GAME_STATE, {
        State = State,
    })
end

-- 设置游戏速度
function XSkyGardenShoppingStreetControl:X3CSetGameSpeed(Speed)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_GAME_SPEED, {
        Speed = Speed,
    })
end

-- 播放游戏特效
function XSkyGardenShoppingStreetControl:X3CPlayShopEffect(areaId, EffectType, Level)
    local isEnterLevel = XMVCA.XSkyGardenShoppingStreet:IsEnterLevel()
    if not isEnterLevel then return end
    local placeId = self._Model:GetPlaceIdByAreaId(areaId)
    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_PLAY_SHOP_EFFECT, {
        PlaceId = placeId,
        EffectType = EffectType,
        Level = Level or 0,
    })
end

--endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--region 共有接口
function XSkyGardenShoppingStreetControl:CleanStageDataCache()
    self._Model:CleanStageDataCache()
end

function XSkyGardenShoppingStreetControl:GetPassedStageIds()
    return self._Model:GetPassedStageIds()
end

-- 获取资源数量
function XSkyGardenShoppingStreetControl:GetStageResById(resId)
    return self._Model:GetStageResById(resId)
end

-- 是否满足资源数量
function XSkyGardenShoppingStreetControl:EnoughStageResById(cost, resId)
    return self._Model:EnoughStageResById(cost, resId)
end

--- 获取所有商店区域数据
function XSkyGardenShoppingStreetControl:GetAllShopAreas()
    return self._Model:GetAllShopAreas()
end

function XSkyGardenShoppingStreetControl:GetShopAreas(isInside)
    return self._Model:GetShopAreas(isInside)
end

function XSkyGardenShoppingStreetControl:GetShopAreaByUiPos(pos, isInside)
    return self._Model:GetShopAreaByUiPos(pos, isInside)
end

function XSkyGardenShoppingStreetControl:GetAreaIdByUiPos(uiPos, isInside)
    return self._Model:GetAreaIdByUiPos(uiPos, isInside)
end

function XSkyGardenShoppingStreetControl:GetShopAreaByShopId(shopId, isInside)
    return self._Model:GetShopAreaByShopId(shopId, isInside)
end

-- 获取PlaceID
function XSkyGardenShoppingStreetControl:GetAreaIdByShopId(shopId)
    return self._Model:GetAreaIdByShopId(shopId)
end

function XSkyGardenShoppingStreetControl:GetUiPositionByShopId(shopId, isInside)
    return self._Model:GetUiPositionByShopId(shopId, isInside)
end

function XSkyGardenShoppingStreetControl:GetMaxStageId()
    return self._Model:GetMaxStageId()
end

function XSkyGardenShoppingStreetControl:GetTargetStageId()
    return self._Model:GetTargetStageId()
end

function XSkyGardenShoppingStreetControl:GetCurrentStageId(isSafe)
    return self._Model:GetCurrentStageId(isSafe)
end

function XSkyGardenShoppingStreetControl:IsStageRunning()
    return self._Model:IsStageRunning()
end

function XSkyGardenShoppingStreetControl:GetRunRound()
    return self._Model:GetRunRound()
end

function XSkyGardenShoppingStreetControl:IsRunningGame()
    return self._Model:IsRunningGame()
end

function XSkyGardenShoppingStreetControl:TryStartAutoRunRound()
    self._StartRunRound = self._Model:TryStartAutoRunRound()
    return self._StartRunRound
end

function XSkyGardenShoppingStreetControl:GetCustomerCount()
    return self._Model:GetCustomerCount()
end

function XSkyGardenShoppingStreetControl:GetCustomerByIndex(index)
    return self._Model:GetCustomerByIndex(index)
end

function XSkyGardenShoppingStreetControl:HasNewsOrGrapevinesTipsByTurn(turn)
    return self._Model:HasNewsOrGrapevinesTipsByTurn(turn)
end

function XSkyGardenShoppingStreetControl:GetStageNews()
    return self._Model:GetStageNews()
end

function XSkyGardenShoppingStreetControl:GetStageGrapevines()
    return self._Model:GetStageGrapevines()
end

function XSkyGardenShoppingStreetControl:GetLastShowNewsId()
    return XSaveTool.GetData(self._PrefsSaveNewsKey) or 0
end

function XSkyGardenShoppingStreetControl:SetLastShowNewsId(newsId)
    XSaveTool.SaveData(self._PrefsSaveNewsKey, newsId)
end

function XSkyGardenShoppingStreetControl:GetGameSpeedIndex()
    return XSaveTool.GetData(self._PrefsSaveSpeedKey) or 1
end

function XSkyGardenShoppingStreetControl:SetGameSpeedIndex(speedIndex)
    XSaveTool.SaveData(self._PrefsSaveSpeedKey, speedIndex)
end

function XSkyGardenShoppingStreetControl:GetStageGameBuffs(getCount)
    return self._Model:GetStageGameBuffs(getCount)
end

function XSkyGardenShoppingStreetControl:SelectBillboardsById(BillboardId, cb)
    self:SgStreetBillboardSelectRequest(BillboardId, cb)
end

function XSkyGardenShoppingStreetControl:GetEndBillboardId()
    return self._Model:GetEndBillboardId()
end

function XSkyGardenShoppingStreetControl:IsFinishBillboardTaskSuccess()
    return self._Model:IsFinishBillboardTaskSuccess()
end

function XSkyGardenShoppingStreetControl:GetBillboardLeftTurn()
    return self._Model:GetBillboardLeftTurn()
end

function XSkyGardenShoppingStreetControl:HasStageLimitTask()
    local list = self._Model:GetStageBillboards()
    return list and #list > 0
end

function XSkyGardenShoppingStreetControl:GetStageBillboardsSelectedId()
    return self._Model:GetStageBillboardsSelectedId()
end

function XSkyGardenShoppingStreetControl:GetStageBillboards()
    return self._Model:GetStageBillboards()
end

function XSkyGardenShoppingStreetControl:GetShopMaxLevel(shopId)
    return self._Model:GetShopMaxLevel(shopId)
end

-- 获取昨日结算信息
function XSkyGardenShoppingStreetControl:GetSettleResultData()
    return self._Model:GetSettleResultData()
end

-- 获取促销数据
function XSkyGardenShoppingStreetControl:GetPromotionData()
    return self._Model:GetPromotionData()
end

-- 是否有促销
function XSkyGardenShoppingStreetControl:HasPromotion()
    return self._Model:HasPromotion()
end

-- 获取推荐商铺ID
function XSkyGardenShoppingStreetControl:GetRecommendShopId()
    return self._Model:GetRecommendShopId()
end

-- 是否可以建商铺
function XSkyGardenShoppingStreetControl:CanBuildShop(isInside)
    return self._Model:CanBuildShop(isInside)
end

-- 是否满足条件建造外圈商铺
function XSkyGardenShoppingStreetControl:CanUnlockOutisdeShop()
    return self._Model:CanUnlockOutisdeShop()
end

function XSkyGardenShoppingStreetControl:GetMascotData()
    return self._Model:GetMascotData()
end

-- 获取限时任务
function XSkyGardenShoppingStreetControl:GetLimitTask()
    return self._Model:GetLimitTask()
end

function XSkyGardenShoppingStreetControl:GetLimitTaskSchedule()
    return self._Model:GetLimitTaskSchedule()
end

-- 是否完成限时任务需要显示
function XSkyGardenShoppingStreetControl:IsFinishLimitTask()
    return self._Model:IsFinishLimitTask()
end

-- 清空限时任务数据
function XSkyGardenShoppingStreetControl:CleanFinishLimitTask()
    self._Model:CleanFinishLimitTask()
end

function XSkyGardenShoppingStreetControl:GetTaskDataByConfigId(taskId)
    return self._Model:GetTaskDataByConfigId(taskId)
end

function XSkyGardenShoppingStreetControl:IsFinishAllStageTask()
    return self._Model:IsFinishAllStageTask()
end

function XSkyGardenShoppingStreetControl:PopGetShowBuff()
    return self._Model:PopGetShowBuff()
end

--endregion

--region 描述相关
function XSkyGardenShoppingStreetControl:_InsertAttrData(attrData, shopId, num, shopAttr, isUp)
    table.insert(attrData, {
        ShopId = shopId,
        Value = num,
        Id = shopAttr.Id,
        IsUp = isUp,
        ResConfigId = shopAttr.Type,
    })
end

-- 获取显示属性
function XSkyGardenShoppingStreetControl:GetAttributes(configLv, shopId, isUp)
    local attrData = {}
    local attrShowConfigs = self:GetShopAttrConfigs()
    for _, shopAttr in pairs(attrShowConfigs) do
        local num = XMVCA.XSkyGardenShoppingStreet:ParseAttributeByConfig(shopAttr.Type, shopId, configLv)
        if num ~= 0 then
            self:_InsertAttrData(attrData, shopId, num, shopAttr, isUp)
        end
    end
    return attrData
end

-- 获取升级属性
function XSkyGardenShoppingStreetControl:GetUpgradeAttributes(upgradeBranchId, shopId)
    local attrData = {}
    local upgradeBranchConfig = self._Model:GetShopLvBranchConfigsByBranchId(upgradeBranchId)
    if not upgradeBranchConfig then
        XLog.Warning("XSkyGardenShoppingStreetControl:GetUpgradeAttributes upgradeBranchConfig is nil", upgradeBranchId, shopId)
        return attrData
    end
    for typeIndex, typeValue in pairs(upgradeBranchConfig.AttrTypes) do
        local shopAttr = self._Model:GetAttrConfigByAttrAddType(typeValue)
        if shopAttr then
            local num = upgradeBranchConfig.AttrValues[typeIndex] or 0
            if num ~= 0 then
                self:_InsertAttrData(attrData, shopId, num, shopAttr, true)
            end
        end
    end
    for typeIndex, typeValue in pairs(upgradeBranchConfig.ShopAttrTypes) do
        local clientType = XMVCA.XSkyGardenShoppingStreet.XShopAttrTypesBase + typeValue
        local shopAttr = self._Model:GetAttrConfigByAttrAddType(clientType)
        if shopAttr then
            local num = upgradeBranchConfig.ShopAttrValues[typeIndex] or 0
            if num ~= 0 then
                self:_InsertAttrData(attrData, shopId, num, shopAttr, true)
            end
        end
    end
    return attrData
end

-- 获取商店属性
function XSkyGardenShoppingStreetControl:GetShopAttributes(shopId, lv, isIniside, isConfig)
    local shopArea = self._Model:GetShopAreaByShopId(shopId, isIniside)
    if not isConfig and shopArea and shopArea:HasShop() then
        local attrData = {}
        local attrShowConfigs = self:GetShopAttrConfigs()
        for _, shopAttr in pairs(attrShowConfigs) do
            local resCfgs = self:GetStageResConfigs()
            local resCfg = resCfgs[shopAttr.Type]
            local num = shopArea:GetTotalAttributesByType(resCfg.Id, resCfg.AttrId)
            if num ~= 0 then
                self:_InsertAttrData(attrData, shopId, num, shopAttr, false)
            end
        end
        return attrData
    else
        return self:GetAttributes(self:GetShopLevelConfigById(shopId, lv or 1, isIniside), shopId)
    end
end

function XSkyGardenShoppingStreetControl:GetValueByValueType(value, valueType, add, gap)
    local v = XTool.ValueStandard(value or 0)
    if not self._ValueGetFunc then
        self._ValueGetFunc = {
            [0] = function ()
                return ""
            end,
            [1] = function (inputV, isAdd, isGap)
                inputV = XMath.FixFloor(inputV)
                if isAdd and inputV > 0 then
                    return "+" .. inputV
                end
                return inputV
            end,
            [2] = function (inputV, isAdd, isGap)
                if isGap then
                    inputV = inputV - 1
                end
                inputV = XMath.FixFloor(inputV * 100)
                if isAdd and inputV > 0 then
                    return "+" .. inputV .. "%"
                end
                return inputV .. "%"
            end,
        }
    end
    local func = self._ValueGetFunc[valueType]
    if func then return func(v, add, gap) end
    return v
end

-- 自动反馈事件buff
function XSkyGardenShoppingStreetControl:GetValueByResConfig(value, config, add, isGap)
    local div = config.Div or 1
    if div == 0 then
        div = 1
    end
    value = value / div
    return self:GetValueByValueType(value, config.ValueType, add, isGap)
end

--- 初始化解析反馈数据
function XSkyGardenShoppingStreetControl:_InitParseData()
    if self._ParceDataInit then return end
    self._ParceDataInit = true

    self._DescReplaceCache = {
        [1] = "{0}",
        [2] = "{1}",
        [3] = "{2}",
        [4] = "{3}",
        [5] = "{4}",
        [6] = "{5}",
    }
    self._FeedbackTypeParseFunc = {
        [0] = function(parseData, shopId, desc, key)
            return string.gsub(desc, key, parseData.Difference)
        end,
        [1] = function(parseData, shopId, desc, key)
            local shopConfig = self:GetShopConfigById(shopId)
            local shopName = shopConfig and shopConfig.Name or shopId
            return string.gsub(desc, key, shopName)
        end,
        [2] = function(parseData, shopId, desc, key)
            local goodId = parseData.GoodId
            local shopType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType
            local shopConfig = self:GetShopConfigById(shopId)
            local goodName
            if shopConfig.FuncType == shopType.Food then
                local goodConfig = self:GetShopFoodGoodsConfigsByGoodId(goodId)
                goodName = goodConfig and goodConfig.GoodsName or goodId
            elseif shopConfig.FuncType == shopType.Grocery then
                local goodConfig = self:GetShopGroceryGoodsConfigsByGoodId(goodId)
                goodName = goodConfig and goodConfig.GoodsName or goodId
            elseif shopConfig.FuncType == shopType.Dessert then
                local goodConfig = self:GetShopDessertGoodsConfigsByGoodId(goodId)
                goodName = goodConfig and goodConfig.GoodsName or goodId
            end
            return string.gsub(desc, key, goodName)
        end,
        [3] = function(parseData, shopId, desc, key)
            local goodId = parseData.GoodId
            local chefConfig = self:GetShopFoodChefConfigsByChefId(goodId)
            local chefName = chefConfig and chefConfig.ChefName or goodId
            return string.gsub(desc, key, chefName)
        end,
        [4] = function(parseData, shopId, desc, key)
            local effectDesc
            if parseData.Difference < 0 then
                effectDesc = XMVCA.XBigWorldService:GetText("SG_SS_GoodAdd")
            else
                effectDesc = XMVCA.XBigWorldService:GetText("SG_SS_GoodSub")
            end
            return string.gsub(desc, key, effectDesc)
        end,
        [5] = function(parseData, shopId, desc, key)
            local effectDesc
            if parseData.Difference > 0 then
                effectDesc = XMVCA.XBigWorldService:GetText("SG_SS_PriceAdd")
            else
                effectDesc = XMVCA.XBigWorldService:GetText("SG_SS_PriceSub")
            end
            return string.gsub(desc, key, effectDesc)
        end,
        [6] = function(parseData, shopId, desc, key)
            return string.gsub(desc, key, parseData.Difference + 1)
        end,
    }
end

--- 获取商店的反馈描述
function XSkyGardenShoppingStreetControl:ParseFeedback(feedbackData, shopId)
    self:_InitParseData()
    local feedbackConfig = self:GetFeedbackConfigsById(feedbackData.FeedbackTemplateId)
    local params = self._Model:GetStageDescConfigsById(feedbackConfig.FeedbackType)
    local desc = feedbackConfig.Desc
    for index, paramType in pairs(params.FeedbackParam) do
        local key = self._DescReplaceCache[index]
        if key then
            local func = self._FeedbackTypeParseFunc[paramType]
            if func then
                desc = func(feedbackData, shopId, desc, key)
            end
        end
    end
    return desc
end

--- 获取小道消息描述
function XSkyGardenShoppingStreetControl:ParseGrapevine(grapevineData)
    self:_InitParseData()
    local cfg = self:GetGrapevineConfigById(grapevineData.GrapevineId)
    local params = self._Model:GetStageDescConfigsById(cfg.GrapevineType)
    local desc = cfg.Desc
    for index, paramCfgIndex in pairs(params.GrapevineIndexParam) do
        local parseData = grapevineData.GrapevineList[paramCfgIndex]
        local key = self._DescReplaceCache[index]
        if key then
            local paramType = params.GrapevineParam[index]
            local func = self._FeedbackTypeParseFunc[paramType]
            if func then
                desc = func(parseData, grapevineData.ShopId, desc, key)
            end
        end
    end
    return desc
end

function XSkyGardenShoppingStreetControl:ParseBuffDescListById(buffId)
    local params = self:ParseBuffDescParamsById(buffId)
    local buffCfg = self:GetBuffConfigById(buffId)
    local descList = {}
    table.insert(descList, buffCfg.Duration)
    -- extra write
    if buffCfg.Type == 8 then
        local buffDescInfo = params.buffs[1]
        if buffDescInfo then
            table.insert(descList, buffDescInfo.duration)
        end
    end
    for _, param in ipairs(params.buffs) do
        local value = param.value
        local resCfgs = self:GetStageResConfigs()
        local resCfg = resCfgs[param.cType]
        local calId = resCfg.BuffCalId
        if calId > 0 then
            local calResCfg = resCfgs[calId]
            local calValue = self._Model:GetAttrsDataByType(calResCfg.AttrId)
            local denominator
            if calResCfg.Div > 0 then
                denominator = calResCfg.Div
            else
                denominator = 1
            end
            value = (calValue + denominator) / denominator * value
        end
        local desc = self:GetValueByResConfig(value, resCfg, true)
        table.insert(descList, desc)
    end
    return descList
end

-- buff详情描述
function XSkyGardenShoppingStreetControl:ParseBuffDescById(buffId)
    local buffCfg = self._Model:GetBuffConfigById(buffId)
    local descList = self:ParseBuffDescListById(buffId)
    return string.ConcatWithPlaceholdersWithTable(buffCfg.Desc, descList)
end

function XSkyGardenShoppingStreetControl:ParseBuffDescParamsById(buffId, inputParams)
    local outPutParams = inputParams or { buffs = {}, }
    local buffCfg = self:GetBuffConfigById(buffId)
    local buffType = buffCfg.Type
    if not self._ParseBuffParamsFunc then
        self._ParseBuffParamsFunc = {
            [1] = function(bCfg, output, duration)
                local params = bCfg.Params
                local attrType = params[1]
                local attrValue = params[2]
                local num = output[attrType] or 0
                output[attrType] = num + attrValue
                table.insert(output.buffs, {
                    cType = attrType,
                    value = attrValue,
                    bType = XMVCA.XSkyGardenShoppingStreet.ParseBuffType.Attr,
                    duration = duration,
                })
            end,
            [2] = function(bCfg, output, duration)
                local params = bCfg.Params
                local attrValue = params[1]
                local InitGoldType = XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold
                local num = output[InitGoldType] or 0
                output[InitGoldType] = num + attrValue
                table.insert(output.buffs, {
                    cType = InitGoldType,
                    value = attrValue,
                    bType = XMVCA.XSkyGardenShoppingStreet.ParseBuffType.Res,
                    duration = duration,
                })
            end,
            [8] = function(bCfg, output, duration)
                local params = bCfg.Params
                local paramsCount = #params
                for i = 2, paramsCount do
                    local subBuffId = params[i]
                    local subBuffCfg = self:GetBuffConfigById(subBuffId)
                    local subsubBuffType = subBuffCfg.Type
                    local func = self._ParseBuffParamsFunc[subsubBuffType]
                    if func then func(subBuffCfg, output, bCfg.Type == 8 and params[1] or duration) end
                end
            end,
            [10] = function (bCfg, output, duration)
                local params = bCfg.Params
                local attrType = params[1] + XMVCA.XSkyGardenShoppingStreet.XShopAttrTypesBase
                local attrValue = params[2]
                local num = output[attrType] or 0
                output[attrType] = num + attrValue
                table.insert(output.buffs, {
                    cType = attrType,
                    value = attrValue,
                    bType = XMVCA.XSkyGardenShoppingStreet.ParseBuffType.Shop,
                    duration = duration,
                })
            end,
        }
        self._ParseBuffParamsFunc[11] = self._ParseBuffParamsFunc[8]
        self._ParseBuffParamsFunc[12] = self._ParseBuffParamsFunc[8]
    end
    local func = self._ParseBuffParamsFunc[buffType]
    if func then func(buffCfg, outPutParams, buffCfg.Duration) end
    return outPutParams
end

-- 促销活动描述
function XSkyGardenShoppingStreetControl:ParsePromotionDescById(promotionId)
    local promotionCfg = self._Model:GetPromotionConfigById(promotionId)
    local descList = {}
    for descIndex, buffId in ipairs(promotionCfg.DescParam) do
        local paramIndex = (promotionCfg.DescParamIndex[descIndex] or 0) + 1
        local inputParams = self:ParseBuffDescListById(buffId)
        table.insert(descList, inputParams[paramIndex])
    end
    return string.ConcatWithPlaceholdersWithTable(promotionCfg.Desc, descList)
end
--endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--region 游戏逻辑
-- 进入游戏场景
function XSkyGardenShoppingStreetControl:_EnterGame(stageId, isOpenTarget)
    self:SgStreetStageStartRequest(stageId, function ()
        -- 进入关卡场景
        local openFunc = isOpenTarget and XMVCA.XBigWorldUI.PopThenOpen or XMVCA.XBigWorldUI.Open
        openFunc(XMVCA.XBigWorldUI, "UiSkyGardenShoppingStreetGame")
    end)
end

-- 目标界面进入
function XSkyGardenShoppingStreetControl:EnterStreetShopGame(stageId)
    if self._Model:IsStageRunning() and stageId ~= self._Model:GetCurrentStageId() then
        XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
            -- ["Key"] = "SG_SS_EnterGame",
            ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
            ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_EnterGameChangeTips"),
            ["SureCallback"] = function()
                self:SgStreetStageGiveUpRequest(self._Model:GetCurrentStageId(), function()
                    self:_EnterGame(stageId, true)
                end)
            end,
        })
        return
    end
    self:_EnterGame(stageId, true)
end

-- 放弃关卡
function XSkyGardenShoppingStreetControl:GiveupStage()
    XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
            -- ["Key"] = "SG_SS_GiveupStage",
            ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
            ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_GiveupStage"),
            ["SureCallback"] = function()
                self:SgStreetStageGiveUpRequest(self._Model:GetCurrentStageId())
            end,
        })
end

-- 解锁商店
function XSkyGardenShoppingStreetControl:UnlockShop(shopId, uiPos, isInside, cb)
    if not self:CanBuildShop(isInside) then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_BuildChanceTips"))
        return
    end

    if not isInside then
        local canUnlockOutside = self:CanUnlockOutisdeShop()
        if not canUnlockOutside then
            XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_UnlockShopSatisfactionTips"))
            return
        end
    end

    local shopConfig = self._Model:GetShopConfigById(shopId, isInside)
    local reduceCost = self._Model:ShopBuildCostReduceBySubType(shopConfig.SubType, shopConfig.Cost)
    local hasRes = self._Model:EnoughStageResById(reduceCost)
    if not hasRes then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotEnoughRes"))
        return
    end

    -- NeedCustomerNum
    -- local position = self._Model:GetAreaIdByUiPos(uiPos, isInside)
    self:SgStreetShopBuildRequest(shopId, uiPos, cb)
end

-- 拆除商店
function XSkyGardenShoppingStreetControl:DestroyShop(uiPos, isInside, cb)
    local areas = self._Model:GetAllShopAreas()
    local shopCount = 0
    for _, area in pairs(areas) do
        if area:GetShopLevel() > 0 then
            shopCount = shopCount + 1
        end
    end
    if shopCount == 1 then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NoShop"))
        return
    end

    local shopAreaData = self._Model:GetShopAreaByUiPos(uiPos, isInside)
    if not shopAreaData then return end

    local denominator = 10000
    local shopRemoveReturnRate = tonumber(self._Model:GetGlobalConfigByKey("ShopRemoveReturnRate"))
    shopRemoveReturnRate = shopRemoveReturnRate + self._Model:GetShopRemoveReturnAddRatio()
    local returnCost = shopAreaData:GetTotalCost() * shopRemoveReturnRate / denominator
    XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
        -- ["Key"] = "SG_SS_GiveupStage",
        ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
        ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_DestroyShop", returnCost),
        ["SureCallback"] = function()
            local shopId = shopAreaData:GetShopId()
            self:SgStreetShopRemoveRequest(shopId, cb)
        end,
    })
end

-- 升级商店
function XSkyGardenShoppingStreetControl:UpgradeShop(uiPos, isInside, upgradeIndex, cb)
    local shopAreaData = self._Model:GetShopAreaByUiPos(uiPos, isInside)
    if not shopAreaData then return end

    local shopId = shopAreaData:GetShopId()
    local level = shopAreaData:GetShopLevel()
    local shopConfig = self._Model:GetShopLevelConfigById(shopId, level + 1, isInside)
    local enoughCustomerNum = shopAreaData:GetRunTotalCustomerNum() >= shopConfig.NeedCustomerNum
    if not enoughCustomerNum then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotEnoughCustomer"))
        return
    end

    local shopCfg = self._Model:GetShopConfigById(shopId, isInside)
    local reduceCost = self._Model:ShopUpgradeCostReduceBySubType(shopCfg.SubType, shopConfig.Cost)
    local hasRes = self._Model:EnoughStageResById(reduceCost)
    if not hasRes then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotEnoughRes"))
        return
    end

    local branchIds = shopAreaData:GetShopUpgradeBranchIds()
    if upgradeIndex > #branchIds then return end
    self:SgStreetShopUpgradeRequest(shopId, branchIds[upgradeIndex], cb)
end

-- start run round
function XSkyGardenShoppingStreetControl:_StartRunRoundServer(cb)
    self._Model:StartRunRound()
    self._StartRunRound = true
    self:SgStreetOperatingStartRequest(function ()
        if cb then cb() end
    end)
end

-- 开始运营
function XSkyGardenShoppingStreetControl:StartRunRound(cb)
    local areas = self._Model:GetAllShopAreas()
    local shopCount = 0
    for _, area in pairs(areas) do
        if area:GetShopLevel() > 0 then
            shopCount = shopCount + 1
            break
        end
    end
    if shopCount == 0 then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NoShop"))
        return
    end

    local hasInsideEmpty = false
    for _, area in pairs(areas) do
        if area:IsInside() then
            if area:IsUnlock() and area:IsEmpty() then
                hasInsideEmpty = true
            end
        end
    end
    local hasShop2Build = false
    local stageId = self:GetCurrentStageId()
    local shoppingConfig = self:GetStageShopConfigsByStageId(stageId)
    for _, shopId in pairs(shoppingConfig.InsideShopGroup) do
        if not self:GetAreaIdByShopId(shopId) then
            local shopCfg = self._Model:GetShopConfigById(shopId, true)
            local reduceCost = self:ShopBuildCostReduceBySubType(shopCfg.SubType, shopCfg.Cost)
            local hasRes = self:EnoughStageResById(reduceCost)
            if hasRes then
                hasShop2Build = true
                break
            end
        end
    end

    if hasInsideEmpty and self._Model:CanBuildShop(true) and hasShop2Build then
        XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
            ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
            ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_EnterGameCanBuild"),
            ["SureCallback"] = function()
                self:_StartRunRoundServer(cb)
            end,
        })
        return
    end

    self:_StartRunRoundServer(cb)
end

-- 结束运营
function XSkyGardenShoppingStreetControl:EndRunRound(cb)
    if not self._StartRunRound then return end
    self._StartRunRound = false
    self:SgStreetOperatingSettleRequest(function (...)
        if cb then cb() end
    end)
end

function XSkyGardenShoppingStreetControl:SetEndRunRoundState()
    self._Model:EndRunRound()
end

function XSkyGardenShoppingStreetControl:GetCustomerHeadIcon(id)
    return self._Model:GetCustomerHeadIcon(id)
end

function XSkyGardenShoppingStreetControl:GetCustomerFeedHeadIcon(feedbackId, randId)
    return self._Model:GetCustomerFeedHeadIcon(feedbackId, randId)
end

--- 本地增加运行资源
function XSkyGardenShoppingStreetControl:ClientSatisfactionGrow(growValue)
    self._Model:ClientSatisfactionGrow(growValue)
end

--- 本地增加运行资源
function XSkyGardenShoppingStreetControl:ClientAddResourceByAwardGold(shopAwardGold)
    self._Model:ClientAddResourceByAwardGold(shopAwardGold)
end

-- 不满事件处理
function XSkyGardenShoppingStreetControl:DoDiscontentEvent(Id, AwardGold)
    self._Model:DoDiscontentEvent(Id, AwardGold)
end

-- 突发事件选择
function XSkyGardenShoppingStreetControl:DoEmergencyEvent(Id, EmergencyOptionIndex, buffId)
    self._Model:DoEmergencyEvent(Id, EmergencyOptionIndex, buffId)
end

-- 反馈处理
function XSkyGardenShoppingStreetControl:DoFeedbackEvent(shopId, feedbackData)
    self._Model:DoFeedbackEvent(shopId, feedbackData)
end

-- 商店建造消耗减少
function XSkyGardenShoppingStreetControl:ShopBuildCostReduceBySubType(subType, cost)
    return self._Model:ShopBuildCostReduceBySubType(subType, cost)
end

-- 商店升级消耗减少
function XSkyGardenShoppingStreetControl:ShopUpgradeCostReduceBySubType(subType, cost)
    return self._Model:ShopUpgradeCostReduceBySubType(subType, cost)
end

-- 自动不满事件buff
function XSkyGardenShoppingStreetControl:AutoDiscontentEvent()
    return self._Model:AutoDiscontentEvent()
end

-- 自动反馈事件buff
function XSkyGardenShoppingStreetControl:AutoFeedbackEvent()
    return self._Model:AutoFeedbackEvent()
end

-- 单日最高流水金额
function XSkyGardenShoppingStreetControl:GetMaxDailyGold()
    return self._Model:GetMaxDailyGold()
end
--endregion
--------------------------------------------------------------------------------

return XSkyGardenShoppingStreetControl