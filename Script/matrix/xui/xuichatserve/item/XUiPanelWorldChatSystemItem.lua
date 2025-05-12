local XUiPanelWorldChatSystemItem = XClass(XUiNode, "XUiPanelWorldChatSystemItem")

function XUiPanelWorldChatSystemItem:Refresh(chatData)
    self.TxtWord.text = string.format("<color=#00A0FFE6>%s</color>%s", CS.XTextManager.GetText("GuildChannelTypeAll"), chatData.Content)
end

return XUiPanelWorldChatSystemItem