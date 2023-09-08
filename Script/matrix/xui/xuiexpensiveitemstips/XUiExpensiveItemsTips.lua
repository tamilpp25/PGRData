local XUiExpensiveItemsTips = XLuaUiManager.Register(XLuaUi, "UiExpensiveItemsTips")
local XUiGridConsumeActivityTaskItem = require("XUi/XUiExpensiveItemsTips/Grid/XUiGridExpensiveItem")

function XUiExpensiveItemsTips:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiExpensiveItemsTips:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiExpensiveItemsTips:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(XUiGridConsumeActivityTaskItem, self)
    self.DynamicTable:SetDelegate(self)

    self.Timer = XScheduleManager.ScheduleForever(function ()
        self:RefreshTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiExpensiveItemsTips:RefreshDynamicTable()
    local allList = XMVCA.XUiMain:GetAllActiveTipExpensiveiItems()
    self.DynamicTable:SetDataSource(allList)
    self.DynamicTable:ReloadDataSync()

    local isEmpty = XTool.IsTableEmpty(allList)
    self.Empty.gameObject:SetActiveEx(isEmpty)
end

function XUiExpensiveItemsTips:RefreshTime()
    local allGrid = self.DynamicTable:GetGrids()
    for k, grid in pairs(allGrid) do
        grid:RefreshByTime()
    end

    local allList = XMVCA.XUiMain:GetAllActiveTipExpensiveiItems()
    if XTool.IsTableEmpty(allList) then
        self:Close()
    end
end

function XUiExpensiveItemsTips:OnEnable()
    self:RefreshDynamicTable()
end

function XUiExpensiveItemsTips:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    end
end

function XUiExpensiveItemsTips:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
end

return XUiExpensiveItemsTips