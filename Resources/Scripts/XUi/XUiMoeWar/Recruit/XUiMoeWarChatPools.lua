local XUiMoeWarChatPools = XClass(nil, "XUiMoeWarChatPools")

function XUiMoeWarChatPools:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiMoeWarChatPools:InitData(dynamicList)
    self.GameObject:SetActiveEx(false)
    dynamicList:AddObjectPools("myMsg", self.PanelSocialMyMsgItem.gameObject)
    dynamicList:AddObjectPools("otherMsg", self.PanelSocialOhterMsgItem.gameObject)
    dynamicList:AddObjectPools("myNo", self.PanelSocialMyNo.gameObject)
    dynamicList:AddObjectPools("myYes", self.PanelSocialMyYes.gameObject)
    dynamicList:AddObjectPools("line", self.PanelLine.gameObject)
end

return XUiMoeWarChatPools