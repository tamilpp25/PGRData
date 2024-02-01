---@class XUiFangKuaiTask : XLuaUi 大方块任务界面
---@field _Control XFangKuaiControl
local XUiFangKuaiTask = XLuaUiManager.Register(XLuaUi, "UiFangKuaiTask")

local TaskType = { Base = 1, Extend = 2 }

function XUiFangKuaiTask:OnStart()
    self:InitCompnent()
    self:InitDynamicTable()
    self.BtnGroup:SelectIndex(TaskType.Base)

    self.EndTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFangKuaiTask:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateRedPoint()
end

function XUiFangKuaiTask:InitCompnent()
    local itemIds = { XEnumConst.FangKuai.ItemId }
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh(itemIds)
    end
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControl)

    self.BtnGroup:Init({ self.BtnTabTask1, self.BtnTabTask2 }, function(index)
        self:OnTabsClick(index)
    end)
end

function XUiFangKuaiTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiFangKuaiTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:UpdateDynamicTable()
        self:UpdateRedPoint()
    end
end

function XUiFangKuaiTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFangKuaiTask:UpdateDynamicTable()
    self.ActivityTasks = self._Control:GetTaskTimeLimitId(self._CurIndex)
    self.DynamicTable:SetDataSource(self.ActivityTasks)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.ActivityTasks))
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiFangKuaiTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActivityTasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
    end
end

function XUiFangKuaiTask:OnTabsClick(index)
    self._CurIndex = index
    self:UpdateDynamicTable()
    self:PlayAnimation("QieHuan")
end

function XUiFangKuaiTask:UpdateRedPoint()
    self.BtnTabTask1:ShowReddot(self._Control:HasTaskRewardGain(TaskType.Base))
    self.BtnTabTask2:ShowReddot(self._Control:HasTaskRewardGain(TaskType.Extend))
end

return XUiFangKuaiTask