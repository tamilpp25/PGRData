-- 存在可领取的累积奖励
local XRedPointConditionTurntableReward = {}
local Events = nil

function XRedPointConditionTurntableReward.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_TURNTABLE_PROGRESS_REWARD),
            }
    return Events
end

function XRedPointConditionTurntableReward.Check()
    ---@type XTurntableAgency
    local agency = XMVCA:GetAgency(ModuleId.XTurntable)
    return agency:IsProgressRewardGain()
end

return XRedPointConditionTurntableReward