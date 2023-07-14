local XEscapeCharacterState = require("XEntity/XEscape/XEscapeCharacterState")
local XEscapeStageResult = require("XEntity/XEscape/XEscapeStageResult")
local XEscapeChapterResult = require("XEntity/XEscape/XEscapeChapterResult")
local type = type
local tableInsert = table.insert
local tableRemove = table.remove

--大逃杀基础信息
local XEscapeData = XClass(nil, "XEscapeData")

local Default = {
    _ChapterId = 0,     --进行中的章节
    _RemainTime = 0,    --剩余时间
    _Score = 0,         --评分
    _SelectedCardIds = {},  --选择的角色
    _SelectedRobotIds = {}, --选择的机器人
    _PrefightCaptainPos = 1, --队长位置
    _PrefightFirstPos = 1, --首发位置
    _CharacterStates = {},   --角色/机器人状态
    _StageResults = {}, --当前通关结果
    _PassStageIds = {}, --已通关关卡ID
    _ChapterResults = {},   --章节结果
}

function XEscapeData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.PassStageIdDic = {} --已通关关卡ID字典
    self.ChapterResultsDic = {}
end

function XEscapeData:UpdateData(data)
    self._ChapterId = data.ChapterId
    self._RemainTime = data.RemainTime
    self._Score = data.Score
    self._SelectedCardIds = data.SelectedCardIds
    self._SelectedRobotIds = data.SelectedRobotIds
    self._PassStageIds = data.PassStageIds
    if XTool.IsNumberValid(data.PrefightCaptainPos) then
        self._PrefightCaptainPos = data.PrefightCaptainPos
    end
    if XTool.IsNumberValid(data.PrefightFirstPos) then
        self._PrefightFirstPos = data.PrefightFirstPos
    end
    self:UpdateCharacterStateData(data.CharacterStates)
    self:UpdateStageResults(data.StageResults)
    self:UpdatePassStageIdDic(data.PassStageIds)
    self:UpdateChapterResults(data.ChapterResults)
    self:UpdateTeam()
end

function XEscapeData:UpdateTeam()
    if XTool.IsTableEmpty(self._SelectedCardIds) and XTool.IsTableEmpty(self._SelectedRobotIds) then
        return
    end

    local team = XDataCenter.EscapeManager.GetTeam()
    team:Clear()
    for i, characterId in ipairs(self._SelectedCardIds) do
        if XTool.IsNumberValid(characterId) then
            team:UpdateEntityTeamPos(characterId, i, true)
        end
    end
    for i, robotId in ipairs(self._SelectedRobotIds) do
        if XTool.IsNumberValid(robotId) then
            team:UpdateEntityTeamPos(robotId, i, true)
        end
    end
    team:UpdateFirstFightPos(self._PrefightFirstPos)
    team:UpdateCaptainPos(self._PrefightCaptainPos)
end

function XEscapeData:UpdateChapterResults(chapterResults)
    self.ChapterResultsDic = {}
    for _, data in ipairs(chapterResults or {}) do
        local chapterResult = XEscapeChapterResult.New()
        chapterResult:UpdateData(data)
        self.ChapterResultsDic[data.ChapterId] = chapterResult
    end
end

function XEscapeData:UpdatePassStageIdDic(passStageIds)
    for _, stageId in ipairs(passStageIds) do
        self:UpdatePassStageId(stageId)
    end
end

function XEscapeData:UpdatePassStageId(stageId)
    self.PassStageIdDic[stageId] = true
end

function XEscapeData:UpdateCharacterStateData(characterStates)
    self._CharacterStates = {}
    for _, data in ipairs(characterStates) do
        local characterState = XEscapeCharacterState.New()
        characterState:UpdateData(data)
        tableInsert(self._CharacterStates, characterState)
    end
end

function XEscapeData:UpdateStageResults(stageResults)
    self._StageResults = {}
    for _, data in ipairs(stageResults) do
        self:UpdateStageResult(data)
    end
end

function XEscapeData:UpdateStageResult(stageResult)
    local characterState = XEscapeStageResult.New()
    characterState:UpdateData(stageResult)
    tableInsert(self._StageResults, characterState)
end

function XEscapeData:GetScore()
    return self._Score
end

function XEscapeData:GetRemainTime()
    return self._RemainTime
end

function XEscapeData:GetChapterId()
    return self._ChapterId
end

function XEscapeData:GetLayerClearStageCount(layerId, isCurChallengeChapter)
    local stageIds = XEscapeConfigs.GetLayerStageIds(layerId)
    local count = 0
    for _, stageId in ipairs(stageIds) do
        if isCurChallengeChapter then
            count = self:IsCurChapterStageClear(stageId) and count + 1 or count
        elseif self:IsStageClear(stageId) then
            count = count + 1
        end
    end
    return count
end

function XEscapeData:GetCharacterState(entityId)
    for _, characterState in ipairs(self._CharacterStates) do
        if characterState:GetCharacterId() == XEntityHelper.GetCharacterIdByEntityId(entityId) then
            return characterState
        end
    end
end

--当前正在进行中的章节，关卡是否通关
function XEscapeData:IsCurChapterStageClear(stageId)
    for _, stageResult in ipairs(self._StageResults) do
        if stageId == stageResult:GetStageId() then
            return true
        end
    end
    return false
end

--当前正在进行中的章节是否通关
function XEscapeData:IsCurChapterClear()
    local curChapterId = self:GetChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        return false
    end

    local layerIds = XEscapeConfigs.GetChapterLayerIds(curChapterId)
    for _, layerId in ipairs(layerIds) do
        if not self:IsLayerClear(layerId, true) then
            return false
        end
    end
    return true
end

function XEscapeData:IsLayerClear(layerId, isCurChapter)
    local clearStageCount = XEscapeConfigs.GetLayerClearStageCount(layerId)
    local stageIds = XEscapeConfigs.GetLayerStageIds(layerId)
    for _, stageId in ipairs(stageIds) do
        if isCurChapter then
            if self:IsCurChapterStageClear(stageId) then
                clearStageCount = clearStageCount - 1
            end
        elseif self:IsStageClear(stageId) then
            clearStageCount = clearStageCount - 1
        end
    end
    return clearStageCount <= 0
end

function XEscapeData:IsStageClear(stageId)
    return self.PassStageIdDic[stageId] or false
end

function XEscapeData:IsInChallengeChapter(chapterId)
    return self:GetChapterId() == chapterId
end

function XEscapeData:IsChapterClear(chapterId)
    local clearStageCount
    local layerIds = XEscapeConfigs.GetChapterLayerIds(chapterId)
    for _, layerId in ipairs(layerIds) do
        if not self:IsLayerClear(layerId) then
            return false
        end
    end
    return true
end

function XEscapeData:GetAllHit()
    local allHit = 0
    for _, stageResult in ipairs(self._StageResults) do
        allHit = allHit + stageResult:GetHit()
    end
    return allHit
end

function XEscapeData:GetAllTrapHit()
    local allTrapHit = 0
    for _, stageResult in ipairs(self._StageResults) do
        allTrapHit = allTrapHit + stageResult:GetTrapHit()
    end
    return allTrapHit
end

function XEscapeData:GetChapterResult(chapterId)
    return self.ChapterResultsDic[chapterId]
end

return XEscapeData