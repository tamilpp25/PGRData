local XEscapeCharacterState = require("XEntity/XEscape/XEscapeCharacterState")
local XEscapeStageResult = require("XEntity/XEscape/XEscapeStageResult")
local XEscapeChapterResult = require("XEntity/XEscape/XEscapeChapterResult")
local XEscapeTacticsNodeData = require("XEntity/XEscape/Tactics/XEscapeTacticsNodeData")
local type = type
local tableInsert = table.insert
local tableRemove = table.remove

--大逃杀基础信息
---@class XEscapeData
local XEscapeData = XClass(nil, "XEscapeData")

local Default = {
    _ChapterId = 0,             --进行中的章节
    _RemainTime = 0,            --剩余时间
    _MaxRemainTime = 0,         --最大上限
    _Score = 0,                 --评分
    _SelectedCardIds = {},      --选择的角色
    _SelectedRobotIds = {},     --选择的机器人
    _PrefightCaptainPos = 1,    --队长位置
    _PrefightFirstPos = 1,      --首发位置
    _OldRemainTime = 0,         --旧时长
    _CharacterStates = {},      --角色/机器人状态
    _StageResults = {},         --当前通关结果
    _PassStageIds = {},         --已通关关卡ID
    _ChapterResults = {},       --章节结果
    _TacticsNodes = {},         --策略节点
}

function XEscapeData:Ctor()
    self:Init()
end

function XEscapeData:Init()
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

--region Setter
function XEscapeData:UpdateData(data)
    if not XTool.IsNumberValid(data.ActivityId) then
        self:Init()
        return
    end
    self:SetChapterId(data.ChapterId)
    self:SetRemainTime(data.RemainTime)
    self:SetMaxRemainTime(data.MaxRemainTime)
    self._Score = data.Score
    self._SelectedCardIds = data.SelectedCardIds
    self._SelectedRobotIds = data.SelectedRobotIds
    self._PassStageIds = data.PassStageIds
    if XTool.IsNumberValid(data.PrefightCaptainPos) then
        self._PrefightCaptainPos = data.PrefightCaptainPos
    end
    if XTool.IsNumberValid(data.PrefightFirstFightPos) then
        self._PrefightFirstPos = data.PrefightFirstFightPos
    end

    self:UpdateStageResults(data.StageResults)
    self:UpdatePassStageIdDic(data.PassStageIds)
    self:UpdateChapterResults(data.ChapterResults)
    self:UpdateTacticsNodes(data.TacticsNodes)
    self:UpdateTeam()
end

function XEscapeData:UpdateTeam()
    if XTool.IsTableEmpty(self._SelectedCardIds) and XTool.IsTableEmpty(self._SelectedRobotIds) then
        return
    end
    
    -- 减少同步请求
    local team = XDataCenter.EscapeManager.GetTeam()
    local EntityIds = {}
    for i, characterId in ipairs(self._SelectedCardIds) do
        if XTool.IsNumberValid(characterId) then
            EntityIds[i] = characterId or 0
        end
    end
    for i, robotId in ipairs(self._SelectedRobotIds) do
        if XTool.IsNumberValid(robotId) then
            EntityIds[i] = robotId or 0
        end
    end
    local teamData = {
        FirstFightPos = self._PrefightFirstPos,
        CaptainPos = self._PrefightCaptainPos,
        TeamData = EntityIds,
        TeamName = team:GetName()
    }
    team:UpdateFromTeamData(teamData)
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

---角色状态更新(1期不开放中途换角,2期开发后弃用)
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
    if XTool.IsTableEmpty(stageResults) then
        return
    end
    for _, data in ipairs(stageResults) do
        self:UpdateStageResult(data)
    end
end

function XEscapeData:UpdateStageResult(stageResult)
    local characterState = XEscapeStageResult.New()
    characterState:UpdateData(stageResult)
    tableInsert(self._StageResults, characterState)
end

function XEscapeData:UpdateTacticsNodes(tacticsNodes)
    ---@type XEscapeTacticsNodeData[]
    self._TacticsNodes = {}
    if XTool.IsTableEmpty(tacticsNodes) then
        return
    end
    for i, tacticsNode in ipairs(tacticsNodes) do
        ---@type XEscapeTacticsNodeData
        local tacticsNodeData = XEscapeTacticsNodeData.New()
        tacticsNodeData:UpdateData(tacticsNode)
        self._TacticsNodes[#self._TacticsNodes+1] = tacticsNodeData
    end
end

function XEscapeData:AddTacticsNodes(data)
    if XTool.IsTableEmpty(self._TacticsNodes) then
        self._TacticsNodes = {}
    end
    local tacticsNodeData = XEscapeTacticsNodeData.New()
    self._TacticsNodes[#self._TacticsNodes + 1] = tacticsNodeData
    tacticsNodeData:UpdateData(data)
end

function XEscapeData:TacticsNodeSelectTactics(tacticsNodeId, tacticsId)
    local data = self:GetTacticsNodeData(tacticsNodeId)
    if not data then
        return
    end
    data:SetSelectTacticsId(tacticsId)
end

function XEscapeData:SetChapterId(chapterId)
    self._ChapterId = chapterId
end

function XEscapeData:SetMaxRemainTime(maxRemainTime)
    self._MaxRemainTime = maxRemainTime
end

function XEscapeData:SetRemainTime(remainTime)
    self._OldRemainTime = self._RemainTime
    self._RemainTime = remainTime
end
--endregion

--region Getter
function XEscapeData:GetScore()
    return self._Score
end

function XEscapeData:GetRemainTime()
    return self._RemainTime
end

function XEscapeData:GetOldRemainTime()
    return self._OldRemainTime
end

function XEscapeData:GetMaxRemainTime()
    return self._MaxRemainTime
end

function XEscapeData:GetChapterId()
    return self._ChapterId
end

function XEscapeData:GetCurLayer()
    local curChapterId = self:GetChapterId()
    if not XTool.IsNumberValid(curChapterId) then
        return false
    end

    local layerIds = XEscapeConfigs.GetChapterLayerIds(curChapterId)
    for _, layerId in ipairs(layerIds) do
        if not self:IsLayerClear(layerId, true) then
            return layerId
        end
    end
    return false
end

function XEscapeData:GetLayerClearNodeCount(layerId, isCurChallengeChapter)
    local stageCount = self:_GetLayerClearStageCount(layerId, isCurChallengeChapter)
    local tacticsCount = self:_GetLayerClearTacticsCount(layerId, isCurChallengeChapter)
    return stageCount + tacticsCount
end

function XEscapeData:_GetLayerClearStageCount(layerId, isCurChallengeChapter)
    local stageIds = XEscapeConfigs.GetLayerStageIds(layerId)
    local count = 0
    if XTool.IsTableEmpty(stageIds) then
        return count
    end
    for _, stageId in ipairs(stageIds) do
        if isCurChallengeChapter then
            count = self:IsCurChapterStageClear(stageId) and count + 1 or count
        elseif self:IsStageClear(stageId) then
            count = count + 1
        end
    end
    return count
end

function XEscapeData:_GetLayerClearTacticsCount(layerId, isCurChallengeChapter)
    local tacticsNodeIds = XEscapeConfigs.GetLayerTacticsNodeIds(layerId)
    local count = 0
    if XTool.IsTableEmpty(tacticsNodeIds) then
        return count
    end
    for _, nodeId in ipairs(tacticsNodeIds) do
        if isCurChallengeChapter then
            count = self:IsCurChapterTacticsNodeClear(nodeId) and count + 1 or count
        end
    end
    return count
end

---@return XEscapeCharacterState
function XEscapeData:GetCharacterState(entityId)
    for _, characterState in ipairs(self._CharacterStates) do
        if characterState:GetCharacterId() == XEntityHelper.GetCharacterIdByEntityId(entityId) then
            return characterState
        end
    end
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

---@return XEscapeChapterResult
function XEscapeData:GetChapterResult(chapterId)
    return self.ChapterResultsDic[chapterId]
end

---@return XEscapeTacticsNodeData
function XEscapeData:GetTacticsNodeData(nodeId)
    if XTool.IsTableEmpty(self._TacticsNodes) then
        return false
    end
    for _, tacticsNode in ipairs(self._TacticsNodes) do
        if nodeId == tacticsNode:GetNodeId() then
            return tacticsNode
        end
    end
    return false
end

---@return XEscapeTactics[]
function XEscapeData:GetCurSelectTactics()
    local result = {}
    for _, tacticsNode in ipairs(self._TacticsNodes) do
        if tacticsNode:GetSelectTactics() then
            result[#result + 1] = tacticsNode:GetSelectTacticsId()
        end
    end
    return XDataCenter.EscapeManager.GetTacticsByList(result)
end

---@return XEscapeTactics[]
function XEscapeData:GetTacticsNodeTacticsList(nodeId)
    if XTool.IsTableEmpty(self._TacticsNodes) then
        return false
    end
    for _, tacticsNode in ipairs(self._TacticsNodes) do
        if nodeId == tacticsNode:GetNodeId() then
            return tacticsNode:GetTacticsList()
        end
    end
    return false
end
--endregion

--region Check
---当前正在进行中的章节，关卡是否通关
function XEscapeData:IsCurChapterStageClear(stageId)
    for _, stageResult in ipairs(self._StageResults) do
        if stageId == stageResult:GetStageId() then
            return true
        end
    end
    return false
end

---当前正在进行中的章节，是否选择策略
function XEscapeData:IsCurChapterTacticsNodeClear(tacticsNodeId)
    for _, tacticsNodeData in ipairs(self._TacticsNodes) do
        if tacticsNodeId == tacticsNodeData:GetNodeId() and tacticsNodeData:IsSelect() then
            return true
        end
    end
    return false
end

---当前正在进行中的章节，策略节点是否被选择
function XEscapeData:IsCurChapterTacticsNodeSelect(layerId, tacticsNodeId)
    for _, tacticsNodeData in ipairs(self._TacticsNodes) do
        if layerId == tacticsNodeData:GetLayerId() and tacticsNodeData:GetNodeId() == tacticsNodeId then
            return true, true
        end
    end
    return false
end

---当前正在进行中的章节是否通关
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
    local clearNodeCount = XEscapeConfigs.GetLayerNodeCount(layerId)
    local clearStageCount = XEscapeConfigs.GetLayerClearStageCount(layerId)
    local stageIds = XEscapeConfigs.GetLayerStageIds(layerId)
    local nodeIds = XEscapeConfigs.GetLayerTacticsNodeIds(layerId)
    for _, stageId in ipairs(stageIds) do
        if isCurChapter then
            if self:IsCurChapterStageClear(stageId) then
                clearNodeCount = clearNodeCount - 1
            end
        elseif self:IsStageClear(stageId) then
            clearStageCount = clearStageCount - 1
        end
    end
    -- 不是挑战中的章节不需要考虑策略节点
    if not isCurChapter then
        return clearStageCount <= 0
    end

    for _, tacticsNodeId in ipairs(nodeIds) do
        if isCurChapter then
            if self:IsCurChapterTacticsNodeClear(tacticsNodeId) then
                clearNodeCount = clearNodeCount - 1
            end
        end
    end
    return clearNodeCount <= 0
end

function XEscapeData:IsStageClear(stageId)
    return self.PassStageIdDic[stageId] or false
end

function XEscapeData:IsInChallengeChapter(chapterId)
    return self:GetChapterId() == chapterId
end

function XEscapeData:IsChapterClear(chapterId)
    local layerIds = XEscapeConfigs.GetChapterLayerIds(chapterId)
    for _, layerId in ipairs(layerIds) do
        if not self:IsLayerClear(layerId) then
            return false
        end
    end
    return true
end
--endregion

return XEscapeData