local XUiMultiDimTalentOpenTip = XLuaUiManager.Register(XLuaUi, "UiMultiDimTalentOpenTip")

function XUiMultiDimTalentOpenTip:OnAwake()
    self:RegisterUiEvents()
end

function XUiMultiDimTalentOpenTip:OnStart()
    local key = XDataCenter.MultiDimManager.GetMultiDimActivityKey(XMultiDimConfig.MultiDimThemeUnlock)
    XSaveTool.SaveData(key, true)
end

function XUiMultiDimTalentOpenTip:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiMultiDimTalentOpenTip:OnBtnCloseClick()
    self:Close()
end

return XUiMultiDimTalentOpenTip