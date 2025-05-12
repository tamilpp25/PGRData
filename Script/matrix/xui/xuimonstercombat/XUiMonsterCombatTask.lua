local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiMonsterCombatTask : XLuaUi
local XUiMonsterCombatTask = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatTask")

function XUiMonsterCombatTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiMonsterCombatTask:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitDynamicTable()
    -- 开启自动关闭检查
    local endTime = XDataCenter.MonsterCombatManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.MonsterCombatManager.OnActivityEnd(true)
        end
    end)
end

function XUiMonsterCombatTask:OnEnable()
    self.Super.OnEnable(self)
    self:SetupDynamicTable()
end

function XUiMonsterCombatTask:OnGetEvents()
    return { 
        XEventId.EVENT_FINISH_TASK, 
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiMonsterCombatTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:SetupDynamicTable()
    end
end

function XUiMonsterCombatTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.DynamicTableTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiMonsterCombatTask:SetupDynamicTable()
    self.DataList = XDataCenter.MonsterCombatManager.GetActivityTaskList()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiMonsterCombatTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DataList[index])
    end
end

function XUiMonsterCombatTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiMonsterCombatTask:OnBtnBackClick()
    self:Close()
end

function XUiMonsterCombatTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiMonsterCombatTask