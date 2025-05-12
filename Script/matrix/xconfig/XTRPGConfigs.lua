local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs
local stringGsub = string.gsub
local CSXTextManagerGetText = CS.XTextManager.GetText

local TABLE_ROLE_PATH = "Share/TRPG/TRPGRole.tab"
local TABLE_ROLE_TALENT_GROUP_PATH = "Share/TRPG/RoleTalentGroup/"
local TABLE_ROLE_TALENT_GROUP_CLIENT_PATH = "Client/TRPG/TRPGTalentGroup.tab"
local TABLE_ROLE_TALENT_PATH = "Share/TRPG/TRPGRoleTalent.tab"
local TABLE_ROLE_ATTRIBUTE_PATH = "Client/TRPG/TRPGRoleAttribute.tab"
local TABLE_MAIN_AREA_PATH = "Share/TRPG/TRPGMainArea.tab"     --主区域
local TABLE_TARGET_LINK_PATH = "Share/TRPG/TRPGTargetLink.tab"      --目标链表
local TABLE_TARGET_PATH = "Share/TRPG/TRPGTarget.tab"               --目标表
local TABLE_MAZE_PATH = "Share/TRPG/TRPGMaze.tab"
local TABLE_MAZE_LAYER_PATH = "Share/TRPG/TRPGMazeLayer.tab"
local TABLE_MAZE_MAP_PATH = "Share/TRPG/MazeMap/"
local TABLE_MAZE_CARD_PATH = "Share/TRPG/TRPGMazeCard.tab"
local TABLE_MAZE_CARD_TYPE_PATH = "Client/TRPG/TRPGMazeCardType.tab"
local TABLE_MAZE_CARD_RECORD_GROUP_PATH = "Client/TRPG/TRPGMazeCardRecordGroup.tab"
local TABLE_LEVEL_PATH = "Share/TRPG/TRPGLevel.tab"
local TABLE_BUFF_PATH = "Share/TRPG/TRPGBuff.tab"
local TABLE_REWARD_PATH = "Share/TRPG/TRPGReward.tab"
local TABLE_SECOND_AREA_PATH = "Share/TRPG/TRPGSecondArea.tab"
local TABLE_THIRD_AREA_PATH = "Share/TRPG/TRPGThirdArea.tab"
local TABLE_SHOP_PATH = "Share/TRPG/TRPGShop.tab"
local TABLE_SHOP_ITEM_PATH = "Share/TRPG/TRPGShopItem.tab"
local TABLE_ITEM_PATH = "Share/TRPG/TRPGItem.tab"
local TABLE_TRUTH_ROAD_GROUP_PATH = "Share/TRPG/TruthRoad/TRPGTruthRoadGroup.tab"
local TABLE_TRUTH_ROAD_PATH = "Share/TRPG/TruthRoad/TRPGTruthRoad.tab"
local TABLE_BOSS_PATH = "Share/TRPG/Boss/TRPGBoss.tab"
local TABLE_BOSS_PHASES_REWARD = "Share/TRPG/Boss/TRPGBossPhasesReward.tab"
local TABLE_MEMOIRE_STORY = "Share/TRPG/TRPGMemoirStory.tab"
local TABLE_PANEL_PLOT_TAB_PATH = "Client/TRPG/TRPGPanelPlotTab.tab"
local TABLE_FUNCTION_GROUP_PATH = "Share/TRPG/TRPGFunctionGroup.tab"
local TABLE_FUNCTION_PATH = "Share/TRPG/TRPGFunction.tab"
local TABLE_EXAMINE_PATH = "Share/TRPG/Examine/TRPGExamine.tab"
local TABLE_EXAMINE_ACTION_PATH = "Share/TRPG/Examine/TRPGExamineAction.tab"
local TABLE_EXAMINE_ACTION_TYPE_PATH = "Client/TRPG/TRPGExamineActionType.tab"
local TABLE_EXAMINE_ACTION_DIFFICULT_PATH = "Client/TRPG/TRPGExamineActionDifficult.tab"
local TABLE_EXAMINE_PUNISH_PATH = "Share/TRPG/Examine/TRPGExaminePunish.tab"
local TABLE_EXAMINE_PUNISH_TEXT_PATH = "Share/TRPG/Examine/TRPGExaminePunishText.tab"
local TABLE_BUTTON_CONDITION_PATH = "Client/TRPG/TRPGButtonCondition.tab"
local TABLE_SECOND_MAIN_PATH = "Share/TRPG/SecondMain/TRPGSecondMain.tab"
local TABLE_SECOND_MAIN_STAGE_PATH = "Share/TRPG/SecondMain/TRPGSecondMainStage.tab"

local RoleTemplate = {}
local RoleTalentGroupTemplate = {}
local RoleTalentGroupClientTemplate = {}
local RoleTalentTemplate = {}
local RoleAttributeTemplate = {}
local MainAreaTemplate = {}
local SecondAreaTemplate = {}
local ThirdAreaTemplate = {}
local TargetLinkTemplate = {}
local TargetTemplate = {}
local RewardTemplate = {}
local MazeTemplate = {}
local MazeLayerTemplate = {}
local MazeMapTemplates = {}
local MazeCardTemplate = {}
local MazeCardTypeTemplate = {}
local MazeCardRecordGroupTemplate = {}
local LevelTemplate = {}
local BuffTemplate = {}
local ShopTemplate = {}
local ShopItemTemplate = {}
local ItemTemplate = {}
local TruthRoadGroupTemplate = {}
local TruthRoadTemplate = {}
local BossTemplate = {}
local BossPhasesRewardTemplate = {}
local MemoireStoryTemplate = {}
local PanelPlotTabTemplate = {}
local MovieIdToTargetIdDic = {}       --剧情Id索引目标Id字典
local TargetOfPreTargetList = {}       --所有目标的前置目标
local ShopItemCountList = {}            --商店道具限购列表
local FunctionGroupTemplate = {}
local FunctionTemplate = {}
local ExamineTemplate = {}
local ExamineActionTemplate = {}
local ExamineActionTypeTemplate = {}
local PunishTemplate = {}
local PunishTextTemplate = {}
local ExamineActionDifficultTemplate = {}
local SecondAreaIdToMazeIdDic = {}
local ButtonConditionTemplate = {}
local SecondMainTemplate = {}
local SecondMainIdList = {}
local SecondMainStageTemplate = {}

local TruthRoadGroupMaxNum = 0
local TargetTotalNum = 0
local DefaultMainLineTargetDesc = CSXTextManagerGetText("TRPGDefaultMainLineTargetDesc")
local DefaultTargetDesc = CSXTextManagerGetText("TRPGDefaultTargetDesc")
local DefaultTargetName = CSXTextManagerGetText("MainLineMission")
local NotPreTargetId = CS.XGame.ClientConfig:GetInt("TRPGNotPreTargetId")
local TaskPanelNewShowTime = CS.XGame.ClientConfig:GetFloat("TRPGTaskPanelNewShowTime")

XTRPGConfigs = XTRPGConfigs or {}

XTRPGConfigs.RoleAttributeType = {
    Power = 1, --力量
    Speed = 2, --敏捷
    Intelligence = 3, --智力
}

XTRPGConfigs.TRPGSecondAreaType = {
    Normal = 1, --普通区域
    Maze = 2, --迷宫
}

XTRPGConfigs.TRPGTargetType = {
    Story = 1, --剧情
    GainRole = 2, --获得探员
    FinishStage = 3, --关卡
    GainItem = 4, --获得道具
    CommitItem = 5, --交付道具
    Examine = 6, --检定事件
}

XTRPGConfigs.TRPGFunctionType = {
    Story = 1, --完成剧情
    Shop = 2, --打开商店
    CommitItem = 3, --提交物品
    FinishStage = 4, --完成关卡
    Examine = 5, --检定事件
}

XTRPGConfigs.TRPGBuffEffectType = {
    RoleTalent = 1, --天赋效果
    Positive = 2, --正面效果
    Negative = 3, --负面效果
}

XTRPGConfigs.TRPGBuffType = {
    Fight = 1, --战斗buff
    AttributeAdd = 2, --属性增加
    ExamineGainItem = 3, --检定获得物品
    ExamineAddWeight = 4, --检定增加权重
    SafeWeightAdd = 5, --安全权重增加
}

XTRPGConfigs.CardType = {
    Default = 0,
    Block = 1, --阻塞牌
    Pass = 2, --通行牌
    FightWin = 3, --战斗通关牌
    Story = 4, --剧情牌
    Examine = 5, --检定牌
    Reward = 6, --奖励牌
    Random = 7, --随机牌
    Skip = 8, --跳转牌
    Fight = 9, --战斗牌
    Over = 10, --结束牌
}

XTRPGConfigs.MissionType = {
    MainLine = 1, --主线
    SubLine = 2, --支线
}

XTRPGConfigs.ItemType = {
    Normal = 1, --普通物品
    Special = 2, --特殊物品
}

XTRPGConfigs.ItemEffect = {
    NoEffect = 0, --无使用效果
    ClearBuff = 1, --清除角色负面buff
    AddBuff = 2, --添加角色buff
    AddExamineAttribute = 3, --增加检定属性
}
XTRPGConfigs.ItemEffectDefaultItemId = -1--不选择物品的基础属性展示

XTRPGConfigs.MissionTypeName = {
    [XTRPGConfigs.MissionType.MainLine] = CSXTextManagerGetText("MainLineMission"),
    [XTRPGConfigs.MissionType.SubLine] = CSXTextManagerGetText("SubLineMission"),
}

XTRPGConfigs.DefaultDesc = {
    [XTRPGConfigs.MissionType.MainLine] = CSXTextManagerGetText("TRPGDefaultMainLineTargetDesc"),
    [XTRPGConfigs.MissionType.SubLine] = CSXTextManagerGetText("TRPGDefaultTargetDesc"),
}
XTRPGConfigs.NotTargetLinkDefaultId = 0    --目标链id不存在时的默认值

XTRPGConfigs.AreaStateType = {
    NotOpen = 1, --未解锁
    Open = 2, --已解锁
    Over = 3, --当前区域主线探索完毕 或 世界BOSS活动已结束
}

XTRPGConfigs.TRPGExamineActionType = {
    Strength = 1, --力量检定
    Agility = 2, --敏捷检定
    Intelligence = 3, --智力检定
    ConsumeItem = 4, --道具检定
}

XTRPGConfigs.TRPGExamineActionDifficult = {
    Default = 0, --无难度（使用道具）
    Easy = 1, --简单
    Strength = 1, --普通
    Hard = 2, --困难
    UnPass = 3, --不可通过
}

--检定状态
XTRPGConfigs.ExmaineStatus = {
    Dead = 0, --检定数据失效，等待下一轮检定开始
    Normal = 1, --正常检定流程
    Suc = 2, --检定成功
    Fail = 3, --检定失败
}

--惩罚类型
XTRPGConfigs.PunishType = {
    Fight = 1, --进入战斗
    DeBuff = 2, --添加负面buff
    LoseItem = 3, --丢失物品
    GoToOrigin = 4, --回到起点
}

--商店道具明日是否重置
XTRPGConfigs.ShopItemResetType = {
    NotReset = 0,
    Reset = 1,
}

XTRPGConfigs.ButtonConditionId = {
    Talent = 1, --天赋
    Collection = 2, --珍藏
}

local InitRoleTalentConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_ROLE_TALENT_GROUP_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        RoleTalentGroupTemplate[key] = XTableManager.ReadByIntKey(path, XTable.XTableTRPGRoleTalentGroup, "Id")
    end)
end

local InitTarget = function()
    TargetTemplate = XTableManager.ReadByIntKey(TABLE_TARGET_PATH, XTable.XTableTRPGTarget, "Id")
    for targetId, config in pairs(TargetTemplate) do
        if config.Type == XTRPGConfigs.TRPGTargetType.Story then
            local movieId = config.Params[1]
            MovieIdToTargetIdDic[movieId] = targetId
        end
    end
end

local InitTargetLink = function()
    TargetLinkTemplate = XTableManager.ReadByIntKey(TABLE_TARGET_LINK_PATH, XTable.XTableTRPGTargetLink, "Id")
    for _, v in pairs(TargetLinkTemplate) do
        for targetIndex, targetId in ipairs(v.TargetId) do
            if not TargetOfPreTargetList[targetId] then
                TargetOfPreTargetList[targetId] = v.PreTarget[targetIndex]
                TargetTotalNum = TargetTotalNum + 1
            elseif TargetOfPreTargetList[targetId] ~= v.PreTarget[targetIndex] then
                XLog.Error("XTRPGConfigs InitTargetLink error:配置存在相同的TargetId且PreTarget不同，Id：" .. v.Id .. " TargetId：" .. targetId .. " PreTarget：" .. v.PreTarget[targetIndex] .. "，配置路径：" .. TABLE_TARGET_LINK_PATH)
            end
        end
    end
end

local InitTruthRoadGroupMaxNum = function()
    for _, v in pairs(MainAreaTemplate) do
        if #v.TruthRoadGroupId > TruthRoadGroupMaxNum then
            TruthRoadGroupMaxNum = #v.TruthRoadGroupId
        end
    end
end

local InitMazeMapConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MAZE_MAP_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        MazeMapTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableTRPGMazeMap, "Id")
    end)
end

local InitShopItemCountList = function()
    for _, v in pairs(ShopTemplate) do
        ShopItemCountList[v.Id] = {}
        for i, shopItemId in ipairs(v.ShopItemId) do
            ShopItemCountList[v.Id][shopItemId] = v.ShopItemCount[i]
        end
    end
end

local InitMazeIdList = function()
    local areaType
    for _, v in pairs(SecondAreaTemplate) do
        areaType = XTRPGConfigs.GetSecondAreaType(v.Id)
        if areaType == XTRPGConfigs.TRPGSecondAreaType.Maze and v.MazeId > 0 then
            SecondAreaIdToMazeIdDic[v.Id] = v.MazeId
        end
    end
end

local InitSecondMainIdList = function()
    for _, v in pairs(SecondMainTemplate) do
        tableInsert(SecondMainIdList, v.Id)
    end
end

function XTRPGConfigs.Init()
    RoleTemplate = XTableManager.ReadByIntKey(TABLE_ROLE_PATH, XTable.XTableTRPGRole, "Id")
    RoleAttributeTemplate = XTableManager.ReadByIntKey(TABLE_ROLE_ATTRIBUTE_PATH, XTable.XTableTRPGRoleAttribute, "AttrType")
    RoleTalentTemplate = XTableManager.ReadByIntKey(TABLE_ROLE_TALENT_PATH, XTable.XTableTRPGRoleTalent, "Id")
    RoleTalentGroupClientTemplate = XTableManager.ReadByIntKey(TABLE_ROLE_TALENT_GROUP_CLIENT_PATH, XTable.XTableTRPGRoleTalentGroupClient, "Id")
    MainAreaTemplate = XTableManager.ReadByIntKey(TABLE_MAIN_AREA_PATH, XTable.XTableTRPGMainArea, "Id")
    MazeTemplate = XTableManager.ReadByIntKey(TABLE_MAZE_PATH, XTable.XTableTRPGMaze, "Id")
    MazeLayerTemplate = XTableManager.ReadByIntKey(TABLE_MAZE_LAYER_PATH, XTable.XTableTRPGMazeLayer, "Id")
    MazeCardTemplate = XTableManager.ReadByIntKey(TABLE_MAZE_CARD_PATH, XTable.XTableTRPGMazeCard, "Id")
    MazeCardTypeTemplate = XTableManager.ReadByIntKey(TABLE_MAZE_CARD_TYPE_PATH, XTable.XTableTRPGMazeCardType, "Type")
    MazeCardRecordGroupTemplate = XTableManager.ReadByIntKey(TABLE_MAZE_CARD_RECORD_GROUP_PATH, XTable.XTableTRPGMazeCardRecordGroup, "Id")
    LevelTemplate = XTableManager.ReadByIntKey(TABLE_LEVEL_PATH, XTable.XTableTRPGLevel, "Id")
    BuffTemplate = XTableManager.ReadByIntKey(TABLE_BUFF_PATH, XTable.XTableTRPGBuff, "Id")
    RewardTemplate = XTableManager.ReadByIntKey(TABLE_REWARD_PATH, XTable.XTableTRPGReward, "Id")
    SecondAreaTemplate = XTableManager.ReadByIntKey(TABLE_SECOND_AREA_PATH, XTable.XTableTRPGSecondArea, "Id")
    ThirdAreaTemplate = XTableManager.ReadByIntKey(TABLE_THIRD_AREA_PATH, XTable.XTableTRPGThirdArea, "Id")
    ShopTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_PATH, XTable.XTableTRPGShop, "Id")
    ShopItemTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_ITEM_PATH, XTable.XTableTRPGShopItem, "Id")
    ItemTemplate = XTableManager.ReadByIntKey(TABLE_ITEM_PATH, XTable.XTableTRPGItem, "Id")
    TruthRoadGroupTemplate = XTableManager.ReadByIntKey(TABLE_TRUTH_ROAD_GROUP_PATH, XTable.XTableTRPGTruthRoadGroup, "Id")
    TruthRoadTemplate = XTableManager.ReadByIntKey(TABLE_TRUTH_ROAD_PATH, XTable.XTableTRPGTruthRoad, "Id")
    BossTemplate = XTableManager.ReadByIntKey(TABLE_BOSS_PATH, XTable.XTableTRPGBoss, "Id")
    BossPhasesRewardTemplate = XTableManager.ReadByIntKey(TABLE_BOSS_PHASES_REWARD, XTable.XTableTRPGBossPhasesReward, "Id")
    MemoireStoryTemplate = XTableManager.ReadByIntKey(TABLE_MEMOIRE_STORY, XTable.XTableTRPGMemoirStory, "Id")
    PanelPlotTabTemplate = XTableManager.ReadByIntKey(TABLE_PANEL_PLOT_TAB_PATH, XTable.XTableTRPGPanelPlotTab, "Id")
    FunctionGroupTemplate = XTableManager.ReadByIntKey(TABLE_FUNCTION_GROUP_PATH, XTable.XTableTRPGFunctionGroup, "Id")
    FunctionTemplate = XTableManager.ReadAllByIntKey(TABLE_FUNCTION_PATH, XTable.XTableTRPGFunction, "Id")
    ExamineTemplate = XTableManager.ReadByIntKey(TABLE_EXAMINE_PATH, XTable.XTableTRPGExamine, "Id")
    ExamineActionTemplate = XTableManager.ReadByIntKey(TABLE_EXAMINE_ACTION_PATH, XTable.XTableTRPGExamineAction, "Id")
    ExamineActionTypeTemplate = XTableManager.ReadByIntKey(TABLE_EXAMINE_ACTION_TYPE_PATH, XTable.XTableTRPGExamineActionType, "Type")
    PunishTemplate = XTableManager.ReadByIntKey(TABLE_EXAMINE_PUNISH_PATH, XTable.XTableTRPGExaminePunish, "Id")
    PunishTextTemplate = XTableManager.ReadByIntKey(TABLE_EXAMINE_PUNISH_TEXT_PATH, XTable.XTableTRPGExaminePunishText, "Id")
    ExamineActionDifficultTemplate = XTableManager.ReadByIntKey(TABLE_EXAMINE_ACTION_DIFFICULT_PATH, XTable.XTableTRPGExamineActionDifficult, "Difficult")
    ButtonConditionTemplate = XTableManager.ReadByIntKey(TABLE_BUTTON_CONDITION_PATH, XTable.XTableTRPGButtonCondition, "Id")
    SecondMainTemplate = XTableManager.ReadByIntKey(TABLE_SECOND_MAIN_PATH, XTable.XTableTRPGSecondMain, "Id")
    SecondMainStageTemplate = XTableManager.ReadAllByIntKey(TABLE_SECOND_MAIN_STAGE_PATH, XTable.XTableTRPGSecondMainStage, "Id")

    InitRoleTalentConfigs()
    InitTarget()
    InitTargetLink()
    InitTruthRoadGroupMaxNum()
    InitMazeMapConfigs()
    InitShopItemCountList()
    InitMazeIdList()
    InitSecondMainIdList()
end

-----------------调查员 begin--------------------
local GetRoleConfig = function(roleId)
    local config = RoleTemplate[roleId]
    if not config then
        XLog.Error("XTRPGConfigs GetRoleConfig error:配置不存在, roleId: " .. roleId .. ", 配置路径: " .. TABLE_ROLE_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetAllRoleIds()
    local roleIds = {}
    for roleId in pairs(RoleTemplate) do
        tableInsert(roleIds, roleId)
    end
    return roleIds
end

function XTRPGConfigs.GetRoleInitAttribute(roleId, attributeType)
    local config = GetRoleConfig(roleId)
    return config.InitAttribute[attributeType] or 0
end

function XTRPGConfigs.GetRoleImage(roleId)
    local config = GetRoleConfig(roleId)
    return config.Image
end

function XTRPGConfigs.GetRoleHeadIcon(roleId)
    local config = GetRoleConfig(roleId)
    return config.HeadIcon
end

function XTRPGConfigs.GetRoleName(roleId)
    local config = GetRoleConfig(roleId)
    return config.Name
end

function XTRPGConfigs.GetRoleDesc(roleId)
    local config = GetRoleConfig(roleId)
    return stringGsub(config.Description, "\\n", "\n")
end

function XTRPGConfigs.GetRoleModelId(roleId)
    local config = GetRoleConfig(roleId)
    return config.ModelId
end

function XTRPGConfigs.GetRoleIsShowTip(roleId)
    local config = GetRoleConfig(roleId)
    return config.IsShowTip == 1
end

--属性 begin--
local GetRoleAttributeConfig = function(attrType)
    local config = RoleAttributeTemplate[attrType]
    if not config then
        XLog.Error("XTRPGConfigs GetRoleAttributeConfig error:配置不存在, attrType: " .. attrType .. ", 配置路径: " .. TABLE_ROLE_ATTRIBUTE_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetRoleAttributeName(attrType)
    local config = GetRoleAttributeConfig(attrType)
    return config.Name
end

function XTRPGConfigs.GetRoleAttributeIcon(attrType)
    local config = GetRoleAttributeConfig(attrType)
    return config.Icon
end

function XTRPGConfigs.GetRoleAttributeMaxValue(attrType)
    local config = GetRoleAttributeConfig(attrType)
    return config.MaxValue
end
--属性 end--
--天赋 begin--
local function GetRoleTalentGroupId(roleId)
    local config = GetRoleConfig(roleId)
    local talentId = config.TalentGroupId
    if not talentId or talentId == 0 then
        XLog.Error("XTRPGConfigs GetRoleTalentGroupId error:角色天赋Id未配置, roleId: " .. roleId .. ", 配置路径: " .. TABLE_ROLE_PATH)
        return
    end
    return talentId
end

local GetRoleTalentGroupConfig = function(talentGroupId)
    local config = RoleTalentGroupTemplate[tostring(talentGroupId)]
    if not config then
        XLog.Error("XTRPGConfigs GetRoleTalentGroupConfig error:配置不存在, talentGroupId: " .. talentGroupId .. ", 配置路径: " .. TABLE_ROLE_TALENT_GROUP_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetRoleTalentGroupConfig(roleId)
    local talentGroupId = GetRoleTalentGroupId(roleId)
    return GetRoleTalentGroupConfig(talentGroupId)
end

local GetRoleTalentConfig = function(roleId, talentId)
    local talentGroupId = GetRoleTalentGroupId(roleId)
    local configs = GetRoleTalentGroupConfig(talentGroupId)
    local config = configs[talentId]
    if not config then
        XLog.Error("XTRPGConfigs GetRoleTalentConfig error:配置不存在, talentId: " .. talentId .. ", 配置路径: " .. TABLE_ROLE_TALENT_GROUP_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetRoleTalentPreId(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return config.PreId
end

function XTRPGConfigs.GetRoleTalentCostPoint(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return config.CostPoint
end

function XTRPGConfigs.GetRoleTalentDescription(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return stringGsub(config.Description, "\\n", "\n")
end

function XTRPGConfigs.GetRoleTalentTitle(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return config.Title
end

function XTRPGConfigs.GetRoleTalentIcon(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return config.Icon
end

function XTRPGConfigs.GetRoleTalentIntro(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return stringGsub(config.Intro, "\\n", "\n")
end

function XTRPGConfigs.IsRoleTalentCommonForShow(roleId, talentId)
    local config = GetRoleTalentConfig(roleId, talentId)
    return config.IsCommonForShow ~= 0
end

local GetRoleTalentDefaultConfig = function()
    local config = RoleTalentTemplate[1]
    if not config then
        XLog.Error("XTRPGConfigs GetRoleTalentDefaultConfig error:配置不存在, 配置路径: " .. TABLE_ROLE_TALENT_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetTalentResetCostItemId()
    local config = GetRoleTalentDefaultConfig()
    return config.ResetTalentItemId
end

function XTRPGConfigs.GetTalentResetCostItemIcon()
    local costItemId = XTRPGConfigs.GetTalentResetCostItemId()
    return XItemConfigs.GetItemIconById(costItemId)
end

function XTRPGConfigs.GetTalentResetCostItemCount()
    local config = GetRoleTalentDefaultConfig()
    return config.ResetTalentItemCount
end

function XTRPGConfigs.GetTalentPointIcon()
    local config = GetRoleTalentDefaultConfig()
    return config.TalentPointIcon
end

local GetRoleTalentGroupClientConfig = function(talentGroupId)
    local config = RoleTalentGroupClientTemplate[talentGroupId]
    if not config then
        XLog.Error("XTRPGConfigs GetRoleTalentGroupClientConfig error:配置不存在, talentGroupId: " .. talentGroupId .. ", 配置路径: " .. TABLE_ROLE_TALENT_GROUP_CLIENT_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetRoleTalentTreePrefab(roleId)
    local talentGroupId = GetRoleTalentGroupId(roleId)
    local config = GetRoleTalentGroupClientConfig(talentGroupId)
    return config.Prefab
end
--天赋 end--
--BUFF begin--
local GetBuffConfig = function(buffId)
    local config = BuffTemplate[buffId]
    if not config then
        XLog.Error("XTRPGConfigs GetBuffConfig error:配置不存在, buffId: " .. buffId .. ", 配置路径: " .. TABLE_BUFF_PATH)
        return
    end
    return config
end

function XTRPGConfigs.IsBuffUp(buffId)
    local config = GetBuffConfig(buffId)
    return config.EffectType == XTRPGConfigs.TRPGBuffEffectType.Positive
end

function XTRPGConfigs.IsBuffDown(buffId)
    local config = GetBuffConfig(buffId)
    return config.EffectType == XTRPGConfigs.TRPGBuffEffectType.Negative
end

function XTRPGConfigs.GetBuffIcon(buffId)
    local config = GetBuffConfig(buffId)
    return config.Icon
end

function XTRPGConfigs.GetBuffName(buffId)
    local config = GetBuffConfig(buffId)
    return config.Name
end

function XTRPGConfigs.GetBuffDesc(buffId)
    local config = GetBuffConfig(buffId)
    return stringGsub(config.Desc, "\\n", "\n")
end
--BUFF end--
-----------------调查员 end--------------------
-----------------求真之路begin--------------
local GetTruthRoadGroupConfig = function(id)
    local config = TruthRoadGroupTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetTruthRoadGroupConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_TRUTH_ROAD_GROUP_PATH)
        return
    end
    return config
end

local GetTruthRoadConfig = function(id)
    local config = TruthRoadTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetTruthRoadConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_TRUTH_ROAD_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetTruthRoadGroupTemplate()
    return TruthRoadGroupTemplate
end

function XTRPGConfigs.GetTruthRoadRewardIdList(truthRoadGroupId)
    local truthRoadIdList = XTRPGConfigs.GetTruthRoadIdList(truthRoadGroupId)
    local trpgRewardId
    local trpgRewardIdList = {}
    for _, truthRoadId in pairs(truthRoadIdList) do
        trpgRewardId = XTRPGConfigs.GetTruthRoadTRPGRewardId(truthRoadId)
        if trpgRewardId and trpgRewardId > 0 then
            table.insert(trpgRewardIdList, trpgRewardId)
        end
    end
    return trpgRewardIdList
end

--返回求真之路奖励可领取的进度
function XTRPGConfigs.GetTruthRoadRewardRecivePercent(truthRoadGroupId, trpgRewardId)
    local truthRoadIdList = XTRPGConfigs.GetTruthRoadIdList(truthRoadGroupId)
    local truthRoadMaxNum = #truthRoadIdList
    local trpgRewardIdCfg
    for i, truthRoadId in ipairs(truthRoadIdList) do
        trpgRewardIdCfg = XTRPGConfigs.GetTruthRoadTRPGRewardId(truthRoadId)
        if trpgRewardIdCfg == trpgRewardId then
            return i / truthRoadMaxNum
        end
    end
    return 0
end

function XTRPGConfigs.GetTruthRoadGroupName(truthRoadGroupId)
    local config = GetTruthRoadGroupConfig(truthRoadGroupId)
    return config.Name
end

function XTRPGConfigs.GetTruthRoadGroupPrefab(truthRoadGroupId)
    local config = GetTruthRoadGroupConfig(truthRoadGroupId)
    return config.Prefab
end

function XTRPGConfigs.GetTruthRoadGroupCondition(truthRoadGroupId)
    local config = GetTruthRoadGroupConfig(truthRoadGroupId)
    return config.Condition
end

function XTRPGConfigs.GetTruthRoadGroupSmallName(truthRoadGroupId)
    local config = GetTruthRoadGroupConfig(truthRoadGroupId)
    return config.SmallName
end

function XTRPGConfigs.GetTruthRoadIdList(truthRoadGroupId)
    local config = GetTruthRoadGroupConfig(truthRoadGroupId)
    return config.TruthRoadId
end

function XTRPGConfigs.GetTruthRoadName(id)
    local config = GetTruthRoadConfig(id)
    return config.Name
end

function XTRPGConfigs.GetTruthRoadPrafabName(id)
    local config = GetTruthRoadConfig(id)
    return config.PrefabName
end

function XTRPGConfigs.GetTruthRoadTRPGRewardId(id)
    local config = GetTruthRoadConfig(id)
    return config.TRPGRewardId
end

function XTRPGConfigs.GetTruthRoadCondition(id)
    local config = GetTruthRoadConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetTruthRoadIcon(id)
    local config = GetTruthRoadConfig(id)
    return config.Icon
end

function XTRPGConfigs.GetTruthRoadDesc(id)
    local config = GetTruthRoadConfig(id)
    return config.Desc
end

function XTRPGConfigs.GetTruthRoadStageId(id)
    local config = GetTruthRoadConfig(id)
    return config.StageId
end

function XTRPGConfigs.GetTruthRoadStoryId(id)
    local config = GetTruthRoadConfig(id)
    return config.StoryId
end

function XTRPGConfigs.GetTruthRoadDialogIcon(id)
    local config = GetTruthRoadConfig(id)
    return config.DialogIcon
end
-----------------求真之路end----------------
-----------------主区域begin----------------
local GetMainAreaConfig = function(id)
    local config = MainAreaTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetMainAreaConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_MAIN_AREA_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetMainAreaName(id)
    local config = GetMainAreaConfig(id)
    return config.Name
end

function XTRPGConfigs.GetSecondAreaIdList(id)
    local config = GetMainAreaConfig(id)
    return config.SubAreaId
end

function XTRPGConfigs.GetTargetLinkIdList(id)
    local config = GetMainAreaConfig(id)
    return config.TargetLinkId
end

function XTRPGConfigs.GetAreaOpenLastTimeStamp(id)
    local config = GetMainAreaConfig(id)
    local timeId = config.OpenTimeId
    local openTimestamp = XFunctionManager.GetStartTimeByTimeId(timeId)
    local serverTimestamp = XTime.GetServerNowTimestamp()
    return openTimestamp - serverTimestamp
end

function XTRPGConfigs.GetTargetLinkId(areaId, targetLinkIndex)
    local targetLinkIdList = XTRPGConfigs.GetTargetLinkIdList(areaId)
    return targetLinkIdList[targetLinkIndex]
end

function XTRPGConfigs.GetTruthRoadGroupMaxNum()
    return TruthRoadGroupMaxNum
end

function XTRPGConfigs.GetMainAreaMaxNum()
    return #MainAreaTemplate
end

function XTRPGConfigs.GetAreaRewardIdList(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.TRPGRewardId
end

function XTRPGConfigs.GetTruthRoadGroupIdList(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.TruthRoadGroupId
end

function XTRPGConfigs.GetTruthRoadGroupId(areaId, index)
    local truthRoadGroupIdList = XTRPGConfigs.GetTruthRoadGroupIdList(areaId)
    local truthRoadGroupId = truthRoadGroupIdList[index]
    return truthRoadGroupId
end

function XTRPGConfigs.GetTruthRoadTabBg(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.TruthRoadTabBg
end

function XTRPGConfigs.GetSecondAreaBg(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.SubAreaBg
end

function XTRPGConfigs.GetTruthRoadBg(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.TruthRoadBg
end

function XTRPGConfigs.GetMainAreaEnName(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.EnName
end

function XTRPGConfigs.GetMainAreaFirstOpenFunctionGroupId(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.FirstOpenFunctionGroupId
end

function XTRPGConfigs.GetMainAreaTemplate()
    return MainAreaTemplate
end

function XTRPGConfigs.GetMainAreaCondition(areaId)
    local config = GetMainAreaConfig(areaId)
    return config.Condition
end
-----------------主区域end------------------
-----------------第二区域begin----------------
local GetSecondAreaConfig = function(id)
    local config = SecondAreaTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetSecondAreaConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_SECOND_AREA_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetSecondAreaName(id)
    local config = GetSecondAreaConfig(id)
    return config.Name
end

function XTRPGConfigs.GetExploreChapterBg(id)
    local config = GetSecondAreaConfig(id)
    return config.SubAreaBg
end

function XTRPGConfigs.GetSecondAreaType(id)
    local config = GetSecondAreaConfig(id)
    return config.Type
end

function XTRPGConfigs.GetSecondAreaMazeId(id)
    local config = GetSecondAreaConfig(id)
    return config.MazeId
end

function XTRPGConfigs.GetThirdAreaIdList(id)
    local config = GetSecondAreaConfig(id)
    return config.SubAreaId
end

function XTRPGConfigs.GetSecondAreaCondition(id)
    local config = GetSecondAreaConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetSecondAreaIdToMazeIdDic()
    return SecondAreaIdToMazeIdDic
end
-----------------第二区域end----------------
-----------------第三区域 begin----------------
local GetThirdAreaConfig = function(thirdAreaId)
    local config = ThirdAreaTemplate[thirdAreaId]
    if not config then
        XLog.Error("XTRPGConfigs GetThirdAreaConfig error:配置不存在, Id: " .. thirdAreaId .. ", 配置路径: " .. TABLE_THIRD_AREA_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetThirdAreaName(thirdAreaId)
    local config = GetThirdAreaConfig(thirdAreaId)
    return config.Name
end

function XTRPGConfigs.GetThirdAreaCondition(id)
    local config = GetThirdAreaConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetThirdAreaIcon(id)
    local config = GetThirdAreaConfig(id)
    return config.Icon
end

function XTRPGConfigs.GetThirdAreaFuncGroupList(id)
    local config = GetThirdAreaConfig(id)
    return config.FuncGroup
end
-----------------第三区域end----------------
function XTRPGConfigs.GetThirdAreaEnName(thirdAreaId)
    local config = GetThirdAreaConfig(thirdAreaId)
    return config.EnName
end

function XTRPGConfigs.GetThirdAreaIcon(thirdAreaId)
    local config = GetThirdAreaConfig(thirdAreaId)
    return config.Icon
end

function XTRPGConfigs.GetThirdAreaBg(thirdAreaId)
    local config = GetThirdAreaConfig(thirdAreaId)
    return config.Bg
end

function XTRPGConfigs.GetThirdAreaFunctionGroupIds(thirdAreaId)
    local functionGroupIds = {}

    local config = GetThirdAreaConfig(thirdAreaId)
    for _, groupId in ipairs(config.FuncGroup) do
        if groupId ~= 0 then
            tableInsert(functionGroupIds, groupId)
        end
    end

    return functionGroupIds
end

local GetFunctionGroupConfig = function(functionGroupId)
    local config = FunctionGroupTemplate[functionGroupId]
    if not config then
        XLog.Error("XTRPGConfigs GetFunctionGroupConfig error:配置不存在, Id: " .. functionGroupId .. ", 配置路径: " .. TABLE_FUNCTION_GROUP_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetFunctionGroupConditionId(functionGroupId)
    local config = GetFunctionGroupConfig(functionGroupId)
    return config.Condition
end

function XTRPGConfigs.GetFunctionGroupFunctionIds(functionGroupId)
    local config = GetFunctionGroupConfig(functionGroupId)
    return config.FunctionId
end

local GetFunctionConfig = function(functionId)
    local config = FunctionTemplate[functionId]
    if not config then
        XLog.Error("XTRPGConfigs GetFunctionConfig error:配置不存在, Id: " .. functionId .. ", 配置路径: " .. TABLE_FUNCTION_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetFunctionStageIds()
    local stageIds = {}

    for functionId, config in pairs(FunctionTemplate) do
        if XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.FinishStage) then
            local stageId = config.Params[1]
            stageIds[stageId] = stageId
        end
    end

    return stageIds
end

function XTRPGConfigs.GetFunctionIcon(functionId)
    local config = GetFunctionConfig(functionId)
    return config.Icon
end

function XTRPGConfigs.CheckFunctionNeedSave(functionId)
    local config = GetFunctionConfig(functionId)
    return config.NeedSave ~= 0
end

function XTRPGConfigs.GetFunctionDesc(functionId)
    local config = GetFunctionConfig(functionId)
    return stringGsub(config.Desc, "\\n", "\n")
end

local function GetFunctionType(functionId)
    local config = GetFunctionConfig(functionId)
    return config.Type
end

function XTRPGConfigs.CheckFunctionType(functionId, functionType)
    return GetFunctionType(functionId) == functionType
end

function XTRPGConfigs.GetFunctionParams(functionId)
    local config = GetFunctionConfig(functionId)
    return config.Params
end

function XTRPGConfigs.IsFunctionShowTag(functionId)
    return XTRPGConfigs.CheckFunctionType(functionId, XTRPGConfigs.TRPGFunctionType.Examine)
end
-----------------第三区域 end----------------
-----------------检定相关 begin----------------
local GetExamineConfig = function(examineId)
    local config = ExamineTemplate[examineId]
    if not config then
        XLog.Error("XTRPGConfigs GetExamineConfig error:配置不存在, Id: " .. examineId .. ", 配置路径: " .. TABLE_EXAMINE_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetExamineCostEndurance(examineId)
    local config = GetExamineConfig(examineId)
    return config.Endurance
end

function XTRPGConfigs.GetExamineTitle(examineId)
    local config = GetExamineConfig(examineId)
    return config.Title
end

function XTRPGConfigs.GetExamineDescription(examineId)
    local config = GetExamineConfig(examineId)
    return stringGsub(config.Description, "\\n", "\n")
end

function XTRPGConfigs.GetExamineSucDesc(examineId)
    local config = GetExamineConfig(examineId)
    return stringGsub(config.SucDesc, "\\n", "\n")
end

function XTRPGConfigs.GetExamineFailDesc(examineId)
    local config = GetExamineConfig(examineId)
    return stringGsub(config.FailDesc, "\\n", "\n")
end

function XTRPGConfigs.GetExamineStartMovieId(examineId)
    local config = GetExamineConfig(examineId)
    return config.StartMovieId
end

function XTRPGConfigs.GetExamineActionIds(examineId)
    local actionIds = {}
    local config = GetExamineConfig(examineId)
    for _, actionId in pairs(config.ActionId) do
        if actionId ~= 0 then
            tableInsert(actionIds, actionId)
        end
    end
    return actionIds
end

local GetExamineActionConfig = function(actionId)
    local config = ExamineActionTemplate[actionId]
    if not config then
        XLog.Error("XTRPGConfigs GetExamineActionConfig error:配置不存在, Id: " .. actionId .. ", 配置路径: " .. TABLE_EXAMINE_ACTION_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetExamineActionDesc(actionId)
    local config = GetExamineActionConfig(actionId)
    return config.Desc
end

function XTRPGConfigs.GetExamineActionItemId(actionId)
    local config = GetExamineActionConfig(actionId)
    return config.ItemId
end

function XTRPGConfigs.GetExamineActionItemIcon(actionId)
    local itemId = XTRPGConfigs.GetExamineActionItemId(actionId)
    return XItemConfigs.GetItemIconById(itemId)
end

function XTRPGConfigs.GetExamineActionItemName(actionId)
    local itemId = XTRPGConfigs.GetExamineActionItemId(actionId)
    return XItemConfigs.GetItemNameById(itemId)
end

function XTRPGConfigs.GetExamineActionRound(actionId)
    local config = GetExamineActionConfig(actionId)
    return config.Round
end

function XTRPGConfigs.GetExamineActionNeedValue(actionId)
    local config = GetExamineActionConfig(actionId)
    return config.NeedValue
end

function XTRPGConfigs.GetExamineActionResetCostItemInfo(actionId)
    local config = GetExamineActionConfig(actionId)
    return config.ResetCostId, config.ResetCostCount
end

local function GetExamineActionType(actionId)
    local config = GetExamineActionConfig(actionId)
    return config.Type
end

function XTRPGConfigs.CheckExamineActionType(actionId, actionType)
    return GetExamineActionType(actionId) == actionType
end

local ActionTypeToAttrType = {
    [XTRPGConfigs.TRPGExamineActionType.Strength] = XTRPGConfigs.RoleAttributeType.Power,
    [XTRPGConfigs.TRPGExamineActionType.Agility] = XTRPGConfigs.RoleAttributeType.Speed,
    [XTRPGConfigs.TRPGExamineActionType.Intelligence] = XTRPGConfigs.RoleAttributeType.Intelligence,
}
function XTRPGConfigs.GetExamineActionNeedAttrType(actionId)
    local actionType = GetExamineActionType(actionId)
    return ActionTypeToAttrType[actionType]
end

local GetExamineActionTypeConfig = function(actionType)
    local config = ExamineActionTypeTemplate[actionType]
    if not config then
        XLog.Error("XTRPGConfigs GetExamineActionTypeConfig error:配置不存在, Id: " .. actionType .. ", 配置路径: " .. TABLE_EXAMINE_ACTION_TYPE_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetExamineActionIcon(actionId)
    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        return XTRPGConfigs.GetExamineActionItemIcon(actionId)
    end

    local actionType = GetExamineActionType(actionId)
    local config = GetExamineActionTypeConfig(actionType)
    return config.Icon
end

function XTRPGConfigs.GetExamineActionTypeDesc(actionId)
    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        return CSXTextManagerGetText("TRPGExploreExmaineUseItem")
    end

    local actionType = GetExamineActionType(actionId)
    local config = GetExamineActionTypeConfig(actionType)
    return config.Desc
end

function XTRPGConfigs.GetExamineActionTypeDescEn(actionId)
    local actionType = GetExamineActionType(actionId)
    local config = GetExamineActionTypeConfig(actionType)
    return config.DescEn
end

function XTRPGConfigs.GetExamineActionTypeDefaultItemDesc(actionId)
    local actionType = GetExamineActionType(actionId)
    local config = GetExamineActionTypeConfig(actionType)
    return config.DefaultItemDesc
end

function XTRPGConfigs.GetExamineActionTypeRangeDesc(actionId)
    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        return ""
    end

    local actionType = GetExamineActionType(actionId)
    local config = GetExamineActionTypeConfig(actionType)
    return config.RangeDesc
end

function XTRPGConfigs.GetExamineActionTypeAttrDesc(actionId)
    if XTRPGConfigs.CheckExamineActionType(actionId, XTRPGConfigs.TRPGExamineActionType.ConsumeItem) then
        return ""
    end

    local actionType = GetExamineActionType(actionId)
    local config = GetExamineActionTypeConfig(actionType)
    return config.AttrDesc
end

local GetExamineDifficultConfig = function(actionDifficult)
    local config = ExamineActionDifficultTemplate[actionDifficult]
    if not config then
        XLog.Error("XTRPGConfigs GetExamineDifficultConfig error:配置不存在, Id: " .. actionDifficult .. ", 配置路径: " .. TABLE_EXAMINE_ACTION_DIFFICULT_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetExamineActionDifficultByDelta(delta)
    for difficult, config in ipairs(ExamineActionDifficultTemplate) do
        if delta >= config.Delta then
            return difficult
        end
    end
    return #ExamineActionDifficultTemplate
end

function XTRPGConfigs.GetExamineActionDifficultDesc(actionDifficult)
    if actionDifficult == XTRPGConfigs.TRPGExamineActionDifficult.Default then
        return ""
    end

    local config = GetExamineDifficultConfig(actionDifficult)
    return config.Desc
end
-----------------检定相关 end----------------
-----------------惩罚相关 end----------------
local GetPunishConfig = function(punishId)
    local config = PunishTemplate[punishId]
    if not config then
        XLog.Error("XTRPGConfigs GetPunishConfig error:配置不存在, Id: " .. punishId .. ", 配置路径: " .. TABLE_EXAMINE_PUNISH_PATH)
        return
    end
    return config
end

function XTRPGConfigs.CheckPunishType(punishId, punishType)
    return GetPunishConfig(punishId).Type == punishType
end

function XTRPGConfigs.GetPunishDesc(punishId)
    local config = GetPunishConfig(punishId)
    local desc = PunishTextTemplate[config.Desc].Text
    return stringGsub(desc, "\\n", "\n")
end

function XTRPGConfigs.GetPunishParams(punishId)
    local config = GetPunishConfig(punishId)
    return config.Params
end
-----------------惩罚相关 end----------------
-----------------目标链表begin----------------
local GetTargetLinkConfig = function(id)
    local config = TargetLinkTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetTargetLinkConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_TARGET_LINK_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetTargetLinkTemplate()
    return TargetLinkTemplate
end

function XTRPGConfigs.GetTargetLink(id)
    return GetTargetLinkConfig(id)
end

function XTRPGConfigs.GetTargetLinkName(id)
    if not id or id == NotPreTargetId then
        return DefaultTargetName
    end
    local config = GetTargetLinkConfig(id)
    return config.Name
end

function XTRPGConfigs.GetTargetIdList(id)
    local config = GetTargetLinkConfig(id)
    return config.TargetId
end

function XTRPGConfigs.GetTargetId(id, index)
    local targetIdList = XTRPGConfigs.GetTargetIdList(id)
    return targetIdList[index]
end

function XTRPGConfigs.GetRewardIdList(id)
    local config = GetTargetLinkConfig(id)
    return config.RewardId
end

function XTRPGConfigs.GetTargetOfPreTargetList()
    return TargetOfPreTargetList
end

function XTRPGConfigs.GetPreTargetByTargetId(targetId)
    local targetOfPreTargetList = XTRPGConfigs.GetTargetOfPreTargetList()
    if not targetOfPreTargetList[targetId] then
        XLog.Error("当前目标没有前置目标，目标id：" .. targetId .. "，检查配置路径：" .. TABLE_TARGET_LINK_PATH)
        return
    end
    return targetOfPreTargetList[targetId]
end

function XTRPGConfigs.GetNotPreTargetId()
    return NotPreTargetId
end

function XTRPGConfigs.GetTargetLinkMissionType(id)
    if not id or id == NotPreTargetId then
        return XTRPGConfigs.MissionType.MainLine
    end
    local config = GetTargetLinkConfig(id)
    return config.TargetMissionType
end

function XTRPGConfigs.GetTargetLinkMissionTypeName(missionType)
    return XTRPGConfigs.MissionTypeName[missionType]
end
-----------------目标链表end------------------
-----------------目标表begin----------------
local GetTargetConfig = function(id)
    local config = TargetTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetTargetConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_TARGET_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetMovieTargetId(movieId)
    return MovieIdToTargetIdDic[movieId]
end

function XTRPGConfigs.GetTargetTemplate()
    return TargetTemplate
end

function XTRPGConfigs.GetTarget(id)
    return GetTargetConfig(id)
end

function XTRPGConfigs.GetTargetPrefabName(id)
    local config = GetTargetConfig(id)
    return config.PrefabName
end

function XTRPGConfigs.GetTargetIcon(id)
    local config = GetTargetConfig(id)
    return config.Icon
end

function XTRPGConfigs.GetTargetName(id)
    if not id or id == NotPreTargetId then
        return DefaultTargetName
    end
    local config = GetTargetConfig(id)
    return config.Name
end

function XTRPGConfigs.GetTargetDesc(targetId, targetLinkId)
    if XDataCenter.TRPGManager.IsTargetAllFinish() then
        return DefaultTargetDesc
    end
    if not targetId or targetId == NotPreTargetId then
        local missionType = XTRPGConfigs.GetTargetLinkMissionType(targetLinkId)
        return XTRPGConfigs.DefaultDesc[missionType]
    end

    local config = GetTargetConfig(targetId)
    return config.Desc
end

function XTRPGConfigs.GetTargetTotalNum()
    return TargetTotalNum
end

function XTRPGConfigs.GetTargetAreaIcon(targetId)
    if not targetId or targetId == NotPreTargetId then
        return ""
    end
    local config = GetTargetConfig(targetId)
    return config.AreaIcon
end

function XTRPGConfigs.GetTargetCardIcon(targetId)
    if not targetId or targetId == NotPreTargetId then
        return
    end
    local config = GetTargetConfig(targetId)
    return config.CardIcon
end

function XTRPGConfigs.GetTaskPanelNewShowTime()
    return TaskPanelNewShowTime
end
-----------------目标表end----------------
-----------------奖励表begin--------------------
local GetRewardConfig = function(id)
    local config = RewardTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetRewardConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_REWARD_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetRewardCondition(id)
    local config = GetRewardConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetRewardId(id)
    local config = GetRewardConfig(id)
    return config.RewardId
end

function XTRPGConfigs.GetRewardReceiveDesc(id)
    local config = GetRewardConfig(id)
    return config.ReceiveDesc
end

function XTRPGConfigs.GetSecondMainReceiveDesc(id)
    local config = GetRewardConfig(id)
    return config.SecondMainReceiveDesc
end
-----------------奖励表end----------------------
-----------------道具表begin--------------------
local GetItemConfig = function(id)
    local config = ItemTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetItemConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_ITEM_PATH)
        return
    end
    return config
end

local CheckItemConfig = function(id)
    return ItemTemplate[id] and true or false
end
XTRPGConfigs.CheckItemConfig = CheckItemConfig

function XTRPGConfigs.IsItemPrecious(id)
    local config = GetItemConfig(id)
    return config.ItemType == XTRPGConfigs.ItemType.Special
end

function XTRPGConfigs.GetItemTagIcon(id)
    local config = GetItemConfig(id)
    return config.TagIcon
end

function XTRPGConfigs.GetItemParamDesc(itemId)
    local config = GetItemConfig(itemId)
    return config.Desc
end

function XTRPGConfigs.CheckItemAddAttributeType(itemId, attrType)
    local config = GetItemConfig(itemId)
    return config.Params[1] == attrType
end

function XTRPGConfigs.GetItemAddAttribute(itemId)
    if XTRPGConfigs.CheckDefaultEffectItemId(itemId) then return 0 end
    local config = GetItemConfig(itemId)
    return config.Params[2]
end

function XTRPGConfigs.GetItemMaxCount(id)
    if not CheckItemConfig(id) then
        return XDataCenter.ItemManager.GetMaxCount(id)
    end

    local config = GetItemConfig(id)
    return config.Capacity
end

function XTRPGConfigs.GetItemType(id)
    local config = GetItemConfig(id)
    return config.ItemType
end

function XTRPGConfigs.CheckItemEffectType(itemId, effectType)
    local config = GetItemConfig(itemId)
    return config.EffectType == effectType
end

function XTRPGConfigs.CheckDefaultEffectItemId(itemId)
    return itemId == XTRPGConfigs.ItemEffectDefaultItemId
end

function XTRPGConfigs.GetExamineBuffItemIds(actionId)
    local itemIds = {}

    local attrType = XTRPGConfigs.GetExamineActionNeedAttrType(actionId)
    for itemId in pairs(ItemTemplate) do
        if XTRPGConfigs.CheckItemEffectType(itemId, XTRPGConfigs.ItemEffect.AddExamineAttribute)
        and XTRPGConfigs.CheckItemAddAttributeType(itemId, attrType) then
            tableInsert(itemIds, itemId)
        end
    end
    tableInsert(itemIds, XTRPGConfigs.ItemEffectDefaultItemId)

    return itemIds
end

function XTRPGConfigs.GetItemParams(id)
    local config = GetItemConfig(id)
    return config.Params
end

function XTRPGConfigs.GetItemEffectType(id)
    local config = GetItemConfig(id)
    return config.EffectType
end

--道具是否需要选择角色使用
function XTRPGConfigs.IsItemSelectCharacter(id)
    local effectType = XTRPGConfigs.GetItemEffectType(id)
    if effectType == XTRPGConfigs.ItemEffect.ClearBuff or effectType == XTRPGConfigs.ItemEffect.AddBuff then
        return true
    end
    return false
end

function XTRPGConfigs.IsItemShowUse(id)
    local itemType = XTRPGConfigs.GetItemType(id)
    local itemEffectType = XTRPGConfigs.GetItemEffectType(id)
    return itemType ~= XTRPGConfigs.ItemType.Special and itemEffectType ~= XTRPGConfigs.ItemEffect.AddExamineAttribute
end
-----------------道具表end----------------------
-----------------商店begin--------------------
local GetShopConfig = function(id)
    local config = ShopTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetShopConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_SHOP_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetShopItemIdList(id)
    local config = GetShopConfig(id)
    return config.ShopItemId
end

function XTRPGConfigs.GetShopItemCount(shopId, shopItemId)
    return ShopItemCountList[shopId] and ShopItemCountList[shopId][shopItemId] or 0
end

local GetShopItemConfig = function(id)
    local config = ShopItemTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetShopItemConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_SHOP_ITEM_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetShopItemRewardId(id)
    local config = GetShopItemConfig(id)
    return config.RewardId
end

function XTRPGConfigs.GetShopItemCondition(id)
    local config = GetShopItemConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetShopItemConsumeId(id)
    local config = GetShopItemConfig(id)
    return config.ConsumeId
end

function XTRPGConfigs.GetShopItemConsumeCount(id)
    local config = GetShopItemConfig(id)
    return config.ConsumeCount
end

function XTRPGConfigs.GetShopItemDesc(id)
    local config = GetShopItemConfig(id)
    return config.Desc
end

--返回外部道具表的id
function XTRPGConfigs.GetItemIdByShopItemId(shopItemId)
    local rewardId = XTRPGConfigs.GetShopItemRewardId(shopItemId)
    local rewardGoodsId = XRewardManager.GetRewardSubId(rewardId, 1)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    return rewardList[1].TemplateId
end

function XTRPGConfigs.GetItemResetType(id)
    local config = GetShopItemConfig(id)
    return config.ResetType
end
-----------------商店end----------------------
-----------------迷宫 begin----------------------
local GetMazeConfig = function(mazeId)
    local config = MazeTemplate[mazeId]
    if not config then
        XLog.Error("XTRPGConfigs GetMazeConfig error:配置不存在, mazeId: " .. mazeId .. ", 配置路径: " .. TABLE_MAZE_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetMazeIds()
    return MazeTemplate
end

function XTRPGConfigs.GetMazeLayerIds(mazeId)
    local config = GetMazeConfig(mazeId)
    return config.LayerId
end

function XTRPGConfigs.GetMazeName(mazeId)
    local config = GetMazeConfig(mazeId)
    return config.Name
end

function XTRPGConfigs.GetMazeStartLayerId(mazeId)
    local config = GetMazeConfig(mazeId)
    return config.StartLayerId
end

local GetMazeLayerConfig = function(layerId)
    local config = MazeLayerTemplate[layerId]
    if not config then
        XLog.Error("XTRPGConfigs GetMazeLayerConfig error:配置不存在, layerId: " .. layerId .. ", 配置路径: " .. TABLE_MAZE_LAYER_PATH)
        return
    end
    return config
end

local GetMazeLayerMapId = function(layerId)
    local config = GetMazeLayerConfig(layerId)
    local mapId = config.MapId
    if not mapId or mapId == 0 then
        XLog.Error("XTRPGConfigs GetMazeLayerMapId error:配置不存在, layerId: " .. layerId .. ", 配置路径: " .. TABLE_MAZE_LAYER_PATH)
        return
    end
    return mapId
end

function XTRPGConfigs.GetMazeLayerBgImage(mazeId)
    local config = GetMazeLayerConfig(mazeId)
    return config.BgImage
end

function XTRPGConfigs.GetMazeLayerName(layerId)
    local config = GetMazeLayerConfig(layerId)
    return config.Name
end

function XTRPGConfigs.GetMazeLayerStartNodeId(layerId)
    local config = GetMazeLayerConfig(layerId)
    return config.StartNodeId
end

function XTRPGConfigs.GetMazeLayerStartCardIndex(layerId)
    local config = GetMazeLayerConfig(layerId)
    return config.StartCardIndex
end

local GetMazeMapConfigs = function(mapId)
    local configs = MazeMapTemplates[tostring(mapId)]
    if not configs then
        XLog.Error("XTRPGConfigs GetMazeMapConfigs error:配置不存在, mapId: " .. mapId .. ", 配置路径: " .. TABLE_MAZE_MAP_PATH)
        return
    end
    return configs
end

function XTRPGConfigs.GetMazeMapConfigs(layerId)
    local mapId = GetMazeLayerMapId(layerId)
    return GetMazeMapConfigs(mapId)
end

local GetMazeCardConfig = function(cardId)
    local config = MazeCardTemplate[cardId]
    if not config then
        XLog.Error("XTRPGConfigs GetMazeCardConfig error:配置不存在, cardId: " .. cardId .. ", 配置路径: " .. TABLE_MAZE_CARD_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetMazeCardType(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.Type
end

function XTRPGConfigs.CheckMazeCardType(cardId, paramCardType)
    local cardType = XTRPGConfigs.GetMazeCardType(cardId)
    return cardType == paramCardType
end

function XTRPGConfigs.GetMazeCardConvertCardId(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.ConvertCardId
end

function XTRPGConfigs.GetMazeCardParam(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.Param
end

function XTRPGConfigs.GetMazeCardOrder(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.Order
end

function XTRPGConfigs.IsMazeCardShowTag(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.ShowTag ~= 0
end

function XTRPGConfigs.GetMazeCardName(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.Name
end

function XTRPGConfigs.GetMazeCardFightDes(cardId)
    local config = GetMazeCardConfig(cardId)
    return stringGsub(config.FightDes, "\\n", "\n")
end

function XTRPGConfigs.GetMazeCardQuickFightDes(cardId)
    local config = GetMazeCardConfig(cardId)
    return stringGsub(config.QuickFightDes, "\\n", "\n")
end

function XTRPGConfigs.GetMazeCardIcon(cardId)
    if not XTRPGConfigs.IsIconFromConfig(cardId) then return end
    local config = GetMazeCardConfig(cardId)
    return config.Icon
end

function XTRPGConfigs.GetMazeCardMovieId(cardId)
    if not XTRPGConfigs.CheckMazeCardType(cardId, XTRPGConfigs.CardType.FightWin) then return end
    local config = GetMazeCardConfig(cardId)
    return config.MovieId
end

function XTRPGConfigs.GetMazeCardIconR(cardId)
    if not XTRPGConfigs.IsIconFromConfig(cardId) then return end
    local config = GetMazeCardConfig(cardId)
    return config.IconR
end

function XTRPGConfigs.GetMazeCardMiniIcon(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.MiniIcon
end

function XTRPGConfigs.IsMazeCardDisposeable(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.Disposeable ~= 0
end

function XTRPGConfigs.IsMazeCardSingleDisposeable(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.SingleDisposeable ~= 0
end

function XTRPGConfigs.GetMazeCardRecordGroupId(cardId)
    local config = GetMazeCardConfig(cardId)
    return config.RecordGroupId
end

local GetMazeCardTypeConfig = function(cardType)
    local config = MazeCardTypeTemplate[cardType]
    if not config then
        XLog.Error("XTRPGConfigs GetMazeCardTypeConfig error:配置不存在, cardType: " .. cardType .. ", 配置路径: " .. TABLE_MAZE_CARD_TYPE_PATH)
        return
    end
    return config
end

--预制体中预设好的的卡牌图片不需要读配置
function XTRPGConfigs.IsIconFromConfig(cardId)
    local cardType = XTRPGConfigs.GetMazeCardType(cardId)

    -- 满纸荒唐言
    -- if cardType == XTRPGConfigs.CardType.Block
    -- if cardType == XTRPGConfigs.CardType.Random
    -- then
    -- return false
    -- end
    return true
end

function XTRPGConfigs.GetMazeCardPrefab(cardId)
    local cardType = XTRPGConfigs.GetMazeCardType(cardId)
    local config = GetMazeCardTypeConfig(cardType)
    return config.Prefab
end

function XTRPGConfigs.GetMazeCardTypeIcon(cardId)
    local cardType = XTRPGConfigs.GetMazeCardType(cardId)
    local config = GetMazeCardTypeConfig(cardType)
    return config.Icon
end

local GetMazeCardRecordGroupConfig = function(cardRecordGroupId)
    local config = MazeCardRecordGroupTemplate[cardRecordGroupId]
    if not config then
        XLog.Error("XTRPGConfigs GetMazeCardRecordGroupConfig error:配置不存在, cardRecordGroupId: " .. cardRecordGroupId .. ", 配置路径: " .. TABLE_MAZE_CARD_RECORD_GROUP_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetMazeCardRecordGroupMiniIcon(cardRecordGroupId)
    local config = GetMazeCardRecordGroupConfig(cardRecordGroupId)
    return config.MiniIcon
end

function XTRPGConfigs.GetMazeCardRecordGroupName(cardRecordGroupId)
    local config = GetMazeCardRecordGroupConfig(cardRecordGroupId)
    return config.Name
end

function XTRPGConfigs.GetMazeCardRecordGroupIdList()
    local cardRecordGroupIds = {}
    for id in pairs(MazeCardRecordGroupTemplate) do
        tableInsert(cardRecordGroupIds, id)
    end
    return cardRecordGroupIds
end
-----------------迷宫 end----------------------
-----------------等级 begin----------------------
local GetLevelConfig = function(level)
    local config = LevelTemplate[level]
    if not config then
        XLog.Error("XTRPGConfigs GetLevelConfig error:配置不存在, level: " .. level .. ", 配置路径: " .. TABLE_LEVEL_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetMaxExp(level)
    local config = GetLevelConfig(level)
    return config.UpExp
end

function XTRPGConfigs.GetMaxTalentPoint(level)
    local config = GetLevelConfig(level)
    return config.TalentPoint
end

function XTRPGConfigs.IsMaxLevel(level)
    local maxExp = XTRPGConfigs.GetMaxExp(level)
    return maxExp == 0
end
-----------------等级 end----------------------
-----------------世界BOSS begin----------------
local GetBossConfig = function(id)
    local config = BossTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetBossConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_BOSS_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetBossModelId()
    local config = GetBossConfig(1)
    return config.ModelId
end

function XTRPGConfigs.GetBossTimeId()
    local config = GetBossConfig(1)
    return config.TimeId
end

function XTRPGConfigs.GetBossChallengeCount()
    local config = GetBossConfig(1)
    return config.ChallengeCount
end

function XTRPGConfigs.GetBossDesc()
    local config = GetBossConfig(1)
    return config.Desc
end

function XTRPGConfigs.GetBossStageId()
    local config = GetBossConfig(1)
    return config.StageId
end

function XTRPGConfigs.IsBossStage(stageId)
    local bossStageId = XTRPGConfigs.GetBossStageId()
    return bossStageId == stageId
end

function XTRPGConfigs.GetBossStartStoryId()
    local config = GetBossConfig(1)
    return config.StartStoryId
end

function XTRPGConfigs.GetBossHideEntranceTimeStr()
    local config = GetBossConfig(1)
    return config.HideEntranceTimeStr
end

local GetBossPhasesRewardConfig = function(id)
    local config = BossPhasesRewardTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetBossPhasesRewardConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_BOSS_PHASES_REWARD)
        return
    end
    return config
end

function XTRPGConfigs.GetBossPhasesRewardMaxNum()
    return #BossPhasesRewardTemplate
end

function XTRPGConfigs.GetBossPhasesRewardPercent(id)
    local config = BossPhasesRewardTemplate[id]
    return config.Percent
end

function XTRPGConfigs.GetBossPhasesRewardId(id)
    local config = BossPhasesRewardTemplate[id]
    return config.RewardId
end

function XTRPGConfigs.GetBossIcon(id)
    local config = BossPhasesRewardTemplate[id]
    return config.Icon
end

function XTRPGConfigs.GetBossPhasesRewardTemplate()
    return BossPhasesRewardTemplate
end
-----------------世界BOSS end------------------
-----------------珍藏-回忆 begin---------------
local GetMemoireStoryConfig = function(id)
    local config = MemoireStoryTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetMemoireStoryConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_MEMOIRE_STORY)
        return
    end
    return config
end

function XTRPGConfigs.GetMemoirStoryMaxNum()
    return #MemoireStoryTemplate
end

function XTRPGConfigs.GetMemoirStoryTemplate()
    return MemoireStoryTemplate
end

function XTRPGConfigs.GetMemoireStoryId(id)
    local config = GetMemoireStoryConfig(id)
    return config.StoryId
end

function XTRPGConfigs.GetMemoireStoryUnlockItemId(id)
    local config = GetMemoireStoryConfig(id)
    return config.UnlockItemId
end

function XTRPGConfigs.GetMemoireStoryUnlockItemCount(id)
    local config = GetMemoireStoryConfig(id)
    return config.UnlockItemCount
end

function XTRPGConfigs.GetMemoireStoryTabName(id)
    local config = GetMemoireStoryConfig(id)
    return config.TabName
end

function XTRPGConfigs.GetMemoireStoryName(id)
    local config = GetMemoireStoryConfig(id)
    return config.Name
end

function XTRPGConfigs.GetMemoireStoryDesc(id)
    local config = GetMemoireStoryConfig(id)
    local desc = config.Desc
    return string.gsub(desc, "\\n", "\n")
end

function XTRPGConfigs.GetMemoireStoryImgCG(id)
    local config = GetMemoireStoryConfig(id)
    return config.ImgCG
end
-----------------珍藏-回忆 end---------------
-----------------TRPGSecondMain begin---------------
local GetSecondMainConfig = function(id)
    local config = SecondMainTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetSecondMainConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_SECOND_MAIN_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetSecondMainIdList()
    return SecondMainIdList
end

function XTRPGConfigs.GetSecondMainCondition(id)
    local config = GetSecondMainConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetSecondMainStageId(id)
    local config = GetSecondMainConfig(id)
    return config.SecondMainStageId
end

function XTRPGConfigs.GetSecondMainPrefab(id)
    local config = GetSecondMainConfig(id)
    return config.Prefab
end

function XTRPGConfigs.GetSecondMainBG(id)
    local config = GetSecondMainConfig(id)
    return config.BG
end
-----------------TRPGSecondMain end-----------------
-----------------TRPGSecondMainStage begin---------------
local GetSecondMainStageConfig = function(id)
    local config = SecondMainStageTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetSecondMainStageConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_SECOND_MAIN_STAGE_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetSecondMainStageName(id)
    local config = GetSecondMainStageConfig(id)
    return config.Name
end

function XTRPGConfigs.GetSecondMainStageDesc(id)
    local config = GetSecondMainStageConfig(id)
    return config.Desc
end

function XTRPGConfigs.GetSecondMainStageIcon(id)
    local config = GetSecondMainStageConfig(id)
    return config.Icon
end

function XTRPGConfigs.GetSecondMainStageStageId(id)
    local config = GetSecondMainStageConfig(id)
    return config.StageId
end

function XTRPGConfigs.GetSecondMainStageStoryId(id)
    local config = GetSecondMainStageConfig(id)
    return config.StoryId
end

function XTRPGConfigs.GetSecondMainStageDialogIcon(id)
    local config = GetSecondMainStageConfig(id)
    return config.DialogIcon
end

function XTRPGConfigs.GetSecondMainStageRewardId(id)
    local config = GetSecondMainStageConfig(id)
    return config.TRPGRewardId
end

function XTRPGConfigs.GetSecondMainStageCondition(id)
    local config = GetSecondMainStageConfig(id)
    return config.Condition
end

function XTRPGConfigs.GetSecondMainStagePrefabName(id)
    local config = GetSecondMainStageConfig(id)
    return config.PrefabName
end

function XTRPGConfigs.GetSecondMainStageRewardIdList(secondMainId)
    local secondMainStageIdList = XTRPGConfigs.GetSecondMainStageId(secondMainId)
    local trpgRewardId
    local trpgRewardIdList = {}
    for _, secondMainStageId in ipairs(secondMainStageIdList) do
        trpgRewardId = XTRPGConfigs.GetSecondMainStageRewardId(secondMainStageId)
        if XTool.IsNumberValid(trpgRewardId) then
            table.insert(trpgRewardIdList, trpgRewardId)
        end
    end
    return trpgRewardIdList
end

--返回常规主线奖励可领取的进度
function XTRPGConfigs.GetSecondMainRewardRecivePercent(secondMainId, trpgRewardId)
    local secondMainStageIdList = XTRPGConfigs.GetSecondMainStageId(secondMainId)
    local secondMainStageMaxNum = #secondMainStageIdList
    local trpgRewardIdCfg
    for i, secondMainStageId in ipairs(secondMainStageIdList) do
        trpgRewardIdCfg = XTRPGConfigs.GetSecondMainStageRewardId(secondMainStageId)
        if trpgRewardIdCfg == trpgRewardId then
            return i / secondMainStageMaxNum
        end
    end
    return 0
end
-----------------TRPGSecondMainStage end-----------------
-----------------客户端配置-求真之路和探索营地标签 begin-------------
local GetPanelPlotTabConfig = function(id)
    local config = PanelPlotTabTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetPanelPlotTabConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_PANEL_PLOT_TAB_PATH)
        return
    end
    return config
end

function XTRPGConfigs.GetPanelPlotTabTemplate()
    return PanelPlotTabTemplate
end

function XTRPGConfigs.GetPanelPlotTabName(id)
    local config = GetPanelPlotTabConfig(id)
    return config.Name
end

function XTRPGConfigs.GetPanelPlotTabBg(id)
    local config = GetPanelPlotTabConfig(id)
    return config.Bg
end

function XTRPGConfigs.GetPanelPlotTabOpenUiName(id)
    local config = GetPanelPlotTabConfig(id)
    return config.OpenUiName
end

function XTRPGConfigs.CheckPanelPlotTabCondition(id)
    local config = GetPanelPlotTabConfig(id)
    local condition = config.Condition
    if condition == 0 then
        return true, ""
    end
    return XConditionManager.CheckCondition(condition)
end
-----------------客户端配置-求真之路和探索营地标签 end-------------
-----------------客户端配置-按钮条件 begin-------------
local GetButtonConditionConfig = function(id)
    local config = ButtonConditionTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetButtonConditionConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_BUTTON_CONDITION_PATH)
        return
    end
    return config
end

function XTRPGConfigs.CheckButtonCondition(id)
    local config = GetButtonConditionConfig(id)
    local condition = config.Condition
    if condition == 0 then
        return true, ""
    end
    return XConditionManager.CheckCondition(condition)
end
-----------------客户端配置-按钮条件 end-------------