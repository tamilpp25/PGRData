XTypeManager = XTypeManager or {}

local GetNameFuncs = {}
local GetQualityFuncs = {}

----Initialize----
function XTypeManager.Init()
    GetNameFuncs[XArrangeConfigs.Types.Character] = function(id) return XMVCA.XCharacter:GetCharacterLogName(id) end
    GetNameFuncs[XArrangeConfigs.Types.Weapon] = function(id) return XMVCA.XEquip:GetEquipName(id) end
    GetNameFuncs[XArrangeConfigs.Types.Wafer] = function(id) return XMVCA.XEquip:GetEquipName(id) end
    GetNameFuncs[XArrangeConfigs.Types.Item] = XDataCenter.ItemManager.GetItemName
    GetNameFuncs[XArrangeConfigs.Types.Fashion] = XDataCenter.FashionManager.GetFashionName
    GetNameFuncs[XArrangeConfigs.Types.Furniture] = XFurnitureConfigs.GetFurnitureNameById
    GetNameFuncs[XArrangeConfigs.Types.HeadPortrait] = XDataCenter.HeadPortraitManager.GetHeadPortraitNameById
    GetNameFuncs[XArrangeConfigs.Types.ChatEmoji] = XDataCenter.ChatManager.GetEmojiName
    GetNameFuncs[XArrangeConfigs.Types.WeaponFashion] = XWeaponFashionConfigs.GetFashionName
    GetNameFuncs[XArrangeConfigs.Types.Collection] = XMedalConfigs.GetCollectionNameById
    GetNameFuncs[XArrangeConfigs.Types.Partner] = XPartnerConfigs.GetPartnerTemplateName
    GetNameFuncs[XArrangeConfigs.Types.Background] = XPhotographConfigs.GetBackgroundNameById

    GetQualityFuncs[XArrangeConfigs.Types.Character] = function(id) return XMVCA.XCharacter:GetCharMinQuality(id) end
    GetQualityFuncs[XArrangeConfigs.Types.Weapon] = function(id) return XMVCA.XEquip:GetEquipQuality(id) end
    GetQualityFuncs[XArrangeConfigs.Types.Wafer] = function(id) return XMVCA.XEquip:GetEquipQuality(id) end
    GetQualityFuncs[XArrangeConfigs.Types.Item] = XDataCenter.ItemManager.GetItemQuality
    GetQualityFuncs[XArrangeConfigs.Types.Fashion] = XDataCenter.FashionManager.GetFashionQuality
    GetQualityFuncs[XArrangeConfigs.Types.Furniture] = XDataCenter.FurnitureManager.GetRewardFurnitureQuality
    GetQualityFuncs[XArrangeConfigs.Types.HeadPortrait] = XDataCenter.HeadPortraitManager.GetHeadPortraitQualityById
    GetQualityFuncs[XArrangeConfigs.Types.DormCharacter] = XDormConfig.GetDormCharacterRewardQualityById
    GetQualityFuncs[XArrangeConfigs.Types.ChatEmoji] = XDataCenter.ChatManager.GetEmojiQuality
    GetQualityFuncs[XArrangeConfigs.Types.WeaponFashion] = XWeaponFashionConfigs.GetFashionQuality
    GetQualityFuncs[XArrangeConfigs.Types.Collection] = XMedalConfigs.GetCollectionDefaultQualityById
    GetQualityFuncs[XArrangeConfigs.Types.Partner] = XPartnerConfigs.GetPartnerTemplateQuality
    GetQualityFuncs[XArrangeConfigs.Types.Background] = XPhotographConfigs.GetBackgroundQualityById
end

----Public Methods----
local GetTypeById = function(id)
    return XArrangeConfigs.GetType(id)
end

local GetNameById = function(id)
    local type = GetTypeById(id)
    return GetNameFuncs[type](id)
end

local GetQualityById = function(id)
    local type = GetTypeById(id)
    return GetQualityFuncs[type](id)
end

XTypeManager.GetTypeById = GetTypeById --(id)
XTypeManager.GetQualityById = GetQualityById --(id)
XTypeManager.GetNameById = GetNameById --(id)