local XRedPointConditionFashionStoryNewChapterUnLock={}

function XRedPointConditionFashionStoryNewChapterUnLock.Check(singlelineId)
    if XTool.IsNumberValid(singlelineId) then
        --解锁&未查看过
        return XDataCenter.FashionStoryManager.CheckGroupIsCanOpen(singlelineId) and not XDataCenter.FashionStoryManager.CheckGroupHadAccess(singlelineId)
    else
        return XDataCenter.FashionStoryManager.CheckIfAnyGroupUnAccess()
    end
end

return XRedPointConditionFashionStoryNewChapterUnLock