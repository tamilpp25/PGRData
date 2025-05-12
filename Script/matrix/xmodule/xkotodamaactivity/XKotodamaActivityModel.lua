---@class XKotodamaActivityModel : XModel
local XKotodamaActivityModel = XClass(XModel, "XKotodamaActivityModel")
local XTeam = require("XEntity/XTeam/XTeam")

local TableMapNormal = {
    KotodamaActivity = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = 'Id', ReadFunc = XConfigUtil.ReadType.Int },
    KotodamaStage = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaCharacterGroup = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaSentence = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = 'Key', ReadFunc = XConfigUtil.ReadType.String},

}

local TableMap = {
    KotodamaSentencePattern = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaWord = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaWordBlock = { DirPath = XConfigUtil.DirectoryType.Client },
    KotodamaArtifact = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaArtifactAffix = { DirPath = XConfigUtil.DirectoryType.Share },
    KotodamaArtifactCompose = { DirPath = XConfigUtil.DirectoryType.Share },
}

local PrivateMap = {}

function XKotodamaActivityModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey('Fuben/Kotodama', TableMap, XConfigUtil.CacheType.Private)
    self._ConfigUtil:InitConfigByTableKey('Fuben/Kotodama', TableMapNormal, XConfigUtil.CacheType.Normal)

    self._activityDataCache = nil

    self._wordGroupConfig = {}
    self._sentenGroupConfig = {}
end

function XKotodamaActivityModel:ClearPrivate()
    self._tmpBtnStartIsValid = nil    --进入冒险按钮是否有效（not disable）
    self._tmpWordGroupCache = nil     --词的顺序数组缓存（减少反复排序）
    self._tmpBlockErrorCache = nil    --各个填空的正确与否缓存
    self._tmpCurWordList = nil      --当前关卡拼词缓存（用于处理词交换的需求）
end

function XKotodamaActivityModel:ResetAll()
    self._activityDataCache = nil

    self._tmpIsReset = nil      --是否存在本地重置
    self._tmpResetStageId = nil --重置的关卡Id
    self._currentTeam = nil
end

----------public start----------
function XKotodamaActivityModel:IsActivityDataExisit()
    return self._activityDataCache ~= nil
end

function XKotodamaActivityModel:GetActivityTimeId()
    if XTool.IsTableEmpty(self._activityDataCache) then
        return 0
    end
    local activityId = self._activityDataCache.ActivityId
    if XTool.IsNumberValid(activityId) then
        local cfg = self:GetKotodamaActivity()[activityId]
        if XTool.IsTableEmpty(cfg) then
            XLog.Error('找不到KotodamaActivity表中的配置 Id:' .. activityId)
            return 0
        end
        return cfg.TimeId
    end
    return 0
end

function XKotodamaActivityModel:GetCurActivityId()
    if not XTool.IsTableEmpty(self._activityDataCache) then
        return self._activityDataCache.ActivityId
    end
    return 0
end

function XKotodamaActivityModel:GetPassStageDataById(stageId)
    if XTool.IsTableEmpty(self._activityDataCache) then
        XLog.Error('不存在当前言灵活动的数据')
        return nil
    end
    if not XTool.IsTableEmpty(self._activityDataCache.PassStages) then
        for i, v in pairs(self._activityDataCache.PassStages) do
            if v.StageId == stageId then
                return v
            end
        end
    end
end

function XKotodamaActivityModel:GetPassStagesData()
    if XTool.IsTableEmpty(self._activityDataCache) then
        return nil
    end
    return self._activityDataCache.PassStages
end

function XKotodamaActivityModel:GetPassedStageCount()
    if not XTool.IsTableEmpty(self._activityDataCache) then
        local passCount = XTool.GetTableCount(self._activityDataCache.PassStages)
        return passCount
    end
    return 0
end

function XKotodamaActivityModel:GetKotodamaUnLockSentenceCountById(stageId)
    local stageData = self:GetPassStageDataById(stageId)
    if stageData then
        return #stageData.Sentences
    end
    return 0
end

function XKotodamaActivityModel:GetKotodamaCollectUnLockSentenceCountById(stageId)
    local stageData = self:GetPassStageDataById(stageId)
    if stageData then
        local count = 0
        for i, v in pairs(stageData.Sentences or {}) do
            if self:IsSentenceCollectable(v) then
                count = count + 1
            end
        end
        return count
    end
    return 0
end

function XKotodamaActivityModel:GetCurStageData()
    if XTool.IsTableEmpty(self._activityDataCache) then
        return nil
    end
    return self._activityDataCache.CurStageInfo
end

function XKotodamaActivityModel:SetActivityData(data)
    PrivateMap.CompareNewArtifactGet(self, self._activityDataCache, data.KotodamaData)
    self._activityDataCache = data.KotodamaData
end

--获取所有通关关卡里的解锁句子的Id，但不区分是否是图鉴
function XKotodamaActivityModel:GetAllUnLockSentenceIds()
    if XTool.IsTableEmpty(self._activityDataCache) then
        return nil
    end
    local sentences = {}
    for index1, stage in pairs(self._activityDataCache.PassStages or {}) do
        for index2, sentence in pairs(stage.Sentences) do
            table.insert(sentences, sentence)
        end
    end
    return sentences
end

-- 读取本地编队信息
function XKotodamaActivityModel:LoadTeamLocal()
    local teamId = PrivateMap.GetCookieKeyTeam(self)
    if not self._currentTeam then
        self._currentTeam = XTeam.New(teamId)
    end
    local ids = self._currentTeam:GetEntityIds()
    local tmpIds = XTool.Clone(ids)
    for pos, id in ipairs(ids) do
        if not XMVCA.XCharacter:IsOwnCharacter(id)
                and not XRobotManager.CheckIsRobotId(id) then
            tmpIds[pos] = 0
        end
    end
    self._currentTeam:UpdateEntityIds(tmpIds)
    return self._currentTeam
end

-- 获取神器数据
function XKotodamaActivityModel:GetArtifactListData()
    if self._activityDataCache then
        return self._activityDataCache.GainArtifacts
    end
end

function XKotodamaActivityModel:CheckHasNewArtifact()
    return self._HasNewArtifact
end

--region 界面临时变量接口

----------getter---------------->>>
function XKotodamaActivityModel:GetTmpBtnStartIsValid()
    return self._tmpBtnStartIsValid
end

function XKotodamaActivityModel:GetTmpWordGroupCache()
    return self._tmpWordGroupCache
end

function XKotodamaActivityModel:GetTmpBlockErrorCache()
    return self._tmpBlockErrorCache
end

function XKotodamaActivityModel:GetTmpCurWordList()
    return self._tmpCurWordList
end

function XKotodamaActivityModel:GetHasResetLocal()
    return self._tmpIsReset, self._tmpResetStageId
end

----------setter------------------->>>
function XKotodamaActivityModel:SetTmpBtnStartIsValid(data)
    self._tmpBtnStartIsValid = data
end

function XKotodamaActivityModel:SetTmpWordGroupCache(data)
    self._tmpWordGroupCache = data
end

function XKotodamaActivityModel:SetTmpBlockErrorCache(data)
    self._tmpBlockErrorCache = data
end

function XKotodamaActivityModel:ResetTmpBlockErrorCache()
    if not XTool.IsTableEmpty(self._tmpBlockErrorCache) then
        for i, v in pairs(self._tmpBlockErrorCache) do
            self._tmpBlockErrorCache[i] = nil
        end
    end
end

function XKotodamaActivityModel:InitTmpCurWordList()
    self._tmpCurWordList = nil
end

function XKotodamaActivityModel:SetTmpCurWordList(data)
    --值拷贝
    self._tmpCurWordList = XTool.Clone(data)
end

function XKotodamaActivityModel:MarkStageHasResetLocal(stageId)
    self._tmpIsReset = true
    self._tmpResetStageId = stageId
end

function XKotodamaActivityModel:ClearResetLocalMark()
    self._tmpIsReset = nil
    self._tmpResetStageId = nil
end

--endregion

----------public end----------

----------private start----------
---@param model XKotodamaActivityModel
PrivateMap.GetCookieKeyTeam = function(model)
    return 'XKotodamaLocalTeam_' .. tostring(model:GetCurActivityId()) .. '_' .. XPlayer.Id
end

PrivateMap.CompareNewArtifactGet = function(model, oldData, newData)
    if XTool.IsTableEmpty(oldData) or XTool.IsTableEmpty(newData) then
        return
    end

    if XTool.IsTableEmpty(oldData.GainArtifacts) then
        model._HasNewArtifact = not XTool.IsTableEmpty(newData.GainArtifacts)
    else
        local composeIds = {}
        for i, v in pairs(oldData.GainArtifacts) do
            table.insert(composeIds, v.ComposeId)
        end
        for i, v in pairs(newData.GainArtifacts) do
            if not table.contains(composeIds, v.ComposeId) then
                model._HasNewArtifact = true
                return
            end
        end
        model._HasNewArtifact = false
    end
end

----------private end----------

----------config start----------
--region 基础读表
function XKotodamaActivityModel:GetKotodamaActivity()
    return self._ConfigUtil:GetByTableKey(TableMapNormal.KotodamaActivity)
end

function XKotodamaActivityModel:GetKotodamaSentencePattern()
    return self._ConfigUtil:GetByTableKey(TableMap.KotodamaSentencePattern)
end

function XKotodamaActivityModel:GetKotodamaStage()
    return self._ConfigUtil:GetByTableKey(TableMapNormal.KotodamaStage)
end

function XKotodamaActivityModel:GetKotodamaSentence()
    return self._ConfigUtil:GetByTableKey(TableMapNormal.KotodamaSentence)
end

function XKotodamaActivityModel:GetKotodamaWord()
    return self._ConfigUtil:GetByTableKey(TableMap.KotodamaWord)
end

function XKotodamaActivityModel:GetKotodamaCharacterGroup()
    return self._ConfigUtil:GetByTableKey(TableMapNormal.KotodamaCharacterGroup)
end

function XKotodamaActivityModel:GetKotodamaWordBlock()
    return self._ConfigUtil:GetByTableKey(TableMap.KotodamaWordBlock)
end

function XKotodamaActivityModel:GetKotodamaClientConfig()
    return self._ConfigUtil:GetByTableKey(TableMapNormal.KotodamaClientConfig)
end

function XKotodamaActivityModel:GetKotodamaArtifact()
    return self._ConfigUtil:GetByTableKey(TableMap.KotodamaArtifact)
end

function XKotodamaActivityModel:GetKotodamaArtifactAffix()
    return self._ConfigUtil:GetByTableKey(TableMap.KotodamaArtifactAffix)
end

function XKotodamaActivityModel:GetKotodamaArtifactCompose()
    return self._ConfigUtil:GetByTableKey(TableMap.KotodamaArtifactCompose)
end
--endregion

--region 条件查找
---@return XTableKotodamaStage
function XKotodamaActivityModel:GetKotodamaStageCfgById(stageId)
    local stageCfg = self:GetKotodamaStage()[stageId]
    if XTool.IsTableEmpty(stageCfg) then
        XLog.Error('找不到KotodamaStage表中的配置 Id:' .. stageId)
        return nil
    end
    return stageCfg
end

function XKotodamaActivityModel:GetKotodamaStageCount()
    return XTool.GetTableCount(self:GetKotodamaStage())
end

function XKotodamaActivityModel:GetKotodamaStageSentenceCountById(stageId)
    local stageCfg = self:GetKotodamaStageCfgById(stageId)
    if stageCfg then
        return #stageCfg.SentencePatterns
    end
    return 0
end

function XKotodamaActivityModel:GetKotodamaSentencePatternCfgById(sentenceId)
    local sentenceCfg = self:GetKotodamaSentencePattern()[sentenceId]
    if XTool.IsTableEmpty(sentenceCfg) then
        XLog.Error('找不到KotodamaSentence表中的配置 Id:' .. sentenceId)
        return nil
    end
    return sentenceCfg
end

--按组获取一系列词，会事先遍历将词的数据按组进行归类
function XKotodamaActivityModel:GetWordGroupConfig(groupId)
    if XTool.IsTableEmpty(self._wordGroupConfig) then
        for i, v in pairs(self:GetKotodamaWord()) do
            if XTool.IsTableEmpty(self._wordGroupConfig[v.PhraseId]) then
                self._wordGroupConfig[v.PhraseId] = {}
            end
            table.insert(self._wordGroupConfig[v.PhraseId], v)
        end
    end

    return self._wordGroupConfig[groupId]
end

--按组获取同一个句式的所有组合句子，会事先遍历将句子按句式归类
function XKotodamaActivityModel:GetSentenceGroupConfig(sentenceId)
    if XTool.IsTableEmpty(self._sentenGroupConfig) then
        for i, v in pairs(self:GetKotodamaSentence()) do
            if XTool.IsTableEmpty(self._sentenGroupConfig[v.PatternId]) then
                self._sentenGroupConfig[v.PatternId] = {}
            end
            table.insert(self._sentenGroupConfig[v.PatternId], v)
        end
    end
    return self._sentenGroupConfig[sentenceId]
end

function XKotodamaActivityModel:GetCollectableSentenceCountByPatternId(patternId)
    local sentences = self:GetSentenceGroupConfig(patternId)
    local result = {}
    for i, v in pairs(sentences) do
        if v.IsCollect == 1 then
            table.insert(result, v)
        end
    end
    return result
end

function XKotodamaActivityModel:GetCollectableSentenceCount()
    local count = 0
    for i, v in pairs(self:GetKotodamaSentence()) do
        if v.IsCollect == 1 then
            count = count + 1
        end
    end
    return count
end

function XKotodamaActivityModel:GetActivityTaskId(activityId)
    local cfg = self:GetKotodamaActivity()[activityId]
    if cfg then
        return cfg.TaskGroupId
    end
end

function XKotodamaActivityModel:IsSentenceCollectable(sentenceId)
    local cfg = self:GetKotodamaSentence()[sentenceId]
    if cfg then
        return cfg.IsCollect == 1
    else
        XLog.Error('IsSentenceCollectable Find Not Data By Id:' .. sentenceId)
    end
end

function XKotodamaActivityModel:GetClientConfigStringByKey(key)
    local clientConfig = self:GetKotodamaClientConfig()
    local cfg = clientConfig[key]
    if cfg then
        return cfg.Value[1]
    else
        XLog.ErrorTableDataNotFound('GetClientConfigStringByKey', '字符串配置', 'Client/Fuben/Kotodama/KotodamaClientConfig')
    end
end

function XKotodamaActivityModel:GetClientConfigIntByKey(key)
    local clientConfig = self:GetKotodamaClientConfig()
    local cfg = clientConfig[key]
    if cfg then
        local intStr = cfg.Value[1]
        return (string.IsNilOrEmpty(intStr) and not string.IsNumeric(intStr)) and 0 or tonumber(intStr)
    else
        XLog.ErrorTableDataNotFound('GetClientConfigStringByKey', '整数配置', 'Client/Fuben/Kotodama/KotodamaClientConfig')
    end
end

function XKotodamaActivityModel:GetClientConfigStringArrayByKey(key)
    local clientConfig = self:GetKotodamaClientConfig()
    local cfg = clientConfig[key]
    if cfg then
        return cfg.Value
    else
        XLog.ErrorTableDataNotFound('GetClientConfigStringByKey', '字符串数组配置', 'Client/Fuben/Kotodama/KotodamaClientConfig')
    end
end
--endregion

----------config end----------


return XKotodamaActivityModel