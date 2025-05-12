local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiMultiDimTask = XLuaUiManager.Register(XLuaUi, "UiMultiDimTask")

function XUiMultiDimTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    
    self.BtnTabGrid = {}
end

function XUiMultiDimTask:OnStart()
    local itemId = XDataCenter.MultiDimManager.GetActivityItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    
    self:InitDynamicTable()
    self:InitLeftTabBtn()
    
    self.TaskGroupIds = XDataCenter.MultiDimManager.GetActivityTaskGroupId()
    self.CurrentTaskGroupId = self.TaskGroupIds[1]

    -- 开启自动关闭检查
    local endTime = XDataCenter.MultiDimManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MultiDimManager.HandleActivityEndTime()
        end
    end)
end

function XUiMultiDimTask:OnEnable()
    self.Super.OnEnable(self)
    self.BtnTabGroup:SelectIndex(self.CurrentTab or 1)
    self:RefreshRedPoint()
end

function XUiMultiDimTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiMultiDimTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:SetupDynamicTable()
        self:RefreshRedPoint()
    end
end

function XUiMultiDimTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiMultiDimTask:SetupDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.CurrentTaskGroupId)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiMultiDimTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDataList[index])
    end
end

function XUiMultiDimTask:InitLeftTabBtn()
    local taskGroupNames = XDataCenter.MultiDimManager.GetActivityTaskGroupName()

    local tabGroup = {}
    for i = 1, #taskGroupNames do
        local btn = self.BtnTabGrid[i]
        if not btn then
            local go = #self.BtnTabGrid == 0 and self.BtnFirst or XUiHelper.Instantiate(self.BtnFirst, self.BtnContent)
            btn = go:GetComponent("XUiButton")
            table.insert(self.BtnTabGrid, btn)
        end
        btn:SetName(taskGroupNames[i])
        tabGroup[i] = btn
    end
    for i = #taskGroupNames + 1, #self.BtnTabGrid do
        self.BtnTabGrid.GameObject:SetActiveEx(false)
    end
    self.BtnTabGroup:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiMultiDimTask:OnClickTabCallBack(tabIndex)
    if self.CurrentTab and self.CurrentTab == tabIndex then
        return
    end

    self.CurrentTab = tabIndex
    self.CurrentTaskGroupId = self.TaskGroupIds[tabIndex]
    self:SetupDynamicTable()
end

function XUiMultiDimTask:RefreshRedPoint()
    for tabIndex, taskGroupId in pairs(self.TaskGroupIds) do
        local btn = self.BtnTabGrid[tabIndex]
        if btn then
            local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
            btn:ShowReddot(isShowRed)
        end
    end
end

function XUiMultiDimTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiMultiDimTask:OnBtnBackClick()
    self:Close()
end

function XUiMultiDimTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiMultiDimTask