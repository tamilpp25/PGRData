local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--================
--成就动态列表
--================
local XUiAchvPanelDTable = XClass(nil, "XUiAchvPanelDTable")

function XUiAchvPanelDTable:Ctor(uiPrefab)
    self.GameObject = uiPrefab.gameObject
    self:InitDynamicTable()
end

function XUiAchvPanelDTable:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local XUiAchvGridDTable = require("XUi/XUiAchievement/Achievement/PanelDTable/XUiAchvGridDTable")
    self.DynamicTable:SetProxy(XUiAchvGridDTable)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiAchvPanelDTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DataList[index])
        grid:RefreshRare()
    end
end

function XUiAchvPanelDTable:SortTask()
    local TaskState = XDataCenter.TaskManager.TaskState
    table.sort(self.DataList, function(taskA, taskB)
                if taskA.State == taskB.State then
                    return taskA.Id < taskB.Id
                end
                if taskA.State == TaskState.Achieved then
                    return true
                end
                if taskB.State == TaskState.Achieved then
                    return false
                end
                if taskA.State == TaskState.Finish then
                    return false
                end
                if taskB.State == TaskState.Finish then
                    return true
                end
                return taskA.Id < taskB.Id
            end)
end
--================
--刷新动态列表
--================
function XUiAchvPanelDTable:Refresh(typeId)
    if not typeId then return end
    local achievements = XDataCenter.AchievementManager.GetAchievementListByType(typeId)
    self.DataList = {}
    for _, achievement in pairs(achievements) do
        local task = achievement:GetTask()
        if task then
            table.insert(self.DataList, task)
        end
    end
    self:SortTask()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiAchvPanelDTable