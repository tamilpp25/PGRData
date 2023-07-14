local XUiReformBuffDetail = XLuaUiManager.Register(XLuaUi, "UiReformBuffDetail")

function XUiReformBuffDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiReformBuffDetail:OnStart(data)
    self.TxtName.text = data.Name
    self.RImgIcon:SetRawImage(data.Icon)
    self.TxtStarCount.text = data.StarCount
    self.TxtDescription.text = data.Description
end

--######################## 私有方法 ########################

function XUiReformBuffDetail:RegisterUiEvents()
    self.BtnClose.CallBack = function() self:Close() end
end

return XUiReformBuffDetail