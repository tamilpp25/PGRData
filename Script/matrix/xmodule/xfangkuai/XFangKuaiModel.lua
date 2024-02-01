---@class XFangKuaiModel : XModel
---@field ActivityData XFangKuaiActivity
local XFangKuaiModel = XClass(XModel, "XFangKuaiModelModel")

local TableKey = {
    FangKuaiActivity = { CacheType = XConfigUtil.CacheType.Normal },
    FangKuaiBlock = {},
    FangKuaiChapter = { CacheType = XConfigUtil.CacheType.Normal },
    FangKuaiCharacter = { DirPath = XConfigUtil.DirectoryType.Client },
    FangKuaiCombo = {},
    FangKuaiStage = { CacheType = XConfigUtil.CacheType.Normal },
    FangKuaiStageBlockRule = {},
    FangKuaiStageEnvironment = {},
    FangKuaiScoreRate = {},
    FangKuaiItem = {},
    FangKuaiNpcAction = { DirPath = XConfigUtil.DirectoryType.Client },
    FangKuaiBrickFace = { DirPath = XConfigUtil.DirectoryType.Client },
    FangKuaiClientConfig = { ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key" },
    FangKuaiBlockTexture = { DirPath = XConfigUtil.DirectoryType.Client },
    FangKuaiBlockPoint = {},
}

function XFangKuaiModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/FangKuai", TableKey)
    self._StageScoreGradeMap = {}
    self._CharacterMap = {}
    self._AllPlayerNpcMap = {}
    self._StageDifficultyMap = {}
end

function XFangKuaiModel:ClearPrivate()
    --这里执行内部数据清理
end

function XFangKuaiModel:ResetAll()
    self.ActivityData = nil
end

----------public start----------

function XFangKuaiModel:CheckTaskRedPoint()
    local taskTimeLimitIds = self:GetActivityConfig(self.ActivityData:GetActivityId()).TaskTimeLimitIds
    for _, taskId in pairs(taskTimeLimitIds) do
        local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId, false)
        for _, taskData in pairs(taskDatas) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end
    return false
end

function XFangKuaiModel:CheckAllChapterRedPoint()
    return self:CheckChapterRedPoint(XEnumConst.FangKuai.Difficulty.Normal) or self:CheckChapterRedPoint(XEnumConst.FangKuai.Difficulty.Hard)
end

function XFangKuaiModel:CheckChapterRedPoint(difficulty)
    local stages = self:GetStagesConfig(difficulty)
    for _, stage in pairs(stages) do
        if self:CheckStageRedPoint(stage.Id) then
            return true
        end
    end
    return false
end

function XFangKuaiModel:CheckStageRedPoint(stageId)
    return self:IsStageUnlock(stageId) and not self:IsStageEnterOnce(stageId)
end

function XFangKuaiModel:CheckChapterChallengeRedPoint(difficulty)
    local stages = self:GetStagesConfig(difficulty)
    for _, stage in pairs(stages) do
        if self:IsStageUnlock(stage.Id) and not self.ActivityData:IsStagePass(stage.Id) then
            return true
        end
    end
    return false
end

function XFangKuaiModel:IsStageUnlock(stageId)
    return self:IsStageTimeUnlock(stageId) and self:IsPreStagePass(stageId)
end

function XFangKuaiModel:IsStageTimeUnlock(stageId)
    local stage = self:GetStageConfig(stageId)
    if XTool.IsNumberValid(stage.TimeId) then
        local time = XFunctionManager.GetStartTimeByTimeId(stage.TimeId) - XTime.GetServerNowTimestamp()
        return XFunctionManager.CheckInTimeByTimeId(stage.TimeId), XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
    end
    return true, ""
end

function XFangKuaiModel:IsPreStagePass(stageId)
    local preStageId = self:GetStageConfig(stageId).PreStageId
    if not XTool.IsNumberValid(preStageId) then
        return true
    end
    return self.ActivityData:IsStagePass(preStageId)
end

function XFangKuaiModel:IsStageEnterOnce(stageId)
    local key = string.format("FangKuaiStageRecord_%s_%s", self.ActivityData:GetActivityId(), stageId)
    return XSaveTool.GetData(key)
end

function XFangKuaiModel:GetProgress()
    local all = 0
    local pass = 0
    ---@type XTableFangKuaiStage[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiStage)
    for _, config in pairs(configs) do
        if self.ActivityData and self.ActivityData:IsStagePass(config.Id) then
            pass = pass + 1
        end
        all = all + 1
    end
    return pass, all
end

----------public end----------

----------private start----------

----------private end----------

----------config start----------

---@return XTableFangKuaiActivity
function XFangKuaiModel:GetActivityConfig(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiActivity, activityId)
end

---@return XTableFangKuaiChapter
function XFangKuaiModel:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiChapter, chapterId)
end

---@return XTableFangKuaiStage
function XFangKuaiModel:GetStageConfig(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiStage, stageId)
end

---@return XTableFangKuaiBlock
function XFangKuaiModel:GetBlockConfig(blockId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiBlock, blockId)
end

---@return XTableFangKuaiItem
function XFangKuaiModel:GetItemConfig(itemId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiItem, itemId)
end

---@return XTableFangKuaiNpcAction
function XFangKuaiModel:GetNpcActionConfig(npcId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiNpcAction, npcId)
end

function XFangKuaiModel:GetBrickFaceConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiBrickFace, id)
end

function XFangKuaiModel:GetEnvironmentConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiStageEnvironment, id)
end

---@return XTableFangKuaiCombo
function XFangKuaiModel:GetComboConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiCombo, id)
end

---@return XTableFangKuaiBlockTexture
function XFangKuaiModel:GetBlockTextureConfig(colorId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiBlockTexture, colorId)
end

function XFangKuaiModel:GetAllColorTextureConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FangKuaiBlockTexture)
end

function XFangKuaiModel:GetClientConfig(key, index)
    index = index or 1
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiClientConfig, key)
    if not config then
        return ""
    end
    return config.Values and config.Values[index] or ""
end

function XFangKuaiModel:GetClientConfigs(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiClientConfig, key)
    if not config then
        return {}
    end
    return config.Values
end

function XFangKuaiModel:GetScoreGrade(stageId, score)
    local index = 1
    if XTool.IsTableEmpty(self._StageScoreGradeMap) then
        self:InitStageScoreGradeMap()
    end
    local datas = self._StageScoreGradeMap[stageId]
    if not XTool.IsTableEmpty(datas) then
        for i, v in ipairs(datas) do
            if score >= v.Score then
                index = i
            end
        end
    end
    return index
end

function XFangKuaiModel:GetScoreGradeConfig(stageId)
    if XTool.IsTableEmpty(self._StageScoreGradeMap) then
        self:InitStageScoreGradeMap()
    end
    return self._StageScoreGradeMap[stageId] or {}
end

function XFangKuaiModel:InitStageScoreGradeMap()
    ---@type XTableFangKuaiScoreRate[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiScoreRate)
    for _, v in pairs(configs) do
        if not self._StageScoreGradeMap[v.StageId] then
            self._StageScoreGradeMap[v.StageId] = {}
        end
        self._StageScoreGradeMap[v.StageId][v.Grade] = v
    end
end

---@return XTableFangKuaiCharacter[]
function XFangKuaiModel:GetAllPlayerNpc()
    return self._ConfigUtil:GetByTableKey(TableKey.FangKuaiCharacter)
end

---@return XTableFangKuaiCharacter
function XFangKuaiModel:GetCharacterByNpcId(npcId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiCharacter, npcId)
end

function XFangKuaiModel:CheckStageDifficulty(activity, stage)
    if XTool.IsTableEmpty(self._StageDifficultyMap) then
        ---@type XTableFangKuaiActivity[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiActivity)
        for _, config in pairs(configs) do
            if not self._StageDifficultyMap[config.Id] then
                self._StageDifficultyMap[config.Id] = {}
            end
            for difficulty, chapterId in ipairs(config.ChapterIds) do
                local chapterConfig = self:GetChapterConfig(chapterId)
                for _, stageId in pairs(chapterConfig.StageIds) do
                    self._StageDifficultyMap[config.Id][stageId] = difficulty
                end
            end
        end
    end
    return self._StageDifficultyMap[activity][stage]
end

function XFangKuaiModel:GetMaxCombo()
    if not XTool.IsNumberValid(self._MaxCombo) then
        self._MaxCombo = 0
        ---@type XTableFangKuaiCombo[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiCombo)
        for _, config in pairs(configs) do
            if self._MaxCombo < config.Id then
                self._MaxCombo = config.Id
            end
        end
    end
    return self._MaxCombo
end

function XFangKuaiModel:GetStagesConfig(difficulty)
    local activity = self:GetActivityConfig(self.ActivityData:GetActivityId())
    local chapterId = activity.ChapterIds[difficulty]
    local chapter = self:GetChapterConfig(chapterId)
    local stages = {}
    for _, stageId in pairs(chapter.StageIds) do
        local stage = self:GetStageConfig(stageId)
        table.insert(stages, stage)
    end
    return stages
end

function XFangKuaiModel:GetBlockPoint(blockType, blockLen)
    if not self._PointMap then
        self._PointMap = {}
        local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiBlockPoint)
        for _, config in pairs(configs) do
            if not self._PointMap[config.BlockType] then
                self._PointMap[config.BlockType] = {}
            end
            self._PointMap[config.BlockType][config.BlockLength] = config.Point
        end
    end
    if not self._PointMap[blockType] or not self._PointMap[blockType][blockLen] then
        XLog.Error(string.format("FangKuaiBlockPoint找不到分数配置 type=%s length=%s", blockType, blockLen))
        return 0
    end
    return self._PointMap[blockType][blockLen]
end

function XFangKuaiModel:GetStageColorIds(stageId)
    if not self._ColorMap then
        self._ColorMap = {}
        ---@type XTableFangKuaiBlock[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiBlock)
        for _, config in pairs(configs) do
            if config.Type == 1 then
                if not self._ColorMap[config.StageId] then
                    self._ColorMap[config.StageId] = {}
                end
                for _, colorId in pairs(config.Colors) do
                    table.insert(self._ColorMap[config.StageId], colorId)
                end
            end
        end
        for _, datas in pairs(self._ColorMap) do
            table.sort(datas)
        end
    end
    return self._ColorMap[stageId]
end

----------config end----------

--region 服务端信息更新和获取

function XFangKuaiModel:NotifyFangKuaiData(data)
    if not data or not XTool.IsNumberValid(data.ActivityId) then
        return
    end
    if not self.ActivityData then
        self.ActivityData = require("XModule/XFangKuai/XEntity/XFangKuaiActivity").New()
    end
    self.ActivityData:NotifyFangKuaiData(data)
end

--endregion

return XFangKuaiModel