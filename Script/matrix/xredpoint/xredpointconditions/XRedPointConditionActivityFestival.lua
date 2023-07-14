local XRedPointConditionActivityFestival = {}

function XRedPointConditionActivityFestival.Check(sectionId)
    if not XDataCenter.FubenFestivalActivityManager.IsFestivalInActivity(sectionId) then
        return false
    end
    
    local sectionCfg = XFestivalActivityConfig.GetFestivalById(sectionId)
    if sectionCfg.FunctionOpenId > 0 then
        if not XFunctionManager.JudgeCanOpen(sectionCfg.FunctionOpenId) then
            return false -- 功能未开启时不显示红点
        end
    end
    
    if sectionId == XFestivalActivityConfig.ActivityId.WhiteValentine
            or sectionId == XFestivalActivityConfig.ActivityId.NewYearFuben then
        local finishCount, totalCount = XDataCenter.FubenFestivalActivityManager.GetFestivalProgress(sectionId)
        return finishCount < totalCount
    end

    return false
end

return XRedPointConditionActivityFestival