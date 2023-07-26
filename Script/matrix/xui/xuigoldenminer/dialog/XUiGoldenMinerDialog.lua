local UiGoldenMinerDialog = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerDialog")

---@class UiGoldenMinerDialog : XLuaUi
function UiGoldenMinerDialog:OnAwake()
    self:InitData()
    self:InitBtnCallBack()
end

---@param data XGoldenMinerDialogExData
function UiGoldenMinerDialog:OnStart(title, content, closeCallback, sureCallback, data)
    if title then
        self.TxtTitle.text = title
    end
    if content then
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
    end
    self.CloseCallback = closeCallback
    self.SureCallback = sureCallback
    self.Data = data
    if self.Data then
        self.BtnClose.gameObject:SetActiveEx(self.Data.IsCanShowClose)
        self.BtnConfirm.gameObject:SetActiveEx(self.Data.IsCanShowSure)
        if self.Data.IsSettleGame then
            self:RefreshSettleGameDialog()
        end
    end
end

function UiGoldenMinerDialog:OnEnable()
    XDataCenter.InputManagerPc.SetCurOperationType(CS.XOperationType.System)
end

function UiGoldenMinerDialog:OnDisable()
    XDataCenter.InputManagerPc.ResumeCurOperationType()
end

--region Init
function UiGoldenMinerDialog:InitData()
    ---@type XGoldenMinerDialogExData
    self.Data = nil
    self.CloseCallback = nil
    self.SureCallback = nil
end
--endregion

--region Ui - SettleGameDialog
---@param data XGoldenMinerDialogExData
function UiGoldenMinerDialog:RefreshSettleGameDialog()
    if not self.BtnSave then
        self.BtnConfirm:SetNameByGroup(0, self.Data.TxtSure)
        self.BtnClose:SetNameByGroup(0, self.Data.TxtClose)
        return
    end
    self.SpecialCloseCallBack = self.Data.FuncSpecial
    self.BtnConfirm.gameObject:SetActiveEx(false)
    self.BtnSave.gameObject:SetActiveEx(true)
    self.BtnTanchuangClose.gameObject:SetActiveEx(true)
    self.BtnClose:SetNameByGroup(0, self.Data.TxtClose)
    if self.Data.IsCanShowClose then
        self.BtnSave:SetNameByGroup(0, self.Data.TxtSure)
    else
        self.BtnSave.gameObject:SetActiveEx(false)
        self.BtnConfirm.gameObject:SetActiveEx(true)
        self.BtnConfirm:SetNameByGroup(0, self.Data.TxtClose)
        self.Data.FuncSpecialIsSure = true
    end
end
--endregion

--region Ui - BtnListener
function UiGoldenMinerDialog:InitBtnCallBack()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnSpecialCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    if self.BtnSave then
        self:RegisterClickEvent(self.BtnSave, self.OnBtnConfirmClick)
    end
end

function UiGoldenMinerDialog:OnBtnCloseClick()
    self:Close()
    if self.CloseCallback then
        self.CloseCallback()
    end
    self:InitData()
end

function UiGoldenMinerDialog:OnBtnSpecialCloseClick()
    self:Close()
    if self.Data and not self.Data.FuncSpecialIsSure then
        self.Data.FuncSpecial()
        self:InitData()
        return
    end
    if self.CloseCallback then
        self.CloseCallback()
    end
    self:InitData()
end

function UiGoldenMinerDialog:OnBtnConfirmClick()
    self:Close()
    if self.Data and self.Data.FuncSpecialIsSure then
        self.Data.FuncSpecial()
        self:InitData()
        return
    end
    if self.SureCallback then
        self.SureCallback()
    end

    self:InitData()
end
--endregion