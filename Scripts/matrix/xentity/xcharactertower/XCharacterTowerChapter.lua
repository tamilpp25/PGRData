---@class XCharacterTowerChapter
local XCharacterTowerChapter = XClass(nil, "XCharacterTowerChapter")

function XCharacterTowerChapter:Ctor(chapterId)
    self:UpdateChapterId(chapterId)
end

function XCharacterTowerChapter:UpdateChapterId(chapterId)
    self.ChapterId = chapterId
    self.Config = XFubenCharacterTowerConfigs.GetChapterConfig(chapterId)
    self.ConfigDetail = XFubenCharacterTowerConfigs.GetChapterDetailConfig(chapterId)
end

---@return XCharacterTowerChapterInfo
function XCharacterTowerChapter:GetChapterInfo()
    return XDataCenter.CharacterTowerManager.GetCharacterTowerChapterInfo(self.ChapterId)
end

-- 获取章节类型
function XCharacterTowerChapter:GetChapterType()
    return self.Config.Type
end

-- 获取章节关卡ids
function XCharacterTowerChapter:GetChapterStageIds()
    return self.Config.StageIds or {}
end

-- 获取剧情章节奖励Id
function XCharacterTowerChapter:GetChapterRewardId()
    return self.Config.ChapterRewardId or 0
end

-- 获取挑战章节TreasureIds
function XCharacterTowerChapter:GetChapterTreasureIds()
    return self.Config.TreasureId or {}
end

function XCharacterTowerChapter:GetChapterImg()
    return self.Config.Img or ""
end

function XCharacterTowerChapter:GetChapterTitle()
    return self.Config.Title or ""
end

function XCharacterTowerChapter:GetChapterActivityTimeId()
    return self.Config.TimeId or 0
end

function XCharacterTowerChapter:GetChapterPrefab()
    return self.Config.Prefab or ""
end

function XCharacterTowerChapter:GetChapterCharacterId()
    return self.Config.CharacterId or 0
end

function XCharacterTowerChapter:GetChapterRelationGroupId()
    return self.Config.RelationGroupId or 0
end

--region 章节详情配置

function XCharacterTowerChapter:GetChapterRelatedChapterId()
    return self.ConfigDetail.RelatedChapterId or 0
end
    
function XCharacterTowerChapter:GetChapterName()
    return self.ConfigDetail.ChapterName or ""
end

function XCharacterTowerChapter:GetChapterPreviewRewardId()
    return self.ConfigDetail.PreviewRewardId or 0
end

function XCharacterTowerChapter:GetChapterShowRewardId()
    local showRewardId = self.ConfigDetail.ShowRewardId or 0
    if not XTool.IsNumberValid(showRewardId) then
        showRewardId = self:GetChapterPreviewRewardId()
    end
    return showRewardId
end

function XCharacterTowerChapter:GetChapterPassedBg()
    return self.ConfigDetail.StoryPassedBg or ""
end

function XCharacterTowerChapter:GetChapterUnPassedBg()
    return self.ConfigDetail.StoryUnPassedBg or ""
end

function XCharacterTowerChapter:GetChapterStorySpineBg()
    return self.ConfigDetail.StorySpineBg or ""
end

function XCharacterTowerChapter:GetChapterRewardIcon()
    return self.ConfigDetail.ChapterRewardIcon or ""
end

function XCharacterTowerChapter:GetChapterTaskSceneUrl()
    return self.ConfigDetail.TaskSceneUrl or ""
end

function XCharacterTowerChapter:GetChapterTaskModelUrl()
    return self.ConfigDetail.TaskModelUrl or ""
end

function XCharacterTowerChapter:GetChapterBattleBg()
    return self.ConfigDetail.BattleBg or ""
end

--endregion

-- 获取章节关卡进度
function XCharacterTowerChapter:GetChapterStageProgress()
    local finishCount = 0
    local totalCount = 0
    
    local chapterInfo = self:GetChapterInfo()
    local stageIds = self:GetChapterStageIds()
    for _, stageId in pairs(stageIds) do
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.FirstRewardShow > 0 then
            totalCount = totalCount + 1
            if chapterInfo:CheckStageRewardReceived(stageId) then
                finishCount = finishCount + 1
            end
        end
    end
    return finishCount, totalCount
end

-- 获取章节进度
function XCharacterTowerChapter:GetChapterProgress()
    local finishCount = 0
    local totalCount = 0
    local chapterInfo = self:GetChapterInfo()
    -- 关卡进度
    finishCount, totalCount = self:GetChapterStageProgress()
    -- 剧情章节奖励
    if self:GetChapterType() == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story then
        local chapterRewardId = self:GetChapterRewardId()
        if chapterRewardId > 0 then
            totalCount = totalCount + 1
            if chapterInfo:CheckChapterRewardReceived(self.ChapterId) then
                finishCount = finishCount + 1
            end
        end
    end
    -- 挑战星级奖励
    if self:GetChapterType() == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge then
        local treasureIds = self:GetChapterTreasureIds()
        for _, treasureId in pairs(treasureIds) do
            local rewardId = XFubenCharacterTowerConfigs.GetRewardIdByTreasureId(treasureId)
            if rewardId > 0 then
                totalCount = totalCount + 1
                if chapterInfo:CheckTreasureRewardReceived(treasureId) then
                    finishCount = finishCount + 1
                end
            end
        end
    end

    return finishCount, totalCount
end

-- 获取关卡界面名
function XCharacterTowerChapter:GetOpenChapterUiName()
    if self:GetChapterType() == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story then
        return "UiCharacterTowerPlot"
    else
        return "UiCharacterTowerBattle"
    end
end

-- 获取章节星数
function XCharacterTowerChapter:GetChapterStars()
    local stageIds = self:GetChapterStageIds()
    local stars = 0
    for _, stageId in pairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        stars = stars + stageInfo.Stars
    end
    local treasureIds = self:GetChapterTreasureIds()
    if XTool.IsTableEmpty(treasureIds) then
        return stars, 0
    end
    local totalStars = XFubenCharacterTowerConfigs.GetRequireStarByTreasureId(treasureIds[#treasureIds])
    --stars = stars > totalStars and totalStars or stars
    
    return stars, totalStars
end

-- 检查章节关卡奖励是否都已领取
function XCharacterTowerChapter:CheckChapterStageRewardFinish()
    local finishCount, totalCount = self:GetChapterStageProgress()
    return finishCount == totalCount
end

-- 检查所有关卡是否都通关
function XCharacterTowerChapter:CheckChapterStageIdsPassed()
    local stageIds = self:GetChapterStageIds()
    for _, stageId in pairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Passed then
            return false
        end
    end
    return true
end

-- 检查是否有已完成未领取的奖励
function XCharacterTowerChapter:CheckChapterRewardAchieved()
    local chapterInfo = self:GetChapterInfo()
    -- 关卡
    local stageIds = self:GetChapterStageIds()
    for _, stageId in pairs(stageIds) do
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageCfg.FirstRewardShow > 0 and stageInfo.Passed and not chapterInfo:CheckStageRewardReceived(stageId) then
            return true
        end
    end
    -- 剧情章节奖励
    if self:GetChapterType() == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story then
        local chapterRewardId = self:GetChapterRewardId()
        local isAllPassed = self:CheckChapterStageIdsPassed()
        if chapterRewardId > 0 and isAllPassed and not chapterInfo:CheckChapterRewardReceived(self.ChapterId) then
            return true
        end
    end
    -- 挑战星级奖励
    if self:GetChapterType() == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge then
        local treasureIds = self:GetChapterTreasureIds()
        local starCount = self:GetChapterStars()
        for _, treasureId in pairs(treasureIds) do
            local rewardId = XFubenCharacterTowerConfigs.GetRewardIdByTreasureId(treasureId)
            local requireStar = XFubenCharacterTowerConfigs.GetRequireStarByTreasureId(treasureId)
            if rewardId > 0 and requireStar > 0 and requireStar <= starCount and not chapterInfo:CheckTreasureRewardReceived(treasureId) then
                return true
            end
        end
    end
    return false
end

-- 检查章节条件
function XCharacterTowerChapter:CheckChapterCondition()
    local inActivity = self:CheckChapterInActivity()
    if inActivity then
        return self:CheckChapterActivityCondition()
    else
        return self:CheckChapterOpenCondition()
    end
end

-- 检查开启条件
function XCharacterTowerChapter:CheckChapterOpenCondition()
    local conditionIds = self.Config.OpenCondition
    for _, conditionId in ipairs(conditionIds) do
        if XTool.IsNumberValid(conditionId) then
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            if not isOpen then
                return isOpen, desc
            end
        end
    end
    return true, ""
end

-- 检测是否在活动中
function XCharacterTowerChapter:CheckChapterInActivity()
    local isActivityChapter = XDataCenter.CharacterTowerManager.CheckActivityChapterId(self.ChapterId)
    local isActivityTime = XFunctionManager.CheckInTimeByTimeId(self.Config.TimeId)
    return isActivityChapter and isActivityTime
end

-- 检测活动条件
function XCharacterTowerChapter:CheckChapterActivityCondition()
    local conditionIds = self.Config.ActivityCondition
    for _, conditionId in ipairs(conditionIds) do
        if XTool.IsNumberValid(conditionId) then
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            if not isOpen then
                return isOpen, desc
            end
        end
    end
    return true, ""
end

return XCharacterTowerChapter