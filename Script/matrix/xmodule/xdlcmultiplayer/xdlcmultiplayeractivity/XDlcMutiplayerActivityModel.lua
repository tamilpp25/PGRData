---@class XDlcMutiplayerActivityModel : XModel
local XDlcMutiplayerActivityModel = XClass(XModel, "XDlcMutiplayerActivityModel")

local DlcMultiplayerTableKey = {
    DlcMultiplayerDiscussion = {
        CacheType = XConfigUtil.CacheType.Private,
    },
    DlcMultiplayerBp = {
        CacheType = XConfigUtil.CacheType.Private,
        ReadFunc = XConfigUtil.ReadType.IntAll,
        Identifier = "Lv",
    },
    DlcMultiplayerSkillGroup = {
        CacheType = XConfigUtil.CacheType.Private,
    }, 
}

function XDlcMutiplayerActivityModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/DlcMultiplayer", DlcMultiplayerTableKey)
end

function XDlcMutiplayerActivityModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self:_InitTableKey()
end

function XDlcMutiplayerActivityModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XDlcMutiplayerActivityModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

---@return XTableDlcMultiplayerActivity
function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityConfigById(id)
end

---@return XTableDlcMultiplayerChapter
function XDlcMutiplayerActivityModel:GetDlcMultiplayerChapterConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerChapterConfigById(id)
end

---@return XTableDlcMultiplayerChapterGroup
function XDlcMutiplayerActivityModel:GetDlcMultiplayerChapterGroupConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerChapterGroupConfigById(id)
end

---@return XTableDlcMultiPlayerCharacter
function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterConfigById(id)
end

---@return XTableDlcMultiplayerCharacterPool
function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterPoolConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterPoolConfigById(id)
end

---@return XTableDlcMultiplayerWorld
function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldConfigById(worldId)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldConfigById(worldId)
end

---@return XTableDlcMultiplayerTitle
function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleConfigById(id)
end

---@return XTableDlcMultiplayerTitleGroup
function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleGroupConfigById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleGroupConfigById(id)
end

---@return XTableDlcMultiplayerConfig
function XDlcMutiplayerActivityModel:GetDlcMultiplayerConfigConfigByKey(key)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerConfigConfigByKey(key)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityTimeIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityTimeIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityNameById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityNameById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityTypeById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityTypeById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityChapterGroupIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityChapterGroupIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityCharacterPoolIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityCharacterPoolIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityTitleGroupIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityTitleGroupIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityHelpIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityHelpIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerActivityShopIdListById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerActivityShopIdListById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerChapterWorldIdsById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerChapterWorldIdsById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerChapterLevelIdsById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerChapterLevelIdsById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerChapterGroupChapterIdsById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerChapterGroupChapterIdsById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterNpcIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterNpcIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterAttribIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterAttribIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterModelIdById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterModelIdById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterNameById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterNameById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterTradeNameById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterTradeNameById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterSquareHeadImageById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterSquareHeadImageById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterRoundHeadImageById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterRoundHeadImageById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterMvpActionById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterMvpActionById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterVictoryActionById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterVictoryActionById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterFailActionById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterFailActionById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerCharacterPoolCharacterIdsById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerCharacterPoolCharacterIdsById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldIconById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldIconById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldSceneUrlById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldSceneUrlById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldSceneModelUrlById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldSceneModelUrlById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldLoadingBackgroundById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldLoadingBackgroundById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldArtNameById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldArtNameById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldMaskLoadingTypeById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldMaskLoadingTypeById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerWorldSettlementUiNameById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerWorldSettlementUiNameById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleTitleContentById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleTitleContentById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleBackgroundById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleBackgroundById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleIconById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleIconById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleDescById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleDescById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerTitleGroupTitleIdsById(id)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerTitleGroupTitleIdsById(id)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerConfigCommentByKey(key)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerConfigCommentByKey(key)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerConfigValuesByKey(key)
    return XMVCA.XDlcMultiplayer:GetDlcMultiplayerConfigValuesByKey(key)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerDiscussionConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerDiscussion, id, false)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerBPConfigs()
    return self._ConfigUtil:GetByTableKey(DlcMultiplayerTableKey.DlcMultiplayerBp)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerBPConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerBp, id, false)
end

function XDlcMutiplayerActivityModel:GetDlcMultiplayerSkillGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcMultiplayerTableKey.DlcMultiplayerSkillGroup, id, false)
end


return XDlcMutiplayerActivityModel