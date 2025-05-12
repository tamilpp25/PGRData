local XCoupleCombatStageData = require("XEntity/XCoupleCombat/XCoupleCombatStageData")

local type = type
local pairs = pairs
local ipairs = ipairs

local Default = {
    _ActivityId = 0,       --活动id
    _Stages = {},          --关卡数据列表
    _UsedSkillIds = {},    --正在使用的职业技能id集合
    _UnlockChapterIds = {}, --已解锁的章节id字典
}

--基础数据
local XCoupleCombatBaseData = XClass(nil, "XCoupleCombatBaseData")

local SetCharacterRecordDic = function(characterRecordDic, stageId, characterIds)
    local chapterId = XFubenCoupleCombatConfig.GetChapterIdByStageId(stageId)
    if not chapterId then
        return
    end

    if not characterRecordDic[chapterId] then
        characterRecordDic[chapterId] = {}
    end

    for _, characterId in ipairs(characterIds) do
        characterId = XRobotManager.GetCharacterId(characterId)
        characterRecordDic[chapterId][characterId] = true
    end
end

function XCoupleCombatBaseData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.CharacterRecordDic = {}    --已使用的角色字典
    self.AleardyActiveCharacterCareerSkillIdDic = {}   --已激活的职业技能Id字典
    self.UsedSkillTypeToSkillIdDic = {} --使用中的技能类型对应的技能Id
end

function XCoupleCombatBaseData:SetActiveCharacterCareerSkill(skillId)
    self.AleardyActiveCharacterCareerSkillIdDic[skillId] = true
end

--检查是否有已激活的职业技能没保存到字典中
function XCoupleCombatBaseData:CheckCharacterCareerSkillInDic()
    local activeSkillList = {}
    local skillGroupTypeToSkillIdsMap = XFubenCoupleCombatConfig.GetSkillGroupTypeToSkillIdsMap()
    local condition
    local isFinish
    for _, skillIds in pairs(skillGroupTypeToSkillIdsMap) do
        for _, skillId in ipairs(skillIds) do
            condition = XFubenCoupleCombatConfig.GetCharacterCareerSkillCondition(skillId)
            isFinish = not XTool.IsNumberValid(condition) and true or XConditionManager.CheckCondition(condition)
            if isFinish and not self:IsActiveCharacterCareerSkill(skillId) then
                table.insert(activeSkillList, skillId)
                self:SetActiveCharacterCareerSkill(skillId)
            end
        end
    end

    return activeSkillList
end

function XCoupleCombatBaseData:IsActiveCharacterCareerSkill(skillId)
    return self.AleardyActiveCharacterCareerSkillIdDic[skillId] or false
end

function XCoupleCombatBaseData:UpdateData(data)
    self.CharacterRecordDic = {}
    self._ActivityId = data.ActivityId
    self:UpdateUsedSkillIds(data.UsedSkillIds)
    self:UpdateUnlockChapterIds(data.UnlockChapterIds)

    for _, v in pairs(data.Stages) do
        local stageData = self:GetStageData(v.StageId)
        if not stageData then
            stageData = XCoupleCombatStageData.New()
            self._Stages[v.StageId] = stageData
        end
        stageData:UpdateData(v)

        SetCharacterRecordDic(self.CharacterRecordDic, v.StageId, v.CharacterIds)
    end
end

function XCoupleCombatBaseData:UpdateUnlockChapterIds(unlockChapterIds)
    for _, chapterId in ipairs(unlockChapterIds or {}) do
        self._UnlockChapterIds[chapterId] = true
    end
end

function XCoupleCombatBaseData:UpdateStageData(data)
    local stageId = data.StageId
    local stageData = self:GetStageData(stageId)
    if not stageData then
        stageData = XCoupleCombatStageData.New()
        self._Stages[stageId] = stageData
    end
    stageData:UpdateData(data)

    SetCharacterRecordDic(self.CharacterRecordDic, stageId, data.CharacterIds)
end

function XCoupleCombatBaseData:UpdateUsedSkillIds(usedSkillIds)
    self._UsedSkillIds = usedSkillIds

    self.UsedSkillTypeToSkillIdDic = {}
    local skillType
    for _, skillId in ipairs(usedSkillIds) do
        skillType = XFubenCoupleCombatConfig.GetCharacterCareerSkillType(skillId)
        for _, type in ipairs(skillType) do
            self.UsedSkillTypeToSkillIdDic[type] = skillId
        end
    end
end

function XCoupleCombatBaseData:ResetStage(stageId)
    local characterIds = XTool.Clone(self:GetCharacterIds(stageId))

    local stageData = self:GetStageData(stageId)
    if not stageData then
        stageData = XCoupleCombatStageData.New()
        self._Stages[stageId] = stageData
    end
    stageData:ResetMember()

    local chapterId = XFubenCoupleCombatConfig.GetChapterIdByStageId(stageId)
    if not self.CharacterRecordDic[chapterId] then
        return
    end

    for _, characterId in ipairs(characterIds) do
        characterId = XRobotManager.GetCharacterId(characterId)
        if self.CharacterRecordDic[chapterId][characterId] then
            self.CharacterRecordDic[chapterId][characterId] = nil
        end
    end
end

function XCoupleCombatBaseData:GetStageData(stageId)
    return self._Stages[stageId]
end

function XCoupleCombatBaseData:GetCharacterIds(stageId)
    local stageData = self:GetStageData(stageId)
    return stageData and stageData:GetCharacterIds() or {}
end

function XCoupleCombatBaseData:IsCharacterUsed(stageId, charId)
    local chapterId = XFubenCoupleCombatConfig.GetChapterIdByStageId(stageId)
    if not self.CharacterRecordDic[chapterId] then
        return false
    end

    charId = XRobotManager.GetCharacterId(charId)
    return self.CharacterRecordDic[chapterId][charId] or false
end

function XCoupleCombatBaseData:GetUsedSkillIds()
    return self._UsedSkillIds
end

function XCoupleCombatBaseData:GetUsedSkillIdBySkillType(skillType)
    return self.UsedSkillTypeToSkillIdDic[skillType]
end

--关卡是否已使用角色上阵
function XCoupleCombatBaseData:IsStageUsedCharacter(stageId)
    local characterIds = self:GetCharacterIds(stageId)
    return not XTool.IsTableEmpty(characterIds)
end

function XCoupleCombatBaseData:IsUnlockChapter(chapterId)
    local unlockChapterId = XFubenCoupleCombatConfig.GetChapterUnlockChapterId(chapterId)
    local stageCount = XFubenCoupleCombatConfig.GetChapterUnlockOccupyStageCount(chapterId)
    if not XTool.IsNumberValid(unlockChapterId) or not XTool.IsNumberValid(stageCount) then
        return true
    end
    return self._UnlockChapterIds[chapterId] or false
end

return XCoupleCombatBaseData