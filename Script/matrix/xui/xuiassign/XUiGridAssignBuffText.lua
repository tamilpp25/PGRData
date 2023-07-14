local XUiGridAssignBuffText = XClass(nil, "XUiGridAssignBuffText")

function XUiGridAssignBuffText:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridAssignBuffText:Refresh(text, isActive)
    if isActive then
        self.NorTxtBuff.gameObject:SetActiveEx(false)
        self.SelectTxtBuff.gameObject:SetActiveEx(true)
        self.SelectTxtBuff.text = text
    else
        self.NorTxtBuff.gameObject:SetActiveEx(true)
        self.SelectTxtBuff.gameObject:SetActiveEx(false)
        self.NorTxtBuff.text = text
    end
end

return XUiGridAssignBuffText