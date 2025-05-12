--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local TableKey = {
    BossInshotActivity = { CacheType = XConfigUtil.CacheType.Normal },
    BossInshotBoss = {},
    BossInshotCharacter = {},
    BossInshotScore = {},
    BossInshotScoreLevel = {},
    BossInshotSkill = {},
    BossInshotStage = {},
    BossInshotTalent = {},
}
---@class XBossInshotModel : XModel
local XBossInshotModel = XClass(XModel, "XBossInshotModel")

function XBossInshotModel:OnInit()
    -- 初始化内部变量
    self._ConfigUtil:InitConfigByTableKey("Fuben/BossInshot", TableKey)
end

function XBossInshotModel:ClearPrivate()
    -- 这里执行内部数据清理
end

function XBossInshotModel:ResetAll()
    -- 这里执行重登数据清理
    self.ActivityId = nil
    self.BossUnlockDataDic = nil
    self.PassStageDataDic = nil
    self.CharacterDataDic = nil
    self.Team = nil
    self.IsPlayback = false
end

--- 获取活动是否开启
function XBossInshotModel:IsActivityOpen()
    -- 开启条件未达成
    local functionName = XFunctionManager.FunctionName.BossInshot
    if not XFunctionManager.JudgeCanOpen(functionName) then
        return false, XFunctionManager.GetFunctionOpenCondition(functionName)
    end

    -- 服务端未下发活动数据
    local activityId = self:GetActivityId()
    if not activityId or activityId == 0 then
        return false, XUiHelper.GetText("FubenRepeatNotInActivityTime")
    end

    -- 活动结束
    local config = self:GetConfigBossInshotActivity(activityId)
    local isInTime = XFunctionManager.CheckInTimeByTimeId(config.TimeId)
    if not isInTime then
        return false, XUiHelper.GetText("FubenRepeatNotInActivityTime")
    end

    return true
end

--- 获取当前开启活动
function XBossInshotModel:GetActivityId()
    return self.ActivityId
end

--- 获取活动的结束时间戳
--- @param id number 活动Id
function XBossInshotModel:GetActivityEndTime(id)
    local config = self:GetConfigBossInshotActivity(id)
    return XFunctionManager.GetEndTimeByTimeId(config.TimeId)
end

--- 设置重新战斗状态
function XBossInshotModel:SetAgainFight(isAgainFight)
    self.IsAgainFight = isAgainFight
end

--- 获取重新战斗状态
function XBossInshotModel:GetAgainFight()
    return self.IsAgainFight
end

--- 获取活动缓存队伍信息
function XBossInshotModel:GetTeam()
    if self.Team then
        return self.Team
    end

    local activityId = self:GetActivityId()
    local teamId = string.format("XBossInshot_Team_Activity%s", activityId)
    local XTeam = require("XEntity/XTeam/XTeam")
    self.Team = XTeam.New(teamId)
    return self.Team
end

--- 获取队伍信息的角色Id
function XBossInshotModel:GetTeamCharacterId()
    local entityIds = self.Team:GetEntityIds()
    for _, entityId in pairs(entityIds) do
        if entityId ~= 0 then
            return XRobotManager.GetCharacterId(entityId)
        end
    end
end

--- 关卡是否解锁
function XBossInshotModel:IsStageUnlock(inshotStageId)
    local config = self:GetConfigBossInshotStage(inshotStageId)

    -- 活动迭代：当玩家在不同id的活动中遭遇相同BossId时，需要继承之前活动中该boss难度的解锁
    local unlockData = self.BossUnlockDataDic[config.BossId]
    if unlockData and unlockData.DifficultySet then
        for _, difficulty in pairs(unlockData.DifficultySet) do
            if difficulty == config.Difficulty then
                return true
            end
        end
    end

    -- 配置condition
    if config.UnlockConditionId ~= 0 then
        local isOpen, desc = XConditionManager.CheckCondition(config.UnlockConditionId)
        return isOpen, desc
    end

    return true
end

--- 是否显示任务红点
function XBossInshotModel:IsShowTaskRed()
    local activityId = self:GetActivityId()
    local taskGroupIds = self:GetActivityTaskGroupIds(activityId)
    for _, groupId in ipairs(taskGroupIds) do
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, nil, true)
        for _, task in pairs(taskDataList) do
            if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end
    return false
end

--- 是否显示第一次进活动红点
function XBossInshotModel:IsShowFirstEnterRed()
    local saveKey = self:GetFirstEnterRedSaveKey()
    local isRemove = XSaveTool.GetData(saveKey) == true
    return not isRemove
end

--- 移除第一次进活动的红点
function XBossInshotModel:RemoveFirstEnterRed()
    local saveKey = self:GetFirstEnterRedSaveKey()
    XSaveTool.SaveData(saveKey, true)
end

function XBossInshotModel:GetFirstEnterRedSaveKey()
    local activityId = self:GetActivityId()
    return string.format("XBossInshotModel:GetFirstEnterRedSaveKey_PlayerId:%s_ActivityId:%s", XPlayer.Id, activityId)
end

--- 是否显示活动红点
function XBossInshotModel:IsShowActivityRedPoint()
    local isOpen, tips = self:IsActivityOpen()
    if not isOpen then
        return false
    end
    return self:IsShowTaskRed() or self:IsShowFirstEnterRed()
end

--- 生成最后战斗的录像数据
function XBossInshotModel:GenLastPlaybackData(bossId, score, scoreLevelIcon, difficulty)
    local characterId = self:GetTeamCharacterId()
    local time = math.floor(CS.XFight.Instance.NonPausedTime)
    local stageId = CS.XFight.Instance.FightData.StageId
    return {
        StageId = stageId,
        BossId = bossId,
        CharacterId = characterId,
        Version = CS.XInfo.Version,
        Time = time,
        Score = score,
        ScoreLevelIcon = scoreLevelIcon,
        Difficulty = difficulty,
        FightDataPath = nil, -- 在点击 覆盖/保存 时才生成录像返回文件路径
    }
end

--- 获取回放数据
function XBossInshotModel:GetPlaybackDatas(bossId)
    local saveKey = self:GetPlaybackSaveKey()
    local data = XSaveTool.GetData(saveKey)
    if not data then
        return {}
    end

    data = self:DeleteOutDataPlaybackData(data)
    return data[bossId] or {}
end

--- 获取子版本列表，输入"2.14.0" 返回{2, 14, 0}
function XBossInshotModel:GetSubVersions(version)
    local subVersions = {}
    for v in string.gmatch(version, "%d+") do
        table.insert(subVersions, tonumber(v))
    end
    return subVersions
end

--- 保存回放数据
function XBossInshotModel:SavePlaybackData(bossId, pos, playbackData)
    -- 录像数据已保存
    if playbackData.FightDataPath then
        XUiManager.TipText("BossInshotSavePlaybackRepeat")
        return
    end

    local saveKey = self:GetPlaybackSaveKey()
    local data = XSaveTool.GetData(saveKey) or {}
    local bossData = data[bossId]
    if not bossData then
        bossData = {}
        data[bossId] = bossData
    end

    -- 覆盖时删除旧录像
    local isCover = bossData[pos] ~= nil
    if isCover then
        CS.XReplayManager.DeleteFightData(bossData[pos].FightDataPath)
        bossData[pos] = nil
    end

    playbackData.FightDataPath = CS.XReplayManager.SaveLastFight()
    bossData[pos] = playbackData
    XSaveTool.SaveData(saveKey, data)

    -- 埋点
    local dict = {}
    dict["save_type"] = isCover and 2 or 1
    CS.XRecord.Record(dict, "900006", "BossInshotSavePlaybackRecord")
end

--- 删除过期版本回放
function XBossInshotModel:DeleteOutDataPlaybackData(data)
    local isDelete = false
    local curVersions = self:GetSubVersions(CS.XInfo.Version)
    for bossId, bossPlaybackDatas in pairs(data) do
        for i = 1, XEnumConst.BOSSINSHOT.BOSS_PLAYBACK_CNT do
            local playbackData = bossPlaybackDatas[i]
            if playbackData then
                local playbackVersions = self:GetSubVersions(playbackData.Version)
                if curVersions[1] ~= playbackVersions[1] or curVersions[2] ~= playbackVersions[2] then
                    CS.XReplayManager.DeleteFightData(playbackData.FightDataPath)
                    bossPlaybackDatas[i] = nil
                    isDelete = true
                end
            end
        end
    end

    if isDelete then
        local saveKey = self:GetPlaybackSaveKey()
        XSaveTool.SaveData(saveKey, data)
    end

    return data
end

--- 删除回放数据
function XBossInshotModel:DeletePlaybackData(bossId, pos)
    local saveKey = self:GetPlaybackSaveKey()
    local data = XSaveTool.GetData(saveKey)
    local playbackData = data[bossId][pos]
    CS.XReplayManager.DeleteFightData(playbackData.FightDataPath)
    data[bossId][pos] = nil
    XSaveTool.SaveData(saveKey, data)
end

--- 获取回放保存的Key
function XBossInshotModel:GetPlaybackSaveKey()
    local activityId = self:GetActivityId()
    return string.format("XBossInshotModel:GetPlaybackSaveKey_PlayerId:%s_ActivityId:%s", XPlayer.Id, activityId)
end

--- 设置角色详情界面显示的天赋选择
function XBossInshotModel:SetCharacterDetailTalentPos(talentPos)
    self.CharacterDetailTalentPos = talentPos
end

--- 获取角色详情界面显示的天赋选择
function XBossInshotModel:GetCharacterDetailTalentPos()
    return self.CharacterDetailTalentPos
end

--- 获取角色新解锁的天赋列表
function XBossInshotModel:GetNewUnlockTalentIds()
    local saveKey = self:GetUnlockTalentSaveKey()
    local data = XSaveTool.GetData(saveKey) or {}
    local isNew = false

    -- 获取新解锁天赋
    local result = {}
    for _, characterData in pairs(self.CharacterDataDic) do
        local newIds = {}
        if characterData.DefaultTalentId ~= 0 then
            if not data[characterData.DefaultTalentId] then
                table.insert(newIds, characterData.DefaultTalentId)
                data[characterData.DefaultTalentId] = true
                isNew = true
            end
        end
        for _, talentId in pairs(characterData.UnlockTalentIds) do
            if not data[talentId] then
                table.insert(newIds, talentId)
                data[talentId] = true
                isNew = true
            end
        end
        if #newIds > 0 then
            result[characterData.CharacterId] = newIds
        end
    end

    -- 更新本地数据
    if isNew then
        XSaveTool.SaveData(saveKey, data)
    end

    return result
end

--- 获取解锁天赋保存key
function XBossInshotModel:GetUnlockTalentSaveKey()
    local activityId = self:GetActivityId()
    return string.format("XBossInshotModel:GetUnlockTalentSaveKey_PlayerId:%s_ActivityId:%s", XPlayer.Id, activityId)
end

---------------------------------------- #region Rpc ----------------------------------------
--- 通知跃升挑战数据
function XBossInshotModel:NotifyBossInshotData(data)
    self.ActivityId = data.BossInshotData.ActivityId
    self.IsPassTeach = data.BossInshotData.IsPassTeach

    self.PassStageDataDic = {}
    for _, stageData in ipairs(data.BossInshotData.PassStageDatas) do
        self.PassStageDataDic[stageData.StageId] = stageData
    end

    self.BossUnlockDataDic = {}
    for _, unlockData in ipairs(data.BossInshotData.BossUnlockDatas) do
        self.BossUnlockDataDic[unlockData.BossId] = unlockData
    end
    
    self.CharacterDataDic = {}
    for _, characterData in ipairs(data.BossInshotData.CharacterDatas) do
        self.CharacterDataDic[characterData.CharacterId] = characterData
    end
end

--- 通知回放开关是否开启
function XBossInshotModel:NotifyBossInshotPlayback(data)
    self.IsPlayback = data.IsPlayback
end

--- 战斗结束更新最高分数
function XBossInshotModel:UpdateMaxScore(settleData)
    if settleData.BossInshotSettleResult then
        local stageId = settleData.StageId
        local score = settleData.BossInshotSettleResult.Score
        local isNew = settleData.BossInshotSettleResult.IsNewRecord
        if isNew then
            local stageData = self.PassStageDataDic[stageId]
            if not stageData then
                stageData = { StageId = stageId, MaxScore = 0}
                self.PassStageDataDic[stageId] = stageData
            end
            stageData.MaxScore = score
        end

        -- 教学关通关
        local teachStageId = self:GetActivityTeachStageId(self.ActivityId)
        if stageId == teachStageId then
            self.IsPassTeach = true
        end
    end
end

--- 获取通关关卡数据
function XBossInshotModel:GetPassStageData(stageId)
    return self.PassStageDataDic[stageId]
end

function XBossInshotModel:GetStageMaxScore(stageId)
    local stageData = self:GetPassStageData(stageId)
    return stageData and stageData.MaxScore or 0
end

--- 教学关是否通关
function XBossInshotModel:IsTeachStagePass()
    return self.IsPassTeach == true
end

--- 获取角色数据
function XBossInshotModel:GetCharacterData(characterId)
    return self.CharacterDataDic[characterId]
end

--- 更新角色天赋
function XBossInshotModel:UpdateCharacterSelectTalentIds(characterId, talentIds)
    local characterData = self:GetCharacterData(characterId)
    if characterData then
        for i, talentId in ipairs(talentIds) do
            characterData.SelectTalentIds[i] = talentId
        end
    end
end

--- 获取角色选择天赋Id列表
function XBossInshotModel:GetCharacterSelectTalentIds(characterId)
    local characterData = self:GetCharacterData(characterId)
    return characterData and characterData.SelectTalentIds or {}
end

--- 获取角色解锁天赋Id列表
function XBossInshotModel:GetCharacterUnlockTalentIds(characterId)
    local characterData = self:GetCharacterData(characterId)
    return characterData and characterData.UnlockTalentIds or {}
end

--- 角色天赋是否选择
function XBossInshotModel:IsCharacterTalentSelect(characterId, talentId)
    local characterData = self:GetCharacterData(characterId)
    if not characterData then
        return false
    end
    
    if characterData.DefaultTalentId == talentId then
        return true
    end
    for pos, tId in pairs(characterData.SelectTalentIds) do
        if tId == talentId then
            return true, pos
        end
    end
    
    return false
end

--- 角色天赋是否解锁
function XBossInshotModel:IsCharacterTalentUnlock(characterId, talentId)
    local unlockConditionId = self:GetTalentUnlockConditionId(talentId)
    if unlockConditionId == 0 then
        return true
    end
    local characterData = self:GetCharacterData(characterId)
    if not characterData then
        return false, XConditionManager.GetConditionDescById(unlockConditionId)
    end
    
    if characterData.DefaultTalentId == talentId then
        return true
    end
    for _, tId in pairs(characterData.UnlockTalentIds) do
        if tId == talentId then
            return true
        end
    end
    
    return false, XConditionManager.GetConditionDescById(unlockConditionId)
end

--- 获取是否显示回放功能
--- @param stageId number 指定关卡
function XBossInshotModel:GetIsShowPlayback(stageId)
    -- 教学关不支持回放
    if stageId == self:GetActivityTeachStageId(self.ActivityId) then
        return false
    end
    
    return self.IsPlayback
end

-- 保存排行榜数据
function XBossInshotModel:SaveRankData(characterCfgId, bossId, isTotalRank, nowTime, res)
    self.RankData = self.RankData or {}
    local key = string.format("%s_%s_%s", characterCfgId, bossId, isTotalRank)
    self.RankData[key] = {
        Time = nowTime,
        Data = res
    }
end

-- 获取排行榜数据
function XBossInshotModel:GetRankData(characterCfgId, bossId, isTotalRank)
    if self.RankData then
        local key = string.format("%s_%s_%s", characterCfgId, bossId, isTotalRank)
        return self.RankData[key]
    end
end
---------------------------------------- #endregion Rpc ----------------------------------------


---------------------------------------- #region 配置表 ----------------------------------------
--- 获取活动配置表
function XBossInshotModel:GetConfigBossInshotActivity(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotActivity)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotActivity.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取活动配置bossId列表
function XBossInshotModel:GetActivityBossIds(id)
    local config = self:GetConfigBossInshotActivity(id)
    return config.BossIds
end

--- 获取活动配置任务组列表
function XBossInshotModel:GetActivityTaskGroupIds(id)
    local config = self:GetConfigBossInshotActivity(id)
    return config.TaskGroupIds
end

--- 获取活动配置教学关卡Id
function XBossInshotModel:GetActivityTeachStageId(id)
    local config = self:GetConfigBossInshotActivity(id)
    return config.TeachStageId
end

--- 获取活动角色Id列表
function XBossInshotModel:GetActivityCharacterIds(id)
    local config = self:GetConfigBossInshotActivity(id)
    return config.CharacterIds
end

--- 获取活动任务展示奖励
function XBossInshotModel:GetActivityPreviewTaskRewardId(id)
    local config = self:GetConfigBossInshotActivity(id)
    return config.PreviewTaskRewardId
end

--- 获取活动限制战斗角色数量
function XBossInshotModel:GetActivityPositionNum(id)
    local config = self:GetConfigBossInshotActivity(id)
    return config.PositionNum
end

--- 获取Boss配置表
function XBossInshotModel:GetConfigBossInshotBoss(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotBoss)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotBoss.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取Boss的名称
function XBossInshotModel:GetBossName(id)
    local config = self:GetConfigBossInshotBoss(id)
    return config.Name
end

--- 获取Boss的模型Id
function XBossInshotModel:GetBossModelId(id)
    local config = self:GetConfigBossInshotBoss(id)
    return config.ModelId
end

--- 获取Boss的头像
function XBossInshotModel:GetBossHeadIcon(id)
    local config = self:GetConfigBossInshotBoss(id)
    return config.HeadIcon
end

--- 获取Boss的技能Id列表
function XBossInshotModel:GetBossSkillIds(id)
    local config = self:GetConfigBossInshotBoss(id)
    return config.SkillIds
end

--- 获取Boss的开启时间
function XBossInshotModel:GetBossOpenTimeId(id)
    local config = self:GetConfigBossInshotBoss(id)
    return config.OpenTimeId
end

--- 获取成员配置表
function XBossInshotModel:GetConfigBossInshotCharacter(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotCharacter)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotCharacter.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取成员名称
function XBossInshotModel:GetCharacterName(id)
    local charCfg = self:GetConfigBossInshotCharacter(id)
    local characterId = charCfg.CharacterId
    if not XTool.IsNumberValid(characterId) then
        characterId = XRobotManager.GetCharacterId(charCfg.RobotId)
    end
    return XMVCA.XCharacter:GetCharacterName(characterId)
end

-- 获取结算评分特效名
function XBossInshotModel:GetMarkEffectName(id)
    local charCfgs = self:GetConfigBossInshotCharacter()
    for _, cfg in pairs(charCfgs) do
        if cfg.CharacterId == id or cfg.RobotId == id then
            return cfg.MarkEffectName
        end
    end
    return ""
end

--- 获取分数配置表
function XBossInshotModel:GetConfigBossInshotScore(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotScore)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotScore.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取分数评级配置表
function XBossInshotModel:GetConfigBossInshotScoreLevel(id, isIgnoreError)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotScoreLevel)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            if not isIgnoreError then
                XLog.Error("请检查配置表Share/Fuben/BossInshot/BossInshotScoreLevel.tab，未配置行Id = " .. tostring(id))
            end
        end
    else
        return cfgs
    end
end

--- 获取评分对应配置Id
function XBossInshotModel:GetScoreLevelId(difficulty, score)
    local cfgs = self:GetConfigBossInshotScoreLevel()
    for _, config in pairs(cfgs) do
        local minScore = config.MinScores[difficulty]
        local maxScore = config.MaxScores[difficulty]
        local isMinReach = minScore == 0 or score >= minScore
        local isMaxReach = maxScore == 0 or score <= maxScore
        if isMinReach and isMaxReach then
            return config.Id
        end
    end
end

--- 获取评分对应等级图标
function XBossInshotModel:GetScoreLevelIcon(difficulty, score)
    local levelId = self:GetScoreLevelId(difficulty, score)
    local config = self:GetConfigBossInshotScoreLevel(levelId)
    return config.LevelIcon
end

--- 获取评分对应等级大图标
function XBossInshotModel:GetScoreLevelBigIcon(difficulty, score)
    local levelId = self:GetScoreLevelId(difficulty, score)
    local config = self:GetConfigBossInshotScoreLevel(levelId)
    return config.BalanceIcon
end

--- 获取评分对应特效名
function XBossInshotModel:GetScoreLevelEffectName(difficulty, score)
    local levelId = self:GetScoreLevelId(difficulty, score)
    local config = self:GetConfigBossInshotScoreLevel(levelId)
    return config.EffectName
end

--- 获取达到下一评分等级提示
function XBossInshotModel:GetNextScoreLevelTips(difficulty, score)
    local levelId = self:GetScoreLevelId(difficulty, score)
    local cfg = self:GetConfigBossInshotScoreLevel(levelId + 1, true)
    if cfg then
        return XUiHelper.GetText("BossInshotNextScoreLevelTips", cfg.MinScores[difficulty], cfg.LevelName)
    else
        return XUiHelper.GetText("BossInshotMaxLevel");
    end
end

--- 获取技能配置表
function XBossInshotModel:GetConfigBossInshotSkill(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotSkill)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotSkill.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XBossInshotModel:GetSkillName(id)
    local config = self:GetConfigBossInshotSkill(id)
    return config.Name
end

function XBossInshotModel:GetSkillTips(id)
    local config = self:GetConfigBossInshotSkill(id)
    return config.Tips
end

function XBossInshotModel:GetSkillDesc(id)
    local config = self:GetConfigBossInshotSkill(id)
    return config.Desc
end

function XBossInshotModel:GetSkillVideoUrl(id)
    local config = self:GetConfigBossInshotSkill(id)
    return config.VideoUrl
end

--- 获取技能对应练习关
function XBossInshotModel:GetSkillPracticeStageId(id)
    local config = self:GetConfigBossInshotSkill(id)
    return config.PracticeStageId
end

--- 获取关卡配置表
function XBossInshotModel:GetConfigBossInshotStage(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotStage)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotStage.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取关卡名称
function XBossInshotModel:GetStageName(id)
    local config = self:GetConfigBossInshotStage(id)
    return config.Name
end

--- 获取关卡难度
function XBossInshotModel:GetStageDifficulty(id)
    local config = self:GetConfigBossInshotStage(id)
    return config.Difficulty
end

--- 获取关卡Id
function XBossInshotModel:GetInshotStageIdByStageId(stageId)
    local cfgs = self:GetConfigBossInshotStage()
    for _, cfg in pairs(cfgs) do
        if cfg.StageId == stageId then
            return cfg.Id
        end
    end
end

--- 获取关卡解锁conditionId
function XBossInshotModel:GetStageUnlockConditionId(id)
    local config = self:GetConfigBossInshotStage(id)
    return config.UnlockConditionId
end

--- 获取关卡对应stageId
function XBossInshotModel:GetStageStageId(id)
    local config = self:GetConfigBossInshotStage(id)
    return config.StageId
end

--- 获取关卡的BossId
function XBossInshotModel:GetStageBossId(id)
    local config = self:GetConfigBossInshotStage(id)
    return config.BossId
end

--- 获取Boss的关卡列表
function XBossInshotModel:GetBossStageIds(bossId)
    local activityId = self:GetActivityId()
    local activityCfg = self:GetConfigBossInshotActivity(activityId)

    local stageIds = {}
    local configs = self:GetConfigBossInshotStage()
    for _, config in ipairs(configs) do
        if config.BossId == bossId and config.IsPractice ~= 1 then
            table.insert(stageIds, config.Id)
        end
    end
    return stageIds
end

--- 获取天赋配置表
function XBossInshotModel:GetConfigBossInshotTalent(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BossInshotTalent)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/BossInshot/BossInshotTalent.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

--- 获取天赋解锁conditionId
function XBossInshotModel:GetTalentUnlockConditionId(id)
    local config = self:GetConfigBossInshotTalent(id)
    return config and config.UnlockConditionId or 0
end

--- 获取角色默认穿戴天赋配置表
function XBossInshotModel:GetCharacterDefaultWearTalentCfg(characterId)
    local talentType = XEnumConst.BOSSINSHOT.TALENT_TYPE.DEFAULT_WEAR
    local cfgs = self:GetConfigBossInshotTalent()
    for _, cfg in pairs(cfgs) do
        if cfg.CharacterId == characterId and cfg.TalentType == talentType then
            return cfg
        end
    end
end

--- 获取角色手动穿戴天赋配置表列表
function XBossInshotModel:GetCharacterHandWearTalentCfgs(characterId)
    local result = {}
    local talentType = XEnumConst.BOSSINSHOT.TALENT_TYPE.HAND_WEAR
    local cfgs = self:GetConfigBossInshotTalent()

    for _, cfg in pairs(cfgs) do
        if cfg.CharacterId == characterId and cfg.TalentType == talentType then
            table.insert(result, cfg)
        end
    end
    
    -- 按照天赋id从小到大从上到下排序
    table.sort(result, function(a, b) 
        return a.Id < b.Id
    end)
    
    return result
end

---------------------------------------- #endregion 配置表 ----------------------------------------

return XBossInshotModel
