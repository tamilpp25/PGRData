---无尽关卡层控件
local XUiTierInfinity = XClass(nil, "XUiTierInfinity")

function XUiTierInfinity:Ctor(gameObject, tierUi)
    self.TierUi = tierUi
    XTool.InitUiObjectByUi(self, gameObject)
end

function XUiTierInfinity:RefreshData(tier)
    self.Tier = tier
    local stageName = self.Tier:GetName()
    self.TxtName.text = CS.XTextManager.GetText("ExpeditionNormalNameFontColor", stageName)
    if self.TxtWave then
        local wave = XDataCenter.ExpeditionManager.GetWave()
        wave = CS.XTextManager.GetText("ExpeditionNormalTierFontColor", wave)
        self.TxtWave.text = wave
    end
    XUiHelper.RegisterClickEvent(self, self.ImgStage, function() self:OnClick() end)
end

function XUiTierInfinity:SetSelect(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiTierInfinity:OnClick()
    if not self.Tier:GetIsUnlock() then
        XUiManager.TipText("ExpeditionTierLock")
        return
    end
    self.TierUi:OnClickInfi()
end

function XUiTierInfinity:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiTierInfinity:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiTierInfinity:PlayAnimEnable()
    if self.AnimEnable then
        self.AnimEnable:Stop()
        self.AnimEnable:Play()
    end
end

return XUiTierInfinity