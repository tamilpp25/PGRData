local tableUnpack = table.unpack

XConditionManager = XConditionManager or {}

local TABLE_CONDITION_PATH = "Share/Condition/Condition.tab"
local ConditionTemplate = {}

local DefaultRet = true

XConditionManager.ConditionType = {
    Unknown = 0,
    Player = 1,
    Character = 13,
    Team = 18,
    Kill = 30,
    Equip = 31,
    Activity = 40,
    Formula = 41
}

local PlayerCondition
PlayerCondition = {
    [10101] = function(condition) -- 查询玩家等级是否达标
        return XPlayer.Level >= condition.Params[1], condition.Desc
    end,
    [10102] = function(condition) -- 查询玩家是否拥有指定角色
        return XDataCenter.CharacterManager.IsOwnCharacter(condition.Params[1]), condition.Desc
    end,
    [10103] = function(condition) -- 查询玩家是否拥有指定数量的角色
        return #XDataCenter.CharacterManager.GetOwnCharacterList() >= condition.Params[1], condition.Desc
    end,
    [10104] = function(condition) -- 查询玩家背包是否有容量
        local ret, desc = PlayerCondition[12101](condition)
        if not ret then
            return ret, desc
        end

        return PlayerCondition[12102](condition)
    end,
    [10105] = function(condition) -- 查询玩家是否通过指定得关卡
        local stageId = condition.Params[1]
        -- local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        -- if stageInfo then
        --     return stageInfo.Passed, condition.Desc
        -- else
        --     return true, condition.Desc
        -- end
        local flag = XDataCenter.FubenManager.CheckStageIsPass(stageId)
        return flag, condition.Desc
    end,
    [10106] = function(condition) --至少拥有其中一个角色
        if condition.Params and #condition.Params > 0 then
            for i = 1, #condition.Params do
                local isOwnCharacter = XDataCenter.CharacterManager.IsOwnCharacter(condition.Params[i])
                if isOwnCharacter then
                    return true, condition.Desc
                end
            end
        end
        return false, condition.Desc
    end,
    [10107] = function(condition) -- 查询玩家等级是否小于等于n
        return XPlayer.Level <= condition.Params[1], condition.Desc
    end,
    [10108] = function(condition) -- 查询玩家是否通过指定得关卡
        local stageId = condition.Params[1]
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            return (not stageInfo.Passed), condition.Desc
        else
            return false, condition.Desc
        end
    end,
    [10109] = function(condition) --查询玩家是否拥有战力X的角色数量
        local needCount = condition.Params[1]
        local needAbility = condition.Params[2]
        local curCount = XDataCenter.CharacterManager.GetCharacterCountByAbility(needAbility)
        if (curCount >= needCount) then
            return true, condition.Desc
        else
            return false, condition.Desc
        end
    end,
    [10110] = function(condition) -- 查询玩家是否有某个勋章
        return XPlayer.IsMedalUnlock(condition.Params[1]), condition.Desc
    end,
    [10111] = function(condition) -- 查询玩家是否完成过某个任务
        local task = XDataCenter.TaskManager.GetTaskDataById(condition.Params[1])
        return task and task.State == XDataCenter.TaskManager.TaskState.Finish or false, condition.Desc
    end,
    [10112] = function(condition) -- 单挑Boss奖励是否领取，活动是否开启
        local isCurActivity = XDataCenter.FubenActivityBossSingleManager.GetCurActivityId() == condition.Params[1]
        local isFinish = XDataCenter.FubenActivityBossSingleManager.CheckRewardIsFinish(condition.Params[2])
        if
            XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenActivitySingleBoss) and isFinish and
                isCurActivity
         then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10114] = function(condition) -- 世界boss属性关完成数量
        local worldBossActivity = XDataCenter.WorldBossManager.GetCurWorldBossActivity()
        if worldBossActivity then
            local finishStageCount = worldBossActivity:GetFinishStageCount()
            if finishStageCount >= condition.Params[1] then
                return true, condition.Desc
            end
        end
        return false, condition.Desc
    end,
    [10115] = function(condition) -- 世界boss血量低于xx(百分比)
        local bossArea = XDataCenter.WorldBossManager.GetBossAreaById(condition.Params[1])
        if bossArea then
            local hpPercent = bossArea:GetHpPercent()
            if hpPercent * 100 <= condition.Params[2] then
                return true, condition.Desc
            end
        end
        return false, condition.Desc
    end,
    [10118] = function(condition) -- 判断玩家是否完成预热关拼图
        local puzzleId = condition.Params[1]
        if
            XDataCenter.FubenActivityPuzzleManager.GetPuzzleStateById(puzzleId) ==
                XFubenActivityPuzzleConfigs.PuzzleState.Complete
         then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10119] = function(condition) -- 判断是否完成跑团（TRPG）某个目标
        local targetId = condition.Params[1]
        if XDataCenter.TRPGManager.IsTargetFinish(targetId) then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10120] = function(condition) -- 判断尼尔角色等级是否达标
        local characterId = condition.Params[1]
        local nieRCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(characterId)
        if nieRCharacter and (nieRCharacter:GetNieRCharacterLevel() >= condition.Params[2]) then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10121] = function(condition) -- 判断尼尔辅助机等级是否达标
        local targetLevel = condition.Params[1]
        local nieRPOd = XDataCenter.NieRManager.GetNieRPODData()
        if nieRPOd and (nieRPOd:GetNieRPODLevel() >= targetLevel) then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10122] = function(condition) -- 判断尼尔辅助机技能等级是否达标
        local skillId = condition.Params[1]
        local skillLevel = condition.Params[2]
        local nieRPOd = XDataCenter.NieRManager.GetNieRPODData()
        if nieRPOd and (nieRPOd:GetNieRPODSkillLevelById(skillId) >= skillLevel) then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10123] = function(condition)
        local result = XDataCenter.RegressionManager.IsRegressionActivityOpen(XRegressionConfigs.ActivityType.Task)
        return result, condition.Desc
    end,
    [10126] = function(condition) --玩家是否完成跑团（TRPG）某迷宫卡牌
        local mazeId = condition.Params[1]
        local layerId = condition.Params[2]
        local cardId = condition.Params[3]
        if XDataCenter.TRPGManager.IsMazeCardFinished(mazeId, layerId, cardId) then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [10127] = function(condition) --判断玩家合成小游戏活动进度是否达标
        local schedule = condition.Params[1]
        local gameId = condition.Params[2]
        local game = XDataCenter.ComposeGameManager.GetGameById(gameId)
        if game then
            local currentSchedule = game:GetCurrentSchedule()
            return currentSchedule >= schedule, condition.Desc
        end
        return false, condition.Desc
    end,
    [10128] = function(condition) --超级据点拥有矿工数量
        local requireCount = condition.Params[1] or 0
        local haveCount = XDataCenter.StrongholdManager.GetMinerCount()
        return haveCount >= requireCount, condition.Desc, haveCount, requireCount
    end,
    [10129] = function(condition) --超级据点拥有矿石数量
        local requireCount = condition.Params[1]
        local haveCount = XDataCenter.StrongholdManager.GetTotalMineralCount()
        return haveCount >= requireCount, condition.Desc, haveCount, requireCount
    end,
    [10130] = function(condition) --超级据点完成据点数量
        local requireCount = condition.Params[1]
        local haveCount = XDataCenter.StrongholdManager.GetFinishGroupCount(XStrongholdConfigs.ChapterType.Normal)
        return haveCount >= requireCount, condition.Desc, haveCount, requireCount
    end,
    [10131] = function(condition) --超级据点完成某个据点
        local groupId = condition.Params[1]
        local isfinished = XDataCenter.StrongholdManager.IsGroupFinished(groupId)
        return isfinished, condition.Desc
    end,
    [10132] = function(condition) --超级据点矿石预计产出
        local requireCount = condition.Params[1]
        local haveCount = XDataCenter.StrongholdManager.GetPredictTotalMineralCount()
        return haveCount >= requireCount, condition.Desc, haveCount, requireCount
    end,
    [10133] = function(condition, ...) --超级据点队伍是否满员
        local args = {...}
        local teamList = args and args[1]
        local isfinished = XDataCenter.StrongholdManager.CheckCurGroupTeamFull(teamList)
        return isfinished, condition.Desc
    end,
    [10134] = function(condition, ...) --超级据点队伍列表平均战力是否符合要求
        local requireCount = condition.Params[1]
        local args = {...}
        local teamList = args and args[1]
        local isfinished, averageAbility =
            XDataCenter.StrongholdManager.CheckTeamListAverageAbility(requireCount, teamList)
        return isfinished, condition.Desc .. "/" .. math.floor(averageAbility)
    end,
    [10135] = function(condition) --超级据点未完成某个据点
        local groupId = condition.Params[1]
        local isfinished = XDataCenter.StrongholdManager.IsGroupFinished(groupId)
        return not isfinished, condition.Desc
    end,
    [10139] = function(condition) --玩家是否未完成跑团（TRPG）某迷宫卡牌
        local mazeId = condition.Params[1]
        local layerId = condition.Params[2]
        local cardId = condition.Params[3]
        if XDataCenter.TRPGManager.IsMazeCardFinished(mazeId, layerId, cardId) then
            return false, condition.Desc
        end
        return true, condition.Desc
    end,
    [10140] = function(condition) --超级据点当前活动阶段是否满足任一参数（1, --开启中2, --战斗开启3, --战斗结束4, --已结束）
        local isfinished = false
        for _, status in pairs(condition.Params) do
            if status > 0 and XDataCenter.StrongholdManager.CheckActivityStatus(status) then
                isfinished = true
                break
            end
        end
        return isfinished, condition.Desc
    end,
    [10141] = function(condition) --Rpg爬塔玩法是否当前队伍等级高于参照值
        local needLevel = condition.Params[1]
        local reachLevel = XDataCenter.RpgTowerManager.GetCurrentLevel() >= needLevel
        return reachLevel, condition.Desc
    end,
    [10142] = function(condition) --是否拥有某个伙伴
        local templateId = condition.Params[1]
        local IsUnLock = XDataCenter.ArchiveManager.GetPartnerUnLockById(templateId)
        return IsUnLock, condition.Desc
    end,
    [10143] = function(condition) --是否完成翻牌小游戏某个关卡
        local activityId = condition.Params[1]
        local stageId = condition.Params[2]
        return XDataCenter.InvertCardGameManager.CheckActivityStageFinished(activityId, stageId), condition.Desc
    end,
    [10144] = function(condition) -- 判断杀戮无双难度星数
        local diff = condition.Params[1]
        local star = condition.Params[2]
        local curStar = XDataCenter.KillZoneManager.GetTotalStageStarByDiff(diff)
        return curStar >= star, condition.Desc
    end,
    [10145] = function(condition) -- 判断超级爬塔通关目标关卡进度
        local targetStageId = condition.Params[1]
        local progress = condition.Params[2]
        local stageManager = XDataCenter.SuperTowerManager.GetStageManager()
        if not stageManager then
            return false
        end
        local stStage = stageManager:GetTargetStageByStStageId(targetStageId)
        if not stStage then
            return false
        end
        return stStage:GetCurrentProgress() >= progress, condition.Desc
    end,
    [10146] = function(condition, ...) -- 或条件判断通过，特定13章探索模型XX节点或通关指定id副本
        local tempCondition1 = {Params = {[1] = condition.Params[1]}}
        local tempCondition2 = {Params = {[1] = condition.Params[2]}}
        local ret1 = PlayerCondition[10105](tempCondition1)
        local ret2 = PlayerCondition[10119](tempCondition2)
        local ret = ret1 or ret2
        return ret, condition.Desc
    end,
    [10150] = function (condition) -- 查询当前的生日剧情是否解锁
        return XPlayer.CheckStoryIsUnlock(condition.Params[1]), condition.Desc
    end,
    [10152] = function(condition) -- 查询当前邮件图鉴是否解锁
        return XDataCenter.ArchiveManager.CheckArchiveMailUnlock(condition.Params[1]), condition.Desc
    end,
    [11101] = function(condition) -- 查询指定道具数量是否达标
        return XDataCenter.ItemManager.CheckItemCountById(condition.Params[1], condition.Params[2]), condition.Desc
    end,
    [11102] = function(condition) --查询玩家角色解放阶段是否达到
        return XDataCenter.ExhibitionManager.IsAchieveLiberation(condition.Params[1], condition.Params[2]), condition.Desc
    end,
    [11103] = function(condition) -- 查询玩家是否领取首充奖励
        return XDataCenter.PayManager.GetFirstRechargeReward(), condition.Desc
    end,
    [11104] = function(condition) -- 查询玩家是否拥有某个时装
        return XDataCenter.FashionManager.CheckHasFashion(condition.Params[1]), condition.Desc
    end,
    [11105] = function(condition) -- 查询玩家是否不拥有某个时装
        return not XDataCenter.FashionManager.CheckHasFashion(condition.Params[1]), condition.Desc
    end,
    [11106] = function(condition) -- 查询玩家是否通过某个试验区关卡（填试验区ID）
        return XDataCenter.FubenExperimentManager.CheckExperimentIsFinish(condition.Params[1]), condition.Desc
    end,
    [11108] = function(condition) -- 查询玩家复刷关等级是否达到
        return XDataCenter.FubenRepeatChallengeManager.IsLevelReach(condition.Params[1]), condition.Desc
    end,
    [11109] = function(condition) -- 查询玩家在指定时间内通过某个关卡
        if not condition.Params or #condition.Params < 2 then
            return false, condition.Desc
        end

        local stageId = condition.Params[1]
        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        if not stageData then
            return false, condition.Desc
        end

        if stageData.BestRecordTime <= 0 or stageData.BestRecordTime > condition.Params[2] then
            return false, condition.Desc
        end

        return true, condition.Desc
    end,
    [11110] = function(condition) -- 查询玩家在本期巴别塔活动中的分数是否超过某个值
        local count = condition.Params[1]
        local _, maxLevel = XDataCenter.FubenBabelTowerManager.GetCurrentActivityScores()

        if maxLevel >= count then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [11111] = function(condition) --查询当前爬塔达到的最高层数
        local curMaxTier = XDataCenter.FubenRogueLikeManager.GetHistoryMaxTier()
        if condition and condition.Params[1] then
            return curMaxTier >= condition.Params[1], condition.Desc
        end
        return false, condition.Desc
    end,
    [11112] = function(condition) --查询玩家是否拥有某个永久武器时装
        local id = condition.Params[1]
        local ret =
            XDataCenter.WeaponFashionManager.CheckHasFashion(id) and
            not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(id)
        return ret, condition.Desc
    end,
    [11113] = function(condition) --查询玩家是否不拥有某个永久武器时装
        local id = condition.Params[1]
        local ret =
            not XDataCenter.WeaponFashionManager.CheckHasFashion(id) or
            XDataCenter.WeaponFashionManager.IsFashionTimeLimit(id)
        return ret, condition.Desc
    end,
    [11114] = function(condition) --查询玩家是否拥有一堆时装中的某一个
        local ret = false
        for _, fashionId in pairs(condition.Params) do
            ret =
                XDataCenter.WeaponFashionManager.CheckHasFashion(fashionId) and
                not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(fashionId)
            if ret then
                break
            end
        end
        return ret, condition.Desc
    end,
    [11117] = function(condition) --查询玩家是否拥指定ID的场景
        local ret = false
        ret = XDataCenter.PhotographManager.CheckSceneIsHaveById(condition.Params[1])
        return ret, condition.Desc
    end,
    [11118] = function(condition, soundStageId) --查询玩家是否通关消消乐
        local stageId = condition.Params[1]
        if
            XTool.IsNumberValid(stageId) and XTool.IsNumberValid(soundStageId) and
                XDataCenter.LivWarmSoundsActivityManager.IsStageUnlock(soundStageId) and
                XDataCenter.LivWarmActivityManager.IsStageWin(stageId)
         then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [11119] = function(condition) --超级据点作战期开启时长是否达标
        local targetTime = tonumber(condition.Params[1])
        local passingTime = XDataCenter.StrongholdManager.GetFightPassingTime()
        return passingTime >= targetTime, condition.Desc
    end,
    [11120] = function(condition) --查询玩家是否通关音频
        local stageId = condition.Params[1]
        if XTool.IsNumberValid(stageId) and XDataCenter.LivWarmSoundsActivityManager.IsStageFinished(stageId) then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [12101] = function(condition) -- 查询武器库是否有容量
        return XDataCenter.EquipManager.CheckMaxCount(XEquipConfig.Classify.Weapon), condition.Desc
    end,
    [12102] = function(condition) -- 查询意识库是否有容量
        return XDataCenter.EquipManager.CheckMaxCount(XEquipConfig.Classify.Awareness), condition.Desc
    end,
    [12103] = function(condition) --超级据点通过据点使用的电力
        local groupId = tonumber(condition.Params[1])
        local requireUseElectric = tonumber(condition.Params[2])
        return XDataCenter.StrongholdManager.CheckGroupPassUseElectric(groupId, requireUseElectric), condition.Desc
    end,
    [21101] = function(condition) -- 查询玩家是否购买月卡
        local isGot = true
        local uiType = condition.Params[1]
        local id = condition.Params[2]
        if XDataCenter.PurchaseManager.IsYkBuyed(uiType, id) then
            local data = XDataCenter.PurchaseManager.GetYKInfoData(uiType, id)
            if data then
                isGot = data.IsDailyRewardGet
            end
        end
        return not isGot, condition.Desc
    end,
    [21102] = function(condition) -- 查询玩家是否未领取首充奖励
        return not XDataCenter.PayManager.GetFirstRechargeReward(), condition.Desc
    end,
    [22001] = function(condition) -- 红包活动ID下指定NPC累计获得的物品数量
        local count = condition.Params[1]
        local itemId = condition.Params[2]
        local activityId = condition.Params[3]
        local npcId = condition.Params[4]
        local total = XDataCenter.ItemManager.GetRedEnvelopeCertainNpcItemCount(activityId, npcId, itemId)
        return total >= count, condition.Desc
    end,
    [23001] = function(condition) -- 判断服务器时间是否达到某个开始时间
        local timeId = condition.Params[1]
        return XFunctionManager.CheckInTimeByTimeId(timeId), condition.Desc
    end,
    [15101] = function(condition)
        local nodeId = condition.Params[1]
        local cfg = XFubenExploreConfigs.GetLevel(nodeId)
        if not cfg then
            return false, condition.Desc
        end
        return XDataCenter.FubenExploreManager.IsNodeFinish(cfg.ChapterId, nodeId), condition.Desc
    end,
    [15102] = function(condition)
        local chapterId = condition.Params[1]
        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
        return (chapterData and chapterData:IsPass()), condition.Desc
    end,
    [15106] = function(condition)
        local count = condition.Params[1]
        local myCount = XDataCenter.ArenaOnlineManager.GetFirstPassCount()
        return myCount >= count, condition.Desc
    end,
    [15110] = function(condition) --查询纷争战区是否开启
        return XDataCenter.ArenaManager.IsPlayerCanEnterFight(), condition.Desc
    end,
    [15111] = function(condition) --幻痛囚笼是否开启
        return XDataCenter.FubenBossSingleManager.IsBossSingleOpen(), condition.Desc
    end,
    [15200] = function(condition) -- 主线普通与隐藏模式的收集进度是否均达到100%
        local chapterMainId = condition.Params[1]
        local chapterMain = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(chapterMainId)
        local NorProgress = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterMain.ChapterId[1])
        local DiffProgress = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterMain.ChapterId[2])

        if NorProgress >= condition.Params[2] and DiffProgress >= condition.Params[2] then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [15201] = function(condition) -- 外篇普通与隐藏模式的收集进度是否均达到100%
        local chapterMainId = condition.Params[1]
        local chapterMain = XDataCenter.ExtraChapterManager.GetChapterCfg(chapterMainId)
        local NorProgress = XDataCenter.ExtraChapterManager.GetProgressByChapterId(chapterMain.ChapterId[1])
        local DiffProgress = XDataCenter.ExtraChapterManager.GetProgressByChapterId(chapterMain.ChapterId[2])

        if NorProgress >= condition.Params[2] and DiffProgress >= condition.Params[2] then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [15202] = function(condition) -- 是否通关周目章节
        local lastStage = XFubenZhouMuConfigs.GetZhouMuChapterLastStage(condition.Params[1])
        local flag = XDataCenter.FubenManager.CheckStageIsPass(lastStage)
        return flag, condition.Desc
    end,
    [15203] = function(condition)-- 故事集普通与隐藏模式的收集进度是否均达到100%
        local chapterMainId = condition.Params[1]
        local chapterIds = XFubenShortStoryChapterConfigs.GetShortStoryChapterIds(chapterMainId)
        local NorProgress = XDataCenter.ShortStoryChapterManager.GetProgressByChapterId(chapterIds[1])
        if not chapterIds[2] then
            if NorProgress >= condition.Params[2] then
                return true, condition.Desc
            end
        else
            local DiffProgress = XDataCenter.ShortStoryChapterManager.GetProgressByChapterId(chapterIds[2])
            if NorProgress >= condition.Params[2] and DiffProgress >= condition.Params[2] then
                return true, condition.Desc
            end
        end
        return false, condition.Desc
    end,
    [16100] = function(condition) --查询公会等级是否达到（服务端未实现）
        if not XDataCenter.GuildManager.IsJoinGuild() then
            return false, condition.Desc
        end
        local guildLevel = XDataCenter.GuildManager.GetGuildLevel()
        if condition.Params and condition.Params[1] > 0 and guildLevel >= condition.Params[1] then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [22002] = function(condition) --查询公会职务是否与参数中任一值匹配
        if not XDataCenter.GuildManager.IsJoinGuild() then
            return false, condition.Desc
        end
        local rankLevel = XDataCenter.GuildManager.GetCurRankLevel()
        for i = 1, #condition.Params do
            if rankLevel == condition.Params[i] then
                return true, condition.Desc
            end
        end
        return false, condition.Desc
    end,
    [10117] = function(condition) -- 查询玩家荣耀勋阶是否达标
        return XPlayer.GetHonorLevel() >= condition.Params[1], condition.Desc
    end,
    [10125] = function(condition)
        local recruitLevel = XDataCenter.ExpeditionManager.GetRecruitLevel()
        return recruitLevel and recruitLevel >= condition.Params[1]
    end,
    [15301] = function(condition) --追击玩法
        local mapId = condition.Params[1]
        local mapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(mapId)
        if mapDb and mapDb:IsKill() then
            return true
        else
            return false, condition.Desc
        end
    end,
    [15302] = function(condition) --追击玩法
        local mapId = condition.Params[1]
        local killBossCount = condition.Params[2]
        local mapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(mapId)
        if mapDb and mapDb:IsKill() then
            return mapDb:GetWinForBattleCount() <= killBossCount
        else
            return false, condition.Desc
        end
    end,
    [15303] = function(condition) --追击玩法:是否布过阵
        for i, mapId in ipairs(condition.Params) do
            local mapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(mapId)
            if mapDb and not mapDb:NeedBuZhen() then
                return true
            end
        end
    end,
    [15304] = function(condition) --骇入玩法:查询研发等级是否达到
        if XDataCenter.FubenHackManager.GetIsActivityEnd() then
            return false
        end
        return condition.Params[1] >= XDataCenter.FubenHackManager.GetLevel()
    end,
    [15305] = function(condition) --分光双星（双人成行）：检测已锁定角色的关卡数
        local target = condition.Params[1]
        local chapterId = condition.Params[2]
        local passCount = XDataCenter.FubenCoupleCombatManager.GetStageSchedule(chapterId)
        return passCount >= target, condition.Desc
    end,
    --全服决战 begin
    [16001] = function(condition) --净化区块数量达到N
        local requireCount = condition.Params[1]
        local clearCount = XDataCenter.AreaWarManager.GetBlockProgress()
        return clearCount >= requireCount, condition.Desc
    end,
    [16002] = function(condition) --指定区块Id被净化
        local blockId = condition.Params[1]
        local ret = XDataCenter.AreaWarManager.IsBlockClear(blockId)
        return ret, condition.Desc
    end,
    --全服决战 end
    -- 肉鸽 begin
    [17000] = function(condition) -- 检查已经完全通过的章节是否达到条件
        local chapterId = condition.Params[1]
        return XDataCenter.TheatreManager.CheckIsGlobalFinishChapter(chapterId), condition.Desc
    end,
    [17001] = function(condition) -- 检查是否已经完成某事件的某步骤
        local eventId = condition.Params[1]
        local stepId = condition.Params[2]
        return XDataCenter.TheatreManager.CheckIsGlobalFinishEvent(eventId, stepId), condition.Desc
    end,
    [17002] = function(condition) --肉鸽玩法：检查是否成功将特定DecorationId升级至X级
        local manager = XDataCenter.TheatreManager.GetDecorationManager()
        local decorationId = condition.Params[1]
        local lv = condition.Params[2]
        local curLv = manager:GetDecorationLv(decorationId)
        return curLv >= lv, condition.Desc
    end,
    [17003] = function(condition) -- 检查冒险是否达成结局
        local endingId = condition.Params[1]
        return XDataCenter.TheatreManager.CheckIsFinishEnding(endingId), condition.Desc
    end,
    [10151] = function(condition)
        if XDataCenter.DormManager.CheckHaveDormCharacter(condition.Params[1]) then
            return true
        end
        return false, condition.Desc
    end,
    -- 肉鸽 end
    -- 大逃杀 begin
    [10160] = function(condition) --检查章节是否通关
        local chapterId = condition.Params[1]
        if XDataCenter.EscapeManager.IsChapterClear(chapterId) then
            return true
        end
        return false, condition.Desc
    end,
    -- 大逃杀 end
    [10148] = function(condition) --检查黄金矿工角色是否解锁
        local redEnvelopeNpcId = condition.Params[1]
        local count = condition.Params[2]
        if XDataCenter.GoldenMinerManager.IsCharacterUnLock(redEnvelopeNpcId) then
            return true
        end
        return false, condition.Desc
    end,
}

local CharacterCondition = {
    [13101] = function(condition, characterId) -- 查询角色性别是否符合
        if type(characterId) ~= "number" then
            characterId = characterId.Id
        end
        local characterTemplate = XCharacterConfigs.GetCharacterTemplate(characterId)
        return characterTemplate.Sex == condition.Params[1], condition.Desc
    end,
    [13102] = function(condition, characterId) -- 查询角色类型是否符合
        local character = characterId
        if type(characterId) == "number" then
            character = XDataCenter.CharacterManager.GetCharacter(characterId)
        end
        local npcId = XCharacterConfigs.GetCharNpcId(character.Id, character.Quality)
        local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)
        for i = 1, #condition.Params do
            if npcTemplate.Type == condition.Params[i] then
                return true
            end
        end
        return false, condition.Desc
    end,
    [13103] = function(condition, characterId) -- 查询角色是否符合等级
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        return character.Level >= condition.Params[1], condition.Desc
    end,
    [13104] = function(condition, characterId) -- 查询单个角色类型是否符合
        local character = characterId
        if type(characterId) == "number" then
            character = XDataCenter.CharacterManager.GetCharacter(characterId)
        end
        local npcId = XCharacterConfigs.GetCharNpcId(character.Id, character.Quality)
        local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcId)
        if npcTemplate.Type == condition.Params[1] then
            return true
        end
        return false, condition.Desc
    end,
    [13105] = function(condition, characterId) -- 查询单个角色品质是否符合
        local character = characterId
        if type(characterId) == "number" then
            character = XDataCenter.CharacterManager.GetCharacter(characterId)
        end

        -- 查询单个角色品质和星级是否符合
        if XTool.IsNumberValid(condition.Params[3]) then
            if character.Quality > condition.Params[1] or 
               character.Quality == condition.Params[1] and character.Star >= condition.Params[3] then
                return true
            end
        elseif character.Quality >= condition.Params[1] then
            return true
        end

        return false, condition.Desc
    end,
    [13106] = function(condition, characterId) -- 查询拥有构造体
        if characterId == condition.Params[1] then
            return true
        end

        return false, condition.Desc
    end,
    [13107] = function(condition, characterId) --查询角色是否符合Grade等级要求
        local character = nil
        if type(characterId) == "number" then
            character = XDataCenter.CharacterManager.GetCharacter(characterId)
        end

        if not character then
            return false, condition.Desc
        end

        if character.Grade >= condition.Params[1] then
            return true
        end
        return false, condition.Desc
    end,
    [13108] = function(condition, characterId) --查询角色战力是否满足
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        if character.Ability >= condition.Params[1] then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [13109] = function(condition, characterId) --查询角色是否佩戴共鸣技能
        local starLimit = condition.Params[1]
        local limitSkillNum = condition.Params[2]
        local allSkillNum = 0

        local weaponData = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
        local equipInfo = XDataCenter.EquipManager.GetEquip(weaponData)
        local star = XDataCenter.EquipManager.GetEquipStar(equipInfo.TemplateId)
        if star >= starLimit then
            if equipInfo.ResonanceInfo ~= nil then
                for _, info in pairs(equipInfo.ResonanceInfo) do
                    if info.CharacterId == characterId then
                        allSkillNum = allSkillNum + 1
                    end
                end
            end
        end

        local awarenessData = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(characterId)
        for _, equipId in pairs(awarenessData) do
            local equipInfo2 = XDataCenter.EquipManager.GetEquip(equipId)
            local star2 = XDataCenter.EquipManager.GetEquipStar(equipInfo2.TemplateId)
            if star2 >= starLimit then
                if equipInfo2.ResonanceInfo ~= nil then
                    for _, info in pairs(equipInfo2.ResonanceInfo) do
                        if info.CharacterId == characterId then
                            allSkillNum = allSkillNum + 1
                        end
                    end
                end
            end
        end

        if allSkillNum >= limitSkillNum then
            return true, condition.Desc
        end

        return false, condition.Desc
    end,
    [13110] = function(condition, characterId) --角色武器共鸣技能数
        if not condition.Params or #condition.Params ~= 2 then
            return false, condition.Desc
        end
        local resonanceCount = 0
        local weaponData = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
        local equipInfo = XDataCenter.EquipManager.GetEquip(weaponData)
        if equipInfo.ResonanceInfo ~= nil then
            for _, info in pairs(equipInfo.ResonanceInfo) do
                local quality = XDataCenter.EquipManager.GetEquipQuality(equipInfo.TemplateId)
                if info.CharacterId == characterId and quality >= condition.Params[1] then
                    resonanceCount = resonanceCount + 1
                end
                if resonanceCount > condition.Params[2] then
                    return true, condition.Desc
                end
            end
        end
        return false, condition.Desc
    end,
    [13111] = function(condition, characterId) --角色意识共鸣技能数
        if not condition.Params or #condition.Params ~= 2 then
            return false, condition.Desc
        end
        local weaponData = XDataCenter.EquipManager.GetCharacterWearingAwarenessIds(characterId)
        local resonanceCount = 0
        for _, equipId in pairs(weaponData) do
            local equipInfo = XDataCenter.EquipManager.GetEquip(equipId)
            if equipInfo.ResonanceInfo ~= nil then
                for _, info in pairs(equipInfo.ResonanceInfo) do
                    local quality = XDataCenter.EquipManager.GetEquipQuality(equipInfo.TemplateId)
                    if info.CharacterId == characterId and quality >= condition.Params[1] then
                        resonanceCount = resonanceCount + 1
                    end
                    if resonanceCount > condition.Params[2] then
                        return true, condition.Desc
                    end
                end
            end
        end
        return false, condition.Desc
    end,
    [13112] = function(condition, characterId) --角色指定id武器共鸣技能数
        if not condition.Params or #condition.Params ~= 2 then
            return false, condition.Desc
        end
        local weaponData = XDataCenter.EquipManager.GetCanUseWeaponIds(characterId)
        local resonanceCount = 0
        local equipInfo = nil
        for _, equipId in pairs(weaponData) do
            if equipId == condition.Params[1] then
                equipInfo = XDataCenter.EquipManager.GetEquip(equipId)
            end

            if equipInfo then
                if equipInfo.ResonanceInfo ~= nil then
                    for _, info in pairs(equipInfo.ResonanceInfo) do
                        if info.CharacterId == characterId then
                            resonanceCount = resonanceCount + 1
                        end
                        if resonanceCount > condition.Params[2] then
                            return true, condition.Desc
                        end
                    end
                end
            end
        end
        return false, condition.Desc
    end,
    [13113] = function(condition) --判断是否是好感度最高的构造体
        if not condition.Params or #condition.Params < 1 then
            return false, condition.Desc
        end

        local id = XDataCenter.FavorabilityManager.GetHighestTrustExpCharacter()

        for _, roleId in pairs(condition.Params) do
            if id == roleId then
                return true
            end
        end

        return false, condition.Desc
    end,
    [13114] = function(condition, characterId) -- 构造体是否终解
        local character = XDataCenter.CharacterManager.GetCharacter(characterId)
        if not character then
            return false, condition.Desc
        end
        local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(character.Id)
        return (XDataCenter.ExhibitionManager.IsMaxLiberationLevel(growUpLevel)), condition.Desc
    end,
    [13115] = function(condition, characterId) -- 构造体是否类型相符（构造体，感染体）
        local character = characterId
        if type(characterId) == "number" then
            character = XDataCenter.CharacterManager.GetCharacter(characterId)
        end
        local charType = XCharacterConfigs.GetCharacterType(character.Id)
        if charType == condition.Params[1] then
            return true
        end
        return false, condition.Desc
    end,
    [13116] = function(condition, characterId) -- 检查角色Sp技能等级
        local character = characterId
        if type(characterId) == "number" then
            character = XDataCenter.CharacterManager.GetCharacter(characterId)
        end
        local groupId = character:EnhanceSkillIdToGroupId(condition.Params[1])
        local groupEntity = character:GetEnhanceSkillGroupData(groupId)
        local skillLevel = groupEntity:GetLevel()
        if skillLevel >= condition.Params[2] then
            return true, condition.Desc
        end
        return false, condition.Desc
    end,
    [59001] = function(condition) --查询猜拳小游戏对应关卡是否通关
        local stageId = condition.Params[1]
        local stage = XDataCenter.FingerGuessingManager.GetStageByStageId(stageId)
        if stage then
            return stage:GetIsClear(), condition.Desc
        end
        return false, condition.Desc
    end,
}

local TeamCondition = {
    [18101] = function(condition, characterIds) -- 查询队伍角色性别是否符合
        local ret, desc = true, nil
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret, desc = CharacterCondition[13101](condition, id)
                    if not ret then
                        break
                    end
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        if ret then
                            ret, desc = CharacterCondition[13101](condition, id)
                        end
                    end
                end
            )
        end

        return ret, desc
    end,
    [18102] = function(condition, characterIds) -- 查询队伍角色类型是否符合
        local ret, desc = true, nil
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret, desc = CharacterCondition[13102](condition, id)
                    if not ret then
                        break
                    end
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret, desc = CharacterCondition[13102](condition, id)
                        if ret then
                            ret, desc = CharacterCondition[13101](condition, id)
                        end
                    end
                end
            )
        end

        return ret, desc
    end,
    [18103] = function(condition, characterIds) -- 查询队伍是否拥有指定角色数量
        local chechCount = condition.Params[1] or 1
        local total = 0
        if type(characterIds) == "table" then
            for i = 2, #condition.Params do
                for _, id in pairs(characterIds) do
                    if id > 0 then
                        if id == condition.Params[i] then
                            total = total + 1
                            break
                        end
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            for i = 2, #condition.Params do
                XTool.LoopCollection(
                    characterIds,
                    function(id)
                        if id > 0 then
                            if id == condition.Params[i] then
                                total = total + 1
                            end
                        end
                    end
                )

                if total >= chechCount then
                    break
                end
            end
        end

        return total >= chechCount, condition.Desc
    end,
    [18104] = function(condition, characterIds) -- 查询队伍是否已拥有指定角色数量
        if type(characterIds) == "table" then
            for i = 1, #condition.Params do
                for _, id in pairs(characterIds) do
                    if id > 0 then
                        if id == condition.Params[i] then
                            return false, condition.Desc
                        end
                    end
                end
            end
        else
            for i = 2, #condition.Params do
                XTool.LoopCollection(
                    characterIds,
                    function(id)
                        if id > 0 then
                            if id == condition.Params[i] then
                                return false, condition.Desc
                            end
                        end
                    end
                )
            end
        end

        return true, condition.Desc
    end,
    [18105] = function(condition, characterIds) -- 派遣中拥有指定数量指定兵种构造
        local ret = true
        local chechCount = condition.Params[2] or 1
        local total = 0
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret = CharacterCondition[13104](condition, id)
                    if ret then
                        total = total + 1
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret = CharacterCondition[13104](condition, id)
                        if ret then
                            total = total + 1
                        end
                    end

                    if total >= chechCount then
                        return
                    end
                end
            )
        end

        return total >= chechCount, condition.Desc
    end,
    [18106] = function(condition, characterIds) -- 派遣中拥有指定数量达到指定战斗力的构造体
        local chechCount = condition.Params[2] or 1
        local total = 0

        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                local character = XDataCenter.CharacterManager.GetCharacter(id)
                if character.Ability >= condition.Params[1] then
                    total = total + 1
                end
            end
        end

        return total >= chechCount, condition.Desc
    end,
    [18107] = function(condition, characterIds) -- 派遣中拥有指定数量达到指定品质的构造体
        local ret = true
        local chechCount = condition.Params[2] or 1
        local total = 0
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret = CharacterCondition[13105](condition, id)
                    if ret then
                        total = total + 1
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret = CharacterCondition[13105](condition, id)
                        if ret then
                            total = total + 1
                        end
                    end

                    if total >= chechCount then
                        return
                    end
                end
            )
        end

        return total >= chechCount, condition.Desc
    end,
    [18108] = function(condition, characterIds) -- 派遣中拥有指定数量达到指定等级的构造体
        local ret = true
        local chechCount = condition.Params[2] or 1
        local total = 0
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret = CharacterCondition[13103](condition, id)
                    if ret then
                        total = total + 1
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret = CharacterCondition[13103](condition, id)
                        if ret then
                            total = total + 1
                        end
                    end

                    if total >= chechCount then
                        return
                    end
                end
            )
        end

        return total >= chechCount, condition.Desc
    end,
    [18109] = function(condition, characterIds) -- 派遣中拥有指定数量指定性别的构造体
        local ret = true
        local chechCount = condition.Params[2] or 1
        local total = 0
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret = CharacterCondition[13101](condition, id)
                    if ret then
                        total = total + 1
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret = CharacterCondition[13101](condition, id)
                        if ret then
                            total = total + 1
                        end
                    end

                    if total >= chechCount then
                        return
                    end
                end
            )
        end

        return total >= chechCount, condition.Desc
    end,
    [18110] = function(condition, characterIds) -- 派遣中拥有构造体
        local ret = true
        local chechCount = condition.Params[2] or 1
        local total = 0
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret = CharacterCondition[13106](condition, id)
                    if ret then
                        total = total + 1
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret = CharacterCondition[13106](condition, id)
                        if ret then
                            total = total + 1
                        end
                    end

                    if total >= chechCount then
                        return
                    end
                end
            )
        end

        return total >= chechCount, condition.Desc
    end,
    [18111] = function(condition, characterIds) -- 仅可上阵N个人
        local count = condition.Params[1]
        local compareType = condition.Params[2]
        local total = 0
        for _, v in pairs(characterIds) do
            if v > 0 then
                total = total + 1
            end
        end
        if compareType == XUiCompareType.Equal then --等于
            return total == count, condition.Desc
        end
        if compareType == XUiCompareType.NoLess then --大于等于
            return total >= count, condition.Desc
        end
        return false, condition.Desc
    end,
    [18112] = function(condition, characterIds) -- 要求队伍中有N个类型构造体
        local ret = true
        local chechCount = condition.Params[2] or 1
        local total = 0
        if type(characterIds) == "table" then
            for _, id in pairs(characterIds) do
                if id > 0 then
                    ret = CharacterCondition[13115](condition, id)
                    if ret then
                        total = total + 1
                    end
                end

                if total >= chechCount then
                    break
                end
            end
        else
            XTool.LoopCollection(
                characterIds,
                function(id)
                    if id > 0 then
                        ret = CharacterCondition[13115](condition, id)
                        if ret then
                            total = total + 1
                        end
                    end

                    if total >= chechCount then
                        return
                    end
                end
            )
        end

        return total >= chechCount, condition.Desc
    end
}

local KillCondition = {
    [30101] = function(condition, npcId) -- 查询怪物击杀数是否达到
        return XDataCenter.ArchiveManager.GetMonsterKillCount(npcId) >= condition.Params[1], condition.Desc
    end
}

local EquipCondition = {
    [31101] = function(condition, equipId) -- 是否拥有某个装备
        return XDataCenter.ArchiveManager.IsEquipGet(equipId), condition.Desc
    end,
    [31102] = function(condition, equipId) -- 装备是否达到目标等级
        return XDataCenter.ArchiveManager.GetEquipLv(equipId) >= condition.Params[1], condition.Desc
    end,
    [31103] = function(condition, equipId) -- 武器的突破次数是否达到目标次数
        return XDataCenter.ArchiveManager.GetEquipBreakThroughTimes(equipId) >= condition.Params[1], condition.Desc
    end,
    [31104] = function(condition, suitId) -- 套装中某一个意识的等级是否达到目标等级
        local idList = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
        local targetNum = condition.Params[1]
        local isOpen = false
        for _, id in ipairs(idList) do
            if XDataCenter.ArchiveManager.GetEquipLv(id) >= targetNum then
                isOpen = true
                break
            end
        end
        return isOpen, condition.Desc
    end,
    [31105] = function(condition, suitId) -- 套装中某一个意识的突破次数是否达到目标次数
        local idList = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
        local targetNum = condition.Params[1]
        local isOpen = false
        for _, id in ipairs(idList) do
            if XDataCenter.ArchiveManager.GetEquipBreakThroughTimes(id) >= targetNum then
                isOpen = true
                break
            end
        end
        return isOpen, condition.Desc
    end,
    [31106] = function(condition, suitId) -- 套装中不同的意识的数量达到目标数量
        return XDataCenter.ArchiveManager.GetAwarenessCountBySuitId(suitId) >= condition.Params[1], condition.Desc
    end
}

function XConditionManager.GetConditionType(id)
    local template = ConditionTemplate[id]
    if not template then
        XLog.Error("XConditionManager.GetConditionType error: can not found template, id is " .. id)
        return XConditionManager.ConditionType.Unknown
    end

    -- 0代表公式专用，没有范围设置，主要是要与服务器逻辑同步
    if template.Type == 0 then
        return XConditionManager.ConditionType.Formula
    elseif template.Type >= 13000 and template.Type < 14000 then
        return XConditionManager.ConditionType.Character
    elseif template.Type >= 18000 and template.Type < 19000 then
        return XConditionManager.ConditionType.Team
    elseif template.Type >= 30000 and template.Type < 31000 then
        return XConditionManager.ConditionType.Kill
    elseif template.Type >= 31000 and template.Type < 32000 then
        return XConditionManager.ConditionType.Equip
    else
        return XConditionManager.ConditionType.Player
    end
end

function XConditionManager.Init()
    ConditionTemplate = XTableManager.ReadByIntKey(TABLE_CONDITION_PATH, XTable.XTableCondition, "Id")
end

function XConditionManager.GetConditionTemplate(id)
    if not ConditionTemplate[id] then
        XLog.Error("XConditionManager.GetConditionTemplate config is null " .. id)
        return
    end
    return ConditionTemplate[id]
end

function XConditionManager.CheckCharacterCondition(id, characterId)
    local template = ConditionTemplate[id]
    if not template then
        XLog.Error("XConditionManager.CheckCharacterCondition error: can not found template, id is " .. id)
        return DefaultRet
    end

    local func = CharacterCondition[template.Type]
    if not func then
        XLog.Error(
            "XConditionManager.CheckCharacterCondition error: can not found condition, id is " ..
                id .. " type is " .. template.Type
        )
        return DefaultRet
    end

    return func(template, characterId)
end

function XConditionManager.CheckPlayerCondition(id, ...)
    local template = ConditionTemplate[id]
    if not template then
        XLog.Error("XConditionManager.CheckPlayerCondition error: can not found template, id is " .. id)
        return DefaultRet
    end

    local func = PlayerCondition[template.Type]
    if not func then
        XLog.Error(
            "XConditionManager.CheckPlayerCondition error: can not found condition, id is " ..
                id .. " type is " .. template.Type
        )
        return DefaultRet
    end

    return func(template, ...)
end

function XConditionManager.CheckTeamCondition(id, characterIds)
    local template = ConditionTemplate[id]
    if not template then
        XLog.Error("XConditionManager.CheckTeamCondition error: can not found template, id is " .. id)
        return DefaultRet
    end

    local func = TeamCondition[template.Type]
    if not func then
        XLog.Error(
            "XConditionManager.CheckTeamCondition error: can not found condition, id is " ..
                id .. " type is " .. template.Type
        )
        return DefaultRet
    end

    return func(template, characterIds)
end

function XConditionManager.CheckKillCondition(id, NpcId)
    local template = ConditionTemplate[id]
    if not template then
        XLog.Error("XConditionManager.CheckKillCondition error: can not found template, id is " .. id)
        return DefaultRet
    end

    local func = KillCondition[template.Type]
    if not func then
        XLog.Error(
            "XConditionManager.CheckKillCondition error: can not found condition, id is " ..
                id .. " type is " .. template.Type
        )
        return DefaultRet
    end

    return func(template, NpcId)
end

-- checkedId can be suitId or equipId
function XConditionManager.CheckEquipCondition(conditionId, checkedId)
    local template = ConditionTemplate[conditionId]
    if not template then
        XLog.Error("XConditionManager.CheckEquipCondition error: can not found template, id is " .. conditionId)
        return DefaultRet
    end
    local func = EquipCondition[template.Type]
    if not func then
        XLog.Error(
            "XConditionManager.CheckEquipCondition error: can not found condition, id is " ..
                conditionId .. " type is " .. template.Type
        )
        return DefaultRet
    end

    return func(template, checkedId)
end

function XConditionManager.CheckCondition(id, ...)
    local type = XConditionManager.GetConditionType(id)
    if type == XConditionManager.ConditionType.Character then
        return XConditionManager.CheckCharacterCondition(id, ...)
    elseif type == XConditionManager.ConditionType.Team then
        return XConditionManager.CheckTeamCondition(id, ...)
    elseif type == XConditionManager.ConditionType.Kill then
        return XConditionManager.CheckKillCondition(id, ...)
    elseif type == XConditionManager.ConditionType.Equip then
        return XConditionManager.CheckEquipCondition(id, ...)
    elseif type == XConditionManager.ConditionType.Formula then
        return XConditionManager.CheckComplexCondition(id, ...)
    else
        return XConditionManager.CheckPlayerCondition(id, ...)
    end
end

--[[
    目前条件组合支持这三种情况 & | () 符号任意组合
    1.1001 & (1002 | 1003) —— 都是无参数
    2.1001 & 1002 | 1003 —— 都是需要指定参数（比如指定角色id），比如判断某个角色是否满足等级大于20级同时战力高于1000
    3.1001 & 1002 | 1003 —— 1001无参数 1002需要传角色id，比如满足指挥官等级是否大于50级和某个角色是否大于20级
]]
function XConditionManager.CheckComplexCondition(id, ...)
    local args = {...}
    local conditionFormula = XConditionManager.ConditionFormula
    if conditionFormula == nil then
        local XConditionFormula = require("XFormula/XConditionFormula")
        conditionFormula = XConditionFormula.New()
        XConditionManager.ConditionFormula = conditionFormula
    end
    local config = XConditionManager.GetConditionTemplate(id)
    -- 便于在内部提示配置错误
    conditionFormula:SetConfig(config)
    local result, desc = conditionFormula:GetResult(config.Formula, args)
    if config.Desc then
        desc = config.Desc
    end
    return result, desc
end

function XConditionManager.GetConditionDescById(id)
    if (ConditionTemplate[id] or {}).Desc then
        return ConditionTemplate[id].Desc
    end
end

function XConditionManager.GetConditionParams(id)
    if (ConditionTemplate[id] or {}).Params then
        return tableUnpack(ConditionTemplate[id].Params)
    end
end
