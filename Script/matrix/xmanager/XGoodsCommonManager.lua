XGoodsCommonManager = XGoodsCommonManager or {}

XGoodsCommonManager.QualityType = {
    White = 1,
    Greed = 2,
    Blue = 3,
    Purple = 4,
    Gold = 5,
    Red = 6,
    Red1 = 7
}


local GoodsName = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetItemName(templateId)
    end,

    [XArrangeConfigs.Types.Character] = function(templateId)
        return XMVCA.XCharacter:GetCharacterName(templateId)
    end,

    [XArrangeConfigs.Types.Weapon] = function(templateId)
        return XDataCenter.EquipManager.GetEquipName(templateId)
    end,

    [XArrangeConfigs.Types.Wafer] = function(templateId)
        return XDataCenter.EquipManager.GetEquipName(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.GetFashionName(templateId)
    end,

    [XArrangeConfigs.Types.BaseEquip] = function(templateId)
        return XDataCenter.BaseEquipManager.GetBaseEquipName(templateId)
    end,

    [XArrangeConfigs.Types.Furniture] = function(templateId)
        return XFurnitureConfigs.GetFurnitureNameById(templateId)
    end,

    [XArrangeConfigs.Types.DormCharacter] = function(templateId)
        return XDormConfig.GetDormCharacterRewardNameById(templateId)
    end,

    [XArrangeConfigs.Types.ChatEmoji] = function(templateId)
        return XDataCenter.ChatManager.GetEmojiName(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XWeaponFashionConfigs.GetFashionName(templateId)
    end,

    [XArrangeConfigs.Types.Collection] = function(templateId)
        return XMedalConfigs.GetCollectionNameById(templateId)
    end,

    [XArrangeConfigs.Types.Background] = function(templateId)
        return XPhotographConfigs.GetBackgroundNameById(templateId)
    end,
    
    [XArrangeConfigs.Types.Partner] = function(templateId)
        return XPartnerConfigs.GetPartnerTemplateName(templateId)
    end,

    [XArrangeConfigs.Types.Nameplate] = function(templateId)
        return XMedalConfigs.GetNameplateName(templateId)
    end,

    [XArrangeConfigs.Types.RankScore] = function(templateId)
        return XFubenSpecialTrainConfig.GetRankScoreGoodName(templateId)
    end,
}

local GoodsQuality = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetItemQuality(templateId)
    end,

    [XArrangeConfigs.Types.Character] = function()
        return XGoodsCommonManager.QualityType.Gold
    end,

    [XArrangeConfigs.Types.Weapon] = function(templateId)
        return XDataCenter.EquipManager.GetEquipQuality(templateId)
    end,

    [XArrangeConfigs.Types.Wafer] = function(templateId)
        return XDataCenter.EquipManager.GetEquipQuality(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.GetFashionQuality(templateId)
    end,

    [XArrangeConfigs.Types.BaseEquip] = function(templateId)
        return XDataCenter.BaseEquipManager.GetBaseEquipQuality(templateId)
    end,

    [XArrangeConfigs.Types.DormCharacter] = function(templateId)
        return XDormConfig.GetDormCharacterRewardQualityById(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XWeaponFashionConfigs.GetFashionQuality(templateId)
    end,

    [XArrangeConfigs.Types.Collection] = function(templateId)
        return XMedalConfigs.GetCollectionDefaultQualityById(templateId)
    end,

    [XArrangeConfigs.Types.Background] = function(templateId)
        return XPhotographConfigs.GetBackgroundQualityById(templateId)
    end,
    
    [XArrangeConfigs.Types.Partner] = function(templateId)
        return XPartnerConfigs.GetPartnerTemplateQuality(templateId)
    end,

    [XArrangeConfigs.Types.Nameplate] = function(templateId)
        return XMedalConfigs.GetNameplateQuality(templateId)
    end,

    [XArrangeConfigs.Types.RankScore] = function(templateId)
        return XFubenSpecialTrainConfig.GetRankScoreGoodQuality(templateId)
    end,
}

local GoodsIcon = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetItemIcon(templateId)
    end,

    [XArrangeConfigs.Types.Character] = function(templateId)
        return XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(templateId)
    end,

    [XArrangeConfigs.Types.Weapon] = function(templateId)
        return XDataCenter.EquipManager.GetEquipIconPath(templateId)
    end,

    [XArrangeConfigs.Types.Wafer] = function(templateId)
        return XDataCenter.EquipManager.GetEquipIconPath(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.GetFashionIcon(templateId)
    end,

    [XArrangeConfigs.Types.BaseEquip] = function(templateId)
        return XDataCenter.BaseEquipManager.GetBaseEquipIcon(templateId)
    end,

    [XArrangeConfigs.Types.Furniture] = function(templateId)
        return XFurnitureConfigs.GetFurnitureIconById(templateId)
    end,
    [XArrangeConfigs.Types.DormCharacter] = function(templateId)
        return XDormConfig.GetDormCharacterRewardIconById(templateId)
    end,

    [XArrangeConfigs.Types.ChatEmoji] = function(templateId)
        return XDataCenter.ChatManager.GetEmojiIcon(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XWeaponFashionConfigs.GetFashionIcon(templateId)
    end,

    [XArrangeConfigs.Types.Collection] = function(templateId)
        return XMedalConfigs.GetCollectionIconById(templateId)
    end,

    [XArrangeConfigs.Types.Background] = function(templateId)
        return XPhotographConfigs.GetBackgroundBigIconById(templateId)
    end,
    
    [XArrangeConfigs.Types.Partner] = function(templateId)
        return XPartnerConfigs.GetPartnerTemplateIcon(templateId)
    end,

    [XArrangeConfigs.Types.Nameplate] = function(templateId)
        return XMedalConfigs.GetNameplateIcon(templateId)
    end,

    [XArrangeConfigs.Types.RankScore] = function(templateId)
        return XFubenSpecialTrainConfig.GetRankScoreGoodIcon(templateId)
    end,
}

local GoodsDescription = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetItemDescription(templateId)
    end,

    [XArrangeConfigs.Types.Character] = function(templateId)
        return XMVCA.XCharacter:GetCharacterIntro(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.GetFashionDesc(templateId)
    end,

    [XArrangeConfigs.Types.Weapon] = function(templateId)
        return XDataCenter.EquipManager.GetEquipDescription(templateId)
    end,

    [XArrangeConfigs.Types.Wafer] = function(templateId)
        return XDataCenter.EquipManager.GetEquipDescription(templateId)
    end,

    [XArrangeConfigs.Types.BaseEquip] = function(templateId)
        return XDataCenter.BaseEquipManager.GetBaseEquipDesc(templateId)
    end,

    [XArrangeConfigs.Types.Furniture] = function(templateId)
        return XFurnitureConfigs.GetFurnitureDescriptionById(templateId)
    end,

    [XArrangeConfigs.Types.HeadPortrait] = function(templateId)
        return XDataCenter.HeadPortraitManager.GetHeadPortraitDescriptionById(templateId)
    end,

    [XArrangeConfigs.Types.DormCharacter] = function(templateId)
        return XDormConfig.GetDormDescriptionRewardCharIdById(templateId)
    end,

    [XArrangeConfigs.Types.ChatEmoji] = function(templateId)
        return XDataCenter.ChatManager.GetEmojiDescription(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XWeaponFashionConfigs.GetFashionDesc(templateId)
    end,

    [XArrangeConfigs.Types.Collection] = function(templateId)
        return XMedalConfigs.GetCollectionDescById(templateId)
    end,

    [XArrangeConfigs.Types.Background] = function(templateId)
        return XPhotographConfigs.GetBackgroundDescriptionById(templateId)
    end,
    
    [XArrangeConfigs.Types.Partner] = function(templateId)
        return XPartnerConfigs.GetPartnerTemplateGoodsDesc(templateId)
    end,

    [XArrangeConfigs.Types.Nameplate] = function(templateId)
        return XMedalConfigs.GetNameplateDescription(templateId)
    end,

    [XArrangeConfigs.Types.RankScore] = function(templateId)
        return XFubenSpecialTrainConfig.GetRankScoreGoodDescription(templateId)
    end,
    [XArrangeConfigs.Types.DrawTicket] = function(templateId) 
        return XDrawConfigs.GetDrawTicketDesc(templateId)
    end,
    [XArrangeConfigs.Types.ItemCollection] = function(templateId)
        local template = XItemConfigs.GetItemCollectTemplate(templateId)
        return template.Description
    end
}

local GoodsWorldDesc = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetItemWorldDesc(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.GetFashionWorldDescription(templateId)
    end,

    [XArrangeConfigs.Types.HeadPortrait] = function(templateId)
        return XDataCenter.HeadPortraitManager.GetHeadPortraitWorldDescById(templateId)
    end,

    [XArrangeConfigs.Types.DormCharacter] = function(templateId)
        return XDormConfig.GetDormWorldDescriptionRewardCharIdById(templateId)
    end,

    [XArrangeConfigs.Types.ChatEmoji] = function(templateId)
        return XDataCenter.ChatManager.GetEmojiWorldDesc(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XWeaponFashionConfigs.GetFashionWorldDescription(templateId)
    end,

    [XArrangeConfigs.Types.Collection] = function(templateId)
        return XMedalConfigs.GetCollectionWorldDescById(templateId)
    end,

    [XArrangeConfigs.Types.Background] = function(templateId)
        return XPhotographConfigs.GetBackgroundWorldDescriptionById(templateId)
    end,
    
    [XArrangeConfigs.Types.Partner] = function(templateId)
        return XPartnerConfigs.GetPartnerTemplateGoodsWorldDesc(templateId)
    end,

    -- [XArrangeConfigs.Types.Nameplate] = function(templateId)
    --     return XMedalConfigs.GetNameplateDescription(templateId)
    -- end,
    [XArrangeConfigs.Types.DrawTicket] = function(templateId) 
        return XDrawConfigs.GetDrawTicketWorldDesc(templateId)
    end,
    [XArrangeConfigs.Types.ItemCollection] = function(templateId)
        local template = XItemConfigs.GetItemCollectTemplate(templateId)
        return template.WorldDesc
    end
}

local GoodsSkipIdParams = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetItemSkipIdParams(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.GetFashionSkipIdParams(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XWeaponFashionConfigs.GetFashionSkipIdParams(templateId)
    end,
}

local GoodsCurrentCount = {
    [XArrangeConfigs.Types.Item] = function(templateId)
        return XDataCenter.ItemManager.GetCount(templateId)
    end,

    [XArrangeConfigs.Types.Character] = function(templateId)
        return XDataCenter.CharacterManager.IsOwnCharacter(templateId) and 1 or 0
    end,

    [XArrangeConfigs.Types.Weapon] = function(templateId)
        return XDataCenter.EquipManager.GetEquipCount(templateId)
    end,

    [XArrangeConfigs.Types.Wafer] = function(templateId)
        return XDataCenter.EquipManager.GetEquipCount(templateId)
    end,

    [XArrangeConfigs.Types.Fashion] = function(templateId)
        return XDataCenter.FashionManager.CheckHasFashion(templateId) and 1 or 0
    end,

    [XArrangeConfigs.Types.BaseEquip] = function(templateId)
        return XDataCenter.BaseEquipManager.GetBaseEquipCount(templateId)
    end,

    [XArrangeConfigs.Types.Furniture] = function(templateId)
        return XDataCenter.FurnitureManager.GetTemplateCount(templateId)
    end,

    [XArrangeConfigs.Types.WeaponFashion] = function(templateId)
        return XDataCenter.WeaponFashionManager.CheckHasFashion(templateId) and 1 or 0
    end,

    [XArrangeConfigs.Types.Collection] = function(templateId)
        return XDataCenter.MedalManager.CheckScoreTitleIsHaveById(templateId) and 1 or 0
    end,

    [XArrangeConfigs.Types.Background] = function(templateId)
        return XDataCenter.PhotographManager.CheckSceneIsHaveById(templateId) and 1 or 0
    end,
    
    [XArrangeConfigs.Types.HeadPortrait] = function(templateId)
        return XDataCenter.HeadPortraitManager.CheckIsUnLockHead(templateId) and 1 or 0
    end,
    
    [XArrangeConfigs.Types.Partner] = function(templateId)
        return XDataCenter.PartnerManager.GetPartnerCountByTemplateId(templateId)
    end,

    [XArrangeConfigs.Types.Nameplate] = function(templateId)
        return XDataCenter.MedalManager.CheckNameplateGroupUnluck(XMedalConfigs.GetNameplateGroup(templateId)) and 1 or 0
    end,
    
    [XArrangeConfigs.Types.DormCharacter] = function(templateId)
        return XDataCenter.DormManager.CheckHaveDormCharacterByRewardId(templateId) and 1 or 0
    end,

    [XArrangeConfigs.Types.RankScore] = function(templateId)
        return XDataCenter.FubenSpecialTrainManager.GetCurScore()
    end,

    [XArrangeConfigs.Types.DlcHuntChip] = function(templateId)
        return XDataCenter.DlcHuntChipManager.GetChipAmountByItemId(templateId)
    end,

    [XArrangeConfigs.Types.ItemCollection] = function(templateId)
        return XDataCenter.ItemManager.CheckCollectItemUnlock(templateId) and 1 or 0
    end,
}

--==============================--
--desc: 通用物品名字获取
--@templateId: 配置表id
--@return 物品名
--==============================--
function XGoodsCommonManager.GetGoodsName(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    return GoodsName[arrangeType] and GoodsName[arrangeType](templateId) or nil
end

--==============================--
--desc: 通用物品默认品质
--@templateId: 配置表id
--@return 物品品质
--==============================--
function XGoodsCommonManager.GetGoodsDefaultQuality(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    return GoodsQuality[arrangeType] and GoodsQuality[arrangeType](templateId) or nil
end

--==============================--
--desc: 通用物品Icon
--@templateId: 配置表id
--@args: 额外参数
--@return 物品Icon
--==============================--
function XGoodsCommonManager.GetGoodsIcon(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    return GoodsIcon[arrangeType] and GoodsIcon[arrangeType](templateId) or nil
end

--==============================--
--desc: 通用物品描述
--@templateId: 配置表id
--@return 物品描述
--==============================--
function XGoodsCommonManager.GetGoodsDescription(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    return GoodsDescription[arrangeType] and GoodsDescription[arrangeType](templateId) or nil
end

--==============================--
--desc: 通用物品世界观描述
--@templateId: 配置表id
--@return 世界观描述
--==============================--
function XGoodsCommonManager.GetGoodsWorldDesc(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    return GoodsWorldDesc[arrangeType] and GoodsWorldDesc[arrangeType](templateId) or nil
end

--==============================--
--desc: 通用物品跳转列表，不包括过期跳转
--@templateId: 配置表id
--@return 跳转列表
--==============================--
function XGoodsCommonManager.GetGoodsSkipIdParams(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    local goodsSkipIdParams = GoodsSkipIdParams[arrangeType]
    if not goodsSkipIdParams then
        return nil
    end

    local skipIds = {}
    local templateSkipIds = GoodsSkipIdParams[arrangeType](templateId)
    for _, skipId in ipairs(templateSkipIds) do
        if XFunctionManager.CheckSkipInDuration(skipId) then
            table.insert(skipIds, skipId)
        end
    end

    return skipIds
end

--==============================--
--desc: 通用物品需要显示的跳转列表
--包括 在持续时间内的跳转 或 过期但IsShowExplain字段为true 的跳转
--需要在上层逻辑中判断跳转是否过期，然后执行相应操作
--@templateId: 配置表id
--@return 跳转列表
--==============================--
function XGoodsCommonManager.GetGoodsShowSkipId(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)
    local goodsSkipIdParams = GoodsSkipIdParams[arrangeType]
    if not goodsSkipIdParams then
        return nil
    end

    local showSkipList = {}
    local allSkipList = GoodsSkipIdParams[arrangeType](templateId)
    for _, skipId in ipairs(allSkipList) do
        if XFunctionManager.CheckSkipInDuration(skipId) or XFunctionConfig.GetIsShowExplain(skipId) then
            table.insert(showSkipList, skipId)
        end
    end

    -- 在持续时间内的跳转排前面
    table.sort(showSkipList, function(a, b)
        local aIsInDuration = XFunctionManager.CheckSkipInDuration(a)
        local bIsInDuration = XFunctionManager.CheckSkipInDuration(b)
        return aIsInDuration and not bIsInDuration
    end)

    return showSkipList
end

--==============================--
--desc: 通用物品当前数量
--@templateId: 配置表id
--@return 当前数量
--==============================--
function XGoodsCommonManager.GetGoodsCurrentCount(templateId)
    --战区贡献道具不在背包，需要特殊处理
    if templateId == XArenaConfigs.CONTRIBUTESCORE_ID then
        return XDataCenter.ArenaManager.GetContributeScore()
    --elseif templateId == XChessPursuitConfig.SHOP_COIN_ITEM_ID then
    --    return XDataCenter.ChessPursuitManager.GetSumCoinCount()
    elseif templateId == XDataCenter.StrongholdManager.GetBatteryItemId() then
        return XDataCenter.StrongholdManager.GetTotalElectricEnergy()
    --elseif templateId == XDataCenter.ReformActivityManager.GetScoreItemId() then
    --    return XDataCenter.ReformActivityManager.GetAllStageAccumulativeScore()
    else
        local arrangeType = XArrangeConfigs.GetType(templateId)
        return GoodsCurrentCount[arrangeType] and GoodsCurrentCount[arrangeType](templateId) or 0
    end
end

local GoodsShowParams = {}

GoodsShowParams[XArrangeConfigs.Types.Item] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Item,
        TemplateId = templateId,
        Name = XDataCenter.ItemManager.GetItemName(templateId),
        Quality = XDataCenter.ItemManager.GetItemQuality(templateId),
        Icon = XDataCenter.ItemManager.GetItemIcon(templateId),
        BigIcon = XDataCenter.ItemManager.GetItemBigIcon(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.Character] = function(templateId)
    local quality = XMVCA.XCharacter:GetCharMinQuality(templateId)

    return {
        RewardType = XRewardManager.XRewardType.Character,
        TemplateId = templateId,
        Name = XMVCA.XCharacter:GetCharacterName(templateId),
        TradeName = XMVCA.XCharacter:GetCharacterTradeName(templateId),
        Quality = quality,
        QualityIcon = XCharacterConfigs.GetCharQualityIconGoods(quality),
        Icon = XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(templateId),
        BigIcon = XDataCenter.CharacterManager.GetCharBigRoundnessHeadIcon(templateId),

    }
end

GoodsShowParams[XArrangeConfigs.Types.Weapon] = function(templateId)
    local quality = XDataCenter.EquipManager.GetEquipQuality(templateId)

    return {
        RewardType = XRewardManager.XRewardType.Equip,
        TemplateId = templateId,
        Name = XDataCenter.EquipManager.GetEquipName(templateId),
        Quality = quality,
        QualityTag = quality > XGoodsCommonManager.QualityType.Gold,
        Star = XDataCenter.EquipManager.GetEquipStar(templateId),
        Site = XDataCenter.EquipManager.GetEquipSiteByTemplateId(templateId),
        Icon = XDataCenter.EquipManager.GetEquipIconPath(templateId),
        BigIcon = XDataCenter.EquipManager.GetEquipBigIconPath(templateId),
        QualityIcon = XDataCenter.EquipManager.GetEquipQualityPath(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.Wafer] = GoodsShowParams[XArrangeConfigs.Types.Weapon]

GoodsShowParams[XArrangeConfigs.Types.Fashion] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Fashion,
        TemplateId = templateId,
        Count = 1,
        Name = XDataCenter.FashionManager.GetFashionName(templateId),
        Quality = XDataCenter.FashionManager.GetFashionQuality(templateId),
        Icon = XDataCenter.FashionManager.GetFashionIcon(templateId),
        BigIcon = XDataCenter.FashionManager.GetFashionBigIcon(templateId),
        CharacterIcon = XDataCenter.FashionManager.GetFashionCharacterIcon(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.BaseEquip] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.BaseEquip,
        TemplateId = templateId,
        Name = XDataCenter.BaseEquipManager.GetBaseEquipName(templateId),
        Quality = XDataCenter.BaseEquipManager.GetBaseEquipQuality(templateId),
        Icon = XDataCenter.BaseEquipManager.GetBaseEquipIcon(templateId),
        BigIcon = XDataCenter.BaseEquipManager.GetBaseEquipBigIcon(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.Furniture] = function(templateId)
    local cfg = XFurnitureConfigs.GetFurnitureReward(templateId)
    if cfg and cfg.FurnitureId then
        return {
            RewardType = XRewardManager.XRewardType.Furniture,
            TemplateId = cfg.FurnitureId,
            Name = XFurnitureConfigs.GetFurnitureNameById(cfg.FurnitureId),
            Icon = XFurnitureConfigs.GetFurnitureIconById(cfg.FurnitureId),
            BigIcon = XFurnitureConfigs.GetFurnitureBigIconById(cfg.FurnitureId),
        }
    end
end

GoodsShowParams[XArrangeConfigs.Types.HeadPortrait] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.HeadPortrait,
        TemplateId = templateId,
        Name = XDataCenter.HeadPortraitManager.GetHeadPortraitNameById(templateId),
        Icon = XDataCenter.HeadPortraitManager.GetHeadPortraitImgSrcById(templateId),
        BigIcon = XDataCenter.HeadPortraitManager.GetHeadPortraitImgSrcById(templateId),
        Effect = XDataCenter.HeadPortraitManager.GetHeadPortraitEffectById(templateId),
        Quality = XDataCenter.HeadPortraitManager.GetHeadPortraitQualityById(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.DormCharacter] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.DormCharacter,
        TemplateId = templateId,
        Name = XDormConfig.GetDormCharacterRewardNameById(templateId),
        Icon = XDormConfig.GetDormCharacterRewardSmallIconById(templateId),
        BigIcon = XDormConfig.GetDormCharacterRewardIconById(templateId),
        Quality = XDormConfig.GetDormCharacterRewardQualityById(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.ChatEmoji] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.ChatEmoji,
        TemplateId = templateId,
        Name = XDataCenter.ChatManager.GetEmojiName(templateId),
        Icon = XDataCenter.ChatManager.GetEmojiIcon(templateId),
        BigIcon = XDataCenter.ChatManager.GetEmojiBigIcon(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.WeaponFashion] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.WeaponFashion,
        TemplateId = templateId,
        Count = 1,
        Name = XWeaponFashionConfigs.GetFashionName(templateId),
        Quality = XWeaponFashionConfigs.GetFashionQuality(templateId),
        Icon = XWeaponFashionConfigs.GetFashionIcon(templateId),
        BigIcon = XWeaponFashionConfigs.GetFashionBigIcon(templateId),
        ShopIcon = XWeaponFashionConfigs.GetFashionShopIcon(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.Collection] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Collection,
        TemplateId = templateId,
        Name = XMedalConfigs.GetCollectionNameById(templateId),
        Quality = XMedalConfigs.GetCollectionDefaultQualityById(templateId),
        Icon = XMedalConfigs.GetCollectionIconById(templateId),
        BigIcon = XMedalConfigs.GetCollectionIconById(templateId),
        LevelIcon = XMedalConfigs.GetCollectionDefaultLevelById(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.Background] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Background,
        TemplateId = templateId,
        Name = XPhotographConfigs.GetBackgroundNameById(templateId),
        Quality = XPhotographConfigs.GetBackgroundQualityById(templateId),
        Icon = XPhotographConfigs.GetBackgroundIconById(templateId),
        BigIcon = XPhotographConfigs.GetBackgroundBigIconById(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.Pokemon] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Pokemon,
        TemplateId = templateId,
        Name = XPokemonConfigs.GetMonsterName(templateId),
        Icon = XPokemonConfigs.GetMonsterHeadIcon(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.Partner] = function(templateId)
    local quality = XPartnerConfigs.GetPartnerTemplateQuality(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Partner,
        TemplateId = templateId,
        Name = XPartnerConfigs.GetPartnerTemplateName(templateId),
        Icon = XPartnerConfigs.GetPartnerTemplateIcon(templateId),
        Quality = quality,
        QualityIcon = XCharacterConfigs.GetCharQualityIconGoods(quality),
    }
end

GoodsShowParams[XArrangeConfigs.Types.Nameplate] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.Nameplate,
        TemplateId = templateId,
        Name = XMedalConfigs.GetNameplateName(templateId),
        Icon = XMedalConfigs.GetNameplateIcon(templateId),
        Quality = XMedalConfigs.GetNameplateQuality(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.RankScore] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.RankScore,
        TemplateId = templateId,
        Name = XFubenSpecialTrainConfig.GetRankScoreGoodName(templateId),
        Icon = XFubenSpecialTrainConfig.GetRankScoreGoodIcon(templateId),
        Quality = XFubenSpecialTrainConfig.GetRankScoreGoodQuality(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.DrawTicket] = function(templateId)
    local cfg = XDrawConfigs.GetDrawTicketCfg(templateId)
    return {
        RewardType = XRewardManager.XRewardType.DrawTicket,
        TemplateId = templateId,
        Name = cfg.Name,
        Icon = cfg.Icon,
        BigIcon = cfg.BigIcon,
        Quality = cfg.Quality
    }
end

GoodsShowParams[XArrangeConfigs.Types.GuildGoods] = function(templateId) 
    return {
        RewardType = XRewardManager.XRewardType.GuildGoods,
        TemplateId = templateId,
        Name = XGuildConfig.GetGoodsName(templateId),
        Icon = XGuildConfig.GetGoodsIcon(templateId),
        GoodsType = XGuildConfig.GetGoodsType(templateId),
        BigIcon = XGuildConfig.GetGoodsBigIcon(templateId)
    }
end

GoodsShowParams[XArrangeConfigs.Types.DlcHuntChip] = function(templateId)
    return {
        RewardType = XRewardManager.XRewardType.DlcHuntChip,
        TemplateId = templateId,
        Name = XDlcHuntChipConfigs.GetChipName(templateId),
        Icon = XDlcHuntChipConfigs.GetChipIcon(templateId),
        Quality = XDlcHuntChipConfigs.GetChipQuality(templateId),
    }
end

GoodsShowParams[XArrangeConfigs.Types.ItemCollection] = function(templateId)
    local template = XItemConfigs.GetItemCollectTemplate(templateId)
    return {
        RewardType = XRewardManager.XRewardType.ItemCollection,
        TemplateId = templateId,
        Name = template.Name,
        Icon = template.Icon,
        BigIcon = template.BigIcon,
        Quality = template.Quality
    }
end
--==============================--
--desc: 通用物品展示参数
--@templateId: 配置表id
--@return 物品展示参数
--==============================--
function XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
    local arrangeType = XArrangeConfigs.GetType(templateId)

    if not GoodsShowParams[arrangeType] then
        local str = "XGoodsCommonManager.GetGoodsShowParamsByTemplateId error: goods type is nonsupport, arrangeType is "
        XLog.Error(str .. arrangeType .. " templateId is " .. templateId)
        return
    end

    return GoodsShowParams[arrangeType](templateId)
end