local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSuperSmashBrosTask = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosTask")

function XUiSuperSmashBrosTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
    
    self.BtnTabGrid = {}
end

function XUiSuperSmashBrosTask:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    self.TaskGroupIds = {}
    self:InitDynamicTable()
    self:InitLeftTabBtn()
    
    self.CurrentTaskGroupId = self.TaskGroupIds[1]
end

function XUiSuperSmashBrosTask:OnEnable()
    self.Super.OnEnable(self)
    self.BtnTabGroup:SelectIndex(self.CurrentTab or 1)
    self:RefreshRedPoint()
end

function XUiSuperSmashBrosTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiSuperSmashBrosTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:SetupDynamicTable()
        self:RefreshRedPoint()
    end
end

function XUiSuperSmashBrosTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSuperSmashBrosTask:SetupDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.CurrentTaskGroupId)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSuperSmashBrosTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDataList[index])
    end
end

function XUiSuperSmashBrosTask:InitLeftTabBtn()
    local allModes = XDataCenter.SuperSmashBrosManager.GetModeSortByPriority()
    local tabGroup = {}

    for i, mode in pairs(allModes) do
        local btn = self.BtnTabGrid[i]
        if not btn then
            local go = #self.BtnTabGrid == 0 and self.BtnFirst or XUiHelper.Instantiate(self.BtnFirst, self.BtnContent)
            btn = go:GetComponent("XUiButton")
            self.BtnTabGrid[i] = btn
        end
        btn:SetName(mode:GetName())
        tabGroup[i] = btn
        self.TaskGroupIds[i] = mode:GetTaskGroupId()
    end

    self.BtnTabGroup:Init(tabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiSuperSmashBrosTask:OnClickTabCallBack(tabIndex)
    if self.CurrentTab and self.CurrentTab == tabIndex then
        return
    end

    self.CurrentTab = tabIndex
    self.CurrentTaskGroupId = self.TaskGroupIds[tabIndex]
    self:PlayAnimation("TaskStoryQieHuan")
    self:SetupDynamicTable()
end

function XUiSuperSmashBrosTask:RefreshRedPoint()
    for tabIndex, taskGroupId in pairs(self.TaskGroupIds) do
        local btn = self.BtnTabGrid[tabIndex]
        if btn then
            local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
            btn:ShowReddot(isShowRed)
        end
    end
end

function XUiSuperSmashBrosTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiSuperSmashBrosTask:OnBtnBackClick()
    self:Close()
end

function XUiSuperSmashBrosTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiSuperSmashBrosTask