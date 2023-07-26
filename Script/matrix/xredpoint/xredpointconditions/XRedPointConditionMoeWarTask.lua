local XRedPointConditionMoeWarTask = {}
local Events = nil
function XRedPointConditionMoeWarTask.GetSubEvents()
	Events = Events or
	{
		XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
		XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
	}
	return Events
end

function XRedPointConditionMoeWarTask.Check()
	local taskCount = XMoeWarConfig.GetTaskGroupCount()
	for i = 1,taskCount do
		if XDataCenter.MoeWarManager.CheckTaskRedPoint(i,XMoeWarConfig.GetTaskGroupId(i)) then
			return true
		end
	end
	return false
end

return XRedPointConditionMoeWarTask