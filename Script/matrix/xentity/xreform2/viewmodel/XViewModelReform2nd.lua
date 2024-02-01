---@class XViewModelReform2nd
local XViewModelReform2nd = XClass(nil, "XViewModelReform2nd")
local XReform2ndChapter = require("XEntity/XReform2/XReform2ndChapter")
local XReform2ndTask = require("XEntity/XReform2/XReform2ndTask")

local IPairs = ipairs
local Pairs = pairs
local StringFormat = string.format
local ToNumber = tonumber
local TableSort = table.sort

function XViewModelReform2nd:Ctor(model)
    ---@type XReformModel
    self._Model = model

    self.CurrentStageIndex = 1
    self.ChapterTotalNumber = #self._Model:GetChapterConfig()
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

    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())

    for i = 1, #stageIds do
        ---@type XReform2ndStage
        local stage = self._Model:GetStage(stageIds[i])

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
        local stage = self._Model:GetStage(winStageId)
        winStageId = self._Model:GetStageName(stage:GetId())
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

    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stage = self._Model:GetStage(stageIds[index])
    local isUnlocked, tip = self:IsStageUnlockedByIndex(index)
    local starNumber = stage:GetStarHistory()
    local fullNumber = self._Model:GetStageFullPointById(stage:GetId())
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
    stageData.IsUnlockedDiff = self._Model:GetStageIsUnlockedDifficulty(stage)
    stageData.IsFinished = isFinished
    stageData.Name = self._Model:GetStageName(stage:GetId())
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

    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stage = self._Model:GetStage(stageIds[self.CurrentStageIndex])
    local characterIdList = self._Model:GetStageRecommendCharacterIds(stage:GetId())
    local iconList = {}

    for i, characterId in IPairs(characterIdList) do
        iconList[i] = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
    end

    chapterData.Name = self._Model:GetStageName(stage:GetId())
    chapterData.Theme = self._Model:GetChapterEventDescById(chapter:GetId())
    chapterData.StageIdLength = #self._Model:GetChapterStageIdById(chapter:GetId())
    chapterData.SpecialGoal = self._Model:GetStageGoalDescById(stage:GetId())
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
        --nowStar = nowStar + self._Model:GetChapterByIndex(i):GetStarNumber(self._Model)
        local chapter = self._Model:GetChapterByIndex(i)
        nowStar = nowStar + self._Model:GetChapterStarNumber(chapter)
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
    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stage = self._Model:GetStage(stageIds[index])
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
    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stage = self._Model:GetStage(stageIds[index])
    local starNumber = stage:GetStarHistory()
    local fullNumber = self._Model:GetStageFullPointById(stage:GetId())

    if starNumber >= fullNumber then
        for i = 1, #stageIds do
            if i ~= index then
                local other = self._Model:GetStage(stageIds[i])
                local otherStarNumber = other:GetStarHistory()
                local otherFullNumber = self._Model:GetStageFullPointById(other:GetId())

                if otherStarNumber < otherFullNumber then
                    self:SetCurrentStageIndex(i)
                end
            end
        end
    end

    return index == self.CurrentStageIndex
end

function XViewModelReform2nd:GetCurrentStage()
    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stageId = stageIds[self.CurrentStageIndex]
    local stage = self._Model:GetStage(stageId)
    stage:SetChapterIndex(self:GetCurrentChapterIndex(), self:GetCurrentStageIndex())
    return stage
end

function XViewModelReform2nd:IsSelectStageUnlocked()
    return self:IsStageUnlockedByIndex(self.CurrentStageIndex)
end

function XViewModelReform2nd:IsStageUnlockedByIndex(index)
    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stage = self._Model:GetStage(stageIds[index])
    local timeId = self._Model:GetStageOpenTimeById(stage:GetId())
    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)

    self.StageTimeOpenDic[stage:GetId()] = isTimeOpen
    if isTimeOpen then
        local preStageId = self._Model:GetStageUnlockStageIdById(stage:GetId())

        if preStageId == nil or preStageId == 0 then
            return true
        else
            ---@type XReform2ndStage
            local preStage = self._Model:GetStage(preStageId)
            return preStage:GetIsPassed(), XUiHelper.GetText("ReformLockedTip", self._Model:GetStageName(preStage:GetId()))
        end
    end

    return false, XUiHelper.GetInTimeDesc(XFunctionManager.GetStartTimeByTimeId(timeId))
end

function XViewModelReform2nd:CheckStageTimeOpenByIndex(index)
    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stage = self._Model:GetStage(stageIds[index])
    local timeId = self._Model:GetStageOpenTimeById(stage:GetId())
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
    local chapter = self._Model:GetChapterByIndex(self.CurrentChapterIndex)
    local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
    local stageId = stageIds[index]
    local stage = self._Model:GetStage(stageId)

    stage:SetChapterIndex(self:GetCurrentChapterIndex(), index)

    return stage:GetStageNumberText()
end

function XViewModelReform2nd:GetChapterLockedTipByIndex(index)
    local chapter = self._Model:GetChapterByIndex(index)
    local timeId = self._Model:GetChapterOpenTimeByChapter(chapter)

    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
    local preIsPassed = false
    local preChapter = self._Model:GetChapterByIndex(index)
    local preChapterOrder = self._Model:GetChapterOrderById(preChapter:GetId())
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)

    if preChapterOrder == 0 or preChapterOrder == nil then
        preIsPassed = true
    else
        local chapter = self._Model:GetChapterByIndex(preChapterOrder)
        preIsPassed = self._Model:IsChapterPassed(chapter)
    end

    if preIsPassed and not isTimeOpen then
        return XUiHelper.GetInTimeDesc(startTime)
    elseif isTimeOpen and not preIsPassed then
        local chapter = self:FindChapterById(preChapterOrder)
        local chapterName = self._Model:GetChapterName(chapter)
        local message = XUiHelper.GetText("ReformLockedTip", chapterName)

        return message
    elseif not isTimeOpen and not preIsPassed then
        return XUiHelper.GetInTimeDesc(startTime)
    else
        return ""
    end
end

function XViewModelReform2nd:GetChapterIsUnlockedByIndex(index)
    local chapter = self._Model:GetChapterByIndex(index)
    local timeId = self._Model:GetChapterOpenTimeByChapter(chapter)
    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
    local preIsPassed = false
    local preChapterOrder = self._Model:GetChapterOrderById(chapter:GetId())

    if preChapterOrder == 0 then
        preIsPassed = true
    else
        local preChapter = self:FindChapterById(preChapterOrder)
        preIsPassed = self._Model:IsChapterPassed(preChapter)
    end

    return isTimeOpen and preIsPassed
end

function XViewModelReform2nd:GetTaskProgressTextAndImgExp()
    local maxStar = self:GetTaskMaxStar()
    local count = self:GetChapterTotalNumber()
    local nowStar = 0

    for i = 1, count do
        local chapter = self._Model:GetChapterByIndex(i)
        nowStar = nowStar + self._Model:GetChapterStarNumber(chapter)
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
    local selectList = XSaveTool.GetData(self._Model:GetStageSelectKey())

    if selectList == nil then
        return
    end

    for stageId, isSelect in Pairs(selectList) do
        local stage = self._Model:GetStage(stageId)
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
            local chapter = self._Model:GetChapterByIndex(i)
            local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())

            for j = 1, #stageIds do
                local stage = self._Model:GetStage(stageIds[j])

                selectList[stageIds[j]] = stage:GetIsSelect()
            end
        end

        XSaveTool.SaveData(self._Model:GetStageSelectKey(), selectList)
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
    local rewardIds = self._Model:GetDisplayTaskIds()
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
    for i = 1, self._Model:GetCurrentChapterNumber() do
        local chapter = self._Model:GetChapterByIndex(i)
        if chapter then
            local stageIds = self._Model:GetChapterStageIdById(chapter:GetId())
            for j = 1, #stageIds do
                local stage = self._Model:GetStage(stageIds[j])

                stage:SetChapterIndex(i, j)
            end
        end
    end
end

function XViewModelReform2nd:GetChapterByIndex(index)
    return self._Model:GetChapterByIndex(index)
end

function XViewModelReform2nd:GetChapterTotalNumber()
    return self._Model:GetChapterNumber()
end

function XViewModelReform2nd:FindChapterById(id)
    return self._Model:GetChapter(id)
end

function XViewModelReform2nd:ReleaseConfig()
    self._Model = nil
end

function XViewModelReform2nd:GetChapterImageByIndex(index)
    local chapter = self._Model:GetChapterByIndex(index)
    if not chapter then
        return false
    end
    return self._Model:GetChapterImageById(chapter:GetId())
end

return XViewModelReform2nd
