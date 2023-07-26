----------------------------------------------------------------
--是否查阅过收藏盒界面
local XRedPointConditionMailFavoriteBox = {}
local Events = nil
function XRedPointConditionMailFavoriteBox.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XAgencyEventId.EVENT_COLLECTION_BOX_VIEW),
    }
    return Events
end

function XRedPointConditionMailFavoriteBox.Check()
    ---@type XMailAgency
    local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
    if mailAgency:GetUICollectBoxViewedRedPoint() then
        return 1
    end 
    return 0
end

return XRedPointConditionMailFavoriteBox