

local XUiPhotographActionPanel = XClass(nil, "XUiPhotographActionPanel")

function XUiPhotographActionPanel:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    local txt = self.Transform:Find("Text")
    if txt then
        self.TxtTitle = txt:GetComponent("Text")
    end
    self:SetTxtTitle()
    self:AddListener()
end 

function XUiPhotographActionPanel:AddListener()
    self.BtnPaly.CallBack = function() self:OnBtnPlayClick() end
    self.BtnAgain.CallBack = function() self:OnBtnAgainClick() end
end 

function XUiPhotographActionPanel:SetViewState(state)
    self.GameObject:SetActiveEx(state)
    self:Refresh(false)
end

function XUiPhotographActionPanel:Refresh(isPlaying, cacheAnim)
    self.BtnPaly.gameObject:SetActiveEx(isPlaying)
    self.BtnAgain.gameObject:SetActiveEx(cacheAnim)
    if self.TxtTitle then
        self.TxtTitle.gameObject:SetActiveEx(isPlaying or cacheAnim)
    end
end

function XUiPhotographActionPanel:SetTxtTitle(txt)
    if not self.TxtTitle then
        return
    end
    txt = string.IsNilOrEmpty(txt) and CSXTextManagerGetText("PhotoModeNotChooseText") or txt
    self.TxtTitle.text = txt
end

function XUiPhotographActionPanel:SetBtnPlayState(select)
    self.BtnPaly:SetButtonState(select and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiPhotographActionPanel:OnBtnPlayClick()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_ANIMATION_STATE, self.BtnPaly:GetToggleState())
end

function XUiPhotographActionPanel:OnBtnAgainClick()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_REPLAY_ANIMATION)
end

return XUiPhotographActionPanel