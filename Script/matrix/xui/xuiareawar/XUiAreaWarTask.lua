local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local TAB_BTN_NUM = 3 --侧边栏任务类型按钮数量

local XUiAreaWarTask = XLuaUiManager.Register(XLuaUi, "UiAreaWarTask")

function XUiAreaWarTask:OnAwake()
    self:InitTabGroup()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )

    self.GridTask.gameObject:SetActiveEx(false)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiAreaWarTask:OnStart()
    self.SelectIndex = 1
end

function XUiAreaWarTask:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self.TabBtnGroup:SelectIndex(self.SelectIndex)
end

function XUiAreaWarTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarTask:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_FINISH_TASK then
        self:UpdateTasks()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarTask:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:OnClickBtnBack()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickBtnMainUi()
    end
end

function XUiAreaWarTask:InitTabGroup()
    local btns = {}
    for i = 1, TAB_BTN_NUM do
        btns[i] = self["BtnTask" .. i]
    end

    self.TabBtnGroup:Init(
        btns,
        function(index)
            self:OnSelectTaskType(index)
        end
    )
    self.Btns = btns
end

function XUiAreaWarTask:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarTask:OnSelectTaskType(index)
    self.SelectIndex = index
    self:UpdateTasks()

    self:PlayAnimation("TaskStoryQieHuan")
end

function XUiAreaWarTask:UpdateTasks()
    self.TaskList = XDataCenter.AreaWarManager.GetActivityTaskList(self.SelectIndex)

    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()

    for index, btn in pairs(self.Btns) do
        btn:ShowReddot(XDataCenter.AreaWarManager.CheckTaskHasRewardToGet(index))
    end

    local isEmpty = XTool.IsTableEmpty(self.TaskList)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(isEmpty)
    self.PanelTaskStoryList.gameObject:SetActiveEx(not isEmpty)
end

function XUiAreaWarTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskList[index])
    end
end

function XUiAreaWarTask:OnClickBtnBack()
    self:Close()
end

function XUiAreaWarTask:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end
