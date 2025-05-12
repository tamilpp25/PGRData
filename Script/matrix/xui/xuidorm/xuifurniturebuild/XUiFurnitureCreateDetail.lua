--家具上限提示弹窗
---@class XUiFurnitureCreateDetail : XLuaUi
local XUiFurnitureCreateDetail = XLuaUiManager.Register(XLuaUi, "UiFurnitureCreateDetail")

function XUiFurnitureCreateDetail:OnAwake()
    self:RegisterUiEvents()
end

function XUiFurnitureCreateDetail:OnStart()
    self.TxtName = XUiHelper.GetText("DormFurnitureCreateDetailTips")
end

function XUiFurnitureCreateDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnRecovery, self.OnBtnRecoveryClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnCloseClick)
end

function XUiFurnitureCreateDetail:OnBtnCloseClick()
    self:Close()
end

function XUiFurnitureCreateDetail:OnBtnRecoveryClick()
    self:Close()
    local uiBag = XLuaUiManager.FindTopUi("UiDormBag")
    if uiBag then
        uiBag.UiProxy.UiLuaTable:OnBtnRecycleClick()
    else
        XLuaUiManager.OpenWithCallback("UiDormBag", function(ui)
            ui.UiProxy.UiLuaTable:OnBtnRecycleClick()
        end)
    end
end

return XUiFurnitureCreateDetail