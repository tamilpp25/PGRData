local XUiDormMainAttItem = XClass(nil, "XUiDormMainAttItem")

function XUiDormMainAttItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiDormMainAttItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.UiRoot:SetUiSprite(self.ImgDes, itemdata[1])
    self.TxtNum.text = itemdata[2]
end

return XUiDormMainAttItem