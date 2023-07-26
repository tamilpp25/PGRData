--===========================
--超限乱斗配置读写
--模块负责：吕天元
--===========================
XSuperSmashBrosConfig = XSuperSmashBrosConfig or {}
--================================================================
--                         配置表地址                            --
--================================================================
local SHARE_TABLE_PATH = "Share/Fuben/SuperSmashBros/"
local CLIENT_TABLE_PATH = "Client/Fuben/SuperSmashBros/"

local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "SuperSmashBrosActivity.tab"
local TABLE_MODE = SHARE_TABLE_PATH .. "SuperSmashBrosMode.tab"
local TABLE_REWARD = SHARE_TABLE_PATH .. "SuperSmashBrosReward.tab"
local TABLE_CORE = SHARE_TABLE_PATH .. "SuperSmashBrosCore.tab"
local TABLE_CORELEVEL = SHARE_TABLE_PATH .. "SuperSmashBrosCoreLevel.tab"
local TABLE_MONSTER = SHARE_TABLE_PATH .. "SuperSmashBrosMonster.tab"
local TABLE_MONSTER_GROUP = SHARE_TABLE_PATH .. "SuperSmashBrosMonsterLibrary.tab"
local TABLE_MONSTER_TYPE = CLIENT_TABLE_PATH .. "SuperSmashBrosMonsterType.tab"
local TABLE_ENVIRONMENT = SHARE_TABLE_PATH .. "SuperSmashBrosEnvLibrary.tab"
local TABLE_SCENE = SHARE_TABLE_PATH .. "SuperSmashBrosMapLibrary.tab"
local TABLE_SYSTEM_CHARA = SHARE_TABLE_PATH .. "SuperSmashBrosSystemCharacter.tab"
local TABLE_BALANCE_TIPS = CLIENT_TABLE_PATH .. "SuperSmashBrosBalanceTips.tab"
local TABLE_MONSTER_INFO = CLIENT_TABLE_PATH .. "SuperSmashBrosMonsterInfo.tab"
local TABLE_REWARD_SHOW = CLIENT_TABLE_PATH .. "SuperSmashBrosRewardShow.tab"
local TABLE_EGG_ROBOT = CLIENT_TABLE_PATH .. "SuperSmashEggRobot.tab"
local TABLE_TEAM_LEVEL = SHARE_TABLE_PATH .. "SuperSmashBrosTeamLevel.tab"
local TABLE_ASSISTANCE_SKILL = SHARE_TABLE_PATH .. "SuperSmashBrosAssistance.tab"
--================================================================
--                         配置表                                --
--================================================================
local Configs = {}

--================================================================
--                         搜索用字典                            --
--================================================================

--================================================================
--                玩法枚举与常数定义                              --
--================================================================
--=============
--配置表枚举
--Id : 枚举Id
--Path : 关联的表地址 (日志中使用)
--Key : 要检查的字段名 (日志中使用)
--=============
XSuperSmashBrosConfig.TableKey = {
    ActivityConfig = {Id = 1, Path = TABLE_ACTIVITY}, --基础活动配置
        ModeConfig = {Id = 2, Path = TABLE_MODE}, --模式配置
        Activity2ModeDic = {Id = 3, Path = TABLE_MODE, Key = "ActivityId"}, --活动Id -> 模式配置字典
        CoreConfig = {Id = 4, Path = TABLE_CORE}, --超算核心配置
        Activity2CoreDic = {Id = 5, Path = TABLE_MODE, Key = "ActivityId"}, --活动Id -> 超算核心字典
        CoreLevelConfig = {Id = 6, Path = TABLE_CORELEVEL}, --超算核心技能配置
        Core2CoreLevelDic = {Id = 7, Path = TABLE_CORELEVEL, Key = "CoreId"}, --核心Id -> 核心技能字典
        RewardConfig = {Id = 8, Path = TABLE_REWARD}, --模式奖励表
        Mode2RewardDic = {Id = 9, Path = TABLE_REWARD}, --模式Id -> 奖励配置字典
        MonsterConfig = {Id = 10, Path = TABLE_MONSTER}, --怪物配置
        Group2MonsterGroupDic = {Id = 11, Path = TABLE_MONSTER_GROUP, Key = "GroupId"}, --怪物组Id -> 怪物组配置
        EnvironmentConfig = {Id = 12, Path = TABLE_ENVIRONMENT}, --关卡环境配置
        Group2EnvironmentDic = {Id = 13, Path = TABLE_ENVIRONMENT, Key = "GroupId"}, --环境组Id -> 关卡环境配置
        SceneConfig = {Id = 14, Path = TABLE_SCENE}, --关卡场景配置
        Group2SceneDic = {Id = 15, Path = TABLE_SCENE, Key = "GroupId"}, --环境组Id -> 关卡环境配置
        SystemCharaConfig = {Id = 16, Path = TABLE_SYSTEM_CHARA}, --试用角色配置
        MonsterGroupConfig = {Id = 17, Path = TABLE_MONSTER_GROUP}, --怪物组配置
        MonsterTypeConfig = {Id = 18, Path = TABLE_MONSTER_TYPE}, --怪兽类型配置
        BalanceTipsConfig = {Id = 19, Path = TABLE_BALANCE_TIPS}, --平衡信息配置
        MonsterInfoConfig = {Id = 20, Path = TABLE_MONSTER_INFO}, --怪物信息配置
        RewardShowConfig = {Id = 21, Path = TABLE_REWARD_SHOW}, --模式奖励表
        EggRobot = {Id = 22, Path = TABLE_EGG_ROBOT}, --彩蛋机器人
        TeamLevel = {Id = 23, Path = TABLE_TEAM_LEVEL}, --队伍等级
        Assistance = { Id = 24, Path = TABLE_ASSISTANCE_SKILL }, --援助
    }
--=============
--模式类型
--=============
XSuperSmashBrosConfig.ModeType = {
        Normal = 1, --常规
        TeamBattle = 2, --共斗
        Arena = 3, --擂台
        DeathMatch = 4, --死斗
        Survive = 5, --连战(生存模式)
        DeathRandom  = 6, --死亡随机(紧急抽调)
    }
--=============
--模式类型 -> 模式名字典
--=============
XSuperSmashBrosConfig.ModeName = {
        [1] = "Normal", --常规
        [2] = "TeamBattle", --共斗
        [3] = "Arena", --擂台
        [4] = "DeathMatch", --死斗
        [5] = "Survive", --连战(生存模式)
        [6] = "DeathRandom", --死亡随机
    }
--=============
--主界面模式可解锁状态存储字符串
--=============
XSuperSmashBrosConfig.ModeUnlockSaveStr = "ModeUnlockSaveStr"
--=============
--颜色面板的颜色名称
--=============
XSuperSmashBrosConfig.PanelColorType = {
        Red = "Red",
        Blue = "Blue",
        Yellow = "Yellow",
        None = "None", --不显示颜色
        Purple = "Purple",
    }
--=============
--颜色面板的颜色枚举
--=============
XSuperSmashBrosConfig.ColorTypeEnum = {
    None = 0,--不显示颜色
    Red = 1,
    Blue = 2,
    Yellow = 3,
    Purple = 4,
}
--=============
--颜色面板的颜色枚举索引
--=============
XSuperSmashBrosConfig.ColorTypeIndex = {
    [0] = "None",--不显示颜色
    [1] = "Red",
    [3] = "Yellow",
    [2] = "Blue",
    [4] = "Purple",
}
--=============
--界面选人控件状态
--=============
XSuperSmashBrosConfig.RoleGridStatus = {
        Ban = "Ban", --禁用
        WaitSelect = "WaitSelect", --等待选择
        Selected = "Selected", --已选择
    }
--=============
--选人界面页签
--=============
XSuperSmashBrosConfig.PickPage = {
    Pick = "PanelPick",
    Select = "PanelHead"
}
--=============
--选关界面页签
--=============
XSuperSmashBrosConfig.SelectStagePage = {
    Map = 1,
    Environment = 2
}
--=============
--怪物组阶级类型
--=============
XSuperSmashBrosConfig.MonsterType = {
    Normal = 1, --普通级怪物组
    Elite = 2, --精英级怪物组
    Boss = 3, --首领级怪物组
}
--=============
--角色分类
--=============
XSuperSmashBrosConfig.RoleType = {
    Chara = 1, --我方角色
    Monster = 2, --怪物
}
--=============
--队伍选取格特殊状态值
--=============
XSuperSmashBrosConfig.PosState = {
    Random = -1, --随机选择
    OnlyRandom = -2, --仅随机
    Ban = -3, --禁用
    Empty = 0, --空位
}
--=============
--援助角色类型
--=============
XSuperSmashBrosConfig.AssistType = {
    Character = 1,
    Robot = 2,
    Monster = 3,
}
--================================================================
--                      关卡配置初始化方法                        --
--================================================================
--=============
--初始化ActivityId -> Mode配置字典
--=============
local InitActivity2ModeDic = function()
    local allMode = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.ModeConfig)
    local tableId = XSuperSmashBrosConfig.TableKey.Activity2ModeDic.Id
    Configs[tableId] = {}
    for _, mode in pairs (allMode or {}) do
        if not Configs[tableId][mode.ActivityId] then
            Configs[tableId][mode.ActivityId] = {}
        end
        --以模式的优先级顺序排序
        Configs[tableId][mode.ActivityId][mode.Priority] = mode
    end
end
--============= abandon
--初始化ActivityId -> 核心配置字典
--需要在Activity2ModeDic初始化后初始化
--=============
local InitActivity2CoreDic = function()
    --local tableId = XSuperSmashBrosConfig.TableKey.Activity2CoreDic.Id
    --Configs[tableId] = {}
    --for activityId, modes in pairs (XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.Activity2ModeDic) or {}) do
    --    Configs[tableId][activityId] = {}
    --    for modePriority, mode in pairs(modes or {}) do
    --        --以所属模式的优先级顺序排序
    --        local t = Configs[tableId][activityId]
    --        t[#t + 1] = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.CoreConfig, mode.CoreId)
    --    end
    --end
end
--=============
--初始化ActivityId -> 核心配置字典
--需要在Activity2ModeDic初始化后初始化
--=============
local InitCore2CoreLevelDic = function()
    local tableId = XSuperSmashBrosConfig.TableKey.Core2CoreLevelDic.Id
    Configs[tableId] = {}
    for _, skill in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.CoreLevelConfig) or {}) do
        if not Configs[tableId][skill.CoreId] then
            Configs[tableId][skill.CoreId] = {}
        end
        --以技能的等级顺序排序
        Configs[tableId][skill.CoreId][skill.Star] = skill
    end
end
--=============
--初始化模式Id -> 模式奖励配置字典
--=============
local InitMode2RewardDic = function()
    local tableId = XSuperSmashBrosConfig.TableKey.Mode2RewardDic.Id
    Configs[tableId] = {}
    for _, reward in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.RewardConfig) or {}) do
        if not Configs[tableId][reward.ModeId] then
            Configs[tableId][reward.ModeId] = {}
        end
        Configs[tableId][reward.ModeId][reward.OrderId] = reward
    end
end
--=============
--初始化怪物组Id -> 怪物配置字典
--=============
local InitGroup2MonsterGroupDic = function()
    local tableId = XSuperSmashBrosConfig.TableKey.Group2MonsterGroupDic.Id
    Configs[tableId] = {}
    for _, monster in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.MonsterGroupConfig) or {}) do
        if not Configs[tableId][monster.LibraryId] then
            Configs[tableId][monster.LibraryId] = {}
        end
        table.insert(Configs[tableId][monster.LibraryId], monster)
    end
end
--=============
--初始化组Id -> 关卡环境配置字典
--=============
local InitGroup2EnvironmentDic = function()
    local tableId = XSuperSmashBrosConfig.TableKey.Group2EnvironmentDic.Id
    Configs[tableId] = {}
    for _, environ in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.EnvironmentConfig) or {}) do
        if not Configs[tableId][environ.LibraryId] then
            Configs[tableId][environ.LibraryId] = {}
        end
        table.insert(Configs[tableId][environ.LibraryId], environ)
    end
end
--=============
--初始化组Id -> 关卡场景配置字典
--=============
local InitGroup2SceneDic = function()
    local tableId = XSuperSmashBrosConfig.TableKey.Group2SceneDic.Id
    Configs[tableId] = {}
    for _, scene in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.
    SceneConfig) or {}) do
        if not Configs[tableId][scene.LibraryId] then
            Configs[tableId][scene.LibraryId] = {}
        end
        table.insert(Configs[tableId][scene.LibraryId], scene)
    end
end
--=============
--初始化所有配置表和字典
--=============
function XSuperSmashBrosConfig.Init()
    Configs[XSuperSmashBrosConfig.TableKey.ActivityConfig.Id] = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableSuperSmashBrosActivity, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.ModeConfig.Id] = XTableManager.ReadByIntKey(TABLE_MODE, XTable.XTableSuperSmashBrosMode, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.CoreConfig.Id] = XTableManager.ReadByIntKey(TABLE_CORE, XTable.XTableSuperSmashBrosCore, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.CoreLevelConfig.Id] = XTableManager.ReadByIntKey(TABLE_CORELEVEL, XTable.XTableSuperSmashBrosCoreLevel, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.RewardConfig.Id] = XTableManager.ReadByIntKey(TABLE_REWARD, XTable.XTableSuperSmashBrosReward, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.MonsterConfig.Id] = XTableManager.ReadByIntKey(TABLE_MONSTER, XTable.XTableSuperSmashBrosMonster, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.MonsterGroupConfig.Id] = XTableManager.ReadByIntKey(TABLE_MONSTER_GROUP, XTable.XTableSuperSmashBrosMonsterLibrary, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.EnvironmentConfig.Id] = XTableManager.ReadByIntKey(TABLE_ENVIRONMENT, XTable.XTableSuperSmashBrosEnvLibrary, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.SceneConfig.Id] = XTableManager.ReadByIntKey(TABLE_SCENE, XTable.XTableSuperSmashBrosMapLibrary, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.SystemCharaConfig.Id] = XTableManager.ReadByIntKey(TABLE_SYSTEM_CHARA, XTable.XTableSuperSmashBrosSystemCharacter, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.MonsterTypeConfig.Id] = XTableManager.ReadByIntKey(TABLE_MONSTER_TYPE, XTable.XTableSuperSmashBrosMonsterType, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.BalanceTipsConfig.Id] = XTableManager.ReadByIntKey(TABLE_BALANCE_TIPS, XTable.XTableSuperSmashBrosBalanceTips, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.MonsterInfoConfig.Id] = XTableManager.ReadByIntKey(TABLE_MONSTER_INFO, XTable.XTableSuperSmashBrosMonsterInfo, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.RewardShowConfig.Id] = XTableManager.ReadByIntKey(TABLE_REWARD_SHOW, XTable.XTableSuperSmashBrosRewardShow, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.EggRobot.Id] = XTableManager.ReadByIntKey(TABLE_EGG_ROBOT, XTable.XTableSuperSmashEggRobot, "Id")
    Configs[XSuperSmashBrosConfig.TableKey.TeamLevel.Id] = XTableManager.ReadByIntKey(TABLE_TEAM_LEVEL, XTable.XTableSuperSmashBrosTeamLevel, "TeamLevel")
    Configs[XSuperSmashBrosConfig.TableKey.Assistance.Id] = XTableManager.ReadByIntKey(TABLE_ASSISTANCE_SKILL, XTable.XTableSuperSmashBrosAssistance, "AssistId")
    InitActivity2ModeDic()
    InitActivity2CoreDic()
    InitCore2CoreLevelDic()
    InitMode2RewardDic()
    InitGroup2MonsterGroupDic()
    InitGroup2EnvironmentDic()
    InitGroup2SceneDic()
end

--=============
--给定配置表Key，获取该配置表全部配置
--@tableKey : XSuperSmashBrosConfig.TableKey枚举项
--=============
function XSuperSmashBrosConfig.GetAllConfigs(tableKey)
    if not tableKey or not tableKey.Id then
        XLog.Error("The tableKey given is not exist. tableKey : " .. tostring(tableKey))
        return {}
    end
    return Configs[tableKey.Id]
end
--=============
--给定配置表Key和Id，获取该配置表指定Id的配置
--@params:
--tableKey : XSuperSmashBrosConfig.TableKey枚举项
--idKey : 该配置表的主键Id或Key
--noTips : 若没有查找到对应项，是否要打印错误日志
--=============
function XSuperSmashBrosConfig.GetCfgByIdKey(tableKey, idKey, noTips)
    if not tableKey or not idKey then
        XLog.Error("XSuperSmashBrosConfig.GetCfgByIdKey error: tableKey or idKey is null!")
        return {}
    end
    local allCfgs = XSuperSmashBrosConfig.GetAllConfigs(tableKey)
    if not allCfgs then
        return {}
    end
    local cfg = allCfgs[idKey]
    if not cfg then
        if not noTips then
            XLog.ErrorTableDataNotFound(
                "XSuperSmashBrosConfig.GetCfgByIdKey",
                tableKey.Key or "唯一Id",
                tableKey.Path,
                tableKey.Key or "唯一Id",
                tostring(idKey))
        end
        return {}
    end
    return cfg
end
--=============
--通过当前配置了OpenTimeId的活动ID获取活动配置(只能有一个活动可配OpenTimeId)
--=============
function XSuperSmashBrosConfig.GetCurrentActivity()
    for _, cfg in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.ActivityConfig)) do
        if cfg.OpenTimeId and cfg.OpenTimeId > 0 then
            return cfg
        end
    end
    XLog.Error("XSuperSmashBrosConfig.GetCurrentActivity error:没有任何一项活动配置了OpenTimeId！请检查配置:" .. TABLE_ACTIVITY)
    return nil
end

function XSuperSmashBrosConfig.GetDailyRewardItemId()
    local cfg = XSuperSmashBrosConfig.GetCurrentActivity()
    return cfg and cfg.LevelItem or false
end

function XSuperSmashBrosConfig.GetDailyRewardItemCount()
    local cfg = XSuperSmashBrosConfig.GetCurrentActivity()
    return cfg and cfg.AddTeamItem or 0
end

---@param role XSmashBCharacter
function XSuperSmashBrosConfig.GetAssistantSkillDesc(role)
    local id = role:GetCharacterId()
    local config = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Assistance, id, true)
    return config.Desc
end

---@param role XSmashBCharacter
function XSuperSmashBrosConfig.GetAssistantSkillName(role)
    local id = role:GetCharacterId()
    local config = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Assistance, id, true)
    return config.SkillName
end