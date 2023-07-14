local XUiDialogDrag = XLuaUiManager.Register(XLuaUi, "UiDialogDrag")

function XUiDialogDrag:OnAwake()
    self:AutoAddListener()
end

function XUiDialogDrag:OnStart(title, content, dialogType, closeCallback, sureCallback, data)
    ---- 处理额外参数 -----
    local ItemIds, sureText, closeText
    if data then
        ItemIds = {data.ItemId1, data.ItemId2, data.ItemId3}
        sureText = data.sureText
        closeText = data.closeText
    end
    
    if ItemIds and #ItemIds > 0 then
        self.PanelActivityAsset.gameObject:SetActive(true)
        XUiPanelAsset.New(self, self.PanelActivityAsset, ItemIds[1], ItemIds[2], ItemIds[3])
    else
        self.PanelActivityAsset.gameObject:SetActive(false)
    end

    if sureText then
        self.BtnConfirm:SetNameByGroup(0, sureText)
        self.BtnConfirmB:SetNameByGroup(0, sureText)
    end
    
    if closeText then
        self.BtnClose:SetNameByGroup(0, closeText)
        self.BtnCloseA:SetNameByGroup(0, closeText)
    end
    ---- end -----
    
    self:HideDialogLayer()
    if title then
        self.TxtTitle.text = title
    end

    if dialogType == XUiManager.DialogType.Normal then
        self.PanelDialog.gameObject:SetActive(true)
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
        self:PlayAnimation("DialogEnable")
    elseif dialogType == XUiManager.DialogType.OnlySure then
        self.PanelSureDialog.gameObject:SetActive(true)
        self.TxtInfoSure.text = string.gsub(content, "\\n", "\n")
        self:PlayAnimation("SureDialogEnable")
    elseif dialogType == XUiManager.DialogType.OnlyClose then
        self.PanelCloseDialog.gameObject:SetActive(true)
        self.TxtInfoClose.text = string.gsub(content, "\\n", "\n")
        self:PlayAnimation("CloseDialogEnable")
    elseif dialogType == XUiManager.DialogType.NoBtn then
        self.PanelDialog.gameObject:SetActive(true)
        self.BtnConfirm.gameObject:SetActive(false)
        self.BtnClose.gameObject:SetActive(false)
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
        self:PlayAnimation("DialogEnable")
    elseif dialogType == XUiManager.DialogType.NormalAndNoBtnTanchuangClose then
        self.BtnTanchuangClose.gameObject:SetActive(false)
        self.PanelDialog.gameObject:SetActive(true)
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
        self:PlayAnimation("DialogEnable")
    end
    self.OkCallBack = sureCallback
    self.CancelCallBack = closeCallback
end

function XUiDialogDrag:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridArenaStage:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridArenaStage:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiDialogDrag:AutoAddListener()
    self:RegisterClickEvent(self.BtnConfirmB, self.OnBtnConfirmBClick)
    self:RegisterClickEvent(self.BtnCloseA, self.OnBtnCloseAClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function XUiDialogDrag:HideDialogLayer()
    self.PanelDialog.gameObject:SetActive(false)
    self.PanelCloseDialog.gameObject:SetActive(false)
    self.PanelSureDialog.gameObject:SetActive(false)
end

function XUiDialogDrag:OnBtnCloseAClick()
    self:CancelBtnClick()
end

function XUiDialogDrag:OnBtnConfirmBClick()
    self:OkBtnClick()
end

function XUiDialogDrag:OnBtnConfirmClick()
    self:OkBtnClick()
end

function XUiDialogDrag:OnBtnCloseClick()
    self:CancelBtnClick()
end

function XUiDialogDrag:OkBtnClick()
    CsXUiManager.Instance:Close("UiDialogDrag")
    if self.OkCallBack then
        self.OkCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

function XUiDialogDrag:CancelBtnClick()
    CsXUiManager.Instance:Close("UiDialogDrag")
    if self.CancelCallBack then
        self.CancelCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

return XUiDialogDrag
