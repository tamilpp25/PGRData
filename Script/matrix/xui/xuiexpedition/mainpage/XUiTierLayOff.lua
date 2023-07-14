--收起关卡的普通关卡层控件
local XUiTierLayOff = XClass(nil, "XUiTierLayOff")

function XUiTierLayOff:Ctor(gameObject, tierUi)
    self.TierUi = tierUi
    XTool.InitUiObjectByUi(self, gameObject)
end

function XUiTierLayOff:RefreshData(tier)
    self.Tier = tier
    local stageName = self.Tier:GetName()
    if self.Tier:CheckIsInfiTier() then
        self.TxtName.text = CS.XTextManager.GetText("ExpeditionNormalNameFontColor", stageName)
    elseif self.Tier:CheckDifficulty(XExpeditionConfig.StageDifficulty.Normal) then
        self.TxtName.text = CS.XTextManager.GetText("ExpeditionNormalNameFontColor", stageName)
    else
        self.TxtName.text = CS.XTextManager.GetText("ExpeditionNightmareFontColor", stageName)
    end
    if self.TxtOrder then
        local orderStr = string.format("%02d", self.Tier:GetOrderId())
        if self.Tier:CheckIsInfiTier() then
            orderStr = CS.XTextManager.GetText("ExpeditionNormalTierFontColor", orderStr)
        elseif self.Tier:CheckDifficulty(XExpeditionConfig.StageDifficulty.Normal) then
            orderStr = CS.XTextManager.GetText("ExpeditionNormalTierFontColor", orderStr)
        else
            orderStr = CS.XTextManager.GetText("ExpeditionNightmareFontColor", orderStr)
        end
        self.TxtOrder.text = orderStr
    end
    self.CommonFuBenClear.gameObject:SetActiveEx(self.Tier:GetIsPass())
    self.RImgBg:SetRawImage(self.Tier:GetBgCoverPath())
    XUiHelper.RegisterClickEvent(self, self.RImgBg, function() self:OnClick() end)
end

function XUiTierLayOff:OnClick()
    if not self.Tier:GetIsUnlock() then
        XUiManager.TipText("ExpeditionTierLock")
        return
    end
    self.TierUi:OnClickLayOff()
end

function XUiTierLayOff:SetSelect(value)
    self:OnClick()
end

function XUiTierLayOff:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiTierLayOff:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiTierLayOff:PlayAnimEnable()
    if self.AnimEnable then
        self.AnimEnable:Stop()
        self.AnimEnable:Play()
    end
end

return XUiTierLayOff