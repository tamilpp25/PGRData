----------------------------------------------------------------
-- 勋章检测
local XRedPointConditionPartnerCanCompose = {}

local Events = nil
function XRedPointConditionPartnerCanCompose.GetSubEvents()
    local eventIds = XDataCenter.PartnerManager.GetCheckEventIds()
    Events = {}
    for _,id in pairs(eventIds or {}) do
        table.insert(Events, XRedPointEventElement.New(id))
    end
    table.insert(Events, XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE))

    return Events
end

function XRedPointConditionPartnerCanCompose.Check()
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Partner) and XDataCenter.PartnerManager.CheckComposeRedOfAll()
end

return XRedPointConditionPartnerCanCompose