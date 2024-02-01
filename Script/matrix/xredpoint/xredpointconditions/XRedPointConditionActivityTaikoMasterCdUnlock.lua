local XRedPointConditionActivityTaikoMasterCdUnlock = {}

function XRedPointConditionActivityTaikoMasterCdUnlock.Check(songId)
    ---@type XTaikoMasterAgency
    local agency = XMVCA:GetAgency(ModuleId.XTaikoMaster)
    if not agency:CheckIsFunctionOpen() then
        return false
    end
    if not agency:CheckIsActivityOpen() then
        return false
    end
    return agency:CheckCdUnlockRedPoint(songId)
end

return XRedPointConditionActivityTaikoMasterCdUnlock
