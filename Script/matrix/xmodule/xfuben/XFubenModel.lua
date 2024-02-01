local TableKey = {
    Stage = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    StageLevelControl = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal },
    StageMultiplayerLevelControl = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal },
    FlopReward = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    StageType = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    StageTransform = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    ActivitySortRule = { DirPath = XConfigUtil.DirectoryType.Custom, Path = "Client/Fuben/ActivitySortRule/ActivitySortRule.tab", CacheType = XConfigUtil.CacheType.Normal },
    FubenFeatures = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    StageFightControl = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    FubenChallengeBanner = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal, Identifier = "Type" },
    MultiChallengeStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    StageCharacterLimit = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal, TableDefindName = "XTableFubenStageCharacterLimit" },
    StageTeamBuff = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    StageFightEvent = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    StageFightEventDetails = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    StageRecommend = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    StageMixCharacterLimitBuff = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "CharacterLimitType" },
    StageStepSkip = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    StageGamePlayDesc = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageType" },
    StageGamePlayDescSheet = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    FubenActivity = { CacheType = XConfigUtil.CacheType.Normal },
    FubenTabConfig = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    FubenSecondTag = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    FubenStoryLine = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    FubenActivityTimeTips = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    FubenCollegeBanner = { CacheType = XConfigUtil.CacheType.Normal },
    FubenClientConfig = { ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "Key" },
    StageVoiceTip = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    StageSettleSpecialSound = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
    SettleLoseTip = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    StageTeleport = { DirPath = XConfigCenter.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, Identifier = "StageId" },
}

---@class XFubenModel : XModel
local XFubenModel = XClass(XModel, "XFubenModel")
function XFubenModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
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
    self._StageEventInfos = {}
    self._NewHideStageId = nil

    self._BeginData = nil
    self._FubenSettleResult = nil
    self._IsWaitingResult = false
    self._EnterFightStartTime = 0
    self._FubenSettling = nil
    self._CurFightResult = nil --战斗结果
    self._LastDpsTable = nil

    self._TeamBuffMaxCountDic = nil
    self._StageMixCharacterLimitBuff = nil
    self._StageGamePlayDataSource = nil

    --副本上阵角色类型限制相关:
    local CSXTextManagerGetText = CS.XTextManager.GetText
    local CSXGameClientConfig = CS.XGame.ClientConfig
    self._ROOM_CHARACTER_LIMIT_CONFIGS = {
        [XEnumConst.FuBen.CharacterLimitType.Normal] = {
            Name = CSXTextManagerGetText("CharacterTypeLimitNameNormal"),
            ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeNormalLimitImage"),
            ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterNormalImage"),
            TextTeamEdit = CSXTextManagerGetText("TeamCharacterTypeNormalLimitText"),
            TextSelectCharacter = CSXTextManagerGetText("TeamRequireCharacterNormalText"),
            TextChapterLimit = CSXTextManagerGetText("ChapterCharacterTypeLimitNormal"),
            TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeNormalLimitText"),
        },
        [XEnumConst.FuBen.CharacterLimitType.Isomer] = {
            Name = CSXTextManagerGetText("CharacterTypeLimitNameIsomer"),
            ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeIsomerLimitImage"),
            ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterIsomerImage"),
            TextTeamEdit = CSXTextManagerGetText("TeamCharacterTypeIsomerLimitText"),
            TextSelectCharacter = CSXTextManagerGetText("TeamRequireCharacterIsomerText"),
            TextChapterLimit = CSXTextManagerGetText("ChapterCharacterTypeLimitIsomer"),
            TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeIsomerLimitText"),
        },
        [XEnumConst.FuBen.CharacterLimitType.IsomerDebuff] = {
            Name = CSXTextManagerGetText("CharacterTypeLimitNameIsomerDebuff"),
            ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeIsomerDebuffLimitImage"),
            ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterIsomerDebuffImage"),
            TextTeamEdit = function(buffDict)
                return CSXTextManagerGetText(buffDict.BuffNoColor)
            end,
            TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeIsomerDebuffLimitDefaultText"),
            TextSelectCharacter = function(buffDict)
                return CSXTextManagerGetText(buffDict.BuffWithColor)
            end,
            TextSelectCharacterDefault = CSXTextManagerGetText("TeamRequireCharacterIsomerDebuffDefaultText"),
            TextChapterLimit = function(buffDes)
                return CSXTextManagerGetText("ChapterCharacterTypeLimitIsomerDebuff", buffDes)
            end,
        },
        [XEnumConst.FuBen.CharacterLimitType.NormalDebuff] = {
            Name = CSXTextManagerGetText("CharacterTypeLimitNameNormalDebuff"),
            ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeNormalDebuffLimitImage"),
            ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterNormalDebuffImage"),
            TextTeamEdit = function(buffDict)
                return CSXTextManagerGetText(buffDict.BuffNoColor)
            end,
            TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeNormalDebuffLimitDefaultText"),
            TextSelectCharacter = function(buffDict)
                return CSXTextManagerGetText(buffDict.BuffWithColor)
            end,
            TextSelectCharacterDefault = CSXTextManagerGetText("TeamRequireCharacterNormalDebuffDefaultText"),
            TextChapterLimit = function(buffDes)
                return CSXTextManagerGetText("ChapterCharacterTypeLimitNormalDebuff", buffDes)
            end,
        },
    }

    self.RegFubenDict = {}
    self.TempCustomFunc = {}
    --self._TempCustomFunc = {}
    
    self.OutdateRegFubenDict = {}
    
    self.InitStageInfoHandler = {}
    self.CheckPreFightHandler = {}
    self.CustomOnEnterFightHandler = {}
    self.PreFightHandler = {}
    self.FinishFightHandler = {}
    self.CallFinishFightHandler = {}
    self.OpenFightLoadingHandler = {}
    self.CloseFightLoadingHandler = {}
    self.ShowSummaryHandler = {}
    self.SettleFightHandler = {}
    self.CheckReadyToFightHandler = {}
    self.CheckAutoExitFightHandler = {}
    self.ShowRewardHandler = {}
    self.CheckStageIsUnlockHandler = {}
    self.CheckStageIsPassHandler = {}
    self.CustomRecordFightBeginDataHandler = {}
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
    self._StageEventInfos = {}
    self.TempCustomFunc = {}
end

----------public start----------
function XFubenModel:SetPlayerStageData(key, value)
    self._PlayerStageData[key] = value
end

function XFubenModel:SetUnlockHideStages(key)
    self._UnlockHideStages[key] = true
end

function XFubenModel:SetStageEventInfo(eventInfo)
    self._StageEventInfos[eventInfo.StageId] = eventInfo
end

-- 战斗结束更新关卡信息
function XFubenModel:UpdateStageEventInfo()
    local result = self:GetCurFightResult()
    if result and result.IsWin and result.CustomData and result.CustomData:ContainsKey(XPlayer.Id) then
        local customData = result.CustomData[XPlayer.Id]
        local eventInfo = self._StageEventInfos[result.StageId]
        if not eventInfo then
            eventInfo = { StageId = result.StageId, EventIdMap = {} }
        end

        local e = customData.Dict:GetEnumerator()
        while e:MoveNext() do
            eventInfo.EventIdMap[e.Current.Key] = e.Current.Value
        end
        e:Dispose()
        
        self:SetStageEventInfo(eventInfo)
    end
end

function XFubenModel:GetStageEventValue(stageId, eventId)
    local eventInfo = self._StageEventInfos[stageId]
    if eventInfo then
        return eventInfo.EventIdMap[eventId]
    end
    return
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
end

---获取进入战斗数据
function XFubenModel:GetBeginData()
    return self._BeginData
end

---设置副本结算数据
function XFubenModel:SetFubenSettleResult(value)
    self._FubenSettleResult = value
end

---获取副本结算状态
function XFubenModel:GetFubenSettleResult()
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
end

function XFubenModel:GetLastDpsTable()
    return self._LastDpsTable
end

function XFubenModel:SetCurFightResult(value)
    self._CurFightResult = value
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
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageType, stageId)
end

------获取整个副本配置表
function XFubenModel:GetStageCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.Stage)
end

function XFubenModel:GetStageLevelMap()
    if not self._StageLevelMap then
        self:InitStageLevelMap()
    end
    return self._StageLevelMap
end

function XFubenModel:GetStageMultiplayerLevelMap()
    if not self._StageMultiplayerLevelMap then
        self:InitStageMultiplayerLevelMap()
    end
    return self._StageMultiplayerLevelMap
end

function XFubenModel:GetStageRelationInfos()
    if not self._StageRelationInfos then
        self:InitStageInfoRelation()
    end
    return self._StageRelationInfos
end

----配置表相关end

---获取关卡信息
---@param stageId number 关卡id
function XFubenModel:GetStageInfo(stageId)
    return self._StageInfos and self._StageInfos[stageId]
end

function XFubenModel:GetStageInfos()
    return self._StageInfos
end

---获取所有关卡信息
function XFubenModel:DebugGetStageInfos()
    return self._StageInfos
end

---获取玩家副本信息
function XFubenModel:GetPlayerStageDataById(stageId)
    return self._PlayerStageData[stageId]
end

function XFubenModel:GetPlayerStageData()
    return self._PlayerStageData
end



----------public end----------

----------private start----------
function XFubenModel:GetStageCfg(stageId, ignoreError)
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

        local stageType = stageCfg.Type
        if XTool.IsNumberValid(stageType) then
            info.Type = stageCfg.Type
        else
            if stageType >= XEnumConst.FuBen.StageType.Transfinite then
                XLog.Error("[XFubenManager] stage表未配置Type, 关卡id:" .. stageId)
            end
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
--region config
function XFubenModel:GetBuffDes(buffId)
    local fightEventCfg = buffId and buffId ~= 0 and CS.XNpcManager.GetFightEventTemplate(buffId)
    return fightEventCfg and fightEventCfg.Description or ""
end

function XFubenModel:GetStageLevelControlCfg()
    local config = self._ConfigUtil:GetByTableKey(TableKey.StageLevelControl)
    return config
end

function XFubenModel:GetStageMultiplayerLevelControlCfg()
    local config = self._ConfigUtil:GetByTableKey(TableKey.StageMultiplayerLevelControl)
    return config
end

function XFubenModel:GetStageMultiplayerLevelControlCfgById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageMultiplayerLevelControl, id)
    return config
end

function XFubenModel:GetStageTransformCfg()
    local config = self._ConfigUtil:GetByTableKey(TableKey.StageTransform)
    return config
end

function XFubenModel:GetFlopRewardTemplates()
    local config = self._ConfigUtil:GetByTableKey(TableKey.FlopReward)
    return config
end

function XFubenModel:GetActivitySortRules()
    local config = self._ConfigUtil:GetByTableKey(TableKey.ActivitySortRule)
    return config
end

function XFubenModel:GetFeaturesById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenFeatures, id)
    return config
end

function XFubenModel:GetActivityPriorityByActivityIdAndType(activityId, type)
    local activitySortRules = self:GetActivitySortRules()
    for _, v in pairs(activitySortRules) do
        if v.Type == type
                and (not not XTool.IsNumberValid(activityId)
                or not XTool.IsNumberValid(v.Activity)
                or v.ActivityId == activityId) then
            return v.Priority
        end
    end
    return 0
end

function XFubenModel:GetStageFightControl(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageFightControl, id, true)
    return config
end

function XFubenModel:IsKeepPlayingStory(stageId)
    local targetCfg = self:GetStageCfg(stageId)
    if not targetCfg or not targetCfg.KeepPlayingStory then
        return false
    end
    return targetCfg.KeepPlayingStory == 1
end

function XFubenModel:GetChapterBannerByType(bannerType)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenChallengeBanner, bannerType)
    return config or {}
end

function XFubenModel:InitNewChallengeConfigs()
    self._FubenNewChallenge = {}
    local config = self._ConfigUtil:GetByTableKey(TableKey.FubenChallengeBanner)
    for _, v in pairs(config) do
        if v.ShowNewStartTime and v.ShowNewEndTime then
            local timeNow = XTime.GetServerNowTimestamp()
            local startTime = XTime.ParseToTimestamp(v.ShowNewStartTime)
            local endTime = XTime.ParseToTimestamp(v.ShowNewEndTime)
            if endTime and timeNow <= endTime then
                table.insert(self._FubenNewChallenge, v)
            end
            if startTime > endTime then
                XLog.Error("新挑战活动配置有误，起始时间晚于结束时间，表路径：FubenChallengeBanner 问题Id :" .. tostring(v.Id))
            end
        end
    end
    return self._FubenNewChallenge
end

function XFubenModel:GetNewChallengeConfigs()
    -- 获取新挑战玩法数据
    return self._FubenNewChallenge or self:InitNewChallengeConfigs()
end

function XFubenModel:GetNewChallengeConfigById(id)
    -- 根据Id取得FubenChallengeBanner配置
    local config = self._ConfigUtil:GetByTableKey(TableKey.FubenChallengeBanner)
    for i in pairs(config) do
        if config[i].Id == id then
            return config[i]
        end
    end
    return nil
end

function XFubenModel:GetNewChallengeConfigsLength()
    -- 获取新活动数量
    local config = self:GetNewChallengeConfigs()
    return #config
end

function XFubenModel:GetNewChallengeFunctionId(index)
    local config = self:GetNewChallengeConfigs()
    if not config[index] then
        return 0
    end
    return config[index].FunctionId
end

function XFubenModel:GetNewChallengeId(index)
    -- 根据索引获取新挑战活动的Id
    local config = XFubenConfigs.GetNewChallengeConfigs()
    if not config[index] then
        return 0
    end
    return config[index].Id
end

function XFubenModel:GetNewChallengeStartTimeStamp(index)
    local config = XFubenModel:GetNewChallengeConfigs()
    if not config[index] then
        return 0
    end
    return XTime.ParseToTimestamp(config[index].ShowNewStartTime)
end

function XFubenModel:GetNewChallengeEndTimeStamp(index)
    local config = self:GetNewChallengeConfigs()
    if not config[index] then
        return 0
    end
    return XTime.ParseToTimestamp(config[index].ShowNewEndTime)
end

function XFubenModel:IsNewChallengeStartByIndex(index)
    -- 根据索引获取新挑战时段是否已经开始
    return self:GetNewChallengeStartTimeStamp(index) <= XTime.GetServerNowTimestamp()
end

function XFubenModel:IsNewChallengeStartById(id)
    -- 根据挑战活动Id获取新挑战时段是否已经开始
    if not id then
        return false
    end
    local cfg = self:GetNewChallengeConfigById(id)
    if not cfg or not cfg.ShowNewStartTime then
        return false
    end
    return XTime.ParseToTimestamp(cfg.ShowNewStartTime) <= XTime.GetServerNowTimestamp()
end

function XFubenModel:GetMultiChallengeStageConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.MultiChallengeStage)
end

function XFubenModel:GetTableStagePath()
    return "Share/Fuben/Stage.tab"
end

function XFubenModel:GetStageCharacterLimitConfig(characterLimitType)
    return self._ROOM_CHARACTER_LIMIT_CONFIGS[characterLimitType]
end

function XFubenModel:GetStageCharacterLimitType(stageId)
    return self:GetStageCfg(stageId).CharacterLimitType
end

function XFubenModel:GetStageCareerSuggestTypes(stageId)
    local result = {}
    local content = self:GetStageCfg(stageId).CareerSuggestType
    if content == nil then
        return result
    end
    for _, v in ipairs(string.Split(content, "|")) do
        if v ~= "0" then
            table.insert(result, tonumber(v))
        end
    end
    return result
end

function XFubenModel:GetStageAISuggestType(stageId)
    return self:GetStageCfg(stageId).AISuggestType
end

function XFubenModel:GetStageCharacterLimitBuffId(stageId)
    local limitBuffId = self:GetStageCfg(stageId).LimitBuffId
    return self:GetLimitShowBuffId(limitBuffId)
end

function XFubenModel:GetLimitShowBuffId(limitBuffId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageCharacterLimit, limitBuffId, true)
    local buffIds = config and config.BuffId
    return buffIds and buffIds[1] or 0
end

function XFubenModel:IsStageCharacterLimitConfigExist(characterLimitType)
    return self:GetStageCharacterLimitConfig(characterLimitType) and true
end

-- 编队界面限制角色类型Icon
function XFubenModel:GetStageCharacterLimitImageTeamEdit(characterLimitType)
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end
    return config.ImageTeamEdit
end

-- 编队界面限制角色类型文本
function XFubenModel:GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end

    --local text = config.TextTeamEdit
    local defaultText = config.TextTeamEditDefault
    if not defaultText then
        return ""
    end

    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    if characterType and characterType ~= defaultCharacterType then
        --if type(text) == "function" then
        local buffDes = self:GetBuffDes(buffId)
        return buffDes
        --end
    else
        return defaultText
    end

    return ""
end

function XFubenModel:GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
    if isColorText == nil then
        isColorText = false
    end
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end
    local text = isColorText and config.TextSelectCharacter or config.TextTeamEdit
    local defaultText = isColorText and config.TextSelectCharacterDefault or config.TextTeamEditDefault
    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    local diffCount = 0 -- 与建议上阵的差异数量
    local rightCount = 0 -- 对应的数量
    for _, value in ipairs(characterTypes) do
        if value ~= defaultCharacterType then
            diffCount = diffCount + 1
        else
            rightCount = rightCount + 1
        end
    end
    local configDic = self:GetCharacterLimitBuffDic(characterLimitType)
    if configDic == nil then
        return defaultText
    end
    local buffDict = {}
    if configDic[diffCount] and configDic[diffCount][rightCount] then
        buffDict = configDic[diffCount][rightCount]
    end
    if buffDict == nil or XTool.IsTableEmpty(buffDict) then
        return defaultText
    end
    if type(text) == "function" then
        return text(buffDict)
    else
        return defaultText
    end
end

-- 选人界面限制角色类型Icon
function XFubenModel:GetStageCharacterLimitImageSelectCharacter(characterLimitType)
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end
    return config.ImageSelectCharacter
end

-- 选人界面限制角色类型文本
function XFubenModel:GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end

    --local text = config.TextSelectCharacter
    local defaultText = config.TextSelectCharacterDefault
    if not defaultText then
        return ""
    end

    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    if characterType ~= defaultCharacterType then
        --if type(text) == "function" then
        --    if not XTool.IsNumberValid(buffId) then
        --        return defaultText
        --    end

        local buffDes = self:GetBuffDes(buffId)
        return buffDes
        --end
    else
        return defaultText
    end

    return ""
end

-- 限制角色类型分区名称文本
function XFubenModel:GetStageCharacterLimitName(characterLimitType)
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end
    return config.Name
end

-- 章节选人界面限制角色类型文本
function XFubenModel:GetChapterCharacterLimitText(characterLimitType, buffId)
    local config = self:GetStageCharacterLimitConfig(characterLimitType)
    if not config then
        return ""
    end

    local text = config.TextChapterLimit
    if type(text) == "function" then
        local buffDes = self:GetBuffDes(buffId)
        return text(buffDes)
    end
    return text
end

function XFubenModel:GetTeamBuffCfg(teamBuffId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageTeamBuff, teamBuffId)
end

function XFubenModel:IsCharacterFitTeamBuff(teamBuffId, characterId)
    if not teamBuffId or teamBuffId <= 0 then
        return false
    end
    if not characterId or characterId <= 0 then
        return false
    end

    local config = self:GetTeamBuffCfg(teamBuffId)

    local initQuality = characterId and characterId > 0 and XMVCA.XCharacter:GetCharMinQuality(characterId)
    if not initQuality or initQuality <= 0 then
        return false
    end

    for _, quality in pairs(config.Quality) do
        if initQuality == quality then
            return true
        end
    end

    return false
end

function XFubenModel:GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    local config = self:GetTeamBuffCfg(teamBuffId)

    local fitCount = 0

    local checkDic = {}
    for _, quality in pairs(config.Quality) do
        checkDic[quality] = true
    end

    for _, characterId in pairs(characterIds) do
        local initQuality = characterId > 0 and XMVCA.XCharacter:GetCharMinQuality(characterId)
        fitCount = checkDic[initQuality] and fitCount + 1 or fitCount
    end

    return fitCount
end

function XFubenModel:GetTeamBuffMaxCountDic()
    if not self._TeamBuffMaxCountDic then
        self._TeamBuffMaxCountDic = {}
        local config = self._ConfigUtil:GetByTableKey(TableKey.StageTeamBuff)
        for id, v in pairs(config) do
            local maxCount = 0
            for _, buffId in ipairs(v.BuffId) do
                if buffId > 0 then
                    maxCount = maxCount + 1
                end
            end
            self._TeamBuffMaxCountDic[id] = maxCount
        end
    end
    return self._TeamBuffMaxCountDic
end

function XFubenModel:GetTeamBuffMaxBuffCount(teamBuffId)
    return self:GetTeamBuffMaxCountDic()[teamBuffId] or 0
end

function XFubenModel:GetTeamBuffOnIcon(teamBuffId)
    local config = self:GetTeamBuffCfg(teamBuffId)
    return config.OnIcon
end

function XFubenModel:GetTeamBuffOffIcon(teamBuffId)
    local config = self:GetTeamBuffCfg(teamBuffId)
    return config.OffIcon
end

function XFubenModel:GetTeamBuffTitle(teamBuffId)
    local config = self:GetTeamBuffCfg(teamBuffId)
    return config.Title
end

function XFubenModel:GetTeamBuffDesc(teamBuffId)
    local config = self:GetTeamBuffCfg(teamBuffId)
    return string.gsub(config.Desc, "\\n", "\n")
end

-- 根据符合初始品质要求的characterId列表获取对应的同调加成buffId
function XFubenModel:GetTeamBuffShowBuffId(teamBuffId, characterIds)
    local config = self:GetTeamBuffCfg(teamBuffId)
    local fitCount = XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    return config.BuffId[fitCount]
end

-- 根据关卡ID查找关卡词缀列表
function XFubenModel:GetStageFightEventByStageId(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageFightEvent, stageId)
    -- todo by zlb
    if not config then
        --XLog.ErrorTableDataNotFound(
        --        "XFubenConfigs.GetStageFightEventByStageId",
        --        "通用关卡词缀数据",
        --        "Share/Fuben/StageFightEvent.tab",
        --        "StageId",
        --        tostring(stageId)
        --)
        return {}
    end
    return config
end

-- 根据ID查找词缀详细
function XFubenModel:GetStageFightEventDetailsByStageFightEventId(eventId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageFightEventDetails, eventId)
    -- todo by zlb
    if not config then
        --XLog.ErrorTableDataNotFound(
        --        "XFubenConfigs.GetStageFightEventDetailsByStageFightEventId",
        --        "通用关卡词缀数据",
        --        "Client/Fuben/StageFightEventDetails.tab",
        --        "Id",
        --        tostring(eventId)
        --)
        return nil
    end
    return config
end

function XFubenModel:GetSettleLoseTipCfg(settleLoseTipId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SettleLoseTip, settleLoseTipId)
end

---
--- 获取 失败提示描述 数组
function XFubenModel:GetTipDescList(settleLoseTipId)
    local cfg = self:GetSettleLoseTipCfg(settleLoseTipId)
    return cfg.TipDesc
end

---
--- 获取 失败提示跳转Id 数组
function XFubenModel:GetSkipIdList(settleLoseTipId)
    local cfg = self:GetSettleLoseTipCfg(settleLoseTipId)
    return cfg.SkipId
end

--获取关卡推荐角色类型（构造体/感染体）
function XFubenModel:GetStageRecommendCharacterType(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageRecommend, stageId)
    if not config then
        return
    end

    local value = config.CharacterType
    return value ~= 0 and value or nil
end

--获取关卡推荐角色元素属性（物理/火/雷/冰/暗）
function XFubenModel:GetStageRecommendCharacterElement(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageRecommend, stageId)
    if not config then
        return
    end

    local value = config.CharacterElement
    return value ~= 0 and value or nil
end

--是否为关卡推荐角色
function XFubenModel:IsStageRecommendCharacterType(stageId, id)
    local characterId = XRobotManager.GetCharacterId(id)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local recommendType = self:GetStageRecommendCharacterType(stageId)
    local element = XMVCA.XCharacter:GetCharacterElement(characterId)
    local recommendElement = self:GetStageRecommendCharacterElement(stageId) or 0
    --(废弃)特殊逻辑：如果为授格者，一定是推荐(废弃)
    --if characterType == XEnumConst.CHARACTER.CharacterType.Isomer and recommendType == characterType then
    --    return true
    --end

    --为【SP区】优先上阵独域角色
    if (recommendType == XEnumConst.CHARACTER.CharacterType.Sp) and
            (characterType == XEnumConst.CHARACTER.CharacterType.Isomer or characterType == XEnumConst.CHARACTER.CharacterType.Sp) then
        return true
    end

    --特殊逻辑：当关卡推荐元素为0时推荐所有该角色类型（构造体/授格者）的构造体
    --（此处兼容之前废弃的《授格者一定推荐的特殊逻辑》，StageRecommend配置中的授格者类型下推荐属性都是0，故兼容）
    return XTool.IsNumberValid(recommendType) and
            recommendType == characterType and
            (element == recommendElement or recommendElement == 0)
end

function XFubenModel:GetStageName(stageId, ignoreError)
    local config = self:GetStageCfg(stageId, ignoreError)
    return config and config.Name or ""
end

function XFubenModel:GetStageDescription(stageId, ignoreError)
    local config = self:GetStageCfg(stageId, ignoreError)
    return config and config.Description or ""
end

function XFubenModel:GetStageMainlineType(stageId)
    local config = self:GetStageCfg(stageId)
    return config and config.StageType or ""
end

---
--- 关卡图标
function XFubenModel:GetStageIcon(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).Icon
end

---
--- 三星条件描述数组
function XFubenModel:GetStarDesc(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).StarDesc
end

---
--- 关卡首通奖励
function XFubenModel:GetFirstRewardShow(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).FirstRewardShow
end

---
--- 关卡非首通奖励
function XFubenModel:GetFinishRewardShow(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).FinishRewardShow
end

---
--- 获得战前剧情ID
function XFubenModel:GetBeginStoryId(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).BeginStoryId
end

---
--- 获得战后剧情ID
function XFubenModel:GetEndStoryId(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).EndStoryId
end

---
--- 获得前置关卡id
function XFubenModel:GetPreStageId(stageId)
    local config = self:GetStageCfg(stageId)
    return (config or {}).PreStageId
end

function XFubenModel:GetStageTypeCfg(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageType, stageId, true)
    return config
end

---
--- 活动特殊关卡配置机器人列表获取
function XFubenModel:GetStageTypeRobot(stageType)
    local config = self:GetStageTypeCfg(stageType)
    return (config or {}).RobotId
end

function XFubenModel:IsAllowRepeatChar(stageType)
    local config = self:GetStageTypeCfg(stageType)
    return (config or {}).MatchCharIdRepeat
end

function XFubenModel:GetStageMixCharacterLimitBuff()
    if not self._StageMixCharacterLimitBuff then
        self._StageMixCharacterLimitBuff = {}

        local characterLimitBuffConfigs = self._ConfigUtil:GetByTableKey(TableKey.StageMixCharacterLimitBuff)
        for limitType, config in pairs(characterLimitBuffConfigs) do
            self._StageMixCharacterLimitBuff[limitType] = self._StageMixCharacterLimitBuff[limitType] or {}
            for _, buffInfo in ipairs(config.BuffInfos) do
                local info = string.Split(buffInfo, "|")
                local diffCount = tonumber(info[1])
                local rightCount = tonumber(info[2])
                local buffDescNoColor = tostring(info[3])
                local buffDescWithColor = tostring(info[4])
                local tmpDic = self._StageMixCharacterLimitBuff[limitType][diffCount] or {}
                tmpDic[rightCount] = {
                    BuffNoColor = buffDescNoColor,
                    BuffWithColor = buffDescWithColor
                }
                self._StageMixCharacterLimitBuff[limitType][diffCount] = tmpDic
            end
        end

    end
    return self._StageMixCharacterLimitBuff
end

function XFubenModel:GetCharacterLimitBuffDic(limitType)
    return self:GetStageMixCharacterLimitBuff()[limitType]
end

-----------------------关卡步骤跳过相关------------------------
function XFubenModel:GetStepSkipListByStageId(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageStepSkip, stageId, true)
    return config and config.SkipStep
end

function XFubenModel:CheckStepIsSkip(stageId, stepSkipType)
    local skipList = self:GetStepSkipListByStageId(stageId)
    for _, skip in pairs(skipList or {}) do
        if skip == stepSkipType then
            return true
        end
    end
    return false
end


--region 暂停界面uiSet，显示可配置的玩法说明
function XFubenModel:GetStageGamePlayDesc(stageType)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageGamePlayDesc, stageType, true)
    return config
end

function XFubenModel:HasStageGamePlayDesc(stageType)
    return self:GetStageGamePlayDesc(stageType) and true or false
end

function XFubenModel:GetStageGamePlayBtnVisible(stageType)
    return self:GetStageGamePlayDesc(stageType)
end

function XFubenModel:GetStageGamePlayTitle(stageType)
    if self:HasStageGamePlayDesc(stageType) then
        return self:GetStageGamePlayDesc(stageType).Title
    end
end

function XFubenModel:GetStageGamePlayDescDataSource(stageType)
    if not self._StageGamePlayDataSource then
        self._StageGamePlayDataSource = {}
        local config = self._ConfigUtil:GetByTableKey(TableKey.StageGamePlayDescSheet)
        for id, cfg in pairs(config) do
            local type = cfg.StageType
            self._StageGamePlayDataSource[type] = self._StageGamePlayDataSource[type] or {}
            local classified = self._StageGamePlayDataSource[type]
            classified[#classified + 1] = cfg
        end
    end
    return self._StageGamePlayDataSource[stageType] or {}
end

function XFubenModel:GetFubenActivityConfigByManagerName(managerName)
    local activityConfigs = self._ConfigUtil:GetByTableKey(TableKey.FubenActivity)
    for _, config in ipairs(activityConfigs) do
        if config.ManagerName == managerName then
            return config
        end
    end
    return {}
end

function XFubenModel:GetSecondTagConfigsByFirstTagId(firstTagId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FubenSecondTag)
    local result = {}
    for _, config in ipairs(configs) do
        if config.FirstTagId == firstTagId then
            table.insert(result, config)
        end
    end
    table.sort(result, function(tagConfigA, tagConfigB)
        return tagConfigA.Order and tagConfigB.Order and (tagConfigA.Order < tagConfigB.Order)
    end)
    return result
end

function XFubenModel:GetSecondTagConfigById(id)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FubenSecondTag)
    return configs[id]
end

function XFubenModel:GetCollegeChapterBannerByType(chapterType)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.FubenCollegeBanner)
    for _, config in ipairs(configs) do
        if config.Type == chapterType then
            return config
        end
    end
end

function XFubenModel:GetActivityPanelPrefabPath()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "ActivityPanelPrefab").Values[1]
end

function XFubenModel:GetMainPanelTimeId()
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "MainPanelTimeId").Values[1])
end

function XFubenModel:GetMainFestivalBg()
    -- 覆盖其他二级标签的活动背景图
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "MainFestivalBg").Values[1]
end

function XFubenModel:GetMainPanelItemId()
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "MainPanelItemId").Values[1])
end

function XFubenModel:GetMainPanelName()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "MainPanelName").Values[1]
end

function XFubenModel:GetMain3DBgPrefab()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "Main3DBgPrefab").Values[1]
end

function XFubenModel:GetMain3DCameraPrefab()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "Main3DCameraPrefab").Values[1]
end

function XFubenModel:GetMainVideoBgUrl()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "MianVideoBgUrl").Values[1]
end

function XFubenModel:GetStageSettleWinSoundId()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "StageSettleWinSoundId").Values
end

function XFubenModel:GetStageSettleLoseSoundId()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "StageSettleLoseSoundId").Values
end

function XFubenModel:GetQxmsTryIcon()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "UiFubenQxmsTryIcon").Values[1]
end

function XFubenModel:GetQxmsUseIcon()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "UiFubenQxmsUseIcon").Values[1]
end

function XFubenModel:GetChallengeShowGridCount()
    return tonumber(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "ChallengeShowGridCount").Values[1])
end

function XFubenModel:GetChallengeShowGridList()
    local result = {}
    for i, value in ipairs(self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FubenClientConfig, "ChallengeShowGridList").Values) do
        result[#result + 1] = tonumber(value)
    end
    return result
end

-- 判断副本主界面是否是用3D场景
function XFubenModel:GetIsMainHave3DBg()
    return not string.IsNilOrEmpty(self:GetMain3DBgPrefab())
end

-- 判断副本主界面是否是用视频背景
function XFubenModel:GetIsMainHaveVideoBg()
    return not string.IsNilOrEmpty(self:GetMainVideoBgUrl())
end
--endregion

function XFubenModel:GetSettleSpecialSoundCfgByStageId(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.StageSettleSpecialSound, stageId, true)
    return config or {}
end

-- 获取关卡跳转配置
function XFubenModel:GetConfigStageTeleport(stageId)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.StageTeleport)
    return cfgs[stageId]
end
--endregion
----------config end----------

function XFubenModel:RegisterOldRegFubenDict(stageType, processFunc, handler)
    self.OutdateRegFubenDict[stageType] = self.OutdateRegFubenDict[stageType] or {}
    self.OutdateRegFubenDict[stageType][processFunc] = handler
end

return XFubenModel