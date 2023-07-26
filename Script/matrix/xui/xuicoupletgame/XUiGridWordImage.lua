local XUiGridWordImage = XClass(nil, "XUiGridWordImage")

function XUiGridWordImage:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiGridWordImage:Init()

end

function XUiGridWordImage:SetData(data)
    local imageWord = XCoupletGameConfigs.GetCoupletWordImageById(data)
    self.ImgOpen:SetRawImage(imageWord)
end

function XUiGridWordImage:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

return XUiGridWordImage