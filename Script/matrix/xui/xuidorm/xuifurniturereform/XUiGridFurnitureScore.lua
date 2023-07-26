
local XUiGridFurnitureScore = XClass(nil, "XUiGridFurnitureScore")

function XUiGridFurnitureScore:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridFurnitureScore:Refresh(newAttr, oldAttr, icon, index)
    self.ImgTool:SetSprite(icon)
    self.TxtToolNum.text = XFurnitureConfigs.GetFurnitureAttrLevelNewDescription(1, index, newAttr)
    self.ImgScoreUp.gameObject:SetActiveEx(newAttr > oldAttr)
    self.ImgScoreDown.gameObject:SetActiveEx(newAttr < oldAttr)
end

function XUiGridFurnitureScore:RefreshTotal(newAttrs, oldAttrs)
    local newScore, oldScore = newAttrs.TotalScore, oldAttrs.TotalScore
    self.TxtToolNum.text = XFurnitureConfigs.GetFurnitureTotalAttrLevelNewColorDescription(1, newScore)
    self.ImgScoreUp.gameObject:SetActiveEx(newScore > oldScore)
    self.ImgScoreDown.gameObject:SetActiveEx(newScore < oldScore)
end

return XUiGridFurnitureScore