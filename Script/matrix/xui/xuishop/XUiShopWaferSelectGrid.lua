local XUiShopWaferSelectGrid = XClass(nil, "XUiShopWaferSelectGrid")

function XUiShopWaferSelectGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiShopWaferSelectGrid:Init(parent, rootUi)
    self.Parent = parent
    self.RootUi = rootUi or parent
    self.Tag.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
end

function XUiShopWaferSelectGrid:Refresh(data, isSelected)
    local icon = data.icon
    self.RImgIcon:SetRawImage(icon)
    self.RImgIcon.gameObject:SetActive(true)

    self.TxtName.text = data.text
    self.TxtDes.text = data.description

    self.Select.gameObject:SetActiveEx(isSelected)
    
    --装备专用的竖条品质色
    if self.ImgEquipQuality and data.suitQualityIcon then
        self.RootUi:SetUiSprite(self.ImgEquipQuality, data.suitQualityIcon)
        self.ImgEquipQuality.gameObject:SetActiveEx(true)
    else
        self.ImgEquipQuality.gameObject:SetActiveEx(false)
    end
end

return XUiShopWaferSelectGrid