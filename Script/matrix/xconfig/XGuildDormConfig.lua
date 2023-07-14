--=================
--公会宿舍配置管理
--负责人：吕天元，陈思亮
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
}

XGuildDormConfig.ErrorCode = {
    Success = 0,
    PreEnterFailed = 1,
    TCPFailed = 2,
    EnterFailed = 3,
    KCPFailed = 4,
    PreEnterSuccess = 5,
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
})

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
    GuildDormRole = {}, -- 公会宿舍角色配置
    GuildDormRoleBehavior = {}, -- 公会宿舍角色行为树配置
    GuildDormPlayAction = {}, -- 公会宿舍角色动画配置
    GuildDormClientConfig = { DirType = XConfigCenter.DirectoryType.Client
    , ReadFuncName = "ReadByStringKey", ReadKeyName = "Key" },
    GuildDormConfig = {},
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
--=============
--额外初始化(没特殊处理时，这里只是用于给ConfigCenter调用的空方法)
--=============
function XGuildDormConfig.Init()

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