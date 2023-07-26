local XUiGridExhibitionAureBallSelect = XClass(nil, "XUiGridExhibitionAureBallSelect")

function XUiGridExhibitionAureBallSelect:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGridExhibitionAureBallSelect:Refresh(config, index)
    self.Id = config.Id
    self.Index = index
    self.Icon:SetRawImage(config.Icon)
end

function XUiGridExhibitionAureBallSelect:SetSelect(flag)
    self.Select.gameObject:SetActiveEx(flag)
    if flag then
        self.RootUi:OnGridSelect(self)
    end
end

function XUiGridExhibitionAureBallSelect:SetUsing(flag)
    self.Using.gameObject:SetActiveEx(flag)
end

return XUiGridExhibitionAureBallSelect