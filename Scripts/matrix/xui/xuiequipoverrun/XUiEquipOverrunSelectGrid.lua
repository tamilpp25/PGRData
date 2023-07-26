local XUiEquipOverrunSelectGrid = XClass(nil, "XUiEquipOverrunSelectGrid")

function XUiEquipOverrunSelectGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiEquipOverrunSelectGrid:Init(parent)
    self.Parent = parent
end

function XUiEquipOverrunSelectGrid:Refresh(suitData, isLastSelect)
    local suitCfg = XEquipConfig.GetEquipSuitCfg(suitData.Id)
    self.RImgIcon:SetRawImage(suitCfg.IconPath)
    self.TxtName.text = suitCfg.Name
    self.TxtDes.text = suitCfg.Description
    self.TagNotActive.gameObject:SetActiveEx(not suitData.IsActive)
    self.TagNow.gameObject:SetActiveEx(isLastSelect)

    local quality = XEquipConfig.GetSuitQuality(suitData.Id)
    local qualityPath = XArrangeConfigs.GeQualityBgPath(quality)
    self.ImgEquipQuality:SetSprite(qualityPath)
end

function XUiEquipOverrunSelectGrid:SetCurSelect(isCurSelect)
    self.Select.gameObject:SetActiveEx(isCurSelect)
end

return XUiEquipOverrunSelectGrid