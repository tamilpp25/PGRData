
local XRedPointConditionSubMenuNewSystem = {}

function XRedPointConditionSubMenuNewSystem.Check()
    local list = XUiConfigs.GetSystemSubMenuList()
    for _, config in ipairs(list or {}) do
        local conditions = config.RedPointCondition
        local state = XRedPointManager.CheckConditions(conditions, config.RedPointParam)
        if state then
            return true
        end
    end
    return false
end

return XRedPointConditionSubMenuNewSystem 