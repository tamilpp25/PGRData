local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
local XUiPanelActivityCalendar = require("XUi/XUiNewActivityCalendar/XUiPanelActivityCalendar")
local XUiPanelEditCalendar = require("XUi/XUiNewActivityCalendar/XUiPanelEditCalendar")

local InterfaceType = {
    Normal = 0,
    Activity = 1,
    Edit = 2,
}

---@class XUiMainLeftCalendar : XUiMainPanelBase
---@field _Control XNewActivityCalendarControl
---@field Parent XUiMain
---@field PanelActivityCalendar XUiPanelActivityCalendar
---@field PanelEditCalendar XUiPanelEditCalendar
local XUiMainLeftCalendar = XClass(XUiMainPanelBase, "XUiMainLeftCalendar")

function XUiMainLeftCalendar:OnStart()
    self.PanelActivity.gameObject.SetActiveEx(false)
    self.PanelEdit.gameObject.SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.CurInterface = InterfaceType.Normal
end

function XUiMainLeftCalendar:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.UpdateActivityCalender, self)
    -- 刷新信息
    self:OpenActivityCalendar()

    ---@type XNewActivityCalendarAgency
    local calendarAgency = XMVCA:GetAgency(ModuleId.XNewActivityCalendar)
    calendarAgency:SaveIsDailyFirstLogin()
    calendarAgency:SaveIsPlayEffect(false)
    calendarAgency:SaveLocalActivityIds()
    if self._Control:CheckIsShowWeekEntrance() then
        calendarAgency:SaveLocalWeekEndTime()
    end
end

function XUiMainLeftCalendar:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE, self.UpdateActivityCalender, self)
end

function XUiMainLeftCalendar:UpdateActivityCalender()
    -- 刷新信息
    if self.CurInterface == InterfaceType.Activity then
        if XMain.IsEditorDebug then
            XLog.Debug("Refresh ActivityCalender Grid By Event")
        end
        self.PanelActivityCalendar:Refresh()
    end
end

function XUiMainLeftCalendar:OpenActivityCalendar()
    self:CloseEditCalendar()
    if not self.PanelActivityCalendar then
        self.PanelActivityCalendar = XUiPanelActivityCalendar.New(self.PanelActivity, self)
    end
    self.PanelActivityCalendar:Open()
    self.PanelActivityCalendar:Refresh(true)
    self.CurInterface = InterfaceType.Activity
end

function XUiMainLeftCalendar:CloseActivityCalendar()
    if self.PanelActivityCalendar then
        self.PanelActivityCalendar:Close()
    end
end

function XUiMainLeftCalendar:OpenEditCalendar()
    self:CloseActivityCalendar()
    if not self.PanelEditCalendar then
        self.PanelEditCalendar = XUiPanelEditCalendar.New(self.PanelEdit, self)
    end
    self.PanelEditCalendar:Open()
    self.PanelEditCalendar:Refresh()
    self.CurInterface = InterfaceType.Edit
end

function XUiMainLeftCalendar:CloseEditCalendar()
    if self.PanelEditCalendar then
        self.PanelEditCalendar:Close()
    end
end

function XUiMainLeftCalendar:OnBtnCloseClick()
    if self.CurInterface == InterfaceType.Activity then
        self.CurInterface = InterfaceType.Normal
        if self.Parent.OnShowMain then
            self.Parent:OnShowMain(true)
        end
    end
    if self.CurInterface == InterfaceType.Edit then
        local closeCallBack = function()
            self:OpenActivityCalendar()
        end
        local sureCallBack = function()
            self.PanelEditCalendar:SaveEditDataList()
            self:OpenActivityCalendar()
        end
        if self.PanelEditCalendar:GetIsEdited() then
            local title = self._Control:GetClientConfig("CalendarEditCloseTitle")
            local content = self._Control:GetClientConfig("CalendarEditCloseContent")
            XUiManager.DialogTip(title, content, nil, closeCallBack, sureCallBack)
        else
            closeCallBack()
        end
    end
end

return XUiMainLeftCalendar