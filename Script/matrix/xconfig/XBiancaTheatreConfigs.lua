XBiancaTheatreConfigs = XBiancaTheatreConfigs or {}

-- 配置表
local SHARE_TABLE_PATH = "Share/BiancaTheatre/"
local CLIENT_TABLE_PATH = "Client/BiancaTheatre/"

--节点类型
XBiancaTheatreConfigs.NodeType = {
    None = 0,  
    Fight = 1,  -- 战斗
    Event = 2,  -- 事件
    Shop = 3, -- 商店
}

XBiancaTheatreConfigs.EventNodeType = {
    Talk = 1,   -- 对白
    Selectable = 2, -- 选项
    LocalReward = 3, -- 本局奖励
    GlobalReward = 4, -- 全局(永久)奖励
    Battle = 5, -- 战斗
    Movie = 6,  -- 剧情
    FightNoSkill = 7,   --战斗
}

--节点奖励类型
XBiancaTheatreConfigs.AdventureRewardType = {
    None = 0,   -- 无
    ItemBox = 1,    -- 选择道具
    Ticket = 2,    -- 招募
    Gold = 3,
}

XBiancaTheatreConfigs.SelectableEventItemType = {
    ConsumeItem = 1,    -- 消耗道具
    CheckHasItem = 2,   -- 检查拥有道具
    IconTrigger = 3,    -- 图标触发
    IconSkip = 4,       -- 图标跳过
}

XBiancaTheatreConfigs.SkillType = {
    Core = 1,   -- 核心技能
    Additional = 2,   -- 附属技能
}

XBiancaTheatreConfigs.SkillOperationType = {
    AddBuff = 1,    -- 增幅
    LevelUp = 2,    -- 升级
    Replace = 3,    -- 替换
}

XBiancaTheatreConfigs.OperationQueueType = {
    NodeReward = 1, -- 奖励
    ChapterSettle = 2,  -- 章节结算
    AdventureSettle = 3,    -- 冒险结算
    BattleSettle = 4,   -- 战斗结算
}

--图鉴页签枚举
XBiancaTheatreConfigs.FieldGuideIds = {
    CurSkill = 1, --当前增益
    AllSkill = 2, --增益图鉴
    Item = 3, --其他道具
}

--道具类型
XBiancaTheatreConfigs.ItemType = {
    Token = 1,  --信物
    ThisGameItem = 2,   --本局道具
    LastItem = 3,   --永久道具
}

--功能解锁弹窗显示的布局枚举
XBiancaTheatreConfigs.UplockTipsPanel = {
    Prerogative = 1,    --解锁功能
    NewTalent = 2,      --解锁新装修项
    OwnRole = 3,        --可使用自己角色
}

XBiancaTheatreConfigs.XCharacterType = {
    Normal = 1,     --普通角色
    Decay = 2,      --腐化角色
}

--节点类型
XBiancaTheatreConfigs.XNodeSlotType = {
    Fight = 1,
    Event = 2,
    Shop = 3,
}

--节点奖励类型
XBiancaTheatreConfigs.XNodeRewardType = {
    ItemBox = 1,
    Ticket = 2,
    Gold = 3,
}

--步骤类型
XBiancaTheatreConfigs.XStepType = {
    --额外奖励
    ExtraItemReward = 1,
    --具体道具奖励
    ItemReward = 2,
    --招募券选择
    SelectRecruitTicket = 3,
    --招募角色
    RecruitCharacter = 4,
    --节点
    Node = 5,
    --战斗奖励选择
    FightReward = 6,
    --招募腐化角色
    DecayRecruitCharacter = 7,
}

--商店售卖项类型
XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType = {
    --道具
    Item = 1,
    --招募券
    Ticket = 2,
}

--步骤对应的UI名
XBiancaTheatreConfigs.StepTypeToUiName = {
    [XBiancaTheatreConfigs.XStepType.ExtraItemReward] = "UiBiancaTheatreChoice",
    [XBiancaTheatreConfigs.XStepType.ItemReward] = "UiBiancaTheatreChoice",
    [XBiancaTheatreConfigs.XStepType.SelectRecruitTicket] = "UiBiancaTheatreChoice",
    [XBiancaTheatreConfigs.XStepType.RecruitCharacter] = "UiBiancaTheatreRecruit",
    [XBiancaTheatreConfigs.XStepType.Node] = {
        ["Default"] = "UiBiancaTheatrePlayMain",
        [XBiancaTheatreConfigs.XNodeSlotType.Event] = "UiBiancaTheatreOutpost",
        [XBiancaTheatreConfigs.XNodeSlotType.Shop] = "UiBiancaTheatreOutpost",
    },
    [XBiancaTheatreConfigs.XStepType.FightReward] = "UiBiancaTheatreChoice",
    [XBiancaTheatreConfigs.XStepType.DecayRecruitCharacter] = "UiBiancaTheatreRecruit",
}

--商店售卖项类型
XBiancaTheatreConfigs.XNodeShopItemType = {
    --道具
    Item = 1,
    --招募券
    Ticket = 2,
}

-- 奖励标签类型
XBiancaTheatreConfigs.NodeRewardTagType = {
    None = 0,       -- 无
    Difficulty = 1, -- 困难
    Luck = 2,       -- 幸运
    Team = 3,       -- 调查团
}

--事件步骤类型
XBiancaTheatreConfigs.XEventStepType = {
    Dialogue = 1,
    Options = 2,
    ChapterItem = 3,
    PermanentItem = 4,
    Fight = 5,
    StoryLine = 6,
    FightNoSkill = 7,
}

--事件物品类型
XBiancaTheatreConfigs.XEventStepItemType = {
    --局外物品
    OutSideItem = 1,
    --局内物品
    InnerItem = 2,
    --道具箱
    ItemBox = 3,
    --招募券
    Ticket = 4,
    --激活灵视
    OpenVision = 5,
    --腐化招募券
    DecayTicket = 6,
    --获得灵视，填BiancaTheatreVisionChange表ID
    ObtainVision = 7,
}

--事件选择类型
XBiancaTheatreConfigs.XEventStepOptionType = {
    CostItem = 1,
    CheckItem = 2,
}

--选择界面的布局类型
XBiancaTheatreConfigs.UiChoiceType = {
    Difficulty = 1, --选择难度
    TeamSelect = 2, --分队选择
    RecruitTicket = 3,   --招募券选择选择奖励
    Reward = 4,     --奖励选择
    ExReward = 5,   --额外奖励选择
    FightReward = 6,    --战斗奖励选择
}

XBiancaTheatreConfigs.ComboBtnType = {
    BaseComboType = 1,
    ChildComboType = 2
}

-- 弹窗优先级(小而优先)
XBiancaTheatreConfigs.TipOrder = {
    UiBiancaTheatreTipReward = 1,       -- 奖励提示
    UiBiancaTheatreUnlockTips = 2,      -- 强化解锁提示
    UiBiancaTheatreLvTips = 3,          -- 等级提升提示
    UiBiancaTheatreItemUnlockTips = 4,  -- 秘藏品图鉴解锁提示
    UiBiancaTheatrePsionicVision = 5,   -- 灵视解锁提示
}

-- 经验
XBiancaTheatreConfigs.TheatreExp = 96117
-- 外循环强化材料
XBiancaTheatreConfigs.TheatreOutCoin = 96118
-- 局内商店货币
XBiancaTheatreConfigs.TheatreInnerCoin = 96119
-- 局内血清，局内购买复活
XBiancaTheatreConfigs.TheatreActionPoint = 96120

XBiancaTheatreConfigs.RewardDisplayType = {
    --普通
    Normal = 0,
    --稀有
    Rare   = 1
}

-- v2.1 利用特殊编辑的Cue文件调整声效滤镜
XBiancaTheatreConfigs.AudioFilterType = {
    None = 1,
    VisionLevel1 = 2,   -- 灵视阶段一的音效滤镜(前为开，后为关)
    VisionLevel2 = 3,   -- 灵视阶段二的音效滤镜
    VisionLevel3 = 4,   -- 灵视阶段三的音效滤镜
}

-- 灵视ItemId，灵视走的是道具系统
XBiancaTheatreConfigs.VisionItem = 96185
-- 部分调查团有额外数值加成文本
XBiancaTheatreConfigs.NeedExtraDescTeamId = {
    ExpeditionTeam = 5,     -- 远征队，加成随通过的战斗节点增加而增加
}

--"开始冒险"艺术字路径
XBiancaTheatreConfigs.TheatreTxtStartPath = CS.XGame.ClientConfig:GetString("BiancaTheatreTxtStartPath")
--"继续冒险"艺术字路径
XBiancaTheatreConfigs.TheatreTxtContinuePath = CS.XGame.ClientConfig:GetString("BiancaTheatreTxtContinuePath")

function XBiancaTheatreConfigs.Init()
    XConfigCenter.CreateGetProperties(XBiancaTheatreConfigs, {
        "BiancaTheatreChapter",
        "TheatreConfig",
        "TheatreDifficulty",
        "BiancaTheatreItem",
        "BiancaTheatreFightStageTemplate",
        "TheatreEvent",
        "TheatreClientConfig",
        "BiancaTheatreEnding",
        "TheatreCombo",
        "TheatreFieldGuide",
        "TheatreEventClientConfig",
        "TheatreComboTypeName",
        "BiancaTheatreTeam",
        "BiancaTheatreRecruitTicket",
        "BiancaTheatreStrengthen",
        "BiancaTheatreStrengthenGroup",
        "BiancaTheatreTeamType",
        "BiancaTheatreLevelReward",
        "BiancaTheatreTask",
        "BiancaTheatreAchievement",
        "BiancaTheatreItemGroup",
        "BiancaTheatreItemType",
        "BiancaTheatreCharacterLevel",
        "BiancaTheatreNodeShop",
        "BiancaTheatreItemBox",
        "BiancaTheatreGold",
        "BiancaTheatreBaseCharacter",
        "BiancaTheatreChildCombo",
        "BiancaTheatreShopNodeClient",
        "BiancaTheatreFightNodeClient",
        "BiancaTheatreNode",
        "BiancaTheatreCharacterElements",
        "BiancaTheatreActivity",
        "BiancaTheatreVision",
        "BiancaTheatreVisionChange",
        "BiancaTheatreDecayRecruitTicket",
        "BiancaTheatreVisionTxtShake",
    }, { 
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreChapter.tab", XTable.XTableBiancaTheatreChapter, "Id",
        "ReadByStringKey", SHARE_TABLE_PATH .. "BiancaTheatreConfig.tab", XTable.XTableBiancaTheatreConfig, "Key",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreDifficulty.tab", XTable.XTableBiancaTheatreDifficulty, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreItem.tab", XTable.XTableBiancaTheatreItem, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreFightStageTemplate.tab", XTable.XTableBiancaTheatreFightStageTemplate, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreEvent.tab", XTable.XTableBiancaTheatreEvent, "Id",
        "ReadByStringKey", CLIENT_TABLE_PATH .. "BiancaTheatreClientConfig.tab", XTable.XTableBiancaTheatreClientConfig, "Key",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreEnding.tab", XTable.XTableBiancaTheatreEnding, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreCombo.tab", XTable.XTableBiancaTheatreCombo, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreFieldGuide.tab", XTable.XTableBiancaTheatreFieldGuide, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreEventClientConfig.tab", XTable.XTableBiancaTheatreEventClientConfig, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreComboTypeName.tab", XTable.XTableBiancaTheatreComboTypeName, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreTeam.tab", XTable.XTableBiancaTheatreTeam, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreRecruitTicket.tab", XTable.XTableBiancaTheatreRecruitTicket, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreStrengthen.tab", XTable.XTableBiancaTheatreStrengthen, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreStrengthenGroup.tab", XTable.XTableBiancaTheatreStrengthenGroup, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreTeamType.tab", XTable.XTableBiancaTheatreTeamType, "Type",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreLevelReward.tab", XTable.XTableBiancaTheatreLevelReward, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreTask.tab", XTable.XTableBiancaTheatreTask, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreAchievement.tab", XTable.XTableBiancaTheatreAchievement, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreItemGroup.tab", XTable.XTableBiancaTheatreItemGroup, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreItemType.tab", XTable.XTableBiancaTheatreItemType, "Type",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreCharacterLevel.tab", XTable.XTableBiancaTheatreCharacterLevel, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreNodeShop.tab", XTable.XTableBiancaTheatreNodeShop, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreItemBox.tab", XTable.XTableBiancaTheatreItemBox, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreGold.tab", XTable.XTableBiancaTheatreGold, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreBaseCharacter.tab", XTable.XTableBiancaTheatreBaseCharacter, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreChildCombo.tab", XTable.XTableBiancaTheatreChildCombo, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreShopNodeClient.tab", XTable.XTableBiancaTheatreShopNodeClient, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreFightNodeClient.tab", XTable.XTableBiancaTheatreFightNodeClient, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreNode.tab", XTable.XTableBiancaTheatreNode, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreCharacterElements.tab", XTable.XTableBiancaTheatreCharacterElements, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreActivity.tab", XTable.XTableBiancaTheatreActivity, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreVision.tab", XTable.XTableBiancaTheatreVision, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreVisionChange.tab", XTable.XTableBiancaTheatreVisionChange, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "BiancaTheatreDecayRecruitTicket.tab", XTable.XTableBiancaTheatreDecayRecruitTicket, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "BiancaTheatreVisionTxtShake.tab", XTable.XTableBiancaTheatreVisionTxtShake, "Id",
    })
    XBiancaTheatreConfigs.InitVisionTxtShakeGroupDir()
end

function XBiancaTheatreConfigs.GetEventNodeConfig(eventId, stepId)
    for id, config in pairs(XBiancaTheatreConfigs.GetTheatreEvent()) do
        if config.EventId == eventId and config.StepId == stepId then
            return config
        end
    end
end

function XBiancaTheatreConfigs.GetInitLevel()
    return XBiancaTheatreConfigs.GetTheatreLv()[1].Lv
end

function XBiancaTheatreConfigs.GetLevel2Data(level)
    local configs = XBiancaTheatreConfigs.GetTheatreLv()
    local config
    for i = #configs, 1, -1 do
        config = configs[i]
        if level >= config.Lv then
            return config
        end
    end
    return configs[1]
end

function XBiancaTheatreConfigs.GetMaxLevel()
    local configs = XBiancaTheatreConfigs.GetTheatreLv()
    return configs[#configs].Lv
end

------------------BiancaTheatreClientConfigs 前端常量配置 begin----------------------
function XBiancaTheatreConfigs.GetNodeTypeName(nodeType)
    return XBiancaTheatreConfigs.GetTheatreClientConfig("NodeTypeName").Values[nodeType]
end

function XBiancaTheatreConfigs.GetNodeTypeIcon(nodeType)
    return XBiancaTheatreConfigs.GetTheatreClientConfig("NodeTypeIcon").Values[nodeType]
end

function XBiancaTheatreConfigs.GetNodeTypeDesc(nodeType)
    return XBiancaTheatreConfigs.GetTheatreClientConfig("NodeTypeDesc").Values[nodeType]
end

function XBiancaTheatreConfigs.GetNodeTypeEffectUrl(nodeType)
    return XBiancaTheatreConfigs.GetTheatreClientConfig("NodeTypeEffectUrl").Values[nodeType]
end

function XBiancaTheatreConfigs.GetClientConfig(key, valueIndex)
    if valueIndex == nil then valueIndex = 1 end
    return XBiancaTheatreConfigs.GetTheatreClientConfig(key).Values[valueIndex]
end

function XBiancaTheatreConfigs.GetRewardTypeIcon(rewardType)
    local result = XBiancaTheatreConfigs.GetTheatreClientConfig("SpecialRewardIcon").Values[rewardType]
    return result
end

function XBiancaTheatreConfigs.GetRewardTypeName(rewardType)
    local result = XBiancaTheatreConfigs.GetTheatreClientConfig("SpecialRewardName").Values[rewardType]
    return result
end

function XBiancaTheatreConfigs.GetShopIds()
    local shopIds = {}
    local shopIdByNormal = XBiancaTheatreConfigs.GetTheatreConfig("ShopIdByNormal").Value
    local shopIdBySpeical = XBiancaTheatreConfigs.GetTheatreConfig("ShopIdBySpecial").Value
    table.insert(shopIds, shopIdByNormal)
    table.insert(shopIds, shopIdBySpeical)
    return shopIds
end

function XBiancaTheatreConfigs.GetRoleDetailLevelIcon()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("RoleDetailLevelIcon").Values[1]
end

function XBiancaTheatreConfigs.GetRoleDetailLevelDesc()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("RoleDetailLevelDesc").Values
end

function XBiancaTheatreConfigs.GetRoleDetailEquipIcon()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("RoleDetailEquipIcon").Values[1]
end

function XBiancaTheatreConfigs.GetRoleDetailEquiupDesc()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("RoleDetailEquiupDesc").Values
end

function XBiancaTheatreConfigs.GetRoleDetailSkillIcon()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("RoleDetailSkillIcon").Values[1]
end

function XBiancaTheatreConfigs.GetRoleDetailSkillDesc()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("RoleDetailSkillDesc").Values
end

function XBiancaTheatreConfigs.GetUnlockOwnRole()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("UnlockOwnRole").Values
end

function XBiancaTheatreConfigs.GetUnlockFavor()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("UnlockFavor").Values
end

function XBiancaTheatreConfigs.GetUnlockDecoration()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("UnlockDecoration").Values
end

function XBiancaTheatreConfigs.GetUnlockNewDecoration()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("UnlockNewDecoration").Values
end

function XBiancaTheatreConfigs.GetSkillPosIcon(index)
    return XBiancaTheatreConfigs.GetTheatreClientConfig("SkillPosIcon").Values[index]
end

function XBiancaTheatreConfigs.GetFirstStoryId()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("FirstStoryId").Values[1]
end

function XBiancaTheatreConfigs.GetStrengthenCoinId()
    local strengthenCoinId = XBiancaTheatreConfigs.GetTheatreClientConfig("StrengthenCoinId").Values[1]
    return strengthenCoinId and tonumber(strengthenCoinId)
end

function XBiancaTheatreConfigs.GetLevelItemId()
    local levelItemId = XBiancaTheatreConfigs.GetTheatreClientConfig("LevelItemId").Values[1]
    return levelItemId and tonumber(levelItemId)
end

function XBiancaTheatreConfigs.GetStrengthenBtnActiveName(index)
    local name = XBiancaTheatreConfigs.GetTheatreClientConfig("StrengthenBtnActiveName").Values[index]
    return name and name or ""
end

function XBiancaTheatreConfigs.GetTextColor(index)
    local colorTxt = XBiancaTheatreConfigs.GetTheatreClientConfig("TextColor").Values[index]
    if colorTxt then
        return XUiHelper.Hexcolor2Color(colorTxt)
    end
    return CS.UnityEngine.Color.white
end

function XBiancaTheatreConfigs.GetRewardTips(index)
    local tips = XBiancaTheatreConfigs.GetTheatreClientConfig("RewardTips").Values[index]
    return tips and tips or ""
end

function XBiancaTheatreConfigs.GetBiancaTheatreComboTips(index)
    local tips = XBiancaTheatreConfigs.GetTheatreClientConfig("BiancaTheatreComboTips").Values[index]
    return tips and tips or ""
end

function XBiancaTheatreConfigs.GetBiancaTheatreStrengthenTips(index)
    local tips = XBiancaTheatreConfigs.GetTheatreClientConfig("StrengthenTips").Values[index]
    return tips and tips or ""
end

function XBiancaTheatreConfigs.GetQualityTextColor(index)
    local colorTxt = XBiancaTheatreConfigs.GetTheatreClientConfig("QualityTextColor").Values[index]
    if colorTxt then
        return XUiHelper.Hexcolor2Color(colorTxt)
    end
end

---灵视等级提升音效
---@param upToLevel number
---@return number
function XBiancaTheatreConfigs.GetVisionUpSoundCueId(upToLevel)
    local value = upToLevel and upToLevel - 1 or #XBiancaTheatreConfigs.GetTheatreClientConfig("VisionUpSound").Values
    local cueId = XBiancaTheatreConfigs.GetTheatreClientConfig("VisionUpSound").Values[value]
    return cueId and tonumber(cueId) or 0
end

-- 灵视等级提升文本
---@param upToLevel number
---@return string
function XBiancaTheatreConfigs.GetVisionUpDesc(upToLevel)
    local value = upToLevel and upToLevel - 1 or #XBiancaTheatreConfigs.GetTheatreClientConfig("VisionUpDesc").Values
    local desc = XBiancaTheatreConfigs.GetTheatreClientConfig("VisionUpDesc").Values[value]
    return desc and desc or ""
end

---外循环强化节点预制体url
---@return string
function XBiancaTheatreConfigs.GetStrengthenSkillNodePrefab()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("StrengthenSkillNodePrefab").Values[1]
end

---腐化特效url
---@return string
function XBiancaTheatreConfigs.GetDecayRoleEffect()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("DecayRoleEffect").Values[1]
end

---v2.1 获得奖励音效(1:领取秘藏箱 | 2:领取秘藏品 | 3:领取邀约)
---@param index number
---@return number
function XBiancaTheatreConfigs.GetCueWhenGetReward(index)
    local cueId = XBiancaTheatreConfigs.GetTheatreClientConfig("CueWhenGetReward").Values[index]
    return tonumber(cueId) or 0
end

---v2.1 灵视结算文本
---@param index any
---@return string
function XBiancaTheatreConfigs.GetVisionSettleDesc(index)
    local config = XBiancaTheatreConfigs.GetTheatreClientConfig("VisionSettleDesc")
    return config and config.Values[index] or ""
end

---v2.1 灵视ui特效预制体
---@param index number
---@return string
function XBiancaTheatreConfigs.GetVisionUiEffectUrl(index)
    local config = XBiancaTheatreConfigs.GetTheatreClientConfig("VisionUiEffectUrl")
    return config and config.Values[index] or ""
end

---v2.1 灵视增长特效预制体
---@param index any
---@return string
function XBiancaTheatreConfigs.GetVisionPsionicEffectUrl(index)
    local config = XBiancaTheatreConfigs.GetTheatreClientConfig("VisionPsionicEffectUrl")
    return config and config.Values[index] or ""
end

---v2.1 成就完成左上角小弹窗文本
---@return string
function XBiancaTheatreConfigs.GetAchievementFinishTipTxt()
    local config = XBiancaTheatreConfigs.GetTheatreClientConfig("AchievementFinishTipTxt")
    return config and config.Values[1] or ""
end

---v2.1 版本更新旧冒险数据自动结算提示文本
---@return string
function XBiancaTheatreConfigs.GetVersionUpdateOldPlaySettleTip()
    local config = XBiancaTheatreConfigs.GetTheatreClientConfig("VersionUpdateOldPlaySettleTip")
    return config and config.Values[1] or ""
end

------------------BiancaTheatreClientConfigs 前端常量配置 end----------------------

------------------BiancaTheatreFightStageTemplate 关卡 begin----------------------
function XBiancaTheatreConfigs.GetTheatreStageCount(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreFightStageTemplate(id)
    return config and config.StageCount or 0
end

function XBiancaTheatreConfigs.GetTheatreStageSuggestAbility(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreFightStageTemplate(id)
    return config and config.SuggestAbility or 0
end

function XBiancaTheatreConfigs.GetTheatreFightStageId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreFightStageTemplate(id, true)
    return config and config.StageId or 0
end
------------------BiancaTheatreFightStageTemplate 关卡 end----------------------

------------------BiancaTheatreTask 任务 begin--------------------
local IsInitTheatreTaskDic = false
local TheatreTaskIdList = {}
local TheatreTaskMainShowIdList = {} --参与主界面任务显示逻辑的Id列表
local TheatreTaskHaveStartTimeIdList = {} --有开启时间的任务Id列表（key：TheatreTaskId，Value：TaskIdList）
local InitTheatreTask = function()
    if IsInitTheatreTaskDic then
        return
    end

    local mainShowOrder
    local taskIdList
    local configs = XBiancaTheatreConfigs.GetBiancaTheatreTask()
    for id, config in pairs(configs) do
        taskIdList = config.TaskId

        if not TheatreTaskHaveStartTimeIdList[id] then
            TheatreTaskHaveStartTimeIdList[id] = {}
        end
        for _, taskId in ipairs(taskIdList) do
            if XTaskConfig.GetTaskStartTime(taskId) then
                table.insert(TheatreTaskHaveStartTimeIdList[id], taskId)
            end
        end

        mainShowOrder = config.MainShowOrder
        if XTool.IsNumberValid(mainShowOrder) then
            table.insert(TheatreTaskMainShowIdList, id)
        end

        table.insert(TheatreTaskIdList, id)
    end

    table.sort(TheatreTaskMainShowIdList, function(a, b)
        local orderA = XBiancaTheatreConfigs.GetTaskMainShowOrder(a)
        local orderB = XBiancaTheatreConfigs.GetTaskMainShowOrder(b)
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a < b
    end)

    IsInitTheatreTaskDic = true
end

function XBiancaTheatreConfigs.GetTheatreTaskIdList()
    InitTheatreTask()
    return TheatreTaskIdList
end

function XBiancaTheatreConfigs.GetTheatreTaskMainShowIdList()
    InitTheatreTask()
    return TheatreTaskMainShowIdList
end

function XBiancaTheatreConfigs.GetTaskHaveStartTimeIdList(id)
    InitTheatreTask()
    return TheatreTaskHaveStartTimeIdList[id] or {}
end

function XBiancaTheatreConfigs.GetTaskIdList(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTask(id)
    return config.TaskId
end

function XBiancaTheatreConfigs.GetTaskName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTask(id)
    return config.Name
end

function XBiancaTheatreConfigs.GetTaskMainShowOrder(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTask(id)
    return config.MainShowOrder
end
------------------BiancaTheatreTask 任务 end----------------------

------------------BiancaTheatreAchievement 任务 begin--------------------
function XBiancaTheatreConfigs.GetAchievementIdList()
    local idList = {}
    local configs = XBiancaTheatreConfigs.GetBiancaTheatreAchievement()
    for _, config in ipairs(configs) do
        table.insert(idList, config.Id)
    end
    return idList
end

function XBiancaTheatreConfigs.GetAchievementTaskIds(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreAchievement(id)
    return config.TaskIds
end

function XBiancaTheatreConfigs.GetAchievementTagName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreAchievement(id)
    return config.TagName
end
------------------BiancaTheatreAchievement 任务 end----------------------

------------------BiancaTheatreChapter 章节 begin--------------------
local GetDefaultChapterConfig = function()
    local configs = XBiancaTheatreConfigs.GetBiancaTheatreChapter()
    for _, config in pairs(configs) do
        return config
    end
end

function XBiancaTheatreConfigs.GetDefaultChapterId()
    return GetDefaultChapterConfig().Id
end

function XBiancaTheatreConfigs.GetCurChapterRecruitMaxCount(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id)
    return config.RecruitRefreshCount
end

function XBiancaTheatreConfigs.GetChapterSceneUrl(id)
    if not id then
        return GetDefaultChapterConfig().SceneUrl
    end
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id)
    return config.SceneUrl
end

function XBiancaTheatreConfigs.GetChapterBgA(id)
    if not id then
        return GetDefaultChapterConfig().BgA
    end
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id)
    return config.BgA
end

function XBiancaTheatreConfigs.GetChapterBgB(id)
    if not id then
        return GetDefaultChapterConfig().BgB
    end
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id)
    return config.BgB
end

function XBiancaTheatreConfigs.GetChapterModelUrl(id)
    if not id then
        return GetDefaultChapterConfig().ModelUrl
    end
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id)
    return config.ModelUrl
end

function XBiancaTheatreConfigs.GetChapterOtherBg(id)
    if not id then
        return GetDefaultChapterConfig().OtherBg
    end
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id)
    return config.OtherBg
end

function XBiancaTheatreConfigs.GetChapterBgmCueId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id, true)
    return config and config.BgmCueId
end

function XBiancaTheatreConfigs.GetChapterExtraRewardDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(id, true)
    return config and config.ExtraRewardDesc
end
------------------BiancaTheatreChapter 章节 end----------------------

------------------TheatreFieldGuide 图鉴表 begin---------------------
function XBiancaTheatreConfigs.GetTheatreFieldGuideIdList(showFieldGuideIds)
    local config = XBiancaTheatreConfigs.GetTheatreFieldGuide()
    local idList = {}
    if showFieldGuideIds then
        idList = XTool.Clone(showFieldGuideIds)
    else
        for id in ipairs(config) do
            table.insert(idList, id)
        end
    end

    table.sort(idList, function(a, b)
        local orderA = XBiancaTheatreConfigs.GetTheatreFieldGuide(a).Order
        local orderB = XBiancaTheatreConfigs.GetTheatreFieldGuide(b).Order
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a < b
    end)
    return idList
end

function XBiancaTheatreConfigs.GetTheatreFieldGuideName(id)
    local config = XBiancaTheatreConfigs.GetTheatreFieldGuide(id)
    return config.Name
end
------------------TheatreFieldGuide 图鉴表 end-----------------------

------------------BiancaTheatreItem 道具表 begin---------------------------
local IsInitTheatreItemDic = false
local TheatreItemIdList = {}
local InitTheatreItem = function()
    if IsInitTheatreItemDic then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreItem()
    for id, config in pairs(configs) do
        table.insert(TheatreItemIdList, id)
    end

    IsInitTheatreItemDic = true
end

function XBiancaTheatreConfigs.GetTheatreItemIdList()
    InitTheatreItem()
    return TheatreItemIdList
end

function XBiancaTheatreConfigs.GetTheatreItemType(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id)
    return config and config.Type
end

function XBiancaTheatreConfigs.GetItemUnlockConditionId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id)
    return config and config.UnlockConditionId
end

function XBiancaTheatreConfigs.GetTheatreItemQuality(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id)
    return config and config.Quality
end

function XBiancaTheatreConfigs.GetItemName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id)
    return config and config.Name
end

function XBiancaTheatreConfigs.GetItemDescription(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id)
    return config and config.Description or ""
end

function XBiancaTheatreConfigs.GetItemWorldDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id)
    return config and config.WorldDesc or ""
end

function XBiancaTheatreConfigs.GetItemIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItem(id, true)
    return config and config.Icon
end
------------------BiancaTheatreItem 道具表 end-----------------------------

------------------TheatreSkillPosDefine 技能位置表 begin-------------
function XBiancaTheatreConfigs.GetTheatreSkillPosDefineSkillType(id)
    local config = XBiancaTheatreConfigs.GetTheatreSkillPosDefine(id)
    return config and config.SkillType or {}
end
------------------TheatreSkillPosDefine 技能位置表 end---------------

------------------TheatreSkill 技能表 begin--------------------------
function XBiancaTheatreConfigs.GetTheatreSkillPowerId(id)
    local config = XBiancaTheatreConfigs.GetTheatreSkill(id)
    return config.PowerId
end

function XBiancaTheatreConfigs.GetTheatreSkillPos(id)
    local config = XBiancaTheatreConfigs.GetTheatreSkill(id)
    return config.Pos
end

function XBiancaTheatreConfigs.GetTheatreSkillLv(id)
    local config = XBiancaTheatreConfigs.GetTheatreSkill(id)
    return config.Lv
end
------------------TheatreSkill 技能表 end----------------------------

------------------TheatreComboTypeName 羁绊表 begin--------------------------
local Order2ComboTypeDic = {}
local BaseComboDic = {}
local StageToEStageDic = {}
local ComboConditionList = {
    [1] = "MemberNum", -- 检查合计数量
    [2] = "TotalRank",  -- 检查合计等级
    [3] = "TargetMember", -- 检查对应角色等级
    [4] = "TargetTypeAndRank", -- 检查指定特征的高于指定等级的人
}
local IsInitTheatreComboConfig = false
local InitComboConfig = function()
    if IsInitTheatreComboConfig then
        return
    end

    local comboConfig = XBiancaTheatreConfigs.GetTheatreCombo()
    for _, comboCfg in pairs(comboConfig) do
        if not BaseComboDic[comboCfg.ChildComboId] then
            BaseComboDic[comboCfg.ChildComboId] = {}
        end
        table.insert(BaseComboDic[comboCfg.ChildComboId], comboCfg)
    end

    local comboTypeNameConfig = XBiancaTheatreConfigs.GetTheatreComboTypeName()
    for _, comboTypeCfg in pairs(comboTypeNameConfig) do
        Order2ComboTypeDic[comboTypeCfg.OrderId] = comboTypeCfg
    end

    IsInitTheatreComboConfig = true
end

--================
--根据子羁绊类型Id获取具体羁绊列表
--================
function XBiancaTheatreConfigs.GetComboByChildComboId(childComboId)
    InitComboConfig()
    return BaseComboDic[childComboId]
end

function XBiancaTheatreConfigs.GetChildComboById(id)
    InitComboConfig()
    return TheatreChildCombo[id]
end

function XBiancaTheatreConfigs.GetBaseComboTypeConfig()
    return XBiancaTheatreConfigs.GetTheatreComboTypeName()
end

function XBiancaTheatreConfigs.GetBaseComboTypeCfgByOrderId(orderId)
    InitComboConfig()
    return Order2ComboTypeDic[orderId]
end

function XBiancaTheatreConfigs.GetBaseComboTypeNameById(id)
    local config = XBiancaTheatreConfigs.GetBaseComboTypeConfig(id)
    return config.Name or ""
end

function XBiancaTheatreConfigs.GetBuyDrawMaxTime()
    local config = XBiancaTheatreConfigs.GetTheatreDrawConsume()
    return #config
end

function XBiancaTheatreConfigs.GetDrawPriceByCount(count)
    local config = XBiancaTheatreConfigs.GetBuyDrawMaxTime(count)
    return config and config.ConsumeCount or 0
end

function XBiancaTheatreConfigs.GetGlobalConfigById(comboId)
    return XBiancaTheatreConfigs.GetTheatreGlobalComboConfig(comboId)
end

function XBiancaTheatreConfigs.GetRankByRankWeightId(index)
    local config = XBiancaTheatreConfigs.GetTheatreDrawRank(index)
    return config and config.Rank or 1
end
--================
--获取招募概率配置表
--================
function XBiancaTheatreConfigs.GetDrawPRConfig()
    return XBiancaTheatreConfigs.GetTheatreDrawPR()
end
--================
--获取招募星数对照表配置
--================
function XBiancaTheatreConfigs.GetDrawRankConfig()
    return XBiancaTheatreConfigs.GetTheatreDrawRank()
end
------------------TheatreComboTypeName 羁绊表 end--------------------------

------------------BiancaTheatreTeam 分队表 begin--------------------------
local TeamIdList = {}
local IsInitBiancaTheatreConfig = false
local InitBiancaTheatreConfig = function()
    if IsInitBiancaTheatreConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreTeam()
    for id in pairs(configs) do
        table.insert(TeamIdList, id)
    end

    IsInitBiancaTheatreConfig = true
end

function XBiancaTheatreConfigs.GetTeamIdList()
    InitBiancaTheatreConfig()
    return TeamIdList
end

function XBiancaTheatreConfigs.GetTeamName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeam(id)
    return config.Name
end

function XBiancaTheatreConfigs.GetTeamDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeam(id)
    return config.Desc
end

function XBiancaTheatreConfigs.GetTeamIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeam(id)
    return config.Icon
end

function XBiancaTheatreConfigs.GetTeamConditionId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeam(id)
    return config.ConditionId
end

function XBiancaTheatreConfigs.GetTeamType(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeam(id, true)
    return config.Type
end

function XBiancaTheatreConfigs.GetTeamTimeId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeam(id, true)
    return config.TimeId
end
------------------BiancaTheatreTeam 分队表 end--------------------------

------------------BiancaTheatreTeamType 分队类型表 start--------------------------
function XBiancaTheatreConfigs.GetTeamTypeName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeamType(id)
    return config and config.Name
end

function XBiancaTheatreConfigs.GetTeamTypeColor(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreTeamType(id)
    return config and config.Color
end
------------------BiancaTheatreTeamType 分队类型表 end--------------------------

------------------BiancaTheatreEnding 结局表 begin------------------
local EndingIdList = {}
local IsInitBiancaTheatreEndingConfig = false
local InitBiancaTheatreEndingConfig = function()
    if IsInitBiancaTheatreEndingConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreEnding()
    for id, v in pairs(configs) do
        --PassType为1时是失败结局，前端没任何用处不加入到结局Id列表中
        if v.PassType ~= 1 then
            table.insert(EndingIdList, id)
        end
    end

    IsInitBiancaTheatreEndingConfig = true
end

function XBiancaTheatreConfigs.GetEndingIdList()
    InitBiancaTheatreEndingConfig()
    return EndingIdList
end

function XBiancaTheatreConfigs.GetEndingRecordIndex(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreEnding(id)
    return config.RecordIndex
end
------------------BiancaTheatreEnding 结局表 end------------------

------------------BiancaTheatreRecruitTicket 招募券表 begin------------------
function XBiancaTheatreConfigs.GetRecruitTicketQuality(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreRecruitTicket(id)
    return config.Quality
end

--是否显示招募券特殊标记
function XBiancaTheatreConfigs.IsShowRecruitTicketSpecialTag(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreRecruitTicket(id)
    return XTool.IsNumberValid(config.IsSpecial)
end

function XBiancaTheatreConfigs.GetRecruitTicketLeastRecruitCount(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreRecruitTicket(id)
    return config and config.LeastRecruitCount or 0
end

function XBiancaTheatreConfigs.GetRecruitTicketName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreRecruitTicket(id)
    return config and config.Name or ""
end

function XBiancaTheatreConfigs.GetRecruitTicketDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreRecruitTicket(id)
    return config.Desc
end

function XBiancaTheatreConfigs.GetRecruitTicketIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreRecruitTicket(id)
    return config.Icon
end
------------------BiancaTheatreRecruitTicket 招募券表 end------------------

------------------BiancaTheatreStrengthen 外循环强化系统表 begin------------------
local StrengthenGroupIdToIdList = {}    --强化组Id集合，key：GroupId；value：BiancaTheatreStrengthen表的Id
local IsInitBiancaStrengthenConfig = false
local InitBiancaStrengthenConfig = function()
    if IsInitBiancaStrengthenConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen()
    local groupId
    for id, config in pairs(configs) do
        groupId = config.GroupId
        if not StrengthenGroupIdToIdList[groupId] then
            StrengthenGroupIdToIdList[groupId] = {}
        end
        table.insert(StrengthenGroupIdToIdList[groupId], id)
    end

    IsInitBiancaStrengthenConfig = true
end

function XBiancaTheatreConfigs.GetStrengthenIdList(groupId)
    InitBiancaStrengthenConfig()
    return StrengthenGroupIdToIdList[groupId] or {}
end

function XBiancaTheatreConfigs.GetStrengthenName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.Name
end

function XBiancaTheatreConfigs.GetStrengthenDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.Desc
end

function XBiancaTheatreConfigs.GetStrengthenIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.Icon
end

function XBiancaTheatreConfigs.GetStrengthenActiveLinesIndex(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.ActiveLinesIndex
end

function XBiancaTheatreConfigs.GetStrengthenUnlockPrice(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.UnlockPrice
end

function XBiancaTheatreConfigs.GetStrengthenPreStrengthenIds(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.PreStrengthenIds
end

function XBiancaTheatreConfigs.GetStrengthenGroupId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthen(id)
    return config.GroupId
end
------------------BiancaTheatreStrengthen 外循环强化系统表 end------------------

------------------BiancaTheatreStrengthenGroup 外循环强化组 begin------------------
local StrengthenGroupIdList = {}        --强化组Id列表
local IsInitBiancaTheatreStrengthenGroupConfig = false
local InitBiancaTheatreStrengthenGroupConfig = function()
    if IsInitBiancaTheatreStrengthenGroupConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreStrengthenGroup()
    for id, config in pairs(configs) do
        table.insert(StrengthenGroupIdList, id)
    end

    IsInitBiancaTheatreStrengthenGroupConfig = true
end

function XBiancaTheatreConfigs.GetStrengthenGroupIdList()
    InitBiancaTheatreStrengthenGroupConfig()
    return StrengthenGroupIdList
end

function XBiancaTheatreConfigs.GetStrengthenGroupTitleAsset(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthenGroup(id, true)
    return config.TitleAsset
end

function XBiancaTheatreConfigs.GetStrengthenGroupLevelAsset(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthenGroup(id, true)
    return config.LevelAsset
end

function XBiancaTheatreConfigs.GetStrengthenGroupName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthenGroup(id, true)
    return config.Name
end

function XBiancaTheatreConfigs.GetStrengthenGroupPreStrengthenGroupId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreStrengthenGroup(id, true)
    return config.PreStrengthenGroupId
end
------------------BiancaTheatreStrengthenGroup 外循环强化组 end------------------

------------------BiancaTheatreItemType 肉鸽道具类型组 begin------------------
local TheatreItemTypeIdList = {} --肉鸽道具类型组Id列表
local TheatreItemTypeIdToItemIdList = {}   --Key：TypeId；value：ItemIdList
local IsInitBiancaItemConfig = false
local InitBiancaItemConfig = function()
    if IsInitBiancaItemConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreItem()
    for id, config in pairs(configs) do
        if not TheatreItemTypeIdToItemIdList[config.Type] then
            TheatreItemTypeIdToItemIdList[config.Type] = {}
        end
        table.insert(TheatreItemTypeIdToItemIdList[config.Type], id)
    end
    
    configs = XBiancaTheatreConfigs.GetBiancaTheatreItemType()
    for typeId in pairs(configs) do
        table.insert(TheatreItemTypeIdList, typeId)
    end

    IsInitBiancaItemConfig = true
end

function XBiancaTheatreConfigs.GetItemTypeIdList()
    InitBiancaItemConfig()
    return TheatreItemTypeIdList
end

function XBiancaTheatreConfigs.GetItemIdListByTypeId(typeId)
    InitBiancaItemConfig()
    return TheatreItemTypeIdToItemIdList[typeId] or {}
end

function XBiancaTheatreConfigs.GetItemTypeName(typeId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItemType(typeId, true)
    return config.Name
end
------------------BiancaTheatreItemType 肉鸽道具类型组 end--------------------

------------------BiancaTheatreLevelReward 奖励表 begin------------------
local LevelRewardIdList = {} --奖励Id列表
local MaxRewardLevel = 0    --奖励最高等级
local IsInitBiancaLevelRewardConfig = false
local InitBiancaLevelRewardConfig = function()
    if IsInitBiancaLevelRewardConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward()
    for id in pairs(configs) do
        table.insert(LevelRewardIdList, id)
        if id > MaxRewardLevel then
            MaxRewardLevel = id
        end
    end

    IsInitBiancaLevelRewardConfig = true
end

function XBiancaTheatreConfigs.GetMaxRewardLevel()
    InitBiancaLevelRewardConfig()
    return MaxRewardLevel
end

function XBiancaTheatreConfigs.GetLevelRewardIdList()
    InitBiancaLevelRewardConfig()
    return LevelRewardIdList
end

function XBiancaTheatreConfigs.GetLevelRewardUnlockScore(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward(id, false)
    return config and config.UnlockScore or 0 
end

function XBiancaTheatreConfigs.GetLevelRewardId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward(id, true)
    return config.RewardId
end

function XBiancaTheatreConfigs.GetLevelRewardDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward(id, true)
    return config.Desc
end

function XBiancaTheatreConfigs.GetLevelRewardDisplayType(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreLevelReward(id, true)
    return config.DisplayType or 0
end
------------------BiancaTheatreLevelReward 奖励表 end------------------

------------------BiancaTheatreCharacterLevel 角色表 end------------------
local CharacterIdDic = {} --Key1：CharacterId    key2：Level  Value：Id
local RobotIdToCharacterId = {} --Key：RobotId   Value：CharacterId
local CharacterIdToMaxLevelDic = {}    --角色最高等级字典
local IsInitBiancaTheatreCharacterLevelConfig = false
local InitBiancaTheatreCharacterLevelConfig = function()
    if IsInitBiancaTheatreCharacterLevelConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreCharacterLevel()
    local characterId, level
    for id, config in pairs(configs) do
        characterId = config.CharacterId
        level = config.Level
        if not CharacterIdDic[characterId] then
            CharacterIdDic[characterId] = {}
        end
        CharacterIdDic[characterId][level] = id
        RobotIdToCharacterId[config.RobotId] = characterId

        if not CharacterIdToMaxLevelDic[characterId] or level > CharacterIdToMaxLevelDic[characterId] then
            CharacterIdToMaxLevelDic[characterId] = level
        end
    end

    IsInitBiancaTheatreCharacterLevelConfig = true
end

function XBiancaTheatreConfigs.GetCharacterIdByRobotId(robotId)
    InitBiancaTheatreCharacterLevelConfig()
    return RobotIdToCharacterId[robotId]
end

--获得角色最高星级
function XBiancaTheatreConfigs.GetCharacterMaxLevel(characterId)
    InitBiancaTheatreCharacterLevelConfig()
    return CharacterIdToMaxLevelDic[characterId] or 0
end

--获得角色表的Id
--characterId：角色Id  level：角色星级
function XBiancaTheatreConfigs.GetTheatreCharacterId(characterId, level)
    InitBiancaTheatreCharacterLevelConfig()
    if not CharacterIdDic[characterId] then
        XLog.Error("BiancaTheatreCharacterLevel表找不到数据，CharacterId：", characterId)
        return
    end
    return CharacterIdDic[characterId][level]
end

function XBiancaTheatreConfigs.GetCharacterLevel(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreCharacterLevel(id)
    return config.Level
end

function XBiancaTheatreConfigs.GetCharacterRobotId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreCharacterLevel(id)
    return config.RobotId
end

function XBiancaTheatreConfigs.GetCharacterFightAbility(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreCharacterLevel(id)
    return config.FightAbility
end
------------------BiancaTheatreCharacterLevel 角色表 end------------------

------------------BiancaTheatreItemBox 道具箱 begin-----------------------
function XBiancaTheatreConfigs.GetItemBoxName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItemBox(id)
    return config.Name
end

function XBiancaTheatreConfigs.GetItemBoxDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItemBox(id)
    return config.Desc
end

function XBiancaTheatreConfigs.GetItemBoxIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreItemBox(id)
    return config.Icon
end
------------------BiancaTheatreItemBox 道具箱 end-------------------------

------------------BiancaTheatreGold 金币表 begin-----------------------
function XBiancaTheatreConfigs.GetGoldName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreGold(id)
    return config.Name
end

function XBiancaTheatreConfigs.GetGoldDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreGold(id)
    return config.Desc
end

function XBiancaTheatreConfigs.GetGoldIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreGold(id)
    return config.Icon
end
------------------BiancaTheatreGold 金币表 end-------------------------

------------------BiancaTheatreBaseCharacter 基础角色表 begin-----------------------
local CharacterIdToBaseCharacterId = {} --key：CharacterId   value：BiancaTheatreBaseCharacter表的Id
local IsInitBiancaTheatrBaseCharacterConfig = false
local InitBiancaTheatreBaseCharacterConfig = function()
    if IsInitBiancaTheatrBaseCharacterConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreBaseCharacter()
    for id, config in pairs(configs) do
        CharacterIdToBaseCharacterId[config.CharacterId] = id
    end

    IsInitBiancaTheatrBaseCharacterConfig = true
end

function XBiancaTheatreConfigs.GetBaseCharacterId(characterId)
    InitBiancaTheatreBaseCharacterConfig()
    return CharacterIdToBaseCharacterId[characterId]
end

function XBiancaTheatreConfigs.GetBaseCharacterReferenceComboId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreBaseCharacter(id, true)
    return config and config.ReferenceComboId or {}
end
------------------BiancaTheatreBaseCharacter 基础角色表 end-------------------------

------------------BiancaTheatreNode 节点表 begin------------------------
local IsInitBiancaTheatreNodeConfig = false
local ChapterIdToNodeTotalCount = {}    --key：chapterId， value：节点总数
local InitBiancaTheatreNodeConfig = function()
    if IsInitBiancaTheatreNodeConfig then
        return
    end

    local configs = XBiancaTheatreConfigs.GetBiancaTheatreNode()
    local chapterNodeCount
    for id, config in pairs(configs) do
        chapterNodeCount = ChapterIdToNodeTotalCount[config.ChapterId] or 0
        ChapterIdToNodeTotalCount[config.ChapterId] = chapterNodeCount + 1
    end

    IsInitBiancaTheatreNodeConfig = true
end

--获得章节节点总数
function XBiancaTheatreConfigs.GetChapterNodeTotalCount(chapterId)
    InitBiancaTheatreNodeConfig()
    return ChapterIdToNodeTotalCount[chapterId]
end
------------------BiancaTheatreNode 节点表 end--------------------------

------------------EventStepItemTypeConfig 事件物品类型相关配置 begin------------------------
function XBiancaTheatreConfigs.GetEventStepItemName(itemId, itemType)
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.OutSideItem then
        local goodsShowParams =  XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        return goodsShowParams.RewardType == XArrangeConfigs.Types.Character and goodsShowParams.TradeName or goodsShowParams.Name
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.ItemBox then
        return XBiancaTheatreConfigs.GetItemBoxName(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketName(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.DecayTicket then
        return XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketName(itemId)
    else
        return XBiancaTheatreConfigs.GetItemName(itemId)
    end
end

function XBiancaTheatreConfigs.GetEventStepItemIcon(itemId, itemType)
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.OutSideItem then
        local goodsShowParams =  XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        return goodsShowParams.Icon
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.ItemBox then
        return XBiancaTheatreConfigs.GetItemBoxIcon(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketIcon(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.DecayTicket then
        return XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketIcon(itemId)
    else
        return XBiancaTheatreConfigs.GetItemIcon(itemId)
    end
end

function XBiancaTheatreConfigs.GetEventStepItemQualityIcon(itemId, itemType)
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.OutSideItem then
        local goodsShowParams =  XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
        return goodsShowParams.QualityIcon
    else
        local quality = XBiancaTheatreConfigs.GetEventStepItemQuality(itemId, itemType)
        return quality and XArrangeConfigs.GeQualityPath(quality)
    end
end

function XBiancaTheatreConfigs.GetEventStepItemQuality(itemId, itemType)
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketQuality(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.DecayTicket then
        return XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketQuality(itemId)
    elseif itemType ~= XBiancaTheatreConfigs.XEventStepItemType.ItemBox then
        return XBiancaTheatreConfigs.GetTheatreItemQuality(itemId)
    end
end

function XBiancaTheatreConfigs.GetEventStepItemDesc(itemId, itemType)
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.OutSideItem then
        return XGoodsCommonManager.GetGoodsDescription(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.ItemBox then
        return XBiancaTheatreConfigs.GetItemBoxDesc(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketDesc(itemId)
    elseif itemType == XBiancaTheatreConfigs.XEventStepItemType.DecayTicket then
        return XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketDesc(itemId)
    else
        return XBiancaTheatreConfigs.GetItemDescription(itemId)
    end
end

function XBiancaTheatreConfigs.GetEventStepItemWorldDesc(itemId, itemType)
    if itemType == XBiancaTheatreConfigs.XEventStepItemType.OutSideItem then
        return XGoodsCommonManager.GetGoodsWorldDesc(itemId)
    else
        return XBiancaTheatreConfigs.GetItemWorldDesc(itemId)
    end
end
------------------EventStepItemTypeConfig 事件物品类型相关配置 end--------------------------

------------------BiancaTheatreCharacterElements 角色元素配置 begin-----------------------
function XBiancaTheatreConfigs.GetCharacterElementsIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreCharacterElements(id)
    return config.Icon
end
------------------BiancaTheatreCharacterElements 角色元素配置 end-------------------------

------------------BiancaTheatreVision 灵视配置 begin-----------------------
function XBiancaTheatreConfigs.GetVisionName(visionId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVision(visionId, true)
    return config.Name
end

function XBiancaTheatreConfigs.GetVisionIcon(visionId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVision(visionId, true)
    return config.Icon
end

function XBiancaTheatreConfigs.GetVisionSoundFilterOpenCueId(visionId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVision(visionId, true)
    return config.SoundFilterOpenCueId
end

function XBiancaTheatreConfigs.GetVisionSoundFilterCloseCueId(visionId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVision(visionId, true)
    return config.SoundFilterCloseCueId
end

function XBiancaTheatreConfigs.GetVisionDescShakeGroupId(visionId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVision(visionId, true)
    return config.DescShakeGroupId
end

function XBiancaTheatreConfigs.GetVisionRecordDescShakeGroupId(visionId)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVision(visionId, true)
    return config.RecordDescShakeGroupId
end

-- 阶段标志(I、II、III)
function XBiancaTheatreConfigs.GetVisionSign(visionId)
    
end

function XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    local configs = XBiancaTheatreConfigs.GetBiancaTheatreVision()
    local resultIndex = 0
    for index, config in ipairs(configs) do
        if visionValue >= config.Min and visionValue <= config.Max then
            resultIndex = index
            break
        end
    end
    if resultIndex > 0 then
        return configs[resultIndex].Id
    end
end
------------------BiancaTheatreVision 灵视配置 end-------------------------

------------------BiancaTheatreVisionChange 灵视变化配置 begin-----------------------
function XBiancaTheatreConfigs.GetVisionChangeChange(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVisionChange(id)
    return config.Change
end

function XBiancaTheatreConfigs.GetVisionChangeGetSoundCueId(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVisionChange(id)
    return config.GetSoundCueId
end

function XBiancaTheatreConfigs.GetVisionChangeShowDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreVisionChange(id)
    return XUiHelper.ReplaceTextNewLine(config.ShowDesc)
end
------------------BiancaTheatreVisionChange 灵视变化配置 end-------------------------

------------------BiancaTheatreDecayRecruitTicket 腐化招募表配置 begin-----------------------
function XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketName(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicket(id)
    return config.Name
end

function XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketDesc(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicket(id)
    return config.Desc
end

function XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketIcon(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicket(id)
    return config.Icon
end

function XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicketQuality(id)
    local config = XBiancaTheatreConfigs.GetBiancaTheatreDecayRecruitTicket(id)
    return config.Quality
end
------------------BiancaTheatreDecayRecruitTicket 腐化招募表配置 end-------------------------

------------------BiancaTheatreVisionTxtShake 灵视文本抖动配置 begin-----------------------
local VisionTxtShakeGroupDir = {}
function XBiancaTheatreConfigs.InitVisionTxtShakeGroupDir()
    local configs = XBiancaTheatreConfigs.GetBiancaTheatreVisionTxtShake()
    for _, config in ipairs(configs) do
        local groupId = config.TxtGroup
        local chapterId = config.ChapterId
        if XTool.IsTableEmpty(VisionTxtShakeGroupDir[groupId]) then
            VisionTxtShakeGroupDir[groupId] = {}
        end
        if chapterId then -- 版本兼容避免分支卡死
            if XTool.IsTableEmpty(VisionTxtShakeGroupDir[groupId][chapterId]) then
                VisionTxtShakeGroupDir[groupId][chapterId] = {}
            end
            table.insert(VisionTxtShakeGroupDir[groupId][chapterId], config)
        else
            table.insert(VisionTxtShakeGroupDir[groupId], config)
        end
    end
end

function XBiancaTheatreConfigs.GetVisionShakeIdListByGroupId(txtGroupId, chapterId)
    return VisionTxtShakeGroupDir[txtGroupId][chapterId]
end
------------------BiancaTheatreVisionTxtShake 灵视文本抖动配置 end-------------------------