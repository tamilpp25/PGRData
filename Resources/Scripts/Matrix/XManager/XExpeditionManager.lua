--虚像地平线玩法管理器
XExpeditionManagerCreator = function()
    local ExpeditionConfig = XExpeditionConfig
    local RankMap = {}
    local ExpeditionManager = {}
    local ExpeditionChapterConfigs = {} --虚像地平线章节配置
    local InitialComplete = false
    local CheckIfRunMain = false
    local EStages = {}
    local XTeam = require("XEntity/XExpedition/XExpeditionTeam")
    local XComboList = require("XEntity/XExpedition/XExpeditionComboList")
    local XStage = require("XEntity/XExpedition/XExpeditionStage")
    local XActivity = require("XEntity/XExpedition/XExpeditionActivity")
    --        sealed class NotifyExpeditionData
    --        int ActivityId;
    --        long ResetTime;
    --        int ChapterId;
    --        Dictionary<int, HashSet<int>> Rewards;
    --        int CanRefreshTimes;
    --        int ExtraRefreshTimes;
    --        int BuyRefreshTimes;
    --        long RefreshTimesRecoveryTime;
    --        int DailyLikeCount;
    --        int RefreshTimes;
    --        int RecruitLevel;
    --        int NpcGroup;
    --        List<XExpeditionCharacter> PickedCharacters;
    --        List<XExpeditionAlternative> AlternativeCharacters
    local ActivityId = 0 --现在的活动ID
    local RecruitTime = 0 --现在可用的抽卡次数
    local ResetTime = 0 --本轮章节重置时间
    local NextRecruitAddTime = 0 --下次增加抽卡次数时间
    local BuyRecruitTime = 0 --螺母累计购买抽卡次数
    local ExtraRecruitTime = 0 --额外追加的抽卡次数
    local CurrentChapterId = 0 --现在使用的章节
    local EActivity --活动管理对象
    local RewardsTable -- 获取章节奖励字典
    local DailyLikeCount = 0 --今日点赞次数
    local IsActivityEnd = true
    local ChapterInfos = {}
    local MyTeam
    local ComboList
    local IsRegisterEditBattleProxy = false

    local SortByRankFunc = function(a, b)
        return a.Rank > b.Rank
    end

    ExpeditionManager.StageType = {
        [1] = "Story", -- 1 剧情关
        [2] = "Battle", -- 2 战斗关
        [3] = "Infinity", -- 3 无尽关
    }
    --=====================
    --关卡难度枚举
    --=====================
    ExpeditionManager.StageDifficulty = {
        Normal = 1, --普通难度
        NightMare = 2, --噩梦难度
    }
    --=====================
    --关卡难度提示枚举
    --=====================
    ExpeditionManager.StageWarning = {
        NoWarning = 1, -- 无警告
        Warning = 2, -- 黄色等级差警告
        Danger = 3, -- 红色等级差警告
    }
    ExpeditionManager.ComboBtnType = {
        BaseComboType = 1,
        ChildComboType = 2
    }

    ExpeditionManager.ComboConditionType = {
        MemberNum = 1, -- 检查合计数量
        TotalRank = 2, -- 检查合计等级
        TargetMember = 3, -- 检查对应角色等级
        TargetTypeAndRank = 4 -- 检查指定特征的高于指定等级的人
    }

    ExpeditionManager.BuffTipsType = {
        GlobalBuff = 1,
        StageBuff = 2,
        Skill = 3,
    }

    local METHOD_NAME = {
        RecruitRefresh = "ExpeditionRefreshAlternativeRequest", --刷新招募商店
        RecruitMember = "ExpeditionRecruitRequest", --招募一个队员
        FireMember = "ExpeditionFireRequest", --解雇一个队员
        SendComment = "ExpeditionSendCommentRequest", --发送留言
        GetCommentInfo = "ExpeditionGetCommentInfoRequest", --取得留言列表
        CommentDoLike = "ExpeditionLikeCommentRequest", --点赞
        GetChapterReward = "ExpeditionGetChapterRewardRequest", --获取当前章节通关奖励
        GetRankingData = "ExpeditionRankRequest", --获取排行数据
        GetMyRanking = "ExpeditionRankNumRequest", --获取玩家自身排行数据
    }
    --===================
    --客户端启动初始化管理器
    --===================
    function ExpeditionManager.Init()
        ExpeditionChapterConfigs = ExpeditionConfig.GetLastestExpeditionConfig()
        ExpeditionManager.InitObjects()
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, ExpeditionManager.OnSyncStageData)
    end
    --===================
    --客户端启动初始化对象
    --===================
    function ExpeditionManager.InitObjects()
        EActivity = XActivity.New()
        MyTeam = XTeam.New()
    end

    function ExpeditionManager.OnSyncStageData(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Type ~= XDataCenter.FubenManager.StageType.Expedition then return end
    end

    function ExpeditionManager.GetChapterReward(difficulty)
        if ExpeditionManager.GetIsReceivedReward(difficulty) then
            return false
        end
        XNetwork.Call(METHOD_NAME.GetChapterReward, { Difficulty = difficulty }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                if not RewardsTable[CurrentChapterId] then RewardsTable[CurrentChapterId] = {} end
                table.insert(RewardsTable[CurrentChapterId], difficulty)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_ON_GET_CHAPTER_REWARD, reply.RewardGoodsList)
            end)
    end
    --*******************************待招募成员相关方法*****************************
    local RecruitMembers
    function ExpeditionManager.InitRecruitInfos()
        local RecruitMembersObj = require("XEntity/XExpedition/XExpeditionRecruitMembers")
        RecruitMembers = RecruitMembersObj.New(ExpeditionManager:GetRecruitDrawNum())
    end

    function ExpeditionManager.RefreshRecruitInfos(recruitMembers)
        RecruitMembers:Reset()
        if recruitMembers and #recruitMembers > 0 then
            for i = 1, ExpeditionManager:GetRecruitDrawNum() do
                RecruitMembers:ResetCharaData(i, recruitMembers[i].ECharacterId)
                if recruitMembers[i].IsPicked then
                    RecruitMembers:SetRecruitPos(i)
                end
            end
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RECRUIT_REFRESH, true)
    end
    --===================
    --招募角色请求
    --@param characterIndex: 要招募的角色在招募列表中的Index
    --===================
    function ExpeditionManager.RecruitMember(characterIndex)
        local chara = RecruitMembers:GetCharaByPos(characterIndex)
        if not chara then return end
        if RecruitMembers:GetRecruitPos() == characterIndex then
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionCharaRecruited"))
            return
        end
        if RecruitMembers:GetIsPicked() then
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionIsPicked"))
            return
        end
        local team = ExpeditionManager.GetTeam()
        if (not team:CheckHaveNewPos() and not team:CheckInTeamByEBaseId(chara:GetBaseId())) then
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionFullMember"))
            return
        end
        if chara:GetIsMaxLevel() then
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionMaxLevel"))
            return
        end
        XNetwork.Call(METHOD_NAME.RecruitMember, { CharacterIndex = characterIndex - 1 }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                ExpeditionManager.RecruitPick(characterIndex)
            end)
    end

    function ExpeditionManager.RecruitPick(index)
        RecruitMembers:SetRecruitPos(index)
        local addMember = RecruitMembers:GetCharaByPos(index)
        MyTeam:AddMemberByEChara(addMember)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RECRUIT_REFRESH, false)
    end

    function ExpeditionManager.RefreshRecruit()
        XNetwork.Call(METHOD_NAME.RecruitRefresh, nil, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                ExpeditionManager.RefreshRecruitInfos(reply.AlternativeCharacters)
            end)
    end

    function ExpeditionManager.SetRecruitInfoHadCommented(eCharId)
        --for _, info in pairs(RecruitInfos) do
        --    if info.Cfg.Id == eCharId then
        --        info.HadCommented = true
        --        return
        --    end
        --end
    end

    function ExpeditionManager.GetCanRecruit()
        return EActivity and EActivity:GetCanRecruit()
    end

    function ExpeditionManager.GetCanBuyDraw()
        return EActivity and EActivity:GetCanBuyDraw()
    end
    --*******************************待招募成员相关方法结束**************************
    --*******************************成员队伍相关方法*****************************
    function ExpeditionManager.GetCharaDisplayIndex(eBaseId)
        return MyTeam:GetCharaDisplayIndexByBaseId(eBaseId)
    end

    function ExpeditionManager.GetCharaByEBaseId(eBaseId)
        return MyTeam:GetCharaByEBaseId(eBaseId)
    end

    function ExpeditionManager.GetECharaByDisplayIndex(index)
        return MyTeam:GetECharaByDisplayIndex(index)
    end

    function ExpeditionManager.IsMemberActive(baseId)
        return MyTeam:CheckInTeamByEBaseId(baseId)
    end

    function ExpeditionManager.InitMemberData(members)
        MyTeam:Reset()
        local memberList = {}
        for _, data in pairs(members) do
            table.insert(memberList, data.ECharacterId)
        end
        MyTeam:AddMemberListByECharaIds(memberList)
    end
    --===================
    --解雇一个角色
    --@param characterId: 要解雇的角色Id
    --===================
    function ExpeditionManager.FireMember(eBaseId, eCharacterId)
        local tipTitle = CS.XTextManager.GetText("ExpeditionFireConfirmTitle")
        local content = CS.XTextManager.GetText("ExpeditionFireConfirmContent")
        local confirmCb = function()
            XNetwork.Call(METHOD_NAME.FireMember, {ECharacterId = eCharacterId}, function(reply)
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    MyTeam:RemoveMember(eBaseId)
                end)
        end
        CsXUiManager.Instance:Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end

    function ExpeditionManager.CheckHaveMember()
        return MyTeam and MyTeam:GetTeamNum() > 0
    end
    --*******************************成员队伍相关方法结束**************************
    --****************************战斗相关方法 开始****************************
    --===================
    --获取出战队伍数据
    --===================
    function ExpeditionManager.GetExpeditionTeam()
        local teamInfos = XDataCenter.TeamManager.GetPlayerTeam(CS.XGame.Config:GetInt("TypeIdExpedition"))
        for index, baseId in pairs(teamInfos.TeamData) do
            if baseId > 0 then
                local isActive = ExpeditionManager.IsMemberActive(baseId)
                if not isActive then
                    teamInfos.TeamData[index] = 0
                end
            end
        end
        return teamInfos
    end

    function ExpeditionManager.CheckStageIsExpedition(stageId)
        local info = XDataCenter.FubenManager.GetStageInfo(stageId)
        return info and info.Type == XDataCenter.FubenManager.StageType.Expedition
    end
    --****************************战斗相关方法 结束****************************
    --****************************Get方法 开始****************************
    function ExpeditionManager.GetCharacterIsInTeam(baseId)
        local teamInfos = XDataCenter.TeamManager.GetPlayerTeam(CS.XGame.Config:GetInt("TypeIdExpedition"))
        if not teamInfos or not baseId then return false end
        for _, v in pairs(teamInfos.TeamData) do
            if v == baseId then
                return true
            end
        end
        return false
    end
    --===================
    --获取招募一次刷新数目
    --===================
    function ExpeditionManager.GetRecruitDrawNum()
        return EActivity:GetRecruitDrawNum()
    end
    --===================
    --获取招募刷新次数字符串
    --===================
    function ExpeditionManager.GetRecruitNumInfoString()
        return EActivity:GetRecruitTimesStr()
    end
    --===================
    --获取自然招募次数是否已到最大值
    --===================
    function ExpeditionManager.GetRecruitTimeFull()
        return EActivity:GetRecruitTimeFull()
    end
    --===================
    --获取活动配置简表
    --===================
    function ExpeditionManager.GetActivityChapters()
        if ExpeditionManager.GetIsActivityEnd() then return {} end
        local chapters = {}
        local expeditionConfig = XExpeditionConfig.GetExpeditionConfig()
        if expeditionConfig then
            for _, v in pairs(expeditionConfig) do
                local startTime = XFunctionManager.GetStartTimeByTimeId(v.TimeId)
                local endTime = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
                local timeNow = XTime.GetServerNowTimestamp()
                if timeNow >= startTime and timeNow < endTime then
                    local tempChapter = {}
                    tempChapter.Type = XDataCenter.FubenManager.ChapterType.Expedition
                    tempChapter.Id = v.Id
                    table.insert(chapters, tempChapter)
                end
            end
        end
        return chapters
    end

    function ExpeditionManager.GetIsChapterClear(difficulty)
        return ExpeditionManager.GetCurrentChapter():GetIsClearByDifficulty(difficulty)
    end
    --===================
    --获取关卡重置时间字符串
    --===================
    function ExpeditionManager.GetResetTime()
        return EActivity:GetResetTime()
    end
    --===================
    --获取下次招募自然恢复刷新时间
    --===================
    function ExpeditionManager.GetNextRecruitAddTime()
        return EActivity:GetNextRecruitAddTime()
    end

    function ExpeditionManager.GetEActivity()
        return EActivity
    end
    --================
    --获取当前章节对象
    --================
    function ExpeditionManager.GetCurrentChapter()
        return EActivity:GetCurrentChapter()
    end
    --================
    --根据难度获取当前章节奖励
    --@param difficulty:难度
    --================
    function ExpeditionManager.GetChapterRewardIdByDifficulty(difficulty)
        return ExpeditionManager.GetCurrentChapter():GetChapterReward(difficulty)
    end
    --================
    --获取当前招募等级
    --================
    function ExpeditionManager.GetRecruitLevel()
        return EActivity:GetRecruitLevel()
    end
    --================
    --获取当前招募等级
    --================
    function ExpeditionManager.GetRecruitNum()
        return EActivity:GetRecruitNum()
    end

    function ExpeditionManager.GetBuyRecruitTimes()
        return EActivity:GetBuyRecruitTimes()
    end
    function ExpeditionManager.GetBuyDrawInfo()
        local price = ExpeditionConfig.GetDrawPriceByCount(ExpeditionManager:GetBuyRecruitTimes() + 1)
        return price
    end

    function ExpeditionManager.GetCurrentChapterGlobalCombos()
        return ExpeditionConfig.GetChapterCfgById(CurrentChapterId).ComboIds
    end

    function ExpeditionManager.GetStartTime()
        if not EActivity then return 0 end
        return XFunctionManager.GetStartTimeByTimeId(EActivity:GetTimeId()) or 0
    end

    function ExpeditionManager.GetEndTime()
        if not EActivity then return 0 end
        return XFunctionManager.GetEndTimeByTimeId(EActivity:GetTimeId()) or 0
    end

    function ExpeditionManager.GetResetTime()
        return EActivity and EActivity:GetResetTime()
    end

    function ExpeditionManager.GetStageCompleteStr(difficulty)
        return ExpeditionManager.GetCurrentChapter():GetStageCompleteStr(difficulty)
    end

    function ExpeditionManager.GetStageCompletePercent(difficulty)
        return ExpeditionManager.GetCurrentChapter():GetStageCompletePercent(difficulty)
    end

    function ExpeditionManager.GetIsReceivedReward(difficulty)
        if not RewardsTable then return false end
        for chapterId, v in pairs(RewardsTable) do
            if chapterId == CurrentChapterId then
                for _, diff in pairs(v) do
                    if diff == difficulty then return true end
                end
            end
        end
        return false
    end

    function ExpeditionManager.GetIsActivityEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= ExpeditionManager.GetEndTime()
        local isStart = timeNow >= ExpeditionManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return IsActivityEnd or not inActivity, timeNow < ExpeditionManager.GetStartTime()
    end

    function ExpeditionManager.GetRankStr(rank)
        if rank >= 27 then return "MAX" end
        return rank
    end

    function ExpeditionManager.GetIfBackMain()
        return CheckIfRunMain or ExpeditionManager.GetIsActivityEnd()
    end

    function ExpeditionManager.SetIfBackMain(ifBackMain)
        CheckIfRunMain = ifBackMain
    end
    --=================
    --使用玩法关卡Id获取关卡对象
    --@param eStageId:玩法关卡Id
    --=================
    function ExpeditionManager.GetEStageByEStageId(eStageId)
        return EStages[eStageId]
    end
    --=================
    --使用关卡Id获取关卡对象
    --@param stageId:关卡Id
    --=================
    function ExpeditionManager.GetEStageByStageId(stageId)
        local eStageId = XExpeditionConfig.GetEStageIdByStageId(stageId)
        return eStageId and EStages[eStageId]
    end
    --****************************Get方法 结束****************************
    --****************************FubenManager方法 开始****************************
    --===================
    --初始化关卡信息
    --===================
    function ExpeditionManager.InitStageInfo(checkNewUnlock)
        EStages = {}
        local eStageList = ExpeditionConfig.GetStageList()
        for eStageId, eStageCfg in pairs(eStageList) do
            EStages[eStageCfg.Id] = XStage.New(eStageCfg.Id)
        end
        if EActivity then EActivity:RefreshChapter() end
    end
    --===================
    --调用结算界面
    --===================
    function ExpeditionManager.ShowReward(winData)
        local eStage = ExpeditionManager.GetEStageByStageId(winData.StageId)
        if eStage:GetIsInfinity() then
            XLuaUiManager.Open("UiExpeditionInfinityWin", winData)
        else
            XLuaUiManager.Open("UiExpeditionSettleWin", winData)
        end
    end
    --****************************FubenManager方法 结束****************************
    --****************************玩法入口方法 开始****************************
    --===================
    --获取玩法入口红点状况
    --===================
    function ExpeditionManager.CheckRecruitRedPoint()
        local isInActivity = not ExpeditionManager.GetIsActivityEnd()
        local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Expedition)
        return isInActivity and isOpen and ((EActivity:GetRecruitTimes() + EActivity:GetExtraRecruitTimes()) > 0)
    end
    --****************************玩法入口方法 结束****************************
    --****************************留言板方法 开始****************************
    local MAX_COMMENT_PAGE = 5
    --===================
    --发送评论
    --===================
    function ExpeditionManager.SendComment(eCharId, content)
        if string.IsNilOrEmpty(content) then XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionNoContentComment")) return end
        XNetwork.Call(METHOD_NAME.SendComment, { ECharacterId = eCharId, Content = content }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                XEventManager.DispatchEvent(XEventId.EVENT_EXPEDITION_COMMENTS_SEND, reply.CommentId, reply.Content)
            end)
    end

    function ExpeditionManager.GetComment(baseId, pageNo)
        XNetwork.Call(METHOD_NAME.GetCommentInfo, { BaseId = baseId, PageNo = pageNo }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                ExpeditionManager.ReceiveComment(reply)
            end)
    end

    function ExpeditionManager.CommentDoLike(baseId, commentId)
        if DailyLikeCount >= EActivity:GetDailyLikeMaxNum() then
            XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionDoLikeOverTime"))
            return
        end
        XNetwork.Call(METHOD_NAME.CommentDoLike, { BaseId = baseId, CommentId = commentId }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                DailyLikeCount = DailyLikeCount + 1
                XEventManager.DispatchEvent(XEventId.EVENT_EXPEDITION_COMMENTS_DOLIKE, commentId)
            end)
    end

    function ExpeditionManager.ReceiveComment(commentData)
        XEventManager.DispatchEvent(XEventId.EVENT_EXPEDITION_COMMENTS_RECEIVE, commentData.Comments, commentData.PageNo)
    end
    --****************************留言板方法 结束****************************
    --****************************功能开放与跳转界面*******************************
    function ExpeditionManager.JumpToExpedition()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Expedition) then
            local canGoTo, notStart = ExpeditionManager.CheckCanGoTo()
            if canGoTo then
                XLuaUiManager.Open("UiExpeditionMain", CurrentChapterId)
            elseif notStart then
                XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionActivityNotStart"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionActivityEnd"))
            end
        end
    end

    function ExpeditionManager.CheckCanGoTo()
        local isActivityEnd, notStart = ExpeditionManager.GetIsActivityEnd()
        return not isActivityEnd, notStart
    end
    --****************************功能开放与跳转*结束***************************
    --****************************网络协议 开始****************************
    --===================
    --接受服务端推送，初始化数据
    --@服务端推送XRpc.InitExpeditionData
    --===================
    function ExpeditionManager.InitData(data)
        if EActivity then EActivity:SetActivityId(data.ActivityId) end
        if data.ChapterId == 0 then ExpeditionManager.ActivityEnd() return end
        ExpeditionManager.SetCurrentChapter(data.ChapterId)
        if EActivity then EActivity:RefreshActivity(data) end
        ExpeditionManager.InitMemberData(data.PickedCharacters)
        ExpeditionManager.InitRecruitInfos()
        ExpeditionManager.RefreshRecruitInfos(data.AlternativeCharacters)
        ExpeditionManager.SetWave(data.NpcGroup)
        ExpeditionManager.RegisterEditBattleProxy()
        RewardsTable = data.Rewards or {}
        IsActivityEnd = false
        if not InitialComplete then InitialComplete = true end
    end

    --[[
    ================
    注册出战界面代理
    ================
    ]]
    function ExpeditionManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.Expedition,
            require("XUi/XUiExpedition/Battle/XUiExpeditionNewRoomSingle"))
    end

    function ExpeditionManager.ActivityEnd()
        IsActivityEnd = true
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.Expedition)
        if InitialComplete then
            CheckIfRunMain = true
        end
    end

    function ExpeditionManager.SetCurrentChapter(chapter)
        local isNewChapter = CurrentChapterId ~= chapter
        if not isNewChapter and CurrentChapterId ~= 0 then return end
        CurrentChapterId = chapter > 0 and chapter or 1
        if EActivity then EActivity:SetChapterOrderId(CurrentChapterId) end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.Expedition)
        if InitialComplete then
            CheckIfRunMain = true
        end
    end

    function ExpeditionManager.UpdateRecruitTimes(data)
        if EActivity then EActivity:UpdateRecruitTimes(data, true) end
    end
    --****************************网络协议 结束****************************
    --****************************
    --二期工程：新对象处理方法
    --****************************
    --================
    --获取队伍对象
    --================
    function ExpeditionManager.GetTeam()
        return MyTeam
    end
    --================
    --获取指定位置的队员
    --@param pos:位置序号
    --================
    function ExpeditionManager.GetTeamCharaByPos(pos)
        if not pos then return nil end
        local team = ExpeditionManager.GetTeam()
        return team and team:GetCharaByDisplayPos(pos)
    end
    --================
    --获取队伍位置对象
    --================
    function ExpeditionManager.GetTeamPosDisplayList()
        return MyTeam:GetTeamPosDisplayList()
    end
    --================
    --根据位置获取成员对象
    --@param index:展示序号
    --================
    function ExpeditionManager.GetCharaByDisplayIndex(index)
        return MyTeam:GetCharaByDisplayPos(index)
    end
    --================
    --获取队伍平均星级
    --================
    function ExpeditionManager.GetTeamAverageStar()
        return MyTeam:GetAverageStar()
    end
    --================
    --检查成员展示列表中是否含有指定序号的成员
    --@param index:展示序号
    --================
    function ExpeditionManager.CheckCharaIsInDisplayByIndex(index)
        return MyTeam:CheckCharaInDisplayListByPos(index)
    end
    --================
    --根据玩法角色ID获取角色
    --================
    function ExpeditionManager.GetECharaByEBaseId(eBaseId)
        return MyTeam:GetCharaByEBaseId(eBaseId)
    end
    --================
    --获取组合一览列表
    --================
    function ExpeditionManager.GetComboList()
        return MyTeam:GetComboList()
    end
    --================
    --根据组合ID获取组合
    --================
    function ExpeditionManager.GetComboByChildComboId(childComboId)
        return ExpeditionManager.GetComboList():GetComboByComboId(childComboId)
    end
    --================
    --获取招募商店角色
    --================
    function ExpeditionManager.GetRecruitMembers()
        return RecruitMembers
    end
    --================
    --获取无尽关卡通过波数
    --================
    function ExpeditionManager.GetWave()
        return EActivity:GetWave()
    end
    --================
    --设置当前章节无尽关卡波数
    --@param wave:波数
    --================
    function ExpeditionManager.SetWave(wave)
        return EActivity:SetWave(wave)
    end
    --================
    --根据商店位置获取招募商店角色
    --================
    function ExpeditionManager.GetRecruitMemberByPos(pos)
        return RecruitMembers:GetCharaByPos(pos)
    end
    --================
    --根据商店位置获取招募商店角色
    --================
    function ExpeditionManager.GetIsNormalClear()
        return ExpeditionManager.GetCurrentChapter():GetIsNormalClear()
    end
    --================
    --获取自己排行数
    --================
    function ExpeditionManager.GetSelfRank()
        return EActivity:GetSelfRank()
    end
    --================
    --获取自己排行数字符串
    --================
    function ExpeditionManager.GetSelfRankStr()
        return EActivity:GetSelfRankStr()
    end
    --================
    --获取前百排行榜数据
    --================
    function ExpeditionManager.GetRankingList()
        return EActivity:GetRankingList()
    end
    --================
    --获取排位图片
    --================
    function ExpeditionManager.GetRankSpecialIcon(ranking)
        return EActivity:GetRankSpecialIcon(ranking)
    end
    --================
    --获取排位信息
    --================
    function ExpeditionManager.GetRankingData()
        XNetwork.Call(METHOD_NAME.GetRankingData, nil, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                if EActivity then EActivity:UpdateRankingData(reply) end
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RANKING_REFRESH)
            end)
    end
    --================
    --获取玩家自身排位信息
    --================
    function ExpeditionManager.GetMyRankingData()
        XNetwork.Call(METHOD_NAME.GetMyRanking, nil, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                if EActivity then EActivity:UpdateMyRankingData(reply) end
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RANKING_REFRESH)
            end)
    end

    --用于活动简介界面的红点检测
    function ExpeditionManager.CheckActivityRedPoint()
        --返回true就是有未用的刷新次数 false就是没有刷新次数
        local canRecruit = ExpeditionManager.GetCanRecruit()
        -- 返回true就是全部关卡通过了
        local isAllPass = ExpeditionManager.GetIsChapterClear(ExpeditionManager.StageDifficulty.NightMare)

        return canRecruit and not isAllPass
    end

    ExpeditionManager.Init()
    return ExpeditionManager
end
--================
--刷新玩法信息
--================
XRpc.NotifyExpeditionData = function(data)
    XDataCenter.ExpeditionManager.InitData(data)
end
--================
--刷新招募相关信息
--================
XRpc.NotifyExpeditionRefreshTimes = function(data)
    XDataCenter.ExpeditionManager.UpdateRecruitTimes(data)
end