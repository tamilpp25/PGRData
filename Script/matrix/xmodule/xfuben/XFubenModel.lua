
local TableKey = {
    Stage = {DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId"},
    StageLevelControl = {DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal},
    StageMultiplayerLevelControl = {DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal},
    FlopReward = {DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal},
    StageType = {DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal}
}

---@class XFubenModel : XModel
local XFubenModel = XClass(XModel, "XFubenModel")
function XFubenModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    ---兼容老的
    self.Compatible = true

    self._ConfigUtil:InitConfigByTableKey("Fuben", TableKey)

    self.DifficultNormal = CS.XGame.Config:GetInt("FubenDifficultNormal")
    self.DifficultHard = CS.XGame.Config:GetInt("FubenDifficultHard")
    self.DifficultVariations = CS.XGame.Config:GetInt("FubenDifficultVariations")
    self.DifficultNightmare = CS.XGame.Config:GetInt("FubenDifficultNightmare")
    self.StageStarNum = CS.XGame.Config:GetInt("FubenStageStarNum")
    self.NotGetTreasure = CS.XGame.Config:GetInt("FubenNotGetTreasure")
    self.GetTreasure = CS.XGame.Config:GetInt("FubenGetTreasure")
    self.FubenFlopCount = CS.XGame.Config:GetInt("FubenFlopCount")

    self.SettleRewardAnimationDelay = CS.XGame.ClientConfig:GetInt("SettleRewardAnimationDelay")
    self.SettleRewardAnimationInterval = CS.XGame.ClientConfig:GetInt("SettleRewardAnimationInterval")

    --配置表解析
    self._StageRelationInfos = nil
    self._StageInfos = nil
    self._StageLevelMap = nil
    self._StageMultiplayerLevelMap = nil
    --

    self._PlayerStageData = {}
    self._UnlockHideStages = {}
    self._NewHideStageId = nil


    self._BeginData = nil
    self._FubenSettleResult = nil
    self._IsWaitingResult = false
    self._EnterFightStartTime = 0
    self._FubenSettling = nil
    self._CurFightResult = nil --战斗结果
    self._LastDpsTable = nil
end

function XFubenModel:ClearPrivate()
    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XFubenModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
    self._PlayerStageData = {}
    self._UnlockHideStages = {}
end

----------public start----------
function XFubenModel:SetPlayerStageData(key, value)
    self._PlayerStageData[key] = value
end

function XFubenModel:SetUnlockHideStages(key)
    self._UnlockHideStages[key] = true
end

function XFubenModel:SetNewHideStage(Id)
    self._NewHideStageId = Id
end

function XFubenModel:GetNewHideStage()
    return self._NewHideStageId
end

---设置进入战斗数据
function XFubenModel:SetBeginData(data)
    self._BeginData = data
    if self.Compatible then
        XDataCenter.FubenManager.SetFightBeginData(data) --兼容
    end
end

---获取进入战斗数据
function XFubenModel:GetBeginData()
    if self.Compatible then
        return XDataCenter.FubenManager.GetFightBeginData()
    end
    return self._BeginData
end

---设置副本结算数据
function XFubenModel:SetFubenSettleResult(value)
    self._FubenSettleResult = value
    if self.Compatible then
        XDataCenter.FubenManager.FubenSettleResult = value
    end
end

---获取副本结算状态
function XFubenModel:GetFubenSettleResult()
    if self.Compatible then
        return XDataCenter.FubenManager.FubenSettleResult
    end
    return self._FubenSettleResult
end

function XFubenModel:SetEnterFightStartTime(value)
    self._EnterFightStartTime = value
end

function XFubenModel:GetEnterFightStartTime()
    return self._EnterFightStartTime
end

---设置副本结算状态
function XFubenModel:SetFubenSettling(value)
    self._FubenSettling = value
end

---返回副本结算状态
function XFubenModel:GetFubenSettling()
    return self._FubenSettling
end

function XFubenModel:SetLastDpsTable(value)
    self._LastDpsTable = value
    if self.Compatible then
        XDataCenter.FubenManager.LastDpsTable = value
    end
end

function XFubenModel:GetLastDpsTable()
    return self._LastDpsTable
end

function XFubenModel:SetCurFightResult(value)
    self._CurFightResult = value
    if self.Compatible then
        XDataCenter.FubenManager.CurFightResult = value
    end
end

function XFubenModel:GetCurFightResult()
    return self._CurFightResult
end

function XFubenModel:SetIsWaitingResult(value)
    self._IsWaitingResult = value
end

function XFubenModel:GetIsWaitingResult()
    return self._IsWaitingResult
end

-----常用配置
function XFubenModel:GetDifficultNormal()
    return self.DifficultNormal
end

function XFubenModel:GetDifficultHard()
    return self.DifficultHard
end

-----常用配置

----配置表相关start

function XFubenModel:GetStageTypeCfg(stageId)
    if self.Compatible then
        return XFubenConfigs.GetStageTypeCfg(stageId)
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageType, stageId)
end

------获取整个副本配置表
function XFubenModel:GetStageCfgs()
    if self.Compatible then
        return XFubenConfigs.GetStageCfgs()
    end
    return self._ConfigUtil:GetByTableKey(TableKey.Stage)
end

function XFubenModel:GetFlopRewardTemplates()
    if self.Compatible then
        return XFubenConfigs.GetFlopRewardTemplates()
    end
    return self._ConfigUtil.GetByTableKey(TableKey.FlopReward)
end

function XFubenModel:GetStageLevelMap()
    if self.Compatible then
        local stageLevelMap = XDataCenter.FubenManager.GetStageLevelMap()
        if not XTool.IsTableEmpty(stageLevelMap) then
            return stageLevelMap
        end
    end
    if not self._StageLevelMap then
        self:InitStageLevelMap()
    end
    return self._StageLevelMap
end

function XFubenModel:GetStageMultiplayerLevelMap()
    if self.Compatible then
        local stageMultiplayerLevelMap = XDataCenter.FubenManager.GetStageMultiplayerLevelMap()
        if not XTool.IsTableEmpty(stageMultiplayerLevelMap) then
            return stageMultiplayerLevelMap
        end
    end
    if not self._StageMultiplayerLevelMap then
        self:InitStageMultiplayerLevelMap()
    end
    return self._StageMultiplayerLevelMap
end

function XFubenModel:GetStageRelationInfos()
    if self.Compatible then
        local stageRelationInfos = XDataCenter.FubenManager.GetStageRelationInfos()
        if not XTool.IsTableEmpty(stageRelationInfos) then
            return stageRelationInfos
        end
    end
    if not self._StageRelationInfos then
        self:InitStageInfoRelation()
    end
    return self._StageRelationInfos
end

----配置表相关end

---获取关卡信息
---@param stageId number 关卡id
function XFubenModel:GetStageInfo(stageId)
    if self.Compatible then
        return XDataCenter.FubenManager.GetStageInfo(stageId)
    end
    return self._StageInfos[stageId]
end

---获取所有关卡信息
function XFubenModel:GetStageInfos()
    if self.Compatible then
        return XDataCenter.FubenManager.GetStageInfos()
    end
    return self._StageInfos
end

---获取玩家副本信息
function XFubenModel:GetPlayerStageDataById(stageId)
    if self.Compatible then
        return XDataCenter.FubenManager.GetStageData(stageId)
    end
    return self._PlayerStageData[stageId]
end

function XFubenModel:GetPlayerStageData()
    if self.Compatible then
        return XDataCenter.FubenManager.GetPlayerStageData()
    end
    return self._PlayerStageData
end



----------public end----------

----------private start----------
function XFubenModel:GetStageCfg(stageId, ignoreError)
    if self.Compatible then
        return XDataCenter.FubenManager.GetStageCfg(stageId)
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.Stage, stageId, ignoreError)
end

function XFubenModel:InitStageInfoRelation()
    self._StageRelationInfos = {}
    local stageCfg = self:GetStageCfgs()
    for stageId, v in pairs(stageCfg) do
        for _, preStageId in pairs(v.PreStageId) do
            self._StageRelationInfos[preStageId] = self._StageRelationInfos[preStageId] or {}
            table.insert(self._StageRelationInfos[preStageId], stageId)
        end
    end
end

function XFubenModel:GetStarsCount(starsMark)
    local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
    local map = { (starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
    return count, map
end

--所有玩法的列表, 包括是否通关, 星级, 是否解锁和开启
function XFubenModel:InitStageInfo()
    self._StageInfos = {}
    local stageCfg = self:GetStageCfgs()
    for stageId, stageCfg in pairs(stageCfg) do
        local info = self._StageInfos[stageId]

        if not info then
            info = {}
            self._StageInfos[stageId] = info
        end

        if XTool.IsNumberValid(stageCfg.StageType) then
            info.Type = stageCfg.StageType
        end
        info.HaveAssist = stageCfg.HaveAssist
        info.IsMultiplayer = stageCfg.IsMultiplayer
        if self._PlayerStageData[stageId] then
            info.Passed = self._PlayerStageData[stageId].Passed
            info.Stars, info.StarsMap = self:GetStarsCount(self._PlayerStageData[stageId].StarsMark)
        else
            info.Passed = false
            info.Stars = 0
            info.StarsMap = { false, false, false }
        end
        info.Unlock = true
        info.IsOpen = true

        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
            info.Unlock = false
        end

        for _, preStageId in pairs(stageCfg.PreStageId or {}) do
            if preStageId > 0 then
                if not self._PlayerStageData[preStageId] or not self._PlayerStageData[preStageId].Passed then
                    info.Unlock = false
                    info.IsOpen = false
                    break
                end
            end
        end
        info.TotalStars = 3
    end
end

function XFubenModel:InitStageInfoNextStageId()
    local stageCfg = self:GetStageCfgs()
    for _, v in pairs(stageCfg) do
        for _, preStageId in pairs(v.PreStageId) do
            local preStageInfo = self:GetStageInfo(preStageId)
            if preStageInfo then
                if not (v.StageType == XFubenConfigs.STAGETYPE_STORYEGG or v.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG) then
                    preStageInfo.NextStageId = v.StageId
                end
            else
                XLog.Error("XFubenModel:InitStageInfoNextStageId error:初始化前置关卡信息失败, 请检查Stage.tab, preStageId: " .. preStageId)
            end
        end
    end
end

function XFubenModel:InitStageLevelMap()
    local tmpDict = {}

    local config = self._ConfigUtil:GetByTableKey(TableKey.StageLevelControl)

    XTool.LoopMap(config, function(key, v)
        if not tmpDict[v.StageId] then
            tmpDict[v.StageId] = {}
        end
        table.insert(tmpDict[v.StageId], v)
    end)

    for k, list in pairs(tmpDict) do
        table.sort(list, function(a, b)
            return a.MaxLevel < b.MaxLevel
        end)
    end

    self._StageLevelMap = tmpDict
end

function XFubenModel:InitStageMultiplayerLevelMap()
    local config = self._ConfigUtil:GetByTableKey(TableKey.StageMultiplayerLevelControl)
    self._StageMultiplayerLevelMap = {}
    for _, v in pairs(config) do
        if not self._StageMultiplayerLevelMap[v.StageId] then
            self._StageMultiplayerLevelMap[v.StageId] = {}
        end
        self._StageMultiplayerLevelMap[v.StageId][v.Difficulty] = v
    end
end

----------private end----------



----------config start----------


----------config end----------


return XFubenModel