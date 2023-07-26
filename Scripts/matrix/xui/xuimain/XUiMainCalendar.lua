local XUiGridNewCalendarItem = require("XUi/XUiNewActivityCalendar/XUiGridNewCalendarItem")
local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiMainCalendar : XUiMainPanelBase
local XUiMainCalendar = XClass(XUiMainPanelBase, "XUiMainCalendar")

---@param rootUi XUiMain
function XUiMainCalendar:OnStart(rootUi)
    self.RootUi = rootUi
    -- XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.IsShow = false
    self:InitDynamicTable()
end

function XUiMainCalendar:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.UpdateActivityCalender, self)
    if not self.IsShow then
        return
    end
    self.RootUi:SetSignPanelEnable(false)
    XDataCenter.NewActivityCalendarManager.NewActivityCalendarGetDataRequest(function()
        self:SetupDynamicTable()
        self:StartTimer()
    end)
end

function XUiMainCalendar:Show()
    --self.GameObject:SetActiveEx(true)
    self.IsShow = true
    
    self:SetGridHasPlayAnim(false)
    self:SetupDynamicTable()
    self:StartTimer()
    
    XDataCenter.NewActivityCalendarManager.SaveIsDailyFirstLogin()
    XDataCenter.NewActivityCalendarManager.SaveIsPlayEffect(false)
    XDataCenter.NewActivityCalendarManager.SaveLoaclActivityIds()
end

-- 重点活动
local IsmajorSort = function(a, b)
    local ismajorA = a:CheckIsMajorActivity()
    local ismajorB = b:CheckIsMajorActivity()
    if ismajorA ~= ismajorB then
        return true, ismajorA
    end
    return false
end
local StartTimeSort = function(a, b)
    local startTimeA = a:GetStartTime()
    local startTimeB = b:GetStartTime()
    return startTimeA < startTimeB
end
local EndTimeSort = function(a, b)
    local endTimeA = a:GetEndTime()
    local endTimeB = b:GetEndTime()
    return endTimeA < endTimeB
end
-- 活动开启状态
local InTimeSort = function(a, b)
    local inTimeA = a:CheckInActivity()
    local inTimeB = b:CheckInActivity()
    if inTimeA ~= inTimeB then
        return true, inTimeA
    end
    if inTimeA then
        return false
    else
        return true, StartTimeSort(a, b)
    end
end
-- 核心奖励领取状态 (活动中)
local ReveiveSort = function(a, b)
    local reveiveA = XDataCenter.NewActivityCalendarManager.CheckNotReceiveMainTemplate(a:GetActivityId())
    local reveiveB = XDataCenter.NewActivityCalendarManager.CheckNotReceiveMainTemplate(b:GetActivityId())
    if reveiveA ~= reveiveB then
        return true, reveiveA
    end
    return false
end

function XUiMainCalendar:GetCalendarActivityData()
    local activityInfo = XDataCenter.NewActivityCalendarManager.GetCalenderActivityInfo()
    table.sort(activityInfo, function(a, b)
        local isSort, sortResult = InTimeSort(a, b)
        if isSort then
            return sortResult
        end
        isSort, sortResult = ReveiveSort(a, b)
        if isSort then
            return sortResult
        end
        isSort, sortResult = IsmajorSort(a, b)
        if isSort then
            return sortResult
        end
        return EndTimeSort(a, b)
    end)
    return activityInfo
end

function XUiMainCalendar:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridNewCalendarItem, self.RootUi)
    self.DynamicTable:SetDelegate(self)
end

function XUiMainCalendar:SetupDynamicTable()
    self.DataList = self:GetCalendarActivityData()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridNewCalendarItem
function XUiMainCalendar:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateTheme(self.ThemeData)
        grid:Refresh(self.DataList[index], index, self.DynamicTable:GetFirstUseGridIndexAndUseCount())
    end
end

function XUiMainCalendar:SetGridHasPlayAnim(value)
    ---@type XUiGridNewCalendarItem[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids or {}) do
        grid:SetHasPlay(value)
    end
end

function XUiMainCalendar:UpdateActivityCalender()
    if not self.IsShow then
        return
    end
    self:SetupDynamicTable()
end

function XUiMainCalendar:CheckIsShow()
    return self.IsShow
end

function XUiMainCalendar:OnBtnCloseClick()
    --self.GameObject:SetActiveEx(false)
    self.IsShow = false
    self:StopTimer()
    self.RootUi:OnHideCalendar()
end

function XUiMainCalendar:OnDisable()
    self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.UpdateActivityCalender, self)
end

function XUiMainCalendar:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiMainCalendar:UpdateTimer()
    if XTool.UObjIsNil(self.GameObject) then
        self:StopTimer()
        return
    end
    ---@type XUiGridNewCalendarItem[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids or {}) do
        grid:RefreshTimer()
    end
end

function XUiMainCalendar:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiMainCalendar