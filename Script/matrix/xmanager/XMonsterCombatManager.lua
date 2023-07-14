-- BVB管理类
XMonsterCombatManagerCreator = function()
    local XMonsterCombat = require("XEntity/XMonsterCombat/XMonsterCombat")
    local XMonsterCombatActivityEntity = require("XEntity/XMonsterCombat/Entity/XMonsterCombatActivityEntity")
    local XMonsterCombatChapterEntity = require("XEntity/XMonsterCombat/Entity/XMonsterCombatChapterEntity")
    local XMonsterCombatMonsterEntity = require("XEntity/XMonsterCombat/Entity/XMonsterCombatMonsterEntity")
    local XMonsterCombatStageEntity = require("XEntity/XMonsterCombat/Entity/XMonsterCombatStageEntity")
    ---@class XMonsterCombatManager
    local XMonsterCombatManager = {}
    ---@type XMonsterCombat
    local MonsterCombatViewModel = nil
    ---@type XMonsterCombatActivityEntity
    local MonsterCombatActivityEntity = nil
    ---@type table<number, XMonsterCombatChapterEntity>
    local MonsterCombatChapterEntity = {}
    ---@type table<number, XMonsterCombatMonsterEntity>
    local MonsterCombatMonsterEntity = {}
    ---@type table<number, XMonsterCombatStageEntity>
    local MonsterCombatStageEntity = {}

    -- 队伍缓存
    ---@type table<number, XMonsterTeam>
    local MonsterTeamCache = {}

    --region Entity

    ---@return XMonsterCombatActivityEntity
    function XMonsterCombatManager.GetActivityEntity()
        if not MonsterCombatViewModel then
            return
        end
        local activityId = MonsterCombatViewModel:GetActivityId()
        if not XTool.IsNumberValid(activityId) then
            XLog.Error("XMonsterCombatManager GetActivityEntity error: ActivityId错误，ActivityId:" .. activityId)
            return
        end
        if not MonsterCombatActivityEntity then
            MonsterCombatActivityEntity = XMonsterCombatActivityEntity.New(activityId)
        else
            MonsterCombatActivityEntity:UpdateActivityId(activityId)
        end
        return MonsterCombatActivityEntity
    end

    ---@return XMonsterCombatChapterEntity
    function XMonsterCombatManager.GetChapterEntity(chapterId)
        if not XTool.IsNumberValid(chapterId) then
            XLog.Error("XMonsterCombatManager GetChapterEntity error: ChapterId错误，ChapterId:" .. chapterId)
            return
        end
        local chapter = MonsterCombatChapterEntity[chapterId]
        if not chapter then
            chapter = XMonsterCombatChapterEntity.New(chapterId)
            MonsterCombatChapterEntity[chapterId] = chapter
        end
        return chapter
    end

    ---@return XMonsterCombatMonsterEntity
    function XMonsterCombatManager.GetMonsterEntity(monsterId)
        if not XTool.IsNumberValid(monsterId) then
            XLog.Error("XMonsterCombatManager GetMonsterEntity error: monsterId错误，monsterId:" .. monsterId)
            return
        end
        local monster = MonsterCombatMonsterEntity[monsterId]
        if not monster then
            monster = XMonsterCombatMonsterEntity.New(monsterId)
            MonsterCombatMonsterEntity[monsterId] = monster
        end
        return monster
    end

    ---@return XMonsterCombatStageEntity
    function XMonsterCombatManager.GetStageEntity(stageId)
        if not XTool.IsNumberValid(stageId) then
            XLog.Error("XMonsterCombatManager GetStageEntity error: stageId错误，stageId:" .. stageId)
            return
        end
        local stage = MonsterCombatStageEntity[stageId]
        if not stage then
            stage = XMonsterCombatStageEntity.New(stageId)
            MonsterCombatStageEntity[stageId] = stage
        end
        return stage
    end

    --endregion

    --region 关卡相关

    function XMonsterCombatManager.InitStageInfo()
        XMonsterCombatManager.InitStageType()
    end

    function XMonsterCombatManager.InitStageType()
        local chapterTemplates = XMonsterCombatConfigs.GetAllConfigs(XMonsterCombatConfigs.TableKey.MonsterCombatChapter)
        for _, chapter in pairs(chapterTemplates) do
            for _, stageId in pairs(chapter.StageIds or {}) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.MonsterCombat
                    stageInfo.ChapterId = chapter.Id
                end
            end
        end
    end

    function XMonsterCombatManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = { 0, 0, 0 }
        preFight.RobotIds = { 0, 0, 0 }
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local monsterTeam = MonsterTeamCache[teamId]
        local entityId = monsterTeam:GetCaptainPosEntityId()
        local pos = monsterTeam:GetCaptainPos()
        local isRobot = XEntityHelper.GetIsRobot(entityId)
        preFight.RobotIds[pos] = isRobot and entityId or 0
        preFight.CardIds[pos] = isRobot and 0 or entityId
        preFight.CaptainPos = pos
        preFight.FirstFightPos = monsterTeam:GetFirstFightPos()
        preFight.MonsterCombatMonsters = monsterTeam:GetMonsterIds()
        return preFight
    end

    function XMonsterCombatManager.ShowReward(winData)
        XLuaUiManager.Open("UiMonsterCombatFight", winData)
    end

    function XMonsterCombatManager.CheckUnlockByStageId(stageId)
        local stageEntity = XMonsterCombatManager.GetStageEntity(stageId)
        return stageEntity:CheckIsUnlock()
    end

    function XMonsterCombatManager.CheckPassedByStageId(stageId)
        local stageEntity = XMonsterCombatManager.GetStageEntity(stageId)
        return stageEntity:CheckIsPass()
    end

    function XMonsterCombatManager.CustomRecordFightBeginData(stageId)
        local beginData = XDataCenter.FubenManager.GetFightBeginData()
        -- 战斗是否通关使用活动数据判断
        beginData.LastPassed = XMonsterCombatManager.CheckPassedByStageId(stageId)
    end

    --endregion

    ---@param monsterTeam XMonsterTeam
    function XMonsterCombatManager.UpdateMonsterTeamCache(monsterTeam)
        MonsterTeamCache[monsterTeam:GetId()] = monsterTeam
    end

    --region 本地数据

    function XMonsterCombatManager.GetChapterClickKey(chapterId)
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if activityEntity then
            return activityEntity:GetLocalSaveDataKey("MonsterCombatChapterClick_%s_%s_%s", chapterId)
        end
    end

    function XMonsterCombatManager.CheckChapterClick(chapterId)
        local key = XMonsterCombatManager.GetChapterClickKey(chapterId)
        local data = XSaveTool.GetData(key) or 0
        return data == 1 and true or false
    end

    function XMonsterCombatManager.SaveChapterClick(chapterId)
        local key = XMonsterCombatManager.GetChapterClickKey(chapterId)
        local data = XSaveTool.GetData(key) or 0
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end

    function XMonsterCombatManager.GetMonsterClickKey(monsterId)
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if activityEntity then
            return activityEntity:GetLocalSaveDataKey("MonsterCombatMonsterClick_%s_%s_%s", monsterId)
        end
    end

    function XMonsterCombatManager.CheckMonsterClick(monsterId)
        local key = XMonsterCombatManager.GetMonsterClickKey(monsterId)
        local date = XSaveTool.GetData(key) or 0
        return date == 1 and true or false
    end

    function XMonsterCombatManager.SaveMonsterClick(monsterId)
        local key = XMonsterCombatManager.GetMonsterClickKey(monsterId)
        local data = XSaveTool.GetData(key) or 0
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end

    function XMonsterCombatManager.GetChapterAnimationKey(chapterId)
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if activityEntity then
            return activityEntity:GetLocalSaveDataKey("MonsterCombatChapterAnimation_%s_%s_%s", chapterId)
        end
    end

    function XMonsterCombatManager.CheckChapterAnimation(chapterId)
        local key = XMonsterCombatManager.GetChapterAnimationKey(chapterId)
        local date = XSaveTool.GetData(key) or 0
        return date == 1
    end

    function XMonsterCombatManager.SaveChapterAnimation(chapterId)
        local key = XMonsterCombatManager.GetChapterAnimationKey(chapterId)
        local data = XSaveTool.GetData(key) or 0
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end

    --endregion

    function XMonsterCombatManager.CheckActivityRedPoint()
        -- 开启
        if not XMonsterCombatManager.IsOpen(true) then
            return false
        end
        -- 新解锁章节
        if XMonsterCombatManager.CheckNewUnlockChapterRedPoint() then
            return true
        end
        -- 任务奖励
        if XMonsterCombatManager.CheckTaskRewardRedPoint() then
            return true
        end
        return false
    end

    function XMonsterCombatManager.CheckNewUnlockChapterRedPoint()
        local chapterIds = XMonsterCombatManager.GetActivityChapterIds()
        for _, chapterId in pairs(chapterIds) do
            local chapterEntity = XMonsterCombatManager.GetChapterEntity(chapterId)
            if chapterEntity:CheckNewUnlockChapter() then
                return true
            end
        end
        return false
    end

    function XMonsterCombatManager.CheckNewUnlockMonsterRedPoint()
        local viewModel = XMonsterCombatManager.GetViewModel()
        if not viewModel then
            return false
        end
        local allUnlockMonsters = viewModel:GetAllUnlockMonsters()
        for _, monsterId in pairs(allUnlockMonsters) do
            local monsterEntity = XMonsterCombatManager.GetMonsterEntity(monsterId)
            if monsterEntity:CheckNewUnlockMonster() then
                return true
            end
        end
        return false
    end

    function XMonsterCombatManager.CheckTaskRewardRedPoint()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return false
        end
        return activityEntity:CheckLimitTaskList()
    end

    function XMonsterCombatManager.OpenMainUi()
        if XMonsterCombatManager.IsOpen() then
            XLuaUiManager.Open("UiMonsterCombatMain")
        end
    end

    function XMonsterCombatManager.IsOpen(noTips)
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            if not noTips then
                XUiManager.TipText("CommonActivityNotStart")
            end
            return false
        end
        return activityEntity:IsOpen(noTips)
    end

    function XMonsterCombatManager.GetHelpKey()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return nil
        end
        return activityEntity:GetHelpKey()
    end

    function XMonsterCombatManager.GetActivityEndTime()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return 0
        end
        return activityEntity:GetEndTime()
    end

    function XMonsterCombatManager.GetActivityChapterIds()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return {}
        end
        return activityEntity:GetChapterIds()
    end

    function XMonsterCombatManager.GetActivityMonsterCostLimit()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return 0
        end
        return activityEntity:GetMonsterCostLimit()
    end

    function XMonsterCombatManager.GetActivityMonsterCountLimit()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return 0
        end
        return activityEntity:GetMonsterCountLimit()
    end

    function XMonsterCombatManager.GetActivityTaskList()
        local activityEntity = XMonsterCombatManager.GetActivityEntity()
        if not activityEntity then
            return {}
        end
        return activityEntity:GetTimeLimitTaskList()
    end

    function XMonsterCombatManager.OnActivityEnd(needRunMain)
        MonsterCombatViewModel = nil
        MonsterCombatActivityEntity = nil
        MonsterCombatChapterEntity = {}
        MonsterCombatMonsterEntity = {}
        MonsterCombatStageEntity = {}
        MonsterTeamCache = {}

        if needRunMain then
            XLuaUiManager.RunMain()
            XUiManager.TipText("CommonActivityEnd")
        end
    end

    ---@return XMonsterCombat
    function XMonsterCombatManager.GetViewModel()
        return MonsterCombatViewModel
    end

    -- 登录的时候下发
    function XMonsterCombatManager.NotifyMonsterCombatData(data)
        local activityId = data.ActivityId
        if XTool.IsNumberValid(activityId) then
            if not MonsterCombatViewModel then
                MonsterCombatViewModel = XMonsterCombat.New(data)
            else
                MonsterCombatViewModel:UpdateData(data)
            end
        else
            XMonsterCombatManager.OnActivityEnd()
        end
    end

    function XMonsterCombatManager.Init()

    end

    XMonsterCombatManager.Init()
    return XMonsterCombatManager
end

XRpc.NotifyMonsterCombatData = function(data)
    XDataCenter.MonsterCombatManager.NotifyMonsterCombatData(data)
end