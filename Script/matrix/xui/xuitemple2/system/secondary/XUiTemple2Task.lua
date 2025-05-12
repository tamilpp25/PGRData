local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2TaskGrid = require("XUi/XUiTemple2/System/Secondary/XUiTemple2TaskGrid")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XUiTemple2Task : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Task = XLuaUiManager.Register(XLuaUi, "UiTemple2Task")

function XUiTemple2Task:OnAwake()
    self._GroupIndex = 1
    self:BindExitBtns()
end

function XUiTemple2Task:OnStart()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
    --XEventManager.AddEventListener(XEventId.EVENT_TASK_TAB_CHANGE, self.OnTaskChangeTab, self)
    self:Init()
end

function XUiTemple2Task:OnEnable()
end

function XUiTemple2Task:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

function XUiTemple2Task:OnTaskChangeSync()
    self:OnTaskPanelSelect(self._GroupIndex)
end

function XUiTemple2Task:Init()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.Temple2 }, self.PanelSpecialTool, self)

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiTemple2TaskGrid, self)
    self.DynamicTable:SetDelegate(self)

    --TxtTaskNumQian

    self.TabList = { self.BtnTabTask1, self.BtnTabTask2 }
    self.BtnGroup:Init(self.TabList, function(index)
        self:OnTaskPanelSelect(index)
        self:PlayAnimation("QieHuan")
    end)
    self.BtnGroup:SelectIndex(1)

    if self.GridTask then
        self.GridTask.gameObject:SetActiveEx(false)
    end
    self:UpdateButtonRedDot()
end

function XUiTemple2Task:OnTaskPanelSelect(index)
    self._GroupIndex = index
    local taskType = XDataCenter.TaskManager.TaskType.Temple2
    local taskDatas = XDataCenter.TaskManager.GetTaskByTypeAndGroup(taskType, XTemple2Enum.TASK[index])
    self.DynamicTable:SetDataSource(taskDatas)
    self.DynamicTable:ReloadDataSync(1)
    self:UpdateButtonRedDot()
end

function XUiTemple2Task:OnBtnMoneyRewardClick()
    --XDataCenter.FunctionalSkipManager.OnOpenMaintainerAction()
end

function XUiTemple2Task:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

function XUiTemple2Task:UpdateButtonRedDot()
    for i = 1, #self.TabList do
        ---@type XUiComponent.XUiButton
        local button = self.TabList[i]
        if button then
            local taskType = XDataCenter.TaskManager.TaskType.Temple2
            local groupId = XTemple2Enum.TASK[i]
            local isShow = XDataCenter.TaskManager.CheckAchievedTaskByTypeAndGroup(taskType, groupId)
            button:ShowReddot(isShow)
        end
    end
end

return XUiTemple2Task