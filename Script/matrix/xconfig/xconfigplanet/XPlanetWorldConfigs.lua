---行星环游记关卡内配置
XPlanetWorldConfigs = XPlanetWorldConfigs or {}
local XPlanetWorldConfigs = XPlanetWorldConfigs

local PLANET_CONFIGDIR = "Share/PlanetRunning/QPlanet/"
local STAGE_PLANET_NAME = "QPlanet"
local TALENT_PLANET_NAME = "QPlanetReform"
local TalentId = 1

---星球配置
---@type XConfig
local _ConfigChapter
---关卡星球配置表:地块 = 地板 + (建筑 or 角色)
---@type table<number, XConfig>
local _ConfigStagePlanet = {}
---天赋星球
---@type XConfig
local _ConfigTalentPlanet
---星球地板
---@type XConfig
local _ConfigMaterial
---星球建筑
---@type XConfig
local _ConfigBuilding
---星球道路
---@type XConfig
local _ConfigRoad
local _PlanetRoadDir = {}
local _PlanetRoadMap = {}
---星球角色
---@type XConfig
local _ConfigCharacter
---星球天气
---@type XConfig
local _ConfigWeather

---星球地块类型
XPlanetWorldConfigs.GridType = {
    None = 1,
    BuildingGrid = 2,
    RoadGrid = 3,
    BeginGrid = 4, 
}

---建筑类型
XPlanetWorldConfigs.BuildType = {
    StartBuild = 1,             -- 基地起点
    RoadCallMonsterBuild = 2,    -- 带召怪事件的建筑，会运行召怪检测逻辑，只能摆在路边
    BuffBuild = 3,              -- 随便摆的范围类BUFF建筑
    FloorBuild = 4,             -- 地块，随便摆的
    RoadBuild = 5,              -- 路边功能建筑，一般用于不带召怪但只能摆在路边的
}

---建筑占地类型
XPlanetWorldConfigs.GridOccupyType = {
    Occupy1 = 1,    -- 占地一格
    Occupy3 = 2,    -- 占地三格
    Occupy7 = 3,    -- 占地七格
}

---建筑效果范围类型
XPlanetWorldConfigs.RangeType = {
    Neighbor = 1,   -- 邻边一圈
    Global = 2,     -- 全局效果
}

function XPlanetWorldConfigs.Init()
    _ConfigChapter = XConfig.New("Share/PlanetRunning/PlanetRunningChapter.tab", XTable.XTablePlanetRunningChapter)

    _ConfigMaterial = XConfig.New("Share/PlanetRunning/PlanetRunningMaterial.tab", XTable.XTablePlanetRunningMaterial)
    _ConfigBuilding = XConfig.New("Share/PlanetRunning/PlanetRunningBuilding.tab", XTable.XTablePlanetRunningBuilding)
    _ConfigCharacter = XConfig.New("Share/PlanetRunning/PlanetRunningChapter.tab", XTable.XTablePlanetRunningCharacter)
    _ConfigWeather = XConfig.New("Share/PlanetRunning/PlanetRunningWeather.tab", XTable.XTablePlanetRunningWeather)

    _ConfigRoad = XConfig.New("Share/PlanetRunning/PlanetRunningRoad.tab", XTable.XTablePlanetRunningRoad)
    XPlanetWorldConfigs.InitPlanetRoadDir()

    XPlanetWorldConfigs.InitStagePlanetCfg()
    XPlanetWorldConfigs.InitTalentPlanetCfg()
end


--region _ConfigChapter 章节
function XPlanetWorldConfigs.GetChapterName(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "ChapterName")
end

function XPlanetWorldConfigs.GetChapterOpenTime(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "OpenTimeId")
end

function XPlanetWorldConfigs.GetChapterPreStageId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "PreStageId")
end
--endregion


--region 星球配置
---读取关卡星球配置
function XPlanetWorldConfigs.InitStagePlanetCfg()
    local stageIdList = XPlanetStageConfigs.GetStageIdList()
    for _, stageId in ipairs(stageIdList) do
        local path = PLANET_CONFIGDIR .. STAGE_PLANET_NAME .. stageId .. ".tab"
        if XTableManager.CheckTableExist(path) then
            _ConfigStagePlanet[stageId] = XConfig.New(path, XTable.XTablePlanetRunningGrid)
        else
            XLog.Error("XPlanetWorldConfigs.InitStagePlanetCfg 行星环游记关卡Id = " .. stageId .. "没有星球配置")
        end
    end
end

---@return XConfig
function XPlanetWorldConfigs.GetStagePlanetCfg(stageId)
    return _ConfigStagePlanet[stageId]
end

---读取关卡星球配置
function XPlanetWorldConfigs.InitTalentPlanetCfg()
    local path = PLANET_CONFIGDIR .. TALENT_PLANET_NAME .. ".tab"
    if XTableManager.CheckTableExist(path) then
        _ConfigTalentPlanet = XConfig.New(path, XTable.XTablePlanetRunningGrid)
    else
        XLog.Error("XPlanetWorldConfigs.InitTalentPlanetCfg 行星环游记关卡没有天赋星球(家园星球)配置")
    end
end

function XPlanetWorldConfigs.GetTalentPlanet()
    return _ConfigTalentPlanet
end

function XPlanetWorldConfigs.GetTalentStageId()
    return TalentId
end
--endregion


--region _ConfigBuilding 建筑
---建筑名称
function XPlanetWorldConfigs.GetBuildingName(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "Name")
end

function XPlanetWorldConfigs.GetBuildingBgDesc(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "BgDesc")
end

---建筑解锁前置关卡
function XPlanetWorldConfigs.GetBuildingUnlockStageId(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "UnlockStageId")
end

---建筑类型
---@return number XPlanetWorldConfigs.BuildType
function XPlanetWorldConfigs.GetBuildingBuildType(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "BuildType")
end

---建筑占地类型
---@return number XPlanetWorldConfigs.GridOccupyType
function XPlanetWorldConfigs.GetBuildingGridOccupyType(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "GridOccupyType")
end

---建筑效果范围
---@return number XPlanetWorldConfigs.RangeType
function XPlanetWorldConfigs.GetBuildingRangeType(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "RangeType")
end

---建筑可建造数量上限
---@return number,boolean 上限值和是否显示
function XPlanetWorldConfigs.GetBuildingLimitCount(buildingId, stageId)
    local default = _ConfigBuilding:GetProperty(buildingId, "BuildingCount")
    local limitNumStageIds = _ConfigBuilding:GetProperty(buildingId, "LimitNumStageIds")
    local limitNums = _ConfigBuilding:GetProperty(buildingId, "LimitNums")
    if not XTool.IsNumberValid(stageId) or XTool.IsTableEmpty(limitNumStageIds) then
        return default, XPlanetWorldConfigs.GetBuildingIsShowBuildingCount(buildingId)
    end
    for i, id in ipairs(limitNumStageIds) do
        if id == stageId then
            if XTool.IsNumberValid(limitNums[i]) then
                return limitNums[i], true
            else
                return default, XPlanetWorldConfigs.GetBuildingIsShowBuildingCount(buildingId)
            end
        end
    end
    return default, XPlanetWorldConfigs.GetBuildingIsShowBuildingCount(buildingId)
end

function XPlanetWorldConfigs.GetBuildingIsShowBuildingCount(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "IsShowBuildingCount")
end

---建筑消耗
---@return number
function XPlanetWorldConfigs.GetBuildingCast(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "Cast")
end

---建筑出售比例
---@return number
function XPlanetWorldConfigs.GetBuildingRecovery(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "Recovery")
end

---建筑是否可以出售
function XPlanetWorldConfigs.GetBuildingCanRecovery(buildingId)
    return XTool.IsNumberValid(_ConfigBuilding:GetProperty(buildingId, "CanRecovery"))
end

---建筑是否可以选择带入到场景中
function XPlanetWorldConfigs.GetBuildingCanSelect(buildingId)
    return XTool.IsNumberValid(_ConfigBuilding:GetProperty(buildingId, "CanSelect"))
end

---建筑每一圈提升的等级数
---@return number
function XPlanetWorldConfigs.GetBuildingCycleLevelUp(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "CycleLevelUp")
end

---建筑是否可批量建造
function XPlanetWorldConfigs.GetBuildingIsCanBatchBuild(buildingId)
    return XTool.IsNumberValid(_ConfigBuilding:GetProperty(buildingId, "BatchBuild"))
end

---建筑携带的事件
---@return number[]
function XPlanetWorldConfigs.GetBuildingEvents(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "Events")
end

---建筑携带的连携事件
---@return number
function XPlanetWorldConfigs.GetBuildingComboEvent(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "ComboEvent")
end

---建筑携带的默认地板
---@return number
function XPlanetWorldConfigs.GetBuildingFloorId(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "FloorId")
end

---地板型建筑需设置高度
---@return number
function XPlanetWorldConfigs.GetBuildingFloorHeight(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "FloorHeight")
end

---@return string
function XPlanetWorldConfigs.GetBuildingModelKey(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "ModelKey")
end

---@return string
function XPlanetWorldConfigs.GetBuildingIconUrl(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "Icon")
end

---@param buildType number XPlanetWorldConfigs.BuildType
---@return boolean
function XPlanetWorldConfigs.CheckBuildingIsType(buildingId, buildType)
    return XPlanetWorldConfigs.GetBuildingBuildType(buildingId) == buildType
end

function XPlanetWorldConfigs.CheckBuildingIsFloorType(buildingId)
    return XPlanetWorldConfigs.GetBuildingBuildType(buildingId) == XPlanetWorldConfigs.BuildType.FloorBuild
end

function XPlanetWorldConfigs.GetBuildingCanBring()
    local configs = _ConfigBuilding:GetConfigs()
    local result = {}
    for id, config in pairs(configs) do
        if config.CanSelect then
            result[#result + 1] = id
        end
    end
    return result
end

---建筑不可选择
---@return boolean
function XPlanetWorldConfigs.GetBuildingUnlockTimeId(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "UnlockTimeId")
end

---建筑不可选择
---@return boolean
function XPlanetWorldConfigs.GetBuildingIsCanSelect(buildingId)
    return _ConfigBuilding:GetProperty(buildingId, "CanSelect")
end
--endregion


--region _ConfigFloor 地板

---地板名称
function XPlanetWorldConfigs.GetFloorName(FloorId)
    return _ConfigMaterial:GetProperty(FloorId, "Name")
end

---地板高度
---@return number
function XPlanetWorldConfigs.GetFloorHeight(FloorId)
    return _ConfigMaterial:GetProperty(FloorId, "Height")
end

---地板材质资源url
---@return string
function XPlanetWorldConfigs.GetFloorMaterialUrl(FloorId)
    return _ConfigMaterial:GetProperty(FloorId, "MaterialUrl")
end

---@return string
function XPlanetWorldConfigs.GetFloorMaterialIcon(FloorId)
    return _ConfigMaterial:GetProperty(FloorId, "MaterialIcon")
end

---地板解锁前置关卡
---@return number
function XPlanetWorldConfigs.GetFloorPreStageId(FloorId)
    return _ConfigMaterial:GetProperty(FloorId, "UnlockStageId")
end

---地板是否是道路
function XPlanetWorldConfigs.GetFloorIsRoad(FloorId)
    return XTool.IsNumberValid(_ConfigMaterial:GetProperty(FloorId, "IsRoad"))
end
--endregion


--region _ConfigRoad 星球道路
---初始化星球道路字典
function XPlanetWorldConfigs.InitPlanetRoadDir()
    local configs = _ConfigRoad:GetConfigs()
    for i = 1, #configs do
        if XTool.IsTableEmpty(_PlanetRoadDir[configs[i].StageId]) then
            _PlanetRoadDir[configs[i].StageId] = {}
        end
        table.insert(_PlanetRoadDir[configs[i].StageId], configs[i].Id)
    end
    for stageId, roadIds in pairs(_PlanetRoadDir) do
        if XTool.IsTableEmpty(_PlanetRoadMap[stageId]) then
            _PlanetRoadMap[stageId] = {}
        end
        for _, id in ipairs(roadIds) do
            local startPoint = XPlanetWorldConfigs.GetRoadStartTileId(id)
            local endPoint = XPlanetWorldConfigs.GetRoadEndTileId(id)
            if XTool.IsTableEmpty(_PlanetRoadMap[stageId][startPoint]) then
                _PlanetRoadMap[stageId][startPoint] = {}
            end
            if XTool.IsTableEmpty(_PlanetRoadMap[stageId][endPoint]) then
                _PlanetRoadMap[stageId][endPoint] = {}
            end
            _PlanetRoadMap[stageId][startPoint]["NextPoint"] = endPoint
            _PlanetRoadMap[stageId][endPoint]["BeforePoint"] = startPoint
        end
    end
end

---获取星球路线网格图
function XPlanetWorldConfigs.GetPlanetRoadMap(StageId)
    if not XTool.IsNumberValid(StageId) then
        return {}
    end
    return _PlanetRoadMap[StageId]
end

---获取星球道路路径序列
---@return number[]
function XPlanetWorldConfigs.GetPlanetRoadConfig(StageId)
    return _PlanetRoadDir[StageId]
end

---道路线段起点Id
---@return number
function XPlanetWorldConfigs.GetRoadStartPointByStageId(stageId)
    local roadIds = XPlanetWorldConfigs.GetPlanetRoadConfig(stageId)
    for _, id in ipairs(roadIds) do
        if XPlanetWorldConfigs.GetRoadIsStart(id) then
            return XPlanetWorldConfigs.GetRoadStartTileId(id)
        end
    end
end

---道路线段起点
---@return number
function XPlanetWorldConfigs.GetRoadStartTileId(roadId)
    return _ConfigRoad:GetProperty(roadId, "StartTileId")
end

---道路线段终点
function XPlanetWorldConfigs.GetRoadEndTileId(roadId)
    return _ConfigRoad:GetProperty(roadId, "EndTileId")
end

---道路线段起点是否是道路起始点
function XPlanetWorldConfigs.GetRoadIsStart(roadId)
    return XTool.IsNumberValid(_ConfigRoad:GetProperty(roadId, "IsRoadStart"))
end
--endregion


--region _ConfigCharacter 角色
---@return string
function XPlanetWorldConfigs.GetCharacterName(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Name")
end

---角色排序优先级
---@return number
function XPlanetWorldConfigs.GetCharacterSorting(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Sorting")
end

---角色模型配置索引
---@return string
function XPlanetWorldConfigs.GetCharacterModelKey(characterId)
    return _ConfigCharacter:GetProperty(characterId, "MedelKey")
end

---角色全部属性Id
---@return number[]
function XPlanetWorldConfigs.GetCharacterAttributeIds(characterId)
    return _ConfigCharacter:GetProperty(characterId, "AttributeIds")
end

---角色全部属性值
---@return number[]
function XPlanetWorldConfigs.GetCharacterAttributeIds(characterId)
    return _ConfigCharacter:GetProperty(characterId, "AttributeValues")
end

---角色某个属性值
---@return number
function XPlanetWorldConfigs.GetCharacterAttributeIds(characterId, attributeId)
    local attributeValues = _ConfigCharacter:GetProperty(characterId, "AttributeValues")
    if XTool.IsNumberValid(attributeValues[attributeId]) then
        return attributeValues[attributeId]
    else
        return 0
    end
end
--endregion


--region _ConfigWeather 天气
function XPlanetWorldConfigs.GetWeatherIdList()
    local result = {}
    for _, config in ipairs(_ConfigWeather:GetConfigs()) do
        table.insert(result, config.Id)
    end
    return result
end

---@return string
function XPlanetWorldConfigs.GetWeatherName(weatherId)
    if not XTool.IsNumberValid(weatherId) then
        return XPlanetConfigs.GetWeatherNoneName()
    end
    return _ConfigWeather:GetProperty(weatherId, "Name")
end

---天气排序优先级
---@return number
function XPlanetWorldConfigs.GetWeatherOrder(weatherId)
    return _ConfigWeather:GetProperty(weatherId, "Order")
end

---天气解锁前置关卡
---@return number
function XPlanetWorldConfigs.GetWeatherUnlockStageId(weatherId)
    return _ConfigWeather:GetProperty(weatherId, "UnlockStageId")
end

---天气事件序列
---@return number[]
function XPlanetWorldConfigs.GetWeatherEvents(weatherId)
    return _ConfigWeather:GetProperty(weatherId, "Events")
end

---天气特效资源Url
---@return string
function XPlanetWorldConfigs.GetWeatherEffectUrl(weatherId)
    return _ConfigWeather:GetProperty(weatherId, "EffectUrl")
end

---天气图标资源Url
---@return string
function XPlanetWorldConfigs.GetWeatherIconUrl(weatherId)
    if not XTool.IsNumberValid(weatherId) then
        return XPlanetConfigs.GetWeatherNoneIcon()
    end
    return _ConfigWeather:GetProperty(weatherId, "IconUrl")
end

---@return string
function XPlanetWorldConfigs.GetWeatherBgUrl(weatherId)
    return _ConfigWeather:GetProperty(weatherId, "BgUrl")
end

---@return boolean
function XPlanetWorldConfigs.GetWeatherIsTalentShow(weatherId)
    return XTool.IsNumberValid(_ConfigWeather:GetProperty(weatherId, "IsTalentShow"))
end
--endregion