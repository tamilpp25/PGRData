---@class XDlcMultiplayerConfigModel : XModel
local XDlcMultiplayerConfigModel = XClass(XModel, "XDlcMultiplayerConfigModel")

local DlcMultiplayerTableKey = {
    DlcMultiplayerConfig = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerWorld = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerActivity = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerChapter = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerChapterGroup = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiPlayerCharacter = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerCharacterPool = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerTitle = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerTitleGroup = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    DlcMultiplayerSkill = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XDlcMultiplayerConfigModel:_GetTableKey()
    return DlcMultiplayerTableKey
end

function XDlcMultiplayerConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/DlcMultiplayer", DlcMultiplayerTableKey)
end

---@return XTableDlcMultiplayerConfig[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerConfigConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerConfig) or {}
end

---@return XTableDlcMultiplayerConfig
function XDlcMultiplayerConfigModel:GetDlcMultiplayerConfigConfigByKey(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerConfig, key, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerConfigCommentByKey(key)
    local config = self:GetDlcMultiplayerConfigConfigByKey(key)

    return config.Comment
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerConfigValuesByKey(key)
    local config = self:GetDlcMultiplayerConfigConfigByKey(key)

    return config.Values
end

---@return XTableDlcMultiplayerWorld[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerWorld) or {}
end

---@return XTableDlcMultiplayerWorld
function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerWorld, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldIconById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.Icon
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldSceneUrlById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.SceneUrl
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldSceneModelUrlById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.SceneModelUrl
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldLoadingBackgroundById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.LoadingBackground
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldArtNameById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.ArtName
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldMaskLoadingTypeById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.MaskLoadingType
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerWorldSettlementUiNameById(id)
    local config = self:GetDlcMultiplayerWorldConfigById(id)

    return config.SettlementUiName
end

---@return XTableDlcMultiplayerActivity[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerActivity) or {}
end

---@return XTableDlcMultiplayerActivity
function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerActivity, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityTimeIdById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.TimeId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityNameById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.Name
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityTypeById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.Type
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityChapterGroupIdById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.ChapterGroupId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityCharacterPoolIdById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.CharacterPoolId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityTitleGroupIdById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.TitleGroupId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityHelpIdById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.HelpId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerActivityShopIdListById(id)
    local config = self:GetDlcMultiplayerActivityConfigById(id)

    return config.ShopIdList
end

---@return XTableDlcMultiplayerChapter[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerChapter) or {}
end

---@return XTableDlcMultiplayerChapter
function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerChapter, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterWorldIdsById(id)
    local config = self:GetDlcMultiplayerChapterConfigById(id)

    return config.WorldIds
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterLevelIdsById(id)
    local config = self:GetDlcMultiplayerChapterConfigById(id)

    return config.LevelIds
end

---@return XTableDlcMultiplayerChapterGroup[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterGroupConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerChapterGroup) or {}
end

---@return XTableDlcMultiplayerChapterGroup
function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerChapterGroup, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerChapterGroupChapterIdsById(id)
    local config = self:GetDlcMultiplayerChapterGroupConfigById(id)

    return config.ChapterIds
end

---@return XTableDlcMultiPlayerCharacter[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiPlayerCharacter) or {}
end

---@return XTableDlcMultiPlayerCharacter
function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterConfigById(id)
    return
        self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiPlayerCharacter, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterNpcIdById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.NpcId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterAttribIdById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.AttribId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterModelIdById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.ModelId
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterNameById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.Name
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterTradeNameById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.TradeName
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterSquareHeadImageById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.SquareHeadImage
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterRoundHeadImageById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.RoundHeadImage
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterMvpActionById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.MvpAction
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterVictoryActionById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.VictoryAction
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterFailActionById(id)
    local config = self:GetDlcMultiplayerCharacterConfigById(id)

    return config.FailAction
end

---@return XTableDlcMultiplayerCharacterPool[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterPoolConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerCharacterPool) or {}
end

---@return XTableDlcMultiplayerCharacterPool
function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterPoolConfigById(id)
    return
        self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerCharacterPool, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerCharacterPoolCharacterIdsById(id)
    local config = self:GetDlcMultiplayerCharacterPoolConfigById(id)

    return config.CharacterIds
end

---@return XTableDlcMultiplayerTitle[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerTitle) or {}
end

---@return XTableDlcMultiplayerTitle
function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerTitle, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleTitleContentById(id)
    local config = self:GetDlcMultiplayerTitleConfigById(id)

    return config.TitleContent
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleBackgroundById(id)
    local config = self:GetDlcMultiplayerTitleConfigById(id)

    return config.Background
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleIconById(id)
    local config = self:GetDlcMultiplayerTitleConfigById(id)

    return config.Icon
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleDescById(id)
    local config = self:GetDlcMultiplayerTitleConfigById(id)

    return config.Desc
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleIsProgressById(id)
    local config = self:GetDlcMultiplayerTitleConfigById(id)

    return config.IsProgress
end

---@return XTableDlcMultiplayerTitleGroup[]
function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleGroupConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerTitleGroup) or {}
end

---@return XTableDlcMultiplayerTitleGroup
function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerTitleGroup, id, false) or {}
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerTitleGroupTitleIdsById(id)
    local config = self:GetDlcMultiplayerTitleGroupConfigById(id)

    return config.TitleIds
end

function XDlcMultiplayerConfigModel:GetDlcMultiplayerSkillConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerSkill, id, false)
end

return XDlcMultiplayerConfigModel
