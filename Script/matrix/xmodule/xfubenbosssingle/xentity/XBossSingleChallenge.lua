local XBossSingleFeature = require("XModule/XFubenBossSingle/XData/XBossSingleFeature")
local XBossSingleSelfRankInfo = require("XModule/XFubenBossSingle/XData/XBossSingleSelfRankInfo")

---@class XBossSingleChallenge
local XBossSingleChallenge = XClass(nil, "XBossSingleChallenge")

function XBossSingleChallenge:Ctor()
    ---@type XBossSingleFeature[]
    self._FeatureList = {}
    ---@type table<number, XBossSingleFeature>
    self._FeatureMap = {}
    ---@type XBossSingleSelfRankInfo
    self._SelfRankInfo = nil
    self._ModelId = nil
    self._IsEmpty = true
end

---@param bossSingle XBossSingle
function XBossSingleChallenge:SetDataWithBossSingleData(bossSingle)
    local sectionId = bossSingle:GetBossSingleChallengeSectionId()
    local featureGroupId = bossSingle:GetBossSingleChallengeFeatureGroupId()
    local featureIds = XMVCA.XFubenBossSingle:GetFeatureIdsByFeatureGroupId(featureGroupId)
    local stageIds = XMVCA.XFubenBossSingle:GetStageIdsById(sectionId)
    local count = math.min(#featureIds, #stageIds)

    self._FeatureMap = {}
    self._IsEmpty = false
    if count ~= 0 then
        self._ModelId = XMVCA.XFubenBossSingle:GetModelIdByStageId(stageIds[count])
    end
    for i = 1, count do
        local history = bossSingle:FindChallengeStageHistoryByStageId(stageIds[i])
        local characters = history and history:GetCharacterList() or nil
        local feature = self._FeatureList[i]

        if not feature then
            self._FeatureList[i] = XBossSingleFeature.New(featureIds[i], stageIds[i], characters)
        else
            feature:SetData(featureIds[i], stageIds[i], characters)
        end
        self._FeatureMap[featureIds[i]] = self._FeatureList[i]
    end
    for i = count + 1, #self._FeatureList do
        self._FeatureList[i] = nil
    end

    self:__InitFeatureRecordTag()
end

function XBossSingleChallenge:GetIsEmpty()
    return self._IsEmpty
end

function XBossSingleChallenge:GetRecordFeatureCount()
    local count = 0

    if not XTool.IsTableEmpty(self._FeatureList) then
        for _, feature in pairs(self._FeatureList) do
            if feature:GetIsRecord() then
                count = count + 1
            end
        end
    end

    return count
end

function XBossSingleChallenge:GetRecordingFeatureCount()
    local count = 0

    if not XTool.IsTableEmpty(self._FeatureList) then
        for _, feature in pairs(self._FeatureList) do
            if feature:GetIsRecording() then
                count = count + 1
            end
        end
    end

    return count
end

---@return XBossSingleFeature
function XBossSingleChallenge:GetFeatureById(featureId)
    return self._FeatureMap[featureId]
end

---@return XBossSingleFeature
function XBossSingleChallenge:GetFeatureByIndex(index)
    return self._FeatureList[index]
end

function XBossSingleChallenge:GetFeatureCount()
    return #self._FeatureList
end

function XBossSingleChallenge:GetSelfRank()
    if self:IsSelfRankInfoEmpty() then
        return 0
    else
        return self._SelfRankInfo:GetRank()
    end
end

function XBossSingleChallenge:GetTotalRank()
    if self:IsSelfRankInfoEmpty() then
        return 0
    else
        return self._SelfRankInfo:GetTotalRank()
    end
end

function XBossSingleChallenge:GetBossModelId()
    return self._ModelId or ""
end

function XBossSingleChallenge:CheckCharacterClash(characterId)
    if not characterId then
        return false
    else
        return self:GetClashFeature(characterId) ~= nil
    end
end

---@return XBossSingleFeature
function XBossSingleChallenge:GetClashFeature(characterId)
    if not characterId then
        return nil
    else
        if XTool.IsTableEmpty(self._FeatureList) then
            return 0
        else
            for _, feature in pairs(self._FeatureList) do
                if feature:CheckCharacterClash(characterId) then
                    return feature
                end
            end
    
            return nil
        end
    end
end

function XBossSingleChallenge:GetFeatureByStageId(stageId)
    local index = self:GetFeatureIndexByStageId(stageId)

    if XTool.IsNumberValid(index) then
        return self:GetFeatureByIndex(index)
    end

    return nil
end

function XBossSingleChallenge:GetFeatureIndexByStageId(stageId)
    if not stageId then
        return 0
    else
        if XTool.IsTableEmpty(self._FeatureList) then
            return 0
        else
            for i, feature in pairs(self._FeatureList) do
                if feature:GetStageId() == stageId then
                    return i
                end
            end
    
            return 0
        end
    end
end

function XBossSingleChallenge:GetStageIdByIndex(index)
    local feature = self:GetFeatureByIndex(index)

    if feature then
        return feature:GetStageId()
    else
        return 0
    end
end

function XBossSingleChallenge:SetSelfRankInfo(info)
    if not self._SelfRankInfo then
        self._SelfRankInfo = XBossSingleSelfRankInfo.New(info)
    else
        self._SelfRankInfo:SetData(info)
    end
end

function XBossSingleChallenge:IsSelfRankInfoEmpty()
    return not self._SelfRankInfo or self._SelfRankInfo:GetIsEmpty()
end

--- 设置计分标记
function XBossSingleChallenge:__InitFeatureRecordTag()
    local minScore = math.huge
    local recordFeatureList = {}

    for i, feature in pairs(self._FeatureList) do
        if feature:GetIsRecord() then
            feature:SetIsRecording(true)
            table.insert(recordFeatureList, feature)
        end
    end

    if #recordFeatureList <= 2 then
        return
    end

    table.sort(recordFeatureList, function(itemA, itemB)
        return itemA:GetScore() > itemB:GetScore()
    end)
    for i, feature in pairs(recordFeatureList) do
        if i > 2 then
            feature:SetIsRecording(false)
        end
    end
end

return XBossSingleChallenge
