local XUiTRPGBagGrid = XClass(nil, "XUiTRPGBagGrid")

function XUiTRPGBagGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiTRPGBagGrid:Refresh()
    -- self.TxtNum.text = --拥有数量
    -- self.TxtItemName.text = 
    -- self.TextItemDesc = 
    -- self.RImgIcon:SetRawImage()
end

return XUiTRPGBagGrid