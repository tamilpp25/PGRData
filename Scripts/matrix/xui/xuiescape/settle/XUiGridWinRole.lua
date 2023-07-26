local XUiGridWinRole = XClass(nil, "XUiGridWinRole")

function XUiGridWinRole:Ctor(ui, pos, isUseDataCopy)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.Pos = pos
    self.EscapeData = isUseDataCopy and XDataCenter.EscapeManager.GetEscapeDataCopy() or XDataCenter.EscapeManager.GetEscapeData()
end

function XUiGridWinRole:Refresh(entityId)
    local charImage = XEntityHelper.GetCharacterSmallIcon(entityId)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(charImage)
    end

    local characterState = self.EscapeData:GetCharacterState(entityId)
    local defaultPercent = 100
    if self.ImgProgressHp then
        self.ImgProgressHp.fillAmount = characterState and characterState:GetLifePermyriadPercent() or defaultPercent
    end
    if self.ImgProgressEnergy then
        self.ImgProgressEnergy.fillAmount = characterState and characterState:GetEnergyPermyriadPercent() or defaultPercent
    end
end

return XUiGridWinRole