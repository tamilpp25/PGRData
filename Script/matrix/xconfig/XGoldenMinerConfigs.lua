XGoldenMinerConfigs = XGoldenMinerConfigs or {}
local XGoldenMinerConfigs = XGoldenMinerConfigs

-- 配置表
local SHARE_TABLE_PATH = "Share/GoldenMiner/"
local CLIENT_TABLE_PATH = "Client/GoldenMiner/"

XGoldenMinerConfigs.Percent = 100

XGoldenMinerConfigs.CLIENT_RECORD_UI = {
    UI_STAGE = 1,
    UI_SHOP = 2,
}

XGoldenMinerConfigs.CLIENT_RECORD_ACTION = {
    SAVE_STAGE = 1,
    STAGE_PREVIEW = 2,
    SHIP_DETAIL = 3,
}

--抓取物类型
XGoldenMinerConfigs.StoneType = {
    Stone = 1,              --石头
    Gold = 2,               --黄金
    Diamond = 3,            --钻石
    Boom = 4,               --炸弹
    Mouse = 5,              --鼬鼠
    RedEnvelope = 6,        --红包箱
    AddTimeStone = 7,       --加时物品
    ItemStone = 8,          --道具(抓起来立刻使用)
    HookDirectionPoint = 9, --转向点(改变钩爪方向物体、不可被抓起)
    Mussel = 10,            --河蚌
    QTE = 11,               --QTE类型
}

--钩爪类型
XGoldenMinerConfigs.FalculaType = {
    Normal = 1,
    Magnetic = 2,           --电磁贯通
    Big = 3,                --大的钩爪
    AimingAngle = 4,        --自瞄角度
    StorePressMagnetic = 5, --长按电磁
    Double = 6,             --双头替身
}

--摄像机类型
XGoldenMinerConfigs.CameraType = {
    Main = 1,   --主界面
    Change = 2, --更换角色
}

XGoldenMinerConfigs.BuffType = {
    GoldenMinerInitItem = 1,        -- Skill-开局初始化xx类型xx个道具
    GoldenMinerInitScores = 2,      -- Skill-开具自带拥有xx积分
    GoldenMinerSkipDiscount = 3,    -- Shop-飞船打x折
    GoldenMinerStoneScore = 4,      -- All-抓取物获得的分数变为原本的 X 倍
    GoldenMinerShortenSpeed = 5,    -- All-钩爪拉回速度变为原本的 X 倍
    GoldenMinerBoom = 6,            -- Item-炸毁正在拉回的抓取物
    GoldenMinerShopDrop = 7,        -- Shop-额外刷新x个道具
    GoldenMinerShopDiscount = 8,    -- Shop-打x折
    GoldenMinerStoneChangeGold = 9, -- Item-正在拉回的物品变为同样重量的金块
    GoldenMinerMouseStop = 10,      -- Item-鼬鼠暂停移动X秒
    GoldenMinerNotActiveBoom = 11,  -- Item-下X次抓取不会触发爆破装置
    GoldenMinerHumanSpeed = 12,     -- Level-飞船移动速度变为原本的 X 倍
    GoldenMinerStretchSpeed = 13,   -- Level-钩爪发射速度变为原本的 X 倍
    GoldenMinerCordMode = 14,       -- Level-钩爪模式变更
    GoldenMinerAim = 15,            -- Level-钩爪增加额外瞄准红线
    GoldenMinerRandItem = 16,       -- Skill-回合开始随机增加道具
    GoldenMinerUseItemStopTime = 17,-- Skill-使用道具时时停
    GoldenMinerItemStopTime = 18,   -- Item-时停
    GoldenMinerInitAddTime = 19,    -- Skill-开局增加游戏时间
    GoldenMinerUseItemAddTime = 20, -- Skill-使用道具增加游戏时间
    GoldenMinerWeightFloat = 21,    -- Item-变化重量
    GoldenMinerTypeBoom = 22,       -- Item-炸某种类型的抓取物
    GoldenMinerValueFloat = 23,     -- Skill-每次夹物品价值变化
    GoldenMinerRoleHook = 24,       -- Skill-默认钩爪,优先级比14低
    GoldenMinerBoomGetScore = 25,   -- Skill-抓到或使用炸弹加分数(min ~ max)
    GoldenMinerMouseGetItem = 26,   -- Skill-抓到定春加道具(redEnvelopeRandPool GroupId)
    GoldenMinerQTEGetScore = 27,    -- Skill-QTE结束被抓取额外获得(min ~ max)%的分数
    GoldenMinerDefaultUpgrade = 28, -- Skill-默认升级项(后端buff)
}

XGoldenMinerConfigs.BuffDisplayType = {
    None = 0,
    Ship = 1,       -- 飞船(角色+升级)
    Item = 2,       -- 货舱(道具)
    Buff = 3,       -- 临时插件(buff)
}

XGoldenMinerConfigs.BuffTipType = {
    None = 0,
    Once = 1,       -- 3秒
    UntilDie = 2,   -- 直到BUff消失
}

XGoldenMinerConfigs.BuffTipStatus = {
    Alive = 1,
    Die = 2,
}

--道具状态改变类型
XGoldenMinerConfigs.ItemChangeType = {
    OnUse = 1,            --消耗
    OnGet = 2,            --获得
}

--道具类型
XGoldenMinerConfigs.ItemType = {
    NormalItem = 1,            --普通道具
    LiftTimeItem = 2,          --带有生存时间的道具，不可主动使用
}

--红包箱类型
XGoldenMinerConfigs.RedEnvelopeType = {
    Score = 1,
    Item = 2,
    MouseItem = 3
}

--表情配置的Id枚举
XGoldenMinerConfigs.FaceId = {
    RoleDefault = 1,        --默认表情（弃用）
    RoleStretch = 2,        --发射中表情
    RoleCantGrap = 3,       --抓不中表情
    RoleGrapBoom = 4,       --抓到炸弹表情
    RoleGraping1 = 5,       --抓取拉回表情1
    RoleGraping2 = 6,       --抓取拉回表情2
    RoleGraping3 = 7,       --抓取拉回表情3
    RoleGrapSuccess1 = 8,   --成功拉回表情1
    RoleGrapSuccess2 = 9,   --成功拉回表情2
    RoleGrapSuccess3 = 10,  --成功拉回表情3
    RoleGrapSuccess4 = 11,  --成功拉回表情4
    MouseDefault = 12,      --定春默认表情
    MouseBeGrap = 13,       --定春被抓住表情
    RoleUseBoom = 14,       --使用炸弹
    RoleUseBoomAfter = 15,  --使用炸弹后
    RoleUseShortenSpeed = 16,   --使用钩爪拉回速度变化的道具
    RoleUseStoneChangeGold1 = 17,    --使用变成黄金的道具1
    RoleUseStoneChangeGold2 = 18,    --使用变成黄金的道具2
    RoleUseMouseStop = 19,  --使用鼬鼠停止的道具
    RoleUseNotActiveBoom = 20,  --使用不激活炸弹的道具
    RoleUseAddTime = 21,        --使用增加时间道具
    RoleUseTimeStop = 22,       --使用时停道具
    RoleUseTypeBoom = 23,       --使用爆破某一类型道具
    RoleUseWeightFloat = 24,    --使用引力衰减道具
    RoleGrapAddTime = 25,       --拉回增加时间道具
    RoleGrapTimeStop = 26,      --拉回时停道具
    RoleGrapRedEnvelope = 27,   --拉回红包道具
}

--表情组枚举
XGoldenMinerConfigs.FaceGroup = {
    RoleGraping = 1,        --抓取拉回表情
    RoleGrapSuccess = 2,    --成功拉回表情
    RoleUseStoneChangeGold = 3, --使用变成黄金的道具
}

--飞船升级类型
XGoldenMinerConfigs.UpgradeType = {
    Level = 0,          --升级
    SameBuy = 1,        --同位购买
    SameReplace = 2,    --同位替换
}

--飞船外观
XGoldenMinerConfigs.ShipAppearanceKey = {
    DefaultShip = "DefaultShip",
    MaxSpeedShip = "MaxSpeedShip",
    MaxClampShip = "MaxClampShip",
    FinalShip = "FinalShip"
}

--飞船外观尺寸
XGoldenMinerConfigs.ShipAppearanceSizeKey = {
    DefaultShipSize = "DefaultShipSize",
    MaxSpeedShipSize = "MaxSpeedShipSize",
    MaxClampShipSize = "MaxClampShipSize",
    FinalShipSize = "FinalShipSize"
}

XGoldenMinerConfigs.QTEGroupType = {
    Score = 1,
    Buff = 2,
    Item = 3,
    ScoreAndBuff = 4,
    ScoreAndItem = 5,
    BuffAndItem = 6,
    All = 7,
}

XGoldenMinerConfigs.BuffTimeType = {
    Global = 1,
    Count = 2,
    Time = 3,
}

--抓取物运动轨迹类型
XGoldenMinerConfigs.StoneMoveType = {
    None = 0,       --静止
    Horizontal = 1, --左右直线
    Vertical = 2,   --上下直线
    Circle = 3,     --圆周
}

XGoldenMinerConfigs.HideTaskType = {
    GrabStone = 1,              -- 抓取到x个指定stoneId对象
    GrabStoneByOnce = 2,        -- 在一次出勾中抓取到x个指定stoneId对象
    GrabStoneInBuff = 3,        -- 在某个buff影响下抓取x个指定stoneId对象
    GrabStoneByReflection = 4,  -- 通过x个转向板反射抓取到地图上的一个指定stoneId对象
    GrabDrawMap = 5,            -- 通过抓取在地图画图
}

--region GameEnum
---播放气泡表情原因枚举
XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE = {
    NONE = 0,
    SHOOTING = 1,       -- 发射中表情
    REVOKING = 2,       -- 收回表情
    GRAB_STONE = 3,     -- 抓到抓取物
    GRAB_NONE = 4,      -- 什么都没抓到
    GRABBED = 5,        -- 成功收回表情
    USE_ITEM = 6,       -- 使用道具表情(只显示一种)
    USE_BY_WEIGHT = 7,  -- 使用道具表情(根据重量变化)
    USE_BY_SCORE = 8,   -- 使用道具表情(根据价值变化)
    QTE_START = 9,      -- QTE开始
    QTE_Click = 10,     -- QTE点击
    QTE_END = 11,       -- QTE结束
}

XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS = {
    NONE = 0,
    SHOOTING = 1,       -- 发射中表情
    REVOKING = 2,       -- 收回表情
}

XGoldenMinerConfigs.GAME_FACE_PLAY_ID = {
    SHOOTING = 2,       --发射中表情
    GRAB_NONE = 3,      --抓不中表情
    REVOKING = 5,       --抓取拉回表情1
    GRABBED = 8,        --成功拉回表情1
    QTE_START = 9,      -- QTE开始
    QTE_END = 11,       -- QTE结束
}

---游戏暂停原因枚举
XGoldenMinerConfigs.GAME_PAUSE_TYPE = {
    NONE = 0,
    PLAYER = 1 << 0,    -- 玩家手动暂停
    ITEM = 1 << 1,      -- 使用道具暂停
    AUTO = 1 << 2,      -- 自动暂停(进入游戏/关闭暂停弹窗)
}

XGoldenMinerConfigs.GAME_ANIM = {
    NONE = "None",
    HOOK_OPEN = "HookOpen",
    HOOK_CLOSE = "HookClose",
}

XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS = {
    NONE = 0,
    BE_ALIVE = 1,   -- 延迟出现
    ALIVE = 2,      -- 可被抓状态
    GRABBING = 3,   -- 被抓住
    GRABBED = 4,    -- 已被抓
    BE_DESTROY = 5, -- 将销毁(炸弹爆炸等)
    DESTROY = 6,    -- 被销毁(自动销毁、被炸弹炸等)
    HIDE = 7,       -- 隐藏状态(河蚌关闭、某种隐藏)
}

XGoldenMinerConfigs.GAME_EFFECT_TYPE = {
    STONE_BOOM = 1,     -- 炸弹爆炸
    TIME_STOP = 2,      -- 时停
    TIME_RESUME = 3,    -- 时停恢复
    GRAB_BOOM = 4,      -- 抓取爆炸
    TYPE_BOOM = 5,      -- 类型爆炸
    TO_GOLD = 6,        -- 点石成金
    GRAB = 7,           -- 被抓取
    WEIGHT_FLOAT = 8,   -- 重量浮动
    WEIGHT_RESUME = 9,  -- 重量浮动
    QTE_CLICK = 10,     -- QTE点击
    QTE_COMPLETE = 11,  -- QTE完成
}

XGoldenMinerConfigs.GAME_MOUSE_STATE = {
    NONE = 0,
    ALIVE = 1,          -- 跑动
    GRABBING = 2,       -- 被抓
    BOOM = 3,           -- 被炸
}

XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS = {
    NONE = 0,
    IDLE = 1,       -- 待使用
    USING = 2,      -- 使用中
}

XGoldenMinerConfigs.GAME_HOOK_STATUS = {
    NONE = 0,
    IDLE = 1,       -- 待发射
    READY = 2,      -- 按键 & 长按
    SHOOTING = 3,   -- 发射中
    GRABBING = 4,   -- 抓取中
    REVOKING = 5,   -- 收回中
    QTE = 6,        -- QTE
}

XGoldenMinerConfigs.GAME_BUFF_STATUS = {
    NONE = 0,
    ALIVE = 1,      -- 生效中
    BE_DIE = 2,     -- 待失效
    DIE = 3,        -- 已失效
}

XGoldenMinerConfigs.GAME_QTE_STATUS = {
    NONE = 0,
    ALIVE = 1,      -- 生效中
    WAIT = 2,       -- 点击冷却
    BE_DIE = 3,     -- 待失效
    DIE = 4,        -- 已失效
}

XGoldenMinerConfigs.GAME_MUSSEL_STATUS = {
    NONE = 0,
    OPEN = 1,       -- 生效中
    CLOSE = 2,      -- 点击冷却
}

XGoldenMinerConfigs.GAME_PC_KEY = {
    Space = 1,
    A = 2,
    D = 3,
    Q = 4,
    W = 5,
    E = 6,
    R = 7,
    T = 8,
}
--endregion

function XGoldenMinerConfigs.Init()
    XConfigCenter.CreateGetProperties(XGoldenMinerConfigs, {
        "GoldenMinerActivity",
        "GoldenMinerBuff",
        "GoldenMinerCharacter",
        "GoldenMinerItem",
        "GoldenMinerMap",
        "GoldenMinerStage",
        "GoldenMinerUpgrade",
        "GoldenMinerShopDrop",
        "GoldenMinerClientConfig",
        "GoldenMinerStone",
        "GoldenMinerStoneType",
        "GoldenMinerFalculaType",
        "GoldenMinerRedEnvelopeRandPool",
        "GoldenMinerFace",
        "GoldenMinerTask",
        "GoldenMinerUpgradeLocal",
        "GoldenMinerScore",
        -- 3.0 新增
        "GoldenMinerHideTask",
        "GoldenMinerHideTaskMapDrawGroup",
        "GoldenMinerQTELevelGroup",
    }, { 
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerActivity.tab", XTable.XTableGoldenMinerActivity, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerBuff.tab", XTable.XTableGoldenMinerBuff, "BuffId",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerCharacter.tab", XTable.XTableGoldenMinerCharacter, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerItem.tab", XTable.XTableGoldenMinerItem, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerMap.tab", XTable.XTableGoldenMinerMap, "MapId",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerStage.tab", XTable.XTableGoldenMinerStage, "StageId",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerUpgrade.tab", XTable.XTableGoldenMinerUpgrade, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerShopDrop.tab", XTable.XTableGoldenMinerShopDrop, "Id",
        "ReadByStringKey", CLIENT_TABLE_PATH .. "GoldenMinerClientConfig.tab", XTable.XTableGoldenMinerClientConfig, "Key",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerStone.tab", XTable.XTableGoldenMinerStone, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerStoneType.tab", XTable.XTableGoldenMinerStoneType, "Type",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerFalculaType.tab", XTable.XTableGoldenMinerFalculaType, "Type",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerRedEnvelopeRandPool.tab", XTable.XTableGoldenMinerRedEnvelopeRandPool, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerFace.tab", XTable.XTableGoldenMinerFace, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerTask.tab", XTable.XTableGoldenMinerTask, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerUpgradeLocal.tab", XTable.XTableGoldenMinerUpgradeLocal, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerScore.tab", XTable.XTableGoldenMinerScore, "Id",
        -- 3.0 新增
        "ReadByIntKey", SHARE_TABLE_PATH .. "GoldenMinerHideTask.tab", XTable.XTableGoldenMinerHideTask, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerHideTaskMapDrawGroup.tab", XTable.XTableGoldenMinerHideTaskMapDrawGroup, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "GoldenMinerQTELevelGroup.tab", XTable.XTableGoldenMinerQTELevelGroup, "Id",
    })
    
    XGoldenMinerConfigs._InitRedEnvelopePoolGroup()
    XGoldenMinerConfigs._InitHideTaskMapDrawGroup()
    XGoldenMinerConfigs._InitQTELevelGroupList()
end

function XGoldenMinerConfigs.DebugLog(content)
    XLog.Debug("黄金矿工Debug:" .. content)
end

function XGoldenMinerConfigs.DebugLogData(...)
    XLog.Debug("黄金矿工Debug:", ...)
end

--region Activity
function XGoldenMinerConfigs.GetActivityTimeId()
    local id = XDataCenter.GoldenMinerManager.GetCurActivityId()
    if not id then
        return 0
    end
    local config = XGoldenMinerConfigs.GetGoldenMinerActivity(id, true)
    return config.TimeId
end

function XGoldenMinerConfigs.GetActivityMaxItemColumnCount()
    local id = XDataCenter.GoldenMinerManager.GetCurActivityId()
    if not id then
        return 0
    end
    local config = XGoldenMinerConfigs.GetGoldenMinerActivity(id, true)
    return config.MaxItemColumnCount
end

function XGoldenMinerConfigs.GetActivityName()
    local id = XDataCenter.GoldenMinerManager.GetCurActivityId()
    if not id then
        return ""
    end
    local config = XGoldenMinerConfigs.GetGoldenMinerActivity(id, true)
    return config.Name
end

function XGoldenMinerConfigs.GetActivityBannerBg()
    local id = XDataCenter.GoldenMinerManager.GetCurActivityId()
    if not id then
        return ""
    end
    local config = XGoldenMinerConfigs.GetGoldenMinerActivity(id, true)
    return config.BannerBg
end

function XGoldenMinerConfigs.GetTotalHideStageCount()
    local id = XDataCenter.GoldenMinerManager.GetCurActivityId()
    if not id then
        return ""
    end
    local config = XGoldenMinerConfigs.GetGoldenMinerActivity(id, true)
    return config.TotalHideStageCount
end
--endregion

--region Buff
local IsInitGoldenMinerBuff = false
local _ShopGridLockCount = 0
local InitGoldenMinerBuffDic = function()
    if IsInitGoldenMinerBuff then
        return
    end

    local configs = XGoldenMinerConfigs.GetGoldenMinerBuff()
    for id, v in pairs(configs) do
        if v.BuffType == XGoldenMinerConfigs.BuffType.GoldenMinerShopDrop and v.Params[1] > _ShopGridLockCount then
            _ShopGridLockCount = v.Params[1]
        end
    end

    IsInitGoldenMinerBuff = true
end

--获得商店最大上锁数量
function XGoldenMinerConfigs.GetShopGridLockCount()
    InitGoldenMinerBuffDic()
    return _ShopGridLockCount
end

function XGoldenMinerConfigs.GetBuffType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config.BuffType
end

function XGoldenMinerConfigs.GetBuffParams(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config.Params
end

function XGoldenMinerConfigs.GetBuffTimeType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config.TimeType
end

function XGoldenMinerConfigs.GetBuffTimeTypeParam(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config.TimeTypeParam
end

function XGoldenMinerConfigs.GetBuffName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.Name or ""
end

function XGoldenMinerConfigs.GetBuffIcon(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.Icon or ""
end

function XGoldenMinerConfigs.GetBuffDesc(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.Desc
end

function XGoldenMinerConfigs.GetBuffDisplayType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.DisplayType
end

function XGoldenMinerConfigs.GetBuffDisplayPriority(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.DisplayPriority
end
--endregion

--region Character
local IsInitGoldenMinerCharacter = false
local GoldenMinerCharacterIdList = {}
local InitGoldenMinerCharacterDic = function()
    if IsInitGoldenMinerCharacter then
        return
    end

    local configs = XGoldenMinerConfigs.GetGoldenMinerCharacter()
    for id, v in pairs(configs) do
        table.insert(GoldenMinerCharacterIdList, id)
    end

    IsInitGoldenMinerCharacter = true
end

function XGoldenMinerConfigs.GetCharacterIdList()
    InitGoldenMinerCharacterDic()
    return GoldenMinerCharacterIdList
end

function XGoldenMinerConfigs.GetCharacterName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.Name
end

function XGoldenMinerConfigs.GetCharacterCondition(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.Condition
end

function XGoldenMinerConfigs.GetCharacterBuffIds(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.BuffIds
end

function XGoldenMinerConfigs.GetCharacterModelId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.ModelId
end

function XGoldenMinerConfigs.GetCharacterInfo(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.Info
end

function XGoldenMinerConfigs.GetCharacterHeadPath(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.HeadPath
end

function XGoldenMinerConfigs.GetCharacterSkillName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.SkillName
end

function XGoldenMinerConfigs.GetCharacterSkillDesc(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.SkillDesc
end

function XGoldenMinerConfigs.GetCharacterEnName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.EnName
end

function XGoldenMinerConfigs.GetCharacterDefaultFace(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerCharacter(id, true)
    return config.DefaultFace
end
--endregion

--region Item
function XGoldenMinerConfigs.GetItemName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.Name
end

function XGoldenMinerConfigs.GetItemDescribe(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.Describe
end

function XGoldenMinerConfigs.GetItemType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.ItemType
end

function XGoldenMinerConfigs.GetItemBuyCost(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.BuyCost
end

function XGoldenMinerConfigs.GetItemIcon(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.Icon
end

function XGoldenMinerConfigs.GetItemBuffId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.BuffId
end

function XGoldenMinerConfigs.GetItemUseSoundId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.UseSoundId
end

function XGoldenMinerConfigs.GetItemUseFaceId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.UseFaceId
end

function XGoldenMinerConfigs.GetItemSellPrice(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.SellPrice
end

function XGoldenMinerConfigs.GetItemTipsType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.TipsType
end

function XGoldenMinerConfigs.GetItemTipsTxt(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerItem(id, true)
    return config.TipsTxt
end
--endregion

--region Map
function XGoldenMinerConfigs.GetMapStoneId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    return config.StoneId
end

function XGoldenMinerConfigs.GetMapTime(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    return config.Time
end

function XGoldenMinerConfigs.GetMapTargetScore(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    return config.TargetScore
end

function XGoldenMinerConfigs.GetMapXPosPercent(id, index)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    local xPosPercent = config.XPosPercent
    return index and xPosPercent[index] or xPosPercent
end

function XGoldenMinerConfigs.GetMapYPosPercent(id, index)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    local yPosPercent = config.YPosPercent
    return index and yPosPercent[index] or yPosPercent
end

function XGoldenMinerConfigs.GetMapScale(id, index)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    local scale = config.Scale
    return index and scale[index] or scale
end

function XGoldenMinerConfigs.GetMapRotationZ(id, index)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    local rotationZ = config.RotationZ
    return index and rotationZ[index] or rotationZ
end

function XGoldenMinerConfigs.GetMapPreviewPic(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    return config.PreviewPic
end

function XGoldenMinerConfigs.GetMapHideTask(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerMap(id, true)
    return config.HideTask
end
--endregion

--region Stage
function XGoldenMinerConfigs.GetNextStage(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStage(id, true)
    return config.NextStage
end

function XGoldenMinerConfigs.GetStageShopGridCount(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStage(id, true)
    return config.ShopGridCount
end

function XGoldenMinerConfigs.GetStageTargetScore(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStage(id, true)
    return config.TargetScore
end

function XGoldenMinerConfigs.GetStageHideTaskFinishCount(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStage(id, true)
    return config.HideTaskFinishCount
end
--endregion

--region ClientConfig
function XGoldenMinerConfigs.GetHelpKey()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("HelpKey", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetMaxItemGridCount()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("MaxItemGridCount", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetScoreIcon()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ScoreIcon", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetUseItemCd()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("UseItemCd", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetRopeStretchSpeed()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("RopeStretchSpeed", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetRopeShortenSpeed()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("RopeShortenSpeed", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetHumenMoveSpeed()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("HumenMoveSpeed", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetRopeRockSpeed()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("RopeRockSpeed", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetUnlockRoleItemId()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("UnlockRoleItemId", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetRoleMoveRangePercent()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("RoleMoveRangePercent", true)
    return tonumber(config.Values[1]) / 100
end

function XGoldenMinerConfigs.GetGameNearEndTime()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("GameNearEndTime", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetGameStopCountdown()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("GameStopCountdown", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetShortenSpeedParameter()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ShortenSpeedParameter", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetShortenMinSpeed()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ShortenMinSpeed", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetRoleGrapSuccessTime()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("RoleGrapSuccessTime", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetUseItemSpeed()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("UseItemSpeed", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetUseBoomEffect()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("UseBoomEffect", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetWeightFloatEffect()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("WeightFloatEffect", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetStopTimeStartEffect()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("StopTimeStartEffect", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetStopTimeStopEffect()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("StopTimeStopEffect", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetFinalShipMaxCount()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("FinalShipMaxCount", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetShipImagePath(key)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig(key, true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetShipSize(key)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig(key, true)
    return tonumber(config.Values[1]), tonumber(config.Values[2])
end

function XGoldenMinerConfigs.GetAddScoreSound()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("AddScoreSound", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetStretchSound()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("StretchSound", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetShortenSound()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ShortenSound", true)
    return tonumber(config.Values[1])
end

-- 抓取物自动销毁爆炸特效
function XGoldenMinerConfigs.GetDestroyEffect()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("SelfDestroyEffect", true)
    return config.Values[1]
end

-- 2期超里大炮物品爆炸特效
function XGoldenMinerConfigs.GetTypeBoomEffect()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("TypeBoomEffect", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetTipAnimTime()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("TipAnimTime", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetTipAnimMoveLength()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("TipAnimMoveLength", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetHookIdleAngleRange()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("HookIdleAngleRange", true)
    return tonumber(config.Values[1]), tonumber(config.Values[2])
end

function XGoldenMinerConfigs.GetHookRopeExLength()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("HookRopeExLength", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetQTEWaitTime()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("QTEWaitTime", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetFaceEmojiShowTime()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("FaceEmojiShowTime", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetHookHitPointRevokeSpeed(hitCount)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("HookHitPointRevokeSpeed", true)
    if not XTool.IsNumberValid(hitCount) then
        hitCount = 1
    end
    if hitCount > #config.Values then
        hitCount = #config.Values
    end
    return tonumber(config.Values[hitCount])
end

---@return UnityEngine.Color
function XGoldenMinerConfigs.GetShopScoreChangeColor(isAdd)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ShopScoreChangeColorCode", true)
    return XUiHelper.Hexcolor2Color(config.Values[isAdd and 1 or 2])
end

---@return UnityEngine.Color
function XGoldenMinerConfigs.GetShopItemPriceColor(isCanBuy)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ShopItemPriceColor", true)
    return XUiHelper.Hexcolor2Color(config.Values[isCanBuy and 1 or 2])
end

function XGoldenMinerConfigs.GetMouseGrabOffset()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("MouseGrabOffset", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetNewMaxScoreSettleEmoji()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("NewMaxScoreSettleEmoji", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetSettleEmoji(isWin)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("SettleEmoji", true)
    return config.Values[isWin and 1 or 2]
end

function XGoldenMinerConfigs.GetTxtDisplayMainTitle(sortType)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("TxtDisplayMainTitle", true)
    return config.Values[sortType]
end

function XGoldenMinerConfigs.GetTxtDisplaySecondTitle(sortType)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("TxtDisplaySecondTitle", true)
    return config.Values[sortType]
end

function XGoldenMinerConfigs.GetGameScoreColorCode(isWin)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("GameScoreColorCode", true)
    return config.Values[isWin and 2 or 1]
end

---@return UnityEngine.Color
function XGoldenMinerConfigs.GetNewMaxScoreColor()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("NewMaxScoreColor", true)
    return XUiHelper.Hexcolor2Color(config.Values[1])
end

function XGoldenMinerConfigs.GetShopUpgradeBuyTxt(isReplace)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ShopUpgradeBuyTxt", true)
    return config.Values[isReplace and 2 or 1]
end

function XGoldenMinerConfigs.GetGameItemBgIcon(isHaveItem)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("GameItemBgIcon", true)
    return config.Values[isHaveItem and 2 or 1]
end

function XGoldenMinerConfigs.GetEffectPomegranateComplete()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("EffectPomegranateComplete", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetEffectPomegranateClick()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("EffectPomegranateClick", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetEffectCreateRecord()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("EffectCreateRecord", true)
    return config.Values[1]
end

function XGoldenMinerConfigs.GetReportShowHideTaskCount()
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("ReportShowHideTaskCount", true)
    return tonumber(config.Values[1])
end

function XGoldenMinerConfigs.GetBtnShootIconUrl(isQte)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("BtnShootIconUrl", true)
    return config.Values[isQte and 2 or 1]
end

function XGoldenMinerConfigs.GetGameWallExAreaValue(isWidth)
    local config = XGoldenMinerConfigs.GetGoldenMinerClientConfig("GameWallExArea", false)
    if not config then
        return 0
    end
    return config.Values[isWidth and 1 or 2]
end
--endregion

--region Stone 抓取物
local IsInitGoldenMinerStone = false
local _GoldWeightDic = {}    --黄金重量对应的Id字典
local InitGoldenMinerStone = function()
    if IsInitGoldenMinerStone then
        return
    end

    local configs = XGoldenMinerConfigs.GetGoldenMinerStone()
    for id, v in pairs(configs) do
        if v.Type == XGoldenMinerConfigs.StoneType.Gold then
            _GoldWeightDic[v.Weight] = id
        end
    end

    IsInitGoldenMinerStone = true
end

function XGoldenMinerConfigs.GetGoldIdByWeight(weight, id)
    InitGoldenMinerStone()
    if XGoldenMinerConfigs.GetStoneType(id) == XGoldenMinerConfigs.StoneType.Gold then
        return
    end

    return _GoldWeightDic[weight]
end

function XGoldenMinerConfigs.GetStoneScore(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.Score
end

function XGoldenMinerConfigs.GetStonePrefab(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.Prefab
end

function XGoldenMinerConfigs.GetStoneType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.Type
end

function XGoldenMinerConfigs.GetStoneMoveType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.MoveType
end

function XGoldenMinerConfigs.GetStoneStartMoveDirection(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.StartMoveDirection
end

function XGoldenMinerConfigs.GetStoneMoveRange(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.MoveRange
end

function XGoldenMinerConfigs.GetStoneMoveSpeed(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.MoveSpeed
end

function XGoldenMinerConfigs.GetStoneWeight(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.Weight
end

function XGoldenMinerConfigs.GetStoneBornDelay(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.BornDelay
end

function XGoldenMinerConfigs.GetStoneDestroyTime(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.DestoryTime
end

function XGoldenMinerConfigs.GetStoneCarryStoneId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.CarryStoneId
end

function XGoldenMinerConfigs.GetStoneCatchEffect(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.CatchEffect
end

function XGoldenMinerConfigs.GetStoneIsBoomDestroy(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return XTool.IsNumberValid(config.IsBoomDestroy)
end

function XGoldenMinerConfigs.GetStoneIntParams(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.IntParams
end

function XGoldenMinerConfigs.GetStoneFloatParams(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.FloatParams
end
--endregion

--region Upgrade
local IsInitGoldenMinerUpgrade = false
local _UpgradeIdList = {}
local InitGoldenMinerUpgrade = function()
    if IsInitGoldenMinerUpgrade then
        return
    end

    local configs = XGoldenMinerConfigs.GetGoldenMinerUpgrade()
    for id, v in pairs(configs) do
        table.insert(_UpgradeIdList, id)
    end

    IsInitGoldenMinerUpgrade = true
end

function XGoldenMinerConfigs.GetUpgradeIdList()
    InitGoldenMinerUpgrade()
    return _UpgradeIdList
end

function XGoldenMinerConfigs.GetUpgradeLocalIdIndex(id, localId)
    local upgradeLocalIdList = XGoldenMinerConfigs.GetUpgradeLocalIds(id)
    for i, upgradeLocalId in ipairs(upgradeLocalIdList) do
        if upgradeLocalId == localId then
            return i
        end
    end
end

function XGoldenMinerConfigs.GetUpgradeName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config.Name
end

function XGoldenMinerConfigs.GetUpgradeDescribe(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config.Describe
end

function XGoldenMinerConfigs.GetUpgradeCosts(id, index)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return index and config.UpgradeCosts[index]
end

function XGoldenMinerConfigs.GetUpgradeIcon(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config.Icon
end

function XGoldenMinerConfigs.GetUpgradeBuffId(id, index)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config and config.UpgradeBuffs[index] or 0
end

function XGoldenMinerConfigs.GetUpgradeLocalIds(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config.LocalIds
end

function XGoldenMinerConfigs.GetUpgradeType(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config.Type
end

function XGoldenMinerConfigs.GetUpgradeLvMaxShipKey(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return config.LvMaxShipKey
end

function XGoldenMinerConfigs.GetUpgradeIsOpen(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return XTool.IsNumberValid(config.IsOpen)
end

---获取升级数据字典(拆分钩子和其他)
function XGoldenMinerConfigs.GetUpgradeShowDataDir()
    local configs = XGoldenMinerConfigs.GetGoldenMinerUpgrade()
    local hookDir = {}
    local upDir = {}
    for _, config in pairs(configs) do
        if XTool.IsNumberValid(config.IsOpen) then
            for index, id in ipairs(config.LocalIds) do
                if XTool.IsNumberValid(config.Conditions[index])
                        and not XConditionManager.CheckCondition(config.Conditions[index]) then
                    goto continue
                end
                if config.Type == XGoldenMinerConfigs.UpgradeType.Level then
                    upDir[#upDir + 1] = id
                else
                    hookDir[#hookDir + 1] = id
                end
                ::continue::
            end
        end
    end
    return hookDir, upDir
end

function XGoldenMinerConfigs.GetUpgradeCondition(id, clientLevelIndex)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgrade(id, true)
    return clientLevelIndex and config.Conditions[clientLevelIndex]
end
--endregion

--region UpgradeLocal
local IsInitGoldenMinerUpgradeLocal = false
local _UpgradeLocalIdList = {}
local InitGoldenMinerUpgradeLocal = function()
    if IsInitGoldenMinerUpgradeLocal then
        return
    end

    local configs = XGoldenMinerConfigs.GetGoldenMinerUpgradeLocal()
    for id, v in pairs(configs) do
        table.insert(_UpgradeLocalIdList, id)
    end
    table.sort(_UpgradeLocalIdList, function(idA, idB)
        return idA < idB
    end)

    IsInitGoldenMinerUpgradeLocal = true
end

function XGoldenMinerConfigs.GetUpgradeLocalIdList()
    InitGoldenMinerUpgradeLocal()
    return _UpgradeLocalIdList
end

function XGoldenMinerConfigs.GetUpgradeId(upgradeLocalId)
    if not XTool.IsNumberValid(upgradeLocalId) then
        return
    end

    local upgradeIdList = XGoldenMinerConfigs.GetUpgradeIdList()
    for _, upgradeId in ipairs(upgradeIdList) do
        if XGoldenMinerConfigs.GetUpgradeIsOpen(upgradeId) then
            local upgradeLocalIds = XGoldenMinerConfigs.GetUpgradeLocalIds(upgradeId)
            for _, upgradeLocalIdTemp in ipairs(upgradeLocalIds) do
                if upgradeLocalIdTemp == upgradeLocalId then
                    return upgradeId
                end
            end
        end
    end
end

function XGoldenMinerConfigs.GetUpgradeLocalName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgradeLocal(id, true)
    return config.Name
end

function XGoldenMinerConfigs.GetUpgradeLocalDescribe(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgradeLocal(id, true)
    return config.Describe
end

function XGoldenMinerConfigs.GetUpgradeLocalIcon(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerUpgradeLocal(id, true)
    return config.Icon
end
--endregion

--region Hook
function XGoldenMinerConfigs.GetFalculaColliderName(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.ColliderName
end

function XGoldenMinerConfigs.GetFalculaOffsetX(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.OffsetXPercent / XGoldenMinerConfigs.Percent
end

function XGoldenMinerConfigs.GetFalculaOffsetY(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.OffsetYPercent / XGoldenMinerConfigs.Percent
end

function XGoldenMinerConfigs.GetFalculaRadius(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.RadiusPercent / XGoldenMinerConfigs.Percent
end

function XGoldenMinerConfigs.GetFalculaSizeX(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.SizeXPercent / XGoldenMinerConfigs.Percent
end

function XGoldenMinerConfigs.GetFalculaSizeY(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.SizeYPercent / XGoldenMinerConfigs.Percent
end

function XGoldenMinerConfigs.GetFalculaShipTip(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.ShipTip
end

function XGoldenMinerConfigs.GetFalculaButtonTip(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.ButtonTip
end

function XGoldenMinerConfigs.GetFalculaIgnoreTypeList(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerFalculaType(type, true)
    return config.IgnoreStoneTypeList
end
--endregion

--region RedEnvelopeRandPool
local RedEnvelopePoolGroup = {}

-- 红包池分组
function XGoldenMinerConfigs._InitRedEnvelopePoolGroup()
    for _, config in ipairs(XGoldenMinerConfigs.GetGoldenMinerRedEnvelopeRandPool()) do
        if XTool.IsTableEmpty(RedEnvelopePoolGroup[config.GroupId]) then
            RedEnvelopePoolGroup[config.GroupId] = {}
        end
        table.insert(RedEnvelopePoolGroup[config.GroupId], config)
    end
end

function XGoldenMinerConfigs.GetRedEnvelopeRandId(groupId)
    local configs = XGoldenMinerConfigs.GetGoldenMinerRedEnvelopeRandPool()
    if XTool.IsNumberValid(groupId) and not XTool.IsTableEmpty(RedEnvelopePoolGroup[groupId]) then
        local result = XTool.WeightRandomSelect(RedEnvelopePoolGroup[groupId], true)
        return result and result.Id or configs[1].Id
    end
    local config = XTool.WeightRandomSelect(configs, true)
    return config and config.Id or configs[1].Id
end

function XGoldenMinerConfigs.GetRedEnvelopeScore(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerRedEnvelopeRandPool(id, true)
    return config.Params[1]
end

function XGoldenMinerConfigs.GetRedEnvelopeItemId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerRedEnvelopeRandPool(id, true)
    return config.Params[2]
end

function XGoldenMinerConfigs.GetRedEnvelopeHeft(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerRedEnvelopeRandPool(id, true)
    return config.Heft
end
--endregion

--region Face
local IsInitGoldenMinerFace = false
local _FaceGroupDic = {}    --key：faceGroup，value：faceId
local InitGoldenMinerFace = function()
    if IsInitGoldenMinerFace then
        return
    end

    local configs = XGoldenMinerConfigs.GetGoldenMinerFace()
    for id, v in pairs(configs) do
        local faceGroup = v.FaceGroup
        if not XTool.IsNumberValid(faceGroup) then
            goto continue
        end
        if not _FaceGroupDic[faceGroup] then
            _FaceGroupDic[faceGroup] = {}
        end

        table.insert(_FaceGroupDic[faceGroup], id)
        :: continue ::
    end

    for _, idList in pairs(_FaceGroupDic) do
        table.sort(idList, function(idA, idB)
            local weightA = XGoldenMinerConfigs.GetFaceWeight(idA)
            local weightB = XGoldenMinerConfigs.GetFaceWeight(idB)
            if weightA ~= weightB then
                return weightA > weightB
            end

            local scoreA = XGoldenMinerConfigs.GetFaceScore(idA)
            local scoreB = XGoldenMinerConfigs.GetFaceScore(idB)
            if scoreA ~= scoreB then
                return scoreA > scoreB
            end
            return idA < idB
        end)
    end

    IsInitGoldenMinerFace = true
end

--获得表情图片
--value：groupId为1时传重量；groupId为2、3时传得分
function XGoldenMinerConfigs.GetFaceIdByGroup(groupId, value)
    InitGoldenMinerFace()
    local faceIdList = _FaceGroupDic[groupId]
    local weight
    local score
    for _, faceId in ipairs(faceIdList) do
        weight = XGoldenMinerConfigs.GetFaceWeight(faceId)
        score = XGoldenMinerConfigs.GetFaceScore(faceId)
        if (XTool.IsNumberValid(weight) and value >= weight) or
            (XTool.IsNumberValid(score) and value >= score) then
            return faceId
        end
    end

    return faceIdList[#faceIdList]
end

function XGoldenMinerConfigs.GetFaceImage(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerFace(id, true)
    return config.FaceImage
end

function XGoldenMinerConfigs.GetFaceWeight(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerFace(id, true)
    return config.Weight
end

function XGoldenMinerConfigs.GetFaceScore(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerFace(id, true)
    return config.Score
end

function XGoldenMinerConfigs.GetFaceGroup(faceId)
    local config = XGoldenMinerConfigs.GetGoldenMinerFace(faceId, true)
    return config.FaceGroup
end
--endregion

--region Task
function XGoldenMinerConfigs.GetTaskGroupIdList()
    local configs = XGoldenMinerConfigs.GetGoldenMinerTask()
    local taskGroupIdList = {}
    for id in pairs(configs) do
        table.insert(taskGroupIdList, id)
    end
    return taskGroupIdList
end

function XGoldenMinerConfigs.GetTaskIdList(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerTask(id, true)
    return config.TaskId
end

function XGoldenMinerConfigs.GetTaskName(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerTask(id, true)
    return config.Name
end
--endregion

--region HideTask
function XGoldenMinerConfigs.GetHideTaskName(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTask(id)
    return configs.Name
end

function XGoldenMinerConfigs.GetHideTaskDesc(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTask(id)
    return configs.Desc
end

function XGoldenMinerConfigs.GetHideTaskType(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTask(id)
    return configs.TaskType
end

function XGoldenMinerConfigs.GetHideTaskFinishProgress(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTask(id)
    return configs.FinishProgress
end

function XGoldenMinerConfigs.GetHideTaskParams(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTask(id)
    return configs.Params
end
--endregion

--region HideTaskMapDrawGroup
local _HideTaskMapDrawGroupDir = {}
function XGoldenMinerConfigs._InitHideTaskMapDrawGroup()
    for _, config in ipairs(XGoldenMinerConfigs.GetGoldenMinerHideTaskMapDrawGroup()) do
        if not _HideTaskMapDrawGroupDir[config.MapId] then
            _HideTaskMapDrawGroupDir[config.MapId] = {}
        end
        _HideTaskMapDrawGroupDir[config.MapId][#_HideTaskMapDrawGroupDir[config.MapId] + 1] = config.Id
    end
end

function XGoldenMinerConfigs.GetHideTaskMapDrawGroup(mapId)
    return _HideTaskMapDrawGroupDir[mapId]
end

function XGoldenMinerConfigs.GetHideTaskMapDrawGroupMapId(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTaskMapDrawGroup(id)
    return configs.MapId
end

function XGoldenMinerConfigs.GetHideTaskMapDrawGroupStoneIdIndex(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTaskMapDrawGroup(id)
    return configs.StoneIdIndex
end

---@return boolean
function XGoldenMinerConfigs.GetHideTaskMapDrawGroupIsStay(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerHideTaskMapDrawGroup(id)
    return XTool.IsNumberValid(configs.IsStay)
end
--endregion

--region QTELevelGroup
local _QTELevelGroupDir = {}
function XGoldenMinerConfigs._InitQTELevelGroupList()
    for _, config in ipairs(XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup()) do
        if not _QTELevelGroupDir[config.GroupId] then
            _QTELevelGroupDir[config.GroupId] = {}
        end
        _QTELevelGroupDir[config.GroupId][#_QTELevelGroupDir[config.GroupId] + 1] = config.Id
    end
end

function XGoldenMinerConfigs.GetQTELevelGroupByGroupId(groupId)
    return _QTELevelGroupDir[groupId]
end

function XGoldenMinerConfigs.GetQTELevelGroupMaxClickCount(groupId)
    local group = _QTELevelGroupDir[groupId]
    if XTool.IsTableEmpty(group) then
        return 0
    end
    return XGoldenMinerConfigs.GetQTELevelGroupClickCount(group[#group])
end

---@return number Id
function XGoldenMinerConfigs.GetQTELevelGroupByCount(groupId, count)
    local list = _QTELevelGroupDir[groupId]
    local result = false
    if XTool.IsTableEmpty(list) then
        XLog.Error("QTE组为空,GroupId = "..groupId.." Count = "..count)
        return result
    end
    if count == 0 then
        return list[1]
    end
    for _, id in ipairs(list) do
        if XGoldenMinerConfigs.GetQTELevelGroupClickCount(id) <= count then
            result = id
        end
    end
    return result
end

function XGoldenMinerConfigs.GetQTELevelGroupId(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.GroupId
end

function XGoldenMinerConfigs.GetQTELevelGroupType(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.Type
end

function XGoldenMinerConfigs.GetQTELevelGroupClickCount(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.ClickCount
end

function XGoldenMinerConfigs.GetQTELevelGroupIcon(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.Icon
end

function XGoldenMinerConfigs.GetQTELevelDownTime(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.DownTime
end

function XGoldenMinerConfigs.GetQTELevelSpeedRate(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.SpeedRate
end

function XGoldenMinerConfigs.GetQTELevelGroupParams(id)
    local configs = XGoldenMinerConfigs.GetGoldenMinerQTELevelGroup(id)
    return configs.Params
end
--endregion

--region Score
function XGoldenMinerConfigs.GetScoreGroupIdList()
    local configs = XGoldenMinerConfigs.GetGoldenMinerScore()
    local ScoreGroupIdList = {}
    for id in pairs(configs) do
        table.insert(ScoreGroupIdList, id)
    end
    return ScoreGroupIdList
end

function XGoldenMinerConfigs.GetLastTimeMax(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerScore(id, true)
    return config.LastTimeMax
end

function XGoldenMinerConfigs.GetPerTimePoint(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerScore(id, true)
    return config.Point
end
--endregion

--region StoneType
function XGoldenMinerConfigs.GetStoneTypeIcon(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerStoneType(type, true)
    return config.Icon
end

function XGoldenMinerConfigs.GetStoneTypeGrabFaceId(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerStoneType(type, true)
    return config.GrabFaceId
end
--endregion