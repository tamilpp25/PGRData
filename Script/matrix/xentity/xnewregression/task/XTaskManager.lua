-- PS:这是回归活动的任务管理类
local XINewRegressionChildManager = require("XEntity/XNewRegression/XINewRegressionChildManager")
local XTaskManager = XClass(XINewRegressionChildManager, "XTaskManager")

function XTaskManager:Ctor()
    self.Config = nil
end

function XTaskManager:InitWithConfigId(id)
    self.Config = XNewRegressionConfigs.GetTaskConfig(id)
end

-- taskType : XNewRegressionConfigs.TaskType
function XTaskManager:GetTaskDatas(taskType, isSort)
    if self.Config == nil then 
        XLog.Error("XTaskManager.GetTaskDatas 配置为空")
        return {} 
    end
    if isSort == nil then isSort = true end
    local result = {}
    local taskIds = {}
    if taskType == nil then
        taskIds = appendArray(taskIds, self.Config.TaskId)
        taskIds = appendArray(taskIds, self.Config.DailyTaskId)
        taskIds = appendArray(taskIds, self.Config.WeeklyTaskId)
    else
        if taskType == XNewRegressionConfigs.TaskType.Normal then
            taskIds = self.Config.TaskId
        elseif taskType == XNewRegressionConfigs.TaskType.Daily then
            taskIds = self.Config.DailyTaskId
        elseif taskType == XNewRegressionConfigs.TaskType.Weekly then
            taskIds = self.Config.WeeklyTaskId
        end
    end
    for _, id in ipairs(taskIds) do
        table.insert(result, XDataCenter.TaskManager.GetTaskDataById(id))
    end
    if isSort then
        XDataCenter.TaskManager.SortTaskList(result)
    end
    return result
end

-- taskType : XNewRegressionConfigs.TaskType
function XTaskManager:CheckCanFinishTaskByType(taskType)
    local taskDatas = self:GetTaskDatas(taskType, false)
    for _, taskData in ipairs(taskDatas) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true 
        end
    end
    return false
end

--######################## XINewRegressionChildManager接口 ########################

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XTaskManager:GetButtonWeight()
    return tonumber(XNewRegressionConfigs.GetChildActivityConfig("TaskButtonWeight"))
end

-- 入口按钮显示名称
function XTaskManager:GetButtonName()
    return XNewRegressionConfigs.GetChildActivityConfig("TaskButtonName")
end

-- 获取面板控制数据
function XTaskManager:GetPanelContrlData()
    return {
        assetPath = XNewRegressionConfigs.GetChildActivityConfig("TaskPrefabAssetPath"),
        proxy = require("XUi/XUiNewRegression/XUiTaskPanel"),
    }
end

-- 用来显示页签和统一入口的小红点
function XTaskManager:GetIsShowRedPoint(...)
    return self:CheckCanFinishTaskByType(...)
end

return XTaskManager