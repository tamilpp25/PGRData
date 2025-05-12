---@class XPokerGuessing2ConfigModel : XModel
local XPokerGuessing2ConfigModel = XClass(XModel, "XPokerGuessing2ConfigModel")

local PokerGuessing2TableKey = {
    PokerGuessing2Activity = { CacheType = XConfigUtil.CacheType.Normal },
    PokerGuessing2Card = { },
    PokerGuessing2Effect = { },
    PokerGuessing2Stage = { CacheType = XConfigUtil.CacheType.Normal },
    PokerGuessing2Story = { },
    PokerGuessing2Config = { DirPath = XConfigUtil.DirectoryType.Client, },
    PokerGuessing2Character = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XPokerGuessing2ConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/PokerGuessing2", PokerGuessing2TableKey)
end

---@return XTablePokerGuessing2Activity[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Activity) or {}
end

---@return XTablePokerGuessing2Activity
function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Activity, id, true)
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityTimeIdById(id)
    local config = self:GetPokerGuessing2ActivityConfigById(id)

    return config.TimeId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityMaxTipsCountById(id)
    local config = self:GetPokerGuessing2ActivityConfigById(id)

    return config.MaxTipsCount
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityBackAssetPathById(id)
    local config = self:GetPokerGuessing2ActivityConfigById(id)

    return config.BackAssetPath
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityShopSkipIdById(id)
    local config = self:GetPokerGuessing2ActivityConfigById(id)

    return config.ShopSkipId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2ActivityStoryIdById(id)
    local config = self:GetPokerGuessing2ActivityConfigById(id)

    return config.StoryId
end

---@return XTablePokerGuessing2Card[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2CardConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Card) or {}
end

---@return XTablePokerGuessing2Card
function XPokerGuessing2ConfigModel:GetPokerGuessing2CardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Card, id, false) or {}
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2CardPokerNumById(id)
    local config = self:GetPokerGuessing2CardConfigById(id)

    return config.PokerNum
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2CardFrontAssetPathById(id)
    local config = self:GetPokerGuessing2CardConfigById(id)

    return config.FrontAssetPath
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2CardSmallAssetPathById(id)
    local config = self:GetPokerGuessing2CardConfigById(id)

    return config.SmallCardPath
end

---@return XTablePokerGuessing2Effect[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2EffectConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Effect) or {}
end

---@return XTablePokerGuessing2Effect
function XPokerGuessing2ConfigModel:GetPokerGuessing2EffectConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Effect, id, false) or {}
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2EffectHandCardIdById(id)
    local config = self:GetPokerGuessing2EffectConfigById(id)

    return config.HandCardId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2EffectOpponentCardById(id)
    local config = self:GetPokerGuessing2EffectConfigById(id)

    return config.OpponentCard
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2EffectEffectTypeById(id)
    local config = self:GetPokerGuessing2EffectConfigById(id)

    return config.EffectType
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2EffectEffectValueById(id)
    local config = self:GetPokerGuessing2EffectConfigById(id)

    return config.EffectValue
end

---@return XTablePokerGuessing2Stage[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2StageConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Stage) or {}
end

---@return XTablePokerGuessing2Stage
function XPokerGuessing2ConfigModel:GetPokerGuessing2StageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Stage, id, false) or {}
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageActivityIdById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.ActivityId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StagePreStageById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.PreStage
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageTimeIdById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.TimeId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageCardGroupById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.CardGroup
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageWinRateById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.WinRate
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageRewardIdById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.RewardId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageEffectById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.Effect
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageNameById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.Name
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageNpcNameById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.NpcName
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageIconById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.Icon
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageEffectDescById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.EffectDesc
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineLevelById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineLevel
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineLevelStartById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineLevelStart
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineRoundWinById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineRoundWin
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineRoundLoseById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineRoundLose
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineRoundDrawById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineRoundDraw
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineGameWinById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineGameWin
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StageLineGaneLoseById(id)
    local config = self:GetPokerGuessing2StageConfigById(id)

    return config.LineGaneLose
end

---@return XTablePokerGuessing2Story[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Story) or {}
end

---@return XTablePokerGuessing2Story
function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Story, id, false) or {}
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryActivityIdById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.ActivityId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryCharacterIdById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.CharacterId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryUnlockItemIdById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.UnlockItemId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryCostById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.Cost
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryIconById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.Icon
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryStageIdById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.StageId
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryLineTipsById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.LineTips
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryLineRoundWinById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.LineRoundWin
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryLineRoundLoseById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.LineRoundLose
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryLineRoundDrawById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.LineRoundDraw
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2StoryLineGameWinById(id)
    local config = self:GetPokerGuessing2StoryConfigById(id)

    return config.LineGameWin
end

---@return XTablePokerGuessing2Config[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2ConfigConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Config) or {}
end

---@return XTablePokerGuessing2Config
function XPokerGuessing2ConfigModel:GetPokerGuessing2ConfigConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Config, id, false) or {}
end

function XPokerGuessing2ConfigModel:GetPokerGuessing2ConfigParamById(id)
    local config = self:GetPokerGuessing2ConfigConfigById(id)

    return config.Param
end

---@return XTablePokerGuessing2Character
function XPokerGuessing2ConfigModel:GetPokerGuessing2CharacterConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PokerGuessing2TableKey.PokerGuessing2Character, id, true)
end

---@return XTablePokerGuessing2Character[]
function XPokerGuessing2ConfigModel:GetPokerGuessing2CharacterConfigs()
    return self._ConfigUtil:GetByTableKey(PokerGuessing2TableKey.PokerGuessing2Character)
end

return XPokerGuessing2ConfigModel