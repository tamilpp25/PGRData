local XUiFubenBabelTowerRank = XLuaUiManager.Register(XLuaUi, "UiFubenBabelTowerRank")
local XUiBabelTowerRankInfo = require("XUi/XUiFubenBabelTower/XUiBabelTowerRankInfo")


function XUiFubenBabelTowerRank:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "BabelTowerRank")
    self.BabelTowerRankInfo = XUiBabelTowerRankInfo.New(self.PanelBossRankInfo, self)
    self.ActivityType = nil
    -- XEventManager.AddEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiFubenBabelTowerRank:OnDestroy()
    self:StopCounter()
    -- XEventManager.RemoveEventListener(XEventId.EVENT_BABEL_ACTIVITY_STATUS_CHANGED, self.CheckActivityStatus, self)
end

function XUiFubenBabelTowerRank:OnStart(activityType)
    self.ActivityType = activityType
    self.BabelTowerRankInfo:SetActivityType(activityType)
    self.BabelTowerRankInfo:Refresh()
    self:StartCounter()
    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(activityType)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(activityType)
        end
    end)
end

function XUiFubenBabelTowerRank:OnEnable()
    XUiFubenBabelTowerRank.Super.OnEnable(self)
    self:CheckActivityStatus()
end

function XUiFubenBabelTowerRank:CheckActivityStatus()
    if not XLuaUiManager.IsUiShow("UiFubenBabelTowerRank") then
        return
    end
    XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(self.ActivityType)
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
    -- local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    -- if not curActivityNo then
    --     return
    -- end
    -- local activityTemplate = XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(curActivityNo)
    -- if not activityTemplate then
    --     return
    -- end

    local endTime = XDataCenter.FubenBabelTowerManager.GetEndTime(self.ActivityType) --XFunctionManager.GetEndTimeByTimeId(activityTemplate.ActivityTimeId)
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