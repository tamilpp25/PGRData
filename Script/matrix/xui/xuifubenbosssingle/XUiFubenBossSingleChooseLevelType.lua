local XUiFubenBossSingleChooseLevelType = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleChooseLevelType")

function XUiFubenBossSingleChooseLevelType:OnAwake()
    self:AutoAddListener()
end

function XUiFubenBossSingleChooseLevelType:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnGaojiqu.CallBack = function() self:OnSelectLevelType(XFubenBossSingleConfigs.LevelType.High) end
    self.BtnChaopinqu.CallBack = function() self:OnSelectLevelType(XFubenBossSingleConfigs.LevelType.Extreme) end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiFubenBossSingleChooseLevelType:OnSelectLevelType(levelType)
    self.LevelType = levelType

    if levelType == XFubenBossSingleConfigs.LevelType.High then
        self.BtnGaojiqu:SetButtonState(CS.UiButtonState.Select)
        self.BtnChaopinqu:SetButtonState(CS.UiButtonState.Normal)
    elseif levelType == XFubenBossSingleConfigs.LevelType.Extreme then
        self.BtnGaojiqu:SetButtonState(CS.UiButtonState.Normal)
        self.BtnChaopinqu:SetButtonState(CS.UiButtonState.Select)
    end
end

function XUiFubenBossSingleChooseLevelType:OnClickBtnConfirm()
    if not self.LevelType then
        XUiManager.TipText("BossSingleChooseLevelTypeEmpty")
        return
    end

    XDataCenter.FubenBossSingleManager.ReqChooseLevelType(self.LevelType)
    self:Close()
end