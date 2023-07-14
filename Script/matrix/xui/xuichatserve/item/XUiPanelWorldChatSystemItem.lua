XUiPanelWorldChatSystemItem = XClass(nil, "XUiPanelWorldChatSystemItem")

function XUiPanelWorldChatSystemItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelWorldChatSystemItem:Refresh(chatData)
    self.TxtWord.text = string.format("<color=#00A0FFE6>%s</color>%s", CS.XTextManager.GetText("GuildChannelTypeAll"), chatData.Content)
end