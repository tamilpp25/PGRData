---@class XUiFubenSnowGameTask : XLuaUi
local XUiFubenSnowGameTask = XLuaUiManager.Register(XLuaUi,"UiFubenSnowGameTask")

function XUiFubenSnowGameTask:OnStart()
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.TaskGroupIds = XDataCenter.FubenSpecialTrainManager.GetTaskGroupIds()
    self:RegisterButtonClick()
    self:InitDynamicTable()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiFubenSnowGameTask:OnEnable()
    self:RefreshDynamicTable()
end

function XUiFubenSnowGameTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiFubenSnowGameTask:OnNotify(event,...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshDynamicTable()
    end
end

function XUiFubenSnowGameTask:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiFubenSnowGameTask:RefreshDynamicTable()
    -- 默认取第二个组
    self.DataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[2])
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiFubenSnowGameTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenSnowGameTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DataList[index])
    end
end

return XUiFubenSnowGameTask