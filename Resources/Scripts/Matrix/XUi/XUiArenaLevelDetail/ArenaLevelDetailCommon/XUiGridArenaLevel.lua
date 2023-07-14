local XUiGridArenaLevel = XClass(nil, "XUiGridArenaLevel")

function XUiGridArenaLevel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridArenaLevel:ResetData(level, curLevel, icon, name)
    self.ImgCurLevel.gameObject:SetActiveEx(level == curLevel)
    self.RImgIcon:SetRawImage(icon)
    if self.TxtName then
        self.TxtName.text = name
    end
end

function XUiGridArenaLevel:SetSelect(isSelected)
    self.ImgSelected.gameObject:SetActiveEx(isSelected)
end

return XUiGridArenaLevel