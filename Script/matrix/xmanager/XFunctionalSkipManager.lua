XFunctionalSkipManagerCreator = function()
    local XFunctionalSkipManager = {}
    local DormDrawGroudId = CS.XGame.ClientConfig:GetInt("DormDrawGroudId")

    -- 跳转打开界面选择标签页类型6
    function XFunctionalSkipManager.SkipSystemWidthArgs(skipDatas)
        if not skipDatas then return end
        local param1 = (skipDatas.CustomParams[1] ~= 0) and skipDatas.CustomParams[1] or nil
        local param2 = (skipDatas.CustomParams[2] ~= 0) and skipDatas.CustomParams[2] or nil
        local param3 = (skipDatas.CustomParams[3] ~= 0) and skipDatas.CustomParams[3] or nil

        if skipDatas.UiName == "UiTask" and XLuaUiManager.IsUiShow("UiTask") then
            XEventManager.DispatchEvent(XEventId.EVENT_TASK_TAB_CHANGE, param1)
        elseif skipDatas.UiName == "UiPuzzleActivity" then
            XDataCenter.FubenActivityPuzzleManager.OpenPuzzleGame(param1)
        elseif skipDatas.UiName == "UiChristmasTreeMain" then
            XFunctionalSkipManager.SkipToChristmasTree(skipDatas.UiName, param1)
        else
            XLuaUiManager.Open(skipDatas.UiName, param1, param2, param3)
        end
    end

    -- 跳转副本类型7
    function XFunctionalSkipManager.SkipCustom(skipDatas)
        if not skipDatas then return end

        if XFunctionalSkipManager[skipDatas.UiName] then
            XFunctionalSkipManager[skipDatas.UiName](skipDatas)
        else
            XLog.Error("跳转不存在", skipDatas.UiName);
        end
    end

    -- 跳转宿舍类型8
    function XFunctionalSkipManager.SkipDormitory(skipDatas)
        if not skipDatas or not XPlayer.Id then return end

        if XFunctionalSkipManager[skipDatas.UiName] then
            XFunctionalSkipManager[skipDatas.UiName](skipDatas)
        end
    end

    -- 前往宿舍房间
    function XFunctionalSkipManager.SkipDormRoom(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        -- 该房间未激活
        if (param1 == nil) or (not XDataCenter.DormManager.IsDormitoryActive(param1)) then
            if not XHomeDormManager.InDormScene() then
                XHomeDormManager.EnterDorm(XPlayer.Id, nil, false)
            end
            return
        end

        -- 房间已激活
        if XHomeDormManager.InDormScene() then
            if XLuaUiManager.IsUiShow("UiDormTask") then
                XLuaUiManager.Close("UiDormTask")
            end

            if not XHomeDormManager.IsInRoom(param1) then

                if not XLuaUiManager.IsUiShow("UiDormSecond") then
                    XLuaUiManager.Open("UiDormSecond", XDormConfig.VisitDisplaySetType.MySelf, param1)
                else
                    XEventManager.DispatchEvent(XEventId.EVENT_DORM_SKIP, param1)
                end

                XHomeDormManager.SetSelectedRoom(param1, true)
            end
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()

                if not XLuaUiManager.IsUiShow("UiDormSecond") then
                    XLuaUiManager.Open("UiDormSecond", XDormConfig.VisitDisplaySetType.MySelf, param1)
                else
                    XEventManager.DispatchEvent(XEventId.EVENT_DORM_SKIP, param1)
                end

                XHomeDormManager.SetSelectedRoom(param1, true)

            end)
        end
    end

    -- 前往宿舍主界面
    function XFunctionalSkipManager.SkipDormMain()

        if XLuaUiManager.IsUiLoad("UiDormTask") then
            XLuaUiManager.Remove("UiDormTask")
        end

        if not XHomeDormManager.InDormScene() then
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false)
        elseif XHomeDormManager.InAnyRoom() then
            local roomId = XHomeDormManager.GetCurrentRoomId()
            if roomId then
                XHomeDormManager.SetSelectedRoom(roomId, false)

                if XLuaUiManager.IsUiLoad("UiDormSecond") then
                    XLuaUiManager.Remove("UiDormSecond")
                end

            end
        end
        XLuaUiManager:ShowTopUi()
    end

    -- 前往宿舍访问
    function XFunctionalSkipManager.SkipDormVisit(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        if XHomeDormManager.InDormScene() then
            XLuaUiManager.Open("UiDormVisit", nil, param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiDormVisit", nil, param1)
            end)
        end
    end

    -- 前往宿舍任务
    function XFunctionalSkipManager.SkipDormTask(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        if XHomeDormManager.InDormScene() then
            XLuaUiManager.Open("UiDormTask", param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiDormTask", param1)
            end)
        end
    end

    -- 前往宿舍仓库界面
    function XFunctionalSkipManager.SkipDormWarehouse(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        if XHomeDormManager.InDormScene() then
            XLuaUiManager.Open("UiDormBag", param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiDormBag", param1)
            end)
        end
    end

    -- 前往宿舍成员界面
    function XFunctionalSkipManager.SkipDormMember()
        if XHomeDormManager.InDormScene() then
            XLuaUiManager.Open("UiDormPerson")
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiDormPerson")
            end)
        end
    end

    -- 前往宿舍打工界面
    function XFunctionalSkipManager.SkipDormWork()
        if XHomeDormManager.InDormScene() then
            if not XLuaUiManager.IsUiShow("UiDormWork") then
                XLuaUiManager.Open("UiDormWork")
            else
                XEventManager.DispatchEvent(XEventId.EVENT_DORM_SKIP)
            end
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiDormWork")
            end)
        end
    end

    -- 前往宿舍商店界面
    function XFunctionalSkipManager.SkipDormShop(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        if XHomeDormManager.InDormScene() then
            if XLuaUiManager.IsUiShow("UiShop") then return end
            XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm, nil, param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                if XLuaUiManager.IsUiShow("UiShop") then return end
                XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm, nil, param1)
            end)
        end
    end

    -- 前往宿舍研发界面
    function XFunctionalSkipManager.SkipDormDraw()
        if XHomeDormManager.InDormScene() then
            XDataCenter.DrawManager.GetDrawGroupList(
            function()
                local info = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(DormDrawGroudId)
                if not info then return end
                XDataCenter.DrawManager.GetDrawInfoList(DormDrawGroudId, function()
                    XLuaUiManager.Open("UiDraw", DormDrawGroudId, function()
                        XHomeSceneManager.ResetToCurrentGlobalIllumination()
                    end, info.UiBackGround)
                end)
            end
            )
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XDataCenter.DrawManager.GetDrawGroupList(
                function()
                    local info = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(DormDrawGroudId)
                    if not info then return end
                    XDataCenter.DrawManager.GetDrawInfoList(DormDrawGroudId, function()
                        XLuaUiManager.Open("UiDraw", DormDrawGroudId, function()
                            XHomeSceneManager.ResetToCurrentGlobalIllumination()
                        end, info.UiBackGround)
                    end)
                end
                )
            end)
        end
    end

    -- 前往宿舍建造界面
    function XFunctionalSkipManager.SkipDormFurnitureBuild(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        if XHomeDormManager.InDormScene() then
            XLuaUiManager.Open("UiFurnitureBuild", param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiFurnitureBuild", param1)
            end)
        end
    end

    -- 前往巴别塔
    function XFunctionalSkipManager.OnOpenBabelTower()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BabelTower) then
            return
        end

        local currentActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
        if not currentActivityNo or not XDataCenter.FubenBabelTowerManager.IsInActivityTime(currentActivityNo) then
            XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
            return
        end

        XDataCenter.FubenBabelTowerManager.OpenBabelTowerCheckStory()
    end

    -- 前往新角色教学活动
    function XFunctionalSkipManager.OnOpenNewCharActivity(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewCharAct) then
            return
        end

        local actId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        local isOpenSkin = list.CustomParams[2] and (list.CustomParams[2] ~= 1)
        -- 活动时间限制
        if not XDataCenter.FubenNewCharActivityManager.IsOpen(actId) then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return
        end

        local newCharType = XFubenNewCharConfig.GetNewCharType(actId)
        local uiName
        if newCharType == XFubenNewCharConfig.NewCharType.YinMianZheGuang then
            uiName = "UiNewCharActivity"
        elseif newCharType == XFubenNewCharConfig.NewCharType.KoroChar then
            uiName = "UiFunbenKoroTutorial"
        elseif newCharType == XFubenNewCharConfig.NewCharType.WeiLa 
                or newCharType == XFubenNewCharConfig.NewCharType.LuoLan
                or newCharType == XFubenNewCharConfig.NewCharType.Pulao
                or newCharType == XFubenNewCharConfig.NewCharType.Selena
                or newCharType == XFubenNewCharConfig.NewCharType.Qishi 
                or newCharType == XFubenNewCharConfig.NewCharType.Hakama
                or newCharType == XFubenNewCharConfig.NewCharType.SuperKarenina then
            uiName = "UiFunbenWeiLaTutorial"
        elseif newCharType == XFubenNewCharConfig.NewCharType.Liv then
            uiName = "UiLifuActivityMain"
        end

        XLuaUiManager.Open(uiName, actId, isOpenSkin)
    end

    -- 前往赏金任务
    function XFunctionalSkipManager.OnOpenUiMoneyReward()
        if XDataCenter.MaintainerActionManager.IsStart() then
            XUiManager.TipText("MaintainerActionEventOver")
            XDataCenter.FunctionalSkipManager.OnOpenMaintainerAction()
        else
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BountyTask) then
                return
            end
            XDataCenter.BountyTaskManager.SetBountyTaskLastRefreshTime()
            XLuaUiManager.Open("UiMoneyReward")
        end

    end

    -- 前往协同作战
    function XFunctionalSkipManager.OnOpenUiOnlineBoss(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        --开启时间限制
        if not XDataCenter.FubenBossOnlineManager.CheckNormalBossOnlineInTime() then
            local tipText = XDataCenter.FubenBossOnlineManager.GetNotInTimeTip()
            XUiManager.TipError(tipText)
            return
        end
        XDataCenter.FubenBossOnlineManager.OpenBossOnlineUi(param1)
    end

    -- 前往活动协同作战
    function XFunctionalSkipManager.OnOpenUiOnlineBossActivity(list)
        local functionId = XFunctionManager.FunctionName.FubenActivityOnlineBoss
        local isOpen = XFunctionManager.JudgeCanOpen(functionId) and XDataCenter.FubenBossOnlineManager.GetIsActivity()

        if not isOpen then
            XUiManager.TipText("ActivityBossOnlineOver")
            return
        end

        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        XDataCenter.FubenBossOnlineManager.OpenBossOnlineUi(param1)
    end


    -- 前往特训关
    function XFunctionalSkipManager.OnOpenUiSpecialTrainActivity(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpecialTrain) then
            return
        end

        if XLuaUiManager.IsUiShow("UiSummerTaskReward") then
            return
        end

        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or 1
        local param3 = (list.CustomParams[3] ~= 0) and list.CustomParams[3] or 0

        if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(param1, true) then
            return
        end

        local config = XFubenSpecialTrainConfig.GetActivityConfigById(param1)
        if config.Type == XFubenSpecialTrainConfig.Type.Music then
            XLuaUiManager.Open("UiSpecialTrainMusic")
        elseif config.Type == XFubenSpecialTrainConfig.Type.Photo then
            XLuaUiManager.Open("UiSummerEpisodeNew", param1, param2, param3)
        elseif config.Type == XFubenSpecialTrainConfig.Type.Snow then
            XLuaUiManager.Open("UiFubenSnowGame")
        elseif config.Type == XFubenSpecialTrainConfig.Type.Rhythm then
            XLuaUiManager.Open("UiFubenYuanXiao")
        elseif config.Type == XFubenSpecialTrainConfig.Type.Breakthrough then
            XLuaUiManager.Open("UiSpecialTrainBreakthroughMain")
        else
            XLuaUiManager.Open("UiSummerEpisode", param1, param2, param3)
        end
    end

    -- 被感染的守林人
    function XFunctionalSkipManager.OnOpenUiActivityBranch(list)

        -- 开启时间限制
        if not XDataCenter.FubenActivityBranchManager.IsOpen() then
            XUiManager.TipText("ActivityBranchNotOpen")
            return
        end

        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil

        if param1 == XDataCenter.FubenActivityBranchManager.BranchType.Difficult then
            if not XDataCenter.FubenActivityBranchManager.IsStatusEqualChallengeBegin() then
                XUiManager.TipText("ActivityBranchNotOpen")
                return
            end
        end

        if XFunctionalSkipManager.IsStageLock(param2) then return end

        local sectionId = XDataCenter.FubenActivityBranchManager.GetCurSectionId()
        XLuaUiManager.Open("UiActivityBranch", sectionId, param1, param2)
    end

    -- 前往格式塔
    function XFunctionalSkipManager.OnOpenUiActivityBossSingle(list)

        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local sectionId = XDataCenter.FubenActivityBossSingleManager.GetCurSectionId() or 1
        -- 活动时间限制
        if not XDataCenter.FubenActivityBossSingleManager.IsOpen() then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return
        end

        if (not param1) or (not XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlock(param1)) then
            XLuaUiManager.Open("UiActivityBossSingle", sectionId)
        else
            XLuaUiManager.Open("UiActivityBossSingleDetail", param1)
        end
    end

    -- 前往纷争战区
    function XFunctionalSkipManager.OnOpenUiArena()
        local arenaChapters = XFubenConfigs.GetChapterBannerByType(XDataCenter.FubenManager.ChapterType.ARENA)
        XDataCenter.ArenaManager.RequestSignUpArena(function()
            XLuaUiManager.Open("UiArena", arenaChapters)
        end)
    end

    -- 前往幻痛囚笼
    function XFunctionalSkipManager.OnOpenUiFubenBossSingle()
        if XDataCenter.FubenBossSingleManager.CheckNeedChooseLevelType() then
            XLuaUiManager.Open("UiFubenBossSingleChooseLevelType")
            return
        end

        XDataCenter.FubenBossSingleManager.OpenBossSingleView()
    end

    -- 前往资源副本
    function XFunctionalSkipManager.OnOpenUiFubenDaily(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]
        if param1 == nil or param1 == 0 then
            XLuaUiManager.Open("UiFuben", XDataCenter.FubenManager.StageType.Resource)
            return
        end

        XLuaUiManager.OpenWithCallback("UiFubenDaily", function()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_RESOURCE_AUTOSELECT, param2)
        end, XDailyDungeonConfigs.GetDailyDungeonRulesById(param1))
    end

    -- 前往前传
    function XFunctionalSkipManager.OnOpenUiPrequel(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]
        local covers = XDataCenter.PrequelManager.GetListCovers()
        if covers then
            local index = 0
            for k, v in pairs(covers) do
                if v.CoverId == param1 then
                    index = k
                    break
                end
            end
            if covers[index] then
                if covers[index].IsAllChapterLock and (not covers[index].IsActivity) then
                    XUiManager.TipMsg(XDataCenter.PrequelManager.GetChapterUnlockDescription(covers[index].ShowChapter))
                    return
                end
                XLuaUiManager.Open("UiPrequel", covers[index], nil, param2)
            end
        end
        -- XLuaUiManager.OpenWithCallback("UiFuben", function()
        --     CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_PREQUEL_AUTOSELECT, param1, param2)
        -- end, 1)
    end
    -- 是否能前往前传
    function XFunctionalSkipManager.IsCanOpenUiPrequel(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]
        local covers = XDataCenter.PrequelManager.GetListCovers()
        if covers then
            local index = 0
            for k, v in pairs(covers) do
                if v.CoverId == param1 then
                    index = k
                    break
                end
            end
            if covers[index] then
                if covers[index].IsAllChapterLock and (not covers[index].IsActivity) then
                    return false
                end
                return true
            end
        end
        return false
    end

    -- 前往剧情简章主界面-- 前往据点战主界面
    function XFunctionalSkipManager.OnOpenMainlineSubtab(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        XLuaUiManager.Open("UiFuben", 1, nil, param1)
    end

    -- 前往隐藏关卡主界面
    function XFunctionalSkipManager.OnOpenMainlineWithDifficuty()
        XLuaUiManager.OpenWithCallback("UiFuben", function()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_MAINLINE_DIFFICUTY_SELECT)
        end, 1)
    end

    -- 前往展示厅,有参数时打开某个角色
    function XFunctionalSkipManager.OnOpenExhibition(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XLuaUiManager.OpenWithCallback("UiExhibition", function()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHARACTER_EXHIBITION_AUTOSELECT, param1)
        end, true, list.CustomParams[2])
    end

    -- 前往具体的抽卡
    function XFunctionalSkipManager.OnOpenDrawDetail(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XDataCenter.DrawManager.GetDrawGroupList(function()
            local drawGroupInfos = XDataCenter.DrawManager.GetDrawGroupInfos()
            for _, info in pairs(drawGroupInfos or {}) do
                if param1 and info.Id == param1 then
                    XDataCenter.DrawManager.GetDrawInfoList(info.Id, function()
                        XLuaUiManager.Open(info.UiPrefab, info.Id, nil, info.UiBackGround)
                    end)
                    break
                end
            end
        end)
    end

    -- 跳转节日活动
    function XFunctionalSkipManager.OnOpenFestivalActivity(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        if not XDataCenter.FubenFestivalActivityManager.IsFestivalInActivity(param1) then
            XUiManager.TipText("FestivalActivityNotInActivityTime")
            return
        end

        if param2 then
            if XFunctionalSkipManager.IsStageLock(param2) then return end
            XLuaUiManager.Open("UiFubenChristmasMainLineChapter", param1, param2)
        else
            XLuaUiManager.Open("UiFubenChristmasMainLineChapter", param1)
        end
    end

    -- 复刷本
    function XFunctionalSkipManager.OnOpenRepeatChallengeActivity(list)
        local param = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
            XUiManager.TipMsg(CS.XTextManager.GetText("FubenRepeatNotInActivityTime"))
            return
        end

        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.RepeatChallenge) then
            return
        end

        XLuaUiManager.Open("UiFubenRepeatchallenge", param)
    end

    -- 爬塔活动
    function XFunctionalSkipManager.OnOpenRogueLikeActivity()
        local activityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
        if activityId == nil or activityId <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
            return
        end
        local activityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(activityId)

        if not activityConfig then
            return
        end
        if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
            XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
            return
        end

        if activityConfig.FunctionalOpenId > 0 and (not XFunctionManager.DetectionFunction(activityConfig.FunctionalOpenId)) then
            return
        end

        XDataCenter.FubenRogueLikeManager.OpenRogueLikeCheckStory()
    end

    -- 打开主线、隐藏线、据点战
    function XFunctionalSkipManager.OnOpenMainLineStage(list)
        local stageId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        local openStageDetail = param2 == 1
        if not stageId then return end
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Difficult == XDataCenter.FubenManager.DifficultHard and (not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)) then
            local openTips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
            XUiManager.TipMsg(openTips)
            return
        end

        if stageInfo.Type == XDataCenter.FubenManager.StageType.Bfrt then
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenNightmare) then
                return
            end
        end

        if XFunctionalSkipManager.IsStageLock(stageId) then return end

        local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
        if not XDataCenter.FubenMainLineManager.CheckChapterCanGoTo(chapter.ChapterId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("FubenMainLineNoneOpen"))
            return
        end
        if openStageDetail then
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
        else
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter)
        end
    end
    function XFunctionalSkipManager.OpenMainLine3DStage(list)
        local chapterId = list.CustomParams[1]
        local stageId = list.CustomParams[2]
        local mainCfg = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(XDataCenter.FubenMainLineManager.MainLine3DId)
        local chapterIndex, stageIndex
        for i, cId in pairs(mainCfg.ChapterId) do
            if chapterId == cId then
                chapterIndex = i
                if not XDataCenter.FubenMainLineManager.CheckChapterCanGoTo(cId) then
                    XUiManager.TipMsg(CS.XTextManager.GetText("FubenMainLineNoneOpen"))
                    return
                end
            end
            local chapterCfg = XDataCenter.FubenMainLineManager.GetChapterCfg(cId)
            for j, sId in pairs(chapterCfg.StageId) do
                if sId == stageId then stageIndex = j end
            end
        end
        XLuaUiManager.Open("UiFubenMainLine3D", chapterIndex, stageIndex, stageId)
    end

    -- 狙击战跳转
    function XFunctionalSkipManager.OnOpenUnionKill()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenUnionKill) then
            return
        end
        local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        if not unionInfo or not unionInfo.Id or unionInfo.Id <= 0 then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
            return
        end

        if not XFubenUnionKillConfigs.UnionKillInActivity(unionInfo.Id) then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
            return
        end

        XLuaUiManager.Open("UiUnionKillMain")
    end

    -- 公会
    function XFunctionalSkipManager.OnOpenGuild()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
            return
        end

        XDataCenter.GuildManager.EnterGuild()
    end

    --拟真围剿
    function XFunctionalSkipManager.OpenGuildBoss()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
            return
        end
        if not XDataCenter.GuildManager.IsJoinGuild() then
            return
        end
        XDataCenter.GuildBossManager.OpenGuildBossHall()
    end
    -- 跳转巴别塔勋章
    function XFunctionalSkipManager.OnOpenMedal(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local selectIndex = 4
        XLuaUiManager.Open("UiPlayer", nil, selectIndex, nil, param1)
    end

    -- 跳转图鉴
    function XFunctionalSkipManager.OnOpenArchive(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        if param1 == XArchiveConfigs.SubSystemType.Monster then
            XLuaUiManager.Open("UiArchiveMonster")
        elseif param1 == XArchiveConfigs.SubSystemType.Weapon then
            XLuaUiManager.Open("UiArchiveWeapon")
        elseif param1 == XArchiveConfigs.SubSystemType.Awareness then
            XLuaUiManager.Open("UiArchiveAwareness")
        elseif param1 == XArchiveConfigs.SubSystemType.Story then
            XLuaUiManager.Open("UiArchiveStory")
        elseif param1 == XArchiveConfigs.SubSystemType.CG then
            XLuaUiManager.Open("UiArchiveCG")
        elseif param1 == XArchiveConfigs.SubSystemType.NPC then
            XLuaUiManager.Open("UiArchiveNpc")
        elseif param1 == XArchiveConfigs.SubSystemType.Email then
            XLuaUiManager.Open("UiArchiveEmail")
        elseif param1 == XArchiveConfigs.SubSystemType.Partner then
            XLuaUiManager.Open("UiArchivePartner")
        elseif param1 == XArchiveConfigs.SubSystemType.PV then
            XLuaUiManager.Open("UiArchivePV")
        end
    end

    -- 跳转gacha
    function XFunctionalSkipManager.OnOpenGacha(list)
        local gachaId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local IsOpen = gachaId and XDataCenter.GachaManager.CheckGachaIsOpenById(gachaId, true) or false
        if not IsOpen then
            return
        end
        XDataCenter.GachaManager.GetGachaRewardInfoRequest(gachaId, function()
            local gachaRule = XGachaConfigs.GetGachaRuleCfgById(gachaId)
            XLuaUiManager.Open(gachaRule.UiName, gachaId)
        end)
    end

    -- 跳转gacha组
    function XFunctionalSkipManager.OnOpenGachaOrganize(list)
        local organizeId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local IsOpen = organizeId and XDataCenter.GachaManager.CheckGachaOrganizeIsOpen(organizeId, true) or false
        if not IsOpen then
            return
        end

        XDataCenter.GachaManager.GetGachaOrganizeInfoRequest(organizeId, function(gachaId)
            local organizeRule = XGachaConfigs.GetOrganizeRuleCfg(organizeId)
            if not organizeRule then
                return
            end
            -- 'gachaId'为卡池组里最新解锁的卡池Id，由服务器下发，打开界面时默认选中
            XLuaUiManager.Open(organizeRule.UiName, organizeId, gachaId, organizeRule)
        end)
    end

    -- 跳转活动材料商店
    function XFunctionalSkipManager.OnOpenActivityBriefShop(list)
        local selectedShopId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local isOpen, desc = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)
        if isOpen then
            XLuaUiManager.Open("UiActivityBriefShop", nil, nil, selectedShopId)
        else
            XUiManager.TipMsg(desc)
        end
    end

    -- 跳转世界Boss
    function XFunctionalSkipManager.OnOpenWorldBoss()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.WorldBoss) then
            return
        end
        if not XDataCenter.WorldBossManager.IsInActivity() then
            XUiManager.TipMsg(CS.XTextManager.GetText("WorldBossNotInActivityTime"))
            return
        end
        XDataCenter.WorldBossManager.OpenWorldMainWind()
    end

    -- 跳转大富翁
    function XFunctionalSkipManager.OnOpenMaintainerAction()
        local ret, msg = XDataCenter.MaintainerActionManager.CheckIsOpen()
        if not ret then
            XUiManager.TipMsg(msg)
            return
        end

        XDataCenter.MaintainerActionManager.OpenMaintainerActionWind()
    end

    -- 跳转师徒系统
    function XFunctionalSkipManager.OnOpenMentorSystem()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MentorSystem) then
            return
        end
        XLuaUiManager.Open("UiMentorMain")
    end

    -- 区域联机
    function XFunctionalSkipManager.OnOpenAreanOnlineChapter()
        XDataCenter.ArenaOnlineManager.SetCurChapterId()
        XLuaUiManager.Open("UiArenaOnlineChapter")
    end

    -- 检查stageId是否开启
    function XFunctionalSkipManager.IsStageLock(stageId)
        if not stageId then return false end
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo then
            return false
        end
        if not stageInfo.Unlock then
            XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(stageId))
            return true
        end
        return false
    end
    -- 跳转到番外关卡
    function XFunctionalSkipManager.ExtraChapter(jumpData)
        if not jumpData then return end
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Extra) then
            local extraManager = XDataCenter.ExtraChapterManager
            if not jumpData.CustomParams then extraManager.JumpToExtraBanner() end
            local chapterId = jumpData.CustomParams[1]
            if chapterId then extraManager.JumpToExtraStage(chapterId, jumpData.CustomParams[2])
            else extraManager.JumpToExtraBanner() end
        end
    end

    --跳转到故事集关卡
    function XFunctionalSkipManager.ShortStoryChapter(jumpData)
        if not jumpData then return end
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShortStory) then
            local extraManager = XDataCenter.ShortStoryChapterManager
            if not jumpData.CustomParams then extraManager.JumpToShortStoryBanner() end
            local chapterId = jumpData.CustomParams[1]
            if chapterId then extraManager.JumpToShortStoryStage(chapterId, jumpData.CustomParams[2])
            else extraManager.JumpToShortStoryBanner() end
        end
    end

    function XFunctionalSkipManager.FubenInfesotorExplore()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenInfesotorExplore) then
            if XDataCenter.FubenInfestorExploreManager.IsInSectionOne()
            or XDataCenter.FubenInfestorExploreManager.IsInSectionTwo() then
                local openCb = function()
                    XLuaUiManager.Open("UiInfestorExploreRank")
                end
                XDataCenter.FubenInfestorExploreManager.OpenEntranceUi(openCb)
            elseif XDataCenter.FubenInfestorExploreManager.IsInSectionEnd() then
                XUiManager.TipText("InfestorExploreEnterSectionEnd")
            end
        end
    end

    --跳转到尼尔彩蛋界面
    function XFunctionalSkipManager.OnNieREasterEgg()
        XDataCenter.NieRManager.OpenNieRDataSaveUi()
    end

    --跳转到尼尔复刷界面
    function XFunctionalSkipManager.OnUiFubenNierRepeat(jumpData)
        XLuaUiManager.Open("UiFubenNierRepeat", jumpData.ParamId)
    end

    --跳转到尼尔任务界面
    function XFunctionalSkipManager.OnUiFubenNierTask(jumpData)
        XLuaUiManager.Open("UiNierTask", jumpData.ParamId)
    end

    --跳转到尼尔主界面
    function XFunctionalSkipManager.OnUiFubenNierEnter()
        if XDataCenter.NieRManager.GetIsActivityEnd() then
            XUiManager.TipText("NieREnd")
        else
            XLuaUiManager.Open("UiFubenNierEnter")
        end
    end

    function XFunctionalSkipManager.Expedition()
        XDataCenter.ExpeditionManager.JumpToExpedition()
    end

    function XFunctionalSkipManager.RpgTower()
        XDataCenter.RpgTowerManager.JumpTo()
    end

    function XFunctionalSkipManager.SuperTowerJumpTo()
        XDataCenter.SuperTowerManager.JumpTo()
    end

    function XFunctionalSkipManager.SkipTRPGMain()
        XDataCenter.TRPGManager.SkipTRPGMain()
    end

    --跳转到口袋战双主界面
    function XFunctionalSkipManager.SkipToPokemonMainUi()
        XDataCenter.PokemonManager.OpenPokemonMainUi()
    end

    --跳转到追击玩法主界面
    function XFunctionalSkipManager.SkipToPursuit()
        if XChessPursuitConfig.GetChessPursuitInTimeMapGroup() then
            XLuaUiManager.Open("UiChessPursuitMain")
        else
            XUiManager.TipText("ChessPursuitNotInTime")
        end
    end

    function XFunctionalSkipManager.SkipToSpringFestivalActivity()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpringFestivalActivity) then
            return
        end
        XDataCenter.SpringFestivalActivityManager.OpenActivityMain()
    end

    function XFunctionalSkipManager.SkipToSpringFestivalActivityWithClose()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpringFestivalActivity) then
            return
        end
        XDataCenter.SpringFestivalActivityManager.OpenMainWithClose()
    end

    function XFunctionalSkipManager.SkipToSpringFestivalSmashEggs()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpringFestivalActivity) then
            return
        end
        if XDataCenter.SpringFestivalActivityManager.IsOpen() then
            XLuaUiManager.PopThenOpen("UiSpringFestivalSmashEggs")
        end
    end

    function XFunctionalSkipManager.SkipToSpringFestivalCollectWord()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpringFestivalActivity) then
            return
        end
        if XDataCenter.SpringFestivalActivityManager.IsOpen() then
            XLuaUiManager.PopThenOpen("UiSpringFestivalCollectCard")
        end
    end

    --跳转至2021端午活动主界面
    function XFunctionalSkipManager.SkipToRpgMakerGameMain()
        XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnter()
    end

    --================
    --跳转到组合小游戏
    --================
    function XFunctionalSkipManager.JumpToComposeGame(skipDatas)
        XDataCenter.ComposeGameManager.JumpTo(skipDatas.CustomParams[1])
    end

    --超级据点主界面
    function XFunctionalSkipManager.SkipToStrongholdMain()
        XDataCenter.StrongholdManager.EnterUiMain()
    end

    --================
    --跳转到白色情人节约会小游戏
    --================    
    function XFunctionalSkipManager.JumpToWhiteValentineGame()
        XDataCenter.WhiteValentineManager.JumpTo()
    end

    -- 跳转到涂装返场商店
    function XFunctionalSkipManager.SkipToSpecialShop(skipData)
        XShopManager.GetShopInfo(skipData.ParamId, function()
            XLuaUiManager.Open("UiSpecialFashionShop", skipData.ParamId)
        end)
    end
    --================
    --跳转到猜拳小游戏
    --================
    function XFunctionalSkipManager.JumpToFingerGuessing()
        XDataCenter.FingerGuessingManager.JumpTo()
    end
    -- 跳转模拟作战
    function XFunctionalSkipManager.SkipToSimulatedCombat(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenSimulatedCombat) then
            return
        end

        local mode, childUiType = list.CustomParams[1], list.CustomParams[2]
        local isOpen, desc = XDataCenter.FubenSimulatedCombatManager.CheckModeOpen(mode)
        if not isOpen then
            XUiManager.TipMsg(desc)
            return
        end

        XLuaUiManager.Remove("UiSimulatedCombatMain")
        XLuaUiManager.Open("UiSimulatedCombatMain", mode, childUiType)
    end

    function XFunctionalSkipManager.SkipToMoeWar()
        XDataCenter.MoeWarManager.OnOpenMain()
    end

    function XFunctionalSkipManager.SkipToFubenHack(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenHack) then
            return
        end
        local isEnd, isNotOpen = XDataCenter.FubenHackManager.GetIsActivityEnd()
        if isNotOpen then
            XUiManager.TipText("CommonActivityNotStart")
        elseif isEnd then
            XUiManager.TipText("ActivityMainLineEnd")
        else
            XLuaUiManager.Open("UiFubenHack")
        end
    end

    function XFunctionalSkipManager.SkipToMineSweeping()
        XDataCenter.MineSweepingManager.OpenMineSweeping()
    end

    function XFunctionalSkipManager.SkipToFubenCoupleCombat(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenCoupleCombat) then
            return
        end
        if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        XLuaUiManager.Open("UiCoupleCombatChapter")
    end

    function XFunctionalSkipManager.SkipToMovieAssemble(skipDatas)
        XLuaUiManager.Open("UiMovieAssemble", skipDatas.CustomParams[1])
    end

    function XFunctionalSkipManager.SkipToPartnerTeachingChapter(skipData)
        local isUnlock, lockTip = XDataCenter.PartnerTeachingManager.WhetherUnLockChapter(skipData.CustomParams[1])
        if isUnlock then
            XLuaUiManager.Open("UiPartnerTeachingChapter", skipData.CustomParams[1])
        else
            XUiManager.TipMsg(lockTip)
        end
    end

    function XFunctionalSkipManager.SkipToReformActivity()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Reform) then
            return
        end
        if not XDataCenter.ReformActivityManager.GetIsOpen() then
            XUiManager.TipError(CS.XTextManager.GetText("FunctionNotDuringOpening"))
            return
        end
        XDataCenter.ReformActivityManager.EnterRequest(function()
            XLuaUiManager.Open("UiReform")
        end)
    end

    function XFunctionalSkipManager.SkipToSuperTowerTier()
        XDataCenter.SuperTowerManager.SkipToSuperTowerTier()
    end

    function XFunctionalSkipManager.SkipToPokerGuessing()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PokerGuessing) and (not XDataCenter.PokerGuessingManager.IsOpen()) then
            return
        end
        XDataCenter.PokerGuessingManager.OnOpenMain()
    end

    function XFunctionalSkipManager.SkipToFashionStory(skipData)
        XDataCenter.FashionStoryManager.OpenFashionStoryMain(skipData.CustomParams[1])
    end

    function XFunctionalSkipManager.SkipToKillZone()
        XDataCenter.KillZoneManager.EnterUiMain()
    end

    function XFunctionalSkipManager.SkipToSameColorGame()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SameColor) then
            return
        end
        XDataCenter.SameColorActivityManager.OpenMainUi()
    end

    -- 跳转圣诞活动
    function XFunctionalSkipManager.SkipToChristmasTree(uiName, actId)
        local actTemplate = XDataCenter.ChristmasTreeManager.Reset(actId);
        local _, endTimeSecond = XFunctionManager.GetTimeByTimeId(actTemplate.TimeId)
        if not endTimeSecond then
            XUiManager.TipError(CSXTextManagerGetText("ActivityMainLineEnd"))
        end
        local time = XTime.GetServerNowTimestamp()
        if time > endTimeSecond then
            XUiManager.TipError(CSXTextManagerGetText("ActivityMainLineEnd"))
            return
        end       
        XLuaUiManager.Open(uiName, actId)
    end

    function XFunctionalSkipManager.SkipToTheatre()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre) then
            return
        end
        XDataCenter.TheatreManager.CheckAutoPlayStory()
    end

    -- 跳转战斗通行证
    function XFunctionalSkipManager.OnOpenPassport()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Passport) then
            return
        end
        XDataCenter.PassportManager.OpenMainUi()
    end

    function XFunctionalSkipManager.SkipToPickFlipRewardActivity(skipData)
        XDataCenter.PickFlipManager.OpenMainUi(skipData.CustomParams[1])
    end
    --================
    --跳转到超限乱斗
    --================
    function XFunctionalSkipManager.SkipToSuperSmashBros()
        XDataCenter.SuperSmashBrosManager.JumpTo()
    end
    --================
    --跳转到打地鼠
    --================
    function XFunctionalSkipManager.SkipToHitMouse()
        XDataCenter.HitMouseManager.JumpTo()
    end
    ---跳转到投骰子小游戏（元旦预热）
    function XFunctionalSkipManager.SkipToDiceGame()
        XDataCenter.DiceGameManager.OpenDiceGame()
    end

    --跳转到全服决战
    function XFunctionalSkipManager.SkipToAreaWar()
        XDataCenter.AreaWarManager.EnterUiMain()
    end

    --跳转到周年意识营救战
    function XFunctionalSkipManager.SkipToMemorySave()
        XDataCenter.MemorySaveManager.EnterUiMain()
    end

    --跳转到末日生存（模拟经营）
    function XFunctionalSkipManager.SkipToDoomsday()
        XDataCenter.DoomsdayManager.EnterUiMain()
    end
    
    --跳转到元旦奖券小游戏
    function XFunctionalSkipManager.SkipToNewYearLuck()
        XDataCenter.NewYearLuckManager.OpenMainUi()
    end

    function XFunctionalSkipManager.SkipToFubenMaverick()
        local notInActivity, notStart = XDataCenter.MaverickManager.IsActivityEnd()
        if notStart then
            XUiManager.TipText("MaverickNotStart")
            return
        end

        if notInActivity then
            XUiManager.TipText("MaverickEnd")
            return
        end

        XLuaUiManager.Open("UiFubenMaverickMain")
    end

    --跳转到大逃杀玩法主界面
    function XFunctionalSkipManager.SkipToEscapeMain()
        XDataCenter.EscapeManager.OnOpenMain()
    end
    
    --跳转到枢纽作战
    function XFunctionalSkipManager.SkipToPivotCombat()
        XDataCenter.PivotCombatManager.JumpTo()
    end
    
    --跳转到哈卡玛小游戏
    function XFunctionalSkipManager.SkipToBodyCombineGame()
        XDataCenter.BodyCombineGameManager.JumpTo()
    end

    function XFunctionalSkipManager.OpenLotto(list)
        local groupId =  tonumber(list.CustomParams[1])
        XDataCenter.LottoManager.OpenLottoUi(groupId)
    end    --跳转到黄金矿工
    function XFunctionalSkipManager.SkipToGoldenMiner()
        XDataCenter.GoldenMinerManager.OnOpenMain()
    end

    --跳转到动作塔防
    function XFunctionalSkipManager.SkipToDoubleTowers()
        XDataCenter.DoubleTowersManager.OnOpenMain()
    end

    --登录弹窗提示，跳转到周任务挑战
    function XFunctionalSkipManager.SkipToWeekChallenge()
        XDataCenter.WeekChallengeManager.OnAutoWindowOpen()
    end
    
    --跳转到累消活动
    function XFunctionalSkipManager.SkipToConsumeActivityMain()
        XDataCenter.AccumulatedConsumeManager.OnOpenActivityMain()
    end
    
    --跳转到福袋抽卡
    function XFunctionalSkipManager.SkipToConsumeActivityLuckyBag()
        XDataCenter.AccumulatedConsumeManager.OnOpenLuckyBag()
    end
    
    --跳转到福行商店
    function XFunctionalSkipManager.SkipToConsumeActivityShop()
        XDataCenter.AccumulatedConsumeManager.OpenActivityShop()
    end
   
    --跳转到音游
    function XFunctionalSkipManager.OnOpenTaikoMaster()
        XDataCenter.TaikoMasterManager.OpenUi()
    end
    
    --跳转到多维跳转
    function XFunctionalSkipManager.SkipToMultiDimMain()
        XDataCenter.MultiDimManager.OnOpenMain()
    end
    
    --跳转到520送礼, 28分支单独处理，增加TimeId判断
    function XFunctionalSkipManager.SkipToFavorabilityNew(skipData)
        local uiName = skipData.UiName
        if not uiName then return end
        if XLuaUiManager.IsUiShow(uiName) then
            return
        end
        
        local timeId = skipData.TimeId
        local isOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
        if not isOpen then
            XUiManager.TipText("ActivityBaseTaskSkipNotInDuring")
            return
        end
        XLuaUiManager.Open("UiFavorabilityNew")
    end

    function XFunctionalSkipManager.OnOpenSlotmachine(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XDataCenter.SlotMachineManager.OpenSlotMachine(param1)
    end

    function XFunctionalSkipManager.UiDrawNewYear( skipData )
        local isOpen = true
        local desc
        if skipData.CustomParams[3] then
            isOpen, desc = XConditionManager.CheckCondition(skipData.CustomParams[3])
        end
        if not isOpen then
            XUiManager.TipError(desc)
        else
            XDataCenter.GachaManager.GetGachaRewardInfoRequest(skipData.CustomParams[1], function()
                XLuaUiManager.Open("UiDrawNewYear", skipData.CustomParams[1], skipData.CustomParams[2])
            end)
        end
    end

    return XFunctionalSkipManager
end