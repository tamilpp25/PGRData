--
-- Author: wujie
-- Note: 图鉴武器红点

local XRedPointConditionArchiveWeapon = {}
local Events = nil

function XRedPointConditionArchiveWeapon.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_NEW_WEAPON),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON),
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING),
    }
    return Events
end

function XRedPointConditionArchiveWeapon.Check()
    return (XMVCA.XArchive:IsHaveNewWeapon() or XMVCA.XArchive:IsHaveNewWeaponSetting())
    and XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive)
end

return XRedPointConditionArchiveWeapon