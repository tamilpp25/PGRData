---@class XBossSingleFeature
local XBossSingleFeature = XClass(nil, "XBossSingleFeature")

function XBossSingleFeature:Ctor(featureId, stageId, characterIds)
    self:SetData(featureId, stageId, characterIds)
end

---@param config XTableBossSingleChallengeFeature
function XBossSingleFeature:SetData(featureId, stageId, characterIds)
    if featureId and stageId then
        local config = XMVCA.XFubenBossSingle:GetFeatureConfigById(featureId)
        local eventIds = config.FightEventIds
        local stageData = XMVCA.XFuben:GetStageData(stageId)

        self._FeatureId = config.Id
        self._Name = config.Name
        self._Desc = config.Desc
        self._Icon = config.Icon
        self._TriangleBg = config.TriangleBg
        self._TotalScore = XMVCA.XFubenBossSingle:GetStageTotalScoreByStageId(stageId)
        self._StageId = stageId
        self._Score = stageData and stageData.Score or 0
        self._FightEventIds = {}
        self._CharacterList = characterIds or {}
        self._IsRecording = false

        if not XTool.IsTableEmpty(eventIds) then
            for _, eventId in pairs(eventIds) do
                table.insert(self._FightEventIds, eventId)
            end
        end
    end
end

function XBossSingleFeature:GetFeatureId()
    return self._FeatureId
end

function XBossSingleFeature:GetName()
    return self._Name
end

function XBossSingleFeature:GetDesc()
    return self._Desc
end

function XBossSingleFeature:GetIcon()
    return self._Icon
end

function XBossSingleFeature:GetTriangleBg()
    return self._TriangleBg
end

function XBossSingleFeature:GetTotalScore()
    return self._TotalScore
end

function XBossSingleFeature:GetStageId()
    return self._StageId
end

function XBossSingleFeature:GetScore()
    return self._Score
end

function XBossSingleFeature:GetFightEventIds()
    return self._FightEventIds
end

function XBossSingleFeature:GetFightEventIdByIndex(index)
    return self._FightEventIds[index or 1]
end

function XBossSingleFeature:GetIsCharacterEmpty()
    return XTool.IsTableEmpty(self._CharacterList)
end

function XBossSingleFeature:GetCharacterList()
    return self._CharacterList
end

function XBossSingleFeature:GetCharacterByIndex(index)
    return self._CharacterList[index or 1]
end

function XBossSingleFeature:SetIsRecording(value)
    self._IsRecording = value
end

function XBossSingleFeature:GetIsRecording()
    return self._IsRecording
end

function XBossSingleFeature:GetIsRecord()
    return not (self:GetIsCharacterEmpty() and self:GetScore() == 0)
end

function XBossSingleFeature:CheckCharacterClash(characterId)
    if self:GetIsCharacterEmpty() then
        return false
    else
        for _, id in pairs(self._CharacterList) do
            if id == characterId then
                return true
            end
        end

        return false
    end
end

return XBossSingleFeature
