---@class XTurntableAgency : XAgency
---@field private _Model XTurntableModel
local XTurntableAgency = XClass(XAgency, "XTurntableAgency")

function XTurntableAgency:OnInit()
    --初始化一些变量
end

function XTurntableAgency:InitRpc()
    XRpc.NotifyTurntableData = handler(self, self.NotifyTurntableData)
end

function XTurntableAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XTurntableAgency:NotifyTurntableData(data)
    self._Model:NotifyTurntableData(data)
end

function XTurntableAgency:GetCurCfg()
    if self._Model.ActivityData then
        local activityId = self._Model.ActivityData:GetActivityId()
        if XTool.IsNumberValid(activityId) then
            return self._Model:GetTurntableActivityById(activityId)
        end
    end
    return nil
end

function XTurntableAgency:GetCostItem()
    local cfg = self:GetCurCfg()
    return cfg and cfg.ConsumeItemId or 0
end

function XTurntableAgency:IsTaskRewardGain()
    local cfg = self:GetCurCfg()
    if cfg then
        local activityId = self._Model.ActivityData:GetActivityId()
        local remind = self._Model:GetRemindItemCount(activityId)
        if remind <= 0 then
            return false
        end
        for _, groupId in pairs(cfg.TaskGroup) do
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
    end
    return false
end

function XTurntableAgency:IsProgressRewardGain()
    local cfg = self:GetCurCfg()
    if cfg then
        local rewardCfgs = self._Model:GetProgressReward(cfg.Id)

        for index, cfg in ipairs(rewardCfgs) do
            local activityId = self._Model.ActivityData:GetActivityId()
            local times = self._Model.ActivityData:GetAccumulateDrawNum()
            local isRewardGain = self._Model.ActivityData:IsRewardGain(index)
            local progress = self._Model:GetProgressByRewardIndex(activityId, index)
            if not isRewardGain and times >= progress then
                return true
            end
        end
    end
    return false
end

function XTurntableAgency:IsHasTimesInTheRemaining72Hours()
    if not self._Model.IsNeedShow72HoursRedPoint then
        return false
    end
    local cfg = self:GetCurCfg()
    if cfg then
        local time = XFunctionManager.GetEndTimeByTimeId(cfg.TimeId) - XTime.GetServerNowTimestamp()
        if time <= 72 * 60 * 60 then
            local itemCount = XDataCenter.ItemManager.GetCount(cfg.ConsumeItemId)
            local activityId = self._Model.ActivityData:GetActivityId()
            local remind = self._Model:GetRemindItemCount(activityId)
            if itemCount >= cfg.ConsumeItemCount and remind > 0 then
                return true
            end
        end
    end
    return false
end

function XTurntableAgency:IsOpen()
    local cfg = self:GetCurCfg()
    if cfg then
        local activityId = self._Model.ActivityData:GetActivityId()
        if not XTool.IsNumberValid(activityId) then
            return false
        end
        return XFunctionManager.CheckInTimeByTimeId(cfg.TimeId)
    end
    return false
end

return XTurntableAgency