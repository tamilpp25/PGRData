local type = type
local pairs = pairs

local XMonsterCombatStage = require("XEntity/XMonsterCombat/XMonsterCombatStage")
local XMonsterCombatFormation = require("XEntity/XMonsterCombat/XMonsterCombatFormation")

--[[
public class NotifyMonsterCombatData
{
    // 活动id
    public int ActivityId;
    // 已通关关卡
    public List<XMonsterCombatStage> PassStages = new List<XMonsterCombatStage>();
    // 已通关章节
    public HashSet<int> PassChapters = new HashSet<int>();
    // 已解锁怪物
    public HashSet<int> UnlockMonsters = new HashSet<int>();
    // 章节阵容
    public List<XMonsterCombatFormation> ChapterFormations = new List<XMonsterCombatFormation>();
}
]]

local Default = {
    _ActivityId = 0, -- 活动Id
    _PassStages = {}, -- 已通关关卡
    _PassChapters = {}, -- 已通关章节
    _UnlockMonsters = {}, -- 已解锁怪物
    _ChapterFormations = {}, -- 章节阵容
}

---@class XMonsterCombat
---@field _ActivityId number 活动Id
---@field _PassStages table<number, XMonsterCombatStage> 已通关关卡
---@field _PassChapters table<number, number> 已通关章节
---@field _UnlockMonsters table<number, number> 已解锁怪物
---@field _ChapterFormations table<number, XMonsterCombatFormation> 章节阵容
local XMonsterCombat = XClass(nil, "XMonsterCombat")

function XMonsterCombat:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if data then
        self:UpdateData(data)
    end
end

function XMonsterCombat:UpdateData(data)
    self._ActivityId = data.ActivityId
    self._PassStages = {}
    for _, passStage in pairs(data.PassStages) do
        self:UpdatePassStage(passStage)
    end
    self._PassChapters = {}
    for _, chapterId in pairs(data.PassChapters) do
        self:UpdatePassChapter(chapterId)
    end
    self._UnlockMonsters = {}
    for _, monsterId in pairs(data.UnlockMonsters) do
        self:UpdateUnlockMonster(monsterId)
    end
    self._ChapterFormations = {}
    for _, chapterFormation in pairs(data.ChapterFormations) do
        self:UpdateChapterFormation(chapterFormation)
    end
end

function XMonsterCombat:UpdatePassStage(data)
    local stageId = data.StageId
    local passStage = self._PassStages[stageId]
    if not passStage then
        passStage = XMonsterCombatStage.New()
        self._PassStages[stageId] = passStage
    end
    passStage:UpdateData(data)
end

function XMonsterCombat:UpdatePassChapter(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    self._PassChapters[chapterId] = chapterId
end

function XMonsterCombat:UpdateUnlockMonster(monsterId)
    if not XTool.IsNumberValid(monsterId) then
        return
    end
    self._UnlockMonsters[monsterId] = monsterId
end

function XMonsterCombat:UpdateChapterFormation(data)
    local chapterId = data.ChapterId
    local chapterFormation = self._ChapterFormations[chapterId]
    if not chapterFormation then
        chapterFormation = XMonsterCombatFormation.New()
        self._ChapterFormations[chapterId] = chapterFormation
    end
    chapterFormation:UpdateData(data)
end

function XMonsterCombat:GetActivityId()
    return self._ActivityId
end

-- 获取关卡最大分数
function XMonsterCombat:GetStageMaxScore(stageId)
    local passStage = self._PassStages[stageId]
    if passStage then
        return passStage:GetMaxScore()
    end
    return 0
end

-- 获取编队角色Id
function XMonsterCombat:GetFormationEntityId(chapterId)
    local chapterFormation = self._ChapterFormations[chapterId]
    if not chapterFormation then
        return 0
    end
    local entityId = 0
    local characterId = chapterFormation:GetCharacterId()
    if XTool.IsNumberValid(characterId) then
        entityId = characterId
    end
    local robotId = chapterFormation:GetRobotId()
    if XTool.IsNumberValid(robotId) then
        entityId = robotId
    end
    return entityId
end

-- 获取编队怪物
function XMonsterCombat:GetFormationMonsters(chapterId)
    local chapterFormation = self._ChapterFormations[chapterId]
    if not chapterFormation then
        return {}
    end
    return chapterFormation:GetMonsterIds()
end

-- 获取所有解锁怪物
function XMonsterCombat:GetAllUnlockMonsters()
    return self._UnlockMonsters
end

-- 检查章节是否通关
function XMonsterCombat:CheckChapterPass(chapterId)
    return self._PassChapters[chapterId] and true or false
end

-- 检查关卡是否通关
function XMonsterCombat:CheckStagePass(stageId)
    return self._PassStages[stageId] and true or false
end

-- 检查怪物是否解锁
function XMonsterCombat:CheckMonsterUnlock(monsterId)
    return self._UnlockMonsters[monsterId] and true or false
end

return XMonsterCombat