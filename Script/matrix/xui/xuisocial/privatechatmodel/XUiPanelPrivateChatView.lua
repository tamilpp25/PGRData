local XUiPanelSocialMyMsgItem = require("XUi/XUiSocial/PrivateChatModel/NewItemModel/XUiPanelSocialMyMsgItem")
local XUiPanelSocialMyMsgEmojiItem = require("XUi/XUiSocial/PrivateChatModel/NewItemModel/XUiPanelSocialMyMsgEmojiItem")
local XUiPanelSocialPools = require("XUi/XUiSocial/PrivateChatModel/Pools/XUiPanelSocialPools")
local XUiPanelSocialMyMsgGiftItem = require("XUi/XUiSocial/PrivateChatModel/NewItemModel/XUiPanelSocialMyMsgGiftItem")
local XUiPanelSocialTipsItem = require("XUi/XUiSocial/PrivateChatModel/NewItemModel/XUiPanelSocialTipsItem")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelPrivateChatView = XClass(XUiNode, "XUiPanelPrivateChatView")
local XUiTogFriendBox = require("XUi/XUiSocial/PrivateChatModel/ItemModel/XUiTogFriendBox")

function XUiPanelPrivateChatView:OnStart(onBtnBackClick)
    self.OnBtnBackClick = onBtnBackClick
    self:InitAutoScript()
    self.ChatButtonGroups = {}
    self.FriendId = 0
    self:InitView()

    local XUiPanelEmojiEx = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiPanelEmojiEx")
    self.XUiPanelFriendEmoji = XUiPanelEmojiEx.New(self, self.PanelEmoji, self)
    local clickCallBack = function(content)
        self.XUiPanelFriendEmoji:Hide()
        self:OnClickEmoji(content)
    end
    self.XUiPanelFriendEmoji:SetClickCallBack(clickCallBack)
    self.XUiPanelFriendEmoji:Hide()

    local XUiPanelEmojiSetting = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiPanelEmojiPackSetting")
    self.UiPanelEmojiSetting = XUiPanelEmojiSetting.New(self, self.PanelEmojiSetup)
    self.UiPanelEmojiSetting:Hide()
    --self:Hide()
    self.XUiPanelSocialPools = XUiPanelSocialPools.New(self.PanelSocialPools)

    self.PrivateDynamicList = XDynamicList.New(self.PanelChatView.transform, self)
    self.PrivateDynamicList:SetReverse(true)

    self.PanelMsgListPools = XUiPanelSocialPools.New(self.PanelMsgListPools)
    self.PanelMsgListPools:InitData(self.PrivateDynamicList)

    self.GroupDynamicListManager = XDynamicTableNormal.New(self.ContactGroupList)
    self.GroupDynamicListManager:SetProxy(XUiTogFriendBox,self)
    self.GroupDynamicListManager:SetDelegate(self)
    self.GroupDynamicListManager:SetDynamicEventDelegate(function(...) self:OnGroupDynamicTableEvent(...) end)
end

function XUiPanelPrivateChatView:InitView()
    --初始化View
    self.PanelEmoji.gameObject:SetActive(false)
    self.PanelInputField.characterLimit = CS.XGame.ClientConfig:GetInt("PrivateChatTextLimit")
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelPrivateChatView:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelPrivateChatView:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelPrivateChatView:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelPrivateChatView:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelPrivateChatView:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnSendMsg, self.OnBtnSendMsgClick)

    self.BtnSendMsg.CallBack = function() self:OnBtnSendMsgClick() end
    self.BtnEmoji.CallBack = function() self:OnBtnEmojiPanelClick() end
    self.BtnLuomu.CallBack = function() self:OnBtnCoinPanelClick() end
    if self.BtnReport then
        self.BtnReport.CallBack = function() self:OnBtnReportClick() end
    end
end
-- auto
function XUiPanelPrivateChatView:OnBtnSendMsgClick()
    --发送聊天消息
    local text = self.PanelInputField.text
    if text == nil or text == "" then
        self.PanelInputField:ActivateInputField()
        return
    end

    self.PanelInputField.text = ""

    -- 替换空白控制符
    text = string.gsub(text, "%s", " ")

    local sendChat = {}
    sendChat.ChannelType = ChatChannelType.Private
    sendChat.MsgType = ChatMsgType.Normal
    sendChat.Content = text
    sendChat.TargetIds = { self.FriendId }
    XDataCenter.ChatManager.SendChat(sendChat, nil, true)
end

function XUiPanelPrivateChatView:OnBtnAddClick()
    if self.PanelEmoji.gameObject.activeInHierarchy then
        self.PanelEmoji.gameObject:SetActive(false)
    end
end

function XUiPanelPrivateChatView:OnBtnEmojiPanelClick()
    --打开表情面板
    self.XUiPanelFriendEmoji:OpenOrClosePanel()
end

function XUiPanelPrivateChatView:OnBtnCoinPanelClick()
    --发送螺母
    if XDataCenter.SocialManager.GetFriendInfo(self.FriendId) == nil then
        XUiManager.TipError(CS.XTextManager.GetText("ChatManagerNotSendCoinToNotFriend"))
        return
    end

    local sendChat = {}
    sendChat.ChannelType = ChatChannelType.Private
    sendChat.MsgType = ChatMsgType.Gift
    sendChat.Content = ""
    sendChat.TargetIds = { self.FriendId }

    XDataCenter.ChatManager.SendChat(sendChat)
end

function XUiPanelPrivateChatView:OnBtnPanelChooseBackClick()
    self.XUiPanelFriendEmoji:Hide()
end

function XUiPanelPrivateChatView:OnClickEmoji(content)
    --发送表情
    local sendChat = {}
    sendChat.ChannelType = ChatChannelType.Private
    sendChat.MsgType = ChatMsgType.Emoji
    sendChat.Content = content
    sendChat.TargetIds = { self.FriendId }
    XDataCenter.ChatManager.SendChat(sendChat)
end

-----------------------------------------------------------------------------------
function XUiPanelPrivateChatView:TryInitData()
    if self.GameObject.activeSelf == false then
        return
    end
    self:InitData()
end

function XUiPanelPrivateChatView:Refresh(friendId)
    --friend为选中的玩家ID
    self:Open()
    self.Parent:PlayAnimation("PrivateChatViewEnable")
    self.FriendId = friendId
    self:InitData()

    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, self.NewChatMsgHandler, self)
    XEventManager.AddEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBtnBackClick, self)
end

function XUiPanelPrivateChatView:InitData()
    XDataCenter.ChatManager.UpdateGiftStatus()

    self:UpdatePrivateDynamicList()

    self:UpdateGroupDynamicList()
end

function XUiPanelPrivateChatView:UpdatePrivateDynamicList()
    local msgData = XDataCenter.ChatManager.GetPrivateDynamicList(self.FriendId)
    --初始化私聊动态列表数据
    self.PrivateDynamicList:SetData(msgData, function(data, cb)
        local poolName = nil
        local ctor = nil
        if (data.MsgType == ChatMsgType.Normal or data.MsgType == ChatMsgType.RoomMsg or data.MsgType == ChatMsgType.DlcRoomMsg) and data.SenderId == XPlayer.Id then
            poolName = "myMsg"
            ctor = XUiPanelSocialMyMsgItem.New
        elseif (data.MsgType == ChatMsgType.Normal or data.MsgType == ChatMsgType.RoomMsg or data.MsgType == ChatMsgType.DlcRoomMsg) and data.SenderId ~= XPlayer.Id then
            poolName = "otherMsg"
            ctor = XUiPanelSocialMyMsgItem.New
        elseif data.MsgType == ChatMsgType.Emoji and data.SenderId == XPlayer.Id then
            poolName = "myEmoji"
            ctor = XUiPanelSocialMyMsgEmojiItem.New
        elseif data.MsgType == ChatMsgType.Emoji and data.SenderId ~= XPlayer.Id then
            poolName = "otherEmoji"
            ctor = XUiPanelSocialMyMsgEmojiItem.New
        elseif data.MsgType == ChatMsgType.Gift and data.SenderId == XPlayer.Id then
            poolName = "myGift"
            ctor = XUiPanelSocialMyMsgGiftItem.New
        elseif data.MsgType == ChatMsgType.Gift and data.SenderId ~= XPlayer.Id then
            poolName = "otherGift"
            ctor = XUiPanelSocialMyMsgGiftItem.New
        elseif data.MsgType == ChatMsgType.Tips then
            poolName = "tips"
            ctor = XUiPanelSocialTipsItem.New
        end
        if cb and poolName and ctor then
            local item = cb(poolName, ctor)
            item.RootUi = self.Parent
            item.Parent = self
            item:Refresh(data, handler(self, self.LongClickMsgItem))
        else
            XLog.Error("------Init social privateChatData item is error!------")
        end
    end, handler(self, self.ScrollCallBack))

    XDataCenter.ChatManager.SetPrivateChatReadByFriendId(self.FriendId)
end

function XUiPanelPrivateChatView:UpdateGroupDynamicList()
    self.FriendGroupData = XDataCenter.ChatManager.GetPrivateChatGroupData(self.FriendId)

    self.GroupDynamicListManager:SetDataSource(self.FriendGroupData)
    self.GroupDynamicListManager:ReloadDataASync()
end

function XUiPanelPrivateChatView:OnDynamicTableEvent()

end

function XUiPanelPrivateChatView:OnGroupDynamicTableEvent(event, index, grid)
    local friend = self.FriendGroupData[index]

    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(friend, friend.FriendId == self.FriendId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local lastIndex, lastFriend = self:GetGroupDataByFriendId(self.FriendId)
        local lastGrid = self.GroupDynamicListManager:GetGridByIndex(lastIndex)
        if lastGrid then
            lastGrid:Refresh(lastFriend, false)
        end

        self.FriendId = friend.FriendId
        self:UpdatePrivateDynamicList()
        grid:Refresh(friend, true)
    end
end

function XUiPanelPrivateChatView:GetGroupDataByFriendId(friendId)
    for k, friend in pairs(self.FriendGroupData) do
        if friendId == friend.FriendId then
            return k, friend
        end
    end
end

function XUiPanelPrivateChatView:Hide()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, self.NewChatMsgHandler, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.BlackDataChange, self)
    self.XUiPanelFriendEmoji:OnDisable()
    self.UiPanelEmojiSetting:OnDisable()
    if not XTool.UObjIsNil(self.GameObject) and self.GameObject.activeSelf then
        self:Close()
    end
    self:SetBtnReportActive(false)
end

--当有新的私聊进来的时候调用
function XUiPanelPrivateChatView:NewChatMsgHandler(chatData)
    if chatData == nil then
        return
    end

    if (chatData.ChannelType ~= ChatChannelType.Private and chatData.ChaneelType ~= ChatChannelType.PrivateInvite) then
        return
    end

    self:UpdateGroupDynamicList()

    if self.FriendId ~= chatData.TargetId and self.FriendId ~= chatData.SenderId then
        return
    end

    self:UpdatePrivateDynamicList()
end

function XUiPanelPrivateChatView:OnDisable()
    self.XUiPanelFriendEmoji:OnDestroy()
    self.UiPanelEmojiSetting:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, self.NewChatMsgHandler, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BLACK_DATA_CHANGE, self.OnBtnBackClick, self)
end

function XUiPanelPrivateChatView:BlackDataChange()
    self:UpdateGroupDynamicList()
    self:UpdatePrivateDynamicList()
end

-------------------举报聊天的按钮相关 begin---------------
function XUiPanelPrivateChatView:OnBtnReportClick()
    self:SetBtnReportActive(false)
    local playerId = self.MsgItem and self.MsgItem:GetPlayerId()
    if not playerId then
        return
    end

    if XDataCenter.RoomManager.RoomData and playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end

    local chatContent = self.MsgItem:GetChatContent()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId, nil, nil, nil, function(data)
        local dataTemp = {Id = data.Id, TitleName = data.Name, PlayerLevel = data.Level, PlayerIntroduction = data.Sign}
        XLuaUiManager.Open("UiReport", dataTemp, chatContent, nil, XReportConfigs.EnterType.Chat, nil, self.SelType)
    end)
end

--长按聊天内容回调，XUiPanelSocialMyMsgItem调用
function XUiPanelPrivateChatView:LongClickMsgItem(msgItem)
    self.MsgItem = msgItem
    local offsetY = 2
    local content = msgItem:GetContent()
    if XTool.UObjIsNil(content) then
        XLog.Error("检查当前长按的msgItem上是否有Content的引用")
        return
    end

    local contentPosition = content.transform.localPosition
    local height = content.rect.height
    local width = content.rect.width
    local localPositionX = contentPosition.x + width * 0.9
    local localPositionY = contentPosition.y - height - offsetY
    self.BtnReport.transform.position = content.transform:TransformPoint(CS.UnityEngine.Vector3(localPositionX, localPositionY, 0))
    self:SetBtnReportActive(true)
end

function XUiPanelPrivateChatView:SetBtnReportActive(isActive)
    if self.BtnReport then
        self.BtnReport.gameObject:SetActiveEx(isActive)
    end
end

function XUiPanelPrivateChatView:IsBtnReportActive()
    return self.BtnReport.gameObject.activeSelf
end

function XUiPanelPrivateChatView:ScrollCallBack()
    self:SetBtnReportActive(false)
end

function XUiPanelPrivateChatView:OpenPanelEmojiSetup()
    self.UiPanelEmojiSetting:Show()
end

function XUiPanelPrivateChatView:OpenPanelEmoji()
    self.XUiPanelFriendEmoji:Show()
end
-------------------举报聊天的按钮相关 end---------------

return XUiPanelPrivateChatView