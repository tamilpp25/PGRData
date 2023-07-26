local XUiTheatreGroupTip = XLuaUiManager.Register(XLuaUi, "UiTheatreGroupTip")

function XUiTheatreGroupTip:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiTheatreGroupTip:OnStart(icon, name, title, content, useOne)
    self.RImgIcon:SetRawImage(icon)
    self.RImgIcon2:SetRawImage(icon)
    self.TxtName.text = name
    self.TxtTitle.text = title
    self.TxtContent.text = content
    self.RImgIcon.gameObject:SetActiveEx(useOne)
    self.RImgIcon2.gameObject:SetActiveEx(not useOne)
end

return XUiTheatreGroupTip