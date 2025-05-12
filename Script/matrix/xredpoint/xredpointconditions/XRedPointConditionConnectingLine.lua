local XRedPointConditionConnectingLine = {}

local Events = nil
function XRedPointConditionConnectingLine.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_CONNECTING_LINE_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_DAILY_RESET),
    }
    return Events
end

function XRedPointConditionConnectingLine.Check()
    if XMVCA.XConnectingLine:IsShowRedPoint() then
        return true
    end
    local itemId = XMVCA.XConnectingLine:GetItemId()
    if itemId then
        return XRedPointConditionConnectingLine.CheckTask()
    end
    return false
end

function XRedPointConditionConnectingLine.CheckTask()
    local isAchieved = XDataCenter.TaskManager.CheckAchievedTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.TimeLimit, XEnumConst.CONNECTING_LINE.TASK)
    return isAchieved
end

return XRedPointConditionConnectingLine