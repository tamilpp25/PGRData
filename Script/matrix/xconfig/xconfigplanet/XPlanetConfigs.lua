---行星环游记总控配置
XPlanetConfigs = XPlanetConfigs or {}
local XPlanetConfigs = XPlanetConfigs

---@type XConfig
local _ConfigActivity
---客户端参数配置
---@type XConfig
local _ConfigClient
---模型配置
---@type XConfig
local _ConfigModel

---地板效果材质
XPlanetConfigs.TileEffectMat = {
    TileSelectMat = "TileSelectMat",        ---地板选中材质
    TileCantBuildMat = "TileCantBuildMat",  ---地板不能建造材质
    TileNoneMat = "TileNoneMat",            ---空白地块材质
    TileNoneBuildMat = "TileNoneBuildMat",  ---空白地块建筑锁材质
    TileBuildRangeMat = "TileBuildRangeMat",---范围地块材质
}

---场景交互类型
XPlanetConfigs.SceneUiEventType = {
    OnClick = 1,        -- 点击
    OnPointerDown = 2,  -- 按下
    OnPointerUp = 3,    -- 抬起
    OnBeginDrag = 4,    -- 开始拖拽
    OnDrag = 5,         -- 拖拽中
    OnEndDrag = 6,      -- 结束拖拽
}

---场景相机模式
XPlanetConfigs.SceneCameraMode = {
    FreeMode = 1,       -- 自由模式(推拽转动相机)
    FollowMode = 2,     -- 跟随模式(跟随角色)
    StaticMode = 3,     -- 固定模式(外部场景镜头)
    MovieMode = 4,      -- 剧情模式(播放剧情)
}

XPlanetConfigs.SceneMode = {
    None = 1,           -- 自由模式(推拽转动相机)
    InBuild = 2,        -- 建造中
}

---天赋球地板型建筑建造模式
XPlanetConfigs.FloorBuildingBuildMode = {
    Point = 1,  -- 单个建造
    Cycle = 2,  -- 一圈建造
}

XPlanetConfigs.AirEffectType = {
    Normal = 1,
    Ice = 2,
    Desert = 3,
    Fire = 4,
    Candy = 5,
}

XPlanetConfigs.TipType = {
    Boss = 1,
    Monster = 2,
    BossBorn = 3,
    GameWin = 4,
    GameOver = 5,
    NewTalentBuildLimit = 6,
    NewBuild = 7,
    NewCharacter = 8,
}

---场景存在的原因
XPlanetConfigs.SceneOpenReason = {
    None = 0,
    UiPlanetLoading = 1 << 0,
    UiPlanetMain = 1 << 1,
    UiPlanetBattleMain = 1 << 2,
    UiPlanetChapter = 1 << 3,
}

XPlanetConfigs.SoundCueId = {
    CamNear = 2940,
    CamFar = 2941,
}

XPlanetConfigs.GuideTriggerType = {
    FirstGetMoney = 1,  -- 首次路过矿车
    FirstFight = 2,     -- 首次进入战斗
    FirstHunt = 3,      -- 首次掉血
    EnterMovie = 4,     -- 入场剧情结束 
}

function XPlanetConfigs.Init()
    --_ConfigActivity = XConfig.New("Share/PlanetRunning/PlanetRunningActivity.tab", XTable.XTablePlanetRunningActivity)
    --_ConfigClient = XConfig.New("Client/PlanetRunning/PlanetRunningClientCfg.tab", XTable.XTablePlanetRunningClientCfg, "Key")
    --_ConfigModel = XConfig.New("Client/PlanetRunning/PlanetRunningModelCfg.tab", XTable.XTablePlanetRunningModelCfg, "Key")
end


--region _ConfigClient 参数配置
function XPlanetConfigs.GetHelpKey()
    return _ConfigClient:GetProperty("HelpKey", "StringValues")[1]
end

---获取地板效果材质资源Url
---@param key XPlanetConfigs.TileEffectMat
---@return string
function XPlanetConfigs.GetTileEffectMat(key)
    return _ConfigClient:GetProperty(key, "StringValues")[1]
end

-- 气泡预置体
function XPlanetConfigs.GetUiPlanet2DObj()
    return _ConfigClient:GetProperty("UiPlanet2DObj", "StringValues")[1]
end

---默认星球预制体
function XPlanetConfigs.GetDefaultPlanetUrl()
    return _ConfigClient:GetProperty("DefaultPlanetUrl", "StringValues")[1]
end

---外部(天赋球)场景
function XPlanetConfigs.GetMainSceneUrl()
    return _ConfigClient:GetProperty("MainSceneUrl", "StringValues")[1]
end

function XPlanetConfigs.GetWeatherNoneIcon()
    return _ConfigClient:GetProperty("WeatherNoneIcon", "StringValues")[1]
end

function XPlanetConfigs.GetWeatherNoneName()
    return _ConfigClient:GetProperty("WeatherNoneName", "StringValues")[1]
end

function XPlanetConfigs.GetFirstOpenMovie()
    local config = _ConfigClient:GetConfigs()["FirstOpenMovie"]
    if not config then
        return false
    end
    return _ConfigClient:GetProperty("FirstOpenMovie", "StringValues")[1]
end

---@return Vector3
function XPlanetConfigs.GetPositionByKey(key)
    if XTool.IsTableEmpty(_ConfigClient:GetConfig(key)) then return Vector3.zero end
    local x = _ConfigClient:GetProperty(key, "FloatValues")[1]
    local y = _ConfigClient:GetProperty(key, "FloatValues")[2]
    local z = _ConfigClient:GetProperty(key, "FloatValues")[3]
    return Vector3(x, y, z)
end

---@return CS.UnityEngine.Quaternion
function XPlanetConfigs.GetRotationByKey(key)
    if XTool.IsTableEmpty(_ConfigClient:GetConfig(key)) then return CS.UnityEngine.Quaternion.identity end
    local x = _ConfigClient:GetProperty(key, "FloatValues")[1]
    local y = _ConfigClient:GetProperty(key, "FloatValues")[2]
    local z = _ConfigClient:GetProperty(key, "FloatValues")[3]
    return CS.UnityEngine.Quaternion.Euler(Vector3(x, y, z))
end

function XPlanetConfigs.GetCamRotationSpeed()
    return _ConfigClient:GetProperty("CamRotationSpeed", "FloatValues")[1]
end

---章节球坐标偏移
function XPlanetConfigs.GetCamChapterXOffset()
    return _ConfigClient:GetProperty("CamChapterXOffset", "FloatValues")[1]
end

---@param mode XPlanetConfigs.ReformFloorBuildMode
---@return string
function XPlanetConfigs.GetReformFloorBuildModeIcon(mode)
    return _ConfigClient:GetProperty("ReformFloorBuildModeIcon", "StringValues")[mode]
end

---战斗伤害数字色号
function XPlanetConfigs.GetBattleDemageTxtColor()
    return _ConfigClient:GetProperty("BattleDemageTxtColor", "Values")[1]
end

---@return string
function XPlanetConfigs.GetMainMeteorEffect()
    return _ConfigClient:GetProperty("MainMeteorEffect", "StringValues")[1]
end

---@return number
function XPlanetConfigs.GetMainAirEffectChapterUse()
    return _ConfigClient:GetProperty("MainAirEffectChapterUse", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetMainCharacterMaxCount()
    return _ConfigClient:GetProperty("MainCharacterMaxCount", "IntValues")[1]
end

---章节球未解锁状态渲染灰度
---@return number
function XPlanetConfigs.GetChapterPlanetLockGray()
    return _ConfigClient:GetProperty("ChapterPlanetLockGray", "FloatValues")[1]
end

---章节球未解锁状态渲染Color
---@return string
function XPlanetConfigs.GetChapterPlanetLockColorCode()
    return _ConfigClient:GetProperty("ChapterPlanetLockColorCode", "StringValues")[1]
end

---地板空状态渲染灰度
---@return number
function XPlanetConfigs.GetNoneTileRendererGray()
    return _ConfigClient:GetProperty("NoneTileRendererGray", "FloatValues")[1]
end

---地板空状态渲染Color
---@return string
function XPlanetConfigs.GetNoneTileRendererColorCode()
    return _ConfigClient:GetProperty("NoneTileRendererColorCode", "StringValues")[1]
end

---@return number
function XPlanetConfigs.GetMainAirEffectChapterUse()
    return _ConfigClient:GetProperty("MainAirEffectChapterUse", "IntValues")[1]
end

function XPlanetConfigs.GetBuildCardAlpha()
    return _ConfigClient:GetProperty("BuildCardAlpha", "FloatValues")[1]
end

function XPlanetConfigs.GetBuildCardScale()
    return _ConfigClient:GetProperty("BuildCardScale", "FloatValues")[1]
end

function XPlanetConfigs.GetCamChapterXOffset()
    return _ConfigClient:GetProperty("CamChapterXOffset", "FloatValues")[1]
end

---场景镜头预制体
---@return string
function XPlanetConfigs.GetCamPrefab()
    return _ConfigClient:GetProperty("CamPrefab", "StringValues")[1]
end

---@return number
function XPlanetConfigs.GetCamMain()
    return _ConfigClient:GetProperty("CamMain", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamFollowRole()
    return _ConfigClient:GetProperty("CamFollowRole", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamBuildMax()
    return _ConfigClient:GetProperty("CamBuildMax", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamBuildMin()
    return _ConfigClient:GetProperty("CamBuildMin", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamChapter()
    return _ConfigClient:GetProperty("CamChapter", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamStageChoose()
    return _ConfigClient:GetProperty("CamStageChoise", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamStageOver()
    return _ConfigClient:GetProperty("CamStageOver", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamStageMovie()
    return _ConfigClient:GetProperty("CamStageMovie", "IntValues")[1]
end

---@return number
function XPlanetConfigs.GetCamStageBoss()
    return _ConfigClient:GetProperty("CamStageBoss", "FloatValues")[1] or 0
end

---@return number
function XPlanetConfigs.GetTalentUnLockStage()
    return _ConfigClient:GetProperty("TalentUnLockStage", "IntValues")[1]
end

---建造特效
---@return string
function XPlanetConfigs.GetBuildEffect()
    return _ConfigClient:GetProperty("BuildEffect", "StringValues")[1]
end

---@return UnityEngine.Color
function XPlanetConfigs.GetMoneyChangeColor(deltaCount)
    local index = deltaCount > 0 and 1 or 2
    return XUiHelper.Hexcolor2Color(_ConfigClient:GetProperty("MoneyColorHex", "StringValues")[index])
end

---@return Vector3
function XPlanetConfigs.GetBuildCardOffset()
    local x = _ConfigClient:GetProperty("BuildCardOffset", "FloatValues")[1]
    local y = _ConfigClient:GetProperty("BuildCardOffset", "FloatValues")[2]
    local z = _ConfigClient:GetProperty("BuildCardOffset", "FloatValues")[3]
    return Vector3(x, y ,z)
end

---@return string
function XPlanetConfigs.GetMainAirEffectNodeName(chapterId)
    if chapterId == XPlanetConfigs.AirEffectType.Ice then
        return "Scene03604b"
    elseif chapterId == XPlanetConfigs.AirEffectType.Desert then
        return "Scene03604a"
    elseif chapterId == XPlanetConfigs.AirEffectType.Fire then
        return "Scene03604c"
    elseif chapterId == XPlanetConfigs.AirEffectType.Candy then
        return "Scene03604d"
    else
        return "Scene03604"
    end
end

function XPlanetConfigs.GetEffectChangeRole()
    local path = _ConfigClient:GetProperty("EffectChangeRole", "StringValues")[1]
    return path
end

---星球选择速度(弧度)
---@return number
function XPlanetConfigs.GetPlanetRotateSpeed()
    if not _ConfigClient:GetConfigs()["PlanetRotateParams"] then
        return 1
    end
    return _ConfigClient:GetProperty("PlanetRotateParams", "FloatValues")[1]
end

---星球旋转惯性降速速率
---@return number
function XPlanetConfigs.GetPlanetRotateReduction()
    if not _ConfigClient:GetConfigs()["PlanetRotateParams"] then
        return 20
    end
    return _ConfigClient:GetProperty("PlanetRotateParams", "FloatValues")[2]
end

function XPlanetConfigs.GetPlanetMoneyBubbleId()
    if not _ConfigClient:GetConfigs()["MoneyEffectId"] then
        return false
    end
    return _ConfigClient:GetProperty("MoneyEffectId", "IntValues")[1]
end

function XPlanetConfigs.GetSkipFightBubble()
    return _ConfigClient:GetProperty("BubbleFight", "IntValues")[1]
end

function XPlanetConfigs.GetSkipFightBubbleSeckill()
    return _ConfigClient:GetProperty("BubbleFightSeckill", "IntValues")[1]
end
--endregion


--region 引导配置
function XPlanetConfigs.GetGuideDragBuildCardList()
    if not _ConfigClient:GetConfigs()["DragBuildCardList"] then
        return {}
    end
    return _ConfigClient:GetProperty("DragBuildCardList", "IntValues")
end

function XPlanetConfigs.GetGuideCardClickCount(stageId, index)
    if not XTool.IsNumberValid(stageId) or not _ConfigClient:GetConfigs()["GuideStageClickCardToDragList"] then
        return 1
    end
    local ClickCountList
    for i, id in ipairs(_ConfigClient:GetProperty("GuideStageClickCardToDragList", "IntValues")) do
        if id == stageId then
            local key = _ConfigClient:GetProperty("GuideStageClickCardToDragList", "StringValues")[i]
            ClickCountList = _ConfigClient:GetProperty(key, "IntValues")
        end
    end
    if XTool.IsTableEmpty(ClickCountList) then
        return 1
    end
    return ClickCountList[index]
end

function XPlanetConfigs.GetGuideStageClickCardToDragList()
    return _ConfigClient:GetProperty("GuideStageClickCardToDragList", "IntValues")
end

function XPlanetConfigs._GetGuideStageTile(stageId, index)
    if not XTool.IsNumberValid(stageId) or not _ConfigClient:GetConfigs()["GuideGuideStageTileList"] then
        return false
    end
    local tileList
    for i, id in ipairs(_ConfigClient:GetProperty("GuideGuideStageTileList", "IntValues")) do
        if id == stageId then
            local key = _ConfigClient:GetProperty("GuideGuideStageTileList", "StringValues")[i]
            tileList = _ConfigClient:GetProperty(key, "IntValues")
        end
    end
    if XTool.IsTableEmpty(tileList) then
        return false
    end
    return tileList[index]
end

---引导关独有镜头角度
function XPlanetConfigs.GetGuideCamRootRotOffset(stageId)
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    if stageId == XPlanetConfigs._GetGuideFirstCamRootRotOffsetStageId() then
        return XPlanetConfigs.GetRotationByKey("GuideFirstCamRootOffset")
    end
    if stageId == XPlanetConfigs._GetGuideSecondCamRootRotOffsetStageId() then
        return XPlanetConfigs.GetRotationByKey("GuideSecondCamRootOffset")
    end
    return false
end

function XPlanetConfigs._GetGuideFirstCamRootRotOffsetStageId()
    if not _ConfigClient:GetConfigs()["GuideFirstCamRootOffset"] then
        return 0
    end
    return _ConfigClient:GetProperty("GuideFirstCamRootOffset", "IntValues")[1]
end

function XPlanetConfigs._GetGuideSecondCamRootRotOffsetStageId()
    if not _ConfigClient:GetConfigs()["GuideSecondCamRootOffset"] then
        return 0
    end
    return _ConfigClient:GetProperty("GuideSecondCamRootOffset", "IntValues")[1]
end
--endregion


--region _ConfigActivity 总控配置
function XPlanetConfigs.GetActivityTimeId(activityId)
    return _ConfigActivity:GetProperty(activityId, "TimeId")
end

function XPlanetConfigs.GetActivityName(activityId)
    return _ConfigActivity:GetProperty(activityId, "Name")
end

function XPlanetConfigs.GetActivityInitCharacterId(activityId)
    return _ConfigActivity:GetProperty(activityId, "InitCharacterId")
end

function XPlanetConfigs.GetActivityTalentPlanetId(activityId)
    return _ConfigActivity:GetProperty(activityId, "TalentPlanetId")
end

function XPlanetConfigs.GetActivityTimeLimitTaskId(activityId)
    return _ConfigActivity:GetProperty(activityId, "TimeLimitTaskId")
end

function XPlanetConfigs.GetActivityShopIdList(activityId)
    return _ConfigActivity:GetProperty(activityId, "ShopIdList")
end

function XPlanetConfigs.CheckInTime(activityId, defaultOpen)
    return XFunctionManager.CheckInTimeByTimeId(XPlanetConfigs.GetActivityTimeId(activityId), defaultOpen)
end
--endregion


--region _ConfigModel 模型配置
---模型资源Url
---@return string
function XPlanetConfigs.GetModelResUrl(key)
    return _ConfigModel:GetProperty(key, "ResUrl")
end

---模型大小
---@return Vector3
function XPlanetConfigs.GetModelScale(key)
    local scale = _ConfigModel:GetProperty(key, "Scale")
    if XTool.IsTableEmpty(scale) then
        return Vector3.zero
    end
    return Vector3(scale[1], scale[2], scale[3])
end
--endregion