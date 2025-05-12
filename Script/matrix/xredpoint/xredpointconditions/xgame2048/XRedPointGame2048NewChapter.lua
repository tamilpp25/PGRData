local XRedPointGame2048NewChapter = {}


function XRedPointGame2048NewChapter:Check()
    -- 活动开启
    local activityId = XMVCA.XGame2048:GetCurActivityId()
    if XTool.IsNumberValid(activityId) then
        local chapterIds = XMVCA.XGame2048:GetCurChapterIds()

        if not XTool.IsTableEmpty(chapterIds) then
            for i, v in ipairs(chapterIds) do
                if XMVCA.XGame2048:CheckChapterUnLockById(v) and XMVCA.XGame2048:CheckChapterIsNew(v) then
                    return true
                end
            end
        end
    end
    
    return false
end 


return XRedPointGame2048NewChapter