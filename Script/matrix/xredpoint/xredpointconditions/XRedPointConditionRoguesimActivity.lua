local XRedPointConditionRoguesimActivity = {}

function XRedPointConditionRoguesimActivity.Check()
    ---@type XRogueSimAgency
    local agency = XMVCA:GetAgency(ModuleId.XRogueSim)
    return agency:IsShowStageRedPoint()
end

return XRedPointConditionRoguesimActivity