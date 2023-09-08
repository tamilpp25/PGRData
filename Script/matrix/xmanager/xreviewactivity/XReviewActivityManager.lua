
XReviewActivityManagerCreator = function()
    local XReviewActivityManager = {}
    local ActivityId
    local ReviewData
    local IsShown
    local Configs
    local METHOD_NAME = {
            GetReviewData = "ReviewDataInfoRequest",
            SetOpenReview = "SetReviewSlapFaceStateRequest",
            GetShareReward = "GetReviewShareRewardRequest"
        }
    
    function XReviewActivityManager.Init()
        ActivityId = 1
        ReviewData = nil
    end

    function XReviewActivityManager.SetConfig(activityConfigs)
        Configs = {}
        for index, config in pairs(activityConfigs) do
            Configs[index] = config
        end
    end

    function XReviewActivityManager.AutoOpenReview()
        if not ReviewData or IsShown then return false end
        XLuaUiManager.Open("UiReviewActivityAnniversary")
        return true
    end
    
    function XReviewActivityManager.RefreshReviewData(reviewData)
        XReviewActivityManager.RefreshActivityId(reviewData.ActivityId)
        XReviewActivityManager.SetReviewIsShown(reviewData.SlapFaceState)
        ReviewData = reviewData
    end

    function XReviewActivityManager.RefreshActivityId(activityId)
        ActivityId = activityId or ActivityId
    end

    function XReviewActivityManager.SetReviewIsShown(value)
        IsShown = value
    end
    
    function XReviewActivityManager.GetReviewIsShown()
        return IsShown and (XReviewActivityManager.GetActivityInTime())
    end
    
    function XReviewActivityManager.GetActivityId()
        return ActivityId
    end

    function XReviewActivityManager.GetShareRewardId()
        local cfg = Configs[XReviewActivityManager.GetActivityId()]
        return cfg and cfg.RewardId or 0
    end

    function XReviewActivityManager.GetActivityInTime()
        local cfg = Configs[XReviewActivityManager.GetActivityId()]
        if not cfg then return false end
        local startTime = cfg.StartTime
        local endTime = cfg.EndTime
        if not startTime or (startTime == 0) then
            return false
        end
        if not endTime or (endTime == 0) then
            return false
        end
        local now = XTime.GetServerNowTimestamp()
        return (startTime <= now) and (endTime > now)
    end
    
    function XReviewActivityManager.GetTotlePageNum()
        return XReviewActivityConfigs.GetTotlePageNum(ActivityId)
    end
    
    function XReviewActivityManager.GetName()
        return ReviewData and ReviewData.Name or XPlayer.Name
    end

    function XReviewActivityManager.GetTopAbilityCharacterId()
        return ReviewData and ReviewData.MaxAbilityCharacterId
    end

    function XReviewActivityManager.GetMaxAbilityCharacterEnName()
        local id = ReviewData and ReviewData.MaxAbilityCharacterId
        if not id then
            return ""
        end
        return XMVCA.XCharacter:GetCharacterEnName(id)
    end

    function XReviewActivityManager.GetMaxAbilityCharacterFullName()
        local id = ReviewData and ReviewData.MaxAbilityCharacterId
        if not id then
            return ""
        end
        return XMVCA.XCharacter:GetCharacterFullNameStr(id)
    end

    function XReviewActivityManager.GetMaxAbility()
        return ReviewData and ReviewData.MaxAbility or 0
    end

    function XReviewActivityManager.GetMaxTrustLv()
        return ReviewData and ReviewData.MaxTrustLv or 1
    end
    
    function XReviewActivityManager.GetMaxTrustLvCharacterCnt()
        return ReviewData and ReviewData.MaxTrustLvCharacterCnt or 1
    end

    function XReviewActivityManager.GetMaxTrustName()
        local maxTrustLv = XReviewActivityManager.GetMaxTrustLv()
        local trustCfg = XMVCA.XFavorability:GetTrustExpById(1011002) --这里角色写死表里的第一个，因为编写当时并没有等级和名称对应的关系，只能使用一个默认角色的好感度等级名称
        return trustCfg and trustCfg[maxTrustLv] and trustCfg[maxTrustLv].Name or XUiHelper.GetText("ReviewActivityDefaultFavorName")
    end

    function XReviewActivityManager.GetMaxTrustData()
        local characterCount = XReviewActivityManager.GetMaxTrustLvCharacterCnt()
        local trustName = XReviewActivityManager.GetMaxTrustName()
        return characterCount, trustName
    end

    function XReviewActivityManager.GetPartnerCount()
        return ReviewData and ReviewData.PartnerCount or 0
    end

    function XReviewActivityManager.GetCreateTime()
        local timeStamp = ReviewData and ReviewData.CreateTimeStamp
        if not timeStamp then return "" end
        return XTime.TimestampToGameDateTimeString(timeStamp, "yyyy-MM-dd")
    end

    function XReviewActivityManager.GetExistDayCount()
        return ReviewData and ReviewData.ExistDayCount or 0
    end

    function XReviewActivityManager.GetGuildName()
        return ReviewData and not string.IsNilOrEmpty(ReviewData.GuildName) and ReviewData.GuildName or XUiHelper.GetText("ReviewActivityNoGuild")
    end

    function XReviewActivityManager.GetMainLineStage()
        local stageId = ReviewData and ReviewData.MainLineStageId
        local stageOrder,stageName = XDataCenter.FubenManager.GetStageNameLevel(stageId)
        if stageOrder then
            return stageOrder,stageName
        else
            return CS.XTextManager.GetText("ReviewActivityNoGuild") , ""
        end
    end

    function XReviewActivityManager.GetMainLineChapterName()
        local chapterId = ReviewData and ReviewData.MainLineChapterId
        if not chapterId or (chapterId == 0) then chapterId = 1001 end
        local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterId)
        if not chapter then return "NoRecord" end
        return chapter.ChapterName
    end

    function XReviewActivityManager.GetAssignSchedule()
        local assignId = ReviewData and ReviewData.AssignSchedule or 0
        assignId = assignId > 0 and assignId or 2001
        local cfg = XFubenAssignConfigs.GetChapterTemplateById(assignId)
        return cfg and cfg.ChapterName or 1
    end

    function XReviewActivityManager.GetBfrtSchedule()
        local bfrtId = ReviewData and ReviewData.BfrtSchedule or 0
        bfrtId = bfrtId > 0 and bfrtId or 1001
        local cfg = XBfrtConfigs.GetBfrtChapterTemplates()[bfrtId]
        return cfg and cfg.ChapterEn
    end
    
    function XReviewActivityManager.GetPlayerId()
        return XPlayer.Id
    end

    function XReviewActivityManager.GetMedalInfos()
        --MedalInfo = { Id//勋章Id, Num//勋章编号, Time}
        return ReviewData and ReviewData.MedalInfos or {}
    end
    
    function XReviewActivityManager.GetMedalCount()
        return #XReviewActivityManager.GetMedalInfos()
    end

    function XReviewActivityManager.GetScoreTitlesIdList()
        local idList = ReviewData and ReviewData.ScoreTitleIdList or {}
        local resultList = {}
        local groupList = {}
        for _, id in pairs(idList) do
            local scoreTitle = XDataCenter.MedalManager.GetScoreTitleById(id)
            if not scoreTitle then goto continue end
            if scoreTitle.GroupId and scoreTitle.GroupId > 0 then
                groupList[scoreTitle.GroupId] = id
            else
                table.insert(resultList, id)
            end
            :: continue ::
        end
        for _, id in pairs(groupList or {}) do
            table.insert(resultList, id)
        end
        table.sort(resultList, function(idA, idB)
                    return idA > idB
                end)
        return resultList
    end
    
    function XReviewActivityManager.GetScoreTitleCount()
        return #XReviewActivityManager.GetScoreTitlesIdList()
    end

    function XReviewActivityManager.GetCharacterCnt()
        return ReviewData and ReviewData.CharacterCnt or 1
    end

    function XReviewActivityManager.GetDormCount()
        return ReviewData and ReviewData.DormCount or 0
    end

    function XReviewActivityManager.GetFurnitureCount()
        return ReviewData and ReviewData.FurnitureCount or 0
    end

    --今年登录游戏天数
    function XReviewActivityManager.GetLoginDayTimes(cb)
        return ReviewData and ReviewData.ReviewActivityStaticData and ReviewData.ReviewActivityStaticData.OnlineDayCount or 0
    end

    --今年消耗的血清总数
    function XReviewActivityManager.GetConsumeSerum(cb)
        return ReviewData and ReviewData.ReviewActivityStaticData and ReviewData.ReviewActivityStaticData.UseActionPointCount or 0
    end

    --今年消耗的螺母总数
    function XReviewActivityManager.GetConsumeNut(cb)
        return ReviewData and ReviewData.ReviewActivityStaticData and ReviewData.ReviewActivityStaticData.UseCoinTotalCount or 0
    end

    function XReviewActivityManager.GetReviewData(cb)
        if ReviewData then
            if cb then
                cb()
            end
            return
        end
        XNetwork.Call(METHOD_NAME.GetReviewData, { ActivityId = ActivityId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XReviewActivityManager.RefreshReviewData(res.ReviewData)
                if cb then
                    cb()
                end
            end)
    end
    
    function XReviewActivityManager.SetOpenReview(cb)
        if IsShown then
            if cb then
                cb(false)
            end
            return
        end
        XNetwork.Call(METHOD_NAME.SetOpenReview, { ActivityId = ActivityId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                IsShown = true
                if cb then
                    cb(true)
                end
            end)
    end
    
    function XReviewActivityManager.GetShareReward(cb)
        XNetwork.Call(METHOD_NAME.GetShareReward, { }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XUiManager.OpenUiObtain(res.RewardList)
                if cb then
                    cb()
                end
            end)
    end
    
    
    XReviewActivityManager.Init()

    return XReviewActivityManager
end

XRpc.NotifyReviewData = function(data)
    XDataCenter.ReviewActivityManager.RefreshReviewData(data.ReviewActivityData)
end

XRpc.NotifyReviewSlapFaceState = function(data)
    XDataCenter.ReviewActivityManager.SetReviewIsShown(data.SlapFaceState)
end

XRpc.NotifyReviewConfig = function(data)
    XDataCenter.ReviewActivityManager.SetConfig(data.ReviewActivityConfigList)
end