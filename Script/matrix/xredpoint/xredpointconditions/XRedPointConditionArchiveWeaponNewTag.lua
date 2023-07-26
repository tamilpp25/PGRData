-- Author: wujie
-- Note: 图鉴武器新得时的红点

local XRedPointConditionArchiveWeaponNewTag = {}
local Events = nil

function XRedPointConditionArchiveWeaponNewTag.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_WEAPON),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON),
    }
    return Events
end

function XRedPointConditionArchiveWeaponNewTag.Check()
    return true
end

return XRedPointConditionArchiveWeaponNewTag