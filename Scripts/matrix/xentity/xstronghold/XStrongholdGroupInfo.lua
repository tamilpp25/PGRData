local XStrongholdStageData = require("XEntity/XStronghold/XStrongholdStageData")

local type = type
local pairs = pairs
local ipairs = ipairs
local isNumberValid = XTool.IsNumberValid
local tableInsert = table.insert
local clone = XTool.Clone

local Default = {
    _Id = 0, --据点Id
    _ChapterType = XStrongholdConfigs.ChapterType.Normal, --章节类型
    _SupportId = 0, --支援方案Id
    _StageIds = {}, --关卡Id列表
    _StageDatas = {}, --关卡数据
    _PassUseElectric = -1, --通关当前据点使用电量
    _UsedSystemElectricEnergy = -1, --通关当前据点使用的系统电量
}

--超级据点据点信息
local XStrongholdGroupInfo = XClass(nil, "XStrongholdGroupInfo")

function XStrongholdGroupInfo:Ctor(id, isHistory)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
    if not isHistory then
        self._ChapterType = XStrongholdConfigs.GetChapterTypeByGroupId(id)
    end
end

function XStrongholdGroupInfo:GetStageId(stageIndex)
    return self._StageIds[stageIndex] or 0
end

function XStrongholdGroupInfo:GetChapterType()
    return self._ChapterType
end

function XStrongholdGroupInfo:GetStageDataByIndex(stageIndex)
    local stageId = self:GetStageId(stageIndex)
    return self:GetStageData(stageId)
end

function XStrongholdGroupInfo:GetStageData(stageId)
    if not isNumberValid(stageId) then
        XLog.Error("XStrongholdGroupInfo:GetStageData error: stageId illegal, stageId is: ", stageId)
        return
    end

    local stageData = self._StageDatas[stageId]
    if not stageData then
        stageData = XStrongholdStageData.New(stageId)
        self._StageDatas[stageId] = stageData
    end
    return stageData
end

function XStrongholdGroupInfo:InitStageData(stageIds, stageBuffIdDic, supportId)
    self._StageIds = {}

    for _, stageId in ipairs(stageIds or {}) do
        local stageData = self:GetStageData(stageId)
        tableInsert(self._StageIds, stageId)

        local buffId = stageBuffIdDic[stageId]
        if isNumberValid(buffId) then
            stageData:SetBuff(buffId)
        end
    end

    self._SupportId = supportId or 0
end

--更新通关使用电量
function XStrongholdGroupInfo:UpdatePassUseElectric(electric, systemElectric)
    self._PassUseElectric = electric or self._PassUseElectric
    self._UsedSystemElectricEnergy = systemElectric or self._UsedSystemElectricEnergy
end

--获得通关使用电量
function XStrongholdGroupInfo:GetPassUseElectric()
    return self._PassUseElectric, self._UsedSystemElectricEnergy
end

function XStrongholdGroupInfo:UpdateFinishStages(finishStageIds)
    for _, stageId in pairs(finishStageIds or {}) do
        local stageData = self:GetStageData(stageId)
        stageData:SetFinished(true)
    end
end

function XStrongholdGroupInfo:ResetFinishStages()
    for _, stageData in pairs(self._StageDatas) do
        stageData:SetFinished(false)
    end
end

function XStrongholdGroupInfo:ResetFinishStage(stageId)
    local stageData = self:GetStageData(stageId)
    if stageData then
        stageData:SetFinished(false)
    end
end

function XStrongholdGroupInfo:GetStageIds()
    return clone(self._StageIds)
end

function XStrongholdGroupInfo:GetSupportId()
    return self._SupportId
end

function XStrongholdGroupInfo:GetRequireTeamNum()
    return #self._StageIds
end

function XStrongholdGroupInfo:GetStageBuffId(stageIndex)
    local stageData = self:GetStageDataByIndex(stageIndex)
    return stageData and stageData:GetBuffId() or 0
end

function XStrongholdGroupInfo:IsStageFinished(stageIndex)
    local stageData = self:GetStageDataByIndex(stageIndex)
    return stageData and stageData:IsFinished() or false
end

function XStrongholdGroupInfo:CheckHasStageFinished()
    for _, stageData in pairs(self._StageDatas) do
        if stageData:IsFinished() then
            return true
        end
    end
    return false
end

function XStrongholdGroupInfo:GetNextFightStageIndex()
    for stageIndex, stageId in ipairs(self._StageIds) do
        local stageData = self:GetStageData(stageId)
        if not stageData:IsFinished() then
            return stageIndex
        end
    end
    return 0
end

return XStrongholdGroupInfo
