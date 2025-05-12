---@class XDlcRoomAgency : XAgency
---@field private _Model XDlcRoomModel
local XDlcRoomAgency = XClass(XAgency, "XDlcRoomAgency")

local RequestProto = {
    JoinWorldRequest = "JoinWorldRequest",
    SwitchWorldIdRequest = "SwitchWorldIdRequest", -- 切换世界Id
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
    CancelJoinWorldRequest = "CancelJoinWorldRequest", -- 取消重连
    -- DlcBackOnlineRequest = "DlcBackOnlineRequest", -- 重连dlc世界
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
    self._CurFightGUID = nil
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
    XRpc.DlcRebuildRoomAfterFight = Handler(self, self.OnDlcRebuildRoomAfterFight)
    XRpc.RoomGuidNotify = Handler(self, self.OnRoomGuidNotify)
end

function XDlcRoomAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
    self:_RegisterFightEvent()
    XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, self._OnUserLoginOut, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_RECEIVE_CHAT_MESSAGE, self._OnReceivePrivateChat, self)
    XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_PAUSE, self._OnAppStateChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_QUIT, self._OnAppStateChange, self)
end

function XDlcRoomAgency:RemoveEvent()
    self:_RemoveFightEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_USER_LOGOUT, self._OnUserLoginOut, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_RECEIVE_CHAT_MESSAGE, self._OnReceivePrivateChat, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_PAUSE, self._OnAppStateChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_QUIT, self._OnAppStateChange, self)
end

function XDlcRoomAgency:OnRelease()
    self:Close()
    self._Room = nil
end

-- region Get/Set

---@param room XDlcRoom
function XDlcRoomAgency:SetRoomProxy(room)
    self:Close()
    self._Room = room
    self._IsNeedChangeProtocol = self._Room:IsNeedChangeProtocol()
end

function XDlcRoomAgency:GetRoomProxy()
    return self._Room
end

function XDlcRoomAgency:OnRoomGuidNotify(data)
    self._CurFightGUID = data.Guid
end

function XDlcRoomAgency:IsCouldRebuildRoom()
    return self._Model:IsRebuildRoom() and not self._Model:IsRoomDataClear() and self._Room
end

function XDlcRoomAgency:SetMatching(value)
    self._Model:SetIsMatching(value)
end

function XDlcRoomAgency:IsMatching()
    return self._Model:IsMatching()
end

function XDlcRoomAgency:RecordFightQuit(quitCode)
    if not XFightUtil.IsDlcFighting() or not self._CurFightGUID then
        return
    end

    local dict = {}
    dict.fight_guid = self._CurFightGUID
    dict.quit_code = quitCode
    CS.XRecord.Record(dict, "900011", "MouseHunterQuit")
end

function XDlcRoomAgency:_OnAppStateChange(isPause)
    if isPause ~= nil then
        self:RecordFightQuit(isPause and 6 or 5)
    else
        self:RecordFightQuit(7)
    end
end

function XDlcRoomAgency:IsSelfReady()
    if self:GetRoomProxy() and self:GetRoomProxy():GetTeam() then
        local team = self:GetRoomProxy():GetTeam()
        local selfMem = team:GetSelfMember()
        return not selfMem:IsLeader() and selfMem:IsReady()
    end

    return false
end

function XDlcRoomAgency:IsInRoomMatching()
    if self:IsInRoom() then
        local roomData = self:GetRoomData()

        return roomData:GetState() == XEnumConst.DlcRoom.RoomState.Match and self:IsMatching()
    end

    return false
end

function XDlcRoomAgency:SetCancelingMatch(value)
    self._Model:SetIsCancelingMatch(value)
end

function XDlcRoomAgency:IsCancelingMatch()
    return self._Model:IsCancelingMatch()
end

function XDlcRoomAgency:GetTeam()
    if self:IsInRoom() then
        return self._Room:GetTeam()
    end

    return nil
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

function XDlcRoomAgency:HasFightBeginData()
    local beginData = self:GetFightBeginData()

    return beginData and beginData:IsExist()
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
    return self._Model:CheckCanRejoinWorld()
end

function XDlcRoomAgency:IsReconnect()
    return self._Model:IsReconnect()
end

function XDlcRoomAgency:IsInTutorialWorld()
    return self:IsTutorialRoom() and self._Model:IsFighting()
end

function XDlcRoomAgency:IsInWorld()
    return self._Model:IsFighting() and self:IsInRoom()
end

function XDlcRoomAgency:IsTutorialRoom()
    return self._Model:IsRoomTutorial()
end

---@type XDlcJoinWorldData
function XDlcRoomAgency:GetRejoinWorldInfo()
    return self._Model:GetReJoinWorldData()
end

function XDlcRoomAgency:SetReJoinWorldInfo(worldInfo)
    self._Model:SetReJoinWorldData(worldInfo)
end

function XDlcRoomAgency:Settlement()
    self._Model:SetIsSettled(true)
end

function XDlcRoomAgency:IsSelecting(selectType)
    return self._IsSelecting[selectType] == true
end

function XDlcRoomAgency:GetInviteShowTime()
    return self._Model:GetInviteShowTime()
end

function XDlcRoomAgency:GetInviteChatCacheTime()
    return self._Model:GetInviteChatCacheTime()
end

function XDlcRoomAgency:Close()
    self._IsSelecting = {}
    self._SelectRequestQueue = {}
    self._IsNeedChangeProtocol = false
    self._Model:ClearAll()
end

-- endregion

-- region 对外接口

--- 初始化战斗,要在活动下推Notify协议中调用
function XDlcRoomAgency:InitFight()
    --- 内部已经做了防止多次初始化判断
    CS.StatusSyncFight.XFight.Init()
end

function XDlcRoomAgency:RebuildRoom()
    if self:IsCouldRebuildRoom() then
        self._Room:ClearRoomChatMessage()
        self._Room:PopThenOpenMultiplayerRoom()
        self._Model:SetIsRebuildRoom(false)
    end
end

function XDlcRoomAgency:CheckReceiveInvitation(isNext)
    self._Model:UpdateInviteChatDataList()

    local inviteList = self._Model:GetInviteChatDataList()

    if not XTool.IsTableEmpty(inviteList) then
        local inviteData = inviteList[1]

        if inviteData then
            local content = inviteData.Content

            if content then
                local params = string.Split(content, "|")
                local worldId = params and tonumber(params[3]) or nil

                if worldId then
                    local agency = XMVCA.XDlcWorld:GetAgencyByWorldId(worldId)

                    if agency then
                        if not agency:DlcCheckInviteUiShow() or isNext then
                            self._Model:RemoveInviteChatData(inviteData.SenderId)
                            agency:DlcOpenInviteUi(inviteData)
                        end
                    end
                end
            end
        end
    end
end

function XDlcRoomAgency:ClearReceiveInvitation()
    self._Model:ClearInviteChatData()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_CLEAR_INVITE)
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
function XDlcRoomAgency:CancelMatch(callback)
    if not self:IsMatching() or self:IsCancelingMatch() then
        XLog.Error("Currently not Matching! Can't Cancel Match!")
        return
    end

    self:ReqCancelMatch(callback)
end

--- 取消匹配(是否取消匹配对话框)
function XDlcRoomAgency:DialogTipCancelMatch(callBack)
    local title = XUiHelper.GetText("TipTitle")
    local cancelMatchMsg = XUiHelper.GetText("OnlineInstanceCancelMatch")

    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XDlcRoom:CancelMatch(callBack)
    end)
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
        self:_OnCreateRoom(res.RoomData, true)
        self._Room:SetTutorialLevelId(levelId)
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
            self:_OnCreateRoom(res.RoomData, false)
        else
            self:Enter()
        end
    end

    self:ReqCreateRoom(worldId, levelId, bornPointId, isMultiplayer, true, replyFunc)
end

--- 进入关卡
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
---@param callback function
function XDlcRoomAgency:Quit(callback)
    self:ReqQuit(callback)
end

--- 退出房间(是否确认退出对话框)
function XDlcRoomAgency:DialogTipQuit(callback)
    local title = XUiHelper.GetText("TipTitle")
    local textKey = self:IsInRoomMatching() and "OnlineInstanceCancelMatchAndQuit" or "OnlineInstanceQuitRoom"
    local quitMsg = XUiHelper.GetText(textKey)

    XUiManager.DialogTip(title, quitMsg, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XDlcRoom:Quit(callback)
    end)
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
function XDlcRoomAgency:ReconnectToWorld()
    if not XMVCA.XSubPackage:CheckSubpackage() then
        XMVCA.XDlcRoom:CancelReconnectToWorld()
        return
    end
    if self:IsCanReconnect() then
        local worldInfo = self._Model:GetReJoinWorldData()

        self:_OnJoinWorld(worldInfo, true)
        self._Model:ClearReJoinWorldData()
        --- 暂停后续打脸弹窗
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_WINDOW_STOP)
    end
end

--- 重连回房间
function XDlcRoomAgency:ReconnectToRoom(callback)
    if self:IsCanReconnect() then
        self:ReqReconnectRoom(callback)
    end
end

function XDlcRoomAgency:ClearReconnectData()
    self._Model:ClearReJoinWorldData()
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
---@param nodeId string
---@param worldId number
---@param createTime number
function XDlcRoomAgency:ClickEnterRoomHref(roomId, nodeId, worldId, createTime)
    if not self:_CheckAgencyClickHrefCanEnter(roomId, nodeId, worldId, createTime) then
        return
    end

    self:ReqEnterTargetWorld(roomId, nodeId, false, worldId, true)
end

function XDlcRoomAgency:CancelReconnectToWorld(callback)
    if not self:IsCanReconnect() then
        return
    end

    local info = self:GetRejoinWorldInfo()
    local ipAddress = info:GetIpAddress()
    local port = info:GetPort()

    XFightNetwork.Connect(ipAddress, port, function(isSuccess)
        if isSuccess then
            self:ReqCancelJoinWorld(info:GetWorldNo(), XPlayer.Id, info:GetToken(), function()
                self:_OnDisconnectRejionWorld()
                if callback then
                    callback()
                end
            end)
        else
            self:_OnDisconnectRejionWorld()
        end
    end, false, Handler(self, self.ClearReconnectData))
end

-- endregion

-- region 网络请求

function XDlcRoomAgency:ReqMatch(worldId, needMatchCountCheck)
    if self:__CheckHasChangeProtocol("ReqMatch", worldId, needMatchCountCheck) then
        return
    end

    local req = {
        WorldInfoId = worldId,
        NeedMatchCountCheck = needMatchCountCheck ~= false,
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
        -- self:SetMatching(true)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_MATCH)
    end

    XNetwork.Call(RequestProto.DlcMatchRoomRequest, req, replyFunc)
end

function XDlcRoomAgency:ReqCancelMatch(callback)
    if self:__CheckHasChangeProtocol("ReqCancelMatch", callback) then
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
        if callback then
            callback()
        end
    end
    local exFunc = function(resCode)
        self:SetCancelingMatch(false)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(resCode.Code), XUiManager.DialogType.OnlySure)
    end

    XNetwork.Call(RequestProto.DlcCancelMatchRequest, {}, replyFunc, nil, exFunc)
end

function XDlcRoomAgency:ReqCreateRoom(worldId, levelId, bornPointId, isOnline, autoMatch, reply)
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    if self:__CheckHasChangeProtocol("ReqCreateRoom", worldId, levelId, bornPointId, isOnline, autoMatch, reply) then
        return
    end

    local req = {
        WorldInfoId = worldId,
        LevelId = levelId,
        BornPointId = bornPointId,
        IsOnline = isOnline,
        AutoMatch = autoMatch,
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

    XNetwork.Call(RequestProto.DlcSetAutoMatchRequest, {
        AutoMatch = autoMatch,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end

        self._Model:SetRoomAutoMatching(autoMatch)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_AUTO_MATCH_CHANGE, autoMatch)
    end)
end

function XDlcRoomAgency:ReqAddLike(playerId)
    if self:__CheckHasChangeProtocol("ReqAddLike", playerId) then
        return
    end

    XNetwork.Send(RequestProto.DlcAddLikeRequest, {
        PlayerId = playerId,
    })
end

function XDlcRoomAgency:ReqQuit(callback)
    if self:__CheckHasChangeProtocol("ReqQuit", callback) then
        return
    end

    local reply = function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        if XFightNetwork.IsConnected() then
            -- 退出房间时如果已经连接战斗服，则断开连接
            self:Settlement()
            XFightNetwork.Disconnect()
        end
        self._Room:ClearRoomChatMessage()
        self._Model:ClearAll()
        self._Model:ClearReJoinWorldData()
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_LEAVE_ROOM)

        if callback then
            callback()
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
        SelectType = selectType,
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
        EndSelectType = selectType,
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
    local req = {
        CharacterId = characterId,
    }
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

function XDlcRoomAgency:ReqReconnectRoom(callback)
    if self:__CheckHasChangeProtocol("ReqReconnectRoom", callback) then
        return
    end

    XNetwork.Call(RequestProto.DlcEnterTargetRoomRequest, {
        IsRejoin = true,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:_OnReconnectRoom(res.RoomData)

        if callback then
            callback()
        end
    end)
end

function XDlcRoomAgency:ReqEnterTargetWorld(roomId, nodeId, isRejoin, worldId, isInvite)
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    if self:__CheckHasChangeProtocol("ReqEnterTargetWorld", roomId, nodeId, isRejoin, worldId, isInvite) then
        return
    end

    XNetwork.Call(RequestProto.DlcEnterTargetRoomRequest, {
        RoomId = roomId,
        NodeId = nodeId,
        IsRejoin = isRejoin,
        WorldId = worldId,
        IsInvite = isInvite,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self:_OnCreateRoom(res.RoomData, false)
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
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_WORLD_CHANGE, worldId, levelId)
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

    if self:IsReconnect() then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS, XPlayer.Id, process)
    end
    XNetwork.Send(RequestProto.DlcUpdateLoadProcessRequest, {
        Process = process,
    })
end

function XDlcRoomAgency:ReqCancelJoinWorld(worldNo, playerId, token, callback)
    if self:__CheckHasChangeProtocol("ReqCancelJoinWorld", worldNo, playerId, token, callback) then
        return
    end

    XFightNetwork.Call(RequestProto.CancelJoinWorldRequest, {
        WorldNo = worldNo,
        PlayerId = playerId,
        Token = token,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        if callback then
            callback()
        end
    end)
end

-- endregion

-- region 内部方法

function XDlcRoomAgency:_OnJoinWorldResponse(response, ip, isRejion)
    XLog.Debug("OnJoinWorldResponse...")

    if response.Code ~= XCode.Success then
        XUiManager.TipCode(response.Code)
        self:Settlement()
        XFightNetwork.Disconnect()
        return
    end

    if not response.WorldData then
        self:Settlement()
        XLog.Error("OnJoinWorldResponse: WorldData is nil!")
        XFightNetwork.Disconnect()
        return
    end

    -- 连接战斗成功后开始心跳
    XFightNetwork.DoDlcHearbeat()

    -- if not response.Port or not response.Conv then
    --     XLog.Error("OnJoinWorldResponse: Port or Conv is nil!")
    --     -- 跳过kcp连接，直接进入战斗
    --     self:_OnEnterWorld(response.WorldData)
    --     return
    -- end

    -- local cb = function(success)
    --     XLog.Debug("OnJoinWorldResponse: Connect Kcp is " .. tostring(success))

    --     if not success then
    --         XLog.Error("OnJoinWorldResponse: Kcp Connect Failed! Use Tcp!")
    --     end

    --     if isRejion then
    --         self:_OnReconnectWorld(response.WorldData, response.ReconnectData)
    --     else
    --         self:_OnEnterWorld(response.WorldData)
    --     end
    -- end

    if isRejion then
        self:_CreateRoomProxy(response.WorldData.WorldId)
    end
    self._Model:SetIsReconnect(isRejion)
    self:_OnConnectWorld(response.WorldData, response.JoinWorldData)

    -- 连接kcp
    -- XFightNetwork.ConnectKcp(ip, response.Port, response.Conv, cb)
end

function XDlcRoomAgency:_OnConnectWorld(worldData, joinWorldData)
    local playerData = nil
    for i = 1, #worldData.Players do
        if worldData.Players[i].Id == XPlayer.Id then
            playerData = worldData.Players[i]
            break
        end
    end

    if not playerData then
        self:Settlement()
        return
    end
    self._Model:ClearFightBeginData()
    if not self._Model:IsReconnect() then
        self._Model:SetFightBeginRoomData(self._Model:GetRoomData())
    end
    self._Model:SetFightBeginWorldDataBySource(worldData)
    self:_ConnectFight(worldData, joinWorldData, XPlayer.Id)
end

function XDlcRoomAgency:_OnDisconnectRejionWorld()
    self:Settlement()
    XFightNetwork.Disconnect()
    self:ClearReconnectData()
    --- 重连打脸完毕
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end

function XDlcRoomAgency:_OnReconnectRoom(roomData)
    self:_CreateRoomProxy(roomData.WorldId)
    self:_SetRoomData(roomData)
end

function XDlcRoomAgency:_OnReadyEnterWorld()
    XLuaUiManager.SetMask(true, self._Model:GetReadyEnterWorldMaskKey())
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_READY_ENTER_WORLD)
    self._Room:OnReadyEnterWorld()
end

function XDlcRoomAgency:_OnCreateRoom(roomData, isTutorial)
    self:_CreateRoomProxy(roomData.WorldId)
    if self:IsInRoom() then
        XLog.Error("XDlcRoomAgency:OnCreateRoom错误, RoomData已经有数据")

        self:_SetRoomData(roomData)
        self._Model:SetRoomIsTutorial(isTutorial)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_REFRESH, self:GetRoomData())
    else
        self:_SetRoomData(roomData)
        self._Model:SetRoomIsTutorial(isTutorial)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_CANCEL_MATCH)
        self._Room:OnCreateRoom()
        self._Room:ClearRoomChatMessage()
        self._Room:OpenMultiplayerRoom()
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_ENTER_ROOM)
    end
end

function XDlcRoomAgency:_OnRebuildRoom(roomData)
    self:_CreateRoomProxy(roomData.WorldId)
    self:_SetRoomData(roomData)
    self._Model:SetRoomIsTutorial(false)
    self._Model:SetIsRebuildRoom(true)
    self._Room:OnRebuildRoom()
end

function XDlcRoomAgency:_SetRoomData(roomData)
    self:SetMatching(false)
    self._Model:SetRoomData(roomData)

    if self:IsInRoom() then
        self._Room:SetTeamByRoomData(self:GetRoomData())
        self._Room:SetFightCharacterId(self._Room:GetTeam():GetSelfMember():GetCharacterId())
    end
end

---@param response XDlcJoinWorldData
function XDlcRoomAgency:_OnJoinWorld(response, isRejoin)
    XLog.Debug("OnJoinWorld(IsRejoin = " .. tostring(isRejoin) .. ")...")

    local result = response:GetResult()
    if result and result > 0 then
        XLog.Debug("Fight is Finished!")
        self._Model:ClearReJoinWorldData()
        return
    end

    local token = response:GetToken()
    local worldNo = response:GetWorldNo()
    local ipAddress = response:GetIpAddress()
    local disconnectCb = function()
        if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
            self:RecordFightQuit(4)
            CS.StatusSyncFight.XFightClient.ExitFight(true)
        end
        if not self:IsSettled() then
            self._Model:ClearAll()
            self:Settlement()
            self:_OnDisconnect()
        end
    end
    local connectCb = function(isSuccess)
        XLog.Debug("OnJoinWorld: Join World is " .. tostring(isSuccess))
        if isSuccess then
            if isRejoin then
                CS.XFightNetwork.IsHandleReconnectionComplete = true
            end
            XFightNetwork.Call(RequestProto.JoinWorldRequest, {
                WorldNo = worldNo,
                PlayerId = XPlayer.Id,
                Token = token,
                IsRejoin = isRejoin,
            }, function(res)
                self:_OnJoinWorldResponse(res, ipAddress, isRejoin)
            end)
        else
            -- 网络错误
            disconnectCb()
        end
    end

    self._Model:SetIsSettled(false)
    self._Model:SetIsLoginOut(false)
    XFightNetwork.Connect(ipAddress, response:GetPort(), connectCb, isRejoin, disconnectCb)
end

function XDlcRoomAgency:_EnterFight(worldData, playerId, isExit)
    if isExit then
        CS.StatusSyncFight.XFightClient.RequestExitFight()
    end

    local fightArgs = CS.StatusSyncFight.XFightClientArgs()

    fightArgs.LoadProgressCb = Handler(self, self.ReqProcess)
    fightArgs.CloseLoadingUiCb = Handler(self, self._OnCloseFightLoading)
    fightArgs.LuaSettleUiCb = Handler(self, self._OnFightSettle)
    fightArgs.OpenLoadingUiCb = Handler(self, self._OnOpenFightLoading)

    if not self:IsTutorialRoom() then
        fightArgs.CheckLuaSettleCb = Handler(self, self._OnCheckFightSettle)
    end

    self._Model:SetIsFighting(true)
    self._Model:SetIsSettled(false)
    CS.StatusSyncFight.XFightClient.EnterFight(worldData, playerId, fightArgs)

    self:_OnFightLoading(worldData.WorldId)
end

function XDlcRoomAgency:_ConnectFight(worldData, connectData, playerId)
    local fightArgs = CS.StatusSyncFight.XFightClientArgs()

    fightArgs.LoadProgressCb = Handler(self, self.ReqProcess)
    fightArgs.CloseLoadingUiCb = Handler(self, self._OnCloseFightLoading)
    fightArgs.LuaSettleUiCb = Handler(self, self._OnFightSettle)
    fightArgs.OpenLoadingUiCb = Handler(self, self._OnOpenFightLoading)

    if not self:IsTutorialRoom() then
        fightArgs.CheckLuaSettleCb = Handler(self, self._OnCheckFightSettle)
    end

    self._Model:SetIsFighting(true)

    CS.StatusSyncFight.XFightClient.EnterFight(worldData, connectData.FightSerializeData,
        connectData.LevelSerializeData, playerId, fightArgs)

    self:_OnFightLoading(worldData.WorldId)
end

function XDlcRoomAgency:_OnFightLoading(worldId)
    XMVCA.XDlcWorld:OnEnterFight(worldId)
    self._Room:OnEnterWorld()
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

function XDlcRoomAgency:_OnCloseFightLoading()
    if self._Room then
        self._Room:CloseFightUiLoading()
    end
end

function XDlcRoomAgency:_OnOpenFightLoading()
    if self._Room then
        self._Room:OpenFightUiLoading()
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
    if CS.XInputManager.CurInputMapID ~= CS.XInputMapId.System then
        CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
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
    if not self._Model:IsLoginOut() then
        XLoginManager.DoDisconnect()
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
    local levelId = self._Room:GetTutorialLevelId()

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
    playerData.Name = XPlayer.Name
    worldNpcData.Id = npcId
    playerData.NpcList:Add(worldNpcData)
    worldData.WorldId = worldId
    worldData.LevelId = levelId
    worldData.Online = false
    worldData.IsTeaching = true
    worldData.WorldType = XMVCA.XDlcWorld:GetWorldTypeById(worldId)
    worldData.Players:Add(playerData)

    local luaWorldData = {
        WorldId = worldId,
        LevelId = levelId,
        Online = false,
        IsTeaching = true,
        WorldType = worldData.WorldType,
        Players = {
            [1] = {
                Master = true,
                Id = playerId,
                Name = XPlayer.Name,
                NpcList = {
                    [1] = {
                        Id = npcId,
                    },
                },
            },
        },
    }

    self._Model:ClearFightBeginData()
    self._Model:SetFightBeginRoomData(self._Model:GetRoomData())
    self._Model:SetFightBeginWorldDataBySource(luaWorldData)
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
    self._IsSelecting[selectType] = false
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

    queue:Enqueue({
        SelectType = selectType,
        Request = request,
    })
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

function XDlcRoomAgency:_CheckAgencyClickHrefCanEnter(roomId, nodeId, worldId, createTime)
    local agency = XMVCA.XDlcWorld:GetAgencyByWorldId(worldId)

    if agency then
        return agency:DlcCheckClickHrefCanEnter(roomId, nodeId, worldId, createTime)
    else
        return false
    end
end

function XDlcRoomAgency:_CheckBlockInvitationMessages()
    return XDataCenter.SetManager.InviteButton ~= 1
end

function XDlcRoomAgency:_OnReceivePrivateChat(chatData)
    if self:_CheckBlockInvitationMessages() then
        return
    end
    if chatData.MsgType ~= ChatMsgType.DlcRoomMsg then
        return
    end

    local contentData = XChatData.DecodeRoomMsg(chatData.Content)

    if not contentData then
        return
    end

    if chatData.SenderId == XPlayer.Id then
        return
    end

    self._Model:RecordingInviteChatData(chatData)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_RECEIVE_INVITE)
end

function XDlcRoomAgency:_OnUserLoginOut()
    self._Model:SetIsLoginOut(true)
end

-- endregion

-- region 特殊方法

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

-- endregion

-- region 协议

function XDlcRoomAgency:OnDlcKickOutNotify(response)
    --- 后续改造将DlcRoomManager彻底删除
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnDlcKickOutNotify(response)
        return
    end
    if response.Code ~= XCode.Success and response.Code ~= XCode.MatchPlayerOffline then
        XUiManager.TipCode(response.Code)
    end
    if response.Code == XCode.MatchStartTimeout then
        self._Room:OnRoomLeaderTimeOut()
    else
        self._Room:OnKickOut(response.Code)
    end

    self._Room:ClearRoomChatMessage()
    self._Model:ClearAll()
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_LEAVE_ROOM)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_KICKOUT)
end

function XDlcRoomAgency:OnDlcMatchNotify(response)
    local roomData = response.RoomData

    if roomData then
        local worldId = roomData.WorldId

        if XDataCenter.DlcRoomManager.IsInRoom() or XMVCA.XDlcWorld:GetWorldTypeById(worldId)
            == XEnumConst.DlcWorld.WorldType.Hunt then
            XDataCenter.DlcRoomManager.OnDlcMatchNotify(response)
            return
        end
    end
    if not self:IsMatching() then
        return
    end

    if response.Code == XCode.Success then
        local worldId = roomData.WorldId

        if XMVCA.XDlcWorld:GetMatchStrategyById(worldId) ~= XEnumConst.DlcWorld.MatchStrategy.Multiplayer then
            self:_OnCreateRoom(roomData, false)
        end
    else
        XUiManager.TipCode(response.Code)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ENTER_WORLD_FAIL)
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

    local worldId = response.WorldId
    local joinWorldData = self._Model:GetJoinWorldDataByResponse(response)

    if XMVCA.XDlcWorld:GetMatchStrategyById(worldId) == XEnumConst.DlcWorld.MatchStrategy.Multiplayer then
        self:_OnReadyEnterWorld()
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(false, self._Model:GetReadyEnterWorldMaskKey())
            self:_OnJoinWorld(joinWorldData, false)
        end, 1.5 * XScheduleManager.SECOND)
    else
        self:_OnJoinWorld(joinWorldData, false)
    end
end

function XDlcRoomAgency:OnDlcRoomInfoChangeNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.OnRoomInfoUpdate(response)
        return
    end
    local changeFlags = {
        IsWorldIdChange = self._Model:GetRoomWorldId() ~= response.WorldId,
        IsAutoMatchChange = self._Model:IsRoomAutoMatch() ~= response.AutoMatch,
        IsAbilityChange = self._Model:GetRoomAbilityLimit() ~= response.AbilityLimit,
    }
    local isSuccess = self._Model:UpdateRoomData(response)

    if isSuccess then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_INFO_CHANGE, self:GetRoomData(), changeFlags)
    end
end

function XDlcRoomAgency:OnDlcRoomStateNotify(response)
    if XDataCenter.DlcRoomManager.IsInRoom() then
        XDataCenter.DlcRoomManager.SetRoomState(response.State)
        return
    end

    local nowState = response.State
    local changeTime = XTime.GetServerNowTimestamp()
    local oldState = self._Model:GetRoomState()
    local isSuccess = self._Model:SetRoomState(nowState)

    if isSuccess then
        self:SetMatching(nowState == XEnumConst.DlcRoom.RoomState.Match)
        if oldState == XEnumConst.DlcRoom.RoomState.Normal and nowState == XEnumConst.DlcRoom.RoomState.Match then
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, changeTime)
        elseif oldState == XEnumConst.DlcRoom.RoomState.Match and nowState == XEnumConst.DlcRoom.RoomState.Normal then
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, changeTime)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_DLC_ROOM_STATE_CHANGE, nowState, changeTime)
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

function XDlcRoomAgency:OnDlcRebuildRoomAfterFight(response)
    if self._Model:IsReconnect() then
        self:_OnRebuildRoom(response.RoomData)
    else
        if self:IsInRoom() then
            self._Model:ClearRoomData()
            self._Model:SetIsRebuildRoom(false)
            self:_SetRoomData(response.RoomData)
        else
            self:_OnRebuildRoom(response.RoomData)
        end
    end
end

-- endregion

return XDlcRoomAgency
