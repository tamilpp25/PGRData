local XUiSlotMachineTaskContentPanel = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineTaskContentPanel")

local XUiSlotMachineTask = XLuaUiManager.Register(XLuaUi, "UiSlotmachineTask")

function XUiSlotMachineTask:OnAwake()
    self.TaskContentPanel = XUiSlotMachineTaskContentPanel.New(self, self.PanelTaskContent)
end

function XUiSlotMachineTask:OnStart(father)
    self.Father = father
    self:AutoAddListener()
    self:InitTabGroup()
end

function XUiSlotMachineTask:OnEnable()
    self.CurMachineEntity = self.Father.CurMachineEntity
    self:Refresh(self.CurMachineEntity:GetId())
end

function XUiSlotMachineTask:AutoAddListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end

function XUiSlotMachineTask:OnGetEvents()
    return {
        XEventId.EVENT_SLOT_MACHINE_FINISH_TASK,
    }
end

function XUiSlotMachineTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SLOT_MACHINE_FINISH_TASK then
        self:Refresh(self.CurMachineEntity:GetId())
    end
end

function XUiSlotMachineTask:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self:RefreshAssetPanel()
    self.TogDaily:ShowReddot(XDataCenter.SlotMachineManager.CheckCanFinishTaskByType(machineId, XSlotMachineConfigs.TaskType.Daily))
    self.TogCumulative:ShowReddot(XDataCenter.SlotMachineManager.CheckCanFinishTaskByType(machineId, XSlotMachineConfigs.TaskType.Cumulative))
    self.TabPanelGroup:SelectIndex(self.LastSelectIndex or 1)
end

function XUiSlotMachineTask:InitTabGroup()
    self.TabList = {}
    table.insert(self.TabList, self.TogDaily)
    table.insert(self.TabList, self.TogCumulative)
    self.TabPanelGroup:Init(self.TabList, function(index) self:OnTaskPanelSelect(index) end)
end

function XUiSlotMachineTask:OnTaskPanelSelect(index)
    self.LastSelectIndex = index
    if index == XSlotMachineConfigs.TaskType.Daily then
        local dailyTaskLimitId = self.CurMachineEntity:GetTaskDailyLimitId()
        self.TaskContentPanel:Refresh(dailyTaskLimitId, index)
    elseif index == XSlotMachineConfigs.TaskType.Cumulative then
        local cumulativeTaskLimitId = self.CurMachineEntity:GetTaskCumulativeLimitId()
        self.TaskContentPanel:Refresh(cumulativeTaskLimitId, index)
    end
end

function XUiSlotMachineTask:RefreshAssetPanel()
    if self.CurMachineEntity then
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, self.CurMachineEntity:GetConsumeItemId())
        if XDataCenter.SlotMachineManager.GetSlotMachineActExchangeType() == XSlotMachineConfigs.ExchangeType.OnlyTask then
            if self.AssetPanel.BtnBuyJump1 then self.AssetPanel.BtnBuyJump1.gameObject:SetActiveEx(false) end
            if self.AssetPanel.BtnBuyJump2 then self.AssetPanel.BtnBuyJump2.gameObject:SetActiveEx(false) end
            if self.AssetPanel.BtnBuyJump3 then self.AssetPanel.BtnBuyJump3.gameObject:SetActiveEx(false) end
        end
    end
end