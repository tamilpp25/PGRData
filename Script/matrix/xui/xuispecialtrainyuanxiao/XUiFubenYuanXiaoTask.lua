local XUiFubenYuanXiaoTask = XLuaUiManager.Register(XLuaUi,"UiFubenYuanXiaoTask")

local TabType = {
    Daily = 1,
    Challenge = 2
}

function XUiFubenYuanXiaoTask:OnStart()
    self.TaskDic = {}
    self.SelectIndex = TabType.Daily
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.TaskGroupIds = XDataCenter.FubenSpecialTrainManager.GetTaskGroupIds()
    self:RegisterButtonClick()
    self:InitDynamicTable()
    self:InitButtonGroup()
    self.GridTask.gameObject:SetActiveEx(false)

    -- 开启自动关闭检查
    local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end)
end

function XUiFubenYuanXiaoTask:OnEnable()
    XUiFubenYuanXiaoTask.Super.OnEnable(self)
    self:RefreshDynamicTable()
    self:RefreshRedPoint()
end

function XUiFubenYuanXiaoTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiFubenYuanXiaoTask:OnNotify(event,...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        self:RefreshDynamicTable()
    end
end

function XUiFubenYuanXiaoTask:RegisterButtonClick()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiFubenYuanXiaoTask:InitButtonGroup()
    local tabList = {
        self.BtnDayTask,
        self.BtnRewardTask
    }
    self.BtnGroup:Init(tabList,function(index)
        self:OnSelectTab(index)
    end)
    self.BtnGroup:SelectIndex(self.SelectIndex)
end

function XUiFubenYuanXiaoTask:OnSelectTab(index)
    self.SelectIndex = index
    self:RefreshDynamicTable()
end

function XUiFubenYuanXiaoTask:RefreshDynamicTable()
    self.TaskDic[TabType.Daily] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[1])
    self.TaskDic[TabType.Challenge] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.TaskGroupIds[2])

    self.DynamicTable:SetDataSource(self.TaskDic[self.SelectIndex])
    self.DynamicTable:ReloadDataASync()
end

function XUiFubenYuanXiaoTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenYuanXiaoTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDic[self.SelectIndex][index])
    end
end

function XUiFubenYuanXiaoTask:RefreshRedPoint()
    local isShowDayRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[1])
    local isShowChallengeRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[2])
    self.BtnDayTask:ShowReddot(isShowDayRedDot)
    self.BtnRewardTask:ShowReddot(isShowChallengeRedDot)
end

return XUiFubenYuanXiaoTask