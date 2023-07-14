----------------------------------------------------------------
-- 勋章检测
local XRedPointConditionPartnerNewSkill = {}

local Events = nil
function XRedPointConditionPartnerNewSkill.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_PARTNER_SKILLUNLOCK),
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),

    }
    return Events
end

function XRedPointConditionPartnerNewSkill.Check()
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Partner) and XDataCenter.PartnerManager.CheckNewSkillRedOfAll()
end

return XRedPointConditionPartnerNewSkill