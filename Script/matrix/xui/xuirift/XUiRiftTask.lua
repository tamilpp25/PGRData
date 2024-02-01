--大秘境任务界面
local XUiRiftTask = XLuaUiManager.Register(XLuaUi, "UiRiftTask")

local SeasonTaskTabIdx = 3

function XUiRiftTask:OnAwake()
    self:InitTabGroup()
    self:InitDynamicTable()
    self:RegisterEvent()
    self:InitTimes()

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin)
    self.AssetPanel:HideBtnBuy()
end

function XUiRiftTask:OnEnable()
    self.Super.OnEnable(self)
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
    self:UpdateRedPoint()
end

function XUiRiftTask:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiRiftTask:InitTabGroup()
    self.TabBtns = {}
    self.TaskGroupIdList = XDataCenter.RiftManager.GetTaskGroupIdList()
    self.SeasonTaskGroupId = XDataCenter.RiftManager.GetSeasonTaskGroupId()
    local taskCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTask)
    for i = 1, 3 do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            tmpBtn:SetName(taskCfgs[i].Name)
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiRiftTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiRiftTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
end

function XUiRiftTask:UpdateDynamicTable()
    local index = self.SelectIndex
    self.TaskDataList = {}
    if index == SeasonTaskTabIdx then
        self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.SeasonTaskGroupId)
        appendArray(self.TaskDataList, XDataCenter.TaskManager.GetRiftTaskList())
        table.sort(self.TaskDataList, self.SortTask)
    else
        self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIdList[index])
    end
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiRiftTask.SortTask(a, b)
    local aState = XUiRiftTask.GetTaskStateSort(a)
    local bState = XUiRiftTask.GetTaskStateSort(b)
    if aState ~= bState then
        return aState < bState
    end

    local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
    local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
    return templatesTaskA.Priority > templatesTaskB.Priority
end

--可领取>未完成>未解锁>已完成
function XUiRiftTask.GetTaskStateSort(task)
    local taskSeason = XDataCenter.RiftManager:GetTaskSeason(task.Id)
    local isUnlock = XDataCenter.RiftManager:CheckSeasonOpen(taskSeason)
    if not isUnlock then
        return 3 + taskSeason -- 按赛季索引排序
    elseif task.State == XDataCenter.TaskManager.TaskState.Achieved then
        return 1
    elseif task.State == XDataCenter.TaskManager.TaskState.Active then
        return 2
    else
        return 99
    end
end

---@param grid XDynamicGridTask
function XUiRiftTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
        if self.SelectIndex == SeasonTaskTabIdx then
            local taskSeason = XDataCenter.RiftManager:GetTaskSeason(taskData.Id)
            local isSeasonOpen = XDataCenter.RiftManager:CheckSeasonOpen(taskSeason)
            local seasonName = XDataCenter.RiftManager:GetSeasonNameByIndex(taskSeason)
            grid:SetTaskLock(not isSeasonOpen, XUiHelper.GetText("RiftSeasonLock", seasonName))
        else
            grid:SetTaskLock(false)
        end
    end
end

function XUiRiftTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiRiftTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiRiftTask:RegisterEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiRiftTask:UpdateRedPoint()
    for i = 1, 3 do
        if self.TabBtns[i] then
            local isShowRed
            if i == SeasonTaskTabIdx then
                isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(self.SeasonTaskGroupId)
            else
                isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIdList[i])
            end
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end