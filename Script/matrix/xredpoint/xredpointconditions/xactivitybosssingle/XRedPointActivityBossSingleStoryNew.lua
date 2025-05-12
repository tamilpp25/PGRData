local XRedPointActivityBossSingleStoryNew = {}


function XRedPointActivityBossSingleStoryNew.Check()
    --判断开启
    if not XDataCenter.FubenActivityBossSingleManager.IsOpen() then
        return false
    end
    --已解锁的剧情id
    local curSectionId=XDataCenter.FubenActivityBossSingleManager.GetCurSectionId()
    local storyIds=XFubenActivityBossSingleConfigs.GetStoryIds(curSectionId)
    if XTool.IsTableEmpty(storyIds) then
        return false
    end
    local unlock={}
    for index, id in ipairs(storyIds) do
        local state=XDataCenter.FubenActivityBossSingleManager.IsStoryOpen(id)
        if state then
            table.insert(unlock,id)
        end
    end   

    --已看过的剧情Id
    for i, id in ipairs(unlock) do
        local state=XDataCenter.FubenActivityBossSingleManager.CheckStoryPassed(id)
        if not state then
            return true
        end
    end
    return false
end

return XRedPointActivityBossSingleStoryNew