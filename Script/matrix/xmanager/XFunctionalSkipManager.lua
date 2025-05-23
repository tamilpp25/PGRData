local XActivityBrieIsOpen = require("XUi/XUiActivityBrief/XActivityBrieIsOpen")
XFunctionalSkipManagerCreator = function()
    ---@class XFunctionalSkipManager
    local XFunctionalSkipManager = {}
    local DormDrawGroudId = CS.XGame.ClientConfig:GetInt("DormDrawGroudId")

    -- 跳转打开界面选择标签页类型6
    function XFunctionalSkipManager.SkipSystemWidthArgs(skipDatas)
        if not skipDatas then
            return false
        end
        local param1 = (skipDatas.CustomParams[1] ~= 0) and skipDatas.CustomParams[1] or nil
        local param2 = (skipDatas.CustomParams[2] ~= 0) and skipDatas.CustomParams[2] or nil
        local param3 = (skipDatas.CustomParams[3] ~= 0) and skipDatas.CustomParams[3] or nil

        if skipDatas.UiName == "UiTask" and XLuaUiManager.IsUiShow("UiTask") then
            XEventManager.DispatchEvent(XEventId.EVENT_TASK_TAB_CHANGE, param1)
            return true
        elseif skipDatas.UiName == "UiPuzzleActivity" then
            return XDataCenter.FubenActivityPuzzleManager.OpenPuzzleGame(param1)
        else
            XLuaUiManager.Open(skipDatas.UiName, param1, param2, param3)
            return true
        end
    end
    
    -- 跳转副本类型7
    function XFunctionalSkipManager.SkipCustom(skipDatas, ...)
        if not skipDatas then
            return false
        end

        if XFunctionalSkipManager[skipDatas.UiName] then
            return XFunctionalSkipManager[skipDatas.UiName](skipDatas, ...)
        end
        
        return false
    end

    -- 跳转宿舍类型8
    function XFunctionalSkipManager.SkipDormitory(skipDatas)
        if not skipDatas or not XPlayer.Id then
            return false
        end

        if XFunctionalSkipManager[skipDatas.UiName] then
            return XFunctionalSkipManager[skipDatas.UiName](skipDatas)
        end
        
        return false
    end
    
    -- 跳转MVCA模块 类型10
    ---@param skipCfg XTableSkipFunctional
    function XFunctionalSkipManager.SkipMVCAModule(skipCfg, ...)
        local agency = XMVCA[skipCfg.UiName]
        if agency then
            if agency.ExOnSkip then
                return agency:ExOnSkip(skipCfg, ...)
            else
                XLog.Error('跳转失败，对应的模块没有实现ExOnSkip方法:'..tostring(skipCfg.UiName))
            end
        else
            XLog.Error('跳转失败，对应的模块不存在:'..tostring(skipCfg.UiName))
        end
        
        return false
    end

    --region 自定义跳转函数-类型7
    
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

        local needVideoSubPackTip = false
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
            needVideoSubPackTip = true
        end
        
        if needVideoSubPackTip and not XMVCA.XSubPackage:CheckSubpackageByIdAndIntercept(XEnumConst.SUBPACKAGE.TEMP_VIDEO_SUBPACKAGE_ID.GAMEPLAY) then
            return
        end

        XDataCenter.FubenNewCharActivityManager.SetCurOpenActivityId(actId)
        XLuaUiManager.Open(uiName, actId, isOpenSkin)
    end
    
    -- 3.0前往新角色试玩玩法（与旧版走不同的功能逻辑）
    function XFunctionalSkipManager.OnOpenCharacterFileFubenActivity(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewCharAct) then
            return
        end

        local actId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
        -- 活动时间限制
        if not XDataCenter.FubenNewCharActivityManager.IsOpen(actId) then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return
        end
        XDataCenter.FubenNewCharActivityManager.SetCurOpenActivityId(actId)
        XLuaUiManager.Open('UiCharacterFileMainRoot', actId)
    end

    -- [3.5 鬼泣联动] 前往新角色试玩玩法
    function XFunctionalSkipManager.OnOpenCharacterFileFubenActivityDMC(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewCharAct) then
            return
        end

        -- 从manager中获取活动Id（条件随机，具体由Manager内的逻辑）
        local actId = XDataCenter.FubenNewCharActivityManager.GetDMCActivityIdByCondition()
        -- 活动时间限制
        if not XDataCenter.FubenNewCharActivityManager.IsOpen(actId) then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return
        end
        XDataCenter.FubenNewCharActivityManager.SetCurOpenActivityId(actId)
        XLuaUiManager.Open('UiCharacterFileMainRoot', actId)
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
    --
    --    -- 开启时间限制
    --    if not XDataCenter.FubenActivityBranchManager.IsOpen() then
    --        XUiManager.TipText("ActivityBranchNotOpen")
    --        return
    --    end
    --
    --    local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or 1
    --    local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil
    --
    --    if param1 == XDataCenter.FubenActivityBranchManager.BranchType.Difficult then
    --        if not XDataCenter.FubenActivityBranchManager.IsStatusEqualChallengeBegin() then
    --            XUiManager.TipText("ActivityBranchNotOpen")
    --            return
    --        end
    --    end
    --
    --    if XFunctionalSkipManager.IsStageLock(param2) then
    --        return
    --    end
    --
    --    local sectionId = XDataCenter.FubenActivityBranchManager.GetCurSectionId()
    --    XLuaUiManager.Open("UiActivityBranch", sectionId, param1, param2)
    end

    -- 超难关
    function XFunctionalSkipManager.OnOpenUiActivityBossSingle(list)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivitySingleBoss) then
            return false
        end
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local sectionId = XDataCenter.FubenActivityBossSingleManager.GetCurSectionId() or 1
        -- 活动时间限制
        if not XDataCenter.FubenActivityBossSingleManager.IsOpen() then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return false
        end

        if (not param1) or (not XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlock(param1)) then
            return XDataCenter.FubenActivityBossSingleManager.ExOpenMainUi(nil,sectionId)
        else
            XLuaUiManager.Open("UiActivityBossSingleDetail", param1)
            return true
        end
        
        return false
    end

    -- 前往纷争战区
    ---@param skipDatas XTableSkipFunctional
    function XFunctionalSkipManager.OnOpenUiArena(skipDatas)
        -- local arenaChapters = XFubenConfigs.GetChapterBannerByType(XDataCenter.FubenManager.ChapterType.ARENA)
        -- XDataCenter.ArenaManager.RequestSignUpArena(function()
        --     XLuaUiManager.Open("UiArena", arenaChapters)
        -- end)
        return XMVCA.XArena:ExOpenMainUi(skipDatas.SkipId)
    end

    -- 前往幻痛囚笼
    ---@param skipDatas XTableSkipFunctional
    function XFunctionalSkipManager.OnOpenUiFubenBossSingle(skipDatas)
        if XMVCA.XFubenBossSingle:IsInLevelTypeChooseAble() then
            return XMVCA.XFubenBossSingle:OpenChooseUi()
        end

        return XMVCA.XFubenBossSingle:OpenBossSingleView(skipDatas.SkipId)
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

        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.Prequel, data.ChapterId) then
            return
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

    function XFunctionalSkipManager.OnOpenExhibitionInfoCustomArg(list, characterId)
        local char = XMVCA.XCharacter:GetCharacter(characterId)
        if not char then
            return
        end
        XLuaUiManager.Open("UiExhibitionInfo", characterId)
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
    
    -- 跳转鬼泣剧情关
    function XFunctionalSkipManager.OnOpenDMCFestivalActivity(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil --  活动Id
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil -- 默认选中的关卡

        if not XDataCenter.FubenFestivalActivityManager.IsFestivalInActivity(param1) then
            XUiManager.TipText("FestivalActivityNotInActivityTime")
            return
        end

        if param2 then
            if XFunctionalSkipManager.IsStageLock(param2) then
                return
            end

            XLuaUiManager.Open("UiDMCFestivalActivityMain", param1, param2)
        else
            XLuaUiManager.Open("UiDMCFestivalActivityMain", param1)
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
        --local activityId = XDataCenter.FubenRogueLikeManager.GetRogueLikeActivityId()
        --if activityId == nil or activityId <= 0 then
        --    XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        --    return
        --end
        --local activityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(activityId)
        --
        --if not activityConfig then
        --    return
        --end
        --if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
        --    XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        --    return
        --end
        --
        --if activityConfig.FunctionalOpenId > 0 and (not XFunctionManager.DetectionFunction(activityConfig.FunctionalOpenId)) then
        --    return
        --end
        --
        --XDataCenter.FubenRogueLikeManager.OpenRogueLikeCheckStory()
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
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MainLine, stageInfo.ChapterId) then
            return
        end
        if openStageDetail then
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter, stageId)
        else
            XLuaUiManager.Open("UiFubenMainLineChapter", chapter)
        end
    end

    function XFunctionalSkipManager.SkipToMainLine2(list)
        local chapterId = list.CustomParams[1]
        local stageId = list.CustomParams[2]
        local isOpenStageDetail = list.CustomParams[3] == 1
        XMVCA:GetAgency(ModuleId.XMainLine2):SkipToMainLine2(chapterId, stageId, isOpenStageDetail)
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
        --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenUnionKill) then
        --    return
        --end
        --local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        --if not unionInfo or not unionInfo.Id or unionInfo.Id <= 0 then
        --    XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
        --    return
        --end
        --
        --if not XFubenUnionKillConfigs.UnionKillInActivity(unionInfo.Id) then
        --    XUiManager.TipMsg(CS.XTextManager.GetText("UnionKillMainNotInActivity"))
        --    return
        --end
        --
        --XLuaUiManager.Open("UiUnionKillMain")
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
    ---@param skipDatas XTableSkipFunctional
    function XFunctionalSkipManager.OpenGuildBoss(skipDatas)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
            return false
        end
        if not XDataCenter.GuildManager.IsJoinGuild() then
            XUiManager.TipError(CS.XTextManager.GetText("GuildNoneJoinToPlay"))
            return false
        end
        return XDataCenter.GuildBossManager.OpenGuildBossHall(skipDatas.SkipId)
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
        if param1 == XEnumConst.Archive.SubSystemType.Monster then
            XLuaUiManager.Open("UiArchiveMonster")
        elseif param1 == XEnumConst.Archive.SubSystemType.Weapon then
            XLuaUiManager.Open("UiArchiveWeapon")
        elseif param1 == XEnumConst.Archive.SubSystemType.Awareness then
            XLuaUiManager.Open("UiArchiveAwareness")
        elseif param1 == XEnumConst.Archive.SubSystemType.Story then
            if not XMVCA.XSubPackage:CheckSubpackageByIdAndIntercept(XEnumConst.SUBPACKAGE.TEMP_VIDEO_SUBPACKAGE_ID.STORY) then
                return
            end

            XLuaUiManager.Open("UiArchiveStory")
        elseif param1 == XEnumConst.Archive.SubSystemType.CG then
            XLuaUiManager.Open("UiArchiveCG")
        elseif param1 == XEnumConst.Archive.SubSystemType.NPC then
            XLuaUiManager.Open("UiArchiveNpc")
        elseif param1 == XEnumConst.Archive.SubSystemType.Email then
            XLuaUiManager.Open("UiArchiveEmail")
        elseif param1 == XEnumConst.Archive.SubSystemType.Partner then
            XLuaUiManager.Open("UiArchivePartner")
        elseif param1 == XEnumConst.Archive.SubSystemType.PV then
            if not XMVCA.XSubPackage:CheckSubpackageByIdAndIntercept(XEnumConst.SUBPACKAGE.TEMP_VIDEO_SUBPACKAGE_ID.STORY) then
                return
            end

            XLuaUiManager.Open("UiArchivePV")
        elseif param1 == XEnumConst.Archive.SubSystemType.Comic then
            XLuaUiManager.Open('UiArchiveComic')    
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
    function XFunctionalSkipManager.OnOpenActivityBriefShop(list, ignoreClosedShopId)
        -- 判断skip配置的时间是否开启
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
        -- 判断首选商店是否开启
        local selectedShopId = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local isOpen, desc = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)
        if isOpen then
            XDataCenter.ActivityBriefManager.OpenShop(nil, nil, selectedShopId, nil, ignoreClosedShopId)
        else
            XUiManager.TipMsg(desc)
        end
    end

    -- 跳转世界Boss
    function XFunctionalSkipManager.OnOpenWorldBoss()
        --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.WorldBoss) then
        --    return
        --end
        --if not XDataCenter.WorldBossManager.IsInActivity() then
        --    XUiManager.TipMsg(CS.XTextManager.GetText("WorldBossNotInActivityTime"))
        --    return
        --end
        --XDataCenter.WorldBossManager.OpenWorldMainWind()
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
    --    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenInfesotorExplore) then
    --        if XDataCenter.FubenInfestorExploreManager.IsInSectionOne()
    --                or XDataCenter.FubenInfestorExploreManager.IsInSectionTwo() then
    --            local openCb = function()
    --                XLuaUiManager.Open("UiInfestorExploreRank")
    --            end
    --            XDataCenter.FubenInfestorExploreManager.OpenEntranceUi(openCb)
    --        elseif XDataCenter.FubenInfestorExploreManager.IsInSectionEnd() then
    --            XUiManager.TipText("InfestorExploreEnterSectionEnd")
    --        end
    --    end
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
        --XDataCenter.ExpeditionManager.JumpToExpedition()
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
        --if XChessPursuitConfig.GetChessPursuitInTimeMapGroup() then
        --    XLuaUiManager.Open("UiChessPursuitMain")
        --else
        --    XUiManager.TipText("ChessPursuitNotInTime")
        --end
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
        --XDataCenter.RpgMakerGameManager.RequestRpgMakerGameEnter()
        XUiManager.TipText("ActivityMainLineEnd")
    end

    --================
    --跳转到组合小游戏
    --================
    function XFunctionalSkipManager.JumpToComposeGame(skipDatas)
        XDataCenter.ComposeGameManager.JumpTo(skipDatas.CustomParams[1])
    end

    --超级据点主界面
    function XFunctionalSkipManager.SkipToStrongholdMain()
        return XDataCenter.StrongholdManager.EnterUiMain()
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
        --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenSimulatedCombat) then
        --    return
        --end
        --
        --local mode, childUiType = list.CustomParams[1], list.CustomParams[2]
        --local isOpen, desc = XDataCenter.FubenSimulatedCombatManager.CheckModeOpen(mode)
        --if not isOpen then
        --    XUiManager.TipMsg(desc)
        --    return
        --end
        --
        --XLuaUiManager.Remove("UiSimulatedCombatMain")
        --XLuaUiManager.Open("UiSimulatedCombatMain", mode, childUiType)
    end

    function XFunctionalSkipManager.SkipToMoeWar()
        --XDataCenter.MoeWarManager.OnOpenMain()
        XUiManager.TipText("MoeWarNotOpen")
    end

    function XFunctionalSkipManager.SkipToFubenHack(list)
        --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenHack) then
        --    return
        --end
        --local isEnd, isNotOpen = XDataCenter.FubenHackManager.GetIsActivityEnd()
        --if isNotOpen then
        --    XUiManager.TipText("CommonActivityNotStart")
        --elseif isEnd then
        --    XUiManager.TipText("ActivityMainLineEnd")
        --else
        --    XLuaUiManager.Open("UiFubenHack")
        --end
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
        if not XMVCA.XRift:GetCurrentConfig() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        if not XMVCA.XRift:IsInActivity() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        XMVCA.XRift:OpenMain()
    end

    function XFunctionalSkipManager.SkipToFubenCoupleCombat(list)
        --if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenCoupleCombat) then
        --    return
        --end
        --if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
        --    XUiManager.TipText("FubenRepeatNotInActivityTime")
        --    return
        --end
        --
        --XLuaUiManager.Open("UiCoupleCombatChapter")
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
            return false
        end
        if not XMVCA.XReform:GetIsOpen() then
            XUiManager.TipError(CS.XTextManager.GetText("FunctionNotDuringOpening"))
            return false
        end
        local resultId
        local isSync = true
        isSync = XMVCA.XReform:EnterRequest(function(success)
            if success then
                XLuaUiManager.Open("UiReform2")
            end
            if not isSync then
                XFunctionManager.AcceptResult(resultId, success)
            end
        end)
        if isSync then
            return true
        end
        resultId = XFunctionManager.GetNewResultId()
        return resultId
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
        --XDataCenter.KillZoneManager.EnterUiMain()
    end

    function XFunctionalSkipManager.SkipToSameColorGame()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SameColor) then
            return false
        end
        return XDataCenter.SameColorActivityManager.OpenMainUi()
    end

    function XFunctionalSkipManager.SkipToTheatre()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre) then
            return false
        end
        return XDataCenter.TheatreManager.CheckAutoPlayStory()
    end

    -- 跳转战斗通行证
    function XFunctionalSkipManager.OnOpenPassport()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Passport) then
            return
        end
        XMVCA.XPassport:OpenMainUi()
    end

    function XFunctionalSkipManager.SkipToPickFlipRewardActivity(skipData)
        XDataCenter.PickFlipManager.OpenMainUi(skipData.CustomParams[1])
    end

    --================
    --跳转到超限乱斗
    --================
    function XFunctionalSkipManager.SkipToSuperSmashBros()
        --XDataCenter.SuperSmashBrosManager.JumpTo()
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
        --local notInActivity, notStart = XDataCenter.MaverickManager.IsActivityEnd()
        --if notStart then
        --    XUiManager.TipText("MaverickNotStart")
        --    return
        --end
        --
        --if notInActivity then
        --    XUiManager.TipText("MaverickEnd")
        --    return
        --end
        --
        --XLuaUiManager.Open("UiFubenMaverickMain")
    end

    --跳转到大逃杀玩法主界面
    function XFunctionalSkipManager.SkipToEscapeMain()
        XDataCenter.EscapeManager.OnOpenMain()
    end

    --跳转到枢纽作战
    function XFunctionalSkipManager.SkipToPivotCombat()
        --XDataCenter.PivotCombatManager.JumpTo()
    end

    --跳转到哈卡玛小游戏
    function XFunctionalSkipManager.SkipToBodyCombineGame()
        XDataCenter.BodyCombineGameManager.JumpTo()
    end

    --跳转到黄金矿工
    function XFunctionalSkipManager.SkipToGoldenMiner()
        XMVCA.XGoldenMiner:ExOpenMainUi()
    end

    --跳转到动作塔防
    function XFunctionalSkipManager.SkipToDoubleTowers()
        --XDataCenter.DoubleTowersManager.OnOpenMain()
    end

    --登录弹窗提示，跳转到周任务挑战
    ---@param skipDatas XTableSkipFunctional
    function XFunctionalSkipManager.SkipToWeekChallenge(skipDatas)
        XDataCenter.WeekChallengeManager.OnAutoWindowOpen(XTool.IsNumberValid(skipDatas.CustomParams[1]))
    end
    
    function XFunctionalSkipManager.SkipToUiPacMan2Main()
        return XMVCA.XPacMan2:OpenMain()
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
        ---@type XTaikoMasterAgency
        local agency = XMVCA:GetAgency(ModuleId.XTaikoMaster)
        agency:ExOpenMainUi()
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
        ---@type XTwoSideTowerAgency
        local twoSideTowerAgency = XMVCA:GetAgency(ModuleId.XTwoSideTower)
        twoSideTowerAgency:ExOpenMainUi()
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
        local star = XMVCA.XEquip:GetEquipStar(templateId)
        local equipType = XMVCA.XEquip:GetEquipClassifyByTemplateId(templateId)
        local shopId = XShopManager.DecompositionShopId[equipType][star]
        if not XTool.IsNumberValid(shopId) then
            XLog.Error("FunctionalSkipManager.SkipToShopByShopId ShopId格式错误, EquipType: " .. equipType .. ", star: " .. star)
            return
        end
        local screenId
        if equipType == XEnumConst.EQUIP.CLASSIFY.WEAPON then
            screenId = XMVCA.XEquip:GetEquipType(templateId)
        elseif equipType == XEnumConst.EQUIP.CLASSIFY.AWARENESS then
            screenId = XMVCA.XEquip:GetEquipSuitId(templateId)
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
        local screenId = XMVCA.XEquip:GetEquipSuitId(templateId)
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
        local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
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
        XDataCenter.DrawManager.OpenDrawUi(param1, param2, drawId,nil,CS.XGame.Config:GetString('UiEquipStrengthenSkipDrawGroups'))
    end
    
    --3.0新增：跳转装备推荐
    function XFunctionalSkipManager.SkipToEquipGuideView(list)
        local characterId = list.CustomParams[1] or 0

        if XTool.IsNumberValid(characterId) then
            local isOwn = XMVCA:GetAgency(ModuleId.XCharacter):IsOwnCharacter(characterId)
            local isUnlock = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideRecommend)
            local canSet = isOwn and isUnlock
            XDataCenter.EquipGuideManager.OpenEquipGuideRecommend(characterId, not canSet)
        else
            XLog.Error('跳转配置参数错误，不是个有效的角色Id:', characterId, 'SkipId:'..tostring(list.SkipId))    
        end
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

    function XFunctionalSkipManager.SkipToLuckyTenant()
        XMVCA.XLuckyTenant:OpenMain()
    end

    function XFunctionalSkipManager.SkipToPokerGuessing2()
        XMVCA.XPokerGuessing2:OpenMain()
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
        if not XMVCA.XCerberusGame:CheckIsActivityOpen() then
            XUiManager.TipError(CS.XTextManager.GetText("CommonActivityNotStart"))
            return
        end
        XMVCA.XCerberusGame:ExOpenMainUi()
    end

    -- 打开三头犬2期
    function XFunctionalSkipManager.OnOpenCerberusGameSecond()
        if not XMVCA.XCerberusGame:CheckInSecondTimeActivity() then
            XUiManager.TipError(CS.XTextManager.GetText("CommonActivityNotStart"))
            return
        end

        if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.CerberusGame) then
            return
        end

        XLuaUiManager.Open("UiCerberusGameMainV2P9")
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
        XMVCA.XRestaurant:ExOpenMainUi()
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
        if not XMVCA.XSubPackage:IsOpen() then
            return
        end
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XLuaUiManager.Open("UiDownLoadMain", param1)
    end

    function XFunctionalSkipManager.SkipToPreload()
        local subPackageAgency = XMVCA.XSubPackage
        if subPackageAgency:IsOpen() and not subPackageAgency:CheckNecessaryComplete() then
            XUiManager.DialogTip("", XUiHelper.GetText("PreloadCheckSubPackage"), XUiManager.DialogType.Normal, nil, function()
                subPackageAgency:OpenUiMain()
            end, {sureText = XUiHelper.GetText("PreloadSkipSubPackage")})
            return
        end
        XLuaUiManager.Open("UiPreloadMain")
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
        --XDataCenter.PlanetManager.EnterUiMain()
        XUiManager.TipText("ActivityMainLineEnd")
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
        return XDataCenter.TransfiniteManager.OpenMain()
    end
    
    --region v2.6 新成员系统跳转 begins
    -- 成员
    function XFunctionalSkipManager.SkipToCharacterV2P6(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XLuaUiManager.Open("UiCharacterSystemV2P6", param1)
    end

    function XFunctionalSkipManager.SkipToCharacterV2P6CustomArg(list, characterId)
        XLuaUiManager.Open("UiCharacterSystemV2P6", characterId)
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
    
    --战棋
    function XFunctionalSkipManager.SkipToBlackRockChess()
        ---@type XBlackRockChessAgency
        local agency = XMVCA:GetAgency(ModuleId.XBlackRockChess)
        return agency:ExOpenMainUi()
    end
    
    -- 黑岩联动关
    function XFunctionalSkipManager.SkipToBlackRockStage()
        XLuaUiManager.Open("UiBlackRockStage")
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

    function XFunctionalSkipManager.SkipToConnectingLine()
        XLuaUiManager.Open("UiConnectingLineGame")
    end

    -- 跳转共鸣，默认选择角色第一个意识
    function XFunctionalSkipManager.SkipToResonanceCustomArg(list, characterId)
        local equipId = nil
        local isHaveCanResonanceEquip = false -- 有【有剩余共鸣位】的意识
        local isWearSixStarEquip = false -- 是否穿戴了六星意识
        local isAllResonanceSkillBindCurChar = true -- 所有共鸣技能都绑定了当前角色

        for equipSite = XEnumConst.EQUIP.MAX_STAR_COUNT, 1, -1 do -- 要查找第一个的，从倒数开始
            local tempEquipId = XMVCA.XEquip:GetCharacterEquipId(characterId, equipSite)

            if XTool.IsNumberValid(tempEquipId) then
                if XMVCA.XEquip:GetEquipStarByEquipId(tempEquipId) >= XEnumConst.EQUIP.MAX_STAR_COUNT 
                and XMVCA.XEquip:GetEquipResonanceCount(tempEquipId) < XEnumConst.EQUIP.MAX_AWAKE_COUNT then -- 意识只能共鸣2个
                    equipId = tempEquipId
                    isHaveCanResonanceEquip = true
                end

                if XMVCA.XEquip:GetEquipStarByEquipId(tempEquipId) >= XEnumConst.EQUIP.MAX_STAR_COUNT then
                    isWearSixStarEquip = true
                end

                for pos = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT, 1 do
                    if XMVCA.XEquip:CheckEquipPosResonanced(tempEquipId, pos) 
                    and XMVCA.XEquip:GetResonanceBindCharacterId(tempEquipId, pos) ~= characterId then --检测当前位置是否仍可以超频，且共鸣绑定当前角色
                        isAllResonanceSkillBindCurChar = false
                        break
                    end
                end
            end
        end

        if isWearSixStarEquip and not isHaveCanResonanceEquip and not isAllResonanceSkillBindCurChar then
            XUiManager.TipError(CS.XTextManager.GetText("ResonanceBindCharNotCur"))
            return
        end

        -- 没有意识符合条件再检查武器
        if not XTool.IsNumberValid(equipId) then
            local usingWeaponId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
            if XMVCA.XEquip:GetEquipStarByEquipId(usingWeaponId) >= XEnumConst.EQUIP.MAX_STAR_COUNT 
            and XMVCA.XEquip:GetEquipResonanceCount(usingWeaponId) < XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT then -- 武器能共鸣3个
                equipId = usingWeaponId
            end
        end

        if not XTool.IsNumberValid(equipId) then
            XUiManager.TipError(CS.XTextManager.GetText("CharNeedWearSixStarEquip"))
            return
        end

        XLuaUiManager.Open("UiEquipDetailV2P6", equipId, nil, characterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    end

    function XFunctionalSkipManager.SkipToAwakeCustomArg(list, characterId)
        local tempEquipId = nil -- 检测所有格子是否有意识
        local sixStarButNotAwakeEquipId = nil -- 第一个【满足可超频的意识 但是没有完全超频的】
        local sixStarButNotResonaceEquipId = nil -- 第一个 【满足可共鸣的意识 但是没完全共鸣】
        local isHaveCanResonanceEquip = false -- 有【有剩余共鸣位】的意识
        local isWearSixStarEquip = false -- 是否穿戴了六星意识 
        local isAllAwarenessMaxLv = true

        for equipSite = XEnumConst.EQUIP.MAX_STAR_COUNT, 1, -1 do
            tempEquipId = XMVCA.XEquip:GetCharacterEquipId(characterId, equipSite) or tempEquipId
            if XTool.IsNumberValid(tempEquipId) then
                
                local isEquipCanAwake = false
                for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT, 1 do
                    if XMVCA.XEquip:CheckEquipCanAwake(tempEquipId, pos) 
                    and XMVCA.XEquip:GetResonanceBindCharacterId(tempEquipId, pos) == characterId then --检测当前位置是否仍可以超频，且共鸣绑定当前角色
                        isEquipCanAwake = true
                        break
                    end
                end

                if isEquipCanAwake and 
                XMVCA.XEquip:GetEquipAwakeNum(tempEquipId) < XEnumConst.EQUIP.MAX_AWAKE_COUNT -- 每个装备超频只能2个
                then -- 且共鸣是绑定当前角色
                    sixStarButNotAwakeEquipId = tempEquipId
                end

                if XMVCA.XEquip:GetEquipStarByEquipId(tempEquipId) >= XEnumConst.EQUIP.MAX_STAR_COUNT 
                and XMVCA.XEquip:GetEquipResonanceCount(tempEquipId) < XEnumConst.EQUIP.MAX_AWAKE_COUNT then -- 意识只能共鸣2个
                    sixStarButNotResonaceEquipId = tempEquipId
                end

                if XMVCA.XEquip:GetEquipStarByEquipId(tempEquipId) >= XEnumConst.EQUIP.MAX_STAR_COUNT then
                    isWearSixStarEquip = true
                end

                if not XMVCA.XEquip:IsMaxLevel(tempEquipId) then
                    isAllAwarenessMaxLv = false
                end
            end
        end
        isHaveCanResonanceEquip = XTool.IsNumberValid(sixStarButNotResonaceEquipId)

        if not XTool.IsNumberValid(tempEquipId) then
            XUiManager.TipError(CS.XTextManager.GetText("CharNeedWearSixStarEquip"))
            return
        end
        
        -- 武器不能超频 不检测
        if sixStarButNotAwakeEquipId then
            XLuaUiManager.Open("UiEquipDetailV2P6", sixStarButNotAwakeEquipId, nil, characterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING)
        elseif sixStarButNotResonaceEquipId then
            XLuaUiManager.Open("UiEquipDetailV2P6", sixStarButNotResonaceEquipId, nil, characterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
        elseif isWearSixStarEquip and not isHaveCanResonanceEquip then -- 穿了六星装备，且没有剩余的可共鸣意识。（既然走到了这个判断，说明这些意识都不是当前绑定角色的共鸣）
            if isAllAwarenessMaxLv then
                XUiManager.TipError(CS.XTextManager.GetText("ResonanceBindCharNotCur"))
            else
                XUiManager.TipError(CS.XTextManager.GetText("AwarenessNeedMaxLvAndResonance"))
            end

        else
            XUiManager.TipError(CS.XTextManager.GetText("CharNeedWearSixStarEquip2"))
        end
    end

    -- 肉鸽模拟经营
    function XFunctionalSkipManager:SkipToRogueSim()
        ---@type XRogueSimAgency
        local rogueSimAgency = XMVCA:GetAgency(ModuleId.XRogueSim)
        rogueSimAgency:ExOpenMainUi()
    end

    function XFunctionalSkipManager:SkipToDlcCasualGames()
        if not XMVCA.XDlcCasual:ExCheckInTime() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end
        
        XLuaUiManager.Open("UiDlcCasualGamesMain")
    end
    
    function XFunctionalSkipManager:SkipToUiKotodamaMain()
        if XMVCA.XKotodamaActivity:ExCheckInTime() then
            XMVCA.XKotodamaActivity:ExOpenMainUi()
        else
            XUiManager.TipText('CommonActivityNotStart')
        end
    end

    function XFunctionalSkipManager:SkipToFangKuai()
        if not XMVCA.XFangKuai:ExCheckInTime() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        XLuaUiManager.Open("UiFangKuaiMain")
    end

    function XFunctionalSkipManager:SkipToTemple()
        if not XMVCA.XTemple:ExCheckInTime() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Temple) then
            return
        end

        XLuaUiManager.Open("UiTempleMain")
    end

    function XFunctionalSkipManager:SkipToTemple2()
        if not XMVCA.XTemple2:ExCheckInTime() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end

        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Temple2) then
            return
        end

        XLuaUiManager.Open("UiTemple2Main")
    end

    --战双工艺
    function XFunctionalSkipManager:SkipToLinkCraftActivity()
        if XMVCA.XLinkCraftActivity:ExCheckInTime() then
            XMVCA.XLinkCraftActivity:ExOpenMainUi()
        else
            XUiManager.TipText('CommonActivityNotStart')
        end
    end

    -- 生日剧情
    function XFunctionalSkipManager:SkipToBirthdaySingleStory()
        XMVCA.XBirthdayPlot:OnEnterSingleStory(false)
    end

    -- 目标任务界面
    function XFunctionalSkipManager:SkipToUiNewPlayerTask()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Target) then
            return
        end
        XLuaUiManager.Open("UiNewPlayerTask")
    end

    -- 入门任务界面
    function XFunctionalSkipManager:SkipToUiNewbieTaskMain()
        XDataCenter.NewbieTaskManager.OpenMainUi()
    end

    -- v2.11春节累消
    function XFunctionalSkipManager:SkipToUiAccumulateExpendMain()
        XMVCA.XAccumulateExpend:OnEnterActivity()
    end

    -- 猫鼠游戏Dlc
    function XFunctionalSkipManager:SkipToDlcMultiMouseHunter()
        if not XMVCA.XDlcMultiMouseHunter:DlcCheckActivityInTime() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end
        
        XMVCA.XDlcMultiMouseHunter:OpenMainUi()
    end

    -- 打开签到面板
    function XFunctionalSkipManager.SkipToSignBanner(list)
        local param1 = (list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        local param2 = (list.CustomParams[2] ~= 0) and list.CustomParams[2] or nil

        if not param1 then
            return
        end

        XLuaUiManager.Open("UiSignBanner", param1, param2)
    end

    function XFunctionalSkipManager:SkipToDunhuang()
        XMVCA.XDunhuang:OpenMainUi()
    end
    
    function XFunctionalSkipManager:SkipToLineArithmetic()
        XMVCA.XLineArithmetic:OpenMainUi() 
    end

    function XFunctionalSkipManager:SkipToBossInshot()
        return XMVCA.XBossInshot:SkipToBossInshot()
    end

    -- 跳转数据演习
    function XFunctionalSkipManager:SkipToSimulateTrain()
        XMVCA.XSimulateTrain:SkipToSimulateTrain()
    end
    
    -- v2.14 机制玩法
    function XFunctionalSkipManager.SkipToMechanismActivity()
        if XMVCA.XMechanismActivity:ExCheckInTime() then
            XMVCA.XMechanismActivity:ExOpenMainUi()
        else
            XUiManager.TipText('CommonActivityNotStart')
        end
    end

    function XFunctionalSkipManager.SkipUiNewFubenChapterBfrt(skipData)
        XLuaUiManager.Open("UiNewFubenChapterBfrt", skipData.ParamId)
    end

    function XFunctionalSkipManager.SkipToWeekCardBuyTips(skipData)
        XLuaUiManager.Open("UiPurchase", 2, nil, 1, { Operation = XPurchaseConfigs.UiPurchaseCustomOperation.OpenCanRenewWeekCardBuyTip }) -- 打开采购礼包主页签限购子页签
        XDataCenter.PurchaseManager.SetWeekCardContinueBuyCache()
    end
    
    -- 肉鸽4
    function XFunctionalSkipManager:SkipToTheatre4()
        ---@type XTheatre4Agency
        local agency = XMVCA:GetAgency(ModuleId.XTheatre4)
        return agency:ExOnSkip()
    end

    --跳转日志上传
    function XFunctionalSkipManager.SkipToLogUpload()
        XMVCA.XLogUpload:OpenLogUploadUi()
    end
    
    -- 背包整理玩法
    function XFunctionalSkipManager.SkipToBagOrganizeActivity()
        XMVCA.XBagOrganizeActivity:ExOpenMainUi()
    end

    -- 超难关BOSS
    function XFunctionalSkipManager.SkipToSucceedBoss()
        return XMVCA.XSucceedBoss:EnterActivity()
    end

    -- 2048玩法
    function XFunctionalSkipManager.SkipToGame2048Activity()
        return XMVCA.XGame2048:ExOpenMainUi()
    end
    
    -- 进入空花
    function XFunctionalSkipManager.SkipToBigWorld()
        XMVCA.XBigWorldGamePlay:EnterGame()
    end
    
    -- 数织小游戏
    function XFunctionalSkipManager.SkipToNonogram()
        XMVCA.XNonogram:EnterActivity()
    end

    -- 首席打枪
    function XFunctionalSkipManager:SkipToFpsGame()
        XMVCA.XFpsGame:ExOpenMainUi()
    end

    -- 孤胆枪手
    function XFunctionalSkipManager.SkipToMaverick3(list)
        local activityId = (list and list.CustomParams[1] ~= 0) and list.CustomParams[1] or nil
        XMVCA.XMaverick3:ExOpenMainUi(activityId)
    end
    
    -- 轮椅手册独立界面
    function XFunctionalSkipManager.SkipToWheelchairManualMainUi(list)
        local activityId = list.CustomParams[1]
        local tabIndex= list.CustomParams[2]
        
        XMVCA.XWheelchairManual:OpenMainUi(activityId, tabIndex)
    end

    -- 跳转到新手任务合集
    function XFunctionalSkipManager.SkipToNewPlayerTaskCollection()
        local skipId = XMVCA.XUiMain:GetFirstCanSkipNewPlayerTaskCollectionSKipId()
        if XTool.IsNumberValid(skipId) then
            XFunctionManager.SkipInterface(skipId)
        end
    end
    
    function XFunctionalSkipManager.SkipToStageMemory()
        XMVCA.XStageMemory:OpenMain()
    end
    
    function XFunctionalSkipManager.SkipToReCallActivity()
        if not XMVCA.XReCallActivity:GetReCallIsOpen() then
            return
        end
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "ReCallAlreadyIn"), true)
        XLuaUiManager.Open("UiReCallActivity")
    end
    
    function XFunctionalSkipManager.SkipToGachaCanLiverMainUi(list)
        --- 活动Id可为空
        local activityId = list.CustomParams[1]
        
        XMVCA.XGachaCanLiver:OpenMainUi(activityId)
    end

    function XFunctionalSkipManager.SkipToMusicGameActivityMain(list)
        XMVCA.XMusicGameActivity:OpenUi()
    end
    
    function XFunctionalSkipManager.SkipToVersionGiftMainUi(list)
        XMVCA.XVersionGift:OpenUiMain()
    end

    -- 打牌
    function XFunctionalSkipManager:SkipToPcg()
        XMVCA.XPcg:ExOpenMainUi()
    end

    function XFunctionalSkipManager:SkipToInstrumentSimulator()
        XMVCA.XInstrumentSimulator:OpenUi()
    end

    -- 新矿区
    function XFunctionalSkipManager.SkipToScoreTower()
        XMVCA.XScoreTower:ExOpenMainUi()
    end

    -- 跳转到自选Gacha卡池
    function XFunctionalSkipManager.SkipToSelfChoiceGacha()
        local curActivityId = XDataCenter.GachaManager.GetCurGachaFashionSelfChoiceActivityId()
        if not XTool.IsNumberValid(curActivityId) then
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
            return
        end

        local curGachaId = XDataCenter.GachaManager.GetCurSelfChoiceSelectGachId()
        if not XTool.IsNumberValid(curGachaId) then
            XLuaUiManager.Open("UiGachaFashionSelfChoiceEntrance")
            return
        end

        ---@type XTableGachaFashionSelfChoiceResources
        local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[curGachaId]
        XFunctionManager.SkipInterface(gachaConfig.SkipId)
    end

    -- 跳转到自选Lotto卡池
    function XFunctionalSkipManager.SkipToSelfChoiceLotto()
        local lottoPrimaryId = XDataCenter.LottoManager.GetCurSelfChoiceLottoPrimaryId()
        if not XTool.IsNumberValid(lottoPrimaryId) then
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
            return
        end

        local selectedLottoId = XDataCenter.LottoManager.GetCurSelectedLottoIdByPrimartLottoId(lottoPrimaryId)
        if not XTool.IsNumberValid(selectedLottoId) then
            XLuaUiManager.Open("UiLottoFashionSelfChoiceEntrance")
            return
        end

        ---@type XTableLottoFashionSelfChoiceResources
        local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[selectedLottoId]
        XFunctionManager.SkipInterface(lottoResConfig.SkipId)
    end
    
    --endregion
    
    return XFunctionalSkipManager
end
