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

    ---@type XReform2ndEnv[]
    self._EnvGroup = nil
    self._SelectedEnvironmentId = nil
end

function XReform2ndStage:GetId()
    return self._Id
end

function XReform2ndStage:IsExtraStar()
    return self._IsExtraStar
end

function XReform2ndStage:SetExtraStar(value)
    self._IsExtraStar = value
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

function XReform2ndStage:GetDifficultyIndex()
    return 0
end

function XReform2ndStage:SetChapterIndex(chapterIndex, stageIndex)
    self._ChapterIndex = chapterIndex
    self._StageIndex = stageIndex
end

---@param model XReformModel
function XReform2ndStage:GetChapter(model)
    return model:GetChapterByIndex(self._ChapterIndex)
end

function XReform2ndStage:GetStageNumberText()
    return string.format("%s-%s", self._ChapterIndex, self._StageIndex)
end

function XReform2ndStage:GetChapterIndex()
    return self._ChapterIndex
end

---@param model XReformModel
---@return XReform2ndEnv[]
function XReform2ndStage:GetEnvironments(model)
    if self._EnvGroup then
        return self._EnvGroup
    end
    self._EnvGroup = {}
    local difficultyConfig = model:GetStageDifficultyByStage(self:GetId())
    local envGroupId = difficultyConfig.ReformEnv
    local group = model:GetReformEnvGroup(envGroupId)
    local XReform2ndEnv = require("XEntity/XReform2/XReform2ndEnv")
    for i = 1, #group do
        local envId = group[i]
        local environment = XReform2ndEnv.New(envId)
        self._EnvGroup[#self._EnvGroup + 1] = environment
    end
    return self._EnvGroup
end

function XReform2ndStage:GetSelectedEnvironment(model)
    local group = self:GetEnvironments(model)
    for i = 1, 1 do
        local environment = group[i]
        return environment
    end
end

function XReform2ndStage:SetSelectedEnvironmentById(environmentId)
    self._SelectedEnvironmentId = environmentId
end

---@param model XReformModel
function XReform2ndStage:IsHardStage(model)
    local difficulty = model:GetStageGoalDifficultyById(self:GetId())
    return difficulty == XEnumConst.REFORM.DIFFICULTY.HARD
end

return XReform2ndStage
