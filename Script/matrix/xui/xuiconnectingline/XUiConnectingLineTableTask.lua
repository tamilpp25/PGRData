local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XRedPointConditionConnectingLine = require("XRedPoint/XRedPointConditions/XRedPointConditionConnectingLine")

---@class XUiConnectingLineTask : XLuaUi
---@field _Control XConnectingLineControl
local XUiConnectingLineTableTask = XLuaUiManager.Register(XLuaUi, "UiConnectingLineTableTask")

function XUiConnectingLineTableTask:OnAwake()
    self._GroupId = nil
    self._GroupIdList = {}
    self:BindExitBtns()
end

function XUiConnectingLineTableTask:OnStart()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
    --XEventManager.AddEventListener(XEventId.EVENT_TASK_TAB_CHANGE, self.OnTaskChangeTab, self)
    self:Init()
end

function XUiConnectingLineTableTask:OnEnable()
end

function XUiConnectingLineTableTask:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

function XUiConnectingLineTableTask:OnTaskChangeSync()
    self:OnTaskPanelSelect(self._GroupId)
end

function XUiConnectingLineTableTask:Init()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin }, self.PanelSpecialTool, self)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)

    self.TabList = { self.BtnTabTask1 }
    local groupIdList = { XEnumConst.CONNECTING_LINE.TASK }
    --for i, v in pairs(XEnumConst.CONNECTING_LINE.TASK) do
    --    groupIdList[#groupIdList + 1] = v
    --end
    --table.sort(groupIdList, function(a, b)
    --    return a < b
    --end)
    --for i = 1, #groupIdList - 1 do
    --    ---@type XUiComponent.XUiButton
    --    local button = XUiHelper.Instantiate(self.BtnTabTask1, self.BtnTabTask1.transform.parent)
    --    self.TabList[#self.TabList + 1] = button
    --end
    --for i = 1, #groupIdList do
    --    local taskType = groupIdList[i]
    --    local button = self.TabList[i]
    --    button:SetNameByGroup(0, XUiHelper.GetText("TempleTask" .. taskType))
    --end
    self.GridTask.gameObject:SetActiveEx(false)
    self._GroupIdList = groupIdList
    self.BtnGroup:Init(self.TabList, function(index)
        local taskType = groupIdList[index]
        self:OnTaskPanelSelect(taskType)
        self:PlayAnimation("QieHuan")
    end)

    self.BtnGroup:SelectIndex(1)
end

function XUiConnectingLineTableTask:OnTaskPanelSelect(groupId)
    self._GroupId = groupId
    local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskByGroupId(groupId)
    self.DynamicTable:SetDataSource(taskDatas)
    self.DynamicTable:ReloadDataSync(1)

    for i = 1, #self.TabList do
        local taskType = self._GroupIdList[i]
        ---@type XUiComponent.XUiButton
        local button = self.TabList[i]
        button:ShowReddot(XRedPointConditionConnectingLine.CheckTask(taskType))
    end
end

function XUiConnectingLineTableTask:OnBtnMoneyRewardClick()
    XDataCenter.FunctionalSkipManager.OnOpenMaintainerAction()
end

function XUiConnectingLineTableTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

return XUiConnectingLineTableTask