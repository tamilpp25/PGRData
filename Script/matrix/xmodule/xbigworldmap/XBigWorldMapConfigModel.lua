---@class XBigWorldMapConfigModel : XModel
local XBigWorldMapConfigModel = XClass(XModel, "XBigWorldMapConfigModel")

local MapTableKey = {
    BigWorldMap = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "LevelId",
    },
    BigWorldMapAreaGroup = {
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "GroupId",
    },
    BigWorldMapArea = {
        Identifier = "AreaId",
    },
    BigWorldMapPinStyle = {
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "StyleId",
    },
    BigWorldMapQuestPin = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "QuestId",
    },
    BigWorldMapLink = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "LevelId",
    },
}

function XBigWorldMapConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Map", MapTableKey)
end

---@return XTableBigWorldMap[]
function XBigWorldMapConfigModel:GetBigWorldMapConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMap)
end

---@return XTableBigWorldMap
function XBigWorldMapConfigModel:GetBigWorldMapConfigByLevelId(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMap, levelId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapPosXByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.PosX
end

function XBigWorldMapConfigModel:GetBigWorldMapPosZByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.PosZ
end

function XBigWorldMapConfigModel:GetBigWorldMapPixelRatioByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.PixelRatio
end

function XBigWorldMapConfigModel:GetBigWorldMapWidthByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.Width
end

function XBigWorldMapConfigModel:GetBigWorldMapHeightByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.Height
end

function XBigWorldMapConfigModel:GetBigWorldMapMapNameByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.MapName
end

function XBigWorldMapConfigModel:GetBigWorldMapBaseImageByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.BaseImage
end

function XBigWorldMapConfigModel:GetBigWorldMapLittleMapScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.LittleMapScale
end

function XBigWorldMapConfigModel:GetBigWorldMapMaxScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.MaxScale
end

function XBigWorldMapConfigModel:GetBigWorldMapMinScaleByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.MinScale
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupIdsByLevelId(levelId)
    local config = self:GetBigWorldMapConfigByLevelId(levelId)

    return config.AreaGroupIds
end

---@return XTableBigWorldMapAreaGroup[]
function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapAreaGroup)
end

---@return XTableBigWorldMapAreaGroup
function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupConfigByGroupId(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapAreaGroup, groupId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupFloorIndexByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    if not config then
        return 0
    end

    return config.FloorIndex
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupGroupNameByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    return config.GroupName
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupAreaIdsByGroupId(groupId)
    local config = self:GetBigWorldMapAreaGroupConfigByGroupId(groupId)

    return config.AreaIds
end

---@return XTableBigWorldMapArea[]
function XBigWorldMapConfigModel:GetBigWorldMapAreaConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapArea)
end

---@return XTableBigWorldMapArea
function XBigWorldMapConfigModel:GetBigWorldMapAreaConfigByAreaId(areaId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapArea, areaId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaPosXByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.PosX
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaPosZByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.PosZ
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaPixelRatioByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.PixelRatio
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaAreaNameByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.AreaName
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaAreaImageByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.AreaImage
end

function XBigWorldMapConfigModel:GetBigWorldMapAreaGroupIdByAreaId(areaId)
    local config = self:GetBigWorldMapAreaConfigByAreaId(areaId)

    return config.GroupId
end

---@return XTableBigWorldMapPinStyle[]
function XBigWorldMapConfigModel:GetBigWorldMapPinStyleConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapPinStyle)
end

---@return XTableBigWorldMapPinStyle
function XBigWorldMapConfigModel:GetBigWorldMapPinStyleConfigByStyleId(styleId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapPinStyle, styleId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapPinStyleActiveIconByStyleId(styleId)
    local config = self:GetBigWorldMapPinStyleConfigByStyleId(styleId)

    return config.ActiveIcon
end

function XBigWorldMapConfigModel:GetBigWorldMapPinStyleUnActiveIconByStyleId(styleId)
    local config = self:GetBigWorldMapPinStyleConfigByStyleId(styleId)

    return config.UnActiveIcon
end

---@return XTableBigWorldMapQuestPin[]
function XBigWorldMapConfigModel:GetBigWorldMapQuestPinConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapQuestPin)
end

---@return XTableBigWorldMapQuestPin
function XBigWorldMapConfigModel:GetBigWorldMapQuestPinConfigByQuestId(questId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapQuestPin, questId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapQuestPinStyleIdByQuestId(questId)
    local config = self:GetBigWorldMapQuestPinConfigByQuestId(questId)

    if not config then
        XLog.Error("XBigWorldMapConfigModel:GetBigWorldMapQuestPinStyleIdByQuestId questId = " .. questId .. " not found!")

        return 0
    end

    return config.StyleId
end

---@return XTableBigWorldMapLink[]
function XBigWorldMapConfigModel:GetBigWorldMapLinkConfigs()
    return self._ConfigUtil:GetByTableKey(MapTableKey.BigWorldMapLink)
end

---@return XTableBigWorldMapLink
function XBigWorldMapConfigModel:GetBigWorldMapLinkConfigByLevelId(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(MapTableKey.BigWorldMapLink, levelId, false)
end

function XBigWorldMapConfigModel:GetBigWorldMapLinkLinkLevelIdByLevelId(levelId)
    local config = self:GetBigWorldMapLinkConfigByLevelId(levelId)

    return config.LinkLevelId
end

function XBigWorldMapConfigModel:GetBigWorldMapLinkLinkWorldIdByLevelId(levelId)
    local config = self:GetBigWorldMapLinkConfigByLevelId(levelId)

    return config.LinkWorldId
end

function XBigWorldMapConfigModel:GetBigWorldMapLinkBindPinIdByLevelId(levelId)
    local config = self:GetBigWorldMapLinkConfigByLevelId(levelId)

    return config.BindPinId
end

return XBigWorldMapConfigModel
