--===========================
--公会战配置读写
--模块负责：吕天元
--===========================
---@class XGuildWarConfig
XGuildWarConfig = XConfigCenter.CreateTableConfig(XGuildWarConfig, "XGuildWarConfig")
local XGuildWarConfig = XGuildWarConfig
--=============== 玩法枚举与常数定义 ===============    

--region 玩法枚举与常数定义
--功能关闭测试开关(打开时客户端公会功能会关闭)
XGuildWarConfig.CLOSE_DEBUG = false
--公会轮数
XGuildWarConfig.ROUND_NUM = 3
-- 遮罩 key
XGuildWarConfig.MASK_KEY = "GuildWar"

--排位榜类型枚举
XGuildWarConfig.RankingType = {
    Guild = 1, --公会排行榜
    Round = 2, --轮次排行榜
    Node = 3, --节点排行榜
    Elite = 4, --精英怪排行榜
    NodeStay = 5, --节点停留排行榜
    HideNodeRank = 6, --隐藏节点排行榜，ID为轮次ID
    DefenseMembers = 7, --驻守列表
    ReinforcementMembers = 8, --援军援助列表
}
--排位榜排位对象枚举
XGuildWarConfig.RankingTarget = {
    Guild = 1, --公会排行榜
    Player = 2, --玩家排行榜
    Secret = 3, --隐藏节点排行榜
}
--地图节点类型枚举
XGuildWarConfig.NodeType = {
    Home = 1, -- 基地
    Normal = 2, -- 普通点
    Buff = 3, -- buff
    Sentinel = 4, -- 前哨
    Guard = 5, -- 近卫区
    Infect = 6, -- 感染区
    PandaRoot = 7, -- 二期黑白鲨boss
    PandaChild = 8, -- 二期黑白鲨boss
    TwinsRoot = 9, --三期双子BOSS根节点 也是合体后的节点 策划要求新建种类代码
    TwinsChild = 10, --三期双子BOSS 单体节点 策划要求新建种类代码
    Term3SecretRoot = 11, --三期隐藏节点根节点 (视未来变化 看看是通用节点 还是三期特有节点)
    Term3SecretChild = 13, --三期隐藏节点子节点 (视未来变化 看看是通用节点 还是三期特有节点)
    SecondarySentinel = 12, --三期新增通用节点 次级前哨(小前哨)
    Term4BossRoot = 14, -- 复刷boss节点
    Term4BossChild = 15, -- 复刷boss节点击杀前置后复活后置
    Blockade = 16, --封锁点
    Resource = 18, --资源点
    NodeBoss7 = 19, -- 七期boss
    NodeRelic = 20, -- 废墟
}
--头目节点类型
XGuildWarConfig.BossNodeType = {
    [XGuildWarConfig.NodeType.Infect] = true,
    [XGuildWarConfig.NodeType.PandaRoot] = true,
    [XGuildWarConfig.NodeType.TwinsRoot] = true,
    [XGuildWarConfig.NodeType.Term4BossRoot] = true,
}
--二期特殊黑白鲨节点类型
XGuildWarConfig.PandaNodeType = {
    [XGuildWarConfig.NodeType.PandaRoot] = true,
    [XGuildWarConfig.NodeType.PandaChild] = true,
}
--三期特殊双子节点类型
XGuildWarConfig.TwinsNodeType = {
    [XGuildWarConfig.NodeType.TwinsRoot] = true,
    [XGuildWarConfig.NodeType.TwinsChild] = true,
}
--四期特殊双子节点类型
XGuildWarConfig.Term4BossNodeType = {
    [XGuildWarConfig.NodeType.Term4BossRoot] = true,
    [XGuildWarConfig.NodeType.Term4BossChild] = true,
}
--最终的关卡类型(BOSS节点)
XGuildWarConfig.LastNodeType = {
    [XGuildWarConfig.NodeType.Infect] = true,
    [XGuildWarConfig.NodeType.PandaRoot] = true,
    [XGuildWarConfig.NodeType.TwinsRoot] = true,
    [XGuildWarConfig.NodeType.Term4BossRoot] = true,
    [XGuildWarConfig.NodeType.NodeBoss7] = true,
}
--节点状态类型
XGuildWarConfig.NodeStatusType = {
    Alive = 0, -- 活着
    Revive = 1, -- 复活
    Die = 2, -- 死亡
}
--子节点顺序(二期命名PandaType, 四期改为ChildNodeIndex)
XGuildWarConfig.ChildNodeIndex = {
    None = 0,
    Left = 1,
    Right = 2,
}
--任务类型
XGuildWarConfig.BaseTaskType = {
    Round = 1, --轮次任务
    Global = 2, --全局任务
}
--子任务类型
XGuildWarConfig.SubTaskType = {
    Real = 1, --真任务
    Hp = 2, --基地血量任务
    Difficulty = 3, --难度任务
    Rank = 4, --排行榜任务
}
--公会战任务类型(配置表XGuildWarTask的Id)
XGuildWarConfig.TaskType = {
    First = 1, --第一轮任务
    Second = 2, --第二轮任务
    Third = 3, --第三轮任务
    Activity = 0, --周期任务
}
-- 播放行动Action的UI类型
XGuildWarConfig.GWActionUiType = {
    GWMap = 100, --地图界面
    Panda = 222, --二期黑白鲨界面
    Twins = 333, --三期双子界面
    NodeDestroyed = 900, --节点破坏动画 顺序比较特殊
}
-- 行动Action类型 , 与服务器XGuildWarActionType同步
XGuildWarConfig.GWActionType = {
    MonsterDead = 1, -- 怪物死亡
    MonsterBorn = 2, -- 怪物出生
    MonsterMove = 3, -- 怪物移动
    BaseBeHit = 4, --基地被撞击
    NodeDestroyed = 5, --节点被破坏
    NextTurn = 6, --下一行动回合(并非轮次 而是动画回合) 服务器叫 EightClockAlarm 8点
    TransferWeakness = 7, --交换弱点
    AllGuardNodeDead = 8, -- 全部近卫区死亡，boss准备炮击倒计时
    BaseBeHitByBoss = 9, -- boss炮击基地
    RoundStart = 10, -- 轮次开始时, 
    BossMerge = 11, -- BOSS合体
    BossTreatMonster = 12, --BOSS治疗怪物
    --前哨怪物出生时间改变
    --1、小前哨被攻破，减少前哨站怪物出生CD，如果前哨站上刚好有怪物，则怪物满血
    --2、BUFF点效果，延长怪物刷新时间
    MonsterBornTimeChange = 13,
    ReinforcementBorn = 14, -- 援军生成
    ReinforcementMove = 15, -- 援军移动
    ReinforcementAttack = 16, -- 援军攻击
    ReinforcementDead = 17, -- 援军死亡
    DragonRageFull = 18, -- 满龙怒状态/关卡切换、龙怒值降低
    DragonRageEmpty = 19, -- 龙怒清零/关卡切换，龙怒值积攒
    NodeChangeToRelic = 20, -- 节点转变为废墟
    NewGameThrough = 21, -- 新周目开启通知
}
-- 行动播放类型表 确定某种类型 会播放什么动画并且获取排序(三期是根据UI分类决定动画的列表和顺序 所以播放类型==UI类型)
--　以下是三期顺序
XGuildWarConfig.GWPlayType2Action = {
    [XGuildWarConfig.GWActionUiType.GWMap] = { --地图界面
        XGuildWarConfig.GWActionType.RoundStart, --小前哨、前哨站出生特效
        XGuildWarConfig.GWActionType.MonsterMove, --精英怪移动
        XGuildWarConfig.GWActionType.BaseBeHit, --精英怪碰撞基地
        XGuildWarConfig.GWActionType.MonsterBornTimeChange, --小前哨被击破特效 获得增益（增益生效时才播放）
        XGuildWarConfig.GWActionType.MonsterBorn, --精英怪出生
        XGuildWarConfig.GWActionType.MonsterDead, --精英怪死亡
        XGuildWarConfig.GWActionType.BossMerge, --Boss合体
        XGuildWarConfig.GWActionType.BossTreatMonster, --BOSS治疗怪物
        XGuildWarConfig.GWActionType.ReinforcementBorn, --援军出生
        XGuildWarConfig.GWActionType.ReinforcementMove, -- 援军移动
        XGuildWarConfig.GWActionType.ReinforcementAttack, -- 援军攻击
        XGuildWarConfig.GWActionType.ReinforcementDead, -- 援军死亡
        XGuildWarConfig.GWActionType.DragonRageEmpty, -- 触发龙怒清零
        XGuildWarConfig.GWActionType.DragonRageFull, -- 触发满龙怒
        XGuildWarConfig.GWActionType.NodeChangeToRelic, -- 节点变成废墟
        XGuildWarConfig.GWActionType.NewGameThrough, -- 新周目开启通知
    },
    [XGuildWarConfig.GWActionUiType.Panda] = { --二期黑白鲨界面
        XGuildWarConfig.GWActionType.TransferWeakness,
    },
    [XGuildWarConfig.GWActionUiType.Twins] = { --三期双子界面
        XGuildWarConfig.GWActionType.BossMerge,
    },
    [XGuildWarConfig.GWActionUiType.NodeDestroyed] = { --节点破坏动画 顺序比较特殊
        XGuildWarConfig.GWActionType.NodeDestroyed,
    },
}
--FightType, 与服务器XGuildWarFightType同步
XGuildWarConfig.NodeFightType = {
    FightNode = 1, -- 节点
    FightMonster = 2, -- 怪物
}
--动画类型
XGuildWarConfig.ActionShowType = {
    Now = 1, -- 当前
    History = 2, -- 历史
}
--日志类型 战斗
XGuildWarConfig.BattleLogType = {
    FirstAttack = 1, -- 首刀
    LasAttack = 2, -- 尾刀
}
--日志类型 生存 死亡
XGuildWarConfig.FightRecordAliveType = {
    Alive = 1,
    Die = 2
}
--日志文本配置
XGuildWarConfig.BattleLogTextConfig = {
    [XGuildWarConfig.BattleLogType.FirstAttack] = {
        [XGuildWarConfig.NodeType.Normal] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Sentinel] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Buff] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Guard] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Infect] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.PandaRoot] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.PandaChild] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.TwinsRoot] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.TwinsChild] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Term3SecretRoot] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.SecondarySentinel] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Term4BossChild] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Term4BossRoot] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Blockade] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.NodeBoss7] = "GuildWarCommonLog",
    },
    [XGuildWarConfig.BattleLogType.LasAttack] = {
        [XGuildWarConfig.NodeType.Normal] = "GuildWarNormalLog",
        [XGuildWarConfig.NodeType.Sentinel] = "GuildWarSentinelLog",
        [XGuildWarConfig.NodeType.Buff] = "GuildWarBuffLog",
        [XGuildWarConfig.NodeType.Guard] = "GuildWarGuardLog",
        [XGuildWarConfig.NodeType.Infect] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.PandaRoot] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.PandaChild] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.TwinsRoot] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.TwinsChild] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.Term3SecretRoot] = "GuildWarNormalLog",
        [XGuildWarConfig.NodeType.SecondarySentinel] = "GuildWarSentinelLog",
        [XGuildWarConfig.NodeType.Term4BossChild] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.Term4BossRoot] = "GuildWarInfectLog",
        [XGuildWarConfig.NodeType.Blockade] = "GuildWarNormalLog",
        [XGuildWarConfig.NodeType.NodeBoss7] = "GuildWarNormalLog",
    }
}
XGuildWarConfig.BattleDeadNodeLogTextConfig = {
    [XGuildWarConfig.NodeType.Sentinel] = "GuildWarDeadSentinelLog",
    [XGuildWarConfig.NodeType.Infect] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.PandaRoot] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.PandaChild] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.TwinsRoot] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.TwinsChild] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.Term4BossChild] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.Term4BossRoot] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.Blockade] = "GuildWarDeadInfectLog",
    [XGuildWarConfig.NodeType.NodeBoss7] = "GuildWarDeadInfectLog",
}
--常量配置
XGuildWarConfig.ActivityPointItemId = 96114 -- 活动体力配置
--多队伍攻略区域 队伍的数据种类
XGuildWarConfig.AreaTeamDataType = {
    Uninit = 0, --未初始化
    Custom = 1, --自定义
    Locked = 2, --锁定
}

XGuildWarConfig.RewardStatus = {
    Incomplete = 1,
    Complete = 2,
    Received = 3,
}

--endregion

--=============
--自动配置
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的字段名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
-- 配置文件所属于的文件夹名称
XGuildWarConfig.DirectoryName = "GuildWar"
XGuildWarConfig.TableKey = enum({
    Activity = { TableName = "GuildWarActivity" }, --活动配置
    Config = { TableName = "GuildWarConfig", ReadFuncName = "ReadByStringKey", ReadKeyName = "Key" }, --活动字符串配置
    Difficulty = { TableName = "GuildWarDifficulty" }, --难度配置
    EliteMonster = { TableName = "GuildWarEliteMonster" }, --精英怪配置
    Node = { TableName = "GuildWarNode" }, --节点配置
    ClientConfig = { DirType = XConfigCenter.DirectoryType.Client, TableName = "GuildWarClientConfig", ReadFuncName = "ReadByStringKey", ReadKeyName = "Key" }, --客户端灵活配置
    MonsterPatrol = { TableName = "GuildWarMonsterPatrol" }, --精英怪巡逻配置
    Buff = { TableName = "GuildWarBuff" }, --buff配置
    SpecialRole = { TableName = "GuildWarSpecialRole" }, --特攻角色列表
    SpecialTeam = { TableName = "GuildWarSpecialRoleTeam" }, --特攻角色队伍Buff
    TaskType = { DirType = XConfigCenter.DirectoryType.Client, TableName = "GuildWarTaskType" }, --公会战任务类型配置
    Task = { TableName = "GuildWarTask" }, --公会战任务配置
    Stage = { TableName = "GuildWarStage" }, -- 关卡表
    RankingType = { DirType = XConfigCenter.DirectoryType.Client, TableName = "GuildWarRankingType" },
    Round = { TableName = "GuildWarRound" },
    BossReward = { TableName = "GuildWarBossReward" },
    Reinforcements = { TableName = "GuildWarReinforcements", DirType = XConfigCenter.DirectoryType.Share },
})
--关卡配置初始化方法                        --
function XGuildWarConfig.Init()
end
--通过当前配置了OpenTimeId的活动ID获取活动配置(只能有一个活动可配OpenTimeId)
function XGuildWarConfig.GetCurrentActivity()
    for _, cfg in pairs(XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Activity)) do
        if cfg.TimeId and cfg.TimeId > 0 then
            return cfg
        end
    end
    -- 策划确实关闭了活动，不配置timeId，故不需要error
    --XLog.Error("XGuildWarConfig.GetCurrentActivity error:没有任何一项活动配置了OpenTimeId！请检查配置:" .. XGuildWarConfig.TableKey.Activity.TableName)
    return nil
end
--ShareConfig
function XGuildWarConfig.GetServerConfigValue(key)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Config, key).Value
end
--ClientConfig
function XGuildWarConfig.GetClientConfigValues(Key, valueType)
    local cfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.ClientConfig, Key)
    
    local tagValues = {}

    if cfg and not XTool.IsTableEmpty(cfg.Values) then
        local values = cfg.Values
        
        if valueType == "Int" or valueType == "Float" then
            for _, value in pairs(values) do
                table.insert(tagValues, tonumber(value))
            end
        else
            tagValues = values
        end
        
    end

    return tagValues
end

function XGuildWarConfig.GetClientConfigValue(Key, valueType, index)
    local cfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.ClientConfig, Key)

    if cfg and not XTool.IsTableEmpty(cfg.Values) then
        local valueStr = cfg.Values[(index or 1)]
        
        if (valueType == "Int" or valueType == "Float") then
            return (not string.IsNilOrEmpty(valueStr) and string.IsFloatNumber(valueStr)) and tonumber(valueStr) or 0
        else
            return valueStr
        end

    end
end

--region 难度位置
local function GetDifficultyConfig(difficultyId)
    local cfg = XGuildWarConfig.GetCfgByIdKey(
            XGuildWarConfig.TableKey.Difficulty,
            difficultyId,
            true
    )
    return cfg
end
--获取难度通关奖励
function XGuildWarConfig.GetDifficultyPassRewardId(difficultyId)
    return XGuildWarConfig.GetClientConfigValues("PassRewardShow", "Int")[difficultyId]
end
--获取该难度的战斗事件
function XGuildWarConfig.GetDifficultyFightEvents(difficultyId)
    local cfg = GetDifficultyConfig(difficultyId)
    return cfg.FightEventIds
end
--获取该难度的前置难度(通关前置难度才能挑战)
function XGuildWarConfig.GetDifficultyPreId(difficultyId)
    local cfg = GetDifficultyConfig(difficultyId)
    return cfg and cfg.PreId or "???"
end
--endregion

--region 节点配置
--获取配置
function XGuildWarConfig.GetNodeConfig(id)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Node, id)
end
--获取节点类型
function XGuildWarConfig.GetNodeType(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).Type
end
--获取节点头像
function XGuildWarConfig.GetNodeIcon(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).Icon
end
--获取节点的难度
function XGuildWarConfig.GetNodeDifficultyId(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).DifficultyId
end
--获取怪物头像
function XGuildWarConfig.GetNodeShowMonsterIcon(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).ShowMonsterIcon
end
--获取怪物名字
function XGuildWarConfig.GetNodeShowMonsterName(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).ShowMonsterName
end
--获取节点名字
function XGuildWarConfig.GetNodeName(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).Name
end
--获取节点索引
function XGuildWarConfig.GetNodeStageIndex(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).StageIndex
end
--获取节点描述
function XGuildWarConfig.GetNodeDesc(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).Desc
end
--获取工会战关卡配置ID
function XGuildWarConfig.GetNodeGuildWarStageId(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).GuildWarStageId
end
--通过难度获取该难度下所有节点ID
function XGuildWarConfig.GetNodeIdsByDifficultyId(difficultyId)
    local result = {}
    local configs = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Node)
    for _, config in pairs(configs) do
        if config.DifficultyId == difficultyId then
            table.insert(result, config.Id)
        end
    end
    return result
end
-- 获取节点模型显示
function XGuildWarConfig.GetNodeModelId(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).ModelId
end
--获取该难度下推荐的工会活跃度
function XGuildWarConfig.GetDifficultyRecommendActivation(difficultyId)
    local cfg = GetDifficultyConfig(difficultyId)
    return cfg and cfg.RecommendActive or "???"
end
--获取节点的攻击伤害(BOSS节点才使用的功能)
function XGuildWarConfig.GetNodeAttackBaseDamage(nodeId)
    local config = XGuildWarConfig.GetNodeConfig(nodeId)
    return config and config.AttackBaseDamage
end
--获取路线上的前一个节点
function XGuildWarConfig.GetFrontNodeIdsByNodeId(nodeId)
    local cfg = XGuildWarConfig.GetNodeConfig(nodeId)

    if cfg and XTool.IsNumberValid(cfg.RootId) then
        nodeId = cfg.RootId
    end
    
    local ids = XGuildWarConfig.GetNodeIdsByDifficultyId(XGuildWarConfig.GetNodeDifficultyId(nodeId))
    local result = {}
    for _, id in ipairs(ids) do
        if table.contains(XGuildWarConfig.GetNodeConfig(id).LinkIds, nodeId) then
            table.insert(result, id)
        end
    end
    return result
end

--region 子节点系统
local _ChildNodes = {}
-- id array
-- 获取子节点配置
local function GetNodesChildren(nodeId)
    if not _ChildNodes[nodeId] then
        local nodeConfig = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Node)
        local childNodes = {}
        for id, config in pairs(nodeConfig) do
            if config.RootId == nodeId then
                childNodes[#childNodes + 1] = config.Id
            end
        end
        _ChildNodes[nodeId] = childNodes
        table.sort(childNodes, function(a, b)
            return a < b
        end)
    end
    return _ChildNodes[nodeId]
end
-- 获取子节点虚弱文字
function XGuildWarConfig.GetChildNodeTextWeakness(nodeId, childIndex)
    local nodes = GetNodesChildren(nodeId)
    local id = nodes[childIndex]
    local config = XGuildWarConfig.GetNodeConfig(id)
    return config and config.DescWeakness or "???"
end
-- 获取子节点ID
function XGuildWarConfig.GetChildNodeId(nodeId, childIndex)
    local nodes = GetNodesChildren(nodeId)
    local id = nodes[childIndex]
    return id
end
-- 获取所有子节点ID
function XGuildWarConfig.GetNodesChildren(nodeId)
    return GetNodesChildren(nodeId)
end
-- 获取子节点数量
function XGuildWarConfig.GetChildrenNumber(nodeId)
    local nodes = GetNodesChildren(nodeId)
    local number = #nodes
    return number
end
-- 获取子节点模型显示
function XGuildWarConfig.GetChildNodeModelId(nodeId, childIndex)
    local nodeId = XGuildWarConfig.GetChildNodeId(nodeId, childIndex)
    return XGuildWarConfig.GetNodeConfig(nodeId).ModelId
end
-- 获取子节点在父节点的顺序
function XGuildWarConfig.GetChildNodeIndex(nodeId)
    local parentNodeId = XGuildWarConfig.GetNodeConfig(nodeId).RootId
    if not parentNodeId then
        return 0
    end
    local index = 1
    while true do
        local childId = XGuildWarConfig.GetChildNodeId(parentNodeId, index)
        if childId then
            if childId == nodeId then
                return index
            end
            index = index + 1
        else
            break
        end
    end
    return 0
end
--endregion

--region 二期黑白鲨节点专用
--获取黑白鲨子节点类型
function XGuildWarConfig.GetChildIndexByNodeId(nodeId)
    return XGuildWarConfig.GetChildNodeIndex(nodeId)
end
--endregion

--endregion

-- 获取特攻角色数据
function XGuildWarConfig.GetSpecialRoles()
    return XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.SpecialRole)
end

-- 获取特攻角色数据
function XGuildWarConfig.GetSpecialRole(characterId)
    local cfg = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.SpecialRole)[characterId]
    if not cfg then
        XLog.Error("GuildWarConfig Does not exist special role:" .. characterId)
    end
    return cfg
end

-- 获取关卡ID
function XGuildWarConfig.GetStageId(guildWarStageId)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage, guildWarStageId).StageId
end

-- 获取关卡推荐战力
function XGuildWarConfig.GetStageAbility(guildWarStageId)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Stage, guildWarStageId).Ability
end

-- 获取精英怪配置
function XGuildWarConfig.GetEliteMonsterConfig(id)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.EliteMonster, id)
end

-- 获取援军配置
function XGuildWarConfig.GetReinforcementConfig(id)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Reinforcements, id)
end

-- 获取BUFFEvent
function XGuildWarConfig.GetBuffFightEventId(groupId, hpPercent)
    XGuildWarConfig.__GroupId2Configs = XGuildWarConfig.__GroupId2Configs or {}
    local groupId2Configs = XGuildWarConfig.__GroupId2Configs[groupId]
    if groupId2Configs == nil then
        groupId2Configs = {}
        local configs = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Buff)
        for _, config in ipairs(configs) do
            if config.GroupId == groupId then
                table.insert(groupId2Configs, config)
            end
        end
        XGuildWarConfig.__GroupId2Configs[groupId] = groupId2Configs
    end
    for _, config in ipairs(groupId2Configs) do
        if hpPercent >= config.HpPercent then
            return config.FightEventId
        end
    end
    return groupId2Configs[#groupId2Configs].FightEventId
end

--region 战斗事件
--描述
function XGuildWarConfig.GetFightEventDesc(eventId)
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId).Description
end
--名字
function XGuildWarConfig.GetFightEventName(eventId)
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId).Name
end
--图标
function XGuildWarConfig.GetFightEventIcon(eventId)
    return XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId).Icon
end
--endregion 

--region BossReward
function XGuildWarConfig.GetBossReward(difficultyId)
    local result = {}
    local allConfig = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.BossReward)
    for i, config in pairs(allConfig) do
        if config.Difficulty == difficultyId then
            result[#result + 1] = config
        end
    end
    return result
end

---@param node XGWNode
function XGuildWarConfig.GetBossRewardId(node)
    local level = node:GetBossLevel()
    local difficultyId = node:GetDifficultyId()
    local allConfig = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.BossReward)
    local rewardId
    local curLevel = 0
    for i, config in pairs(allConfig) do
        if config.Difficulty == difficultyId then
            local limitLevel = config.LimitLevel
            if limitLevel > curLevel and level >= limitLevel then
                curLevel = limitLevel
                rewardId = config.RewardId
            end
        end
    end
    if not rewardId then
        -- 找不到返回 level 1
        for i, config in pairs(allConfig) do
            if config.Difficulty == difficultyId then
                if level == 1 then
                    rewardId = config.RewardId
                end
            end
        end
    end
    return rewardId or 0
end

function XGuildWarConfig.IsBossRewardCanReceive(node, configBossReward)
    local level = node:GetBossLevel()
    return level > configBossReward.LimitLevel
end
--endregion BossReward
