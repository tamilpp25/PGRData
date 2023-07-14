-- 有可领取奖励的任务时红点
local XRedPointConditionZhouMuTask = {}
local Events = nil

function XRedPointConditionZhouMuTask.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointConditionZhouMuTask.Check(chapterMainId)
    if chapterMainId == 0 then
        return false
    end

    local zhouMuId = XFubenMainLineConfigs.GetZhouMuId(chapterMainId)
    if zhouMuId == 0 then
        return false
    end
    return XDataCenter.FubenZhouMuManager.HasTaskReward(zhouMuId)
end

return XRedPointConditionZhouMuTask