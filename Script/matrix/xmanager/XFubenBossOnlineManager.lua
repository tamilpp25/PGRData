local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
XFubenBossOnlineManagerCreator = function()

    local XFubenBossOnlineManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.BossOnline)

    XFubenBossOnlineManager.OnlineBossDifficultLevel = {
        SIMPLE = 1,
        NORMAL = 2,
        HARD = 3,
        HELL = 4,
        NightMare = 5,
    }

    local NORMAL_BOSS_COUNT = 4
    local ACTIVITY_BOSS_COUNT = 5

    local METHOD_NAME = {
        GetActivityBossDataRequest = "GetActivityBossDataRequest"
    }


    local IsActivity
    local BossDataList
    local OnlineLelfTime --联机Boss刷新时间
    local OnlineBeginTime
    local OnlineBossSectionTemplates = {}
    local OnlineBossChapterTemplates = {}
    local NormalChapterId = CS.XGame.Config:GetInt("OnlineBossNormalChapterId")
    local ActivityChapterId = CS.XGame.Config:GetInt("OnlineBossActivityChapterId")
    local LastRequestTime = 0
    local RequestInterval = 30

    function XFubenBossOnlineManager.Init()
        OnlineBossSectionTemplates = XFubenBossOnlineConfig.GetSectionTemplates()
        OnlineBossChapterTemplates = XFubenBossOnlineConfig.GetChapterTemplates()
    end

    function XFubenBossOnlineManager.GetBossOnlineChapters()
        if not BossDataList then
            return {}
        end
        local list = {}
        local chapterId = IsActivity and ActivityChapterId or NormalChapterId
        for k, v in pairs(OnlineBossChapterTemplates) do
            if k == chapterId then
                table.insert(list, v)
            end
        end
        table.sort(list, function(a, b)
            return a.Id < b.Id
        end)
        return list
    end

    function XFubenBossOnlineManager.UpdateStageUnlock(stageId, diff)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        stageInfo.Unlock = false
        stageInfo.IsOpen = false
        if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
            return
        end

        if diff > 1 then
            for _, v in pairs(OnlineBossSectionTemplates) do
                if v.DifficultType == diff - 1 then
                    local preStageInfo = XDataCenter.FubenManager.GetStageInfo(v.StageId)
                    if preStageInfo.Passed then
                        stageInfo.Unlock = true
                        stageInfo.IsOpen = true
                        return
                    end
                end
            end
        else
            stageInfo.Unlock = true
            stageInfo.IsOpen = true
        end
    end

    function XFubenBossOnlineManager.InitStageInfo()
        for _, sectionCfg in pairs(OnlineBossSectionTemplates) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(sectionCfg.StageId)
            stageInfo.BossSectionId = sectionCfg.Id
            stageInfo.Type = XDataCenter.FubenManager.StageType.BossOnline
            stageInfo.Difficult = sectionCfg.DifficultType
            XFubenBossOnlineManager.UpdateStageUnlock(sectionCfg.StageId, sectionCfg.DifficultType)
        end
    end

    function XFubenBossOnlineManager.CheckAutoExitFight(stageId)
        return true
    end

    function XFubenBossOnlineManager.OpenFightLoading(stageId)
        XLuaUiManager.Open("UiOnLineLoading")
    end

    function XFubenBossOnlineManager.CloseFightLoading()
        XLuaUiManager.Remove("UiOnLineLoading")
        XLuaUiManager.Remove("UiOnLineLoadingCute")
    end

    function XFubenBossOnlineManager.ShowReward(winData)
        -- XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SHOW_REWARD, winData)
        -- XLuaUiManager.Open("UiSettleWin", winData)
        if XDataCenter.FubenManager.CheckHasFlopReward(winData) then
            XLuaUiManager.Open("UiFubenFlopReward", function()
                XLuaUiManager.PopThenOpen("UiMultiplayerFightGrade", function()
                    XLuaUiManager.PopThenOpen("UiSettleWin", winData)
                end)
            end, winData)
            if XDataCenter.FubenManager.CheckHasFlopReward(winData, true) and not XDataCenter.FubenManager.CheckCanFlop(winData.StageId) then
                XUiManager.TipText("BossOnlineConsumeFinish", XUiManager.UiTipType.Success)
            end
        else
            XLuaUiManager.Open("UiMultiplayerFightGrade", function()
                XLuaUiManager.PopThenOpen("UiSettleWin", winData)
            end)
        end
    end

    function XFubenBossOnlineManager.CheckIsInvade()
        local key = "OnlineBossBeginTime_" .. XPlayer.Id
        local time = XSaveTool.GetData(key)
        return OnlineBeginTime == time
    end

    function XFubenBossOnlineManager.RecordInvade()
        local key = "OnlineBossBeginTime_" .. XPlayer.Id
        XSaveTool.SaveData(key, OnlineBeginTime)
    end

    function XFubenBossOnlineManager.GetActOnlineBossSectionForDiff(difficult)
        if not BossDataList then
            return
        end

        for _, v in pairs(BossDataList) do
            if v.DifficultyType == difficult then
                return v
            end
        end
    end

    function XFubenBossOnlineManager.GetStageIdByDiff(difficult)
        for _, v in pairs(OnlineBossSectionTemplates) do
            if v.DifficultType == difficult then
                return v.StageId
            end
        end
        return 0
    end

    function XFubenBossOnlineManager.GetActOnlineBossSectionById(secitonId, useLastTemplate)
        if useLastTemplate then
            local tmp = OnlineBossSectionTemplates[secitonId]
            return OnlineBossSectionTemplates[tmp.LastSectionId]
        end
        return OnlineBossSectionTemplates[secitonId]
    end

    function XFubenBossOnlineManager.GetBossDataList()
        return BossDataList
    end

    function XFubenBossOnlineManager.GetIsActivity()
        return IsActivity
    end

    function XFubenBossOnlineManager.CheckBossDataCorrect()
        if not BossDataList then
            XLog.Error("XFubenBossOnlineManager.CheckBossDataCorrect 错误, 联网获取的Boss信息列表为空")
            return false
        end

        local count = IsActivity and ACTIVITY_BOSS_COUNT or NORMAL_BOSS_COUNT
        for diff = 1, count, 1 do
            local correct = false
            for _, bossInfo in pairs(BossDataList) do
                if bossInfo.DifficultyType == diff then
                    correct = true
                    break
                end
            end
            if not correct then
                XLog.Error("XFubenBossOnlineManager.CheckBossDataCorrect错误, Boss无法根据DifficultyType找到  DifficultyType:" .. diff)
                return false
            end
        end

        for _, v in pairs(BossDataList) do
            if not OnlineBossSectionTemplates[v.BossId] then
                XLog.Error("XFubenBossOnlineManager.CheckBossDataCorrect错误, 无法根据BossId：" .. v.BossId .. "在" .. TABLE_FUBEN_ONLINEBOSS_SECTION .. "表中找到数据")
                return false
            end
        end
        return true
    end

    function XFubenBossOnlineManager.OnRefreshBossData(data)
        local oldBeginTime = OnlineBeginTime
        IsActivity = data.Activity == 1
        OnlineBeginTime = data.BeginTime
        OnlineLelfTime = data.LeftTime + XTime.GetServerNowTimestamp()
        BossDataList = data.BossDataList
        if oldBeginTime == OnlineBeginTime then
            XEventManager.DispatchEvent(XEventId.EVENT_ONLINEBOSS_UPDATE)
        else
            XEventManager.DispatchEvent(XEventId.EVENT_ONLINEBOSS_REFRESH)
        end
    end

    -- 获取联机BOSS信息
    function XFubenBossOnlineManager.RequsetGetBossDataList(cb)
        LastRequestTime = XTime.GetServerNowTimestamp()
        XNetwork.Call(METHOD_NAME.GetActivityBossDataRequest, nil, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end
            XFubenBossOnlineManager.OnRefreshBossData(reply)
            if cb then
                cb()
            end
        end)
    end

    function XFubenBossOnlineManager.RefreshBossData(cb)
        if not XFubenBossOnlineManager.BossDataList or
        XFubenBossOnlineManager.CheckOnlineBossTimeOut() or
        XTime.GetServerNowTimestamp() - LastRequestTime > RequestInterval then
            XFubenBossOnlineManager.RequsetGetBossDataList(cb)
        else
            if cb then
                cb()
            end
        end
    end

    function XFubenBossOnlineManager.GetOnlineBossUpdateTime()
        return OnlineLelfTime
    end

    --检测boss是否已经更新
    function XFubenBossOnlineManager.CheckOnlineBossTimeOut()
        if OnlineLelfTime == nil then
            return false
        end
        local curTime = XTime.GetServerNowTimestamp()
        local offset = OnlineLelfTime - curTime
        return offset <= 0
    end

    --检测前置条件
    function XFubenBossOnlineManager.CheckOnlineBossUnlock(diffcult, needTips)
        if not BossDataList then
            return false
        end

        local bossData = XFubenBossOnlineManager.GetActOnlineBossSectionForDiff(diffcult)
        if not bossData then
            return false
        end

        local boSection = XFubenBossOnlineManager.GetActOnlineBossSectionById(bossData.BossId)
        if not boSection then
            return false
        end

        local stageCfg = XDataCenter.FubenManager.GetStageCfg(boSection.StageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageCfg.StageId)

        if needTips then
            if not stageInfo.Unlock then
                XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(stageCfg.StageId, CS.XTextManager.GetText("BossOnlineNotUnlock")))
            end
        end

        return stageInfo.Unlock
    end

    function XFubenBossOnlineManager.GetFlopConsumeItemCount()
        local template
        for _, v in pairs(OnlineBossSectionTemplates) do
            template = v
            break
        end
        if not template then
            return 0
        end
        local itemId = XDataCenter.FubenManager.GetFlopConsumeItemId(template.StageId)
        local item = XDataCenter.ItemManager.GetItem(itemId)
        return item and item:GetCount() or 0
    end

    function XFubenBossOnlineManager.OpenBossOnlineUi(selectIdx)
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.BossOnline) then
            return
        end
        XFubenBossOnlineManager.RefreshBossData(function()
            if not XDataCenter.FubenBossOnlineManager.CheckBossDataCorrect() then
                XLuaUiManager.RunMain()
                return
            end
            local isActivity = XFubenBossOnlineManager.GetIsActivity()
            if isActivity and XFubenBossOnlineManager.CheckIsInvade() then
                XLuaUiManager.Open("UiOnlineBossActivity", selectIdx)
            else
                XLuaUiManager.Open("UiOnlineBoss", selectIdx)
            end
        end)
    end

    function XFubenBossOnlineManager.OpenBossOnlineUiWithoutCheck(selectIdx)
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.BossOnline) then
            return
        end
        local isActivity = XFubenBossOnlineManager.GetIsActivity()
        if isActivity and XFubenBossOnlineManager.CheckIsInvade() then
            XLuaUiManager.Open("UiOnlineBossActivity", selectIdx)
        else
            XLuaUiManager.Open("UiOnlineBoss", selectIdx)
        end
    end

    function XFubenBossOnlineManager.PopOverTips()
        if XFubenBossOnlineManager.GetIsActivity() then
            XUiManager.TipText("ActivityBossOnlineOver")
        else
            XUiManager.TipText("BossOnlineOver")
        end
    end

    function XFubenBossOnlineManager.OnActivityEnd()
        BossDataList = nil
        XFubenBossOnlineManager.RequsetGetBossDataList()
        XEventManager.DispatchEvent(XEventId.EVENT_ONLINE_BOSS_REFRESH)
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        if XFubenBossOnlineManager.TryPopOverTips() then
            XLuaUiManager.RunMain()
        end
    end

    function XFubenBossOnlineManager.TryPopOverTips()
        if XLuaUiManager.IsUiShow("UiOnlineBoss") or XLuaUiManager.IsUiShow("UiOnlineBossActivity") then
            XFubenBossOnlineManager.PopOverTips()
            return true
        end
        return false
    end

    ------------------副本入口扩展 start-------------------------
    function XFubenBossOnlineManager:ExGetChapterType()
        return XFubenConfigs.ChapterType.BossOnline
    end

    -- 获取进度提示
    function XFubenBossOnlineManager:ExGetProgressTip() 
        local strProgress = ""
        if self:ExGetIsLocked() then
           
        end

        return strProgress
    end

    -- 获取倒计时
    function XFubenBossOnlineManager:ExGetRunningTimeStr()
        local timeText = ""
        if XFubenBossOnlineManager.GetIsActivity() then
            local endtime = XFubenBossOnlineManager.GetOnlineBossUpdateTime()
            local time = XTime.GetServerNowTimestamp()

            local shopStr = CsXTextManager.GetText("ActivityBranchShopLeftTime")
            local fightStr = CsXTextManager.GetText("ActivityBranchFightLeftTime")

            if endtime <= time and time <= endtime then
                local leftTime = endtime - time
                if leftTime > 0 then
                    timeText = shopStr .. XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                else
                    if self.OnActivityEnd then
                        self:OnActivityEnd()
                    end
                end
            else
                local leftTime = endtime - time
                if leftTime > 0 then
                    timeText = fightStr .. XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                else
                    if self.OnActivityEnd then
                        self:OnActivityEnd()
                    end
                end
            end
        end

        return timeText
    end

    function XFubenBossOnlineManager:ExOpenMainUi()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivityOnlineBoss) then
            return
        end

        --分包资源检查
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.BossOnline) then
            return
        end

        -- 先检查更新再开界面
        XFubenBossOnlineManager.RefreshBossData(
            function()
                if not XFubenBossOnlineManager.CheckBossDataCorrect() then
                    return
                end
                XFubenBossOnlineManager.OpenBossOnlineUiWithoutCheck()
            end
        )
    end
    
    ------------------副本入口扩展 end-------------------------

    XFubenBossOnlineManager.Init()
    return XFubenBossOnlineManager
end

XRpc.NotifyBossOnlineActivityStatus = function(data)
    XDataCenter.FubenBossOnlineManager.OnRefreshBossData(data)
end