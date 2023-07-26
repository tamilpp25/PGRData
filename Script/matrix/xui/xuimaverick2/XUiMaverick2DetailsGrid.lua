local XUiMaverick2DetailsGrid = XClass(nil, "UiMaverick2DetailsGrid")

function XUiMaverick2DetailsGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiMaverick2DetailsGrid:Refresh(talentInfo)
    self.RImgIcon:SetRawImage(talentInfo.Icon)
    self.TxtLv.text = XUiHelper.GetText("Maverick2TalentLv", talentInfo.Level)
    self.TxtDesc.text = talentInfo.Desc
end

return XUiMaverick2DetailsGrid