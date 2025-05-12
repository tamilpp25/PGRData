-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    PcgActivity = { CacheType = XConfigUtil.CacheType.Normal },
    PcgChapter = { CacheType = XConfigUtil.CacheType.Normal },
    PcgCharacterType = {},
    PcgStage = { CacheType = XConfigUtil.CacheType.Normal },
    PcgCharacter = {},
    PcgEffects = {},
    PcgMonster = {},
    PcgMonsterBehavior = {},
    PcgCards = {},
    PcgToken = {},
    PcgClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    PcgCharacterTag = { DirPath = XConfigUtil.DirectoryType.Client },
    PcgTeam = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XPcgModel : XModel
local XPcgModel = XClass(XModel, "XPcgModel")
function XPcgModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    
    --config相关
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/PunishingCardGame", TableKey)

    ---@type XPcgActivity
    self.ActivityData = nil
    ---@type XPcgPlayingStage
    self.PlayingStageData = nil
    
    self._GameState = nil                                           -- 游戏状态
    self._RoundState = nil                                          -- 回合状态
    self._CacheNextPlayingStageData = nil                           -- 缓存下一回合关卡数据
    self._CacheEffectSettles = nil                                  -- 缓存结算效果列表
    ---@type table<number, XPcgRoundLog>
    self._RoundLogDic = nil                                         -- 回合记录
end

function XPcgModel:ClearPrivate()
    --这里执行内部数据清理
end

function XPcgModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self.PlayingStageData = nil
    self._CacheNextPlayingStageData = nil
    self._CacheEffectSettles = nil
    self._RoundLogDic = nil
    self.NewUnlockCharacterIds = nil
end

--region 配置表读取
-- 获取活动表
function XPcgModel:GetConfigActivity(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgActivity, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgActivity)
    end
end

-- 获取当前活动TimeId
function XPcgModel:GetActivityTimeId()
    if self.ActivityData then
        local config = self:GetConfigActivity(self:GetActivityId())
        return config and config.TimeId or 0
    end
    return 0
end

-- 检测活动是否在开启时间内
function XPcgModel:CheckActivityInTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

-- 获取活动的结束时间
function XPcgModel:GetActivityEndTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 获取活动核心奖励
function XPcgModel:GetActivityRewardId()
    local config = self:GetConfigActivity(self:GetActivityId())
    return config and config.RewardId or 0
end

-- 获取任务组Id列表
function XPcgModel:GetActivityTaskGroupIds()
    local config = self:GetConfigActivity(self:GetActivityId())
    return config and config.TaskGroupIds or {}
end

-- 获取任务组名称列表
function XPcgModel:GetActivityTaskGroupNames()
    local config = self:GetConfigActivity(self:GetActivityId())
    return config and config.TaskGroupNames or {}
end

-- 获取章节表
function XPcgModel:GetConfigChapter(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgChapter, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgChapter)
    end
end

-- 获取活动对应的章节配置表
function XPcgModel:GetActivityChapterConfigs()
    local result = {}
    local activityId = self:GetActivityId()
    local cfgs = self:GetConfigChapter()
    for _, cfg in pairs(cfgs) do
        if cfg.ActivityId == activityId then
            table.insert(result, cfg)
        end
    end
    table.sort(result, function(a, b) return a.Id < b.Id end)
    return result
end

-- 获取章节关卡列表
function XPcgModel:GetChapterStageIds(chapterId)
    local stageIds = {}
    local chapterCfg = self:GetConfigChapter(chapterId)
    for i, stageId in ipairs(chapterCfg.StageIds) do
        table.insert(stageIds, stageId)
    end
    -- 无尽关最后显示
    if chapterCfg.ChallengeStageId ~= 0 then
        table.insert(stageIds, chapterCfg.ChallengeStageId)
    end
    return stageIds
end

-- 获取关卡表
function XPcgModel:GetConfigStage(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgStage, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgStage)
    end
end

-- 获取关卡类型
function XPcgModel:GetStageType(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.Type or 0
end

-- 获取关卡的推荐队伍
function XPcgModel:GetStageRecommendCharacterIds(stageId)
    local stageCfg = self:GetConfigStage(stageId)
    local characters = {0, 0, 0}
    for _, charId in ipairs(stageCfg.RecommendChar) do
        local charCfg = self:GetConfigCharacter(charId)
        if characters[charCfg.ColorType] ~= 0 then
            XLog.Error(string.format("请策划老师检查关卡%s的推荐角色，存在相同的ColorType = %s, RecommendChar = %s，", stageId, charCfg.ColorType, XLog.Dump(stageCfg.RecommendChar)))
        end
        characters[charCfg.ColorType] = charId
    end
    return characters
end

-- 获取下一关卡Id
function XPcgModel:GetNextStageId(stageId)
    local chapterCfgs = self:GetConfigChapter()
    for _, chapterCfg in ipairs(chapterCfgs) do
        local stageCnt = #chapterCfg.StageIds
        for i, tempStageId in ipairs(chapterCfg.StageIds) do
            if tempStageId == stageId then
                if i == stageCnt then
                    return chapterCfg.ChallengeStageId
                else
                    return chapterCfg.StageIds[i + 1]
                end
            end
        end
    end
end

-- 获取关卡类型
function XPcgModel:GetStageType(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.Type or 0
end

-- 获取关卡星级条件
function XPcgModel:GetStageStarConditions(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.StarConditions or {}
end

-- 获取关卡星级描述
function XPcgModel:GetStageStarDescs(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.StarDesc or {}
end

-- 获取关卡手牌上限
function XPcgModel:GetStageHandNum(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.HandNum or 0
end

-- 获取关卡初始行动点
function XPcgModel:GetStageInitActionPoint(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.InitActionPoint or 0
end

-- 获取关卡指挥官最大血量
function XPcgModel:GetStageMaxHp(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.MaxHp or 0
end

-- 获取关卡指挥官最大能量
function XPcgModel:GetStageMaxEnergy(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.MaxEnergy or 0
end

-- 获取关卡是否可使用指挥官技能
function XPcgModel:GetStageEnablePlayerSkill(id)
    local stageCfg = self:GetConfigStage(id)
    return stageCfg and stageCfg.EnablePlayerSkill == 1 or false
end

-- 获取角色表
function XPcgModel:GetConfigCharacter(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgCharacter, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgCharacter)
    end
end

-- 获取角色的胜利CvId
function XPcgModel:GetCharacterFinishCv(charId)
    local cfg = self:GetConfigCharacter(charId)
    return cfg and cfg.FinishCv or 0
end

-- 获取角色的QteCvId
function XPcgModel:GetCharacterQteCv(charId)
    local cfg = self:GetConfigCharacter(charId)
    return cfg and cfg.QteCv or 0
end

-- 角色是否包含效果
function XPcgModel:IsCharacterContainEffectId(charId, effectId)
    local cfg = self:GetConfigCharacter(charId)
    for _, passiveEffectId in ipairs(cfg.CorePassiveEffects) do
        if passiveEffectId == effectId then
            return true
        end
    end
    return false
end

-- 获取解锁的角色Id列表
function XPcgModel:GetUnlockCharacterIds(stageId, colorType)
    -- 已解锁角色Id
    local charIdDic = {}
    local charCfgs = self:GetConfigCharacter()
    for _, cfg in pairs(charCfgs) do
        local isUnlock = self:IsCharacterUnlock(cfg.Id)
        if cfg.ColorType == colorType and isUnlock then
            charIdDic[cfg.Id] = true
        end
    end
    
    -- 关卡推荐角色Id
    local stageCfg = self:GetConfigStage(stageId)
    for _, recommendCharId in pairs(stageCfg.RecommendChar) do
        local cfg = self:GetConfigCharacter(recommendCharId)
        if cfg.ColorType == colorType then
            charIdDic[cfg.Id] = true
        end
    end
    
    local result = {}
    for charId, _ in pairs(charIdDic) do
        table.insert(result, charId)
    end
    table.sort(result)
    return result
end

-- 获取角色上锁提示
function XPcgModel:GetCharacterLockTips(characterId)
    local chapterCfgs = self:GetConfigChapter()
    for _, chapterCfg in pairs(chapterCfgs) do
        for _, unlockCharacterId in pairs(chapterCfg.CharacterUnlockIds) do
            if unlockCharacterId == characterId then
                local tips = self:GetClientConfig("CharacterUnlockTips")
                return string.format(tips, chapterCfg.Name) 
            end
        end
    end
    return ""
end

function XPcgModel:GetConfigCharacterType(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgCharacterType, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgCharacterType)
    end
end

-- 获取效果表
function XPcgModel:GetConfigEffect(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgEffects, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgEffects)
    end
end

function XPcgModel:GetEffectShowDesc(id)
    local cfg = self:GetConfigEffect(id)
    return cfg and cfg.ShowDesc or ""
end

function XPcgModel:GetEffectCv(id)
    local cfg = self:GetConfigEffect(id)
    return cfg and cfg.Cv or 0
end

-- 获取怪物表
function XPcgModel:GetConfigMonster(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgMonster, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgMonster)
    end
end

-- 获取怪物行为表
function XPcgModel:GetConfigMonsterBehavior(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgMonsterBehavior, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgMonsterBehavior)
    end
end

-- 获取关卡的Boss级别怪物Id，优先取Id大的
function XPcgModel:GetStageBossMonsterId(stageId)
    local stageCfg = self:GetConfigStage(stageId)
    local groupId = stageCfg.MonsterGroup
    local monsterCfgs = self:GetConfigMonster()
    local monsterId = 0
    for _, monsterCfg in pairs(monsterCfgs) do
        if monsterCfg.Group == groupId and monsterCfg.Type == XEnumConst.PCG.MONSTER_TYPE.BOSS and monsterCfg.Id > monsterId then
            monsterId = monsterCfg.Id
        end
    end
    return monsterId
end

-- 获取手牌表
function XPcgModel:GetConfigCards(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgCards, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgCards)
    end
end

function XPcgModel:GetCardType(id)
    local cardCfg = self:GetConfigCards(id)
    return cardCfg and cardCfg.Type or 0
end

function XPcgModel:GetCardColor(id)
    local cardCfg = self:GetConfigCards(id)
    return cardCfg and cardCfg.Color or 0
end

-- 获取标记表
function XPcgModel:GetConfigToken(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgToken, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgToken)
    end
end

function XPcgModel:GetTokenIsShow(id)
    local tokenCfg = self:GetConfigToken(id)
    return tokenCfg and tokenCfg.IsShow == 1 or false
end

-- 获取手牌的角色头像
function XPcgModel:GetCardCharacterHeadIcon(id)
    local charCfgs = self:GetConfigCharacter()
    for _, charCfg in pairs(charCfgs) do
        if charCfg.SignatureCardId == id then
            return charCfg.HeadIconCircle
        end
    end
    return ""
end

-- 获取ClientConfig表配置
function XPcgModel:GetClientConfig(key, index)
    if index == nil then index = 1 end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgClientConfig, key)
    return config and config.Params[index] or ""
end

-- 获取ClientConfig表配置所有参数
function XPcgModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgClientConfig, key)
    return config and config.Params or {}
end

-- 获取角色标签配置
function XPcgModel:GetConfigCharacterTag(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgCharacterTag, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgCharacterTag)
    end
end

-- 获取队伍配置
function XPcgModel:GetConfigTeam(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PcgTeam, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.PcgTeam)
    end
end

-- 获取队伍名称
function XPcgModel:GetTeamName(characterIds)
    local cfgs = self:GetConfigTeam()
    for _, cfg in pairs(cfgs) do
        if cfg.CharacterIdColor1 == characterIds[1] and cfg.CharacterIdColor2 == characterIds[2] and cfg.CharacterIdColor3 == characterIds[3] then
            return cfg.Name
        end
    end
end

--endregion

--region 协议数据
-- 通知玩法数据
function XPcgModel:PcgStagesNotify(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XPcg/XEntity/XPcgActivity").New()
    end
    self.ActivityData:PcgStagesNotify(data)
    if data.PlayingStage then
        self:RefreshPlayingStageData(data.PlayingStage)
    end
end

-- 刷新关卡记录
function XPcgModel:RefreshStageRecord(stageId, stageData)
    if not self.ActivityData or not stageData then return end
    self.LastStageRecord = stageData
    self.ActivityData:RefreshStageRecord(stageId, stageData)
end

-- 获取上一次通关记录
function XPcgModel:GetLastStageRecord()
    return self.LastStageRecord
end

-- 关卡开始
function XPcgModel:OnStageBegin(playingStage)
    self.NewUnlockCharacterIds = nil
    self._CacheEffectSettles = {}
    self._RoundLogDic = {}
    self:RefreshPlayingStageData(playingStage)
    self:SetGameState(XEnumConst.PCG.GAME_STATE.Init) -- 游戏初始化
    self:SetRoundState(XEnumConst.PCG.ROUND_STATE.PLAY_CARDS) -- 开始游戏/重新开始游戏都是从我方出牌开始
end

-- 关卡继续
function XPcgModel:OnStageContinue()
    self:UseCacheNextPlayingStageData()
    self:SetGameState(XEnumConst.PCG.GAME_STATE.Init) -- 游戏初始化
    self:SetRoundState(XEnumConst.PCG.ROUND_STATE.PLAY_CARDS) -- 继续游戏是从我方出牌开始
end

-- 刷新卡关数据
function XPcgModel:RefreshPlayingStageData(data)
    if not self.PlayingStageData then
        self.PlayingStageData = require("XModule/XPcg/XEntity/XPcgPlayingStage").New()
    end
    self.PlayingStageData:RefreshData(data)

    -- 游戏结束
    if data.IsStageFinished then
        self:SetGameState(XEnumConst.PCG.GAME_STATE.End)
    end
end

-- 刷新指挥官数据
function XPcgModel:RefreshCommander(commanderData)
    if not self.PlayingStageData then return end
    self.PlayingStageData:RefreshCommanderData(commanderData)
end

-- 刷新手牌
function XPcgModel:RefreshHandPool(commanderData)
    if not self.PlayingStageData then return end
    self.PlayingStageData:RefreshHandPool(commanderData)
end

-- 设置关卡结束
function XPcgModel:SetStageFinished()
    if self.PlayingStageData then
        self.PlayingStageData:SetStageFinished()
    end
    self:SetGameState(XEnumConst.PCG.GAME_STATE.End)
end

-- 缓存下一回合关卡数据
function XPcgModel:CacheNextPlayingStageData(playingStageData)
    self._CacheNextPlayingStageData = playingStageData
end

-- 应用缓存的下一回合关卡数据
function XPcgModel:UseCacheNextPlayingStageData()
    if self._CacheNextPlayingStageData then
        self:RefreshPlayingStageData(self._CacheNextPlayingStageData)
        self._CacheNextPlayingStageData = nil
    end
end

-- 收到效果结算
function XPcgModel:OnEffectSettleNotify(data)
    local XPcgEffectSettle = require("XModule/XPcg/XEntity/XPcgEffectSettle")
    local effectSettles = {}
    for _, v in ipairs(data.Data) do
        ---@type XPcgEffectSettle
        local effectSettle = XPcgEffectSettle.New()
        effectSettle:RefreshData(v)
        table.insert(effectSettles, effectSettle)
    end
    -- 添加到回合日志数据
    self:AddRoundLogData(effectSettles)
    -- 缓存结算效果
    self:CacheEffectSettles(effectSettles)
end

-- 收到新角色解锁
function XPcgModel:OnCharacterUnlockNotify(data)
    self.NewUnlockCharacterIds = data.NewCharacterUnlock
    self.ActivityData:OnCharacterUnlockNotify(data.NewCharacterUnlock)
end

-- 获取新解锁的角色Id列表
function XPcgModel:GetNewUnlockCharacterIds()
    return self.NewUnlockCharacterIds
end

-- 缓存结算效果列表
function XPcgModel:CacheEffectSettles(effectSettles)
    if not self._CacheEffectSettles then
        self._CacheEffectSettles = {}
    end
    for _, effectSettle in ipairs(effectSettles) do
        table.insert(self._CacheEffectSettles, effectSettle)
    end
end

-- 应用缓存的结算效果列表
function XPcgModel:UseCacheEffectSettles()
    if not self._CacheEffectSettles or #self._CacheEffectSettles == 0 then
        return {}
    end

    local effectSettles = self._CacheEffectSettles
    self._CacheEffectSettles = {}
    return effectSettles
end

-- 添加回合日志数据
function XPcgModel:AddRoundLogData(effectSettles)
    if not self._RoundLogDic then
        self._RoundLogDic = {}
    end
    local roundId = self.PlayingStageData:GetRound()
    local roundLog = self._RoundLogDic[roundId]
    if not roundLog then
        roundLog = require("XModule/XPcg/XEntity/XPcgRoundLog").New(roundId)
        self._RoundLogDic[roundId] = roundLog
    end
    if self:GetRoundState() == XEnumConst.PCG.ROUND_STATE.PLAY_CARDS then
        roundLog:AddCommanderEffectSettles(effectSettles)
    else
        roundLog:AddMonsterEffectSettles(effectSettles)
    end
end

-- 获取历史结算效果列表
function XPcgModel:GetRoundLogs()
    if not self._RoundLogDic then return {} end
    
    local roundLogs = {}
    for _, roundLog in pairs(self._RoundLogDic) do
        table.insert(roundLogs, roundLog)
    end
    table.sort(roundLogs, function(a, b) return a.RoundId < b.RoundId end)
    return roundLogs
end

-- 是否在游戏中
function XPcgModel:IsInGame()
    return self.PlayingStageData and self.PlayingStageData.IsStageFinished == false
end

-- 获取当前进行中的关卡Id
function XPcgModel:GetCurrentStageId()
    if self.PlayingStageData and not self.PlayingStageData:GetIsStageFinished() then
        return self.PlayingStageData:GetId() or 0
    end
end

-- 获取当前进行中关卡的章节Id
function XPcgModel:GetCurrentChapterId()
    local stageId = self:GetCurrentStageId()
    if XTool.IsNumberValid(stageId) then
        local chapterCfgs = self:GetConfigChapter()
        for _, chapterCfg in pairs(chapterCfgs) do
            if chapterCfg.ChallengeStageId == stageId then
                return chapterCfg.Id
            end
            for _, tempStageId in pairs(chapterCfg.StageIds) do
                if tempStageId == stageId then
                    return chapterCfg.Id
                end
            end
        end
    end
end

-- 获取上一局的关卡Id，对局结束不会清除PlayingStageData
function XPcgModel:GetLastStageId()
    return self.PlayingStageData and self.PlayingStageData:GetId() or 0
end

-- 获取上一局的角色Id列表，对局结束不会清除PlayingStageData
function XPcgModel:GetLastCharacterIds()
    local characterIds = {0, 0, 0}
    if self.PlayingStageData then
        local characters = self.PlayingStageData:GetCharacters()
        for i, char in ipairs(characters) do
            local charId = char:GetId()
            if charId ~= 0 then
                local charCfg = self:GetConfigCharacter(charId)
                characterIds[charCfg.ColorType] = charId
            end
        end
    end
    return characterIds
end

-- 获取当前活动Id
function XPcgModel:GetActivityId()
    return self.ActivityData and self.ActivityData:GetActivityId() or 0
end

-- 关卡是否解锁
function XPcgModel:IsStageUnlock(stageId)
    if not self.ActivityData then 
        return false, ""
    end
    
    local stageCfg = self:GetConfigStage(stageId)
    if stageCfg.PreStage == 0 then 
        return true, "" 
    end
    
    local isPreStagePassed = self:IsStagePassed(stageCfg.PreStage)
    local preStageCfg = self:GetConfigStage(stageCfg.PreStage)
    local tipFormat = self:GetClientConfig("StageLockTips")
    local tips = string.format(tipFormat, preStageCfg.Name)
    return isPreStagePassed, tips
end

-- 关卡是否通关
function XPcgModel:IsStagePassed(stageId)
    if not self.ActivityData then
        return false
    end

    local stageRecord = self.ActivityData:GetStageRecord(stageId)
    return stageRecord ~= nil
end

-- 章节是否解锁
function XPcgModel:IsChapterUnlock(chapterId)
    -- 未到解锁时间
    local chapterCfg = self:GetConfigChapter(chapterId)
    if chapterCfg.TimeId ~= 0 then
        local startTime = XFunctionManager.GetStartTimeByTimeId(chapterCfg.TimeId)
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime < startTime then
            local time = startTime - nowTime
            return false, XUiHelper.GetText("BossInshotBossUnlockTips", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY))
        end
    end
    
    -- 前置关卡未解锁
    local stageId = chapterCfg.StageIds[1] -- 以第一个关卡为解锁条件
    if not self:IsStageUnlock(stageId) then
        return false, chapterCfg.LockTips
    end
    
    return true, ""
end

-- 章节是否通过
function XPcgModel:IsChapterPassed(chapterId)
    local chapterCfg = self:GetConfigChapter(chapterId)
    -- 普通关
    for _, stageId in pairs(chapterCfg.StageIds) do
        local isPassed = self:IsStagePassed(stageId)
        if not isPassed then
            return false
        end
    end
    -- 无尽关
    local stageId = chapterCfg.ChallengeStageId
    if XTool.IsNumberValid(stageId) and not self:IsStagePassed(stageId) then
        return false
    end
    return true
end

-- 获取章节的星星数量
function XPcgModel:GetChapterStarCount(chapterId)
    local curStar = 0
    local allStar = 0
    local chapterCfg = self:GetConfigChapter(chapterId)
    for _, stageId in ipairs(chapterCfg.StageIds) do
        local stageCfg = self:GetConfigStage(stageId)
        local stageRecord = self.ActivityData:GetStageRecord(stageId)
        allStar = allStar + #stageCfg.StarConditions
        if stageRecord then
            curStar = curStar + stageRecord:GetStars()
        end
    end
    
    return curStar, allStar
end

-- 角色是否解锁
function XPcgModel:IsCharacterUnlock(characterId)
    return self.ActivityData and self.ActivityData:IsCharacterUnlock(characterId) or false
end

-- 获取怪物行为图标 + 怪物行为数值文本
---@param behaviorPreviews XPcgBehaviorPreview[]
function XPcgModel:GetMonsterBehaviorPreviewsIconAndTxt(behaviorPreviews)
    local icon = self:GetMonsterBehaviorIcon(behaviorPreviews)
    local txt = self:GetMonsterBehaviorValue(behaviorPreviews)
    return icon, txt
end

-- 获取怪物行为图标
---@param behaviorPreviews XPcgBehaviorPreview[]
function XPcgModel:GetMonsterBehaviorIcon(behaviorPreviews)
    local behaviorId = behaviorPreviews[1]:GetBehaviorId()
    local behaviorCfg = self:GetConfigMonsterBehavior(behaviorId)
    if not behaviorCfg or behaviorCfg.IconId == 0 then
        XLog.Error(string.format("PcgMonsterBehavior.tab对应Id = %s，未配置IconId", behaviorId))
        return
    end
    local icon = self:GetClientConfig("MonsterBehaviorIcons", behaviorCfg.IconId)
    if not icon then
        XLog.Error(string.format("PcgClientConfig.tab对应MonsterBehaviorIcons未配置Params[%s]图片", behaviorCfg.IconId))
        return
    end
    return icon
end

-- 获取怪物行为数值
-- 有伤害时需要显示  次数*伤害值
function XPcgModel:GetMonsterBehaviorValue(behaviorPreviews)
    local damages = {}
    for _, behavior in ipairs(behaviorPreviews) do
        local effectCfg = self:GetConfigEffect(behavior:GetId())
        if effectCfg and effectCfg.Type == XEnumConst.PCG.EFFECT_TYPE.ATTACK_COMMANDER_DAMAGE then
            local effectValue = behavior:GetValue()
            table.insert(damages, effectValue)
        end
    end
    if #damages > 0 then
        return #damages > 1 and tostring(damages[1]).."x"..tostring(#damages) or tostring(damages[1])
    end
    return ""
end

-- 是否显示任务蓝点
function XPcgModel:IsTaskShowRed()
    local taskGroupIds = self:GetActivityTaskGroupIds()
    for _, taskGroupId in ipairs(taskGroupIds) do
        local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
        if isShowRed then
            return true
        end
    end
    return false
end

-- 是否显示角色解锁蓝点
function XPcgModel:IsCharacterShowRed(characterId)
    local isUnlock = self:IsCharacterUnlock(characterId)
    local isReviewed = self:IsCharacterReviewedBrochure(characterId)
    if isUnlock and not isReviewed then
        return true
    end
    return false
end

-- 角色是否查看过图鉴
function XPcgModel:IsCharacterReviewedBrochure(characterId)
    local key = self:GetCharacterSaveKey(characterId)
    return XSaveTool.GetData(key) == true
end

-- 设置角色查看过图鉴
function XPcgModel:SetCharacterReviewedBrochure(characterId)
    local isUnlock = self:IsCharacterUnlock(characterId)
    if not isUnlock then return end
    local key = self:GetCharacterSaveKey(characterId)
    XSaveTool.SaveData(key, true)
end

function XPcgModel:GetCharacterSaveKey(characterId)
    local activityId = self:GetActivityId()
    return string.format("XPcgModel_GetCharacterSaveKey_%s_%s_%s", XPlayer.Id, activityId, characterId)
end

-- 是否显示章节蓝点
function XPcgModel:IsChapterShowRed(chapterId)
    if not self:IsChapterUnlock(chapterId) then return false end
    local isEntered = self:IsChapterEntered(chapterId)
    return not isEntered
end

-- 是否进入过章节
function XPcgModel:IsChapterEntered(chapterId)
    local key = self:GetChapterSaveKey(chapterId)
    return XSaveTool.GetData(key) == true
end

-- 设置进入过章节
function XPcgModel:SetChapterEntered(chapterId)
    local key = self:GetChapterSaveKey(chapterId)
    XSaveTool.SaveData(key, true)
end

function XPcgModel:GetChapterSaveKey(chapterId)
    local activityId = self:GetActivityId()
    return string.format("XPcgModel_GetChapterSaveKey_%s_%s_%s", XPlayer.Id, activityId, chapterId)
end

--endregion

--region 游戏状态、回合状态、是否正在使用指挥官技能
-- 设置游戏状态
function XPcgModel:SetGameState(gameState)
    self._GameState = gameState
end

-- 获取游戏状态
function XPcgModel:GetGameState()
    return self._GameState
end

-- 设置下一回合状态
function XPcgModel:SetNextRoundState()
    local nextRoundState = self._RoundState + 1
    local isExit = false
    for _, state in pairs(XEnumConst.PCG.ROUND_STATE) do
        if nextRoundState == state then
            isExit = true
            break
        end
    end
    -- 没有下一个，回到第一个
    if not isExit then
        nextRoundState = 1
    end
    self:SetRoundState(nextRoundState)
end

-- 设置回合状态
function XPcgModel:SetRoundState(roundState)
    self._RoundState = roundState
end

-- 获取回合状态
function XPcgModel:GetRoundState()
    return self._RoundState
end
--endregion

return XPcgModel
