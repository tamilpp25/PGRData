XFunctionalSkipManagerCreator = function()
    local XFunctionalSkipManager = {}
    local DormDrawGroudId = CS.XGame.ClientConfig:GetInt("DormDrawGroudId")

    -- 跳转打开界面选择标签页类型6
    function XFunctionalSkipManager.SkipSystemWidthArgs(skipDatas)
        if not skipDatas then
            return
        end
        local param1 = (skipDatas.CustomParams[1] ~= 0) and skipDatas.CustomParams[1] or nil
        local param2 = (skipDatas.CustomParams[2] ~= 0) and skipDatas.CustomParams[2] or nil
        local param3 = (skipDatas.CustomParams[3] ~= 0) and skipDatas.CustomParams[3] or nil

        if skipDatas.UiName == "UiTask" and XLuaUiManager.IsUiShow("UiTask") then
            XEventManager.DispatchEvent(XEventId.EVENT_TASK_TAB_CHANGE, param1)
        elseif skipDatas.UiName == "UiPuzzleActivity" then
            XDataCenter.FubenActivityPuzzleManager.OpenPuzzleGame(param1)
        else
            XLuaUiManager.Open(skipDatas.UiName, param1, param2, param3)
        end
    end

    -- 跳转副本类型7
    function XFunctionalSkipManager.SkipCustom(skipDatas, ...)
        if not skipDatas then
            return
        end

        if XFunctionalSkipManager[skipDatas.UiName] then
            XFunctionalSkipManager[skipDatas.UiName](skipDatas, ...)
        end
    end

    -- 跳转宿舍类型8
    function XFunctionalSkipManager.SkipDormitory(skipDatas)
        if not skipDatas or not XPlayer.Id then
            return
        end

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
        local needRemoveUiName = {
            "UiDormTask",
            "UiDormTerminalSystem",
            "UiShop",
        }
        for _, uiName in pairs(needRemoveUiName) do
            if XLuaUiManager.IsUiLoad(uiName) then
                XLuaUiManager.Remove(uiName)
            end
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
        XLuaUiManager.ShowTopUi()
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
            XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm, nil, param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
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
                        if not info then
                            return
                        end
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
                            if not info then
                                return
                            end
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
        if XDataCenter.FurnitureManager.CheckFurnitureSlopLimit() then
            XLuaUiManager.Open("UiFurnitureCreateDetail")
            return
        end
        if XHomeDormManager.InDormScene() then
            XLuaUiManager.Open("UiFurnitureBuild", param1)
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiFurnitureBuild", param1)
            end)
        end
    end

    -- 前往宿舍委托主界面
    function XFunctionalSkipManager.SkipToDormQuestTerminal()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DormQuest) then
            return
        end
        if XHomeDormManager.InDormScene() then
            if not XLuaUiManager.IsUiShow("UiDormTerminalSystem") then
                XLuaUiManager.Open("UiDormTerminalSystem")
            end
        else
            XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
                XLuaUiManager.Open("UiDormTerminalSystem")
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
        elseif newCharType == XFubenNewCharConfig.NewCharType.Liv then
            uiName = "UiLifuActivityMain"
        else
            uiName = "UiFunbenWeiLaTutorial"
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
            --XLuaUiManager.Open("UiFubenYuanXiao")
            XLuaUiManager.Open("UiFuben2023YuanXiao")
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

        if XFunctionalSkipManager.IsStageLock(param2) then
            return
        end

        local sectionId = XDataCenter.FubenActivityBranchManager.GetCurSectionId()
        XLuaUiManager.Open("UiActivityBranch", sectionId, param1, param2)
    end

    -- 超难关
    function XFunctionalSkipManager.OnOpenUiActivityBossSingle(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivitySingleBoss) then
            return
        end
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local sectionId = XDataCenter.FubenActivityBossSingleManager.GetCurSectionId() or 1
        -- 活动时间限制
        if not XDataCenter.FubenActivityBossSingleManager.IsOpen() then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return
        end

        if (not param1) or (not XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlock(param1)) then
            XDataCenter.FubenActivityBossSingleManager.ExOpenMainUi(nil,sectionId)
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
        -- 检测是否有开放, 跳往战斗入口界面，全部转换为检测其对应打开界面的二级标签
        local _, __, secondTagId = XDataCenter.FubenManagerEx.GetTagConfigByChapterType(XFubenConfigs.ChapterType.Daily)
        local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(secondTagId)
        if not isOpen then
            XUiManager.TipMsg(lockTip)
            return
        end

        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]
        if param1 == nil or param1 == 0 then
            -- XLuaUiManager.Open("UiFuben", XDataCenter.FubenManager.StageType.Resource)
            XLuaUiManager.Open("UiNewFuben", XFubenConfigs.ChapterType.Daily)
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
        local chapterList = XDataCenter.PrequelManager.GetChapterList()
        local data = nil
        local index = 0
        for k, v in pairs(chapterList) do
            if v.ChapterId == param1 then
                data = v
                index = k
                break
            end
        end
        if data.IsLock and not data.IsActivity then
            XUiManager.TipMsg(XDataCenter.PrequelManager.GetChapterUnlockDescription(data.ChapterId))
            return false
        end

        XLuaUiManager.Open("UiPrequelMain", data.PequelChapterCfg)
        -- XLuaUiManager.OpenWithCallback("UiFuben", function()
        --     CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_PREQUEL_AUTOSELECT, param1, param2)
        -- end, 1)
    end

    -- 前往角色碎片(v1.30新入口)
    function XFunctionalSkipManager.OnOpenUiFragment(list)
        -- 检测是否有开放, 跳往战斗入口界面，全部转换为检测其对应打开界面的二级标签
        local _, __, secondTagId = XDataCenter.FubenManagerEx.GetTagConfigByChapterType(XFubenConfigs.ChapterType.CharacterFragment)
        local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(secondTagId)
        if not isOpen then
            XUiManager.TipMsg(lockTip)
            return
        end

        XLuaUiManager.Open("UiNewFuben", XFubenConfigs.ChapterType.CharacterFragment)
    end

    -- 是否能前往前传
    function XFunctionalSkipManager.IsCanOpenUiPrequel(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]
        local chapterList = XDataCenter.PrequelManager.GetChapterList()
        local data = nil
        local index = 0
        for k, v in pairs(chapterList) do
            if v.ChapterId == param1 then
                data = v
                index = k
                break
            end
        end
        if data.IsLock and not data.IsActivity then
            XUiManager.TipMsg(XDataCenter.PrequelManager.GetChapterUnlockDescription(data.ChapterId))
            return false
        end
        return true
    end

    -- 前往剧情简章主界面
    function XFunctionalSkipManager.OnOpenMainlineSubtab(list)
        -- local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        -- XLuaUiManager.Open("UiFuben", 1, nil, param1)
        -- 检测是否有开放, 跳往战斗入口界面，全部转换为检测其对应打开界面的二级标签
        local _, __, secondTagId = XDataCenter.FubenManagerEx.GetTagConfigByChapterType(XFubenConfigs.ChapterType.Prequel)
        local isOpen, lockTip = XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(secondTagId)
        if not isOpen then
            XUiManager.TipMsg(lockTip)
            return
        end
        XLuaUiManager.Open("UiNewFuben", XFubenConfigs.ChapterType.Prequel)
    end

    -- 前往隐藏关卡主界面
    function XFunctionalSkipManager.OnOpenMainlineWithDifficuty()
        -- XLuaUiManager.OpenWithCallback("UiFuben", function()
        --     CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_MAINLINE_DIFFICUTY_SELECT)
        -- end, 1)
        XLuaUiManager.OpenWithCallback("UiNewFuben", function()
            -- 变更新ui名，但新主线界面已经没有隐藏关卡按钮，看看之后消息要不要发fixme
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
            if XFunctionalSkipManager.IsStageLock(param2) then
                return
            end
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
        XDataCenter.FubenRepeatChallengeManager.ResetPanelState(true)
        XLuaUiManager.Open("UiFubenRepeatchallenge",param)
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
        if not stageId then
            return
        end
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

        if XFunctionalSkipManager.IsStageLock(stageId) then
            return
        end

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
                if sId == stageId then
                    stageIndex = j
                end
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

    -- 公会宿舍
    function XFunctionalSkipManager.OnOpenGuildDorm()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
            return
        end

        XDataCenter.GuildDormManager.EnterGuildDorm()
    end

    --拟真围剿
    function XFunctionalSkipManager.OpenGuildBoss()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
            return
        end
        if not XDataCenter.GuildManager.IsJoinGuild() then
            XUiManager.TipError(CS.XTextManager.GetText("GuildNoneJoinToPlay"))
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
        local isOpenStageLine = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        isOpenStageLine = XTool.IsNumberValid(isOpenStageLine)
        local IsOpen = gachaId and XDataCenter.GachaManager.CheckGachaIsOpenById(gachaId, true) or false
        if not IsOpen then
            return
        end
        XDataCenter.GachaManager.GetGachaRewardInfoRequest(gachaId, function()
            local gachaRule = XGachaConfigs.GetGachaRuleCfgById(gachaId)
            XLuaUiManager.Open(gachaRule.UiName, gachaId, isOpenStageLine)
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
        local timeId = list.TimeId
        local startTimeStr = list.StartTime
        local closeTimeStr = list.CloseTime
        local opened
        if XTool.IsNumberValid(timeId) then
            opened = XFunctionManager.CheckInTimeByTimeId(timeId)
        else
            local nowTimeStamp = XTime.GetServerNowTimestamp()
            local startTimeStamp = XTime.ParseToTimestamp(startTimeStr) or 0
            local closeTimeStamp = XTime.ParseToTimestamp(closeTimeStr) or nowTimeStamp
            opened = nowTimeStamp >= startTimeStamp and nowTimeStamp <= closeTimeStamp
        end
        if not opened then
            XUiManager.TipText("ShopIsNotOpen")
            return
        end
        local selectedShopId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local isOpen, desc = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)
        if isOpen then
            XDataCenter.ActivityBriefManager.OpenShop(nil, nil, selectedShopId)
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
        if not stageId then
            return false
        end
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
        if not jumpData then
            return
        end
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Extra) then
            local extraManager = XDataCenter.ExtraChapterManager
            if not jumpData.CustomParams then
                extraManager.JumpToExtraBanner()
            end
            local chapterId = jumpData.CustomParams[1]
            if chapterId then
                extraManager.JumpToExtraStage(chapterId, jumpData.CustomParams[2])
            else
                extraManager.JumpToExtraBanner()
            end
        end
    end

    --跳转到故事集关卡
    function XFunctionalSkipManager.ShortStoryChapter(jumpData)
        if not jumpData then
            return
        end
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShortStory) then
            local extraManager = XDataCenter.ShortStoryChapterManager
            if not jumpData.CustomParams then
                extraManager.JumpToShortStoryBanner()
            end
            local chapterId = jumpData.CustomParams[1]
            if chapterId then
                extraManager.JumpToShortStoryStage(chapterId, jumpData.CustomParams[2])
            else
                extraManager.JumpToShortStoryBanner()
            end
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

    --超级据点关卡选择界面
    function XFunctionalSkipManager.SkipToStrongholdFightMain(skipDatas)
        local chapterId = skipDatas.CustomParams[1]
        local groupId = skipDatas.CustomParams[2]
        local isUnlock, conditionDes = XDataCenter.StrongholdManager.CheckChapterUnlock(chapterId)
        if not isUnlock then
            XUiManager.TipMsg(conditionDes)
            return
        end

        local callFunc = function()
            XLuaUiManager.Open("UiStrongholdFightMain", chapterId, groupId)
        end

        if not XDataCenter.StrongholdManager.IsSelectedLevelId() then
            XLuaUiManager.Open("UiStrongholdChooseLevelType", callFunc)
        else
            callFunc()
        end
    end

    --================
    --跳转到白色情人节约会小游戏
    --================    
    function XFunctionalSkipManager.JumpToWhiteValentineGame()
        XDataCenter.WhiteValentineManager.JumpTo()
    end

    -- 跳转到涂装返场商店
    function XFunctionalSkipManager.SkipToSpecialShop(skipData)
        local shopId = XSpecialShopConfigs.GetShopId()
        local weaponShopId = XSpecialShopConfigs.GetWeaponFashionShopId()
        XShopManager.GetShopInfo(weaponShopId)
        XShopManager.GetShopInfo(shopId, function()
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

    function XFunctionalSkipManager.SkipRift()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Rift) then
            -- 条件
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        -- 活动数据
        if not XDataCenter.RiftManager.GetCurrentConfig() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        if not XDataCenter.RiftManager.IsInActivity() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        XLuaUiManager.Open("UiRiftMain")
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
        if not XDataCenter.Reform2ndManager.GetIsOpen() then
            XUiManager.TipError(CS.XTextManager.GetText("FunctionNotDuringOpening"))
            return
        end
        XDataCenter.Reform2ndManager.EnterRequest(function()
            XLuaUiManager.Open("UiReform2")
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

    --跳转到黄金矿工
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
        if not uiName then
            return
        end
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

    function XFunctionalSkipManager.OpenTwoSideTower()
        XDataCenter.TwoSideTowerManager.OnOpenMain()
    end

    function XFunctionalSkipManager.OpenLotto(list)
        local groupId = tonumber(list.CustomParams[1])
        local param1 = tonumber(list.CustomParams[2])
        XDataCenter.LottoManager.OpenLottoUi(groupId, param1)
    end

    -- 跳转到夏日签到
    function XFunctionalSkipManager.SkipToSummerSignInMain()
        XDataCenter.SummerSignInManager.OnOpenMain()
    end

    --region   ------------------装备目标系统跳转 start-------------------

    --==============================
    ---@desc 跳转到分解商店，并选中对应装备类型/意识套装
    ---@list 配置参数，静态 
    ---@args 动态参数 
    --==============================
    function XFunctionalSkipManager.SkipToShopByShopId(list, args)
        if args and type(args) ~= "table" then
            XLog.Error("FunctionalSkipManager.SkipToShopByShopId 参数传递错误:", args)
            return
        end
        if not list then
            return
        end
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil

        local templateId = args[1]
        local star = XDataCenter.EquipManager.GetEquipStar(templateId)
        local equipType = XDataCenter.EquipManager.GetEquipClassifyByTemplateId(templateId)
        local shopId = XShopManager.DecompositionShopId[equipType][star]
        if not XTool.IsNumberValid(shopId) then
            XLog.Error("FunctionalSkipManager.SkipToShopByShopId ShopId格式错误, EquipType: " .. equipType .. ", star: " .. star)
            return
        end
        local screenId
        if equipType == XEquipConfig.Classify.Weapon then
            screenId = XDataCenter.EquipManager.GetEquipTypeByTemplateId(templateId)
        elseif equipType == XEquipConfig.Classify.Awareness then
            screenId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
        end
        XLuaUiManager.Open("UiShop", param1, param2, shopId, screenId)
    end

    function XFunctionalSkipManager.SkipToShopByShopTypeAndShopId(list)
        local shopType = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local shopId = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        XLuaUiManager.Open("UiShop", shopType, nil, shopId)
    end

    --==============================
    ---@desc 跳转到复刷关商店
    ---@list 配置参数，静态 
    --==============================
    function XFunctionalSkipManager.SkipToRepeatChallengeActivityShop(list, args)
        local timeId = list.TimeId
        local startTimeStr = list.StartTime
        local closeTimeStr = list.CloseTime
        local opened
        if XTool.IsNumberValid(timeId) then
            opened = XFunctionManager.CheckInTimeByTimeId(timeId)
        else
            local nowTimeStamp = XTime.GetServerNowTimestamp()
            local startTimeStamp = XTime.ParseToTimestamp(startTimeStr) or 0
            local closeTimeStamp = XTime.ParseToTimestamp(closeTimeStr) or nowTimeStamp
            opened = nowTimeStamp >= startTimeStamp and nowTimeStamp <= closeTimeStamp
        end
        opened = opened and XDataCenter.FubenRepeatChallengeManager.IsOpen()
        if not opened then
            XUiManager.TipText("ShopIsNotOpen")
            return
        end
        if args and type(args) ~= "table" then
            XLog.Error("FunctionalSkipManager.SkipToRepeatChallengeActivityShop 参数传递错误:", args)
            return
        end
        local selectedShopId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local isOpen, desc = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)

        local templateId = args[1]
        local screenId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
        if isOpen then
            XDataCenter.ActivityBriefManager.OpenShop(nil, nil, selectedShopId, screenId)
        else
            XUiManager.TipMsg(desc)
        end
    end

    function XFunctionalSkipManager.SkipToRepeatChallengeActivityShopByIndex(list)
        local shopIndex = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local shopList = XDataCenter.ActivityBriefManager.GetActivityShopIds()
        if XTool.IsTableEmpty(shopList) or not shopIndex then
            return
        end
        local selectedShopId = shopList[shopIndex]
        if not selectedShopId then
            return
        end

        local isOpen, desc = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)

        if isOpen then
            XDataCenter.ActivityBriefManager.OpenShop(nil, nil, selectedShopId)
        else
            XUiManager.TipMsg(desc)
        end

    end
    --==============================
    ---@desc 跳转到资源商店，并选择对应意识套装
    ---@list 配置参数，静态  
    ---@args 动态参数 
    --==============================
    function XFunctionalSkipManager.SkipToFubenDailyAndOpenShop(list, args)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]
        local param3 = (list.CustomParams[3] ~= 0) and list.CustomParams[3]
        if param1 == nil or param1 == 0 then
            XLuaUiManager.Open("UiFuben", XDataCenter.FubenManager.StageType.Resource)
            return
        end

        XLuaUiManager.OpenWithCallback("UiFubenDaily", function()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_RESOURCE_AUTOSELECT, param2)
        end, XDailyDungeonConfigs.GetDailyDungeonRulesById(param1))

        if not XTool.IsNumberValid(param3) then
            XLog.Error("XFunctionalSkipManager.SkipToFubenDailyAndOpenShop Error CustomParams[3] : " .. param3)
            return
        end
        if args and type(args) ~= "table" then
            XLog.Error("FunctionalSkipManager.SkipToShopByShopId 参数传递错误:", args)
            return
        end
        local templateId = args[1]
        local suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(templateId)
        XLuaUiManager.Open("UiFubenDailyShop", param3, suitId)
    end

    function XFunctionalSkipManager.SkipToDrawAimWeapon(list, args)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1]
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2]

        if args and type(args) ~= "table" then
            XLog.Error("FunctionalSkipManager.SkipToShopByShopId 参数传递错误:", args)
            return
        end
        local templateId = args[1]
        local drawId = XDrawConfigs.GetDrawIdByTemplateIdAndCombinationsTypes(templateId, XDrawConfigs.CombinationsTypes.Aim)
        if not XTool.IsNumberValid(drawId) then
            XUiManager.TipText("EquipGuideDrawNoWeaponTip")
            return
        end
        XDataCenter.DrawManager.OpenDrawUi(param1, param2, drawId)
    end
    --endregion------------------装备目标系统跳转 finish------------------

    --肉鸽二期
    function XFunctionalSkipManager.SkipToBiancaTheatre()
        XDataCenter.BiancaTheatreManager:ExOpenMainUi()
    end

    --DLC
    function XFunctionalSkipManager.SkipToDlcHuntMain()
        XDataCenter.DlcHuntManager.OpenMain()
    end

    -- 本我回廊（角色塔）
    function XFunctionalSkipManager.SkipToUiCharacterTowerChapter(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        local param3 = (list.CustomParams[3] ~= 0) and list.CustomParams[3] or nil
        if not XTool.IsNumberValid(param1) then
            XLuaUiManager.Open("UiNewFuben", XFubenConfigs.ChapterType.CharacterTower)
            return
        end

        local isUnlock, tips = XDataCenter.CharacterTowerManager.IsUnlock(param1)
        if not isUnlock then
            XUiManager.TipError(tips)
            return
        end
        local closeLastStage = param3 == 1 -- 关闭上一个界面，然后打开下一个界面
        XDataCenter.CharacterTowerManager.OpenChapterUi(param2, closeLastStage)
    end

    -- 打开主线章节或者关卡详情
    function XFunctionalSkipManager.SkipToMainLineChapterOrStage(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        local param3 = (list.CustomParams[3] ~= 0) and list.CustomParams[3] or nil
        local openStageDetail = param2 == 1 -- 打开关卡详情
        local closeLastStage = param3 == 1 -- 关闭上一个界面，然后打开下一个界面
        local removeStage = param3 == 2 -- 打开界面前先移除当前Ui的缓存
        if not param1 then
            return
        end
        if removeStage then
            XLuaUiManager.Remove("UiFubenMainLineChapter")
        end
        XDataCenter.FubenMainLineManager.OpenMainLineChapterOrStage(param1, openStageDetail, closeLastStage)
    end

    -- 打开三头犬
    function XFunctionalSkipManager.OnOpenCerberusGame()
        if not XDataCenter.CerberusGameManager.CheckIsActivityOpen() then
            XUiManager.TipError(CS.XTextManager.GetText("CommonActivityNotStart"))
            return
        end

        XLuaUiManager.Open("UiCerberusGameMain")
    end

    -- 调色板战争
    function XFunctionalSkipManager.SkipToColorTable()
        XDataCenter.ColorTableManager.ExOpenMainUi()
    end

    -- 异构阵线2.0
    function XFunctionalSkipManager.SkipToMaverick2()
        XDataCenter.Maverick2Manager.ExOpenMainUi()
    end

    --region   ------------------回归活动 start-------------------
    --回归打开剧情界面
    function XFunctionalSkipManager.SkipToRegression3rdMovie(list)
        XDataCenter.Regression3rdManager.EnterUiMain()
    end
    --endregion------------------回归活动 finish------------------

    --涂装投票
    function XFunctionalSkipManager.SkipToSkinVote(list)
        XDataCenter.SkinVoteManager.EnterMainUi()
    end

    -- 边界公约
    function XFunctionalSkipManager.SkipToFubenAssign(list)
        XDataCenter.FubenAssignManager.OpenUi()
    end

    -- 意识公约
    function XFunctionalSkipManager.SkipToFubenAwareness(list)
        XDataCenter.FubenAwarenessManager.OpenUi()
    end

    --光辉同行 
    function XFunctionalSkipManager.SkipToBrilliantWalkMain(list)
        XDataCenter.BrilliantWalkManager:ExOpenMainUi()
    end

    --战双餐厅
    function XFunctionalSkipManager.SkipToRestaurantMain(list)
        XDataCenter.RestaurantManager.EnterUiMain()
    end

    -- 好感度（打开指定角色）
    function XFunctionalSkipManager.SkipToFavorabilityNewParam(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        if not XTool.IsNumberValid(param1) then
            return
        end
        if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityMain) then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
            return
        end
        XLuaUiManager.Open("UiFavorabilityNew", param1)
    end

    --分包下载
    function XFunctionalSkipManager.SkipToDLCDownload(list)
        if not XDataCenter.DlcManager.CheckIsOpen() then
            return
        end
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XLuaUiManager.Open("UiDownLoadMain", param1)
    end

    function XFunctionalSkipManager.SkipToNewDrawMain(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        local param3 = (list.CustomParams[3] ~= 0) and list.CustomParams[3] or nil
        if XHomeDormManager.InDormScene() then
            local title = XUiHelper.GetText("TipTitle")
            local content = XUiHelper.GetText("DormSkipToNewDrawMainContent")
            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
                XDataCenter.DormManager.ExitDormitoryBackToMain()
                XScheduleManager.ScheduleOnce(function()
                    XDataCenter.DrawManager.OpenDrawUi(param1, param2, param3)
                end, XScheduleManager.SECOND)
            end)
            return
        end
        XDataCenter.DrawManager.OpenDrawUi(param1, param2, param3)
    end

    --工会宿舍签到
    function XFunctionalSkipManager.SkipToGuildSign(list)
        local themeId = XDataCenter.GuildDormManager.GetThemeId()
        if not XTool.IsNumberValid(themeId) then
            XLog.Error("skip to guild sign error, theme id is invalid themeId = " .. tostring(themeId))
            return
        end
        local themeCfg = XGuildDormConfig.GetThemeCfgById(themeId)
        XLuaUiManager.Open(themeCfg.UiName)
    end

    function XFunctionalSkipManager.SkipToMaze()
        XDataCenter.MazeManager.OpenMain()
    end

    -- 跳转到库街区
    function XFunctionalSkipManager.SkipToKujiequ()
        XDataCenter.KujiequManager.OpenKujiequ()
    end

    ---跳转到行星环游记
    function XFunctionalSkipManager.SkipToPlanetRunning()
        XDataCenter.PlanetManager.EnterUiMain()
    end

    -- 跳转到BVB
    function XFunctionalSkipManager.SkipToMonsterCombat()
        XDataCenter.MonsterCombatManager.OpenMainUi()
    end

    -- 跳转到老虎机
    function XFunctionalSkipManager.SkipToSlotMachine(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
        local isOpenTask = param2 == 1
        XDataCenter.SlotMachineManager.OpenSlotMachine(param1, isOpenTask)
    end

    -- 超限连战
    function XFunctionalSkipManager.SkipToTransfinite()
        XDataCenter.TransfiniteManager.OpenMain()
    end
    
    --region v2.6 新成员系统跳转 begins
    -- 成员
    function XFunctionalSkipManager.SkipToCharacterV2P6(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XLuaUiManager.Open("UiCharacterSystemV2P6", param1)
    end

    -- 成员升级
    function XFunctionalSkipManager.SkipToCharacterLevelUpV2P6()
        XLuaUiManager.Open("UiCharacterSystemV2P6", nil, XEnumConst.CHARACTER.SkipEnumV2P6.PropertyLvUp)
    end

    -- 成员晋升
    function XFunctionalSkipManager.SkipToCharacterGradeV2P6()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterGrade) then
            return
        end
        XLuaUiManager.Open("UiCharacterSystemV2P6", nil, XEnumConst.CHARACTER.SkipEnumV2P6.PropertyGrade)
    end

    -- 成员技能
    function XFunctionalSkipManager.SkipToCharacterSkillV2P6()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill) then
            return
        end
        XLuaUiManager.Open("UiCharacterSystemV2P6", nil, XEnumConst.CHARACTER.SkipEnumV2P6.PropertySkill)
    end

    --endregion v2.6 新成员系统跳转 end

    ---v2.6 肉鸽3.0
    function XFunctionalSkipManager.SkipToTheatre3()
        ---@type XTheatre3Agency
        local agency = XMVCA:GetAgency(ModuleId.XTheatre3)
        agency:ExOpenMainUi()
    end
    
    --剧情关章节界面
    function XFunctionalSkipManager.SkipToFashionStoryChapter(skipData)
        if skipData.ParamId then
            local IsOpen,LockReason=XDataCenter.FashionStoryManager.CheckGroupIsCanOpen(skipData.ParamId)
            XDataCenter.FashionStoryManager.EnterPaintingGroupPanel(skipData.ParamId,IsOpen,LockReason,function()
        XLuaUiManager.PopThenOpen("UiFubenFashionPaintingNew",skipData.ParamId)
                XDataCenter.FashionStoryManager.MarkGroupAsHadAccess(skipData.ParamId)
            end)
    end
    end
    
    -- EquipGuideDrawNoWeaponTip

    return XFunctionalSkipManager
end
