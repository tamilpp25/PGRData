
local XUiReviewActivityGridCollection = XClass(nil, "XUiReviewActivityGridCollection")

function XUiReviewActivityGridCollection:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiReviewActivityGridCollection:RefreshData(id)
    self.Id = id
    local data = XDataCenter.MedalManager.GetScoreTitleById(id)
    if data.MedalImg ~= nil then
        self.ImgCollectionIcon:SetRawImage(data.MedalImg)
    end
    self.TxtCollectionName.text = data.Name
end

return XUiReviewActivityGridCollection