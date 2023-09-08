local XAdventureManager = require("XEntity/XTheatre/Adventure/XAdventureManager")
local XTheatreTokenManager = require("XEntity/XTheatre/Token/XTheatreTokenManager")
local XTheatreDecorationManager = require("XEntity/XTheatre/Decoration/XTheatreDecorationManager")
local XTheatrePowerManager = require("XEntity/XTheatre/Power/XTheatrePowerManager")
local XTheatreTaskManager = require("XEntity/XTheatre/Task/XTheatreTaskManager")
local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")

XTheatreManagerCreator = function()
    ---@class XTheatreManager:XExFubenSimulationChallengeManager
    local XTheatreManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.Theatre)
    -- 当前冒险管理 XAdventureManager
    ---@type XTheatreAdventureManager
    local CurrentAdventureManager = nil
    -- 信物管理 XTheatreTokenManager
    local TokenManager = nil
    -- 装修改造管理
    local DecorationManager = XTheatreDecorationManager.New()
    -- 好感度管理
    local PowerManager = XTheatrePowerManager.New()
    -- 任务管理
    local TaskManager = XTheatreTaskManager.New()
    -- 完全经过的章节，章节ID
    local _PassChapterIdList = {}
    -- 已经完成的时间步骤
    local _PassEventRecordDic = {}
    -- 是否连续挑战多关卡
    local _AutoMultiFight = false
    -- 是否挑战多关卡
    local _MultiFight = false
    -- 当前正在挑战的多关卡下标
    local _CurFightStageIndex = 0
    -- 已完成的结局数据
    local _EndingIdRecords = {}

    function XTheatreManager.InitWithServerData(data)
        local tokenManager = XTheatreManager.GetTokenManager()
        tokenManager:UpdateData(data)
        DecorationManager:UpdateData(data.Decorations)
        PowerManager:UpdateData(data)

        XTheatreManager.UpdatePassChapterIds(data.PassChapterId)
        XTheatreManager.UpdatePassEventRecord(data.PassEventRecord)
        XTheatreManager.UpdateEndingIdRecords(data.EndingRecord)

        -- 更新当前冒险数据
        if data.CurChapterDb then
            XTheatreManager.UpdateCurrentAdventureManager(XAdventureManager.New())
            CurrentAdventureManager:InitWithServerData({
                CurChapterDb = data.CurChapterDb,   -- 章节数据
                DifficultyId = data.DifficultyId,   -- 难度
                KeepsakeId = data.KeepsakeId,   -- 信物
                CurRoleLv = data.CurRoleLv, -- 冒险等级
                ReopenCount = data.ReopenCount, -- 重开次数
                Skills = data.Skills,   -- 拥有技能
                RecruitRole = data.RecruitRole, -- 已招募的角色 TheatreRoleAttr表的roleId
                SingleTeamData = data.SingleTeamData,   -- 单队伍数据
                MultiTeamDatas = data.MultiTeamDatas,   -- 多队伍数据
                UseOwnCharacter = data.UseOwnCharacter, -- 是否使用自己的角色 0否 1是
                FavorCoin = data.FavorCoin, -- 当前章节获取的好感度
                DecorationCoin = data.DecorationCoin,   -- 当前章节获取的装修点
                PassNodeCount = data.PassNodeCount,     -- 当前章节通过的节点数
            })
        end
    end

    function XTheatreManager.UpdatePassChapterIds(value)
        _PassChapterIdList = value or {}
    end

    function XTheatreManager.UpdatePassEventRecord(value)
        _PassEventRecordDic = value or {}
    end

    function XTheatreManager.UpdateEndingIdRecords(value)
        _EndingIdRecords = value or {}
    end

    function XTheatreManager.CheckIsGlobalFinishChapter(chapterId)
        for _, v in pairs(_PassChapterIdList) do
            if v == chapterId then
                return true
            end
        end
        return false
    end

    function XTheatreManager.CheckIsGlobalFinishEvent(eventId, stepId)
        if not _PassEventRecordDic[eventId] then return false end
        if not _PassEventRecordDic[eventId][stepId] then return false end
        return true
    end

    function XTheatreManager.CheckIsFinishEnding(id)
        for _, v in pairs(_EndingIdRecords) do
            if v == id then
                return true
            end
        end
        return false
    end

    function XTheatreManager.CheckHasAdventure()
        return CurrentAdventureManager ~= nil
    end

    function XTheatreManager.GetDecorationManager()
        return DecorationManager
    end

    ---@return XTheatreAdventureManager
    function XTheatreManager.GetCurrentAdventureManager()
        return CurrentAdventureManager
    end

    function XTheatreManager.CreateAdventureManager()
        return XAdventureManager.New()
    end

    function XTheatreManager.UpdateCurrentAdventureManager(value)
        if CurrentAdventureManager then 
            CurrentAdventureManager:Release() 
            CurrentAdventureManager = nil
        end
        CurrentAdventureManager = value
    end

    function XTheatreManager.GetTokenManager()
        if TokenManager == nil then
            TokenManager = XTheatreTokenManager.New()
        end
        return TokenManager
    end

    function XTheatreManager.GetPowerManager()
        return PowerManager
    end

    function XTheatreManager.GetHelpKey()
        return XTheatreConfigs.GetClientConfig("HelpKey")
    end

    function XTheatreManager.GetReopenHelpKey()
        return XTheatreConfigs.GetClientConfig("ReopenHelpKey")
    end

    -- 局外显示资源
    function XTheatreManager.GetAssetItemIds()
        return {XTheatreConfigs.TheatreOutsideCoin
            , XTheatreConfigs.TheatreDecorationCoin
            , XTheatreConfigs.TheatreFavorCoin}
    end

    -- 局内显示资源
    function XTheatreManager.GetAdventureAssetItemIds()
        return {XTheatreConfigs.TheatreCoin}
    end

    function XTheatreManager.GetAllCoinItemDatas()
        local result = {}
        local itemManager = XDataCenter.ItemManager
        local coinCount = itemManager:GetCount(XTheatreConfigs.TheatreCoin)
        if coinCount > 0 then
            table.insert(result, {
                TemplateId = XTheatreConfigs.TheatreCoin,
                Count = coinCount
            })
        end
        local decorationCoinCount = itemManager:GetCount(XTheatreConfigs.TheatreDecorationCoin)
        if decorationCoinCount > 0 then
            table.insert(result, {
                TemplateId = XTheatreConfigs.TheatreDecorationCoin,
                Count = decorationCoinCount
            })
        end
        local favorCoinCount = itemManager:GetCount(XTheatreConfigs.TheatreFavorCoin)
        if favorCoinCount > 0 then
            table.insert(result, {
                TemplateId = XTheatreConfigs.TheatreFavorCoin,
                Count = favorCoinCount
            })
        end
        return result
    end

    -- 副本相关
    function XTheatreManager.InitStageInfo()
        -- 关卡池的关卡
        local configs = XTheatreConfigs.GetTheatreStage()
        local stageInfo = nil
        for _, config in pairs(configs) do
            for _, id in ipairs(config.StageId) do
                if id > 0 then
                    stageInfo = XDataCenter.FubenManager.GetStageInfo(id)
                    if stageInfo then
                        stageInfo.Type = XDataCenter.FubenManager.StageType.Theatre
                    else
                        XLog.Error("肉鸽找不到配置的关卡id：" .. id)
                    end
                end
            end
        end
        -- 事件的关卡
        configs = XTheatreConfigs.GetTheatreEvent()
        for _, config in pairs(configs) do
            if config.StageId > 0 then
                stageInfo = XDataCenter.FubenManager.GetStageInfo(config.StageId)    
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.Theatre    
                else
                    XLog.Error("肉鸽找不到配置的关卡id：" .. config.StageId)
                end
            end
        end
    end

    function XTheatreManager.OpenFightLoading(stageId)
        if not _AutoMultiFight then
            XDataCenter.FubenManager.OpenFightLoading(stageId)
            return
        end

        local nextBattleIndex = CurrentAdventureManager:GetAdventureMultiDeploy():GetNextBattleIndex()
        XLuaUiManager.Open("UiTheatreMultiBattleInfo", nextBattleIndex, stageId)
    end

    function XTheatreManager.CloseFightLoading(stageId)
        if not _AutoMultiFight then
            XDataCenter.FubenManager.CloseFightLoading(stageId)
        else
            XLuaUiManager.Remove("UiTheatreMultiBattleInfo")
        end
    end

    function XTheatreManager.CallFinishFight()
        local fubenManager = XDataCenter.FubenManager
        local res = fubenManager.FubenSettleResult
        if not res then
            -- 强退
            XTheatreManager.ClearMultiFightState()
        end
        fubenManager.CallFinishFight()
    end

    function XTheatreManager.FinishFight(settle)
        if settle.IsWin then
            XDataCenter.FubenManager.ChallengeWin(settle)
        else
            local beginData = XDataCenter.FubenManager.GetFightBeginData()
            local winData = XDataCenter.FubenManager.GetChallengeWinData(beginData, settle)
            XTheatreManager.ShowRewardUpdateMultiFight(winData)
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end

    function XTheatreManager.ShowReward(winData, playEndStory)
        winData.OperationQueueType = XTheatreConfigs.OperationQueueType.BattleSettle
        CurrentAdventureManager:AddNextOperationData(winData, true)
        XTheatreManager.ShowRewardUpdateMultiFight(winData)

        --去掉了奖励结算界面，战后播完剧情会没恢复被释放的UI
        if not _AutoMultiFight and not _MultiFight and not XLuaUiManager.IsUiLoad("UiTheatrePlayMain") and playEndStory then
            --XLuaUiManager.Remove("UiTheatrePlayMain")
            --XLuaUiManager.Open("UiTheatrePlayMain")
            --v2.6 UiTheatrePlayMain的enable处理导致Ui连续open卡死锁，故这么写
            CurrentAdventureManager:ShowNextOperation()
        end
    end

    function XTheatreManager.ShowRewardUpdateMultiFight(winData)
        local currentNode = CurrentAdventureManager:GetCurrentChapter():GetCurrentNode()
        local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
        local playableCount = adventureManager and adventureManager:GetPlayableCount() or 0
        if not currentNode or (not _AutoMultiFight and not _MultiFight) then
            XTheatreManager.ClearMultiFightState()
            XLuaUiManager.Remove("UiTheatreDeploy")
            return
        end

        local theatreStageId = currentNode.GetTheatreStageId and currentNode:GetTheatreStageId()
        if winData.SettleData.IsWin then
            if currentNode.SetStageFinish then
                currentNode:SetStageFinish(winData.StageId, _CurFightStageIndex)
            end
        elseif (_MultiFight or _AutoMultiFight) and theatreStageId and playableCount > 0 then
            XTheatreManager.ClearMultiFightState()
        end

        if playableCount <= 0 then
            XLuaUiManager.Remove("UiTheatreDeploy")
            return
        end

        local isAllStageFinish = CurrentAdventureManager:GetAdventureMultiDeploy():IsAllFinished()
        if isAllStageFinish then
            XTheatreManager.ClearMultiFightState()
            XLuaUiManager.Remove("UiTheatreDeploy")
        elseif _AutoMultiFight then
            --多队伍连续战斗
            local nextBattleIndex = CurrentAdventureManager:GetAdventureMultiDeploy():GetNextBattleIndex()
            local stageIdList = theatreStageId and XTheatreConfigs.GetTheatreStageIdList(theatreStageId)
            local stageId = stageIdList and stageIdList[nextBattleIndex]
            XTheatreManager.SetCurFightStageIndex(nextBattleIndex)
            if stageId then
                CurrentAdventureManager:EnterFight(theatreStageId, nextBattleIndex)
            else
                XTheatreManager.ClearMultiFightState()
                XLuaUiManager.Remove("UiTheatreDeploy")
            end
        else
            XTheatreManager.ClearMultiFightState()
        end
    end

    function XTheatreManager.ClearMultiFightState()
        XTheatreManager.SetMultiFightState(false)
        XTheatreManager.SetAutoMultiFight(false)
    end

    function XTheatreManager.SetAutoMultiFight(state)
        _AutoMultiFight = state
    end

    function XTheatreManager.SetMultiFightState(state)
        _MultiFight = state
    end

    function XTheatreManager.SetCurFightStageIndex(index)
        _CurFightStageIndex = index
    end

    function XTheatreManager.GetTaskManager()
        return TaskManager
    end

    function XTheatreManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local team = CurrentAdventureManager:GetTeamById(teamId)
        local cardIds, robotIds = CurrentAdventureManager:GetCardIdsAndRobotIdsFromTeam(team)
        local teamIndex = team and team:GetTeamIndex() or 0
        return {
            StageId = stage.StageId,
            IsHasAssist = isAssist,
            ChallengeCount = challengeCount,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
            TeamIndex = teamIndex,
        }
    end

    function XTheatreManager.CheckCondition(conditionKey, isShowTip)
        local conditionId = XTheatreConfigs.GetTheatreConfig(conditionKey).Value
        conditionId = conditionId and tonumber(conditionId)
        local isUnLock, desc
        if XTool.IsNumberValid(conditionId) then
            isUnLock, desc = XConditionManager.CheckCondition(conditionId)
        else
            isUnLock, desc = true, ""
        end
        if not isUnLock then
            if isShowTip then
                XUiManager.TipError(desc)
            end
            return isUnLock
        end
        return isUnLock
    end

    --更新界面显示的3D背景
    local _UiModel
    local _UiModelGo
    local _SceneInfo
    local _CurLoadSceneChapterId  --当前加载场景的章节
    function XTheatreManager.UpdateSceneUrl(rootUi)
        if not rootUi or not rootUi.Ui then
            return
        end

        local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
        local chapter = adventureManager and adventureManager:GetCurrentChapter()
        local chapterId = (_CurLoadSceneChapterId) or (chapter and chapter:GetId()) or XTheatreConfigs.GetDefaultChapterId()
        local sceneUrl = XTheatreConfigs.GetChapterSceneUrl(chapterId)
        local modelUrl = XTheatreConfigs.GetChapterModelUrl(chapterId)
        
        if XTool.UObjIsNil(_UiModel) or XTool.UObjIsNil(_UiModelGo) or not _SceneInfo or _CurLoadSceneChapterId ~= chapterId then
            --会加载不同的UiModel，隐藏旧的
            if not XTool.UObjIsNil(_UiModelGo) then
                _UiModelGo.gameObject:SetActiveEx(false)
            end
            XTheatreManager.SetSceneActive(false)

            rootUi:LoadUiScene(sceneUrl, modelUrl, nil, false)
            --rootUi:SetGameObject()
            _UiModel = rootUi.UiModel
            _UiModelGo = rootUi.UiModelGo
            _SceneInfo = rootUi.UiSceneInfo
        end
        _UiModel.UiTransfrom = rootUi.Transform
        _UiModelGo.gameObject:SetActiveEx(true)
        XTheatreManager.SetSceneActive(true)
        XTheatreManager.SetCurLoadSceneChapterId(chapterId)
    end

    function XTheatreManager.SetCurLoadSceneChapterId(chapterId)
        _CurLoadSceneChapterId = chapterId
    end

    function XTheatreManager.SetSceneActive(isActive)
        if not _SceneInfo or XTool.UObjIsNil(_SceneInfo.GameObject) then
            return
        end
        _SceneInfo.GameObject:SetActiveEx(isActive)
        if isActive then
            _SceneInfo.SceneSetting.enabled = false
            XScheduleManager.ScheduleOnce(function()
                if not _SceneInfo or XTool.UObjIsNil(_SceneInfo.GameObject) then
                    return
                end
                _SceneInfo.SceneSetting.enabled = true
            end, 1)

            if _UiModel then
                _UiModel.gameObject:SetActiveEx(false)
                _UiModel.gameObject:SetActiveEx(true)
            end

            --播放剧情会把物理相机关了
            local uiNearCamera = _UiModel and _UiModel.UiNearCamera
            if uiNearCamera then
                uiNearCamera.usePhysicalProperties = true
            end
        end
    end

    function XTheatreManager.GetUiModelGo()
        return _UiModelGo
    end

    --显示角色模型的摄像机
    --showFarCameraText, showNearCameraText：要显示的摄像机名
    --isActiveSceneBlur：是否激活动态模糊
    function XTheatreManager.ShowRoleModelCamera(rootUi, showFarCameraText, showNearCameraText, isActiveSceneBlur)
        if XTool.UObjIsNil(_UiModelGo) then
            return
        end

        local uiModelGoTransform = _UiModelGo.transform
        if XTool.UObjIsNil(uiModelGoTransform) then
            return
        end

        local showFarCamera = uiModelGoTransform:FindTransform(showFarCameraText)
        local showNearCamera = uiModelGoTransform:FindTransform(showNearCameraText)
        local farCameraMain = uiModelGoTransform:FindTransform("FarCameraMain")
        local farCameraChoose = uiModelGoTransform:FindTransform("FarCameraChoose")
        local farCameraRecruit = uiModelGoTransform:FindTransform("FarCameraRecruit")
        local farCameraPlayMain = uiModelGoTransform:FindTransform("FarCameraPlayMain")
        local farCameraChooseBuff = uiModelGoTransform:FindTransform("FarCameraChooseBuff")
        local nearCameraMain = uiModelGoTransform:FindTransform("NearCameraMain")
        local nearCameraChoose = uiModelGoTransform:FindTransform("NearCameraChoose")
        local nearCameraRecruit = uiModelGoTransform:FindTransform("NearCameraRecruit")
        local nearCameraPlayMain = uiModelGoTransform:FindTransform("NearCameraPlayMain")
        local nearCameraChooseBuff = uiModelGoTransform:FindTransform("NearCameraChooseBuff")
        local scene3DBlur = uiModelGoTransform:FindTransform("UiFarCamera"):GetComponent("XUiScene3DBlur")
        if farCameraMain then
            farCameraMain.gameObject:SetActiveEx(false)
        end
        if farCameraChoose then
            farCameraChoose.gameObject:SetActiveEx(false)
        end
        if farCameraRecruit then
            farCameraRecruit.gameObject:SetActiveEx(false)
        end
        if farCameraPlayMain then
            farCameraPlayMain.gameObject:SetActiveEx(false)
        end
        if farCameraChooseBuff then
            farCameraChooseBuff.gameObject:SetActiveEx(false)
        end
        if nearCameraMain then
            nearCameraMain.gameObject:SetActiveEx(false)
        end
        if nearCameraChoose then
            nearCameraChoose.gameObject:SetActiveEx(false)
        end
        if nearCameraRecruit then
            nearCameraRecruit.gameObject:SetActiveEx(false)
        end
        if nearCameraPlayMain then
            nearCameraPlayMain.gameObject:SetActiveEx(false)
        end
        if nearCameraChooseBuff then
            nearCameraChooseBuff.gameObject:SetActiveEx(false)
        end
        if showFarCamera then
            showFarCamera.gameObject:SetActiveEx(true)
        end
        if showNearCamera then
            showNearCamera.gameObject:SetActiveEx(true)
        end
        if scene3DBlur then
            scene3DBlur.enabled = isActiveSceneBlur or false
        end
    end

    ------------------自动播放剧情 begin-------------------
    local GetLocalSavedKey = function(key)
        return string.format("%s%d", key, XPlayer.Id)
    end

    function XTheatreManager.CheckAutoPlayStory()
        local localSavedKey = GetLocalSavedKey("TheatreAutoStory")
        local storyId = XTheatreConfigs.GetFirstStoryId()
        if XSaveTool.GetData(localSavedKey) or not storyId then
            XLuaUiManager.Open("UiTheatreMain")
            return
        end

        XDataCenter.MovieManager.PlayMovie(storyId, function()
            --播完剧情会把最上层的界面打开，加个延迟防止先打开本界面
            XScheduleManager.ScheduleOnce(function()
                XLuaUiManager.Open("UiTheatreMain")
            end, 1)
        end)
        XSaveTool.SaveData(localSavedKey, true)
    end
    ------------------自动播放剧情 end---------------------

    ------------------自动弹窗 begin-----------------------
    function XTheatreManager.CheckIsCookie(key, isNotSave)
        local localSavedKey = GetLocalSavedKey(key)
        if XSaveTool.GetData(localSavedKey) then
            return false
        end
        if not isNotSave then
            XSaveTool.SaveData(localSavedKey, true)
        end
        return true
    end

    local TheatreUnlockOwnRoleAutoWindowKey = "TheatreUnlockOwnRoleAutoWindow"
    -- 检查是否打开解锁自用角色弹窗
    function XTheatreManager.CheckUnlockOwnRole()
        local adventureManager = XTheatreManager.GetCurrentAdventureManager()
        if not adventureManager then
            return
        end

        local useOwnCharacterFa = XTheatreConfigs.GetTheatreConfig("UseOwnCharacterFa").Value
        useOwnCharacterFa = useOwnCharacterFa and tonumber(useOwnCharacterFa)
        if not useOwnCharacterFa then
            return
        end

        local power = adventureManager:GeRoleAveragePower()
        if power >= useOwnCharacterFa and XTheatreManager.CheckIsCookie(TheatreUnlockOwnRoleAutoWindowKey) then
            XLuaUiManager.Open("UiTheatreUnlockTips", {ShowTipsPanel = XTheatreConfigs.UplockTipsPanel.OwnRole})
        end
    end

    function XTheatreManager.RemoveOwnRoleCookie()
        XSaveTool.RemoveData(TheatreUnlockOwnRoleAutoWindowKey)
    end

    -- 检查周期任务是否刷新，弹窗提醒（没周任务了，先屏蔽）
    function XTheatreManager.CheckWeeklyTaskWindows()
        -- local nowTime = XTime.GetServerNowTimestamp()
        -- local saveKey = GetLocalSavedKey("TheatreWeeklyTaskWindows")
        -- local refreshTime = XSaveTool.GetData(saveKey) or 0
        -- if refreshTime <= nowTime then
        --     local monday = 1
        --     local nextWeekOfDayStartWithMon = XTime.GetSeverNextWeekOfDayRefreshTime(monday)
        --     XSaveTool.SaveData(saveKey, nextWeekOfDayStartWithMon)
        --     XUiManager.TipText("TheatreWeekTaskRefresh")
        -- end
    end

    --检查配置指定的装修组是否可升级
    function XTheatreManager.CheckDecorationGroupIndexLvUp()
        local groupIndex = XTheatreConfigs.GetCheckDecorationGroupIndex()
        if not groupIndex then
            return
        end

        local decorationIds = XTheatreConfigs.GetDecorationIdsByGroupIndex(groupIndex)
        for _, decorationId in ipairs(decorationIds or {}) do
            if XTheatreManager.IsDecorationLvUp(decorationId) then
                return true
            end
        end
        return false
    end
    ------------------自动弹窗 end-----------------------

    ------------------红点相关 begin-----------------------
    --检查是否有任务奖励可领取
    function XTheatreManager.CheckTaskCanReward()
        local theatreTask = XTheatreConfigs.GetTheatreTask()
        local taskIdList
        for id in pairs(theatreTask) do
            if XTheatreManager.CheckTaskCanRewardByTheatreTaskId(id) then
                return true
            end
        end
        return false
    end

    function XTheatreManager.CheckTaskCanRewardByTheatreTaskId(theatreTaskId)
        local taskIdList = XTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end

    local _TaskStartTimeOpenCookieKey = "TheatreTaskStartTimeOpen_"
    --检查是否有任务过了开启时间
    function XTheatreManager.CheckTaskStartTimeOpen()
        local taskIdList = XTheatreConfigs.GetTheatreTaskHaveStartTimeIdList()
        for _, taskId in ipairs(taskIdList) do
            if XTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId) then
                return true
            end
        end
        return false
    end

    function XTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId)
        local template = XTaskConfig.GetTaskTemplate()[taskId]
        if not template then
            return false
        end

        local startTime = XTime.ParseToTimestamp(template.StartTime)
        local now = XTime.GetServerNowTimestamp()
        if startTime and startTime <= now and not XTheatreManager.CheckIsCookie(_TaskStartTimeOpenCookieKey .. taskId, true) then
            return true
        end
        return false
    end

    function XTheatreManager.CheckTaskStartTimeOpenByTheatreTaskId(theatreTaskId)
        local taskIdList = XTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId) then
                return true
            end
        end
        return false
    end

    function XTheatreManager.SaveTaskStartTimeOpenCookie(theatreTaskId)
        local taskIdList = XTheatreConfigs.GetTaskIdList(theatreTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XTheatreManager.CheckTaskStartTimeOpenByTaskId(taskId) then
                XSaveTool.SaveData(GetLocalSavedKey(_TaskStartTimeOpenCookieKey .. taskId), true)
            end 
        end
    end

    local _TheatreWeekTaskRefreshTimeCookieKey = "TheatreWeekTaskRefreshTime"
    --周任务刷新检查红点（没周任务了，先屏蔽）
    function XTheatreManager.CheckWeeklyTaskRedPoint()
        -- if XTheatreManager.CheckIsCookie(_TheatreWeekTaskRefreshTimeCookieKey, true) then
        --     return true
        -- end
        -- local refreshTime = XSaveTool.GetData(GetLocalSavedKey(_TheatreWeekTaskRefreshTimeCookieKey))
        -- local nowTime = XTime.GetServerNowTimestamp()
        -- return refreshTime <= nowTime
        return false
    end

    --缓存下周一的服务器更新时间
    function XTheatreManager.SaveWeeklyTaskStartWithMonCookie()
        local monday = 1
        local nextWeekOfDayStartWithMon = XTime.GetSeverNextWeekOfDayRefreshTime(monday)
        XSaveTool.SaveData(GetLocalSavedKey(_TheatreWeekTaskRefreshTimeCookieKey), nextWeekOfDayStartWithMon)
    end

    --检查是否显示图鉴红点
    local _TheatreGuideGainFieldCookieKey = "TheatreGuideGainField_"
    function XTheatreManager.CheckFieldGuideRedPoint()
        return XTheatreManager.CheckGuideGainFieldRedPoint() or XTheatreManager.CheckGuidePropRedPoint()
    end

    --检查是否显示增益图鉴的红点
    function XTheatreManager.CheckGuideGainFieldRedPoint()
        local configs = XTheatreConfigs.GetTheatreSkill()
        for id in pairs(configs) do
            if XTheatreManager.GetTokenManager():IsActiveSkill(id) and XTheatreManager.CheckIsCookie(_TheatreGuideGainFieldCookieKey .. id, true) then
                return true
            end
        end
        return false
    end

    --检查是否显示装修的红点
    function XTheatreManager.CheckDecorationRedPoint()
        if not XTheatreManager.CheckCondition("DecorationConditionId") then
            return false
        end

        local decorationIds = XTheatreConfigs.GetTheatreDecorationIds()
        local decorationManager = XTheatreManager.GetDecorationManager()
        for decorationId in pairs(decorationIds) do
            if XTheatreManager.IsDecorationLvUp(decorationId) then
                return true
            end
        end
        return false
    end

    --装修项是否可升级
    function XTheatreManager.IsDecorationLvUp(decorationId)
        local decorationManager = XTheatreManager.GetDecorationManager()
        local theatreDecorationId = decorationManager:GetTheatreDecorationId(decorationId)
        if theatreDecorationId then
            local maxLevel = XTheatreConfigs.GetTheatreDecorationMaxLv(decorationId)
            local curLevel = decorationManager:GetDecorationLv(decorationId)
            local isMaxLv = curLevel >= maxLevel
            local conditionId = decorationManager:GetTheatreDecorationNextLvConditionId(decorationId)
            local ret = not XTool.IsNumberValid(conditionId) and true or XConditionManager.CheckCondition(conditionId)
            local costItemId = XTheatreConfigs.GetDecorationUpgradeCostItemId(theatreDecorationId)
            local costUpgradeCost = XTheatreConfigs.GetDecorationUpgradeCost(theatreDecorationId)
            local costCostCount = XDataCenter.ItemManager.GetCount(costItemId)
            local isLevelUp = not isMaxLv and ret and costCostCount >= costUpgradeCost
            if isLevelUp then
                return true
            end
        end
        return false
    end

    --检查是否显示势力好感的红点
    function XTheatreManager.CheckFavorRedPoint()
        if not XTheatreManager.CheckCondition("FavorConditionId") then
            return false
        end

        local powerManager = XTheatreManager.GetPowerManager()
        local powerIdList = XTheatreConfigs.GetPowerConditionIdList()
        local powerFavorId
        local upgradeCost = XDataCenter.ItemManager.GetCount(XTheatreConfigs.TheatreFavorCoin)
        local upgradeCostConfig
        local powerCurLv

        for _, powerId in ipairs(powerIdList) do
            if (powerManager:IsUnlockPower(powerId)) and not powerManager:IsPowerMaxLv(powerId) then
                powerCurLv = powerManager:GetPowerCurLv(powerId)
                powerFavorId = XTheatreConfigs.GetTheatrePowerIdAndLvToId(powerId, powerCurLv)
                upgradeCostConfig = XTheatreConfigs.GetPowerFavorUpgradeCost(powerFavorId)
                if not powerManager:IsUnlockPowerFavor(powerFavorId) and upgradeCost >= upgradeCostConfig then
                    return true
                end
            end
        end
        return false
    end

    function XTheatreManager.SaveGuideGainFieldRedPoint()
        local configs = XTheatreConfigs.GetTheatreSkill()
        for id in pairs(configs) do
            if XTheatreManager:GetTokenManager():IsActiveSkill(id) then
                XTheatreManager.CheckIsCookie(_TheatreGuideGainFieldCookieKey .. id)
            end
        end
    end

    --检查是否显示其他道具图鉴的红点
    local _TheatreGuidePropCookieKey = "TheatreGuideProp_"
    function XTheatreManager.CheckGuidePropRedPoint()
        local configs = XTheatreConfigs.GetTheatreItem()
        for id in pairs(configs) do
            if XTheatreManager:GetTokenManager():IsActiveToken(id) and XTheatreManager.CheckIsCookie(_TheatreGuidePropCookieKey .. id, true) then
                return true
            end
        end
        return false
    end

    function XTheatreManager.SaveGuidePropRedPoint()
        local configs = XTheatreConfigs.GetTheatreItem()
        for id in pairs(configs) do
            if XTheatreManager:GetTokenManager():IsActiveToken(id) then
                XTheatreManager.CheckIsCookie(_TheatreGuidePropCookieKey .. id)
            end
        end
    end
    
    local TheatreSPModeRedPointCookieKey = "TheatreSPModeRedPoint"
    function XTheatreManager.CheckSPModeRedPoint()
        if not XTheatreManager.CheckSPModeIsOpen() then
            return false
        end
        return XTheatreManager.CheckIsCookie(TheatreSPModeRedPointCookieKey)
    end
    ------------------红点相关 end-------------------------

    ------------------副本入口扩展 start-------------------------

    function XTheatreManager:ExOpenMainUi()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre) then
            return
        end

        --分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end

        XTheatreManager.CheckAutoPlayStory()
    end

    -- 检查是否展示红点
    function XTheatreManager:ExCheckIsShowRedPoint()
        return XRedPointConditionTheatreAllRedPoint.Check()
    end

    ---商店买空即为Clear
    function XTheatreManager:ExCheckIsFinished(cb)
        local result = false
        self.IsClear = result
        
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) 
                or not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre, nil, true) then
            if cb then cb(result) end
            return
        end
        local shopIdList = XTheatreConfigs.GetShopIds()
        if XTool.IsTableEmpty(shopIdList) then
            if cb then cb(result) end
            return
        end
        
        local SetShopIsFinish = function()
            local tempTotalBuyTimes
            local tempBuyTimesLimit
            for _, shopId in ipairs(shopIdList) do
                local shopGoods = XShopManager.GetShopGoodsList(shopId, true)
                for _, shopGood in pairs(shopGoods) do
                    tempTotalBuyTimes = shopGood.TotalBuyTimes
                    tempBuyTimesLimit = shopGood.BuyTimesLimit

                    if tempTotalBuyTimes and tempBuyTimesLimit
                            and tempBuyTimesLimit ~= 0
                            and tempTotalBuyTimes ~= tempBuyTimesLimit then
                        if cb then cb(result) end
                        return
                    end
                end
            end

            result = true
            self.IsClear = result
            if cb then cb(result) end
        end

        if XTool.IsTableEmpty(XShopManager.GetShopGoodsList(shopIdList[1], true)) then
            XShopManager.GetShopInfoList(shopIdList, SetShopIsFinish, XShopManager.ActivityShopType.TheatreShop, true)
        else
            SetShopIsFinish()
        end
    end
    ------------------副本入口扩展 end-------------------------
    
    --region 冒险模式
    function XTheatreManager.CheckSPModeIsOpen(isTip)
        local conditionId = XTheatreConfigs.GetSPModeConditionId()
        if not XTool.IsNumberValid(conditionId) then
            return false
        end
        local ret, desc = XConditionManager.CheckCondition(conditionId)
        if isTip and not ret then
            XUiManager.TipError(desc)
        end
        return ret
    end
    
    ---@return boolean
    function XTheatreManager.GetSPMode()
        if not XTheatreManager.CheckSPModeIsOpen() then
            return false
        end
        local key = GetLocalSavedKey("TheatreSPMode_")
        return XSaveTool.GetData(key, false)
    end

    function XTheatreManager.SetSPMode(isOn, isTip)
        local key = GetLocalSavedKey("TheatreSPMode_")
        if isTip then
            if isOn then
                XUiManager.TipError(XTheatreConfigs.GetSPModeOpenTile())
            else
                XUiManager.TipError(XTheatreConfigs.GetSPModeCloseTile())
            end
        end
        return XSaveTool.SaveData(key, isOn)
    end
    
    function XTheatreManager.SetSPModeRedPoint()
        local key = GetLocalSavedKey(TheatreSPModeRedPointCookieKey)
        XSaveTool.SaveData(key, true)
    end
    --endregion

    return XTheatreManager
end

XRpc.NotifyTheatreData = function(data)
    XDataCenter.TheatreManager.InitWithServerData(data)
end

-- 信物升级
XRpc.NotifyTheatreKeepsakeUpgrade = function(data)
    XDataCenter.TheatreManager:GetTokenManager():UpdateKeepsakeLv(data)
end

-- 节点奖励
XRpc.NotifyTheatreNodeReward = function(data)
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    local chapter = adventureManager:GetCurrentChapter()
    -- 技能选择奖励
    if data.RewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        chapter:UpdateWaitSelectableSkillIds(data.Skills)
    -- 升级
    elseif data.RewardType == XTheatreConfigs.AdventureRewardType.LevelUp then
        data.LastLevel = adventureManager:GetCurrentLevel()
        data.LastAveragePower = adventureManager:GeRoleAveragePower()
        adventureManager:UpdateCurrentLevel(data.Lv)
        XDataCenter.TheatreManager.CheckUnlockOwnRole()
    -- 装修点
    elseif data.RewardType == XTheatreConfigs.AdventureRewardType.Decoration then
    -- 好感度
    elseif data.RewardType == XTheatreConfigs.AdventureRewardType.PowerFavor then
    end
    data.OperationQueueType = XTheatreConfigs.OperationQueueType.NodeReward
    adventureManager:AddNextOperationData(data)
end

-- 新的节点
XRpc.NotifyTheatreAddNode = function(data)
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    local currentChapter = adventureManager:GetCurrentChapter(false)
    if currentChapter == nil then
        currentChapter = adventureManager:CreatreChapterById(data.ChapterId)
    end
    if #currentChapter:GetCurrentNodes() > 0 
        and not currentChapter:CheckHasMovieNode() then
        currentChapter:AddPassNodeCount(1)
    end
    currentChapter:UpdateCurrentNode(data)
end

-- 冒险结算，重开次数用完，或者没有下一章
XRpc.NotifyTheatreAdventureSettle = function(data)
    local theatreManager = XDataCenter.TheatreManager
    theatreManager.SetCurLoadSceneChapterId(nil)
    theatreManager.RemoveOwnRoleCookie()
    local adventureManager = theatreManager.GetCurrentAdventureManager()
    adventureManager:ClearTeam()
    data.LastChapteEndStoryId = adventureManager:GetCurrentChapter(false):GetEndStoryId()
    data.OperationQueueType = XTheatreConfigs.OperationQueueType.AdventureSettle
    adventureManager:AddNextOperationData(data)
    theatreManager.UpdatePassChapterIds(data.SettleData.PassChapterId)
    theatreManager.UpdatePassEventRecord(data.SettleData.PassEventRecord)
    theatreManager.UpdateEndingIdRecords(data.SettleData.EndingRecord)
end 

-- 章节结算，打完一章，并且还有下一章
XRpc.NotifyTheatreChapterSettle = function(data)
    local theatreManager = XDataCenter.TheatreManager
    local adventureManager = theatreManager.GetCurrentAdventureManager()
    -- 更新到下一个章节
    data.LastChapteEndStoryId = adventureManager:GetCurrentChapter(false):GetEndStoryId()
    adventureManager:UpdateNextChapter()
    data.OperationQueueType = XTheatreConfigs.OperationQueueType.ChapterSettle
    adventureManager:AddNextOperationData(data)
    theatreManager.UpdatePassChapterIds(data.SettleData.PassChapterId)
    theatreManager.UpdatePassEventRecord(data.SettleData.PassEventRecord)
    theatreManager.UpdateEndingIdRecords(data.SettleData.EndingRecord)
end

XRpc.TheatreNodeNextStep = function(data)
    local chapter = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
    if data.NextStepId <= 0 then -- 事件战斗结束后没有下一步了
        return
    end
    local eventNode = chapter:GetEventNode(data.EventId)
    eventNode:UpdateNextStepEventNode(data.NextStepId)
end

XRpc.NotifyTheatreReopenCount = function(data)
    XDataCenter.TheatreManager.GetCurrentAdventureManager():UpdateReopenCount(data.ReopenCount)
end

XRpc.NotifyTheatreUseOwnCharacter = function(data)
    XDataCenter.TheatreManager.GetCurrentAdventureManager():UpdateUseOwnCharacter(data.UseOwnCharacter)
end

XRpc.NotifyTheatreCoinChange = function(data)
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    adventureManager:UpdateCurrentFavorCoin(data.FavorCoin)
    adventureManager:UpdateCurrentDecorationCoin(data.DecorationCoin)
end

--通知解锁信物
XRpc.NotifyUnlockKeepsake = function(data)
    XDataCenter.TheatreManager.GetTokenManager():UpdateKeepsake(data.Keepsake)
end