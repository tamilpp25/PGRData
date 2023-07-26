--有未领取奖励时红点
local XRedPointConditionSuperSmashBrosHaveReward = {}
local Events = nil
function XRedPointConditionSuperSmashBrosHaveReward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_SSB_STAGE_REFRESH)
    }
    return Events
end

function XRedPointConditionSuperSmashBrosHaveReward.Check()
    local supersmashRewardTaskList = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.RewardShowConfig)
    local haveReward = nil
    for index, value in pairs(supersmashRewardTaskList) do
        local taskId = value.TaskId
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)

        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            haveReward = true
            break
        end
    end

    return haveReward
end

return XRedPointConditionSuperSmashBrosHaveReward