local XRedPointConditionMoeWarTaskTab = {}
local Events = nil
function XRedPointConditionMoeWarTaskTab.GetSubEvents()
	Events = Events or
	{
		XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
		XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
	}
	return Events
end

function XRedPointConditionMoeWarTaskTab.Check(type)
	return XDataCenter.MoeWarManager.CheckTaskRedPoint(type,XMoeWarConfig.GetTaskGroupId(type)),type
end

return XRedPointConditionMoeWarTaskTab