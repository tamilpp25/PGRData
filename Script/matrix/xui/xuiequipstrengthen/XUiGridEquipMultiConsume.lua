local XUiGridEquipMultiConsume = XClass(nil, "XUiGridEquipMultiConsume")

function XUiGridEquipMultiConsume:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.ItemGrid = XTool.InitUiObjectByUi({}, self.GridExpItem)
    self.EquipGrid = XTool.InitUiObjectByUi({}, self.GridEquip)
end

function XUiGridEquipMultiConsume:Refresh(consume)
    if consume:IsEquip() then
        local templateId = consume.TemplateId
        self.EquipGrid.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId))

        local qualityPath = XDataCenter.EquipManager.GetEquipQualityPath(templateId)
        self.EquipGrid.ImgEquipQuality:SetSprite(qualityPath)

        self.EquipGrid.TxtLevel.text = consume:GetLevel()

        self.GridEquip.gameObject:SetActiveEx(true)
        self.GridExpItem.gameObject:SetActiveEx(false)
    elseif consume:IsItem() then
        local itemId = consume.TemplateId
        self.ItemGrid.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))

        local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
        local qualityPath = XArrangeConfigs.GeQualityPath(quality)
        self.ItemGrid.ImgEquipQuality:SetSprite(qualityPath)

        self.ItemGrid.TxtCount.text = "x" .. consume.SelectCount

        self.GridEquip.gameObject:SetActiveEx(false)
        self.GridExpItem.gameObject:SetActiveEx(true)
    end
end

return XUiGridEquipMultiConsume
