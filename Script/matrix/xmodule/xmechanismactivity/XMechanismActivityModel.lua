---@class XMechanismActivityModel : XModel
local XMechanismActivityModel = XClass(XModel, "XMechanismActivityModel")
local XTeam = require('XEntity/XTeam/XTeam')

local TableNormal = {
    MechanismActivity = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    MechanismChapter = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    MechanismCharacter = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    MechanismStage = { DirPath = XConfigUtil.DirectoryType.Share,Identifier='Id',ReadFunc=XConfigUtil.ReadType.Int },
    
    MechanismClientConfig = { DirPath = XConfigUtil.DirectoryType.Client,Identifier='Key',ReadFunc=XConfigUtil.ReadType.String },
}

function XMechanismActivityModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey('Fuben/Mechanism',TableNormal,XConfigUtil.CacheType.Normal)
    self._TeamList = {}
end

function XMechanismActivityModel:ClearPrivate()
    self:ClearUITempData()
end

function XMechanismActivityModel:ResetAll()

end

----------public start----------

--region --------------------活动数据-----------------------------
function XMechanismActivityModel:RecieveActivityData(data)
    self._ActivityData = data
    
    -- 通关关卡的 id-data 字典映射，方便查找
    self._PassStageDataMap = {}

    if self._ActivityData and not XTool.IsTableEmpty(self._ActivityData.PassStages) then
        for i, stageData in ipairs(self._ActivityData.PassStages) do
            self._PassStageDataMap[stageData.StageId] = stageData
        end
    end
end

function XMechanismActivityModel:GetActivityIdFromCurData()
    if self._ActivityData then
        return self._ActivityData.ActivityId
    end
    
    return 0
end

function XMechanismActivityModel:GetStarRewardGotTotalFromCurData()
    local starCount = 0
    if self._ActivityData and not XTool.IsTableEmpty(self._ActivityData.PassStages) then
        for i, stageData in ipairs(self._ActivityData.PassStages) do
            starCount = starCount + XTool.GetTableCount(stageData.StarRewardIdxs)
        end
    end

    return starCount
end

---@param stageIds table @关卡Id列表
function XMechanismActivityModel:GetSumStarOfStages(stageIds)
    local count = 0

    if not XTool.IsTableEmpty(stageIds) then
        for i, v in pairs(stageIds) do
            local stageData = self._PassStageDataMap[v]
            if stageData then
                count = count + #stageData.StarRewardIdxs
            end
        end
    end
    
    return count
end

function XMechanismActivityModel:GetStarOfStage(stageId)
    if not XTool.IsTableEmpty(self._PassStageDataMap) then
        local stageData = self._PassStageDataMap[stageId]
        if stageData then
            return  #stageData.StarRewardIdxs
        end
    end
    return 0
end

function XMechanismActivityModel:GetPassStageDataById(stageId)
    if not XTool.IsTableEmpty(self._PassStageDataMap) then
        return self._PassStageDataMap[stageId]
    end
end

function XMechanismActivityModel:CheckHasGetStarRewardById(stageId, index)
    local passStageData = self:GetPassStageDataById(stageId)
    if passStageData then
        if not XTool.IsTableEmpty(passStageData.StarRewardIdxs) then
            return table.contains(passStageData.StarRewardIdxs, index)
        end
    end
    return false
end
--endregion

--region --------------------队伍数据-------------------------------

--- 队伍和玩法章节绑定
function XMechanismActivityModel:GetTeamLocalKeyByChapterId(chapterId)
    local activityId = self:GetActivityIdFromCurData()
    local key = 'MechanismActivityTeam_'..tostring(activityId)..'_'..tostring(chapterId)..'_'..XPlayer.Id
    return key
end

--- 队伍和玩法章节绑定
function XMechanismActivityModel:GetTeamDataByChapterId(chapterId)
    if self._TeamList[chapterId] then
        return self._TeamList[chapterId]
    end
    local teamKey = self:GetTeamLocalKeyByChapterId(chapterId)
    local teamData = XTeam.New(teamKey)
    self._TeamList[chapterId] = teamData
    
    return teamData
end
--endregion

--region --------------------蓝点数据-------------------------------
function XMechanismActivityModel:GetBuffLocalKey(characterIndex, buffIndex)
    local activityId = self:GetActivityIdFromCurData()
    local keyTab = {
        'MechanismActivityBuff_',
        tostring(activityId),
        tostring(characterIndex),
        tostring(buffIndex),
        XPlayer.Id
    }
    local key = table.concat(keyTab)
    return key
end

function XMechanismActivityModel:CheckBuffIsOld(characterIndex, buffIndex)
    local key = self:GetBuffLocalKey(characterIndex, buffIndex)
    if XSaveTool.GetData(key) then
        return true
    else
        return false
    end
end

function XMechanismActivityModel:SetBuffToOld(characterIndex, buffIndex)
    local key = self:GetBuffLocalKey(characterIndex, buffIndex)
    XSaveTool.SaveData(key, true)
end

function XMechanismActivityModel:GetChapterLocalKey(chapterId)
    local activityId = self:GetActivityIdFromCurData()
    local key = 'MechanismActivityChapter_'..tostring(activityId)..tostring(chapterId)..XPlayer.Id
    return key
end

function XMechanismActivityModel:CheckChapterIsOld(chapterId)
    local key = self:GetChapterLocalKey(chapterId)
    return XSaveTool.GetData(key) and true or false
end

function XMechanismActivityModel:SetChapterToOld(chapterId)
    local key = self:GetChapterLocalKey(chapterId)
    XSaveTool.SaveData(key, true)
end

function XMechanismActivityModel:GetStageLocalKey(stageId)
    local activityId = self:GetActivityIdFromCurData()
    local key = 'MechanismActivityStage_'..tostring(activityId)..tostring(stageId)..XPlayer.Id
    return key
end

function XMechanismActivityModel:CheckStageIsOld(stageId)
    local key = self:GetStageLocalKey(stageId)
    return XSaveTool.GetData(key) and true or false
end

function XMechanismActivityModel:SetStageToOld(stageId)
    local key = self:GetStageLocalKey(stageId)
    XSaveTool.SaveData(key, true)
end
--endregion

--region --------------------界面数据------------------------------
function XMechanismActivityModel:GetMechanismCurChapterId()
    return self._CurChapterId or 0
end

function XMechanismActivityModel:SetMechanismCurChapterId(chapterId)
    if XTool.IsNumberValid(chapterId) then
        self._CurChapterId = chapterId
    end
end

function XMechanismActivityModel:GetSelectStageIndexLocalKey(chapterId)
    local activityId = self:GetActivityIdFromCurData()
    local key = 'MechanismActivitySelectStage_'..tostring(activityId)..tostring(chapterId)..XPlayer.Id
    return key
end

function XMechanismActivityModel:GetLastSelectStageIndex(chapterId)
    return XSaveTool.GetData(self:GetSelectStageIndexLocalKey(chapterId))
end

function XMechanismActivityModel:SetSelectStageIndex(chapterId, stageIndex)
    XSaveTool.SaveData(self:GetSelectStageIndexLocalKey(chapterId), stageIndex)
end

function XMechanismActivityModel:ClearUITempData()
    self._CurChapterId = nil
end

--- 战斗中暂停界面数据依赖于界面操作的结果，由于界面数据在所有关联界面销毁后将会清空，需要把部分界面数据进行缓存
function XMechanismActivityModel:UITempDataTransferFight()
    self._CurChapterIdInFight = self:GetMechanismCurChapterId()
end

function XMechanismActivityModel:GetMechanismCurChapterIdInFight()
    return self._CurChapterIdInFight or 0
end
--endregion
----------public end----------

----------private start----------


----------private end----------

----------config start----------

--region ---------------------基础读表-----------------------------
function XMechanismActivityModel:GetMechanismActivityCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.MechanismActivity)
end

function XMechanismActivityModel:GetMechanismChapterCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.MechanismChapter)
end

function XMechanismActivityModel:GetMechanismCharacterCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.MechanismCharacter)
end

function XMechanismActivityModel:GetMechanismStageCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.MechanismStage)
end

function XMechanismActivityModel:GetMechanismClientConfig()
    return self._ConfigUtil:GetByTableKey(TableNormal.MechanismClientConfig)
end
--endregion

--region --------------------配置表项读取----------------------------------
---@return XTableMechanismActivity
function XMechanismActivityModel:GetMechanismActivityCfgById(id)
    local cfg = self:GetMechanismActivityCfgs()[id]

    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismActivityCfgById',nil,TableNormal.MechanismActivity,'id',id)
    end
end

---@return XTableMechanismChapter
function XMechanismActivityModel:GetMechanismChapterCfgById(id)
    local cfg = self:GetMechanismChapterCfgs()[id]

    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismChapterCfgById',nil,TableNormal.MechanismChapter,'id',id)
    end
end

---@return XTableMechanismCharacter
function XMechanismActivityModel:GetMechanismCharacterCfgById(id)
    local cfg = self:GetMechanismCharacterCfgs()[id]

    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismCharacterCfgById',nil,TableNormal.MechanismCharacter,'id',id)
    end
end

---@return XTableMechanismStage
function XMechanismActivityModel:GetMechanismStageCfgById(id)
    local cfg = self:GetMechanismStageCfgs()[id]

    if cfg then
        return cfg
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismStageCfgById',nil,TableNormal.MechanismStage,'id',id)
    end
end

---@return string
function XMechanismActivityModel:GetMechanismClientConfigString(key)
    local cfg = self:GetMechanismClientConfig()[key]

    if cfg then
        return cfg.Value[1]
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismClientConfigString',nil,TableNormal.MechanismClientConfig,'id',id)
    end
end

function XMechanismActivityModel:GetMechanismClientConfigStringArray(key)
    local cfg = self:GetMechanismClientConfig()[key]

    if cfg then
        return cfg.Value
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismClientConfigString',nil,TableNormal.MechanismClientConfig,'id',id)
    end
end

---@return number
function XMechanismActivityModel:GetMechanismClientConfigNumber(key)
    local cfg = self:GetMechanismClientConfig()[key]

    if cfg then
        return XTool.IsNumberValid(cfg.Value[1]) and tonumber(cfg.Value[1]) or 0
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismClientConfigNumber',nil,TableNormal.MechanismActivity,'id',id)
    end
end

function XMechanismActivityModel:GetMechanismClientConfigBool(key)
    local val = self:GetMechanismClientConfigNumber(key)
    if XTool.IsNumberValid(val) then
        return true
    else
        return false
    end
end

---@return table @数值数组
function XMechanismActivityModel:GetMechanismClientConfigNumArray(key)
    local cfg = self:GetMechanismClientConfig()[key]
    local array = {}
    if cfg then
        for i, v in ipairs(cfg.Value) do
            local val = XTool.IsNumberValid(v) and tonumber(v) or 0
            table.insert(array, val)
        end
    else
        XLog.ErrorTableDataNotFound('XMechanismActivityModel:GetMechanismClientConfigNumArray',nil,TableNormal.MechanismActivity,'id',id)
    end

    return array

end
--endregion

--region --------------------配置表字段读取------------------------------

---@param activityId @活动Id
function XMechanismActivityModel:GetMechanismActivityTimeIdById(activityId)
    if not XTool.IsNumberValid(activityId) then
        return 0
    end
    
    local cfg = self:GetMechanismActivityCfgById(activityId)

    if cfg then
        return cfg.TimeId
    end
end

---@param activityId @活动Id
---@return table @数值列表
function XMechanismActivityModel:GetMechanismActivityChapterIdsById(activityId)
    if not XTool.IsNumberValid(activityId) then
        return
    end

    local cfg = self:GetMechanismActivityCfgById(activityId)

    if cfg then
        return cfg.ChapterIds
    end
end

---@param chapterId @章节Id
function XMechanismActivityModel:GetMechanismChapterTimeIdById(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return 0
    end

    local cfg = self:GetMechanismChapterCfgById(chapterId)

    if cfg then
        return cfg.TimeId
    end

    return 0
end

---@param chapterId @章节Id
---@return table @数值列表
function XMechanismActivityModel:GetMechanismChapterStageIdsById(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end

    local cfg = self:GetMechanismChapterCfgById(chapterId)

    if cfg then
        return cfg.StageIds
    end
end

---@param stageId @关卡Id,MechanismStage.tab-Stage.tab Id一致
---@return number @关卡星数上限
function XMechanismActivityModel:GetMechanismStageStarLimitById(stageId)
    if not XTool.IsNumberValid(stageId) then
        return 0
    end
    
    local cfg = self:GetMechanismStageCfgById(stageId)

    if cfg then
        return #cfg.StarRewards
    end
    
    return 0
end

function XMechanismActivityModel:GetMechanismCharacterIndexByEntityId(entityId)
    if XTool.IsNumberValid(entityId) then
        local characterId = entityId
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        end
        
        local cfgs = self:GetMechanismCharacterCfgs()
        for i, cfg in pairs(cfgs) do
            if cfg.CharacterId == characterId then
                return i
            end
        end
    end
    return 0
end
--endregion

----------config end----------


return XMechanismActivityModel