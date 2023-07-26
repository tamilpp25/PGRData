---@class XCharacterTowerRelation
local XCharacterTowerRelation = XClass(nil, "XCharacterTowerRelation")

function XCharacterTowerRelation:Ctor(relationId)
    self:UpdateRelationId(relationId)
end

function XCharacterTowerRelation:UpdateRelationId(relationId)
    self.RelationId = relationId
    self.Config = XFubenCharacterTowerConfigs.GetRelationConfig(relationId)
    self.ConfigDetail = XFubenCharacterTowerConfigs.GetRelationDetailConfig(relationId)
end

---@return XCharacterTowerRelationInfo
function XCharacterTowerRelation:GetRelationInfo()
    return XDataCenter.CharacterTowerManager.GetCharacterTowerRelationInfo(self.RelationId)
end

function XCharacterTowerRelation:GetRelationConditionIds()
    return self.Config.Conditions or {}
end

function XCharacterTowerRelation:GetRelationFightEventIds()
    return self.Config.FightEventIds or {}
end

function XCharacterTowerRelation:GetRelationStoryIdByIndex(index)
    local storyIds = self.Config.StoryIds or {}
    local storyId = storyIds[index] or ""
    if storyId == "-1" then
        storyId = ""
    end
    return storyId
end

function XCharacterTowerRelation:GetRelationFinishNumByIndex(index)
    local num = self.Config.FinishNums or {}
    return num[index] or 0
end

--region 羁绊详情配置

function XCharacterTowerRelation:GetRelationFettersPrefab()
    return self.ConfigDetail.FettersPrefab or ""
end

function XCharacterTowerRelation:GetRelationFettersTitleByIndex(index)
    local title = self.ConfigDetail.FettersTitles or {}
    return title[index] or ""
end

function XCharacterTowerRelation:GetRelationFettersDescribeByIndex(index)
    local desc = self.ConfigDetail.FettersDescribes or {}
    return desc[index] or ""
end

function XCharacterTowerRelation:GetRelationConditionTitleByIndex(index)
    local titles = self.ConfigDetail.ConditionTitles or {}
    return titles[index] or ""
end

function XCharacterTowerRelation:GetRelationConditionSkipIdByIndex(index)
    local skipIds = self.ConfigDetail.ConditionSkipId or {}
    return skipIds[index] or 0
end

--endregion

-- 获取条件的标题
function XCharacterTowerRelation:GetRelationConditionTitleByConditionId(conditionId)
    local conditionIds = self:GetRelationConditionIds()
    local isContain, index = table.contains(conditionIds, conditionId)
    if isContain then
        return self:GetRelationConditionTitleByIndex(index)
    end
    return ""
end

-- 获取条件的跳转Id
function XCharacterTowerRelation:GetRelationConditionSkipIdByConditionId(conditionId)
    local conditionIds = self:GetRelationConditionIds()
    local isContain, index = table.contains(conditionIds, conditionId)
    if isContain then
        return self:GetRelationConditionSkipIdByIndex(index)
    end
    return 0
end

-- 获取羁绊进度
function XCharacterTowerRelation:GetRelationProgress()
    local finishCount = 0
    local totalCount = 0

    local relationInfo = self:GetRelationInfo()
    local fightEventIds = self:GetRelationFightEventIds()
    
    totalCount = totalCount + #fightEventIds
    for index, eventId in pairs(fightEventIds) do
        if eventId > 0 then
            if relationInfo:CheckRelationUnlock(eventId) then
                finishCount = finishCount + 1
            end
        else
            local storyId = self:GetRelationStoryIdByIndex(index)
            if not string.IsNilOrEmpty(storyId) and relationInfo:CheckStoryPlayed(storyId) then
                finishCount = finishCount + 1
            end
        end
    end
    
    return finishCount, totalCount
end

-- 检查是否有已完成未激活的羁绊
function XCharacterTowerRelation:CheckRelationNotActive(characterId)
    local relationInfo = self:GetRelationInfo()
    local fightEventIds = self:GetRelationFightEventIds()
    local totalFinishNum = self:GetConditionFinishNums(characterId)
    for index, eventId in ipairs(fightEventIds) do
        local num = self:GetRelationFinishNumByIndex(index)
        if eventId > 0 then
            if not relationInfo:CheckRelationUnlock(eventId) and num <= totalFinishNum then
                return true, index
            end
        else
            local storyId = self:GetRelationStoryIdByIndex(index)
            if not string.IsNilOrEmpty(storyId) and not relationInfo:CheckStoryPlayed(storyId) and num <= totalFinishNum then
                return true, index
            end
        end
    end
    return false, 0
end

-- 获取条件完成的个数
function XCharacterTowerRelation:GetConditionFinishNums(characterId)
    local finishCount = 0
    local conditionIds = self:GetRelationConditionIds()
    for _, conditionId in pairs(conditionIds) do
        local result, _ = self:CheckFinishCondition(conditionId, characterId)
        if result then
            finishCount = finishCount + 1
        end
    end
    return finishCount
end

-- 返回 1已播放的数目、2完成任务的数目、3完成未播放的条件
function XCharacterTowerRelation:GetPlayConditionAndFinishConditionNums(characterId)
    local playCount = 0
    local finishCount = 0
    local unPlayConditions = {}
    local conditionIds = self:GetRelationConditionIds()
    for _, conditionId in pairs(conditionIds) do
        local isOpen, _ = self:CheckFinishCondition(conditionId, characterId)
        if isOpen then
            if XDataCenter.CharacterTowerManager.CheckRelationTaskPlayAnim(conditionId) then
                playCount = playCount + 1
            else
                table.insert(unPlayConditions, conditionId)
            end
            finishCount = finishCount + 1
        end
    end
    table.sort(unPlayConditions,function(a, b) 
        return a < b
    end)
    return playCount, finishCount, unPlayConditions
end

-- 检查羁绊是否激活
function XCharacterTowerRelation:CheckRelationActive(eventId, index)
    local relationInfo = self:GetRelationInfo()
    local fetterActive = false
    if eventId > 0 then
        fetterActive = relationInfo:CheckRelationUnlock(eventId)
    else
        local storyId = self:GetRelationStoryIdByIndex(index)
        if not string.IsNilOrEmpty(storyId) then
            fetterActive = relationInfo:CheckStoryPlayed(storyId)
        end
    end
    return fetterActive
end

-- 检查未播放的条件和已激活的羁绊是否相等
function XCharacterTowerRelation:CheckPlayAnimCondition(characterId)
    local playCount, finishCount, unPlayConditions = self:GetPlayConditionAndFinishConditionNums(characterId)
    local fetterActive = self:GetRelationProgress()
    if playCount < fetterActive and fetterActive <= finishCount then
        for i = 1, fetterActive - playCount do
            local conditionId = unPlayConditions[i]
            XDataCenter.CharacterTowerManager.SaveRelationTaskPlayAnim(conditionId)
        end
    end
end

function XCharacterTowerRelation:CheckFinishCondition(conditionId, characterId)
    local relationInfo = self:GetRelationInfo()
    local isFinish = relationInfo:CheckFinishCondition(conditionId)
    local isOpen, desc = XConditionManager.CheckCondition(conditionId, characterId)
    return isFinish or isOpen, desc
end

return XCharacterTowerRelation