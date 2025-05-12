---@class XGachaCanLiverControl : XControl
---@field private _Model XGachaCanLiverModel
local XGachaCanLiverControl = XClass(XControl, "XGachaCanLiverControl")
function XGachaCanLiverControl:OnInit()
    --初始化内部变量
end

function XGachaCanLiverControl:AddAgencyEvent()
    
end

function XGachaCanLiverControl:RemoveAgencyEvent()

end

function XGachaCanLiverControl:OnRelease()
    self:StopTimelimitDrawLeftTimer()
end

--region ActivityData

function XGachaCanLiverControl:GetGachaSpecialRewardInfoList(gachaId)
    local dataList = XDataCenter.GachaManager.GetGachaRewardInfoById(gachaId)
    
    local result = nil

    if not XTool.IsTableEmpty(dataList) then
        result = {}

        for i, v in pairs(dataList) do
            if v.Rare then
                table.insert(result, v)
            end
        end
    end
    
    return result
end

function XGachaCanLiverControl:GetCurActivityFreeItemIdGainTimes()
    return self._Model:GetCurActivityFreeItemIdGainTimes()
end

--- 获取剩余可领取的免费次数
function XGachaCanLiverControl:GetLeftCanGetFreeItemCount()
    local freeCoinLimit = self:GetCurActivityFreeItemGainUpLimit()
    local hasGotFreeCount = self:GetCurActivityFreeItemIdGainTimes()
    local leftCanGetCount = freeCoinLimit - hasGotFreeCount
    
    return leftCanGetCount
end
--endregion

--region ActivityData-Config -- 基于服务端数据的配置表读取逻辑

--- GachaCanLiverShow

--- 获取当前活动的商店入口奖励预览的奖励Id
function XGachaCanLiverControl:GetCurActivityShopShowRewardId()
    local curActivityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self._Model:GetGachaCanLiverShowCfgById(curActivityId)

        if cfg then
            return cfg.ShopShowRewardId
        end
    end
end

function XGachaCanLiverControl:GetCurActivityCharacterId()
    local curActivityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self._Model:GetGachaCanLiverShowCfgById(curActivityId)

        if cfg then
            return cfg.CharacterId
        end
    end
end

function XGachaCanLiverControl:GetCurActivityCharacterSkipId()
    local curActivityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self._Model:GetGachaCanLiverShowCfgById(curActivityId)

        if cfg then
            return cfg.CharacterSkipId
        end
    end
end

--- 特殊奖励显示数目限制
function XGachaCanLiverControl:GetCurActivitySpecialRewardLimitCount()
    local curActivityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self._Model:GetGachaCanLiverShowCfgById(curActivityId)

        if cfg then
            return cfg.SpecialRewardLimitCount
        end
    end
end

--- GachaCanLiver

function XGachaCanLiverControl:GetCurActivityFreeItemId()
    return self._Model:GetCurActivityFreeItemId()
end

function XGachaCanLiverControl:GetCurActivityFreeItemCount()
    local itemId = self:GetCurActivityFreeItemId()

    if XTool.IsNumberValid(itemId) then
        return XDataCenter.ItemManager.GetCount(itemId)
    end

    return 0
end

function XGachaCanLiverControl:GetCurActivityFreeItemGainUpLimit()
    return self._Model:GetCurActivityFreeItemGainUpLimit()
end

function XGachaCanLiverControl:GetCurActivityCoinItemId()
    return self._Model:GetCurActivityCoinItemId()
end

function XGachaCanLiverControl:GetCurActivityCoinItemCount()
    local itemId = self:GetCurActivityCoinItemId()

    if XTool.IsNumberValid(itemId) then
        return XDataCenter.ItemManager.GetCount(itemId)
    end
    
    return 0
end

function XGachaCanLiverControl:GetCurActivityShopIds(ignoreClosed)
    return self._Model:GetCurActivityShopIds(ignoreClosed)
end

function XGachaCanLiverControl:GetCurActivityResidentShopId()
    return self._Model:GetCurActivityResidentShopId()
end

function XGachaCanLiverControl:GetCurActivityTimelimitShopId()
    return self._Model:GetCurActivityTimelimitShopId()
end

function XGachaCanLiverControl:GetCurActivityTaskIds()
    --- 常驻任务
    local taskIds = self._Model:GetCurActivityTaskIds()
    local taskDataList = XDataCenter.TaskManager.GetTaskIdListData(taskIds, false)
    
    -- 限时任务
    local taskTimeLimitGroupIds = self._Model:GetCurActivityTaskTimeLimitGroupIds()
    if not XTool.IsTableEmpty(taskTimeLimitGroupIds) then
        for i, groupId in pairs(taskTimeLimitGroupIds) do
            local timeLimitTaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, false, false)

            if not XTool.IsTableEmpty(timeLimitTaskDataList) then
                for i2, data in pairs(timeLimitTaskDataList) do
                    table.insert(taskDataList, data)
                end
            end
        end
    end
    
    return taskDataList
end

function XGachaCanLiverControl:GetCurActivityResidentGachaId()
    return self._Model:GetCurActivityResidentGachaId()
end

function XGachaCanLiverControl:GetCurActivityTimeLimitGachaIds()
    return self._Model:GetCurActivityTimeLimitGachaIds()
end

--- 获取当前的最新开启的限时卡池Id
function XGachaCanLiverControl:GetCurActivityLatestTimelimitGachaId()
    local ids = self:GetCurActivityTimeLimitGachaIds()

    if not XTool.IsTableEmpty(ids) then
        for i = #ids, 1, -1 do
            local id = ids[i]

            if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(id) then
                return id
            end
        end
        
        -- 如果都没有开启，则默认打开第一个
        return ids[1]
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end
end

--- 获取当前的最新开启的限时卡池索引
function XGachaCanLiverControl:GetCurActivityLatestTimelimitGachaIndex()
    local ids = self:GetCurActivityTimeLimitGachaIds()

    if not XTool.IsTableEmpty(ids) then
        for i = #ids, 1, -1 do
            local id = ids[i]

            if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(id) then
                return i
            end
        end

        -- 如果都没有开启，则默认打开第一个
        return 1
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end
end

--- 获取指定id的限时卡池索引
function XGachaCanLiverControl:GetCurActivityLatestTimelimitGachaIndexById(gachaId)
    local ids = self:GetCurActivityTimeLimitGachaIds()

    if not XTool.IsTableEmpty(ids) then
        for i = #ids, 1, -1 do
            local id = ids[i]

            if gachaId == id then
                return i
            end
        end

        XLog.Error('限时卡池组I找不到Id为:'..tostring(gachaId)..'的配置，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
        return 1
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end
end

--- 获取当前的最新开启的限时卡池Id
function XGachaCanLiverControl:GetCurActivityTimelimitGachaIdByIndex(index)
    local ids = self:GetCurActivityTimeLimitGachaIds()

    if not XTool.IsTableEmpty(ids) then
        return ids[index]
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end
end

--- 获取当前解锁的卡池数
function XGachaCanLiverControl:GetCurActivityTimelimitGachaUnlockCount()
    local ids = self:GetCurActivityTimeLimitGachaIds()
    local count = 0
    
    if not XTool.IsTableEmpty(ids) then
        for i = #ids, 1, -1 do
            local id = ids[i]

            if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(id) then
                count = count + 1
            end
        end
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end
    
    return count
end

--- 获取当前未解锁的卡池数
function XGachaCanLiverControl:GetCurActivityTimelimitGachaLockCount()
    local ids = self:GetCurActivityTimeLimitGachaIds()
    local lockCount = 0
    if not XTool.IsTableEmpty(ids) then
        local count = #ids
        lockCount = count - self:GetCurActivityTimelimitGachaUnlockCount()
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end

    return lockCount
end
--endregion

--region Config
function XGachaCanLiverControl:GetConfigPanelAssetItemIds(activityId)
    ---@type XTableGachaCanLiverShow
    local cfg = self._Model:GetGachaCanLiverShowCfgById(activityId)

    if cfg then
        return cfg.PanelAssetItemIds
    end
end

--- 抽卡道具的Id(非免费）
function XGachaCanLiverControl:GetConsumeItemId(gachaId)
    ---@type XTableGacha
    local gachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)

    if gachaCfg then
        return gachaCfg.ConsumeId
    end
end

--- 单次抽取消耗的道具数量
function XGachaCanLiverControl:GetConsumeCount(gachaId)
    ---@type XTableGacha
    local gachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)

    if gachaCfg then
        return gachaCfg.ConsumeCount
    end
end
--endregion

--region 界面数据
function XGachaCanLiverControl:SetCurShowGachaId(gachaId)
    self._CurShowGachaId = gachaId
end

function XGachaCanLiverControl:GetCurShowGachaId()
    return self._CurShowGachaId or 0
end

function XGachaCanLiverControl:SetCurShowGachaIsTimelimit(isTimelimit)
    self._CurShowGachaIsTimelimit = isTimelimit
end

function XGachaCanLiverControl:GetCurShowGachaIsTimelimit()
    return self._CurShowGachaIsTimelimit or false
end
--endregion

--region 踢出检查

function XGachaCanLiverControl:SetLockTickout(isLock)
    self._LockTickOut = isLock
end

function XGachaCanLiverControl:StopTimelimitDrawLeftTimer()
    if self._DrawLeftTimerId then
        XScheduleManager.UnSchedule(self._DrawLeftTimerId)
        self._DrawLeftTimerId = nil
    end

    if self._DrawLeftTimerNextFrameId then
        XScheduleManager.UnSchedule(self._DrawLeftTimerNextFrameId)
        self._DrawLeftTimerNextFrameId = nil
    end
end

function XGachaCanLiverControl:StartTimelimitDrawLeftTimer()
    self:StopTimelimitDrawLeftTimer()
    self._DrawLeftTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimelimitDrawTimeShow), XScheduleManager.SECOND)
    self._DrawLeftTimerNextFrameId = XScheduleManager.ScheduleNextFrame(function()
        self:UpdateTimelimitDrawTimeShow()
        self._DrawLeftTimerNextFrameId = nil
    end)
end

function XGachaCanLiverControl:UpdateTimelimitDrawTimeShow()
    local now = XTime.GetServerNowTimestamp()

    --- 限时卡池时间统一
    local gachaId = self:GetCurActivityTimelimitGachaIdByIndex(1)

    ---@type XTableGacha
    local gachaCfg = XGachaConfigs.GetGachaCfgById(gachaId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(gachaCfg.TimeId)

    local leftTime = math.max(0, endTime - now)

    if leftTime <= 0 then
        if not self._LockTickOut then
            self:StopTimelimitDrawLeftTimer()
            XUiManager.TipMsg(XGachaConfigs.GetClientConfig('TimelimitDrawIsOver'))
            XLuaUiManager.RunMain()
        end
    end
end
--endregion

return XGachaCanLiverControl