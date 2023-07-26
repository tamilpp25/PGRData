local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")
---@class XCharacterTowerViewModel : XChapterViewModel
local XCharacterTowerViewModel = XClass(XChapterViewModel, "XCharacterTowerViewModel")

--region 获取额外信息

-- 获取优先级
function XCharacterTowerViewModel:GetPriority()
    return self:GetExtralData().Priority or 0
end
-- 获取章节列表
function XCharacterTowerViewModel:GetChapterIds()
    return self:GetExtralData().ChapterIds or {}
end
    
--endregion

---@return XCharacterTowerChapter
function XCharacterTowerViewModel:GetChapterViewModel(chapterId)
    return XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
end

function XCharacterTowerViewModel:GetChapterIdsByChapterType(chapterType)
    local tempChapterIds = {}
    for _, chapterId in pairs(self:GetChapterIds()) do
        local chapterViewModel = self:GetChapterViewModel(chapterId)
        if chapterViewModel:GetChapterType() == chapterType then
            table.insert(tempChapterIds, chapterId)
        end
    end
    return tempChapterIds
end

function XCharacterTowerViewModel:GetCurrentAndMaxProgress()
    local finishCount = 0
    local totalCount = 0

    for _, chapterId in pairs(self:GetChapterIds()) do
        local chapterViewModel = self:GetChapterViewModel(chapterId)
        local tempFinishCount, tempTotalCount = chapterViewModel:GetChapterProgress()
        finishCount = finishCount + tempFinishCount
        totalCount = totalCount + tempTotalCount
    end

    return finishCount, totalCount
end
-- 获取进度提示
function XCharacterTowerViewModel:GetProgressTips()
    local finishCount, totalCount = self:GetCurrentAndMaxProgress()
    return XUiHelper.GetText("CharacterTowerChapterProgressDesc", finishCount, totalCount)
end

function XCharacterTowerViewModel:GetIsLocked()
    return not XDataCenter.CharacterTowerManager.IsUnlock(self:GetId())
end

function XCharacterTowerViewModel:GetLockTip()
    local _, desc = XDataCenter.CharacterTowerManager.IsUnlock(self:GetId())
    return desc
end

function XCharacterTowerViewModel:CheckHasRedPoint()
    for _, chapterId in pairs(self:GetChapterIds()) do
        local hasRedPoint = XDataCenter.CharacterTowerManager.CheckRedPointByChapterId(chapterId)
        if hasRedPoint then
            return true
        end
    end
    return false
end

-- 是否隐藏进度条
function XCharacterTowerViewModel:CheckHideProgressBar()
    return true
end
-- 检查是否有活动中标签， 一般规则为在活动中
function XCharacterTowerViewModel:CheckHasInActivityTag()
    return XDataCenter.CharacterTowerManager.CheckInActivity(self:GetChapterIds())
end
-- 是否显示缩略图的进度提示
function XCharacterTowerViewModel:CheckShowThumbnailProgressTips()
    return true
end

return XCharacterTowerViewModel