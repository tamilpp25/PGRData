--信物和道具详情的格子
local XUiDetailPropGrid = XClass(nil, "XUiDetailPropGrid")

function XUiDetailPropGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

-- token : XAdventureToken
function XUiDetailPropGrid:SetData(token)
    self.RImgIcon:SetRawImage(token:GetIcon())
    self.ImgQualit:SetSprite(token:GetItemQualityIcon())
end

return XUiDetailPropGrid