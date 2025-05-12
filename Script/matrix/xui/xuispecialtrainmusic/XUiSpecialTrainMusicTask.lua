local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSpecialTrainMusicTask = XLuaUiManager.Register(XLuaUi,"UiSpecialTrainMusicTask")

local TabType = {
    Daily = 1,
    Challenge = 2
}


function XUiSpecialTrainMusicTask:OnStart()
    self.TaskDic = {}
    self.SelectIndex = TabType.Daily
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterButtonClick()
    self:InitDynamicTable()
    self:InitButtonGroup()
end

function XUiSpecialTrainMusicTask:OnEnable()
    self:RefreshDynamicTable()
    self:RefreshRedPoint()
end

function XUiSpecialTrainMusicTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiSpecialTrainMusicTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or
        event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        self:RefreshDynamicTable()
    end
end

function XUiSpecialTrainMusicTask:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask,self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpecialTrainMusicTask:RefreshDynamicTable()
    self.TaskDic[TabType.Daily] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(XFubenSpecialTrainConfig.SpecialTrainMusicTaskId.DailyId)
    self.TaskDic[TabType.Challenge] = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(XFubenSpecialTrainConfig.SpecialTrainMusicTaskId.ChallengeId)
    
    self.DynamicTable:SetDataSource(self.TaskDic[self.SelectIndex])
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSpecialTrainMusicTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDic[self.SelectIndex][index])
    end
end

function XUiSpecialTrainMusicTask:RegisterButtonClick()
    self.BtnBack.CallBack = function() 
        self:Close()
    end
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
end

function XUiSpecialTrainMusicTask:InitButtonGroup()
    local tabList = {
        self.BtnDayTask,
        self.BtnRewardTask
    }
    self.BtnGroup:Init(tabList,function(index) 
        self:OnSelectTab(index)
    end)
    self.BtnGroup:SelectIndex(self.SelectIndex)
end

function XUiSpecialTrainMusicTask:OnSelectTab(index)
    self.SelectIndex = index
    self:RefreshDynamicTable()
end

function XUiSpecialTrainMusicTask:RefreshRedPoint()
    local isShowDayRedDot = XDataCenter.TaskManager.CheckLimitTaskList(XFubenSpecialTrainConfig.SpecialTrainMusicTaskId.DailyId)
    local isShowChallengeRedDot = XDataCenter.TaskManager.CheckLimitTaskList(XFubenSpecialTrainConfig.SpecialTrainMusicTaskId.ChallengeId)
    self.BtnDayTask:ShowReddot(isShowDayRedDot)
    self.BtnRewardTask:ShowReddot(isShowChallengeRedDot)
end

return XUiSpecialTrainMusicTask