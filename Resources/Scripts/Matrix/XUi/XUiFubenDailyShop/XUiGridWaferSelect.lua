local XUiGridWaferSelect = XClass(nil, "XUiGridWaferSelect")

function XUiGridWaferSelect:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridWaferSelect:Init(parent, rootUi)
    self.Parent = parent
    self.RootUi = rootUi or parent
end

function XUiGridWaferSelect:Refresh(suitId, isSelected, isNew)
    local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)

    local icon = XDataCenter.EquipManager.GetSuitIconBagPath(suitId)
    self.RImgIcon:SetRawImage(icon)
    self.RImgIcon.gameObject:SetActive(true)

    self.TxtName.text = suitCfg.Name
    self.TxtDes.text = suitCfg.Description

    self.Select.gameObject:SetActiveEx(isSelected)
    self.Tag.gameObject:SetActiveEx(isNew)

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi:SetUiSprite(self.ImgEquipQuality, XDataCenter.EquipManager.GetSuitQualityIcon(suitId))
    end

    self.GameObject:SetActiveEx(true)
end

return XUiGridWaferSelect