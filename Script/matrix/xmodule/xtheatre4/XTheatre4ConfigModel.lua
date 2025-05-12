---@class XTheatre4ConfigModel : XModel
local XTheatre4ConfigModel = XClass(XModel, "XTheatre4ConfigModel")
--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local Theatre4TableKey = {
    Theatre4Activity = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre4ColorResource = {},
    Theatre4Config = { ReadFunc = XConfigUtil.ReadType.String, Identifier = "Key", },
    Theatre4Difficulty = {},
    Theatre4DifficultyStar = {},
    Theatre4Effect = {},
    Theatre4EffectGroup = {},
    Theatre4Event = {},
    Theatre4EventGroup = {},
    Theatre4EventOption = {},
    Theatre4Fight = {},
    Theatre4FightGroup = {},
    Theatre4FightMold = {},
    Theatre4Item = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre4ItemBox = {},
    Theatre4ItemGroup = {},
    Theatre4RecruitTicket = {},
    Theatre4Reward = {},
    Theatre4RewardDrop = {},
    Theatre4Shop = {},
    Theatre4ShopGoods = {},
    Theatre4Tech = {},
    Theatre4Affix = {},
    Theatre4Character = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre4CharacterStar = {},
    Theatre4Building = {},
    Theatre4Fate = {},
    Theatre4FateEvent = {},
    Theatre4ColorTalent = {},
    Theatre4MapClient = { DirPath = XConfigCenter.DirectoryType.Client },
    Theatre4MapIndex = { DirPath = XConfigCenter.DirectoryType.Client },
    Theatre4Asset = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigCenter.DirectoryType.Client },
    Theatre4ClientConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key"
    },
    Theatre4BattlePass = {
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "Level",
    },
    Theatre4Task = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre4ColorTalentSlot = {},
    Theatre4ColorTalentPool = {},
    Theatre4ColorTalentTree = {},
    Theatre4Ending = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre4BoxGroup = {},
    Theatre4Reboot = { CacheType = XConfigUtil.CacheType.Normal },
    Theatre4BlockIcon = { DirPath = XConfigCenter.DirectoryType.Client },
    Theatre4ItemEffectCount = { DirPath = XConfigCenter.DirectoryType.Client },
    Theatre4ScientificSpEffect = { DirPath = XConfigCenter.DirectoryType.Client },
    Theatre4Traceback = {},
}

local Theatre4MapTableKey = {
    Theatre4Map = {},
    Theatre4MapBlueprint = {},
    Theatre4MapHiddenGrid = {},
    Theatre4MapGroup = {},
}

function XTheatre4ConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("Theatre4", Theatre4TableKey)
    self._ConfigUtil:InitConfigByTableKey("Theatre4/Theatre4Map", Theatre4MapTableKey)
end

---@return XTableTheatre4Activity[]
function XTheatre4ConfigModel:GetActivityConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Activity) or {}
end

---@return XTableTheatre4Activity
function XTheatre4ConfigModel:GetActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Activity, id) or {}
end

function XTheatre4ConfigModel:GetActivityNameById(id)
    local config = self:GetActivityConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetActivityTimeIdById(id)
    local config = self:GetActivityConfigById(id)
    return config.TimeId
end

---@return XTableTheatre4ColorResource[]
function XTheatre4ConfigModel:GetColorResourceConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ColorResource) or {}
end

---@return XTableTheatre4ColorResource
function XTheatre4ConfigModel:GetColorResourceConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ColorResource, id) or {}
end

function XTheatre4ConfigModel:GetColorResourceGroupIdById(id)
    local config = self:GetColorResourceConfigById(id)
    return config.GroupId
end

function XTheatre4ConfigModel:GetColorResourceColorById(id)
    local config = self:GetColorResourceConfigById(id)
    return config.Color
end

function XTheatre4ConfigModel:GetColorResourceWeightById(id)
    local config = self:GetColorResourceConfigById(id)
    return config.Weight
end

function XTheatre4ConfigModel:GetColorResourceResourceById(id)
    local config = self:GetColorResourceConfigById(id)
    return config.Resource
end

---@return XTableTheatre4Config[]
function XTheatre4ConfigModel:GetConfigConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Config) or {}
end

---@return XTableTheatre4Config
function XTheatre4ConfigModel:GetConfigConfigByKey(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Config, key) or {}
end

function XTheatre4ConfigModel:GetConfigDescByKey(key)
    local config = self:GetConfigConfigByKey(key)
    return config.Desc
end

function XTheatre4ConfigModel:GetConfigValuesByKey(key)
    local config = self:GetConfigConfigByKey(key)
    return config.Values
end

---@return XTableTheatre4Difficulty[]
function XTheatre4ConfigModel:GetDifficultyConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Difficulty) or {}
end

---@return XTableTheatre4Difficulty
function XTheatre4ConfigModel:GetDifficultyConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Difficulty, id) or {}
end

function XTheatre4ConfigModel:GetDifficultyNameById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetDifficultyDescById(id)
    local config = self:GetDifficultyConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetDifficultyStoryDescById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.StoryDesc
end

function XTheatre4ConfigModel:GetDifficultyConditionIdById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.ConditionId
end

function XTheatre4ConfigModel:GetDifficultyDifficultRateById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.DifficultRate
end

function XTheatre4ConfigModel:GetDifficultyBPExpRateById(id)
    local config = self:GetDifficultyConfigById(id)
    return math.roundDecimals((config.BPExpRate or 0), 1)
end

function XTheatre4ConfigModel:GetDifficultyTechPointRateById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.TechPointRate
end

function XTheatre4ConfigModel:GetDifficultyRebootIdById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.RebootId
end

function XTheatre4ConfigModel:GetDifficultyActionPointById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.ActionPoint
end

function XTheatre4ConfigModel:GetDifficultyHpById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.Hp
end

function XTheatre4ConfigModel:GetDifficultyHpActionPointById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.HpActionPoint
end

function XTheatre4ConfigModel:GetDifficultyEnergyById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.Energy
end

function XTheatre4ConfigModel:GetDifficultyReEnergyById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.ReEnergy
end

function XTheatre4ConfigModel:GetDifficultyStarGroupIdsById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.StarGroupIds
end

function XTheatre4ConfigModel:GetDifficultySnowEffectById(id)
    local config = self:GetDifficultyConfigById(id)
    return config.SnowEffect
end

---@return XTableTheatre4Effect[]
function XTheatre4ConfigModel:GetEffectConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Effect) or {}
end

---@return XTableTheatre4Effect
function XTheatre4ConfigModel:GetEffectConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Effect, id) or {}
end

function XTheatre4ConfigModel:GetEffectDescById(id)
    local config = self:GetEffectConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetEffectOtherDescById(id)
    local config = self:GetEffectConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc1)
end

function XTheatre4ConfigModel:GetEffectTypeById(id)
    local config = self:GetEffectConfigById(id)
    return config.Type
end

function XTheatre4ConfigModel:GetEffectParamsById(id)
    local config = self:GetEffectConfigById(id)
    return config.Params
end

function XTheatre4ConfigModel:GetEffectSkillCostTypeById(id)
    local config = self:GetEffectConfigById(id)
    return config.SkillCostType
end

function XTheatre4ConfigModel:GetEffectSkillCostIdById(id)
    local config = self:GetEffectConfigById(id)
    return config.SkillCostId
end

function XTheatre4ConfigModel:GetEffectSkillCostCountById(id)
    local config = self:GetEffectConfigById(id)
    return config.SkillCostCount
end

function XTheatre4ConfigModel:GetEffectSkillCostUpById(id)
    local config = self:GetEffectConfigById(id)
    return config.SkillCostUp
end

---@return XTableTheatre4EffectGroup[]
function XTheatre4ConfigModel:GetEffectGroupConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4EffectGroup) or {}
end

---@return XTableTheatre4EffectGroup
function XTheatre4ConfigModel:GetEffectGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4EffectGroup, id) or {}
end

function XTheatre4ConfigModel:GetEffectGroupDescById(id)
    local config = self:GetEffectGroupConfigById(id)
    return config.Desc
end

function XTheatre4ConfigModel:GetEffectGroupFightEventsById(id)
    local config = self:GetEffectGroupConfigById(id)
    return config.FightEvents
end

function XTheatre4ConfigModel:GetEffectGroupEffectsById(id)
    local config = self:GetEffectGroupConfigById(id)
    return config.Effects
end

---@return XTableTheatre4Event[]
function XTheatre4ConfigModel:GetEventConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Event) or {}
end

---@return XTableTheatre4Event
function XTheatre4ConfigModel:GetEventConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Event, id) or {}
end

function XTheatre4ConfigModel:GetEventTypeById(id)
    local config = self:GetEventConfigById(id)
    return config.Type
end

function XTheatre4ConfigModel:GetEventNextEventGroupById(id)
    local config = self:GetEventConfigById(id)
    return config.NextEventGroup
end

function XTheatre4ConfigModel:GetEventOptionGroupIdById(id)
    local config = self:GetEventConfigById(id)
    return config.OptionGroupId
end

function XTheatre4ConfigModel:GetEventFightIdById(id)
    local config = self:GetEventConfigById(id)
    return config.FightId
end

function XTheatre4ConfigModel:GetEventRewardIdsById(id)
    local config = self:GetEventConfigById(id)
    return config.RewardId
end

function XTheatre4ConfigModel:GetEventRoleIconById(id)
    local config = self:GetEventConfigById(id)
    return config.RoleIcon
end

function XTheatre4ConfigModel:GetEventRoleNameById(id)
    local config = self:GetEventConfigById(id)
    return config.RoleName
end

function XTheatre4ConfigModel:GetEventRoleContentById(id)
    local config = self:GetEventConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.RoleContent)
end

function XTheatre4ConfigModel:GetEventRoleEffectById(id)
    local config = self:GetEventConfigById(id)
    return config.RoleEffect
end

function XTheatre4ConfigModel:GetEventConfirmContentById(id)
    local config = self:GetEventConfigById(id)
    return config.ConfirmContent
end

function XTheatre4ConfigModel:GetEventIsEndById(id)
    local config = self:GetEventConfigById(id)
    return config.IsEnd
end

function XTheatre4ConfigModel:GetEventIsForcePlayById(id)
    local config = self:GetEventConfigById(id)
    return config.IsForcePlay
end

function XTheatre4ConfigModel:GetEventBgAssetById(id)
    local config = self:GetEventConfigById(id)
    return config.BgAsset
end

function XTheatre4ConfigModel:GetEventStoryIdById(id)
    local config = self:GetEventConfigById(id)
    return config.StoryId
end

-- 获取事件名称
function XTheatre4ConfigModel:GetEventNameById(id)
    local config = self:GetEventConfigById(id)
    return config.Name
end

-- 获取事件图标
function XTheatre4ConfigModel:GetEventIconById(id)
    local config = self:GetEventConfigById(id)
    return config.Icon
end

-- 获取事件块图标
function XTheatre4ConfigModel:GetEventBlockIconById(id)
    local config = self:GetEventConfigById(id)
    return config.BlockIcon
end

function XTheatre4ConfigModel:GetEventTitleById(id)
    local config = self:GetEventConfigById(id)
    return config.Title
end

function XTheatre4ConfigModel:GetEventTitleContentById(id)
    local config = self:GetEventConfigById(id)
    return config.TitleContent
end

function XTheatre4ConfigModel:GetEventDescById(id)
    local config = self:GetEventConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetEventUnOpenDescById(id)
    local config = self:GetEventConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.UnOpenDesc)
end

---@return XTableTheatre4EventGroup[]
function XTheatre4ConfigModel:GetEventGroupConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4EventGroup) or {}
end

---@return XTableTheatre4EventGroup
function XTheatre4ConfigModel:GetEventGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4EventGroup, id) or {}
end

function XTheatre4ConfigModel:GetEventGroupGroupIdById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.GroupId
end

function XTheatre4ConfigModel:GetEventGroupEventIdById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.EventId
end

function XTheatre4ConfigModel:GetEventGroupWeightById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.Weight
end

function XTheatre4ConfigModel:GetEventGroupGameRepeatableById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.GameRepeatable
end

function XTheatre4ConfigModel:GetEventGroupConditionIdById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.ConditionId
end

function XTheatre4ConfigModel:GetEventGroupLinkGroupIdById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.LinkGroupId
end

function XTheatre4ConfigModel:GetEventGroupAddWeightById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.AddWeight
end

function XTheatre4ConfigModel:GetEventGroupAddWeightConditionById(id)
    local config = self:GetEventGroupConfigById(id)
    return config.AddWeightCondition
end

---@return XTableTheatre4EventOption[]
function XTheatre4ConfigModel:GetEventOptionConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4EventOption) or {}
end

---@return XTableTheatre4EventOption
function XTheatre4ConfigModel:GetEventOptionConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4EventOption, id) or {}
end

function XTheatre4ConfigModel:GetEventOptionOptionDescById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionDesc
end

function XTheatre4ConfigModel:GetEventOptionOptionTypeById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionType
end

function XTheatre4ConfigModel:GetEventOptionOptionDownDescById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionDownDesc
end

function XTheatre4ConfigModel:GetEventOptionOptionTypeById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionType
end

function XTheatre4ConfigModel:GetEventOptionOptionItemTypeById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionItemType
end

function XTheatre4ConfigModel:GetEventOptionOptionItemIdById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionItemId
end

function XTheatre4ConfigModel:GetEventOptionOptionItemCountById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionItemCount
end

function XTheatre4ConfigModel:GetEventOptionOptionStageScoreMinById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionStageScoreMin
end

function XTheatre4ConfigModel:GetEventOptionOptionStageScoreMaxById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionStageScoreMax
end

function XTheatre4ConfigModel:GetEventOptionNextEventGroupIdById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.NextEventGroupId
end

function XTheatre4ConfigModel:GetEventOptionOptionConditionById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionCondition
end

function XTheatre4ConfigModel:GetEventOptionOptionShowConditionById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionShowCondition
end

function XTheatre4ConfigModel:GetEventOptionOptionIconById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.OptionIcon
end

function XTheatre4ConfigModel:GetEventOptionEffectGroupIdById(id)
    local config = self:GetEventOptionConfigById(id)
    return config.EffectGroupId
end

---@return XTableTheatre4Fight[]
function XTheatre4ConfigModel:GetFightConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Fight) or {}
end

---@return XTableTheatre4Fight
function XTheatre4ConfigModel:GetFightConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Fight, id) or {}
end

function XTheatre4ConfigModel:GetFightMoldIdById(id)
    local config = self:GetFightConfigById(id)
    return config.MoldId
end

function XTheatre4ConfigModel:GetFightTypeById(id)
    local config = self:GetFightConfigById(id)
    return config.FightType
end

function XTheatre4ConfigModel:GetFightDifficultyById(id)
    local config = self:GetFightConfigById(id)
    return config.Difficulty
end

function XTheatre4ConfigModel:GetFightRewardDropIdById(id)
    local config = self:GetFightConfigById(id)
    return config.RewardDropId
end

function XTheatre4ConfigModel:GetFightEventIdById(id)
    local config = self:GetFightConfigById(id)
    return config.EventId
end

function XTheatre4ConfigModel:GetFightPunishTermById(id)
    local config = self:GetFightConfigById(id)
    return config.PunishTerm
end

function XTheatre4ConfigModel:GetFightPunishEffectGroupById(id)
    local config = self:GetFightConfigById(id)
    return config.PunishEffectGroup
end

function XTheatre4ConfigModel:GetFightNameById(id)
    local config = self:GetFightConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetFightPanelNameById(id)
    local config = self:GetFightConfigById(id)
    return config.PanelName
end

function XTheatre4ConfigModel:GetFightIconById(id)
    local config = self:GetFightConfigById(id)
    return config.Icon
end

function XTheatre4ConfigModel:GetFightBlockIconById(id)
    local config = self:GetFightConfigById(id)
    return config.BlockIcon
end

function XTheatre4ConfigModel:GetFightHeadIconById(id)
    local config = self:GetFightConfigById(id)
    return config.HeadIcon
end

function XTheatre4ConfigModel:GetFightDescById(id)
    local config = self:GetFightConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetFightNextFightIdById(id)
    local config = self:GetFightConfigById(id)
    return config.NextFightId
end

function XTheatre4ConfigModel:GetFightNextFightConditionById(id)
    local config = self:GetFightConfigById(id)
    return config.NextFightCondition
end

---@return XTableTheatre4FightGroup[]
function XTheatre4ConfigModel:GetFightGroupConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4FightGroup) or {}
end

---@return XTableTheatre4FightGroup
function XTheatre4ConfigModel:GetFightGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4FightGroup, id) or {}
end

function XTheatre4ConfigModel:GetFightGroupGroupIdById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.GroupId
end

function XTheatre4ConfigModel:GetFightGroupFightNodeIdById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.FightNodeId
end

function XTheatre4ConfigModel:GetFightGroupWeightById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.Weight
end

function XTheatre4ConfigModel:GetFightGroupRepeatableById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.Repeatable
end

function XTheatre4ConfigModel:GetFightGroupRepeatWeightById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.RepeatWeight
end

function XTheatre4ConfigModel:GetFightGroupConditionById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.Condition
end

function XTheatre4ConfigModel:GetFightGroupDifficultyById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.Difficult
end

function XTheatre4ConfigModel:GetFightGroupClearCostById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.ClearCost
end

function XTheatre4ConfigModel:GetFightGroupRedClearCostById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.ClearRedColorCost
end

function XTheatre4ConfigModel:GetFightGroupProsperityLimitById(id)
    local config = self:GetFightGroupConfigById(id)
    return config.ProsperityLimit
end

---@return XTableTheatre4FightMold[]
function XTheatre4ConfigModel:GetFightMoldConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4FightMold) or {}
end

---@return XTableTheatre4FightMold
function XTheatre4ConfigModel:GetFightMoldConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4FightMold, id) or {}
end

function XTheatre4ConfigModel:GetFightMoldStageIdById(id)
    local config = self:GetFightMoldConfigById(id)
    return config.StageId
end

function XTheatre4ConfigModel:GetFightMoldMonsterGroupIdById(id)
    local config = self:GetFightMoldConfigById(id)
    return config.MonsterGroupId
end

function XTheatre4ConfigModel:GetFightMoldModeById(id)
    local config = self:GetFightMoldConfigById(id)
    return config.Mode
end

function XTheatre4ConfigModel:GetFightMoldModeParamsById(id)
    local config = self:GetFightMoldConfigById(id)
    return config.ModeParams
end

function XTheatre4ConfigModel:GetFightMoldBaseHpById(id)
    local config = self:GetFightMoldConfigById(id)
    return config.BaseHp
end

function XTheatre4ConfigModel:GetFightMoldFightEventsById(id)
    local config = self:GetFightMoldConfigById(id)
    return config.FightEvents
end

---@return XTableTheatre4Item[]
function XTheatre4ConfigModel:GetItemConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Item) or {}
end

---@return XTableTheatre4Item
function XTheatre4ConfigModel:GetItemConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Item, id) or {}
end

function XTheatre4ConfigModel:GetItemNameById(id)
    local config = self:GetItemConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetItemCountLimitById(id)
    local config = self:GetItemConfigById(id)
    return config.CountLimit
end

function XTheatre4ConfigModel:GetItemTypeById(id)
    local config = self:GetItemConfigById(id)
    return config.Type
end

function XTheatre4ConfigModel:GetItemQualityById(id)
    local config = self:GetItemConfigById(id)
    return config.Quality
end

function XTheatre4ConfigModel:GetItemEffectGroupIdById(id)
    local config = self:GetItemConfigById(id)
    return config.EffectGroupId
end

function XTheatre4ConfigModel:GetItemDescById(id)
    local config = self:GetItemConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetItemDescIconById(id)
    local config = self:GetItemConfigById(id)
    return config.DescIcon
end

function XTheatre4ConfigModel:GetItemEffectDescIdById(id)
    local config = self:GetItemConfigById(id)
    return config.EffectDescId
end

function XTheatre4ConfigModel:GetItemIconById(id)
    local config = self:GetItemConfigById(id)
    return config.Icon
end

function XTheatre4ConfigModel:GetItemIsPropById(id)
    local config = self:GetItemConfigById(id)
    return config.IsProp
end

function XTheatre4ConfigModel:GetItemIsShowById(id)
    local config = self:GetItemConfigById(id)
    return config.IsShow
end

function XTheatre4ConfigModel:GetItemIsPlayById(id)
    local config = self:GetItemConfigById(id)
    return config.IsPlay
end

function XTheatre4ConfigModel:GetItemBackPriceById(id)
    local config = self:GetItemConfigById(id)
    return config.BackPrice
end

function XTheatre4ConfigModel:GetItemConditionById(id)
    local config = self:GetItemConfigById(id)
    return config.Condition
end

---@return XTableTheatre4ItemBox[]
function XTheatre4ConfigModel:GetItemBoxConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ItemBox) or {}
end

---@return XTableTheatre4ItemBox
function XTheatre4ConfigModel:GetItemBoxConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ItemBox, id) or {}
end

function XTheatre4ConfigModel:GetItemBoxGroupIdById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.GroupId
end

function XTheatre4ConfigModel:GetItemBoxWeightById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.Weight
end

function XTheatre4ConfigModel:GetItemBoxConditionIdById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.ConditionId
end

function XTheatre4ConfigModel:GetItemBoxItemGroupIdById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.ItemGroupId
end

function XTheatre4ConfigModel:GetItemBoxSafeItemGroupIdById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.SafeItemGroupId
end

function XTheatre4ConfigModel:GetItemBoxQualityById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.Quality
end

function XTheatre4ConfigModel:GetItemBoxNameById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetItemBoxIconById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.Icon
end

function XTheatre4ConfigModel:GetItemBoxTitleById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.Title
end

function XTheatre4ConfigModel:GetItemBoxTitleContentById(id)
    local config = self:GetItemBoxConfigById(id)
    return config.TitleContent
end

function XTheatre4ConfigModel:GetItemBoxDescById(id)
    local config = self:GetItemBoxConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

---@return XTableTheatre4ItemGroup[]
function XTheatre4ConfigModel:GetItemGroupConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ItemGroup) or {}
end

---@return XTableTheatre4ItemGroup
function XTheatre4ConfigModel:GetItemGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ItemGroup, id) or {}
end

function XTheatre4ConfigModel:GetItemGroupGroupIdById(id)
    local config = self:GetItemGroupConfigById(id)
    return config.GroupId
end

function XTheatre4ConfigModel:GetItemGroupItemIdById(id)
    local config = self:GetItemGroupConfigById(id)
    return config.ItemId
end

function XTheatre4ConfigModel:GetItemGroupWeightById(id)
    local config = self:GetItemGroupConfigById(id)
    return config.Weight
end

function XTheatre4ConfigModel:GetItemGroupConditionById(id)
    local config = self:GetItemGroupConfigById(id)
    return config.Condition
end

---@return XTableTheatre4RecruitTicket[]
function XTheatre4ConfigModel:GetRecruitTicketConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4RecruitTicket) or {}
end

---@return XTableTheatre4RecruitTicket
function XTheatre4ConfigModel:GetRecruitTicketConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4RecruitTicket, id) or {}
end

function XTheatre4ConfigModel:GetRecruitTicketQualityById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.Quality
end

function XTheatre4ConfigModel:GetRecruitTicketCharacterGroupAById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.CharacterGroupA
end

function XTheatre4ConfigModel:GetRecruitTicketCharacterNumAById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.CharacterNumA
end

function XTheatre4ConfigModel:GetRecruitTicketCharacterGroupBById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.CharacterGroupB
end

function XTheatre4ConfigModel:GetRecruitTicketCharacterNumBById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.CharacterNumB
end

function XTheatre4ConfigModel:GetRecruitTicketSelectNumById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.SelectNum
end

function XTheatre4ConfigModel:GetRecruitTicketRefreshLimitById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.RefreshLimit
end

function XTheatre4ConfigModel:GetRecruitTicketNameById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetRecruitTicketDescById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetRecruitTicketIconById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.Icon
end

function XTheatre4ConfigModel:GetRecruitTicketIsSpecialById(id)
    local config = self:GetRecruitTicketConfigById(id)
    return config.IsSpecial
end

---@return XTableTheatre4Reward[]
function XTheatre4ConfigModel:GetRewardConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Reward) or {}
end

---@return XTableTheatre4Reward
function XTheatre4ConfigModel:GetRewardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Reward, id) or {}
end

function XTheatre4ConfigModel:GetRewardElementTypeById(id)
    local config = self:GetRewardConfigById(id)
    return config.ElementType
end

function XTheatre4ConfigModel:GetRewardElementIdById(id)
    local config = self:GetRewardConfigById(id)
    return config.ElementId
end

function XTheatre4ConfigModel:GetRewardElementCountById(id)
    local config = self:GetRewardConfigById(id)
    return config.ElementCount
end

function XTheatre4ConfigModel:GetRewardGroupIdById(id)
    local config = self:GetRewardConfigById(id)
    return config.GroupId
end

function XTheatre4ConfigModel:GetRewardWeightById(id)
    local config = self:GetRewardConfigById(id)
    return config.Weight
end

function XTheatre4ConfigModel:GetRewardConditionById(id)
    local config = self:GetRewardConfigById(id)
    return config.Condition
end

function XTheatre4ConfigModel:GetRewardConditionWeightById(id)
    local config = self:GetRewardConfigById(id)
    return config.ConditionWeight
end

function XTheatre4ConfigModel:GetRewardIsSHowById(id)
    local config = self:GetRewardConfigById(id)
    return config.IsShow
end

---@return XTableTheatre4RewardDrop[]
function XTheatre4ConfigModel:GetRewardDropConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4RewardDrop) or {}
end

---@return XTableTheatre4RewardDrop
function XTheatre4ConfigModel:GetRewardDropConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4RewardDrop, id) or {}
end

function XTheatre4ConfigModel:GetRewardDropTypeById(id)
    local config = self:GetRewardDropConfigById(id)
    return config.Type
end

function XTheatre4ConfigModel:GetRewardDropGroupIdsById(id)
    local config = self:GetRewardDropConfigById(id)
    return config.GroupIds
end

function XTheatre4ConfigModel:GetRewardDropProbabilitysById(id)
    local config = self:GetRewardDropConfigById(id)
    return config.Probabilitys
end

---@return XTableTheatre4Tech[]
function XTheatre4ConfigModel:GetTechConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Tech) or {}
end

---@return XTableTheatre4Tech
function XTheatre4ConfigModel:GetTechConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Tech, id) or {}
end

function XTheatre4ConfigModel:GetTechTypeById(id)
    local config = self:GetTechConfigById(id)
    return config.Type
end

function XTheatre4ConfigModel:GetTechCostById(id)
    local config = self:GetTechConfigById(id)
    return config.Cost
end

function XTheatre4ConfigModel:GetTechEffectGroupIdById(id)
    local config = self:GetTechConfigById(id)
    return config.EffectGroupId
end

function XTheatre4ConfigModel:GetTechConditionById(id)
    local config = self:GetTechConfigById(id)
    return config.Condition
end

function XTheatre4ConfigModel:GetTechPreIdsById(id)
    local config = self:GetTechConfigById(id)
    return config.PreIds
end

function XTheatre4ConfigModel:GetTechNameById(id)
    local config = self:GetTechConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetTechDescById(id)
    local config = self:GetTechConfigById(id)
    return config.Desc
end

function XTheatre4ConfigModel:GetTechIconById(id)
    local config = self:GetTechConfigById(id)
    return config.Icon
end

--region

--region map
---@return XTableTheatre4Map[]
function XTheatre4ConfigModel:GetMapConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4MapTableKey.Theatre4Map) or {}
end

---@return XTableTheatre4Map
function XTheatre4ConfigModel:GetMapConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4MapTableKey.Theatre4Map, id) or {}
end

function XTheatre4ConfigModel:GetMapDescById(id)
    local config = self:GetMapConfigById(id)
    return config.Desc
end

function XTheatre4ConfigModel:GetMapSizeXById(id)
    local config = self:GetMapConfigById(id)
    return config.SizeX
end

function XTheatre4ConfigModel:GetMapSizeYById(id)
    local config = self:GetMapConfigById(id)
    return config.SizeY
end

function XTheatre4ConfigModel:GetMapBaseBlockGroupIdById(id)
    local config = self:GetMapConfigById(id)
    return config.BaseBlockGroupId
end

function XTheatre4ConfigModel:GetMapHiddenIdById(id)
    local config = self:GetMapConfigById(id)
    return config.HiddenId
end

---@return XTableTheatre4MapBlueprint[]
function XTheatre4ConfigModel:GetMapBlueprintConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4MapTableKey.Theatre4MapBlueprint) or {}
end

---@return XTableTheatre4MapBlueprint
function XTheatre4ConfigModel:GetMapBlueprintConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4MapTableKey.Theatre4MapBlueprint, id) or {}
end

function XTheatre4ConfigModel:GetMapBlueprintDescById(id)
    local config = self:GetMapBlueprintConfigById(id)
    return config.Desc
end

function XTheatre4ConfigModel:GetMapBlueprintOrderById(id)
    local config = self:GetMapBlueprintConfigById(id)
    return config.Order
end

function XTheatre4ConfigModel:GetMapBlueprintMapIdById(id)
    local config = self:GetMapBlueprintConfigById(id)
    return config.MapId
end

function XTheatre4ConfigModel:GetMapBlueprintIndexById(id)
    local config = self:GetMapBlueprintConfigById(id)
    return config.Index
end

---@return XTableTheatre4MapHiddenGrid[]
function XTheatre4ConfigModel:GetMapHiddenGridConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4MapTableKey.Theatre4MapHiddenGrid) or {}
end

---@return XTableTheatre4MapHiddenGrid
function XTheatre4ConfigModel:GetMapHiddenGridConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4MapTableKey.Theatre4MapHiddenGrid, id) or {}
end

function XTheatre4ConfigModel:GetMapHiddenGridConditionIdById(id)
    local config = self:GetMapHiddenGridConfigById(id)
    return config.ConditionId
end

function XTheatre4ConfigModel:GetMapHiddenGridPointById(id)
    local config = self:GetMapHiddenGridConfigById(id)
    return config.Point
end

function XTheatre4ConfigModel:GetMapHiddenGridGridPosById(id)
    local config = self:GetMapHiddenGridConfigById(id)
    return config.GridPos
end

---@return XTableTheatre4MapGroup[]
function XTheatre4ConfigModel:GetMapGroupConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4MapTableKey.Theatre4MapGroup) or {}
end

function XTheatre4ConfigModel:GetScientificSpEffectConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ScientificSpEffect) or {}
end

--endregion map

--region Set
function XTheatre4ConfigModel:GetAffixConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Affix) or {}
end

---@return XTableTheatre4Affix
function XTheatre4ConfigModel:GetAffixConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Affix, id)
end

function XTheatre4ConfigModel:GetAffixNameById(id)
    local config = self:GetAffixConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetAffixDescById(id)
    local config = self:GetAffixConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XTheatre4ConfigModel:GetAffixIconById(id)
    local config = self:GetAffixConfigById(id)
    return config.Icon
end

---@return XTableTheatre4Character
function XTheatre4ConfigModel:GetCharacterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Character, id)
end

-- 获取角色Id
function XTheatre4ConfigModel:GetCharacterIdById(id)
    local config = self:GetCharacterConfigById(id)
    return config.CharacterId
end

-- 获取机器人Id
function XTheatre4ConfigModel:GetCharacterRobotIdById(id)
    local config = self:GetCharacterConfigById(id)
    return config.RobotId
end

function XTheatre4ConfigModel:GetCharacterStarConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4CharacterStar)
end

function XTheatre4ConfigModel:GetCharacterStarConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4CharacterStar, id)
end

---@return XTableTheatre4MapClient
function XTheatre4ConfigModel:GetMapClientConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4MapClient, id) or {}
end

--endregion Set

--region Theatre4MapIndex

---@return XTableTheatre4MapIndex[]
function XTheatre4ConfigModel:GetMapIndexConfigs(id)
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4MapIndex, id) or {}
end

---@return XTableTheatre4MapIndex
function XTheatre4ConfigModel:GetMapIndexConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4MapIndex, id) or {}
end

function XTheatre4ConfigModel:GetMapIndexNameById(id)
    local config = self:GetMapIndexConfigById(id)
    return config and config.Name or ""
end

--endregion

--region Theatre4ClientConfig

---@return XTableTheatre4ClientConfig[]
function XTheatre4ConfigModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ClientConfig, key, true)
    return config and config.Params or nil
end

---@return XTableTheatre4ClientConfig
function XTheatre4ConfigModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ClientConfig, key)
    if not config then
        return nil
    end
    return config.Params and config.Params[index] or nil
end

--endregion

--region 商店相关

---@return XTableTheatre4Shop
function XTheatre4ConfigModel:GetShopConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Shop, id) or {}
end

-- 商店名称
function XTheatre4ConfigModel:GetShopNameById(id)
    local config = self:GetShopConfigById(id)
    return config.Name
end

-- 商店图标
function XTheatre4ConfigModel:GetShopIconById(id)
    local config = self:GetShopConfigById(id)
    return config.Icon
end

-- 商店块图标
function XTheatre4ConfigModel:GetShopBlockIconById(id)
    local config = self:GetShopConfigById(id)
    return config.BlockIcon
end

-- 商店标题
function XTheatre4ConfigModel:GetShopTitleById(id)
    local config = self:GetShopConfigById(id)
    return config.Title
end

-- 商店标题内容
function XTheatre4ConfigModel:GetShopTitleContentById(id)
    local config = self:GetShopConfigById(id)
    return config.TitleContent
end

-- 商店描述
function XTheatre4ConfigModel:GetShopDescById(id)
    local config = self:GetShopConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

-- 商店未翻开描述
function XTheatre4ConfigModel:GetShopUnOpenDescById(id)
    local config = self:GetShopConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.UnOpenDesc)
end

-- 商店角色立绘
function XTheatre4ConfigModel:GetShopRoleIconById(id)
    local config = self:GetShopConfigById(id)
    return config.RoleIcon
end

-- 商店角色名称
function XTheatre4ConfigModel:GetShopRoleNameById(id)
    local config = self:GetShopConfigById(id)
    return config.RoleName
end

-- 商店角色描述
function XTheatre4ConfigModel:GetShopRoleContentById(id)
    local config = self:GetShopConfigById(id)
    return config.RoleContent
end

-- 商店背景资产
function XTheatre4ConfigModel:GetShopBgAssetById(id)
    local config = self:GetShopConfigById(id)
    return config.BgAsset
end

-- 商店刷新上限
function XTheatre4ConfigModel:GetShopRefreshLimitById(id)
    local config = self:GetShopConfigById(id)
    return config.RefreshLimit
end

-- 商店刷新免费次数
function XTheatre4ConfigModel:GetShopRefreshFreeTimesById(id)
    local config = self:GetShopConfigById(id)
    return config.RefreshFreeTimes
end

-- 商店刷新消耗
function XTheatre4ConfigModel:GetShopRefreshCostById(id)
    local config = self:GetShopConfigById(id)
    return config.RefreshCost
end

--endregion

--region 商店商品相关

---@return XTableTheatre4ShopGoods
function XTheatre4ConfigModel:GetShopGoodsConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ShopGoods, id) or {}
end

-- 商品类型
function XTheatre4ConfigModel:GetShopGoodsTypeById(id)
    local config = self:GetShopGoodsConfigById(id)
    return config.GoodsType
end

-- 商品Id
function XTheatre4ConfigModel:GetShopGoodsIdById(id)
    local config = self:GetShopGoodsConfigById(id)
    return config.GoodsId
end

-- 商品数量
function XTheatre4ConfigModel:GetShopGoodsNumById(id)
    local config = self:GetShopGoodsConfigById(id)
    return config.GoodsNum
end

-- 商品价格
function XTheatre4ConfigModel:GetShopGoodsPriceById(id)
    local config = self:GetShopGoodsConfigById(id)
    return config.Price
end

--endregion

--region 建筑相关

---@return XTableTheatre4Building
function XTheatre4ConfigModel:GetBuildingConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Building, id) or {}
end

-- 建筑类型
function XTheatre4ConfigModel:GetBuildingTypeById(id)
    local config = self:GetBuildingConfigById(id)
    return config.Type
end

-- 建筑参数
function XTheatre4ConfigModel:GetBuildingParamsById(id)
    local config = self:GetBuildingConfigById(id)
    return config.Params
end

-- 建筑名称
function XTheatre4ConfigModel:GetBuildingNameById(id)
    local config = self:GetBuildingConfigById(id)
    return config.Name
end

-- 建筑图标
function XTheatre4ConfigModel:GetBuildingIconById(id)
    local config = self:GetBuildingConfigById(id)
    return config.Icon
end

-- 建筑标题
function XTheatre4ConfigModel:GetBuildingTitleById(id)
    local config = self:GetBuildingConfigById(id)
    return config.Title
end

-- 建筑标题内容
function XTheatre4ConfigModel:GetBuildingTitleContentById(id)
    local config = self:GetBuildingConfigById(id)
    return config.TitleContent
end

-- 建筑描述
function XTheatre4ConfigModel:GetBuildingDescById(id)
    local config = self:GetBuildingConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

-- 获取建筑在章节中最大数量
function XTheatre4ConfigModel:GetBuildingMaxCountInChapterById(id)
    local config = self:GetBuildingConfigById(id)
    return config.MaxCountInChapter
end

-- 获取建筑技能图片
function XTheatre4ConfigModel:GetBuildingSkillPictureById(id)
    local config = self:GetBuildingConfigById(id)
    return config.SkillPicture
end

--endregion

-- region 任务BP相关

---@return XTableTheatre4BattlePass[]
function XTheatre4ConfigModel:GetBattlePassConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4BattlePass) or {}
end

---@return XTableTheatre4BattlePass
function XTheatre4ConfigModel:GetBattlePassConfigByLevel(level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4BattlePass, level) or {}
end

function XTheatre4ConfigModel:GetBattlePassNextLvExpByLevel(level)
    local config = self:GetBattlePassConfigByLevel(level)
    return config.NeedExp
end

function XTheatre4ConfigModel:GetBattlePassRewardIdByLevel(level)
    local config = self:GetBattlePassConfigByLevel(level)
    return config.RewardId
end

function XTheatre4ConfigModel:GetBattlePassDisplayByLevel(level)
    local config = self:GetBattlePassConfigByLevel(level)
    return config.Display
end

---@return XTableTheatre4Task[]
function XTheatre4ConfigModel:GetTaskConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Task) or {}
end

---@return XTableTheatre4Task
function XTheatre4ConfigModel:GetTaskConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Task, id) or {}
end

function XTheatre4ConfigModel:GetTaskNameById(id)
    local config = self:GetTaskConfigById(id)
    return config.Name
end

function XTheatre4ConfigModel:GetTaskMainShowOrderById(id)
    local config = self:GetTaskConfigById(id)
    return config.MainShowOrder
end

function XTheatre4ConfigModel:GetTaskTaskIdById(id)
    local config = self:GetTaskConfigById(id)
    return config.TaskId
end

-- endregion

--region 命运（时间轴）

---@return XTableTheatre4Fate
function XTheatre4ConfigModel:GetFateConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Fate, id) or {}
end

-- 获取触发天数
function XTheatre4ConfigModel:GetFateTriggerDayById(id)
    local config = self:GetFateConfigById(id)
    return config.TriggerDay
end

-- 获取事件组
function XTheatre4ConfigModel:GetFateEventGroupById(id)
    local config = self:GetFateConfigById(id)
    return config.EventGroup
end

--endregion

--region 命运事件

---@return XTableTheatre4FateEvent
function XTheatre4ConfigModel:GetFateEventConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4FateEvent, id) or {}
end

-- 获取持续时间
function XTheatre4ConfigModel:GetFateEventDurationById(id)
    local config = self:GetFateEventConfigById(id)
    return config.Duration
end

--endregion

--region talent 天赋
---@return XTableTheatre4ColorTalentSlot[]
function XTheatre4ConfigModel:GetColorTalentSlotConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ColorTalentSlot)
end

---@return XTableTheatre4ColorTalentSlot
function XTheatre4ConfigModel:GetColorTalentSlotConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ColorTalentSlot, id, true)
end

function XTheatre4ConfigModel:GetColorTalentSlotConfigByColor(color)
    -- todo by zlb 遍历
    local configs = self:GetColorTalentSlotConfigs(color)
    local result = {}
    for _, config in pairs(configs) do
        if config.Color == color then
            result[#result + 1] = config
        end
    end
    return result
end

function XTheatre4ConfigModel:GetColorTalentPoolTalentByGroup(groupId)
    -- todo by zlb 遍历
    local result = {}
    local configs = self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ColorTalentPool)
    for i, config in pairs(configs) do
        if config.Group == groupId then
            result[#result + 1] = config.TalentId
        end
    end
    return result
end

--endregion talent 天赋

-- region 颜色天赋

---@return XTableTheatre4ColorTalent[]
function XTheatre4ConfigModel:GetColorTalentConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4ColorTalent) or {}
end

---@return XTableTheatre4ColorTalent
function XTheatre4ConfigModel:GetColorTalentConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ColorTalent, id) or {}
end

-- 获取颜色天赋名称
function XTheatre4ConfigModel:GetColorTalentNameById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.Name
end

-- 获取颜色天赋描述
function XTheatre4ConfigModel:GetColorTalentDescById(id)
    local config = self:GetColorTalentConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

-- 获取颜色天赋图标
function XTheatre4ConfigModel:GetColorTalentIconById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.Icon
end

-- 获取颜色天赋类型
function XTheatre4ConfigModel:GetColorTalentTypeById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.Type
end

-- 获取颜色天赋是否是技能
function XTheatre4ConfigModel:GetColorTalentIsSkillById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.IsSkill
end

-- 获取颜色天赋效果组Id
function XTheatre4ConfigModel:GetColorTalentEffectGroupIdById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.EffectGroupId
end

-- 获取颜色天赋颜色Type
function XTheatre4ConfigModel:GetColorTalentColorTypeById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.ColorType
end

-- 获取颜色天赋解锁条件(图鉴用)
function XTheatre4ConfigModel:GetColorTalentConditionById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.Condition
end

-- 获取颜色天赋参数
function XTheatre4ConfigModel:GetColorTalentParamById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.Param
end

-- 获取颜色天赋标签
function XTheatre4ConfigModel:GetColorTalentTagsById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.Tags
end

-- 获取颜色天赋标签背景颜色
function XTheatre4ConfigModel:GetColorTalentTagBgColorsById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.TagBgColors
end

-- 获取颜色天赋是否参与结算
function XTheatre4ConfigModel:GetColorTalentJoinSettleById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.JoinSettle
end

-- 获取颜色天赋是否参与冒险结算
function XTheatre4ConfigModel:GetColorTalentJoinAdventureSettleById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.JoinAdventureSettle
end

-- 获取颜色天赋父节点
function XTheatre4ConfigModel:GetColorTalentParentNodeById(id)
    local config = self:GetColorTalentConfigById(id)
    return config.ParentNode
end

--endregion

--region 资产配置

---@return XTableTheatre4Asset[]
function XTheatre4ConfigModel:GetAssetConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Asset) or {}
end

-- 通过类型和参数获取资产配置
function XTheatre4ConfigModel:GetAssetConfigByTypeAndParam(type, param)
    local configs = self:GetAssetConfigs()
    for _, config in pairs(configs) do
        if config.Type == type then
            if XTool.IsNumberValid(param) then
                if config.Params == param then
                    return config
                end
            else
                return config
            end
        end
    end
    return nil
end

-- 获取资产名称
function XTheatre4ConfigModel:GetAssetName(type, param)
    local config = self:GetAssetConfigByTypeAndParam(type, param)
    return config and config.Name or ""
end

-- 获取资产图标
function XTheatre4ConfigModel:GetAssetIcon(type, param)
    local config = self:GetAssetConfigByTypeAndParam(type, param)
    return config and config.Icon or nil
end

-- 获取资产描述
function XTheatre4ConfigModel:GetAssetDesc(type, param)
    local config = self:GetAssetConfigByTypeAndParam(type, param)
    return config and config.Description or ""
end

-- 获取资产世界观描述
function XTheatre4ConfigModel:GetAssetWorldDesc(type, param)
    local config = self:GetAssetConfigByTypeAndParam(type, param)
    return config and config.WorldDesc or ""
end

--endregion

--region talent tree
function XTheatre4ConfigModel:GetColorTreeName(color)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ColorTalentTree, color)
    return config and config.Name or ""
end

function XTheatre4ConfigModel:GetColorTreeName(color)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ColorTalentTree, color)
    return config and config.Name or ""
end

function XTheatre4ConfigModel:GetColorTreeConditionId(color)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ColorTalentTree, color)
    return config and config.ConditionId or ""
end

--endregion talent tree

--region 结局配置

---@return XTableTheatre4Ending
function XTheatre4ConfigModel:GetEndingConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Ending, id) or {}
end

-- 获取结局倍率
function XTheatre4ConfigModel:GetEndingFactorById(id)
    local config = self:GetEndingConfigById(id)
    return config.Factor
end

-- 获取结局最大繁荣度
function XTheatre4ConfigModel:GetEndingMaxProsperityById(id)
    local config = self:GetEndingConfigById(id)
    return config.MaxProsperity
end

--endregion

--region 宝箱组配置

---@return XTableTheatre4BoxGroup[]
function XTheatre4ConfigModel:GetBoxGroupConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4BoxGroup) or {}
end

---@return XTableTheatre4BoxGroup
function XTheatre4ConfigModel:GetBoxGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4BoxGroup, id) or {}
end

-- 获取宝箱名称
function XTheatre4ConfigModel:GetBoxGroupNameById(id)
    local config = self:GetBoxGroupConfigById(id)
    return config.Name
end

-- 获取宝箱描述
function XTheatre4ConfigModel:GetBoxGroupDescById(id)
    local config = self:GetBoxGroupConfigById(id)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

-- 获取宝箱图标
function XTheatre4ConfigModel:GetBoxGroupIconById(id)
    local config = self:GetBoxGroupConfigById(id)
    return config.Icon
end

-- 获取宝箱块图标
function XTheatre4ConfigModel:GetBoxGroupBlockIconById(id)
    local config = self:GetBoxGroupConfigById(id)
    return config.BlockIcon
end

-- 获取宝箱标题
function XTheatre4ConfigModel:GetBoxGroupTitleById(id)
    local config = self:GetBoxGroupConfigById(id)
    return config.Title
end

-- 获取宝箱标题内容
function XTheatre4ConfigModel:GetBoxGroupTitleContentById(id)
    local config = self:GetBoxGroupConfigById(id)
    return config.TitleContent
end

--endregion

--region 重启配置

---@return XTableTheatre4Reboot
function XTheatre4ConfigModel:GetRebootConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4Reboot, id) or {}
end

-- 获取重启消耗
function XTheatre4ConfigModel:GetFubenRestartCostById(id)
    local config = self:GetRebootConfigById(id)
    return config.FubenRestartCost
end

--endregion

--region 块图标

---@return XTableTheatre4BlockIcon
function XTheatre4ConfigModel:GetBlockIconConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4BlockIcon, id) or {}
end

function XTheatre4ConfigModel:GetBlockIconDefaultIconById(id)
    local config = self:GetBlockIconConfigById(id)
    return config.DefaultIcon
end

function XTheatre4ConfigModel:GetBlockIconColorIconById(id)
    local config = self:GetBlockIconConfigById(id)
    return config.ColorIcon
end

--endregion

--region 藏品效果计数

---@return XTableTheatre4ItemEffectCount
function XTheatre4ConfigModel:GetItemEffectCountConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4ItemEffectCount, id) or {}
end

-- 获取藏品效果计数效果类型
function XTheatre4ConfigModel:GetItemEffectCountEffectTypeById(id)
    local config = self:GetItemEffectCountConfigById(id)
    return config.EffectType
end

-- 获取藏品效果计数描述
function XTheatre4ConfigModel:GetItemEffectCountDescById(id)
    local config = self:GetItemEffectCountConfigById(id)
    return config.Desc
end

-- 获取藏品简略效果计数描述
function XTheatre4ConfigModel:GetItemEffectCountBubbleDescById(id)
    local config = self:GetItemEffectCountConfigById(id)
    return config.BubbleDesc
end

--endregion

--region 难度星级

---@return XTableTheatre4DifficultyStar[]
function XTheatre4ConfigModel:GetDifficultyStarConfigs()
    return self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4DifficultyStar) or {}
end

---@return XTableTheatre4DifficultyStar
function XTheatre4ConfigModel:GetDifficultyStarConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(Theatre4TableKey.Theatre4DifficultyStar, id) or {}
end

-- 获取难度星级奖励BP经验
function XTheatre4ConfigModel:GetDifficultyStarRewardBpExpById(id)
    local config = self:GetDifficultyStarConfigById(id)
    return config.RewardBpExp
end

-- 获取难度星级类型
function XTheatre4ConfigModel:GetDifficultyStarTypeById(id)
    local config = self:GetDifficultyStarConfigById(id)
    return config.Type
end

-- 获取难度星级参数
function XTheatre4ConfigModel:GetDifficultyStarParamsById(id)
    local config = self:GetDifficultyStarConfigById(id)
    return config.Params
end

-- 获取难度星级条件
function XTheatre4ConfigModel:GetDifficultyStarConditionById(id)
    local config = self:GetDifficultyStarConfigById(id)
    return config.Condition
end

-- 获取难度星级标题
function XTheatre4ConfigModel:GetDifficultyStarTitleById(id)
    local config = self:GetDifficultyStarConfigById(id)
    return config.Title
end

---endregion

function XTheatre4ConfigModel:GetTraceBackConfigByIdAndDifficulty(groupId, difficulty)
    local configs = self._ConfigUtil:GetByTableKey(Theatre4TableKey.Theatre4Traceback)
    for i, v in pairs(configs) do
        if v.GroupId == groupId and v.Difficulty == difficulty then
            return v
        end
    end
    return false
end

return XTheatre4ConfigModel
