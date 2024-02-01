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
    XRpc.NotifyRogueSimExploredGridIdsAdd = handler(self, self.NotifyRogueSimExploredGridIdsAdd)
    XRpc.NotifyRogueSimVisibleGridIdsAdd = handler(self, self.NotifyRogueSimVisibleGridIdsAdd)
    XRpc.NotifyRogueSimResourceChange = handler(self, self.NotifyRogueSimResourceChange)
    XRpc.NotifyRogueSimCommodityChange = handler(self, self.NotifyRogueSimCommodityChange)
    XRpc.NotifyRogueSimEventAdd = handler(self, self.NotifyRogueSimEventAdd)
    XRpc.NotifyRogueSimEventRemoves = handler(self, self.NotifyRogueSimEventRemoves)
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
    XRpc.NotifyActionPiont = handler(self, self.NotifyActionPoint)
    XRpc.NotifyRogueSimStatisticsData = handler(self, self.NotifyRogueSimStatisticsData)
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
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, data)
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
    self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.Buff, data.BuffData)
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
        XLog.Warning("属性加成：", data.CommodityAdds)
        XLog.Warning("杂项加成：", data.MiscAdds)
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

-- 通知更新行动点
function XRogueSimAgency:NotifyActionPoint(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    self._Model.ActivityData:UpdateActionPoint(data.ActionPoint)
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

function XRogueSimAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RogueSim, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipError(self._Model:GetClientConfig("ActivityNotOpenTip",1))
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

-- 是否显示关卡蓝点
function XRogueSimAgency:IsShowStageRedPoint()
    if not self:GetIsOpen(true) then
        return false
    end

    -- 正在进行关卡游戏中，显示红点
    local isPlaying = not self._Model:CheckStageDataEmpty()
    if isPlaying then
        return true
    end

    -- 已开启关卡存在未首通的，显示红点
    if self:CheckActivityIsInGameTime() then
        local stageIds = self._Model:GetActivityStageIds()
        for _, stageId in ipairs(stageIds) do
            local isInTime = self:CheckStageIsInOpenTime(stageId)
            local isPass = self:CheckStageIsPass(stageId)
            if isInTime and not isPass then
                return true
            end
        end
    end

    return false
end

-- 获取玩法商店Id
function XRogueSimAgency:GetShopId()
    local shopId = tonumber(self._Model:GetClientConfig("ShopId", 1))
    return shopId
end

-- 是否显示商店蓝点
function XRogueSimAgency:IsShowShopRedPoint()
    if not self:GetIsOpen(true) then
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
    -- 保持FubenActivity表TimeId清空功能有效
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
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

-- 剩余行动点比较
function XRogueSimAgency:ActionPointCompare(targetActionPoint, camp)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local curActionPoint = stageData:GetActionPoint()
    return self._Model:CompareInt(curActionPoint, targetActionPoint, camp)
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
    local isCritical = turnSettle.CommodityProduceIsCritical or false
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

-- 检查建筑是否购买
---@param buildingId number 建筑配置Id
function XRogueSimAgency:CheckBuildingIsBuy(buildingId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local buildingInfo = stageData:GetBuildingData()
    if not buildingInfo then
        return false
    end
    for _, data in pairs(buildingInfo) do
        if data:GetConfigId() == buildingId then
            return data:CheckIsBuy()
        end
    end
    return false
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

return XRogueSimAgency
