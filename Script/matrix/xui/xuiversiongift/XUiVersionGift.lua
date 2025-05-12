---@class XUiVersionGift: XLuaUi
---@field _Control XVersionGiftControl
local XUiVersionGift = XLuaUiManager.Register(XLuaUi, 'UiVersionGift')

function XUiVersionGift:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
end

function XUiVersionGift:OnStart()
    self._PanelVersionGiftGet = require('XUi/XUiVersionGift/XUiPanelVersionRewardGet').New(self.PanelVersionRewardGet, self)
    self._PanelVersionGiftGet:Close()
end

function XUiVersionGift:OnEnable()
    self:RefreshAll()
    self:StartLeftTimer()
end

function XUiVersionGift:OnDisable()
    self:StopLeftTimer()
    self:UnScheduleProgressRewardShow()
end

--region 界面刷新
function XUiVersionGift:RefreshAll()
    self:RefreshDailyRewardShow()
    self:RefreshVersionRewardShow()
    self:RefreshProgressRewardShow()
    self:RefreshTaskShow()
end

function XUiVersionGift:RefreshDailyRewardShow()
    if not self._DailyReward then
        self._DailyReward = require('XUi/XUiVersionGift/XUiGridVersionGiftDailyReward').New(self.GridDailyReward, self)
        self._DailyReward:Open()
    end
    
    self._DailyReward:Refresh()
end

function XUiVersionGift:RefreshVersionRewardShow()
    if not self._VersionReward then
        self._VersionReward = require('XUi/XUiVersionGift/XUiGridVersionGiftVersionReward').New(self.VersionReward, self)
        self._VersionReward:Open()
    end
    
    self._VersionReward:Refresh()
end

function XUiVersionGift:RefreshProgressRewardShow()
    local noTween = false
    
    if not self._PanelProgressReward then
        self._PanelProgressReward = require('XUi/XUiVersionGift/XUiPanelProgressReward').New(self.PanelBottom, self)
        self._PanelProgressReward:Open()
        noTween = true
    end

    if noTween then
        self:UnScheduleProgressRewardShow()
        
        self._ProgressRewardFirstRefreshTimeId = XScheduleManager.ScheduleNextFrame(function()
            self._PanelProgressReward:Refresh(noTween)
        end)
        
    else
        self._PanelProgressReward:Refresh()
    end
end

function XUiVersionGift:RefreshTaskShow()
    if not self._PanelTask then
        self._PanelTask = require('XUi/XUiVersionGift/XUiPanelVersionGiftTask').New(self.PanelRight, self)
        self._PanelTask:Open()
    end
end
--endregion

function XUiVersionGift:OpenPanelVersionGiftGet()
    self._PanelVersionGiftGet:Open()
end

function XUiVersionGift:ClosePanelVersionGiftGet()
    self._PanelVersionGiftGet:Close()
    self._VersionReward:Refresh()
end

function XUiVersionGift:UnScheduleProgressRewardShow()
    if self._ProgressRewardFirstRefreshTimeId then
        XScheduleManager.UnSchedule(self._ProgressRewardFirstRefreshTimeId)
        self._ProgressRewardFirstRefreshTimeId = nil
    end
end

--region 时间显示定时器
function XUiVersionGift:StopLeftTimer()
    if self._LeftTimeTimeId then
        XScheduleManager.UnSchedule(self._LeftTimeTimeId)
        self._LeftTimeTimeId = nil
    end
end

function XUiVersionGift:StartLeftTimer()
    self:StopLeftTimer()
    self.TxtTime.gameObject:SetActiveEx(true)
    self._LeftTimeTimeId = XScheduleManager.ScheduleForever(handler(self, self.UpdateLeftTimeShow), XScheduleManager.SECOND)
    self:UpdateLeftTimeShow()
end

function XUiVersionGift:UpdateLeftTimeShow()
    local now = XTime.GetServerNowTimestamp()
    local timeId = self._Control:GetActivityTimeId()

    if XTool.IsNumberValid(timeId) then
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)

        if endTime <= 0 then
            self.TxtTime.gameObject:SetActiveEx(false)
            self:StopLeftTimer()
        else
            local leftTime = math.max(0, endTime - now)
            local leftTimeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            self.TxtTime.text = XUiHelper.GetText('VersionGiftLeftTime', leftTimeStr)
        end
    else
        self.TxtTime.gameObject:SetActiveEx(false)
        self:StopLeftTimer()
    end
end
--endregion

return XUiVersionGift