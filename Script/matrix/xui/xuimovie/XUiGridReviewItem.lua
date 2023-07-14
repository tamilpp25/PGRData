local XUiGridReviewItem = XClass(nil, "XUiGridReviewItem")

function XUiGridReviewItem:Ctor(ui, data,cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ReviewCallBack = cb
    self.CueId = data.CueId or 0
    XTool.InitUiObject(self)
    self.BtnReview.CallBack = function() 
        if self.ReviewCallBack then
           self.ReviewCallBack(self.CueId)
        end        
     end
    self.BtnReview.gameObject:SetActiveEx(self.CueId ~= 0)
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