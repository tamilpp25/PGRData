local XTwoSideTowerPoint = require("XModule/XTwoSideTower/XEntity/XTwoSideTowerPoint")

---@class XTwoSideTowerChapter
local XTwoSideTowerChapter = XClass(nil, "XTwoSideTowerChapter")

local REDUCE_SCORE_CNT = 2 -- 屏蔽2个特性以上开始扣分

function XTwoSideTowerChapter:Ctor()
    -- 章节Id
    self.ChapterId = 0
    -- 是否通关
    self.Cleared = false
    -- 章节历史最高积分
    self.MaxChapterScore = 0
    -- 章节上次挑战积分
    self.LastChapterScore = 0
    -- 累计特性
    ---@type number[]
    self.TotalFeatures = {}
    -- 屏蔽特性
    ---@type number[]
    self.ShieldFeatures = {}
    -- 可扫荡关卡
    ---@type number[]
    self.SweepStageIds = {}
    -- 节点数据
    ---@type XTwoSideTowerPoint[]
    self.PointDataList = {}
    -- 章节上次挑战屏蔽特性
    ---@type number[]
    self.LastShieldFeatures = {}
end

function XTwoSideTowerChapter:UpdateChapterData(data)
    self.ChapterId = data.ChapterId or 0
    self.Cleared = data.Cleared or false
    self.MaxChapterScore = data.MaxChapterScore or 0
    self.LastChapterScore = data.LastChapterScore or 0
    self.TotalFeatures = data.TotalFeatures or {}
    self.ShieldFeatures = data.ShieldFeatures or {}
    self.SweepStageIds = data.SweepStageIds or {}
    self.PointDataList = {}
    self:UpdatePointInfos(data.PointDataList)
    self.LastShieldFeatures = data.LastShieldFeatures or {}
end

function XTwoSideTowerChapter:UpdatePointInfos(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddPointInfo(v)
    end
end

function XTwoSideTowerChapter:AddPointInfo(data)
    if not data then
        return
    end
    local point = self.PointDataList[data.PointId]
    if not point then
        point = XTwoSideTowerPoint.New()
        self.PointDataList[data.PointId] = point
    end
    point:UpdatePointData(data)
end

function XTwoSideTowerChapter:IsCleared()
    return self.Cleared
end

function XTwoSideTowerChapter:IsPointPass(pointId)
    local point = self.PointDataList[pointId]
    if not point then
        return false
    end
    local passStageId = point:GetPassStageId()
    return XTool.IsNumberValid(passStageId)
end

function XTwoSideTowerChapter:IsShieldFeature(featureId)
    return table.contains(self.ShieldFeatures, featureId)
end

function XTwoSideTowerChapter:IsLastShieldFeature(featureId)
    return table.contains(self.LastShieldFeatures, featureId)
end

function XTwoSideTowerChapter:IsSweepStageId(stageId)
    return table.contains(self.SweepStageIds, stageId)
end

function XTwoSideTowerChapter:GetMaxChapterScore()
    return self.MaxChapterScore
end

function XTwoSideTowerChapter:GetLastChapterScore()
    return self.LastChapterScore or 0
end

function XTwoSideTowerChapter:GetPointPassStageId(pointId)
    local point = self.PointDataList[pointId]
    if not point then
        return 0
    end
    return point:GetPassStageId()
end

-- 检查屏蔽特性数量是否大于2
function XTwoSideTowerChapter:CheckShieldFeaturesCount()
    return #self.ShieldFeatures >= REDUCE_SCORE_CNT
end

return XTwoSideTowerChapter
