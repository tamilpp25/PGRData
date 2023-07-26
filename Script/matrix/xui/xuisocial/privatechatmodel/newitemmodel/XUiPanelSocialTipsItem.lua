XUiPanelSocialTipsItem = XClass(nil, "XUiPanelSocialTipsItem")

function XUiPanelSocialTipsItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelSocialTipsItem:Refresh(chatData)
    self.CreateTime = chatData.CreateTime
    self.SenderId = chatData.SenderId

    self.TxtInfo.text = XDataCenter.ChatManager.CreateGiftTips(chatData)
end

function XUiPanelSocialTipsItem:SetShow(code)
    self.GameObject:SetActiveEx(code)
end