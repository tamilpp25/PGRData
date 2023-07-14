XUiPanelChatContent = XClass(nil, "XUiPanelChatContent")

XUiPanelChatContent.WorldChatBoxType = {
    OtherChatBox = 1,
    OtherChatBoxEmoji = 2,
    SelfChatBox = 3,
    SelfChatBoxEmoji = 4
}

function XUiPanelChatContent:Ctor(rootUi, ui, parent)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self:InitAutoScript()
    self.DynamicListManager = XDynamicList.New(self.PanelChatView.transform, self)
    self.DynamicListManager:SetReverse(true)

    self.PanelChatPools = XUiPanelChatPools.New(self.PanelChatPools)
    self.PanelChatPools:InitData(self.DynamicListManager)

    self.UnreadMsgCount = 0
end


-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelChatContent:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelChatContent:AutoInitUi()
    self.PanelChatView = self.Transform:Find("PanelChatView")
    self.PanelChatPools = self.Transform:Find("PanelChatView/PanelChatPools")
end

function XUiPanelChatContent:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelChatContent:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiPanelChatContent:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelChatContent:AutoAddListener()
    self.AutoCreateListeners = {}
end
-- auto
--初始化聊天纪录
function XUiPanelChatContent:RefreshChatList(channelType)
    self.ChannelType = channelType
    local msgData = XDataCenter.ChatManager.GetChatList(channelType)
    self:InitWorldChatDynamicList(msgData)
end

function XUiPanelChatContent:ReceiveChatHandler(chatData)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    --接收到消息
    if chatData == nil then
        return
    end
    if self.ChannelType ~= chatData.ChannelType then
        return
    end
    local tempTable = {}
    table.insert(tempTable, chatData)
    if self.DynamicListManager:GetBarValue() > 0.1 and chatData.SenderId ~= XPlayer.Id then
        self.UnreadMsgCount = self.UnreadMsgCount + 1
        self.DynamicListManager:InsertData(tempTable, DLInsertDataDir.Head, false)
    else
        self.UnreadMsgCount = 0
        local msgData = XDataCenter.ChatManager.GetChatList(self.ChannelType)
        self:InitWorldChatDynamicList(msgData)
    end
    XDataCenter.ChatManager.SetChatRead(self.ChannelType)
    XDataCenter.ChatManager.KeywordMatch(self.ChannelType, chatData)
    self.RootUi:ShowUnreadMsgCount(self.UnreadMsgCount)
end

function XUiPanelChatContent:InitWorldChatDynamicList(msgData)
    --初始化私聊动态列表数据
    msgData = msgData or {}
    self.DynamicListManager:SetData(msgData, function(data, cb)
        local poolName = nil
        local ctor = nil
        if data.MsgType == ChatMsgType.Normal and data.SenderId == XPlayer.Id then
            poolName = "myMsg"
            ctor = XUiPanelWorldChatMyMsgItem.New
        elseif data.MsgType == ChatMsgType.Normal and data.SenderId ~= XPlayer.Id then
            poolName = "ohterMsg"
            ctor = XUiPanelWorldChatMyMsgItem.New
        elseif data.MsgType == ChatMsgType.Emoji and data.SenderId == XPlayer.Id then
            poolName = "myEmoji"
            ctor = XUiPanelWorldChatMyMsgEmoji.New
        elseif data.MsgType == ChatMsgType.Emoji and data.SenderId ~= XPlayer.Id then
            poolName = "otherEmoji"
            ctor = XUiPanelWorldChatMyMsgEmoji.New
        elseif data.MsgType == ChatMsgType.System then
            poolName = "system"
            ctor = XUiPanelWorldChatSystemItem.New
        elseif data.MsgType == ChatMsgType.SpringFestival and data.SenderId ~= XPlayer.Id then
            poolName = "otherHelp"
            ctor = XUiPanelWorldChatMyHelp.New
        elseif data.MsgType == ChatMsgType.SpringFestival and data.SenderId == XPlayer.Id then
            poolName = "myHelp"
            ctor = XUiPanelWorldChatMyHelp.New
        end
        if cb and poolName and ctor then
            local item = cb(poolName, ctor)
            item.RootUi = self.RootUi
            item:Refresh(data)
        else
            XLog.Error("------Init social worldChatData item is error!------")
        end
    end)
end