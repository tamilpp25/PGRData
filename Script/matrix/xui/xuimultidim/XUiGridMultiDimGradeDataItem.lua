local XUiGridMultiDimGradeDataItem = XClass(nil, "XUiGridMultiDimGradeDataItem")

function XUiGridMultiDimGradeDataItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridMultiDimGradeDataItem:Refresh(mvp, value)
    self.ImgMvp.gameObject:SetActive(mvp and true or false)
    self.TxtValue.text = value
end

return XUiGridMultiDimGradeDataItem