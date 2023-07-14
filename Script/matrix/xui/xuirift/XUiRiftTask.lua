--大秘境任务界面
local XUiRiftTask = XLuaUiManager.Register(XLuaUi, "UiRiftTask")

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
    local taskCfgs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTask)
    for i, id in ipairs(self.TaskGroupIdList) do
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
    local taskGroupId = self.TaskGroupIdList[index]
    if not taskGroupId then
        return
    end

    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
end

function XUiRiftTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
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
    for i, groupId in ipairs(self.TaskGroupIdList) do
        if self.TabBtns[i] then
            local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(groupId)
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end