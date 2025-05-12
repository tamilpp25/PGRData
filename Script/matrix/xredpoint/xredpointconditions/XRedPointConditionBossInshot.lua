local XRedPointConditionBossInshot = {}

function XRedPointConditionBossInshot.Check()
    ---@type XBossInshotAgency
    local agency = XMVCA:GetAgency(ModuleId.XBossInshot)
    return agency:IsShowActivityRedPoint()
end

return XRedPointConditionBossInshot