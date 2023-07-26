local XUiDoomsdayFubenMainGameMovie = XLuaUiManager.Register(XLuaUi, "UiDoomsdayFubenMainGameMovie")

function XUiDoomsdayFubenMainGameMovie:OnStart(stageId, isFinishEnd)
    local stageData = XDataCenter.DoomsdayManager.GetStageData(stageId)

    if isFinishEnd then
        self.TxtTitle.text = CsXTextManagerGetText("DoomsdayFinishEndTitle")
        self.TxtContent.text = stageData:GetEndingDesc()
    else
        self.TxtTitle.text = CsXTextManagerGetText("DoomsdayThemeTitle", stageData:GetProperty("_Day"))
        self.TxtContent.text = CsXTextManagerGetText("DoomsDayTodayWeatherTips", XDoomsdayConfigs.WeatherConfig:GetProperty(stageData:GetProperty("_CurWeatherId"), "Name"))
    end
end

function XUiDoomsdayFubenMainGameMovie:OnEnable()
    self:PlayAnimation("ThemeEnable")
end
