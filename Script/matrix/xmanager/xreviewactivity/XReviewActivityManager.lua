
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
        local isOpen,desc=XMVCA.XAnniversary:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.Review)
        if isOpen then
            XLuaUiManager.Open("UiAnniversaryReview")
            return true
        end
        return false
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
        local stageOrder,stageName = nil,nil
        if XTool.IsNumberValid(stageId) then
            stageOrder,stageName = XDataCenter.FubenManager.GetStageNameLevel(stageId)
        end
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
        return cfg and cfg.ChapterEn or CS.XTextManager.GetText("ReviewActivityNoGuild")
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
                XReviewActivityManager.RefreshReviewData(res.ReviewActivityData)
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
                if ReviewData then
                    ReviewData.ShareRewardState=true
                end
                XUiManager.OpenUiObtain(res.RewardList)
                if cb then
                    cb()
                end
            end)
    end
    
    --region 2.9
    function XReviewActivityManager.GetMaxFightCountCharaFullNameAndFightCount()
        if ReviewData then
            if ReviewData.ReviewActivityStaticData  and ReviewData.ReviewActivityStaticData.ReviewCharacterData then
                local maxCount=-1
                local charaId=nil
                for i, v in pairs(ReviewData.ReviewActivityStaticData.ReviewCharacterData) do
                    if v.FightCount>maxCount then
                        maxCount=v.FightCount
                        charaId=v.CharacterId
                    elseif v.FightCount==maxCount then
                        --取好感度高的
                        local newCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(v.CharacterId)
                        local oldCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(charaId)
                        if newCharFavorabilityLv >oldCharFavorabilityLv then
                            charaId=v.CharacterId
                        elseif newCharFavorabilityLv==oldCharFavorabilityLv then
                            --取优先级高的
                            if XMVCA.XCharacter:GetCharacterPriority(v.CharacterId) >XMVCA.XCharacter:GetCharacterPriority(charaId) then
                                charaId=v.CharacterId
                            end    
                            
                        end
                    end                    
                end
                if XTool.IsNumberValid(charaId) and maxCount>0 then
                    return XMVCA.XCharacter:GetCharacterFullNameStr(charaId),maxCount
                end
                return CS.XTextManager.GetText("ReviewActivityNoGuild"),false
            end
        end
    end

    function XReviewActivityManager.GetDormFondleMoodCountCharaFullNameAndFightCount()
        if ReviewData then
            if ReviewData.ReviewActivityStaticData  and ReviewData.ReviewActivityStaticData.ReviewCharacterData then
                local maxCount=-1
                local charaId=nil
                for i, v in pairs(ReviewData.ReviewActivityStaticData.ReviewCharacterData) do
                    if v.DormFondleMoodCount>maxCount then
                        maxCount=v.DormFondleMoodCount
                        charaId=v.CharacterId
                    elseif v.DormFondleMoodCount==maxCount then
                        --取好感度高的
                        local newCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(v.CharacterId)
                        local oldCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(charaId)
                        if newCharFavorabilityLv >oldCharFavorabilityLv then
                            charaId=v.CharacterId
                        elseif newCharFavorabilityLv==oldCharFavorabilityLv then
                            --取优先级高的
                            if XMVCA.XCharacter:GetCharacterPriority(v.CharacterId) >XMVCA.XCharacter:GetCharacterPriority(charaId) then
                                charaId=v.CharacterId
                            end

                        end
                    end
                end
                if XTool.IsNumberValid(charaId) and maxCount>0 then
                    return XMVCA.XCharacter:GetCharacterFullNameStr(charaId),maxCount
                else
                    return CS.XTextManager.GetText("ReviewActivityNoGuild"),false
                end
            end
        end
    end

    function XReviewActivityManager.GetDormWorkCountCharaFullNameAndFightCount()
        if ReviewData then
            if ReviewData.ReviewActivityStaticData  and ReviewData.ReviewActivityStaticData.ReviewCharacterData then
                local maxCount=-1
                local charaId=nil
                for i, v in pairs(ReviewData.ReviewActivityStaticData.ReviewCharacterData) do
                    if v.DormWorkCount>maxCount then
                        maxCount=v.DormWorkCount
                        charaId=v.CharacterId
                    elseif v.DormWorkCount==maxCount then
                        --取好感度高的
                        local newCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(v.CharacterId)
                        local oldCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(charaId)
                        if newCharFavorabilityLv >oldCharFavorabilityLv then
                            charaId=v.CharacterId
                        elseif newCharFavorabilityLv==oldCharFavorabilityLv then
                            --取优先级高的
                            if XMVCA.XCharacter:GetCharacterPriority(v.CharacterId) >XMVCA.XCharacter:GetCharacterPriority(charaId) then
                                charaId=v.CharacterId
                            end

                        end
                    end
                end
                if XTool.IsNumberValid(charaId) and maxCount>0 then
                    return XMVCA.XCharacter:GetCharacterFullNameStr(charaId),maxCount
                else
                    return CS.XTextManager.GetText("ReviewActivityNoGuild"),false
                end
            end
        end
    end

    function XReviewActivityManager.GetTouchCountCharaFullNameAndFightCount()
        if ReviewData then
            if ReviewData.ReviewActivityStaticData  and ReviewData.ReviewActivityStaticData.ReviewCharacterData then
                local maxCount=-1
                local charaId=nil
                for i, v in pairs(ReviewData.ReviewActivityStaticData.ReviewCharacterData) do
                    if v.TouchCount>maxCount then
                        maxCount=v.TouchCount
                        charaId=v.CharacterId
                    elseif v.TouchCount==maxCount then
                        --取好感度高的
                        local newCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(v.CharacterId)
                        local oldCharFavorabilityLv=XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(charaId)
                        if newCharFavorabilityLv >oldCharFavorabilityLv then
                            charaId=v.CharacterId
                        elseif newCharFavorabilityLv==oldCharFavorabilityLv then
                            --取优先级高的
                            if XMVCA.XCharacter:GetCharacterPriority(v.CharacterId) >XMVCA.XCharacter:GetCharacterPriority(charaId) then
                                charaId=v.CharacterId
                            end

                        end
                    end
                end
                if XTool.IsNumberValid(charaId) and maxCount>0 then
                    return XMVCA.XCharacter:GetCharacterFullNameStr(charaId),maxCount
                else
                    return CS.XTextManager.GetText("ReviewActivityNoGuild"),false
                end
            end
        end
    end
    
    function XReviewActivityManager.GetBossSingleMaxScore()
        if ReviewData then
            if ReviewData.ReviewActivityStaticData then
                return ReviewData.ReviewActivityStaticData.BossSingleTotalScore
            end
        end
        return 0
    end
    
    --最高两个段位的达成次数，高段位在前
    function XReviewActivityManager.GetArenaChallengeMaxLevelCount()
        if ReviewData then
            local result={}
            if ReviewData.ReviewActivityStaticData and ReviewData.ReviewActivityStaticData.ReviewArenaChallenge then
                --排序，高段位在前
                table.sort(ReviewData.ReviewActivityStaticData.ReviewArenaChallenge,function(a,b)
                    return a.ArenaLevel>b.ArenaLevel
                end)
                
                for i, v in ipairs(ReviewData.ReviewActivityStaticData.ReviewArenaChallenge) do
                    if XTool.IsNumberValid(v.Count) then
                        table.insert(result,v)
                        if #result>=2 then
                            return result
                        end
                    end
                end
                
            end
            --如果没有，则默认预备的
            if XTool.IsTableEmpty(result) then
                table.insert(result,{ArenaLevel=1,Count=0})
            end
            return result
        end
    end
    
    --获取通关次数最多的矿区及其次数
    function XReviewActivityManager.GetMaxPassStronghold()
        if ReviewData then
            if ReviewData.ReviewActivityStaticData and ReviewData.ReviewActivityStaticData.ReviewStronghold then
                --设置组到章节的单向映射
                local map={}
                local chapterIds=XStrongholdConfigs.GetAllChapterIds()
                for i, chapterId in pairs(chapterIds) do
                    local groupdIds=XStrongholdConfigs.GetGroupIds(chapterId)
                    for i2, groupId in pairs(groupdIds) do
                        map[groupId]=chapterId
                    end
                end
                --遍历数据并按照映射统计各个矿区的次数之和
                local result={}
                for i, v in pairs(ReviewData.ReviewActivityStaticData.ReviewStronghold) do
                    result[map[v.GroupId]]=result[map[v.GroupId]]+v.Count
                end
                --找到次数最多的
                local chapterId=1
                local maxTimes=0
                for i, v in pairs(result) do
                    if v>maxTimes then
                        chapterId=i
                        maxTimes=v
                    end
                end
                
                return chapterId,maxTimes
            end
        end
    end
    
    --序列公约通关进度（关卡个数）
    function XReviewActivityManager.GetAwarenessSchedule()
        if ReviewData then
            return ReviewData.AwarenessSchedule
        end
    end
    
    function XReviewActivityManager.IsGetShareReward()
        if ReviewData then
            return ReviewData.ShareRewardState
        end
    end

    function XReviewActivityManager.HasActivityInTime()
        for id, cfg in pairs(Configs or {}) do
            if not cfg then return false end
            local startTime = cfg.StartTime
            local endTime = cfg.EndTime
            if not startTime or (startTime == 0) then

            elseif not endTime or (endTime == 0) then

            else
                local now = XTime.GetServerNowTimestamp()
                local isOpen=(startTime <= now) and (endTime > now)
                if isOpen then return true end
            end
            
        end
        return false
    end
    
    function XReviewActivityManager.CheckHasActivityInTime()
        if XReviewActivityManager.HasActivityInTime() then
            return true,''
        else
            return false,XUiHelper.GetText('CommonActivityNotStart')
        end
    end
    --endregion
    
    
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