local XCourseStageData = require("XEntity/XCourse/XCourseStageData")
local XCourseChapterData = require("XEntity/XCourse/XCourseChapterData")
local tableInsert = table.insert

local XCourseData = XClass(nil, "XCourseData")

function XCourseData:Ctor()
    self._TotalLessonPoint = 0  --总课程绩点（通关StageType为1的章节对应的关卡才有数据）
    self._MaxTotalLessonPoint = 0  --总课程绩点（通关StageType为1的章节对应的关卡才有数据）
    self._ChapterDataList = {}  --章节
    self._StageDataDict = {}    --关卡
    self._RewardIds = {}        --已领取奖励id
end

function XCourseData:UpdateData(data)
    self._ChapterDataList = {}
    self._StageDataDict = {}
    self._RewardIds = {}
    self:SetTotalLessonPoint(data.TotalLessonPoint)
    self:SetMaxTotalLessonPoint(data.MaxTotalLessonPoint)
    self:UpdateChapterDataList(data.ChapterDataList)
    self:UpdateStageDataDict(data.StageDataDict)
    self:UpdateRewardIds(data.RewardIds)
end

-- 更新玩家章节进度数据
function XCourseData:UpdateChapterDataList(chapterDataList)
    for _, value in pairs(chapterDataList) do
        local chapterData = XCourseChapterData.New()
        chapterData:UpdateData(value)
        self._ChapterDataList[value.Id] = chapterData
    end
end

-- 更新玩家关卡进度数据
function XCourseData:UpdateStageDataDict(stageDataDict)
    for _, value in pairs(stageDataDict) do
        local stageData = XCourseStageData.New()
        stageData:UpdateData(value)
        self._StageDataDict[value.Id] = stageData
    end
end

-- 更新玩家奖励领取数据
function XCourseData:UpdateRewardIds(rewardIds)
    for _, value in pairs(rewardIds) do
        self._RewardIds[value] = true
    end
end

--==============================章节相关==============================
function XCourseData:SetTotalLessonPoint(point)
    self._TotalLessonPoint = point
end

function XCourseData:SetMaxTotalLessonPoint(point)
    self._MaxTotalLessonPoint = point
end

function XCourseData:GetTotalLessonPoint()
    return self._TotalLessonPoint
end

function XCourseData:GetMaxTotalLessonPoint()
    return self._MaxTotalLessonPoint
end

function XCourseData:GetChapterData(chapterId)
    return self._ChapterDataList[chapterId]
end

-- 获取玩家在某章节所获得的进度
function XCourseData:GetChapterTotalPoint(chapterId)
    local chapter = self:GetChapterData(chapterId)
    if chapter == nil then return 0 end
    return chapter:GetTotalPoint() or 0
end

-- 判断该章节是否满足通关条件
function XCourseData:CheckChapterIsClear(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return true
    end

    local chapter = self:GetChapterData(chapterId)
    if chapter == nil then return false end
    return chapter:GetIsClear() or false
end

-- 判断章节是否是满星通关
function XCourseData:CheckChapterIsFullStar(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return true
    end
    local stageIds = XCourseConfig.GetCourseChapterStageIdsById(chapterId)
    if XTool.IsTableEmpty(stageIds) then
        return false
    end
    local cfgStar, trueStar = 0, 0
    for _, stageId in ipairs(stageIds) do
        local stage = self._StageDataDict[stageId]
        local desc = XFubenConfigs.GetStarDesc(stageId)
        cfgStar = cfgStar + #desc
        trueStar = trueStar + (stage and XTool.GetStageStarsFlag(stage:GetStarsFlag(), #desc) or 0)
    end
    return trueStar == cfgStar
end

-- 获得关卡类型对应的所有章节已获得的总绩点
function XCourseData:GetTotalPointByStageType(stageType)
    local chapterIdList = XCourseConfig.GetChapterIdListByStageType(stageType)
    local totalPoint = 0
    for index, chapterId in ipairs(chapterIdList) do
        totalPoint = totalPoint + self:GetChapterTotalPoint(chapterId)
    end
    return totalPoint
end

-- 获取达成条件的章节数
function XCourseData:GetChapterAllCanDrawNumber(stageType)
    local chapterIdList = XCourseConfig.GetChapterIdListByStageType(stageType)
    local totalPoint = 0
    for _, chapterId in ipairs(chapterIdList) do
        if XDataCenter.CourseManager.CheckRewardAllCanDraw(chapterId) then
            totalPoint = totalPoint + 1
        end
    end
    return totalPoint
end
--====================================================================



--==============================关卡相关==============================
function XCourseData:GetStageStarsFlag(stageId)
    local stageData = self._StageDataDict[stageId]
    if XTool.IsTableEmpty(stageData) then return end
    return stageData:GetStarsFlag()
end

function XCourseData:CheckStageIsComplete(stageId)
    if not XTool.IsNumberValid(stageId) then
        return true
    end
    return not XTool.IsTableEmpty(self._StageDataDict[stageId])
end

function XCourseData:CheckStageIsFullStarComplete(stageId)
    if not XTool.IsNumberValid(stageId) then
        return true
    end
    local passed = not XTool.IsTableEmpty(self._StageDataDict[stageId])
    local fullStar = false
    if passed then
        local desc = XFubenConfigs.GetStarDesc(stageId)
        local stage = self._StageDataDict[stageId]
        local tureStar = (stage and XTool.GetStageStarsFlag(stage:GetStarsFlag(), #desc) or 0)
        fullStar = tureStar >= #desc
    end
    return passed and fullStar
end
--====================================================================



function XCourseData:CheckRewardIsDraw(courseRewardId)
    return self._RewardIds[courseRewardId] or false
end

return XCourseData