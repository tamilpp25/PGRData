local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelWheelchairManualGuide: XUiNode
---@field _Control XWheelchairManualControl
local XUiPanelWheelchairManualGuide = XClass(XUiNode, 'XUiPanelWheelchairManualGuide')
local XUiGridWheelchairManualGuide = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualGuide/XUiGridWheelchairManualGuide')

local GridShowAnimationInterval = 0.1

function XUiPanelWheelchairManualGuide:OnStart()
    self.GridChallenge.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.ListChallenge)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridWheelchairManualGuide, self)
    GridShowAnimationInterval = XMVCA.XWheelchairManual:GetWheelchairManualConfigNum('GuideGridFadeInAnimInterval')

    XMVCA.XWheelchairManual:SetSubActivityIsOld(XEnumConst.WheelchairManual.ReddotKey.GuideNew)
end

function XUiPanelWheelchairManualGuide:OnEnable()
    self:RefreshTable()
    self:StartActivityTimeRefreshTimer()
    XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_GUIDE_ACTIVITY_UPDATE, self.RefreshTableIgnoreAnimation, self)
    XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_ACTIVITY_UPDATE, self.RefreshTableIgnoreAnimation, self)
end

function XUiPanelWheelchairManualGuide:OnDisable()
    self.DynamicTable:RecycleAllTableGrid()
    self:StopActivityTimeRefreshTimer()
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_GUIDE_ACTIVITY_UPDATE, self.RefreshTableIgnoreAnimation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_ACTIVITY_UPDATE, self.RefreshTableIgnoreAnimation, self)
end

function XUiPanelWheelchairManualGuide:RefreshTableIgnoreAnimation()
    self:RefreshTable(true)
end

function XUiPanelWheelchairManualGuide:RefreshTable(ignorePlayAnimation)
    local activityDataList = self._Control:GetCurActivityGuideActivityList()
    self._IgnorePlayAnimation = ignorePlayAnimation
    if activityDataList ~= nil then
        self.IsReloadTable = true
        self.DynamicTable:SetDataSource(activityDataList)
        self.DynamicTable:ReloadDataSync()
    end
    
    self.PaneNothing.gameObject:SetActiveEx(XTool.GetTableCount(activityDataList) <= 0)
end

function XUiPanelWheelchairManualGuide:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:Refresh(self.DynamicTable.DataSource[index])
        if self.IsReloadTable then
            if self._IgnorePlayAnimation then
                grid:SetRootCanvasGroupAlpha(1)
            else
                grid:SetRootCanvasGroupAlpha(0)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:SetRootCanvasGroupAlpha(1)
        grid:Close()    
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self._IgnorePlayAnimation then
            self._IgnorePlayAnimation = false
            self.IsReloadTable = false
            return
        end
        
        local grids = self.DynamicTable:GetGrids()
        
        self.GridIndex = 1
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item:PlayAnimation('GridChallengeEnable')
            end
            self.GridIndex = self.GridIndex + 1
        end, GridShowAnimationInterval * XScheduleManager.SECOND, #grids, 0)
        self.IsReloadTable = false
    end
end

--region Activity Timer Refresh
function XUiPanelWheelchairManualGuide:StopActivityTimeRefreshTimer()
    if self._ActivitiesTimeRefreshTimerId then
        XScheduleManager.UnSchedule(self._ActivitiesTimeRefreshTimerId)
        self._ActivitiesTimeRefreshTimerId = nil
    end
end

function XUiPanelWheelchairManualGuide:StartActivityTimeRefreshTimer()
    self:StopActivityTimeRefreshTimer()

    self._ActivitiesTimeRefreshTimerId = XScheduleManager.ScheduleForever(handler(self, self.RefreshActivitiesTime), XScheduleManager.SECOND)
end

function XUiPanelWheelchairManualGuide:RefreshActivitiesTime()
    local grids = self.DynamicTable:GetGrids()

    if not XTool.IsTableEmpty(grids) then
        for i, v in pairs(grids) do
            v:RefreshTime()
        end
    end
end
--endregion

return XUiPanelWheelchairManualGuide