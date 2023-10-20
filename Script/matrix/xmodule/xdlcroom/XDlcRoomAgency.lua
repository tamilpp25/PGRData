---@class XDlcRoomAgency : XAgency
---@field private _Model XDlcRoomModel
local XDlcRoomAgency = XClass(XAgency, "XDlcRoomAgency")

local RequestProto = {
    JoinWorldRequest = "JoinWorldRequest",
    SwitchWorldIdRequest = "SwitchWorldIdRequest", --切换世界Id
    DlcCreateRoomRequest = "DlcCreateRoomRequest", -- 创建房间
    DlcMatchRoomRequest = "DlcMatchRoomRequest", -- 匹配
    DlcCancelMatchRequest = "DlcCancelMatchRequest", -- 取消匹配
    DlcQuitRoomRequest = "DlcQuitRoomRequest", -- 退出房间
    DlcReadyRequest = "DlcReadyRequest", -- 准备
    DlcCancelReadyRequest = "DlcCancelReadyRequest", -- 取消准备
    DlcEnterWorldRequest = "DlcEnterWorldRequest", -- 进入大世界
    DlcSelectRequest = "DlcSelectRequest",
    DlcChangeLeaderRequest = "DlcChangeLeaderRequest", -- 切换房主
    DlcKickOutRequest = "DlcKickOutRequest", -- 踢人
    DlcAddLikeRequest = "DlcAddLikeRequest", -- 添加喜欢
    DlcUpdateLoadProcessRequest = "DlcUpdateLoadProcessRequest", -- 更新进度
    DlcEnterTargetRoomRequest = "DlcEnterTargetRoomRequest", -- 进入目标房间
    DlcBeginSelectRequest = "DlcBeginSelectRequest", -- 进入切换角色状态
    DlcEndSelectRequest = "DlcEndSelectRequest", -- 退出切换角色状态
    DlcSetAutoMatchRequest = "DlcSetAutoMatchRequest", -- 设置自动匹配是否开启
    DlcSetAbilityLimitRequest = "DlcSetAbilityLimitRequest", -- 修改房间战力限制
    DlcBackOnlineRequest = "DlcBackOnlineRequest" -- 重连dlc世界
}

function XDlcRoomAgency:OnInit()
    ---@type XDlcRoom
    self._Room = nil
    self._IsNeedChangeProtocol = false
    self._IsSelecting = {}
    --- 维护选择角色请求的顺序
    ---@type XQueue[]
    self._SelectRequestQueue = {}
    self._OnFightExitEvent = Handler(self, self._OnFightExit)
end

function XDlcRoomAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.DlcKickOutNotify = Handler(self, self.OnDlcKickOutNotify)
    XRpc.DlcMatchNotify = Handler(self, self.OnDlcMatchNotify)
    XRpc.DlcPlayerSyncInfoNotify = Handler(self, self.OnDlcPlayerSyncInfoNotify)
    XRpc.NewJoinWorldNotify = Handler(self, self.OnNewJoinWorldNotify)
    XRpc.DlcRoomInfoChangeNotify = Handler(self, self.OnDlcRoomInfoChangeNotify)
    XRpc.DlcRoomStateNotify = Handler(self, self.OnDlcRoomStateNotify)
    XRpc.DlcPlayerEnterNotify = Handler(self, self.OnDlcPlayerEnterNotify)
    XRpc.DlcPlayerLeaveNotify = Handler(self, self.OnDlcPlayerLeaveNotify)
    XRpc.DlcAddLikeNotify = Handler(self, self.OnDlcAddLikeNotify)
    XRpc.DlcRefreshLoadProcessNotify = Handler(self, self.OnDlcRefreshLoadProcessNotify)
end

function XDlcRoomAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
    self:_RegisterFightEvent()
end

function XDlcRoomAgency:RemoveEvent()
    self:_RemoveFightEvent()
end

function XDlcRoomAgency:OnRelease()
    self:Close(true)
end

--region Get/Set
---@param room XDlcRoom
function XDlcRoomAgency:SetRoomProxy(room)
    self:Close(true)
    self._Room = room
    self._IsNeedChangeProtocol = self._Room:IsNeedChangeProtocol()
end

function XDlcRoomAgency:GetRoomProxy()
    return self._Room
end

function XDlcRoomAgency:SetMatching(value)
    self._Model:SetIsMatching(value)
end

function XDlcRoomAgency:IsMatching()
    return self._Model:IsMatching()
end

function XDlcRoomAgency:SetCancelingMatch(value)
    self._Model:SetIsCancelingMatch(value)
end

function XDlcRoomAgency:IsCancelingMatch()
    return self._Model:IsCancelingMatch()
end

function XDlcRoomAgency:GetTeam()
    return self._Room:GetTeam()
end

function XDlcRoomAgency:GetRoomState()
    return self._Model:GetRoomState()
end

function XDlcRoomAgency:IsRoomAutoMatch()
    return self._Model:IsRoomAutoMatch()
end

function XDlcRoomAgency:IsInRoom()
    return self._Room and self._Model:IsInRoom()
end

function XDlcRoomAgency:IsSettled()
    return self._Model:IsSettled()
end

function XDlcRoomAgency:GetRoomData()
    return self._Model:GetRoomData()
end

function XDlcRoomAgency:GetRoomName()
    return self._Room:GetName()
end

---@return XDlcFightBeginData
function XDlcRoomAgency:GetFightBeginData()
    return self._Model:GetFightBeginData()
end

function XDlcRoomAgency:IsCanReconnect()
    if not self._Model:CheckCanRejoinWorld() then
        return false
    end
    if self:IsReconnectFail() then
        return false
    end

    return true
end

--- 是否重连失败
function XDlcRoomAgency:IsReconnectFail()
    if not self._Model:CheckCanRejoinWorld() then
        return false
    end

    local rejoinWorldInfo = self._Model:GetReJoinWorldData()
    local remainTime = self:GetRejoinRemainTime()

    if remainTime <= 0 then
        return true, XEnumConst.DlcRoom.RECONNECT_FAIL.TIME_OUT
    end
    if rejoinWorldInfo.Result > 0 then
        return true, rejoinWorldInfo.Result
    end

    return false
end

function XDlcRoomAgency:IsInTutorialWorld()
    -- return self._OldFocusType and true or false
    return self._Model:IsRoomTutorial() and self._Model:IsFighting()
end

function XDlcRoomAgency:IsTutorialRoom()
    return self._Model:IsRoomTutorial()
end

--- 获取重连时间
function XDlcRoomAgency:GetRejoinRemainTime()
    if not self._Model:CheckCanRejoinWorld() then
        return 0
    end

    local rejoinData = self._Model:GetReJoinWorldData()
    local expireTime = rejoinData:GetReJoinExpireTime() or 0
    local time = XTime.GetServerNowTimestamp()

    return math.max(0, expireTime - time)
end

function XDlcRoomAgency:SetReJoinWorldInfo(worldInfo)
    self._Model:SetReJoinWorldData(worldInfo)
end

function XDlcRoomAgency:Settlement()
    self._Model:SetIsSettled(true)
end

function XDlcRoomAgency:Close(isClearRoomProxy)
    if isClearRoomProxy then
        self._Room = nil
    end
    self._IsSelecting = {}
    self._SelectRequestQueue = {}
    self._IsNeedChangeProtocol = false
    self._Model:ClearAll()
end

--endregion

--region 对外接口
--- 初始化战斗
function XDlcRoomAgency:InitFight()
    --- 内部已经做了防止多次初始化判断
    CS.StatusSyncFight.XFight.Init()
end

--- 开始匹配接口
---@param needMatchCountCheck boolean
function XDlcRoomAgency:Match(worldId, needMatchCountCheck)
    if self:IsMatching() or self:IsCancelingMatch() then
        XLog.Error("Now Matching! Don't Repeat Match!")
        return
    end

    self:ReqMatch(worldId, needMatchCountCheck ~= false)
end

--- 取消匹配
function XDlcRoomAgency:CancelMatch()
    if not self:IsMatching() or self:IsCancelingMatch() then
        XLog.Error("Currently not Matching! Can't Cancel Match!")
        return
    end

    self:ReqCancelMatch()
end

--- 创建教学房间
function XDlcRoomAgency:CreateRoomTutorial(worldId, levelId)
    local replyFunc = function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetFocusType(XDataCenter.SetManager.FocusTypeDlcHunt)
        XDataCenter.SetManager.SetFocusTypeDlcHunt(XSetConfigs.FocusTypeDlcHunt.Auto)
        self:_OnCreateRoom(res.RoomData, levelId, false, true)
    end
    
    self:ReqCreateRoom(worldId, levelId, nil, false, false, replyFunc)
end

--- 创建房间
---@param bornPointId number
---@param isMultiplayer boolean
function XDlcRoomAgency:CreateRoom(worldId, levelId, bornPointId, isMultiplayer)
    local replyFunc = function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:SetMatching(false)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH)
        if isMultiplayer then
            self:_OnCreateRoom(res.RoomData, levelId)
        else
            self:Enter()
        end
    end

    self:ReqCreateRoom(worldId, levelId, bornPointId, isMultiplayer, true, replyFunc)
end

--- 进入关卡
---@param cb function
---@param callbackOnFail function
function XDlcRoomAgency:Enter()
    if self._Model:IsRoomTutorial() then
        self:_EnterTutorialWorld()
        return
    end

    self:ReqEnterWorld()
end

--- 设置房间自动匹配
---@param autoMatch boolean
function XDlcRoomAgency:SetAutoMatch(autoMatch)
    self:ReqSetAutoMatch(autoMatch)
end

--- 点赞
---@param playerId number
function XDlcRoomAgency:AddLike(playerId)
    self:ReqAddLike(playerId)
end

--- 退出房间
---@param cb function
function XDlcRoomAgency:Quit(cb)
    self:ReqQuit(cb)
end

--- 开始切换角色请求
---@param selectType XEnumConst.DlcRoom.RoomSelect
function XDlcRoomAgency:BeginSelectRequest(selectType)
    if not self:IsInRoom() then
        return
    end
    if selectType == XEnumConst.DlcRoom.RoomSelect.None then
        return
    end

    if self:_CheckAwaitSelect(selectType) then
        self:_AwaitSelectRequest(selectType, Handler(self, self.ReqBeginSelect))
    else
        self:ReqBeginSelect(selectType)
    end
end

--- 结束切换角色请求
function XDlcRoomAgency:EndSelectRequest(selectType)
    if not self:IsInRoom() then
        return
    end
    if selectType == XEnumConst.DlcRoom.RoomSelect.None then
        return
    end

    if self:_CheckAwaitSelect(selectType) then
        self:_AwaitSelectRequest(selectType, Handler(self, self.ReqEndSelect))
    else
        self:ReqEndSelect(selectType)
    end
end

--- 切换角色请求
---@param selectId number
function XDlcRoomAgency:SelectRequest(selectType, selectId)
    if not self:IsInRoom() and not selectId then
        return
    end
    if selectType == XEnumConst.DlcRoom.RoomSelect.None then
        return
    end

    if self:_CheckAwaitSelect(selectType) then
        self:_AwaitSelectRequest(selectType, function(curSelectType)
            self:ReqSelect(selectId, curSelectType)
        end)
    else
        self:ReqSelect(selectId, selectType)
    end
end

function XDlcRoomAgency:BeginSelectCharacter()
    self:BeginSelectRequest(XEnumConst.DlcRoom.RoomSelect.Character)
end

function XDlcRoomAgency:EndSelectCharacter()
    self:EndSelectRequest(XEnumConst.DlcRoom.RoomSelect.Character)
end

function XDlcRoomAgency:SelectCharacter(characterId)
    self:SelectRequest(XEnumConst.DlcRoom.RoomSelect.Character, characterId)
end

--- 取消准备
function XDlcRoomAgency:CancelReady()
    self:ReqCancelReady()
end

--- 准备
function XDlcRoomAgency:Ready()
    self:ReqReady()
end

--- 重连进入关卡
function XDlcRoomAgency:DoReJoinWorld()
    if self:IsCanReconnect() then
        self:_OnJoinWorld(self._Model:GetReJoinWorldData(), true)
        self._Model:ClearReJoinWorldData()
    end
end

--- 重连回房间
function XDlcRoomAgency:ReconnectToRoom()
    self:ReqEnterTargetWorld("", true)
end

--- 设置战力
---@param value number
function XDlcRoomAgency:SetAbilityLimit(value)
    self:ReqSetAbilityLimit(value)
end

--- 踢出队伍
---@param playerId number
function XDlcRoomAgency:KickOut(playerId, callback)
    if not playerId then
        return
    end

    playerId = tonumber(playerId)
    self:ReqKickOut(playerId, callback)
end

--- 切换队长
---@param playerId number
function XDlcRoomAgency:ChangeLeader(playerId)
    self:ReqChangeLeader(playerId)
end

function XDlcRoomAgency:SwitchWorld(worldId, levelId, callback)
    self:ReqSwitchWorldId(worldId, levelId, callback)
end

--- 自定义按钮检测
---@param roomId number
---@param worldId number
---@param createTime number
function XDlcRoomAgency:ClickEnterRoomHref(roomId, worldId, createTime)
    if not self:_CheckAgencyClickHrefCanEnter(roomId, worldId, createTime) then
        return
    end

    self:ReqEnterTargetWorld(roomId, false, worldId)
end

--endregion

--region 网络请求
function XDlcRoomAgency:ReqMatch(worldId, needMatchCountCheck)
    if self:__CheckHasChangeProtocol("ReqMatch", worldId, needMatchCountCheck) then
        return
    end

    local req = {
        WorldInfoId = worldId,
        NeedMatchCountCheck = needMatchCountCheck ~= false
    }
    local replyFunc = function(res)
        if res.Code == XCode.MatchInvalidToManyMatchPlayers then
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_MATCH_PLAYERS, res.Code, worldId)
            return
        end
        if res.Code == XCode.MatchPlayerHaveNotCreateRoom then
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_MATCH_PLAYERS, res.Code, worldId)
            return
        end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:SetMatching(true)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_MATCH)
    end

    XNetwork.Call(RequestProto.DlcMatchRoomRequest, req, replyFunc)
end

function XDlcRoomAgency:ReqCancelMatch()
    if self:__CheckHasChangeProtocol("ReqCancelMatch") then
        return
    end

    self:SetCancelingMatch(true)

    local replyFunc = function(res)
        self:SetCancelingMatch(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:SetMatching(false)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH)
    end

    XNetwork.Call(RequestProto.DlcCancelMatchRequest, {}, replyFunc)
end

function XDlcRoomAgency:ReqCreateRoom(worldId, levelId, bornPointId, isOnline, autoMatch, reply)
    if self:__CheckHasChangeProtocol("ReqCreateRoom", worldId, levelId, bornPointId, isOnline, autoMatch, reply) then
        return
    end

    local req = {
        WorldInfoId = worldId,
        LevelId = levelId,
        BornPointId = bornPointId,
        IsOnline = isOnline,
        AutoMatch = autoMatch
    }

    XNetwork.Call(RequestProto.DlcCreateRoomRequest, req, reply)
end

function XDlcRoomAgency:ReqEnterWorld()
    if self:__CheckHasChangeProtocol("ReqEnterWorld") then
        return
    end

    XNetwork.Call(RequestProto.DlcEnterWorldRequest, {}, function(res)
        -- 此请求发送之后服务器会解散房间
        if res.Code ~= XCode.Success then
            if res.Code ~= XCode.MatchRoomInFight then
                XUiManager.TipCode(res.Code)
            end
            -- XLog.Debug("XDlcRoomAgency:Enter error, " .. tostring(res.Code))
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ENTER_FIGHT_FAIL, res)
        else
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ENTER_FIGHT_SUCCESS, res)
        end
    end)
end

function XDlcRoomAgency:ReqSetAutoMatch(autoMatch)
    if self:__CheckHasChangeProtocol("ReqSetAutoMatch", autoMatch) then
        return
    end

    XNetwork.Send(RequestProto.DlcSetAutoMatchRequest, { AutoMatch = autoMatch })
end

function XDlcRoomAgency:ReqAddLike(playerId)
    if self:__CheckHasChangeProtocol("ReqAddLike", playerId) then
        return
    end

    XNetwork.Send(RequestProto.DlcAddLikeRequest, { PlayerId = playerId })
end

function XDlcRoomAgency:ReqQuit(cb)
    if self:__CheckHasChangeProtocol("ReqQuit", cb) then
        return
    end

    local reply = function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        if XFightNetwork.IsConnected() then
            -- 退出房间时如果已经连接战斗服，则断开连接
            CS.XFightNetwork.Disconnect()
        end
        -- XDlcRoomManager.SetRoomData(false)
        self._Model:ClearRoomData()
        self._Model:ClearReJoinWorldData()
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_LEAVE_ROOM)

        if cb then
            cb()
        end
    end

    XNetwork.Call(RequestProto.DlcQuitRoomRequest, {}, reply)
end

function XDlcRoomAgency:ReqBeginSelect(selectType)
    if self:__CheckHasChangeProtocol("ReqBeginSelect", selectType) then
        return
    end

    self._IsSelecting[selectType] = true
    XNetwork.Call(RequestProto.DlcBeginSelectRequest, {
        SelectType = selectType
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:_ClearSelectQueue(selectType)
            return
        end

        self._IsSelecting[selectType] = false
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_BEGIN_SELECT_CHARACTER, selectType)
        self:_NextSelectRequest(selectType)
    end)
end

function XDlcRoomAgency:ReqEndSelect(selectType)
    if self:__CheckHasChangeProtocol("ReqEndSelect", selectType) then
        return
    end

    self._IsSelecting[selectType] = true
    XNetwork.Call(RequestProto.DlcEndSelectRequest, {
        EndSelectType = selectType
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:_ClearSelectQueue(selectType)
            return
        end

        self._IsSelecting[selectType] = false
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_END_SELECT_CHARACTER, selectType)
        self:_NextSelectRequest(selectType)
    end)
end

function XDlcRoomAgency:ReqSelect(characterId, selectType)
    if self:__CheckHasChangeProtocol("ReqSelect", characterId) then
        return
    end

    self._IsSelecting[selectType] = true
    local req = { CharacterId = characterId }
    XNetwork.Call(RequestProto.DlcSelectRequest, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:_ClearSelectQueue(selectType)
            return
        end

        self._IsSelecting[selectType] = false
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_SELECT_CHARACTER, characterId, selectType)
        self._Room:SetFightCharacterId(characterId)
        self:_NextSelectRequest(selectType)
    end)
end

function XDlcRoomAgency:ReqCancelReady()
    if self:__CheckHasChangeProtocol("ReqCancelReady") then
        return
    end

    XNetwork.Send(RequestProto.DlcCancelReadyRequest, {})
end

function XDlcRoomAgency:ReqReady()
    if self:__CheckHasChangeProtocol("ReqReady") then
        return
    end

    XNetwork.Call(RequestProto.DlcReadyRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XDlcRoomAgency:ReqEnterTargetWorld(roomId, isRejoin, worldId)
    if self:__CheckHasChangeProtocol("ReqEnterTargetWorld", roomId, isRejoin, worldId) then
        return
    end

    XNetwork.Call(RequestProto.DlcEnterTargetRoomRequest, {
        RoomId = roomId,
        IsRejoin = isRejoin,
        WorldId = worldId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:_OnCreateRoom(res.RoomData, 0, true)
    end)
end

function XDlcRoomAgency:ReqSwitchWorldId(worldId, levelId, callback)
    if self:__CheckHasChangeProtocol("ReqSwitchWorldId", worldId, levelId, callback) then
        return
    end

    XNetwork.Call(RequestProto.SwitchWorldIdRequest, {
        Id = worldId,
        LevelId = levelId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetRoomWorldId(worldId)
        self._Model:SetRoomLevelId(levelId)
        if callback then
            callback()
        end
    end)
end

function XDlcRoomAgency:ReqSetAbilityLimit(value)
    if self:__CheckHasChangeProtocol("ReqSetAbilityLimit", value) then
        return
    end

    XNetwork.Call(RequestProto.DlcSetAbilityLimitRequest, {
        AbilityLimit = value,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local isSuccess = self._Model:SetRoomAbilityLimit(value)

        if isSuccess then
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_ABILITY_LIMIT_CHANGE, value)
        end
    end)
end

function XDlcRoomAgency:ReqKickOut(playerId, callback)
    if self:__CheckHasChangeProtocol("ReqKickOut", playerId) then
        return
    end

    XNetwork.Call(RequestProto.DlcKickOutRequest, {
        PlayerId = playerId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if callback then
            callback()
        end
    end)
end

function XDlcRoomAgency:ReqChangeLeader(playerId)
    if self:__CheckHasChangeProtocol("ReqChangeLeader", playerId) then
        return
    end

    XNetwork.Call(RequestProto.DlcChangeLeaderRequest, {
        PlayerId = playerId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_CHANGE_LEADER)
    end)
end

function XDlcRoomAgency:ReqProcess(process)
    if self:__CheckHasChangeProtocol("ReqProcess", process) then
        return
    end

    XNetwork.Send(RequestProto.DlcUpdateLoadProcessRequest, { Process = process })
end

--endregion

--region 内部方法
function XDlcRoomAgency:_OnJoinWorldResponse(response, ip)
    XLog.Debug("OnJoinWorldResponse...")

    if response.Code ~= XCode.Success then
        XLog.Error("OnJoinWorldResponse: Response is Not Success! Error Code:" .. tostring(response.Code))
        return
    end

    if not response.WorldData then
        XLog.Error("OnJoinWorldResponse: WorldData is nil!")
        CS.XFightNetwork.Disconnect()
        return
    end

    -- 连接战斗成功后开始心跳
    XFightNetwork.DoHeartbeat()

    if not response.Port or not response.Conv then
        XLog.Error("OnJoinWorldResponse: Port or Conv is nil!")
        -- 跳过kcp连接，直接进入战斗
        self:_OnEnterWorld(response.WorldData)
        return
    end

    local cb = function(success)
        XLog.Debug("OnJoinWorldResponse: Connect Kcp is " .. tostring(success))

        if not success then
            XLog.Error("OnJoinWorldResponse: Kcp Connect Failed! Use Tcp!")
        end

        self:_OnEnterWorld(response.WorldData)
    end

    -- 连接kcp
    XFightNetwork.ConnectKcp(ip, response.Port, response.Conv, cb)
end

function XDlcRoomAgency:_OnEnterWorld(worldData)
    XLuaUiManager.Remove("UiDialog")

    local playerData
    for i = 1, #worldData.Players do
        if worldData.Players[i].Id == XPlayer.Id then
            playerData = worldData.Players[i]
            break
        end
    end

    if not playerData then
        XLog.Error("XDlcRoomAgency:OnEnterWorld函数出错, 联机副本Players列表中没有找到自身数据")
        return
    end

    self:_EnterFight(worldData, XPlayer.Id)
    self._Model:ClearFightBeginData()
    self._Model:SetFightBeginRoomData(self._Model:GetRoomData())
    self._Model:SetFightBeginWorldDataBySource(worldData)
end

function XDlcRoomAgency:_OnCreateRoom(roomData, levelId, isReconnect, isTutorial)
    self:_CreateRoomProxy(roomData.WorldId)
    if self:IsInRoom() then
        XLog.Error("XDlcRoomAgency:OnCreateRoom错误, RoomManager中RoomData已经有数据")

        self:_SetRoomData(roomData)
        self._Model:SetRoomIsReconnect(isReconnect)
        self._Model:SetRoomIsTutorial(isTutorial)
        self._Model:SetRoomLevelId(levelId)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_REFRESH, self:GetRoomData())
    else
        self:SetMatching(false)
        self:_SetRoomData(roomData)
        self._Model:SetRoomIsReconnect(isReconnect)
        self._Model:SetRoomIsTutorial(isTutorial)
        self._Model:SetRoomLevelId(levelId)
        -- --如果是聊天跳转，需要先关闭聊天
        -- if XLuaUiManager.IsUiShow("UiChatServeMain") then
        --     XLuaUiManager.Close("UiChatServeMain")
        -- end
        -- XLuaUiManager.Open("UiDlcHuntPlayerRoom2", _Room)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH)
        self._Room:OpenMultiplayerRoom()
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_ENTER_ROOM)
    end
end

function XDlcRoomAgency:_SetRoomData(roomData)
    self._Model:SetRoomData(roomData)

    if self:IsInRoom() then
        self._Room:SetTeamByRoomData(self:GetRoomData())
        self._Room:SetFightCharacterId(self._Room:GetTeam():GetSelfMember():GetCharacterId())
    end
end

---@param response XDlcJoinWorldData
function XDlcRoomAgency:_OnJoinWorld(response, isRejoin)
    -- if response.Clear then
    --     -- self._ReJoinWorldInfo = nil
    --     self._Room:ClearReJoinWorldData()
    --     return
    -- end
    XLog.Debug("OnJoinWorld(IsRejoin = " .. tostring(isRejoin) .. ")...")

    local result = response:GetResult()
    if result and result > 0 then
        XLog.Debug("Fight is Finished!")
        self._Model:ClearReJoinWorldData()
        return
    end

    -- XLog.Debug("XDlcRoomManager.OnNewJoinWorldNotify,IsReJoin:" .. tostring(isRejoin))
    self._Room:OpenFightLoading()
    XMVCA.XDlcWorld:OnEnterFight()

    local disconnectCb = function()
        if CS.StatusSyncFight.XFightClient.FightInstance == nil then
            return
        end
        CS.StatusSyncFight.XFightClient.ExitFight(true)
        self._Model:ClearRoomData()
        self._Model:ClearFightBeginData()
        if not self:IsSettled() then
            self:Settlement()
            self:_OnDisconnect()
        end
        -- XDataCenter.FubenManager.CloseFightLoading()
        -- XDlcRoomManager.DialogReconnect()
        -- self._Room:OpenUi(XEnumConst.DlcRoom.RoomUiType.ReconnectDialog)
    end

    local cb = function(success)
        XLog.Debug("OnJoinWorld: Join World is " .. tostring(success))
        if success then
            if isRejoin then
                CS.XFightNetwork.IsHandleReconnectionComplete = true
            end
            XFightNetwork.Call(RequestProto.JoinWorldRequest, {
                WorldNo = response:GetWorldNo(),
                PlayerId = XPlayer.Id,
                Token = response:GetToken(),
                IsRejoin = isRejoin
            }, function(res)
                self:_OnJoinWorldResponse(res, response:GetIpAddress())
            end)
        else
            -- 网络错误
            disconnectCb()
        end
    end

    XFightNetwork.Connect(response:GetIpAddress(), response:GetPort(), cb, isRejoin, disconnectCb)
end

function XDlcRoomAgency:_EnterFight(worldData, playerId, isExit)
    if isExit then
        CS.StatusSyncFight.XFightClient.RequestExitFight()
    end

    local fightArgs = CS.StatusSyncFight.XFightClientArgs()

    fightArgs.LoadProgressCb = Handler(self, self.ReqProcess)
    fightArgs.CloseLoadingCb = Handler(self, self._OnCloseFightLoading)
    fightArgs.LuaSettleUiCb = Handler(self, self._OnFightSettle)
    fightArgs.CheckLuaSettleCb = Handler(self, self._OnCheckFightSettle)

    self._Model:SetIsFighting(true)
    self._Model:SetIsSettled(false)
    CS.StatusSyncFight.XFightClient.EnterFight(worldData, playerId, fightArgs)
end

function XDlcRoomAgency:_OnCloseFightLoading()
    self._Room:CloseFightLoading()
    if self._Model:IsRoomTutorial() then
        self:Quit()
    end
end

function XDlcRoomAgency:_RegisterFightEvent()
    if self._OnFightExitEvent then
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnFightExitEvent)
    end
end

function XDlcRoomAgency:_RemoveFightEvent()
    if self._OnFightExitEvent then
        CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnFightExitEvent)
    end
end

function XDlcRoomAgency:_OnFightSettle()
    -- 通知战斗结束，关闭战斗设置页面
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
    if self:IsSettled() then
        return
    end
    if self:IsTutorialRoom() then
        self:Settlement()
        self._Room:OnTutorialFightFinish()
        return
    end

    XMVCA.XDlcWorld:OnFightSettle()
end

function XDlcRoomAgency:_OnCheckFightSettle()
    return XMVCA.XDlcWorld:HasResult()
end

function XDlcRoomAgency:_OnFightExit()
    self._Model:SetIsFighting(false)

    if self._Model:IsNeedRevertFocusType() then
        XDataCenter.SetManager.SetFocusTypeDlcHunt(self._Model:GetFocusType())
        self._Model:ClearFocusType()
    end
    if not XFightUtil.IsDlcOnline() then
        return
    end
    
    self:_OnFightFinishExit()
end

function XDlcRoomAgency:_OnDisconnect()
    -- 失败
    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)
    if self._Room then
        self._Room:OnDisconnect()
    end
end

function XDlcRoomAgency:_OnFightFinishExit()
    if self._Room then
        self._Room:OnFightExit()
    end
end

function XDlcRoomAgency:_EnterTutorialWorld()
    local playerId = XPlayer.Id
    local playerData = CS.XWorldPlayerData()
    local worldNpcData = CS.XWorldNpcData()
    local worldData = CS.XWorldData()
    local npcId = self._Room:GetTutorialNpcId()
    local worldId = self._Model:GetRoomWorldId()
    local levelId = self._Model:GetRoomLevelId()

    if npcId == nil then
        XLog.Error("NpcId = nil! 请重写" .. self._Room.__cname .. ":GetTutorialNpcId返回正确NpcId!")
        return
    end
    if worldId == nil then
        XLog.Error("WorldId = nil! 请检查创建房间是否正确!")
        return
    end
    if levelId == nil then
        XLog.Error("LevelId = nil! 请检查创建房间是否正确!")
        return
    end

    playerData.Master = true
    playerData.Id = playerId
    worldNpcData.Id = npcId
    playerData.NpcList:Add(worldNpcData)
    worldData.WorldId = worldId
    worldData.LevelId = levelId
    worldData.Online = false
    worldData.IsTeaching = true
    worldData.WorldType = XMVCA.XDlcWorld:GetWorldTypeById(worldId)
    worldData.Players:Add(playerData)

    self._Room:OpenFightLoading()
    XMVCA.XDlcWorld:OnEnterFight()
    self._Model:SetFightBeginRoomData(self._Model:GetRoomData())
    self:_EnterFight(worldData, playerId, true)
end

function XDlcRoomAgency:_RefreshTeam()
    if self:IsInRoom() then
        local team = self._Room:GetTeam()

        if team then
            team:SetDataWithRoomData(self:GetRoomData())
        end
    end
end

function XDlcRoomAgency:_ClearSelectQueue(selectType)
    self._SelectRequestQueue[selectType] = nil
end

function XDlcRoomAgency:_NextSelectRequest(selectType)
    local queue = self._SelectRequestQueue[selectType]

    if queue then
        local task = queue:Dequeue()

        if task then
            local requestFunc = task.Request

            requestFunc(task.SelectType)
        end
    end
end

function XDlcRoomAgency:_AwaitSelectRequest(selectType, request)
    local queue = self._SelectRequestQueue[selectType]

    if not queue then
        queue = XQueue.New()
        self._SelectRequestQueue[selectType] = queue
    end

    queue:Enqueue({ SelectType = selectType, Request = request })
end

function XDlcRoomAgency:_CreateRoomProxy(worldId)
    local agency = XMVCA.XDlcWorld:GetAgencyByWorldId(worldId)

    if agency then
        self:SetRoomProxy(agency:DlcGetRoomProxy())
    end
end

function XDlcRoomAgency:_CheckAwaitSelect(selectType)
    return self._IsSelecting[selectType]
end

function XDlcRoomAgency:_CheckAgencyClickHrefCanEnter(roomId, worldId, createTime)
    local agency = XMVCA.XDlcWorld:GetAgencyByWorldId(worldId)

    return agency:DlcCheckClickHrefCanEnter(roomId, worldId, createTime)
end

--endregion

--region 特殊方法
function XDlcRoomAgency:__CheckHasChangeProtocol(reqName, ...)
    if not self._IsNeedChangeProtocol then
        return false
    end
    if self._Room[reqName] then
        self._Room[reqName](self._Room, ...)

        return true
    end

    return false
end
--endregion

--region 协议
function XDlcRoomAgency:OnDlcKickOutNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnDlcKickOutNotify(response)
        return 
    end
    if response.Code and response.Code ~= XCode.Success and response.Code ~= XCode.MatchPlayerOffline then
        XUiManager.TipCode(response.Code)
    end

    self._Model:ClearRoomData()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_LEAVE_ROOM)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_KICKOUT)
end

function XDlcRoomAgency:OnDlcMatchNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnDlcMatchNotify(response)
        return 
    end
    if not self:IsMatching() then
        return
    end

    if response.Code == XCode.Success then
        self:_OnCreateRoom(response.RoomData, 0)
    else
        self:SetMatching(false)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH)
    end
end

function XDlcRoomAgency:OnDlcPlayerSyncInfoNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnPlayerInfoUpdate(response)
        return 
    end
    local playerIdList = self._Model:UpdatePlayerInfo(response.PlayerInfoList)

    self:_RefreshTeam()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH, playerIdList)
end

function XDlcRoomAgency:OnNewJoinWorldNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnNewJoinWorldNotify(response, false)
        return 
    end
    local joinWorldData = self._Model:GetJoinWorldDataByResponse(response)

    self:_OnJoinWorld(joinWorldData, false)
end

function XDlcRoomAgency:OnDlcRoomInfoChangeNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnRoomInfoUpdate(response)
        return 
    end
    local isSuccess = self._Model:UpdateRoomData(response)

    if isSuccess then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self:GetRoomData())
    end
end

function XDlcRoomAgency:OnDlcRoomStateNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.SetRoomState(response.State)
        return 
    end
    local isSuccess = self._Model:SetRoomState(response.State)

    if isSuccess then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_STAGE_CHANGE, response.State)
    end
end

function XDlcRoomAgency:OnDlcPlayerEnterNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnPlayerEnterNotify(response)
        return 
    end
    local playerId = self._Model:JoinPlayer(response.PlayerData)

    self:_RefreshTeam()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, playerId)
end

function XDlcRoomAgency:OnDlcPlayerLeaveNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnPlayerLeaveNotify(response)
        return 
    end
    local leaveIdList = self._Model:LeavePlayer(response.Players)

    self:_RefreshTeam()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, leaveIdList)
end

function XDlcRoomAgency:OnDlcAddLikeNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnDlcAddLikeNotify(response)
        return 
    end
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_ADD_LIKE_NOTIFY, response.FromPlayerId, response.ToPlayerId)
end

function XDlcRoomAgency:OnDlcRefreshLoadProcessNotify(response)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_FIGHT_LOADING, response.PlayerId, response.Process)
end

--endregion

return XDlcRoomAgency
