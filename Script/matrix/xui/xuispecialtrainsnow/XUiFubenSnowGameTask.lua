local XUiFubenSnowGameTask = XLuaUiManager.Register(XLuaUi,"UiFubenSnowGameTask")

local TabType = {
    Daily = 1,
    Challenge = 2
}

function XUiFubenSnowGameTask:OnStart()
    self.TaskDic = {}
    self.SelectIndex = TabType.Daily
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.TaskGroupIds = XDataCenter.FubenSpecialTrainManager.GetTaskGroupIds()
    self:RegisterButtonClick()
    self:InitDynamicTable()
    self:InitButtonGroup()
end

function XUiFubenSnowGameTask:OnEnable()
    self:RefreshDynamicTable()
    self:RefreshRedPoint()
end

function XUiFubenSnowGameTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiFubenSnowGameTask:OnNotify(event,...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        self:RefreshDynamicTable()
    end
end

function XUiFubenSnowGameTask:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiFubenSnowGameTask:InitButtonGroup()
    local tabList = {
        self.BtnDayTask,
        self.BtnRewardTask
    }
    self.BtnGroup:Init(tabList,function(index)
        self:OnSelectTab(index)
    end)
    self.BtnGroup:SelectIndex(self.SelectIndex)
end

function XUiFubenSnowGameTask:OnSelectTab(index)
    self.SelectIndex = index
    self:RefreshDynamicTable()
end

function XUiFubenSnowGameTask:RefreshDynamicTable()
    self.TaskDic[TabType.Daily] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[1])
    self.TaskDic[TabType.Challenge] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[2])

    self.DynamicTable:SetDataSource(self.TaskDic[self.SelectIndex])
    self.DynamicTable:ReloadDataASync()
end

function XUiFubenSnowGameTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenSnowGameTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDic[self.SelectIndex][index])
    end
end

function XUiFubenSnowGameTask:RefreshRedPoint()
    local isShowDayRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[1])
    local isShowChallengeRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[2])
    self.BtnDayTask:ShowReddot(isShowDayRedDot)
    self.BtnRewardTask:ShowReddot(isShowChallengeRedDot)
end

return XUiFubenSnowGameTask