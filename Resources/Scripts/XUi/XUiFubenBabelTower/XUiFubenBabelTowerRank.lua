local XUiFubenBabelTowerRank = XLuaUiManager.Register(XLuaUi, "UiFubenBabelTowerRank")
local XUiBabelTowerRankInfo = require("XUi/XUiFubenBabelTower/XUiBabelTowerRankInfo")


function XUiFubenBabelTowerRank:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "BabelTowerRank")
    self.BabelTowerRankInfo = XUiBabelTowerRankInfo.New(self.PanelBossRankInfo, self)

    XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiFubenBabelTowerRank:OnDestroy()
    self:StopCounter()
    XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiFubenBabelTowerRank:OnStart()
    self.BabelTowerRankInfo:Refresh()
    self:StartCounter()
end

function XUiFubenBabelTowerRank:OnEnable()
    self:CheckActivityStatus()
end

function XUiFubenBabelTowerRank:CheckActivityStatus()
    if not XLuaUiManager.IsUiShow("UiFubenBabelTowerRank") then
        return
    end
    local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    if not curActivityNo or not XDataCenter.FubenBabelTowerManager.IsInActivityTime(curActivityNo) then
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerNoneOpen"))
        XLuaUiManager.RunMain()
    end
end

function XUiFubenBabelTowerRank:OnBtnBackClick()
    self:Close()
end

function XUiFubenBabelTowerRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenBabelTowerRank:StartCounter()
    self:StopCounter()

    local time = XTime.GetServerNowTimestamp()
    local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    if not curActivityNo then
        return
    end
    local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(curActivityNo)
    if not activityTemplate then
        return
    end

    local endTime = XFunctionManager.GetEndTimeByTimeId(activityTemplate.ActivityTimeId)
    if not endTime then
        return
    end
    local leftTimeDesc = CS.XTextManager.GetText("BabelTowerRankReset")
    self.BabelTowerRankInfo:UpdateCurTime(string.format(leftTimeDesc, XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)))
    self.Timer = XScheduleManager.ScheduleForever(
    function()
        time = XTime.GetServerNowTimestamp()
        if time > endTime then
            self:StopCountDown()
            return
        end
        self.BabelTowerRankInfo:UpdateCurTime(string.format(leftTimeDesc, XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)))
    end,
    XScheduleManager.SECOND,
    0
    )

end

function XUiFubenBabelTowerRank:StopCounter()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end