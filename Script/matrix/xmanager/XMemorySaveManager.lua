XMemorySaveManagerCreator = function ()

    local XMemorySaveManager = {}

    local REQUEST_FUNC_NAME = {
        MemorySaveChapterAwardRequest = "MemorySaveChapterAwardRequest",
    }

--region 活动入口
    local _ActivityId = XMemorySaveConfig.GetDefaultActivityId() --当前开放Id
    local _ActivityEnd = false -- 活动是否结束
    local _ActivityInfo = {}
    local _ScrollViewPosX = {}
    local _SelectIndex = nil
    local _PlayerRewardData = {}
    local _StagePrefabKey = "UiMemorySaveYishi" -- 关卡预制体key
    local _PassStageMap = {} -- 已经通过的stage


    function XMemorySaveManager.GetActivityName()
        return XMemorySaveConfig.GetActivityName(_ActivityId)
    end

    function XMemorySaveManager.UpdateScrollViewPos(tabIndex, pos)
        _ScrollViewPosX[tabIndex] = pos
    end

    function XMemorySaveManager.GetScrollViewPos(tabIndex)
        return _ScrollViewPosX[tabIndex]
    end

    function XMemorySaveManager.UpdateSelectIndex(tabIndex)
        _SelectIndex = tabIndex
    end

    function XMemorySaveManager.GetSelectIndex()
        return _SelectIndex
    end

    function XMemorySaveManager.GetActivityBanner()
        return XMemorySaveConfig.GetActivityBanner(_ActivityId)
    end

    --#region 重写XFubenManager 方法
    function XMemorySaveManager.InitStageInfo()
        local chapterIds = XMemorySaveManager.GetActivityChapterIds()
        for _, chapterid in ipairs(chapterIds or {}) do
            local stageIds = XMemorySaveManager.GetChapterStageIds(chapterid)
            for _, stageId in ipairs(stageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.MemorySave
                end
            end
        end
        XMemorySaveManager.RegisterEditBattleProxy()
    end

    -- 重载XFubenManager.FinishFight 更新stageinfo
    function XMemorySaveManager.FinishFight(settle)
        XDataCenter.FubenManager.FinishFight(settle)
        if settle.IsWin then
            table.insert(_ActivityInfo.FinishStageIds, settle.StageId)
        end
        XMemorySaveManager.UpdateStageInfo()
    end

    function XMemorySaveManager.CheckUnlockByStageId(stageId)
        return XMemorySaveManager.GetStageIsOpen(stageId)
    end

    function XMemorySaveManager.CheckPassedByStageId(stageId)
        return XMemorySaveManager.GetPassStageById(stageId)
    end

    --#endregion

    -- 注册出战代理界面
    function XMemorySaveManager.RegisterEditBattleProxy()
        XUiNewRoomSingleProxy.RegisterProxy(
                XDataCenter.FubenManager.StageType.MemorySave,
                require("XUi/XUiMemorySave/Proxy/XUiMemorySaveNewRoomSingle")
        )
    end

    -- 活动是否开始
    function XMemorySaveManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end

        if _ActivityEnd then
            return false
        end
        
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XMemorySaveManager.GetActivityStartTime()
        local endTime = XMemorySaveManager.GetActivityEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XMemorySaveManager.GetActivityChapters()
        if not XMemorySaveManager.IsOpen() then
            return
        end
        local chapters = {}
        table.insert(chapters, {
            Id = _ActivityId,
            Type = XDataCenter.FubenManager.ChapterType.MemorySave,
            BannerBg = XMemorySaveManager.GetActivityBanner(),
            Name = XMemorySaveManager.GetActivityName()
        })
        return chapters
    end

    function XMemorySaveManager.GetActivityStartTime()
        return XMemorySaveConfig.GetActivityStartTime(_ActivityId) or 0
    end

    function XMemorySaveManager.GetActivityEndTime()
        return XMemorySaveConfig.GetActivityEndTime(_ActivityId) or 0
    end

    function XMemorySaveManager.GetActivityChapterIds()
        return XMemorySaveConfig.GetActivityChapterIds(_ActivityId) or {}
    end

    -- 获取当前章节已通关的小节数量
    function XMemorySaveManager.GetChapterPassed(chapterId)
        local pass = 0
        local stageIds = XMemorySaveManager.GetChapterStageIds(chapterId)
        for idx, stageId in ipairs(stageIds) do
            local passed = XMemorySaveManager.GetPassStageById(stageId)
            if passed then
                pass = pass + 1
            end
        end
        return pass
    end

    function XMemorySaveManager.MemorySaveChapterAwardRequest(cb, chapterId, index)
        local req = {ChapterId = chapterId, RewardIndex = index}
        XNetwork.Call(REQUEST_FUNC_NAME.MemorySaveChapterAwardRequest, req, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb(res.AwardList)
            end
        end)
    end

    -- 总体进度
    function XMemorySaveManager.GetActivityProgress()
        local passedStages = XTool.GetTableCount(_PassStageMap) -- 已经通关的关卡数
        local openedStages = 0 -- 当前已经开放的关卡数
        local chapterIds = XMemorySaveManager.GetActivityChapterIds()
        for _, chapterId in ipairs(chapterIds) do
            if XMemorySaveManager.IsChapterOpen(chapterId) then
                local stageIds = XMemorySaveManager.GetChapterStageIds(chapterId)
                openedStages = openedStages + #stageIds
            end
        end
        return CS.XTextManager.GetText("BossSingleProgress", passedStages, openedStages)
    end

    -- 章节进度
    function XMemorySaveManager.GetCurChapterProgress(chapterId)
        local stageIds =XMemorySaveManager.GetChapterStageIds(chapterId)
        local total = #stageIds
        if total <= 0 then
            XLog.Error("XMemorySaveManager.GetCurChapterProgress Div Zero")
            return
        end
        local pass = 0
        for idx, stageId in ipairs(stageIds) do
            local passed = XMemorySaveManager.GetPassStageById(stageId)
            if passed then
                pass = pass + 1
            end
        end
        return string.format("%d%%", (pass/total) * 100)
    end

    function XMemorySaveManager.NotifyMemorySaveInfo(data)
        --[[
            data 组成：
            ActivityNo 当前开放的活动id
            FinishStageIds = []     已经完成的关卡且领取首次通关的关卡id
            RewardChapterIds = []   已经领取奖励的信息，[{"ChapterId":1111, "RewardIndexList":[]}, ....]
        ]]--
        _ActivityEnd = data.ActivityNo == 0 -- 活动id为0, 活动已经结束
        if _ActivityEnd then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MEMORYSAVE_ACTIVITY_END) -- 通知主界面的活动结束
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.MemorySave) -- 通知战前准备房间活动重制
            return
        end
        _ActivityInfo = {
            FinishStageIds = data.FinishStageIds or {},
            RewardChapterIds = data.RewardChapterIds or {},
        }
        XMemorySaveManager.UpdateStageInfo()
    end

    function XMemorySaveManager.UpdateStageInfo()
        for _, info in pairs(_ActivityInfo.RewardChapterIds) do
            local chapterId = info.ChapterId
            local rewardIndex = info.RewardIndexList
            for _, value in ipairs(rewardIndex) do
                if XTool.IsNumberValid(value) then
                    XMemorySaveManager.SetRewardIsGet(chapterId, value)
                end
            end
        end
        for _, stageId in ipairs(_ActivityInfo.FinishStageIds) do
            _PassStageMap[stageId] = true
        end
    end

    function XMemorySaveManager.SetRewardIsGet(chapterId, index)
        if not _PlayerRewardData[chapterId] then
            _PlayerRewardData[chapterId] = {}
        end
        _PlayerRewardData[chapterId][index] = true
    end

    function XMemorySaveManager.GetPassStageById(stageId)
        return _PassStageMap[stageId]
    end

    function XMemorySaveManager.GetStageIsOpen(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.PreStageId then
            for _, _StageId in ipairs(stageCfg.PreStageId) do
                if not XMemorySaveManager.GetPassStageById(_StageId) then
                    return false -- 有前置关卡未通过
                end
            end
            return true
        end
        return true -- 没有前置关卡
    end

    function XMemorySaveManager.GetFinishStagesIds()
        if not _ActivityInfo then
            return
        end
        return _ActivityInfo.FinishStageIds
    end

    -- 获取当前已经开放的章节id
    function XMemorySaveManager.GetCurOpenChapterId()
        local openId = {}
        for index, chapterId in ipairs(XMemorySaveManager.GetActivityChapterIds()) do
            if XMemorySaveManager.IsChapterOpen(chapterId) then
                openId[index] = chapterId
            end
        end
        return openId
    end

    -- 是否是首次进入副本
    function XMemorySaveManager.IsFirstEntry(key)
        local key = string.format( "XMemorySaveManager_%s_%s_MemorySave", XPlayer.Id, key)
        return not XSaveTool.GetData(key)
    end

    -- 进入副本后设置标记
    function XMemorySaveManager.SetFirstEntryFlag(key)
        local key = string.format( "XMemorySaveManager_%s_%s_MemorySave", XPlayer.Id, key)
        XSaveTool.SaveData(key, "has played")
    end

    -- 是否有新章节解锁
    function XMemorySaveManager.IsNewChapterUnlock()
        local pluginIds = XAreaWarConfigs.GetAllPluginIds()
        for _, pluginId in pairs(pluginIds) do
            if XAreaWarManager.IsPluginCanUnlock(pluginId) then
                return true
            end
        end
        return false
    end

    -- 奖励是否已经领取
    function XMemorySaveManager.IsTreasureGet(chapterId, index)
        local chapterRewards = _PlayerRewardData[chapterId]
        if not chapterRewards then
            return false
        end
        return chapterRewards[index]
    end

    -- 当前章节下是否有奖励完成
    function XMemorySaveManager.IsTreasureUnlock(chapterId)
        local rewardIds = XMemorySaveConfig.GetChapterRewardIds(chapterId)
        for idx, rewardId in ipairs(rewardIds) do
            -- 关卡奖励条件完成，并且未领取
            if XMemorySaveManager.IsFinishReward(chapterId, idx) and not XMemorySaveManager.IsTreasureGet(chapterId, idx) then
                return true
            end
        end
        return false
    end
    -- 关卡奖励条件完成
    function XMemorySaveManager.IsFinishReward(chapterId, idx)
        local passed = XMemorySaveManager.GetChapterPassed(chapterId) -- 已经通关数
        local require = XMemorySaveConfig.GetChapterRequirePass(chapterId, idx) -- 需要的通关数
        return passed > 0 and passed >= require
    end

    -- 活动结束回调
    function XMemorySaveManager.OnActivityEnd()
        if XMemorySaveManager.IsOpen() then
            return false
        end
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") or XLuaUiManager.IsUiLoad("UiSettleLose") or
                XLuaUiManager.IsUiLoad("UiSettleWin")
        then
            return false
        end
        -- 防止UI界面动画开启被打断
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.RunMain()
            XUiManager.TipText("PicCompositionTimeQver")
        end, 1000)
        return true
    end

    function XMemorySaveManager.EnterUiMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MemorySave) then
            return
        end
        if not XMemorySaveManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        XLuaUiManager.Open("UiMemorySave")
    end
    
    --===========================================================================
     ---@desc 返回当前已开放章节有没有未完成关卡
     ---@return {bool} 是否有已开放但未完成的关卡
    --===========================================================================
    function XMemorySaveManager.IsFinishCurOpened()
        if not XMemorySaveManager.IsOpen() then
            return false
        end
        local openChapterIds = XMemorySaveManager.GetCurOpenChapterId()
        for idx, chapterId in ipairs(openChapterIds or {}) do
            local stageIds = XMemorySaveConfig.GetChapterStageIds(chapterId)
            for _, stageId in ipairs(stageIds) do
                if not XMemorySaveManager.GetPassStageById(stageId) then
                    return false
                end
            end 
        end
        return true
    end

--endregion

--region 章节相关
    function XMemorySaveManager.IsChapterOpen(chapterId)
        return XMemorySaveConfig.IsChapterOpen(chapterId)
    end

    function XMemorySaveManager.GetChapterName(chapterId)
        return XMemorySaveConfig.GetChapterName(chapterId)
    end

    function XMemorySaveManager.GetChapterBannerBg(chapterId)
        return XMemorySaveConfig.GetChapterBannerBg(chapterId)
    end

    function XMemorySaveManager.GetChapterBtnBg(chapterId)
        return XMemorySaveConfig.GetChapterBtnBg(chapterId)
    end

    function XMemorySaveManager.GetStageBg(chapterId)
        return XMemorySaveConfig.GetStageBg(chapterId)
    end

    function XMemorySaveManager.GetChapterStageIds(chapterId)
        return XMemorySaveConfig.GetChapterStageIds(chapterId)
    end

    function XMemorySaveManager.GetChapterStageConfig(chapterId)
        return {
            ChapterId = chapterId,
            StageBg = XMemorySaveManager.GetStageBg(chapterId),
        }
    end

    function XMemorySaveManager.GetStagePrefabPath()
        return XUiConfigs.GetComponentUrl(_StagePrefabKey)
    end

    -- 当前章节是否完成
    function XMemorySaveManager.IsFinishCurChapter(chapterId)
        local pass = XMemorySaveManager.GetChapterPassed(chapterId)
        local total = #(XMemorySaveManager.GetChapterStageIds(chapterId))
        return pass == total
    end

--endregion

    return XMemorySaveManager
end

XRpc.NotifyMemorySaveInfo = function (data)
    XDataCenter.MemorySaveManager.NotifyMemorySaveInfo(data)
end