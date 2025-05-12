local XRedPointBagOrganizeActivityNewChapter = {}


function XRedPointBagOrganizeActivityNewChapter:Check()
    -- 活动开启
    local activityId = XMVCA.XBagOrganizeActivity:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        local chapterIds = XMVCA.XBagOrganizeActivity:GetCurChapterIds()

        if not XTool.IsTableEmpty(chapterIds) then
            for i, v in ipairs(chapterIds) do
                if XMVCA.XBagOrganizeActivity:CheckChapterUnLockById(v) and XMVCA.XBagOrganizeActivity:CheckChapterIsNew(v) then
                    return true
                end
            end
        end
    end
    
    return false
end 


return XRedPointBagOrganizeActivityNewChapter