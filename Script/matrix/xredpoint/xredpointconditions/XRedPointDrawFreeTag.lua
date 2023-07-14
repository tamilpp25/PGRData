-- 有可领取奖励的任务时红点
local XRedPointDrawFreeTag = {}
local Events = nil

function XRedPointDrawFreeTag.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_DRAW_FREE_TICKET_UPDATE)
    }
    return Events
end

function XRedPointDrawFreeTag.Check()
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard) then
        return XDataCenter.DrawManager.CheckDrawFreeTicketTag()
    else
        return false
    end

end

return XRedPointDrawFreeTag