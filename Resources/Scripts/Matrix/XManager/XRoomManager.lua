XRoomManagerCreator = function()
    local XRoomManager = {
        IsOpen = false,
        UiRoom = nil,
        UiOnlineInstance = nil,
        Matching = false,
        MatchStageId = nil,
        RoomData = nil,
        StageInfo = nil, --关卡
    }

    XRoomManager.PlayerState = {
        Normal = 0,
        Ready = 1,
        Select = 2,
        Clump = 3,
        Fight = 4,
        Settle = 5,
    }

    XRoomManager.IndexType = {
        Left = 1,
        Center = 2,
        Right = 3,
        Max = 3
    }

    XRoomManager.RoomState =
    {
        Normal = 0,
        Fight = 1,
        Settle = 2,
        Close = 3,
    }


    local RequestProto = {
        -- gateServer
        JoinFightRequest = "JoinFightRequest", --请求进入战斗服(gate)

        -- 普通联机
        CreateRoomRequest = "CreateRoomRequest", --创建房间
        MatchRoomRequest = "MatchRoomRequest", --匹配
        CancelMatchRequest = "CancelMatchRequest", --取消匹配
        QuitRoomRequest = "QuitRoomRequest", --退出房间
        ReadyRequest = "ReadyRequest", --准备
        CancelReadyRequest = "CancelReadyRequest", --取消准备
        EnterFightRequest = "EnterFightRequest", -- 进入战斗
        SelectRequest = "SelectRequest", --抽卡
        ChangeLeaderRequest = "ChangeLeaderRequest", --切换房主
        KickOutRequest = "KickOutRequest", --踢人
        AddLikeRequest = "AddLikeRequest", -- 添加喜欢
        UpdateLoadProcessRequest = "UpdateLoadProcessRequest", -- 更新进度
        EnterTargetRoomRequest = "EnterTargetRoomRequest", -- 进入目标房间
        SelectRewardRequest = "SelectRewardRequest", -- 选择奖励
        BeginSelectRequest = "BeginSelectRequest", -- 进入切换角色状态
        EndSelectRequest = "EndSelectRequest", -- 退出切换角色状态
        SetStageLevelRequest = "SetStageLevelRequest", -- 请求设置副本难度
        SetAutoMatchRequest = "SetAutoMatchRequest", --设置自动匹配是否开启
        SetAbilityLimitRequest = "SetAbilityLimitRequest", --修改房间战力限制

        -- 区域联机相关
        ArenaOnlineCreateRoomRequest = "ArenaOnlineCreateRoomRequest", --创建房间
        ArenaOnlineStartMatchReqeust = "ArenaOnlineStartMatchReqeust", --匹配
        ArenaOnlineCancelMatchRequest = "ArenaOnlineCancelMatchRequest", --取消匹配
        ArenaOnlineQuitRoomRequest = "ArenaOnlineQuitRoomRequest", --退出房间
        ArenaOnlineReadyRequest = "ArenaOnlineReadyRequest", --准备
        ArenaOnlineCancelReadyRequest = "ArenaOnlineCancelReadyRequest", --取消准备
        ArenaOnlineEnterFightRequest = "ArenaOnlineEnterFightRequest", -- 进入战斗
        ArenaOnlineSelectRequest = "ArenaOnlineSelectRequest", --抽卡
        ArenaOnlineChangeLeaderRequest = "ArenaOnlineChangeLeaderRequest", --切换房主
        ArenaOnlineKickOutRequest = "ArenaOnlineKickOutRequest", --踢人
        ArenaOnlineAddLikeRequest = "ArenaOnlineAddLikeRequest", -- 添加喜欢
        ArenaOnlineUpLoadProcessRequest = "ArenaOnlineUpLoadProcessRequest", -- 更新进度
        ArenaOnlineEnterRoomRequest = "ArenaOnlineEnterRoomRequest", -- 进入目标房间
        ArenaOnlineSelectRewardRequest = "ArenaOnlineSelectRewardRequest", -- 选择奖励
        ArenaOnlineBeginSelectRequest = "ArenaOnlineBeginSelectRequest", -- 进入切换角色状态
        ArenaOnlineEndSelectRequest = "ArenaOnlineEndSelectRequest", -- 退出切换角色状态
        ArenaOnlineSetLevelRequest = "ArenaOnlineSetLevelRequest", -- 请求设置副本难度
        ArenaOnlineSetAutoMatchRequest = "ArenaOnlineSetAutoMatchRequest", --设置自动匹配是否开启
        ArenaOnlineSetAbilityLimitRequest = "ArenaOnlineSetAbilityLimitRequest", --修改房间战力限制
        ArenaOnlineSetStageIdRequest = "ArenaOnlineSetStageIdRequest", --修改关卡

        -- 夏活拍照关联机相关
        FubenPhotoCreateRoomRequest = "FubenPhotoCreateRoomRequest", --创建房间
        FubenPhotoMatchRoomRequest = "FubenPhotoMatchRoomRequest", --匹配
        FubenPhotoCancelMatchRequest = "FubenPhotoCancelMatchRequest", --取消匹配
        FubenPhotoQuitRoomRequest = "FubenPhotoQuitRoomRequest", --退出房间
        FubenPhotoReadyRequest = "FubenPhotoReadyRequest", --准备
        FubenPhotoCancelReadyRequest = "FubenPhotoCancelReadyRequest", --取消准备
        FubenPhotoEnterFightRequest = "FubenPhotoEnterFightRequest", -- 进入战斗
        FubenPhotoChangeLeaderRequest = "FubenPhotoChangeLeaderRequest", --切换房主
        FubenPhotoKickOutRequest = "FubenPhotoKickOutRequest", --踢人
        FubenPhotoAddLikeRequest = "FubenPhotoAddLikeRequest", -- 添加喜欢
        FubenPhotoUpdateLoadProcessRequest = "FubenPhotoUpdateLoadProcessRequest", -- 更新进度
        FubenPhotoEnterTargetRoomRequest = "FubenPhotoEnterTargetRoomRequest", -- 进入目标房间
        FubenPhotoBeginSelectRequest = "FubenPhotoBeginSelectRequest", -- 进入切换角色状态
        FubenPhotoEndSelectRequest = "FubenPhotoEndSelectRequest", -- 退出切换角色状态
        FubenPhotoSetAutoMatchRequest = "FubenPhotoSetAutoMatchRequest", --设置自动匹配是否开启
        FubenPhotoChangeMapRequest = "FubenPhotoChangeMapRequest", --修改关卡
        FubenPhotoSelectRequest = "FubenPhotoSelectRequest",    --选择角色
    }

    function XRoomManager.Init()
        CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, XRoomManager.OnFightExit)
    end

    function XRoomManager.OnFightExit()
        XLog.Debug("XRoomManager.OnFightExit")
        CS.XFightNetwork.Disconnect()
    end

    function XRoomManager.SetRoomData(roomData)
        XRoomManager.RoomData = roomData
        if not roomData and not XLuaUiManager.IsUiShow("UiMultiplayerRoom") and XLuaUiManager.IsUiLoad("UiMultiplayerRoom") then
            XLuaUiManager.Remove("UiMultiplayerRoom")
        end
    end

    --获取默认角色
    function XRoomManager.GetDefaultChar()
        local list = XDataCenter.CharacterManager.GetOwnCharacterList()
        local char
        for _, v in pairs(list) do
            if not char or v.Ability > char.Ability then
                char = v
            end
        end
        return char
    end

    function XRoomManager.CheckPlayerStagePass()
        if not XRoomManager.RoomData then
            return false
        end

        for _, v in pairs(XRoomManager.RoomData.PlayerDataList) do
            if v.Id == XPlayer.Id and v.HaveFirstPass then
                return true
            end
        end

        return false
    end

    --创建房间
    function XRoomManager.CreateRoom(stageId, cb)
        local req = {
            StageId = stageId,
            StageLevel = 1,
            AutoMatch = true,
        }
        XNetwork.Call(RequestProto.CreateRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XRoomManager.Matching = false
                XRoomManager.MatchStageId = nil
                XRoomManager.OnCreateRoom(res.RoomData)
                if cb then
                    cb()
                end
            end)
    end

    --夏活照相关创建房间
    function XRoomManager.PhotoCreateRoom(stageId, cb)
        local req = {
            StageId = stageId,
            StageLevel = 1,
            AutoMatch = true,
        }
        XNetwork.Call(RequestProto.FubenPhotoCreateRoomRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XRoomManager.Matching = false
            XRoomManager.MatchStageId = nil
            XRoomManager.OnCreateRoom(res.RoomData)
            if cb then
                cb()
            end
        end)
    end

    -- 区域联机创建房间
    function XRoomManager.ArenaOnlineCreateRoom(stageId, cb)
        local req = {
            ChallengeId = stageId,
            ChallengeLevel = 1,
            AutoMatch = true,
        }
        XNetwork.Call(RequestProto.ArenaOnlineCreateRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XRoomManager.Matching = false
                XRoomManager.MatchStageId = nil
                XRoomManager.OnCreateRoom(res.Room, XDataCenter.FubenManager.StageType.ArenaOnline)
                if cb then
                    cb()
                end
            end)
    end

    function XRoomManager.OnCreateRoom(roomData,stagetype)
        -- 创建房间
        if XDataCenter.RoomManager.RoomData then
            XLog.Error("XRoomManager.OnCreateRoom错误, RoomManager中RoomData已经有数据")
            XRoomManager.SetRoomData(roomData)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_REFRESH, roomData)
        else
            XRoomManager.SetRoomData(roomData)
            XRoomManager.Matching = false
            XRoomManager.MatchStageId = nil
            --如果是聊天跳转，需要先关闭聊天
            if XLuaUiManager.IsUiShow("UiChatServeMain") then
                XLuaUiManager.Close("UiChatServeMain")
            end
            -- XLuaUiManager.Open("UiOnLineTranscriptRoom")
            XLuaUiManager.Open("UiMultiplayerRoom")
            local stageId = roomData.StageId
            local challengeId = roomData.ChallengeId
            local stageInfo
            if XDataCenter.FubenManager.StageType.ArenaOnline == stagetype then
                stageInfo = XDataCenter.ArenaOnlineManager.GetStageInfo(challengeId)
            else
                stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            end
            XDataCenter.RoomManager.StageInfo = stageInfo
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_ENTER_ROOM)
        end
    end

    function XRoomManager.BeginSelectRequest(cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineBeginSelectRequest(cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoBeginSelectRequest(cb)
        else
            XRoomManager.NormalBeginSelectRequest(cb)
        end
    end

    function XRoomManager.NormalBeginSelectRequest(cb)
        XNetwork.Call(RequestProto.BeginSelectRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    function XRoomManager.PhotoBeginSelectRequest(cb)
        XNetwork.Call(RequestProto.FubenPhotoBeginSelectRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    function XRoomManager.ArenaOnlineBeginSelectRequest(cb)
        XNetwork.Call(RequestProto.ArenaOnlineBeginSelectRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                
                local roomData = XRoomManager.RoomData
                for _, playerData in pairs(roomData.PlayerDataList) do
                    if XPlayer.Id == playerData.Id then
                        playerData.State = XDataCenter.RoomManager.PlayerState.Select
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, playerData)
                        break
                    end
                end
                
                if cb then
                    cb()
                end
            end)
    end

    function XRoomManager.EndSelectRequest(cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineEndSelectRequest(cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoEndSelectRequest(cb)
        else
            XRoomManager.NormalEndSelectRequest(cb)
        end
    end

    function XRoomManager.NormalEndSelectRequest(cb)
        XNetwork.Call(RequestProto.EndSelectRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    function XRoomManager.PhotoEndSelectRequest(cb)
        XNetwork.Call(RequestProto.FubenPhotoEndSelectRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    function XRoomManager.ArenaOnlineEndSelectRequest(cb)
        XNetwork.Call(RequestProto.ArenaOnlineEndSelectRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                
                local roomData = XRoomManager.RoomData
                for _, playerData in pairs(roomData.PlayerDataList) do
                    if XPlayer.Id == playerData.Id then
                        playerData.State = XDataCenter.RoomManager.PlayerState.STOP
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, playerData)
                        break
                    end
                end
                
                if cb then
                    cb()
                end
            end)
    end

    --匹配
    function XRoomManager.Match(stageId, cb)
        local req = { StageId = stageId }

        XNetwork.Call(RequestProto.MatchRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XRoomManager.Matching = true
                XRoomManager.MatchStageId = stageId

                if cb then
                    cb()
                end
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_MATCH)
            end)
    end

    --匹配
    function XRoomManager.PhotoMatch(stageId, cb)
        local req = { StageId = stageId }
        XRoomManager.MatchType = XDataCenter.FubenManager.StageType.SpecialTrain

        XNetwork.Call(RequestProto.FubenPhotoMatchRoomRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XRoomManager.Matching = true
            XRoomManager.MatchStageId = stageId

            if cb then
                cb()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_MATCH)
        end)
    end

    -- 区域联机匹配
    function XRoomManager.AreanaOnlineMatch(stageId, cb)
        local req = { ChallengeId = stageId }
        XRoomManager.MatchType = XDataCenter.FubenManager.StageType.ArenaOnline

        XNetwork.Call(RequestProto.ArenaOnlineStartMatchReqeust, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XRoomManager.Matching = true
                XRoomManager.MatchStageId = stageId

                if cb then
                    cb()
                end
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_MATCH)
            end)
    end

    --取消匹配
    function XRoomManager.CancelMatch(cb)
        if XRoomManager.MatchType == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.CancelArenaOnlineMatch(cb)
        elseif XRoomManager.MatchType == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.CancelPhotoMatch(cb)
        else
            XRoomManager.CancelNormalMatch(cb)
        end
    end

    --取消正常匹配
    function XRoomManager.CancelNormalMatch(cb)
        if XRoomManager.DoingCancel or not XRoomManager.Matching then
            return
        end
        XRoomManager.DoingCancel = true

        local req = { StageId = XRoomManager.MatchStageId }
        XNetwork.Call(RequestProto.CancelMatchRequest, req, function(res)
                XRoomManager.DoingCancel = false
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XRoomManager.Matching = false
                XRoomManager.MatchStageId = nil

                if cb then
                    cb()
                end

                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
            end)
    end

    --取消夏活照相关匹配
    function XRoomManager.CancelPhotoMatch(cb)
        if XRoomManager.DoingCancel or not XRoomManager.Matching then
            return
        end
        XRoomManager.DoingCancel = true

        local req = { StageId = XRoomManager.MatchStageId }
        XNetwork.Call(RequestProto.FubenPhotoCancelMatchRequest, req, function(res)
            XRoomManager.DoingCancel = false
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XRoomManager.Matching = false
            XRoomManager.MatchStageId = nil

            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
        end)
    end

    -- 区域联机取消匹配
    function XRoomManager.CancelArenaOnlineMatch(cb)
        XRoomManager.MatchType = nil
        if XRoomManager.DoingCancel or not XRoomManager.Matching then
            return
        end
        XRoomManager.DoingCancel = true

        local req = { }
        XNetwork.Call(RequestProto.ArenaOnlineCancelMatchRequest, req, function(res)
                XRoomManager.DoingCancel = false
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XRoomManager.Matching = false
                XRoomManager.MatchStageId = nil

                if cb then
                    cb()
                end

                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
            end)
    end

    --退出房间
    function XRoomManager.Quit(cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineQuit(cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoQuit(cb)
        else
            XRoomManager.NormalQuit(cb)
        end
    end

    --普通退出房间
    function XRoomManager.NormalQuit(cb)
        local req = {}
        XNetwork.Call(RequestProto.QuitRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                end
                if XFightNetwork.IsConnected() then
                    -- 退出房间时如果已经连接战斗服，则断开连接
                    CS.XFightNetwork.Disconnect()
                end
            XRoomManager.SetRoomData(nil)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
                if cb then
                    cb()
                end
            end)
    end

    --夏活照相关退出房间
    function XRoomManager.PhotoQuit(cb)
        local req = {}
        XNetwork.Call(RequestProto.FubenPhotoQuitRoomRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end
            if XFightNetwork.IsConnected() then
                -- 退出房间时如果已经连接战斗服，则断开连接
                CS.XFightNetwork.Disconnect()
            end
            XRoomManager.SetRoomData(nil)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
            if cb then
                cb()
            end
        end)
    end

    --区域联机退出房间
    function XRoomManager.ArenaOnlineQuit(cb)
        local req = {}
        XNetwork.Call(RequestProto.ArenaOnlineQuitRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                end
                if XFightNetwork.IsConnected() then
                    -- 退出房间时如果已经连接战斗服，则断开连接
                    CS.XFightNetwork.Disconnect()
                end
                XRoomManager.RoomData = nil
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
                if cb then
                    cb()
                end
            end)
    end

    -- 准备
    function XRoomManager.Ready(cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineReady(cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoReady(cb)
        else
            XRoomManager.NormalReady(cb)
        end
    end

    --普通准备
    function XRoomManager.NormalReady(cb)
        XNetwork.Call(RequestProto.ReadyRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    --夏活照相关准备
    function XRoomManager.PhotoReady(cb)
        XNetwork.Call(RequestProto.FubenPhotoReadyRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    --区域联机准备
    function XRoomManager.ArenaOnlineReady(cb)
        XNetwork.Call(RequestProto.ArenaOnlineReadyRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local roomData = XDataCenter.RoomManager.RoomData
                if roomData then
                    for _, v in pairs(roomData.PlayerDataList) do
                        if v.Id == XPlayer.Id then
                            v.State = XRoomManager.PlayerState.Ready
                            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, v)
                            return
                        end
                    end
                end

                if cb then
                    cb()
                end
            end)
    end

    --取消准备
    function XRoomManager.CancelReady(cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.CancelAreanOnlineReady(cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.CancelPhotoReady()
        else
            XRoomManager.CancelNormalReady()
        end
    end

    --普通取消准备
    function XRoomManager.CancelNormalReady()
        XNetwork.Send(RequestProto.CancelReadyRequest, {})
    end

    --夏活照相关取消准备
    function XRoomManager.CancelPhotoReady()
        XNetwork.Send(RequestProto.FubenPhotoCancelReadyRequest, {})
    end

    --区域联机取消准备
    function XRoomManager.CancelAreanOnlineReady(cb)
        XNetwork.Call(RequestProto.ArenaOnlineCancelReadyRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local roomData = XDataCenter.RoomManager.RoomData
                if roomData then
                    for _, v in pairs(roomData.PlayerDataList) do
                        if v.Id == XPlayer.Id then
                            v.State = XRoomManager.PlayerState.Normal
                            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, v)
                            return
                        end
                    end
                end

                if cb then
                    cb()
                end
            end)
    end

    --进入战斗
    function XRoomManager.Enter(cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineEnter(cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoEnter(cb)
        else
            XRoomManager.NormalEnter(cb)
        end
    end

    --普通进入战斗
    function XRoomManager.NormalEnter(cb)
        if not XRoomManager.RoomData then
            return
        end

        local stageInfo = XDataCenter.FubenManager.GetStageInfo(XRoomManager.RoomData.StageId)
        if stageInfo.Type == XDataCenter.FubenManager.StageType.BossOnline and XDataCenter.FubenBossOnlineManager.CheckOnlineBossTimeOut() then
            XUiManager.TipMsg(CS.XTextManager.GetText("OnlineBossTimeOut"))
            return
        end

        XNetwork.Call(RequestProto.EnterFightRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    if res.Code ~= XCode.MatchRoomInFight then
                        XUiManager.TipCode(res.Code)
                    end
                    XLog.Debug("XRoomManager.NormalEnter error, " .. tostring(res.Code))
                    return
                end

                if cb then
                    cb(res)
                end
            end)
    end

    --夏活照相关进入战斗
    function XRoomManager.PhotoEnter(cb)
        if not XRoomManager.RoomData then
            return
        end

        XNetwork.Call(RequestProto.FubenPhotoEnterFightRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                if res.Code ~= XCode.MatchRoomInFight then
                    XUiManager.TipCode(res.Code)
                end
                XLog.Debug("XRoomManager.PhotoEnter error, " .. tostring(res.Code))
                return
            end
            if cb then
                cb(res)
            end
        end)
    end

    --区域联机进入战斗
    function XRoomManager.ArenaOnlineEnter(cb)
        if not XRoomManager.RoomData then
            return
        end

        XNetwork.Call(RequestProto.ArenaOnlineEnterFightRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    if res.Code ~= XCode.MatchRoomInFight then
                        XUiManager.TipCode(res.Code)
                    end
                    XLog.Debug("XRoomManager.ArenaOnlineEnter error, " .. tostring(res.Code))
                    return
                end
                if cb then
                    cb(res)
                end
            end)
    end

    function XRoomManager.Select(charId, cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineSelect(charId, cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoSelect(charId,cb)
        else
            XRoomManager.NormalSelect(charId, cb)
        end
    end

    function XRoomManager.NormalSelect(charId, cb)
        local req = { CharacterId = charId }

        XNetwork.Call(RequestProto.SelectRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb(res.Code)
                end
            end)
    end

    function XRoomManager.PhotoSelect(charId, cb)
        local req = { CharacterId = charId }

        XNetwork.Call(RequestProto.FubenPhotoSelectRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb(res.Code)
            end
        end)
    end


    function XRoomManager.ArenaOnlineSelect(charId, cb)
        local req = { CharacterId = charId }

        XNetwork.Call(RequestProto.ArenaOnlineSelectRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb(res.Code)
                end
            end)
    end

    --切换房主
    function XRoomManager.ChangeLeader(playerId, cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineChangeLeader(playerId, cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoChangeLeader(playerId, cb)
        else
            XRoomManager.NormalChangeLeader(playerId, cb)
        end
    end

    --普通切换房主
    function XRoomManager.NormalChangeLeader(playerId, cb)
        local req = { PlayerId = playerId }
        XNetwork.Call(RequestProto.ChangeLeaderRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    --夏活照相关切换房主
    function XRoomManager.PhotoChangeLeader(playerId, cb)
        local req = { PlayerId = playerId }
        XNetwork.Call(RequestProto.FubenPhotoChangeLeaderRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    --区域联机切换房主
    function XRoomManager.ArenaOnlineChangeLeader(playerId, cb)
        local req = { PlayerId = playerId }
        XNetwork.Call(RequestProto.ArenaOnlineChangeLeaderRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local roomData = XDataCenter.RoomManager.RoomData
                if roomData then
                    for _, v in pairs(roomData.PlayerDataList) do
                        if v.Id == playerId then
                            v.Leader = true
                        else
                            v.Leader = false
                        end
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
                    end
                end

                if cb then
                    cb()
                end
            end)
    end

    --踢出房间
    function XRoomManager.KickOut(playerId, cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineKickOut(playerId, cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoKickOut(playerId, cb)
        else
            XRoomManager.NormalKickOut(playerId, cb)
        end
    end

    --普通踢出房间
    function XRoomManager.NormalKickOut(playerId, cb)
        local req = { PlayerId = playerId }
        XNetwork.Call(RequestProto.KickOutRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    --普通踢出房间
    function XRoomManager.PhotoKickOut(playerId, cb)
        local req = { PlayerId = playerId }
        XNetwork.Call(RequestProto.FubenPhotoKickOutRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    --踢出房间
    function XRoomManager.ArenaOnlineKickOut(playerId, cb)
        local req = { PlayerId = playerId }
        XNetwork.Call(RequestProto.ArenaOnlineKickOutRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- 设置房间等级难度
    function XRoomManager.SetStageLevel(level, cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.AreanOnlineSetStageLevel(level, cb)
        else
            XRoomManager.NormalSetStageLevel(level, cb)
        end
    end

    -- 普通设置房间等级难度
    function XRoomManager.NormalSetStageLevel(level, cb)
        local req = { Level = level }
        XNetwork.Call(RequestProto.SetStageLevelRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- 区域联机设置房间等级难度
    function XRoomManager.AreanOnlineSetStageLevel(level, cb)
        local data = XDataCenter.RoomManager.RoomData
        local req = { ChallengeId = data.ChallengeId,ChallengeLevel = level }
        XNetwork.Call(RequestProto.ArenaOnlineSetStageIdRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- 夏活照相关设置关卡
    function XRoomManager.PhotoChangeMapRequest(stageId, cb)
        local req = {StageId = stageId}
        XNetwork.Call(RequestProto.FubenPhotoChangeMapRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    -- 设置房间是否自动匹配
    function XRoomManager.SetAutoMatch(autoMatch, cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineSetAutoMatch(autoMatch, cb)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoSetAutoMatch(autoMatch, cb)
        else
            XRoomManager.NormalSetAutoMatch(autoMatch, cb)
        end
    end

    -- 普通设置房间是否自动匹配
    function XRoomManager.NormalSetAutoMatch(autoMatch, cb)
        local req = { AutoMatch = autoMatch }
        XNetwork.Call(RequestProto.SetAutoMatchRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- 夏活照相关设置房间是否自动匹配
    function XRoomManager.PhotoSetAutoMatch(autoMatch, cb)
        local req = { AutoMatch = autoMatch }
        XNetwork.Call(RequestProto.FubenPhotoSetAutoMatchRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    -- 区域联机设置房间是否自动匹配
    function XRoomManager.ArenaOnlineSetAutoMatch(autoMatch, cb)
        local req = { AutoMatch = autoMatch }
        XNetwork.Call(RequestProto.ArenaOnlineSetAutoMatchRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- 设置房间战力限制
    function XRoomManager.SetAbilityLimit(abilityLimit, cb)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineSetAbilityLimit(abilityLimit, cb)
        else
            XRoomManager.NormalSetAbilityLimit(abilityLimit, cb)
        end
    end

    -- 普通设置房间战力限制
    function XRoomManager.NormalSetAbilityLimit(abilityLimit, cb)
        local req = { AbilityLimit = abilityLimit }
        XNetwork.Call(RequestProto.SetAbilityLimitRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 区域联机设置房间战力限制
    function XRoomManager.ArenaOnlineSetAbilityLimit(abilityLimit, cb)
        local req = { AbilityLimit = abilityLimit }
        XNetwork.Call(RequestProto.ArenaOnlineSetAbilityLimitRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 区域联机设置关卡
    function XRoomManager.ArenaOnlineSetStageId(stageId, cb)
        local data = XDataCenter.RoomManager.RoomData
        local req = { ChallengeId = stageId,ChallengeLevel = data.ChallengeLevel }
        XNetwork.Call(RequestProto.ArenaOnlineSetStageIdRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    --
    function XRoomManager.AddLike(playerId)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.AddArenaOnlineLike(playerId)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.AddPhotoLike(playerId)
        else
            XRoomManager.AddNormalLike(playerId)
        end
    end

    function XRoomManager.AddNormalLike(playerId)
        local req = { PlayerId = playerId }
        XNetwork.Send(RequestProto.AddLikeRequest, req)
    end

    function XRoomManager.AddArenaOnlineLike(playerId)
        local req = { PlayerId = playerId }
        XNetwork.Send(RequestProto.ArenaOnlineAddLikeRequest, req)
    end
    --夏活拍照关喜欢
    function XRoomManager.AddPhotoLike(playerId)
        local req = { PlayerId = playerId }
        XNetwork.Send(RequestProto.FubenPhotoAddLikeRequest, req)
    end

    function XRoomManager.UpdateLoadProcess(progress)
        if not XRoomManager.RoomData then
            return
        end
        --战斗计算进度时会出现除零，导致progress无限小，服务端报错。Lua临时处理。
        if progress < 0 then
            return
        end
        --更新进度
        local req = { Process = progress }
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XNetwork.Send(RequestProto.ArenaOnlineUpLoadProcessRequest, req)
        elseif XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XNetwork.Send(RequestProto.FubenPhotoUpdateLoadProcessRequest, req)
        else
            XNetwork.Send(RequestProto.UpdateLoadProcessRequest, req)
        end

    end

    function XRoomManager.ClickEnterRoomHref(param, createTime)
        -- 前置自定义按键冲突检测
        if XDataCenter.FubenManager.CheckCustomUiConflict() then return end
        
        if not param then
            return
        end

        local result = string.Split(param, '|')
        local roomId = result[1]
        local stageId = tonumber(result[2])
        local roomType = tonumber(result[3])
        
        -- 处理开房链接，狙击战走这里，其他走通用
        local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
        if unionFightData and unionFightData.Id then
            XUiManager.TipCode(XCode.MatchPlayerAlreadyInRoom)
            return
        end
        if MultipleRoomType.UnionKill == roomType then
            XDataCenter.FubenUnionKillRoomManager.ClickEnterRoomHref(roomId, createTime)
            return
        end

        local tempStageId = stageId
        if MultipleRoomType.ArenaOnline == roomType then
            local level = tonumber(result[4])
            tempStageId = XDataCenter.ArenaOnlineManager.GetStageIdByIdAndLevel(stageId, level)
        end

        local stageInfo = XDataCenter.FubenManager.GetStageInfo(tempStageId)
        if not stageInfo then
            return
        end

        local fubenName = ""
        if stageInfo.Type == XDataCenter.FubenManager.StageType.BossOnline then
            fubenName = XFunctionManager.FunctionName.FubenActivity
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.Daily then
            local challengeCfg = XDataCenter.FubenDailyManager.GetDailyCfgBySectionId(stageInfo.DailySectionId)
            if challengeCfg and challengeCfg.Type == XDataCenter.FubenManager.ChapterType.EMEX then
                fubenName = XFunctionManager.FunctionName.FubenDailyEMEX
            end
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            fubenName = XFunctionManager.FunctionName.ArenaOnline
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            fubenName = XFunctionManager.FunctionName.SpecialTrain
        end

        if not XFunctionManager.DetectionFunction(fubenName) then
            return
        end

        --超链接点击
        if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            --XRoomManager.ArenaOnlineEnterTargetRoom(roomId, stageId, createTime)
            XUiManager.TipText("ActivityAlreadyClose")
        elseif stageInfo.Type == XDataCenter.FubenManager.StageType.SpecialTrain then
            XRoomManager.PhotoEnterTargetRoom(roomId, stageId, createTime)
        else
            XRoomManager.NormalEnterTargetRoom(roomId, stageId, createTime)
        end
    end

    function XRoomManager.NormalEnterTargetRoom(roomId, stageId, createTime)
        --进入房间
        if XRoomManager.RoomData then
            XUiManager.TipCode(XCode.MatchPlayerAlreadyInRoom)
            return
        end

        if XTime.GetServerNowTimestamp() > createTime + CS.XGame.Config:GetInt("RoomHrefDisableTime") then
            XUiManager.TipText("RoomHrefDisabled")
            return
        end

        local req = { RoomId = roomId, StageId = stageId }
        XNetwork.Call(RequestProto.EnterTargetRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XRoomManager.OnCreateRoom(res.RoomData)
                XUiManager.TipText("OnlineInstanceEnterRoom", XUiManager.UiTipType.Success)
            end)
    end

    function XRoomManager.PhotoEnterTargetRoom(roomId, stageId, createTime)
        --进入房间
        if XRoomManager.RoomData then
            XUiManager.TipCode(XCode.MatchPlayerAlreadyInRoom)
            return
        end

        if XTime.GetServerNowTimestamp() > createTime + CS.XGame.Config:GetInt("RoomHrefDisableTime") then
            XUiManager.TipText("RoomHrefDisabled")
            return
        end

        local req = { RoomId = roomId, StageId = stageId }
        XNetwork.Call(RequestProto.FubenPhotoEnterTargetRoomRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XRoomManager.OnCreateRoom(res.RoomData)
            XUiManager.TipText("OnlineInstanceEnterRoom", XUiManager.UiTipType.Success)
        end)
    end


    function XRoomManager.ArenaOnlineEnterTargetRoom(roomId, stageId, createTime)
        --进入房间
        if XRoomManager.RoomData then
            XUiManager.TipCode(XCode.MatchPlayerAlreadyInRoom)
            return
        end

        if XTime.GetServerNowTimestamp() > createTime + CS.XGame.Config:GetInt("RoomHrefDisableTime") then
            XUiManager.TipText("RoomHrefDisabled")
            return
        end

        local req = { RoomId = roomId, StageId = stageId}
        XNetwork.Call(RequestProto.ArenaOnlineEnterRoomRequest, req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XDataCenter.ArenaOnlineManager.SetCurChapterId()
                XRoomManager.OnCreateRoom(res.Room)
                XUiManager.TipText("OnlineInstanceEnterRoom", XUiManager.UiTipType.Success)
            end)
    end


    function XRoomManager.SelectReward(pos)
        if XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            XRoomManager.ArenaOnlineSelectReward(pos)
        else
            XRoomManager.NormalSelectReward(pos)
        end
    end

    function XRoomManager.NormalSelectReward(pos)
        local req = { Pos = pos }
        XNetwork.Send(RequestProto.SelectRewardRequest, req)
    end

    function XRoomManager.ArenaOnlineSelectReward(pos)
        local req = { Pos = pos }
        XNetwork.Send(RequestProto.ArenaOnlineSelectRewardRequest, req)
    end

    function XRoomManager.OnJoinFightNotify(response)
        local roomData = XDataCenter.RoomManager.RoomData
        if not roomData then
            XLog.Error("XRoomManager.OnJoinFightNotify错误, RoomManager中RoomData没有数据，说明初始化数据失败或者还没有创建房间")
            return
        end

        XRoomManager.ChallengeId = XRoomManager.RoomData.ChallengeId
        
        XNetwork.Call(RequestProto.JoinFightRequest, { NodeId = response.NodeId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                -- 进入战斗前关闭所有弹出框
                XDataCenter.FubenManager.OnEnterFight(res.FightData)
            end)
    end

    function XRoomManager.OnNewJoinFightNotify(response)
        XLog.Debug("XRoomManager.OnNewJoinFightNotify")
        XLog.Debug(response)
        local roomData = XDataCenter.RoomManager.RoomData
        if not roomData then
            XLog.Error("XRoomManager.OnNewJoinFightNotify error, roomData is nil")
            return
        end

        local cb = function(success)
            XLog.Debug("XRoomManager.OnNewJoinFightNotify Cb " .. tostring(success))
            if success then
                XFightNetwork.Call("JoinFightRequest", {FightId = response.FightId, PlayerId = XPlayer.Id, Token = response.Token}, function(res)
                    XRoomManager.OnJoinFightResponse(res, response.IpAddress)
                end)
            elseif not CS.XFight.IsOutFight then
                if CS.XFight.Instance then
                    -- 网络错误，如果战斗已经启动，则退出战斗
                    CS.XFight.Instance.ExitOnOnlineDisconnect()
                end
            end
        end

        XFightNetwork.Connect(response.IpAddress, response.Port, cb)
    end

    function XRoomManager.OnJoinFightResponse(response, ip)
        XLog.Debug("XRoomManager.OnJoinFightResponse")

        if response.Code ~= XCode.Success then
            XLog.Error("XRoomManager.OnJoinFightResponse error, Code:" .. tostring(response.Code))
            return
        end

        if not response.FightData then
            XLog.Error("XRoomManager.OnJoinFightResponse error, fightData is nil")
            CS.XFightNetwork.Disconnect()
            return
        end
        
        local roomData = XDataCenter.RoomManager.RoomData
        if not roomData then
            XLog.Error("XRoomManager.OnJoinFightResponse error, roomData is nil")
            CS.XFightNetwork.Disconnect()
            return
        end

        -- 连接战斗成功后开始心跳
        XFightNetwork.DoHeartbeat()

        if not response.Port or not response.Conv then
            XLog.Error("XRoomManager.OnJoinFightResponse error, port:" .. tostring(response.Port) .. " conv:" .. tostring(response.Conv))
            -- 跳过kcp连接，直接进入战斗
            XDataCenter.FubenManager.OnEnterFight(response.FightData)
            return
        end

        local cb = function(success)
            XLog.Debug("XRoomManager.OnJoinFightResponse Cb " .. tostring(success))
            if not success then
                XLog.Error("kcp disconnect! use tcp for fight")
            end

            local roomData = XDataCenter.RoomManager.RoomData
            if not roomData then
                XLog.Error("XRoomManager.OnJoinFightResponse Cb error, roomData is nil")
                CS.XFightNetwork.Disconnect()
                return
            end

            XDataCenter.FubenManager.OnEnterFight(response.FightData)
        end

        -- 连接kcp
        XFightNetwork.ConnectKcp(ip, response.Port, response.Conv, cb)
    end

    function XRoomManager.IsLeader(playerId)
        for _, v in pairs(XRoomManager.RoomData.PlayerDataList) do
            if v.Id == playerId and v.Leader then
                return true
            end
        end

        return false
    end

    function XRoomManager.OnDisconnect()
        -- -- 区域联机重连不做任何处理
        -- if XRoomManager.StageInfo and XRoomManager.StageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        --     return
        -- end

        -- if XRoomManager.Matching then
        --     XRoomManager.Matching = false
        --     XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
        -- end

        -- if XRoomManager.RoomData then
        --     -- 关战斗
        --     if CS.XFight.Instance and CS.XFight.Instance.Online then
        --         XLuaUiManager.Close("UiLoading")
        --         XLuaUiManager.Close("UiOnLineLoading")
        --         CS.XFight.ClearFight()
        --     end

        --     if XLuaUiManager.IsUiShow("UiChatServeMain") then
        --         XLuaUiManager.Close("UiChatServeMain")
        --     end

        --     if XLuaUiManager.IsUiShow("UiDialog") then
        --         XLuaUiManager.Close("UiDialog")
        --     end

        --     -- 关房间
        --     if XLuaUiManager.IsUiShow("UiMultiplayerRoom") then
        --         XLuaUiManager.Close("UiMultiplayerRoom")
        --     else
        --         XLuaUiManager.Remove("UiMultiplayerRoom")
        --     end

        --     XLuaUiManager.ShowTopUi()

        --     -- 提示&清数据
        --     XUiManager.TipText("OnlineRoomOnDisconnet")
        --     XRoomManager.RoomData = nil
        --     XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
        -- end
    end

    -- 监听断网
    XEventManager.AddEventListener(XEventId.EVENT_NETWORK_DISCONNECT, XRoomManager.OnDisconnect, XRoomManager)

    XRoomManager.Init()
    return XRoomManager
end

XRpc.SelectRewardNotify = function(data)
    XEventManager.DispatchEvent(XEventId.EVENT_ONLINEBOSS_DROPREWARD_NOTIFY, data)
end

XRpc.NotifyArenaOnlineSelectReward = function(data)
    XEventManager.DispatchEvent(XEventId.EVENT_ONLINEBOSS_DROPREWARD_NOTIFY, data)
end

--踢出房间
XRpc.KickOutNotify = function(response)
    if response.Code and response.Code ~= XCode.Success and response.Code ~= XCode.MatchPlayerOffline then
        XUiManager.TipCode(response.Code)
    end
    if XFightNetwork.IsConnected() then
        -- 退出房间时如果已经连接战斗服，则断开连接
        CS.XFightNetwork.Disconnect()
    end
    XDataCenter.RoomManager.SetRoomData(nil)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_KICKOUT)
end

--踢出房间
XRpc.FubenPhotoKickOutNotify = function(response)
    if response.Code and response.Code ~= XCode.Success and response.Code ~= XCode.MatchPlayerOffline then
        XUiManager.TipCode(response.Code)
    end
    if XFightNetwork.IsConnected() then
        -- 退出房间时如果已经连接战斗服，则断开连接
        CS.XFightNetwork.Disconnect()
    end
    XDataCenter.RoomManager.SetRoomData(nil)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_KICKOUT)
end

--更新进度条
XRpc.RefreshLoadProcessNotify = function(response)
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_PROGRESS, response.PlayerId, response.Process)
end

--更新进度条
XRpc.FubenPhotoRefreshLoadProcessNotify = function(response)
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_PROGRESS, response.PlayerId, response.Process)
end

XRpc.FightPlayerListNotify = function(response)
    XDataCenter.RoomManager.FightPlayerList = response.PlayerIdList
end

--踢人倒计时
XRpc.OnCountDownNotify = function(response)
    if response.TimeCount == 0 then
        XDataCenter.RoomManager.CountDowning = false
    else
        XDataCenter.RoomManager.CountDowning = true
    end
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_COUNT_DOWN, response.TimeCount)
end

--匹配通知
XRpc.MatchNotify = function(response)
    if not XDataCenter.RoomManager.Matching then
        return
    end

    if response.Code == XCode.Success then
        XDataCenter.RoomManager.OnCreateRoom(response.RoomData)
    else
        XDataCenter.RoomManager.Matching = false
        XDataCenter.RoomManager.MatchStageId = nil
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
    end
end

--匹配通知
XRpc.FubenPhotoMatchNotify = function(response)
    if not XDataCenter.RoomManager.Matching then
        return
    end

    if response.Code == XCode.Success then
        XDataCenter.RoomManager.OnCreateRoom(response.RoomData)
    else
        XDataCenter.RoomManager.Matching = false
        XDataCenter.RoomManager.MatchStageId = nil
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
    end
end

--联机匹配成功通知
XRpc.NotifyArenaOnlineMatchFinish = function(response)
    if not XDataCenter.RoomManager.Matching then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
    XDataCenter.RoomManager.OnCreateRoom(response.Room)
end

--联机匹配失败通知
XRpc.NotifyArenaOnlineMatchFail = function()
    if not XDataCenter.RoomManager.Matching then
        return
    end

    XDataCenter.RoomManager.Matching = false
    XDataCenter.RoomManager.MatchStageId = nil
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
end

XRpc.PlayerSyncInfoNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, playerInfo in pairs(response.PlayerInfoList) do
            for _, v in pairs(roomData.PlayerDataList) do
                if v.Id == playerInfo.Id then
                    v.State = playerInfo.State
                    v.Leader = playerInfo.Leader
                    if playerInfo.FightNpcData then
                        v.FightNpcData = playerInfo.FightNpcData
                    end
                    break
                end
            end
        end

        -- 先赋值再通知事件
        for _, playerInfo in pairs(response.PlayerInfoList) do
            for _, v in pairs(roomData.PlayerDataList) do
                if v.Id == playerInfo.Id then
                    if playerInfo.FightNpcData then
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
                    else
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, v)
                    end
                    break
                end
            end
        end
    end
end

XRpc.FubenPhotoPlayerSyncInfoNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, playerInfo in pairs(response.PlayerInfoList) do
            for _, v in pairs(roomData.PlayerDataList) do
                if v.Id == playerInfo.Id then
                    v.State = playerInfo.State
                    v.Leader = playerInfo.Leader
                    if playerInfo.FightNpcData then
                        v.FightNpcData = playerInfo.FightNpcData
                    end
                    break
                end
            end
        end

        -- 先赋值再通知事件
        for _, playerInfo in pairs(response.PlayerInfoList) do
            for _, v in pairs(roomData.PlayerDataList) do
                if v.Id == playerInfo.Id then
                    if playerInfo.FightNpcData then
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
                    else
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, v)
                    end
                    break
                end
            end
        end
    end
end


XRpc.NotifyArenaOnlineFightNpcData = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, v in pairs(roomData.PlayerDataList) do
            if v.Id == response.PlayerId then
                if response.FightNpcData then
                    v.FightNpcData = response.FightNpcData
                    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
                    return
                end
            end
        end
    end
end

XRpc.NotifyArenaOnlineLeaderChange = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, v in pairs(roomData.PlayerDataList) do
            if v.Id == response.LeaderId then
                v.Leader = true
            else
                v.Leader = false
            end
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
        end
    end
end

XRpc.NotifyArenaOnlinePlayerState = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, state in pairs(response.PlayerStateList) do
            for _, playerData in pairs(roomData.PlayerDataList) do
                if state.PlayerId == playerData.Id then
                    playerData.State = state.PlayerState
                    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, playerData)
                    break
                end
            end
        end
    end
end

XRpc.PlayerEnterNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        table.insert(roomData.PlayerDataList, response.PlayerData)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_ENTER, response.PlayerData)
    end
end

XRpc.FubenPhotoPlayerEnterNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        table.insert(roomData.PlayerDataList, response.PlayerData)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_ENTER, response.PlayerData)
    end
end

XRpc.NotifyArenaOnlinePlayerEnter = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        table.insert(roomData.PlayerDataList, response.Player)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_ENTER, response.Player)
    end
end

XRpc.PlayerLeaveNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, targetId in pairs(response.Players) do
            for k, v in pairs(roomData.PlayerDataList) do
                if v.Id == targetId then
                    table.remove(roomData.PlayerDataList, k)
                    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_LEAVE, targetId)
                    break
                end
            end
        end
    end
end

XRpc.FubenPhotoPlayerLeaveNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, targetId in pairs(response.Players) do
            for k, v in pairs(roomData.PlayerDataList) do
                if v.Id == targetId then
                    table.remove(roomData.PlayerDataList, k)
                    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_LEAVE, targetId)
                    break
                end
            end
        end
    end
end

XRpc.NotifyArenaOnlinePlayerLeave = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for k, v in pairs(roomData.PlayerDataList) do
            if v.Id == response.PlayerId then
                table.remove(roomData.PlayerDataList, k)
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_LEAVE, response.PlayerId)
                break
            end
        end
    end

    if response.NewLeaderId <= 0 then return end
    if not roomData then return end
    for _, v in pairs(roomData.PlayerDataList) do
        if v.Id == response.NewLeaderId then
            v.Leader = true
        else
            v.Leader = false
        end
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
    end
end

XRpc.NotifyArenaOnlineForceBanish = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then return end

    if response.PlayerId == XPlayer.Id then
        if XDataCenter.RoomManager.IsLeader(response.PlayerId) then
            XUiManager.TipCode(XCode.MatchStartTimeout)
        else
            XUiManager.TipCode(XCode.MatchRoomLeaderForceLeave)
        end
        if XFightNetwork.IsConnected() then
            -- 退出房间时如果已经连接战斗服，则断开连接
            CS.XFightNetwork.Disconnect()
        end
        XDataCenter.RoomManager.SetRoomData(nil)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_KICKOUT)
    else
        for k, v in pairs(roomData.PlayerDataList) do
            if v.Id == response.PlayerId then
                table.remove(roomData.PlayerDataList, k)
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_LEAVE, response.PlayerId)
                break
            end
        end
    end
end


XRpc.JoinFightNotify = function(response)
    if not XDataCenter.RoomManager.RoomData then
        return
    end
    XDataCenter.RoomManager.OnJoinFightNotify(response)
end

XRpc.NewJoinFightNotify = function(response)
    if not XDataCenter.RoomManager.RoomData then
        XLog.Error("XRpc.NewJoinFightNotify, RoomManager中RoomData没有数据，说明初始化数据失败或者还没有创建房间")
        return
    end
    XDataCenter.RoomManager.OnNewJoinFightNotify(response)
end

XRpc.RoomInfoChangeNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    local lastAutoMatch = roomData.AutoMatch
    local lastStageLevel = roomData.StageLevel
    local lastAbilityLimit = roomData.AbilityLimit
    roomData.AutoMatch = response.AutoMatch
    roomData.StageLevel = response.StageLevel
    roomData.AbilityLimit = response.AbilityLimit
    -- 先全部赋值再发事件
    if lastAutoMatch ~= roomData.AutoMatch then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, roomData.AutoMatch)
    end
    if lastStageLevel ~= roomData.StageLevel then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_LEVEL_CHANGE, lastStageLevel, roomData.StageLevel)
    end
    if lastAbilityLimit ~= roomData.AbilityLimit then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, lastAbilityLimit, roomData.AbilityLimit)
    end
end

XRpc.FubenPhotoRoomInfoChangeNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    local lastAutoMatch = roomData.AutoMatch
    local lastStageLevel = roomData.StageLevel
    local lastAbilityLimit = roomData.AbilityLimit
    roomData.AutoMatch = response.AutoMatch
    roomData.StageLevel = response.StageLevel
    roomData.AbilityLimit = response.AbilityLimit
    -- 先全部赋值再发事件
    if lastAutoMatch ~= roomData.AutoMatch then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, roomData.AutoMatch)
    end
    if lastStageLevel ~= roomData.StageLevel then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_LEVEL_CHANGE, lastStageLevel, roomData.StageLevel)
    end
    if lastAbilityLimit ~= roomData.AbilityLimit then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, lastAbilityLimit, roomData.AbilityLimit)
    end
end

-- 区域联机战力变化
XRpc.NotifyArenaOnlineAbilityLimit = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    local lastAbilityLimit = roomData.AbilityLimit
    roomData.AbilityLimit = response.AbilityLimit

    if lastAbilityLimit ~= roomData.AbilityLimit then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, lastAbilityLimit, roomData.AbilityLimit)
    end
end

-- 区域联机难度变化
--XRpc.NotifyArenaOnlineStageLevel = function(response)
--local roomData = XDataCenter.RoomManager.RoomData
--local lastStageLevel = roomData.StageLevel
--roomData.StageLevel = response.StageLevel

--if lastStageLevel ~= roomData.StageLevel then
--XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_LEVEL_CHANGE, lastStageLevel, roomData.StageLevel)
--end
--end

-- 区域联机快速匹配变化
XRpc.NotifyArenaOnlineAutoMatch = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    local lastAutoMatch = roomData.AutoMatch
    roomData.AutoMatch = response.AutoMatch

    if lastAutoMatch ~= roomData.AutoMatch then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, roomData.AutoMatch)
    end
end

XRpc.RoomStateNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    roomData.State = response.State
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_CHANGE, response.State)
end

XRpc.FubenPhotoRoomStateNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    roomData.State = response.State
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_CHANGE, response.State)
end

XRpc.NotifyArenaOnlineRoomState = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then return end

    if response.RoomState == XDataCenter.RoomManager.RoomState.Close then
        XUiManager.TipMsg(CS.XTextManager.GetText("OnlineRoomClose"))
        if XFightNetwork.IsConnected() then
            -- 退出房间时如果已经连接战斗服，则断开连接
            CS.XFightNetwork.Disconnect()
        end
        XDataCenter.RoomManager.SetRoomData(nil)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_KICKOUT)
    else
        roomData.State = response.RoomState
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_CHANGE, response.RoomState)
    end
end

-- 切换关卡通知
XRpc.NotifyArenaOnlineStageId = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    local oldLevel = roomData.ChallengeLevel
    local oldChallengeId = roomData.ChallengeId
    roomData.ChallengeId = response.ChallengeId
    roomData.ChallengeLevel = response.ChallengeLevel
    roomData.StageId = response.StageId
    roomData.StageLevel = response.StageLevel

    local showChange = oldChallengeId == response.ChallengeId

    if showChange then
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_LEVEL_CHANGE, oldLevel, roomData.StageLevel)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CHANGE_STAGE)
    end
end

-- 战斗结束玩家信息推送
XRpc.NotifyArenaOnlinePlayerInfoChange = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        for _, v in pairs(roomData.PlayerDataList) do
            if v.Id == response.PlayerId then
                v.AssistCount = response.AssistCount
                v.HaveFirstPass = response.HaveFirstPass
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
                break
            end
        end
    end
end


XRpc.NotifyArenaOnlineTimeout = function()
    XUiManager.TipText("ArenaOnlineRoomConnectTimeOut")

    if XFightNetwork.IsConnected() then
        -- 退出房间时如果已经连接战斗服，则断开连接
        CS.XFightNetwork.Disconnect()
    end
    XDataCenter.RoomManager.SetRoomData(nil)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_KICKOUT)
end

XRpc.FubenPhotoChangeMapNotify = function(response)
    local roomData = XDataCenter.RoomManager.RoomData
    if roomData then
        roomData.StageId = response.StageId
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CHANGE_STAGE_SUMMER_EPISODE)
    end
end