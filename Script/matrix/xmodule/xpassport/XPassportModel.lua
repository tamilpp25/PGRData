local XPassportBaseInfo = require("XEntity/XPassport/XPassportBaseInfo")
local XPassportInfo = require("XEntity/XPassport/XPassportInfo")

local tableInsert = table.insert
local tableSort = table.sort
local pairs = pairs

local TableKey = {
    PassportActivity = { CacheType = XConfigUtil.CacheType.Normal },
    PassportLevel = { CacheType = XConfigUtil.CacheType.Normal },
    PassportReward = { CacheType = XConfigUtil.CacheType.Normal },
    PassportTypeInfo = { CacheType = XConfigUtil.CacheType.Normal },
    PassportTaskGroup = { CacheType = XConfigUtil.CacheType.Normal },
    PassportBuyFashionShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "PassportId" },
    PassportBuyRewardShow = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XPassportModel : XModel
local XPassportModel = XClass(XModel, "XPassportModel")

function XPassportModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Passport", TableKey)

    self._PassportActivityIdToLevelIdList = nil
    self._PassportRewardIdDic = {}
    self._PassportActivityIdToTypeInfoIdList = nil
    self._PassportActivityAndLevelToLevelIdDic = nil
    self._PassportIdToPassportRewardIdList = nil
    self._PassportIdToBuyRewardShowIdList = nil
    self._LevelIdListSeparate = {}

    self._DefaultActivityId = 1

    ---@type XPassportBaseInfo
    self._BaseInfo = XPassportBaseInfo.New()            --基础信息
    ---@type XPassportInfo[]
    self._PassportInfosDic = {}                         --已解锁通行证字典
    ---@type XPassportBaseInfo[]
    self._LastTimeBaseInfo = XPassportBaseInfo.New()    --上一期活动基础信息
    self.CurrMainViewSelectTagIndex = nil              --缓存主界面选择的页签
end

function XPassportModel:Init()
    self:_InitPassportActivityId()
    --self:_InitPassportActivityIdToLevelIdList()
    self:_InitPassportRewardIdDic()
    --self:_InitPassportActivityAndLevelToLevelIdDic()
    --self:_InitPassportIdToBuyRewardShowIdList()
end

function XPassportModel:ClearPrivate()
    self._PassportRewardIdDic = {}
    self._PassportActivityAndLevelToLevelIdDic = nil
    self._PassportIdToBuyRewardShowIdList = nil
    self._LevelIdListSeparate = {}
end

function XPassportModel:ResetAll()
    self._PassportActivityIdToTypeInfoIdList = nil
    self._PassportIdToPassportRewardIdList = nil
    -- temp
    self._DefaultActivityId = 1
    self._BaseInfo = XPassportBaseInfo.New()
    self._PassportInfosDic = {}
    self._LastTimeBaseInfo = XPassportBaseInfo.New()
    self.CurrMainViewSelectTagIndex = nil
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

--region config start
function XPassportModel:_InitPassportActivityId()
    if self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportActivity, self._DefaultActivityId) then
        return
    end
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportActivity)
    for activityId, config in pairs(configs) do
        if XTool.IsNumberValid(config.TimeId) then
            self._DefaultActivityId = activityId
            break
        end
        self._DefaultActivityId = activityId
    end
end

function XPassportModel:_InitPassportActivityIdToLevelIdList()
    if not self._PassportActivityIdToLevelIdList then
        self._PassportActivityIdToLevelIdList = {}
        local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportLevel)
        for _, v in pairs(configs) do
            if not self._PassportActivityIdToLevelIdList[v.ActivityId] then
                self._PassportActivityIdToLevelIdList[v.ActivityId] = {}
            end
            tableInsert(self._PassportActivityIdToLevelIdList[v.ActivityId], v.Id)
        end

        local sortFunc = function(a, b)
            return a < b
        end
        for _, idList in pairs(self._PassportActivityIdToLevelIdList) do
            tableSort(idList, sortFunc)
        end
    end
end

function XPassportModel:_InitPassportRewardIdDic()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportReward)
    for _, v in pairs(configs) do
        if not self._PassportRewardIdDic[v.PassportId] then
            self._PassportRewardIdDic[v.PassportId] = {}
        end
        self._PassportRewardIdDic[v.PassportId][v.Level] = v.Id
    end
end

function XPassportModel:_InitPassportIdToPassportRewardIdList(passportId)
    self._PassportIdToPassportRewardIdList = self._PassportIdToPassportRewardIdList or {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportReward)
    for _, v in pairs(configs) do
        if passportId == v.PassportId then
            if not self._PassportIdToPassportRewardIdList[v.PassportId] then
                self._PassportIdToPassportRewardIdList[v.PassportId] = {}
            end
            tableInsert(self._PassportIdToPassportRewardIdList[v.PassportId], v.Id)
        end
    end

    local sortFunc = function(a, b)
        local levelA = self:GetPassportRewardLevel(a)
        local levelB = self:GetPassportRewardLevel(b)
        if levelA ~= levelB then
            return levelA < levelB
        end
        return a < b
    end
    local idList = self._PassportIdToPassportRewardIdList[passportId]
    if idList then
        tableSort(idList, sortFunc)
    end
end

function XPassportModel:_InitPassportActivityIdToTypeInfoIdList()
    self._PassportActivityIdToTypeInfoIdList = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportTypeInfo)
    for _, v in pairs(configs) do
        if not self._PassportActivityIdToTypeInfoIdList[v.ActivityId] then
            self._PassportActivityIdToTypeInfoIdList[v.ActivityId] = {}
        end
        tableInsert(self._PassportActivityIdToTypeInfoIdList[v.ActivityId], v.Id)
    end

    local sortFunc = function(a, b)
        return a < b
    end
    for _, idList in pairs(self._PassportActivityIdToTypeInfoIdList) do
        tableSort(idList, sortFunc)
    end
end

function XPassportModel:_InitPassportActivityAndLevelToLevelIdDic()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportLevel)
    self._PassportActivityAndLevelToLevelIdDic = {}
    for _, v in pairs(configs) do
        if not self._PassportActivityAndLevelToLevelIdDic[v.ActivityId] then
            self._PassportActivityAndLevelToLevelIdDic[v.ActivityId] = {}
        end
        self._PassportActivityAndLevelToLevelIdDic[v.ActivityId][v.Level] = v.Id
    end
end

function XPassportModel:_InitPassportIdToBuyRewardShowIdList()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportBuyRewardShow)
    self._PassportIdToBuyRewardShowIdList = {}
    for _, v in pairs(configs) do
        if not self._PassportIdToBuyRewardShowIdList[v.PassportId] then
            self._PassportIdToBuyRewardShowIdList[v.PassportId] = {}
        end
        if XTool.IsNumberValid(v.Id) then
            tableInsert(self._PassportIdToBuyRewardShowIdList[v.PassportId], v.Id)
        end
    end

    local sortFunc = function(a, b)
        local levelA = self:GetPassportBuyRewardShowLevel(a)
        local levelB = self:GetPassportBuyRewardShowLevel(b)
        if levelA ~= levelB then
            return levelA > levelB
        end
        return a < b
    end
    for _, idList in pairs(self._PassportIdToBuyRewardShowIdList) do
        tableSort(idList, sortFunc)
    end
end

function XPassportModel:GetDefaultActivityId()
    return self._DefaultActivityId
end

function XPassportModel:SetDefaultActivityId(value)
    self._DefaultActivityId = value
end

function XPassportModel:GetPassportActivityConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportActivity, id)
    return config
end
--endregion config

--region notify
function XPassportModel:NotifyPassportData(data)
    self:SetDefaultActivityId(data.ActivityId)
    self._BaseInfo:SetToLevel(data.Level or data.BaseInfo.Level)
    self._LastTimeBaseInfo:UpdateData(data.LastTimeBaseInfo)
    self:UpdatePassportInfosDic(data.PassportInfos)
    XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_PASSPORT_DATA)
end

function XPassportModel:NotifyPassportBaseInfo(data)
    self._BaseInfo:UpdateData(data.Level or data.BaseInfo.Level)
    XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO)
end

--endregion notify

---------------------本地接口 begin------------------
function XPassportModel:UpdatePassportInfosDic(passportInfos)
    ---@type XPassportInfo
    local passportInfo
    for _, data in pairs(passportInfos) do
        passportInfo = self._PassportInfosDic[data.Id]
        if not passportInfo then
            passportInfo = XPassportInfo.New()
            self._PassportInfosDic[data.Id] = passportInfo
        end
        passportInfo:UpdateData(data)
    end
end

function XPassportModel:SetPassportReceiveReward(passportId, passportRewardId)
    local passportInfo = self:GetPassportInfos(passportId)
    if passportInfo then
        passportInfo:SetReceiveReward(passportRewardId)
    end
end
---------------------本地接口 end------------------

function XPassportModel:GetPassportLevelConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportLevel, id)
    return config
end

function XPassportModel:GetPassportLevelIdList(activityId)
    self:_InitPassportActivityIdToLevelIdList()
    return self._PassportActivityIdToLevelIdList[activityId] or {}
end

function XPassportModel:GetPassportLevelId(level)
    local activityId = self:GetDefaultActivityId()
    if not self._PassportActivityAndLevelToLevelIdDic then
        self:_InitPassportActivityAndLevelToLevelIdDic()
    end
    return self._PassportActivityAndLevelToLevelIdDic[activityId] and self._PassportActivityAndLevelToLevelIdDic[activityId][level]
end

function XPassportModel:GetPassportRewardConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportReward, id)
    return config
end

function XPassportModel:GetPassportRewardIdList(passportId)
    if not self._PassportIdToPassportRewardIdList or not self._PassportIdToPassportRewardIdList[passportId] then
        self:_InitPassportIdToPassportRewardIdList(passportId)
    end
    if not self._PassportIdToPassportRewardIdList[passportId] then
        XLog.Error("[XPassportModel] GetPassportRewardIdList empty")
    end
    return self._PassportIdToPassportRewardIdList[passportId] or {}
end

--获得奖励表的id
function XPassportModel:GetRewardIdByPassportIdAndLevel(passportId, level)
    return self._PassportRewardIdDic[passportId] and self._PassportRewardIdDic[passportId][level]
end

function XPassportModel:GetPassportActivityIdToTypeInfoIdList()
    local activityId = self:GetDefaultActivityId()
    if not self._PassportActivityIdToTypeInfoIdList then
        self:_InitPassportActivityIdToTypeInfoIdList()
    end
    return self._PassportActivityIdToTypeInfoIdList[activityId]
end

function XPassportModel:GetPassportTypeInfoConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportTypeInfo, id)
    return config
end

function XPassportModel:GetPassportTaskGroupConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportTaskGroup, id)
    return config
end

function XPassportModel:GetPassportTaskGroupConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PassportTaskGroup)
    return configs
end

function XPassportModel:GetPassportBuyFashionShowConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportBuyFashionShow, id)
    return config
end

function XPassportModel:GetPassportBuyRewardShowConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PassportBuyRewardShow, id)
    return config
end

function XPassportModel:GetBuyRewardShowIdList(passportId)
    if not self._PassportIdToBuyRewardShowIdList then
        self:_InitPassportIdToBuyRewardShowIdList()
    end
    return self._PassportIdToBuyRewardShowIdList[passportId] or {}
end

function XPassportModel:GetLevelIdListSeparate()
    return self._LevelIdListSeparate
end

function XPassportModel:GetPassportInfos(passportId)
    return self._PassportInfosDic[passportId]
end

function XPassportModel:GetBaseInfo()
    return self._BaseInfo
end

function XPassportModel:GetLastTimeBaseInfo()
    return self._LastTimeBaseInfo
end

function XPassportModel:GetAutoGetTaskRewardListCookieKey()
    local activityId = self:GetDefaultActivityId()
    return XPlayer.Id .. "_XPassport_AutoGetTaskRewardList" .. activityId
end

function XPassportModel:InsertCookieAutoGetTaskRewardList(rewardList)
    local key = self:GetAutoGetTaskRewardListCookieKey()
    local cookieRewardList = self:GetCookieAutoGetTaskRewardList()
    if cookieRewardList then
        for _, rewardData in ipairs(rewardList) do
            table.insert(cookieRewardList, rewardData)
        end
    end
    XSaveTool.SaveData(key, cookieRewardList or rewardList)
end

function XPassportModel:GetCookieAutoGetTaskRewardList()
    local key = self:GetAutoGetTaskRewardListCookieKey()
    return XSaveTool.GetData(key)
end

--通知自动领取任务奖励列表
function XPassportModel:NotifyPassportAutoGetTaskReward(data)
    self:InsertCookieAutoGetTaskRewardList(data.RewardList or {})
    XEventManager.DispatchEvent(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST)
end

--检查活动没开回主界面
function XPassportModel:CheckActivityIsOpen(isNotRunMain)
    local timeId = self:GetPassportActivityTimeId()
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return false
        end

        XUiManager.TipText("ActivityMainLineEnd")
        if not isNotRunMain then
            XLuaUiManager.RunMain()
        end
        return false
    end
    return true
end

function XPassportModel:GetPassportActivityTimeId()
    local activityId = self:GetDefaultActivityId()
    local config = self:GetPassportActivityConfig(activityId)
    return config.TimeId
end

function XPassportModel:GetPassportMaxLevel()
    local activityId = self:GetDefaultActivityId()
    local levelIdList = self:GetPassportLevelIdList(activityId)
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

function XPassportModel:GetPassportLevel(id)
    local config = self:GetPassportLevelConfig(id)
    return config.Level
end

--活动是否已结束
function XPassportModel:IsActivityClose()
    local nowServerTime = XTime.GetServerNowTimestamp()
    local timeId = self:GetPassportActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    return nowServerTime >= endTime
end

function XPassportModel:CheckPassportAchievedTaskRedPoint(taskType)
    local taskIdList = taskType == XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY and self:GetPassportBPTask()
            or self:GetPassportTaskGroupCurrOpenTaskIdList(taskType)
    for _, taskId in pairs(taskIdList) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end

function XPassportModel:GetPassportBPTask()
    local activityId = self:GetDefaultActivityId()
    local config = self:GetPassportActivityConfig(activityId)
    return config and config.BPTask or {}
end

function XPassportModel:GetPassportTaskGroupCurrOpenTaskIdList(type)
    for _, v in pairs(self:GetPassportTaskGroupConfigs()) do
        if v.Type == type and XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            return self:GetPassportTaskGroupTaskIdList(v.Id)
        end
    end
    return {}
end

function XPassportModel:GetPassportTaskGroupTaskIdList(id)
    local config = self:GetPassportTaskGroupConfig(id)
    return config.TaskId
end

--通行证检查是否可领取等级奖励
function XPassportModel:CheckPassportRewardRedPoint()
    local baseInfo = self._BaseInfo
    local currLevel = baseInfo:GetLevel()
    local typeInfoIdList = self:GetPassportActivityIdToTypeInfoIdList()
    local passportRewardIdList
    local levelCfg

    for _, passportId in ipairs(typeInfoIdList) do
        if self:GetPassportInfos(passportId) then
            passportRewardIdList = self:GetPassportRewardIdList(passportId)
            for _, passportRewardId in ipairs(passportRewardIdList) do
                levelCfg = self:GetPassportRewardLevel(passportRewardId)
                if currLevel < levelCfg then
                    break
                end
                if not self:IsReceiveReward(passportId, passportRewardId) then
                    return true
                end
            end
        end
    end
    return false
end

function XPassportModel:GetPassportRewardLevel(id)
    local config = self:GetPassportRewardConfig(id)
    return config.Level
end

--是否已领取奖励
function XPassportModel:IsReceiveReward(passportId, passportRewardId)
    local rewardId = self:GetPassportRewardId(passportRewardId)
    if not XTool.IsNumberValid(rewardId) then
        --没配置奖励作已领取处理
        return true
    end

    local passportInfo = self:GetPassportInfos(passportId)
    return passportInfo and passportInfo:IsReceiveReward(passportRewardId)
end

function XPassportModel:GetPassportRewardId(id)
    local config = self:GetPassportRewardConfig(id)
    return config.RewardId
end

function XPassportModel:GetPassportBuyRewardShowLevel(id)
    local config = self:GetPassportBuyRewardShowConfig(id)
    return config.Level
end

function XPassportModel:IsPassportTargetLevel(id)
    local config = self:GetPassportLevelConfig(id)
    return XTool.IsNumberValid(config.IsTargetLevel)
end

return XPassportModel