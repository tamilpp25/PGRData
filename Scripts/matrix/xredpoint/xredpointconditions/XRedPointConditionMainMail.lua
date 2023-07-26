----------------------------------------------------------------
--主界面邮件红点
local XRedPointConditionMainMail = {}
local SubConditions = nil

function XRedPointConditionMainMail.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_MAIL_PERSONAL,
        XRedPointConditions.Types.CONDITION_MAIL_FAVORITE,
        XRedPointConditions.Types.CONDITION_MAIL_FAVORITE_BOX
    }
    return SubConditions
end

function XRedPointConditionMainMail.Check()
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    return mailAgency:GetHasUnDealMail() + XRedPointConditionMailFavoriteBox.Check() + XRedPointConditionMailFavorite.Check()
end

return XRedPointConditionMainMail