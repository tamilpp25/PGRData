-- Author: wujie
-- Note: 图鉴武器设定新得时的红点

local XRedPointConditionArchiveWeaponSettingUnlock = {}
local Events = nil

function XRedPointConditionArchiveWeaponSettingUnlock.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ARCHIVE_UNLOCK_WEAPON_SETTING),
    }
    return Events
end

function XRedPointConditionArchiveWeaponSettingUnlock.Check(templateId)
    return XMVCA.XArchive:IsNewWeaponSetting(templateId)
end

return XRedPointConditionArchiveWeaponSettingUnlock