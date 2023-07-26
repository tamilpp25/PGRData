local XRedPointConditionSTRoleLevelUp = {}

function XRedPointConditionSTRoleLevelUp.Check(roleId)
    local superTowerManager = XDataCenter.SuperTowerManager
    -- 活动没开启不处理
    if superTowerManager.GetIsEnd() then return false end
    return XDataCenter.SuperTowerManager.GetRoleManager()
        :CheckRolesSuperLevelUpShowRedDot(roleId)
end

return XRedPointConditionSTRoleLevelUp