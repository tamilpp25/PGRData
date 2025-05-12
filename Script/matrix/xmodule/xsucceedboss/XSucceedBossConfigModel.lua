---@class XSucceedBossConfigModel : XModel
local XSucceedBossConfigModel = XClass(XModel, "XSucceedBossConfigModel")

local TableKey = {
    SucceedBossActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal },
    SucceedBossChapter = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
    SucceedBossElement = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
    SucceedBossMonster = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
    SucceedBossMonsterGroup = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
    SucceedBossMonsterLevel = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
    SucceedBossFightEventShow = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal, Identifier = "FightEventId" },
    SucceedBossCharacterBuff = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
}

function XSucceedBossConfigModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/SucceedBoss", TableKey)
    self.CharacterBuffAnalyzeTable = {}
    self.MonsterLevelAnalyzeConfigTable = {}
end

--region SucceedBossActivity
---@return table<number, table>
function XSucceedBossConfigModel:GetSucceedBossActivityConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.SucceedBossActivity)
end

---@return table
function XSucceedBossConfigModel:GetSucceedBossActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossActivity, id)
end

---@return number
function XSucceedBossConfigModel:GetSucceedBossActivityTimeId(id)
    local cfg = self:GetSucceedBossActivityById(id)
    if not cfg then
        return
    end
    return cfg.TimeId
end

---@return string Name
function XSucceedBossConfigModel:GetSucceedBossActivityName(id)
    local cfg = self:GetSucceedBossActivityById(id)
    if not cfg then
        return
    end
    return cfg.Name
end

---@return number[]
function XSucceedBossConfigModel:GetSucceedBossActivityChapterIds(id)
    local cfg = self:GetSucceedBossActivityById(id)
    if not cfg then
        return
    end
    return cfg.ChapterIds
end
--endregion

--region SucceedBossChapter
---@return table<number, table>
function XSucceedBossConfigModel:GetSucceedBossChapterById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossChapter, id)
end

---@return number
function XSucceedBossConfigModel:GetSucceedBossChapterTimeId(chapterId)
    local cfg = self:GetSucceedBossChapterById(chapterId)
    if not cfg then
        return
    end
    return cfg.TimeId
end

---@return number XEnumConst.SucceedBoss.ChapterType 1:普通 2:凹分
function XSucceedBossConfigModel:GetSucceedBossChapterType(chapterId)
    local cfg = self:GetSucceedBossChapterById(chapterId)
    if not cfg then
        return
    end
    return cfg.Type
end

---@return number
function XSucceedBossConfigModel:GetSucceedBossChapterPreChapter(chapterId)
    local cfg = self:GetSucceedBossChapterById(chapterId)
    if not cfg then
        return
    end
    return cfg.PreChapter
end

---@return number[]
function XSucceedBossConfigModel:GetSucceedBossChapterMonsterGroupIds(chapterId)
    local cfg = self:GetSucceedBossChapterById(chapterId)
    if not cfg then
        return
    end
    return cfg.MonsterGroupIds
end
--endregion

--region SucceedBossElement
function XSucceedBossConfigModel:GetSucceedBossElements()
    return self._ConfigUtil:GetByTableKey(TableKey.SucceedBossElement)
end

---@return table<number, table>
function XSucceedBossConfigModel:GetSucceedBossElementById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossElement, id)
end

---@return string
function XSucceedBossConfigModel:GetSucceedBossElementName(elementId)
    local cfg = self:GetSucceedBossElementById(elementId)
    if not cfg then
        return
    end

    if not string.IsNilOrEmpty(cfg.Name) then
        return cfg.Name
    else
        if XTool.IsNumberValid(cfg.FightEventId) then
            return self:GetFightEventName(cfg.FightEventId)
        end
    end

    return ""
end

---@return number[]
function XSucceedBossConfigModel:GetSucceedBossElementFightEventId(elementId)
    local cfg = self:GetSucceedBossElementById(elementId)
    if not cfg then
        return
    end
    return cfg.FightEventId
end

---@return string
function XSucceedBossConfigModel:GetSucceedBossElementDesc(elementId)
    local cfg = self:GetSucceedBossElementById(elementId)
    if not cfg then
        return
    end

    if not string.IsNilOrEmpty(cfg.Desc) then
        return cfg.Desc
    else
        if XTool.IsNumberValid(cfg.FightEventId) then
            return self:GetFightEventDesc(cfg.FightEventId)
        end
    end

    return ""
end

---@return string
function XSucceedBossConfigModel:GetSucceedBossElementIcon(elementId)
    local cfg = self:GetSucceedBossElementById(elementId)
    if not cfg then
        return
    end

    if not string.IsNilOrEmpty(cfg.Icon) then
        return cfg.Icon
    else
        if XTool.IsNumberValid(cfg.FightEventId) then
            return self:GetFightEventIcon(cfg.FightEventId)
        end
    end

    return ""
end
--endregion

--region SucceedBossMonster
---@return table<number, table>
function XSucceedBossConfigModel:GetSucceedBossMonsterById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossMonster, id)
end

---@return number
function XSucceedBossConfigModel:GetSucceedBossMonsterNpcId(monsterId)
    local cfg = self:GetSucceedBossMonsterById(monsterId)
    if not cfg then
        return
    end
    return cfg.NpcId
end

---@return string
function XSucceedBossConfigModel:GetSucceedBossMonsterName(monsterId)
    local cfg = self:GetSucceedBossMonsterById(monsterId)
    if not cfg then
        return
    end
    return cfg.Name
end

---@return number StageId
function XSucceedBossConfigModel:GetSucceedBossMonsterStageId(monsterId)
    local cfg = self:GetSucceedBossMonsterById(monsterId)
    if not cfg then
        return
    end
    return cfg.StageId
end

---@return number SkillFightEventId
function XSucceedBossConfigModel:GetSucceedBossMonsterSkillFightEventId(monsterId)
    local cfg = self:GetSucceedBossMonsterById(monsterId)
    if not cfg then
        return
    end
    return cfg.SkillFightEventId
end

---@return number BuffFightEventId
function XSucceedBossConfigModel:GetSucceedBossMonsterBuffFightEventId(monsterId)
    local cfg = self:GetSucceedBossMonsterById(monsterId)
    if not cfg then
        return
    end
    return cfg.BuffFightEventId
end

---@return number DefaultUnlockLevel
function XSucceedBossConfigModel:GetSucceedBossMonsterDefaultUnlockLevel(monsterId)
    local cfg = self:GetSucceedBossMonsterById(monsterId)
    if not cfg then
        return
    end
    return cfg.DefaultUnlockLevel
end
--endregion

--region SucceedBossMonsterGroup
---@return table<number, table>
function XSucceedBossConfigModel:GetSucceedBossMonsterGroupById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossMonsterGroup, id)
end

---@return number[] MonsterIds
function XSucceedBossConfigModel:GetSucceedBossMonsterGroupMonsterIds(groupId)
    local cfg = self:GetSucceedBossMonsterGroupById(groupId)
    if not cfg then
        return
    end
    return cfg.MonsterIds
end
--endregion

--region SucceedBossMonsterLevel
---@return table<number, table>
function XSucceedBossConfigModel:GetSucceedBossMonsterLevels()
    return self._ConfigUtil:GetByTableKey(TableKey.SucceedBossMonsterLevel)
end

function XSucceedBossConfigModel:InitSucceedBossMonsterLevelConfig()
    if XTool.IsTableEmpty(self.MonsterLevelAnalyzeConfigTable) then
        local monsterLevels = self:GetSucceedBossMonsterLevels()
        for _, v in pairs(monsterLevels) do
            if not self.MonsterLevelAnalyzeConfigTable[v.MonsterId] then
                self.MonsterLevelAnalyzeConfigTable[v.MonsterId] = {}
            end
            self.MonsterLevelAnalyzeConfigTable[v.MonsterId][v.Level] = v
        end
    end
end

function XSucceedBossConfigModel:GetSucceedBossMonsterLevelConfigByIdAndLevel(monsterId, level)
    self:InitSucceedBossMonsterLevelConfig()
    if not self.MonsterLevelAnalyzeConfigTable[monsterId] then
        return
    end
    
    return self.MonsterLevelAnalyzeConfigTable[monsterId][level]
end

function XSucceedBossConfigModel:GetSucceedBossMonsterLevelConfigById(monsterId)
    self:InitSucceedBossMonsterLevelConfig()
    return self.MonsterLevelAnalyzeConfigTable[monsterId]
end

---@return number MonsterScore
function XSucceedBossConfigModel:GetSucceedBossMonsterLevelMonsterScore(monsterId, level)
    local cfg = self:GetSucceedBossMonsterLevelConfigByIdAndLevel(monsterId, level)
    if not cfg then
        return
    end
    return cfg.MonsterScore
end

---@return number SweepScore
function XSucceedBossConfigModel:GetSucceedBossMonsterLevelSweepScore(monsterId, level)
    local cfg = self:GetSucceedBossMonsterLevelConfigByIdAndLevel(monsterId, level)
    if not cfg then
        return
    end
    return cfg.SweepScore
end

-----@return number MonsterAtk
--function XSucceedBossConfigModel:GetSucceedBossMonsterLevelMonsterAtk(levelId)
--    local cfg = self:GetSucceedBossMonsterLevelById(levelId)
--    if not cfg then
--        return
--    end
--    return cfg.MonsterAtk
--end
--
-----@return number MonsterHp
--function XSucceedBossConfigModel:GetSucceedBossMonsterLevelMonsterHp(levelId)
--    local cfg = self:GetSucceedBossMonsterLevelById(levelId)
--    if not cfg then
--        return
--    end
--    return cfg.MonsterHp
--end

---@return number FightEventId
function XSucceedBossConfigModel:GetSucceedBossMonsterLevelFightEventId(monsterId, level)
    local cfg = self:GetSucceedBossMonsterLevelConfigByIdAndLevel(monsterId, level)
    if not cfg then
        return
    end
    return cfg.FightEventId
end
--endregion

--region SucceedBossFightEventShow
function XSucceedBossConfigModel:GetAllFightEventShowConfig()
    return self._ConfigUtil:GetByTableKey(TableKey.SucceedBossFightEventShow)
end

function XSucceedBossConfigModel:GetFightEventShowConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossFightEventShow, id)
end

function XSucceedBossConfigModel:GetFightEventName(fightEventId)
    local cfg = self:GetFightEventShowConfigById(fightEventId)
    if not cfg then
        return
    end
    return cfg.Name
end

function XSucceedBossConfigModel:GetFightEventIcon(fightEventId)
    local cfg = self:GetFightEventShowConfigById(fightEventId)
    if not cfg then
        return
    end
    return cfg.Icon
end

function XSucceedBossConfigModel:GetFightEventDesc(fightEventId)
    local cfg = self:GetFightEventShowConfigById(fightEventId)
    if not cfg then
        return
    end
    return cfg.Desc
end

--endregion

--region SucceedBossCharacterBuff

function XSucceedBossConfigModel:GetSucceedBossCharacterBuffs()
    return self._ConfigUtil:GetByTableKey(TableKey.SucceedBossCharacterBuff)
end

function XSucceedBossConfigModel:GetSucceedBossCharacterBuffById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SucceedBossCharacterBuff, id)
end

function XSucceedBossConfigModel:GetSucceedBossCharacterBuffFightEventId(elementId, careerId)
    if XTool.IsTableEmpty(self.CharacterBuffAnalyzeTable) then
        local characterBuffs = self:GetSucceedBossCharacterBuffs()
        for _, v in pairs(characterBuffs) do
            local element = v.CharacterElement
            local career = v.CharacterCareer
            if not self.CharacterBuffAnalyzeTable[element] then
                self.CharacterBuffAnalyzeTable[element] = {}
            end
            self.CharacterBuffAnalyzeTable[element][career] = v.FightEventId
        end
    end
    
    if not self.CharacterBuffAnalyzeTable[elementId] then
        return
    end
    
    return self.CharacterBuffAnalyzeTable[elementId][careerId]
end

--endregion

function XSucceedBossConfigModel:GetCharacterElementId(elementConfigId)
    local cfg = self:GetSucceedBossElementById(elementConfigId)
    if not cfg then
        return false
    end
    return cfg.ElementId
end

return XSucceedBossConfigModel