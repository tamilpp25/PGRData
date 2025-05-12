local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiDlcCasualGamesTask : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field ImgEmpty UnityEngine.UI.Image
---@field PanelAsset UnityEngine.RectTransform
---@field BtnDayTask XUiComponent.XUiButton
---@field BtnRewardTask XUiComponent.XUiButton
---@field TaskList UnityEngine.RectTransform
---@field GridTask UnityEngine.RectTransform
---@field BtnGroup XUiButtonGroup
---@field Dark UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualGamesTask = XLuaUiManager.Register(XLuaUi, "UiDlcCasualGamesTask")
local XUiDlcCasualGamesTaskGrid = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesTaskGrid")

function XUiDlcCasualGamesTask:Ctor()
    self._SelectIndex = XEnumConst.DlcCasualGame.TaskGroupType.Daily
end

--region 生命周期
function XUiDlcCasualGamesTask:OnAwake()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiDlcCasualGamesTask:OnStart()
    local endTime = self._Control:GetEndTime()
    
    self:SetAutoCloseInfo(endTime, Handler(self, self._AutoCloseHandler))
    self.GridTask.gameObject:SetActiveEx(false)
    self:_InitDynamicTable()
    self:_InitButtonGroup()
end

function XUiDlcCasualGamesTask:OnEnable()
    self:_RefreshDynamicTable()
    self:_RefreshRedPoint()
end

function XUiDlcCasualGamesTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiDlcCasualGamesTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:_RefreshRedPoint()
        self:_RefreshDynamicTable()
    end
end
--endregion

--region 事件
function XUiDlcCasualGamesTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        
        grid:SetData(data)
    end
end

function XUiDlcCasualGamesTask:OnSelectTab(index)
    self._SelectIndex = index
    self:_RefreshDynamicTable()
end
--endregion

--region 私有方法
function XUiDlcCasualGamesTask:_AutoCloseHandler(isClose)
    if isClose then
        self._Control:AutoCloseHandler()
    end
end

function XUiDlcCasualGamesTask:_InitButtonGroup()
    local tabList = {
        self.BtnDayTask,
        self.BtnRewardTask
    }
    
    self.BtnGroup:Init(tabList, Handler(self, self.OnSelectTab))
    self.BtnGroup:SelectIndex(self._SelectIndex)
end

function XUiDlcCasualGamesTask:_RefreshDynamicTable()
    local taskData = self._Control:GetTaskListByType(self._SelectIndex)

    self:PlayAnimation("QieHuan")
    self.DynamicTable:SetDataSource(taskData)
    self.DynamicTable:ReloadDataASync()
end

function XUiDlcCasualGamesTask:_InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XUiDlcCasualGamesTaskGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcCasualGamesTask:_RefreshRedPoint()
    local isShowDayRedDot = self._Control:CheckDailyTasksAchieved()
    local isShowChallengeRedDot = self._Control:CheckAccumulatedTasksAchieved()

    self.BtnDayTask:ShowReddot(isShowDayRedDot)
    self.BtnRewardTask:ShowReddot(isShowChallengeRedDot)
end
--endregion

return XUiDlcCasualGamesTask