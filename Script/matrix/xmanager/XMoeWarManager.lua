local XMoeWarPreparationBaseData = require("XEntity/XMoeWar/XMoeWarPreparationBaseData")
local XMoeWarPlayer = require("XEntity/XMoeWar/XMoeWarPlayer")
local XMoeWarMatch = require("XEntity/XMoeWar/XMoeWarMatch")
local XMoeWarVoteItem = require("XEntity/XMoeWar/XMoeWarVoteItem")
local XMoeWarParkourStage = require("XEntity/XMoeWar/XMoeWarParkourStage")
local XTeam = require("XEntity/XTeam/XTeam")

local RankReqIntervalTime = 60 * 2
XMoeWarManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort
    local stringFormat = string.format
    local mathFloor = math.floor
    local pairs = pairs
    local ipairs = ipairs
    local mathMax = math.max
    local CSXTextManagerGetText = CS.XTextManager.GetText
    local ActivityInfo = nil
    local DefaultActivityInfo = nil
    local CurMatchEntity = nil
    local Timer
    local CurMatchId = 0
	local VoteDaily = 0
	local ScreenRecordDic = {}
    local PlayerDic = {}
    local MatchDic = {}
    local MatchGroup = {}
    local VoteItemDic = {}
    local SessionList = {}
    local RankCache = {}
    local TabIndexCache = {}
    local ParkourStageDict = {}
    local GROUP_TAB_INDEX_KEY
    local StatusInFightChangeCache = false  -- 是否在战斗中缓存

    local PrepareTeamData = {}
    local ExcludeWrongAnswersDic = {}
    local ParkourTeam
    local ParkourActivityId
    local ParkourTicket = 0 --跑酷票数
    local ParkourMaxTicket = 0 --跑酷每日获取最大票数
    local ParkourTicketMagnification = 10 --票数倍率，对应Reward的Count
    local ParkourTeachStage
	
	local PlayerScreenRecordSize = CS.XGame.ClientConfig:GetInt("MoeWarPlayerScreenRecordSize")
	local MoeWarPlayerScreenRecordShowNumber = CS.XGame.ClientConfig:GetInt("MoeWarPlayerScreenRecordShowNumber")

    local MoeWarPreparationBaseData = XMoeWarPreparationBaseData.New()
    ---------------------本地接口 begin------------------
    local function Init()
        local activityTemplates = XMoeWarConfig.GetActTemplates()
        local nowTime = XTime.GetServerNowTimestamp()
        for _, template in pairs(activityTemplates) do
            DefaultActivityInfo = XMoeWarConfig.GetActivityTemplateById(template.Id)
            local timeId = template.ActivityTimeId
            local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
            if nowTime > startTime and nowTime < endTime then
                if not ActivityInfo then
                    ActivityInfo = XMoeWarConfig.GetActivityTemplateById(template.Id)
                end

                if Timer then
                    XScheduleManager.UnSchedule(Timer)
                end
                Timer = XScheduleManager.ScheduleForever(function()
                    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_ACTIVITY_END)
                        XScheduleManager.UnSchedule(Timer)
                    end
                end, XScheduleManager.SECOND * 3)
            end
        end

        if ActivityInfo then
            for _, v in pairs(XMoeWarConfig.GetPlayers()) do
                PlayerDic[v.Id] = XMoeWarPlayer.New(v.Id)
            end
            for _, v in pairs(XMoeWarConfig.GetMatchCfgs()) do
                local match = XMoeWarMatch.New(v.Id)
                MatchDic[v.Id] = match
                if not MatchGroup[v.SessionId] then
                    MatchGroup[v.SessionId] = {}
                end
                MatchGroup[v.SessionId][v.Type] = match
                if v.Type == XMoeWarConfig.MatchType.Publicity then
                    SessionList[v.SessionId] = match
                end
            end
            GROUP_TAB_INDEX_KEY = stringFormat("%s_%s", XMoeWarConfig.KEY_GROUP_TAB_INDEX, XPlayer.Id)
            TabIndexCache = XSaveTool.GetData(GROUP_TAB_INDEX_KEY) or {}
            for _, v in pairs(XMoeWarConfig.GetVoteItems()) do
                VoteItemDic[v.No] = XMoeWarVoteItem.New(v.No)
            end
        end
    end

    local SetExcludeWrongAnswers = function(excludeWrongAnswers)
        ExcludeWrongAnswersDic = {}
        for _, excludeWrongAnswerIndex in ipairs(excludeWrongAnswers or {}) do
            ExcludeWrongAnswersDic[excludeWrongAnswerIndex] = true
        end
    end

    --返回剩余未恢复的支援次数
    local GetLastNotRecoverCount = function()
        local assistanceCount = MoeWarPreparationBaseData:GetAssistanceCount()
        local maxCount = XMoeWarConfig.GetPreparationAssistanceSupportMaxCount()
        return mathMax(maxCount - assistanceCount, 0)
    end

    -- 状态改变直接回到主界面
    local JudgeGotoMain = function(newMatchId, newActivityId)
        if not XLuaUiManager.IsUiLoad("UiMoeWarPreparation") then
            return
        end

        -- 如果玩家在战斗中 先做缓存
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            StatusInFightChangeCache = true
            return
        end
        
        local oldMatchId = MoeWarPreparationBaseData:GetMatchId()
        local oldActivityId = MoeWarPreparationBaseData:GetActivityId()
        if oldMatchId ~= newMatchId or oldActivityId ~= newActivityId then
            XUiManager.TipText("ActivityStateChange")
            XLuaUiManager.RunMain()
            XLuaUiManager.Open("UiMoeWarMain")
        end
    end
    
    local GetQuestionTemplate = function(questionId, desc, recruitMsgType, isPlayMsgAnima, isOverPlayMsgAnima)
        return {
            QuestionId = questionId,
            Desc = desc,
            RecruitMsgType = recruitMsgType,
            IsPlayMsgAnima = isPlayMsgAnima,
            IsOverPlayMsgAnima = false
        }
    end
    
    local InitParkourData = function()
        if not XTool.IsNumberValid(ParkourActivityId) then
            return
        end
        local stageList = XMoeWarConfig.GetParkourStageList(ParkourActivityId)
        for _, stageId in ipairs(stageList or {}) do
            local template = XMoeWarConfig.GetParkourStageTemplate(stageId)
            local item = XMoeWarParkourStage.New(template)
            ParkourStageDict[stageId] = item
        end
        ParkourMaxTicket = XMoeWarConfig.GetParkourDailyMaxReward(ParkourActivityId)
        local teachTemplate = XMoeWarConfig.GetParkourStageTemplate(XMoeWarConfig.GetParkourTeachStageId(ParkourActivityId))
        ParkourTeachStage = XMoeWarParkourStage.New(teachTemplate)
    end
    ---------------------本地接口 end--------------------
    local MoeWarManager = {}

    ---------------------选手与赛程接口 begin--------------------
    function MoeWarManager.GetActivityInfo()
        return ActivityInfo
    end

    function MoeWarManager.GetActivityShopIds()
        return ActivityInfo.ShopIds
    end

    function MoeWarManager.GetPlayer(id)
        return PlayerDic[id]
    end

    function MoeWarManager.GetMySupportCount(playerId, matchId)
        -- matchId 为空则获取总支持数
        local player = PlayerDic[playerId]
        if not player then
            return 0
        else
            return player:GetMySupportCount(matchId)
        end
    end

    function MoeWarManager.GetMatch(sId)
        return SessionList[sId]
    end

    function MoeWarManager.GetVoteItem(id)
        return VoteItemDic[id]
    end

    function MoeWarManager.GetMatchById(Id)
        return MatchDic[Id]
    end

    function MoeWarManager.GetCurMatch()
        return CurMatchEntity
    end

    function MoeWarManager.GetCurMatchId()
        return CurMatchId
    end

    function MoeWarManager.GetVoteMatch(sId)
        if not MatchGroup[sId] then return end
        return MatchGroup[sId][XMoeWarConfig.MatchType.Voting]
    end

    function MoeWarManager.GetSessionList()
        return SessionList
    end

    function MoeWarManager.GetRankTabList()
        local list = XTool.Clone(XMoeWarConfig.GetRankGroups())

        local playerList = {}
        for i, v in pairs(PlayerDic) do
            tableInsert(playerList, v)
        end

        local curMatch = MoeWarManager.GetCurMatch()
        tableSort(playerList, function(a, b)
            local isWeedOutA = curMatch and curMatch:IsPlayerWeedOut(a.Id)
            local isWeedOutB = curMatch and curMatch:IsPlayerWeedOut(b.Id)
            if isWeedOutA ~= isWeedOutB then
                return isWeedOutB
            elseif a.IsEliminate == b.IsEliminate then
                return a.Id < b.Id
            else
                return b.IsEliminate
            end
        end)

        for i, v in ipairs(playerList) do
            local info = { TagName = v:GetName(), RankType = XMoeWarConfig.RankType.Player, PlayerId = v.Id, HasSub = false, IsSub = true }
            tableInsert(list, info)
        end

        for k, v in pairs(list) do
            if v.IsSub then
                if list[k - 1].IsSub then
                    v.SecondTagType = XMoeWarConfig.SubTagType.Mid
                else
                    v.SecondTagType = XMoeWarConfig.SubTagType.Top
                end

                if list[k + 1] then
                    if not list[k + 1].IsSub then
                        if v.SecondTagType == XMoeWarConfig.SubTagType.Mid then
                            v.SecondTagType = XMoeWarConfig.SubTagType.Btm
                        else
                            v.SecondTagType = XMoeWarConfig.SubTagType.All
                        end
                    end
                else
                    if v.SecondTagType == XMoeWarConfig.SubTagType.Mid then
                        v.SecondTagType = XMoeWarConfig.SubTagType.Btm
                    else
                        v.SecondTagType = XMoeWarConfig.SubTagType.All
                    end
                end
            end
        end


        return list
    end

    function MoeWarManager.GetUserSupportPlayer(sId)
        local userSupportPlayer = 0
        local pairListIndex = 0
        local maxSupportCount = 0

        local match = MoeWarManager.GetMatch(sId)
        for i, v in ipairs(match.PairList) do
            for _, playerId in ipairs(v.Players) do
                local count = XDataCenter.MoeWarManager.GetMySupportCount(playerId)
                if count > maxSupportCount then
                    userSupportPlayer = playerId
                    pairListIndex = i
                    maxSupportCount = count
                end
            end
        end

        return userSupportPlayer, pairListIndex, maxSupportCount
    end

    function MoeWarManager.GetNextTabIndex(sType)
        local tabIndex = TabIndexCache[sType] or 0
        local nextIndex = tabIndex % #XMoeWarConfig.GetGroups() + 1
        TabIndexCache[sType] = nextIndex
        XSaveTool.SaveData(GROUP_TAB_INDEX_KEY, TabIndexCache)
        return nextIndex
    end
    ---------------------选手与赛程接口 end--------------------
	---------------------投票接口 begin--------------------
	function MoeWarManager.NotifyMoeWarVoteScreenRecord(data)
		if not data then return end
        if MoeWarManager.IsSelectSkip() then return end
		for i = 1,#data.Records do
			local playerId = data.Records[i].TargetId
			if not ScreenRecordDic[playerId] then
				ScreenRecordDic[playerId] = XQueue.New()
			end
			if ScreenRecordDic[playerId]:Count() >= PlayerScreenRecordSize then
				ScreenRecordDic[playerId]:Dequeue()
			end 
			ScreenRecordDic[playerId]:Enqueue(data.Records[i])
		end
	end
	
	function MoeWarManager.NotifyMoeWarVoteShowChange(data)
		if not data or not CurMatchEntity then return end
		CurMatchEntity:UpdateInfo(data.Match)
		CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_UPDATE)
	end
	
	function MoeWarManager.NotifyMoeWarDailyReset(data)
		VoteDaily = 0
		for _,player in pairs(PlayerDic) do
			for _,voteItem in pairs(VoteItemDic) do
				player:UpdateDailyVote(voteItem:GetVoteItemId(),0)
			end
		end
	end
	function MoeWarManager.SetIsSelectSkip(isSkip)
        XSaveTool.SaveData(string.format("%s_%s_%s",XMoeWarConfig.SKIP_KEY_PREFIX,XPlayer.Id,MoeWarManager.GetCurMatch():GetType()),isSkip)
    end
    function MoeWarManager.IsSelectSkip()
        local isSkip = XSaveTool.GetData(string.format("%s_%s_%s",XMoeWarConfig.SKIP_KEY_PREFIX,XPlayer.Id,MoeWarManager.GetCurMatch():GetType())) or false
        return isSkip
    end
	function MoeWarManager.GetDailyVoteCount()
		return VoteDaily
	end
	
	function MoeWarManager.GetScreenRecordByPlayerId(playerId)
		if ScreenRecordDic[playerId] and ScreenRecordDic[playerId]:Count() > 0 then
			return ScreenRecordDic[playerId]:Dequeue()
		end
		return nil
	end
    function MoeWarManager.ClearAllScreenRecord()
        for _,queue in pairs(ScreenRecordDic) do
            queue:Clear()
        end
    end
	
	function MoeWarManager:GetDefaultSelect()
		local match = MoeWarManager.GetCurMatch()
		local pairList = match:GetPairList()
		local player,index,maxCount = MoeWarManager.GetUserSupportPlayer(match:GetSessionId())
		if maxCount > 0 then
			return index,false
		end
		local defaultSelectKey = string.format("%s_%s",XMoeWarConfig.DEFAULT_SELECT_KEY_PREFIX,tostring(XPlayer.Id))
 		local selectIndex =  XSaveTool.GetData(defaultSelectKey)
		if match:GetSessionId() == XMoeWarConfig.SessionType.Game24In12 then
			if selectIndex then
				return selectIndex,false
			else
				return math.random(1,#pairList),true
			end
		else
			local lastPlayer,lastIndex,lastMaxCount = XDataCenter.MoeWarManager.GetUserSupportPlayer(match:GetSessionId() - 1)
			local lastPlayerEntity = MoeWarManager.GetPlayer(lastPlayer)
			if (lastPlayerEntity and lastPlayerEntity:GetIsEliminate()) or lastMaxCount == 0 then
				return math.random(1,#pairList),true
			else
				for i = 1,#pairList do
					for j = 1,#(pairList[i].Players) do
						if pairList[i].Players[j] == lastPlayer then
							return i,false
						end
					end
				end
			end
		end
	end
	
	function MoeWarManager:GetMatchPerGroupCount()
		local match = MoeWarManager.GetCurMatch()
		local sessionId = match:GetSessionId()
        if sessionId == XMoeWarConfig.SessionType.GameInAudition then
            return 9
        elseif sessionId == XMoeWarConfig.SessionType.FirstRoundVoting then
            return 4
        elseif sessionId == XMoeWarConfig.SessionType.FailWeekVotingUp then
            return 3
        elseif sessionId == XMoeWarConfig.SessionType.FailWeekVotingDown then
            return 1
        elseif sessionId == XMoeWarConfig.SessionType.Game6In3 then
            return 1
        else
            return 1
        end
	end
	
	function MoeWarManager.GetDefaultSelectGroup()
		local index,isRandom = MoeWarManager.GetDefaultSelect()
		local perGroupCount = MoeWarManager.GetMatchPerGroupCount()
        return (isRandom and { nil } or { math.ceil(index / perGroupCount) })[1]
	end

	
	--每次播放完弹幕动画清空缓存列表
	function MoeWarManager.GetScreenRecord()
		 return ScreenRecord
	end
	
	function MoeWarManager.UpdateDailyVoteCount(addCount)
		VoteDaily = VoteDaily + addCount	
	end
    function MoeWarManager.IsInStatistics()
        return MoeWarManager.GetCurMatch():GetVoteEnd() and (not MoeWarManager.GetCurMatch():GetResultOut())
    end
    ---------------------投票接口 end----------------------
    ---------------------赛况同步 begin--------------------
    function MoeWarManager.HandleActivityData(data)
        if not ActivityInfo or ActivityInfo.Id ~= data.ActivityNo then
            ActivityInfo = XMoeWarConfig.GetActivityTemplateById(data.ActivityNo)
            Init()
        end

        for _, matchData in ipairs(data.Matches) do
            local matchEntity = MatchDic[matchData.MatchId]
            matchEntity:UpdateInfo(matchData)
            if (matchEntity:GetIsEnd(true) and matchEntity:GetType() == XMoeWarConfig.MatchType.Publicity) or
            (matchEntity:GetNotOpen(true) and matchEntity:GetType() == XMoeWarConfig.MatchType.Voting) or
            matchEntity:GetInTime(true) then
                SessionList[matchEntity:GetSessionId()] = matchEntity
            end
        end 
		
		for _, dailyRecord in ipairs(data.MyVoteItemDailyRecord) do
			local player = PlayerDic[dailyRecord.PlayerId]
			player:UpdateDailyVote(dailyRecord.ItemId,dailyRecord.MyVote)
		end

        CurMatchId = data.CurMatchId
		VoteDaily = data.VoteDaily
        CurMatchEntity = MatchDic[CurMatchId]

        for _, myVoteData in ipairs(data.MyVoteRecord) do
            PlayerDic[myVoteData.PlayerId]:UpdateMatchMyVote(myVoteData)
        end

        if CurMatchEntity:GetType() == XMoeWarConfig.MatchType.Publicity then
            for _,queue in pairs(ScreenRecordDic) do
                queue:Clear()
            end
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_UPDATE)
    end
    ---------------------赛况同步 end--------------------
    ---------------------赛事筹备 begin------------------
    ----筹备界面begin
    function MoeWarManager.GetStagesAndOneReserveStage()
        return MoeWarPreparationBaseData:GetStagesAndOneReserveStage()
    end

    function MoeWarManager.GetPreparationAllOpenStageIdList()
        return MoeWarPreparationBaseData:GetAllOpenStageIdList()
    end

    function MoeWarManager.GetReserveStageTimeByIndex(index)
        return MoeWarPreparationBaseData:GetReserveStageTimeByIndex(index)
    end

    function MoeWarManager.IsOpenPreparationStageByIndex(index)
        local reserveStageTime = MoeWarManager.GetReserveStageTimeByIndex(index)
        local nowServerTime = XTime.GetServerNowTimestamp()
        return nowServerTime >= reserveStageTime
    end

    function MoeWarManager.IsPreparationGetRewardGears(gearId)
        return MoeWarPreparationBaseData:IsGetRewardGears(gearId)
    end

    function MoeWarManager.GetPreparationMatchOpenState(matchId)
        local nowServerTime = XTime.GetServerNowTimestamp()
        local timeId = XMoeWarConfig.GetPreparationMatchTimeId(matchId)
        local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
        local matchState
        if nowServerTime < startTime then
            matchState = XMoeWarConfig.MatchState.NotOpen
        elseif nowServerTime >= endTime then
            matchState = XMoeWarConfig.MatchState.Over
        else
            matchState = XMoeWarConfig.MatchState.Open
        end
        return matchState
    end

    function MoeWarManager.GetPreparationAllOpenStageCount()
        return MoeWarPreparationBaseData:GetAllOpenStageCount()
    end

    --获得已招募的角色列表
    function MoeWarManager.GetAllOwnHelpersList()
        local helpersDic = MoeWarPreparationBaseData:GetAllHelpersDic()
        local helpersList = {}
        local helper
        local helperStatus
        for helperId in pairs(helpersDic) do
            helper = MoeWarPreparationBaseData:GetHelper(helperId)
            if helper:IsRecruitFinish() then
                tableInsert(helpersList, helperId)
            end
        end
        tableSort(helpersList, function(a, b)
            return a < b
        end)
        return helpersList
    end

    --获得单次送礼需要的数量
    function MoeWarManager.GetOnceGiftAmount()
        local preparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
        return XTool.IsNumberValid(preparationActivityId) and XMoeWarConfig.GetPreparationActivityGiftAmount(preparationActivityId) or 1
    end
    ----筹备界面end
    ----招募通讯begin
    function MoeWarManager.GetRecruitHelperStatus(helperId)
        return MoeWarPreparationBaseData:GetHelperStatus(helperId)
    end

    function MoeWarManager.GetRecruitHelperExpirationTime(helperId)
        return MoeWarPreparationBaseData:GetHelperExpirationTime(helperId)
    end

    function MoeWarManager.GetTotalQuestionCount(helperId)
        return MoeWarPreparationBaseData:GetTotalQuestionCount(helperId)
    end

    --当前通讯进度
    function MoeWarManager.GetCurrQuestionCount(helperId)
        local finishQuestionCount = MoeWarManager.GetFinishQuestionCount(helperId)
        local answerRecords = MoeWarPreparationBaseData:GetAnswerRecords(helperId)
        local errorQuestionCount = 0
        local questionId
        local questionType
        local answerId
        for _, answerRecord in ipairs(answerRecords) do
            questionId = answerRecord:GetQuestionId()
            questionType = XMoeWarConfig.GetPreparationQuestionType(questionId)
            answerId = answerRecord:GetAnswerId()
            if not answerRecord:QuestionIsRight() and XTool.IsNumberValid(answerId) and questionType == XMoeWarConfig.QuestionType.RandomQuestion then
                errorQuestionCount = errorQuestionCount + 1
            end
        end
        return errorQuestionCount + finishQuestionCount
    end

    function MoeWarManager.GetRecruitQuestionIsRight(helperId, questionId)
        return MoeWarPreparationBaseData:QuestionIsRight(helperId, questionId)
    end

    function MoeWarManager.GetRecruitAnswerId(helperId, questionId)
        return MoeWarPreparationBaseData:GetAnswerId(helperId, questionId)
    end

    function MoeWarManager.GetFinishQuestionCount(helperId)
        return MoeWarPreparationBaseData:GetFinishQuestionCount(helperId)
    end

    function MoeWarManager.GetAnswerRecordsTemplate(helperId)
        return MoeWarPreparationBaseData:GetAnswerRecords(helperId)
    end

    function MoeWarManager.GetAssistanceCount()
        local nowServerTime = XTime.GetServerNowTimestamp()
        local effectId = MoeWarManager.GetSupportTakeEffectIdByEffectType(XMoeWarConfig.PreparationAssistanceEffectType.RecoveryTime)
        local recoveryTime = MoeWarPreparationBaseData:GetAssistanceRecoveryTime()
        local cd = XMoeWarConfig.GetPreparationAssistanceParam(effectId)
        local addCount = 0
        local lastNotRecover = GetLastNotRecoverCount()
        local assistanceCount = MoeWarPreparationBaseData:GetAssistanceCount()

        for i = 1, lastNotRecover do
            local recoveryTimeTemp = recoveryTime + (i - 1) * cd
            if nowServerTime < recoveryTimeTemp then
                break
            else
                addCount = addCount + 1
            end
        end
        return assistanceCount + addCount
    end

    function MoeWarManager.GetAssistanceRecoveryTime()
        local nowServerTime = XTime.GetServerNowTimestamp()
        local recoveryTime = MoeWarPreparationBaseData:GetAssistanceRecoveryTime()
        local effectId = MoeWarManager.GetSupportTakeEffectIdByEffectType(XMoeWarConfig.PreparationAssistanceEffectType.RecoveryTime)
        local lastNotRecover = GetLastNotRecoverCount()

        local cd = XMoeWarConfig.GetPreparationAssistanceParam(effectId)
        for i = 1, lastNotRecover do
            local recoveryTimeTemp = recoveryTime + (i - 1) * cd
            if nowServerTime < recoveryTimeTemp then
                return recoveryTimeTemp
            end
        end
        return 0
    end

    --获得拥有的帮手对应的试玩角色Id列表
    function MoeWarManager.GetPreparationOwnHelperRobotIdList()
        local helpersDic = MoeWarPreparationBaseData:GetAllHelpersDic()
        local robotIdList = {}
        local robotId
        for helperId, helper in pairs(helpersDic) do
            if helper:IsRecruitFinish() then
                robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
                tableInsert(robotIdList, robotId)
            end
        end
        return robotIdList
    end

    function MoeWarManager.GetPreparationOwnHelperIdByRobotId(robotId)
        local helpersDic = MoeWarPreparationBaseData:GetAllHelpersDic()
        local robotIdTemp
        for helperId, helper in pairs(helpersDic) do
            if helper:IsRecruitFinish() then
                robotIdTemp = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
                if robotIdTemp == robotId then
                    return helperId
                end
            end
        end
        return 0
    end

    function MoeWarManager.GetAllQuestionTemplateByHelperId(helperId)
        local answerRecords = MoeWarManager.GetAnswerRecordsTemplate(helperId)
        local data = {}
        local questionType
        local questionId
        local isPlayMsgAnima = false
        for _, v in ipairs(answerRecords) do
            questionId = v:GetQuestionId()
            questionType = XMoeWarConfig.GetPreparationQuestionType(questionId)
            if questionType == XMoeWarConfig.QuestionType.RandomQuestion then
                --问题
                tableInsert(data, 1, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestion(questionId), XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))
                local answerId = v:GetAnswerId()
                if answerId ~= 0 then
                    --我的回答
                    local recruitMsgType = v:QuestionIsRight() and XMoeWarConfig.RecruitMsgType.MyYes or XMoeWarConfig.RecruitMsgType.MyNo
                    local myDesc = XMoeWarConfig.GetPreparationQuestionAnswer(questionId, answerId)
                    tableInsert(data, 1, GetQuestionTemplate(questionId, myDesc, recruitMsgType, isPlayMsgAnima))

                    --回答回复
                    local replyDesc = v:QuestionIsRight() and XMoeWarConfig.GetPreparationQuestionRightReply(questionId) or XMoeWarConfig.GetPreparationQuestionWrongReply(questionId)
                    tableInsert(data, 1, GetQuestionTemplate(questionId, replyDesc, XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))
                    tableInsert(data, 1, GetQuestionTemplate(questionId, "", XMoeWarConfig.RecruitMsgType.Line, isPlayMsgAnima))
                end
            elseif questionType == XMoeWarConfig.QuestionType.RecruitRight or questionType == XMoeWarConfig.QuestionType.RecruitLose then
                tableInsert(data, 1, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestionChat(questionId), XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))
                tableInsert(data, 1, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestionChatReply(questionId), XMoeWarConfig.RecruitMsgType.MyMsg, isPlayMsgAnima))
            else
                tableInsert(data, 1, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestionChat(questionId), XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))
            end
        end
        return data
    end

    function MoeWarManager.IsQuestionAllRight(helperId)
        local rightQuestionCount = MoeWarManager.GetFinishQuestionCount(helperId)
        local totalCount = XMoeWarConfig.GetMoeWarPreparationHelperTotalQuestionCount(helperId)
        return rightQuestionCount == totalCount
    end

    function MoeWarManager.SetHelperStatus(helperId, status)
        MoeWarPreparationBaseData:SetHelperStatus(helperId, status)
    end

    function MoeWarManager.IsExcludeWrongAnswer(answerIndex)
        return ExcludeWrongAnswersDic[answerIndex] or false
    end

    function MoeWarManager.CheckHelperRedPoint(helperId)
        local status = MoeWarPreparationBaseData:GetHelperStatus(helperId)
        return status == XMoeWarConfig.PreparationHelperStatus.Communicating
    end

    function MoeWarManager.CheckAllHelpersRedPoint()
        local helpersDic = MoeWarPreparationBaseData:GetAllHelpersDic()
        for helperId in pairs(helpersDic) do
            if MoeWarManager.CheckHelperRedPoint(helperId) then
                return true
            end
        end
        return false
    end

    function MoeWarManager.CheckAllOwnHelpersIsResetStatus()
        local ownHelpers = MoeWarPreparationBaseData:GetAllHelpersDic()
        for helperId in pairs(ownHelpers) do
            MoeWarManager.CheckIsResetHelperStatus(helperId)
        end
    end

    function MoeWarManager.CheckIsResetHelperStatus(helperId)
        local isExpired = MoeWarManager.IsHelperExpired(helperId)
        if isExpired then
            XDataCenter.MoeWarManager.SetHelperStatus(helperId, XMoeWarConfig.PreparationHelperStatus.NotCommunicating)
        end
    end

    --已招募的帮手是否过期
    function MoeWarManager.IsHelperExpired(helperId)
        if not XTool.IsNumberValid(helperId) then
            return false
        end
        local nowServerTime = XTime.GetServerNowTimestamp()
        local expirationTime = XDataCenter.MoeWarManager.GetRecruitHelperExpirationTime(helperId)
        local status = MoeWarPreparationBaseData:GetHelperStatus(helperId)
        if expirationTime ~= 0 and nowServerTime >= expirationTime and status == XMoeWarConfig.PreparationHelperStatus.RecruitFinish then
            return true
        end
        return false
    end

    function MoeWarManager.GetMoodValue(helperId)
        return MoeWarPreparationBaseData:GetMoodValue(helperId)
    end

    function MoeWarManager.GetLastMoodValue(helperId)
        return MoeWarPreparationBaseData:GetLastMoodValue(helperId)
    end

    --获得赠礼可增加的心情值
    function MoeWarManager.GetGiftAddMoodValue(helperId)
        local recoveryMood = XMoeWarConfig.GetPreparationHelperGiftRecoveryMood(helperId)
        local amount = MoeWarManager.GetOnceGiftAmount()
        local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
        local curMood = MoeWarManager.GetMoodValue(helperId)
        local addMood = recoveryMood * amount
        return curMood + addMood > moodUpLimit and moodUpLimit - curMood or addMood
    end
    ----招募通讯end
    ----场外应援begin
    function MoeWarManager.GetSupportVoteItemCount(itemId)
        return MoeWarPreparationBaseData:GetVoteItemCount(itemId)
    end

    --返回当前支援类型生效的id
    function MoeWarManager.GetSupportTakeEffectIdByEffectType(effectType)
        local effectIdList = XMoeWarConfig.GetPreparationAssistanceEffectIdList()
        local ownVoteItemCount
        local effectTypeTemp
        local voteItemCount
        local voteItemId
        local effectLevel
        local takeEffectMaxlevel = 0
        local supportTakeEffectId

        for _, effectId in ipairs(effectIdList) do
            effectTypeTemp = XMoeWarConfig.GetPreparationAssistanceEffectType(effectId)
            voteItemCount = XMoeWarConfig.GetPreparationAssistanceVoteItemCount(effectId)
            voteItemId = XMoeWarConfig.GetPreparationAssistanceVoteItemId(effectId)
            ownVoteItemCount = MoeWarManager.GetSupportVoteItemCount(voteItemId)
            effectLevel = XMoeWarConfig.GetPreparationAssistanceLevel(effectId)

            if effectTypeTemp == effectType and ownVoteItemCount >= voteItemCount and effectLevel >= takeEffectMaxlevel then
                takeEffectMaxlevel = effectLevel
                supportTakeEffectId = effectId
            end
        end
        return supportTakeEffectId
    end
    ----场外应援end
    ----选人界面begin
    function MoeWarManager.SetPrepareTeamData(teamData)
        PrepareTeamData = teamData
    end

    function MoeWarManager.GetPrepareTeamData()
        return XTool.IsTableEmpty(PrepareTeamData) and { 0, 0, 0 } or PrepareTeamData
    end

    function MoeWarManager.ClearPrepareTeamData()
        PrepareTeamData = {}
    end

    function MoeWarManager.GetPrepareOwnHelperId(charId)
        if XRobotManager.CheckIsRobotId(charId) then
            return MoeWarManager.GetPreparationOwnHelperIdByRobotId(charId)
        end

        local robotIdToChatId
        local ownHelpers = MoeWarPreparationBaseData:GetAllHelpersDic()
        local robotId
        for helperId in pairs(ownHelpers) do
            robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
            robotIdToChatId = XRobotManager.GetCharacterId(robotId)
            if robotIdToChatId == charId then
                return helperId
            end
        end
        return 0
    end
    ----选人界面end
    --萌战赛事筹备领取奖励
    function MoeWarManager.RequestMoeWarPreparationGearReward(gearId, cb)
        local req = { GearId = gearId }
        XNetwork.Call("MoeWarPreparationGearRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoodsList)
            MoeWarPreparationBaseData:SetOverReceiveRewardGear(gearId)
            if cb then
                cb()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_MOE_WAR_PREPARATION_GEAR_REWARD)
        end)
    end

    --萌战赛事筹备通讯
    --refreshCb：刷新答题界面回调
    --receiveChatHandlerCb：播放问答动画回调
    --currSelectContactBtnIndex：帮手对应的按钮下标
    --setMsgListPanelHelperIdCb：设置当前通讯中的帮手id回调
    --requestFailCb：请求失败回调
    function MoeWarManager.RequestMoeWarPreparationHelperCommunicate(helperId, refreshCb, receiveChatHandlerCb, currSelectContactBtnIndex, setMsgListPanelHelperIdCb, requestFailCb)
        local req = { HelperId = helperId }
        if not XMoeWarConfig.GetPreparationHelperDefaultLock(helperId) then
            return
        end
        XNetwork.Call("MoeWarPreparationHelperCommunicateRequest", req, function(res)
            if res.Code ~= XCode.Success then
                if requestFailCb then
                    requestFailCb()
                end
                XUiManager.TipCode(res.Code)
                return
            end

            if setMsgListPanelHelperIdCb then
                setMsgListPanelHelperIdCb(helperId)
            end

            local setHelperStatus = function()
                local helper = MoeWarPreparationBaseData:GetHelper(helperId)
                if helper:IsRecruitFinish() then
                    MoeWarManager.SetHelperStatus(helperId, XMoeWarConfig.PreparationHelperStatus.RecruitFinishAndCommunicating)
                else
                    MoeWarManager.SetHelperStatus(helperId, XMoeWarConfig.PreparationHelperStatus.Communicating)
                end
            end

            local setData = function()
                MoeWarPreparationBaseData:InsertQuestion(helperId, res.QuestionId)
                MoeWarPreparationBaseData:SetCurrQuestionId(helperId, res.QuestionId)
                SetExcludeWrongAnswers(res.ExcludeWrongAnswers)
            end

            local isPlayMsgAnima = false
            local status = MoeWarPreparationBaseData:GetHelperStatus(helperId)
            --不在通讯中状态
            if status ~= XMoeWarConfig.PreparationHelperStatus.Communicating and status ~= XMoeWarConfig.PreparationHelperStatus.RecruitFinishAndCommunicating then
                --设置状态为通讯中并刷新答题界面
                setHelperStatus()
                if refreshCb then
                    refreshCb(helperId, currSelectContactBtnIndex)
                end

                --插入打招呼和问题
                local data = {}
                local questionStartList = XMoeWarConfig.GetPreparationQuestionIdListByType(helperId, XMoeWarConfig.QuestionType.QuestionStart)
                for _, questionId in ipairs(questionStartList) do
                    tableInsert(data, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestionChat(questionId), XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))
                end
                tableInsert(data, GetQuestionTemplate(res.QuestionId, XMoeWarConfig.GetPreparationQuestion(res.QuestionId), XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))

                --播放问答动画
                if receiveChatHandlerCb then
                    receiveChatHandlerCb(data)
                end
                --设置数据
                setData()

                --刷新除答题界面外的其他界面（不中断问答动画）
                if refreshCb then
                    refreshCb(helperId, currSelectContactBtnIndex, true)
                end
            else
                --正在通讯中状态，不播放问答动画，设置数据并刷新界面
                setHelperStatus()
                setData()
                if refreshCb then
                    refreshCb(helperId, currSelectContactBtnIndex)
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_MOE_WAR_CHECK_RECRUIT_RED_POINT)
        end)
    end

    --萌战赛事筹备通讯答题
    function MoeWarManager.RequestMoeWarPreparationHelperAnswer(helperId, answerId, refreshCb, receiveChatHandlerCb)
        local req = { HelperId = helperId, AnswerId = answerId }
        XNetwork.Call("MoeWarPreparationHelperAnswerRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SetExcludeWrongAnswers({})

            local preparationHelper = MoeWarPreparationBaseData:GetHelper(helperId)

            local questionId = MoeWarPreparationBaseData:GetCurrQuestionId(helperId)
            MoeWarPreparationBaseData:UpdateAnswerRecord(helperId, answerId, res.IsRight)
            if res.IsRight then
                MoeWarPreparationBaseData:AddOnceFinishQuestionCount(helperId)
            end

            local isPlayMsgAnima = false    --回答错误播放动画
            local replyDesc = res.IsRight and XMoeWarConfig.GetPreparationQuestionRightReply(questionId) or XMoeWarConfig.GetPreparationQuestionWrongReply(questionId)
            local recruitMsgType = res.IsRight and XMoeWarConfig.RecruitMsgType.MyYes or XMoeWarConfig.RecruitMsgType.MyNo
            local myDesc = XMoeWarConfig.GetPreparationQuestionAnswer(questionId, answerId)
            local data = {}
            tableInsert(data, GetQuestionTemplate(questionId, myDesc, recruitMsgType, isPlayMsgAnima))
            tableInsert(data, GetQuestionTemplate(questionId, replyDesc, XMoeWarConfig.RecruitMsgType.OtherMsg, not res.IsRight))
            tableInsert(data, GetQuestionTemplate(0, "", XMoeWarConfig.RecruitMsgType.Line, isPlayMsgAnima))

            local isQuestionAllRight = MoeWarManager.IsQuestionAllRight(helperId)
            if res.NextQuestionId ~= 0 then --下个题目id，0表示没有题目了
                MoeWarPreparationBaseData:InsertQuestion(helperId, res.NextQuestionId)
                tableInsert(data, GetQuestionTemplate(res.NextQuestionId, XMoeWarConfig.GetPreparationQuestion(res.NextQuestionId), XMoeWarConfig.RecruitMsgType.OtherMsg, isPlayMsgAnima))
            else
                --已招募的角色不管是否全答对，状态都设为已招募
                local status
                if preparationHelper:IsRecruitFinish() then
                    status = XMoeWarConfig.PreparationHelperStatus.RecruitFinish
                else
                    status = isQuestionAllRight and XMoeWarConfig.PreparationHelperStatus.RecruitFinish or XMoeWarConfig.PreparationHelperStatus.CommunicationEnd
                end
                MoeWarManager.SetHelperStatus(helperId, status)
                if receiveChatHandlerCb then
                    local questionType = isQuestionAllRight and XMoeWarConfig.QuestionType.RecruitRight or XMoeWarConfig.QuestionType.RecruitLose
                    local questionId = XMoeWarConfig.GetPreparationQuestionId(helperId, questionType)
                    tableInsert(data, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestionChat(questionId), XMoeWarConfig.RecruitMsgType.OtherMsg, questionType == XMoeWarConfig.QuestionType.RecruitLose))
                    tableInsert(data, GetQuestionTemplate(questionId, XMoeWarConfig.GetPreparationQuestionChatReply(questionId), XMoeWarConfig.RecruitMsgType.MyMsg, isPlayMsgAnima))
                end
            end

            if receiveChatHandlerCb then
                receiveChatHandlerCb(data)
            end

            if refreshCb then
                refreshCb()
            end

            if res.NextQuestionId == 0 then
                if isQuestionAllRight or preparationHelper:IsRecruitFinish() then
                    preparationHelper:ResetData()
                else
                    MoeWarPreparationBaseData:ClearAnswerRecords(helperId)
                end
            end
            MoeWarPreparationBaseData:SetCurrQuestionId(helperId, res.NextQuestionId)
            XEventManager.DispatchEvent(XEventId.EVENT_MOE_WAR_CHECK_RECRUIT_RED_POINT)
        end)
    end

    --萌战赛事筹备答题场外援助
    function MoeWarManager.RequestMoeWarPreparationAssistance(helperId, cb)
        local req = { HelperId = helperId }
        XNetwork.Call("MoeWarPreparationAssistanceRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SetExcludeWrongAnswers(res.ExcludeWrongAnswers)
            if cb then
                cb()
            end
        end)
    end

    --萌战赛事关卡扫荡
    function MoeWarManager.RequestMoeWarPreparationHelperSweep(helperId, stageId)
        local req = { HelperId = helperId, StageId = stageId }
        XNetwork.Call("MoeWarPreparationHelperSweepRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end)
    end

    --萌战赛事赠送礼物
    function MoeWarManager.RequestMoeWarPreparationHelperSendGift(helperId, receiveChatHandlerCb)
        local amount = MoeWarManager.GetOnceGiftAmount()
        local req = { 
            HelperId = helperId, 
            Amount = amount,    --礼物数量
        }
        XNetwork.Call("MoeWarPreparationHelperSendGiftRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local data = {}
            local thankId = XMoeWarConfig.GetPreparationHelperThankId(helperId)
            tableInsert(data, GetQuestionTemplate(0, XMoeWarConfig.GetThankText(thankId), XMoeWarConfig.RecruitMsgType.GiftThank, false))

            if receiveChatHandlerCb then
                receiveChatHandlerCb(data)
            end
        end)
    end

    --推送萌战赛事筹备数据（进入服务器、活动重置、赛事阶段变更推送）
    function MoeWarManager.NotifyMoeWarPreparationData(data)
        JudgeGotoMain(data.Data.MatchId, data.Data.ActivityId)
        MoeWarPreparationBaseData:UpdateData(data.Data)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE)
    end

    --萌战赛事筹备关卡变化
    function MoeWarManager.NotifyMoeWarPreparationStage(data)
        MoeWarPreparationBaseData:UpdateStage(data.Stage)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_PREPARATION_STAGE)
    end

    --萌战赛事筹备援助变化
    function MoeWarManager.NotifyMoeWarPreparationAssistance(data)
        MoeWarPreparationBaseData:UpdateAssistance(data.Assistance)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_PREPARATION_NOTIFY_ASSISTANCE)
    end

    --萌战赛事筹备应援道具变化
    function MoeWarManager.NotifyMoeWarPreparationVoteItem(data)
        MoeWarPreparationBaseData:UpdateVoteItem(data.VoteItem)
    end

    --萌战招募成功推送
    function MoeWarManager.NotifyMoeWarPreparationHelper(data)
        local helper = data.Helper
        local preparationHelper = MoeWarPreparationBaseData:GetHelper(helper.Id)
        if preparationHelper:GetStatus() ~= helper.Status then
            MoeWarManager.SetHelperStatus(helper.Id, helper.Status)
        end
        MoeWarPreparationBaseData:SetHelperExpirationTime(helper.Id, helper.ExpirationTime)
        preparationHelper:UpdateMoodValue(helper.MoodValue)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_HELPER_NOTIFY)
    end

    --萌战赛事筹备每日重置
    function MoeWarManager.NotifyMoeWarPreparationDailyReset(data)
        MoeWarPreparationBaseData:ClearGetRewardGears()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_PREPARATION_DAILY_RESET)
    end
    ---------------------赛事筹备 end--------------------
    --萌战排行榜请求
    function MoeWarManager.RequestRank(rankType, playerId, cb)
        if not RankCache[rankType] then
            return
        end
        local cache = RankCache[rankType][playerId]
        if cache then
            local nowTime = XTime.GetServerNowTimestamp()
            if nowTime <= cache.RefreshTime + RankReqIntervalTime then
                if cb then
                    cb(cache)
                end 
                return
            end
        end

        local req = { RankType = rankType, PlayerId = playerId }
        XNetwork.Call("MoeWarOpenRankRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if cb then
                    cb({ RankingList = {} })
                end
                return
            end

            local nowTime = XTime.GetServerNowTimestamp()
            local rankData = { RefreshTime = nowTime,
            UserRank = res.MyRankInfo,
            RankingList = res.RankList,}
            RankCache[rankType][playerId] = rankData

            if cb then
                cb(rankData)
            end
        end)
    end

    --萌战排行榜请求
    function MoeWarManager.ClearCache()
        for _, v in pairs(XMoeWarConfig.RankType) do
            RankCache[v] = {}
        end
    end
    ---------------------活动相关 begin--------------------
    function MoeWarManager.GetActivityStartTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetStartTimeByTimeId(DefaultActivityInfo.ActivityTimeId) or 0
        end
        return 0
    end

    function MoeWarManager.GetActivityEndTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetEndTimeByTimeId(DefaultActivityInfo.ActivityTimeId) or 0
        end
        return 0
    end

	function MoeWarManager.OnOpenMain()
		if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MoeWar) then
			return
		end
		if not MoeWarManager.IsOpen() then
			XUiManager.TipText("MoeWarNotOpen")
			return
		end
		local isPlayedStory = XSaveTool.GetData(string.format("%s_%s","MoeWarPlayedStory",XPlayer.Id))
		if isPlayedStory then
			XLuaUiManager.Open("UiMoeWarMain")
		else
			if ActivityInfo and XMovieConfigs.CheckMovieConfigExist(XMoeWarConfig.GetBeginStoryId()) then
				XDataCenter.MovieManager.PlayMovie(XMoeWarConfig.GetBeginStoryId(), function()
						XLuaUiManager.Open("UiMoeWarMain")
						XSaveTool.SaveData(string.format("%s_%s","MoeWarPlayedStory",XPlayer.Id),true)
					end, nil, nil, false)
			else
				XLog.Error("剧情不存在 MovieId:",ActivityInfo.BeginStoryId)
				XLuaUiManager.Open("UiMoeWarMain")
			end
		end
	end

    function MoeWarManager.IsOpen()
        if not ActivityInfo then return false end
        return XFunctionManager.CheckInTimeByTimeId(ActivityInfo.ActivityTimeId)
    end

    function MoeWarManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end

        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
    end
	
	function MoeWarManager.OpenVotePanel(index)
		local match = MoeWarManager.GetCurMatch()
		local key = string.format("%s_%s","MOE_WAR_VOTE_SHOW_MATCH_SCENE",tostring(XPlayer.Id))
		local isShowMatchPanel = XSaveTool.GetData(key)
		if match and match:GetSessionId() == XMoeWarConfig.SessionType.GameInAudition and match:GetType() == XMoeWarConfig.MatchType.Voting then
			if not isShowMatchPanel then
				XLuaUiManager.Open("UiMoeWarGroupList")
			else
				XLuaUiManager.Open("UiMoeWarVote",index)
			end
		else
            XLuaUiManager.Open("UiMoeWarVote", index)
		end
	end

    function MoeWarManager.GetActivityChapter()
        local chapters = {}
        if MoeWarManager.IsOpen() then
            local temp = {}
            local template = MoeWarManager.GetActivityInfo()
            temp.Id = template.Id
            temp.Name = template.Name
            temp.Background = template.Background
            temp.Type = XDataCenter.FubenManager.ChapterType.MoeWar
            tableInsert(chapters, temp)
        end
        return chapters
    end
	
	function MoeWarManager.RequestShare(playerId,cb)
		local req = {PlayerId = playerId}
		XNetwork.Call("MoeWarShareRequest", req, function(res)
				if res.Code ~= XCode.Success then
					XUiManager.TipCode(res.Code)
					return
				end
				if cb then
					cb()
				end
			end)
		
	end

    -- 战斗结束后判断是否跳到主界面
    function MoeWarManager.JudgeGotoMainWhenFightOver()
        if not XLuaUiManager.IsUiLoad("UiMoeWarPreparation") then
            StatusInFightChangeCache = false
            return
        end

        if not StatusInFightChangeCache then
            return false
        end

        StatusInFightChangeCache = false
        XUiManager.TipText("ActivityStateChange")
        XLuaUiManager.RunMain()
        XLuaUiManager.Open("UiMoeWarMain")
    end
    ---------------------活动相关 end--------------------
    ---------------------任务相关 begin--------------------
    function MoeWarManager.GetTaskListByType(type,groupId)
		local taskList = {}
		local sortList = {}
        if type == XMoeWarConfig.TaskType.Daily then
            taskList = XDataCenter.TaskManager.GetMoeWarDailyTaskList()
        else
            taskList =  XDataCenter.TaskManager.GetMoeWarNormalTaskList()
        end
		for id,task in pairs(taskList) do
			local config = XTaskConfig.GetTaskCfgById(task.Id)
			if config.GroupId == groupId then
				tableInsert(sortList,task)
			end
		end
		return sortList
    end
	
	function MoeWarManager.CheckTaskRedPoint(type,groupId)
		local taskList = MoeWarManager.GetTaskListByType(type,groupId)
		for _,task in pairs(taskList) do
			if XDataCenter.TaskManager.CheckTaskAchieved(task.Id) then
				return true
			end
		end
		return false
	end
	

    ---------------------任务相关 end--------------------
    ---------------------场景动画相关 begin--------------------
    --public class XMoeWarPlayerPair <==> pairInfo
    --{
    --    public int WinnerId;
    --    public int SecondId;
    --    public List<int> Players = new List<int>();
    --}
    function MoeWarManager.EnterAnimation(pairInfo, matchEntity, closeCallback)
        local winnerIndex = 0
        local animGroupIds = {}

        local match = matchEntity or XDataCenter.MoeWarManager.GetCurMatch()
        local sessionId = match:GetSessionId()

        for index, playerId in ipairs(pairInfo.Players) do
            local animGroupId

            if XTool.IsNumberValid(playerId) then
                local player = MoeWarManager.GetPlayer(playerId)

                if playerId == pairInfo.WinnerId then
                    winnerIndex = index
                    animGroupId = player:GetWinAnimGroupId(sessionId)
                elseif playerId == pairInfo.SecondId then
                    animGroupId = player:GetSecondAnimGroupId(sessionId)
                else
                    animGroupId = player:GetLoseAnimGroupId(sessionId)
                end

                tableInsert(animGroupIds, animGroupId)
            end
        end

        if not XTool.IsNumberValid(winnerIndex) then
            XLog.Error("MoeWarManager.EnterAnimation error: 萌战动画播放错误，找不到胜利者，pairInfo：", pairInfo)
            return
        end

        XLuaUiManager.Open("UiMoeWarAnimation", animGroupIds, winnerIndex, closeCallback, pairInfo.Players, match)
    end
    ---------------------场景动画相关 end--------------------
    ---------------------通用 begin--------------------
    function MoeWarManager.CheckRespondItemIsMax(isShow)
        local match = XDataCenter.MoeWarManager.GetCurMatch()
        if not match then
            return false
        end

        --公示期不弹出提示框
        if not isShow then
            local matchType = match:GetType()
            local session = match:GetSessionId()
            if matchType ~= XMoeWarConfig.MatchType.Voting then
                return false
            end
        end

        local itemId = XDataCenter.ItemManager.ItemId.MoeWarRespondItemId
        local itemMaxCount = XDataCenter.ItemManager.GetMaxCount(itemId)
        local itemCount = XDataCenter.ItemManager.GetCount(itemId)
        if itemCount == itemMaxCount then
            local itemName = XDataCenter.ItemManager.GetItemName(itemId)
            local title = CSXTextManagerGetText("MoeWarRespondItemMaxTitle", itemName)
            local content = CSXTextManagerGetText("MoeWarRespondItemMaxDesc", itemName)
            local sureCallback = function()
                XLuaUiManager.Open("UiMoeWarVote")
            end
            XUiManager.DialogTip(title, content, nil, nil, sureCallback, {sureText = CSXTextManagerGetText("MoeWarGoToVote")})
            return true
        end
        return false
    end
    
    --region   ------------------跑酷相关 start-------------------
    --==============================
    ---@desc 跳转到跑酷小游戏
    --==============================
    function MoeWarManager.JumpToParkour()
        if not XTool.IsNumberValid(ParkourActivityId) then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end
        
        if not MoeWarManager.ParkourIsOpen() then
            XUiManager.TipText("FubenRepeatNotInActivityTime")
            return
        end
        
        XLuaUiManager.Open("UiMoeWarParkourMain")
    end

    --==============================
    ---@desc 跑酷关卡列表
    ---@return table
    --==============================
    function MoeWarManager.GetParkourStageList()
        local list = {}
        for _, stage in pairs(ParkourStageDict) do
            tableInsert(list, stage)
        end
        tableSort(list, function(a, b) 
            return a:GetId() < b:GetId()
        end)
        return list
    end
    
    --==============================
     ---@desc 获取关卡数据类
     ---@stageId 关卡Id 
     ---@return @Class XMoeWarParkourStage
    --==============================
    function MoeWarManager.GetStageById(stageId)
        if not XTool.IsNumberValid(stageId) then
            return
        end
        if stageId == XMoeWarConfig.GetParkourTeachStageId(ParkourActivityId) then
            return ParkourTeachStage
        end
        return ParkourStageDict[stageId]
    end
    
    --==============================
     ---@desc 跑酷活动开启时间
     ---@return number
    --==============================
    function MoeWarManager.GetParkourStartTime()
        return XMoeWarConfig.GetParkourStartTime(ParkourActivityId)
    end

    --==============================
    ---@desc 跑酷活动关闭时间
    ---@return number
    --==============================
    function MoeWarManager.GetParkourEndTime()
        return XMoeWarConfig.GetParkourEndTime(ParkourActivityId)
    end
    
    --==============================
     ---@desc 跑酷奖励Id
     ---@return number
    --==============================
    function MoeWarManager.GetParkourRewardId()
        return XMoeWarConfig.GetParkourRewardId(ParkourActivityId) or 0
    end
    
    --==============================
     ---@desc 跑酷开启
     ---@return boolean
    --==============================
    function MoeWarManager.ParkourIsOpen()
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfBgn = MoeWarManager.GetParkourStartTime()
        local timeOfEnd = MoeWarManager.GetParkourEndTime()
        
        return timeOfNow >= timeOfBgn and timeOfNow <= timeOfEnd
    end
    
    --==============================
     ---@desc 跑酷角色列表
     ---@roleType 角色类型 1.泛用 2.独域
     ---@return table
    --==============================
    function MoeWarManager.GetOwnHelperId(roleType)
        local list = MoeWarManager.GetAllOwnHelpersList()
        if not XTool.IsNumberValid(roleType) then
            return list
        end
        local tmpList = {}
        for _, helperId in ipairs(list) do
            local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
            local type = XRobotManager.GetRobotCharacterType(robotId)
            if type == roleType then
                tableInsert(tmpList, helperId)
            end
        end
        return tmpList
    end
    
    --==============================
     ---@desc 检查助手是否已经招募
     ---@helperId 助手Id 
     ---@return boolean
    --==============================
    function MoeWarManager.CheckHelperIsOwn(helperId)
        if not XTool.IsNumberValid(helperId) then
            return false
        end
        local helperDic = MoeWarPreparationBaseData:GetAllHelpersDic()
        return helperDic[helperId] and true or false
    end
    
    --==============================
     ---@desc 代理FubenManager的胜利结算界面
     ---@winData 战斗胜利数据
     ---@playEndStory 代理FubenManager的胜利结算界面
    --==============================
    function MoeWarManager.ShowReward(winData, playEndStory)
        XLuaUiManager.Open("UiMoeWarParkourSettle", winData)
    end
    
    function MoeWarManager.GetParkourTeam()
        local teamId = XMoeWarConfig.KEY_PARKOUR_TEAM..XPlayer.Id.."_MoeWarManager"
        ParkourTeam = ParkourTeam or XTeam.New(teamId)
        return ParkourTeam
    end
    
    function MoeWarManager.ClearParkourTeam()
        if not ParkourTeam then 
            return 
        end
        ParkourTeam:Clear()
    end
    
    --==============================
     ---@desc 当日票数限制
     ---@return number
    --==============================
    function MoeWarManager.GetParkourTicket()
        return (ParkourMaxTicket - ParkourTicket) * ParkourTicketMagnification
    end
    
    --==============================
     ---@desc 刷新票数
     ---@tickets 票数 
    --==============================
    function MoeWarManager.RefreshParkourTicket(tickets)
        ParkourTicket = tickets
    end
    
    --==============================
     ---@desc 进跑酷战斗前，更新历史心情值，方便结算计算心情改变值
     ---@helperId 帮手Id 
    --==============================
    function MoeWarManager.RefreshLastMoodValue(helperId)
        if not XTool.IsNumberValid(helperId) then
            return
        end
        local helper = MoeWarPreparationBaseData:GetHelper(helperId)
        helper:UpdateMoodValue(helper.MoodValue)
    end
    
    --==============================
     ---@desc 跑酷阶段转换
    --==============================
    function MoeWarManager.OnPreparationDataUpdate()
        -- 通过PopTheOpen打开，须一级一级关闭，注意顺序
        local needCloseUiList = {
            "UiMoeWarParkourPerson", "UiMoeWarParkourPrepare", "UiMoeWarParkourMain"
        }
        for _, uiName in ipairs(needCloseUiList) do
            if XLuaUiManager.IsUiShow(uiName) then
                XLuaUiManager.Close(uiName)
            end
        end
        XUiManager.TipText("MoeWarParkourQuit")
    end
    
    --==============================
     ---@desc 跳转到跑酷教学关卡
    --==============================
    function MoeWarManager.JumpToTeach()
        XLuaUiManager.Open("UiMoeWarParkourPrepare", ParkourTeachStage)
    end
    
    --==============================
     ---@desc 跑酷教学关关卡Id
     ---@return number
    --==============================
    function MoeWarManager.GetParkourTeachStageId()
        return XMoeWarConfig.GetParkourTeachStageId(ParkourActivityId)
    end
    
    --==============================
     ---@desc 刷新跑酷数据，登录下发
     ---@data NotifyMoeWarParkourData 
    --==============================
    function MoeWarManager.NotifyMoeWarParkourData(data)
        ParkourActivityId = data.ActivityId
        ParkourTicket = data.DailyReward
        InitParkourData()
        local list = data.StageDataList
        for _, stageData in ipairs(list or {}) do
            local stageId = stageData.StageId
            local stage = ParkourStageDict[stageId]
            if stage then
                stage:RefreshAllTimeHigh(stageData.MaxScore)
            end
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_PARKOUR_UPDATE)
    end
    --endregion------------------跑酷相关 finish------------------
    
    --region   ------------------铭牌商店相关 start-------------------
    --==============================
     ---@desc 获取当前角色的铭牌列表
     ---@shopType 角色类型 
     ---@return table
    --==============================
    function MoeWarManager.GetMoeWarItemList(shopType)
        local nameplateList
        local cfgList = XMoeWarConfig.GetMoeWarNameplateList()
        if not XTool.IsNumberValid(shopType) then
            nameplateList = {}
            for _, cfg in pairs(cfgList) do
                for _, nId in ipairs(cfg.NameplateId) do
                    table.insert(nameplateList, nId)
                end
            end
        else
            local cfg = cfgList[shopType]
            if not cfg then return {} end
            nameplateList = cfg.NameplateId
        end
        local sortTmp = {
            [true]  = 2,
            [false] = 1
        }
        tableSort(nameplateList, function(a, b) 
            local unlockA = XDataCenter.MoeWarManager.CheckHaveNameplateById(a)
            local unlockB = XDataCenter.MoeWarManager.CheckHaveNameplateById(b)
            if unlockA ~= unlockB then
               return sortTmp[unlockA] < sortTmp[unlockB]
            end
            
            return a < b
        end)
        return nameplateList
    end
    
    --==============================
     ---@desc 判断名牌是否解锁
     ---@nameplateId 铭牌Id 
     ---@return boolean
    --==============================
    function MoeWarManager.CheckHaveNameplateById(nameplateId)
        local list = XDataCenter.MedalManager.GetNameplateGroupList()
        local unlockDict = {}
        
        for _, group in ipairs(list) do
            local id = group:GetNameplateId()
            unlockDict[id] = true
            local preId = XMoeWarConfig.GetPreNameplateId(id)
            while XTool.IsNumberValid(preId) do
                unlockDict[preId] = true
                preId = XMoeWarConfig.GetPreNameplateId(preId)
            end
        end
        return unlockDict[nameplateId] or false
    end
    
    --==============================
     ---@desc 商店购买物品
     ---@itemId 铭牌Id 
     ---@cb 回调 
    --==============================
    function MoeWarManager.BuyNameplate(itemId, cb)
        
        XNetwork.Call("MoeWarNameplateStoreBuyRequest", { NameplateId = itemId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then cb() end
        end)
    end
    
    --endregion------------------铭牌商店相关 finish------------------
   
    ---------------------通用 begin--------------------
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, Init)
    return MoeWarManager
end

---------------------(服务器推送)begin------------------
XRpc.NotifyMoeWarActivityData = function(data)
    --XDataCenter.MoeWarManager.HandleActivityData(data)
end

XRpc.NotifyMoeWarPreparationData = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarPreparationData(data)
end

XRpc.NotifyMoeWarPreparationStage = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarPreparationStage(data)
end

XRpc.NotifyMoeWarVoteRecord = function(data)
	--XDataCenter.MoeWarManager.NotifyMoeWarVoteScreenRecord(data)
end

XRpc.NotifyMoeWarVoteShowChange = function(data)
	--XDataCenter.MoeWarManager.NotifyMoeWarVoteShowChange(data)
end

XRpc.NotifyMoeWarDailyReset = function(data)
	--XDataCenter.MoeWarManager.NotifyMoeWarDailyReset(data)
end

XRpc.NotifyMoeWarPreparationAssistance = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarPreparationAssistance(data)
end

XRpc.NotifyMoeWarPreparationVoteItem = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarPreparationVoteItem(data)
end

XRpc.NotifyMoeWarPreparationHelper = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarPreparationHelper(data)
end

XRpc.NotifyMoeWarPreparationDailyReset = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarPreparationDailyReset(data)
end

XRpc.NotifyMoeWarParkourData = function(data)
    --XDataCenter.MoeWarManager.NotifyMoeWarParkourData(data)
end
---------------------(服务器推送)end--------------------