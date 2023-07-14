local UiButtonState = CS.UiButtonState
local XUiGuildDormPanelUiSetting = XClass(nil, "XUiGuildDormPanelUiSetting")

function XUiGuildDormPanelUiSetting:Ctor(ui)
    self.GuildDormManager = XDataCenter.GuildDormManager
    XUiHelper.InitUiClass(self, ui)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnUi, self.OnBtnUiClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnName, self.OnBtnNameClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnEmoji, self.OnBtnTalkClicked)
    self.BtnUiSelected = true
    self.GuildDormManager.SetIsHideNameUi(false)
    self.GuildDormManager.SetIsHideTalkUi(false)
    self.BtnUi:SetButtonState(UiButtonState.Select)
    self.BtnName:SetButtonState(UiButtonState.Select)
    self.BtnEmoji:SetButtonState(UiButtonState.Select)
    self.BtnUi.ExitCheck = false
    self.BtnName.ExitCheck = false
    self.BtnEmoji.ExitCheck = false
    self.CloseCallback = nil
end

function XUiGuildDormPanelUiSetting:Open(cb)
    self.GameObject:SetActiveEx(true)
    self.CloseCallback = cb
end

function XUiGuildDormPanelUiSetting:OnBtnUiClicked()
    self.BtnUiSelected = not self.BtnUiSelected
    self.BtnUi:SetButtonState(self.BtnUiSelected and UiButtonState.Select
        or UiButtonState.Normal)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, self.BtnUiSelected)
end

function XUiGuildDormPanelUiSetting:OnBtnNameClicked()
    local isHideName = self.GuildDormManager.GetIsHideNameUi()
    isHideName = not isHideName
    self.GuildDormManager.SetIsHideNameUi(isHideName)
    self.BtnName:SetButtonState(isHideName and UiButtonState.Normal
        or UiButtonState.Select)
end

function XUiGuildDormPanelUiSetting:OnBtnTalkClicked()
    local isHideTalkUi = self.GuildDormManager.GetIsHideTalkUi()
    isHideTalkUi = not isHideTalkUi
    self.GuildDormManager.SetIsHideTalkUi(isHideTalkUi)
    self.BtnEmoji:SetButtonState(isHideTalkUi and UiButtonState.Normal
        or UiButtonState.Select)
end

function XUiGuildDormPanelUiSetting:Close()
    self.GameObject:SetActiveEx(false)
    if self.CloseCallback then
        self.CloseCallback()
    end
end

return XUiGuildDormPanelUiSetting