local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDunhuangTaskGrid = require("XUi/XUiDunhuang/XUiDunhuangTaskGrid")

---@class XUiDunhuangTask : XLuaUi
---@field _Control XDunhuangControl
local XUiDunhuangTask = XLuaUiManager.Register(XLuaUi, "UiDunhuangTask")

function XUiDunhuangTask:OnAwake()
    self.GridTask.gameObject:SetActiveEx(false)
    self:AddBtnListener()
    self:BindHelpBtn(self.BtnHelp, "DunhuangHelp")
end

function XUiDunhuangTask:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.MuralShareCoin)
    
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiDunhuangTaskGrid, self)
    self.DynamicTable:SetDelegate(self)
    
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

function XUiDunhuangTask:OnEnable()
    self:OnTaskChangeSync()
end

function XUiDunhuangTask:OnDisable()

end

function XUiDunhuangTask:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

--region Ui - BtnListener
function XUiDunhuangTask:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiDunhuangTask:OnBtnBackClick()
    self:Close()
end

function XUiDunhuangTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

function XUiDunhuangTask:OnTaskChangeSync()
    --local groupId = 98366 -- todo
    --local taskDatas = XDataCenter.TaskManager.GetTimeLimitTaskByGroupId(groupId)

    local taskDatas = self._Control:GetActivityTasks()
    if not XTool.IsTableEmpty(taskDatas) then
        self.DynamicTable:SetDataSource(taskDatas)
        self.DynamicTable:ReloadDataSync(1)
    end
end

function XUiDunhuangTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

return XUiDunhuangTask