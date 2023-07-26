--关卡层关卡控件
local XUiTierStage = XClass(nil, "XUiTierStage")

function XUiTierStage:Ctor(gameObject, tierUi)
    self.TierUi = tierUi
    self.RootUi = self.TierUi.RootUi
    XTool.InitUiObjectByUi(self, gameObject)
    self:Init()
end

function XUiTierStage:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnReset, function() self:OnClickReset() end)
    XUiHelper.RegisterClickEvent(self, self.ImgBg, function() self:OnClickStage() end)
    self.GameObject:SetActiveEx(false) --界面进入时默认隐藏
end

function XUiTierStage:RefreshData(eStage)
    if not eStage then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.EStage = eStage
    self.TxtName.text = self.EStage:GetStageName()
    if self.TxtOrder then self.TxtOrder.text = string.format("%02d", self.EStage:GetOrderId()) end
    self.CommonFuBenClear.gameObject:SetActiveEx(self.EStage:GetIsPass())
    self.RImgIcon:SetRawImage(self.EStage:GetStageCover())
    if self.EStage:GetStageType() == XExpeditionConfig.StageType.Battle then
        self.BtnReset.gameObject:SetActiveEx(not self.EStage:GetTierIsPass() and self.EStage:GetIsPass())
        self:SetWarning()
    else
        self.BtnReset.gameObject:SetActiveEx(false)
        self.IconYellow.gameObject:SetActiveEx(false)
        self.IconRed.gameObject:SetActiveEx(false)
    end
end

function XUiTierStage:SetWarning()
    local warning = self.EStage:GetStageIsDanger()
    self.IconYellow.gameObject:SetActiveEx(warning == XDataCenter.ExpeditionManager.StageWarning.Warning)
    self.IconRed.gameObject:SetActiveEx(warning == XDataCenter.ExpeditionManager.StageWarning.Danger)
end

function XUiTierStage:OnClickReset()
    XLuaUiManager.Open("UiExpeditionReset", self.EStage)
end

function XUiTierStage:OnClickStage()
    XLuaUiManager.Open("UiExpeditionStageDetail", self.EStage, self.RootUi)
end

function XUiTierStage:OnShow()
    if self.StageEnable then
        self.StageEnable:Stop()
        local stageBg = self.Transform:Find("StageBg"):GetComponent("CanvasGroup")
        if stageBg then
            stageBg.alpha = 0
        end
        self.GameObject:SetActiveEx(true)
        self.StageEnable:Play()
    end    
end

function XUiTierStage:OnDisable()
    if self.StageDisable then
        self.StageDisable:Stop()
        self.StageDisable:Play()
    end
end

return XUiTierStage