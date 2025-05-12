local XTransfiniteStage = require("XEntity/XTransfinite/XTransfiniteStage")
local XTransfiniteEvent = require("XEntity/XTransfinite/XTransfiniteEvent")
local XTransfiniteTeam = require("XEntity/XTransfinite/XTransfiniteTeam")

---@class XTransfiniteStageGroup
local XTransfiniteStageGroup = XClass(nil, "XTransfiniteStageGroup")

local Pairs = pairs

function XTransfiniteStageGroup:Ctor(id)
    self._Id = id

    ---@type XTransfiniteStage[]
    self._StageList = false

    ---@type XTransfiniteStage[]
    self._StageDict = false

    ---@type XTransfiniteEvent
    self._Event = false

    self._IsBegin = false
    self._IsClear = false
    self._IsIsland = nil

    ---@type XTeam
    self._Team = false

    self._BestClearTime = 0

    self._StageSaveIndex = 0
    self._StageProgressIndex = 1
    self._StartStageProgress = 0 -- 关卡开始进度

    -- 上一次关卡记录
    self._Result = false

    -- 未confirm的记录
    self._LastResult = false

    -- 历史关卡记录
    self._HistoryResults = false
end

function XTransfiniteStageGroup:SetDataFromServer(data)
    if not data then
        self:Reset()
        return
    end
    self._Id = data.StageGroupId
    local teamInfo = data.TeamInfo
    if teamInfo then
        self._IsBegin = true
        local team = self:GetTeam()
        team:SetCaptainPos(teamInfo.CaptainPos)
        team:SetFirstPos(teamInfo.FirstFightPos)
        team:SetEnterCgIndex(teamInfo.EnterCgIndex)
        team:SetSettleCgIndex(teamInfo.SettleCgIndex)
        team:UpdateByEntityIds(teamInfo.CharacterIdList)
        team:UpdateSelectGeneralSkill(teamInfo.SelectedGeneralSkill)
        local characterResultList = data.Result.CharacterResultList
        team:SetCharacterData(characterResultList)
    else
        if self._Team then
            self._Team = false
        end
        self._IsBegin = false
    end

    local stageList = self:GetStageList()
    for _, stage in pairs(stageList) do
        stage:Reset()
    end
    local stageInfoList = data.StageInfo
    for i = 1, #stageInfoList do
        local info = stageInfoList[i]
        local stageId = info.StageId
        local isWin = info.IsWin
        local time = info.SpendTime
        local score = info.Score
        local stage = self:GetStage(stageId)
        if stage then
            stage:SetPassed(isWin)
            stage:SetPassedTime(time)
            stage:SetScore(score)
        end
    end

    self._StageSaveIndex = data.StageProgressIndex
    self._StageProgressIndex = data.StageProgressIndex + 1
    self._StartStageProgress = data.StartStageProgress or 0
    local stageAmount = self:GetStageAmount()
    if self._StageProgressIndex > stageAmount then
        self._StageProgressIndex = stageAmount
        self._IsClear = true
    else
        self._IsClear = false
    end
    if self._StageSaveIndex >= stageAmount then
        self._StageSaveIndex = stageAmount - 1
    end

    self._Result = data.Result
    self._LastResult = data.LastResult
    self._HistoryResults = data.HistoryResults
end

function XTransfiniteStageGroup:GetId()
    return self._Id
end

function XTransfiniteStageGroup:SetId(value)
    self:Reset()
    self:SetBestClearTime(0)
    self._Id = value
end

function XTransfiniteStageGroup:Reset()
    self._StageList = false
    self._StageDict = false
    self._Event = false
    self._IsBegin = false
    self._IsClear = false
    --self._Team = false
    self._Score = 0
    self._StageProgressIndex = 1
    self._StageSaveIndex = 0
    self._StartStageProgress = 0
    return true
end

function XTransfiniteStageGroup:GetStageGroupType()
    return XTransfiniteConfigs.GetStageGroupType(self._Id)
end

function XTransfiniteStageGroup:IsIsland()
    if self._IsIsland == nil then
        local region = XDataCenter.TransfiniteManager.GetRegion()
        local stageGroupIdList = region:GetIslandStageGroupIdArray()

        self._IsIsland = false
        for i = 1, #stageGroupIdList do
            if self._Id == stageGroupIdList[i] then
                self._IsIsland = true
            end
        end
    end

    return self._IsIsland
end

function XTransfiniteStageGroup:GetName()
    return XTransfiniteConfigs.GetStageGroupName(self._Id)
end

function XTransfiniteStageGroup:GetBackground()
    return XTransfiniteConfigs.GetStageGroupImg(self._Id)
end

function XTransfiniteStageGroup:GetStageList()
    if not self._StageList then
        self._StageList = {}
        local stageIdArray = XTransfiniteConfigs.GetStageGroupStageId(self._Id)
        for i = 1, #stageIdArray do
            local stageId = stageIdArray[i]
            ---@type XTransfiniteStage
            local stage = XTransfiniteStage.New(stageId)
            stage:SetStageGroup(self)
            self._StageList[#self._StageList + 1] = stage
        end
    end
    return self._StageList
end

---@return XTransfiniteStage
function XTransfiniteStageGroup:GetStage(stageId)
    if not self._StageDict then
        self._StageDict = {}
        local list = self:GetStageList()
        for i = 1, #list do
            local stage = list[i]
            self._StageDict[stage:GetId()] = stage
        end
    end
    return self._StageDict[stageId]
end

---@return XTransfiniteStage
function XTransfiniteStageGroup:GetStageByIndex(index)
    return self:GetStageList()[index]
end

function XTransfiniteStageGroup:GetStageAmount()
    local stageIdArray = XTransfiniteConfigs.GetStageGroupStageId(self._Id)
    return #stageIdArray
end

---@return XTransfiniteEvent[]
function XTransfiniteStageGroup:GetFightEvent()
    if not self._Event then
        self._Event = {}
        local strengthenIdArray = XTransfiniteConfigs.GetStageGroupStrengthenId(self._Id)
        for i = 1, #strengthenIdArray do
            local strengthenId = strengthenIdArray[i]
            local event = XTransfiniteEvent.New(strengthenId)
            self._Event[#self._Event + 1] = event
        end
    end
    return self._Event
end

function XTransfiniteStageGroup:IsBegin()
    return self._IsBegin
end

function XTransfiniteStageGroup:IsClear()
    return self._IsClear
end

function XTransfiniteStageGroup:GetStageAmountClear()
    local winAmount = 0
    local list = self:GetStageList()
    for i = 1, #list do
        local stage = list[i]
        if stage:IsPassed() then
            winAmount = winAmount + 1
        end
    end
    return winAmount
end

function XTransfiniteStageGroup:IsRewardCanGet()
    return false
end

function XTransfiniteStageGroup:GetTotalClearTime()
    local time = 0
    local list = self:GetStageList()
    for i = 1, #list do
        local stage = list[i]
        if stage:IsPassed() then
            time = time + stage:GetPassedTime()
        end
    end
    return time
end

function XTransfiniteStageGroup:IsHaveTeam()
    return self._Team and true or false
end

---@return XTransfiniteTeam
function XTransfiniteStageGroup:GetTeam()
    if not self._Team then
        self._Team = XTransfiniteTeam.New(self._Id)
    end
    return self._Team
end

function XTransfiniteStageGroup:GetScore()
    local score = 0
    local stageList = self:GetStageList()
    for i = 1, #stageList do
        local stage = stageList[i]
        score = score + stage:GetScore()
    end
    return score
end

function XTransfiniteStageGroup:GetIcon()
    return XTransfiniteConfigs.GetStageGroupImg(self._Id)
end

function XTransfiniteStageGroup:IsAchievementAchieved()
    local achievementIdList = XTransfiniteConfigs.GetAchievementListByStageGroupId(self._Id)

    if not achievementIdList then
        return false
    end
    for id, config in Pairs(achievementIdList) do
        local taskIds = XTransfiniteConfigs.GetTaskTaskIds(id)
        for _, taskId in Pairs(taskIds) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
    end

    return false
end

function XTransfiniteStageGroup:IsAchievementFinished()
    local achievementIdList = XTransfiniteConfigs.GetAchievementListByStageGroupId(self._Id)
    for id, config in Pairs(achievementIdList) do
        if not XDataCenter.TaskManager.CheckTaskFinished(id) then
            return false
        end
    end
    return true
end

function XTransfiniteStageGroup:GetAchievementProgress()
    local achievementIdList = XTransfiniteConfigs.GetAchievementListByStageGroupId(self._Id)
    if not achievementIdList then
        return 0, 0
    end
    local normalAchievementIdList = {}
    local seniorAchievementIdList = {}

    for id, config in Pairs(achievementIdList) do
        if config.Type == XTransfiniteConfigs.TaskTypeEnum.Normal then
            local taskIds = XTransfiniteConfigs.GetTaskTaskIds(id)

            for _, taskId in Pairs(taskIds) do
                normalAchievementIdList[#normalAchievementIdList + 1] = taskId
            end
        elseif config.Type == XTransfiniteConfigs.TaskTypeEnum.Senior then
            local taskIds = XTransfiniteConfigs.GetTaskTaskIds(id)

            for _, taskId in Pairs(taskIds) do
                seniorAchievementIdList[#seniorAchievementIdList + 1] = taskId
            end
        end
    end

    local normalTaskList = XDataCenter.TaskManager.GetTaskIdListData(normalAchievementIdList)
    local seniorTaskList = XDataCenter.TaskManager.GetTaskIdListData(seniorAchievementIdList)
    local normalTaskProgress, normalAllCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(normalTaskList)
    local seniorTaskProgress, seniorAllCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(seniorTaskList)

    if normalTaskProgress > seniorTaskProgress then
        return normalTaskProgress, normalAllCount
    else
        return seniorTaskProgress, seniorAllCount
    end
end

function XTransfiniteStageGroup:SetBestClearTime(value)
    self._BestClearTime = value
end

function XTransfiniteStageGroup:GetBestClearTime()
    return self._BestClearTime
end

--- 检测关卡组是否通关
function XTransfiniteStageGroup:CheckStageGroupIsPass()
    return self._BestClearTime > 0
end

function XTransfiniteStageGroup:GetCurrentIndex()
    return self._StageProgressIndex
end

function XTransfiniteStageGroup:GetProgress()
    return self:GetStageAmountClear()
end

function XTransfiniteStageGroup:GetProgressMax()
    return self:GetStageAmount()
end

function XTransfiniteStageGroup:GetCurrentStage()
    return self:GetStageList()[self._StageProgressIndex]
end

function XTransfiniteStageGroup:GetStageIndex(stage)
    local stageList = self:GetStageList()
    for i = 1, #stageList do
        if stageList[i] == stage then
            return i
        end
    end
    return false
end

---@param stage XTransfiniteStage
function XTransfiniteStageGroup:IsStageLock(stage)
    local status = stage:GetStatus()
    if status == XTransfiniteConfigs.StageStatus.Lock then
        return true
    end

    local index = self:GetStageIndex(stage)
    if index then
        return self:GetCurrentIndex() < index
    end
    return true
end

function XTransfiniteStageGroup:IsStageCurrent(stage)
    return self:GetCurrentStage() == stage
end

function XTransfiniteStageGroup:SetCurrentIndex(value)
    self._StageProgressIndex = value
end

function XTransfiniteStageGroup:GetEnvironment()
    local environment = require("XEntity/XTransfinite/XTransfiniteEnvironment").New()
    environment:SetStageGroup(self)
    return environment
end

function XTransfiniteStageGroup:IsFinalStage(stage)
    local index = self:GetStageIndex(stage)
    local lastIndex = #self:GetStageList()
    return index >= lastIndex
end

function XTransfiniteStageGroup:GetNextStage(stage)
    local index = self:GetStageIndex(stage)
    if not index then
        return
    end
    local nextIndex = index + 1
    local nextStage = self:GetStageByIndex(nextIndex)
    if not nextStage then
        return
    end
    return nextStage
end

function XTransfiniteStageGroup:SetIsBegin(value)
    self._IsBegin = value
end

---@param stage XTransfiniteStage
function XTransfiniteStageGroup:IsRecordNotConfirm(stage)
    stage = stage or self:GetCurrentStage()
    if self._LastResult then
        local stageId = self._LastResult.LastWinStageId
        if stageId == stage:GetId() then
            if self:GetStageIndex(stage) == self:GetCurrentIndex() then
                --if not stage:IsPassed() then
                --end
                return true
            end
        end
    end
    return false
end

---@param stage XTransfiniteStage 最后一关且已通关, 但未结算
function XTransfiniteStageGroup:IsFinalStageAndNotConfirm(stage)
    stage = stage or self:GetCurrentStage()
    if not self:IsFinalStage(stage) then
        return false
    end
    if not self._LastResult then
        return false
    end
    local stageId = self._LastResult.LastWinStageId
    if stageId == stage:GetId() then
        return true
    end
    return false
end

function XTransfiniteStageGroup:GetLastResult()
    return self._LastResult
end

function XTransfiniteStageGroup:ClearLastResult()
    self._LastResult = nil
end

function XTransfiniteStageGroup:GetSaveStageIndex()
    return self._StageSaveIndex
end

function XTransfiniteStageGroup:GetHistoryCharacterByIndex(index)
    local historyIndex = 0
    local stageProgress = self:GetStartStageProgress()
    if stageProgress > 1 then
        historyIndex = self._StageSaveIndex - stageProgress
    else
        historyIndex = self._StageSaveIndex - 1
    end

    if self._HistoryResults and historyIndex > 0 then
        local historyResults = self._HistoryResults[historyIndex]
        if historyResults and historyResults.CharacterResultList then
            return historyResults.CharacterResultList[index]
        end
    end
end

--- 获取关卡开始进度
function XTransfiniteStageGroup:GetStartStageProgress()
    if not XTool.IsNumberValid(self._StartStageProgress) then
        return 1
    end
    return self._StartStageProgress
end

--- 获取下期关卡开始进度通过通关关卡数
function XTransfiniteStageGroup:GetNextStartProgress()
    local maxRotateStageProgressIndex = XDataCenter.TransfiniteManager.GetMaxRotateStageProgressIndex()
    local winAmount = self:GetStageAmountClear()
    local lastMaxProgress = math.max(maxRotateStageProgressIndex, winAmount)
    -- 没有挑战时显示默认值
    if lastMaxProgress > 0 and self:GetStartStageProgress() > lastMaxProgress then
        return 0
    end
    local startProgress = 0
    local configs = XTransfiniteConfigs.GetAllStartStageProgress()
    for _, config in ipairs(configs) do
        if config.LastProgress <= lastMaxProgress and config.StartProgress > startProgress then
            startProgress = config.StartProgress
        end
    end
    return startProgress
end

--- 获取关卡开始进度配置的Id
function XTransfiniteStageGroup:GetStartStageProgressId()
    local id = 1 -- 默认第一个
    -- 溢出关卡
    if self:IsIsland() then
        return id
    end
    -- 锚点为1
    local progress = self:GetStartStageProgress()
    if progress > 0 and progress == 1 then
        return id
    end
    local configs = XTransfiniteConfigs.GetAllStartStageProgress()
    for _, config in ipairs(configs) do
        if config.StartProgress == progress then
            id = config.Id
            break
        end
    end
    return id
end

return XTransfiniteStageGroup
