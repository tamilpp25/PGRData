local XUiGridFurnitreTemplate = XClass(nil, "XUiGridFurnitreTemplate")

function XUiGridFurnitreTemplate:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridFurnitreTemplate:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridFurnitreTemplate:Refresh(frunitrue)
    self.Frunitrue = frunitrue
    local furnitureCfg = XFurnitureConfigs.GetFurnitureTemplateById(self.Frunitrue.ConfigId)
    self.TxtName.text = furnitureCfg.Name
    self.RImgIcon:SetRawImage(furnitureCfg.Icon)

    if frunitrue.ConnectDormId > 0 then
        if self.Frunitrue.Count > self.Frunitrue.TargetCount then
            self.TxtNum.text = CS.XTextManager.GetText("DormTemplateCountNotEnough", self.Frunitrue.TargetCount, self.Frunitrue.Count)
        else
            self.TxtNum.text = CS.XTextManager.GetText("DormTemplateCountEnough", self.Frunitrue.TargetCount, self.Frunitrue.Count)
        end

        self.PanelComplete.gameObject:SetActiveEx(self.Frunitrue.Count <= self.Frunitrue.TargetCount)
    else
        self.TxtNum.text = tostring(self.Frunitrue.Count)
        self.PanelComplete.gameObject:SetActiveEx(false)
    end
end

return XUiGridFurnitreTemplate