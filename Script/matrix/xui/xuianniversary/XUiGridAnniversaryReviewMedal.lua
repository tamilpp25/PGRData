local XUiGridAnniversaryReviewMedal=XClass(XUiNode,'XUiGridAnniversaryReviewMedal')

function XUiGridAnniversaryReviewMedal:OnStart()
    
end

function XUiGridAnniversaryReviewMedal:Refresh(data)
    local cfg=XMedalConfigs.GetMeadalConfigById(data.Id)
    self.TxtMedalName.text = cfg.Name
    self.ImgMedalIcon:SetRawImage(cfg.MedalImg)
    self.TxtMedalTime.text=XTime.TimestampToGameDateTimeString(data.Time)
end


return XUiGridAnniversaryReviewMedal
