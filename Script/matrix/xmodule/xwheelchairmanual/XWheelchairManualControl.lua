---@class XWheelchairManualControl : XControl
---@field private _Model XWheelchairManualModel
local XWheelchairManualControl = XClass(XControl, "XWheelchairManualControl")
function XWheelchairManualControl:OnInit()
    --初始化内部变量
    
    -- 因为活动结束发生在领取奖励的时候，并且除了独立界面外，在公告活动界面内也有
    -- 需要考虑界面状态较多，暂时不实时踢出界面
    --self:StartTickOutCheckTimer()
    
    -- 检查Lotto是否解锁
    XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Lotto, true, true)
end

function XWheelchairManualControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XWheelchairManualControl:RemoveAgencyEvent()

end

function XWheelchairManualControl:OnRelease()
    --self:StopTickOutCheckTimer()
end

--region ActivityData
function XWheelchairManualControl:GetCurActivityId()
    return self._Model:GetActivityId()    
end

function XWheelchairManualControl:CheckPlanIsGetReward(planId)
    return self._Model:CheckPlanIsGetReward(planId)
end

function XWheelchairManualControl:GetBpLevel()
    return self._Model:GetBpLevel()
end

function XWheelchairManualControl:CheckAnyPlanCanGetReward()
    local planIds = self:GetCurActivityPlanIds()

    if not XTool.IsTableEmpty(planIds) then
        for i, v in pairs(planIds) do
            if self:CheckPlanIsCanReward(v) and not self:CheckPlanIsGetReward(v) then
                return true
            end
        end
    end
    
    return false
end

function XWheelchairManualControl:CheckPlanIsCanReward(planId)
    local curCount, allCount = XMVCA.XWheelchairManual:GetPlanProcess(planId)
    return curCount == allCount
end

function XWheelchairManualControl:CheckManualRewardIsGet(id)
    return self._Model:CheckManualRewardIsGet(id)
end

function XWheelchairManualControl:GetIsSeniorManualUnLock()
    return self._Model:GetIsSeniorManualUnLock()
end

---@return boolean, table<number> @是否有可完成的任务，可完成的任务Id列表
function XWheelchairManualControl:CheckPlanAnyTaskCanFinish()
    --只检查到当前阶段为止的任务
    local planIndex = self:GetCurActivityCurrentPlanIndex()
    local planIds = self:GetCurActivityPlanIds()

    if XTool.IsNumberValid(planIndex) and not XTool.IsTableEmpty(planIds) then
        local finishableTaskIds = {}
        for i = planIndex, 1, -1 do
            local planId = planIds[i]

            if XTool.IsNumberValid(planId) then
                local taskIds = self:GetManualPlanRewardTaskIds(planId)

                if not XTool.IsTableEmpty(taskIds) then
                    for k, v in pairs(taskIds) do
                        if XDataCenter.TaskManager.CheckTaskAchieved(v) then
                            table.insert(finishableTaskIds, v)    
                        end
                    end
                end
            end
        end
        
        return #finishableTaskIds > 0, finishableTaskIds
    end
    
    return false
end

---@return boolean, number @是否有这样的阶段， 阶段索引
function XWheelchairManualControl:GetMaxPlanWithFinishableTask()
    --只检查到当前阶段为止的任务
    local planIndex = self:GetCurActivityCurrentPlanIndex()
    local planIds = self:GetCurActivityPlanIds()

    if XTool.IsNumberValid(planIndex) and not XTool.IsTableEmpty(planIds) then
        for i = planIndex, 1, -1 do
            local planId = planIds[i]

            if XTool.IsNumberValid(planId) then
                local taskIds = self:GetManualPlanRewardTaskIds(planId)

                if not XTool.IsTableEmpty(taskIds) then
                    for k, v in pairs(taskIds) do
                        if XDataCenter.TaskManager.CheckTaskAchieved(v) then
                            return true, i
                        end
                    end
                end
            end
        end
    end

    return false
end

function XWheelchairManualControl:GetCurActivityGuideActivityList()
    local list = self._Model:GetActivityDataList()
    
    if XTool.IsTableEmpty(list) then
        return
    end
    
    -- 需要筛选出开放的活动
    local openedActivityList = {}
    ---@param v XWheelchairManualGuideViewData
    for i, v in pairs(list) do
        if v:IsTimelimitActivity() then
            if v:GetTimelimitActivityIsOpen() then
                table.insert(openedActivityList, v)
            end
        else
            if self._Model:CheckWeekIsShow(v:GetMainId()) then
                table.insert(openedActivityList, v)
            end
        end
    end
    
    -- 排序
    ---@param a XWheelchairManualGuideViewData
    ---@param b XWheelchairManualGuideViewData
    table.sort(openedActivityList, function(a, b)
        -- 未完成的在完成的前面
        local isFinishA = self:CheckGuideActivityIsFinishedByData(a)
        local isFinishB = self:CheckGuideActivityIsFinishedByData(b)

        if isFinishA ~= isFinishB then
            return not isFinishA and true or false
        end
        
        -- 序号大的在前面
        local sortA = a:GetSort()
        local sortB = b:GetSort()
        
        return sortA > sortB
    end)
    
    return openedActivityList
end

---@param viewData XWheelchairManualGuideViewData
function XWheelchairManualControl:CheckGuideActivityIsFinishedByData(viewData)
    if viewData:IsTimelimitActivity() then
        -- 获取当前活动的期数
        local periodId = self:GetTimelimitActivityCurPeriodId(viewData)

        if XTool.IsNumberValid(periodId) then
            local templateIds, templateCounts = self:GetPeriodTemplatesAndCount(periodId)

            if not XTool.IsTableEmpty(templateIds) and not XTool.IsTableEmpty(templateCounts) then
                local templateCountMap = viewData:GetReceiveTemplateCounts(periodId)

                if XTool.IsTableEmpty(templateCountMap) then
                    return false
                end
                
                for i, v in pairs(templateIds) do
                    if not XTool.IsNumberValid(templateCountMap[v]) or templateCountMap[v] < templateCounts[i] then
                        return false
                    end
                end
                return true
            end
        end
    else
        local templateIds, templateCounts = self:GetWeekActivityTemplatesAndCount(viewData)

        if not XTool.IsTableEmpty(templateIds) and not XTool.IsTableEmpty(templateCounts) then
            local templateCountMap = viewData:GetWeekActivityReceiveTemplateCounts()

            if XTool.IsTableEmpty(templateCountMap) then
                return false
            end

            for i, v in pairs(templateIds) do
                -- 如果存在配置填的上限是0，那么表示没有上限，则不可能完成
                if not XTool.IsNumberValid(templateCounts[i]) then
                    return false
                end
                if not XTool.IsNumberValid(templateCountMap[v]) or templateCountMap[v] < templateCounts[i] then
                    return false
                end
            end
            return true
        end
    end
    
    return false
end

---@param viewData XWheelchairManualGuideViewData
function XWheelchairManualControl:GetTimelimitActivityCurPeriodId(viewData)
    local periodIds = viewData:GetPeriodIds()

    if not XTool.IsTableEmpty(periodIds) then
        -- 查找最近的正在开始的期数
        for i, v in pairs(periodIds) do
            local periodCfg = self._Model:GetWheelchairManualGuideActivityPeriodCfg(v)

            if periodCfg and XFunctionManager.CheckInTimeByTimeId(periodCfg.TimeId) then
                return v
            end
        end
    end
    
    return 0
end

---@param viewData XWheelchairManualGuideViewData
function XWheelchairManualControl:GetWeekActivityTemplatesAndCount(viewData)
    local rewardCfgId = viewData:GetMainId() * 100 + viewData:GetSubId()
    
    local cfg = self._Model:GetWheelchairManualGuideWeekRewardCfg(rewardCfgId)

    if cfg then
        return cfg.MainTemplateId, cfg.MainTemplateCount
    else
        XLog.Error('活动找不到对应的奖励显示配置,请检查是否是配置表配置错误，或下发数据存在异常 mainId:'..tostring(viewData:GetMainId())..' subId:'..tostring(viewData:GetSubId()))
    end
end

function XWheelchairManualControl:GetWeekRemainingTimeDesc(mainId)
    return self._Model:GetWeekRemainingTimeDesc(mainId)
end

-- 检查周常是否显示领取的数量
function XWheelchairManualControl:CheckWeekIsShowReceiveCount(mainId)
    local refreshTime = self:GetGuideWeekActivityRefreshTime(mainId)
    if not string.IsNilOrEmpty(refreshTime) then
        local now = XTime.GetServerNowTimestamp()
        local refreshTimestamp = XTime.ParseToTimestamp(refreshTime)
        -- 刷新时间未到
        if XTool.IsNumberValid(refreshTimestamp) and now <= refreshTimestamp then
            return false
        end
    end
    return true
end

-- 检查周常是否显示提示信息
function XWheelchairManualControl:CheckWeekIsShowTips(mainId)
    return self._Model:CheckWeekIsShowTips(mainId)
end
--endregion

--region ActivityData-Configs

-- Activity

function XWheelchairManualControl:GetCurActivityPlanIds()
    return self._Model:GetCurActivityPlanIds()
end

function XWheelchairManualControl:GetCurActivityPlanCount()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return #cfg.PlanIds
        end
    end
end

function XWheelchairManualControl:GetCurActivityCurrentPlanId()
    return self._Model:GetPlanId()
end

function XWheelchairManualControl:GetCurActivityCurrentPlanIndex()
    local planId = self:GetCurActivityCurrentPlanId()

    if XTool.IsNumberValid(planId) then
        local planIds = self:GetCurActivityPlanIds()

        if not XTool.IsTableEmpty(planIds) then
            for i, v in pairs(planIds) do
                if planId == v then
                    return i
                end
            end
        end
    end
end

--- 获取最低可领取奖励的阶段索引
function XWheelchairManualControl:GetCurActivityMinPlanCanGetIndex()
    local planIds = self:GetCurActivityPlanIds()

    if not XTool.IsTableEmpty(planIds) then
        for i, v in ipairs(planIds) do
            if XMVCA.XWheelchairManual:CheckPlanCanGetReward(v) then
                return i
            end
        end
    end
end

function XWheelchairManualControl:GetCurActivityPlanIdByIndex(index)
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.PlanIds[index]
        end
    end
end

function XWheelchairManualControl:GetCurActivityTeachCommonStageIds()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.TeachCommonStageIds
        end
    end
end

function XWheelchairManualControl:GetCurActivityTeachConnectivityStageId()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.TeachConnectivityStageId
        end
    end
end

function XWheelchairManualControl:GetCurActivityTeachTaskIds()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            return cfg.TeachTaskIds
        end
    end
end

--- 判断当期活动BP等级是否到达最大，即BP等级数据 >= 配置BpLevelConfig[2] - BpLevelConfig[1]之差
function XWheelchairManualControl:CheckCurActivityBpLevelIsMax()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)
        if cfg then
            local levelMax = cfg.BpLevelConfig[2] - cfg.BpLevelConfig[1]
            local curLevel = self:GetBpLevel()
            
            return curLevel >= levelMax
        end
    end
    
    return false
end

-- ActivityShow

function XWheelchairManualControl:GetCurActivityPurchaseUiType()
    return self._Model:GetCurActivityPurchaseUiType()
end

function XWheelchairManualControl:GetCurActivityShowPurchaseIds()
    return self._Model:GetCurActivityShowPurchaseIds()
end


function XWheelchairManualControl:GetCurActivityLottoId()
    return self._Model:GetCurActivityLottoId()
end

function XWheelchairManualControl:GetCurActivityTeachingShowRewardId()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityShowCfg(activityId)
        if cfg then
            return cfg.TeachingShowRewardId
        end
    end
end
-- Plan

---@return XTableWheelchairManualCharacterPlan
function XWheelchairManualControl:GetCurActivityCharacterPlanCfg()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
       local cfg = self._Model:GetWheelchairManualCharacterPlanCfg(activityId)
        return cfg
    end
end

function XWheelchairManualControl:GetCurBPLevelNeedExp()
    local activityId = self._Model:GetActivityId()
    local bpLevel = self._Model:GetBpLevel()

    if XTool.IsNumberValid(activityId) and XTool.IsNumberValid(bpLevel) then
        local cfg = self._Model:GetWheelchairManualBattlePassLevelCfg(activityId * 1000 + bpLevel)
        if cfg then
            return cfg.NeedExp
        end
    end
    
    return 0
end

--获取距离最近的下一个特殊奖励
function XWheelchairManualControl:GetCurActivityNextSpecialLevel(curLevel)
    local activityId = self._Model:GetActivityId()
    local levelMax = self:GetActivityLevelMax(activityId)
    
    -- 从前往后找
    if XTool.IsNumberValid(levelMax) then
        for i = curLevel, levelMax do
            local id = activityId * 1000 + i
            local levelCfg = self._Model:GetWheelchairManualBattlePassLevelCfg(id)

            if levelCfg then
                if levelCfg.IsSpecial then
                    return levelCfg.Level
                end
            end
        end
    end
end

function XWheelchairManualControl:GetCurActivityCommanManualId()
    return self._Model:GetCurActivityCommanManualId()
end

function XWheelchairManualControl:GetCurActivitySeniorManualId()
    return self._Model:GetCurActivitySeniorManualId()
end

function XWheelchairManualControl:GetCurActivityCommanManualRewardCfgIds()
    return self._Model:GetCurActivityCommanManualRewardCfgIds()
end

function XWheelchairManualControl:GetCurActivitySeniorManualRewardCfgIds()
    return self._Model:GetCurActivitySeniorManualRewardCfgIds()
end

-- WheelchairManualPassportScrollCards

function XWheelchairManualControl:GetCurActivityScrollCardSwitchInterval()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualPassportScrollCardsCfg(activityId)

        if cfg then
            return cfg.SwitchInterval
        end
    end
    
    return XScheduleManager.SECOND
end

function XWheelchairManualControl:GetCurActivityScrollCardImages()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualPassportScrollCardsCfg(activityId)

        if cfg then
            return cfg.Images
        end
    end
end


function XWheelchairManualControl:GetCurActivityScrollCardBannerLabels()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualPassportScrollCardsCfg(activityId)

        if cfg then
            return cfg.BannerLabels
        end
    end
end

function XWheelchairManualControl:GetCurActivityScrollCardSkipIds()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualPassportScrollCardsCfg(activityId)

        if cfg then
            return cfg.ImgSkips
        end
    end
end

-- PassportCardPrefab
function XWheelchairManualControl:GetCurActivityPassportCardPrefabAddress()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local prefabCfg = self._Model:GetWheelchairManualPassportPrefabCfg(activityId)

        if prefabCfg then
            return prefabCfg.PrefabAddress
        end
    end
end

function XWheelchairManualControl:GetCurActivityPassportCardPrefabCfg()
    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local prefabCfg = self._Model:GetWheelchairManualPassportPrefabCfg(activityId)

        return prefabCfg
    end
end

-- GuideActivity
function XWheelchairManualControl:GetGuideActivitySortByData(data)
    if XTool.IsNumberValid(data.ActivityId) then
        local activityCfg = self._Model:GetWheelchairManualGuideActivityCfg(data.ActivityId)
        if activityCfg then
            return activityCfg.Sort
        end
    else
        
    end
    
    return 0
end

-- GuideWeekActivity
function XWheelchairManualControl:GetGuideWeekActivityRefreshTime(mainId)
    local config = self._Model:GetWheelchairManualGuideWeekActivityCfg(mainId)
    return config and config.RefreshTime or ""
end
--endregion

--region Configs

-- Activity

function XWheelchairManualControl:GetActivityLevelMax(activityId)
    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetWheelchairManualActivityCfg(activityId)

        if cfg then
            return cfg.BpLevelConfig[2]
        end
    end
    
    return 0
end

-- Tabs
function XWheelchairManualControl:GetManualTabMainTitle(tabId)
    local cfg = self._Model:GetWheelchairManualTabsCfg(tabId)
    if cfg then
        return cfg.MainTitle
    end
end

function XWheelchairManualControl:GetManualTabSecondTitle(tabId)
    local cfg = self._Model:GetWheelchairManualTabsCfg(tabId)
    if cfg then
        return cfg.SecondTitle
    end
end

function XWheelchairManualControl:GetManualTabCondition(tabId)
    local cfg = self._Model:GetWheelchairManualTabsCfg(tabId)
    if cfg then
        return cfg.Condition
    end
end

function XWheelchairManualControl:GetManualTabImage(tabId)
    local cfg = self._Model:GetWheelchairManualTabsCfg(tabId)
    if cfg then
        return cfg.Image
    end
    return ''
end

-- Plans
function XWheelchairManualControl:GetManualPlanIsSpecial(planId)
    local cfg = self._Model:GetWheelchairManualPlanCfg(planId)
    if cfg then
        return cfg.IsSpecial
    end
end

function XWheelchairManualControl:GetManualPlanRewardId(planId)
    local cfg = self._Model:GetWheelchairManualPlanCfg(planId)
    if cfg then
        return cfg.RewardId
    end
end

function XWheelchairManualControl:GetManualPlanRewardHighlightList(planId)
    local cfg = self._Model:GetWheelchairManualPlanCfg(planId)
    if cfg then
        return cfg.IsDisplays
    end
end

function XWheelchairManualControl:GetManualPlanName(planId)
    local cfg = self._Model:GetWheelchairManualPlanCfg(planId)
    if cfg then
        return cfg.Name
    end
	return ''
end

function XWheelchairManualControl:GetManualPlanTitleIcon(planId)
    local cfg = self._Model:GetWheelchairManualPlanCfg(planId)
    if cfg then
        return cfg.TitleIcon
    end
    return ''
end

function XWheelchairManualControl:GetManualPlanRewardTaskIds(planId)
    return self._Model:GetManualPlanRewardTaskIds(planId)
end

-- Level

function XWheelchairManualControl:GetManualBPLevelByLevelId(id)
    if XTool.IsNumberValid(id) then
        local cfg = self._Model:GetWheelchairManualBattlePassLevelCfg(id)

        if cfg then
            return cfg.Level
        end
    end

    return 0
end

-- Reward
function XWheelchairManualControl:GetBPRewardIdById(id)
    if XTool.IsNumberValid(id) then
        local cfg = self._Model:GetWheelchairManualBattlePassRewardCfg(id)

        if cfg then
            return cfg.RewardId
        end
    end
end

function XWheelchairManualControl:GetBPIsDisplaysById(id)
    if XTool.IsNumberValid(id) then
        local cfg = self._Model:GetWheelchairManualBattlePassRewardCfg(id)

        if cfg then
            return cfg.IsDisplays
        end
    end
end

-- Manual
function XWheelchairManualControl:GetManualName(manualId)
    if XTool.IsNumberValid(manualId) then
        local cfg = self._Model:GetWheelchairManualBattlePassManualCfg(manualId)

        if cfg then
            return cfg.Name
        end
    end
    
    return ''
end

function XWheelchairManualControl:GetManualUnLockRewardId(manualId)
    if XTool.IsNumberValid(manualId) then
        local cfg = self._Model:GetWheelchairManualBattlePassManualCfg(manualId)

        if cfg then
            return cfg.RewardId
        end
    end

    return 0
end

function XWheelchairManualControl:GetManualPreviewRewardId(manualId)
    if XTool.IsNumberValid(manualId) then
        local cfg = self._Model:GetWheelchairManualBattlePassManualCfg(manualId)

        if cfg then
            return cfg.PreviewRewardId
        end
    end

    return 0
end

function XWheelchairManualControl:GetManualConsumeItemId(manualId)
    if XTool.IsNumberValid(manualId) then
        local cfg = self._Model:GetWheelchairManualBattlePassManualCfg(manualId)

        if cfg then
            return cfg.ConsumeItemId
        end
    end

    return 0
end

function XWheelchairManualControl:GetManualConsumeItemCount(manualId)
    if XTool.IsNumberValid(manualId) then
        local cfg = self._Model:GetWheelchairManualBattlePassManualCfg(manualId)

        if cfg then
            return cfg.ConsumeItemCount
        end
    end

    return 0
end

function XWheelchairManualControl:GetManualDesc(manualId)
    if XTool.IsNumberValid(manualId) then
        local cfg = self._Model:GetWheelchairManualBattlePassManualCfg(manualId)

        if cfg then
            return cfg.Desc
        end
    end

    return 0
end

--- Guide
function XWheelchairManualControl:GetManualGuideActivityCfg(id)
    return self._Model:GetWheelchairManualGuideActivityCfg(id)
end

--- GuideKind
function XWheelchairManualControl:GetWheelchairManualGuideKindCfg(id)
    return self._Model:GetWheelchairManualGuideKindCfg(id)
end

--- GuidePeriod
function XWheelchairManualControl:GetPeriodTemplatesAndCount(id)
    local periodCfg = self._Model:GetWheelchairManualGuideActivityPeriodCfg(id)

    if periodCfg then
        return periodCfg.MainTemplateIds, periodCfg.MainTemplateCounts
    end
end

--- ClientConfig

function XWheelchairManualControl:GetWheelchairManualConfigNumArray(key)
    return self._Model:GetWheelchairManualConfigNumArray(key)
end

--endregion

--region 活动关闭踢出
function XWheelchairManualControl:StartTickOutCheckTimer()
    self:StopTickOutCheckTimer()
    if not self:TickOutCheck() then
        self._TickOutCheckTimeId = XScheduleManager.ScheduleForever(handler(self, self.TickOutCheck), XScheduleManager.SECOND)
    end
end

function XWheelchairManualControl:StopTickOutCheckTimer()
    if self._TickOutCheckTimeId then
        XScheduleManager.UnSchedule(self._TickOutCheckTimeId)
        self._TickOutCheckTimeId = nil
    end
end

function XWheelchairManualControl:TickOutCheck()
    if XMVCA.XWheelchairManual:GetIsOpen() then
        return false
    end

    self:StopTickOutCheckTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipText('ActivityMainLineEnd')    
    return true
end

--endregion

--region 界面数据

function XWheelchairManualControl:SetTabIndexCache(index)
    self._Model:SetTabIndexCache(index)
end

function XWheelchairManualControl:GetTabIndexCache()
    return self._Model:GetTabIndexCache()
end

--- 展示奖励的接口，会筛选出成员和武器使用单独的界面进行展示，之后再弹窗显示汇总的奖励
function XWheelchairManualControl:ShowRewardList(rewardList)
    -- 如果有武器和角色，需要单独弹窗
    if not XTool.IsTableEmpty(rewardList) then
        local weaponAndCharacterList = {}
        for i, v in pairs(rewardList) do
            if v.RewardType == XRewardManager.XRewardType.Character or v.RewardType == XRewardManager.XRewardType.Equip then
                v.Id = 0
                table.insert(weaponAndCharacterList, v)
            else
                -- 成员可能转化成碎片了
                if XTool.IsNumberValid(v.ConvertFrom) then
                    if XTypeManager.GetTypeById(v.ConvertFrom) == XRewardManager.XRewardType.Character then
                        table.insert(weaponAndCharacterList, v)
                    end
                end
            end
        end

        -- 先显示角色，再显示武器
        table.sort(weaponAndCharacterList, function(a, b)
            if a.RewardType == XRewardManager.XRewardType.Character then
                return true
            else
                return false
            end
        end)

        if not XTool.IsTableEmpty(weaponAndCharacterList) then
            -- 先展示成员、武器，最后再弹窗汇总
            XLuaUiManager.Open("UiWheelchairManualDrawShowNew", nil, weaponAndCharacterList, nil, 1, function()
                XUiManager.OpenUiObtain(rewardList, nil, nil, nil)
                -- 领完奖要刷新下页签红点
                XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
            end, true)
        else
            XUiManager.OpenUiObtain(rewardList, nil, nil, nil)
            -- 领完奖要刷新下页签红点
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
        end
    else
        -- 领完奖要刷新下页签红点
        XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
        XLog.Error('服务端返回的奖励列表rewardList为空')
    end
end
--endregion

return XWheelchairManualControl