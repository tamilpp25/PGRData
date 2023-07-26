---@class XTwoSideTowerChapter
local XTwoSideTowerChapter = XClass(nil, "XTwoSideTowerChapter")
local XTwoSideTowerPoint = require("XEntity/XTwoSideTower/XTwoSideTowerPoint")
function XTwoSideTowerChapter:Ctor(chapterId)
    self.Cfg = XTwoSideTowerConfigs.GetChapterCfg(chapterId)
    self.TotalFeatures = {}
    self.PointDataList = {}
    self.Cleared = false
    self.NextPointIndex = 0
    self.MaxChapterScore = 0
    self.FirstCleared = false
    self.SweepStageIds ={}
    for _, pointId in pairs(self.Cfg.PointIds) do
        self.PointDataList[pointId] = XTwoSideTowerPoint.New(pointId)
    end
end

function XTwoSideTowerChapter:GetTotalFeatures()
    return XTool.Clone(self.TotalFeatures)
end

function XTwoSideTowerChapter:GetId()
    return self.Cfg.Id
end

function XTwoSideTowerChapter:IsCleared()
    return self.Cleared
end

function XTwoSideTowerChapter:GetChapterName()
    return self.Cfg.Name
end

function XTwoSideTowerChapter:GetIcon()
    return self.Cfg.Icon
end

function XTwoSideTowerChapter:GetFubenPrefab()
    return self.Cfg.FubenPrefab
end

function XTwoSideTowerChapter:GetSecondName()
    return self.Cfg.SecondName
end

function XTwoSideTowerChapter:GetChapterOverviewDesc()
    return self.Cfg.OverviewDesc
end

function XTwoSideTowerChapter:GetChapterOverviewIcon()
    return self.Cfg.OverviewIcon
end

-- 获取章节当前分数
function XTwoSideTowerChapter:GetChapterScore()
    local score = 0
    for _, pointData in pairs(self.PointDataList) do
        score = score + pointData:GetPointScore()
    end
    return score
end

-- 获取当前分数对应图
function XTwoSideTowerChapter:GetChapterScoreIcon()
    local curScore = self:GetChapterScore()
    local scoreLv = 1
    for i, score in ipairs(self.Cfg.ScoreLevel) do
        if curScore >= score then
            scoreLv = i
        end
    end

    return XTwoSideTowerConfigs.GetScoreLevelIcon(scoreLv)
end

-- 获取最高分数
function XTwoSideTowerChapter:GetMaxChapterScore()
    return self.MaxChapterScore
end

-- 获取最高分数对应的分数等级
function XTwoSideTowerChapter:GetMaxChapterScoreLevel()
    local scoreLv = 1
    for i, score in ipairs(self.Cfg.ScoreLevel) do
        if self.MaxChapterScore >= score then
            scoreLv = i
        end
    end

    return scoreLv
end

function XTwoSideTowerChapter:GetMaxChapterScoreIcon()
    local scoreLv = self:GetMaxChapterScoreLevel()
    return XTwoSideTowerConfigs.GetScoreLevelIcon(scoreLv)
end

function XTwoSideTowerChapter:GetPointData()
    local list = {}
    for _,pointData in pairs(self.PointDataList) do
        table.insert(list, pointData)
    end
    table.sort(list,function(a,b)
        return a:GetId() < b:GetId()
    end)
    return list
end

-- 获取节点是否正向列表
function XTwoSideTowerChapter:GetPointPositiveDic()
    local positiveDic = {}
    for _, pointData in pairs(self.PointDataList) do
        local isPositive = self:IsPointPositive(pointData)
        local pointId = pointData:GetId()
        positiveDic[pointId] = isPositive
    end

    return positiveDic
end

-- 当前章节是否处于正向
function XTwoSideTowerChapter:IsPositive()
    local pointList = self:GetPointData()
    return self.NextPointIndex + 1 <= #pointList
end

-- 当前节点是否处于正向
function XTwoSideTowerChapter:IsPointPositive(pointData)
    local pointList = self:GetPointData()
    local index = -1
    for i, point in ipairs(pointList) do
        if point:GetId() == pointData:GetId() then
            index = i
        end
    end

    return index >= self.NextPointIndex + 1
end

function XTwoSideTowerChapter:IsFirstCleared()
    return self.FirstCleared
end

function XTwoSideTowerChapter:UpdateData(data)
    self.Cleared = data.Cleared
    self.NextPointIndex = data.NextPointIndex
    self.MaxChapterScore = data.MaxChapterScore
    self.TotalFeatures = data.TotalFeatures
    self.SweepStageIds = data.SweepStageIds
    self.FirstCleared = data.FirstCleared
    for _, pointData in pairs(data.PointDataList) do
        if not self.PointDataList[pointData.PointId] then
            self.PointDataList[pointData.PointId] = XTwoSideTowerPoint.New(pointData.PointId)
        end
        self.PointDataList[pointData.PointId]:UpdateData(pointData)
    end
end

function XTwoSideTowerChapter:UpdatePointData(pointData)
    if self.PointDataList[pointData.PointId] then
        self.PointDataList[pointData.PointId]:UpdateData(pointData)
    end
end

function XTwoSideTowerChapter:GetProcess()
    local now = XTime.GetServerNowTimestamp()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self.Cfg.TimeId)
    if now < startTime then
        return CS.XTextManager.GetText("XTwoSideTowerChapterTimeProcess", XUiHelper.GetTime(startTime - now, XUiHelper.TimeFormatType.ACTIVITY)), false
    end
    for _, chapterId in pairs(self.Cfg.UnlockChapterIds) do
        ---@type XTwoSideTowerChapter
        local chapter = XDataCenter.TwoSideTowerManager.GetChapter(chapterId)
        if not chapter:IsCleared() then
            return CS.XTextManager.GetText("XTwoSideTowerChapterConditionProcess", chapter:GetChapterName()), false
        end
    end
    return "", true
end

function XTwoSideTowerChapter:IsUnlockPoint(pointData)
    local pointList = self:GetPointData()
    local index = -1
    for i, point in ipairs(pointList) do
        if point:GetId() == pointData:GetId() then
            index = i
        end
    end
    if not self:IsPositive() then
        index = math.abs(index - #pointList)
        return index <= self.NextPointIndex - #pointList
    else
        -- 正向关卡打完直接转为逆向关卡，只有下一关卡可挑战
        return index == self.NextPointIndex + 1    
    end
    
end

function XTwoSideTowerChapter:CheckIsCanSweep(stageId)
    for _,id in pairs(self.SweepStageIds) do
        if id == stageId then
            return true
        end
    end
    return false
end

---@param pointData XTwoSideTowerPoint
function XTwoSideTowerChapter:GetNegativeFeatureList(pointData, isPositiveOrder)
    local pointList = self:GetPointData()
    local featureList = {}
    for i = #pointList, 1, -1 do
        local point = pointList[i]
        local featureId = point:GetNegativeStageFeatureId()
        table.insert(featureList, featureId)
        if pointData:GetId() == point:GetId() then
            break
        end
    end

    if isPositiveOrder and #featureList > 1 then
        local backOrderList = {}
        for i = #featureList, 1, -1 do
            table.insert(backOrderList, featureList[i])
        end
        featureList = backOrderList
    end

    return featureList
end

function XTwoSideTowerChapter:IsCurrPoint(pointData)
    local pointList = self:GetPointData()
    local index = -1
    for i, point in ipairs(pointList) do
        if point:GetId() == pointData:GetId() then
            index = i
        end
    end
    if not self:IsPositive() then
        index = math.abs(index - #pointList)
        return index == self.NextPointIndex - #pointList
    else
        return index == self.NextPointIndex + 1    
    end
    
end

return XTwoSideTowerChapter
