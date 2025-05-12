---@class XLuckyTenantConfigModel : XModel
local XLuckyTenantConfigModel = XClass(XModel, "XLuckyTenantConfigModel")

local LuckyTenantTestTableKey = {
    LuckyTenantTestCase = { DirPath = XConfigUtil.DirectoryType.Share, },
}

local LuckyTenantRandomTableKey = {
    LuckyTenantChessCondition = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenantChessRandomGroup = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenantChessRound = { DirPath = XConfigUtil.DirectoryType.Share, },
}

local LuckyTenantTableKey = {
    LuckyTenantChess = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenantChessSkill = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenantChessType = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenantStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LuckyTenantStageTask = { DirPath = XConfigUtil.DirectoryType.Share, },
    LuckyTenantActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LuckyTenantTag = { DirPath = XConfigUtil.DirectoryType.Client, },
    LuckyTenantQuality = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XLuckyTenantConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant/LuckyTenantRandom", LuckyTenantRandomTableKey)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant", LuckyTenantTableKey)
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/LuckyTenant/Test", LuckyTenantTestTableKey)
end

---@return XTableLuckyTenantChessCondition[]
function XLuckyTenantConfigModel:GetLuckyTenantChessConditionConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantRandomTableKey.LuckyTenantChessCondition)
end

---@return XTableLuckyTenantChessCondition
function XLuckyTenantConfigModel:GetLuckyTenantChessConditionConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantRandomTableKey.LuckyTenantChessCondition, id, false)
end

function XLuckyTenantConfigModel:GetLuckyTenantChessConditionNameById(id)
    local config = self:GetLuckyTenantChessConditionConfigById(id)

    return config.Name
end

function XLuckyTenantConfigModel:GetLuckyTenantChessConditionTypeById(id)
    local config = self:GetLuckyTenantChessConditionConfigById(id)

    return config.Type
end

function XLuckyTenantConfigModel:GetLuckyTenantChessConditionParamsById(id)
    local config = self:GetLuckyTenantChessConditionConfigById(id)

    return config.Params
end

---@return XTableLuckyTenantChessRandomGroup[]
function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantRandomTableKey.LuckyTenantChessRandomGroup)
end

---@return XTableLuckyTenantChessRandomGroup
function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantRandomTableKey.LuckyTenantChessRandomGroup, id, true)
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupGroupIdById(id)
    local config = self:GetLuckyTenantChessRandomGroupConfigById(id)

    return config.GroupId
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupPieceIdById(id)
    local config = self:GetLuckyTenantChessRandomGroupConfigById(id)

    return config.PieceId
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupPieceWeightById(id)
    local config = self:GetLuckyTenantChessRandomGroupConfigById(id)

    return config.PieceWeight
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupConditionById(id)
    local config = self:GetLuckyTenantChessRandomGroupConfigById(id)

    return config.Condition
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRandomGroupIncreaseWeightById(id)
    local config = self:GetLuckyTenantChessRandomGroupConfigById(id)

    return config.IncreaseWeight
end

---@return XTableLuckyTenantChessRound[]
function XLuckyTenantConfigModel:GetLuckyTenantChessRoundConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantRandomTableKey.LuckyTenantChessRound)
end

---@return XTableLuckyTenantChessRound
function XLuckyTenantConfigModel:GetLuckyTenantChessRoundConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantRandomTableKey.LuckyTenantChessRound, id, false)
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRoundStageIdById(id)
    local config = self:GetLuckyTenantChessRoundConfigById(id)

    return config.StageId
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRoundStartRoundById(id)
    local config = self:GetLuckyTenantChessRoundConfigById(id)

    return config.StartRound
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRoundGroupById(id)
    local config = self:GetLuckyTenantChessRoundConfigById(id)

    return config.Group
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRoundFirstUseInRoundById(id)
    local config = self:GetLuckyTenantChessRoundConfigById(id)

    return config.FirstUseInRound
end

function XLuckyTenantConfigModel:GetLuckyTenantChessRoundFirstUseInStageById(id)
    local config = self:GetLuckyTenantChessRoundConfigById(id)

    return config.FirstUseInStage
end

---@return XTableLuckyTenantChess[]
function XLuckyTenantConfigModel:GetLuckyTenantChessConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantTableKey.LuckyTenantChess)
end

---@return XTableLuckyTenantChess
function XLuckyTenantConfigModel:GetLuckyTenantChessConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantChess, id, false)
end

function XLuckyTenantConfigModel:GetLuckyTenantChessTypeById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Type
end

function XLuckyTenantConfigModel:GetLuckyTenantChessQualityById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Quality
end

function XLuckyTenantConfigModel:GetLuckyTenantChessNameById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Name
end

function XLuckyTenantConfigModel:GetLuckyTenantChessDescById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Desc
end

function XLuckyTenantConfigModel:GetLuckyTenantChessValueById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Value
end

function XLuckyTenantConfigModel:GetLuckyTenantChessIconById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Icon
end

function XLuckyTenantConfigModel:GetLuckyTenantChessCanDeleteById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.CanDelete
end

function XLuckyTenantConfigModel:GetLuckyTenantChessCanDieById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.CanDie
end

function XLuckyTenantConfigModel:GetLuckyTenantChessPriorityById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Priority
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillIdById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.SkillId
end

function XLuckyTenantConfigModel:GetLuckyTenantChessTagById(id)
    local config = self:GetLuckyTenantChessConfigById(id)

    return config.Tag
end

---@return XTableLuckyTenantChessSkill[]
function XLuckyTenantConfigModel:GetLuckyTenantChessSkillConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantTableKey.LuckyTenantChessSkill)
end

---@return XTableLuckyTenantChessSkill
function XLuckyTenantConfigModel:GetLuckyTenantChessSkillConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantChessSkill, id, false)
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillTypeById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.Type
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillNameById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.Name
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillDescById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.Desc
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillParamsById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.Params
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillScoreById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.Score
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillPriorityById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.Priority
end

function XLuckyTenantConfigModel:GetLuckyTenantChessSkillIsPassiveById(id)
    local config = self:GetLuckyTenantChessSkillConfigById(id)

    return config.IsPassive
end

---@return XTableLuckyTenantChessType[]
function XLuckyTenantConfigModel:GetLuckyTenantChessTypeConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantTableKey.LuckyTenantChessType)
end

---@return XTableLuckyTenantChessType
function XLuckyTenantConfigModel:GetLuckyTenantChessTypeConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantChessType, id, false)
end

function XLuckyTenantConfigModel:GetLuckyTenantChessTypeNameById(id)
    local config = self:GetLuckyTenantChessTypeConfigById(id)
    if config then
        return config.Name
    end
end

function XLuckyTenantConfigModel:GetLuckyTenantChessTypeDescById(id)
    local config = self:GetLuckyTenantChessTypeConfigById(id)
    if not config then
        return false
    end
    return config.Desc
end

---@return XTableLuckyTenantStage[]
function XLuckyTenantConfigModel:GetLuckyTenantStageConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantTableKey.LuckyTenantStage)
end

---@return XTableLuckyTenantStage
function XLuckyTenantConfigModel:GetLuckyTenantStageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantStage, id, false)
end

function XLuckyTenantConfigModel:GetLuckyTenantStageNameById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.Name
end

function XLuckyTenantConfigModel:GetLuckyTenantStageInitialPieceById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.InitialPiece
end

function XLuckyTenantConfigModel:GetLuckyTenantStageInitialPieceNumById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.InitialPieceNum
end

function XLuckyTenantConfigModel:GetLuckyTenantStageSpecialPieceTypeById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.SpecialPieceType
end

function XLuckyTenantConfigModel:GetLuckyTenantStageSpecialScoreById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.SpecialScore
end

function XLuckyTenantConfigModel:GetLuckyTenantStageChallengeTaskGroupById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.ChallengeTaskGroup
end

function XLuckyTenantConfigModel:GetLuckyTenantStageWinTaskById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.WinTask
end

function XLuckyTenantConfigModel:GetLuckyTenantStageRowById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.Row
end

function XLuckyTenantConfigModel:GetLuckyTenantStageColumnById(id)
    local config = self:GetLuckyTenantStageConfigById(id)

    return config.Column
end

---@return XTableLuckyTenantStageTask[]
function XLuckyTenantConfigModel:GetLuckyTenantStageTaskConfigs()
    return self._ConfigUtil:GetByTableKey(LuckyTenantTableKey.LuckyTenantStageTask)
end

---@return XTableLuckyTenantStageTask
function XLuckyTenantConfigModel:GetLuckyTenantStageTaskConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantStageTask, id, true)
end

function XLuckyTenantConfigModel:GetLuckyTenantStageTaskStageIdById(id)
    local config = self:GetLuckyTenantStageTaskConfigById(id)

    return config.StageId
end

function XLuckyTenantConfigModel:GetLuckyTenantStageTaskNameById(id)
    local config = self:GetLuckyTenantStageTaskConfigById(id)

    return config.Name
end

function XLuckyTenantConfigModel:GetLuckyTenantStageTaskDescById(id)
    local config = self:GetLuckyTenantStageTaskConfigById(id)

    return config.Desc
end

function XLuckyTenantConfigModel:GetLuckyTenantStageTaskRoundById(id)
    local config = self:GetLuckyTenantStageTaskConfigById(id)

    return config.Round
end

function XLuckyTenantConfigModel:GetLuckyTenantStageTaskScoreById(id)
    local config = self:GetLuckyTenantStageTaskConfigById(id)

    return config.Score
end

function XLuckyTenantConfigModel:GetLuckyTenantStageTaskRewardPiecesById(id)
    local config = self:GetLuckyTenantStageTaskConfigById(id)

    return config.RewardPieces
end

function XLuckyTenantConfigModel:GetLuckyTenantActivityById(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantActivity, id, true)
    return config
end

function XLuckyTenantConfigModel:GetTestCase(id)
    self._ConfigUtil:Clear("Share/MiniActivity/LuckyTenant/Test/LuckyTenantTestCase.tab")
    local configs = self._ConfigUtil:GetByTableKey(LuckyTenantTestTableKey.LuckyTenantTestCase)
    local find = 0
    for i = 1, #configs do
        local config = configs[i]
        if config.SkillId == id then
            find = i
            break
        end
    end
    if find == 0 then
        return false
    end
    local result = {}
    local row = 4
    for i = find + row, find, -1 do
        local pos = configs[i].Pos
        for j = 1, 5 do
            local pieceId = pos[j] or 0
            table.insert(result, pieceId)
        end
    end
    return result
end

function XLuckyTenantConfigModel:GetTagIcon(tag)
    tag = tonumber(tag)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantTag, tag)
    if config then
        return config.Icon
    end
end

function XLuckyTenantConfigModel:GetQualityIconQuad(quality)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantQuality, quality)
    if config then
        return config.IconQuad
    end
end

function XLuckyTenantConfigModel:GetQualityIconCircle(quality)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(LuckyTenantTableKey.LuckyTenantQuality, quality)
    if config then
        return config.IconCircle
    end
end

function XLuckyTenantConfigModel:GetQualityIcon(quality, qualityIconType)
    local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
    if qualityIconType == XLuckyTenantEnum.QualityIcon.Circle then
        return self:GetQualityIconCircle(quality)
    end
    if qualityIconType == XLuckyTenantEnum.QualityIcon.Quad then
        return self:GetQualityIconQuad(quality)
    end
    return self:GetQualityIconQuad(quality)
end

return XLuckyTenantConfigModel