local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcMultiPlayerInviteGrid = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerInviteGrid")

---@class XUiDlcMultiPlayerInvite : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field GridFriend UnityEngine.RectTransform
---@field PanelFriendList UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerInvite = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerInvite")

-- region 生命周期
function XUiDlcMultiPlayerInvite:OnAwake()
    self._FriendList = nil
    self._InvitedTimer = nil
    self._DynamicTable = XDynamicTableNormal.New(self.PanelFriendList)
    self._DynamicTable:SetProxy(XUiDlcMultiPlayerInviteGrid, self)
    self._DynamicTable:SetDelegate(self)

    self:_RegisterButtonClicks()
end

function XUiDlcMultiPlayerInvite:OnStart(friendList)
    local endTime = self._Control:GetActivityEndTime()

    self._FriendList = friendList
    self:SetAutoCloseInfo(endTime, Handler(self._Control, self._Control.AutoCloseHandler))
    self.GridFriend.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerInvite:OnEnable()
    self:_Refresh()
    self:_RegisterSchedules()
    self:_RegisterListeners()
end

function XUiDlcMultiPlayerInvite:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

-- endregion

function XUiDlcMultiPlayerInvite:OnRefresh()
    self:_Refresh()
end

function XUiDlcMultiPlayerInvite:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayOffFrameAnimation()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        self._Control:SetGridTransparent(grid, false)
    end
end

function XUiDlcMultiPlayerInvite:OnInviteClick(friendId)
    XDataCenter.ChatManager.SendChat(self:_GetSendChat(friendId), function()
        XUiManager.TipText("OnlineSendWorldSuccess")
    end, true)
end

-- region 私有方法

function XUiDlcMultiPlayerInvite:_Refresh()
    if XTool.IsTableEmpty(self._FriendList) then
        self.PanelNone.gameObject:SetActiveEx(true)
    else
        self._DynamicTable:SetDataSource(self._FriendList)
        self._DynamicTable:ReloadDataASync(1)
    end
end

function XUiDlcMultiPlayerInvite:_RefreshInvitedTime()
    local gridList = self._DynamicTable:GetGrids()

    if not XTool.IsTableEmpty(gridList) then
        for _, grid in pairs(gridList) do
            ---@type XDlcMultiplayerFriend
            local data = grid:GetData()

            if data then
                local invitedTime = data:GetInvitedTime()
                local nowTime = XTime.GetServerNowTimestamp()
                local invitedCd = self._Control:GetInvitedTime()

                if invitedTime and nowTime - invitedTime <= invitedCd then
                    grid:SetInvitedTime(invitedCd - nowTime + invitedTime)
                end
            end
        end
    end
end

function XUiDlcMultiPlayerInvite:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClose, self.Close, true)
end

function XUiDlcMultiPlayerInvite:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RegisterInviteTimer()
end

function XUiDlcMultiPlayerInvite:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveInviteTimer()
end

function XUiDlcMultiPlayerInvite:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, self.OnRefresh, self)
end

function XUiDlcMultiPlayerInvite:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, self.OnRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, self.OnRefresh, self)

end

function XUiDlcMultiPlayerInvite:_RegisterInviteTimer()
    self:_RemoveInviteTimer()
    self._InvitedTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshInvitedTime), 1)
end

function XUiDlcMultiPlayerInvite:_RemoveInviteTimer()
    if self._InvitedTimer then
        XScheduleManager.UnSchedule(self._InvitedTimer)
        self._InvitedTimer = nil
    end
end

function XUiDlcMultiPlayerInvite:_GetSendChat(friendId)
    local content = self:_GetInviteContent()

    if not content then
        return
    end

    return {
        ChannelType = ChatChannelType.Private,
        MsgType = ChatMsgType.DlcRoomMsg,
        Content = content,
        TargetIds = {
            friendId,
        },
    }
end

function XUiDlcMultiPlayerInvite:_GetInviteContent()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return nil
    end

    local roomData = XMVCA.XDlcRoom:GetRoomData()

    if not roomData then
        return nil
    end

    local contentId = RoomMsgContentId.FrinedInvite
    local worldId = roomData:GetWorldId()
    local levelId = roomData:GetLevelId()
    local roomId = roomData:GetId()
    local nodeId = roomData:GetNodeId()
    local roomType = MultipleRoomType.DlcWorld

    return XChatData.EncodeRoomMsg(contentId, XPlayer.Id, worldId, roomId, roomType, 0, nodeId, levelId)
end

function XUiDlcMultiPlayerInvite:_PlayOffFrameAnimation()
    self._Control:PlayOffFrameAnimation(self._DynamicTable:GetGrids(), "GridFriendAnimEnable", nil, 0.05, 0.2)
end

-- endregion

return XUiDlcMultiPlayerInvite
