local XUiPlanetPropertyTask = XLuaUiManager.Register(XLuaUi, "UiPlanetPropertyTask")

function XUiPlanetPropertyTask:OnAwake()
    self:AddBtnClickListener()
    self:InitDynamicTable()
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ XDataCenter.ItemManager.ItemId.PlanetRunningShopActivity }, self.PanelSpecialTool)
    self.CurrentTaskGroupId = XDataCenter.PlanetManager.GetViewModel():GetActivityTimeLimitTaskId()
    XDataCenter.PlanetManager.SetSceneActive(false)
end

function XUiPlanetPropertyTask:OnEnable()
    self:RefreshDynamicTable()
end

function XUiPlanetPropertyTask:OnDestroy()
    XDataCenter.PlanetManager.SetSceneActive(true)
end

function XUiPlanetPropertyTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPlanetPropertyTask:RefreshDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.CurrentTaskGroupId)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPlanetPropertyTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDataList[index])
    end
end

--#region 按钮绑定
function XUiPlanetPropertyTask:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end
--endregion

function XUiPlanetPropertyTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:RefreshDynamicTable()
    end
end

function XUiPlanetPropertyTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end