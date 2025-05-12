local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiTheatre4LvRewardTask : XUiNode
---@field PanelTips UnityEngine.RectTransform
---@field PanelTaskStoryList UnityEngine.RectTransform
---@field GridTask UnityEngine.RectTransform
---@field PanelNoneStoryTask UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiTheatre4LvRewardTask = XClass(XUiNode, "XUiTheatre4LvRewardTask")

-- region 生命周期

function XUiTheatre4LvRewardTask:OnStart()
    self._TaskType = 1
    self._DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self._DynamicTable:SetProxy(XDynamicGridTask, self.Parent, nil, Handler(self, self.OnTaskGridClick))
    self._DynamicTable:SetDelegate(self)

    self:_InitUi()
end

function XUiTheatre4LvRewardTask:OnEnable()
    self:_RegisterListeners()
end

function XUiTheatre4LvRewardTask:OnDisable()
    self:_RemoveListeners()
end

-- endregion

function XUiTheatre4LvRewardTask:FinishTask(id)
    self._Control.SystemControl:RecordBattlePassOldExp()
    XDataCenter.TaskManager.FinishTask(id, function(rewardGoodsList)
        XLuaUiManager.Open("UiTheatre4PopupGetReward", rewardGoodsList, nil, function()
            self._Control.SystemControl:CheckShowBattlePassLvUpImmediately()
        end)
    end)
end

function XUiTheatre4LvRewardTask:OnTaskGridClick(reward)
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", reward.TemplateId)
end

function XUiTheatre4LvRewardTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        
        grid:ResetData(data)
        grid.BtnFinish.CallBack = function()
            self:FinishTask(data.Id)
        end
    end
end

function XUiTheatre4LvRewardTask:Refresh(taskType)
    self._TaskType = taskType
    self:_RefreshDynamicList(taskType)
end

function XUiTheatre4LvRewardTask:OnTaskFinish()
    self:_RefreshDynamicList(self._TaskType)
end

-- region 私有方法

function XUiTheatre4LvRewardTask:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
end

function XUiTheatre4LvRewardTask:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskFinish, self)
end

function XUiTheatre4LvRewardTask:_RefreshDynamicList(taskType)
    local taskDatas = self._Control.SystemControl:GetTaskDatasByTaskType(taskType)

    self.PanelNoneStoryTask.gameObject:SetActiveEx(XTool.IsTableEmpty(taskDatas))
    self._DynamicTable:SetDataSource(taskDatas)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiTheatre4LvRewardTask:_InitUi()
    self.GridTask.gameObject:SetActiveEx(false)
end

-- endregion

return XUiTheatre4LvRewardTask
