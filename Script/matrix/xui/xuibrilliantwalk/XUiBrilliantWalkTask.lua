local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--技能UI网格 End
local XUiBrilliantWalkTask = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkTask")

function XUiBrilliantWalkTask:OnAwake()
    --资源条
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,  XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --任务类型按钮组
    self.SelectIndex = 1
    local tabList = {
        self.BtnTabTask1,
        self.BtnTabTask2
    }
    self.BtnGroup:Init(tabList,function(index)
        self:OnBtnTagClicked(index)
    end)
    --任务动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActive(false)
    --主界面按钮
    self.BtnMainUi.CallBack =  function()
        self:OnBtnMainUiClick()
    end
    --返回按钮
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
end
function XUiBrilliantWalkTask:OnEnable()
    self.BtnGroup:SelectIndex(1)
    self.RedPointID = XRedPointManager.AddRedPointEvent(self, self.UpdateRedPoint, self,{ XRedPointConditions.Types.CONDITION_BRILLIANTWALK_REWARD }, -1)
end
function XUiBrilliantWalkTask:OnDisable()
    self:StopDelayUpdateTaskPanelTimer()
    XRedPointManager.RemoveRedPointEvent(self.RedPointID)
end

function XUiBrilliantWalkTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end
function XUiBrilliantWalkTask:OnNotify(event)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        --一键领取奖励和一键完成任务会频繁刷新，加个延迟防卡顿
        if self.DelayUpdateTaskPanelTimer then
            self.IsKeepUpdateTaskPanel = true
            return
        end

        self:UpdateView()
        self.DelayUpdateTaskPanelTimer = XScheduleManager.ScheduleOnce(function()
            if self.IsKeepUpdateTaskPanel then
                self:UpdateView()
                self.IsKeepUpdateTaskPanel = false
            end
            self:StopDelayUpdateTaskPanelTimer()
        end, 500)
    end
end
function XUiBrilliantWalkTask:StopDelayUpdateTaskPanelTimer()
    if self.DelayUpdateTaskPanelTimer then
        XScheduleManager.UnSchedule(self.DelayUpdateTaskPanelTimer)
        self.DelayUpdateTaskPanelTimer = nil
    end
end
--刷新红点
function XUiBrilliantWalkTask:UpdateRedPoint()
    self.BtnTabTask1:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkTaskRedByType(XBrilliantWalkTaskType.Daily))
    self.BtnTabTask2:ShowReddot(XDataCenter.BrilliantWalkManager.CheckBrilliantWalkTaskRedByType(XBrilliantWalkTaskType.Accumulative))
end
--刷新界面
function XUiBrilliantWalkTask:UpdateView()
    local viewData = XDataCenter.BrilliantWalkManager.GetUIDataTask(self.TaskType)
    self.TaskList = viewData.TaskList
    self.DynamicTable:SetDataSource(self.TaskList)
    self.DynamicTable:ReloadDataSync()
end

function XUiBrilliantWalkTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.RootUi = self.RootUi
        grid:ResetData(self.TaskList[index])
    end
end

--点击任务类型按钮
function XUiBrilliantWalkTask:OnBtnTagClicked(index)
    self.TaskType = index
    self:PlayAnimationWithMask("QieHuan")
    self:UpdateView()
end
--点击返回按钮
function XUiBrilliantWalkTask:OnBtnBackClick()
    self.StageId = nil
    self.ParentUi:CloseStackTopUi()
end
--点击主界面按钮
function XUiBrilliantWalkTask:OnBtnMainUiClick()
    self.StageId = nil
    XLuaUiManager.RunMain()
end