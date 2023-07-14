local XUiMultiplayerInviteFriend = XLuaUiManager.Register(XLuaUi, "UiMultiplayerInviteFriend")
local XUiGridInviteFriendItem = require("XUi/XUiMultiplayerInviteFriend/XUiGridInviteFriendItem")

function XUiMultiplayerInviteFriend:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.GridInviteFriendItem.gameObject:SetActive(false)
end

function XUiMultiplayerInviteFriend:OnStart(...)
    local args = {...}
    self.Invited = {}
    self.ItemsPool = {}
    self.MultipleRoomType = args[1] or MultipleRoomType.Normal
    self.DynamicListManager = XDynamicTableNormal.New(self.PanelContactView)
    self.DynamicListManager:SetProxy(XUiGridInviteFriendItem)
    self.DynamicListManager:SetDelegate(self)
    XDataCenter.SocialManager.GetFriendsInfo(handler(self, self.Refresh))
end

function XUiMultiplayerInviteFriend:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.FriendList[index]
        grid:Refresh(data, self.Invited[data.FriendId])
    end
end

function XUiMultiplayerInviteFriend:Refresh()
    self.FriendList = XDataCenter.SocialManager.GetFriendList()
    self.PanelTips.gameObject:SetActive(#self.FriendList == 0)
    self.DynamicListManager:SetDataSource(self.FriendList)
    self.DynamicListManager:ReloadDataASync()
end

function XUiMultiplayerInviteFriend:OnClickInvite(data)
    local content
    if self.MultipleRoomType == MultipleRoomType.UnionKill then
        local unionRoomData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
        if not unionRoomData then return end
        content = XChatData.EncodeRoomMsg(
            RoomMsgContentId.FrinedInvite,
            XPlayer.Id,
            0,
            unionRoomData.Id,
            self.MultipleRoomType)
    else
        local roomId = XDataCenter.RoomManager.RoomData.Id
        local stageId = XDataCenter.RoomManager.RoomData.StageId
        local stateLevel = XDataCenter.RoomManager.RoomData.StageLevel
        if self.MultipleRoomType == MultipleRoomType.ArenaOnline then
            roomId = XDataCenter.RoomManager.RoomData.RoomId
            stageId = XDataCenter.RoomManager.RoomData.ChallengeId
            stateLevel = XDataCenter.RoomManager.RoomData.ChallengeLevel
        end
        content = XChatData.EncodeRoomMsg(
            RoomMsgContentId.FrinedInvite,
            XPlayer.Id,
            stageId,
            roomId,
            self.MultipleRoomType,
            stateLevel)
    end

    local sendChat = {}
    sendChat.ChannelType = ChatChannelType.Private
    sendChat.MsgType = ChatMsgType.RoomMsg
    sendChat.Content = content
    sendChat.TargetIds = { data.FriendId }
    self.Invited[data.FriendId] = true
    XDataCenter.ChatManager.SendChat(sendChat, function()
        XUiManager.TipText("OnlineSendWorldSuccess")
    end, true)
end

function XUiMultiplayerInviteFriend:OnBtnBackClick()
    self:Close()
end

function XUiMultiplayerInviteFriend:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end