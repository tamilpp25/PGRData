local XUiGridReviewItem = XClass(nil, "XUiGridReviewItem")

function XUiGridReviewItem:Ctor(ui, data,cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ReviewCallBack = cb
    self.CueId = data.CueId or 0
    XTool.InitUiObject(self)
    self.BtnReview.gameObject:SetActiveEx(self.CueId ~= 0)
    self.BtnReview.CallBack = function() self:OnClickBtnReview() end
    self.TxtWords.onLinkClick = function(arg) self:OnClickTxtWords(arg) end
    self:Refresh(data)
end

function XUiGridReviewItem:OnClickBtnReview()
    if self.ReviewCallBack then
        self.ReviewCallBack(self.CueId)
    end
end

function XUiGridReviewItem:OnClickTxtWords(arg)
    XLuaUiManager.Open("UiMovieKeywordTips", arg)
end

function XUiGridReviewItem:Refresh(data)
    self.TxtWords.text = tostring(data.RoleName) .. tostring(data.Content)
end

function XUiGridReviewItem:SetTextColor(color)
    self.TxtWords.color = color
end

function XUiGridReviewItem:GetTextColor()
    return self.TxtWords.color
end

return XUiGridReviewItem