XGoldenMinerConfigs = XGoldenMinerConfigs or {}

-- 配置表
local SHARE_TABLE_PATH = "Share/GoldenMiner/"
local CLIENT_TABLE_PATH = "Client/GoldenMiner/"

XGoldenMinerConfigs.Percent = 100

--抓取物类型
XGoldenMinerConfigs.StoneType = {
    Stone = 1,  --石头
    Gold = 2,   --黄金
    Diamond = 3, --钻石
    Boom = 4,   --炸弹
    Mouse = 5,  --鼬鼠
    RedEnvelope = 6, --红包箱
}

--钩爪类型
XGoldenMinerConfigs.FalculaType = {
    Normal = 1,
    Magnetic = 2,   --电磁贯通
    Big = 3,        --大的钩爪
}

--摄像机类型
XGoldenMinerConfigs.CameraType = {
    Main = 1,   --主界面
    Change = 2, --更换角色
}

XGoldenMinerConfigs.BuffType = {
    GoldenMinerInitItem = 1,        -- 开具初始化xx类型xx个道具
    GoldenMinerInitScores = 2,      -- 开具自带拥有xx积分
    GoldenMinerSkipDiscount = 3,    -- 飞船打x折
    GoldenMinerStoneScore = 4,      -- 抓取物获得的分数变为原本的 X 倍
    GoldenMinerShortenSpeed = 5,    -- 钩爪拉回速度变为原本的 X 倍
    GoldenMinerBoom = 6,            -- 炸毁正在拉回的抓取物
    GoldenMinerShopDrop = 7,        -- 商店额外刷新x个道具
    GoldenMinerShopDiscount = 8,    -- 商店打x折
    GoldenMinerStoneChangeGold = 9, -- 正在拉回的物品变为同样重量的金块
    GoldenMinerMouseStop = 10,      -- 鼬鼠暂停移动X秒
    GoldenMinerNotActiveBoom = 11,  -- 下X次抓取不会触发爆破装置
    GoldenMinerHumenSpeed = 12,     -- 飞船移动速度变为原本的 X 倍
    GoldenMinerStretchSpeed = 13,   -- 钩爪发射速度变为原本的 X 倍
    GoldenMinerCordMode = 14,       -- 钩爪模式变更
    GoldenMinerAim = 15,            -- 钩爪增加额外瞄准红线
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
    ScoreAndItem = 3
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
}

--表情组枚举
XGoldenMinerConfigs.FaceGroup = {
    RoleGraping = 1,        --抓取拉回表情
    RoleGrapSuccess = 2,    --成功拉回表情
    RoleUseStoneChangeGold = 3, --使用变成黄金的道具
}

--持续时间类型
XGoldenMinerConfigs.DurationTimeType = {
    NextStretch = 1,    --下一次发射操作
    NextStage = 2,      --下一关
    Forever = 3,        --永久
}

--飞船升级类型
XGoldenMinerConfigs.UpgradeType = {
    Falcula = 1,    --钩爪
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
    })
end

------------------GoldenMinerActivity begin----------------------
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
------------------GoldenMinerActivity end------------------------

------------------GoldenMinerBuff begin----------------------
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

function XGoldenMinerConfigs.GetBuffIcon(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.Icon or ""
end

function XGoldenMinerConfigs.GetBuffDesc(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerBuff(id, true)
    return config and config.Desc
end
------------------GoldenMinerBuff end------------------------

------------------GoldenMinerCharacter begin----------------------
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
------------------GoldenMinerCharacter end------------------------

------------------GoldenMinerItem begin----------------------
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
------------------GoldenMinerItem end------------------------

------------------GoldenMinerMap begin----------------------
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
------------------GoldenMinerMap end------------------------

------------------GoldenMinerStage begin----------------------
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
------------------GoldenMinerStage end------------------------

--------------------------GoldenMinerClientConfig begin------------------------
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
--------------------------GoldenMinerClientConfig end--------------------------

--------------------------GoldenMinerStone begin------------------------
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

function XGoldenMinerConfigs.GetStoneCarryStoneId(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.CarryStoneId
end

function XGoldenMinerConfigs.GetStoneCatchEffect(id)
    local config = XGoldenMinerConfigs.GetGoldenMinerStone(id, true)
    return config.CatchEffect
end
--------------------------GoldenMinerStone end--------------------------

--------------------------GoldenMinerUpgrade begin------------------------
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
--------------------------GoldenMinerUpgrade end--------------------------

--------------------------GoldenMinerUpgradeLocal begin--------------------------
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
        local upgradeLocalIds = XGoldenMinerConfigs.GetUpgradeLocalIds(upgradeId)
        for _, upgradeLocalIdTemp in ipairs(upgradeLocalIds) do
            if upgradeLocalIdTemp == upgradeLocalId then
                return upgradeId
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
--------------------------GoldenMinerUpgradeLocal end----------------------------

--------------------------GoldenMinerFalculaType begin--------------------
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
--------------------------GoldenMinerFalculaType end----------------------

--------------------------GoldenMinerRedEnvelopeRandPool begin--------------------
function XGoldenMinerConfigs.GetRedEnvelopeRandId()
    local configs = XGoldenMinerConfigs.GetGoldenMinerRedEnvelopeRandPool()
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
--------------------------GoldenMinerRedEnvelopeRandPool end----------------------

--------------------------GoldenMinerFace begin--------------------
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
--------------------------GoldenMinerFace end----------------------

--------------------------GoldenMinerTask begin----------------------
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
--------------------------GoldenMinerTask end------------------------

function XGoldenMinerConfigs.GetStoneTypeIcon(type)
    local config = XGoldenMinerConfigs.GetGoldenMinerStoneType(type, true)
    return config.Icon
end