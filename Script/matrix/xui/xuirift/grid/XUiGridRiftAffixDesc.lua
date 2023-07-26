local XUiGridRiftAffixDesc = XClass(nil, "XUiGridRiftAffixDesc")

function XUiGridRiftAffixDesc:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridRiftAffixDesc:Refresh(affixId)
    self.AffixId = affixId
    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(affixId)
    self.TxtName.text = cfg.Name
    self.TxtDesc.text = cfg.Description
    self.RImgIcon:SetRawImage(cfg.Icon)
end

return XUiGridRiftAffixDesc
