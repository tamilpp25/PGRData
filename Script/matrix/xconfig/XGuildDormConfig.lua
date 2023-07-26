--=================
--公会宿舍配置管理
--负责人：吕天元，陈思亮，李培弘
--=================
XGuildDormConfig = XConfigCenter.CreateTableConfig(XGuildDormConfig, "XGuildDormConfig")
--================
--常量配置
--================
-- 配置文件所属于的文件夹名称
XGuildDormConfig.DirectoryName = "GuildDorm"
-- 请求公会成员列表的需求间隔时间
XGuildDormConfig.RequestMemberGap = 10
--================
--测试配置
--================
-- 开启键鼠操作
XGuildDormConfig.DebugKeyboard = false
-- 开启延迟测试
XGuildDormConfig.DebugNetworkDelay = false
-- 最小延迟时间（毫秒）
XGuildDormConfig.DebugNetworkDelayMin = 1
-- 最大延迟时间（毫秒）
XGuildDormConfig.DebugNetworkDelayMax = 2
-- 开启断线重连测试
XGuildDormConfig.DebugOpenReconnect = false
XGuildDormConfig.DebugReconnectSign = false
-- 开启满人数测试
XGuildDormConfig.DebugFullRole = false
-- 增加人数数量
XGuildDormConfig.DebugFullRoleCount = 1
-- 切换新旧公会入口
XGuildDormConfig.DebugOpenOldUi = false

XGuildDormConfig.UiGridSortIndex = {
    PanelSummerGift = 40,
    PanelMusicPlayer = 39,
    GridName = 38,
}

XGuildDormConfig.TriangleType = {
    None = -1,
    Player = 1,
    Npc = 2,
}

XGuildDormConfig.FurnitureRewardEventType = {
    Normal = 1,
}

XGuildDormConfig.SyncState = {
    None = 0,
    MoveWall = 1,
    Move = 2,
}

XGuildDormConfig.SyncMsgType = {
    Furniture = 1,
    PlayAction = 2,
    PlayerExit = 3,
    Entities = 4,
    BGM = 5,
    Theme = 6,
    NpcGroup = 7,
}

XGuildDormConfig.ErrorCode = {
    Success = 0,
    PreEnterFailed = 1,
    TCPFailed = 2,
    EnterFailed = 3,
    KCPFailed = 4,
    PreEnterSuccess = 5,
    RemoteDisconnect = 6, -- 这个远程断开有可能是自己触发的
}

XGuildDormConfig.TcpErrorCode = {
    OK = 0, -- 连接成功
    Error = 1, -- ConnectionReset(自己断网)
    --[[
        1.远程服务器断开（关服）
        2.服务器主动踢出（这情况未测试过）
        3.印象中手机设备自己退出也会触发（需要再验证）
    ]]
    RemoteDisconnect = 2,
}

-- 交互状态
XGuildDormConfig.InteractStatus = {
    Begin = 1,
    Playing = 2,
    End = 3,
}

--家具摆放的旋转状态
XGuildDormConfig.FurnitureRotateState = {
    Horizontal = 0, --横摆
    Vertical = 1, --竖摆
}

-- 角色状态机
XGuildDormConfig.RoleFSMType = enum({
    IDLE = "IDLE", -- 闲置状态
    MOVE = "MOVE", -- 移动状态
    PLAY_ACTION = "PLAY_ACTION", -- 播放行为状态
    PATROL_IDLE="PATROL_IDLE", -- 巡逻中的停留状态
    INTERACT="INTERACT" --交互状态
})

--2.6同步角度忽略值
XGuildDormConfig.IgnoreAngle=99999

-- NPC状态
XGuildDormConfig.NpcState= {
    Static=0,
    Move=1,
    Idle=2,
    Interact=3
}

--家具模型类型
XGuildDormConfig.FurnitureType = {
    GROUND = 1, --地板
    NORMAL = 2, --一般家具
    DITHER = 3, --需要视角遮蔽时隐藏的家具  
}
--家具Dither脚本状态机状态枚举
XGuildDormConfig.FurnitureDitherState = {
    Display = "Enter", --展示
    Hide = "Hide" --隐藏
}
XGuildDormConfig.FurnitureButtonType = {
    BehaviorTree = 1, -- 行为树
    SkipFunction = 2, -- 跳转功能
    Npc = 3, -- npc交互
}
--家具动画播放类型
XGuildDormConfig.FurnitureAnimationType = {
    NoAnimation = 0, --没有动画
    TriggerAnimation = 1, --根据交互Trigger来播放动画,进入时播放进入动画，离开时播放离开动画
    FunctionAnimation = 2, --根据约定的方法来播放动画(前端写方法)
}
--家具动画播放时机类型
XGuildDormConfig.FurnitureAnimationName = {
    Setup = 1, --启动动画
    Exit = 2, --关闭动画
}

XGuildDormConfig.FurnitureAnimationEventType = {
    GuildWar = "CheckGuildWarOpen",
    Test = "TestEvent"
}

--工会宿舍引导Id
XGuildDormConfig.GuildGroupId = 60221

--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XGuildDormConfig.TableKey = enum({
    Furniture = { TableName = "GuildDormFurniture" }, --家具配置
    DefaultFurniture = { TableName = "GuildDormDefaultFurniture" }, --默认家具配置
    Room = { TableName = "GuildDormRoom" },
    BGM = { TableName = "GuildDormBgm" }, --BGM配置
    Theme = { TableName = "GuildDormRoomTheme" }, --主题配置
    ThemeLabel = {TableName = "GuildDormRoomThemeLabel"}, --主题标签配置
    GuildDormRole = {}, -- 公会宿舍角色配置
    GuildDormRoleBehavior = {}, -- 公会宿舍角色行为树配置
    GuildDormPlayAction = {}, -- 公会宿舍角色动画配置
    GuildDormClientConfig = { DirType = XConfigCenter.DirectoryType.Client
        , ReadFuncName = "ReadByStringKey", ReadKeyName = "Key" },
    GuildDormConfig = {},
    GuildDormNpc = {},
    GuildDormNpcRefresh = {},
    GuildDormNpcRefreshGroup = {},
    GuildDormNpcTalk = {},
    GuildDormDialog = { DirType = XConfigCenter.DirectoryType.Client },
    GuildDormFurnitureInteractBtn = { DirType = XConfigCenter.DirectoryType.Client },
    GuildDormEffect = { DirType = XConfigCenter.DirectoryType.Client },
    GuildDormFurnitureEffect = { DirType = XConfigCenter.DirectoryType.Client },
    GuildDormNpcActionIdle={},
})
--=============
--场景所属数据类型
--=============
XGuildDormConfig.SceneObjOwnerType = {
    SELF = 1, --玩家自身的对象数据
    OTHER = 2 --其他玩家的对象数据
}
--=============
--场景视角类型
--=============
XGuildDormConfig.SceneViewType = {
    OverView = 0, --总览
    RoomView = 1, --房间视角
    DeviceView = 2, --设备视角
}

XGuildDormConfig.SpecialRewardUiType = {
    Normal = 1,
    RandomReward = 2, -- 随机奖励
    RedPointReward = 3, -- 红点奖励
}

-- 家具条件类型
XGuildDormConfig.FurnitureConditionType = {
    None = 0,
    Time = 1,
    Condition = 2,
    RedPointCondition = 3,
}

--=============
--额外初始化(没特殊处理时，这里只是用于给ConfigCenter调用的空方法)
--=============
function XGuildDormConfig.Init()

end

function XGuildDormConfig.GetBgmCfgById(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.BGM, id)
    return config or {}
end

function XGuildDormConfig.GetThemeCfgById(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Theme, id)
    return config or {}
end

function XGuildDormConfig.GetTalkHeightOffset(roleId)
    local config = XDormConfig.GetCharacterStyleConfigById(roleId)
    if config == nil then return 0 end
    return config.DailogWidgetHight
end

function XGuildDormConfig.GetRoleBehaviorIdByState(roleId, state)
    if XGuildDormConfig._RoleState2BehaviorId == nil then
        XGuildDormConfig._RoleState2BehaviorId = {}
        for _, v in pairs(XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.GuildDormRoleBehavior)) do
            XGuildDormConfig._RoleState2BehaviorId[v.CharacterId] = XGuildDormConfig._RoleState2BehaviorId[v.CharacterId] or {}
            XGuildDormConfig._RoleState2BehaviorId[v.CharacterId][v.State] = v
        end
    end
    if not XGuildDormConfig._RoleState2BehaviorId[roleId] then
        return XGuildDormConfig.GetDefaultBehaviorIdByState(state)
    end
    if string.IsNilOrEmpty(XGuildDormConfig._RoleState2BehaviorId[roleId][state]) then
        return XGuildDormConfig.GetDefaultBehaviorIdByState(state)
    end
    return XGuildDormConfig._RoleState2BehaviorId[roleId][state]
end

function XGuildDormConfig.GetModelPathByRoleId(roleId)
    local config = XDormConfig.GetCharacterStyleConfigById(roleId)
    if config == nil then return 0 end
    return config.Model
end

function XGuildDormConfig.GetCharacterControllerArgs(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormRole, id)
    return config.CCHeight
            , config.CCRadius
            , CS.UnityEngine.Vector3(config.CCCenterX, config.CCCenterY, config.CCCenterZ)
            , config.SkinWidth
end

function XGuildDormConfig.GetRoleCCSkinWidth(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormRole, id)
    if config == nil then return 0 end
    return config.SkinWidth
end

function XGuildDormConfig.GetRoleMoveSpeed()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "RoleMoveSpeed")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetRoleAngleSpeed()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "RoleAngleSpeed")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetSyncServerTime()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "SyncServerTime")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetTalkHideTime()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "TalkHideTime")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetChannelCountByRoomId(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Room, id)
    return config.ChannelCount
end

function XGuildDormConfig.GetChannelMemberCountByRoomId(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Room, id)
    return config.ChannelMemberCount
end

function XGuildDormConfig.GetRoleNameHeightOffset(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormRole, id)
    if config == nil then return 0 end
    return config.NameHeightOffset
end

function XGuildDormConfig.GetRoleTalkHeightOffset(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormRole, id)
    if config == nil then return 0 end
    return config.TalkHeightOffset
end

function XGuildDormConfig.GetMaxPredictionTime()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "MaxPredictionTime")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetClosePredictionDistance()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "ClosePredictionDistance")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetInteractIntervalTime()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormConfig, 1)
    return config.InteractIntervalTime
end

function XGuildDormConfig.GetTalkSpiltLenght()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "TalkSpiltLenght")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetIsOpenPrediction()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "IsOpenPrediction")
    return tonumber(config.Values[1]) >= 1
end

function XGuildDormConfig.GetAutoGCMemroy()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "AutoGCMemroy")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetSwitchRoleEffect()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "SwitchRoleEffect")
    return config.Values[1]
end

function XGuildDormConfig.GetDefaultBehaviorIdByState(state)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , state .. "_BEHAVIORID")
    if config.Values == nil then
        return "unknow"
    end
    return config.Values[1]
end

function XGuildDormConfig.GetRoleIdleAnimName(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormRole, id)
    if config and not string.IsNilOrEmpty(config.IdleAnim) then
        return config.IdleAnim
    end
    return XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "IdleAnimationName").Values[1]
end

function XGuildDormConfig.GetRoleWalkAnimName(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormRole, id)
    if config and not string.IsNilOrEmpty(config.WalkAnim) then
        return config.WalkAnim
    end
    return XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "WalkAnimationName").Values[1]
end

function XGuildDormConfig.GetRoleInteracAngleSpeed()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "RoleInteracAngleSpeed")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetChannelMemberCountIcon(count)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
        , "ChannelMemberCountIcon")
    for i = 1, #config.Values, 2 do
        if count <= tonumber(config.Values[i]) then
            return config.Values[i + 1]
        end
    end
    return config.Values[#config.Values]
end

function XGuildDormConfig.GetRoleAlpha()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
    , "RoleAlpha")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetRoleAlphaSpeed()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
    , "RoleAlphaSpeed")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetRoleAlphaDistance()
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormClientConfig
    , "RoleAlphaDistance")
    return tonumber(config.Values[1])
end

function XGuildDormConfig.GetNpcRefreshConfigsByThemeId(id)
    local result = {}
    local configs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.GuildDormNpcRefresh)
    for _, config in ipairs(configs) do
        if config.ThemeId == id then
            table.insert(result, config)
        end
    end
    return result
end

function XGuildDormConfig.GetNpcRefreshConfigById(id)
    local configs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.GuildDormNpcRefresh)
    return configs[id]
end

function XGuildDormConfig.GetNpcRefreshConfigsByNpcGroupId(id, themeId)
    local result = {}
    local groupIdCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormNpcRefreshGroup, id)
    for _, npcRefreshId in pairs(groupIdCfg.NpcRefreshIds or {}) do
        local npcRefreshCfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormNpcRefresh, npcRefreshId)
        if npcRefreshCfg.ThemeId == themeId then
            table.insert(result, npcRefreshCfg)
        end
    end
    return result
end

function XGuildDormConfig.CheckHasTalkId(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormNpcTalk, id, true)
    return not XTool.IsTableEmpty(config)
end

-- Id大于1000的配置为预览配置，设置装扮时需要减去1000
function XGuildDormConfig.GetTemplateThemeConfigs()
    local list = {}
    for _, v in pairs(XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.Theme)) do
        if v.Id > 1000 then
            table.insert(list, v)
        end
    end
    return list
end

-- 当配置的有TimeId时 判断当前时间是否在开始时间之后
function XGuildDormConfig.GetShowThemeConfigs()
    local list = {}
    local configs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.Theme)
    for _, config in pairs(configs) do
        local timeId = config.TimeId
        if XTool.IsNumberValid(timeId) then
            local now = XTime.GetServerNowTimestamp()
            local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
            if startTime < now then
                table.insert(list, config)
            end
        else
            table.insert(list, config)
        end
    end
    return list
end

function XGuildDormConfig.GetLabelConfigById(id)
    return XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.ThemeLabel, id)
end

function XGuildDormConfig.GetFurnitureInteractBtnByGroupId(groupId)
    if XGuildDormConfig._GroupId2InteractBtn == nil then
        XGuildDormConfig._GroupId2InteractBtn = {}
        local configs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.GuildDormFurnitureInteractBtn)
        for _, v in pairs(configs) do
            XGuildDormConfig._GroupId2InteractBtn[v.GroupId] = XGuildDormConfig._GroupId2InteractBtn[v.GroupId] or {}
            table.insert(XGuildDormConfig._GroupId2InteractBtn[v.GroupId], v)
        end
    end

    return XGuildDormConfig._GroupId2InteractBtn[groupId]
end

function XGuildDormConfig.GetEffectCfgById(id)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormEffect, id)
    return config or {}
end

function XGuildDormConfig.GetFurnitureEffectCfgByGroupId(groupId)
    if XGuildDormConfig._GroupId2FurnitureEffect == nil then
        XGuildDormConfig._GroupId2FurnitureEffect = {}
        local configs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.GuildDormFurnitureEffect)
        for _, v in pairs(configs) do
            XGuildDormConfig._GroupId2FurnitureEffect[v.GroupId] = XGuildDormConfig._GroupId2FurnitureEffect[v.GroupId] or {}
            table.insert(XGuildDormConfig._GroupId2FurnitureEffect[v.GroupId], v)
        end
    end
    
    return XGuildDormConfig._GroupId2FurnitureEffect[groupId]
end

function XGuildDormConfig.GetIdleConfigById(id)
    return XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormNpcActionIdle,id)     
end 