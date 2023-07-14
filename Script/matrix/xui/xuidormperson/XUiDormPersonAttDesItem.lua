local XUiDormPersonAttDesItem = XClass(nil, "XUiDormPersonAttDesItem")

function XUiDormPersonAttDesItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiDormPersonAttDesItem:OnRefresh(txt, icon)
    self.TxtDes.text = txt
    if not icon or not self.UiRoot then
        return
    end

    self.UiRoot:SetUiSprite(self.ImgDes, icon)
end

function XUiDormPersonAttDesItem:SetState(state)
    if not self.GameObject then
        return
    end

    self.GameObject:SetActive(state)
end

return XUiDormPersonAttDesItem