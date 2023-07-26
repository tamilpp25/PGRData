local XUiGridFurnitreTemplate = XClass(nil, "XUiGridFurnitreTemplate")

function XUiGridFurnitreTemplate:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridFurnitreTemplate:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridFurnitreTemplate:Refresh(furniture)
    self.Furniture = furniture
    local furnitureCfg = XFurnitureConfigs.GetFurnitureTemplateById(self.Furniture.ConfigId)
    self.TxtName.text = furnitureCfg.Name
    self.RImgIcon:SetRawImage(furnitureCfg.Icon)

    if furniture.ConnectDormId > 0 and furniture.RoomDataType ~= XDormConfig.DormDataType.Self then
        if self.Furniture.Count > self.Furniture.TargetCount then
            self.TxtNum.text = CS.XTextManager.GetText("DormTemplateCountNotEnough", self.Furniture.TargetCount, self.Furniture.Count)
        else
            self.TxtNum.text = CS.XTextManager.GetText("DormTemplateCountEnough", self.Furniture.TargetCount, self.Furniture.Count)
        end

        self.PanelComplete.gameObject:SetActiveEx(self.Furniture.Count <= self.Furniture.TargetCount)
    else
        self.TxtNum.text = tostring(self.Furniture.Count)
        self.PanelComplete.gameObject:SetActiveEx(false)
    end
end

return XUiGridFurnitreTemplate