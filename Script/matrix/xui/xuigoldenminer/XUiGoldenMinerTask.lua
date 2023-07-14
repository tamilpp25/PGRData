--黄金矿工任务界面
local XUiGoldenMinerTask = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerTask")

function XUiGoldenMinerTask:OnAwake()
    self:InitTabGroup()
    self:InitDynamicTable()
    self:AddListener()
end

function XUiGoldenMinerTask:OnStart()
    self:InitTimes()
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
end

function XUiGoldenMinerTask:OnEnable()
    XUiGoldenMinerTask.Super.OnEnable(self)
    self:UpdateDynamicTable()
    self:UpdateRedPoint()
end

function XUiGoldenMinerTask:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.GoldenMinerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.GoldenMinerManager.HandleActivityEndTime()
        end
    end)
end

function XUiGoldenMinerTask:InitTabGroup()
    self.TabBtns = {}
    self.TaskGroupIdList = XGoldenMinerConfigs.GetTaskGroupIdList()
    for i, id in ipairs(self.TaskGroupIdList) do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            tmpBtn:SetName(XGoldenMinerConfigs.GetTaskName(id))
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiGoldenMinerTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end

function XUiGoldenMinerTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerTask:UpdateDynamicTable()
    local index = self.SelectIndex
    local taskGroupId = self.TaskGroupIdList[index]
    if not taskGroupId then
        return
    end

    self.TaskDataList = XDataCenter.GoldenMinerManager.GetTaskDataList(taskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiGoldenMinerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiGoldenMinerTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiGoldenMinerTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiGoldenMinerTask:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiGoldenMinerTask:UpdateRedPoint()
    for i, goldenMinerTaskId in ipairs(self.TaskGroupIdList) do
        if self.TabBtns[i] then
            local isShowRed = XDataCenter.GoldenMinerManager.CheckTaskCanRewardByGoldenMinerTaskId(goldenMinerTaskId)
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end