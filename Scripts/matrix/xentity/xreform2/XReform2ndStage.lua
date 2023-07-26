local XReform2ndMobGroup = require("XEntity/XReform2/XReform2ndMobGroup")

---@class XReform2ndStage
local XReform2ndStage = XClass(nil, "XReform2ndStage")

function XReform2ndStage:Ctor(id)
    self._Id = id

    ---@type XReform2ndMobGroup[]
    self._MobGroupList = false
    self._StarAmountMax = 4
    self._StarHistory = 0
    self._IsSelect = false
    self._IsPassed = false
    self._IsExtraStar = false

    self._ChapterIndex = 0
    self._StageIndex = 0
end

function XReform2ndStage:GetId()
    return self._Id
end

function XReform2ndStage:GetName()
    return XReform2ndConfigs.GetStageName(self._Id)
end

function XReform2ndStage:IsExtraStar()
    return self._IsExtraStar
end

function XReform2ndStage:SetExtraStar(value)
    self._IsExtraStar = value
end

function XReform2ndStage:GetStar(pressure)
    pressure = pressure or self:GetPressure()
    return XReform2ndConfigs.GetStarByPressure(pressure, self:GetId())
end

function XReform2ndStage:GetPressureByStar(star)
    return XReform2ndConfigs.GetPressureByStar(star, self:GetId())
end

function XReform2ndStage:GetStarMax(isHardMode)
    if isHardMode == nil then
        isHardMode = self:GetIsUnlockedDifficulty()
    end
    return XReform2ndConfigs.GetStarMax(isHardMode)
end

function XReform2ndStage:GetPressure()
    local pressure = 0
    local list = self:GetMonsterGroup()
    for i = 1, #list do
        local group = list[i]
        pressure = pressure + group:GetPressure()
    end
    return pressure
end

function XReform2ndStage:GetPressureMax()
    if self:GetIsUnlockedDifficulty() then
        return XReform2ndConfigs.GetStagePressureHard(self._Id)
    end
    return XReform2ndConfigs.GetStagePressureEasy(self._Id)
end

---@return XReform2ndMobGroup[]
function XReform2ndStage:GetMonsterGroup()
    if not self._MobGroupList then
        local groupList = XReform2ndConfigs.GetStageMobGroup(self._Id)
        self._MobGroupList = {}
        for i = 1, #groupList do
            local data = groupList[i]
            local group = data.MobArray
            ---@type XReform2ndMobGroup
            local mobGroup = XReform2ndMobGroup.New(self, group, i, data.MobAmount)
            local mobGroupId = data.MobGroupId
            mobGroup:SetGroupId(mobGroupId)
            local mobSourceId = data.MobSourceId
            mobGroup:SetSourceId(mobSourceId)
            self._MobGroupList[#self._MobGroupList + 1] = mobGroup
        end
    end
    return self._MobGroupList
end

---@return XReform2ndMobGroup
function XReform2ndStage:GetMonsterGroupByIndex(index)
    local group = self:GetMonsterGroup()[index]
    return group
end

---@return XReform2ndMobGroup
function XReform2ndStage:GetMonsterGroupByGroupId(groupId)
    local groupList = self:GetMonsterGroup()
    for i = 1, #groupList do
        local group = groupList[i]
        if group:GetGroupId() == groupId then
            return group
        end
    end
    return false
end

function XReform2ndStage:GetRecommendCharacters()
    return XReform2ndConfigs.GetStageRecommendCharacterIds(self._Id)
end

function XReform2ndStage:GetUnlockStageId()
    return XReform2ndConfigs.GetStageUnlockStageIdById(self._Id)
end

function XReform2ndStage:GetOpenTime()
    return XReform2ndConfigs.GetStageOpenTimeById(self._Id)
end

function XReform2ndStage:GetFullPoint()
    return XReform2ndConfigs.GetStageFullPointById(self._Id)
end

function XReform2ndStage:GetGoalDesc()
    return XReform2ndConfigs.GetStageGoalDescById(self._Id)
end

function XReform2ndStage:GetCharacterGroupId()
    return XReform2ndConfigs.GetStageRecommendCharacterGroupIdById(self._Id)
end

function XReform2ndStage:SetId(id)
    self._Id = id
end

-- include extra star
function XReform2ndStage:GetStarHistory(includeExtraStar)
    if includeExtraStar == nil then
        includeExtraStar = true
    end
    if includeExtraStar and self:IsExtraStar() then
        return self._StarHistory + 1
    end
    return self._StarHistory
end

function XReform2ndStage:SetStarHistory(starNumber)
    self._StarHistory = starNumber
end

function XReform2ndStage:GetIsSelect()
    return self._IsSelect
end

function XReform2ndStage:SetIsSelect(isSelect)
    self._IsSelect = isSelect
end

function XReform2ndStage:GetIsPassed()
    return self._IsPassed
end

function XReform2ndStage:SetIsPassed(isPassed)
    self._IsPassed = isPassed
end

function XReform2ndStage:GetIsUnlockedDifficulty()
    return self._StarHistory >= XReform2ndConfigs.GetStarHardMode()
end

function XReform2ndStage:GetDifficultyIndex()
    return 0
end

function XReform2ndStage:IsOverPressure(pressure)
    pressure = pressure or 0
    return self:GetPressure() + pressure > self:GetPressureMax()
end

function XReform2ndStage:IsFullPressure()
    return self:GetPressure() >= self:GetPressureMax()
end

function XReform2ndStage:SetChapterIndex(chapterIndex, stageIndex)
    self._ChapterIndex = chapterIndex
    self._StageIndex = stageIndex
end

function XReform2ndStage:GetChapter()
    return XDataCenter.Reform2ndManager.GetChapterByIndex(self._ChapterIndex)
end

function XReform2ndStage:GetStageNumberText()
    return string.format("%s-%s", self._ChapterIndex, self._StageIndex)
end

function XReform2ndStage:GetChapterIndex()
    return self._ChapterIndex
end

return XReform2ndStage
