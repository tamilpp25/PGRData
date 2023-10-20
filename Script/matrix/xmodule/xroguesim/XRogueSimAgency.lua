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
            XUiManager.TipText("CommonActivityNotStart")
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

function XRogueSimAgency:IsShowStageRedPoint()
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
    local isInGameTime = self:CheckActivityIsInGameTime()
    if not isInGameTime then
        return ""
    end

    local stageDate = self._Model:GetStageData()
    if not stageDate then
        local passCount, totalCount = self:GetPassStageCount()
        local desc = self._Model:GetClientConfig("ActivityEntryProgressTips", 1)
        return string.format(desc, passCount, totalCount)
    end
    local stageId = stageDate:GetStageId()
    local stageName = self._Model:GetRogueSimStageName(stageId)
    local curTurn = stageDate:GetTurnNumber()
    local maxTurn = self._Model:GetRogueSimStageMaxTurnCount(stageId)
    local desc = self._Model:GetClientConfig("ActivityEntryProgressTips", 2)
    return string.format(desc, stageName, curTurn, maxTurn)
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
function XRogueSimAgency:CheckIsProductionCritical(isTrigger)
    local turnSettle = self._Model.TurnSettleData
    if not turnSettle then
        return false
    end
    local isCritical = turnSettle.CommodityProduceIsCritical or false
    return isCritical == isTrigger
end

-- 上回合结算时是否触发销售暴击
function XRogueSimAgency:CheckIsSellCritical(isTrigger)
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
        if info:GetIsCritical() == isTrigger then
            return true
        end
    end
    return false
end

-- 检查关卡是否通关
function XRogueSimAgency:CheckStageIsPass(stageId)
    return self._Model:CheckStageIsPass(stageId)
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

return XRogueSimAgency
