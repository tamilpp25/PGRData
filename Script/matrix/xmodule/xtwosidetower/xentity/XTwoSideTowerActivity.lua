local XTwoSideTowerChapter = require("XModule/XTwoSideTower/XEntity/XTwoSideTowerChapter")

---@class XTwoSideTowerActivity
local XTwoSideTowerActivity = XClass(nil, "XTwoSideTowerActivity")

function XTwoSideTowerActivity:Ctor()
    -- 活动id
    self.ActivityId = 0
    -- 章节数据
    ---@type XTwoSideTowerChapter[]
    self.ChapterDataList = {}
    -- 已通过关卡
    ---@type number[]
    self.PassedStages = {}
end

function XTwoSideTowerActivity:NotifyTwoSideTowerActivityData(data)
    self.ActivityId = data.ActivityId
    self:UpdateChapterInfos(data.ChapterDataList)
    self.PassedStages = data.PassedStages or {}
end

function XTwoSideTowerActivity:UpdateChapterInfos(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddChapterInfo(v)
    end
end

function XTwoSideTowerActivity:AddChapterInfo(data)
    if not data then
        return
    end
    local chapter = self.ChapterDataList[data.ChapterId]
    if not chapter then
        chapter = XTwoSideTowerChapter.New()
        self.ChapterDataList[data.ChapterId] = chapter
    end
    chapter:UpdateChapterData(data)
end

function XTwoSideTowerActivity:GetActivityId()
    return self.ActivityId
end

-- 获取章节历史最高积分
function XTwoSideTowerActivity:GetMaxChapterScore(chapterId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return 0
    end
    return chapter:GetMaxChapterScore()
end

-- 获取章节上一次积分
function XTwoSideTowerActivity:GetLastChapterScore(chapterId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return 0
    end
    return chapter:GetLastChapterScore()
end

-- 获取节点已通关关卡Id
function XTwoSideTowerActivity:GetPointPassStageId(chapterId, pointId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return 0
    end
    return chapter:GetPointPassStageId(pointId)
end

-- 检查章节是否通关
function XTwoSideTowerActivity:CheckChapterCleared(chapterId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return false
    end
    return chapter:IsCleared()
end

-- 检查节点是否通关
function XTwoSideTowerActivity:CheckPointIsPass(chapterId, pointId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return false
    end
    return chapter:IsPointPass(pointId)
end

-- 检查关卡是否通关
function XTwoSideTowerActivity:CheckPassedByStageId(stageId)
    return table.contains(self.PassedStages, stageId)
end

-- 检查当前特性是否已屏蔽
function XTwoSideTowerActivity:CheckChapterIsShieldFeature(chapterId, featureId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return false
    end
    return chapter:IsShieldFeature(featureId)
end

-- 检查上一次挑战特性是否已屏蔽
function XTwoSideTowerActivity:CheckChapterIsLastShieldFeature(chapterId, featureId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return false
    end
    return chapter:IsLastShieldFeature(featureId)
end

-- 检查屏蔽特性是否大于等于2次
function XTwoSideTowerActivity:CheckChapterShieldFeaturesCount(chapterId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return false
    end
    return chapter:CheckShieldFeaturesCount()
end

-- 检查是否是可扫荡关卡
function XTwoSideTowerActivity:CheckIsCanSweepStageId(chapterId, stageId)
    local chapter = self.ChapterDataList[chapterId]
    if not chapter then
        return false
    end
    return chapter:IsSweepStageId(stageId)
end

return XTwoSideTowerActivity
