XFubenRogueLikeConfig = XFubenRogueLikeConfig or {}

local CLIENT_ROGUELIKE_ACTIVITY = "Client/Fuben/RogueLike/RogueLikeActivityDetails.tab"
local CLIENT_ROGUELIKE_Buff = "Client/Fuben/RogueLike/RogueLikeBuffDetails.tab"

local CLIENT_ROGUELIKE_TIER_SECTION = "Client/Fuben/RogueLike/RogueLikeTierSectionDetails.tab"
local CLIENT_ROGUELIKE_TIER_SPECIALEVENT = "Client/Fuben/RogueLike/RogueLikeSpecialEventDetails.tab"
local CLIENT_ROGUELIKE_SUPPORTSTATION = "Client/Fuben/RogueLike/RogueLikeSupportStationDetails.tab"
local CLIENT_ROGUELIKE_SPECIALEVENTGROUPITEM = "Client/Fuben/RogueLike/RogueLikeSpecialEventGroupItem.tab"
local CLIENT_ROGUELIKE_SPECIALEVENTGROUPDETAIL = "Client/Fuben/RogueLike/RogueLikeSpecialEventGroupDetails.tab"
local CLIENT_ROGUELIKE_SCORE_DETAIL = "Client/Fuben/RogueLike/RogueLikePurgatoryScoreDesDetail.tab"

local SHARE_ROGUELIKE_ACTIVITY = "Share/Fuben/RogueLike/RogueLikeActivity.tab"
local SHARE_ROGUELIKE_BOX = "Share/Fuben/RogueLike/RogueLikeBox.tab"
local SHARE_ROGUELIKE_BUFF = "Share/Fuben/RogueLike/RogueLikeBuff.tab"
local SHARE_ROGUELIKE_EVENT = "Share/Fuben/RogueLike/RogueLikeEvent.tab"
local SHARE_ROGUELIKE_NODE = "Share/Fuben/RogueLike/RogueLikeNode.tab"
local SHARE_ROGUELIKE_ROBOT = "Share/Fuben/RogueLike/RogueLikeRobot.tab"
local SHARE_ROGUELIKE_SHOP = "Share/Fuben/RogueLike/RogueLikeShop.tab"
local SHARE_ROGUELIKE_SHOPITEM = "Share/Fuben/RogueLike/RogueLikeShopItem.tab"
local SHARE_ROGUELIKE_TIER = "Share/Fuben/RogueLike/RogueLikeTier.tab"
local SHARE_ROGUELIKE_TIER_SECTION = "Share/Fuben/RogueLike/RogueLikeTierSection.tab"
local SHARE_ROGUELIKE_RECOVER = "Share/Fuben/RogueLike/RogueLikeRecover.tab"
local SHARE_ROGUELIKE_SPECIALEVENT = "Share/Fuben/RogueLike/RogueLikeSpecialEvent.tab"
local SHARE_ROGUELIKE_TEAMEFFECT = "Share/Fuben/RogueLike/RogueLikeTeamEffect.tab"
local SHARE_ROGUELIKE_SUPPORTSTATION = "Share/Fuben/RogueLike/RogueLikeSupportStation.tab"
local SHARE_ROGUELIKE_SPECIALEVENTGROUP = "Share/Fuben/RogueLike/RogueLikeSpecialEventGroup.tab"
local SHARE_ROGUELIKE_NODE_DETAILS = "Share/Fuben/RogueLike/RogueLikeNodeDetails.tab"



local ActivityConfig = {}
local BuffConfig = {}
local NodeConfig = {}
local TierSectionConfig = {}
local SpecialEventConfig = {}
local SupportStationConfig = {}
local SpecialEventGroupDetailsConfig = {}
local SpecialEventGroupItemConfig = {}

local RogueLikeActivity = {}
local RogueLikeBox = {}
local RogueLikeBuff = {}
local RogueLikeEvent = {}
local RogueLikeNode = {}
local RogueLikeRobot = {}
local RogueLikeShop = {}
local RogueLikeShopItem = {}
local RogueLikeTier = {}
local RogueLikeTierSection = {}
local RogueLikeRecover = {}
local RogueLikeSpecialEvent = {}
local RogueLikeTeamEffect = {}
local RogueLikeSupportStation = {}
local RogueLikeSpecialEventGroup = {}
local RogueLikePurgatoryScoreDesConfig = {}

local Section2GroupMap = {}
local Group2TierMap = {}

local Group2NodeMap = {}
local NodeIndexMap = {}

XFubenRogueLikeConfig.TEAM_NUMBER = CS.XGame.ClientConfig:GetInt("RogueLikeTeamMemberCount")
XFubenRogueLikeConfig.UNKNOW_ROBOT = CS.XGame.ClientConfig:GetString("RogueLikeUnknowRobot")

XFubenRogueLikeConfig.NORMAL_NODE = CS.XGame.ClientConfig:GetString("RogueLikeNormalNode")
XFubenRogueLikeConfig.BOSS_NODE = CS.XGame.ClientConfig:GetString("RogueLikeBossNode")

XFubenRogueLikeConfig.ChallengeCoin = CS.XGame.ClientConfig:GetInt("RogueLikeChallengeCoin")
XFubenRogueLikeConfig.PumpkinCoin = CS.XGame.ClientConfig:GetInt("RogueLikePumpkinCoin")
XFubenRogueLikeConfig.KeepsakeCoin = CS.XGame.ClientConfig:GetInt("RogueLikeKeepsakeCoin")

XFubenRogueLikeConfig.CHECK_LINES = CS.XGame.ClientConfig:GetInt("RogueLikeCheckLineSwitch")

XFubenRogueLikeConfig.KEY_PLAY_STORY = "KeyRogueLikePlayBeginStory"
XFubenRogueLikeConfig.KEY_SHOW_TIPS = "KeyRogueLikeShowTips"

XFubenRogueLikeConfig.XRLNodeType = {
    Fight = 1, --战斗//不需要请求
    Box = 2, --宝箱//不需要请求
    Rest = 3, --休息//不需要请求
    Shop = 4, --商店//需要请求
    Event = 5, --事件//需要请求
}

--这里是定义副本模式的枚举
XFubenRogueLikeConfig.TierType = {
    Normal = 1, --普通
    Purgatory = 2, --试炼
}
-- 节点图标类型
XFubenRogueLikeConfig.NodeTabBg = {
    [XFubenRogueLikeConfig.XRLNodeType.Fight] = CS.XGame.ClientConfig:GetString("RogueLikeTabFightNor"),
    [XFubenRogueLikeConfig.XRLNodeType.Box] = CS.XGame.ClientConfig:GetString("RogueLikeTabBox"),
    [XFubenRogueLikeConfig.XRLNodeType.Rest] = CS.XGame.ClientConfig:GetString("RogueLikeTabRest"),
    [XFubenRogueLikeConfig.XRLNodeType.Shop] = CS.XGame.ClientConfig:GetString("RogueLikeTabShop"),
    [XFubenRogueLikeConfig.XRLNodeType.Event] = CS.XGame.ClientConfig:GetString("RogueLikeTabEvent"),
}
XFubenRogueLikeConfig.NodeTabDisBg = {
    [XFubenRogueLikeConfig.XRLNodeType.Fight] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabNor"),
    [XFubenRogueLikeConfig.XRLNodeType.Box] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabBox"),
    [XFubenRogueLikeConfig.XRLNodeType.Rest] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabRest"),
    [XFubenRogueLikeConfig.XRLNodeType.Shop] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabShop"),
    [XFubenRogueLikeConfig.XRLNodeType.Event] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabEvent"),
}
XFubenRogueLikeConfig.NodeFightType = {
    Normal = 1,
    Elite = 2,
    Boss = 3
}
XFubenRogueLikeConfig.NodeFightTabBg = {
    [XFubenRogueLikeConfig.NodeFightType.Normal] = CS.XGame.ClientConfig:GetString("RogueLikeTabFightNor"),
    [XFubenRogueLikeConfig.NodeFightType.Elite] = CS.XGame.ClientConfig:GetString("RogueLikeTabFightElite"),
    [XFubenRogueLikeConfig.NodeFightType.Boss] = CS.XGame.ClientConfig:GetString("RogueLikeTabFightBoss"),
}
XFubenRogueLikeConfig.NodeFightTabDisBg = {
    [XFubenRogueLikeConfig.NodeFightType.Normal] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabNor"),
    [XFubenRogueLikeConfig.NodeFightType.Elite] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabElite"),
    [XFubenRogueLikeConfig.NodeFightType.Boss] = CS.XGame.ClientConfig:GetString("RogueLikeDisTabBoss"),
}

XFubenRogueLikeConfig.XRLBoxType = {
    Item = 1, --物品
    Buff = 2, --buff
}

XFubenRogueLikeConfig.XRLShopItemType = {
    Item = 1,
    Buff = 2,
    Robot = 3,
}

XFubenRogueLikeConfig.XRLEventType = {
    NormalNode = 1, --普通节点事件
    Other = 2, --其他事件
}

XFubenRogueLikeConfig.XRLResetType = {
    Recover = 1, --恢复行动点
    IntensifyBuff = 2, --强化buff
}

-- buff类型
XFubenRogueLikeConfig.BuffType = {
    PositiveBuff = 1,
    NegativeBuff = 2
}

-- 特殊事件结果类型
XFubenRogueLikeConfig.SpecialResultType = {
    SingleEvent = 1,
    MultipleEvent = 2,
}

-- 选择出站类型
XFubenRogueLikeConfig.SelectCharacterType = {
    Character = 1,
    Robot = 2,
}

XFubenRogueLikeConfig.XRLOtherEventType = {
    --获得buff
    AddBuff = 1, --测过
    --移除buff
    RemoveBuff = 2,
    --获得助战机器人
    AddRobot = 3, --测过
    --血量恢复
    AddHp = 4,
    --增加行动点
    AddActionPoint = 5, --测过
    --减少行动点
    ActionPoint = 6, --测过
    --获得物品
    GainItem = 7,
    --兑换物品
    ExchangeItem = 8,
    --消耗物品
    ConsumeItem = 9,
    -- 减少血量
    ReduceHp = 10,
    -- 获得物品(百分比)
    GainItemRate = 11,
    -- 消耗物品(百分比)
    ConsumeItemRate = 12,
}

-- 休息点操作，回复行动点，强化buff，离开
XFubenRogueLikeConfig.ClientRestCount = 3
XFubenRogueLikeConfig.ClientRestClickType = {
    Recover = 1,
    IntensifyBuff = 2,
    Leave = 3,
}
XFubenRogueLikeConfig.ClientRestClickName = {
    [XFubenRogueLikeConfig.ClientRestClickType.Recover] = CS.XTextManager.GetText("RogueLikeAddActionPoint"),
    [XFubenRogueLikeConfig.ClientRestClickType.IntensifyBuff] = CS.XTextManager.GetText("RogueLikeIntensifyBuff"),
    [XFubenRogueLikeConfig.ClientRestClickType.Leave] = CS.XTextManager.GetText("RogueLikeRestLeave"),
}

function XFubenRogueLikeConfig.Init()
    RogueLikeActivity = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_ACTIVITY, XTable.XTableRogueLikeActivity, "Id")
    RogueLikeBox = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_BOX, XTable.XTableRogueLikeBox, "Id")
    RogueLikeBuff = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_BUFF, XTable.XTableRogueLikeBuff, "Id")
    RogueLikeEvent = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_EVENT, XTable.XTableRogueLikeEvent, "Id")
    RogueLikeNode = XTableManager.ReadAllByIntKey(SHARE_ROGUELIKE_NODE, XTable.XTableRogueLikeNode, "Id")
    RogueLikeRobot = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_ROBOT, XTable.XTableRogueLikeRobot, "Id")
    RogueLikeShop = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_SHOP, XTable.XTableRogueLikeShop, "Id")
    RogueLikeShopItem = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_SHOPITEM, XTable.XTableRogueLikeShopItem, "Id")
    RogueLikeTier = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_TIER, XTable.XTableRogueLikeTier, "Id")
    RogueLikeTierSection = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_TIER_SECTION, XTable.XTableRogueLikeTierSection, "Id")
    RogueLikeRecover = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_RECOVER, XTable.XTableRogueLikeRecover, "Id")
    RogueLikeSpecialEvent = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_SPECIALEVENT, XTable.XTableRogueLikeSpecialEvent, "Id")
    RogueLikeTeamEffect = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_TEAMEFFECT, XTable.XTableRogueLikeTeamEffect, "Id")
    RogueLikeSupportStation = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_SUPPORTSTATION, XTable.XTableRogueLikeSupportStation, "Id")
    RogueLikeSpecialEventGroup = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_SPECIALEVENTGROUP, XTable.XTableRogueLikeSpecialEventGroup, "Id")

    ActivityConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_ACTIVITY, XTable.XTableRogueLikeActivityDetails, "Id")
    BuffConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_Buff, XTable.XTableRogueLikeBuffDetails, "Id")
    NodeConfig = XTableManager.ReadByIntKey(SHARE_ROGUELIKE_NODE_DETAILS, XTable.XTableRogueLikeNodeDetails, "Id")
    TierSectionConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_TIER_SECTION, XTable.XTableRogueLikeTierSectionDetails, "Id")
    SpecialEventConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_TIER_SPECIALEVENT, XTable.XTableRogueLikeSpecialEventDetails, "Id")
    SupportStationConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_SUPPORTSTATION, XTable.XTableRogueLikeSupportStationDetails, "Id")
    SpecialEventGroupDetailsConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_SPECIALEVENTGROUPDETAIL, XTable.XTableRogueLikeSpecialEventGroupDetails, "Id")
    SpecialEventGroupItemConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_SPECIALEVENTGROUPITEM, XTable.XTableRogueLikeSpecialEventGroupItem, "Id")

    RogueLikePurgatoryScoreDesConfig = XTableManager.ReadByIntKey(CLIENT_ROGUELIKE_SCORE_DETAIL, XTable.XTableRogueLikePurgatoryScoreDesDetail, "Type")

    XFubenRogueLikeConfig.InitGroup2TierMap()
end

function XFubenRogueLikeConfig.InitGroup2TierMap()

    -- 按照groupId, tier存储节点
    Group2TierMap = {}
    for _, v in pairs(RogueLikeTier) do
        if not Group2TierMap[v.Group] then
            Group2TierMap[v.Group] = {}
        end
        if not Group2TierMap[v.Group][v.Tier] then
            Group2TierMap[v.Group][v.Tier] = {}
        end

        Group2TierMap[v.Group][v.Tier] = {
            Nodes = v.NodeId,
            FatherNodes = v.FatherNode,
        }
    end

    -- Section2GroupMap
    for _, v in pairs(RogueLikeTierSection) do
        for i = 1, #v.GroupId do
            local groupId = v.GroupId[i]
            if not Section2GroupMap[groupId] then
                Section2GroupMap[groupId] = {}
            end

            Section2GroupMap[groupId] = {
                GroupId = groupId,
                MinTier = v.MinTier,
                MaxTier = v.MaxTier,
            }
        end
    end

end

function XFubenRogueLikeConfig.GetNodesByGroupId(groupId)
    if not Group2NodeMap[groupId] then
        Group2NodeMap[groupId] = {}
        NodeIndexMap[groupId] = {}
        local SectionData = Section2GroupMap[groupId]
        if not SectionData then
            --XLog.Error("SectoinData not exist :" .. tostring(groupId))
            XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetNodesByGroupId",
            "SectionData", SHARE_ROGUELIKE_TIER_SECTION, "groupId", tostring(groupId))
        end
        local nodeIndex = 0
        for i = SectionData.MinTier, SectionData.MaxTier do
            local nodeDatas = Group2TierMap[groupId][i]
            for j = 1, #nodeDatas.Nodes do
                nodeIndex = nodeIndex + 1
                Group2NodeMap[groupId][nodeIndex] = {}
                Group2NodeMap[groupId][nodeIndex].Index = nodeIndex
                Group2NodeMap[groupId][nodeIndex].Group = groupId
                Group2NodeMap[groupId][nodeIndex].TierIndex = i
                Group2NodeMap[groupId][nodeIndex].NodeId = nodeDatas.Nodes[j]
                local fatherNodes = {}
                if nodeDatas.FatherNodes[j] then
                    fatherNodes = string.Split(nodeDatas.FatherNodes[j], '|')
                end
                Group2NodeMap[groupId][nodeIndex].FatherNodes = {}
                for fatherNodeIndex = 1, #fatherNodes do
                    Group2NodeMap[groupId][nodeIndex].FatherNodes[fatherNodeIndex] = tonumber(fatherNodes[fatherNodeIndex])
                end
                NodeIndexMap[groupId][nodeDatas.Nodes[j]] = nodeIndex
            end
        end
    end

    return Group2NodeMap[groupId], NodeIndexMap[groupId]
end

function XFubenRogueLikeConfig.GetGroup2TierMapDatas(groupId, tierIndex)
    return Group2TierMap[groupId][tierIndex]
end

function XFubenRogueLikeConfig.GetNodesByGroup(group)
    return Group2TierMap[group]
end

function XFubenRogueLikeConfig.GetRougueLikeTemplateById(id)
    if not RogueLikeActivity[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRougueLikeTemplateById",
        "RogueLikeActivity", SHARE_ROGUELIKE_ACTIVITY, "Id", tostring(id))
        return
    end
    return RogueLikeActivity[id]
end

function XFubenRogueLikeConfig.GetLastRogueLikeConfig()
    local config = RogueLikeActivity[#RogueLikeActivity]

    if not config then
        XLog.Error("配置表：RogueLikeActivity 没有配置数据")
        return
    end
    return config
end

function XFubenRogueLikeConfig.GetRogueLikeConfigById(id)
    if not ActivityConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRogueLikeConfigById",
        "RogueLikeActivityDetails", CLIENT_ROGUELIKE_ACTIVITY, "Id", tostring(id))
        return
    end
    return ActivityConfig[id]
end

function XFubenRogueLikeConfig.GetBoxTemplateById(id)
    if not RogueLikeBox[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetBoxTemplateById", "RogueLikeBox", SHARE_ROGUELIKE_BOX, "Id", tostring(id))
        return
    end
    return RogueLikeBox[id]
end

function XFubenRogueLikeConfig.GetBuffTemplateById(id)
    if not RogueLikeBuff[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetBuffTemplateById", "RogueLikeBuff", SHARE_ROGUELIKE_BUFF, "Id", tostring(id))
        return
    end
    return RogueLikeBuff[id]
end

function XFubenRogueLikeConfig.GetBuffConstItemIdById(id)
    if not RogueLikeBuff[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetBuffTemplateById", "RogueLikeBuff", SHARE_ROGUELIKE_BUFF, "Id", tostring(id))
        return
    end
    return RogueLikeBuff[id].CostItemId
end

function XFubenRogueLikeConfig.GetBuffConstItemCountById(id)
    if not RogueLikeBuff[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetBuffTemplateById", "RogueLikeBuff", SHARE_ROGUELIKE_BUFF, "Id", tostring(id))
        return
    end
    return RogueLikeBuff[id].CostItemCount
end

function XFubenRogueLikeConfig.IsBuffMaxLevel(id)
    local buffTemplate = XFubenRogueLikeConfig.GetBuffTemplateById(id)
    return buffTemplate.IntensifyId == nil or buffTemplate.IntensifyId == 0
end

function XFubenRogueLikeConfig.GetBuffConfigById(id)
    if not BuffConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetBuffConfigById", "RogueLikeBuffDetails", CLIENT_ROGUELIKE_Buff, "Id", tostring(id))
        return
    end
    return BuffConfig[id]
end

function XFubenRogueLikeConfig.GetEventTemplateById(id)
    if not RogueLikeEvent[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetEventTemplateById", "RogueLikeEvent", SHARE_ROGUELIKE_EVENT, "Id", tostring(id))
        return
    end
    return RogueLikeEvent[id]
end

function XFubenRogueLikeConfig.GetNodeTemplateById(id)
    if not RogueLikeNode[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetNodeTemplateById", "RogueLikeNode", SHARE_ROGUELIKE_NODE, "Id", tostring(id))
        return
    end
    return RogueLikeNode[id]
end

function XFubenRogueLikeConfig.GetAllNodes()
    return RogueLikeNode
end

function XFubenRogueLikeConfig.GetNodeConfigteById(id)
    if not NodeConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetNodeConfigteById", "RogueLikeNodeDetails", SHARE_ROGUELIKE_NODE_DETAILS, "Id", tostring(id))
        return
    end
    return NodeConfig[id]
end


function XFubenRogueLikeConfig.GetRobotTemplateById(id)
    if not RogueLikeRobot[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRobotTemplateById", "RogueLikeRobot", SHARE_ROGUELIKE_ROBOT, "Id", tostring(id))
        return
    end
    return RogueLikeRobot[id]
end

function XFubenRogueLikeConfig.GetShopTemplateById(id)
    if not RogueLikeShop[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetShopTemplateById", "RogueLikeShop", SHARE_ROGUELIKE_SHOP, "Id", tostring(id))
        return
    end
    return RogueLikeShop[id]
end

function XFubenRogueLikeConfig.GetShopItemTemplateById(id)
    if not RogueLikeShopItem[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetShopItemTemplateById",
        "RogueLikeShopItem", SHARE_ROGUELIKE_SHOPITEM, "Id", tostring(id))
        return
    end
    return RogueLikeShopItem[id]
end

function XFubenRogueLikeConfig.GetTierTemplateById(id)
    if not RogueLikeTier[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetTierTemplateById", "RogueLikeTier", SHARE_ROGUELIKE_TIER, "Id", tostring(id))
        return
    end
    return RogueLikeTier[id]
end

function XFubenRogueLikeConfig.GetTierSectionTemplateById(id)
    if not RogueLikeTierSection[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetTierSectionTemplateById",
        "RogueLikeTierSection", SHARE_ROGUELIKE_TIER_SECTION, "Id", tostring(id))
        return
    end
    return RogueLikeTierSection[id]
end

function XFubenRogueLikeConfig.GetTierSectionTierTypeById(id)
    return RogueLikeTierSection[id] and RogueLikeTierSection[id].TierType
end

function XFubenRogueLikeConfig.GetTierSectionConfigById(id)
    if not TierSectionConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetTierSectionConfigById",
        "TierSectionDetails", CLIENT_ROGUELIKE_TIER_SECTION, "Id", tostring(id))
        return
    end
    return TierSectionConfig[id]
end

function XFubenRogueLikeConfig.GetRecoverTemplateById(id)
    if not RogueLikeRecover[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRecoverTemplateById", "RogueLikeRecover", SHARE_ROGUELIKE_RECOVER, "Id", tostring(id))
        return
    end
    return RogueLikeRecover[id]
end

function XFubenRogueLikeConfig.GetRecoverHpPercentById(id)
    if not RogueLikeRecover[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRecoverTemplateById", "RogueLikeRecover", SHARE_ROGUELIKE_RECOVER, "Id", tostring(id))
        return
    end
    return RogueLikeRecover[id].HpPercent
end

-- 获取恢复血量所需支援配额
function XFubenRogueLikeConfig.GetRecoverCostSupportPointById(id)
    if not RogueLikeRecover[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRecoverTemplateById", "RogueLikeRecover", SHARE_ROGUELIKE_RECOVER, "Id", tostring(id))
        return
    end
    return RogueLikeRecover[id].CostSupportPoint
end

function XFubenRogueLikeConfig.GetSpecialEventTemplateById(id)
    if not RogueLikeSpecialEvent[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSpecialEventTemplateById",
        "RogueLikeSpecialEvent", SHARE_ROGUELIKE_SPECIALEVENT, "Id", tostring(id))
        return
    end
    return RogueLikeSpecialEvent[id]
end

function XFubenRogueLikeConfig.GetSpecialEventConfigById(id)
    if not SpecialEventConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSpecialEventConfigById",
        "RogueLikeSpecialEventDetails", CLIENT_ROGUELIKE_TIER_SPECIALEVENT, "Id", tostring(id))
        return
    end
    return SpecialEventConfig[id]
end

function XFubenRogueLikeConfig.GetTeamEffectTemplateById(id)
    if not RogueLikeTeamEffect[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetTeamEffectTemplateById",
        "RogueLikeTeamEffect", SHARE_ROGUELIKE_TEAMEFFECT, "Id", tostring(id))
        return
    end
    return RogueLikeTeamEffect[id]
end

function XFubenRogueLikeConfig.RogueLikeIsCheckLines()
    return XFubenRogueLikeConfig.CHECK_LINES == 1
end

function XFubenRogueLikeConfig.GetAllSupports()
    return RogueLikeSupportStation
end

function XFubenRogueLikeConfig.GetSupportStationTemplateById(id)
    if not RogueLikeSupportStation[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSupportStationTemplateById",
        "RogueLikeSupportStation", SHARE_ROGUELIKE_SUPPORTSTATION, "Id", tostring(id))
        return
    end
    return RogueLikeSupportStation[id]
end

function XFubenRogueLikeConfig.GetSupportStationConfigById(id)
    if not SupportStationConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSupportStationConfigById",
        "SupportStationDetails", CLIENT_ROGUELIKE_SUPPORTSTATION, "Id", tostring(id))
        return
    end
    return SupportStationConfig[id]
end

function XFubenRogueLikeConfig.GetSepcialEventGroupTemplateById(id)
    if not RogueLikeSpecialEventGroup[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSepcialEventGroupTemplateById",
        "RogueLikeSpecialEventGroup", SHARE_ROGUELIKE_SPECIALEVENTGROUP, "Id", tostring(id))
        return
    end
    return RogueLikeSpecialEventGroup[id]
end

function XFubenRogueLikeConfig.GetSpecialEventGroupConfigById(id)
    if not SpecialEventGroupDetailsConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSpecialEventGroupConfigById",
        "RogueLikeSpecialEventGroupDetails", CLIENT_ROGUELIKE_SPECIALEVENTGROUPDETAIL, "Id", tostring(id))
        return
    end
    return SpecialEventGroupDetailsConfig[id]
end

function XFubenRogueLikeConfig.GetSpecialEventGroupItemConfigById(id)
    if not SpecialEventGroupItemConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetSpecialEventGroupItemConfigById",
        "RogueLikeSpecialEventGroupItem", CLIENT_ROGUELIKE_SPECIALEVENTGROUPITEM, "Id", tostring(id))
        return
    end
    return SpecialEventGroupItemConfig[id]
end

-- 特殊事件组条件
function XFubenRogueLikeConfig.IsSpecialGroupType(specialEventType)
    return specialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ReduceHp or
    specialEventType == XFubenRogueLikeConfig.XRLOtherEventType.GainItemRate or
    specialEventType == XFubenRogueLikeConfig.XRLOtherEventType.ConsumeItemRate
end

-- 选择不需要发通知的类型
function XFubenRogueLikeConfig.IsRequestBeforeSelectType(normalType)
    return normalType == XFubenRogueLikeConfig.XRLNodeType.Fight or
    normalType == XFubenRogueLikeConfig.XRLNodeType.Box
end

function XFubenRogueLikeConfig.NoNeedCheckActionPointType(normalType)
    return false -- normalType == XFubenRogueLikeConfig.XRLNodeType.Rest
end


function XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreDescConfigByType(nodeType)
    if not RogueLikePurgatoryScoreDesConfig[nodeType] then
        XLog.ErrorTableDataNotFound("XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreDescConfigByType",
        "RogueLikePurgatoryScoreDesConfig", CLIENT_ROGUELIKE_SCORE_DETAIL, "Type", tostring(nodeType))
        return
    end
    return RogueLikePurgatoryScoreDesConfig[nodeType]
end

function XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreTitleByType(nodeType)
    local conifg = XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreDescConfigByType(nodeType)
    return conifg and conifg.Title
end

function XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreDescriptionByType(nodeType)
    local conifg = XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreDescConfigByType(nodeType)
    return conifg and conifg.Description
end