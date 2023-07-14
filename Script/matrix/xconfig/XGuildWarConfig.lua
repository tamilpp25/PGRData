--===========================
--公会战配置读写
--模块负责：吕天元
--===========================
XGuildWarConfig =  XConfigCenter.CreateTableConfig(XGuildWarConfig, "XGuildWarConfig")
--================================================================
--                         搜索用字典                            --
--================================================================

--================================================================
--                玩法枚举与常数定义                              --
--================================================================
--功能关闭测试开关(打开时客户端公会功能会关闭)
XGuildWarConfig.CLOSE_DEBUG = false
--公会轮数
XGuildWarConfig.ROUND_NUM = 3
--================
--排位榜类型枚举
--================
XGuildWarConfig.RankingType =
{
    Guild = 1, --公会排行榜
    Round = 2, --轮次排行榜
    Node = 3, --节点排行榜
    Elite = 4, --精英怪排行榜
    NodeStay = 5, --节点停留排行榜
}
--================
--排位榜排位对象枚举
--================
XGuildWarConfig.RankingTarget =
{
    Guild = 1,  --公会排行榜
    Player = 2,  --玩家排行榜
}
--================
--地图节点枚举
--================
XGuildWarConfig.NodeType =
{
    Home = 1,   -- 基地
    Normal = 2, -- 普通点
    Buff = 3, -- buff
    Sentinel = 4,   -- 前哨
    Guard = 5,  -- 近卫区
    Infect = 6, -- 感染区
}
--================
--节点状态类型
--================
XGuildWarConfig.NodeStatusType = {
    Alive = 0, -- 活着
    Revive = 1, -- 复活
    Die = 2, -- 死亡
}
--================
--日志类型
--================
XGuildWarConfig.BattleLogType = {
    FirstAttack = 1, -- 首刀
    LasAttack = 2, -- 尾刀
}

XGuildWarConfig.FightRecordAliveType = {
    Alive = 1,
    Die = 2
}

XGuildWarConfig.BaseTaskType = {
    Round = 1, --轮次任务
    Global = 2, --全局任务
}

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

--================
--怪物的行动类型
--================
XGuildWarConfig.MosterActType = {
    Dead = 1, -- 死亡
    Born = 2, -- 出生
    Move = 3, -- 移动
    BaseHit = 4, --撞击基地
    NodeDestroyed = 5, --节点击破
    NextTurn = 6,--下一回合
}

--================
--FightType, 与服务器XGuildWarFightType同步
--================
XGuildWarConfig.NodeFightType = {
    FightNode = 1, -- 节点
    FightMonster = 2, -- 怪物
}

--================
--ActionShowType
--================
XGuildWarConfig.ActionShowType = {
    Now = 1, -- 当前
    History = 2, -- 历史
}
--================
--日志文本配置
--================
XGuildWarConfig.BattleLogTextConfig = {
    [XGuildWarConfig.BattleLogType.FirstAttack] = {
        [XGuildWarConfig.NodeType.Normal] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Sentinel] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Buff] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Guard] = "GuildWarCommonLog",
        [XGuildWarConfig.NodeType.Infect] = "GuildWarCommonLog",
    },
    [XGuildWarConfig.BattleLogType.LasAttack] = {
        [XGuildWarConfig.NodeType.Normal] = "GuildWarNormalLog",
        [XGuildWarConfig.NodeType.Sentinel] = "GuildWarSentinelLog",
        [XGuildWarConfig.NodeType.Buff] = "GuildWarBuffLog",
        [XGuildWarConfig.NodeType.Guard] = "GuildWarGuardLog",
        [XGuildWarConfig.NodeType.Infect] = "GuildWarInfectLog",
    }
}
XGuildWarConfig.BattleDeadNodeLogTextConfig = {
    [XGuildWarConfig.NodeType.Sentinel] = "GuildWarDeadSentinelLog",
    [XGuildWarConfig.NodeType.Infect] = "GuildWarDeadInfectLog",
}
--================
--常量配置
--================
XGuildWarConfig.ActivityPointItemId = 96114 -- 活动体力配置
-- 配置文件所属于的文件夹名称
XGuildWarConfig.DirectoryName = "GuildWar"
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的字段名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XGuildWarConfig.TableKey = enum({
        Activity = { TableName = "GuildWarActivity" }, --活动配置
        Config = { TableName = "GuildWarConfig", ReadFuncName = "ReadByStringKey", ReadKeyName = "Key"}, --活动字符串配置
        Difficulty = { TableName = "GuildWarDifficulty" }, --难度配置
        EliteMonster = { TableName = "GuildWarEliteMonster" }, --精英怪配置
        Node = { TableName = "GuildWarNode" }, --节点配置
        ClientConfig = { DirType = XConfigCenter.DirectoryType.Client, TableName = "GuildWarClientConfig", ReadFuncName = "ReadByStringKey", ReadKeyName = "Key"}, --客户端灵活配置
        MonsterPatrol = { TableName = "GuildWarMonsterPatrol" }, --精英怪巡逻配置
        Buff = { TableName = "GuildWarBuff" }, --buff配置
        SpecialRole = { TableName = "GuildWarSpecialRole" }, --特攻角色列表
        SpecialTeam = { TableName = "GuildWarSpecialRoleTeam" }, --特攻角色队伍Buff
        TaskType = { DirType = XConfigCenter.DirectoryType.Client, TableName = "GuildWarTaskType" }, --公会战任务类型配置
        Task = { TableName = "GuildWarTask" }, --公会战任务配置
        Stage = { TableName = "GuildWarStage" }, -- 关卡表
        RankingType = { DirType = XConfigCenter.DirectoryType.Client, TableName = "GuildWarRankingType"},
        Round = { TableName = "GuildWarRound" }
    })
--================================================================
--                      关卡配置初始化方法                        --
--================================================================
function XGuildWarConfig.Init()
end

--=============
--通过当前配置了OpenTimeId的活动ID获取活动配置(只能有一个活动可配OpenTimeId)
--=============
function XGuildWarConfig.GetCurrentActivity()
    for _, cfg in pairs(XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Activity)) do
        if cfg.TimeId and cfg.TimeId > 0 then
            return cfg
        end
    end
    XLog.Error("XGuildWarConfig.GetCurrentActivity error:没有任何一项活动配置了OpenTimeId！请检查配置:" .. XGuildWarConfig.TableKey.Activity.TableName)
    return nil
end

function XGuildWarConfig.GetNodeConfig(id)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Node, id)
end

function XGuildWarConfig.GetServerConfigValue(key)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Config, key).Value
end

function XGuildWarConfig.GetClientConfigValues(Key, valueType)
    local cfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.ClientConfig, Key)
    local values = cfg and cfg.Values
    local tagValues = {}

    if valueType == "Int" or valueType == "Float" then
        for _,value in pairs(values or {}) do
            table.insert(tagValues, tonumber(value))
        end
    else
        tagValues = values
    end

    return tagValues
end

-- 获取精英怪配置
function XGuildWarConfig.GetEliteMonsterConfig(id)
    return XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.EliteMonster, id)
end

function XGuildWarConfig.GetNodeDifficultyId(nodeId)
    return XGuildWarConfig.GetNodeConfig(nodeId).DifficultyId
end

function XGuildWarConfig.GetNodeIdsByDifficultyId(difficultyId)
    local result = {}
    local configs = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Node)
    for _, config in ipairs(configs) do
        if config.DifficultyId == difficultyId then
            table.insert(result, config.Id)
        end
    end
    return result
end

function XGuildWarConfig.GetParentNodeIdsByNodeId(nodeId)
    local ids = XGuildWarConfig.GetNodeIdsByDifficultyId(XGuildWarConfig.GetNodeDifficultyId(nodeId))
    local result = {}
    for _, id in ipairs(ids) do
        if table.contains(XGuildWarConfig.GetNodeConfig(id).LinkIds, nodeId) then
            table.insert(result, id)
        end
    end
    return result
end

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