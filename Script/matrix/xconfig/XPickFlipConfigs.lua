XPickFlipConfigs = XPickFlipConfigs or {}

-- 配置表
local SHARE_TABLE_PATH = "Share/MiniActivity/PickFlip/"
local CLIENT_TABLE_PATH = "Client/MiniActivity/PickFlip/"

XPickFlipConfigs.UiRewardDetailType = {
    Config = 1, -- 配置界面
    Check = 2 -- 查看界面
}

XPickFlipConfigs.RewardType = {
    Select = 1,
    Random = 2,
    All = 3
}

XPickFlipConfigs.RewardState = {
    Unfliped = 0,
    Fliped = 1
}

XPickFlipConfigs.LayerRewardState = {
    Unrewarded = 0,
    Rewarded = 1
}

-- 配置数据
local Group2LayerIds = {}

function XPickFlipConfigs.Init()
    XConfigCenter.CreateGetPropertyByFunc(XPickFlipConfigs, "PickFlipActivity", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "PickFlipActivity.tab", XTable.XTablePickFlipActivity, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XPickFlipConfigs, "PickFlipRewardGroup", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "PickFlipRewardGroup.tab", XTable.XTablePickFlipRewardGroup, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XPickFlipConfigs, "PickFlipReward", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "PickFlipReward.tab", XTable.XTablePickFlipReward, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XPickFlipConfigs, "PickFlipTextRule", function()
        return XTableManager.ReadByIntKey(CLIENT_TABLE_PATH .. "PickFlipTextRule.tab", XTable.XTablePickFlipTextRule, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XPickFlipConfigs, "PickFlipItemTypeConfig", function()
        return XTableManager.ReadByIntKey(CLIENT_TABLE_PATH .. "PickFlipItemTypeConfig.tab", XTable.XTablePickFlipItemTypeConfig, "ItemType")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XPickFlipConfigs, "PickFlipClienConfig", function()
        return XTableManager.ReadByStringKey(CLIENT_TABLE_PATH .. "PickFlipClienConfig.tab", XTable.XTablePickFlipClienConfig, "Key")
    end)
end

function XPickFlipConfigs.GetRewardGroupConfig(id)
    return XPickFlipConfigs.GetPickFlipActivity(id)
end

function XPickFlipConfigs.GetRewardLayerConfig(id)
    return XPickFlipConfigs.GetPickFlipRewardGroup(id)
end

function XPickFlipConfigs.GetRewardConfig(id)
    return XPickFlipConfigs.GetPickFlipReward(id)
end

function XPickFlipConfigs.GetCurrentGroupId()
    local defaultId
    for id, config in pairs(XPickFlipConfigs.GetPickFlipActivity()) do
        defaultId = id
        if XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            return id
        end
    end
    return defaultId
end

function XPickFlipConfigs.GetRewardGroupAllLayerIds(groupId)
    local result = Group2LayerIds[groupId]
    if result == nil then
        result = {}
        for id, config in pairs(XPickFlipConfigs.GetPickFlipRewardGroup()) do
            if config.ActivityId == groupId then
                table.insert(result, id)
            end
        end
        Group2LayerIds[groupId] = result
    end
    return result
end

function XPickFlipConfigs.GetLayerRewardIds(layerId, rewardType)
    local result = {}
    for id, config in pairs(XPickFlipConfigs.GetPickFlipReward()) do
        if config.RewardGroupId == layerId and 
            (config.Type == rewardType or rewardType == nil) then
            table.insert(result, id)
        end
    end
    return result
end

function XPickFlipConfigs.GetTextRuleConfig(groupId)
    for _, config in pairs(XPickFlipConfigs.GetPickFlipTextRule()) do
        if config.ActivityId == groupId then
            return config
        end
    end
end

function XPickFlipConfigs.GetItemTypeName(itemType)
    return XPickFlipConfigs.GetPickFlipItemTypeConfig(itemType).Name
end

function XPickFlipConfigs.GetItemTypeIsSpecial(itemType)
    return XPickFlipConfigs.GetPickFlipItemTypeConfig(itemType).IsSpecial
end

function XPickFlipConfigs.GetConsumeSpecialIcons()
    return XPickFlipConfigs.GetPickFlipClienConfig("ConsumeIcons").Values
end

function XPickFlipConfigs.GetTargetIcon()
    return XPickFlipConfigs.GetPickFlipClienConfig("TargetIcon").Values[1]
end