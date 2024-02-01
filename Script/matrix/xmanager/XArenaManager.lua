local XExFubenSimulationChallengeManager = require("XEntity/XFuben/XExFubenSimulationChallengeManager")
---
--- 竞技副本管理器
---

XArenaManagerCreator = function()
    local XArenaManager = XExFubenSimulationChallengeManager.New(XFubenConfigs.ChapterType.ARENA)

    local SYNC_RANK_LIST_SECOND = 60        --获取排行榜List请求保护时间
    local SYNC_HALL_SECOND = 5              --获取其他请求保护时间
    local SYNC_OTHER_SECOND = 15            --获取其他请求保护时间
    local SYNC_GOURP_MEMBER_SECOND = 10     --请求小队排行保护时间

    local LastSyncRankListTime = 0   --排行榜List最后刷新时间
    local LastHallTeamListTime = 0   --大厅队伍列表最后刷新时间
    local LastHallPlayerListTime = 0 --大厅个人玩家列表最后刷新时间
    local LastFriendPlayerTime = 0   --请求好友竞技信息最后刷新时间
    local LasGroupMemberTime = 0   --请求小队排信息最后刷新时间

    --队伍数据
    local HallTeamMap = {}      --大厅队伍
    local HallPlayerMap = {}    --大厅玩家
    local FriendMap = {}        --好友列表
    local TeamInfo = nil    --队伍信息
    local ApplyMap = {}     --申请列表
    local InviteMap = {}    --邀请列表
    local HaveToRequestApplyData = -1

    local APPLY_TYPE = {
        TEAM = 1, --自己有队伍
        SINGLE = 2, --自己无队伍
    }

    --竞技全局数据
    local ActivityNo = 0            -- 活动编号
    local LastActivityNo = 0        -- 上一期活动编号
    local ActivityStatus = XArenaActivityStatus.Default   --当前活动状态
    local CountDownTime = 0         -- 进入下一阶段倒计时
    local TeamStartTime = 0         -- 组队期开始时间
    local FightStartTime = 0        -- 战斗期开始时间
    local ResultStartTime = 0       -- 结算期开始时间
    local WaveRate = 0              -- 波动指数
    local WaveLastRate = 0          -- 上一期波动指数
    local GroupFightEvent = nil       --战区Buff

    --竞技排行数据
    local PlayerResultRankList = {}         -- 该段位玩家排行
    local PlayerLoaclResultRanlList = nil   -- 该段位玩家排行(本地数据)
    local PlayerLastResultRanlList = {}    -- 该段位上一期玩家排行
    local TeamRankChallengeId = 0           -- 队伍排行榜的挑战ID
    local TeamRankData = {}                 -- 队伍排行
    local TeamResultList = {}               -- 该段位队员成绩
    local TeamLastResultList = nil           -- 该段位队员上一期成绩
    -- local AreaIdToStageDetailList = {}      -- 各战区玩家通关详情
    local LastDataRespone = nil

    --竞技个人数据
    local ChallengeId = 0           -- 挑战Id（根据玩家等级与竞技段位决定）
    local ContributeScore = 0       -- 当前战区贡献总分
    local LastChallengeId = 0       -- 上一期挑战Id（根据玩家等级与竞技段位决定）
    local ArenaLevel = 0            -- 竞技段位
    local LastArenaLevel = 0        -- 上一期竞技段位
    local LastContributeScore = 0   --上一期战区贡献分
    local IsJoinActivity = false    -- 是否已报名
    local UnlockCount = 0           -- 剩余解锁次数
    local TotalPoint = 0            -- 总分数
    local AreaDatas = {}            -- 战区信息列表

    local ArenaActivityResultData = nil  --竞技奖励缓存数据
    local ArenaStatusInFightChangeCache = false -- 竞技状态改变是否在战斗中缓存

    local EnterAreaStageInfo = {}   -- 进入战斗的区域信息

    local MaxPointStageDic = {}     -- 已经通关的满分列表

    local ArenaRequest = {
        RequestMyTeamInfo = "MyTeamRequest", -- 获取我的队伍信息
        RequestHallTeamList = "HallTeamRequest", -- 获取大厅队伍列表
        RequestHallPlayerList = "HallPlayerRequest", -- 获取大厅个人玩家列表
        RequestApplyData = "ApplyDataRequest", -- 获取邀请申请信息列表
        RequestFriendArenaInfo = "FriendPlayerRequest", -- 请求好友竞技信息
        RequestCreateTeam = "CreateTeamRequest", -- 请求创建队伍
        RequestApplyTeam = "ApplyTeamRequest", -- 申请入队
        RequestRefuseApply = "RefuseApplyRequest", -- 拒绝申请
        RequestAcceptApply = "AcceptApplyRequest", -- 接受申请
        RequestLeaveTeam = "LeaveTeamRequest", -- 请求离队
        RequestKickTeam = "KickTeamRequest", -- 请求踢人
        RequestInvitePlayer = "InvitePlayerRequest", -- 邀请玩家
        RequestRefuseInvite = "PersonalRefuseRequest", -- 拒绝邀请
        RequestAcceptInvite = "PersonalAcceptRequest", -- 接受邀请

        RequestSignUpArena = "JoinActivityRequest", -- 报名参加竞技活动

        RequestGroupMember = "GroupMemberRequest", -- 请求主页面成员信息
        RequestAreaData = "AreaDataRequest", -- 请求区域信息
        RequestStagePassDetail = "StagePassDetailRequest", -- 请求通关详情
        RequestUnlockArea = "UnlockAreaRequest", -- 请求解锁战区

        RequestTeamRankData = "TeamRankDataRequest", -- 请求队伍排行
        ScoreQueryReq = "ScoreQueryRequest", -- 请求上一期主页面成员信息
        AreaAutoFightRequest = "AreaAutoFightRequest",
        ArenaChallengeGetRankRequest = "ArenaChallengeGetRankRequest",  --根据ChallengeId获取个人排行榜
    }

    ----------------------------Team start--------------------------

    --监听UI界面打开事件
    --function XArenaManager.Init()
    --    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ENABLE, function(_, ui)
    --        XArenaManager.OpenArenaActivityResult(ui[0].UiData.UiName)
    --    end)
    --end

    -- 打开竞技奖励界面
    function XArenaManager.OpenArenaActivityResult()
        if ArenaActivityResultData == nil then
            return
        end

        XLuaUiManager.Open("UiArenaActivityResult", ArenaActivityResultData, function()
            ArenaActivityResultData = nil
        end)
    end
    
    function XArenaManager.GetGroupFightEvent()
        return GroupFightEvent
    end
    
    function XArenaManager.GetActivityNo()
        return ActivityNo
    end
    
    function XArenaManager.GetChallengeId()
        return ChallengeId
    end

    -- 检测竞技奖励界面
    function XArenaManager.CheckOpenArenaActivityResult()
        if ArenaActivityResultData == nil then
            return false
        end

        XLuaUiManager.Open("UiArenaActivityResult", ArenaActivityResultData, function()
            ArenaActivityResultData = nil
        end, function()
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_RESULT_CLOSE)
        end)

        return true
    end

    -- 处理竞技活动结果
    function XArenaManager.HandleArenaActivityResult(data)
        ArenaLevel = data.NewArenaLevel
        ContributeScore = data.ContributeScore
        ArenaActivityResultData = data
    end

    -- 获取我队队伍Id
    function XArenaManager.GetTeamId()
        if not TeamInfo then
            return 0
        end

        return TeamInfo.TeamId or 0
    end

    -- 检测指定玩家是否是我队队长
    function XArenaManager.CheckPlayerIsCaptain(Id)
        if not Id then
            return false
        end

        if Id == 0 then
            return false
        end

        if not TeamInfo then
            return false
        end

        local captain = TeamInfo.Captain or 0
        return captain == Id
    end

    -- 检测自己是否是我队队长
    function XArenaManager.CheckSelfIsCaptain()
        return XArenaManager.CheckPlayerIsCaptain(XPlayer.Id)
    end

    -- 获取我的队伍成员列表
    function XArenaManager.GetMyTeamMemberList()
        if not TeamInfo then
            return {}
        end

        return TeamInfo.ShowList
    end

    -- 获取大厅玩家列表
    function XArenaManager.GetHallPlayerList()
        local list = {}

        if HallPlayerMap then
            for _, v in pairs(HallPlayerMap) do
                table.insert(list, v)
            end
        end

        return list
    end

    -- 获取大厅队伍列表
    function XArenaManager.GetHallTeamList()
        local list = {}

        if HallTeamMap then
            for _, v in pairs(HallTeamMap) do
                table.insert(list, v)
            end
        end

        return list
    end

    -- 获取申请数据列表
    function XArenaManager.GetApplyDataList()
        local teamId = XArenaManager.GetTeamId()
        local list = {}
        if teamId > 0 then
            if XArenaManager.CheckSelfIsCaptain() then
                for _, v in pairs(ApplyMap) do
                    table.insert(list, v)
                end
                return list
            else
                return list
            end
        else
            for _, v in pairs(InviteMap) do
                table.insert(list, v)
            end
            return list
        end
    end

    -- 检测是否有申请数据
    function XArenaManager.CheckHaveApplyData()
        local list = XArenaManager.GetApplyDataList()
        return #list > 0 or HaveToRequestApplyData > 0
    end

    -- 获取竞技好友列表
    function XArenaManager.GetArenaFriendList()
        local list = {}

        if FriendMap then
            for _, v in pairs(FriendMap) do
                table.insert(list, v)
            end
        end

        table.sort(list, function(a, b)
            local isSameIdA = ChallengeId == a.ChallengeId
            local isSameIdB = ChallengeId == b.ChallengeId
            if isSameIdA ~= isSameIdB then
                return isSameIdA
            end

            local isEnterFightA = a.ChallengeId > 0
            local isEnterFightB = b.ChallengeId > 0
            if isEnterFightA ~= isEnterFightB then
                return isEnterFightB
            end

            return a.Info.Id > b.Info.Id
        end)

        return list
    end

    -- 处理被队长踢出队伍
    function XArenaManager.HandleIsKickedByCaptain()
        TeamInfo = {}
        XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_CHANGE)
    end

    -- 收到新申请信息
    function XArenaManager.HandleNewApplyData()
        HaveToRequestApplyData = 1
        XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_NEW_APPLY_ENTER)
    end

    -- 处理队伍信息
    function XArenaManager.HandleTeamInfo(info)
        if (not TeamInfo or not TeamInfo.TeamId) and info.TeamId > 0 and HaveToRequestApplyData > 0 then
            HaveToRequestApplyData = 0
        end

        TeamInfo = info

        XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_CHANGE)
    end

    -- 处理大厅队伍列表
    function XArenaManager.HandleHallTeamList(data)
        HallTeamMap = {}
        for _, v in ipairs(data.TeamList) do
            HallTeamMap[v.Info.TeamId] = v
        end
    end

    -- 处理大厅玩家列表
    function XArenaManager.HandleHallPlayerList(data)
        HallPlayerMap = {}
        for _, v in ipairs(data.PlayerList) do
            HallPlayerMap[v.Info.Id] = v
        end
    end

    -- 处理好友列表
    function XArenaManager.HandleFriendList(data)
        FriendMap = {}
        if data and data.FriendPlayerList then
            for _, v in ipairs(data.FriendPlayerList) do
                --TODO 筛选相同段位的
                FriendMap[v.Info.Id] = v
            end
        end
    end

    -- 处理邀请申请信息列表
    function XArenaManager.HandleApplyData(data)
        if not data then
            return
        end

        ApplyMap = {}
        InviteMap = {}

        local map = {}
        for _, v in ipairs(data.ApplyList) do
            map[v.Id] = v
        end

        if data.ApplyType == APPLY_TYPE.SINGLE then
            --队伍邀请信息列表
            InviteMap = map
        elseif data.ApplyType == APPLY_TYPE.TEAM then
            --玩家请求消息列表
            ApplyMap = map
        end

        XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_RECEIVE_APPLY_DATA)
    end

    -- 检查是否在组队期状态
    function XArenaManager.CheckInTeamState()
        return ActivityStatus == XArenaActivityStatus.Rest
    end

    -- 检查是否在战斗期状态
    function XArenaManager.CheckInFightState()
        return ActivityStatus == XArenaActivityStatus.Fight
    end

    -- 检查玩家是否可以打纷争战区副本
    function XArenaManager.IsPlayerCanEnterFight()
        local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenArena)
        return isOpen and XArenaManager.CheckInFightState()
    end

    -- 获取我的队伍信息
    function XArenaManager.RequestMyTeamInfo(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        if TeamInfo then
            if cb then
                cb()
            end
            return
        end

        XNetwork.Call(ArenaRequest.RequestMyTeamInfo, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XArenaManager.HandleTeamInfo(res.MyTeam)

            if cb then
                cb()
            end
        end)
    end

    -- 请求大厅队伍列表
    function XArenaManager.RequestHallTeamList(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LastHallTeamListTime + SYNC_HALL_SECOND >= now then
            if cb then
                cb()
            end
            return
        end
        LastHallTeamListTime = now

        --TODO 受刷新时间限制
        XNetwork.Call(ArenaRequest.RequestHallTeamList, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XArenaManager.HandleHallTeamList(res.HallTeamData)

            if cb then
                cb()
            end
        end)
    end

    -- 请求大厅玩家列表
    function XArenaManager.RequestHallPlayerList(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LastHallPlayerListTime + SYNC_HALL_SECOND >= now then
            if cb then
                cb()
            end
            return
        end
        LastHallPlayerListTime = now

        --TODO 受刷新时间限制
        XNetwork.Call(ArenaRequest.RequestHallPlayerList, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XArenaManager.HandleHallPlayerList(res.HallPlayerData)

            if cb then
                cb()
            end
        end)
    end

    -- 获取邀请申请信息列表
    function XArenaManager.RequestApplyData(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        --TODO 受刷新时间限制
        XNetwork.Call(ArenaRequest.RequestApplyData, nil, function(res)
            HaveToRequestApplyData = 0
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XArenaManager.HandleApplyData(res.ApplyData)

            if cb then
                cb()
            end
        end)
    end

    -- 获取所有好友竞技信息
    function XArenaManager.RequestFriendArenaInfo(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LastFriendPlayerTime + SYNC_OTHER_SECOND >= now then
            if cb then
                cb()
            end
            return
        end
        LastFriendPlayerTime = now

        XNetwork.Call(ArenaRequest.RequestFriendArenaInfo, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XArenaManager.HandleFriendList(res.FriendPlayerData)

            if cb then
                cb()
            end
        end)
    end

    -- 请求创建队伍
    function XArenaManager.RequestCreateTeam(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestCreateTeam, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 申请入队
    function XArenaManager.RequestApplyTeam(teamId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestApplyTeam, { TeamId = teamId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local info = HallTeamMap[teamId]
            if info then
                info.Apply = 1
            end

            if cb then
                cb()
            end
        end)
    end

    -- 拒绝申请
    function XArenaManager.RequestRefuseApply(targetId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestRefuseApply, { TargetId = targetId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            ApplyMap[targetId] = nil
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_APPLY_CHANGE)

            if cb then
                cb()
            end
        end)
    end

    -- 接受申请
    function XArenaManager.RequestAcceptApply(targetId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestAcceptApply, { TargetId = targetId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            ApplyMap[targetId] = nil
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_APPLY_CHANGE)

            if cb then
                cb()
            end
        end)
    end

    -- 请求离队
    function XArenaManager.RequestLeaveTeam(cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestLeaveTeam, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            TeamInfo = {}
            if HaveToRequestApplyData > 0 then
                HaveToRequestApplyData = 0
            end

            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_INITIATIVE_LEAVE)

            if cb then
                cb()
            end
        end)
    end

    -- 踢除队员
    function XArenaManager.RequestKickTeam(targetId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestKickTeam, { TargetId = targetId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    -- 邀请玩家入队
    function XArenaManager.RequestInvitePlayer(targetId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestInvitePlayer, { TargetId = targetId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local info = HallPlayerMap[targetId]
            if info then
                info.Invite = 1
            end

            local friend = FriendMap[targetId]
            if friend then
                friend.Invite = 1
            end

            if cb then
                cb()
            end
        end)
    end

    -- 拒绝邀请
    function XArenaManager.RequestRefuseInvite(targetId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestRefuseInvite, { TargetId = targetId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            InviteMap[targetId] = nil
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_APPLY_CHANGE)

            if cb then
                cb()
            end
        end)
    end

    -- 接受邀请
    function XArenaManager.RequestAcceptInvite(targetId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Rest then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestAcceptInvite, { TargetId = targetId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            InviteMap[targetId] = nil
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_TEAM_APPLY_CHANGE)

            if cb then
                cb()
            end
        end)
    end

    -- 保存排名到本地
    function XArenaManager.SaveResultToLocal()
        if ActivityNo <= 0 then return end

        local key = XPrefs.ArenaTeamResult .. tostring(XPlayer.Id)
        local value = tostring(ActivityNo) .. "|"
        for i, info in ipairs(PlayerResultRankList) do
            value = value .. tostring(info.Id)
            if i < #PlayerResultRankList then
                value = value .. "|"
            end
        end

        CS.UnityEngine.PlayerPrefs.SetString(key, value)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    -- 获取本地排名数据
    function XArenaManager.GetResultFormLocal(playerId)
        PlayerLoaclResultRanlList = {}

        local key = XPrefs.ArenaTeamResult .. tostring(XPlayer.Id)
        if not CS.UnityEngine.PlayerPrefs.HasKey(key) then
            return nil
        end

        local value = CS.UnityEngine.PlayerPrefs.GetString(key)
        local strs = string.Split(value)
        if not strs or #strs < 2 then
            return nil
        end

        if tonumber(strs[1]) ~= LastActivityNo then
            return nil
        end

        for i=2, #strs do
            PlayerLoaclResultRanlList[tonumber(strs[i])] = i - 1
        end

        return PlayerLoaclResultRanlList[playerId] or nil
    end
    ----------------------------Team end--------------------------

    ----------------------------Arena start--------------------------
    -- 获取活动状态
    function XArenaManager.GetArenaActivityStatus()
        return ActivityStatus
    end

    -- 获取进入下一阶段时间戳
    function XArenaManager.GetEnterNextStatusTime()
        return CountDownTime
    end

    -- 获取功能开启时间
    local GetTimeStr = function(time)
        if not time or time <= 0 then
            return ""
        end
        local str = XTime.TimestampToGameDateTimeString(time, "yy/MM/dd  HH:mm")
        return str
    end

    -- 获取组队期开始时间
    function XArenaManager.GetTeamStartTime()
        return GetTimeStr(TeamStartTime)
    end

    -- 获取战斗期开始时间
    function XArenaManager.GetFightStartTime()
        return GetTimeStr(FightStartTime)
    end

    -- 获取结算期开始时间
    function XArenaManager.GetResultStartTime()
        return GetTimeStr(ResultStartTime)
    end

    -- 获取当前的竞技段位
    function XArenaManager.GetCurArenaLevel()
        return ArenaLevel
    end

    -- 获取上一期的竞技段位
    function XArenaManager.GetLastArenaLevel()
        return LastArenaLevel
    end

    -- 获取上一期战区贡献分
    function XArenaManager.GetLastContributeScore()
        return LastContributeScore
    end

    -- 获取波动指数
    function XArenaManager.GetWaveRate()
        return WaveRate
    end

    -- 获取上一期波动指数
    function XArenaManager.GetWaveLastRate()
        return WaveLastRate
    end

    -- 获取当前挑战id
    function XArenaManager.GetCurChallengeId()
        return ChallengeId
    end

    -- 获取当前战区贡献总分
    function XArenaManager.GetContributeScore()
        return ContributeScore
    end

    -- 获取当前挑战配置
    function XArenaManager.GetCurChallengeCfg()
        return XArenaConfigs.GetChallengeArenaCfgById(ChallengeId)
    end

    -- 获取上一期挑战配置
    function XArenaManager.GetLastChallengeCfg()
        return XArenaConfigs.GetChallengeArenaCfgById(LastChallengeId)
    end

    -- 获取竞技挑战最高等级
    function XArenaManager.IsMaxArenaLevel(level)
        return level >= XArenaConfigs.GetChallengeMaxArenaLevel(ChallengeId)
    end

    -- 获取玩家竞技信息
    function XArenaManager.GetPlayerArenaInfo()
        for _, info in ipairs(TeamResultList) do
            if info.Id == XPlayer.Id then
                return info
            end
        end
    end

    -- 获取玩家上一期竞技信息
    function XArenaManager.GetPlayerLastArenaInfo()
        for _, info in ipairs(TeamLastResultList or {}) do
            if info.Id == XPlayer.Id then
                return info
            end
        end
    end

    -- 获取玩家竞技个人排名
    function XArenaManager.GetPlayerArenaRankAndRegion()
        local rank = 0
        local point = 0
        local region = XArenaPlayerRankRegion.DownRegion

        for i, info in ipairs(PlayerResultRankList) do
            if info.Id == XPlayer.Id then
                rank = i
                point = info.Point
            end
        end

        if point == 0 then
            if ArenaLevel <= 1 then
                region = XArenaPlayerRankRegion.KeepRegion
            end
            return rank, region
        end

        local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(ChallengeId)
        if challengeCfg then
            if rank <= challengeCfg.DanUpRank then
                region = XArenaPlayerRankRegion.UpRegion
            elseif rank > challengeCfg.DanUpRank and rank <= challengeCfg.DanKeepRank then
                region = XArenaPlayerRankRegion.KeepRegion
            end
        end

        return rank, region
    end

    -- 获取玩家上一期竞技个人排名
    function XArenaManager.GetLastPlayerArenaRankAndRegion()
        local rank = 0
        local point = 0
        local region = XArenaPlayerRankRegion.DownRegion

        for i, info in ipairs(PlayerLastResultRanlList) do
            if info.Id == XPlayer.Id then
                rank = i
                point = info.Point
            end
        end

        if point == 0 then
            if ArenaLevel <= 1 then
                region = XArenaPlayerRankRegion.KeepRegion
            end
            return rank, region
        end

        local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(LastChallengeId)
        if challengeCfg then
            if rank <= challengeCfg.DanUpRank then
                region = XArenaPlayerRankRegion.UpRegion
            elseif rank > challengeCfg.DanUpRank and rank <= challengeCfg.DanKeepRank then
                region = XArenaPlayerRankRegion.KeepRegion
            end
        end

        return rank, region
    end

    -- 获取队员竞技信息列表
    function XArenaManager.GetPlayerArenaTeamMemberInfo()
        local list = {}
        for _, info in ipairs(TeamResultList) do
            if info.Id ~= XPlayer.Id then
                table.insert(list, info)
            end
        end

        return list
    end

    -- 获取队员上一期竞技信息列表
    function XArenaManager.GetPlayerLastArenaTeamMemberInfo()
        local list = {}
        for _, info in ipairs(TeamLastResultList or {}) do
            if info.Id ~= XPlayer.Id then
                table.insert(list, info)
            end
        end

        return list
    end

    -- 获取队伍竞技总分
    function XArenaManager.GetArenaTeamTotalPoint()
        local point = 0
        for _, info in ipairs(TeamResultList) do
            point = point + info.Point
        end

        return point
    end

    -- 获取队伍上一期竞技总分
    function XArenaManager.GetLastArenaTeamTotalPoint()
        local point = 0
        for _, info in ipairs(TeamLastResultList or {}) do
            point = point + info.Point
        end

        return point
    end


    -- 获取玩家竞技排行数据
    function XArenaManager.GetPlayerArenaRankList()
        local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(ChallengeId)
        if not challengeCfg then
            return nil
        end

        local rankData = {}
        rankData.UpList = {}
        rankData.KeepList = {}
        rankData.DownList = {}

        for i, info in ipairs(PlayerResultRankList) do
            local Data = {
                Rank = i,
                PlayerInfo = info
            }
            if info.Point > 0 then
                if (i - challengeCfg.DanUpRank <= 0) then
                    table.insert(rankData.UpList, Data)
                elseif (i - challengeCfg.DanKeepRank <= 0) then
                    table.insert(rankData.KeepList, Data)
                else
                    table.insert(rankData.DownList, Data)
                end
            else
                if challengeCfg.ArenaLv <= 1 then
                    table.insert(rankData.KeepList, Data)
                else
                    table.insert(rankData.DownList, Data)
                end
            end
        end

        return rankData
    end

    -- 获取玩家上一期竞技排行数据
    function XArenaManager.GetLastPlayerArenaRankList()
        local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(LastChallengeId)
        if not challengeCfg then
            return nil
        end

        local rankData = {}
        rankData.UpList = {}
        rankData.KeepList = {}
        rankData.DownList = {}

        for i, info in ipairs(PlayerLastResultRanlList) do
            local Data = {
                Rank = i,
                PlayerInfo = info
            }
            if info.Point > 0 then
                if (i - challengeCfg.DanUpRank <= 0) then
                    table.insert(rankData.UpList, Data)
                elseif (i - challengeCfg.DanKeepRank <= 0) then
                    table.insert(rankData.KeepList, Data)
                else
                    table.insert(rankData.DownList, Data)
                end
            else
                if challengeCfg.ArenaLv <= 1 then
                    table.insert(rankData.KeepList, Data)
                else
                    table.insert(rankData.DownList, Data)
                end
            end
        end

        return rankData
    end

    -- 获取队伍排行榜的挑战配置
    function XArenaManager.GetTeamRankChallengeCfg()
        if TeamRankChallengeId <= 0 then
            return nil
        end

        return XArenaConfigs.GetChallengeArenaCfgById(TeamRankChallengeId)
    end

    -- 获取队伍排行统计时间
    function XArenaManager.GetArenaTeamRankTime(index)
        if not TeamRankData.BeginTime or not TeamRankData.BeginTime then
            return ""
        end

        local begin_time = XTime.TimestampToGameDateTimeString(TeamRankData.BeginTime, "yy.MM.dd")
        local end_time = XTime.TimestampToGameDateTimeString(TeamRankData.EndTime, "yy.MM.dd")
        local desc = index == 1 and CS.XTextManager.GetText("ArenaRankDesc") or ""
        return begin_time .. "-" .. end_time .. desc
    end

    -- 获取竞技队伍排行列表
    function XArenaManager.GetTeamRankList()
        return TeamRankData.TeamRowList
    end

    -- 获取自己队伍排行百分比
    function XArenaManager.GetMyTeamRankRate()
        local rankRate = TeamRankData.RankRate or 0
        return rankRate / 10000
    end

    -- 获取竞技我的队伍排行及数据
    function XArenaManager.GetMyTeamRankAndData()
        return TeamRankData.MyRank, TeamRankData.TotalRank, TeamRankData.MyTeamInfo
    end

    -- 获取剩余解锁战区次数
    function XArenaManager.GetUnlockArenaAreaCount()
        return UnlockCount
    end

    -- 获取玩家战区总分
    function XArenaManager.GetArenaAreaTotalPoint()
        return TotalPoint
    end

    -- 通过战区Id获取战区信息
    function XArenaManager.GetArenaAreaDataByAreaId(areaId)
        return AreaDatas[areaId]
    end

    -- 通过战区Id获取战区当前关卡进度
    function XArenaManager.GetCurStageIndexByAreaId(areaId)
        local stageInfos = AreaDatas[areaId].StageInfos
        if not stageInfos then
            return 1
        end

        if #stageInfos >= XArenaConfigs.GetTheMaxStageCountOfArenaArea() then
            return #stageInfos
        else
            return #stageInfos + 1
        end
    end

    -- 通过战区Id、关卡Id获取关卡积分
    function XArenaManager.GetArenaStageScore(areaId, stageId)
        local stageInfos = AreaDatas[areaId].StageInfos
        if not stageInfos then
            return 0
        end

        for _, v in ipairs(stageInfos) do
            if v.StageId == stageId then
                return v.Point
            end
        end
        return 0
    end

    -- 通过战区Id、关卡Id修改关卡积分
    function XArenaManager.ChangeArenaStageScore(areaId, stageId, score)
        local stageInfos = AreaDatas[areaId].StageInfos
        if not stageInfos then
            return
        end

        for _, v in ipairs(stageInfos) do
            if v.StageId == stageId then
                v.Point = score
            end
        end
    end

    -- 设置正在战斗的竞技区域
    function XArenaManager.SetEnterAreaStageInfo(areaId, index)
        EnterAreaStageInfo = {}
        EnterAreaStageInfo.AreaId = areaId
        EnterAreaStageInfo.StageIndex = index

        local stageId = XArenaConfigs.GetArenaAreaStageCfgByAreaId(areaId).StageId[index]

        local chaperName, stageName = XArenaConfigs.GetChapterAndStageName(areaId, stageId)
        EnterAreaStageInfo.ChapterName = chaperName
        EnterAreaStageInfo.StageName = stageName
    end

    -- 获取竞技结算分数配置
    function XArenaManager.GetMarkCfg()
        if not EnterAreaStageInfo.AreaId or not EnterAreaStageInfo.StageIndex then
            return nil
        end

        local stageCfg = XArenaConfigs.GetArenaAreaStageCfgByAreaId(EnterAreaStageInfo.AreaId)
        if not stageCfg then
            return nil
        end

        local markCfg = XArenaConfigs.GetMarkCfgById(stageCfg.MarkId[EnterAreaStageInfo.StageIndex])
        return markCfg
    end

    -- 状态改变直接回到主界面
    local JudgeGotoMain = function()
        if not XLuaUiManager.IsUiLoad("UiArena") then
            return
        end

        if ActivityStatus == XArenaActivityStatus.Loading or ActivityStatus == XArenaActivityStatus.Default then
            return
        end

        -- 如果玩家在竞技战斗中 先做缓存
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            ArenaStatusInFightChangeCache = true
            return
        end

        -- 如果玩家在好友宿舍中 退出宿舍
        if XLuaUiManager.IsUiLoad("UiDormSecond") then
            XHomeSceneManager.LeaveScene()
            XEventManager.DispatchEvent(XEventId.EVENT_DORM_CLOSE_COMPONET)
        end

        XUiManager.TipText("ArenaActivityStatusChange")
        XLuaUiManager.RunMain()
    end

    -- 竞技战斗结束后判断是否跳到主界面
    function XArenaManager.JudgeGotoMainWhenFightOver()
        if not XLuaUiManager.IsUiLoad("UiArena") then
            return false
        end

        if not ArenaStatusInFightChangeCache then
            return false
        end

        ArenaStatusInFightChangeCache = false
        XUiManager.TipText("ArenaActivityStatusChange")
        XLuaUiManager.RunMain()

        return true
    end

     -- 是否战斗中改变了状态
     function XArenaManager.IsChangeStatusInFight()
        return ArenaStatusInFightChangeCache
    end

    -- 处理竞技活动相关数据
    function XArenaManager.HandleArenaActivity(data)
        -- 清空数据
        HallTeamMap = {}
        HallPlayerMap = {}
        FriendMap = {}
        TeamInfo = nil
        ApplyMap = {}
        InviteMap = {}
        MaxPointStageDic = {}
        HaveToRequestApplyData = -1

        ActivityNo = 0
        ActivityStatus = XArenaActivityStatus.Default
        CountDownTime = 0
        TeamStartTime = 0
        FightStartTime = 0
        ResultStartTime = 0
        WaveRate = 0
        PlayerResultRankList = {}
        TeamRankChallengeId = 0
        TeamRankData = {}
        TeamResultList = {}
        -- AreaIdToStageDetailList = {}
        ChallengeId = 0
        ArenaLevel = 0
        UnlockCount = 0
        TotalPoint = 0
        AreaDatas = {}
        EnterAreaStageInfo = {}

        -- 请求保护时间清0
        LastSyncRankListTime = 0
        LastHallTeamListTime = 0
        LastHallPlayerListTime = 0
        LastFriendPlayerTime = 0
        LasGroupMemberTime = 0

        -- 重设数据
        ActivityNo = data.ActivityNo
        ChallengeId = data.ChallengeId
        ActivityStatus = data.Status
        CountDownTime = data.NextStatusTime
        TeamStartTime = data.TeamTime
        FightStartTime = data.FightTime
        ResultStartTime = data.ResultTime
        ArenaLevel = data.ArenaLevel
        IsJoinActivity = data.JoinActivity == 1 -- 是否参加过当前活动
        UnlockCount = data.UnlockCount
        ContributeScore = data.ContributeScore

        for _, v in pairs(data.MaxPointStageList) do
            MaxPointStageDic[v] = true
        end

        if ActivityStatus == XArenaActivityStatus.Over then
            IsJoinActivity = false
            WaveLastRate = nil
            PlayerLastResultRanlList = {}
            TeamLastResultList = nil
            LastChallengeId = nil
            LastActivityNo = nil
            LastArenaLevel = nil
            LastDataRespone = nil
            LastContributeScore = nil
        end

        local remainTime = CountDownTime - XTime.GetServerNowTimestamp()
        XCountDown.CreateTimer(XArenaConfigs.ArenaTimerName, remainTime)

        JudgeGotoMain()
        XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
        
        -- 状态更改通知周历刷新
        XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
    end

    -- 获取正在战斗的竞技区域
    function XArenaManager.GetEnterAreaStageInfo()
        return EnterAreaStageInfo
    end

    -- 获取是否参加过当前活动
    function XArenaManager.GetIsJoinActivity()
        return IsJoinActivity
    end

    -- 报名参加竞技活动
    function XArenaManager.RequestSignUpArena(cb)
        if ActivityStatus == XArenaActivityStatus.Over then
            if cb then
                cb()
            end
            return
        end

        if IsJoinActivity then
            if cb then
                cb()
            end
            return
        end

        XNetwork.Call(ArenaRequest.RequestSignUpArena, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsJoinActivity = true
            if res.ChallengeId then
                ChallengeId = res.ChallengeId
            end

            if cb then
                cb()
            end
        end)
    end

    -- 请求主页面成员信息
    function XArenaManager.RequestGroupMember(cb)
        if ActivityStatus ~= XArenaActivityStatus.Fight then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LasGroupMemberTime + SYNC_GOURP_MEMBER_SECOND >= now then
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_MAIN_INFO)
            if cb then
                cb()
            end
            return
        end
        LasGroupMemberTime = now

        XNetwork.Call(ArenaRequest.RequestGroupMember, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            WaveRate = res.WaveRate
            PlayerResultRankList = res.GroupPlayerList
            TeamResultList = res.TeamPlayerList
            XArenaManager.SaveResultToLocal()
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_MAIN_INFO)
            if cb then
                cb()
            end
        end)
    end

    -- 请求上一期主界面信息
    function XArenaManager.ScoreQueryReq(cb)
        -- -- TODO:::等待服务器完成功能
        -- if true then
        --     XUiManager.TipMsg(CS.XTextManager.GetText("ComingSoon"), XUiManager.UiTipType.Tip)
        --     return
        -- end
        if LastDataRespone and LastDataRespone.Code ~= XCode.Success then
            XUiManager.TipCode(LastDataRespone.Code)
            return
        end

        if TeamLastResultList ~= nil then
            if cb then
                cb()
            end
            return
        end

        XNetwork.Call(ArenaRequest.ScoreQueryReq, nil, function(res)
            LastDataRespone = res
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            WaveLastRate = res.WaveRate
            PlayerLastResultRanlList = res.GroupPlayerList
            TeamLastResultList = res.TeamPlayerList
            LastChallengeId = res.ChallengeId
            LastActivityNo = res.ActivityNo
            LastArenaLevel = res.ArenaLevel
            LastContributeScore = res.ContributeScore

            if cb then cb() end
        end)
    end

    -- 请求区域信息
    function XArenaManager.RequestAreaData(cb, failCb)
        if ActivityStatus ~= XArenaActivityStatus.Fight then
            XUiManager.TipText("ArenaActivityStatusWrong")
            if failCb then failCb() end
            return
        end

        XNetwork.Call(ArenaRequest.RequestAreaData, nil, function(res)
            if res.Code ~= XCode.Success then
                -- XUiManager.TipCode(res.Code)
                if failCb then failCb() end
                return
            end

            TotalPoint = res.TotalPoint
            GroupFightEvent = res.GroupFightEvent
            for _, areaShowData in ipairs(res.AreaList) do
                AreaDatas[areaShowData.AreaId] = areaShowData
            end
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_REFRESH_AREA_INFO)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ARENA_REFRESH_AREA_INFO)

            if cb then
                cb()
            end
        end)
    end
    function XArenaManager.RequestSelfRankList(challengeId,cb)
        XNetwork.Call(ArenaRequest.ArenaChallengeGetRankRequest,{ChallengeId = challengeId},function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb(res)
            end
        end)
    end
    -- 请求通关详情
    function XArenaManager.RequestStagePassDetail(areaId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Fight then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        XNetwork.Call(ArenaRequest.RequestStagePassDetail, { AreaId = areaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local detailMap = {}
            for _, data in ipairs(res.StageDetailList) do
                detailMap[data.StageId] = data
            end
            -- AreaIdToStageDetailList[areaId] = detailMap

            if cb then
                cb(detailMap)
            end
        end)
    end

    -- 请求解锁战区
    function XArenaManager.RequestUnlockArea(areaId, cb)
        if ActivityStatus ~= XArenaActivityStatus.Fight then
            XUiManager.TipText("ArenaActivityStatusWrong")
            return
        end

        if UnlockCount <= 0 then
            XUiManager.TipError(CS.XTextManager.GetText("ArenaActivityUnlockCountNotEnough"))
            return
        end

        XNetwork.Call(ArenaRequest.RequestUnlockArea, { AreaId = areaId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UnlockCount = UnlockCount - 1
            local data = AreaDatas[areaId]
            data.Lock = 0

            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_UNLOCK_AREA)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ARENA_UNLOCK_AREA)

            if cb then
                cb()
            end
        end)
    end

    -- 请求队伍排行
    function XArenaManager.RequestTeamRankData(cb)
        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LastSyncRankListTime + SYNC_RANK_LIST_SECOND >= now and TeamRankChallengeId > 0 then
            if cb then
                cb()
            end
            return
        end
        LastSyncRankListTime = now

        XNetwork.Call(ArenaRequest.RequestTeamRankData, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            TeamRankChallengeId = res.ChallengeId
            TeamRankData = res.RankData

            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_REFRESH_TEAM_RANK_INFO)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ARENA_REFRESH_TEAM_RANK_INFO)

            if cb then
                cb()
            end
        end)
    end

    --记录满分通关的关卡列表
    function XArenaManager.NotifyMaxPointList(data)
        MaxPointStageDic = {}
        for _, v in pairs(data.MaxPointStageList) do
            MaxPointStageDic[v] = true
        end
    end

    function XArenaManager.IsCanAutoFightByStageId(stageId,areaId)
        local areaStageCfg = XArenaConfigs.GetArenaAreaStageCfgByAreaId(areaId)
        local targetIsMaxPoint =  MaxPointStageDic[stageId] == true
        local otherIsMaxPoint = false
        if areaStageCfg then
            for i, sId in pairs(areaStageCfg.StageId) do
                if sId == stageId then
                    local stageStr = areaStageCfg.ActiveAutoFightStageStr[i]
                    if not string.IsNilOrEmpty(stageStr) then
                        local stageIdList = string.Split(stageStr,"|")
                        for _, id in pairs(stageIdList) do
                            otherIsMaxPoint = MaxPointStageDic[tonumber(id)] == true or otherIsMaxPoint
                        end
                    end
                end
            end
        end
        return  targetIsMaxPoint or otherIsMaxPoint
    end
    
    function XArenaManager.NotifyArenaAutoJoinActivity(data)
        XLog.Debug("XArenaManager.NotifyArenaAutoJoinActivity 战区自动加入", data)
        ChallengeId = data.ChallengeId
    end

    function XArenaManager.RequestAutoFight(areaId, stageId)
        XNetwork.Call(ArenaRequest.AreaAutoFightRequest, { AreaId = areaId, StageId = stageId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XArenaManager.RequestAreaData(function()
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ARENA_RESULT_AUTOFIGHT)
                        XUiManager.TipText("ArenaAutoFightSuccess")
                    end)
            end)
    end

    function XArenaManager.InitStageInfo()
        local arenaStageInfo = XArenaConfigs.GetArenaStageCfg()
        for _, stageList in ipairs(arenaStageInfo) do
            for _, v in ipairs(stageList.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                stageInfo.Type = XDataCenter.FubenManager.StageType.Arena
            end
        end
    end

    --计算竞技场贡献分(需要根据战区积分判断)
    function XArenaManager.GetContributeScoreByCfg(index, challengeCfg, point)
        if point > 0 then
            return challengeCfg.ContributeScore[index] or 0 
        else
            return 0
        end
    end
    
    -- 获取当前挑战任务
    function XArenaManager.GetCurChallengeTasks()
        local tasks = {}
        local dailyTasks = XDataCenter.TaskManager.GetArenaChallengeTaskList()
        local challengeCfg = XArenaConfigs.GetChallengeArenaCfgById(ChallengeId)
        if challengeCfg then
            for _, cfgTaskId in pairs(challengeCfg.TaskId or {}) do
                for _, dailyTask in pairs(dailyTasks) do
                    if cfgTaskId == dailyTask.Id then
                        table.insert(tasks, dailyTask)
                    end
                end
            end
        end
        return tasks
    end

    --XArenaManager.Init()
    ----------------------------Arena start--------------------------

    ------------------副本入口扩展 start-------------------------
    function XArenaManager:ExGetChapterType()
        return XDataCenter.FubenManager.ChapterType.ARENA
    end
    
    function XArenaManager:ExGetProgressTip()
        local status = XDataCenter.ArenaManager.GetArenaActivityStatus()
        if status == XArenaActivityStatus.Rest then
            return CS.XTextManager.GetText("ArenaTeamDescription")
        elseif status == XArenaActivityStatus.Fight then
            local isJoin = XDataCenter.ArenaManager.GetIsJoinActivity()
            if isJoin then
                return CS.XTextManager.GetText("ArenaFightJoinDescription")
            else
                return CS.XTextManager.GetText("ArenaFightNotJoinDescription")
            end
        elseif status == XArenaActivityStatus.Over then
            return CS.XTextManager.GetText("ArenaOverDescription")
        end
        return ""
    end
    
    function XArenaManager:ExGetRunningTimeStr()
        local remainTime = CountDownTime - XTime.GetServerNowTimestamp()
        local state = XDataCenter.ArenaManager.GetArenaActivityStatus()
        local timeText = ""
        if state == XArenaActivityStatus.Rest then
            timeText = CS.XTextManager.GetText("ArenaActivityBeginCountDown") .. XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        elseif state == XArenaActivityStatus.Fight then
            timeText = CS.XTextManager.GetText("ArenaActivityEndCountDown", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE))
        elseif state == XArenaActivityStatus.Over then
            timeText = CS.XTextManager.GetText("ArenaActivityResultCountDown") .. XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.CHALLENGE)
        end
        return timeText
    end

    function XArenaManager:ExCheckIsFinished(cb)
        local state = XDataCenter.ArenaManager.GetArenaActivityStatus()
        if state ~= XArenaActivityStatus.Fight then -- 特殊，只要不在战斗期就一定显示Clear
            self.IsClear = true
            if cb then
                cb(true)
            end
            return
        end
        self.IsClear = false
        -- 检测完成的数据必现先报名战区并请求下发数据，不然会弹提示。所以把提示关掉
        XArenaManager.RequestAreaData(function()
            local isHasAreaUnlock = false   --有战区未解锁
            local isHasArealock = false     --有战区已解锁
            local isAreaUnLockButHasStageUnpassed = false   --解锁的区有关卡没打
            for k, areaInfo in pairs(AreaDatas) do
                if areaInfo.Lock == 1 and not isHasAreaUnlock then
                    isHasAreaUnlock = true
                end
    
                if areaInfo.Lock == 0  then
                    if not isHasArealock then
                        isHasArealock = true
                    end
    
                    if areaInfo.StageInfos and #areaInfo.StageInfos < 3 then
                        isAreaUnLockButHasStageUnpassed = true
                    end
                end
            end

            local result = true
            if (isHasAreaUnlock and UnlockCount > 0) -- 有次数且未解锁区
                    or (isHasArealock and isAreaUnLockButHasStageUnpassed)  -- 有战区已解锁 且 解锁的区有关卡没打
                    or XRedPointManager.CheckConditions({"CONDITION_ARENA_MAIN_TASK"}) -- 有奖励未领取
                    or self:ExGetIsLocked()
            then
                result = false
            end

            self.IsClear = result
            if cb then
                cb(result)
            end
        end, cb)
    end

    function XArenaManager:ExOpenMainUi()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenArena) then
            XArenaManager.RequestSignUpArena(function()
                XLuaUiManager.Open("UiArena", XFubenConfigs.GetChapterBannerByType(XDataCenter.FubenManager.ChapterType.ARENA))
            end)
        end
    end

    -- 获取倒计时（周历专用）
    function XArenaManager:ExGetCalendarRemainingTime()
        if not XTool.IsNumberValid(CountDownTime) then
            return ""
        end
        local remainTime = CountDownTime - XTime.GetServerNowTimestamp()
        if remainTime < 0 then
            remainTime = 0
        end
        local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)
        return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
    end
    
    -- 获取解锁时间（周历专用）
    function XArenaManager:ExGetCalendarEndTime()
        if not XTool.IsNumberValid(CountDownTime) then
            return 0
        end
        return CountDownTime
    end

    -- 是否在周历里显示
    function XArenaManager:ExCheckShowInCalendar()
        if not XTool.IsNumberValid(CountDownTime) then
            return false
        end
        if CountDownTime - XTime.GetServerNowTimestamp() <= 0 then
            return false
        end
        local state = XDataCenter.ArenaManager.GetArenaActivityStatus()
        if state == XArenaActivityStatus.Fight then
            return true
        end
        return false
    end
    ------------------副本入口扩展 end-------------------------

    return XArenaManager
end

XRpc.NotifyArenaActivity = function(data)
    XDataCenter.ArenaManager.HandleArenaActivity(data)
end

XRpc.NotifyMyTeam = function(data)
    XDataCenter.ArenaManager.HandleTeamInfo(data.MyTeam)
end

XRpc.NotifyPlayerKick = function()
    XDataCenter.ArenaManager.HandleIsKickedByCaptain()
end

XRpc.NotifyNewApply = function(data)
    XDataCenter.ArenaManager.HandleNewApplyData(data)
end

XRpc.ActivityResultNotify = function(data)
    XDataCenter.ArenaManager.HandleArenaActivityResult(data)
end

--已经满分通关的关卡列表（用于自动作战）
XRpc.NotifyMaxPointList = function(data)
    XDataCenter.ArenaManager.NotifyMaxPointList(data)
end

XRpc.NotifyArenaAutoJoinActivity = function(data)
    XDataCenter.ArenaManager.NotifyArenaAutoJoinActivity(data)
end