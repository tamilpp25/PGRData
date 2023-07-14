local XUiDoomsdayFubenMainGameMovie = XLuaUiManager.Register(XLuaUi, "UiDoomsdayFubenMainGameMovie")

function XUiDoomsdayFubenMainGameMovie:OnStart(stageId, battleLose)
    local stageData = XDataCenter.DoomsdayManager.GetStageData(stageId)

    if battleLose then
        self.TxtTitle.text = CsXTextManagerGetText("DoomsdayLoseTitle")
        self.TxtContent.text = XDoomsdayConfigs.LOSE_REASON_TEXT[stageData:GetLoseReason()]
    else
        local cur = stageData:GetProperty("_Day")
        self.TxtTitle.text = CsXTextManagerGetText("DoomsdayThemeTitle", stageData:GetProperty("_Day"))
        self.TxtContent.text = CsXTextManagerGetText("DoomsdayThemeContent", stageData:GetProperty("_LeftDay"))
    end
end

function XUiDoomsdayFubenMainGameMovie:OnEnable()
    self:PlayAnimation("ThemeEnable")
end
