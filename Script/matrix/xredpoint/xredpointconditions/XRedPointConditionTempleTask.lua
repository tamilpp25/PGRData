local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")

local XRedPointConditionTempleTask = {}

function XRedPointConditionTempleTask.Check()
    if XMVCA.XTemple:ExGetIsLocked() then
        return false
    end
    
    if XRedPointConditionTempleTask.CheckTask() then
        return true
    end

    if XMVCA.XTemple:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.COUPLE) then
        return true
    end

    if XMVCA.XTemple:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.SPRING) then
        return true
    end

    if XMVCA.XTemple:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.LANTERN) then
        return true
    end

    return false
end

function XRedPointConditionTempleTask.CheckActivityBanner()
    if XMVCA.XTemple:ExGetIsLocked() then
        return false
    end

    if XRedPointConditionTempleTask.CheckTask() then
        return true
    end

    if XRedPointConditionTempleTask.CheckPhotoJustUnlock() then
        return true
    end

    if XMVCA.XTemple:IsCoupleChapterJustUnlock() then
        return true
    end

    if XMVCA.XTemple:IsChapterHasJustUnlockStage(XTempleEnumConst.CHAPTER.SPRING) then
        return true
    end

    if XMVCA.XTemple:IsChapterHasJustUnlockStage(XTempleEnumConst.CHAPTER.LANTERN) then
        return true
    end

    if XMVCA.XTemple:IsChapterHasJustUnlockMessage(XTempleEnumConst.CHAPTER.SPRING) then
        return true
    end

    if XMVCA.XTemple:IsChapterHasJustUnlockMessage(XTempleEnumConst.CHAPTER.LANTERN) then
        return true
    end

    return false
end

function XRedPointConditionTempleTask.CheckTask(groupId)
    if groupId then
        local isAchieved = XDataCenter.TaskManager.CheckAchievedTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.TimeLimit, groupId)
        return isAchieved
    end
    for i, groupId in pairs(XTempleEnumConst.TASK) do
        local isAchieved = XDataCenter.TaskManager.CheckAchievedTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.TimeLimit, groupId)
        if isAchieved then
            return isAchieved
        end
    end
end

function XRedPointConditionTempleTask.CheckPhotoJustUnlock()
    return XMVCA.XTemple:CheckPhotoJustUnlock()
end

function XRedPointConditionTempleTask.IsNewStageJustUnlock(chapterId)
    return XMVCA.XTemple:IsChapterStageJustUnlockOnce(chapterId)
end

function XRedPointConditionTempleTask.IsNewMessageJustUnlock(chapterId)
    return XMVCA.XTemple:IsChapterHasJustUnlockMessage(chapterId)
end

return XRedPointConditionTempleTask
