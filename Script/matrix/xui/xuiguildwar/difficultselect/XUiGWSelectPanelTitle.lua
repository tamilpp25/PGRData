--难度选择界面标题面板
local XUiGWSelectPanelTitle = XClass(nil, "XUiGWSelectPanelTitle")

function XUiGWSelectPanelTitle:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    self:InitPanel()
end

function XUiGWSelectPanelTitle:InitPanel()
    self.TxtTitleName.text = XDataCenter.GuildWarManager.GetName()
    if self.TxtPreActive then
        local preRound = XDataCenter.GuildWarManager.GetPreRound()
        if preRound then
            self.TxtPreActive.text = XUiHelper.GetText("GuildWarSelectDifficultyPreTotalActive", preRound:GetTotalActivation())
        else
            self.TxtPreActive.text = ""
        end
    end
    self:ShowRemainTime()
end

function XUiGWSelectPanelTitle:ShowRemainTime()
    local textId
    if XDataCenter.GuildWarManager.CheckRoundIsInTime() then
        textId = "GuildWarRoundLeftTime"
    else
        textId = "GuildWarRoundLeftTime2" 
    end
    local remainTime = XDataCenter.GuildWarManager.GetRoundLeftTime()
    if remainTime <= 0 and XDataCenter.GuildWarManager.IsLastRound() then
        remainTime = XDataCenter.GuildWarManager.GetActivityLeftTime()
        textId = "GuildWarRoundLeftTime3"
    end
    
    self.TxtTime.text = XUiHelper.GetText(
        textId,
        XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    )
end

function XUiGWSelectPanelTitle:StartTimeCount()
    if self.TimeCountId then return end
    self:ShowRemainTime()
    self.TimeCountId = XScheduleManager.ScheduleForever(function()
            self:ShowRemainTime()
        end, 1000)
end

function XUiGWSelectPanelTitle:EndTimeCount()
    if not self.TimeCountId then return end
    XScheduleManager.UnSchedule(self.TimeCountId)
    self.TimeCountId = nil
end

return XUiGWSelectPanelTitle