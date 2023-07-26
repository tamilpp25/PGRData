---@class XViewModelReform2nd
local XViewModelReform2nd = XClass(nil, "XViewModelReform2nd")
local XReform2ndChapter = require("XEntity/XReform2/XReform2ndChapter")
local XReform2ndTask = require("XEntity/XReform2/XReform2ndTask")

local IPairs = ipairs
local Pairs = pairs
local StringFormat = string.format
local ToNumber = tonumber
local TableSort = table.sort

function XViewModelReform2nd:Ctor()
    self.CurrentStageIndex = 1
    self.ChapterTotalNumber = #XReform2ndConfigs.GetChapterConfig()
    ---@type XReform2ndTask[]
    self.TaskList = {}
    self.TaskLength = 0
    self.CurrentChapterIndex = 1
    self.MaxTaskStar = 0
    self.IsChange = false
    self.StageTimeOpenDic = {}
    self:Init()
end

function XViewModelReform2nd:InitCurrentStageIndex()
    self.CurrentStageIndex = 1
    
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()

    for i = 1, #stageIds do
        ---@type XReform2ndStage
        local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[i])

        if stage:GetIsSelect() then
            self.CurrentStageIndex = i
            break
        end
    end
end

function XViewModelReform2nd:SetCurrentChapterIndex(index)
    self.CurrentChapterIndex = index
    self:InitCurrentStageIndex()
end

function XViewModelReform2nd:GetCurrentChapterIndex()
    return self.CurrentChapterIndex
end

function XViewModelReform2nd:SetCurrentStageIndex(index)
    self.CurrentStageIndex = index
end

function XViewModelReform2nd:GetCurrentStageIndex()
    return self.CurrentStageIndex
end

function XViewModelReform2nd:SaveIndexToManager()
    XDataCenter.Reform2ndManager.SetPreIndex(self.CurrentChapterIndex, self.CurrentStageIndex)
end

function XViewModelReform2nd:GetUnlockedHardStageName()
    local isUnlocked, winStageId, chapterIndex, stageIndex = XDataCenter.Reform2ndManager.IsUnlockHardModeStageId()

    if winStageId then
        local stage = XDataCenter.Reform2ndManager.GetStage(winStageId)

        winStageId = stage:GetName()
    end
    self.CurrentChapterIndex = chapterIndex
    self.CurrentStageIndex = stageIndex

    return isUnlocked, winStageId
end

function XViewModelReform2nd:GetStageDataByIndex(index)
    local stageData = {
        Index = false,
        IsSelect = false,
        IsUnlocked = false,
        UnlockedTip = false,
        IsUnlockedDiff = false,
        IsFinished = false,
        Name = false,
        StarDesc = false,
        Number = false
    }

    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[index])
    local isUnlocked, tip = self:IsStageUnlockedByIndex(index)
    local starNumber = stage:GetStarHistory()
    local fullNumber = stage:GetFullPoint()
    local isSelect = self:GetStageIsSelectByIndex(index)
    local isFinished = starNumber >= fullNumber

    self:SetStageSelect(stage, isSelect)

    if starNumber > fullNumber then
        starNumber = fullNumber
    end

    stageData.Index = index
    stageData.IsSelect = stage:GetIsSelect()
    stageData.IsUnlocked = isUnlocked
    stageData.UnlockedTip = tip
    stageData.IsUnlockedDiff = stage:GetIsUnlockedDifficulty()
    stageData.IsFinished = isFinished
    stageData.Name = stage:GetName()
    stageData.StarDesc = StringFormat("%s/%s", starNumber, fullNumber)
    stageData.Number = stage:GetStageNumberText()

    return stageData
end

function XViewModelReform2nd:GetChapterData()
    local chapterData = {
        Name = false,
        Theme = false,
        StageIdLength = false,
        RecommendCharacterList = false,
        SpecialGoal = false
    }

    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[self.CurrentStageIndex])
    local characterIdList = stage:GetRecommendCharacters()
    local iconList = {}

    for i, characterId in IPairs(characterIdList) do
        iconList[i] = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId)
    end

    chapterData.Name = stage:GetName()
    chapterData.Theme = chapter:GetThemeDesc()
    chapterData.StageIdLength = #chapter:GetStageIdList()
    chapterData.SpecialGoal = stage:GetGoalDesc()
    chapterData.RecommendCharacterList = iconList

    return chapterData
end

function XViewModelReform2nd:GetTaskDataByIndex(index)
    local taskData = {
        Id = false,
        RewardsList = false,
        State = false,
        StarNumsTxt = false
    }

    local task = self.TaskList[index]
    local rewardId = XTaskConfig.GetTaskRewardId(task:GetId())
    local taskStar = task:GetTotalStar()
    local nowStar = 0

    for i = 1, self.ChapterTotalNumber do
        nowStar = nowStar + XDataCenter.Reform2ndManager.GetChapterByIndex(i):GetStarNumber()
    end

    if nowStar >= taskStar then
        nowStar = taskStar
    end

    taskData.Id = task:GetId()
    taskData.RewardsList = XRewardManager.GetRewardList(rewardId)
    taskData.State = task:GetState()
    taskData.StarNumsTxt = XUiHelper.GetText("ReformTaskStarNumber", nowStar, taskStar)

    return taskData
end

function XViewModelReform2nd:SetStageSelectByIndex(index)
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[index])
    local isSelect = index == self.CurrentStageIndex
    
    self:SetStageSelect(stage, isSelect)
end

function XViewModelReform2nd:SetStageSelect(stage, isSelect)
    if isSelect ~= stage:GetIsSelect() then
        stage:SetIsSelect(isSelect)
        self.IsChange = true
    end
end

function XViewModelReform2nd:GetStageIsSelectByIndex(index)
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[index])
    local starNumber = stage:GetStarHistory()
    local fullNumber = stage:GetFullPoint()

    if starNumber >= fullNumber then
        for i = 1, #stageIds do
            if i ~= index then
                local other = XDataCenter.Reform2ndManager.GetStage(stageIds[i])
                local otherStarNumber = other:GetStarHistory()
                local otherFullNumber = other:GetFullPoint()

                if otherStarNumber < otherFullNumber then
                    self:SetCurrentStageIndex(i)
                end
            end
        end
    end

    return index == self.CurrentStageIndex
end

function XViewModelReform2nd:GetCurrentStage()
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stageId = stageIds[self.CurrentStageIndex]
    local stage = XDataCenter.Reform2ndManager.GetStage(stageId)
    stage:SetChapterIndex(self:GetCurrentChapterIndex(), self:GetCurrentStageIndex())
    return stage
end

function XViewModelReform2nd:IsSelectStageUnlocked()
    return self:IsStageUnlockedByIndex(self.CurrentStageIndex)
end

function XViewModelReform2nd:IsStageUnlockedByIndex(index)
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[index])
    local timeId = stage:GetOpenTime()
    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)

    self.StageTimeOpenDic[stage:GetId()] = isTimeOpen
    if isTimeOpen then
        local preStageId = stage:GetUnlockStageId()

        if preStageId == nil or preStageId == 0 then
            return true
        else
            ---@type XReform2ndStage
            local preStage = XDataCenter.Reform2ndManager.GetStage(preStageId)

            return preStage:GetIsPassed(), XUiHelper.GetText("ReformLockedTip", preStage:GetName())
        end
    end

    return false, XUiHelper.GetInTimeDesc(XFunctionManager.GetStartTimeByTimeId(timeId))
end

function XViewModelReform2nd:CheckStageTimeOpenByIndex(index)
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[index])
    local timeId = stage:GetOpenTime()
    local isChangeUnlocked = XFunctionManager.CheckInTimeByTimeId(timeId) ~= self.StageTimeOpenDic[stage:GetId()]

    if isChangeUnlocked then
        self.StageTimeOpenDic[stage:GetId()] = XFunctionManager.CheckInTimeByTimeId(timeId)
    end
    
    return isChangeUnlocked
end

function XViewModelReform2nd:GetCurrStageNumberText()
    return self:GetStageNumberTextByIndex(self.CurrentStageIndex)
end

function XViewModelReform2nd:GetStageNumberTextByIndex(index)
    local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = chapter:GetStageIdList()
    local stageId = stageIds[index]
    local stage = XDataCenter.Reform2ndManager.GetStage(stageId)

    stage:SetChapterIndex(self:GetCurrentChapterIndex(), index)

    return stage:GetStageNumberText()
end

function XViewModelReform2nd:GetChapterLockedTipByIndex(index)
    local timeId = XDataCenter.Reform2ndManager.GetChapterByIndex(index):GetOpenTime()
    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
    local preIsPassed = false
    local preChapter = XDataCenter.Reform2ndManager.GetChapterByIndex(index):GetOrder()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)

    if preChapter == 0 or preChapter == nil then
        preIsPassed = true
    else
        preIsPassed = XDataCenter.Reform2ndManager.GetChapterByIndex(preChapter):IsPassed()
    end

    if preIsPassed and not isTimeOpen then
        return XUiHelper.GetInTimeDesc(startTime)
    elseif isTimeOpen and not preIsPassed then
        local chapter = self:FindChapterById(preChapter)
        local chapterName = chapter:GetName()
        local message = XUiHelper.GetText("ReformLockedTip", chapterName)

        return message
    elseif not isTimeOpen and not preIsPassed then
        return XUiHelper.GetInTimeDesc(startTime)
    else
        return ""
    end
end

function XViewModelReform2nd:GetChapterIsUnlockedByIndex(index)
    local timeId = XDataCenter.Reform2ndManager.GetChapterByIndex(index):GetOpenTime()
    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
    local preIsPassed = false
    local preChapter = XDataCenter.Reform2ndManager.GetChapterByIndex(index):GetOrder()

    if preChapter == 0 then
        preIsPassed = true
    else
        local chapter = self:FindChapterById(preChapter)

        preIsPassed = chapter:IsPassed()
    end

    return isTimeOpen and preIsPassed
end

function XViewModelReform2nd:GetTaskProgressTextAndImgExp()
    local maxStar = self:GetTaskMaxStar()
    local count = self:GetChapterTotalNumber()
    local nowStar = 0

    for i = 1, count do
        nowStar = nowStar + XDataCenter.Reform2ndManager.GetChapterByIndex(i):GetStarNumber()
    end

    if maxStar > nowStar then
        return StringFormat("%s/%s", nowStar, maxStar), nowStar / maxStar
    else
        return StringFormat("%s/%s", maxStar, maxStar), 1
    end
end

-------==============================================
function XViewModelReform2nd:Init()
    self:RefreshTaskData()
    self:GetStageIsSelectFromLocal()
    self:InitCurrentStageIndex()
end

function XViewModelReform2nd:GetStageIsSelectFromLocal()
    local selectList = XSaveTool.GetData(XDataCenter.Reform2ndManager.GetStageSelectKey())

    if selectList == nil then
        return
    end

    for stageId, isSelect in Pairs(selectList) do
        local stage = XDataCenter.Reform2ndManager.GetStage(stageId)
        if stage then
            stage:SetIsSelect(isSelect)
        end
    end
end

function XViewModelReform2nd:SetStageIsSelectToLocal()
    if self.IsChange then
        self.IsChange = false
        
        local selectList = {}

        for i = 1, self:GetChapterTotalNumber() do
            local stageIds = XDataCenter.Reform2ndManager.GetChapterByIndex(i):GetStageIdList()

            for j = 1, #stageIds do
                local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[j])

                selectList[stageIds[j]] = stage:GetIsSelect()
            end
        end

        XSaveTool.SaveData(XDataCenter.Reform2ndManager.GetStageSelectKey(), selectList)
    end
end

function XViewModelReform2nd:RefreshTaskData()
    local taskData = XDataCenter.TaskManager.GetTaskList(TaskType.Reform)

    for i, data in Pairs(taskData) do
        local task = self.TaskList[i]
        local progress = XTaskConfig.GetProgress(data.Id)

        if task then
            task:SetId(data.Id)
            task:SetTotalStar(progress)
            task:SetState(data.State)
        else
            task = XReform2ndTask.New(data.Id, progress, data.State)
            self.TaskList[i] = task
        end
    end

    TableSort(self.TaskList, function(taskA, taskB)
        return taskA:GetTotalStar() < taskB:GetTotalStar()
    end)

    self.TaskLength = #self.TaskList
    self.MaxTaskStar = self.TaskList[self.TaskLength]:GetTotalStar()
end

function XViewModelReform2nd:SortTaskList()
    local taskList = {}
    ---@type XReform2ndTask[]
    local oldTaskList = self.TaskList
    local finishTaskList = {}
    local taskListLength = 0
    local finishTaskListLength = 0

    for i = 1, self.TaskLength do
        if oldTaskList[i]:GetState() ~= XDataCenter.TaskManager.TaskState.Finish then
            taskList[taskListLength + 1] = oldTaskList[i]
            taskListLength = taskListLength + 1
        else
            finishTaskList[finishTaskListLength + 1] = oldTaskList[i]
            finishTaskListLength = finishTaskListLength + 1
        end
    end

    for i = 1, finishTaskListLength do
        taskList[taskListLength + 1] = finishTaskList[i]
        taskListLength = taskListLength + 1
    end

    self.TaskList = taskList
    self.TaskLength = taskListLength
end

function XViewModelReform2nd:GetDisplayRewards()
    local rewardIds = XReform2ndConfigs.GetDisplayTaskIds()
    local rewards = {}
    local length = 0

    if not rewardIds then
        return rewards
    end

    for i = 1, #rewardIds do
        local rewardList = XRewardManager.GetRewardListNotCount(ToNumber(rewardIds[i]))
        if rewardList then
            for j = 1, #rewardList do
                rewards[length + 1] = rewardList[j]
                length = length + 1
            end
        end
    end

    return rewards
end

function XViewModelReform2nd:GetTaskDataList()
    self:RefreshTaskData()
    self:SortTaskList()

    local taskData = {}

    for i = 1, self.TaskLength do
        taskData[i] = self:GetTaskDataByIndex(i)
    end

    return taskData
end

function XViewModelReform2nd:GetTaskMaxStar()
    return self.MaxTaskStar
end

function XViewModelReform2nd:GetTaskTotalNumber()
    return self.TaskLength
end

function XViewModelReform2nd:InitChapterList()
    for i = 1, XDataCenter.Reform2ndManager.GetCurrentChapterNumber() do
        local chapter = XDataCenter.Reform2ndManager.GetChapterByIndex(i)

        local stageIds = chapter:GetStageIdList()

        for j = 1, #stageIds do
            local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[j])

            stage:SetChapterIndex(i, j)
        end
    end
end

function XViewModelReform2nd:GetChapterByIndex(index)
    return XDataCenter.Reform2ndManager.GetChapterByIndex(index)
end

function XViewModelReform2nd:GetChapterTotalNumber()
    return XDataCenter.Reform2ndManager.GetChapterNumber()
end

function XViewModelReform2nd:FindChapterById(id)
    return XDataCenter.Reform2ndManager.GetChapter(id)
end

function XViewModelReform2nd:ReleaseConfig()
    XReform2ndConfigs.ReleaseMemberSourceConfig()
    XReform2ndConfigs.ReleaseMemberGroupConfig()
    XReform2ndConfigs.ReleaseChapterConfig()
    XReform2ndConfigs.ReleaseStageConfig()
    XReform2ndConfigs.ReleaseClientConfig()
end

return XViewModelReform2nd
