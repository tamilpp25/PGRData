local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")
local XExRpgTowerManager = XClass(XExFubenActivityManager, "XExRpgTowerManager")

-- 获取是否已锁住
function XExRpgTowerManager:ExGetIsLocked()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgTower) then
        return true
    end
    local activityEnd, _ = XDataCenter.RpgTowerManager.GetIsEnd()
    if activityEnd then
        return true
    end
    return false
end

-- 获取锁提示
function XExRpgTowerManager:ExGetLockTip()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgTower) then
        return XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.RpgTower)
    end
    local activityEnd, notStart = XDataCenter.RpgTowerManager.GetIsEnd()
    if activityEnd then
        if notStart then
            return CS.XTextManager.GetText("RpgTowerNotStart")
        end
        return CS.XTextManager.GetText("RpgTowerEnd")
    end
    return ""
end

function XExRpgTowerManager:ExGetProgressTip()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgTower) then
        return XDataCenter.RpgTowerManager.GetWholeProgressStr()
    end
    local activityEnd, notStart = XDataCenter.RpgTowerManager.GetIsEnd()
    if activityEnd then
        if notStart then
            return CS.XTextManager.GetText("RpgTowerNotStart")
        else
            return CS.XTextManager.GetText("RpgTowerEnd")
        end
    end
    return XDataCenter.RpgTowerManager.GetWholeProgressStr()
end

function XExRpgTowerManager:ExGetRunningTimeStr()
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.RpgTower) then
        local activityEnd, notStart = XDataCenter.RpgTowerManager.GetIsEnd()
        if activityEnd then
            return ""
        end
    end

    local endTimeSecond = XDataCenter.RpgTowerManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local leftTime = endTimeSecond - now
    local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    
    return XUiHelper.GetText("ActivityBranchFightLeftTime") .. remainTime
end

return XExRpgTowerManager