local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridInviteFriendItem = require("XUi/XUiMultiplayerInviteFriend/XUiGridInviteFriendItem")

local XUiDlcHuntPlayerInviteFriend = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPlayerInviteFriend")

function XUiDlcHuntPlayerInviteFriend:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self.GridInviteFriendItem.gameObject:SetActive(false)
end

function XUiDlcHuntPlayerInviteFriend:OnStart()
    self.Invited = {}
    self.ItemsPool = {}
    self.MultipleRoomType = MultipleRoomType.DlcHunt
    self.DynamicListManager = XDynamicTableNormal.New(self.PanelContactView)
    self.DynamicListManager:SetProxy(XUiGridInviteFriendItem)
    self.DynamicListManager:SetDelegate(self)
    XDataCenter.SocialManager.GetFriendsInfo(handler(self, self.Refresh))
end

function XUiDlcHuntPlayerInviteFriend:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.FriendList[index]
        grid:Refresh(data, self.Invited[data.FriendId])
    end
end

function XUiDlcHuntPlayerInviteFriend:Refresh()
    self.FriendList = {}
    self.FriendList = XDataCenter.SocialManager.GetFriendList()
    self.PanelTips.gameObject:SetActive(#self.FriendList == 0)
    self.DynamicListManager:SetDataSource(self.FriendList)
    self.DynamicListManager:ReloadDataASync()
end

function XUiDlcHuntPlayerInviteFriend:OnClickInvite(data)
    local roomType = self.MultipleRoomType
    local content

    local room = XDataCenter.DlcRoomManager.GetRoom()
    local roomId = room:GetId()
    local worldId = room:GetWorld():GetWorldId()
    -- nonsense
    local stateLevel = 0

    content = XChatData.EncodeRoomMsg(
            RoomMsgContentId.FrinedInvite,
            XPlayer.Id,
            worldId,
            roomId,
            roomType,
            stateLevel)

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

function XUiDlcHuntPlayerInviteFriend:OnBtnBackClick()
    self:Close()
end

function XUiDlcHuntPlayerInviteFriend:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiDlcHuntPlayerInviteFriend