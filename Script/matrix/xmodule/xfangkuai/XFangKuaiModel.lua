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
    FangKuaiBlockPoint = { CacheType = XConfigUtil.CacheType.Normal },
    FangKuaiStageBlockRule = {},
    FangKuaiStageItemRule = {},
    FangKuaiDropBlock = {},
    FangKuaiStageGroup = { CacheType = XConfigUtil.CacheType.Normal },
}

function XFangKuaiModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/FangKuai", TableKey)
    self._StageScoreGradeMap = {}
    self._CharacterMap = {}
    self._AllPlayerNpcMap = {}
    self._StageDifficultyMap = {}
end

function XFangKuaiModel:ClearPrivate()
    self._BlockTemplateMap = nil
    self._StageIdChapterIdMap = nil
    self._StageIdBlockRuleExpandMap = nil
    self._StageIdBlockRuleLoopMap = nil
    self._StageIdItemRuleExpand = nil
    self._CurFightChapterId = nil
    self._CurStageId = nil
end

function XFangKuaiModel:ResetAll()
    self.ActivityData = nil
    self._StageGroupTabIdxMap = nil
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
    local configs = self:GetChapterConfigs()
    for _, config in pairs(configs) do
        if self:CheckChapterRedPoint(config.Id) then
            return true
        end
    end
    return false
end

function XFangKuaiModel:CheckChapterRedPoint(chapterId)
    local config = self:GetChapterConfig(chapterId)
    for _, StageGroupId in pairs(config.StageGroupIds) do
        if self:CheckStageGroupRedPoint(StageGroupId) then
            return true
        end
    end
    return false
end

function XFangKuaiModel:CheckStageGroupRedPoint(StageGroupId)
    local config = self:GetStageGroupConfig(StageGroupId)
    local stageId = XTool.IsNumberValid(config.SimpleStageId) and config.SimpleStageId or config.DiffcultStageId
    if not self:IsStageGroupTimeUnlock(StageGroupId) or not self:IsStageUnlock(stageId) then
        return false
    end
    return not self:IsStageGroupEnterOnce(StageGroupId) or self:CheckStageRedPoint(config.DiffcultStageId)
end

function XFangKuaiModel:CheckChapterChallengeRedPoint()
    local chapters = self:GetChapterConfigs()
    for _, chapter in pairs(chapters) do
        for _, StageGroupId in pairs(chapter.StageGroupIds) do
            if self:IsStageGroupTimeUnlock(StageGroupId) then
                local stageGroup = self:GetStageGroupConfig(StageGroupId)
                if self:CheckStageChallengeRedPoint(stageGroup.DiffcultStageId) or self:CheckStageChallengeRedPoint(stageGroup.SimpleStageId) then
                    return true
                end
            end
        end
    end
    return false
end

---关卡解锁并且还没进入过
function XFangKuaiModel:CheckStageRedPoint(stageId)
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    return self:IsStageUnlock(stageId) and not self:IsStageEnterOnce(stageId)
end

---关卡解锁并且还没通关
function XFangKuaiModel:CheckStageChallengeRedPoint(stageId)
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    return self:IsStageUnlock(stageId) and not self.ActivityData:IsStagePass(stageId)
end

function XFangKuaiModel:IsStageUnlock(stageId)
    if not XTool.IsNumberValid(stageId) then
        return true
    end
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

function XFangKuaiModel:IsStageGroupTimeUnlock(stageGroupId)
    local stageGroup = self:GetStageGroupConfig(stageGroupId)
    if XTool.IsNumberValid(stageGroup.TimeId) then
        local time = XFunctionManager.GetStartTimeByTimeId(stageGroup.TimeId)
        return XFunctionManager.CheckInTimeByTimeId(stageGroup.TimeId), self:GetTimeStr(time)
    end
    return true, ""
end

function XFangKuaiModel:IsChapterTimeUnlock(chapterId)
    local minUnlockTime = XMath.IntMax()
    local chapter = self:GetChapterConfig(chapterId)
    for _, id in pairs(chapter.StageGroupIds) do
        local stageGroup = self:GetStageGroupConfig(id)
        if XTool.IsNumberValid(stageGroup.TimeId) and not XFunctionManager.CheckInTimeByTimeId(stageGroup.TimeId) then
            minUnlockTime = math.min(minUnlockTime, XFunctionManager.GetStartTimeByTimeId(stageGroup.TimeId))
        else
            return true, ""
        end
    end
    return false, self:GetTimeStr(minUnlockTime)
end

function XFangKuaiModel:GetTimeStr(timestamp)
    local dt = CS.XDateUtil.GetLocalDateTime(timestamp)
    return string.format("%d%s%d%s", dt.Month, XUiHelper.GetText("Monthly"), dt.Day, XUiHelper.GetText("Diary"))
end

function XFangKuaiModel:IsPreStagePass(stageId)
    local preStageId = self:GetStageConfig(stageId).PreStageId
    if not XTool.IsNumberValid(preStageId) then
        return true
    end
    return self.ActivityData:IsStagePass(preStageId)
end

function XFangKuaiModel:IsStageEnterOnce(stageId)
    local key = string.format("FangKuaiStageRecord_%s_%s_%s", self.ActivityData:GetActivityId(), stageId, XPlayer.Id)
    return XSaveTool.GetData(key)
end

function XFangKuaiModel:IsStageGroupEnterOnce(stageGroupId)
    local key = string.format("FangKuaiStageGroupRecord_%s_%s_%s", self.ActivityData:GetActivityId(), stageGroupId, XPlayer.Id)
    return XSaveTool.GetData(key)
end

function XFangKuaiModel:GetProgress()
    local all = 0
    local pass = 0
    ---@type XTableFangKuaiStageGroup[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiStageGroup)
    for _, config in pairs(configs) do
        if self.ActivityData then
            local isSimplePass = not XTool.IsNumberValid(config.SimpleStageId) or self.ActivityData:IsStagePass(config.SimpleStageId)
            local isDiffcultPass = not XTool.IsNumberValid(config.DiffcultStageId) or self.ActivityData:IsStagePass(config.DiffcultStageId)
            if isSimplePass and isDiffcultPass then
                pass = pass + 1
            end
        end
        all = all + 1
    end
    return pass, all
end

function XFangKuaiModel:RecordStageGroupTabIdx(id, index)
    if not self._StageGroupTabIdxMap then
        self._StageGroupTabIdxMap = {}
    end
    self._StageGroupTabIdxMap[id] = index
end

function XFangKuaiModel:GetStageGroupTabIdx(id)
    if not self._StageGroupTabIdxMap or not self._StageGroupTabIdxMap[id] then
        local stageGroup = self:GetStageGroupConfig(id)
        if not XTool.IsNumberValid(stageGroup.SimpleStageId) then
            return XEnumConst.FangKuai.DifficultTab
        elseif not XTool.IsNumberValid(stageGroup.DiffcultStageId) then
            return XEnumConst.FangKuai.SimpleTab
        else
            return self.ActivityData:IsStagePass(stageGroup.SimpleStageId) and XEnumConst.FangKuai.DifficultTab or XEnumConst.FangKuai.SimpleTab
        end
    end
    return self._StageGroupTabIdxMap[id]
end

function XFangKuaiModel:RecordFightChapterId(chapterId)
    self._CurFightChapterId = chapterId
end

-- 给Agency用 功能内使用Control那边的同名方法
function XFangKuaiModel:GetFightChapterId()
    return self._CurFightChapterId
end

function XFangKuaiModel:IsStagePlaying(stageId)
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    local chapterId = self:GetStageIdChapterId(stageId)
    return self:GetCurStageId(chapterId) == stageId
end

function XFangKuaiModel:GetCurStageId(chapterId)
    local stageData = self.ActivityData:GetStageData(chapterId)
    return stageData and stageData:GetStageId() or nil
end

----------public end----------

----------private start----------

----------private end----------

----------config start----------

---@return XTableFangKuaiActivity
function XFangKuaiModel:GetActivityConfig(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiActivity, activityId)
end

---@return XTableFangKuaiChapter[]
function XFangKuaiModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FangKuaiChapter)
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

---@return XTableFangKuaiBlock[]
function XFangKuaiModel:GetBlockConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FangKuaiBlock)
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

---@return XTableFangKuaiStageGroup[]
function XFangKuaiModel:GetStageGroupConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.FangKuaiStageGroup)
end

---@return XTableFangKuaiStageGroup
function XFangKuaiModel:GetStageGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FangKuaiStageGroup, id)
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

---返回True表示困难关卡 返回False表示普通关卡
function XFangKuaiModel:IsStageDifficulty(stageId)
    if XTool.IsTableEmpty(self._StageDifficultyMap) then
        local configs = self:GetStageGroupConfigs()
        for _, config in pairs(configs) do
            if XTool.IsNumberValid(config.SimpleStageId) then
                self._StageDifficultyMap[config.SimpleStageId] = false
            end
            if XTool.IsNumberValid(config.DiffcultStageId) then
                self._StageDifficultyMap[config.DiffcultStageId] = true
            end
        end
    end
    return self._StageDifficultyMap[stageId]
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
        for _, config in pairs(self:GetBlockConfigs()) do
            -- UnBuild=1的是设计给因道具而生成的方块上的 所以不能包含在内
            if config.Type == 1 and not XTool.IsNumberValid(config.UnBuild) then
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

function XFangKuaiModel:GetCurActivityTimeId()
    ---@type XTableFangKuaiActivity[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiActivity)
    for _, v in pairs(configs) do
        if XFunctionManager.CheckInTimeByTimeId(v.TimeId, false) then
            return v.TimeId
        end
    end
    return nil
end

--region 方块生成

---@return table<number,table<number,XTableFangKuaiBlock[]>>
function XFangKuaiModel:GetBlockTemplates()
    if not self._BlockTemplateMap then
        self._BlockTemplateMap = {}
        for _, config in pairs(self:GetBlockConfigs()) do
            local stage = self:GetStageConfig(config.StageId)
            if not stage then
                XLog.Error(string.format("配置错误. 无效的StageId. Id:%s, StageId:%s", config.Id, config.StageId))
                goto CONTINUE
            end
            if config.Length <= 0 or config.Length > stage.MaxBlockLength then
                XLog.Error(string.format("配置错误. Length 需大于 0 且小于等于对应关卡表的 MaxBlockLength. Id:%s, Length:%s, stage.MaxBlockLength:%s", config.Id, config.Length, stage.MaxBlockLength))
                goto CONTINUE
            end
            if #config.Colors == 0 then
                XLog.Error(string.format("配置错误. Colors 的数量不可以为 0. Id:%s", config.Id))
                goto CONTINUE
            end
            local datas = self._BlockTemplateMap[config.StageId]
            if not datas then
                datas = {}
            end
            if not datas[config.Length] then
                datas[config.Length] = {}
            end
            table.insert(datas[config.Length], config)
            self._BlockTemplateMap[config.StageId] = datas
            :: CONTINUE ::
        end
    end
    return self._BlockTemplateMap
end

function XFangKuaiModel:GetStageIdChapterIdMap()
    if not self._StageIdChapterIdMap then
        self._StageIdChapterIdMap = {}
        local configs = self:GetChapterConfigs()
        for _, config in pairs(configs) do
            for _, groupId in pairs(config.StageGroupIds) do
                local stageGroupConfig = self:GetStageGroupConfig(groupId)
                if XTool.IsNumberValid(stageGroupConfig.SimpleStageId) then
                    self._StageIdChapterIdMap[stageGroupConfig.SimpleStageId] = config.Id
                end
                if XTool.IsNumberValid(stageGroupConfig.DiffcultStageId) then
                    self._StageIdChapterIdMap[stageGroupConfig.DiffcultStageId] = config.Id
                end
            end
        end
    end
    return self._StageIdChapterIdMap
end

function XFangKuaiModel:GetStageIdChapterId(stageId)
    return self:GetStageIdChapterIdMap()[stageId]
end

function XFangKuaiModel:InitBlockRule()
    ---@type table<number, XFangKuaiRuleExpand>
    self._StageIdBlockRuleExpandMap = {}
    ---@type table<number, XTableFangKuaiStageBlockRule[]>
    self._StageIdBlockRuleLoopMap = {}
    ---@type XTableFangKuaiStageBlockRule[]
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiStageBlockRule)
    for _, config in pairs(configs) do
        local stageId = config.StageId
        if not self._StageIdBlockRuleExpandMap[stageId] then
            self._StageIdBlockRuleExpandMap[stageId] = require("XModule/XFangKuai/XEntity/XFangKuaiRuleExpand").New()
        end
        for i = config.MinLine, config.MaxLine do
            self._StageIdBlockRuleExpandMap[stageId].Rules[i] = config
        end
        if not self._StageIdBlockRuleLoopMap[stageId] then
            self._StageIdBlockRuleLoopMap[stageId] = {}
        end
        if config.IsLoop then
            table.insert(self._StageIdBlockRuleLoopMap[stageId], config)
        end
    end
    -- 检查展开表行数是否连贯
    for stageId, blockRuleExpand in pairs(self._StageIdBlockRuleExpandMap) do
        blockRuleExpand:UpdateKeyRange()
        -- 最大行数等于配置行数, 即是连贯的
        if blockRuleExpand.MaxKey == XTool.GetTableCount(blockRuleExpand.Rules) then
            goto CONTINUE
        end

        for i = 1, blockRuleExpand.MaxKey do
            if not blockRuleExpand.Rules[i] then
                XLog.Error(string.format("TableFangKuaiStageBlockRule配置错误. 行数配置缺失. stageId:%s, line:%s", stageId, i))
            end
        end

        :: CONTINUE ::
    end
end

function XFangKuaiModel:GetBlockRuleExpand(stageId)
    if not self._StageIdBlockRuleExpandMap then
        self:InitBlockRule()
    end
    return self._StageIdBlockRuleExpandMap[stageId]
end

function XFangKuaiModel:GetBlockRuleLoop(stageId)
    if not self._StageIdBlockRuleLoopMap then
        self:InitBlockRule()
    end
    return self._StageIdBlockRuleLoopMap[stageId]
end

function XFangKuaiModel:GetItemRuleExpand(stageId)
    if not self._StageIdItemRuleExpand then
        ---@type table<number, XFangKuaiRuleExpand>
        self._StageIdItemRuleExpand = {}
        ---@type XTableFangKuaiStageItemRule[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiStageItemRule)
        for _, config in pairs(configs) do
            if not self._StageIdItemRuleExpand[config.StageId] then
                self._StageIdItemRuleExpand[config.StageId] = require("XModule/XFangKuai/XEntity/XFangKuaiRuleExpand").New()
            end
            for i = config.MinLine, config.MaxLine do
                self._StageIdItemRuleExpand[config.StageId].Rules[i] = config
            end
        end
        for _, itemRuleExpand in pairs(self._StageIdItemRuleExpand) do
            itemRuleExpand:UpdateKeyRange()
        end
    end
    return self._StageIdItemRuleExpand[stageId]
end

function XFangKuaiModel:GetBlockConfigByData(stageId, length, direction, colorId)
    local blockTemplates = self:GetBlockTemplates()
    local blocks = blockTemplates[stageId][length]
    for _, block in pairs(blocks) do
        if block.StageId == stageId and block.Length == length and block.Direction == direction and table.indexof(block.Colors, colorId) then
            return block
        end
    end
    XLog.Error(string.format("FangKuaiBlock表里没有找到StageId=%s,Length=%s,Direction=%s,ColorId=%s对于的配置", stageId, length, direction, colorId))
    return nil
end

--endregion

--region 关卡环境：方块掉落

function XFangKuaiModel:GetBlockDropStageDatas(stageId)
    if not self._BlockDropStageMap then
        ---@type table<number, XTableFangKuaiDropBlock[]>
        self._BlockDropStageMap = {}
        ---@type XTableFangKuaiDropBlock[]
        local configs = self._ConfigUtil:GetByTableKey(TableKey.FangKuaiDropBlock)
        for _, config in pairs(configs) do
            if not self._BlockDropStageMap[config.StageId] then
                self._BlockDropStageMap[config.StageId] = {}
            end
            table.insert(self._BlockDropStageMap[config.StageId], config)
        end
        for _, datas in pairs(self._BlockDropStageMap) do
            table.sort(datas, function(a, b)
                return a.ActionRange[1] < b.ActionRange[1]
            end)
        end
    end
    return self._BlockDropStageMap[stageId]
end

function XFangKuaiModel:HasBlockDropEnviroment(stageId)
    return not XTool.IsTableEmpty(self:GetBlockDropStageDatas(stageId))
end

---@return XTableFangKuaiDropBlock
function XFangKuaiModel:GetBlockDropConfig(stageId, times)
    local datas = self:GetBlockDropStageDatas(stageId)
    if XTool.IsTableEmpty(datas) then
        XLog.Error(string.format("关卡%s没有配置关卡环境（方块顶部掉落）", stageId))
    end
    local config
    for _, v in pairs(datas) do
        if times >= v.ActionRange[1] and times <= v.ActionRange[2] then
            config = v
            break
        end
    end
    if not config then
        config = datas[#datas]
    end
    return config
end

--endregion

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

function XFangKuaiModel:NotifyFangKuaiCurStageData(data)
    if data and self.ActivityData and self:IsStagePlaying(data.CurData.StageId) then
        XEventManager.DispatchEvent(XEventId.EVENT_FANGKUAI_RESETDATA, data.CurData)
    end
end

--endregion

--region 引导

function XFangKuaiModel:SetCurStageIdGuide(stageId)
    self._CurStageId = stageId
end

function XFangKuaiModel:GetCurStageIdGuide()
    return self._CurStageId
end

--endregion

return XFangKuaiModel