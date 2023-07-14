local XUiGridUnionBuffItem = XClass(nil, "XUiGridUnionBuffItem")

function XUiGridUnionBuffItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

end

function XUiGridUnionBuffItem:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridUnionBuffItem:Refresh(buffId)
    local buffConfig = XFubenUnionKillConfigs.GetUnionEventConfigById(buffId)
    if not buffConfig then return end
    self.RImgBuffIcon:SetRawImage(buffConfig.Icon)
    self.TxtTitle.text = buffConfig.Name
    self.TxtLevel.text = buffConfig.Level
    self.TxtDescription.text = buffConfig.Description
end

return XUiGridUnionBuffItem