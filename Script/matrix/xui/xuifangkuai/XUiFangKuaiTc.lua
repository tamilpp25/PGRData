---@class XUiFangKuaiTc : XLuaUi
---@field _Control XFangKuaiControl 弹框
local XUiFangKuaiTc = XLuaUiManager.Register(XLuaUi, "UiFangKuaiTc")

function XUiFangKuaiTc:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnSure, self.OnSureClick)
end

function XUiFangKuaiTc:OnStart(title, desc, onSureCallBack)
    self.TxtTitle.text = title or XUiHelper.GetText("TipTitle")
    self.TxtDesc.text = desc
    self._SureCallBack = onSureCallBack
end

function XUiFangKuaiTc:OnSureClick()
    if self._SureCallBack then
        self._SureCallBack()
    end
    self:Close()
end

return XUiFangKuaiTc