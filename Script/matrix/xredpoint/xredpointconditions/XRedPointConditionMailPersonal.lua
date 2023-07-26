----------------------------------------------------------------
--单个邮件检测
local XRedPointConditionMailPersonal = {}
local Events = nil
function XRedPointConditionMailPersonal.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XAgencyEventId.EVENT_MAIL_SYNC),
        XRedPointEventElement.New(XAgencyEventId.EVENT_MAIL_GET_ALL_MAIL_REWARD),
        XRedPointEventElement.New(XAgencyEventId.EVENT_MAIL_DELETE),
        XRedPointEventElement.New(XAgencyEventId.EVENT_MAIL_READ),
        XRedPointEventElement.New(XAgencyEventId.EVENT_MAIL_GET_MAIL_REWARD),
    }
    return Events
end

function XRedPointConditionMailPersonal.Check(mailId)
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    return mailAgency:IsMailUnReadOrHasReward(mailId)
end

return XRedPointConditionMailPersonal