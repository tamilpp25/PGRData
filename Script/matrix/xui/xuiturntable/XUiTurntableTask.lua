local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTurntableTask = require("XUi/XUiTurntable/XUiGridTurntableTask")

---@class XUiTurntableTask : XLuaUi
---@field _Control XTurntableControl
local XUiTurntableTask = XLuaUiManager.Register(XLuaUi, "UiTurntableTask")

local Tab = { Daily = 1, Accumulate = 2 }

function XUiTurntableTask:OnAwake()

end

function XUiTurntableTask:OnStart(root)
    ---@type XUiTurntableMain
    self._Root = root

    self:InitTaskList()
    self:InitTab()
    self:Refresh()

    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    local itemId, _ = self._Control:GetTurntableCost()
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh({ itemId })
    end
end

function XUiTurntableTask:OnEnable()
    self:Refresh()
end

function XUiTurntableTask:OnDisable()
    self.DynamicTable:RecycleAllTableGrid()
end

function XUiTurntableTask:Refresh(isReset)
    self.BtnGroup:SelectIndex(isReset and Tab.Daily or self._CurIndex)
    self:UpdateRedPoint()
end

function XUiTurntableTask:OnSelectTab(index)
    self._CurIndex = index
    self._ActivityTasks = self._Control:GetTasks(index)
    self.DynamicTable:SetDataSource(self._ActivityTasks)
    self.DynamicTable:ReloadDataASync(1)
    self:PlayAnimation("QieHuan")
end

function XUiTurntableTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_TASK_FINISH_FAIL,
    }
end

function XUiTurntableTask:OnNotify(evt, ...)
    self:Refresh()
end

function XUiTurntableTask:InitTab()
    local datas = {}
    table.insert(datas, self.BtnTabTask1)
    table.insert(datas, self.BtnTabTask2)
    self.BtnGroup:Init(datas, function(index)
        self:OnSelectTab(index)
    end)
    self.BtnGroup:SelectIndex(1)
    self.BtnTabTask2.gameObject:SetActiveEx(self._Control:GetTaskGroup(Tab.Accumulate) ~= 0)
end

function XUiTurntableTask:InitTaskList()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiGridTurntableTask, self._Root)
    self.DynamicTable:SetDelegate(self)
end

---动态列表事件
---@param grid XUiGridTurntableTask
function XUiTurntableTask:OnDynamicTableEvent(event, index, grid)
    if not grid then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:UpdateGrid(data)
    end
end

function XUiTurntableTask:OnTaskChangeSync()
    self.DynamicTable:SetDataSource(self._ActivityTasks)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiTurntableTask:UpdateRedPoint()
    self.BtnTabTask1:ShowReddot(self._Control:CanTaskRewardGain(Tab.Daily))
    self.BtnTabTask2:ShowReddot(self._Control:CanTaskRewardGain(Tab.Accumulate))
end

return XUiTurntableTask