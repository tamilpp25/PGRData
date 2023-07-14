local XUiGridSnowGameDataItem = XClass(nil, "XUiGridSnowGameDataItem")

function XUiGridSnowGameDataItem:Ctor(ui, name)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.TxtTitle.text = name
end

function XUiGridSnowGameDataItem:Refresh(mvp, value)
    self.ImgMvp.gameObject:SetActiveEx(mvp and true or false)
    self.TxtValue.text = value
end

return XUiGridSnowGameDataItem