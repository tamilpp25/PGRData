local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSummerEpisodeNewTask = XLuaUiManager.Register(XLuaUi, "UiSummerEpisodeNewTask")

local TabType = {
    Daily = 1, -- 每日任务
    Achievement = 2, -- 成就任务
}

function XUiSummerEpisodeNewTask:OnAwake()
    self:RegisterUiEvents()
    
    self.GridTask.gameObject:SetActiveEx(false)
    self.TaskDic = {}
end

function XUiSummerEpisodeNewTask:OnStart(closeCallback)
    self.SelectIndex = TabType.Daily
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.TaskGroupIds = XDataCenter.FubenSpecialTrainManager.GetTaskGroupIds()
    self.CloseCallBack=closeCallback
    self:InitDynamicTable()
    self:InitButtonGroup()
    
    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end)
end

function XUiSummerEpisodeNewTask:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshDynamicTable()
    self:RefreshRedPoint()
end

function XUiSummerEpisodeNewTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiSummerEpisodeNewTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        self:RefreshDynamicTable()
    end
end

function XUiSummerEpisodeNewTask:OnDisable()
    self.Super.OnDisable(self)
    if self.CloseCallBack then
        self.CloseCallBack()
		self.CloseCallBack=nil
    end
end

function XUiSummerEpisodeNewTask:InitButtonGroup()
    local tabList = {
        self.BtnDayTask,
        self.BtnRewardTask
    }
    self.BtnGroup:Init(tabList,function(index)
        self:OnSelectTab(index)
    end)
    self.BtnGroup:SelectIndex(self.SelectIndex)
end

function XUiSummerEpisodeNewTask:OnSelectTab(index)
    self.SelectIndex = index
    self:RefreshDynamicTable()
end

function XUiSummerEpisodeNewTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSummerEpisodeNewTask:RefreshDynamicTable()
    self.TaskDic[TabType.Daily] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[1])
    self.TaskDic[TabType.Achievement] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[2])
    
    self.DynamicTable:SetDataSource(self.TaskDic[self.SelectIndex])
    self.DynamicTable:ReloadDataASync()
end

function XUiSummerEpisodeNewTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDic[self.SelectIndex][index])
    end
end

function XUiSummerEpisodeNewTask:RefreshRedPoint()
    local isShowDayRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[1])
    local isShowChallengeRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[2])
    self.BtnDayTask:ShowReddot(isShowDayRedDot)
    self.BtnRewardTask:ShowReddot(isShowChallengeRedDot)
end

function XUiSummerEpisodeNewTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiSummerEpisodeNewTask:OnBtnBackClick()
    self:Close()
end

function XUiSummerEpisodeNewTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiSummerEpisodeNewTask