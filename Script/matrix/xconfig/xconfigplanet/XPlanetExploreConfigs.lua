XPlanetExploreConfigs = XPlanetExploreConfigs or {}
local XPlanetExploreConfigs = XPlanetExploreConfigs


--region 回合制
XPlanetExploreConfigs.ATTACK_STATUS = {
    NONE = 0,
    MOVE_PREPARE = 1,
    MOVE_FORWARD = 2,
    ANIMATION = 3,
    MOVE_BACKWARD = 4,
    END = 5,
}
--endregion


--region Explore
XPlanetExploreConfigs.CAMP = {
    NONE = 0,
    PLAYER = 1,
    BOSS = 2,
    MOVIE = 3,
    LEADER = 99,
}

XPlanetExploreConfigs.MOVE_STATUS = {
    NONE = 0,
    START = 1,
    WALK = 2,
    END = 3,
    IDLE = 4,
    SIZE = 5, -- 状态数量
}

XPlanetExploreConfigs.SETTLE_TYPE = {
    None = 0,
    Win = 1,
    Lose = 2,
    Quit = 3,
    StageFinish = 4,
}

XPlanetExploreConfigs.PAUSE_REASON = {
    NONE = 0,
    FIGHT = 1 << 0,
    PLAYER = 1 << 1,
    BUILD = 1 << 2,
    TALENT = 1 << 3,
    FOLLOW = 1 << 4,
    DETAIL = 1 << 5,
    ITEM = 1 << 6,
    RESULT = 1 << 7,
    MOVIE = 1 << 8,
    CAMERA = 1 << 9,
    GUIDE = 1 << 10,
}

XPlanetExploreConfigs.ACTION = {
    None = "None",
    STAND = "Stand02",
    WALK = "Walk01",
    SKIP_FIGHT = "StandReward01",
    RUN = "Run01",
    FAIL = "Stand03",
    WIN = "Victory01",
}
XPlanetExploreConfigs.TIME_SCALE = {
    NORMAL = 2,
    X2 = 3,
}
XPlanetExploreConfigs.TIME_SCALE_FIGHT = {
    NORMAL = 1,
    X2 = 2,
}

XPlanetExploreConfigs.MOVIE_CONDITION = {
    ENTER_STAGE = 1, -- 进入战斗
    BOSS_FIGHT = 2, -- 撞Boss战斗前
    SETTLE_WIN = 3, -- 结算前胜利
    SETTLE_FAIL = 4, -- 结算前失败
}

--endregion

---@type XConfig
local _ConfigFightingPower

---@type XConfig
local _ConfigTarget
local _ConfigBubbleResource
local _ConfigBubbleController
---@type XConfig
local _ConfigMovieContent
local _ConfigMovieController

local MovieIdCfgDic = {} -- key = movieId , value = { [1] = {text, name}, [2] = {text, name}, ...}

function XPlanetExploreConfigs.Init()
    _ConfigFightingPower = XConfig.New("Share/PlanetRunning/PlanetRunningFightingPower.tab", XTable.XTablePlanetRunningFightingPower, "StageId")
    _ConfigTarget = XConfig.New("Client/PlanetRunning/PlanetRunningTarget.tab", XTable.XTablePlanetRunningTarget)
    _ConfigBubbleResource = XConfig.New("Client/PlanetRunning/PlanetRunningBubbleResource.tab", XTable.XTablePlanetRunningBubbleResource)
    _ConfigBubbleController = XConfig.New("Client/PlanetRunning/PlanetRunningBubbleController.tab", XTable.XTablePlanetRunningBubbleController)
    _ConfigMovieContent = XConfig.New("Client/PlanetRunning/PlanetRunningMovieContent.tab", XTable.XTablePlanetRunningMovieContent)
    _ConfigMovieController = XConfig.New("Client/PlanetRunning/PlanetRunningMovieController.tab", XTable.XTablePlanetRunningMovieController)
    XPlanetExploreConfigs.InitMovieIdCfgDic()
end

---@param entity XPlanetRunningExploreEntity
function XPlanetExploreConfigs.GetFightingPower(entity)
    local ATTR = XPlanetCharacterConfigs.ATTR
    local attrList = {
        [ATTR.MaxLife] = entity.Attr.MaxLife,
        [ATTR.Defense] = entity.Attr.Defense,
        [ATTR.Attack] = entity.Attr.Attack,
        [ATTR.CriticalChance] = entity.Attr.CriticalPercent,
        [ATTR.CriticalDamage] = entity.Attr.CriticalDamageAdded,
        [ATTR.AttackSpeed] = entity.Attr.Speed,
    }

    local value = XPlanetExploreConfigs.GetFightingPowerByAttrList(attrList)
    return value
end

function XPlanetExploreConfigs.GetFightingPowerByAttrList(attrList)
    local ATTR = XPlanetCharacterConfigs.ATTR
    local life = attrList[ATTR.MaxLife] or 0
    local attack = attrList[ATTR.Attack] or 0
    local criticalPercent = attrList[ATTR.CriticalChance] or 0
    local criticalDamageAdded = attrList[ATTR.CriticalDamage] or 0
    local speed = attrList[ATTR.AttackSpeed] or 0
    local ratioPercent = 10000
    local fightPower = attack * life *
            (1 + (criticalDamageAdded / ratioPercent) * (criticalPercent / ratioPercent)) *
            (speed / ratioPercent + 1) / 20;
    return math.floor(fightPower)
end

---@param entities XPlanetRunningExploreEntity[]
function XPlanetExploreConfigs.GetPlayerFightingPower(entities)
    local value = 0
    for i = 1, #entities do
        local entity = entities[i]
        value = value + XPlanetExploreConfigs.GetFightingPower(entity)
    end
    return value
end

function XPlanetExploreConfigs.GetTarget(stageId)
    local targetGroupId = XPlanetStageConfigs.GetStageTargetGroupId(stageId)
    local result = {}
    for i, config in pairs(_ConfigTarget:GetConfigs()) do
        if config.GroupId == targetGroupId then
            result[#result + 1] = config
        end
    end
    return result
end

function XPlanetExploreConfigs.GetBubbleRes(bubbleId)
    return _ConfigBubbleResource:GetConfig(bubbleId)
end

function XPlanetExploreConfigs.GetBubbleController(bubbleControllerId)
    return _ConfigBubbleController:GetConfig(bubbleControllerId)
end

function XPlanetExploreConfigs.InitMovieIdCfgDic()
    for k, v in ipairs(_ConfigMovieContent:GetConfigs()) do
        if XTool.IsTableEmpty(MovieIdCfgDic[v.MovieId]) then
            MovieIdCfgDic[v.MovieId] = {}
        end
        table.insert(MovieIdCfgDic[v.MovieId], v)
    end
end

function XPlanetExploreConfigs.GetMovieInfoById(movieId)
    return MovieIdCfgDic[movieId]
end

function XPlanetExploreConfigs.GetMovieIdByCheckControllerStage(condition, stageId)
    for i, v in ipairs(_ConfigMovieController:GetConfigs()) do
        if v.StageId == stageId then
            if v.Condition and v.Condition == condition then
                return v.MovieId
            end
        end
    end
    return nil
end

function XPlanetExploreConfigs.GetMovieIdByCheckControllerBoss(condition, stageId, bossId)
    for i, v in ipairs(_ConfigMovieController:GetConfigs()) do
        if v.BossId == bossId and v.StageId == stageId then
            if v.Condition and v.Condition == condition then
                return v.MovieId
            end
        end
    end
    return nil
end