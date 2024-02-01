local XExFubenCollegeStudyManager = require("XEntity/XFuben/XExFubenCollegeStudyManager")

XPracticeManagerCreator = function()
    local XPracticeManager = XExFubenCollegeStudyManager.New(XFubenConfigs.ChapterType.Practice)
    local PracticeChapterInfos = {}
    local PracticeStageInfo = {}
    local IsChallengeWin = false    --战斗结束后是否胜利
    
    local CELICA_TEACHING_ABILITY_GRADE = 2000

    local ChallengeWin = function()
        IsChallengeWin = true
    end

    function XPracticeManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, ChallengeWin)
        XEventManager.AddEventListener(XEventId.EVENT_FIGHT_FINISH_LOSEUI_CLOSE, XPracticeManager.ChallengeLose)
        XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, XPracticeManager.RefreshStagePassed)
    end
--拟真boss出战情况不同于原始的训练模式，需要一种新的副本类型
    function XPracticeManager.InitStageInfo()
        local allPracticeChapters = XPracticeConfigs.GetPracticeChapters()
        for _, chapter in pairs(allPracticeChapters) do
            for _, stageId in pairs(chapter.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    if XTool.IsNumberValid(XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(stageId))then
                        stageInfo.Type = XDataCenter.FubenManager.StageType.PracticeBoss
                    else
                        stageInfo.Type = XDataCenter.FubenManager.StageType.Practice
                    end
                end
            end
            -- 成员战斗
            for _, groupId in pairs(chapter.Groups or {}) do
                local stageIds = XPracticeConfigs.GetPracticeStageIdsByGroupId(groupId)
                for _, stageId in pairs(stageIds or {}) do
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    if stageInfo then
                        stageInfo.Type = XDataCenter.FubenManager.StageType.Practice
                    end
                end
            end
        end
        XPracticeManager.RefreshStagePassed()
    end

    function XPracticeManager.ShowReward(winData)
        if not winData then return end
        XPracticeManager.RefreshStagePassedBySettleDatas(winData.SettleData)

        XLuaUiManager.Open("UiSettleWinTutorialCount", winData)
    end

    function XPracticeManager.CheckPracticeStageOpen(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

        if not stageInfo.Unlock then return false, CS.XTextManager.GetText("FubenNotUnlock") end

        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
            return false, CS.XTextManager.GetText("TeamLevelToOpen", stageCfg.RequireLevel)
        end

        local actInfo = XPracticeConfigs.GetPracticeActivityInfo(stageId)
        local condition = {}
        if XPracticeManager.CheckStageInActivity(stageId) then
            condition = actInfo.ActivityCondition
        elseif actInfo then
            condition = actInfo.OpenCondition
        end

        for _, conditionId in pairs(condition or {}) do
            local ret, desc = XConditionManager.CheckCondition(conditionId)
            if not ret then
                return false, desc
            end
        end
        return true
    end

    function XPracticeManager.GetSortedChapterStage(chapterId, groupId)
        local stageIds = XPracticeConfigs.GetPracticeChapterById(chapterId).StageId
        local sortedNodes = {}
        for _, stageId in pairs(stageIds) do
            local archiveId = XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(stageId)
            local canVisible = XTool.IsNumberValid(archiveId) and XPracticeManager.CheckPracticeStageVisible(archiveId, groupId) or not XTool.IsNumberValid(archiveId)
            if canVisible then
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local isOpen = XPracticeManager.CheckPracticeStageOpen(stageId)
                local inActivity = XPracticeManager.CheckStageInActivity(stageId)
                local weight
                if stageInfo.Passed then
                    -- 已通关
                    weight = 3
                elseif isOpen then
                    -- 可打未通过
                    weight = 1
                else
                    -- 未解锁
                    weight = 2
                end
                table.insert(sortedNodes, {
                    StageId = stageId,
                    InActivity = inActivity,
                    Weight = weight
                })
            end
        end
        table.sort(sortedNodes, function(nodeA, nodeB)
            if nodeA.InActivity ~= nodeB.InActivity then
                return nodeA.InActivity and not nodeB.InActivity
            end
            if nodeA.Weight == nodeB.Weight then
                return nodeA.StageId < nodeB.StageId
            else
                return nodeA.Weight < nodeB.Weight
            end
        end)
        return sortedNodes
    end

    -- 已解锁
    function XPracticeManager.CheckPracticeStageIsUnlock(stageId)
        return PracticeStageInfo[stageId] or false
    end

    -- 进度是否完成
    --function XPracticeManager.IsPracticeStageFinish(chapterId, stageId)
    --    local practiceDatas = PracticeChapterInfos[chapterId]
    --    if not practiceDatas then return false end
    --    for _, finishStageId in pairs(practiceDatas) do
    --        if finishStageId == stageId then
    --            return true
    --        end
    --    end
    --    return false
    --end

    -- 是否处于活动期间
    function XPracticeManager.CheckStageInActivity(stageId)
        local actInfo = XPracticeConfigs.GetPracticeActivityInfo(stageId)
        if actInfo and actInfo.ActivityTimeId and
                XFunctionManager.CheckInTimeByTimeId(actInfo.ActivityTimeId) then
            return true
        else
            return false
        end
    end

    function XPracticeManager.RefreshStagePassedBySettleDatas(settleData)
        if not settleData then return end

        local chapterId = XPracticeConfigs.GetPracticeChapterIdByStageId(settleData.StageId)
        if chapterId ~= 0 then
            if not PracticeChapterInfos[chapterId] then
                PracticeChapterInfos[chapterId] = {}
            end
            PracticeChapterInfos[chapterId][settleData.StageId] = true
            PracticeStageInfo[settleData.StageId] = true
            XPracticeManager.RefreshStagePassed()
            XEventManager.DispatchEvent(XEventId.EVENT_PRACTICE_ON_DATA_REFRESH)
        end
    end
    
    function XPracticeManager.RefreshStagePassedByStageId(stageId)
        if not XTool.IsNumberValid(stageId) then
            return
        end

        local chapterId = XPracticeConfigs.GetPracticeChapterIdByStageId(stageId)
        if chapterId ~= 0 then
            if not PracticeChapterInfos[chapterId] then
                PracticeChapterInfos[chapterId] = {}
            end
            PracticeChapterInfos[chapterId][stageId] = true
            PracticeStageInfo[stageId] = true
            XPracticeManager.RefreshStagePassed()
            XEventManager.DispatchEvent(XEventId.EVENT_PRACTICE_ON_DATA_REFRESH)
        end
    end
    
    function XPracticeManager.RefreshStagePassed()
        local allPracticeChapters = XPracticeConfigs.GetPracticeChapters()
        for _, chapter in pairs(allPracticeChapters) do
            for _, stageId in pairs(chapter.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo and stageInfo.Type ~= XDataCenter.FubenManager.StageType.PracticeBoss then--拟真boss不走这一套
                    stageInfo.Passed = PracticeStageInfo[stageId] or false

                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true

                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                    end
                    for _, prestageId in pairs(stageCfg.PreStageId or {}) do
                        if prestageId > 0 then
                            if not PracticeStageInfo[prestageId] then
                                stageInfo.Unlock = false
                                stageInfo.IsOpen = false
                                break
                            end
                        end
                    end

                end
            end
            -- 成员战斗
            for _, groupId in pairs(chapter.Groups or {}) do
                local stageIds = XPracticeConfigs.GetPracticeStageIdsByGroupId(groupId)
                for _, stageId in pairs(stageIds or {}) do
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                    if stageInfo then
                        stageInfo.Passed = PracticeStageInfo[stageId] or false

                        stageInfo.Unlock = true
                        stageInfo.IsOpen = true

                        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                            stageInfo.Unlock = false
                            stageInfo.IsOpen = false
                        end
                        for _, prestageId in pairs(stageCfg.PreStageId or {}) do
                            if prestageId > 0 then
                                if not PracticeStageInfo[prestageId] then
                                    stageInfo.Unlock = false
                                    stageInfo.IsOpen = false
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -----------拟真boss------
    function XPracticeManager.CheckPracticeStageVisible(archiveId, groupId)
        if groupId == nil then
            return true
        end
        if not XTool.IsNumberValid(archiveId)  then
            return true
        end

        local timeId = XPracticeConfigs.GetSimulateTrainMonsterTimeId(archiveId)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId, true)
        if (isInTime) and (groupId == 0 or XPracticeConfigs.GetSimulateTrainMonsterGroupId(archiveId) == groupId) then
            if XMVCA.XArchive:IsArchiveMonsterUnlockByArchiveId(archiveId) then
                return true
            end
        end
        return false
    end
    --只针对拟真boss类型使用
    function XPracticeManager.CheckPracticeStagesVisibleByChapterId(chapterId)
        if chapterId then
            local stageIds = XPracticeConfigs.GetPracticeChapterStageIdById(chapterId)
            if XTool.IsTableEmpty(stageIds) then
                return true
            end
            for i, id in pairs(stageIds) do
                local archiveId = XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(id)
                if XPracticeManager.CheckPracticeStageVisible(archiveId, 0) then
                    return true
                end
            end
        end
        return false
    end

    function XPracticeManager.CheckUnLockBtnState(id)--true false表名按钮状态，id标识主按钮，nil标识非boss类型
        if XPracticeConfigs.GetPracticeChapterTypeById(id) == XPracticeConfigs.PracticeType.Boss then
            if XTool.IsNumberValid(XPracticeConfigs.GetPracticeSubTagById(id)) then
                return XDataCenter.PracticeManager.CheckPracticeStagesVisibleByChapterId(id)
            else
                return id
            end
        end
        return nil
    end

    local function GetCookieKeyTeam()
        return string.format("XPracticeManager_CookieKeyTeam_Boss_%d", XPlayer.Id)
    end

    -- 保存编队信息
    function XPracticeManager.SaveBossTeamLocal(curTeam)
        XSaveTool.SaveData(GetCookieKeyTeam(), curTeam)
    end

    -- 读取本地编队信息
    function XPracticeManager.LoadBossTeamLocal()
        local team = XSaveTool.GetData(GetCookieKeyTeam()) or XDataCenter.TeamManager.EmptyTeam
        return XTool.Clone(team)
    end

    local function GetCookieKeyStage(stageId)
        return string.format("XPracticeManager_CookieKeyStage_Boss_%d_StagId_%d", XPlayer.Id, stageId)
    end

    -- 保存玩家关卡信息
    function XPracticeManager.SaveKeyBossStageSetting(stageId, hard, period, atk, hp)
        local stageSettingInfo = {hard = hard, period = period, atk = atk, hp = hp}
        XSaveTool.SaveData(GetCookieKeyStage(stageId), stageSettingInfo)
    end

    -- 读取本地关卡信息
    function XPracticeManager.LoadBossStageSettingLocal(stageId)
        local stageSettingInfo = XSaveTool.GetData(GetCookieKeyStage(stageId))
        return XTool.IsTableEmpty(stageSettingInfo) and {} or XTool.Clone(stageSettingInfo)
    end

    --检查怪物是否开启
    function XPracticeManager.CheckSimulateTrainMonsterExist(archiveId)
        if not XPracticeConfigs.CheckSimulateTrainMonsterExist(archiveId) then
            return false
        end

        local timeId = XPracticeConfigs.GetSimulateTrainMonsterTimeId(archiveId)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId, true)
        if isInTime and XMVCA.XArchive:IsArchiveMonsterUnlockByArchiveId(archiveId) then
            return true
        end
        return false
    end

    local function GetCookieKeyChapter(chapterId)
        return string.format("XPracticeManager_CookieKeyChapter_PlayerId_%s_ChapterId_%s", XPlayer.Id, chapterId)
    end

    --红点检测，检查是否点击过了拟真boss页签
    function XPracticeManager.CheckBossNewChallengerRedPoint(chapterId)
        return XSaveTool.GetData(GetCookieKeyChapter(chapterId)) or false
    end

    function XPracticeManager.SaveClickBossNewChallenger(chapterId)
        if XPracticeManager.CheckBossNewChallengerRedPoint(chapterId) then
            return
        end
        XSaveTool.SaveData(GetCookieKeyChapter(chapterId), true)
    end
    -------拟真boss end-------

    function XPracticeManager.ChallengeLose()
        IsChallengeWin = false
    end

    function XPracticeManager.GetIsChallengeWin()
        return IsChallengeWin
    end

    -- 同步数据
    function XPracticeManager.OnAsyncPracticeData(chapterInfos)
        if not chapterInfos then return end
        for _, v in pairs(chapterInfos) do
            if not PracticeChapterInfos[v.Id] then
                PracticeChapterInfos[v.Id] = {}
            end
            for _, stageId in pairs(v.FinishStages or {}) do
                PracticeChapterInfos[v.Id][stageId] = true
                PracticeStageInfo[stageId] = true
            end
        end

        XPracticeManager.RefreshStagePassed()
    end

    --region 赛利卡教学相关

    --[[
        return
        [1] : 是否拥有角色
        [2] : 战力值
        [3] : 是否通关
    ]]
    local CheckCelicaTeachCondition = function(characterId)
        if not characterId then
            return false, false, false
        end
        if XRobotManager.CheckIsRobotId(characterId) then
            characterId = XRobotManager.GetCharacterId(characterId)
        end
        -- 是否拥有该角色
        local isOwnerCharacter = XMVCA.XCharacter:IsOwnCharacter(characterId)
        local ability = 0  -- 未拥有的角色战力视为0
        if isOwnerCharacter then
            local character = XMVCA.XCharacter:GetCharacter(characterId)
            ability = character.Ability
        end

        local groupId = XPracticeConfigs.GetGroupIdByCharacterId(characterId)
        -- 是否全通关（包含赛丽卡补习班group是否全通关 或 TeachingActivity.tab的角色ID对应stage是否全通关）
        local isPassed = XPracticeManager.CheckStageAllPass(groupId) or XDataCenter.FubenNewCharActivityManager.CheckStagePassByCharacterId(characterId)
        return isOwnerCharacter, ability, isPassed
    end

    -- 构造教学按钮key
    function XPracticeManager.GetBtnTeachingCookieKey(characterId)
        return "XPracticeManager_GetBtnTeachingCookieKey_"..XPlayer.Id.."_"..characterId
    end

    function XPracticeManager.HaveBtnTeachingCookie(characterId)
        local key = XPracticeManager.GetBtnTeachingCookieKey(characterId)
        return XSaveTool.GetData(key)
    end

    function XPracticeManager.SetBtnTeachingCookie(characterId)
        local key = XPracticeManager.GetBtnTeachingCookieKey(characterId)
        if not XPracticeManager.HaveBtnTeachingCookie(characterId) then
            XSaveTool.SaveData(key, "HasClickedBtnTeaching")
        end
    end

    -- 构造教学每日提示key
    function XPracticeManager.GetDiglogHintCookieKey()
        return "XPracticeManager_GetDiglogHintCookieKey_"..XPlayer.Id
    end

    function XPracticeManager.HaveDiglogHintCookie()
        local key = XPracticeManager.GetDiglogHintCookieKey()
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < updateTime
    end

    -- 设置-是否选中今日不再提示
    function XPracticeManager.SetDiglogHintCookie(isSelect)
        local key = XPracticeManager.GetDiglogHintCookieKey()
        if not isSelect then
            XSaveTool.RemoveData(key)
        else
            if XPracticeManager.HaveDiglogHintCookie() then return end
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        end
    end

    -- 根据角色id(支持机器人id)跳转到对应的赛利卡教学界面
    function XPracticeManager.OpenUiFubenPractice(characterId, isSetTag)
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Practice) then
            XUiManager.TipMsg(XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.Practice))
            return
        end
        if XRobotManager.CheckIsRobotId(characterId) then
            characterId = XRobotManager.GetCharacterId(characterId)
        end
        if isSetTag then
            XPracticeManager.SetBtnTeachingCookie(characterId)
        end
        local groupId = XPracticeConfigs.GetGroupIdByCharacterId(characterId)
        local chapterId = XPracticeConfigs.GetChapterIdByGroupId(groupId)
        if not (groupId and chapterId) then
            XLog.Error("Can Not Open UiFubenPractice groupId = ", groupId, ", chapterId = ", chapterId)
        end
        XDataCenter.PracticeManager.OpenUiFubenPratice(chapterId, groupId)
    end

    -- 是否显示提示
    function XPracticeManager.IsShowTeachDialogHintTip(characterId)
        --只在选人界面显示提示框（目前包含：通用选人界面，诺曼底登录选人界面）
        if not XLuaUiManager.IsUiShow("UiStrongholdRoomCharacterV2P6") and not XLuaUiManager.IsUiShow("UiBattleRoomRoleDetail") then
            return false
        end
        if not characterId then
            return false
        end
        if not XRobotManager.CheckIsRobotId(characterId) then
            return false -- 不是机器人则不提示
        else
            characterId = XRobotManager.GetCharacterId(characterId)
        end
        local bOwned, ability, bPassed = CheckCelicaTeachCondition(characterId)
        local bHasCookie = XPracticeManager.HaveDiglogHintCookie()
        local bOpenCelicaTeach = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Practice)
        --[[
            显示每日提示条件
            ["未拥有该角色", "拥有角色且战力值不足2000且未通过塞利卡"] 满足任意一个
            且 没有选中今日不再提示
            且 已经开放赛利卡教学
        ]]--
        local bTips = not bOwned or (bOwned and ability < CELICA_TEACHING_ABILITY_GRADE and not bPassed)
        return bTips and not bHasCookie and bOpenCelicaTeach
    end

    -- 获取每日提示信息
    --[[
        @characterId  角色Id
        return        提示信息
    ]]--
    function XPracticeManager.GetTeachDialogHintTip(characterId)
        --[[
            1. 玩家未拥有该角色（不管有没有通过赛利卡）；
                提示：检测到指挥官未拥有该成员，是否需要进行成员教学？
            2. 玩家拥有该，且该角色战力不足2000，且玩家未通过赛利卡。
                提示：检测到指挥官的该成员战力不足2000，且未通过赛利卡补习班教学，是否需要进行成员教学？
        ]]--
        local bOwned, ability, bPassed = CheckCelicaTeachCondition(characterId)
        if not bOwned then
            return CSXTextManagerGetText("CelicaTechDialogHintTip1")
        end

        if bOwned and ability < CELICA_TEACHING_ABILITY_GRADE and not bPassed then
            return CSXTextManagerGetText("CelicaTechDialogHintTip2")
        end
        
        return CSXTextManagerGetText("CelicaTechTips")
    end
    
    -- 显示每日提示
    local isShowTips = false
    function XPracticeManager.ShowTeachDialogHintTip(characterId, cancelCallBack, confirmCallBack)
        --如果已经显示弹窗，则不显示多次(不用XLuaUiManager.IsUiShow, 避免出现其他系统弹提示）
        if isShowTips then 
            return 
        end
        local title     = CS.XTextManager.GetText("CelicaTechTipsTitle")
        local content   = XPracticeManager.GetTeachDialogHintTip(characterId)
        local status    = XDataCenter.PracticeManager.HaveDiglogHintCookie()
        local hintInfo  = {
            SetHintCb   = XDataCenter.PracticeManager.SetDiglogHintCookie,
            Status      = status,
            IsNeedClose = true,
        }
        local closeCb = function()
            isShowTips = false
            if cancelCallBack then cancelCallBack() end
        end
        
        local sureCb = function()
            isShowTips = false
            if confirmCallBack then confirmCallBack() end
        end
        isShowTips = true
        XUiManager.DialogHintTip(title, content, "", closeCb, sureCb, hintInfo)
    end

    -- 带显示每日提示的编队回调
    --[[
        @characterId        角色Id
        @confirmCallBack    编入队伍-点击确认教学回调
        @joinFinishCallBack 编入队伍-点击取消教学回调
    ]]--
    function XPracticeManager.OnJoinTeam(characterId, confirmCallBack, joinFinishCallBack)
        if not (characterId and confirmCallBack and joinFinishCallBack) then
            return
        end
        -- 特殊处理 特训关(元宵)不需要弹出提示
        local isTip = XDataCenter.FubenSpecialTrainManager.CheckSpecialTrainRobotId(characterId)
        
        if XPracticeManager.IsShowTeachDialogHintTip(characterId) and not isTip then
            XPracticeManager.ShowTeachDialogHintTip(characterId, joinFinishCallBack, confirmCallBack)
        else
            joinFinishCallBack() -- 正常编入队伍
        end
    end

    -- 教学按钮红点显示规则
    function XPracticeManager.CheckShowCelicaTeachRedDot(characterId)
        if not characterId then
            return false
        end
        if XRobotManager.CheckIsRobotId(characterId) then
            characterId = XRobotManager.GetCharacterId(characterId)
        end
        local bOwned, ability, bPassed = CheckCelicaTeachCondition(characterId)
        local bClickBtnTeach = XPracticeManager.HaveBtnTeachingCookie(characterId)
        local bOpenCelicaTeach = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Practice)
        --[[
            出现蓝点情况：
                [未拥有该角色, 拥有但战力不足2000] 任意满足一个
                且 未通关对应的教学关卡
                且 未点击教学按钮
                且 已经开放赛利卡教学
        ]]
        return (not bOwned or (bOwned and ability < CELICA_TEACHING_ABILITY_GRADE)) and not bPassed and not bClickBtnTeach and bOpenCelicaTeach
    end

    -- 章节是否处于活动期间
    function XPracticeManager.CheckChapterInActivity(groupId)
        local activityTimeId = XPracticeConfigs.GetPracticeGroupActivityTimeId(groupId)
        if XTool.IsNumberValid(activityTimeId) and XFunctionManager.CheckInTimeByTimeId(activityTimeId) then
            return true
        else
            return false
        end
    end
    
    function XPracticeManager.CheckPracticeChapterOpen(groupId)
        local condition = {}
        if XPracticeManager.CheckChapterInActivity(groupId) then
            condition = XPracticeConfigs.GetPracticeGroupActivityCondition(groupId)
        else
            condition = XPracticeConfigs.GetPracticeGroupOpenCondition(groupId)
        end

        for _, conditionId in pairs(condition or {}) do
            local ret, desc = XConditionManager.CheckCondition(conditionId)
            if not ret then
                return false, desc
            end
        end
        return true
    end
    
    -- 所有关卡是否全部通关
    function XPracticeManager.CheckStageAllPass(groupId)
        if not XTool.IsNumberValid(groupId) then
            return false
        end
        local stageIds = XPracticeConfigs.GetPracticeStageIdsByGroupId(groupId)
        
        if XTool.IsTableEmpty(stageIds) then
            return false
        end
        
        for _, stageId in pairs(stageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if not stageInfo.Passed then
                return false
            end
        end
        return true
    end

    function XPracticeManager.GetSortedChapterById(id)
        local infos = XPracticeConfigs.GetPracticeChapterById(id)
        local sortedNodes = {}
        for index, groupId in pairs(infos.Groups) do
            local weight
            local allPass = XPracticeManager.CheckStageAllPass(groupId)
            local isOpen = XPracticeManager.CheckPracticeChapterOpen(groupId)
            local inActivity = XPracticeManager.CheckChapterInActivity(groupId)
            if allPass then
                -- 已全通关
                weight = 3
            elseif isOpen then
                -- 可打未通过
                weight = 1
            else
                -- 未解锁
                weight = 2
            end
            table.insert(sortedNodes, {
                GroupId = groupId,
                Index = index,
                InActivity = inActivity,
                Weight = weight
            })
        end
        
        table.sort(sortedNodes, function(nodeA, nodeB)
            if nodeA.InActivity ~= nodeB.InActivity then
                return nodeA.InActivity and not nodeB.InActivity
            end
            if nodeA.Weight == nodeB.Weight then
                return nodeA.Index < nodeB.Index
            else
                return nodeA.Weight < nodeB.Weight
            end
        end)
        return sortedNodes
    end
    
    ---关卡进度
    ---@return number 通关关卡数|总关卡数
    function XPracticeManager.GetChapterProgress(groupId)
        local stageIdList = XPracticeConfigs.GetPracticeStageIdsByGroupId(groupId)
        local passNum = 0
        local totalNum = #stageIdList

        for _, stageId in ipairs(stageIdList) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo.Passed then
                passNum = passNum + 1
            end
        end

        return passNum, totalNum
    end
    
    --endregion

    ------------------副本入口扩展 start-------------------------
    function XPracticeManager:ExOpenMainUi()
        if not XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
            return
        end
        XPracticeManager.OpenUiFubenPratice()
    end
    
    function XPracticeManager.OpenUiFubenPratice(...)
        --if not XMVCA.XSubPackage:CheckSubpackage() then
        --    return
        --end

        XLuaUiManager.Open("UiFubenPractice", ...)
    end
    
    ------------------副本入口扩展 end-------------------------

    XPracticeManager.Init()
    return XPracticeManager
end

XRpc.NotifyPracticeData = function(response)
    if not response then return end
    XDataCenter.PracticeManager.OnAsyncPracticeData(response.ChapterInfos)
end
