local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs

---@class XPassportControl : XControl
---@field private _Model XPassportModel
local XPassportControl = XClass(XControl, "XPassportControl")

function XPassportControl:OnInit()
    self._Model:Init()
end

function XPassportControl:AddAgencyEvent()
end

function XPassportControl:RemoveAgencyEvent()

end

function XPassportControl:OnRelease()
end

--region 原config
-----------------PassportActivity 活动相关 begin-----------------------
function XPassportControl:SetDefaultActivityId(activityId)
    self._Model:SetDefaultActivityId(activityId)
end

function XPassportControl:GetDefaultActivityId()
    return self._Model:GetDefaultActivityId()
end

function XPassportControl:GetPassportActivityTimeId()
    return self._Model:GetPassportActivityTimeId()
end

function XPassportControl:GetPassportDailyTaskGroup()
    local activityId = self:GetDefaultActivityId()
    local config = self._Model:GetPassportActivityConfig(activityId)
    return config.DailyTaskGroup
end

function XPassportControl:GetPassportWeekTaskGroup()
    local activityId = self:GetDefaultActivityId()
    local config = self._Model:GetPassportActivityConfig(activityId)
    return config.WeekTaskGroup
end

function XPassportControl:GetPassportBuyPassPortEarlyEndTime()
    local activityId = self:GetDefaultActivityId()
    local config = self._Model:GetPassportActivityConfig(activityId)
    return config.BuyPassPortEarlyEndTime
end

function XPassportControl:GetPassportBPTask()
    return self._Model:GetPassportBPTask()
end

function XPassportControl:GetPassportBPTaskTotalCount()
    local taskList = self:GetPassportBPTask()
    return #taskList
end
-----------------PassportActivity 活动相关 end-------------------------

-----------------PassportLevel 等级 begin-----------------------

function XPassportControl:GetPassportLevel(id)
    return self._Model:GetPassportLevel(id)
end

function XPassportControl:GetPassportLevelTotalExp(id)
    local config = self._Model:GetPassportLevelConfig(id)
    return config.TotalExp
end

function XPassportControl:GetPassportLevelCostItemId(id)
    local config = self._Model:GetPassportLevelConfig(id)
    return config.CostItemId
end

function XPassportControl:GetPassportLevelCostItemCount(id)
    local config = self._Model:GetPassportLevelConfig(id)
    return config.CostItemCount
end

function XPassportControl:GetPassportMaxLevel()
    local activityId = self._Model:GetDefaultActivityId()
    local levelIdList = self._Model:GetPassportLevelIdList(activityId)
    local maxLevel = 0
    local levelCfg
    for _, levelId in ipairs(levelIdList) do
        levelCfg = self:GetPassportLevel(levelId)
        if levelCfg > maxLevel then
            maxLevel = levelCfg
        end
    end
    return maxLevel
end

function XPassportControl:GetPassportLevelTotalExpByLevel(level)
    local id = self._Model:GetPassportLevelId(level)
    local config = self._Model:GetPassportLevelConfig(id)
    return config.TotalExp
end

function XPassportControl:IsPassportTargetLevel(id)
    return self._Model:IsPassportTargetLevel(id)
end

--返回下一个目标的等级
function XPassportControl:GetPassportTargetLevel(currLevel)
    local activityId = self._Model:GetDefaultActivityId()
    local levelIdList = self._Model:GetPassportLevelIdList(activityId)
    local lastLevelIdIndex = #levelIdList
    local levelCfg

    for i, levelId in ipairs(levelIdList) do
        levelCfg = self:GetPassportLevel(levelId)
        if (levelCfg >= currLevel or i == lastLevelIdIndex) and self._Model:IsPassportTargetLevel(levelId) then
            return levelCfg
        end
    end
end

function XPassportControl:GetBuyLevelCostItemId()
    local activityId = self._Model:GetDefaultActivityId()
    local levelIdList = self._Model:GetPassportLevelIdList(activityId)
    for _, levelId in ipairs(levelIdList) do
        return self:GetPassportLevelCostItemId(levelId)
    end
end
-----------------PassportLevel 等级 end-------------------------

-----------------PassportReward 奖励 begin-----------------------

function XPassportControl:GetPassportRewardPassportId(id)
    local config = self._Model:GetPassportRewardConfig(id)
    return config.PassportId
end

function XPassportControl:GetPassportRewardId(id)
    return self._Model:GetPassportRewardId(id)
end

function XPassportControl:GetPassportRewardData(passportRewardId)
    local rewardId = self:GetPassportRewardId(passportRewardId)
    local rewards = XTool.IsNumberValid(rewardId) and XRewardManager.GetRewardList(rewardId)
    return rewards and rewards[1]
end

--返回对应等级的已解锁的通行证奖励
function XPassportControl:GetUnLockPassportRewardIdListByLevel(level)
    local typeInfoIdList = self._Model:GetPassportActivityIdToTypeInfoIdList()
    local unLockPassportRewardIdList = {}
    local rewardId
    local passportRewardId

    for _, passportId in ipairs(typeInfoIdList) do
        if self:GetPassportInfos(passportId) then
            passportRewardId = self._Model:GetRewardIdByPassportIdAndLevel(passportId, level)
            rewardId = self:GetPassportRewardId(passportRewardId)
            if XTool.IsNumberValid(rewardId) then
                tableInsert(unLockPassportRewardIdList, passportRewardId)
            end
        end
    end
    return unLockPassportRewardIdList
end

function XPassportControl:IsPassportPrimeReward(id)
    local config = self._Model:GetPassportRewardConfig(id)
    return config.IsPrimeReward
end

function XPassportControl:GetPassportRewardLevel(id)
    return self._Model:GetPassportRewardLevel(id)
end

-----------------PassportReward 奖励 end-------------------------

-----------------PassportTypeInfo 通行证类型 begin-----------------------

function XPassportControl:GetPassportTypeInfoRewardId(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.RewardId
end

function XPassportControl:GetPassportTypeInfoName(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.Name or ""
end

function XPassportControl:GetPassportTypeInfoCostItemId(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.CostItemId
end

function XPassportControl:GetPassportTypeInfoCostItemCount(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.CostItemCount
end

function XPassportControl:GetPassportTypeInfoRewardId(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.RewardId
end

function XPassportControl:GetPassportTypeInfoBuyDesc(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.BuyDesc or ""
end

function XPassportControl:GetPassportTypeInfoIcon(id)
    local config = self._Model:GetPassportTypeInfoConfig(id)
    return config.Icon
end

-----------------PassportTypeInfo 通行证类型 end-------------------------

-----------------PassportTaskGroup 任务 begin--------------------------

function XPassportControl:GetPassportTaskGroupTimeId(id)
    local config = self._Model:GetPassportTaskGroupConfig(id)
    return config.TimeId
end

function XPassportControl:GetPassportTaskGroupTaskIdList(id)
    return self._Model:GetPassportTaskGroupTaskIdList(id)
end

function XPassportControl:GetPassportTaskGroupCurrOpenTaskIdList(type)
    return self._Model:GetPassportTaskGroupCurrOpenTaskIdList(type)
end

function XPassportControl:GetPassportTaskGroupIdByType(type)
    for _, v in pairs(self._Model:GetPassportTaskGroupConfigs()) do
        if v.Type == type and XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            return v.Id
        end
    end
end

--获得总周数和当前第几周
function XPassportControl:GetPassportWeeklyTaskGroupCountAndCurrWeekly()
    local nowServerTime = XTime.GetServerNowTimestamp()
    local weekTaskGroup = self:GetPassportWeekTaskGroup()
    local totalCount = 0
    local currWeekly = 0
    local startTime

    for _, v in pairs(self._Model:GetPassportTaskGroupConfigs()) do
        startTime = XFunctionManager.GetStartTimeByTimeId(v.TimeId)
        if v.Type == XEnumConst.PASSPORT.TASK_TYPE.WEEKLY and v.Group == weekTaskGroup then
            if nowServerTime >= startTime then
                currWeekly = currWeekly + 1
            end
            totalCount = totalCount + 1
        end
    end

    currWeekly = XTool.IsNumberValid(currWeekly) and currWeekly or 1    --默认第1周
    return totalCount, currWeekly
end

-----------------PassportTaskGroup 任务 end----------------------------

-----------------PassportBuyFashionShowConfig 购买通行证界面展示的时装相关 start----------------------------

function XPassportControl:GetPassportBuyFashionShowIcon(id)
    local config = self._Model:GetPassportBuyFashionShowConfig(id)
    return config.Icon
end

function XPassportControl:GetPassportBuyFashionShowFashionId(id)
    local config = self._Model:GetPassportBuyFashionShowConfig(id)
    return config.FashionId
end

function XPassportControl:IsPassportBuyFashionShowIsWeaponFahion(id)
    local config = self._Model:GetPassportBuyFashionShowConfig(id)
    return XTool.IsNumberValid(config.IsWeaponFahion) and true or false
end
-----------------PassportBuyFashionShowConfig 购买通行证界面展示的时装相关 end------------------------------

-----------------PassportBuyRewardShowConfig 购买通行证界面展示的道具相关 start----------------------------

function XPassportControl:GetPassportBuyRewardShowLevel(id)
    return self._Model:GetPassportBuyRewardShowLevel(id)
end

function XPassportControl:GetPassportBuyRewardShowCount(id)
    local config = self._Model:GetPassportBuyRewardShowConfig(id)
    return config.ShowCount
end

function XPassportControl:GetPassportBuyRewardShowRewardData(id, isNotCount)
    local config = self._Model:GetPassportBuyRewardShowConfig(id)
    local rewardId = config.RewardId
    local rewards = isNotCount and XRewardManager.GetRewardListNotCount(rewardId) or XRewardManager.GetRewardList(rewardId)
    return rewards and rewards[1]
end

function XPassportControl:GetBuyRewardShowIdList(passportId)
    return self._Model:GetBuyRewardShowIdList(passportId)
end
-----------------PassportBuyRewardShowConfig 购买通行证界面展示的道具相关 end------------------------------

----------------- 无限区奖励 start----------------------------

-- 最大可购买等级 ！= 最大等级
function XPassportControl:GetPassportMaxBuyableLevel()
    local activityId = self:GetDefaultActivityId()
    local levelIdList = self._Model:GetPassportLevelIdList(activityId)
    local maxLevel = 0
    for i = 1, #levelIdList do
        local id = levelIdList[i]
        if self:IsInfReward(id) then
            break
        end
        local level = self:GetPassportLevel(id)
        if level > maxLevel then
            maxLevel = level
        end
    end
    return maxLevel
end

function XPassportControl:GetPassportLevelIdListByRewardType(activityId, rewardType)
    local levelIdListSeparate = self._Model:GetLevelIdListSeparate()
    levelIdListSeparate[activityId] = levelIdListSeparate[activityId] or {}
    local result = levelIdListSeparate[activityId][rewardType]
    if result then
        return result
    end
    result = {}
    local levelIdList = self._Model:GetPassportLevelIdList(activityId)
    for i = 1, #levelIdList do
        local id = levelIdList[i]
        if rewardType == self:GetRewardType(id) then
            result[#result + 1] = id
        end
    end
    levelIdListSeparate[activityId][rewardType] = result
    return result
end

function XPassportControl:GetRewardType(id)
    return self:IsInfReward(id) and XEnumConst.PASSPORT.REWARD_TYPE.INFINITE or
            XEnumConst.PASSPORT.REWARD_TYPE.NORMAL
end

function XPassportControl:IsInfReward(id)
    local costItemId = self:GetPassportLevelCostItemId(id)
    return not costItemId or costItemId == 0
end

----------------- 无限区奖励 end------------------------------
--endregion 原config

--region 原manager
--获得玩家通行证信息
--id：通行证id
function XPassportControl:GetPassportInfos(passportId)
    return self._Model:GetPassportInfos(passportId)
end

--是否已领取奖励
function XPassportControl:IsReceiveReward(passportId, passportRewardId)
    return self._Model:IsReceiveReward(passportId, passportRewardId)
end

--是否可领取奖励
function XPassportControl:IsCanReceiveReward(passportId, passportRewardId)
    local passportInfo = self:GetPassportInfos(passportId)
    local isUnLock = passportInfo and true or false
    local baseInfo = self:GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    local levelCfg = self:GetPassportRewardLevel(passportRewardId)
    return currLevel >= levelCfg and isUnLock
end

function XPassportControl:GetPassportBaseInfo()
    return self._Model:GetBaseInfo()
end

function XPassportControl:GetPassportLastTimeBaseInfo()
    return self._Model:GetLastTimeBaseInfo()
end

---------------------红点 begin---------------------


---------------------红点 end-----------------------

---------------------活动入口 begin---------------------
--活动是否已结束
function XPassportControl:IsActivityClose()
    return self._Model:IsActivityClose()
end

--检查活动没开回主界面
function XPassportControl:CheckActivityIsOpen(isNotRunMain)
    return self._Model:CheckActivityIsOpen(isNotRunMain)
end

function XPassportControl:OpenMainUi()
    if not self:CheckActivityIsOpen(true) then
        return
    end
    XLuaUiManager.Open("UiPassport")
end
---------------------活动入口 end-----------------------

---------------------主界面 begin---------------------
function XPassportControl:CatchCurrMainViewSelectTagIndex(currSelectTagIndex)
    self._Model.CurrMainViewSelectTagIndex = currSelectTagIndex
end

function XPassportControl:GetCurrMainViewSelectTagIndex()
    return self._Model.CurrMainViewSelectTagIndex or 1
end
---------------------主界面 end-----------------------

---------------------任务 begin------------------
function XPassportControl:GetClearTaskCount(taskType)
    local taskIdList = taskType == XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY and self:GetPassportBPTask()
            or self:GetPassportTaskGroupCurrOpenTaskIdList(taskType)
    local clearTotalCount = 0
    for _, taskId in ipairs(taskIdList) do
        if XDataCenter.TaskManager.CheckTaskFinished(taskId) then
            clearTotalCount = clearTotalCount + 1
        end
    end
    return clearTotalCount
end

function XPassportControl:GetPassportTask(taskType)
    local taskIdList = taskType == XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY and self:GetPassportBPTask()
            or self:GetPassportTaskGroupCurrOpenTaskIdList(taskType)
    local taskList = {}
    local tastData
    for _, taskId in pairs(taskIdList) do
        tastData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if tastData then
            table.insert(taskList, tastData)
        end
    end

    local achieved = XDataCenter.TaskManager.TaskState.Achieved
    local finish = XDataCenter.TaskManager.TaskState.Finish
    table.sort(taskList, function(a, b)
        if a.State ~= b.State then
            if a.State == achieved then
                return true
            end
            if b.State == achieved then
                return false
            end
            if a.State == finish then
                return false
            end
            if b.State == finish then
                return true
            end
        end

        local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
        local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
        return templatesTaskA.Priority > templatesTaskB.Priority
    end)

    return taskList
end

--返回当前任务列表中已获得的经验，和能获得的总经验
function XPassportControl:GetPassportTaskExp(passportTaskGroupId)
    if not XTool.IsNumberValid(passportTaskGroupId) then
        return 0, 0
    end

    local taskIdList = self:GetPassportTaskGroupTaskIdList(passportTaskGroupId)
    local rewardId
    local totalExp = 0
    local currExp = 0
    local rewards
    local itemId = XDataCenter.ItemManager.ItemId.PassportExp
    local isTaskFinish

    for _, taskId in ipairs(taskIdList) do
        rewardId = XTaskConfig.GetTaskRewardId(taskId)
        rewards = XRewardManager.GetRewardList(rewardId)
        isTaskFinish = XDataCenter.TaskManager.CheckTaskFinished(taskId)
        for _, v in pairs(rewards) do
            if v.TemplateId == itemId then
                totalExp = totalExp + v.Count
                if isTaskFinish then
                    currExp = currExp + v.Count
                end
            end
        end
    end

    return currExp, totalExp
end

function XPassportControl:GetPassportAchievedTaskIdList(taskType)
    local taskIdList = taskType == XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY and self:GetPassportBPTask()
            or self:GetPassportTaskGroupCurrOpenTaskIdList(taskType)
    local achievedTaskIdList = {}
    local tastData
    for _, taskId in pairs(taskIdList) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            table.insert(achievedTaskIdList, taskId)
        end
    end
    return achievedTaskIdList
end
---------------------任务 end--------------------

---------------------奖励 begin-----------------------

function XPassportControl:ClearCookieAutoGetTaskRewardList()
    local key = self._Model:GetAutoGetTaskRewardListCookieKey()
    XSaveTool.RemoveData(key)
end

---------------------奖励 end-----------------------

---------------------protocol begin------------------

--购买通行证请求
function XPassportControl:RequestPassportBuyPassport(id, cb)
    XNetwork.Call("PassportBuyPassportRequest", { Id = id }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local name = self:GetPassportTypeInfoName(id)
        local msg = CS.XTextManager.GetText("SuccessfulItemPurchase", name)
        XUiManager.TipMsg(msg)

        if not XTool.IsTableEmpty(res.RewardList) then
            XUiManager.OpenUiObtain(res.RewardList)
        end
        self._Model:UpdatePassportInfosDic({ res.PassportInfo })

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_BUY_PASSPORT_COMPLEATE)
    end)
end

--购买通行证经验（等级）请求
function XPassportControl:RequestPassportBuyExp(toLevel, cb)
    XNetwork.Call("PassportBuyExpRequest", { ToLevel = toLevel }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XUiManager.TipText("PassportBuyExpCompleate")
        local baseInfo = self._Model:GetBaseInfo()
        baseInfo:SetToLevel(toLevel)

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_BUY_EXP_COMPLEATE)
    end)
end

--领取单个奖励请求
function XPassportControl:RequestPassportRecvReward(passportRewardId, cb)
    XNetwork.Call("PassportRecvRewardRequest", { Id = passportRewardId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local passportId = self:GetPassportRewardPassportId(passportRewardId)
        self._Model:SetPassportReceiveReward(passportId, passportRewardId)

        XUiManager.OpenUiObtain(res.RewardList or {})

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_BUY_RECV_REWARD_COMPLEATE)
    end)
end

--一键领取奖励请求
function XPassportControl:RequestPassportRecvAllReward(cb)
    XNetwork.Call("PassportRecvAllRewardRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(res.RewardList or {}, nil, nil, nil, horizontalNormalizedPosition)
        self._Model:UpdatePassportInfosDic(res.PassportInfos)

        if cb then
            cb()
        end

        XEventManager.DispatchEvent(XEventId.EVENT_BUY_RECV_ALL_REWARD_COMPLEATE)
    end)
end

--批量领取任务奖励
function XPassportControl:FinishMultiTaskRequest(taskType)
    self:FinishAllTaskRequest()
    -- local taskIds = self:GetPassportAchievedTaskIdList(taskType)
    -- if XTool.IsTableEmpty(taskIds) then
    --     return
    -- end

    -- XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
    --     local horizontalNormalizedPosition = 0
    --     XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
    -- end)
end

-- v1.29 【通行证】优化任务页签一键领取逻辑，改为点击后领取全部任务页签的奖励
function XPassportControl:FinishAllTaskRequest()
    local allTaskIds = {}
    for name, taskType in pairs(XEnumConst.PASSPORT.TASK_TYPE) do
        local taskIds = self:GetPassportAchievedTaskIdList(taskType)
        for i = 1, #taskIds do
            allTaskIds[#allTaskIds + 1] = taskIds[i]
        end
    end
    if XTool.IsTableEmpty(allTaskIds) then
        return
    end

    XDataCenter.TaskManager.FinishMultiTaskRequest(allTaskIds, function(rewardGoodsList)
        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
    end)
end
--endregion 原manager

function XPassportControl:GetCookieAutoGetTaskRewardList()
    return self._Model:GetCookieAutoGetTaskRewardList()
end

function XPassportControl:GetPassportLevelId(level)
    return self._Model:GetPassportLevelId(level)
end

function XPassportControl:GetPassportActivityIdToTypeInfoIdList()
    return self._Model:GetPassportActivityIdToTypeInfoIdList()
end

function XPassportControl:GetRewardIdByPassportIdAndLevel(passportId, level)
    return self._Model:GetRewardIdByPassportIdAndLevel(passportId, level)
end

function XPassportControl:CheckStopToBuyBeforeTheEnd()
    if not self:CheckActivityIsOpen() then
        return false
    end
    local time = self:GetPassportBuyPassPortEarlyEndTime()
    local timeId = self:GetPassportActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    endTime = endTime - time
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime > endTime then
        XUiManager.TipText("ActivityMainLineEnd")
        return false
    end
    return true
end 

return XPassportControl
