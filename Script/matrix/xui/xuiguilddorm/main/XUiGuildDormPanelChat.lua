--==============
--公会宿舍主界面聊天界面
--==============
local XUiGuildDormPanelChat = XClass(XSignalData, "XUiGuildDormPanelChat")
local MAX_CHAT_WIDTH = 470
local CHAT_SUB_LENGTH = 18

function XUiGuildDormPanelChat:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    self.BtnChat.CallBack = function() self:OnBtnChatClick() end
    self:InitEventListener()
end

function XUiGuildDormPanelChat:InitEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_OPEN, self.SetHide, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_CLOSE, self.SetShow, self)
end

function XUiGuildDormPanelChat:OnEnable()
    self:Refresh(nil, true)
end

function XUiGuildDormPanelChat:Refresh(chatData, onEnable)
    local chatList = XDataCenter.ChatManager.GetGuildChatList()
    if not chatList then return end
    local lastChat = chatList[1]
    if not lastChat then return end
    if not string.IsNilOrEmpty(lastChat.CustomContent) then
        self.TxtMessageContent.supportRichText = true
    else
        self.TxtMessageContent.supportRichText = false
    end

    local nameRemark = XDataCenter.SocialManager.GetPlayerRemark(lastChat.SenderId, lastChat.NickName)
    local content = lastChat.Content
    if lastChat.MsgType == ChatMsgType.System then
        content = string.format("%s：%s", CS.XTextManager.GetText("GuildChannelTypeAll"), lastChat.Content)
        self.TxtMessageContent.text = content
    else
        content = lastChat.Content
        if lastChat.MsgType == ChatMsgType.Emoji then
            content = CS.XTextManager.GetText("GuildEmojiReplace")
        end
        self.TxtMessageContent.text = string.format("%s：%s", nameRemark, content)
    end

    if XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH then
        self.TxtMessageContent.text = string.Utf8Sub(self.TxtMessageContent.text, 1, CHAT_SUB_LENGTH) .. [[...]]
    end
    if not onEnable then
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_TALK, lastChat.SenderId, lastChat.Content, lastChat.MsgType == ChatMsgType.Emoji)
    end
end

function XUiGuildDormPanelChat:OnBtnChatClick()
    RunAsyn(function ()
        self:EmitSignal("SetRoleIsCanMove", false)
        XLuaUiManager.Open("UiChatServeMain", false, ChatChannelType.Guild, ChatChannelType.World)
        local signalCode = XLuaUiManager.AwaitSignal("UiChatServeMain", "_", self)
        if signalCode ~= XSignalCode.RELEASE then return end
        self:EmitSignal("SetRoleIsCanMove", true)
    end)
    
end

function XUiGuildDormPanelChat:SetShow()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildDormPanelChat:SetHide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormPanelChat:Dispose()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_OPEN, self.SetHide, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_CLOSE, self.SetShow, self)
end

return XUiGuildDormPanelChat