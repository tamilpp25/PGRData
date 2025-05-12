local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiArenaTask : XLuaUi
---@field _Control XArenaControl
local XUiArenaTask = XLuaUiManager.Register(XLuaUi, "UiArenaTask")

function XUiArenaTask:OnAwake()
    self:_RegisterClickEvents()
end

function XUiArenaTask:OnStart()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.GridTask.gameObject:SetActive(false)

    self._DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self._DynamicTable:SetProxy(XDynamicGridTask)
    self._DynamicTable:SetDelegate(self)
    self:_InitView()
end

function XUiArenaTask:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnRefresh, self)
    self:_Refresh()
end

function XUiArenaTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnRefresh, self)
end

function XUiArenaTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid.RootUi = self
        grid:ResetData(data)
    end
end

function XUiArenaTask:OnRefresh()
    self:_Refresh()
end

function XUiArenaTask:_RegisterClickEvents()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
end

function XUiArenaTask:_Refresh()
    if not self.GameObject:Exist() then
        return
    end

    local tasks = self._Control:GetCurrentChallengeTaskList()

    XDataCenter.TaskManager.SortTaskList(tasks)
    -- v3.2 增加任务一键领取按钮
    tasks = XDataCenter.TaskManager.AddReceiveDataIfAchieved(tasks)
    self._DynamicTable:SetDataSource(tasks)
    self._DynamicTable:ReloadDataASync()
end

function XUiArenaTask:_InitView()
    local challengeId = self._Control:GetActivityChallengeId()

    if XTool.IsNumberValid(challengeId) and self.TxtTitle then
        local minLv = self._Control:GetChallengeMinLvByChallengeId(challengeId)
        local maxLv = self._Control:GetChallengeMaxLvByChallengeId(challengeId)
        local challengeName = self._Control:GetChallengeNameByChallengeId(challengeId)

        self.TxtTitle.text = XUiHelper.GetText("ArenaTaskTitle", challengeName, minLv, maxLv)
    end
end

return XUiArenaTask
