local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdChooseLevelType = XLuaUiManager.Register(XLuaUi, "UiStrongholdChooseLevelType")

function XUiStrongholdChooseLevelType:OnAwake()
    self:AutoAddListener()
end

function XUiStrongholdChooseLevelType:OnStart(cb)
    self.Cb = cb
    self.BtnNormal:SetName(CsXTextManagerGetText("StrongholdChooseLevelTypeOne"))
    self.BtnHard:SetName(CsXTextManagerGetText("StrongholdChooseLevelTypeTwo"))
end

function XUiStrongholdChooseLevelType:OnEnable()

end

function XUiStrongholdChooseLevelType:OnDisable()

end

function XUiStrongholdChooseLevelType:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnNormal.CallBack = function() self:OnSelectLevelType(XStrongholdConfigs.LevelType.Medium) end
    self.BtnHard.CallBack = function() self:OnSelectLevelType(XStrongholdConfigs.LevelType.High) end
    self.BtnDetailsNormal.CallBack = function() self:OpenTipsUi(XStrongholdConfigs.LevelType.Medium) end
    self.BtnDetailsHard.CallBack = function() self:OpenTipsUi(XStrongholdConfigs.LevelType.High) end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
end

function XUiStrongholdChooseLevelType:OnSelectLevelType(levelType)
    self.LevelType = levelType

    if levelType == XStrongholdConfigs.LevelType.Medium then
        self.BtnNormal:SetButtonState(CS.UiButtonState.Select)
        self.BtnHard:SetButtonState(CS.UiButtonState.Normal)
    elseif levelType == XStrongholdConfigs.LevelType.High then
        self.BtnNormal:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHard:SetButtonState(CS.UiButtonState.Select)
    end
end

function XUiStrongholdChooseLevelType:OpenTipsUi(levelType)
    XLuaUiManager.Open("UiStrongholdRewardTip", levelType)
end

function XUiStrongholdChooseLevelType:OnClickBtnConfirm()
    if not self.LevelType then
        XUiManager.TipText("StrongholdChooseLevelTypeEmpty")
        return
    end

    XDataCenter.StrongholdManager.SelectStrongholdLevelRequest(self.LevelType, self.Cb)
    self:Close()
end