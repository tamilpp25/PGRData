---@class XUiLogUpload : XLuaUi
---@field BtnAgree XUiComponent.XUiButton
local XUiLogUpload = XLuaUiManager.Register(XLuaUi, "UiLogUpload")

function XUiLogUpload:OnStart()
    self:RegisterUiEvents()
    self._IsShowUpload = false
end

function XUiLogUpload:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnRetry, self.OnBtnRetryClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnAgree, self.OnBtnAgreeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUpload, self.OnBtnUploadClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiLogUpload:OnEnable()
    self:ShowDefaultUi()

    XMVCA.XLogUpload:AddAgencyEvent(XAgencyEventId.EVENT_LOG_UPLOAD_PROGRESS, self.OnLogUploadProgress, self)
    XMVCA.XLogUpload:AddAgencyEvent(XAgencyEventId.EVENT_LOG_UPLOAD_COMPLETE, self.OnLogUploadComplete, self)
end

function XUiLogUpload:ShowDefaultUi()
    self._IsShowUpload = false
    self.TxtTips.gameObject:SetActiveEx(true)
    self.Panel.gameObject:SetActiveEx(true)
    self.PanelUpload.gameObject:SetActiveEx(false)

    self:UpdateBtnAgree()
end

function XUiLogUpload:UpdateBtnAgree()
    local isSelect = XMVCA.XLogUpload:IsAgreeUpload()
    self.BtnAgree:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiLogUpload:ShowUploadUi()
    self._IsShowUpload = true
    self.TxtTips.gameObject:SetActiveEx(false)
    self.Panel.gameObject:SetActiveEx(false)
    self.PanelUpload.gameObject:SetActiveEx(true)
    self.BtnRetry.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
    self.ImgBar.fillAmount = 0
    self.TxtInfo.text = XUiHelper.GetText("LogUploadProgress") --"日志上传中" --LogUploadProgress
    if self.TxtUpload then
        self.TxtUpload.gameObject:SetActiveEx(true)
    end
end


function XUiLogUpload:OnDisable()
    XMVCA.XLogUpload:RemoveAgencyEvent(XAgencyEventId.EVENT_LOG_UPLOAD_PROGRESS, self.OnLogUploadProgress, self)
    XMVCA.XLogUpload:RemoveAgencyEvent(XAgencyEventId.EVENT_LOG_UPLOAD_COMPLETE, self.OnLogUploadComplete, self)
end

function XUiLogUpload:OnBtnRetryClick()
    XMVCA.XLogUpload:RetryUpload()
end

function XUiLogUpload:OnBtnCloseClick()
    self:Close()
end

function XUiLogUpload:OnBtnAgreeClick()
    XMVCA.XLogUpload:UpdateIsAgreeUpload()
    self:UpdateBtnAgree()
end

function XUiLogUpload:OnBtnUploadClick()
    if XMVCA.XLogUpload:IsAgreeUpload() then
        if XMVCA.XLogUpload:CheckAndUpload() then
            self:ShowUploadUi()
        end
    else
        XUiManager.TipText("LogUploadAgree", XUiManager.UiTipType.Tip)
    end
end

function XUiLogUpload:OnBtnBackClick()
    if not self._IsShowUpload then
        self:Close()
    end
end

function XUiLogUpload:OnLogUploadProgress(value)
    self.ImgBar.fillAmount = value
end

function XUiLogUpload:OnLogUploadComplete(code)
    if code == CS.XLogPackageUploadCode.SUCCESS then
        self.ImgBar.fillAmount = 1
        --这里提示成功
        self.BtnClose.gameObject:SetActiveEx(true)
        self.TxtInfo.text = XUiHelper.GetText("LogUploadSuccess") --"上传成功" --LogUploadSuccess
    else
        self.ImgBar.fillAmount = 0
        self.BtnRetry.gameObject:SetActiveEx(true)
        self.BtnClose.gameObject:SetActiveEx(true)
        self.TxtInfo.text = XUiHelper.GetText("LogUploadFail")--"上传失败" --LogUploadFail
    end
    if self.TxtUpload then
        self.TxtUpload.gameObject:SetActiveEx(false)
    end
end

return XUiLogUpload