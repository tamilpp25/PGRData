XFubenFestivalActivityManagerCreator = function()
    local XFestivalChapter = require("XEntity/XFestival/XFestivalChapter") 
    local XFubenFestivalActivityManager = {}
    local FestivalChapters = {}
    XFubenFestivalActivityManager.StageFuben = 1    --战斗
    XFubenFestivalActivityManager.StageStory = 2    --剧情
    local StageId2ChapterIdDic = {}

    function XFubenFestivalActivityManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, XFubenFestivalActivityManager.RefreshChapterStages)
    end

    -- [初始化数据]
    function XFubenFestivalActivityManager.InitStageInfo()
        XFubenFestivalActivityManager.InitAllEntities()
    end

    function XFubenFestivalActivityManager.InitAllEntities()
        local festivalTemplates = XFestivalActivityConfig.GetFestivalsTemplates()
        for _, festivalTemplate in pairs(festivalTemplates or {}) do
            if not FestivalChapters[festivalTemplate.Id] then
                FestivalChapters[festivalTemplate.Id] = XFestivalChapter.New(festivalTemplate.Id)
            else
                FestivalChapters[festivalTemplate.Id]:RefreshStages()
            end
        end
    end

    function XFubenFestivalActivityManager.AddStageId2ChapterId(stageId, chapterId)
        StageId2ChapterIdDic[stageId] = chapterId
    end

    function XFubenFestivalActivityManager.GetChapterIdByStageId(stageId)
        return StageId2ChapterIdDic[stageId] or 0
    end

    -- [胜利]
    function XFubenFestivalActivityManager.ShowReward(winData)
        if not winData then return end
        XFubenFestivalActivityManager.RefreshStagePassedBySettleDatas(winData.SettleData)
        XLuaUiManager.Open("UiSettleWin", winData)
    end
    --====================
    --根据通关数据刷新章节关卡
    --====================
    function XFubenFestivalActivityManager.RefreshStagePassedBySettleDatas(settleData)
        if not settleData then return end
        for _, chapter in pairs(FestivalChapters) do
            local stage = chapter:GetStageByStageId(settleData.StageId)
            if stage then
                stage:SetIsPass(true)
                stage:AddPassCount(1)
                chapter:RefreshChapterStageInfos()
                XEventManager.DispatchEvent(XEventId.EVENT_ON_FESTIVAL_CHANGED)
                break
            end
        end
    end
    --====================
    --刷新章节关卡，用于外部条件变更时刷新章节关卡状态
    --====================
    function XFubenFestivalActivityManager.RefreshChapterStages()
        for _, chapter in pairs(FestivalChapters) do
            if chapter:GetIsOpen() then
                chapter:RefreshChapterStageInfos()
            end
        end
    end
    --====================
    --同步通关数据
    --@param response:服务器传来的通关数据
    --====================
    function XFubenFestivalActivityManager.RefreshStagePassed(response)
        for _, info in pairs(response.FestivalInfos or {}) do
            local chapter = FestivalChapters[info.Id]
            if chapter then
                for _, stageInfos in pairs(info.StageInfos or {}) do
                    local stage = chapter:GetStageByStageId(stageInfos.Id)
                    if stage then
                        stage:SetIsPass(true)
                        stage:SetPassCount(stageInfos.ChallengeCount)
                    end
                end
                chapter:RefreshChapterStageInfos()
            end
        end
    end
    --====================
    --根据节日ID获取节日活动的通关数据
    --@return1  通关总数
    --@return2  关卡总数
    --====================
    function XFubenFestivalActivityManager.GetFestivalProgress(festivalId)
        local chapter = FestivalChapters[festivalId]
        if not chapter then return 0, 0 end
        return chapter:GetStagePassCount(), chapter:GetStageTotalCount()
    end
    --====================
    --根据节日ID获取节日活动是否在开放时间内
    --@param festivalId:节日配置Id
    --====================
    function XFubenFestivalActivityManager.GetAvailableFestivals()
        local activityList = {}
        for _, chapter in pairs(FestivalChapters) do
            if chapter:GetIsOpen() then
                table.insert(activityList, {
                        Id = chapter:GetChapterId(),
                        Type = chapter:GetChapterType(),
                        Name = chapter:GetName(),
                        Icon = chapter:GetBannerBg(),
                    })
            end
        end
        return activityList
    end
    --====================
    --根据节日ID获取节日活动是否在开放时间内
    --@param festivalId:节日配置Id
    --====================
    function XFubenFestivalActivityManager.IsFestivalInActivity(festivalId)
        local chapter = FestivalChapters[festivalId]
        if chapter then
            return chapter:GetIsInTime()
        end
        return false
    end
    --====================
    --根据节日ID和关卡ID获取节日关卡对象
    --@param festivalId:节日配置Id
    --@param stageId:关卡表Id
    --====================
    function XFubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
        local chapter = FestivalChapters[festivalId]
        if not chapter then return end
        return chapter:GetStageByStageId(stageId)
    end
    --====================
    --根据节日ID和关卡ID获取节日章节对象
    --@param festivalId:节日配置Id
    --====================
    function XFubenFestivalActivityManager.GetFestivalChapterById(festivalId)
        return FestivalChapters[festivalId]
    end
    --====================
    --根据关卡ID获取关卡是否开放
    --@param stageId:关卡ID
    --====================   
    function XFubenFestivalActivityManager.CheckPassedByStageId(stageId)
        for _, chapter in pairs(FestivalChapters) do
            local stage = chapter:GetStageByStageId(stageId)
            if stage then
                return stage:GetIsPass()
            end
        end
        return false
    end
    -- [播放剧情]
    function XFubenFestivalActivityManager.FinishStoryRequest(stageId, cb)
        XNetwork.Call("EnterStoryRequest", { StageId = stageId }, function(res)
                cb = cb or function() end
                if res.Code == XCode.Success then
                    cb(res)
                else
                    XUiManager.TipCode(res.Code)
                end
            end)
    end

    function XFubenFestivalActivityManager.OnAsyncFestivalStages(response)
        if not response then return end
        XFubenFestivalActivityManager.RefreshStagePassed(response)
    end

    XFubenFestivalActivityManager.Init()
    return XFubenFestivalActivityManager
end

XRpc.NotifyFestivalData = function(response)
    XDataCenter.FubenFestivalActivityManager.OnAsyncFestivalStages(response)
end