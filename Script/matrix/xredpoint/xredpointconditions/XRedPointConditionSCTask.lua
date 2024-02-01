local XRedPointConditionSCTask = {}

-- function XRedPointConditionSCTask.GetEvents()
--     if XRedPointConditionSCTask.Events == nil then
--         XRedPointConditionSCTask.Events = {
--             XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK)            
--         }
--     end
--     return XRedPointConditionSCTask.Events
-- end

-- XSameColorGameConfigs.TaskType
function XRedPointConditionSCTask.Check(taskType)
    local sameColorGameManager = XDataCenter.SameColorActivityManager
    if not sameColorGameManager.GetIsOpen() then
        return false
    end
    return XMVCA.XSameColor:CheckTaskRedPoint(taskType)
end

return XRedPointConditionSCTask