local XUiCommonInterBtn = XClass(nil, "XUiCommonInterBtn")

function XUiCommonInterBtn:Ctor(rootUi, gameObject)
    self.RootUi = rootUi
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    XTool.InitUiObject(self)
    
    self.IsSelect = false
    self.Data = {Id = 0, Key = 0, Icon = "", Text = "", Order = 0, IsDisable = false}
    self.XUiButton = gameObject:GetComponent("XUiButton")
    XUiHelper.RegisterClickEvent(self, self.XUiButton, self.OnClickBtn)
end

function XUiCommonInterBtn:OnClickBtn()
    local fight = CS.XFight.Instance
    if not fight then
        return
    end
    self.RootUi:UpdateOptionsSelect()
    fight.InputControl:OnClick(self.Data.Key, CS.XOperationClickType.KeyDown)
    fight.InputControl:OnClick(self.Data.Key, CS.XOperationClickType.KeyUp)
end

function XUiCommonInterBtn:Refresh(data)
    self.Data = data
    self.XUiButton:SetName(data.Text)
    self.XUiButton:SetSprite(data.Icon)
    self.XUiButton:SetButtonState(data.IsDisable and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self:SetIsSelect(false)
    self.GameObject:SetActiveEx(true)
end

function XUiCommonInterBtn:GetKey()
    return self.Data.Key
end

function XUiCommonInterBtn:SetIsSelect(isSelect)
    self.IsSelect = isSelect
    if not self.Data.IsDisable then
        return
    end
    self.RImgDisableSelect.gameObject:SetActiveEx(isSelect)
    self.ImgDisable.gameObject:SetActiveEx(not isSelect)

    if isSelect then
        self.RootUi:CancelOptionSelect()
    end
end

function XUiCommonInterBtn:GetTransform()
    return self.GameObject.transform
end

function XUiCommonInterBtn:GetXUiButton()
    return self.XUiButton
end

return XUiCommonInterBtn