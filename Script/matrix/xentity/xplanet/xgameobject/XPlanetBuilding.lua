local XPlanetIObject = require("XEntity/XPlanet/XGameObject/XPlanetIObject")

---@class XPlanetBuilding:XPlanetIObject
---@field _Guid number 唯一标识Id|默认建筑是配置表的buildingCenter|建造的是服务端计算的Id
---@field _BuildingId number building表id或talentBuildingId
---@field _BuildingDirection number 建筑方向
---@field _OccupyTileList table 占地地块
---@field _RangeTileList table<number, table> 范围地块
---@field _InRangeRoadList table<number, table> 在范围内的道路(刷怪用)
---@field _IsTalentBuilding boolean 是否是天赋建筑
local XPlanetBuilding = XClass(XPlanetIObject, "XPlanetBuilding")

function XPlanetBuilding:Ctor(root, id)
    self:Init(id)
end

function XPlanetBuilding:Init(id)
    self._Guid = id
    self._BuildingId = 0
    self._BuildingDirection = 1
    self._OccupyTileList = {}   -- 占地地块
    self._RangeTileList = {}    -- 范围地块：第一圈[1] = {}, 第二圈[2] = {},
    self._InRangeRoadList = {}  -- 在范围内的道路(刷怪用)
    self._IsTalentBuilding = false
    self._FloorId = 0
end


--region Getter
function XPlanetBuilding:GetGuid()
    return self._Guid
end

function XPlanetBuilding:GetBuildingId()
    return self._BuildingId
end

function XPlanetBuilding:GetBuildingDirection()
    return self._BuildingDirection
end

function XPlanetBuilding:GetOccupyTileList()
    return self._OccupyTileList 
end

---@return table<number, table>
function XPlanetBuilding:GetRangeTileList()
    return self._RangeTileList
end

---@return table
function XPlanetBuilding:GetRangeTileListByRange(range)
    return self._RangeTileList[range]
end

function XPlanetBuilding:GetInRangeRoadList()
    return self._InRangeRoadList
end

function XPlanetBuilding:GetIsTalentBuilding()
    return self._IsTalentBuilding
end

function XPlanetBuilding:GetModelKey()
    return XPlanetWorldConfigs.GetBuildingModelKey(self:GetBuildingId())
end

function XPlanetBuilding:GetFloorId()
    return self._FloorId
end

function XPlanetBuilding:GetRotation()
    if XTool.UObjIsNil(self._Transform) then
        return CS.UnityEngine.Quaternion.identity
    end
    return self._Transform.rotation
end
--endregion


--region Setter
function XPlanetBuilding:SetId(id)
    self._Guid = id
end

function XPlanetBuilding:SetBuildingId(buildingId)
    self._BuildingId = buildingId
end

function XPlanetBuilding:SetBuildingDirection(buildingDirection)
    self._BuildingDirection = buildingDirection
end

function XPlanetBuilding:SetOccupyTileList(occupyTileList)
    self._OccupyTileList = XTool.Clone(occupyTileList)
end

---添加占地地块
function XPlanetBuilding:AddOccupyTile(tileId)
    table.insert(self._OccupyTileList, tileId)
end

function XPlanetBuilding:SetRangeTileList(rangeTileList)
    self._RangeTileList = XTool.Clone(rangeTileList)
end

---添加效果范围内的地块
function XPlanetBuilding:AddRangeTile(tileId)
    table.insert(self._RangeTileList, tileId)
end

function XPlanetBuilding:SetInRangeRoadList(inRangeRoadList)
    self._InRangeRoadList = XTool.Clone(inRangeRoadList)
end

---添加在效果范围内的道路地块
function XPlanetBuilding:AddInRangeRoadTile(tileId)
    table.insert(self._InRangeRoadList, tileId)
end

function XPlanetBuilding:SetIsTalentBuilding(isTalentBuilding)
    self._IsTalentBuilding = isTalentBuilding
end

function XPlanetBuilding:SetFloorId(floorId)
    if XTool.IsNumberValid(floorId) then
        self._FloorId = floorId
    else
        if self:GetIsTalentBuilding() then
            self._FloorId = XPlanetTalentConfigs.GetTalentBuildingDefaultFloorId(self:GetBuildingId())
        else
            self._FloorId = XPlanetWorldConfigs.GetBuildingFloorId(self:GetBuildingId())
        end
    end
end
--endregion


--region Check
---检查GameObject是否是该建筑
function XPlanetBuilding:CheckIsModel(modelobj)
    if XTool.UObjIsNil(self._Transform) then return false end
    return self._Transform == modelobj
end
--endregion

--region 加载
--- 加载成功回调
function XPlanetBuilding:OnLoadSuccess()
    self:SetGameObjectDynamicTag()
    self._Transform.localScale = XPlanetConfigs.GetModelScale(self:GetModelKey())
end

function XPlanetBuilding:GetAssetPath()
    return XPlanetConfigs.GetModelResUrl(self:GetModelKey())
end

function XPlanetBuilding:GetObjName()
    if self:GetIsTalentBuilding() then
        return "_Talent_"..self:GetModelKey()
    else
        return self:GetModelKey()
    end
end
--endregion

return XPlanetBuilding