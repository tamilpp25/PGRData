---@class XTurntableControl : XControl
---@field private _Model XTurntableModel
local XTurntableControl = XClass(XControl, "XTurntableControl")

local RequestProto = {
    TurntableDrawRewardRequest = "TurntableDrawRewardRequest", -- 抽奖
    TurntableGainAccumulateRewardRequest = "TurntableGainAccumulateRewardRequest", -- 获取累抽奖励
}

function XTurntableControl:OnInit()

end

function XTurntableControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTurntableControl:RemoveAgencyEvent()

end

function XTurntableControl:OnRelease()

end

function XTurntableControl:GetActivityId()
    return self._Model.ActivityData:GetActivityId()
end

function XTurntableControl:GetTurntableById(id)
    return self._Model:GetTurntableById(id)
end

---@return number,number
function XTurntableControl:GetTurntableCost()
    local cfg = self._Model:GetTurntableActivityById(self:GetActivityId())
    if cfg then
        return cfg.ConsumeItemId, cfg.ConsumeItemCount
    end
    return 0, 0
end

function XTurntableControl:GetProgressRewards()
    return self._Model:GetProgressReward(self:GetActivityId())
end

---@return XTableTurntable[]
function XTurntableControl:GetTurntableRewards()
    return self._Model:GetTurntableRewards(self:GetActivityId())
end

---奖励是否已领取
function XTurntableControl:IsProgressRewardGain(index)
    return self._Model.ActivityData:IsRewardGain(index)
end

---已抽取的次数
function XTurntableControl:GetRotateTimes()
    return self._Model.ActivityData:GetAccumulateDrawNum()
end

---是否能领取奖励
function XTurntableControl:CanProgressRewardGain(index)
    local activityId = self:GetActivityId()
    if XTool.IsNumberValid(activityId) then
        local progress = self._Model:GetProgressByRewardIndex(activityId, index)
        return not self:IsProgressRewardGain(index) and self:GetRotateTimes() >= progress
    end
    return false
end

---道具是否已经抽完了
function XTurntableControl:IsGoodsGone()
    return self:RemainingItemsCount() <= 0
end

---剩余道具数量
function XTurntableControl:RemainingItemsCount()
    return self._Model:GetRemindItemCount(self:GetActivityId())
end

---连抽次数
function XTurntableControl:GetMaxDrawNum()
    local cfg = self._Model:GetTurntableActivityById(self:GetActivityId())
    return cfg and cfg.MaxDrawNum or 0
end

function XTurntableControl:GetRecordNum()
    local cfg = self._Model:GetTurntableActivityById(self:GetActivityId())
    return cfg and cfg.RecordNum or 0
end

---是否显示十连抽
function XTurntableControl:CanTenDraw()
    local num = self:GetMaxDrawNum()
    return num > 1 and self:RemainingItemsCount() > 1
end

function XTurntableControl:EndTime()
    local cfg = self._Model:GetTurntableActivityById(self:GetActivityId())
    if cfg then
        return XFunctionManager.GetEndTimeByTimeId(cfg.TimeId) - XTime.GetServerNowTimestamp()
    end
    return 0
end

function XTurntableControl:GetTaskGroup(index)
    local cfg = self._Model:GetTurntableActivityById(self:GetActivityId())
    if cfg then
        return index == 1 and cfg.TaskGroup[1] or cfg.TaskGroup[2]
    end
    return 0
end

function XTurntableControl:GetTasks(index)
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self:GetTaskGroup(index))
end

function XTurntableControl:CanTaskRewardGain(index)
    local taskGroupId = self:GetTaskGroup(index)
    if taskGroupId == 0 or self:IsGoodsGone() then
        return false
    end
    return XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
end

function XTurntableControl:GetRuleDesc()
    local data = {}
    local cfg = self._Model:GetTurntableActivityById(self:GetActivityId())
    if cfg then
        for i, v in ipairs(cfg.BaseRuleTitles) do
            if not data[i] then
                data[i] = {}
            end
            data[i].title = v
        end
        for i, v in ipairs(cfg.BaseRules) do
            if not data[i] then
                data[i] = {}
            end
            data[i].rule = v
        end
    end
    return data
end

function XTurntableControl:GetGainRecords()
    return self._Model.ActivityData:GetGainRecords()
end

function XTurntableControl:GetItemGainTimes(id)
    return self._Model.ActivityData:GetItemGainTimes(id)
end

function XTurntableControl:GetItemByRewardId(rewardId)
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    local item = rewardItems[1] -- 拿首个进行展示
    return item.TemplateId, item.Count
end

function XTurntableControl:GetAllCanGainRewards()
    local canGainList = {}
    local rewards = self:GetProgressRewards()
    for i, v in ipairs(rewards) do
        if self:CanProgressRewardGain(i) then
            table.insert(canGainList, i - 1)
        end
    end
    return canGainList
end

function XTurntableControl:GetSkipAnimationValue()
    local data = XSaveTool.GetData("TurntableJump") or 0
    return data == 1
end

function XTurntableControl:SaveSkipAnimationValue(value)
    local isSave = value == true and 1 or 0
    XSaveTool.SaveData("TurntableJump", isSave)
end

function XTurntableControl:RequestDrawReward(times, cb)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.TurntableDrawRewardRequest, { Times = times }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:NotifyTurntableActivity(res.Data)
        if cb then
            cb(res.GainRecords)
        end
    end)
end

function XTurntableControl:RequestGainAccumulateReward(cb)
    local ids = self:GetAllCanGainRewards()
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.TurntableGainAccumulateRewardRequest, { AccumulateRewardIndex = ids }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateGainRewardIndexs(res.GainAccumulateRewardIndexs)
        if cb then
            cb(res.RewardGoodsList)
        end
    end)
end

return XTurntableControl