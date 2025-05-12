local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiPanelSocialMyMsgItem = XClass(nil, "XUiPanelSocialMyMsgItem")

function XUiPanelSocialMyMsgItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelSocialMyMsgItem:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelSocialMyMsgItem:AutoInitUi()

end

function XUiPanelSocialMyMsgItem:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelSocialMyMsgItem:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelSocialMyMsgItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelSocialMyMsgItem:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnView, self.OnBtnViewClick)
    self:RegisterListener(self.TxtWord, "onHrefClick", self.OnBtnHrefClick)

    if self.BtnClickPointer then
        XUiButtonLongClick.New(self.BtnClickPointer, XScheduleManager.SECOND, self, nil, self.OnBtnLongClick, nil, true)
    end
end

function XUiPanelSocialMyMsgItem:OnBtnLongClick()
    if self.LongClickCallBack then
        self.LongClickCallBack(self)
    end
end
-- auto
function XUiPanelSocialMyMsgItem:OnBtnViewClick()
    if XDataCenter.RoomManager.RoomData and self.playerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.playerId, nil, nil, self.ChatContent)
end

function XUiPanelSocialMyMsgItem:OnBtnHrefClick(param)
    XDataCenter.RoomManager.ClickEnterRoomHref(param, self.CreateTime)
end

function XUiPanelSocialMyMsgItem:Refresh(chatData, longClickCb)
    if chatData == nil then
        return
    end
    self.LongClickCallBack = longClickCb
    self.playerId = chatData.SenderId
    self.ChatContent = chatData.Content

    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    XUiPlayerHead.InitPortrait(chatData.Icon, chatData.HeadFrameId, self.Head)
    
    self.CreateTime = chatData.CreateTime
    self:SetText(chatData)
    self:SetShow(true)
end

function XUiPanelSocialMyMsgItem:SetText(chatData)
    if chatData.MsgType == ChatMsgType.RoomMsg or chatData.MsgType == ChatMsgType.DlcRoomMsg then
        self:SetRoomMsgText(chatData)
    else
        self:SetNormalMsgText(chatData)
    end

end

function XUiPanelSocialMyMsgItem:SetRoomMsgText(chatData)
    self.TxtWord.supportRichText = true

    self.TxtWord.text = chatData:GetRoomMsgContent()
end

function XUiPanelSocialMyMsgItem:SetNormalMsgText(chatData)
    if not string.IsNilOrEmpty(chatData.CustomContent) then
        self.TxtWord.supportRichText = true
    else
        self.TxtWord.supportRichText = false
    end

    self.TxtWord.text = chatData.Content
end

function XUiPanelSocialMyMsgItem:SetShow(code)
    self.GameObject.gameObject:SetActive(code)
end

function XUiPanelSocialMyMsgItem:GetPlayerId()
    return self.playerId
end

function XUiPanelSocialMyMsgItem:GetContent()
    return self.Content
end

function XUiPanelSocialMyMsgItem:GetChatContent()
    return self.ChatContent
end

return XUiPanelSocialMyMsgItem