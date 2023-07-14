--===========================
--超限乱斗模式对象
--模块负责：吕天元
--===========================
---@class XSmashBMode
local XSmashBMode = XClass(nil, "XSmashBMode")

function XSmashBMode:Ctor(modeCfg)
    self.ModeCfg = modeCfg
    self.RewardCfgs = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Mode2RewardDic, self:GetId(), true)
    self.RewardLevel = 1
    self.IsPlaying = false
    --总怪物数
    self.TotalMonsters = #XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2MonsterGroupDic, self:GetMonsterLibraryId(), true)
    self.HistoryResultList = {}
    self._EggIdList = {}
    self._EggReplaceList = {}
    self._BattleDb = false
end
--=============
--模式ID
--=============
function XSmashBMode:GetId()
    return self.ModeCfg and self.ModeCfg.Id
end
--=============
--活动ID
--=============
function XSmashBMode:GetActivityId()
    return self.ModeCfg and self.ModeCfg.ActivityId
end
--=============
--模式名称
--=============
function XSmashBMode:GetName()
    return self.ModeCfg and self.ModeCfg.Name
end
--=============
--模式开放时间(填活动开始后经过的时间)
--=============
function XSmashBMode:GetOpenCondition()
    return self.ModeCfg and self.ModeCfg.OpenTime or 0
end
--=============
--怪物库Id
--=============
function XSmashBMode:GetMonsterLibraryId()
    return self.ModeCfg and self.ModeCfg.MonsterLibraryId
end
--=============
--地图库Id
--=============
function XSmashBMode:GetMapLibraryId()
    return self.ModeCfg and self.ModeCfg.MapLibraryId
end
--=============
--环境库Id
--=============
function XSmashBMode:GetEnvLibraryId()
    return self.ModeCfg and self.ModeCfg.EnvLibraryId
end
--=============
--是否是线性模式
--=============
function XSmashBMode:GetIsLinearStage()
    return self.ModeCfg and self.ModeCfg.IsLinearStage
end
--=============
--我方队伍角色数量最大值
--=============
function XSmashBMode:GetRoleMaxPosition()
    return self.ModeCfg and self.ModeCfg.RoleMaxPosition
end
--=============
--我方队伍角色数量最小值
--=============
function XSmashBMode:GetRoleMinPosition()
    return self.ModeCfg and self.ModeCfg.RoleMinPosition
end
--=============
--敌人队伍角色数量最大值
--=============
function XSmashBMode:GetMonsterMaxPosition()
    return self.ModeCfg and self.ModeCfg.MonsterMaxPosition
end
--=============
--敌人队伍角色数量最大值
--=============
function XSmashBMode:GetMonsterMinPosition()
    return self.ModeCfg and self.ModeCfg.MonsterMinPosition
end
--=============
--我方每次出战人数
--=============
function XSmashBMode:GetRoleBattleNum()
    return self.ModeCfg and self.ModeCfg.RoleBattleNum
end
--=============
--我方强制随机开始位置,和monster的固定随机不同，强随机需设为UnKnown状态，在进入ready界面也不能揭开角色信息，直到该角色上场
--=============
function XSmashBMode:GetRoleRandomStartIndex()
    local num = self.ModeCfg.RoleForceRandomIndex
    if num and num <= 0 then
        num = nil
    end
    return num
end
--=============
--我方援助开始位置
--=============
function XSmashBMode:GetRoleForceAssistIndex()
    return self.ModeCfg.RoleForceAssistIndex
end
--=============
--敌方每次出战人数
--=============
function XSmashBMode:GetMonsterBattleNum()
    return self.ModeCfg and self.ModeCfg.MonsterBattleNum
end
--=============
--敌方随机位置
--=============
function XSmashBMode:GetMonsterRandomNum()
    return self.ModeCfg and self.ModeCfg.MonsterRandomNum
end
--=============
--获取一次游戏中敌方Boss限制数量
--若没配置，则默认为敌方最大出战数目
--=============
function XSmashBMode:GetBossLimit()
    local bossLimit = self.ModeCfg and self.ModeCfg.BossLimit
    return bossLimit and bossLimit > 0 and bossLimit or self:GetMonsterMaxPosition()
end
--=============
--模式描述
--=============
function XSmashBMode:GetDescription()
    return self.ModeCfg and self.ModeCfg.Description
end
--=============
--背景图
--=============
function XSmashBMode:GetBgPath()
    return self.ModeCfg and self.ModeCfg.BgPath
end
--=============
--图标
--=============
function XSmashBMode:GetIcon()
    return self.ModeCfg and self.ModeCfg.Icon
end
--=============
--序号图标
--=============
function XSmashBMode:GetOrderIcon()
    return self.ModeCfg and self.ModeCfg.OrderIcon
end
--=============
--背景影子图
--=============
function XSmashBMode:GetShadowBgPath()
    return self.ModeCfg and self.ModeCfg.ShadowBgPath
end
--=============
--入口底色
--=============
function XSmashBMode:GetNamePlateColor()
    local color = CS.UnityEngine.Color(self.ModeCfg.NamePlateColorR / 255, self.ModeCfg.NamePlateColorG / 255, self.ModeCfg.NamePlateColorB / 255)
    return color
end
--=============
--模式优先级
--=============
function XSmashBMode:GetPriority()
    return self.ModeCfg and self.ModeCfg.Priority
end
--===============
--获取队伍格最大数
--===============
function XSmashBMode:GetTeamMaxPosition()
    return self.ModeCfg and self.ModeCfg.TeamMaxPosition
end
--===============
--获取是否显示排行榜
--===============
function XSmashBMode:GetIsRanking()
    return self.ModeCfg and self.ModeCfg.IsRanking
end
--===============
--获取正常选角替换彩蛋概率
--===============
function XSmashBMode:GetEggRateNormal()
    return self.ModeCfg and self.ModeCfg.EggRateNormal
end
--获取随机选角替换彩蛋概率
--===============
function XSmashBMode:GetEggRateRandom()
    return self.ModeCfg and self.ModeCfg.EggRateRandom
end
--获取彩蛋开始替换的下标
--===============
function XSmashBMode:GetEggStartEndIndex()
    if self.ModeCfg then
        return self.ModeCfg.EggStartIndex, self.ModeCfg.EggEndIndex
    end
    return nil
end
--获取该模式的彩蛋机器人列表
--===============
function XSmashBMode:GetEggRobots()
    return self.ModeCfg and self.ModeCfg.EggRobots
end
--获取该模式的任务
--===============
function XSmashBMode:GetTaskGroupId()
    return self.ModeCfg and self.ModeCfg.TaskGroupId
end
--=============
--模式主页面的预制件地址
--=============
function XSmashBMode:GetPickUiPrefab()
    local isLine = self:GetIsLinearStage()
    if isLine then
        return CS.XGame.ClientConfig:GetString("SmashBrosPickPrefabLine")
    else
        return CS.XGame.ClientConfig:GetString("SmashBrosPickPrefabNormal")
    end
end
--=============
--模式准备对战页面的预制件地址
--=============
function XSmashBMode:GetReadyUiPrefab()
    local is1v1 = self:GetRoleBattleNum() == 1
    if is1v1 then
        return CS.XGame.ClientConfig:GetString("SmashBrosReadyPrefabLine")
    else
        return CS.XGame.ClientConfig:GetString("SmashBrosReadyPrefabNormal")
    end
end
--=============
--获取所有该模式的关卡
--=============
function XSmashBMode:GetAllStages()
    return XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2SceneDic, self:GetMapLibraryId())
end
--=============
--检查是否已完成所有积分奖励
--=============
function XSmashBMode:CheckComplete()
    local rewards = self:GetAllRewardCfgs()
    for _, reward in pairs(rewards) do
        if not (self.ReceivedReward and self.ReceivedReward[reward.Id]) then
            return false
        end
    end
    return true
end
--=============
--获取当前积分档位
--=============
function XSmashBMode:GetRewardLevel()
    local rewards = self:GetAllRewardCfgs()
    for level, rewardCfg in pairs(rewards) do
        if (self.RewardCfgs[level].NeedScore > self:GetScore()) and (not self.ReceivedReward or not self.ReceivedReward[rewardCfg.Id]) then
            return level
        end
    end
    return #rewards
end
--=============
--获取首个可以获取奖励的奖励等级
--=============
function XSmashBMode:GetFirstCanGetRewardLevel()
    local rewards = self:GetAllRewardCfgs()
    for level, rewardCfg in pairs(rewards) do
        if (self.RewardCfgs[level].NeedScore <= self:GetScore()) and (self.ReceivedReward and not self.ReceivedReward[rewardCfg.Id]) then
            return level
        end
    end
    return self:GetRewardLevel()
end
--=============
--获取当前积分已完成的档位数
--=============
function XSmashBMode:GetScoreArriveNum()
    local total = 0
    for level, rewardCfg in pairs(self:GetAllRewardCfgs()) do
        if self.RewardCfgs[level].NeedScore <= (self:GetScore()) then
            total = total + 1
        end
    end
    return total
end
--=============
--获取当前已领取的奖励数
--=============
function XSmashBMode:GetRewardReceivedNum()
    local result = 0
    for _, _ in pairs(self.ReceivedReward or {}) do
        result = result + 1
    end
    return result
end
--=============
--获取当前奖励配置(下一档奖励)
--=============
function XSmashBMode:GetCurrentRewardCfg()
    local level = self:GetRewardLevel()
    if level > #self:GetAllRewardCfgs() then
        level = #self:GetAllRewardCfgs()
    end
    return self.RewardCfgs[level] or {}
end
--=============
--根据给定奖励等级获取奖励配置
--=============
function XSmashBMode:GetRewardCfgByLevel(level)
    return self.RewardCfgs and self.RewardCfgs[level] or {}
end
--=============
--获取所有奖励配置
--=============
function XSmashBMode:GetAllRewardCfgs()
    return self.RewardCfgs or {}
end
--=============
--获取当前奖励的目标分数
--=============
function XSmashBMode:GetTargetScore()
    local cfg = self:GetRewardCfgByLevel(self:GetFirstCanGetRewardLevel())
    if cfg and next(cfg) then
        return cfg.NeedScore
    end
    return 0
end
--=============
--获取当前奖励的奖励Id
--=============
function XSmashBMode:GetRewardId()
    local rewards = self:GetAllRewardCfgs()
    for _, cfg in pairs(rewards) do
        if not (self.ReceivedReward and self.ReceivedReward[cfg.Id]) then
            return cfg.RewardId
        end
    end
    return rewards[#rewards] and rewards[#rewards].RewardId or 0
end

function XSmashBMode:CheckRewardReceiveStateByLevel(level)
    local cfg = self:GetRewardCfgByLevel(level)
    if not cfg or (not next(cfg)) then
        return false, false
    end
    local isGet = self.ReceivedReward and self.ReceivedReward[cfg.Id]
    local canGet = (not isGet) and (cfg.NeedScore <= self:GetScore())
    return canGet, isGet
end

function XSmashBMode:SetReceiveStateByRewardId(rewardId)
    if not self.ReceivedReward then
        self.ReceivedReward = {}
    end
    self.ReceivedReward[rewardId] = true
end
--=============
--获取最前面未领取且是可领取的奖励配置
--若没有，则返回空
--=============
function XSmashBMode:GetFirstRewardCfgNotGet()
    local rewards = self:GetAllRewardCfgs()
    local score = self:GetScore()
    for _, cfg in pairs(rewards) do
        if (cfg.NeedScore <= score) and not (self.ReceivedReward and self.ReceivedReward[cfg.Id]) then
            return cfg
        end
    end
    return nil
end
--=============
--获取已通过的怪物数
--=============
function XSmashBMode:GetPassMonsters()
    return XDataCenter.SuperSmashBrosManager.GetPassMonstersNumByModeId(self:GetId())
end
--=============
--获取所有怪物总数
--=============
function XSmashBMode:GetTotalMonsters()
    return self.TotalMonsters or 1 --缺省1能正常被除
end
--=============
--获取剩余未首通怪物数量
--=============
function XSmashBMode:GetMonstersNotPass()
    return self:GetTotalMonsters() - self:GetPassMonsters()
end
--=============
--获取通关模式解锁的核心对象
--=============
function XSmashBMode:GetCore()
    return XDataCenter.SuperSmashBrosManager.GetCoreByMode(self:GetId())
end
--=============
--检查是否解锁
--=============
function XSmashBMode:CheckUnlock()
    local startTime = XDataCenter.SuperSmashBrosManager.GetActivityStartTime()
    local now = XTime.GetServerNowTimestamp()
    return (now - startTime) > self:GetOpenCondition()
end
--=============
--获取模式现在积分
--=============
function XSmashBMode:GetScore()
    return self.Score or 0
end
--=============
--检查是否正在进行
--=============
function XSmashBMode:CheckIsPlaying()
    return self.IsPlaying
end
--=============
--设置是否正在进行
--=============
function XSmashBMode:SetIsPlaying(value)
    self.IsPlaying = value
end
--=============
--获取我方的模式参战队伍所有成员
--=============
function XSmashBMode:GetBattleTeam()
    return XDataCenter.SuperSmashBrosManager.GetRoleIdsByModeId(self:GetId())
end
--=============
--获取我方的下一场战斗出战的成员
--=============
function XSmashBMode:GetBattleMember()
    local team = {}
    local ownTeam = self:GetBattleTeam()
    local battleNum = self:GetRoleBattleNum()
    if self.CharacterProgressIndex and self.CharacterProgressIndex > 0 then
        for i = 1, self.CharacterProgressIndex + battleNum - 1 do
            local id = ownTeam[i]
            local chara
            if id then
                chara = XDataCenter.SuperSmashBrosManager.GetRoleById(id)
            end
            table.insert(team, id)
        end
    end
    return team
end
--=============
--获取出战下标
--=============
function XSmashBMode:GetBattleCharaIndex()
    return self.CharacterProgressIndex or 1
end
--=============
--获取敌人出战队伍
--=============
function XSmashBMode:GetEnemyTeam()
    return self.EnemyTeam
end
--=============
--获取敌人出战下标
--=============
function XSmashBMode:GetBattleEnemyIndex()
    return self.MonsterGroupProgressIndex
end
--=============
--获取累计消耗时间(整轮模式累计)
--=============
function XSmashBMode:GetSpendTime()
    return self.LastSpendTime or 0
end
--=============
--获取历史最佳消耗时间
--=============
function XSmashBMode:GetBestTime(career)
    if career and self.BestSpendTimeList then
        return self.BestSpendTimeList[career]
    end
    return self.BestSpendTime or 0
end
--=============
--(连战模式)获取当前正在进行的连胜数值
--这里在确认前后端发来的数值不会+1，若要在确认前展示暂时的连胜次数，需在数值上手动+1
--=============
function XSmashBMode:GetWinCount(career)
    if career and self.WinCountMaxList then
        return self.WinCountMaxList[career] or 0
    end
    return self.WinCount or 0
end
--=============
--(连战模式)获取连胜最高数值
--这里在确认前后端发来的数值不会+1，若要在确认前展示暂时的连胜次数，需在数值上手动+1
--=============
function XSmashBMode:GetCurrentWinCount()
    return (self.StageProgressIndex or 0) - 1
end
--=============
--获取最新一轮的连战时间挑战数据
--=============
function XSmashBMode:GetLastTimeAttackData()
    return self.LastTimeAttackList or {}
end
--=============
--获取历史最佳连战时间挑战数据
--=============
function XSmashBMode:GetBestTimeAttackData()
    return self.BestTimeAttackList or {}
end
--=============
--获取历史最佳连战时间挑战数据的数量
--=============
function XSmashBMode:GetBestStageAttackNum()
    return #self:GetBestTimeAttackData()
end
--=============
--获取上一关通关时间
--=============
function XSmashBMode:GetLastStagePassTime()
    return self.StageSpendTime or 0
end
--=============
--获取下一关StageId
--=============
function XSmashBMode:GetNextStageId()
    if self.StageProgressIndex > #self.AllStageId then
        return -1 --表示已全部通关
    end
    return self.AllStageId[self.StageProgressIndex]
end
--=============
--获取连战模式下的进度字符串
--=============
function XSmashBMode:GetLineProgress()
    return XUiHelper.GetText("SSBMainPointGetText", self.StageProgressIndex, #self.AllStageId)
end
--=============
--获取连战模式下一个敌人信息
--这里关卡进度下标也表示与模式的按ID排序的敌人的顺位
--=============
function XSmashBMode:GetNextEnemy()
    if self:GetId() == XSuperSmashBrosConfig.ModeType.DeathRandom and self.AllStageId then
        local allStage = self.AllStageId
        local stageId = allStage[self.StageProgressIndex + 1]
        if not stageId then
            return nil
        end
        local monsterGroupId = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.SceneConfig, stageId).MonsterLibraryId
        local monsterGroup = XDataCenter.SuperSmashBrosManager.GetMonsterGroupById(monsterGroupId)
        return monsterGroup
    end
    
    local monsterGroups = XDataCenter.SuperSmashBrosManager.GetMonsterGroupListByModeId(self:GetId())
    if not monsterGroups then
        return nil
    end
    local monsterGroup = monsterGroups[self.StageProgressIndex + 1]
    return monsterGroup
end
--=============
--获取模式结果状态
--=============
function XSmashBMode:GetModeResult()
    local isStart = self:GetBattleCharaIndex() == 1 and self:GetBattleEnemyIndex() == 1
    local isWin = self:GetBattleEnemyIndex() > #self:GetEnemyTeam()
    local isEnd = (self:GetBattleCharaIndex() > self:GetRoleMaxPosition()) or (self:GetBattleEnemyIndex() > #self:GetEnemyTeam())
    return isStart, isEnd, isWin
end
--=============
--获取确认标识
--=============
function XSmashBMode:GetConfirmFlag()
    return self.ConfirmFlag
end
--=============
--检查是否开始
--=============
function XSmashBMode:CheckIsStart()
    return self:GetBattleCharaIndex() == 1 and self:GetBattleEnemyIndex() == 1
end
--=============
--检查是否结束
--=============
function XSmashBMode:CheckIsEnd()
    local assistanceIndex = self:GetRoleForceAssistIndex()
    local currentIndex = self:GetBattleCharaIndex()
    if XDataCenter.SuperSmashBrosManager.IsAssistance(currentIndex, assistanceIndex) then
        return true
    end
    return (not self:GetBattleTeam()[self:GetBattleCharaIndex()] or self:GetBattleTeam()[self:GetBattleCharaIndex()] == 0)
            or (self:CheckIsWin())
end
--=============
--检查是否胜利
--=============
function XSmashBMode:CheckIsWin()
    return (self:GetBattleEnemyIndex() > #self:GetEnemyTeam()) and (self.StageProgressIndex >= #self.AllStageId)
end
--=============
--检查上一场的胜利方
--=============
function XSmashBMode:GetLastWin()
    if self.LastWin == nil then
        return 0
    else
        return self.LastWin
    end
end
--=============
--存储result 用于重新挑战寻找再上一次对战的角色数据
--=============
function XSmashBMode:RecordResult(result)
    self.Result = result
end
--=============
--获取result
--=============
function XSmashBMode:GetResult()
    return self.Result
end
--=============
--刷新后台推送活动数据
--@param data:
--List<SuperSmashBrosModeDb>
--SuperSmashBrosModeDb:
--int ModeId
--List<int> CurFightMonsterGroupId
--Dictionary<int, int> MonsterGroupWinCount
--int Score
--List<int> TakedRewardList
--SuperSmashBrosBattleDb BattleDb
--int LastRankScore
--=============
function XSmashBMode:RefreshNotifyModeData(modeDb)
    self.Score = modeDb.Score --当前分数
    --累计战斗耗时
    self.LastSpendTime = modeDb.CurSpendTime
    --本模式最佳耗时时间
    self.BestSpendTime = modeDb.BestSpendTime
    self.BestSpendTimeList = modeDb.BestSpendTimeList

    self.ReceivedReward = {}
    for _, rewardId in pairs(modeDb.TakedRewardList or {}) do
        self.ReceivedReward[rewardId] = true
    end
    self.HistoryWinCount = modeDb.WinCountMax
    self.WinCountMaxList = modeDb.WinCountMaxList
    self.LastTimeAttackList = {}
    for index, timeAttackInfo in pairs(modeDb.CurStageList) do
        self.LastTimeAttackList[index] = {
            StageId = timeAttackInfo.Id,
            Time = timeAttackInfo.Time
        }
    end
    self.BestTimeAttackList = {}
    for index, timeAttackInfo in pairs(modeDb.StageHistory) do
        self.BestTimeAttackList[index] = {
            StageId = timeAttackInfo.Id,
            Time = timeAttackInfo.Time
        }
    end
    self.BestStageAttackNum = #self.BestTimeAttackList
    --用于连胜模式表示当前胜利次数
    self.WinCount = #modeDb.CurStageList
    local manager = XDataCenter.SuperSmashBrosManager
    manager.RefreshMonsterGroupWinCount(modeDb.MonsterGroupWinCountList)
    self:RefreshNotifyBattleData(modeDb.BattleDb)

    -- 战斗纪录
    self:_SetHistoryResult(modeDb.BattleDb)

    -- 彩蛋角色列表
    self:_SetEggIdList(modeDb.BattleDb)
end
--=============
--刷新后台推送模式战斗数据
--@param data:
--SuperSmashBrosBattleDb:
--List<int> CharacterIdList
--Dictionary<int,int> CharacterIdResult
--List<int> CharacterPosList
--int LastBattleCharacterIndex
--List<int> MonsterGroupIdList
--List<XNpcHpInfo> LeftMonster
--int LastBattleMonsterIndex
--int StageId
--int EnvId
--int StageProgressIndex
--long SpendTime
--long StartTime
--int WinCount
--=============
function XSmashBMode:RefreshNotifyBattleData(battleDb)
    self._BattleDb = battleDb
    self.EnemyTeam = {}
    if not battleDb or not next(battleDb) then
        return
    end
    for index, enemyId in pairs(battleDb.MonsterGroupIdList or {}) do
        table.insert(self.EnemyTeam, enemyId)
    end
    self:_SetEggReplace(battleDb)
    XDataCenter.SuperSmashBrosManager.SetTeamByModeId(
            battleDb.CaptainPos,
            battleDb.FirstFightPos,
            battleDb.CharacterIdList,
            battleDb.CharacterPosList,
            self:GetId()
    )
    --所有关卡Id，非连战模式只有一项，连战模式会是整个关卡链的数组
    self.AllStageId = battleDb.StageId
    --下一个关卡的下标
    self.StageProgressIndex = battleDb.StageProgressIndex + 1
    --上一个战斗胜利的关卡，在关卡结束未确认结果前就会刷新
    self.LastWinStageId = battleDb.LastWinStageId
    --环境Id
    self.CurrentEvironment = battleDb.EnvId

    if battleDb.LastResult then
        --ConfirmFlag是后端用于确认重登，掉线等情况再连上时，有没保留未确认数据的标识
        --LastResult有值时，先使用这个值展示，但是不能被确认，详细请跟后端确认
        self.ConfirmFlag = true
        self:RefreshBattleResultDb(battleDb.LastResult)
        self.LastWin = (self.AllStageId[self.StageProgressIndex] == battleDb.LastResult.LastWinStageId) or not (battleDb.LastResult.LastWinStageId == 0)
    else
        self.ConfirmFlag = false
        self:RefreshBattleResultDb(battleDb.Result)
        if battleDb.Result then
            self.LastWin = (self.AllStageId[self.StageProgressIndex] == battleDb.Result.LastWinStageId) or not (battleDb.Result.LastWinStageId == 0)
        else
            self.LastWin = true
        end
    end

    -- 重新挑战时必现要用到 Result， 纯记录一遍Result
    if battleDb.Result then
        self:RecordResult(battleDb.Result)
    end

    -- 战斗纪录
    self:_SetHistoryResult(battleDb)

    -- 彩蛋角色列表
    self:_SetEggIdList(battleDb)
end
--================
--刷新登陆时接收的缓存战斗数据
--================
function XSmashBMode:RefreshBattleResultDb(data)
    data = data or {}
    local manager = XDataCenter.SuperSmashBrosManager
    --下个角色出战下标(+1对齐Lua从1开始的下标)，注意，若一次上阵多个角色，此下标表示第一个上阵角色的下标
    self.CharacterProgressIndex = (data.CharacterProgressIndex or 0) + 1
    manager.SetBattleRoleLeftHp(self:GetBattleTeam(), self.CharacterProgressIndex, data.CharacterResultList)
    --下个怪物出战下标(+1对齐Lua从1开始的下标)，注意，若一次上阵多个角色，此下标表示第一个上阵角色的下标
    self.MonsterGroupProgressIndex = (data.MonsterGroupProgressIndex or 0) + 1
    manager.SetMonsterTeamLeftHp(self:GetEnemyTeam(), self.MonsterGroupProgressIndex, data.LeftMonster, self:GetMonsterBattleNum())
end
--================
--刷新战斗后接收的缓存战斗数据
--================
function XSmashBMode:RefreshBattleResult(data, isWin)
    if not data then
        return
    end
    self:_SetEggReplace(nil, data)
    if data.EggReplace and isWin then
        XDataCenter.SuperSmashBrosManager.SetJustFail()
    end

    local manager = XDataCenter.SuperSmashBrosManager
    self.LastWin = (self.AllStageId[self.StageProgressIndex] == data.LastWinStageId) or not (data.LastWinStageId == 0)
    self.ConfirmFlag = true --当正常战斗结算后检测确认Flag
    --下个角色出战下标(+1对齐Lua从1开始的下标)，注意，若一次上阵多个角色，此下标表示第一个上阵角色的下标
    self.CharacterProgressIndex = (data.CharacterProgressIndex or 0) + 1
    --下个怪物出战下标(+1对齐Lua从1开始的下标)，注意，若一次上阵多个角色，此下标表示第一个上阵角色的下标
    self.MonsterGroupProgressIndex = (data.MonsterGroupProgressIndex or 0) + 1
    if isWin then
        manager.SetBattleRoleLeftHp(self:GetBattleTeam(), self.CharacterProgressIndex, data.CharacterResultList)
        manager.SetMonsterTeamLeftHp(self:GetEnemyTeam(), self.MonsterGroupProgressIndex)
    else
        manager.SetBattleRoleLeftHp(self:GetBattleTeam(), self.CharacterProgressIndex, data.CharacterResultList)
        manager.SetMonsterTeamLeftHp(self:GetEnemyTeam(), self.MonsterGroupProgressIndex, data.LeftMonster, self:GetMonsterBattleNum())
    end
    --上一个战斗的时间
    self.StageSpendTime = data.StageSpendTime

    data.MonsterGroupIdList = self.EnemyTeam
end
--================
--重置模式正在进行的状态
--================
function XSmashBMode:ResetPlaying()
    self:SetIsPlaying(false)
    XDataCenter.SuperSmashBrosManager.ResetTeamByModeId(self:GetId())
    XDataCenter.SuperSmashBrosManager.ResetMonsterGroupHpLeftByIdList(self:GetEnemyTeam())
    self.EnemyTeam = {}
    self.CharacterProgressIndex = 1
    self.MonsterGroupProgressIndex = 1
    self.StageProgressIndex = 1
    self.StageSpendTime = 0
    self.LastWinStageId = 0
    self.LastWin = nil
    self.Result = nil
    self.HistoryResultList = {}
end
--================
--是否 显示挑战记录
--================
function XSmashBMode:IsShowRecordBtn()
    return self:GetId() == XSuperSmashBrosConfig.ModeType.Survive
end
--================
--是否 可改变关卡
--================
function XSmashBMode:IsCanChangeStage()
    return self:GetId() == XSuperSmashBrosConfig.ModeType.DeathRandom
end

function XSmashBMode:GetResultList()
    return self.HistoryResultList
end

function XSmashBMode:IsCanReady()
    return true
end

function XSmashBMode:_SetHistoryResult(battleDb)
    if battleDb.HistoryResultList then
        self.HistoryResultList = battleDb.HistoryResultList
    else
        self.HistoryResultList = {}
    end
    if battleDb.HistoryMonsterGroupIdList then
        for i = 1, #self.HistoryResultList do
            local result = self.HistoryResultList[i]
            result.MonsterGroupIdList = { battleDb.HistoryMonsterGroupIdList[i] }
        end
    end
end

function XSmashBMode:GetStageId(monsterGroupId)
    local allStages = self:GetAllStages()
    for i = 1, #allStages do
        local stage = allStages[i]
        if stage.MonsterLibraryId == monsterGroupId then
            return stage.Id
        end
    end
    return false
end

-- 用彩蛋角色替换原本角色，在继续战斗之前
function XSmashBMode:_SetEggReplace(battleDb, result)
    local isUpdateAfterFight = result and true or false
    if isUpdateAfterFight then
        battleDb = self._BattleDb
    else
        result = battleDb.LastResult or battleDb.Result
    end
    if not battleDb or not result then
        return
    end
    if result.EggReplace then
        if result.EggReplaceIndex and result.EggReplaceIndex > -1 then
            self._EggReplaceList[result.EggReplaceIndex] = true
        end
        for index, isReplace in pairs(self._EggReplaceList) do
            if isReplace then
                local eggCharacter = battleDb.EggIdList[index + 1]
                if eggCharacter then
                    local oldCharacterId = eggCharacter.OrgId
                    local oldCharacterIndex = false
                    for i = 1, #battleDb.CharacterIdList do
                        local oldCharacter = battleDb.CharacterIdList[i]
                        if oldCharacter.Id == oldCharacterId then
                            oldCharacterIndex = i
                            break
                        end
                    end
                    if oldCharacterIndex then
                        battleDb.CharacterIdList[oldCharacterIndex] = eggCharacter
                    end
                end
            end
        end
    end
    -- 战后 设置彩蛋角色
    if isUpdateAfterFight then
        XDataCenter.SuperSmashBrosManager.SetTeamByModeId(
                battleDb.CaptainPos,
                battleDb.FirstFightPos,
                battleDb.CharacterIdList,
                battleDb.CharacterPosList,
                self:GetId()
        )
    end
end

function XSmashBMode:_SetEggIdList(battleDb)
    self._EggIdList = battleDb.EggIdList or {}
    self._EggReplaceList = battleDb.EggReplaceList or {}
end

function XSmashBMode:GetEggId()
    local egg = self._EggIdList[1]
    return egg and egg.Id
end

function XSmashBMode:IsEggReplace(characterIndex)
    return self._EggReplaceList[characterIndex - 1] and true or false
end
--=============
--检查是否援助
--=============
function XSmashBMode:IsAssistancePos(index)
    local assistanceIndex = self:GetRoleForceAssistIndex()
    if XDataCenter.SuperSmashBrosManager.IsAssistance(index, assistanceIndex) then
        return true
    end
    return false
end

function XSmashBMode:IsStagePassed(stageId)
    if not self.AllStageId then
        return false
    end
    for index, id in pairs(self.AllStageId) do
        if stageId == id then
            return index < self.StageProgressIndex
        end
    end
    return false
end

return XSmashBMode