local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XRogueSimAgency : XFubenActivityAgency
---@field private _Model XRogueSimModel
local XRogueSimAgency = XClass(XFubenActivityAgency, "XRogueSimAgency")
function XRogueSimAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XRogueSimAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyRogueSimData = handler(self, self.NotifyRogueSimData)
    XRpc.NotifyRogueSimAreaChange = handler(self, self.NotifyRogueSimAreaChange)
    XRpc.NotifyRogueSimExploredGridIdsAdd = handler(self, self.NotifyRogueSimExploredGridIdsAdd)
    XRpc.NotifyRogueSimVisibleGridIdsAdd = handler(self, self.NotifyRogueSimVisibleGridIdsAdd)
    XRpc.NotifyRogueSimGridChange = handler(self, self.NotifyRogueSimGridChange)
    XRpc.NotifyRogueSimResourceChange = handler(self, self.NotifyRogueSimResourceChange)
    XRpc.NotifyRogueSimCommodityChange = handler(self, self.NotifyRogueSimCommodityChange)
    XRpc.NotifyRogueSimBuildingBluePrintChange = handler(self, self.NotifyRogueSimBuildingBluePrintChange)
    XRpc.NotifyRogueSimTemporaryBagChange = handler(self, self.NotifyRogueSimTemporaryBagChange)
    XRpc.NotifyRogueSimEventAdd = handler(self, self.NotifyRogueSimEventAdd)
    XRpc.NotifyRogueSimEventRemoves = handler(self, self.NotifyRogueSimEventRemoves)
    XRpc.NotifyRogueSimEventGambleAdd = handler(self, self.NotifyRogueSimEventGambleAdd)
    XRpc.NotifyRogueSimEventGambleRemoves = handler(self, self.NotifyRogueSimEventGambleRemoves)
    XRpc.NotifyRogueSimBuildingChange = handler(self, self.NotifyRogueSimBuildingChange)
    XRpc.NotifyRogueSimCityChange = handler(self, self.NotifyRogueSimCityChange)
    XRpc.NotifyRogueSimTaskChange = handler(self, self.NotifyRogueSimTaskChange)
    XRpc.NotifyRogueSimIllustrates = handler(self, self.NotifyRogueSimIllustrates)
    XRpc.NotifyRogueSimBuffsData = handler(self, self.NotifyRogueSimBuffsData)
    XRpc.NotifyRogueSimBuffAdd = handler(self, self.NotifyRogueSimBuffAdd)
    XRpc.NotifyRogueSimBuffRemove = handler(self, self.NotifyRogueSimBuffRemove)
    XRpc.NotifyRogueSimRewards = handler(self, self.NotifyRogueSimRewards)
    XRpc.NotifyRogueSimRewardAdd = handler(self, self.NotifyRogueSimRewardAdd)
    XRpc.NotifyRogueSimSendReward = handler(self, self.NotifyRogueSimSendReward)
    XRpc.NotifyRogueSimVolatilityData = handler(self, self.NotifyRogueSimVolatilityData)
    XRpc.NotifyRogueSimPropData = handler(self, self.NotifyRogueSimPropData)
    XRpc.NotifyRogueSimAdds = handler(self, self.NotifyRogueSimAdds)
    XRpc.NotifyRogueSimTechData = handler(self, self.NotifyRogueSimTechData)
    XRpc.NotifyRogueSimStatisticsData = handler(self, self.NotifyRogueSimStatisticsData)
    XRpc.NotifyRogueSimCameraMoveToGrid = handler(self, self.NotifyRogueSimCameraMoveToGrid)
    XRpc.NotifyRogueSimAreaUnlock = handler(self, self.NotifyRogueSimAreaUnlock)
    XRpc.NotifyRogueSimSpGridUnlock = handler(self, self.NotifyRogueSimSpGridUnlock)
    XRpc.NotifyRogueSimTipAdd = handler(self, self.NotifyRogueSimTipAdd)
end

function XRogueSimAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

-- 通知玩法数据
function XRogueSimAgency:NotifyRogueSimData(data)
    if not data or not XTool.IsNumberValid(data.ActivityId) then
        return
    end
    if data.IsReset then
        self:DispatchEvent(XAgencyEventId.EVENT_ROGUE_SIM_CACHE_STAGE_SETTLE_DATA)
    end
    self._Model:NotifyRogueSimData(data)
end

-- 通知区域发生变化
function XRogueSimAgency:NotifyRogueSimAreaChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end

    local mapData = stageData:GetMapData()
    for _, areaData in ipairs(data.Datas) do
        mapData:UpdateMapAreaData(areaData)
    end
end

-- 通知已探索格子增加
function XRogueSimAgency:NotifyRogueSimExploredGridIdsAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddExploredGridIds(data.GridIds)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, data.GridIds)
end

-- 通知额外开放视野的格子增加
function XRogueSimAgency:NotifyRogueSimVisibleGridIdsAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddVisibleGridIds(data.GridIds)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_VISIBLE_GRID, data)
end

-- 通知格子数据变化
function XRogueSimAgency:NotifyRogueSimGridChange(data)
    local mapData = self._Model:GetMapData()
    if mapData then
        mapData:AddMapGridDatas(data.Datas)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_CHANGE_GRID, data.Datas)
    end
end

-- 通知资源数据更新
function XRogueSimAgency:NotifyRogueSimResourceChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateResourceData(data.Datas)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE)
end

-- 通知商品数据更新
function XRogueSimAgency:NotifyRogueSimCommodityChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateCommodityData(data.Datas)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_CHANGE)
    self:DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_CHANGE)
end

-- 通知建筑蓝图数据更新
function XRogueSimAgency:NotifyRogueSimBuildingBluePrintChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateBuildingBluePrintData(data.Datas)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_BUILDING_BLUEPRINT_CHANGE)
end

-- 通知临时背包数据更新
function XRogueSimAgency:NotifyRogueSimTemporaryBagChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    local beforeData = self:GetTemporaryBagRewardData()
    stageData:UpdateTemporaryBagData(data.Datas)
    local afterData = self:GetTemporaryBagRewardData()
    local changeData = self:GetTemporaryBagDataChange(beforeData, afterData)
    stageData:UpdateTemporaryBagRewardDropIds(data.RewardDropIds)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_TEMPORARY_BAG_CHANGE, changeData)
end

-- 通知事件添加
function XRogueSimAgency:NotifyRogueSimEventAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddEventData(data.EventData)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EVENT_ADD, data.EventData.GridId)
end

-- 通知事件移除
function XRogueSimAgency:NotifyRogueSimEventRemoves(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end

    local gridIds = {}
    for _, id in ipairs(data.RemovedIds) do
        local eventData = stageData:GetEventDataById(id)
        table.insert(gridIds, eventData.GridId)
    end
    stageData:RemoveEventData(data.RemovedIds)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE, gridIds)
end

-- 通知事件投机添加
function XRogueSimAgency:NotifyRogueSimEventGambleAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddEventGambleData(data.EventGambleData)
end

-- 通知事件投机移除
function XRogueSimAgency:NotifyRogueSimEventGambleRemoves(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    local gridId = 0
    if XTool.IsNumberValid(data.RemovedId) then
        local eventGambleData = stageData:GetEventGambleDataById(data.RemovedId)
        if eventGambleData then
            gridId = eventGambleData:GetGridId()
        end
    end
    stageData:RemoveEventGambleData(data.RemovedId)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EVENT_GAMBLE_REMOVE, gridId)
end

-- 通知建筑变化
function XRogueSimAgency:NotifyRogueSimBuildingChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddBuildingData(data.BuildingData)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_BUILDING_ADD, data.BuildingData.GridId)
end

-- 通知城邦变化
function XRogueSimAgency:NotifyRogueSimCityChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddCityData(data.Data)
    if data.Data then
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_CITY_CHANGE, data.Data.GridId)
    end
end

-- 通知任务变化(增量)
function XRogueSimAgency:NotifyRogueSimTaskChange(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateTaskData(data.TaskDatas)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_TASK_CHANGE)
    self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.Task, data.TaskDatas)
end

-- 通知图鉴数据更新
function XRogueSimAgency:NotifyRogueSimIllustrates(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    self._Model.ActivityData:UpdateIllustrates(data.Illustrates)
end

-- 通知更新Buff数据
function XRogueSimAgency:NotifyRogueSimBuffsData(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateBuffData(data.BuffDatas)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE)
end

-- 通知添加Buff
function XRogueSimAgency:NotifyRogueSimBuffAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddBuffData(data.BuffData)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE)
end

-- 通知移除Buff
function XRogueSimAgency:NotifyRogueSimBuffRemove(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:RemoveBuffData(data.BuffId)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE)
end

-- 通知更新奖励数据
function XRogueSimAgency:NotifyRogueSimRewards(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateRewardData(data.Rewards)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE)
end

-- 通知新增掉落奖励数据
function XRogueSimAgency:NotifyRogueSimRewardAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    -- 已领取的信息在NotifyRogueSimSendReward里处理
    if not data.Reward.Pick then
        stageData:AddReward(data.Reward)
        self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.PropSelect, data.Reward)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE)
    end
end

-- 通知发送奖励
function XRogueSimAgency:NotifyRogueSimSendReward(data)
    if not data then
        return
    end
    if self._Model:CheckStageDataEmpty() then
        return
    end
    self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.Reward, data.RewardId, data.RewardItems)
end

-- 通知更新波动预报(全量)
function XRogueSimAgency:NotifyRogueSimVolatilityData(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateVolatilityData(data.VolatilityData)
end

-- 通知更新道具数据(全量)
function XRogueSimAgency:NotifyRogueSimPropData(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdatePropBoxData(data.PropBoxData)
end

-- 通知更新加成数据
function XRogueSimAgency:NotifyRogueSimAdds(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateCommodityAdds(data.CommodityAdds)
    stageData:UpdateMiscAdds(data.MiscAdds)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE)
    -- 打印加成数据
    if XEnumConst.RogueSim.IsDebug then
        XLog.Warning("<color=#F1D116>RogueSim:</color> 属性加成: ", data.CommodityAdds)
        XLog.Warning("<color=#F1D116>RogueSim:</color> 杂项加成: ", data.MiscAdds)
    end
end

-- 通知更新科技数据(全量)
function XRogueSimAgency:NotifyRogueSimTechData(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateTechData(data.TechData)
end

-- 通知更新统计数据
function XRogueSimAgency:NotifyRogueSimStatisticsData(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateStatisticsData(data.StatisticsData)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_STATISTICS_CHANGE)
end

-- 通知镜头移动到某格子
function XRogueSimAgency:NotifyRogueSimCameraMoveToGrid(data)
    if not data then
        return
    end
    -- 目前不配置这个effect效果，等配置再接入，该事件是用c#接口注册，需要改用c#接口触发
    --XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_FOCUS_GRID, data.GridId)
end

-- 通知区域解锁
function XRogueSimAgency:NotifyRogueSimAreaUnlock(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    self._Model.ActivityData:SetAreaIsUnlock(data.AreaId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddExploredGridIds(data.ExploredGridIds)
    -- data.ExploreRewards 在通用的奖励下发协议中处理
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, data.ExploredGridIds)
end

-- 通知特殊已探索格子
function XRogueSimAgency:NotifyRogueSimSpGridUnlock(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    --self._Model.ActivityData:SetAreaIsUnlock(data.AreaId) -- 任务显示用，不在此处解锁
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:UpdateSpExploredGridIds(data.SpExploredGridIds)
end

-- 通知传闻添加
function XRogueSimAgency:NotifyRogueSimTipAdd(data)
    if not data then
        return
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return
    end
    stageData:AddTipIdByTurnNumber(data.TurnNumber, data.TipId)
    self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.NewTips, data.TurnNumber, data.TipId)
end

function XRogueSimAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RogueSim, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipError(self._Model:GetClientConfig("ActivityNotOpenTip", 1))
        end
        return false
    end
    return true
end

-- 检查是否处于活动的游戏时间
function XRogueSimAgency:CheckActivityIsInGameTime()
    local timeId = self._Model:GetActivityGameTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

-- 检查关卡是否在开启时间内
function XRogueSimAgency:CheckStageIsInOpenTime(stageId)
    local timeId = self._Model:GetRogueSimStageTimeId(stageId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

-- 获取活动结束时间
function XRogueSimAgency:GetActivityEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 获取关卡结束时间
function XRogueSimAgency:GetActivityGameEndTime()
    local timeId = self._Model:GetActivityGameTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 获取玩法商店Id
function XRogueSimAgency:GetShopId()
    local shopId = tonumber(self._Model:GetClientConfig("ShopId", 1))
    return shopId
end

-- 关卡列表是否显示蓝点
function XRogueSimAgency:IsShowStagesRedPoint()
    local stageIds = self._Model:GetActivityStageIds()
    for _, stageId in ipairs(stageIds) do
        if self:IsShowStageRedPoint(stageId) then 
            return true
        end
    end
    return false
end

-- 是否显示关卡蓝点
function XRogueSimAgency:IsShowStageRedPoint(stageId)
    -- 游戏时间已过，不显示蓝点
    if not self:CheckActivityIsInGameTime() then
        return false
    end

    -- 已进入过关卡，不显示蓝点
    local record = self._Model:GetStageRecord(stageId)
    if record then
        return false
    end
    local stageData = self._Model:GetStageData()
    if stageData and stageData:GetStageId() == stageId then
        return false
    end

    -- 未到解锁时间，不显示蓝点
    local timeId = self._Model:GetRogueSimStageTimeId(stageId)
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false 
    end
    -- 前置关卡未解锁，不显示蓝点
    local preStageId = self._Model:GetRogueSimStagePreStageId(stageId)
    local isPrePass = preStageId == 0 or self._Model:CheckStageIsPass(preStageId)
    if not isPrePass then 
        return false
    end

    return true
end

-- 是否显示商店蓝点
function XRogueSimAgency:IsShowShopRedPoint()
    -- 未在配置时间内，不显示蓝点
    local timerId = tonumber(self._Model:GetClientConfig("ShopRedPointTimerId", 1))
    if not XFunctionManager.CheckInTimeByTimeId(timerId) then 
        return false
    end

    -- 代币数目不超过阈值，不显示蓝点
    local redPointCoinNumber = tonumber(self._Model:GetClientConfig("ShopRedPointCoinNumber", 1))
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RogueSimCoin)
    if ownCnt < redPointCoinNumber then
        return false
    end

    -- 代币数目超过阈值，且存在【尚未售罄】的商品时，显示蓝点
    local shopId = self:GetShopId()
    local shopGoods = XShopManager.GetShopGoodsList(shopId, true)
    local previewGoods = {}
    for _, good in ipairs(shopGoods) do
        local isSellOut = good.BuyTimesLimit > 0 and good.TotalBuyTimes >= good.BuyTimesLimit
        local needCount = good.ConsumeList[1].Count
        local canBuy = ownCnt >= needCount
        if not isSellOut and canBuy and self:IsConditionsReach(good.ConditionIds) then
            return true
        end
    end

    return false
end

-- 是否达成所有条件
function XRogueSimAgency:IsConditionsReach(conditionIds)
    if not conditionIds or #conditionIds == 0 then
        return true
    end

    for _, id in pairs(conditionIds) do
        local isReach, desc = XConditionManager.CheckCondition(id)
        if not isReach then
            return false
        end
    end
    return true
end

-- 获取通过的关卡数和关卡总数
function XRogueSimAgency:GetPassStageCount()
    local stageIds = self._Model:GetActivityStageIds()
    local passCount = 0
    for _, stageId in ipairs(stageIds) do
        if self:CheckStageIsPass(stageId) then
            passCount = passCount + 1
        end
    end
    return passCount, #stageIds
end

--region 副本入口扩展

function XRogueSimAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end
    -- 打开主界面
    XLuaUiManager.Open("UiRogueSimMain")
end

function XRogueSimAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XRogueSimAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.RogueSim
end

function XRogueSimAgency:ExCheckInTime()
    return self.Super.ExCheckInTime(self)
end

function XRogueSimAgency:ExGetProgressTip()
    -- 游戏进行中，显示当前游戏进度
    local stageDate = self._Model:GetStageData()
    if stageDate then
        local stageId = stageDate:GetStageId()
        local stageName = self._Model:GetRogueSimStageName(stageId)
        local curTurn = stageDate:GetTurnNumber()
        local maxTurn = self._Model:GetRogueSimStageMaxTurnCount(stageId)
        local desc = self._Model:GetClientConfig("ActivityEntryProgressTips", 2)
        return string.format(desc, stageName, curTurn, maxTurn)
    end

    -- 游戏时间结束，不显示进度
    local isInGameTime = self:CheckActivityIsInGameTime()
    if not isInGameTime then
        return ""
    end

    -- 游戏时间未结束，显示通关进度
    local passCount, totalCount = self:GetPassStageCount()
    local desc = self._Model:GetClientConfig("ActivityEntryProgressTips", 1)
    return string.format(desc, passCount, totalCount)
end

function XRogueSimAgency:ExGetRunningTimeStr()
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local gameEndTime = self:GetActivityGameEndTime()
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        local desc = self._Model:GetClientConfig("MainCountDownDesc", 1)
        return string.format(desc, timeStr)
    else
        -- 兑换时间
        local endTime = self:GetActivityEndTime()
        local exchangeTime = endTime - XTime.GetServerNowTimestamp()
        if exchangeTime < 0 then
            exchangeTime = 0
        end
        local timeStr = XUiHelper.GetTime(exchangeTime, XUiHelper.TimeFormatType.ACTIVITY)
        local desc = self._Model:GetClientConfig("ExchangeCountDownDesc", 1)
        return string.format(desc, timeStr)
    end
end

function XRogueSimAgency:ExCheckIsShowRedPoint()
    if not self:GetIsOpen(true) then return false end

    if self:IsShowStagesRedPoint() then return true end
    if self:IsShowShopRedPoint() then return true end

    return false
end

--endregion

--region Condition相关

-- 当前回合数比较
function XRogueSimAgency:TurnNumberCompare(targetTurn, camp)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local curTurn = stageData:GetTurnNumber()
    return self._Model:CompareInt(curTurn, targetTurn, camp)
end

-- 当前繁荣度比较
function XRogueSimAgency:ProsperityCompare(targetProsperity, camp)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local curProsperity = stageData:GetResourceCount(XEnumConst.RogueSim.ResourceId.Exp)
    return self._Model:CompareInt(curProsperity, targetProsperity, camp)
end

-- 上回合结算时是否触发生产暴击
function XRogueSimAgency:CheckIsProductionCritical(flag)
    local turnSettle = self._Model.TurnSettleData
    if not turnSettle then
        return false
    end
    local turnNumber = turnSettle:GetTurnNumber()
    if turnNumber <= 0 then
        return false
    end
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local produceResult = stageData:GetProduceResultByTurnNumber(turnNumber)
    if not produceResult then
        return false
    end
    local isCritical = produceResult:CheckProduceCritical()
    local tmpFlag = isCritical and 1 or 0
    return tmpFlag == flag
end

-- 上回合结算时是否触发销售暴击
function XRogueSimAgency:CheckIsSellCritical(flag)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local lastTurn = stageData:GetTurnNumber() - 1
    if lastTurn <= 0 then
        return false
    end
    local lastSellResult = stageData:GetSellResultByTurnNumber(lastTurn)
    if not lastSellResult then
        return false
    end
    -- 出售列表
    local infos = lastSellResult:GetDatas()
    for _, info in pairs(infos) do
        local isCritical = info:GetIsCritical()
        local tmpFlag = isCritical and 1 or 0
        if tmpFlag == flag then
            return true
        end
    end
    return false
end

-- 检查关卡是否通关
function XRogueSimAgency:CheckStageIsPass(stageId)
    return self._Model:CheckStageIsPass(stageId)
end

-- 检查当前关卡类型
---@param type number 1:教学关 2:普通关
function XRogueSimAgency:CheckCurStageType(type)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local stageId = stageData:GetStageId()
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    local stageType = self._Model:GetRogueSimStageType(stageId)
    return stageType == type
end

-- 检查引导是否触发过
---@param guideId number 引导Id
---@param flag number 1:已触发 2:未触发
function XRogueSimAgency:CheckGuideIsTrigger(guideId, flag)
    if not XTool.IsNumberValid(guideId) then
        return false
    end
    if not self._Model.ActivityData then
        return false
    end
    local isTrigger = self:GetGuideIsTriggerById(guideId)
    local tmpFlag = isTrigger and 1 or 2
    return tmpFlag == flag
end

-- 检查当前主城等级
---@param level number 目标主城等级
---@param camp number 比较类型
function XRogueSimAgency:MainLevelCompare(level, camp)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local curMainLevel = stageData:GetMainLevel()
    return self._Model:CompareInt(curMainLevel, level, camp)
end

-- 检查通关关卡次数
function XRogueSimAgency:CheckPassStageCount(stageId, count)
    local record = self._Model:GetStageRecord(stageId)
    if not record then
        return false
    end
    local passCount = record:GetFinishedTimes()
    return passCount >= count
end

-- 检查通关星级总数
function XRogueSimAgency:CheckPassStarCount(count)
    local stageIds = self._Model:GetActivityStageIds()
    local starCount = 0
    for _, stageId in ipairs(stageIds) do
        local record = self._Model:GetStageRecord(stageId)
        if record then
            starCount = starCount + self._Model:CountBit(record:GetStarMask())
        end
    end
    return starCount >= count
end

--endregion

--region 本地信息相关

-- 获取引导是否已触发通过引导Id
function XRogueSimAgency:GetGuideIsTriggerById(guideId)
    local key = self._Model:GetGuideRecordKey()
    local guideRecord = XSaveTool.GetData(key) or {}
    return guideRecord[guideId] or false
end

--endregion

--region 临时背包相关

-- 获取临时背包奖励数据
---@return table<number, number> key:货物Id, value:数量
function XRogueSimAgency:GetTemporaryBagRewardData()
    local temporaryBagData = self._Model:GetStageData():GetTemporaryBagData()
    if not temporaryBagData then
        return {}
    end
    local rewardData = {}
    for _, data in pairs(temporaryBagData) do
        rewardData[data:GetId()] = data:GetCount()
    end
    return rewardData
end

-- 获取临时背包数据变化（只收集减少的数据）
---@param beforeData table<number, number> key:货物Id, value:数量
---@param afterData table<number, number> key:货物Id, value:数量
---@return table<number, number> key:货物Id, value:数量
function XRogueSimAgency:GetTemporaryBagDataChange(beforeData, afterData)
    local changeData = {}
    for _, id in pairs(XEnumConst.RogueSim.CommodityIds) do
        local changeCount = (beforeData[id] or 0) - (afterData[id] or 0)
        if changeCount > 0 then
            changeData[id] = changeCount
        end
    end
    return changeData
end

--endregion

return XRogueSimAgency
