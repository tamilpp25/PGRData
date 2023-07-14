XFubenUnionKillRoomManagerCreator = function()

    local XFubenUnionKillRoomManager = {}
    local UnionRoomRpc = {
        CreateUnionKillRoom = "CreateUnionKillRoomRequest",                 -- 创建房间
        UnionKillMatchRoom = "UnionKillMatchRoomRequest",                   -- 匹配
        UnionKillCancelMatch = "UnionKillCancelMatchRequest",               -- 取消匹配
        UnionKillEnterFight = "UnionKillEnterFightRequest",                 -- 进入战斗
        UnionKillChangePlayerState = "UnionKillChangePlayerStateRequest",   -- 更改玩家状态
        UnionKillChangeLeader = "UnionKillChangeLeaderRequest",             -- 更改队长
        UnionKillKickOut = "UnionKillKickOutRequest",                       -- 踢出队伍
        UnionKillSelect = "UnionKillSelectRequest",                         -- 选择角色
        UnionKillEnterTargetRoom = "UnionKillEnterTargetRoomRequest",       -- 进入房间
        UnionKillLeaveTeamRoom = "UnionKillLeaveTeamRoomRequest",           -- 离开组队界面
        UnionKillSetAutoMatch = "UnionKillSetAutoMatchRequest",             -- 切换快速匹配
    }

    local UnionRoomData = {}
    local IsUnionMatching = false


    -- 快速匹配：结果返回
    function XFubenUnionKillRoomManager.SyncMatchData(notifyData)
        if not notifyData then return end

        if notifyData.Code ~= XCode.Success then
            IsUnionMatching = false
            XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_MATCHRESULT)
            return
        end

        XDataCenter.ChatManager.ResetRoomChat()
        UnionRoomData.Id = notifyData.RoomData.Id
        UnionRoomData.AutoMatch = notifyData.RoomData.AutoMatch
        UnionRoomData.State = notifyData.RoomData.State
        local playerDataList = notifyData.RoomData.PlayerDataList
        UnionRoomData.PlayerDataList = {}
        for _, playerData in pairs(playerDataList or {}) do
            UnionRoomData.PlayerDataList[playerData.Id] = playerData
        end

        if XLuaUiManager.IsUiShow("UiDialog") then
            XLuaUiManager.Close("UiDialog")
        end

        IsUnionMatching = false
        XLuaUiManager.Open("UiUnionKillRoom")
        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_MATCHRESULT)
    end

    -- 被踢出队伍
    function XFubenUnionKillRoomManager.SyncKickOutData(notifyData)
        if not notifyData then return end

        if notifyData.Code == XCode.Success then
            local playerData = UnionRoomData.PlayerDataList[XPlayer.Id]
            if playerData and playerData.Leader then
                XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaderStayTooLong"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("UnionMemberKickOut"))
            end
        else
            XUiManager.TipCode(notifyData.Code)
        end
        UnionRoomData = {}

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_KICKOUT)
    end

    -- 同步队长信息
    function XFubenUnionKillRoomManager.SyncRoomLeaderData(notifyData)
        if not notifyData then return end
        if UnionRoomData then
            for id, playerData in pairs(UnionRoomData.PlayerDataList or {}) do
                playerData.Leader = notifyData.LeaderId == id
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_LEADER_CHANGED)
    end

    -- 同步玩家状态
    function XFubenUnionKillRoomManager.SyncPlayerStatusData(notifyData)
        if not notifyData then return end
        local lastState = XFubenUnionKillConfigs.UnionRoomPlayerState.Normal
        if UnionRoomData then
            for id, playerData in pairs(UnionRoomData.PlayerDataList or {}) do
                if id == notifyData.PlayerId then
                    lastState = playerData.State
                    playerData.State = notifyData.State
                end
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_PLAYERSTATE_CHANGED, notifyData.PlayerId, lastState)
    end

    -- 同步玩家共享角色信息
    function XFubenUnionKillRoomManager.SyncPlayerFightNpcData(notifyData)
        if not notifyData then return end
        if UnionRoomData then
            for id, playerData in pairs(UnionRoomData.PlayerDataList or {}) do
                if id == notifyData.PlayerId then
                    playerData.FightNpcData = notifyData.FightNpcData
                end
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_FIGHTNPC_CHANGED, notifyData.PlayerId)
    end

    -- 有其他玩家加入我所在的房间
    function XFubenUnionKillRoomManager.SyncPlayerEnterData(notifyData)
        if not notifyData then return end
        if UnionRoomData and UnionRoomData.PlayerDataList then
            local playerData = notifyData.PlayerData
            UnionRoomData.PlayerDataList[playerData.Id] = playerData
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_PLAYERENTER)
    end

    -- 有玩家离开当前房间
    function XFubenUnionKillRoomManager.SyncPlayerLeaveData(notifyData)
        if not notifyData then return end

        if notifyData.PlayerId == XPlayer.Id then
            if not CS.XFight.IsRunning then
                XUiManager.TipMsg(CS.XTextManager.GetText("UnionNetworkFluctuation"))
            end
            UnionRoomData = {}
            XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_KICKOUT)
            return
        end
        if UnionRoomData and UnionRoomData.PlayerDataList then
            UnionRoomData.PlayerDataList[notifyData.PlayerId] = nil
            if notifyData.NewLeaderId and notifyData.NewLeaderId ~= 0 then
                for id, playerData in pairs(UnionRoomData.PlayerDataList or {}) do
                    playerData.Leader = id == notifyData.NewLeaderId
                end
            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_PLAYERLEAVE)
    end

    -- 快速匹配同步
    function XFubenUnionKillRoomManager.SyncAutoMatchData(notifyData)
        if not notifyData then return end

        if UnionRoomData then
            UnionRoomData.AutoMatch = notifyData.AutoMatch
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_AUTOMATCHCHANGE)

    end

    -- 玩家主动离开队伍
    function XFubenUnionKillRoomManager.LeaveUnionTeamRoom(func)
        XNetwork.Call(UnionRoomRpc.UnionKillLeaveTeamRoom, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end

            -- 清理房间数据
            UnionRoomData = {}
        end)

    end

    -- 进入房间：点击链接
    function XFubenUnionKillRoomManager.EnterTargetUnionRoom(roomId, func)
        XNetwork.Call(UnionRoomRpc.UnionKillEnterTargetRoom, {
            RoomId = roomId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDataCenter.ChatManager.ResetRoomChat()
            UnionRoomData.Id = res.RoomData.Id
            UnionRoomData.AutoMatch = res.RoomData.AutoMatch
            UnionRoomData.State = res.RoomData.State
            local playerDataList = res.RoomData.PlayerDataList
            UnionRoomData.PlayerDataList = {}
            for _, playerData in pairs(playerDataList or {}) do
                UnionRoomData.PlayerDataList[playerData.Id] = playerData
            end

            if func then
                func()
            end

        end)
    end

    -- 玩家点击链接
    function XFubenUnionKillRoomManager.ClickEnterRoomHref(roomId, createTime)

        -- 检查玩法开启
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenUnionKill) then
            return
        end

        -- 链接超时检查
        if XTime.GetServerNowTimestamp() > createTime + CS.XGame.Config:GetInt("RoomHrefDisableTime") then
            XUiManager.TipText("RoomHrefDisabled")
            return
        end

        XFubenUnionKillRoomManager.EnterTargetUnionRoom(roomId, function()
            XLuaUiManager.Open("UiUnionKillRoom")
        end)
    end

    -- 切换快速匹配
    function XFubenUnionKillRoomManager.SetUnionQuickMatch(autoMatch, func)
        if UnionRoomData and UnionRoomData.AutoMatch == autoMatch then return end

        XNetwork.Call(UnionRoomRpc.UnionKillSetAutoMatch, { AutoMatch = autoMatch }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UnionRoomData.AutoMatch = autoMatch
            if func then
                func()
            end
        end)
    end

    -- 选择角色-不涉及房间数据的管理
    function XFubenUnionKillRoomManager.SelectUnionRole(characterId, func)
        XNetwork.Call(UnionRoomRpc.UnionKillSelect, { CharacterId = characterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if UnionRoomData and UnionRoomData.PlayerDataList then
                local playerData = UnionRoomData.PlayerDataList[XPlayer.Id]
                playerData.FightNpcData = res.FightNpcData
            end

            if func then
                func()
            end

        end)
    end

    -- 踢出队伍
    function XFubenUnionKillRoomManager.KickOutUnionTeam(playerId, func)
        XNetwork.Call(UnionRoomRpc.UnionKillKickOut, { PlayerId = playerId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if UnionRoomData then
                UnionRoomData.PlayerDataList[playerId] = nil
            end

            if func then
                func()
            end
        end)
    end

    -- 更换队长
    function XFubenUnionKillRoomManager.ChangeUnionLeader(playerId, func)
        XNetwork.Call(UnionRoomRpc.UnionKillChangeLeader, { PlayerId = playerId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if UnionRoomData then
                for id, playerData in pairs(UnionRoomData.PlayerDataList or {}) do
                    playerData.Leader = id == playerId
                end
            end

            if func then
                func()
            end
        end)
    end

    -- 更改玩家状态-不涉及房间数据的管理
    function XFubenUnionKillRoomManager.ChangePlayerState(state, func)
        local req = { State = state }
        XNetwork.Call(UnionRoomRpc.UnionKillChangePlayerState, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end
        end)
    end

    -- 进入战斗：成功进入UnionKillStage界面-不涉及房间数据的管理
    function XFubenUnionKillRoomManager.EnterUnionRoomFihgt(func)
        XNetwork.Call(UnionRoomRpc.UnionKillEnterFight, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end
        end)

    end

    -- 取消匹配:取消匹配，成功匹配界面才能关闭-不涉及房间数据的管理
    function XFubenUnionKillRoomManager.CancelUnionMatch(func)
        if not IsUnionMatching then
            if func then
                func()
            end
            return
        end
        XNetwork.Call(UnionRoomRpc.UnionKillCancelMatch, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsUnionMatching = false

            if func then
                func()
            end
        end)
    end

    -- 匹配:发起匹配，成功限时匹配的view-不涉及房间数据的管理
    function XFubenUnionKillRoomManager.MatchUnionRoom(func)
        if IsUnionMatching then
            return
        end
        XNetwork.Call(UnionRoomRpc.UnionKillMatchRoom, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsUnionMatching = true

            if func then
                func()
            end
        end)
    end

    -- 创建
    function XFubenUnionKillRoomManager.CreateUnionRoom(autoMatch, func)
        XNetwork.Call(UnionRoomRpc.CreateUnionKillRoom, { AutoMatch = autoMatch }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDataCenter.ChatManager.ResetRoomChat()
            -- 创建房间数据
            UnionRoomData.Id = res.RoomData.Id
            UnionRoomData.AutoMatch = res.RoomData.AutoMatch
            UnionRoomData.State = res.RoomData.State
            local playerDataList = res.RoomData.PlayerDataList
            UnionRoomData.PlayerDataList = {}
            for _, playerData in pairs(playerDataList or {}) do
                UnionRoomData.PlayerDataList[playerData.Id] = playerData
            end

            if func then
                func()
            end

        end)
    end

    function XFubenUnionKillRoomManager.SetPlayersFightState()
        if UnionRoomData then
            for id, playerData in pairs(UnionRoomData.PlayerDataList or {}) do
                playerData.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Fight
                XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_PLAYERSTATE_CHANGED, id)
            end
        end
    end

    -- 是否是队长
    function XFubenUnionKillRoomManager.IsLeader(playerId)
        if UnionRoomData and UnionRoomData.PlayerDataList then
            local playerData = UnionRoomData.PlayerDataList[playerId]
            if not playerData then return false end
            return playerData.Leader
        end
        return false
    end

    -- 获取队员状态
    function XFubenUnionKillRoomManager.GetPlayerState(playerId)
        if UnionRoomData and UnionRoomData.PlayerDataList then
            for id, playerData in pairs(UnionRoomData.PlayerDataList) do
                if id == playerId then
                    return playerData.State
                end
            end
        end
        return XFubenUnionKillConfigs.UnionRoomPlayerState.Normal
    end

    -- 全员已经准备好了:不需要考虑队长
    function XFubenUnionKillRoomManager.IsAllMemberReady()
        local isAllReady = true
        local hasFight = false
        if UnionRoomData and UnionRoomData.PlayerDataList then
            for _, playerData in pairs(UnionRoomData.PlayerDataList) do
                if playerData.State ~= XFubenUnionKillConfigs.UnionRoomPlayerState.Ready and
                not playerData.Leader then
                    isAllReady = false
                end
                if playerData.State == XFubenUnionKillConfigs.UnionRoomPlayerState.Fight then
                    hasFight = true
                end
            end
        end
        if hasFight then
            isAllReady = false
        end
        return isAllReady
    end

    function XFubenUnionKillRoomManager.IsMatching()
        return IsUnionMatching
    end

    -- 获取组队数据
    function XFubenUnionKillRoomManager.GetUnionRoomData()
        return UnionRoomData
    end

    function XFubenUnionKillRoomManager.Init()
        IsUnionMatching = false
    end

    XFubenUnionKillRoomManager.Init()
    return XFubenUnionKillRoomManager
end

-- 匹配成功：队长队员处理：收下收到的数据
XRpc.UnionKillMatchNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncMatchData(notifyData)
end

-- 踢出队伍：一般只有队员能收到，队长变为队员也能收到
XRpc.UnionKillKickOutNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncKickOutData(notifyData)
end

-- 同步玩家数据变化：队长？状态？角色？拆分成3条,减少数据同步量
XRpc.UnionKillTeamLeaderChangeNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncRoomLeaderData(notifyData)
end

XRpc.UnionKillTeamPlayerStatusChangeNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncPlayerStatusData(notifyData)
end

XRpc.UnionKillTeamPlayerFightNpcChangeNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncPlayerFightNpcData(notifyData)
end

-- 玩家加入：队长队员的处理：新增加入队员的数据->刷新界面
XRpc.UnionKillPlayerEnterNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncPlayerEnterData(notifyData)
end

-- 玩家离队：队长队员的处理：清除离队队员的数据->刷新界面
XRpc.UnionKillPlayerLeaveNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncPlayerLeaveData(notifyData)
end

-- 快速匹配数据同步
XRpc.UnionKillAutoMatchChangeNotify = function(notifyData)
    XDataCenter.FubenUnionKillRoomManager.SyncAutoMatchData(notifyData)
end