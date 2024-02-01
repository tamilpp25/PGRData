local XUiTogFriendBox = XClass(XUiNode, "XUiTogFriendBox")


function XUiTogFriendBox:OnStart()
    self.RootUi=self.Parent.Parent
    self.ImgNewTag.gameObject:SetActive(false)
    self.RedPointId = self:AddRedPointEvent(self.ImgNewTag, self.OnCheckUnReadMsgCount, self, { XRedPointConditions.Types.CONDITION_FRIEND_CHAT_PRIVATE }, nil, false)
end

function XUiTogFriendBox:OnCheckUnReadMsgCount(count, args)
    if args == self.FriendId then
        self.ImgNewTag.gameObject:SetActive(count >= 0)
        self.TxtUnMsgCount.text = tostring(count)
    end
end

function XUiTogFriendBox:SetSelect(isSelect)
    if isSelect then
        self.BtnBackground:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnBackground:SetButtonState(CS.UiButtonState.Normal)
    end

    self.isSelect = isSelect
end

function XUiTogFriendBox:UpdateLastChatText()
    local chatDataList = XDataCenter.ChatManager.GetPrivateDynamicList(self.FriendId)
    if not chatDataList or #chatDataList <= 0 then
        self.BtnBackground:SetTxtByObjName("TxtNewChat", "")
        return
    end

    local chatData = chatDataList[1]
    if chatData.MsgType == ChatMsgType.Emoji then
        self.BtnBackground:SetTxtByObjName("TxtNewChat", CS.XTextManager.GetText("EmojiText"))
    elseif chatData.MsgType == ChatMsgType.Tips then
        self.BtnBackground:SetTxtByObjName("TxtNewChat", XDataCenter.ChatManager.CreateGiftTips(chatData))
    elseif chatData.MsgType == ChatMsgType.Gift then
        self.BtnBackground:SetTxtByObjName("TxtNewChat", XDataCenter.ChatManager.CreateGiftTips(chatData))
    elseif chatData.MsgType == ChatMsgType.RoomMsg then
        self.BtnBackground:SetTxtByObjName("TxtNewChat", chatData:GetRoomMsgContent())
    else
        self.BtnBackground:SetTxtByObjName("TxtNewChat", chatData.Content)
    end
end

function XUiTogFriendBox:Refresh(friendData, isSelect)
    if friendData == nil then
        return
    end

    self.FriendId = friendData.FriendId
    self:SetSelect(isSelect)
    self:UpdateLastChatText()
    XUiPLayerHead.InitPortrait(friendData.Icon, friendData.HeadFrameId, self.Head)
    self.BtnBackground:SetTxtByObjName("TxtFriendName", XDataCenter.SocialManager.GetPlayerRemark(self.FriendId, friendData.NickName))
    XRedPointManager.Check(self.RedPointId, self.FriendId)
end


return XUiTogFriendBox