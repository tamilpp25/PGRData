local XUiGridYuanXiaoDataItem = XClass(nil, "XUiGridYuanXiaoDataItem")

function XUiGridYuanXiaoDataItem:Ctor(ui, name)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.TxtTitle.text = name
end

function XUiGridYuanXiaoDataItem:Refresh(mvp, value)
    self.ImgMvp.gameObject:SetActiveEx(mvp and true or false)
    self.TxtValue.text = value
end

return XUiGridYuanXiaoDataItem