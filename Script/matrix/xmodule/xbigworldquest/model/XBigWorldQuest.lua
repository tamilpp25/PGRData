---@class XBigWorldQuestObjective
---@field _ObjectiveId number
local XBigWorldQuestObjective = XClass(nil, "XBigWorldQuestObjective")

function XBigWorldQuestObjective:Ctor(processId)
    self._ObjectiveId = processId
    self._Progress = 0
end

function XBigWorldQuestObjective:UpdateData(objective)
    self._Progress = objective.Progress
end

function XBigWorldQuestObjective:SetProgress(value)
    self._Progress = value
end

function XBigWorldQuestObjective:GetProgress()
    return self._Progress
end

function XBigWorldQuestObjective:GetId()
    return self._ObjectiveId
end

function XBigWorldQuestObjective:Restore()
    self._Progress = 0
end


---@class XBigWorldQuestStep
---@field _StepId number 步骤Id
---@field _ObjectiveDict table<number, XBigWorldQuestObjective> 目标数据
local XBigWorldQuestStep = XClass(nil, "XBigWorldQuestStep")

local StepState = XMVCA.XBigWorldQuest.StepState

function XBigWorldQuestStep:Ctor(stepId)
    self._StepId = stepId
    self._ObjectiveDict = false
    self._State = StepState.Inactive
end

function XBigWorldQuestStep:GetCurrentProcessId()
    return self._CurrentProcessId
end

function XBigWorldQuestStep:UpdateData(step)
    self._State = step.State
    local objectives = step.Objectives
    if not XTool.IsTableEmpty(objectives) then
        if not self._ObjectiveDict then
            self._ObjectiveDict = {}
        end
        for _, objective in pairs(objectives) do
            local objectiveId = objective.Id
            local objectiveData = self:TryGetObjective(objectiveId)
            objectiveData:UpdateData(objective)
        end
    end
end

function XBigWorldQuestStep:GetState()
    return self._State
end

function XBigWorldQuestStep:SetState(value)
    self._State = value
end

function XBigWorldQuestStep:TryGetObjective(objectiveId)
    if not self._ObjectiveDict then
        self._ObjectiveDict = {}
    end
    local objectiveData = self._ObjectiveDict[objectiveId]
    if not objectiveData then
        objectiveData = XBigWorldQuestObjective.New(objectiveId)
        self._ObjectiveDict[objectiveId] = objectiveData
    end
    return objectiveData
end

---@return XBigWorldQuestObjective[]
function XBigWorldQuestStep:GetObjectiveList(check)
    if not self._ObjectiveDict then
        return
    end
    local list = {}
    for _, data in pairs(self._ObjectiveDict) do
        if check then
            if check(data) then
                list[#list + 1] = data
            end
        else
            list[#list + 1] = data
        end
        
    end
    return list
end

function XBigWorldQuestStep:IsActive()
    return self._State == StepState.Active
end

function XBigWorldQuestStep:IsFinish()
    return self._State == StepState.Finished
end

function XBigWorldQuestStep:GetId()
    return self._StepId
end

function XBigWorldQuestStep:Reset()
    self._StepId = 0
    self._ObjectiveDict = false
    self._State = StepState.Inactive
end

function XBigWorldQuestStep:Restore()
    self._State = StepState.Inactive
    if not XTool.IsTableEmpty(self._ObjectiveDict) then
        for _, obj in pairs(self._ObjectiveDict) do
            obj:Restore()
        end
    end
end


---@class XBigWorldQuest
---@field _QuestId number 任务Id
---@field _StepDict table<number, XBigWorldQuestStep> 步骤数据
local XBigWorldQuest = XClass(nil, "XBigWorldQuest")

local QuestState = XMVCA.XBigWorldQuest.QuestState

function XBigWorldQuest:Ctor(questId)
    self._QuestId = questId
    self._StepDict = false
    self._State = QuestState.None
end

function XBigWorldQuest:UpdateData(quest)
    self._State = quest.State
    local steps = quest.Steps
    if not XTool.IsTableEmpty(steps) then
        for _, step in pairs(steps) do
            local stepId = step.Id
            local stepData = self:TryGetStep(stepId)
            stepData:UpdateData(step)
        end
    end
end

---@return XBigWorldQuestStep
function XBigWorldQuest:TryGetStep(stepId)
    if not self._StepDict then
        self._StepDict = {}
    end

    local stepData = self._StepDict[stepId]
    if not stepData then
        stepData = XBigWorldQuestStep.New(stepId)
        self._StepDict[stepId] = stepData
    end

    return stepData
end

---@return XBigWorldQuestStep
function XBigWorldQuest:GetStep(stepId)
    if not self._StepDict then
        return
    end
    return self._StepDict[stepId]
end

---@return XBigWorldQuestStep[]
function XBigWorldQuest:GetActiveStepData()
    if not self._StepDict then
        return
    end
    local list = {}
    for _, data in pairs(self._StepDict) do
        if data:IsActive() then
            list[#list + 1] = data
        end
    end
    return list
end

function XBigWorldQuest:GetState()
    return self._State
end

function XBigWorldQuest:SetState(state)
    self._State = state
end

function XBigWorldQuest:Finish()
    self:SetState(QuestState.Finished)
    if not XTool.IsTableEmpty(self._StepDict) then
        for _, step in pairs(self._StepDict) do
            step:Restore()
        end
    end
end

function XBigWorldQuest:GetId()
    return self._QuestId
end

function XBigWorldQuest:IsFinish()
    return self._State == QuestState.Finished
end

function XBigWorldQuest:IsShowInList()
    if self._State == QuestState.Undertaken then
        return true
    end

    return false
end

function XBigWorldQuest:Reset()
    self._QuestId = 0
    self._StepDict = false
    self._State = QuestState.None
end

return XBigWorldQuest