---@class XUiRogueSimTask: XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimTask = XLuaUiManager.Register(XLuaUi, "UiRogueSimTask")

function XUiRogueSimTask:OnAwake()
    self:InitDynamicTable()
    self:RegisterUiEvents()
    self:InitTimes()

    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({XDataCenter.ItemManager.ItemId.RogueSimCoin}, self.PanelSpecialTool, self)
end

function XUiRogueSimTask:OnStart()
    self.TaskGroupId = tonumber(self._Control:GetClientConfig("TaskGroupId"))
end

function XUiRogueSimTask:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateDynamicTable()
end

function XUiRogueSimTask:OnDisable()
    self.Super.OnDisable(self)
end

function XUiRogueSimTask:InitTimes()
    self.EndTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiRogueSimTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiRogueSimTask:UpdateDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiRogueSimTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiRogueSimTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
    end
end

function XUiRogueSimTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiRogueSimTask:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

return XUiRogueSimTask