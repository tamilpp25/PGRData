---@class XPlanetTileData:XDataEntityBase
local XPlanetTileData = XClass(XDataEntityBase, "XPlanetTileData")

local default = {
    _TileId = 0,
    _GridType = 1,
    _BuildingId = 0,
    _BuildingDirection = 1,
    _BuildingCenter = 0,
    _FloorId = 1,
    _FloorHeight = 0,
    _AdjacentGrid = {},
    _BuildingGuid = -1,
    _BeInBuildingRangeList = {},    -- 建筑范围内包含该地块的建筑列表
}

---@class XPlanetTileData
---@field _TileId int 地块Id
---@field _GridType XPlanetWorldConfigs.GridType 地块类型
---@field _BuildingId int  该地块上的建筑模型
---@field _BuildingDirection int 模型朝向
---@field _BuildingCenter int 默认建筑中心
---@field _FloorId int  地板材质Id
---@field _FloorHeight float 地板高度
---@field _AdjacentGrid table<int, int> 相邻地块Id
---@field _BuildingGuid numbert 地块建筑唯一id
function XPlanetTileData:Ctor(stageId)
    self:Init(default, stageId)
end

function XPlanetTileData:UpdateData(data)
    self:SetTileId(data.Id)
    self:SetGridType(data.GridType)
    self:SetBuildingId(data.DefaultBuilding)
    self:SetBuildingCenter(data.BuildingCenter)
    self:SetBuildingDirection(data.BuildingDirection)
    self:SetFloorId(data.DefaultFloorId)
    self:SetFloorHeight(data.FloorHeight)
    self:SetAdjacentGrid(data.AdjacentGrid)
end

function XPlanetTileData:CheckIsDefaultBuild()
    return XTool.IsNumberValid(self._BuildingCenter)
end

function XPlanetTileData:CheckIsHaveBuild()
    return XTool.IsNumberValid(self._BuildingId)
end

function XPlanetTileData:CheckIsGirdType(gridType)
    return self._GridType == gridType
end


--region Getter
function XPlanetTileData:GetTileId()
    return self:GetProperty("_TileId")
end

---@return XPlanetWorldConfigs.GridType
function XPlanetTileData:GetGridType()
    return self:GetProperty("_GridType")
end

function XPlanetTileData:GetBuildingId()
    return self:GetProperty("_BuildingId")
end

function XPlanetTileData:GetBuildingDirection()
    return self:GetProperty("_BuildingDirection")
end

function XPlanetTileData:GetBuildingCenter()
    return self:GetProperty("_BuildingCenter")
end

function XPlanetTileData:GetFloorId()
    return self:GetProperty("_FloorId")
end

---@return float
function XPlanetTileData:GetFloorHeight()
    return self:GetProperty("_FloorHeight")
end

function XPlanetTileData:GetAdjacentGrid()
    return self:GetProperty("_AdjacentGrid")
end

function XPlanetTileData:GetBuildingGuid()
    return self:GetProperty("_BuildingGuid")
end
--endregion

--region Setter
function XPlanetTileData:SetTileId(tileId)
    self:SetProperty("_TileId", tileId)
end

function XPlanetTileData:SetGridType(gridType)
    self:SetProperty("_GridType", gridType)
end

function XPlanetTileData:SetBuildingId(buildingId)
    self:SetProperty("_BuildingId", buildingId)
end

function XPlanetTileData:SetBuildingDirection(buildingDirection)
    self:SetProperty("_BuildingDirection", buildingDirection)
end

function XPlanetTileData:SetBuildingCenter(buildingCenter)
    self:SetProperty("_BuildingCenter", buildingCenter)
end

function XPlanetTileData:SetFloorId(floorId)
    self:SetProperty("_FloorId", floorId)
end

function XPlanetTileData:SetFloorHeight(floorHeight)
    self:SetProperty("_FloorHeight", floorHeight)
end

function XPlanetTileData:SetAdjacentGrid(adjacentGrid)
    self:SetProperty("_AdjacentGrid", XTool.Clone(adjacentGrid))
end

function XPlanetTileData:SetBuildingGuid(buildingGuid)
    self:SetProperty("_BuildingGuid", buildingGuid)
end

function XPlanetTileData:AddBeInBuildingRangeList(buildingGuid)
    if XTool.IsTableEmpty(self._BeInBuildingRangeList) then
        table.insert(self._BeInBuildingRangeList, buildingGuid)
    else
        local index = table.indexof(self._BeInBuildingRangeList, buildingGuid)
        if not XTool.IsNumberValid(index) then
            table.insert(self._BeInBuildingRangeList, buildingGuid)
        end
    end
end

function XPlanetTileData:RemoveBeInBuildingRangeList(buildingGuid)
    
end
--endregion

return XPlanetTileData