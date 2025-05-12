---@class XDlcMultiplayerConfigAgency : XAgency
---@field private _Model XDlcMultiplayerConfigModel
local XDlcMultiplayerConfigAgency = XClass(XAgency, "XDlcMultiplayerConfigAgency")

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerConfigCommentByKey(key)
    return self._Model:GetDlcMultiplayerConfigCommentByKey(key)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerConfigValuesByKey(key)
    return self._Model:GetDlcMultiplayerConfigValuesByKey(key)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldIconById(id)
    return self._Model:GetDlcMultiplayerWorldIconById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldSceneUrlById(id)
    return self._Model:GetDlcMultiplayerWorldSceneUrlById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldSceneModelUrlById(id)
    return self._Model:GetDlcMultiplayerWorldSceneModelUrlById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldLoadingBackgroundById(id)
    return self._Model:GetDlcMultiplayerWorldLoadingBackgroundById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldArtNameById(id)
    return self._Model:GetDlcMultiplayerWorldArtNameById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldMaskLoadingTypeById(id)
    return self._Model:GetDlcMultiplayerWorldMaskLoadingTypeById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerWorldSettlementUiNameById(id)
    return self._Model:GetDlcMultiplayerWorldSettlementUiNameById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityTimeIdById(id)
    return self._Model:GetDlcMultiplayerActivityTimeIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityNameById(id)
    return self._Model:GetDlcMultiplayerActivityNameById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityTypeById(id)
    return self._Model:GetDlcMultiplayerActivityTypeById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityChapterGroupIdById(id)
    return self._Model:GetDlcMultiplayerActivityChapterGroupIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityCharacterPoolIdById(id)
    return self._Model:GetDlcMultiplayerActivityCharacterPoolIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityTitleGroupIdById(id)
    return self._Model:GetDlcMultiplayerActivityTitleGroupIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityHelpIdById(id)
    return self._Model:GetDlcMultiplayerActivityHelpIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerActivityShopIdListById(id)
    return self._Model:GetDlcMultiplayerActivityShopIdListById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerChapterWorldIdsById(id)
    return self._Model:GetDlcMultiplayerChapterWorldIdsById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerChapterLevelIdsById(id)
    return self._Model:GetDlcMultiplayerChapterLevelIdsById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerChapterGroupChapterIdsById(id)
    return self._Model:GetDlcMultiplayerChapterGroupChapterIdsById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterNpcIdById(id)
    return self._Model:GetDlcMultiplayerCharacterNpcIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterAttribIdById(id)
    return self._Model:GetDlcMultiplayerCharacterAttribIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterModelIdById(id)
    return self._Model:GetDlcMultiplayerCharacterModelIdById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterNameById(id)
    return self._Model:GetDlcMultiplayerCharacterNameById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterTradeNameById(id)
    return self._Model:GetDlcMultiplayerCharacterTradeNameById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterSquareHeadImageById(id)
    return self._Model:GetDlcMultiplayerCharacterSquareHeadImageById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterRoundHeadImageById(id)
    return self._Model:GetDlcMultiplayerCharacterRoundHeadImageById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterMvpActionById(id)
    return self._Model:GetDlcMultiplayerCharacterMvpActionById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterVictoryActionById(id)
    return self._Model:GetDlcMultiplayerCharacterVictoryActionById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterFailActionById(id)
    return self._Model:GetDlcMultiplayerCharacterFailActionById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerCharacterPoolCharacterIdsById(id)
    return self._Model:GetDlcMultiplayerCharacterPoolCharacterIdsById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerTitleTitleContentById(id)
    return self._Model:GetDlcMultiplayerTitleTitleContentById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerTitleBackgroundById(id)
    return self._Model:GetDlcMultiplayerTitleBackgroundById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerTitleIconById(id)
    return self._Model:GetDlcMultiplayerTitleIconById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerTitleDescById(id)
    return self._Model:GetDlcMultiplayerTitleDescById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerTitleIsProgressById(id)
    return self._Model:GetDlcMultiplayerTitleIsProgressById(id)
end

function XDlcMultiplayerConfigAgency:GetDlcMultiplayerTitleGroupTitleIdsById(id)
    return self._Model:GetDlcMultiplayerTitleGroupTitleIdsById(id)
end

return XDlcMultiplayerConfigAgency