local XUiGridKotodamaChapterDetailMonster=XClass(XUiNode,'XUiGridKotodamaChapterDetailMonster')

function XUiGridKotodamaChapterDetailMonster:Refresh(icon,name)
    self.RImgIcon:SetRawImage(icon)
    self.TxtName.text=name
end

return XUiGridKotodamaChapterDetailMonster