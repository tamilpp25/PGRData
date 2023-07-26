local XDlcHuntRoom = require("XEntity/XDlcHunt/XDlcHuntRoom")
local XDlcHuntSettle = require("XEntity/XDlcHunt/XDlcHuntSettle")
local XDlcHuntFightBeginData = require("XEntity/XDlcHunt/XDlcHuntFightBeginData")

XDlcRoomManagerCreator = function()
    ---@class XDlcRoomManager
    local XDlcRoomManager = {}

    -- private
    ---@type XDlcHuntRoom
    local _Room = XDlcHuntRoom.New()

    ---@type XDlcHuntFightBeginData
    local _FightBeginData = XDlcHuntFightBeginData.New()

    ---@type XDlcHuntSettle
    local _Settle = XDlcHuntSettle.New()

    local OldFocusTypeDlcHunt = false

    --region debug
    local _IsDebug = false
    if _IsDebug then
        local XDlcHuntDebug = require("XEntity/XDlcHunt/XDlcHuntDebug")
        XDlcHuntDebug.Hack()
    end
    --region debug

    local RequestProto = {
        JoinWorldRequest = "JoinWorldRequest",
        DlcCreateRoomRequest = "DlcCreateRoomRequest", --创建房间
        DlcMatchRoomRequest = "DlcMatchRoomRequest", --匹配
        DlcCancelMatchRequest = "DlcCancelMatchRequest", --取消匹配
        DlcQuitRoomRequest = "DlcQuitRoomRequest", --退出房间
        DlcReadyRequest = "DlcReadyRequest", --准备
        DlcCancelReadyRequest = "DlcCancelReadyRequest", --取消准备
        DlcEnterWorldRequest = "DlcEnterWorldRequest", -- 进入大世界
        DlcSelectRequest = "DlcSelectRequest",
        DlcChangeLeaderRequest = "DlcChangeLeaderRequest", --切换房主
        DlcKickOutRequest = "DlcKickOutRequest", --踢人
        DlcAddLikeRequest = "DlcAddLikeRequest", -- 添加喜欢
        --DlcUpdateLoadProcessRequest = "DlcUpdateLoadProcessRequest", -- 更新进度
        DlcEnterTargetRoomRequest = "DlcEnterTargetRoomRequest", -- 进入目标房间
        DlcBeginSelectRequest = "DlcBeginSelectRequest", -- 进入切换角色状态
        DlcEndSelectRequest = "DlcEndSelectRequest", -- 退出切换角色状态
        DlcSetAutoMatchRequest = "DlcSetAutoMatchRequest", --设置自动匹配是否开启
        DlcSetAbilityLimitRequest = "DlcSetAbilityLimitRequest", --修改房间战力限制
        DlcBackOnlineRequest = "DlcBackOnlineRequest" -- 重连dlc世界
    }

    function XDlcRoomManager.Init()
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLCFIGHT_NPC_LOAD_COMPLETE, function(eventName, params)
            -- local uuid = params[0]
            local isLocalPlayer = params[1]
            if isLocalPlayer then
                XDataCenter.FubenManager.CloseFightLoading()
            end

            -- 教学关需要退出房间，但是为了指引，不能在进战斗瞬间关闭房间界面
            if _Room and _Room:IsTutorial() then
                XDlcRoomManager.Quit()
            end
        end)

        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_PRE_EXIT, function(eventName, params)
            local worldData = CS.StatusSyncFight.XFightClient.FightInstance.WorldData
            if not worldData then
                return
            end
            if worldData.IsLocalDebug then
                return
            end
            if worldData.IsTeaching then
                return
            end
            if not worldData.Online then
                return
            end
            if not XLuaUiManager.IsUiShow("UiDlcHuntSettlement")
                    and not XLuaUiManager.IsUiPushing("UiDlcHuntSettlement")
                    and not XLuaUiManager.IsUiShow("UiDlcHuntPowerSettleLose")
                    and not XLuaUiManager.IsUiPushing("UiDlcHuntPowerSettleLose")
                    and not XLuaUiManager.IsUiShow("UiDlcHuntSettleLose")
                    and not XLuaUiManager.IsUiPushing("UiDlcHuntSettleLose")
            then
                XLuaUiManager.Open("UiBiancaTheatreBlack")
            end
        end)
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_WORLD_EXIT, function(eventName, params, c, d)
            if OldFocusTypeDlcHunt then
                XDataCenter.SetManager.SetFocusTypeDlcHunt(OldFocusTypeDlcHunt)
                OldFocusTypeDlcHunt = false
            end
            if not XFightUtil.IsDlcOnline() then
                return
            end
            if not params then
                XDlcRoomManager.ChallengeLose()
                return
            end
            local settleResult = params[0]
            XDlcRoomManager.CallFinishFight(settleResult)
        end)
    end

    function XDlcRoomManager.IsMatching()
        return _Room:IsMatching()
    end

    function XDlcRoomManager.IsCancelingMatch()
        return _Room:IsCancelingMatch()
    end

    ---@return XDlcHuntTeam
    function XDlcRoomManager.GetTeam(teamId)
        return _Room:GetTeam(teamId)
    end

    function XDlcRoomManager.GetRoomState()
        return _Room:GetState()
    end

    function XDlcRoomManager.IsRoomAutoMatch()
        return _Room:IsAutoMatch()
    end

    -- match
    ---@param world XDlcHuntWorld
    function XDlcRoomManager.Match(world, needMatchCountCheck)
        if XDlcRoomManager.IsMatching() or XDlcRoomManager.IsCancelingMatch() then
            return
        end

        local req = {
            WorldInfoId = world:GetWorldId(),
            NeedMatchCountCheck = needMatchCountCheck ~= false
        }
        local replyFunc = function(res)
            if res.Code == XCode.MatchInvalidToManyMatchPlayers then
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_MATCH_PLAYERS, res.Code)
                return
            end
            if res.Code == XCode.MatchPlayerHaveNotCreateRoom then
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_MATCH_PLAYERS, res.Code)
                return
            end
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _Room:SetMatching(true)
        end
        XNetwork.Call(RequestProto.DlcMatchRoomRequest, req, replyFunc)
    end

    -- cancel match with DialogTip
    function XDlcRoomManager.CancelMatch(callback)
        local title = XUiHelper.GetText("TipTitle")
        local cancelMatchMsg = XUiHelper.GetText("OnlineInstanceCancelMatch")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.DlcRoomManager.ReqCancelMatch(callback)
        end)
    end

    -- request cancel match
    function XDlcRoomManager.ReqCancelMatch(reqCallback)
        if not XDlcRoomManager.IsMatching() or XDlcRoomManager.IsCancelingMatch() then
            return false
        end
        _Room:SetCancelingMatch(true)
        local replyFunc = function(res)
            _Room:SetCancelingMatch(false)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _Room:SetMatching(false)
            if reqCallback then
                reqCallback()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
        end
        --region Debug
        if _IsDebug then
            XScheduleManager.ScheduleOnce(function()
                replyFunc({ Code = XCode.Success })
            end, 0)
            return
        end
        --endregion Debug
        XNetwork.Call(RequestProto.DlcCancelMatchRequest, {}, replyFunc)
    end

    function XDlcRoomManager.CreateRoomTutorial()
        local req = {
            WorldInfoId = XDlcHuntConfigs.TUTORIAL_WORLD.Id,
            LevelId = XDlcHuntConfigs.TUTORIAL_WORLD.LevelId,
            BornPointId = nil,
            IsOnline = false,
            AutoMatch = false,
        }
        local replyFunc = function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            OldFocusTypeDlcHunt = XDataCenter.SetManager.FocusTypeDlcHunt
            XDataCenter.SetManager.SetFocusTypeDlcHunt(XSetConfigs.FocusTypeDlcHunt.Auto)
            XDlcRoomManager.OnCreateRoom(res.RoomData, false, true)
            _Room:SetLevel(req.LevelId)
        end
        XNetwork.Call(RequestProto.DlcCreateRoomRequest, req, replyFunc)
    end

    function XDlcRoomManager.IsInTutorialWorld()
        return OldFocusTypeDlcHunt and true or false
    end

    -- create room
    ---@param world XDlcHuntWorld
    function XDlcRoomManager.CreateRoom(world, bornPointId, IsMultiplayer, cb)
        local req = {
            WorldInfoId = world:GetWorldId(),
            --LevelId = 13,
            BornPointId = bornPointId,
            IsOnline = IsMultiplayer,
            AutoMatch = true,
        }
        local replyFunc = function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _Room:SetMatching(false)
            if IsMultiplayer then
                XDlcRoomManager.OnCreateRoom(res.RoomData)
                if cb then
                    cb()
                end
            else
                XDlcRoomManager.Enter(cb)
            end
        end
        XNetwork.Call(RequestProto.DlcCreateRoomRequest, req, replyFunc)
    end

    -- enter world
    function XDlcRoomManager.Enter(cb, callbackOnFail)
        if _Room:IsTutorial() then
            --(int WorldId, int LevelId, int PlayerId, int NpcId)
            local worldId = _Room:GetWorldId()
            local levelId = _Room:GetLevel()
            local playerId = 0--XPlayer.Id
            local member = _Room:GetTeam():GetSelfMember()
            if not member then
                XLog.Error("[XDlcRoomManager] Tutorial Room, member is not found")
                return
            end
            local npcId = member:GetNpcId()
            XLuaUiManager.Open("UiLoading", LoadingType.Fight)
            --CS.StatusSyncFight.XFightClient.EnterWorldTutorial(worldId, levelId, playerId, npcId)

            local playerData = CS.XWorldPlayerData()
            playerData.Master = true
            playerData.Id = playerId

            local worldNpcData = CS.XWorldNpcData()
            worldNpcData.Id = npcId
            playerData.NpcList:Add(worldNpcData)

            local worldData = CS.XWorldData()
            worldData.WorldId = worldId
            worldData.LevelId = levelId
            worldData.Online = false
            worldData.IsTeaching = true
            worldData.Players:Add(playerData)

            CS.StatusSyncFight.XFightClient.ExitFight()
            CS.StatusSyncFight.XFightClient.EnterFight(worldData, playerId)
            return
        end

        XNetwork.Call(RequestProto.DlcEnterWorldRequest, {}, function(res)
            --此请求发送之后服务器会解散房间
            if res.Code ~= XCode.Success then
                if res.Code ~= XCode.MatchRoomInFight then
                    XUiManager.TipCode(res.Code)
                end
                XLog.Debug("XDlcRoomManager.Enter error, " .. tostring(res.Code))
                if callbackOnFail then
                    callbackOnFail()
                end
                return
            end

            if cb then
                cb(res)
            end
        end)
    end

    -- 设置房间是否自动匹配
    function XDlcRoomManager.ReqSetAutoMatch(autoMatch)
        local req = { AutoMatch = autoMatch }
        XNetwork.Call(RequestProto.DlcSetAutoMatchRequest, req, function()
        end)
    end

    function XDlcRoomManager.AddLike(playerId)
        local req = { PlayerId = playerId }
        XNetwork.Send(RequestProto.DlcAddLikeRequest, req, function(res)
            if res.Code ~= XCode.MatchRoomInFight then
                XUiManager.TipCode(res.Code)
            end
        end)
    end

    function XDlcRoomManager.IsReconnectFail()
        local rejoinWorldInfo = XDlcRoomManager.ReJoinWorldInfo
        if not rejoinWorldInfo then
            return false
        end
        local remainTime = XDlcRoomManager.GetRejoinRemainTime()
        if remainTime <= 0 then
            return true, XDlcHuntConfigs.RECONNECT_FAIL.TIME_OUT
        end
        if rejoinWorldInfo.Result > 0 then
            return true, rejoinWorldInfo.Result
        end
        return false
    end

    function XDlcRoomManager.OnNewJoinWorldNotify(response, isRejoin)
        if response.Clear then
            XDlcRoomManager.ReJoinWorldInfo = false
            return
        end

        if response.Result and response.Result > 0 then
            XDlcRoomManager.ReJoinWorldInfo = false
            return
        end

        XLog.Debug("XDlcRoomManager.OnNewJoinWorldNotify,IsReJoin:" .. tostring(isRejoin))
        XLuaUiManager.Open("UiLoading", LoadingType.Fight)
        _FightBeginData:SetRoomData(_Room:GetData())

        local disconnectCb = function()
            if CS.StatusSyncFight.XFightClient.FightInstance == nil then
                return
            end
            CS.StatusSyncFight.XFightClient.OnExitFight(true)
            -- XDataCenter.FubenManager.CloseFightLoading()
            --XDlcRoomManager.DialogReconnect()
        end

        local cb = function(success)
            XLog.Debug("XDlcRoomManager.OnNewJoinWorldNotify Cb " .. tostring(success))
            if success then
                if isRejoin then
                    CS.XFightNetwork.IsHandleReconnectionComplete = true
                end
                XFightNetwork.Call(RequestProto.JoinWorldRequest, { WorldNo = response.WorldNo, PlayerId = XPlayer.Id, Token = response.Token, IsRejoin = isRejoin }, function(res)
                    XDlcRoomManager.OnJoinWorldResponse(res, response.IpAddress)
                end)
            else
                -- 网络错误
                disconnectCb()
            end
        end

        XFightNetwork.Connect(response.IpAddress, response.Port, cb, isRejoin, disconnectCb)
    end

    -- 创建房间
    function XDlcRoomManager.OnCreateRoom(roomData, isReconnect, isTutorial)
        if XDlcRoomManager.IsInRoom() then
            XLog.Error("XDlcRoomManager.OnCreateRoom错误, RoomManager中RoomData已经有数据")
            XDlcRoomManager.SetRoomData(roomData)
            _Room:SetIsReconnect(isReconnect)
            _Room:SetIsTutorial(isTutorial)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_REFRESH, roomData)
        else
            XDlcRoomManager.SetRoomData(roomData)
            _Room:SetIsReconnect(isReconnect)
            _Room:SetMatching(false)
            _Room:SetIsTutorial(isTutorial)
            --如果是聊天跳转，需要先关闭聊天
            if XLuaUiManager.IsUiShow("UiChatServeMain") then
                XLuaUiManager.Close("UiChatServeMain")
            end
            XLuaUiManager.Open("UiDlcHuntPlayerRoom2", _Room)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_ENTER_ROOM)
        end
    end

    --退出房间
    function XDlcRoomManager.Quit(cb)
        local req = {}
        local reply = function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end
            if XFightNetwork.IsConnected() then
                -- 退出房间时如果已经连接战斗服，则断开连接
                CS.XFightNetwork.Disconnect()
            end
            XDlcRoomManager.SetRoomData(false)
            if cb then
                cb()
            else
                XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
            end
            XDlcRoomManager.ReJoinWorldInfo = false
        end
        if _IsDebug then
            XScheduleManager.ScheduleOnce(function()
                reply({
                    Code = XCode.Success
                })
            end, 0)
            return
        end
        XNetwork.Call(RequestProto.DlcQuitRoomRequest, req, reply)
    end

    local _SelectType = false
    function XDlcRoomManager.BeginSelectRequest(selectType, cb)
        if _IsDebug then
            return
        end
        if _Room and _Room:IsTutorial() and selectType == XDlcHuntConfigs.RoomSelect.Character then
            return
        end
        if _SelectType then
            return
        end
        _SelectType = selectType
        XNetwork.Call(RequestProto.DlcBeginSelectRequest, {
            SelectType = selectType
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end

    local function EndSelectRequest(selectType)
        XNetwork.Call(RequestProto.DlcEndSelectRequest, {
            EndSelectType = selectType
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end

    function XDlcRoomManager.GetSelectingType()
        return _SelectType
    end

    function XDlcRoomManager.ClearSelectType()
        _SelectType = false
    end

    -- bug，同时发送的请求，服务端却不保证接收顺序，导致要改成在上一个response之后再请求
    function XDlcRoomManager.EndSelectRequest()
        if _IsDebug then
            return
        end
        if not XDlcRoomManager.IsInRoom() then
            return
        end
        if not _SelectType then
            return
        end
        local selectType = _SelectType
        _SelectType = false
        if XDlcRoomManager.IsInRoom() and selectType == XDlcHuntConfigs.RoomSelect.Character then
            local characterId = XDataCenter.DlcHuntCharacterManager.GetFightCharacterId()
            XDlcRoomManager.ReqSelectCharacter(characterId, true)
            return
        end
        EndSelectRequest(selectType)
    end

    function XDlcRoomManager.ReqSelectCharacter(characterId, justForUpdate)
        if not XDlcRoomManager.IsInRoom() then
            return
        end
        local req = { CharacterId = characterId }
        XNetwork.Call(RequestProto.DlcSelectRequest, req, function(res)
            if justForUpdate then
                EndSelectRequest(XDlcHuntConfigs.RoomSelect.Character)
            end
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if not justForUpdate then
                XUiManager.TipText("OnlineFightSuccess", XUiManager.UiTipType.Success)
            end
            XDataCenter.DlcHuntCharacterManager.SetFightCharacter(characterId)
        end)
    end

    function XDlcRoomManager.SetRoomData(roomData)
        if not roomData then
            XDataCenter.DlcHuntChipManager.ClearAssistantChip2Myself()
        end
        _Room:SetData(roomData)
    end

    function XDlcRoomManager.GetRoomData()
        _Room:GetData()
    end

    function XDlcRoomManager._DebugGetRoom()
        return _Room
    end

    function XDlcRoomManager.SetRoomState(state)
        _Room:SetState(state)
    end

    function XDlcRoomManager.IsInRoom()
        return _Room:IsInRoom()
    end

    function XDlcRoomManager.OnDlcMatchNotify(response)
        if not _Room:IsMatching() then
            return
        end
        if response.Code == XCode.Success then
            XDlcRoomManager.OnCreateRoom(response.RoomData)
        else
            _Room:SetMatching(false)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
        end
    end

    function XDlcRoomManager.OnRoomInfoUpdate(response)
        _Room:SetAutoMatching(response.AutoMatch)
    end

    function XDlcRoomManager.OnPlayerInfoUpdate(response)
        _Room:UpdatePlayerInfo(response.PlayerInfoList)
    end

    function XDlcRoomManager.GetRoomName()
        return _Room:GetName()
    end

    ---@return XDlcHuntRoom
    function XDlcRoomManager.GetRoom(roomId)
        return _Room
    end

    --取消准备
    function XDlcRoomManager.CancelReady(cb)
        XNetwork.Send(RequestProto.DlcCancelReadyRequest, {})
    end

    -- 准备
    function XDlcRoomManager.Ready(cb)
        XNetwork.Call(RequestProto.DlcReadyRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if cb then
                cb()
            end
        end)
    end

    function XDlcRoomManager.OnPlayerEnterNotify(response)
        _Room:JoinPlayer(response.PlayerData)
    end

    function XDlcRoomManager.OnPlayerLeaveNotify(response)
        _Room:LeavePlayer(response.Players)
    end

    --region rejoin
    function XDlcRoomManager.SetReJoinWorldInfo(worldInfo)
        XDlcRoomManager.ReJoinWorldInfo = worldInfo
    end

    function XDlcRoomManager.IsCanReconnect()
        if not XDlcRoomManager.ReJoinWorldInfo or not next(XDlcRoomManager.ReJoinWorldInfo) then
            return false
        end
        if XDlcRoomManager.IsReconnectFail() then
            return false
        end
        return true
    end

    function XDlcRoomManager.DoReJoinWorld()
        if XDlcRoomManager.IsCanReconnect() then
            XDataCenter.DlcRoomManager.OnNewJoinWorldNotify(XDlcRoomManager.ReJoinWorldInfo, true)
            XDlcRoomManager.ReJoinWorldInfo = nil
        end
    end

    -- 重连回房间
    function XDlcRoomManager.ReconnectToRoom()
        local confirm = function()
            XNetwork.Call(RequestProto.DlcEnterTargetRoomRequest, {
                RoomId = "",
                IsRejoin = true,
            }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XDlcRoomManager.OnCreateRoom(res.RoomData, true)
            end)
        end
        local cancel = function()
            XDlcRoomManager.Quit()
        end
        XLuaUiManager.Open("UiDlcHuntDialog", nil, XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("DlcHuntReconnectToRoom")), confirm, cancel)
    end

    function XDlcRoomManager.DialogReconnect()
        XLuaUiManager.Open("UiDlcHuntDialog", nil, nil, function()
            local isFail, reason = XDlcRoomManager.IsReconnectFail()
            if isFail then
                if reason == XDlcHuntConfigs.RECONNECT_FAIL.TEAM_FAIL then
                    XUiManager.TipText("DlcHuntReconnectFail1")
                elseif reason == XDlcHuntConfigs.RECONNECT_FAIL.TEAM_FAIL then
                    XUiManager.TipText("DlcHuntReconnectFail2")
                elseif reason == XDlcHuntConfigs.RECONNECT_FAIL.TEAM_FAIL then
                    XUiManager.TipText("DlcHuntReconnectFail3")
                end
                return
            end
            XDataCenter.DlcRoomManager.DoReJoinWorld()
        end, function()
            XDlcRoomManager.ReconnectToRoom()
        end)
    end

    function XDlcRoomManager.GetRejoinRemainTime()
        local rejoinData = XDlcRoomManager.ReJoinWorldInfo
        if not rejoinData then
            return 0
        end
        local expireTime = rejoinData.ReJoinWorldExpireTime or 0
        local time = XTime.GetServerNowTimestamp()
        return math.max(0, expireTime - time)
    end

    --endregion rejoin

    function XDlcRoomManager.OnJoinWorldResponse(response, ip)
        XLog.Debug("XDlcRoomManager.OnJoinWorldResponse")

        if response.Code ~= XCode.Success then
            XLog.Error("XDlcRoomManager.OnJoinWorldResponse error, Code:" .. tostring(response.Code))
            return
        end

        if not response.WorldData then
            XLog.Error("XDlcRoomManager.OnJoinWorldResponse error, WorldData is nil")
            CS.XFightNetwork.Disconnect()
            return
        end

        -- 连接战斗成功后开始心跳
        XFightNetwork.DoHeartbeat()

        if not response.Port or not response.Conv then
            XLog.Error("XDlcRoomManager.OnJoinWorldResponse error, port:" .. tostring(response.Port) .. " conv:" .. tostring(response.Conv))
            -- 跳过kcp连接，直接进入战斗
            XDlcRoomManager.OnEnterWorld(response.WorldData)
            return
        end

        local cb = function(success)
            XLog.Debug("XDlcRoomManager.OnJoinWorldResponse Cb " .. tostring(success))
            if not success then
                XLog.Error("kcp disconnect! use tcp for fight")
            end
            XDlcRoomManager.OnEnterWorld(response.WorldData)
        end

        -- 连接kcp
        XFightNetwork.ConnectKcp(ip, response.Port, response.Conv, cb)
    end

    function XDlcRoomManager.CallFinishFight(settleResult)
        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
    end

    function XDlcRoomManager.ChallengeLose()
        --失败
        XLuaUiManager.Open("UiDlcHuntSettleLose")
    end

    ---@return XDlcHuntFightBeginData
    function XDlcRoomManager.GetFightBeginData()
        return _FightBeginData
    end

    function XDlcRoomManager.OnEnterWorld(worldData)
        XLuaUiManager.Remove("UiDialog")

        local playerData
        for i = 1, #worldData.Players do
            if worldData.Players[i].Id == XPlayer.Id then
                playerData = worldData.Players[i]
                break
            end
        end

        if not playerData then
            XLog.Error("XFubenManager.OnEnterWorld函数出错, 联机副本Players列表中没有找到自身数据")
            return
        end

        CS.StatusSyncFight.XFightClient.EnterFight(worldData, XPlayer.Id)
        _FightBeginData:SetWorldData(worldData)
    end

    function XDlcRoomManager.DialogTipQuitRoom(cb)
        if not XDataCenter.DlcRoomManager.IsInRoom() then
            if cb then
                cb()
            end
            return
        end

        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
        XLuaUiManager.Open("UiDlcHuntDialog", title, cancelMatchMsg, function()
            XDataCenter.DlcRoomManager.Quit(cb)
        end)
    end

    -- 准备
    function XDlcRoomManager.SetAbilityLimit(value)
        XNetwork.Call(RequestProto.DlcSetAbilityLimitRequest, {
            AbilityLimit = value,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _Room:SetAbilityLimit(value)
            XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE)
        end)
    end

    function XDlcRoomManager.KickOut(playerId)
        if not playerId then
            return
        end
        playerId = tonumber(playerId)
        XNetwork.Call(RequestProto.DlcKickOutRequest, {
            PlayerId = playerId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end

    function XDlcRoomManager.ChangeLeader(playerId)
        XNetwork.Call(RequestProto.DlcChangeLeaderRequest, {
            PlayerId = playerId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end

    function XDlcRoomManager.ClickEnterRoomHref(roomId, worldId, createTime)
        -- 检查玩法开启
        if not XDataCenter.DlcHuntManager.IsOpen() then
            return
        end

        -- 超时检查
        if XTime.GetServerNowTimestamp() > createTime + CS.XGame.Config:GetInt("RoomHrefDisableTime") then
            XUiManager.TipText("RoomHrefDisabled")
            return
        end

        XNetwork.Call(RequestProto.DlcEnterTargetRoomRequest, {
            RoomId = roomId,
            IsRejoin = false,
            WorldId = worldId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDlcRoomManager.OnCreateRoom(res.RoomData, true)
        end)
    end

    XDlcRoomManager.Init()
    return XDlcRoomManager
end



--region ------------------------------------notify-------------------------------------
XRpc.DlcSelectRewardNotify = function(data)
    XEventManager.DispatchEvent(XEventId.EVENT_ONLINEBOSS_DROPREWARD_NOTIFY, data)
end

--踢出房间
XRpc.DlcKickOutNotify = function(response)
    XLog.Debug("============================> " .. response.Code)
    if response.Code and response.Code ~= XCode.Success and response.Code ~= XCode.MatchPlayerOffline then
        XUiManager.TipCode(response.Code)
    end
    if XFightNetwork.IsConnected() then
        --现有规则下，进入战斗前会踢出房间，受网速影响会造成推送来的太慢导致进游戏前就断开连接----------------TODO张爽---------可能要改
        -- 退出房间时如果已经连接战斗服，则断开连接
        --CS.XFightNetwork.Disconnect()
    end
    XDataCenter.DlcRoomManager.SetRoomData(false)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_LEAVE_ROOM)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_KICKOUT)
end

--匹配通知
XRpc.DlcMatchNotify = function(response)
    XDataCenter.DlcRoomManager.OnDlcMatchNotify(response)
end

XRpc.DlcPlayerSyncInfoNotify = function(response)
    XDataCenter.DlcRoomManager.OnPlayerInfoUpdate(response)
end

XRpc.NewJoinWorldNotify = function(response)
    XDataCenter.DlcRoomManager.OnNewJoinWorldNotify(response, false)
end

XRpc.DlcRoomInfoChangeNotify = function(response)
    XDataCenter.DlcRoomManager.OnRoomInfoUpdate(response)
end

XRpc.DlcRoomStateNotify = function(response)
    XDataCenter.DlcRoomManager.SetRoomState(response.State)
end

XRpc.DlcPlayerEnterNotify = function(response)
    XDataCenter.DlcRoomManager.OnPlayerEnterNotify(response)
end

XRpc.DlcPlayerLeaveNotify = function(response)
    XDataCenter.DlcRoomManager.OnPlayerLeaveNotify(response)
end

XRpc.DlcReportWorldResult = function(response)
end

XRpc.DlcAddLikeNotify = function(response)
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_ADD_LIKE_NOTIFY, response)
end

--endregion