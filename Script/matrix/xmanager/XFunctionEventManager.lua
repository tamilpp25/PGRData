XFunctionEventManagerCreator = function()
    local InMainUi = false
    local FunctionEvenState =    {
        IDLE = 1,
        PLAYING = 2,
        LOCK = 3
    }
    local DisableFunction = false     --功能屏蔽标记（调试模式时使用）
    local FunctionState = FunctionEvenState.IDLE
    
    local XFunctionEventManager = {}
    
    function XFunctionEventManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function()
            XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, XFunctionEventManager.HandlerPlayerLevelChange)
            XEventManager.AddEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, XFunctionEventManager.HandlerFightResult)
            XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_START, XFunctionEventManager.OnFunctionEventStart)
            XEventManager.AddEventListener(XEventId.EVENT_MEDAL_TIPSOVER, XFunctionEventManager.OnMedalTipsCompleted)
            XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, XFunctionEventManager.OnFunctionEventCompleted)
            XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_UP_ANIMATION_END, XFunctionEventManager.OnLevelUpAnimationEnd)
            XEventManager.AddEventListener(XEventId.EVENT_TASKFORCE_TIP_MISSION_END, XFunctionEventManager.OnTipMissionEnd)
            XEventManager.AddEventListener(XEventId.EVENT_AUTO_WINDOW_STOP, XFunctionEventManager.OnFunctionEventBreak)
            XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, XFunctionEventManager.OnBackToMain)
            XEventManager.AddEventListener(XEventId.EVENT_ARENA_RESULT_CLOSE, XFunctionEventManager.UnLockFunctionEvent)
            XEventManager.AddEventListener(XEventId.EVENT_SCORETITLE_NEW, XFunctionEventManager.GetNewCollection)
            XEventManager.AddEventListener(XEventId.EVENT_AUTO_WINDOW_END, XFunctionEventManager.OnHitFaceEnd)
            XEventManager.AddEventListener(XEventId.EVENT_MENTOR_AUTO_GRADUATE, XFunctionEventManager.HandlerAutoGraduate)
            XEventManager.AddEventListener(XEventId.EVENT_PLAYER_UNLOCK_BIRTHDAY_STORY, XFunctionEventManager.UnLockBirthdayStory)
            XEventManager.AddEventListener(XEventId.EVENT_REVIEW_ACTIVITY_HIT_FACE_END, XFunctionEventManager.OnReviewEnd)
            XEventManager.AddEventListener(XEventId.EVENT_WEB_RECHARGE_SUCCESS, XFunctionEventManager.OnWebPay)
            XEventManager.AddEventListener(XEventId.EVENT_WEB_RECHARGE_SUCCESS_END, XFunctionEventManager.OnWebPayEnd)
        end)
        DisableFunction = XFunctionEventManager.CheckFuncDisable()
    end

    --处理战斗结算
    function XFunctionEventManager.HandlerFightResult()
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --处理等级提升
    function XFunctionEventManager.HandlerPlayerLevelChange()
        XFunctionEventManager.OnFunctionEventValueChange()
    end
    
    --处理自动毕业
    function XFunctionEventManager.HandlerAutoGraduate()
        XFunctionEventManager.OnFunctionEventValueChange()
    end
    
    function XFunctionEventManager.OnFunctionEventValueChange()
        --第一次进入主界面并播放完成首次进入动画后在响应对应的方法
        if not XLoginManager.IsStartGuide() then
            return
        end

        XFunctionManager.CheckOpen()

        if FunctionState ~= FunctionEvenState.IDLE or DisableFunction then
            return
        end

        XDataCenter.CommunicationManager.SetCommunication()
        XDataCenter.CommunicationManager.SetFestivalCommunication()
        -- 当前是否在主界面(同时在最上层，避免像三周年签到自动弹窗界面 场景预览 双开UiMain)
        InMainUi = XLuaUiManager.IsUiShow("UiMain") and XLuaUiManager.GetTopUiName() == "UiMain"
        if XDeeplinkManager.InvokeDeeplink() then
            FunctionState = FunctionEvenState.PLAYING
        elseif XLoginManager.CheckLimitLogin() then --登录限制（答题）
            FunctionState = FunctionEvenState.PLAYING
        elseif XPlayer.HandlerPlayLevelUpAnimation() then --玩家等级提升
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.MentorSystemManager.CheckHaveGraduateReward() then --学员毕业
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.FubenManager.CheckHasNewHideStage() then --隐藏关卡开启
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.TaskForceManager.HandlerPlayTipMission() then --任务提示
            FunctionState = FunctionEvenState.PLAYING
        elseif XMVCA.XArena:CheckOpenActivityResultUi() then -- 竞技结算
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.MedalManager.ShowUnlockTips() then --勋章飘窗
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XDataCenter.GuildBossManager.CheckShowTip() then -- 公会boss击败
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XDataCenter.GuildManager.CheckGuildLevelUp() then -- 公会等级提升
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.CommunicationManager.ShowNextCommunication(XDataCenter.CommunicationManager.Type.Medal) then --勋章通讯
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.CommunicationManager.ShowNextCommunication(XDataCenter.CommunicationManager.Type.Normal) then --通常通讯
            FunctionState = FunctionEvenState.PLAYING
        elseif XFunctionManager.ShowOpenHint() then --系统开放
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.GuideManager.CheckGuideOpen() then -- 引导
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XDataCenter.CommunicationManager.ShowFestivalCommunication() then --节日通讯
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XDataCenter.PayManager.CheckShowWebTips() then -- 网页充值成功弹框
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XDataCenter.AutoWindowManager.CheckAutoWindow() then -- 打脸
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XMVCA.XDlcWorld:OnReconnectFight() then  --Dlc重连弹窗
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.MedalManager.CheckCanGetNewCollection() then -- 获得收藏品
            FunctionState = FunctionEvenState.PLAYING
        elseif XDataCenter.CommunicationManager.ShowBirthdayStory() then -- 生日通讯
            FunctionState = FunctionEvenState.PLAYING
        elseif InMainUi and XMVCA.XAnniversary:AutoOpenReview() then -- 回顾活动
            FunctionState = FunctionEvenState.PLAYING
        end

        if FunctionState ~= FunctionEvenState.PLAYING then
            XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_END)
        end
    end

    -- 交互开始
    function XFunctionEventManager.OnFunctionEventStart()
        FunctionState = FunctionEvenState.PLAYING
    end

    -- 交互完成
    function XFunctionEventManager.OnFunctionEventCompleted()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --回到主界面
    function XFunctionEventManager.OnBackToMain()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --飘窗结束
    function XFunctionEventManager.OnMedalTipsCompleted()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    -- 打脸中断
    function XFunctionEventManager.OnFunctionEventBreak()
        FunctionState = FunctionEvenState.IDLE
    end

    -- 打脸结束
    function XFunctionEventManager.OnHitFaceEnd()
        FunctionState = FunctionEvenState.IDLE
        -- if XDataCenter.GuideManager.CheckGuideOpen() then
        --     FunctionState = FunctionEvenState.PLAYING
        -- end
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    function XFunctionEventManager.OnReviewEnd()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end
    --完成
    function XFunctionEventManager.OnLevelUpAnimationEnd()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    -- 派遣队伍提升
    function XFunctionEventManager.OnTipMissionEnd()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --锁
    function XFunctionEventManager.LockFunctionEvent()
        FunctionState = FunctionEvenState.LOCK
    end

    --解锁
    function XFunctionEventManager.UnLockFunctionEvent()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --获得收藏品
    function XFunctionEventManager.GetNewCollection()
        --FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --解锁生日剧情
    function XFunctionEventManager.UnLockBirthdayStory()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --网页充值弹框
    function XFunctionEventManager.OnWebPay()
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    --网页充值弹框结束
    function XFunctionEventManager.OnWebPayEnd()
        FunctionState = FunctionEvenState.IDLE
        XFunctionEventManager.OnFunctionEventValueChange()
    end

    function XFunctionEventManager.IsPlaying()
        return FunctionState == FunctionEvenState.PLAYING
    end

    --检测功能开关
    function XFunctionEventManager.CheckFuncDisable()
        return XMain.IsDebug and XSaveTool.GetData(XPrefs.FunctionEventTrigger)
    end

    function XFunctionEventManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.FunctionEventTrigger, DisableFunction)
    end
    
    XFunctionEventManager.Init()
    return XFunctionEventManager
end