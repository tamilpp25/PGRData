--异构阵线2.0任务界面
local XUiMaverick2Task = XLuaUiManager.Register(XLuaUi, "UiMaverick2Task")

function XUiMaverick2Task:OnAwake()
    self:InitDynamicTable()
    self:RegisterEvent()
    self:InitTimes()
    self:InitAssetPanel()

    local taskGroupIdList = XMaverick2Configs.GetTaskGroupIds()
    self.TaskGroupId = taskGroupIdList[1]
end

function XUiMaverick2Task:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateAssetPanel()
    self:UpdateDynamicTable()
    self:RefreshTime()
end

function XUiMaverick2Task:OnDisable()
    self.Super.OnDisable(self)
end

function XUiMaverick2Task:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTime()
        end
    end)
end

function XUiMaverick2Task:RefreshTime()
    local endTime = XDataCenter.Maverick2Manager.GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local remainTime = endTime >= nowTime and (endTime - nowTime) or 0
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiMaverick2Task:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiMaverick2Task:UpdateDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiMaverick2Task:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiMaverick2Task:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
    end
end

function XUiMaverick2Task:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiMaverick2Task:RegisterEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiMaverick2Task:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.Maverick2Coin,
            XDataCenter.ItemManager.ItemId.Maverick2Unit,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiMaverick2Task:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.Maverick2Coin,
            XDataCenter.ItemManager.ItemId.Maverick2Unit,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------