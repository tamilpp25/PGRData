local XUiGridReviewItem = XClass(nil, "XUiGridReviewItem")

function XUiGridReviewItem:Ctor(ui, data)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Refresh(data)
end

function XUiGridReviewItem:Refresh(data)
    self.TxtName.text = data.RoleName
    self.TxtWords.text = data.Content
end

function XUiGridReviewItem:SetTextColor(color)
    self.TxtWords.color = color
    self.TxtName.color = color
end

function XUiGridReviewItem:GetTextColor()
    return self.TxtWords.color
end

return XUiGridReviewItem