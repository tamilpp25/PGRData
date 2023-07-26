-- 多维挑战首通红点
local XRedPointConditionMultiDimFirstReward = {}

function XRedPointConditionMultiDimFirstReward.Check(themeId)
    -- 是否开启
    local isThemeOpen = XDataCenter.MultiDimManager.CheckThemeIsOpen(themeId)
    -- 每日首通
    local isFirstPassOpen = XDataCenter.MultiDimManager.CheckThemeIsFirstPassOpen(themeId)
    -- 是否点击过
    local isClickFightBtn = XDataCenter.MultiDimManager.CheckClickMainTeamFightBtn(themeId)
    return isThemeOpen and isFirstPassOpen and not isClickFightBtn
end 

return XRedPointConditionMultiDimFirstReward