local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--调色板战争任务界面
local XUiColorTableTask = XLuaUiManager.Register(XLuaUi, "UiColorTableTask")

function XUiColorTableTask:OnAwake()
    self:InitTabGroup()
    self:InitDynamicTable()
    self:RegisterEvent()
    self:InitTimes()
    self:InitAssetPanel()
end

function XUiColorTableTask:OnEnable()
    self.Super.OnEnable(self)
    self.BtnGroup:SelectIndex(self.SelectIndex or 1)
    self:UpdateRedPoint()
end

function XUiColorTableTask:OnDisable()
    self.Super.OnDisable(self)
end

function XUiColorTableTask:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.ColorTableManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiColorTableTask:InitTabGroup()
    self.TabBtns = {}
    self.TaskGroupIdList = XDataCenter.ColorTableManager.GetTaskGroupIdList()
    for i, id in ipairs(self.TaskGroupIdList) do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            table.insert(self.TabBtns, tmpBtn)
        end
    end

    self.BtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiColorTableTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiColorTableTask:OnSelectedTog(index)
    if self.SelectIndex == index then
        return
    end
    self.SelectIndex = index
    self:PlayAnimation("QieHuan")
    self:UpdateDynamicTable()
    self:UpdateAssetPanel()
end

function XUiColorTableTask:UpdateDynamicTable()
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

function XUiColorTableTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
    end
end

function XUiColorTableTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiColorTableTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiColorTableTask:RegisterEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

function XUiColorTableTask:UpdateRedPoint()
    for i, groupId in ipairs(self.TaskGroupIdList) do
        if self.TabBtns[i] then
            local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(groupId)
            self.TabBtns[i]:ShowReddot(isShowRed)
        end
    end
end

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiColorTableTask:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiColorTableTask:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------