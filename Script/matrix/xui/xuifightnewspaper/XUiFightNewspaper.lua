local XUiFightNewspaper = XLuaUiManager.Register(XLuaUi, "UiFightNewspaper")

function XUiFightNewspaper:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = function()
        local fight = CS.XFight.Instance
        if fight then
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
        end
        self:Close()
    end
end

function XUiFightNewspaper:OnEnable(name)
    self.RImgNewspaper:SetRawImage(name)
end