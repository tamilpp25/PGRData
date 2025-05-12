local XRedPointActivityFestivalDMC = {}


function XRedPointActivityFestivalDMC.Check(stageId)
    -- 节日Id是否在开放时间内
    if not XDataCenter.FubenFestivalActivityManager.IsFestivalInActivity(XFestivalActivityConfig.ActivityId.DMC) then
        return false
    end
    -- 功能是否开启
    local sectionCfg = XFestivalActivityConfig.GetFestivalById(XFestivalActivityConfig.ActivityId.DMC)
    if sectionCfg.FunctionOpenId > 0 then
        if not XFunctionManager.JudgeCanOpen(sectionCfg.FunctionOpenId) then
            return false
        end
    end
    
    -- 未全通关时的每日提醒
    if XDataCenter.FubenFestivalActivityManager.CheckFestivalRedPoint(XFestivalActivityConfig.ActivityId.DMC) then
        return true
    end
    
    -- 未通过指定关卡时的常显提醒
    if XTool.IsNumberValid(stageId) and not XDataCenter.FubenFestivalActivityManager.CheckStageIsPassById(stageId) then
        return true 
    end

    return false
end 

return XRedPointActivityFestivalDMC