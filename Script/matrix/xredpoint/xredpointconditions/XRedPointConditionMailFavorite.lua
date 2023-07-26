----------------------------------------------------------------
--是否有收藏好感邮件没领取
local XRedPointConditionMailFavorite = {}
local Events = nil
function XRedPointConditionMailFavorite.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XAgencyEventId.EVENT_FAVORITE_MAIL_SYNC),
        XRedPointEventElement.New(XAgencyEventId.EVENT_GET_FAVORITE_MAIL_SYNC),
        XRedPointEventElement.New(XAgencyEventId.EVENT_MAIL_GET_ALL_MAIL_REWARD),
    }
    return Events
end

function XRedPointConditionMailFavorite.Check()
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    if mailAgency:HasFavoriteMailActivity() then
        return 1
    end
    return 0
end

return XRedPointConditionMailFavorite