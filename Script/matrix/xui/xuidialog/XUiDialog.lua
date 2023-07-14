local XUiDialog = XLuaUiManager.Register(XLuaUi, "UiDialog")

function XUiDialog:OnAwake()
    self.LastOperationType = CS.XInputManager.CurOperationType  
    self:AutoAddListener()
end

function XUiDialog:OnStart(title, content, dialogType, closeCallback, sureCallback, data)
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
    elseif dialogType == XUiManager.DialogType.Passport then
        self.PanelDialog.gameObject:SetActive(true)
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
        self.EnableAnimation = "DialogEnable"
        self:ShowSpecialRegulationForJP()
    end
    self.OkCallBack = sureCallback
    self.CancelCallBack = closeCallback
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
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    if XDataCenter.InputManagerPc then
        self.LastInputLevel = XDataCenter.InputManagerPc.GetCurrentLevel()
        XDataCenter.InputManagerPc.SetCurrentLevel(5000)
    end
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
    self.CancelCallBack = nil
end

function XUiDialog:CancelBtnClick()
    self:EmitSignal("Close", false)
    CsXUiManager.Instance:Close(self.Name)
    if self.CancelCallBack then
        self.CancelCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

function XUiDialog:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.TxtInfoNormal.transform:LoadPrefab(url)
            local data = {type = 4,consumeId = 1}
            local timeId = XPassportConfigs.GetPassportActivityTimeId()
            local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
            local startTimeStr = XTime.TimestampToGameDateTimeString(startTime,"yyyy/MM/dd HH:mm")
            local endTimeStr = XTime.TimestampToGameDateTimeString(endTime-86400,"yyyy/MM/dd HH:mm")
            data.content = string.format("%s-%s", startTimeStr, endTimeStr)
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CS.XTextManager.GetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(-220, -136, 0)
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiDialog:OnDestroy()
    self:AutoRemoveListener()
    CS.XInputManager.SetCurOperationType(self.LastOperationType)
end

function XUiDialog:AutoRemoveListener()
    if XDataCenter.InputManagerPc then
        XDataCenter.InputManagerPc.SetCurrentLevel(self.LastInputLevel)
    end
end

return XUiDialog
