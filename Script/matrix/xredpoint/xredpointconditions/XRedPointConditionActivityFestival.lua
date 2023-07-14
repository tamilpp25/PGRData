local XRedPointConditionActivityFestival = {}

function XRedPointConditionActivityFestival.Check(sectionId)
    -- 节日Id是否在开放时间内
    if not XDataCenter.FubenFestivalActivityManager.IsFestivalInActivity(sectionId) then
        return false
    end
    -- 功能是否开启
    local sectionCfg = XFestivalActivityConfig.GetFestivalById(sectionId)
    if sectionCfg.FunctionOpenId > 0 then
        if not XFunctionManager.JudgeCanOpen(sectionCfg.FunctionOpenId) then
            return false
        end
    end
    if XDataCenter.FubenFestivalActivityManager.CheckFestivalRedPoint(sectionId) then
        return true
    end

    return false
end

return XRedPointConditionActivityFestival