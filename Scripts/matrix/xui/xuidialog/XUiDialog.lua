local XUiDialog = XLuaUiManager.Register(XLuaUi, "UiDialog")

function XUiDialog:OnAwake()
    self.LastOperationType = CS.XInputManager.CurOperationType
    self:AutoAddListener()
end

function XUiDialog:OnStart(title, content, dialogType, closeCallback, sureCallback, data, cancelCallBack)
    ---- 处理额外参数 -----
    local ItemIds, sureText, closeText
    local content2, content3    --content2存在时用TxtInfo2替换TxtInfoNormal显示
    if data then
        ItemIds = { data.ItemId1, data.ItemId2, data.ItemId3 }
        sureText = data.sureText
        closeText = data.closeText
        content2 = data.Content2
        content3 = data.Content3
    end

    if content2 then
        self.TxtInfoNormal.gameObject:SetActiveEx(false)
        self.TxtInfo2.text = string.gsub(content2, "\\n", "\n")
        self.TxtInfo2.gameObject:SetActiveEx(true)
    else
        self.TxtInfo2.gameObject:SetActiveEx(false)
    end

    if content3 then
        self.TxtInfo3.text = string.gsub(content3, "\\n", "\n")
        self.TxtInfo3.gameObject:SetActiveEx(true)
    else
        self.TxtInfo3.gameObject:SetActiveEx(false)
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
        self.EnableAnimation = "DialogEnable"
    elseif dialogType == XUiManager.DialogType.OnlySure then
        self.PanelSureDialog.gameObject:SetActive(true)
        self.TxtInfoSure.text = string.gsub(content, "\\n", "\n")
        self.EnableAnimation = "SureDialogEnable"
    elseif dialogType == XUiManager.DialogType.OnlyClose then
        self.PanelCloseDialog.gameObject:SetActive(true)
        self.TxtInfoClose.text = string.gsub(content, "\\n", "\n")
        self.EnableAnimation = "CloseDialogEnable"
    elseif dialogType == XUiManager.DialogType.NoBtn then
        self.PanelDialog.gameObject:SetActive(true)
        self.BtnConfirm.gameObject:SetActive(false)
        self.BtnClose.gameObject:SetActive(false)
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
        self.EnableAnimation = "DialogEnable"
    elseif dialogType == XUiManager.DialogType.NormalAndNoBtnTanchuangClose then
        self.BtnTanchuangClose.gameObject:SetActive(false)
        self.PanelDialog.gameObject:SetActive(true)
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
        self.EnableAnimation = "DialogEnable"
    end
    self.OkCallBack = sureCallback
    self.CloseCallBack = closeCallback
    self.CancelCallBack = cancelCallBack
    self.DialogType = dialogType
end

function XUiDialog:OnEnable()
    self.LastOperationType = CS.XInputManager.CurOperationType
    if CS.XInputManager.CurOperationType ~= CS.XOperationType.System then
        CS.XInputManager.SetCurOperationType(CS.XOperationType.System)
    end
    if self.EnableAnimation then
        self:PlayAnimation(self.EnableAnimation)
    end

end

function XUiDialog:OnDisable()

end

function XUiDialog:RegisterClickEvent(uiNode, func)
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

function XUiDialog:AutoAddListener()
    self:RegisterClickEvent(self.BtnConfirmB, self.OnBtnConfirmBClick)
    self:RegisterClickEvent(self.BtnCloseA, self.OnBtnCloseAClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function XUiDialog:HideDialogLayer()
    self.PanelDialog.gameObject:SetActive(false)
    self.PanelCloseDialog.gameObject:SetActive(false)
    self.PanelSureDialog.gameObject:SetActive(false)
end

function XUiDialog:OnBtnCloseAClick()
    self:CancelBtnClick()
end

function XUiDialog:OnBtnConfirmBClick()
    self:OkBtnClick()
end

function XUiDialog:OnBtnConfirmClick()
    self:OkBtnClick()
end

function XUiDialog:OnBtnCloseClick()
    self:CancelBtnClick()
end

function XUiDialog:OkBtnClick()
    self:EmitSignal("Close", true)
    CsXUiManager.Instance:Close(self.Name)
    if self.OkCallBack then
        self.OkCallBack()
    end

    self.OkCallBack = nil
    self.CloseCallBack = nil
end

function XUiDialog:CancelBtnClick()
    self:EmitSignal("Close", false)
    CsXUiManager.Instance:Close(self.Name)
    if self.CloseCallBack then
        self.CloseCallBack()
    end

    self.OkCallBack = nil
    self.CloseCallBack = nil
end

--PC端响应返回键关闭界面
function XUiDialog:PcClose()
    if self.DialogType == XUiManager.DialogType.OnlySure then
        self:OkBtnClick()
        return
    end
    self:CancelBtnClick()
end

function XUiDialog:OnDestroy()
    self:AutoRemoveListener()
    CS.XInputManager.SetCurOperationType(self.LastOperationType)
end

function XUiDialog:AutoRemoveListener()
end

-- 区分取消和关闭弹窗
function XUiDialog:OnBtnCancelClick()
    self:EmitSignal("Close", false)
    CsXUiManager.Instance:Close(self.Name)
    if self.CancelCallBack then
        self.CancelCallBack()
    elseif self.CloseCallBack then
        self.CloseCallBack()
    end

    self.OkCallBack = nil
    self.CloseCallBack = nil
    self.CancelCallBack = nil
end

return XUiDialog
