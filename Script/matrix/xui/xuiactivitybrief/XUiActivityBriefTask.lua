local XDynamicActivityTask = require("XUi/XUiTask/XDynamicActivityTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiActivityBriefTask = XLuaUiManager.Register(XLuaUi, "UiActivityBriefTask")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiActivityBriefTask:OnAwake()
    self.GridTask.gameObject:SetActiveEx(false)
    self.BtnBack.CallBack = function()
        self:Close()
        if self.CloseCb then self.CloseCb() end
    end
    self.BtnActDesc.CallBack = function()
        self:OnBtnActDescClick()
    end
    self:InitDynamicTable()
end

function XUiActivityBriefTask:OnStart(closeCb, base)
    self.CloseCb = closeCb
    self.Base = base
    self:InitLeftTime()
    self:InitActivityPointIcon()
    self:SetTaskBg()
end

function XUiActivityBriefTask:OnEnable()
    if self.Base then
        self.Base.BasePane.gameObject:SetActiveEx(false)
    end
    self:UpdateDynamicTable()
    self:UpdateActivityPointCount()
end

function XUiActivityBriefTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiActivityBriefTask:OnNotify(evt)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
    end
end

function XUiActivityBriefTask:InitLeftTime()
    if not XDataCenter.ActivityBriefManager.IsActivityTaskInTime() then
        self.TxtTime.gameObject:SetActiveEx(false)
    else
        local nowTime = XTime.GetServerNowTimestamp()
        local _, taskEndTime = XDataCenter.ActivityBriefManager.GetActivityTaskTime()
        local timeStr = XUiHelper.GetTime(taskEndTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = CSXTextManagerGetText("ActivityBriefTaskLeftTime", timeStr)
        self.TxtTime.gameObject:SetActiveEx(true)
    end
end

function XUiActivityBriefTask:InitActivityPointIcon()
    local pointId = XDataCenter.ActivityBriefManager.GetActivityActivityPointId()
    local point = XUiGridCommon.New(self, self.UseItemGrid)
    point:Refresh(pointId)
end

function XUiActivityBriefTask:SetTaskBg()
    self.TaskBg = XDataCenter.ActivityBriefManager.GetActivityTaskBg()
    self.TaskVipBg = XDataCenter.ActivityBriefManager.GetActivityTaskVipBg()
    self.TaskGotBg = XDataCenter.ActivityBriefManager.GetActivityTaskGotBg()
    self.TaskVipGotBg = XDataCenter.ActivityBriefManager.GetActivityTaskVipGotBg()
end

function XUiActivityBriefTask:UpdateActivityPointCount()
    local pointId = XDataCenter.ActivityBriefManager.GetActivityActivityPointId()
    self.TxtNumber.text = XDataCenter.ItemManager.GetCount(pointId)
end

function XUiActivityBriefTask:OnBtnActDescClick()
    XUiManager.UiFubenDialogTip(CSXTextManagerGetText("ActivityBriefTaskMissionInfo"), CSXTextManagerGetText("ActivityBriefTaskDesc") or "")
end

function XUiActivityBriefTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicActivityTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiActivityBriefTask:UpdateDynamicTable()
    local taskDatas = XDataCenter.ActivityBriefManager.GetActivityTaskDatas()
    local pointId = XDataCenter.ActivityBriefManager.GetActivityActivityPointId()
    if not next(taskDatas) then
        XUiManager.TipText("ActivityBriefNoTask")
        return
    end
    self.TaskDatas = {}

    for _, data in pairs(taskDatas) do
        local tmpData = {}
        for k, v in pairs(data) do
            tmpData[k] = v
            if k == "Id" then
                if XDataCenter.ActivityBriefManager.CheckTaskIsInMark(v) then
                    tmpData["IsMark"] = true
                else
                    tmpData["IsMark"] = false
                end
            end
        end
        tmpData["PointId"] = pointId
        table.insert(self.TaskDatas, tmpData)
    end
    self.DynamicTable:SetDataSource(self.TaskDatas)
    self.DynamicTable:ReloadDataASync()
end

function XUiActivityBriefTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.TaskDatas[index]
        grid:ResetData(data, self)
    end
end