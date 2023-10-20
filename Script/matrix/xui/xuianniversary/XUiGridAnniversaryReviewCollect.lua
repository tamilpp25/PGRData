local XUiGridAnniversaryReviewCollect=XClass(XUiNode,'XUiGridAnniversaryReviewCollect')

function XUiGridAnniversaryReviewCollect:Refresh(data)
    self.TxtMedalName.text = data.Name
    self.ImgMedalIcon:SetRawImage(data.MedalImg)
end

return XUiGridAnniversaryReviewCollect