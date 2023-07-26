local XGridNieREasterEggChatList = XClass(nil, "XGridNieREasterEggChatList")

function XGridNieREasterEggChatList:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XGridNieREasterEggChatList:Refesh(data)
    self.TagBtn:SetNameByGroup(0, data.Message)
end

function XGridNieREasterEggChatList:IsSelect(isSel)
    if not isSel then
        self.TagBtn:SetButtonState(CS.UiButtonState.Normal)
    else
        self.TagBtn:SetButtonState(CS.UiButtonState.Select)
    end
    
end

return XGridNieREasterEggChatList