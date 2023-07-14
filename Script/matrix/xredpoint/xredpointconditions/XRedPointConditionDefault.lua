-- 红点条件检测器
--默认
local XRedPointConditionDefault = {}
XRedPointConditionDefault.__index = XRedPointConditionDefault

--检测
function XRedPointConditionDefault.Check()
    return false
end

return XRedPointConditionDefault