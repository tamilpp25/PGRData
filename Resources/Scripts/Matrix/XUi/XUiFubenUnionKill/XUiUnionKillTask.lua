local XUiUnionKillTask = XLuaUiManager.Register(XLuaUi, "UiUnionKillTask")

function XUiUnionKillTask:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self,self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.gameObject)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshUnionKillTasks, self)
end

function XUiUnionKillTask:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.RefreshUnionKillTasks, self)
end

function XUiUnionKillTask:OnStart()
    self:RefreshUnionKillTasks()
end

function XUiUnionKillTask:RefreshUnionKillTasks()
    local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
    if not unionInfo then return end

    local activityId = unionInfo.Id
    if activityId == nil or activityId == 0 then return end
    self.CurrentUnionActivityConfig = XFubenUnionKillConfigs.GetUnionActivityConfigById(activityId)
    self.CurrentUnionActivityTemplate = XFubenUnionKillConfigs.GetUnionActivityById(activityId)

    local tasklimitedIds = self.CurrentUnionActivityTemplate.TaskLimitId

    self.UnionKillTasks = {}
    for _, tasklimitedId in pairs(tasklimitedIds or {}) do
        local tasks = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(tasklimitedId)
        for _, task in pairs(tasks or {}) do
            table.insert(self.UnionKillTasks, task)
        end
    end

    self.DynamicTable:SetDataSource(self.UnionKillTasks)
    self.DynamicTable:ReloadDataASync()
end

--动态列表事件
function XUiUnionKillTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.UnionKillTasks[index]
        if not data then
            return
        end
        grid.RootUi = self
        grid:ResetData(data)
    end
end

function XUiUnionKillTask:OnBtnBackClick()
    self:Close()
end

function XUiUnionKillTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
