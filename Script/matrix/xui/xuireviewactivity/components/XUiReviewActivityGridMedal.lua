
local XUiReviewActivityGridMedal = XClass(nil, "XUiReviewActivityGridMedal")

function XUiReviewActivityGridMedal:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiReviewActivityGridMedal:RefreshData(medalInfo)
    self.Data = medalInfo
    local data = XDataCenter.MedalManager.GetMedalById(medalInfo.Id)
    if data and data.MedalImg ~= nil then
        self.ImgMedalIcon:SetRawImage(data.MedalImg)
    end
    self.TxtMedalName.text = data.Name
    self.TxtMedalTime.text = XUiHelper.GetText("DayOfGetMedal", XTime.TimestampToGameDateTimeString(data.Time))
end

return XUiReviewActivityGridMedal