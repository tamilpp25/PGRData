---@class XWheelchairManualModel : XModel
local XWheelchairManualModel = XClass(XModel, "XWheelchairManualModel")

local TableNormal = {
    WheelchairManualActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualTabs = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key" },
    WheelchairManualActivityShow = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "ActivityId" },

    WheelchairManualGuideActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualGuideActivityPeriod = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualGuideWeekActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualGuideWeekReward = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },

    WheelchairManualBattlePassPlan = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualBattlePassReward = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualBattlePassManual = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },

}

local TablePrivate = {
    WheelchairManualCharacterPlan = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "ActivityId" },
    WheelchairManualBattlePassLevel = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    WheelchairManualPassportScrollCards = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "ActivityId" },
    WheelchairManualPassportPrefab = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "ActivityId" },
    

    WheelchairManualGuideKind = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
}

local XWheelchairManualGuideViewData = require('XModule/XWheelchairManual/Entity/XWheelchairManualGuideViewData')


function XWheelchairManualModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("WheelchairManual", TableNormal, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("WheelchairManual", TablePrivate, XConfigUtil.CacheType.Private)
end

function XWheelchairManualModel:ClearPrivate()

end

function XWheelchairManualModel:ResetAll()
    -- 清空活动数据
    self._ManualData = nil
    self._ActivityDataList = nil
    self._ActivityDataMap = nil
    self._HasInitWeekActivityViewModel = nil
end

--region ActivityData

function XWheelchairManualModel:UpdateManualData(data)
    self._ManualData = {}
    self._ManualData.ActivityId = data.ActivityId
    self._ManualData.PlanId = data.PlanId
    self._ManualData.BpLevel = data.BpLevel
    self._ManualData.IsSeniorManualUnlock = data.IsSeniorManualUnlock
    self._ManualData.GetRewardPlanIdList = data.GetRewardPlanIds
    self._ManualData.FinishStageIdList = data.FinishStageIds
    self._ManualData.GetRewardManualRewardIds = data.GetRewardManualRewardIds
    self._ManualData.TimeLimitActivityInfos = data.TimeLimitActivityInfos
    self._ManualData.WeekActivityInfos = data.WeekActivityInfos
    self._ManualData.BluePointSet = data.BluePointSet -- 页签首次点击的红点
    self._ManualData.RedPointSet = data.RedPointSet -- 其他杂红点
    self._ManualData.StartTick = data.StartTick
    self.CurrentGuildBossEndTime = data.CurrentGuildBossEndTime
    --针对引导活动需要合在一起参与排序
    -- 当前开启的活动Id是全量，覆盖和刷新新增
    self:_InitGuideTimeLimitActivityViewModel(data)
    self:_InitWeekActivityViewModel()
    self:RefreshViewData(data)
    
    XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_ACTIVITY_UPDATE)
end

function XWheelchairManualModel:GetCurActivityId()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.ActivityId or 0
    end
    return 0
end

function XWheelchairManualModel:RefreshViewData(data)
    -- 将限时活动数据写入存在的视图数据中
    if not XTool.IsTableEmpty(self._ManualData.TimeLimitActivityInfos) then
        for i, v in pairs(self._ManualData.TimeLimitActivityInfos) do
            local viewData = self._ActivityDataMap[v.ActivityId]

            if viewData then
                viewData:InitData(v)
            end
        end
    end
    
    -- 将周常活动数据写入存在的视图数据中
    if not XTool.IsTableEmpty(self._ManualData.WeekActivityInfos) then
        for i, v in pairs(self._ManualData.WeekActivityInfos) do
            local viewData = self._ActivityDataMap[v.MainId]

            if viewData then
                viewData:InitData(v)
            end
        end
    end
end

function XWheelchairManualModel:UpdateGuideData(data)
    -- 将限时活动数据写入存在的视图数据中
    self:_UpdateGuideTimelimitActivityData(data)
    
    -- 将周常活动数据写入存在的视图数据中
    self:_UpdateGuideWeekActivityData(data)
    
    XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_GUIDE_ACTIVITY_UPDATE)
end

function XWheelchairManualModel:_InitGuideTimeLimitActivityViewModel(data)
    if self._ActivityDataList == nil then
        self._ActivityDataList = {}
    end

    -- <ActivityId, viewData>
    if self._ActivityDataMap == nil then
        self._ActivityDataMap = {}
    end
    
    local isTimelimitActivityEmpty = XTool.IsTableEmpty(data.OpenActivityIds)
    local isLastNotEmpty = not XTool.IsTableEmpty(self._ActivityDataList)
    
    -- 刷新生成限时活动的视图数据对象
    if not isTimelimitActivityEmpty then
        -- 更新新增的部分
        for i, id in pairs(data.OpenActivityIds) do
            local viewData = self._ActivityDataMap[id]

            if not viewData then
                local newViewData = XWheelchairManualGuideViewData.New()
                newViewData:InitConfig(self:GetWheelchairManualGuideActivityCfg(id))
                newViewData:SetIsTimelimitActivity(true)
                self._ActivityDataMap[id] = newViewData
                table.insert(self._ActivityDataList, newViewData)
            end
        end
        -- 移除减少的部分
        if not XTool.IsTableEmpty(self._ManualData.OpenActivityIds) then
            for i, id in pairs(self._ManualData.OpenActivityIds) do
                if not table.contains(data.OpenActivityIds, id) then
                    local viewData = self._ActivityDataMap[id]

                    if viewData then
                        local isin, index = table.contains(self._ActivityDataList, viewData)
                        self._ActivityDataMap[id] = nil

                        if isin then
                            table.remove(self._ActivityDataList, index)
                        end
                    end
                end
            end
        end
    end

    if isTimelimitActivityEmpty and isLastNotEmpty then
        -- 所有活动都关闭了，执行清空
        for i = #self._ActivityDataList, 1, -1 do
            ---@type XWheelchairManualGuideViewData
            local data = self._ActivityDataList[i]
            if data:IsTimelimitActivity() then
                table.remove(self._ActivityDataList, i)
                local id = data:GetId()

                if XTool.IsNumberValid(id) then
                    self._ActivityDataMap[id] = nil
                end
            end
        end
    end
    
    -- 全量覆盖
    self._ManualData.OpenActivityIds = data.OpenActivityIds
end 

function XWheelchairManualModel:_UpdateGuideTimelimitActivityData(data)
    if not XTool.IsTableEmpty(data.UpdateTimeLimitActivityInfos) then
        for i, v in pairs(data.UpdateTimeLimitActivityInfos) do
            local viewData = self._ActivityDataMap[v.ActivityId]

            if viewData then
                viewData:InitData(v)
            end
        end
    end
end

function XWheelchairManualModel:GetActivityId()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.ActivityId or 0
    end
    
    return 0
end

function XWheelchairManualModel:GetPlanId()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.PlanId or 0
    end

    return 0
end

function XWheelchairManualModel:GetBpLevel()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.BpLevel or 0
    end

    return 0
end

function XWheelchairManualModel:GetRewardPlanIdList()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.GetRewardPlanIdList
    end
end

function XWheelchairManualModel:CheckManualRewardIsGet(id)
    if not XTool.IsTableEmpty(self._ManualData) and not XTool.IsTableEmpty(self._ManualData.GetRewardManualRewardIds) then
        return table.contains(self._ManualData.GetRewardManualRewardIds, id)
    end
    
    return false
end

function XWheelchairManualModel:GetManualRewardIds()
    if not XTool.IsTableEmpty(self._ManualData) and not XTool.IsTableEmpty(self._ManualData.GetRewardManualRewardIds) then
        return self._ManualData.GetRewardManualRewardIds
    end
end

function XWheelchairManualModel:GetIsSeniorManualUnLock()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.IsSeniorManualUnlock or false
    end

    return false
end 

function XWheelchairManualModel:GetActivityDataList()
    return self._ActivityDataList
end

function XWheelchairManualModel:CheckPlanIsGetReward(planId)
    local gotList = self:GetRewardPlanIdList()

    return not XTool.IsTableEmpty(gotList) and table.contains(gotList, planId) or false
end

-- 将一个页签的首次显示红点提示点掉
function XWheelchairManualModel:SetBulePointAsOld(type)
    if not XTool.IsTableEmpty(self._ManualData) and not XTool.IsTableEmpty(self._ManualData.BluePointSet) then
        local isin, index = table.contains(self._ManualData.BluePointSet, type)

        if isin then
            table.remove(self._ManualData.BluePointSet, index)
            return true
        end
    end
    return false
end

-- 判断一个页签的首次显示红点是否存在
function XWheelchairManualModel:CheckBulePointIsNew(type)
    if not XTool.IsTableEmpty(self._ManualData) and not XTool.IsTableEmpty(self._ManualData.BluePointSet) then
        local isin, index = table.contains(self._ManualData.BluePointSet, type)

        return isin
    end
    return false
end

-- 将一个新解锁显示红点提示点掉
function XWheelchairManualModel:SetUnlockBulePointAsOld(id)
    if not XTool.IsTableEmpty(self._ManualData) and not XTool.IsTableEmpty(self._ManualData.RedPointSet) then
        local isin, index = table.contains(self._ManualData.RedPointSet, id)

        if isin then
            table.remove(self._ManualData.RedPointSet, index)
            return true
        end
    end
    return false
end

-- 判断一个新解锁显示红点是否存在
function XWheelchairManualModel:CheckUnlockBulePointIsNew(id)
    if not XTool.IsTableEmpty(self._ManualData) and not XTool.IsTableEmpty(self._ManualData.RedPointSet) then
        local isin, index = table.contains(self._ManualData.RedPointSet, id)

        return isin
    end
    return false
end

-- 客户端缓存蓝点消除
function XWheelchairManualModel:SetLocalReddotAsOld(key)
    local fullKey = self:GetLocalReddotKey()..key

    if not XSaveTool.GetData(fullKey) then
        XSaveTool.SaveData(fullKey, true)
    end
end

-- 判断客户端缓存蓝点是否存在
function XWheelchairManualModel:CheckLocalReddotIsShow(key)
    local fullKey = self:GetLocalReddotKey()..key
    
    return not XSaveTool.GetData(fullKey) and true or false
end

function XWheelchairManualModel:GetLocalReddotKey()
    return 'WheelchairManualClientReddot_'..tostring(XPlayer.Id)..'_'..tostring(self:GetCurActivityId())..'_'
end

function XWheelchairManualModel:GetStartTick()
    if not XTool.IsTableEmpty(self._ManualData) then
        return self._ManualData.StartTick or 0
    end
    return 0
end

---@return boolean, number @是否有倒计时，剩余时间
function XWheelchairManualModel:GetLeftTime()
    local countDown = self:GetCurActivityCountDown()

    if XTool.IsNumberValid(countDown) then
        local startTime = self:GetStartTick()

        if XTool.IsNumberValid(startTime) then
            local now = XTime.GetServerNowTimestamp()
            local leftTime = startTime + countDown - now

            if leftTime < 0 then
                leftTime = 0
            end
            
            return true, leftTime
        end
    end
    
    return false
end
--endregion

--region ActivityData - Configs
function XWheelchairManualModel:GetCurActivityPlanIds()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.PlanIds
        end
    end
end

function XWheelchairManualModel:GetCurActivityCommanManualId()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local activityCfg = self:GetWheelchairManualActivityCfg(activityId)

        if activityCfg then
            local manualId = activityCfg.CommonBattlePassManualId

            return manualId
        end
    end
end

function XWheelchairManualModel:GetCurActivitySeniorManualId()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local activityCfg = self:GetWheelchairManualActivityCfg(activityId)

        if activityCfg then
            local manualId = activityCfg.SeniorBattlePassManualId

            return manualId
        end
    end
end

function XWheelchairManualModel:GetCurActivityCommanManualRewardCfgIds()
    local manualId = self:GetCurActivityCommanManualId()

    if XTool.IsNumberValid(manualId) then
        local manualCfg = self:GetWheelchairManualBattlePassManualCfg(manualId)

        if manualCfg then
            local beginIndex = manualCfg.BpRewardConfig[1]
            local endIndex= manualCfg.BpRewardConfig[2]

            local cfgIds = {}
            for i = beginIndex, endIndex do
                table.insert(cfgIds, i)
            end

            return cfgIds
        end
    end
end

--- 获取普通手册的Id范围
---@return @<起始索引，末尾索引>
function XWheelchairManualModel:GetCurActivityCommanManualRewardIdRange()
    local manualId = self:GetCurActivityCommanManualId()

    if XTool.IsNumberValid(manualId) then
        local manualCfg = self:GetWheelchairManualBattlePassManualCfg(manualId)

        if manualCfg then
            local beginIndex = manualCfg.BpRewardConfig[1]
            local endIndex= manualCfg.BpRewardConfig[2]

            return beginIndex, endIndex
        end
    end
end

function XWheelchairManualModel:GetCurActivitySeniorManualRewardCfgIds()
    local manualId = self:GetCurActivitySeniorManualId()

    if XTool.IsNumberValid(manualId) then
        local manualCfg = self:GetWheelchairManualBattlePassManualCfg(manualId)

        if manualCfg then
            local beginIndex = manualCfg.BpRewardConfig[1]
            local endIndex= manualCfg.BpRewardConfig[2]

            local cfgIds = {}
            for i = beginIndex, endIndex do
                table.insert(cfgIds, i)
            end

            return cfgIds
        end
    end
end

--- 获取高级手册的Id范围
---@return @<起始索引，末尾索引>
function XWheelchairManualModel:GetCurActivitySeniorManualRewardIdRange()
    local manualId = self:GetCurActivitySeniorManualId()

    if XTool.IsNumberValid(manualId) then
        local manualCfg = self:GetWheelchairManualBattlePassManualCfg(manualId)

        if manualCfg then
            local beginIndex = manualCfg.BpRewardConfig[1]
            local endIndex= manualCfg.BpRewardConfig[2]

            return beginIndex, endIndex
        end
    end
end

function XWheelchairManualModel:GetCurActivityCountDown()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.CountDown
        end
    end
    return 0
end

function XWheelchairManualModel:GetCurActivityPurchaseUiType()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.PurchaseType
        end
    end
end

function XWheelchairManualModel:GetCurActivityShowPurchaseIds()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.ShowPackageIds
        end
    end
end

function XWheelchairManualModel:GetCurActivityLottoId()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.LottoId
        end
    end
end

--- 检查在索引范围内的bp奖励是否都获取了
function XWheelchairManualModel:CheckManualRewardIsAllGotInRange(beginIndex, endIndex)
    local rewardGotIds = self:GetManualRewardIds()
    -- 如果没有领奖数据，那么一定没有领取完
    if XTool.IsTableEmpty(rewardGotIds) then
        return false
    end

    -- 计算手册奖励数目
    local rewardCount = endIndex - beginIndex + 1

    -- 累计当前领取奖励
    local rewardGotCount = 0
    
    for i, id in pairs(rewardGotIds) do
        -- 如果id在普通奖励范围内，计数+1（此处信任服务端的id不会出现重复） 
        if id >= beginIndex and id <= endIndex then
            rewardGotCount = rewardGotCount + 1
        end
    end
    -- 如果已领取奖励数与普通奖励配置数量一致则认为领取完了所有奖励
    return rewardGotCount >= rewardCount
end
--endregion

--region Configs

---@return XTableWheelchairManualActivity
function XWheelchairManualModel:GetWheelchairManualActivityCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualActivity, id)
end

---@return XTableWheelchairManualActivityShow
function XWheelchairManualModel:GetWheelchairManualActivityShowCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualActivityShow, id)
end

---@return XTableWheelchairManualTabs
function XWheelchairManualModel:GetWheelchairManualTabsCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualTabs, id)
end

---@return XTableWheelchairManualBattlePassPlan
function XWheelchairManualModel:GetWheelchairManualPlanCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualBattlePassPlan, id)
end

---@return XTableWheelchairManualCharacterPlan
function XWheelchairManualModel:GetWheelchairManualCharacterPlanCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.WheelchairManualCharacterPlan, id)
end

---@return XTableWheelchairManualBattlePassLevel
function XWheelchairManualModel:GetWheelchairManualBattlePassLevelCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.WheelchairManualBattlePassLevel, id)
end

---@return XTableWheelchairManualBattlePassReward
function XWheelchairManualModel:GetWheelchairManualBattlePassRewardCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualBattlePassReward, id)
end

---@return XTableWheelchairManualBattlePassManual
function XWheelchairManualModel:GetWheelchairManualBattlePassManualCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualBattlePassManual, id)
end

---@return XTableWheelchairManualPassportScrollCards
function XWheelchairManualModel:GetWheelchairManualPassportScrollCardsCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.WheelchairManualPassportScrollCards, id)
end

---@return XTableWheelchairManualPassportPrefab
function XWheelchairManualModel:GetWheelchairManualPassportPrefabCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.WheelchairManualPassportPrefab, id)
end

---@return XTableWheelchairManualGuideActivity
function XWheelchairManualModel:GetWheelchairManualGuideActivityCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualGuideActivity, id)
end

---@return XTableWheelchairManualGuideActivityPeriod
function XWheelchairManualModel:GetWheelchairManualGuideActivityPeriodCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualGuideActivityPeriod, id)
end

function XWheelchairManualModel:GetWheelchairManualGuideWeekActivityCfgs()
    local cfgs = self._ConfigUtil:GetByTableKey(TableNormal.WheelchairManualGuideWeekActivity)

    if not cfgs then
        XLog.ErrorTableDataNotFound('XWheelchairManualModel:GetWheelchairManualGuideWeekActivityCfgs', "Share/WheelchairManual/WheelchairManualGuideWeekActivity.tab")
    end
    
    return cfgs
end

---@return XTableWheelchairManualGuideWeekActivity
function XWheelchairManualModel:GetWheelchairManualGuideWeekActivityCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualGuideWeekActivity, id)
end

---@return XTableWheelchairManualGuideWeekReward
function XWheelchairManualModel:GetWheelchairManualGuideWeekRewardCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualGuideWeekReward, id)
end

---@return XTableWheelchairManualGuideKind
function XWheelchairManualModel:GetWheelchairManualGuideKindCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.WheelchairManualGuideKind, id)
end

--- ClientConfig
function XWheelchairManualModel:GetWheelchairManualConfigNum(key, index)
    index = XTool.IsNumberValid(index) and index or 1
    
    ---@type XTableWheelchairManualClientConfig
    local cfg = self._ConfigUtil:GetByTableKey(TableNormal.WheelchairManualClientConfig)[key]

    if cfg then
        local value = cfg.Values[index]
        if not string.IsNilOrEmpty(value) and string.IsFloatNumber(value) then
            return tonumber(value)
        end
    end
    
    return 0
end

function XWheelchairManualModel:GetWheelchairManualConfigNumArray(key)
    ---@type XTableWheelchairManualClientConfig
    local cfg = self._ConfigUtil:GetByTableKey(TableNormal.WheelchairManualClientConfig)[key]

    if cfg then
        local valueList = {}
        for i, v in ipairs(cfg.Values) do
            if not string.IsNilOrEmpty(v) and string.IsFloatNumber(v) then
                table.insert(valueList, tonumber(v))
            end
        end
        return valueList
    end
end

function XWheelchairManualModel:GetWheelchairManualConfigString(key, index)
    index = XTool.IsNumberValid(index) and index or 1

    ---@type XTableWheelchairManualClientConfig
    local cfg = self._ConfigUtil:GetByTableKey(TableNormal.WheelchairManualClientConfig)[key]

    if cfg then
        local value = cfg.Values[index]
        return value or ''
    end

    return ''
end

function XWheelchairManualModel:GetManualPlanRewardTaskIds(planId)
    local cfg = self:GetWheelchairManualPlanCfg(planId)
    if cfg then
        return cfg.TaskIds
    end
end
--endregion

--region RedPoint
function XWheelchairManualModel:GetActivityKey()
    return 'WheelchairManaul_'..tostring(self:GetActivityId())..'_'..tostring(XPlayer.Id)
end
--endregion

--region 常驻活动相关

function XWheelchairManualModel:_InitWeekActivityViewModel()
    if self._ActivityDataList == nil then
        self._ActivityDataList = {}
    end

    -- <ActivityId, viewData>
    if self._ActivityDataMap == nil then
        self._ActivityDataMap = {}
    end
    
    if self._HasInitWeekActivityViewModel then
        return
    end

    self._HasInitWeekActivityViewModel = true
    
    local cfgs = self:GetWheelchairManualGuideWeekActivityCfgs()

    if not XTool.IsTableEmpty(cfgs) then
        ---@param v XTableWheelchairManualGuideWeekActivity
        for i, v in pairs(cfgs) do
            local viewData = self._ActivityDataMap[v.Id]

            if not viewData then
                local newViewData = XWheelchairManualGuideViewData.New()
                newViewData:InitConfig(v)
                newViewData:SetIsTimelimitActivity(false)
                self._ActivityDataMap[v.Id] = newViewData
                table.insert(self._ActivityDataList, newViewData)
            end
        end
    end
end

function XWheelchairManualModel:_UpdateGuideWeekActivityData(data)
    if not XTool.IsTableEmpty(data.UpdateWeekActivityInfos) then
        for i, v in pairs(data.UpdateWeekActivityInfos) do
            local viewData = self._ActivityDataMap[v.MainId]

            if viewData then
                viewData:InitData(v)
            end
        end
    end
end

-- 获取常驻活动的管理类
function XWheelchairManualModel:GetManagerByMainId(mainId)
    -- 判断特例
    if mainId == XEnumConst.WheelchairManual.WeekMainId.GuildBoss then
        -- 拟真围剿 特殊处理
        return self:GetCalendarShowGuildBossData()
    end
    
    -- 获取配置表
    ---@type XTableWheelchairManualGuideWeekActivity
    local weekActivityCfg = self:GetWheelchairManualGuideWeekActivityCfg(mainId)
    if weekActivityCfg then
        -- 根据章节类型获取管理器
        if XTool.IsNumberValid(weekActivityCfg.ChapterType) then
            return XDataCenter.FubenManagerEx.GetManager(weekActivityCfg.ChapterType)
        end
        -- 根据管理器名称获取管理器
        if not string.IsNilOrEmpty(weekActivityCfg.ManagerName) then
            if XDataCenter[weekActivityCfg.ManagerName] then
                return XDataCenter[weekActivityCfg.ManagerName]
            end

            if XMVCA[weekActivityCfg.ManagerName] then
                return XMVCA[weekActivityCfg.ManagerName]
            end
        end
    else
        XLog.Error('周常活动'..tostring(weekActivityCfg.Name)..'配置Id:'..tostring(mainId)..'找不到系统管理器')
    end
    XLog.Error('周常配置不存在，Id:'..tostring(mainId))
    return nil
end

-- 检查周常是否显示
function XWheelchairManualModel:CheckWeekIsShow(mainId)
    -- 是否有对应的数据
    if not self._ActivityDataMap[mainId] or not self._ActivityDataMap[mainId]:HasServerData() then
        return false
    end
    
    -- 活动系统是否开启显示
    local manager = self:GetManagerByMainId(mainId)
    if manager then
        if manager.ExCheckShowInCalendar then
            return manager:ExCheckShowInCalendar()
        else
            XLog.Error('周常配置Id:'..tostring(mainId)..'对应的系统管理器缺少 检查是否显示的接口：ExCheckShowInCalendar', 'ManagerName:'..tostring(manager.__cname))
        end
    end
    return false
end

-- 获取周常活动倒计时描述
function XWheelchairManualModel:GetWeekRemainingTimeDesc(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager then
        if manager.ExGetCalendarRemainingTime then
            return manager:ExGetCalendarRemainingTime()
        else
            if XMain.IsWindowsEditor then
                XLog.Warning('周常配置Id:'..tostring(mainId)..'对应的系统管理器缺少 获取周常活动倒计时描述的接口：ExGetCalendarRemainingTime')
            end
        end
    end
    return ""
end

-- 获取周常活动结束时间
function XWheelchairManualModel:GetWeekEndTime(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager then
        if manager.ExGetCalendarEndTime then
            return manager:ExGetCalendarEndTime()
        else
            if XMain.IsWindowsEditor then
                XLog.Warning('周常配置Id:'..tostring(mainId)..'对应的系统管理器缺少 获取周常活动结束时间的接口：ExGetCalendarEndTime')
            end
        end
    end
    return 0
end

-- 检查周常是否显示提示信息
function XWheelchairManualModel:CheckWeekIsShowTips(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager then
        if manager.ExCheckWeekIsShowTips then
            return manager:ExCheckWeekIsShowTips()
        end
    end
    return false
end

-- 获取周历需要的拟真围剿接口
function XWheelchairManualModel:GetCalendarShowGuildBossData()
    return {
        -- 获取倒计时
        ExGetCalendarRemainingTime = function()
            local endTime = self.CurrentGuildBossEndTime
            if not XTool.IsNumberValid(endTime) then
                return ""
            end
            local remainTime = endTime - XTime.GetServerNowTimestamp()
            if remainTime < 0 then
                remainTime = 0
            end
            local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)
            return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
        end,
        -- 获取解锁时间
        ExGetCalendarEndTime = function()
            return self.CurrentGuildBossEndTime or 0
        end,
        -- 是否在周历里显示
        ExCheckShowInCalendar = function()
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild, nil, true) then
                return false
            end

            if not XDataCenter.GuildManager.IsJoinGuild() then
                return false
            end

            local endTime = self.CurrentGuildBossEndTime
            if XTool.IsNumberValid(endTime) and (endTime - XTime.GetServerNowTimestamp()) > 0 then
                return true
            end
            return false
        end,
    }
end

--endregion

--region 界面数据

function XWheelchairManualModel:SetTabIndexCache(index)
    self._UiMainTabIndexCache = index
end

function XWheelchairManualModel:GetTabIndexCache()
    return self._UiMainTabIndexCache
end
--endregion

return XWheelchairManualModel