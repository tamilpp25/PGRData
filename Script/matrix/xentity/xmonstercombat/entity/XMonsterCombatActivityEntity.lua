-- BVB活动类
---@class XMonsterCombatActivityEntity
local XMonsterCombatActivityEntity = XClass(nil, "XMonsterCombatActivityEntity")

function XMonsterCombatActivityEntity:Ctor(activityId)
    if not XTool.IsNumberValid(activityId) then
        return
    end
    self:UpdateActivityId(activityId)
end

function XMonsterCombatActivityEntity:UpdateActivityId(activityId)
    local oldActivityId = self.ActivityId or 0
    if oldActivityId == activityId then
        return
    end
    self.ActivityId = activityId
    self.Config = XMonsterCombatConfigs.GetCfgByIdKey(XMonsterCombatConfigs.TableKey.MonsterCombatActivity, activityId)
end

function XMonsterCombatActivityEntity:GetTimeId()
    return self.Config.TimeId or 0
end

function XMonsterCombatActivityEntity:GetName()
    return self.Config.Name or ""
end

function XMonsterCombatActivityEntity:GetChapterIds()
    return self.Config.ChapterIds or {}
end
-- 活动任务组id
function XMonsterCombatActivityEntity:GetTimeLimitTaskId()
    return self.Config.TimeLimitTaskId or 0
end
-- 怪物负重上限
function XMonsterCombatActivityEntity:GetMonsterCostLimit()
    return self.Config.MonsterCostLimit or 0
end
-- 怪物数量上限
function XMonsterCombatActivityEntity:GetMonsterCountLimit()
    return self.Config.MonsterCountLimit or 0
end

function XMonsterCombatActivityEntity:GetHelpKey()
    local helpId = self.Config.HelpId or 0
    return XHelpCourseConfig.GetHelpCourseTemplateById(helpId).Function
end

-- 活动是否开启
function XMonsterCombatActivityEntity:IsOpen(noTips)
    if not XTool.IsNumberValid(self.ActivityId) then
        return false
    end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MonsterCombat, false, noTips) then
        return false
    end
    local inTime = XFunctionManager.CheckInTimeByTimeId(self:GetTimeId())
    if not inTime then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XMonsterCombatActivityEntity:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId())
end

-- 获取任务信息
function XMonsterCombatActivityEntity:GetTimeLimitTaskList()
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self:GetTimeLimitTaskId())
end

function XMonsterCombatActivityEntity:CheckLimitTaskList()
    return XDataCenter.TaskManager.CheckLimitTaskList(self:GetTimeLimitTaskId())
end

function XMonsterCombatActivityEntity:GetLocalSaveDataKey(name, value)
    return string.format(name, XPlayer.Id, self.ActivityId, value)
end

return XMonsterCombatActivityEntity