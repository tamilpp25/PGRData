local XUiDoomsdayTask = XLuaUiManager.Register(XLuaUi, "UiDoomsdayTask")

function XUiDoomsdayTask:OnAwake()
    self.AssetPanel =
        XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )

    self.GridTask.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)

    self:InitTabGroup()
    self:AutoAddListener()
end

function XUiDoomsdayTask:OnStart()
    self.SelectIndex = 1
end

function XUiDoomsdayTask:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.DoomsdayManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self.PanellTabBtns:SelectIndex(self.SelectIndex)
end

function XUiDoomsdayTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_DOOMSDAY_ACTIVITY_END
    }
end

function XUiDoomsdayTask:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateTasks()
    elseif evt == XEventId.EVENT_DOOMSDAY_ACTIVITY_END then
        if XDataCenter.DoomsdayManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiDoomsdayTask:InitTabGroup()
    local btns = {
        self.BtnTask,
        self.BtnTaskDiary
    }

    self.PanellTabBtns:Init(
        btns,
        function(index)
            self:OnSelectTaskType(index)
        end
    )
    self.Btns = btns
end

function XUiDoomsdayTask:AutoAddListener()
    self:BindExitBtns()
end

function XUiDoomsdayTask:OnSelectTaskType(index)
    self.SelectIndex = index
    self:UpdateTasks()

    self:PlayAnimation("TaskStoryQieHuan")
end

function XUiDoomsdayTask:UpdateTasks()
    self.TaskList = XDataCenter.DoomsdayManager.GetGroupTasksByIndex(self.SelectIndex)

    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()

    for index, btn in pairs(self.Btns) do
        btn:ShowReddot(XDataCenter.DoomsdayManager.CheckTaskRewardToGet(index))
    end

    local isEmpty = XTool.IsTableEmpty(self.TaskList)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(isEmpty)
    self.PanelTaskStoryList.gameObject:SetActiveEx(not isEmpty)
end

function XUiDoomsdayTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskList[index])
    end
end

return XUiDoomsdayTask
