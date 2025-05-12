local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--- 任务界面
---@class XUiBagOrganizeTask: XLuaUi
---@field private _Control XBagOrganizeActivityControl
local XUiBagOrganizeTask = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizeTask')

function XUiBagOrganizeTask:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    if self.BtnMainUi then
        self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    end

    -- 初始化任务动态列表
    if self.GridTask then
        self.GridTask.gameObject:SetActiveEx(false)
    end
    
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require('XUi/XUiBagOrganizeActivity/UiBagOrganizeTask/XUiGridBagOrganizeTask'), self)
end

function XUiBagOrganizeTask:OnStart()
    
end

function XUiBagOrganizeTask:OnEnable()
    self:RefreshTaskShow()
end

function XUiBagOrganizeTask:RefreshTaskShow()
    local taskDataList
    local taskTimelimitId = XMVCA.XBagOrganizeActivity:GetCurTaskTimelimitId()

    if XTool.IsNumberValid(taskTimelimitId) then
        taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimelimitId, true)
        
        -- 收集所有可领取的奖励
        local allRecieve = nil
        
        if not XTool.IsTableEmpty(taskDataList) then
            ---@param v XTaskData
            for i, v in pairs(taskDataList) do
                if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                    if allRecieve == nil then
                        allRecieve = {}
                        allRecieve.IsReceiveAllTask = true
                        allRecieve.TaskIds = {}
                    end
                    
                    table.insert(allRecieve.TaskIds, v.Id)
                end
            end
        end

        if not XTool.IsTableEmpty(allRecieve) then
            table.insert(taskDataList, 1, allRecieve)
        end
    end

    if not XTool.IsTableEmpty(taskDataList) then
        self.ImgEmpty.gameObject:SetActiveEx(false)
        
        self.DynamicTable:SetDataSource(taskDataList)
        self.DynamicTable:ReloadDataASync()
    else
        self.DynamicTable:RecycleAllTableGrid()
        self.ImgEmpty.gameObject:SetActiveEx(true)
    end
end

---@param grid XUiGridBagOrganizeTask
function XUiBagOrganizeTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:RefreshTask(self.DynamicTable.DataSource[index])
    end
end

return XUiBagOrganizeTask