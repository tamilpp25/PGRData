local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
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
    if self.MultipleRoomType == MultipleRoomType.MultiDimOnline then
        self.TxtTitle.text = CS.XTextManager.GetText("MultiDimOnlineInviteTitle")
        local guildId = XDataCenter.GuildManager.GetGuildId()
        XDataCenter.GuildManager.GetGuildMembers(guildId,function() self:Refresh() end)
        local textTip = self.PanelTips:FindTransform("Text"):GetComponent("Text")
        textTip.text = CS.XTextManager.GetText("MultiDimOnlineInviteNoFriend")
    else
        XDataCenter.SocialManager.GetFriendsInfo(handler(self, self.Refresh))
    end
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
    self.FriendList = {}
    if self.MultipleRoomType == MultipleRoomType.MultiDimOnline then
        local memberDic = XDataCenter.GuildManager.GetMemberList()
        for _, member in pairs(memberDic) do
            if member.Id ~= XPlayer.Id then
                member.FriendId = member.Id
                member.IsOnline = member.OnlineFlag == 1
                member.Icon = member.HeadPortraitId
                table.insert(self.FriendList, member)
            end
        end
        table.sort(self.FriendList, function(a, b)
            if a.OnlineFlag == b.OnlineFlag then
                return false
            end

            return a.OnlineFlag > b.OnlineFlag
        end)
    elseif self.MultipleRoomType==MultipleRoomType.FubenPhoto then
        local friends =  XDataCenter.SocialManager.GetFriendList()
        local levelLimit=XDataCenter.FubenSpecialTrainManager.GetOpenLevelLimit()
        for _, member in pairs(friends) do
            if member.Level >= levelLimit then
                member.OnlineFlag=member.IsOnline and 1 or 0
                table.insert(self.FriendList, member)
            end
        end
        table.sort(self.FriendList, function(a, b)
            if a.OnlineFlag == b.OnlineFlag then
                return false
            end
            
            return a.OnlineFlag > b.OnlineFlag
        end)
    elseif self.MultipleRoomType == MultipleRoomType.DlcWorld then
        local friends = XDataCenter.SocialManager.GetFriendList()
        local levelLimit = XMVCA.XDlcCasual:GetOpenLevelLimit()

        for _, friend in pairs(friends) do
            if friend.Level >= levelLimit then
                friend.OnlineFlag = friend.IsOnline and 1 or 0
                table.insert(self.FriendList, friend) 
            end
        end
        table.sort(self.FriendList, function(a, b)
            if a.OnlineFlag == b.OnlineFlag then
                return false
            end
            
            return a.OnlineFlag > b.OnlineFlag
        end)
    else
        self.FriendList = XDataCenter.SocialManager.GetFriendList()
    end
    self.PanelTips.gameObject:SetActive(#self.FriendList == 0)
    self.DynamicListManager:SetDataSource(self.FriendList)
    self.DynamicListManager:ReloadDataASync()
end

function XUiMultiplayerInviteFriend:OnClickInvite(data)
    local content
    local roomtType = self.MultipleRoomType
    --if self.MultipleRoomType == MultipleRoomType.UnionKill then
    --    local unionRoomData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    --    if not unionRoomData then
    --        return
    --    end
    --    content = XChatData.EncodeRoomMsg(
    --            RoomMsgContentId.FrinedInvite,
    --            XPlayer.Id,
    --            0,
    --            unionRoomData.Id,
    --            roomtType)
    if self.MultipleRoomType == MultipleRoomType.DlcWorld then
        if not XMVCA.XDlcRoom:IsInRoom() then
            return
        end

        local roomData = XMVCA.XDlcRoom:GetRoomData()

        if not roomData then
            return
        end

        local contentId = RoomMsgContentId.FrinedInvite
        local worldId = roomData:GetWorldId()
        local roomId = roomData:GetId()
        local nodeId = roomData:GetNodeId()
        local roomType = self.MultipleRoomType
        local stateLevel = 0

        content = XChatData.EncodeRoomMsg(contentId, XPlayer.Id, worldId, roomId, roomType, stateLevel, nodeId)
    else
        local roomId = XDataCenter.RoomManager.RoomData.Id
        local stageId = XDataCenter.RoomManager.RoomData.StageId
        local stateLevel = XDataCenter.RoomManager.RoomData.StageLevel
        if self.MultipleRoomType == MultipleRoomType.ArenaOnline then
            roomId = XDataCenter.RoomManager.RoomData.RoomId
            stageId = XDataCenter.RoomManager.RoomData.ChallengeId
            stateLevel = XDataCenter.RoomManager.RoomData.ChallengeLevel
        elseif self.MultipleRoomType == MultipleRoomType.MultiDimOnline then
            roomtType = MultipleRoomType.Normal
        end

        content = XChatData.EncodeRoomMsg(
                RoomMsgContentId.FrinedInvite,
                XPlayer.Id,
                stageId,
                roomId,
                roomtType,
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