--通用返回，主菜单
local XUiTopControl = XClass(nil, "XUiTopControl")

function XUiTopControl:Ctor(rootUi, topControlPanel, onBack, onMainUi)
    self.RootUi = rootUi
    self.OnBack = onBack
    self.OnMainUi = onMainUi
    XTool.InitUiObjectByUi(self, topControlPanel)
    self:InitBtns()
end

function XUiTopControl:InitBtns()
    if self.BtnBack then self.BtnBack.CallBack = self.OnBack or function() self:OnClickBtnBack() end end
    if self.BtnMainUi then self.BtnMainUi.CallBack = self.OnMainUi or function() self:OnClickMainUi() end end
end

function XUiTopControl:OnClickBtnBack()
    self.RootUi:Close()
end

function XUiTopControl:OnClickMainUi()
    XLuaUiManager.RunMain()
end

function XUiTopControl:ShowUi()
    self.GameObject:SetActiveEx(true)
end

function XUiTopControl:HideUi()
    self.GameObject:SetActiveEx(false)
end

return XUiTopControl