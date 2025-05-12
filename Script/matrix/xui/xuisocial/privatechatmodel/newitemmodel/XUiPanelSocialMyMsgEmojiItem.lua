local XUiPanelSocialMyMsgEmojiItem = XClass(nil, "XUiPanelSocialMyMsgEmojiItem")

function XUiPanelSocialMyMsgEmojiItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelSocialMyMsgEmojiItem:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelSocialMyMsgEmojiItem:AutoInitUi()
    -- self.PanelRole = self.Transform:Find("PanelRole")
    -- self.RImgIcon = self.Transform:Find("PanelRole/RImgIcon"):GetComponent("RawImage")
    -- self.HeadIconEffect = self.Transform:Find("PanelRole/RImgIcon/Effect"):GetComponent("XUiEffectLayer")
    -- self.BtnView = self.Transform:Find("PanelRole/BtnView"):GetComponent("Button")
    -- self.PanelMsg = self.Transform:Find("PanelMsg")
    -- self.TxtName = self.Transform:Find("PanelMsg/TxtName"):GetComponent("Text")
    -- self.RImgEmoji = self.Transform:Find("PanelMsg/Content/RImgEmoji"):GetComponent("RawImage")
end

function XUiPanelSocialMyMsgEmojiItem:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelSocialMyMsgEmojiItem:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelSocialMyMsgEmojiItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelSocialMyMsgEmojiItem:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnView, self.OnBtnViewClick)
end
-- auto
function XUiPanelSocialMyMsgEmojiItem:OnBtnViewClick()
    if XDataCenter.RoomManager.RoomData and self.PlayerId == XPlayer.Id then
        --在房间中不能在聊天打开自己详情面板
        return
    end
    if self.PlayerId then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
    end
end

function XUiPanelSocialMyMsgEmojiItem:Refresh(chatData)
    local icon = XDataCenter.ChatManager.GetEmojiIcon(chatData.Content)
    if icon ~= nil then
        self.RImgEmoji:SetRawImage(icon)
    end
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    XUiPlayerHead.InitPortrait(chatData.Icon, chatData.HeadFrameId, self.Head)
    self.PlayerId = chatData.SenderId
end

function XUiPanelSocialMyMsgEmojiItem:SetShow()

end

return XUiPanelSocialMyMsgEmojiItem