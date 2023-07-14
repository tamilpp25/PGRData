local XUiDormPersonAttDesItem = XClass(nil, "XUiDormPersonAttDesItem")

function XUiDormPersonAttDesItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiDormPersonAttDesItem:OnRefresh(txt, icon)
    self.TxtDes.text = txt
    if not icon then
        return
    end

    self.ImgDes:SetSprite(icon)
end

function XUiDormPersonAttDesItem:SetState(state)
    if not self.GameObject then
        return
    end

    self.GameObject:SetActive(state)
end

return XUiDormPersonAttDesItem