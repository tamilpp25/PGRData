--踩格子界面
local XUiFightBangbiPaper = XLuaUiManager.Register(XLuaUi, "UiFightBangbiPaper")

function XUiFightBangbiPaper:OnStart()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnClose)
end

function XUiFightBangbiPaper:OnClose()
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self:Close()
end