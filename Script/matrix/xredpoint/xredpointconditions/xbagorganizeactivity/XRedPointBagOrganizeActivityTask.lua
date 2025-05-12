local XRedPointBagOrganizeActivityTask = {}


function XRedPointBagOrganizeActivityTask:Check()
    -- 活动开启
    local activityId = XMVCA.XBagOrganizeActivity:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        return XMVCA.XBagOrganizeActivity:CheckAnyTaskCanFinish()
    end
    
    return false
end


return XRedPointBagOrganizeActivityTask