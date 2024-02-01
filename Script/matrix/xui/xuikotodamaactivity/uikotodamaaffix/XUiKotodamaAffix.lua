local XUiKotodamaAffix=XLuaUiManager.Register(XLuaUi,'UiKotodamaAffix')

function XUiKotodamaAffix:OnAwake()
    self.BtnClose.CallBack=function() self:Close() end
    self.BtnTanchuangClose.CallBack=function() self:Close() end
end

return XUiKotodamaAffix