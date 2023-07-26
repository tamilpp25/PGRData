local XUiCommonBuffDetail = XLuaUiManager.Register(XLuaUi, "UiCommonBuffDetail")

function XUiCommonBuffDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiCommonBuffDetail:OnStart(name, icon, desc, title, descTitle)
    self.TxtName.text = name
    self.RImgIcon:SetRawImage(icon)
    self.TxtDesc.text = desc
    if title then 
        self.TxtTitle.text = title 
    end
    if descTitle then 
        self.TxtDescTitle.text = descTitle 
    end
end

--######################## 私有方法 ########################

function XUiCommonBuffDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

return XUiCommonBuffDetail