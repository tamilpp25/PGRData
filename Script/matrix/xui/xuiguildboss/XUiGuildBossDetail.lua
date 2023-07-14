--工会boss自己详细分数页面
local XUiGuildBossTeamList = require("XUi/XUiGuildBoss/Component/XUiGuildBossTeamList")
local XUiGuildBossDetail = XLuaUiManager.Register(XLuaUi, "UiGuildBossDetail")

function XUiGuildBossDetail:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.TeamLow = XUiGuildBossTeamList.New(self.TeamLowObj)
    self.TeamHigh = XUiGuildBossTeamList.New(self.TeamHighObj)
    self.TeamBoss = XUiGuildBossTeamList.New(self.TeamBossObj)
end

function XUiGuildBossDetail:OnStart()
    self.TxtSumScore.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetMyTotalScore())
    self.TxtScoreLow.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetLowScore())
    self.TxtScoreHigh.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetHighScore())
    self.TxtScoreBoss.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetBossScore())
    self.TxtAddSorce.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetAdditionalScore())
    self.TxtAddDis.text = string.format(CS.XTextManager.GetText("GuildBossDeathDis"), XDataCenter.GuildBossManager.GetAdditionalScore())
    self.TxtFinish.gameObject:SetActiveEx(XDataCenter.GuildBossManager.GetCurBossHp() <= 0 and XDataCenter.GuildBossManager.GetMyTotalScore() > 0)

    local lowLevelData = XDataCenter.GuildBossManager.GetLowLevelInfo()
    local highLevelData = XDataCenter.GuildBossManager.GetHighLevelInfo()
    local bossLevelData = XDataCenter.GuildBossManager.GetBossLevelInfo()

    if lowLevelData ~= nil then
        self.TeamLow:Init(lowLevelData.CardIds, lowLevelData.CharacterHeadInfoList, true)
        self.TeamLow.GameObject:SetActiveEx(true)
    else
        self.TeamLow.GameObject:SetActiveEx(false)
    end
    if highLevelData ~= nil then
        self.TeamHigh:Init(highLevelData.CardIds, highLevelData.CharacterHeadInfoList, true)
        self.TeamHigh.GameObject:SetActiveEx(true)
    else
        self.TeamHigh.GameObject:SetActiveEx(false)
    end
    if bossLevelData ~= nil and bossLevelData.CardIds ~= nil then
        self.TeamBoss:Init(bossLevelData.CardIds, bossLevelData.CharacterHeadInfoList, true)
        self.TeamBoss.GameObject:SetActiveEx(true)
    else
        self.TeamBoss.GameObject:SetActiveEx(false)
    end
end

function XUiGuildBossDetail:OnBtnBackClick()
    self:Close()
end

function XUiGuildBossDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
