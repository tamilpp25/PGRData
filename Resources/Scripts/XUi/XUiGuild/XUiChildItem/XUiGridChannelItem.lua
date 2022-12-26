local XUiGridChannelItem = XClass(nil, "XUiGridChannelItem")

function XUiGridChannelItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.OriginSize = self.Transform.sizeDelta

    XTool.InitUiObject(self)
end

function XUiGridChannelItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridChannelItem:SetNewsInfo(chat)
    local nameRemark = XDataCenter.SocialManager.GetPlayerRemark(chat.SenderId, chat.NickName)
    if chat.MsgType == ChatMsgType.System then
        self.TxtInfo.text = string.format("<color=#00A0FFE6>%s：</color>%s", CS.XTextManager.GetText("GuildChannelTypeAll"), chat.Content)
    else
        local content = chat.Content
        if chat.MsgType == ChatMsgType.Emoji then
            content = CS.XTextManager.GetText("GuildEmojiReplace")
        end
        self.TxtInfo.text = string.format("<color=#000000FF>【%s】：</color>%s", nameRemark, content)
    end
    self:Resize()
end

function XUiGridChannelItem:Resize()
    self.Transform.sizeDelta = CS.UnityEngine.Vector2(self.OriginSize.x, self.TxtInfo.preferredHeight)
end


return XUiGridChannelItem