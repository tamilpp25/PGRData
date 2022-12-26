-- 虚像地平线排行榜UI
local XUiExpeditionRanking = XLuaUiManager.Register(XLuaUi, "UiExpeditionRank")
local XRankInfo = require("XUi/XUiExpedition/Ranking/XUiExpeditionRankInfo")
function XUiExpeditionRanking:OnAwake()
    XTool.InitUiObject(self)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.RankInfo = XRankInfo.New(self.PanelRankInfo, self)
    self:SetResetTimer()
    self:RegisterButtonEvent()
end

function XUiExpeditionRanking:OnStart()
    XDataCenter.ExpeditionManager.GetRankingData()
end

function XUiExpeditionRanking:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET, XEventId.EVENT_EXPEDITION_RANKING_REFRESH }
end

function XUiExpeditionRanking:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        self:OnActivityReset()
    elseif evt == XEventId.EVENT_EXPEDITION_RANKING_REFRESH then
        self.RankInfo:RefreshRankData()
    end
end

function XUiExpeditionRanking:OnDisable()
    self:StopTimer()
end

function XUiExpeditionRanking:OnDestroy()
    self:StopTimer()
end

function XUiExpeditionRanking:SetResetTimer()
    self:StopTimer()
    self:SetResetTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
            self:SetResetTime()
        end, XScheduleManager.SECOND, 0)
end

function XUiExpeditionRanking:SetResetTime()
    local endTimeSecond = XDataCenter.ExpeditionManager.GetResetTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    self.RankInfo:RefreshCountDown(XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    if leftTime <= 0 then
        self:OnActivityReset()
    end
end

function XUiExpeditionRanking:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiExpeditionRanking:OnActivityReset()
    self:StopTimer()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
end

function XUiExpeditionRanking:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "ExpeditionMainHelp")
end

function XUiExpeditionRanking:OnBtnBackClick()
    self:Close()
end

function XUiExpeditionRanking:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end