local XUiGridAnniversaryReviewCollect=XClass(XUiNode,'XUiGridAnniversaryReviewCollect')

function XUiGridAnniversaryReviewCollect:Refresh(data)
    ---黑岩超难关藏品特殊处理
    if data.Id == XEnumConst.SpecialHandling.DEADCollectiblesId then
        self.TxtMedalName.fontSize = 18
    end
    self.TxtMedalName.text = data.Name
    self.ImgMedalIcon:SetRawImage(data.MedalImg)
end

return XUiGridAnniversaryReviewCollect