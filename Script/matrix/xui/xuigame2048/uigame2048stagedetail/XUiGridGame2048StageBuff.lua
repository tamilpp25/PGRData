local XUiGridGame2048StageBuff = XClass(XUiNode, 'XUiGridGame2048StageAffix')

function XUiGridGame2048StageBuff:Refresh(affixIcon, affixDesc, affixName)
    self.RImgSkill:SetRawImage(affixIcon)
    self.TxtDetail.text = affixDesc

    if self.TxtName then
        self.TxtName.text = affixName
    end
end

return XUiGridGame2048StageBuff