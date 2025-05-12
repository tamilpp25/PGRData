-- Author: wujie
-- Note: 图鉴武器新得时的红点

local XRedPointConditionArchiveWeaponGridNewTag = {}
local Events = nil

function XRedPointConditionArchiveWeaponGridNewTag.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_WEAPON),
    }
    return Events
end

function XRedPointConditionArchiveWeaponGridNewTag.Check(templateId)
    return XMVCA.XArchive:IsNewWeapon(templateId)
end

return XRedPointConditionArchiveWeaponGridNewTag