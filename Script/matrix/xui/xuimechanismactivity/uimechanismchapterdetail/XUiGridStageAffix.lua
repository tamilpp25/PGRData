local XUiGridStageAffix = XClass(XUiNode, 'XUiGridStageAffix')

function XUiGridStageAffix:Refresh(affixIcon, affixDesc)
    self.RImgAffix:SetRawImage(affixIcon)
    self.TxtDetail.text = affixDesc
end

return XUiGridStageAffix