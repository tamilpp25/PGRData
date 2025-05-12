local XUiPanelChatPools = require("XUi/XUiChatServe/XUiPanelChatPools")
local XUiPanelChatContent = XClass(XUiNode, "XUiPanelChatContent")

XUiPanelChatContent.WorldChatBoxType = {
    OtherChatBox = 1,
    OtherChatBoxEmoji = 2,
    SelfChatBox = 3,
    SelfChatBoxEmoji = 4
}

function XUiPanelChatContent:OnStart(rootUi)
    self.RootUi = rootUi
    self:InitAutoScript()
    self.DynamicListManager = XDynamicList.New(self.PanelChatView.transform, self)
    self.DynamicListManager:SetReverse(true)

    self.PanelChatPools = XUiPanelChatPools.New(self.PanelChatPools)
    self.PanelChatPools:InitData(self.DynamicListManager)

    self.UnreadMsgCount = 0
    
    self._ShowedChatItemList = {}
end

function XUiPanelChatContent:OnDisable()
    -- XDynamicList内部在显示前会回收所有gameobject, 外部无法在回收期间获得对应grid，需要先手动关闭XUiNode
    if not XTool.IsTableEmpty(self._ShowedChatItemList) then
        for i = #self._ShowedChatItemList, 1, -1 do
            self._ShowedChatItemList[i]:Close()
            table.remove(self._ShowedChatItemList, i)
        end
    end
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
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
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

    if (self.DynamicListManager:GetBarValue() > 0.1 and chatData.SenderId ~= XPlayer.Id) or (chatData.SenderId ~= XPlayer.Id and self.RootUi:IsBtnReportActive()) then
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
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatMyMsgItem').New
        elseif data.MsgType == ChatMsgType.Normal and data.SenderId ~= XPlayer.Id then
            poolName = "ohterMsg"
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatMyMsgItem').New
        elseif data.MsgType == ChatMsgType.Emoji and data.SenderId == XPlayer.Id then
            poolName = "myEmoji"
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatMyMsgEmoji').New
        elseif data.MsgType == ChatMsgType.Emoji and data.SenderId ~= XPlayer.Id then
            poolName = "otherEmoji"
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatMyMsgEmoji').New
        elseif data.MsgType == ChatMsgType.System then
            poolName = "system"
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatSystemItem').New
        elseif data.MsgType == ChatMsgType.SpringFestival and data.SenderId ~= XPlayer.Id then
            poolName = "otherHelp"
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatMyHelp').New
        elseif data.MsgType == ChatMsgType.SpringFestival and data.SenderId == XPlayer.Id then
            poolName = "myHelp"
            ctor = require('XUi/XUiChatServe/Item/XUiPanelWorldChatMyHelp').New
        end
        if cb and poolName and ctor then
            local item = cb(poolName, ctor, self)
            item.RootUi = self.RootUi
            item:Open()
            item:Refresh(data, handler(self, self.LongClickCb))
            -- 加入到列表以便控制其生命周期
            table.insert(self._ShowedChatItemList, item)
        else
            XLog.Error("------Init social worldChatData item is error!------")
        end
    end, handler(self, self.ScrollCallBack))
end

function XUiPanelChatContent:LongClickCb(msgItem)
    self.RootUi:LongClickMsgItem(msgItem)
end

function XUiPanelChatContent:ScrollCallBack()
    self.RootUi:SetBtnReportActive(false)
end

return XUiPanelChatContent