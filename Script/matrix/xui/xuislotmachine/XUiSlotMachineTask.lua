local XUiSlotMachineTaskContentPanel = require("XUi/XUiSlotMachine/XUiSlotMachineTaskContentPanel")

---@class XUiSlotMachineTask : XLuaUi
---@field TaskContentPanel XUiSlotMachineTaskContentPanel
local XUiSlotMachineTask = XLuaUiManager.Register(XLuaUi, "UiSlotmachineTask")

function XUiSlotMachineTask:OnAwake()
    self:AutoAddListener()
    self.TaskContentPanel = XUiSlotMachineTaskContentPanel.New(self, self.PanelTaskContent)
end

function XUiSlotMachineTask:OnStart(father)
    self.Father = father
    self:InitTabGroup()
end

function XUiSlotMachineTask:OnEnable()
    self.CurMachineEntity = self.Father.CurMachineEntity
    self:Refresh(self.CurMachineEntity:GetId())
end

function XUiSlotMachineTask:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiSlotMachineTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiSlotMachineTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:Refresh(self.CurMachineEntity:GetId())
    end
end

function XUiSlotMachineTask:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self:RefreshAssetPanel()
    self.TogDaily:ShowReddot(XDataCenter.TaskManager.CheckLimitTaskList(self.CurMachineEntity:GetTaskDailyLimitId()))
    self.TogCumulative:ShowReddot(XDataCenter.TaskManager.CheckLimitTaskList(self.CurMachineEntity:GetTaskCumulativeLimitId()))
    self.TabPanelGroup:SelectIndex(self.LastSelectIndex or 1)
end

function XUiSlotMachineTask:InitTabGroup()
    self.TabList = {
        self.TogDaily,
        self.TogCumulative,
    }
    self.TabPanelGroup:Init(self.TabList, function(index)
        self:OnTaskPanelSelect(index)
    end)
end

function XUiSlotMachineTask:OnTaskPanelSelect(index)
    self.LastSelectIndex = index
    local taskLimitId
    if index == XSlotMachineConfigs.TaskType.Daily then
        taskLimitId = self.CurMachineEntity:GetTaskDailyLimitId()
    elseif index == XSlotMachineConfigs.TaskType.Cumulative then
        taskLimitId = self.CurMachineEntity:GetTaskCumulativeLimitId()
    end
    self.TaskContentPanel:Refresh(taskLimitId)
    self:PlayAnimation("QieHuan")
end

function XUiSlotMachineTask:RefreshAssetPanel()
    if self.CurMachineEntity then
        local itemId = self.CurMachineEntity:GetConsumeItemId()
        if not self.AssetPanel then
            self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
            self.AssetPanel:SetRootUiName(self.Name)
        else
            self.AssetPanel:Refresh({ itemId })
        end
    end
end

return XUiSlotMachineTask