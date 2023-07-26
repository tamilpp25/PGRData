local XPlanetIObject = require("XEntity/XPlanet/XGameObject/XPlanetIObject")
local XPlanetTileData = require("XEntity/XPlanet/XData/XPlanetTileData")
local XPlanetBuilding = require("XEntity/XPlanet/XGameObject/XPlanetBuilding")

---@class XPlanet:XPlanetIObject
---@field _StageId number 星球Id
---@field _Planet CS.Planet.Planet 星球总控对象(包含了所有地块对象)
---@field _PlanetCfg XConfig 星球配置数据
---@field _TileDataDir XPlanetTileData[] 星球地板数据字典
---@field _DefaultBuildObjList XPlanetBuilding[] 默认建筑对象
---@field _BuildObjList XPlanetBuilding[] 建造的建筑对象
---@field _RoadHeight number 道路高度
---@field _IsTalentPlanet boolean 是否是天赋球
---@field _EffectPoolDir table<string, XObjectPool> 特效池
---@field _EffectResourceDir table<string, IResource> 特效资源字典
local XPlanet = XClass(XPlanetIObject, "XPlanet")

function XPlanet:Ctor(root, stageId)
    self:Init(stageId, stageId == XPlanetWorldConfigs.GetTalentStageId())
end

function XPlanet:Init(stageId, isTalentPlanet)
    self._StageId = stageId
    self._Planet = nil
    self._PlanetCfg = nil
    self._TileDataDir = {}
    self._DefaultBuildObjList = {}
    self._BuildObjList = {}
    self._RoadHeight = 0
    self._IsTalentPlanet = isTalentPlanet
    self._EffectPoolDir = {}
    self._EffectResourceDir = {}
    self._TimerEffect = {}
end


--region 星球对象&数据获取
---地块:获取星球所有地块对象
---@return CS.Planet.PlanetTile[]
function XPlanet:GetTiles()
    return self._Planet.tiles
end

---地块:获取星球指定地块对象
---@return CS.Planet.PlanetTile
function XPlanet:GetTile(tileId)
    if not XTool.IsNumberValid(tileId) then
        XLog.Error("XPlanet.GetTile(tileId) Error:tileId不可为0!")
    end
    return self._Planet:GetTile(tileId)
end

---地块:统计某种类型的地块网格数量
---@param gridType number XPlanetWorldConfigs.GridType|nil
---@return number
function XPlanet:GetTileCount(gridType)
    if XTool.IsNumberValid(gridType) then
        local result = 0
        for _, tile in ipairs(self:GetTiles()) do
            if self:GetTileData(tile.TileId):CheckIsGirdType(gridType) then
                result = result + 1
            end
        end
        return result
    end
    return self._Planet.tiles.Count
end

---地块:获取星球指定地块数据
---@return XPlanetTileData
function XPlanet:GetTileData(tileId)
    return not XTool.IsTableEmpty(self._TileDataDir) and self._TileDataDir[tileId]
end

---地块:获取星球所有地块数据
---@return table<number, XPlanetTileData>
function XPlanet:GetTileDataDir()
    return self._TileDataDir
end

---建筑:获取地块建筑对象
---@param guid number
---@param isDefault boolean
function XPlanet:GetBuildingByBuildGuid(guid, isDefault)
    if isDefault then
        return self._DefaultBuildObjList[guid]
    else
        return self._BuildObjList[guid]
    end
end

---建筑:获取地块默认建筑对象
---@return XPlanetBuilding
function XPlanet:GetDefaultBuildingByTileId(tileId)
    local tileData = self:GetTileData(tileId)
    if self._IsTalentPlanet or not tileData:CheckIsDefaultBuild() then
        return
    end
    return self._DefaultBuildObjList[tileData:GetBuildingGuid()]
end

---建筑:获取在地块建造的建筑对象
---@return XPlanetBuilding
function XPlanet:GetBuildingByTileId(tileId)
    local tileData = self:GetTileData(tileId)
    if not tileData:CheckIsHaveBuild() or self._IsTalentPlanet and tileData:CheckIsDefaultBuild() then
        return
    end
    return self._BuildObjList[tileData:GetBuildingGuid()]
end

---建筑:获取指定建筑Id的建筑对象
---@return XPlanetBuilding[]
function XPlanet:GetBuildingByBuildingId(buildIngId)
    local result = {}
    for _, build in pairs(self._BuildObjList) do
        if build:GetBuildingId() == buildIngId then
            table.insert(result, build)
        end
    end
    return result
end

function XPlanet:GetBuildingPosition(tileIdList)
    return self._Planet:GetModelPosition(tileIdList)
end

---获取占地建筑的范围地块
---@param occupyTileIdList number[]
---@param buildId number
function XPlanet:GetBuildRangeTileList(occupyTileIdList, buildId)
    local result = {}
    local recordDir = {}    -- 去重字典
    local range = XPlanetWorldConfigs.GetBuildingRangeType(buildId)

    for _, tileId in ipairs(occupyTileIdList) do
        recordDir[tileId] = true
    end
    if range >= 1 then
        result[1] = {}
        for _, tileId in ipairs(occupyTileIdList) do
            local neighborIds = self:GetTile(tileId):GetNeighborIds()
            for i = 0, neighborIds.Count - 1 do
                if not recordDir[neighborIds[i]] then
                    table.insert(result[1], neighborIds[i])
                    recordDir[neighborIds[i]] = true
                end
            end
        end
    end
    for i = 2, range do
        result[i] = {}
        for _, tileId in ipairs(result[i - 1]) do
            local neighborIds = self:GetTile(tileId):GetNeighborIds()
            for j = 0, neighborIds.Count - 1 do
                if not recordDir[neighborIds[j]] then
                    table.insert(result[i], neighborIds[j])
                    recordDir[neighborIds[j]] = true
                end
            end
        end
    end
    return result
end

function XPlanet:GetAllBuildingObj()
    return self._BuildObjList
end
--endregion


--region Effect
function XPlanet:PlayEffect(url, position, rotation, callback)
    -- 特效管理根节点
    if not self._EffectRoot then
        self._EffectRoot = self._GameObject:FindTransform("EffectRoot")
    end
    -- 资源字典
    if not self._EffectResourceDir[url] then
        local resource = CS.XResourceManager.LoadAsync(url)
        if not (resource and resource.Asset) then
            XLog.Error("restaurant load resource error: asset path = " .. url)
            return
        end
        self._EffectResourceDir[url] = resource
    end
    -- 对象池
    self._EffectPoolDir[url] = self._EffectPoolDir[url] or XObjectPool.New(function()
        return self:CreateEffectObj(url)
    end)
    local effectObj = self._EffectPoolDir[url]:Create()
    if effectObj then
        local duration
        local effectSetting = XUiHelper.TryGetComponent(effectObj.transform, "", "XEffectSetting")
        if effectSetting then
            duration = math.floor(effectSetting.LifeTime * XScheduleManager.SECOND)
        else
            duration = XScheduleManager.SECOND
        end

        effectObj.transform:SetParent(self._EffectRoot.transform, false)
        effectObj.transform.position = position
        if rotation then
            effectObj.transform.localRotation = rotation
        end
        effectObj.gameObject:SetActiveEx(true)
        local timer
        timer = XScheduleManager.ScheduleOnce(function()
            if not effectObj:Exist() then   -- 防止等待回收过程中立马销毁场景报错
                self:RemoveTimer(timer)
                return
            end
            effectObj.gameObject:SetActiveEx(false)
            self._EffectPoolDir[url]:Recycle(effectObj)
            self:RemoveTimer(timer)
            if callback then
                callback()
            end
        end, duration)
        self:AddTimer(timer)
    end
end

function XPlanet:AddTimer(timer)
    self._TimerEffect[#self._TimerEffect + 1] = timer
end

function XPlanet:RemoveTimer(timer)
    for i = 1, #self._TimerEffect do
        if self._TimerEffect[i] == timer then
            table.remove(self._TimerEffect, i)
        end
    end
end

function XPlanet:CreateEffectObj(url)
    if not self._EffectResourceDir[url] then
        return nil
    end
    return XUiHelper.Instantiate(self._EffectResourceDir[url].Asset)
end
--endregion


--region 星球对象设置
---根据配置更新星球地块和默认建筑
function XPlanet:_UpdatePlanetByCfg()
    self:_UpdatePlanetByServerData()
    for _, tileData in pairs(self:GetTileDataDir()) do
        local tileId = tileData:GetTileId()
        local height = tileData:GetFloorHeight()
        local floorId = tileData:GetFloorId()
        local girdType = tileData:GetGridType()
        if girdType == XPlanetWorldConfigs.GridType.RoadGrid then
            self._RoadHeight = height
        end
        self:UpdateTile(tileId, height, floorId, girdType)
    end

    for _, obj in pairs(self._BuildObjList) do
        self:SetBuilding(obj)
    end
    if self._IsTalentPlanet then
        for _, obj in pairs(self._DefaultBuildObjList) do
            self:SetBuilding(obj)
        end
    end
end

---根据服务端更新星球地块和模型
function XPlanet:_UpdatePlanetByServerData()
    local function SetBuildByServerData(buildId, buildGuid, data)
        if XTool.IsTableEmpty(data) then
            return
        end
        local building = self._BuildObjList[buildGuid]
        if XTool.IsTableEmpty(building) then
            local occupyType = XPlanetWorldConfigs.GetBuildingGridOccupyType(buildId)
            building = XPlanetBuilding.New(self._Root, buildGuid)
            building:SetBuildingId(buildId)
            building:SetBuildingDirection(XTool.IsNumberValid(data.Rotate) and data.Rotate or 1)
            building:SetIsTalentBuilding(self._IsTalentPlanet)
            if not data.MaterialId then -- 关卡不发基底材质数据
                local chapterId = XPlanetStageConfigs.GetStageChapterId(self._StageId)
                local isFloor = XPlanetWorldConfigs.CheckBuildingIsFloorType(buildId)
                local baseMaterialId = XPlanetStageConfigs.GetChapterBaseRoadFloorId(chapterId)
                if isFloor then
                    -- 不是建筑使用建筑配置基底
                    building:SetFloorId(data.MaterialId)
                else
                    -- 是建筑使用章节基底
                    building:SetFloorId(baseMaterialId)
                end
            else
                building:SetFloorId(data.MaterialId)
            end
            for _, tileId in ipairs(data.Occupy) do
                building:AddOccupyTile(tileId)
            end
            if occupyType == XPlanetWorldConfigs.GridOccupyType.Occupy7 then
                for _, tileId in ipairs(data.Occupy) do
                    local neighborIds = self:GetTile(tileId):GetNeighborIds()
                    for i = 0, neighborIds.Count - 1 do
                        building:AddOccupyTile(neighborIds[i])
                    end
                end
            end
            building:SetRangeTileList(self:GetBuildRangeTileList(building:GetOccupyTileList(), buildId))
        end
        self:AddBuilding(building, false)
    end
    if self._IsTalentPlanet then
        local buildDataDir = XDataCenter.PlanetManager.GetTalentBuildData()
        if XTool.IsTableEmpty(buildDataDir) then
            return
        end

        for buildId, dataDir in pairs(buildDataDir) do
            for buildGuid, data in pairs(dataDir.Building) do
                SetBuildByServerData(buildId, buildGuid, data)
            end
        end
    else
        local buildDataDir = XDataCenter.PlanetManager.GetStageBuildData()
        if XTool.IsTableEmpty(buildDataDir) then
            return
        end
        for buildId, dataDir in pairs(buildDataDir) do
            for buildGuid, data in pairs(dataDir.Building) do
                SetBuildByServerData(buildId, buildGuid, data)
            end
        end
    end
end

---地块:更新地块
function XPlanet:UpdateTile(tileId, height, floorId, girdType)
    local tile = self:GetTile(tileId)
    self:GetTileData(tileId):SetFloorHeight(height)
    self:GetTileData(tileId):SetFloorId(floorId)
    if XTool.IsNumberValid(girdType) then
        self:GetTileData(tileId):SetGridType(girdType)
    end
    tile:SetMeshActive(true)
    tile:CreatePillarMesh(height)
    tile:ChangeFloorMaterial(XDataCenter.PlanetManager.GetMaterialByFloorId(floorId))
    self:ResetTileMaterial(tileId)
end

---地块:重置地板材质
function XPlanet:ResetTileMaterial(tileId)
    local tile = self:GetTile(tileId)
    local tileData = self:GetTileData(tileId)
    tile:ResetTileMaterial()
    if tileData:GetGridType() == XPlanetWorldConfigs.GridType.None then
        self:SetTileNoneMat(tileId)
    end
end

---地块:设置地板材质为空表网格材质
function XPlanet:SetTileNoneMat(tileId)
    self:SetTileShowNone(tileId, true)
    --local tile = self:GetTile(tileId)
    --tile:SetEffectMaterial(XDataCenter.PlanetManager.GetEffectMaterial(XPlanetConfigs.TileEffectMat.TileNoneMat))
end

---地块:设置地板材质为选择材质(建造时)
function XPlanet:SetTileSelectMat(tileId)
    local tile = self:GetTile(tileId)
    self:SetTileShowNone(tileId, false)
    tile:SetEffectMaterial(XDataCenter.PlanetManager.GetEffectMaterial(XPlanetConfigs.TileEffectMat.TileSelectMat))
end

---地块:设置地板材质为不可建造材质(建造时)
function XPlanet:SetTileCantBuildMat(tileId)
    local tile = self:GetTile(tileId)
    self:SetTileShowNone(tileId, false)
    tile:SetEffectMaterial(XDataCenter.PlanetManager.GetEffectMaterial(XPlanetConfigs.TileEffectMat.TileCantBuildMat))
end

---地块:设置地板材质为空表网格材质(建造时)
function XPlanet:SetTileNoneBuildMat(tileId)
    local tile = self:GetTile(tileId)
    self:SetTileShowNone(tileId, true)
    tile:SetEffectMaterial(XDataCenter.PlanetManager.GetEffectMaterial(XPlanetConfigs.TileEffectMat.TileNoneBuildMat))
end

---地块:设置地板材质为建筑范围材质(建造时)
function XPlanet:SetTileRangeMat(tileId)
    self:SetTileShowNone(tileId, false)
    local tile = self:GetTile(tileId)
    tile:SetEffectMaterial(XDataCenter.PlanetManager.GetEffectMaterial(XPlanetConfigs.TileEffectMat.TileBuildRangeMat))
end

function XPlanet:SetTileShowNone(tileId, isShow)
    local tile = self:GetTile(tileId)
    local gray = XPlanetConfigs.GetNoneTileRendererGray()
    local color = XUiHelper.Hexcolor2Color(XPlanetConfigs.GetNoneTileRendererColorCode())
    tile:SetNoneShow(isShow, gray, color)
end

---建筑:放置建筑
---@param building XPlanetBuilding
function XPlanet:SetBuilding(building, cb)
    local direction = building:GetBuildingDirection()
    local buildingId = building:GetBuildingId()
    local occupyTileList = building:GetOccupyTileList()
    for _, tileId in ipairs(occupyTileList) do
        local data = self:GetTileData(tileId)
        data:SetBuildingGuid(building:GetGuid())
        data:SetBuildingId(buildingId)
        data:SetBuildingDirection(direction)
    end
    self:UpdateBuildTile(building)
    if not string.IsNilOrEmpty(building:GetModelKey()) then
        self:SetBuildingModel(building, cb)
    end
end

---建筑:添加建筑进入建筑列表
---@param building XPlanetBuilding 建筑对象
---@param isDefault boolean 是否默认建筑
function XPlanet:AddBuilding(building, isDefault)
    if isDefault then
        self._DefaultBuildObjList[building:GetGuid()] = building
    else
        self._BuildObjList[building:GetGuid()] = building
    end
end

---@param building XPlanetBuilding
function XPlanet:RotateBuilding(building, direction)
    direction = direction + 1
    self:UpdateBuildingDirection(building, direction)
end

function XPlanet:UpdateBuildingDirection(building, direction)
    if not building:GetTransform() then
        return
    end
    if direction > 5 then
        direction = 1
    end
    building:SetBuildingDirection(direction)

    local forward = self._Planet:GetModelDirection(building:GetOccupyTileList(), direction)
    local up = (building:GetTransform().position - self._Planet.transform.position).normalized
    local angle = Vector3.Dot(forward, up)
    up = up - angle * forward
    building:GetTransform().rotation = CS.UnityEngine.Quaternion.LookRotation(forward, up)
end

---建筑:移除建筑
function XPlanet:RemoveBuilding(buildGuid, isDefault)
    local building = self:GetBuildingByBuildGuid(buildGuid, isDefault)
    self:RemoveFloor(building)
    building:Release()
    if isDefault then
        self._DefaultBuildObjList[buildGuid] = nil
    else
        self._BuildObjList[buildGuid] = nil
    end
end

function XPlanet:UpdateBuildTile(building)
    local occupyTileList = building:GetOccupyTileList()
    for _, tileId in ipairs(occupyTileList) do
        local floorId = building:GetFloorId()
        local isFloorBuild = XPlanetWorldConfigs.CheckBuildingIsType(building:GetBuildingId(), XPlanetWorldConfigs.BuildType.FloorBuild)
        local floorHeight = isFloorBuild and XPlanetWorldConfigs.GetBuildingFloorHeight(building:GetBuildingId()) or self._RoadHeight
        self:UpdateTile(tileId, floorHeight, floorId, XPlanetWorldConfigs.GridType.BuildingGrid)
    end
end

---建筑:同步建筑
function XPlanet:ClearTalentBuilding()
    self:_UpdatePlanetByServerData()
    local buildDataDir = XDataCenter.PlanetManager.GetTalentBuildData()
    if XTool.IsTableEmpty(buildDataDir) then
        self:ClearBuilding()
        return
    end
    for _, building in pairs(self._BuildObjList) do
        local buildTable = buildDataDir[building:GetBuildingId()]
        if XTool.IsTableEmpty(buildTable) then
            self:RemoveBuilding(building:GetGuid(), false)
            goto CONTINUE
        end
        local exitBuild = buildTable.Building[building:GetGuid()]
        if XTool.IsTableEmpty(exitBuild) then
            self:RemoveBuilding(building:GetGuid(), false)
            goto CONTINUE
        end
        :: CONTINUE ::
    end
end

---建筑:清空建筑
function XPlanet:ClearBuilding()
    for buildGuid, _ in pairs(self._BuildObjList) do
        self:RemoveBuilding(buildGuid, false)
    end
end

---建筑:正式摆放建筑模型
---@param building XPlanetBuilding
function XPlanet:SetBuildingModel(building, cb)
    local modelObj = building:GetGameObject()
    local occupyTileList = building:GetOccupyTileList()
    local direction = building:GetBuildingDirection()
    
    -- 处理默认建筑方向
    local getDirectionTile = { }
    local center = self._PlanetCfg:GetProperty(occupyTileList[1], "BuildingCenter")
    if not XTool.IsNumberValid(center) then
        goto CONTINUE
    end
    table.insert(getDirectionTile, center)
    for _, tileId in ipairs(occupyTileList) do
        if tileId ~= center then
            table.insert(getDirectionTile, tileId)
        end
    end
    if #getDirectionTile == #occupyTileList then
        occupyTileList = getDirectionTile
    end
    building:SetOccupyTileList(getDirectionTile)
    building:SetBuildingDirection(self._PlanetCfg:GetProperty(center, "BuildingDirection"))
    direction = building:GetBuildingDirection()
    :: CONTINUE ::
    
    if XTool.UObjIsNil(modelObj) then
        building:Load(function()
            modelObj = building:GetGameObject()
            self._Planet:SetModel(occupyTileList, modelObj, direction)
            if cb then
                cb()
            end
        end)
    else
        self._Planet:SetModel(occupyTileList, modelObj, direction)
        if cb then
            cb()
        end
    end
end

---建筑:临时摆放建筑模型
---@param building XPlanetBuilding
function XPlanet:SetTempBuildingModel(building, cb)
    local modelObj = building:GetGameObject()
    local occupyTileList = building:GetOccupyTileList()
    local direction = building:GetBuildingDirection()
    local setFunc = function()
        modelObj.transform.position = self._Planet:GetModelPosition(occupyTileList)
        local forward = self._Planet:GetModelDirection(building:GetOccupyTileList(), direction)
        local up = (building:GetTransform().position - self._Planet.transform.position).normalized
        local angle = Vector3.Dot(forward, up)
        up = up - angle * forward
        building:GetTransform().rotation = CS.UnityEngine.Quaternion.LookRotation(forward, up)
    end
    if XTool.UObjIsNil(modelObj) then
        building:Load(function()
            modelObj = building:GetGameObject()
            modelObj.transform:SetParent(self._Planet.transform)
            setFunc()
            if cb then
                cb()
            end
        end)
    else
        setFunc()
        if cb then
            cb()
        end
    end
end

function XPlanet:RemoveFloor(building, isTemp)
    local occupyTileList = building:GetOccupyTileList()
    local tileFloorId, tileHeight
    for _, tileId in ipairs(occupyTileList) do
        local data = self:GetTileData(tileId)
        if not isTemp then
            data:SetBuildingGuid(-1)
            data:SetBuildingId(0)
            data:SetBuildingDirection(0)
            data:SetBuildingCenter(0)
        end
        if self._IsTalentPlanet then
            tileFloorId = self._PlanetCfg:GetProperty(tileId, "DefaultFloorId")
        else
            local chapterId = XPlanetStageConfigs.GetStageChapterId(self._StageId)
            tileFloorId = XPlanetStageConfigs.GetChapterBaseTileFloorId(chapterId)
        end
        tileHeight = self._PlanetCfg:GetProperty(tileId, "FloorHeight")
        self:UpdateTile(tileId, tileHeight, tileFloorId, XPlanetWorldConfigs.GridType.BuildingGrid)
    end
end

---建筑:根据占地得坐标
function XPlanet:GetTempModelPosition(occupyTileIdList)
    return self._Planet:GetModelPosition(occupyTileIdList)
end
--endregion


--region 星球对象/数据初始化
function XPlanet:InitPlanet()
    self._Planet = self._GameObject:GetComponent("Planet")
    self._Planet.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.Room))
    self._PlanetCfg = self._IsTalentPlanet and XPlanetWorldConfigs.GetTalentPlanet() or XPlanetWorldConfigs.GetStagePlanetCfg(self._StageId)
    self:_ClearPrefabModel()
    self:_InitTileDataDirByCfg()
    -- self:_InitDefaultBuildDataDirByCfg()
end

---清理预制体的model层
function XPlanet:_ClearPrefabModel()
    for _, tile in pairs(self:GetTiles()) do
        tile:RemoveModel()
    end
end

---根据配置初始化星球地块数据
function XPlanet:_InitTileDataDirByCfg()
    for tileId, data in ipairs(self._PlanetCfg:GetConfigs()) do
        self._TileDataDir[tileId] = XPlanetTileData.New(tileId)
        self._TileDataDir[tileId]:UpdateData(data)
        if XTool.IsNumberValid(data.BuildingCenter) then
            self._TileDataDir[tileId]:SetBuildingGuid(data.BuildingCenter)
        end
        -- 关卡拆除建筑要恢复基底材质
        if not self._IsTalentPlanet
                and self._TileDataDir[tileId]:GetGridType() == XPlanetWorldConfigs.GridType.BuildingGrid
                and XTool.IsNumberValid(data.BuildingCenter) then
            self._TileDataDir[tileId]:SetFloorId(XPlanetStageConfigs.GetChapterBaseTileFloorId(XPlanetStageConfigs.GetStageChapterId(self._StageId)))
        end
    end
end

---根据配置初始化星球默认建筑
function XPlanet:_InitDefaultBuildDataDirByCfg()
    for tileId, data in ipairs(self._PlanetCfg:GetConfigs()) do
        if XTool.IsNumberValid(data.BuildingCenter) and XTool.IsNumberValid(data.DefaultBuilding) then
            local building = self:GetBuildingByBuildGuid(data.BuildingCenter, true)
            if XTool.IsTableEmpty(building) then
                building = XPlanetBuilding.New(self._Root, data.BuildingCenter)
                building:SetBuildingId(data.DefaultBuilding)
                building:SetBuildingDirection(data.BuildingDirection)
                building:SetIsTalentBuilding(self._IsTalentPlanet)
                building:SetFloorId()
                building:AddOccupyTile(tileId)
                self:AddBuilding(building, true)
            else
                building:AddOccupyTile(tileId)
            end
        end
    end
end
--endregion


--region 加载
function XPlanet:GetAssetPath()
    return XPlanetConfigs.GetDefaultPlanetUrl()
end

function XPlanet:GetObjName()
    return "_Planet"
end

--- 释放资源
---@return void
function XPlanet:Release()
    self.Super.Release(self)
    for _, resource in pairs(self._EffectResourceDir) do
        resource:Release()
    end
    self:Init()

    for i = 1, #self._TimerEffect do
        local timer = self._TimerEffect[i]
        XScheduleManager.UnSchedule(timer)
    end
    self._TimerEffect = {}
end

function XPlanet:OnLoadSuccess()
    self:InitPlanet()
    self:_UpdatePlanetByCfg()
end
--endregion


--region Debug
function XPlanet:ShowBuildGuid(active, font)
    if not self:Exist() then
        return
    end
    if XTool.IsTableEmpty(self._BuildObjList) then
        return
    end
    if active then
        self.DebugBuildGuidRoot = self._Transform:Find("BuildIdTextRoot")
        if XTool.UObjIsNil(self.DebugBuildGuidRoot) then
            local go = CS.UnityEngine.GameObject("BuildIdTextRoot")
            go:AddComponent(typeof(CS.UnityEngine.Canvas)).renderMode = CS.UnityEngine.RenderMode.WorldSpace
            go.transform:SetParent(self._Transform, false)
            self:TryResetTransform(go.transform)
            self.DebugBuildGuidRoot = go
        end
        for i = self.DebugBuildGuidRoot.transform.childCount - 1, 0, -1 do
            XUiHelper.Destroy(self.DebugBuildGuidRoot.transform:GetChild(i).gameObject)
        end
        for _, build in pairs(self._BuildObjList) do
            local txt = CS.UnityEngine.GameObject("TxtBuildGuid" .. build:GetGuid())
            txt.transform:SetParent(self.DebugBuildGuidRoot.transform)
            local txtObj = txt:AddComponent(typeof(CS.UnityEngine.UI.Text))
            txtObj.text = build:GetGuid()
            -- txtObj.font = font
            txtObj.color = CS.UnityEngine.Color.red
            txtObj.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
            txtObj.transform.localScale = Vector3(0.05, 0.05, 1)
            local position = self:GetBuildingPosition(build:GetOccupyTileList())
            txtObj.transform.position = self:GetBuildingPosition(build:GetOccupyTileList()) * 1.12
            txtObj.transform.forward = -(position - self._Planet.transform.position)
        end
    else
        XUiHelper.Destroy(self.DebugBuildGuidRoot)
        self.DebugBuildGuidRoot = nil
    end
end

function XPlanet:ShowTileId(active, font)
    if not self:Exist() then
        return
    end
    if active then
        self.DebugTileIdRoot = self._Transform:Find("TileIdTextRoot")
        if XTool.UObjIsNil(self.DebugTileIdRoot) then
            local go = CS.UnityEngine.GameObject("TileIdTextRoot")
            go:AddComponent(typeof(CS.UnityEngine.Canvas)).renderMode = CS.UnityEngine.RenderMode.WorldSpace
            go.transform:SetParent(self._Transform, false)
            self:TryResetTransform(go.transform)
            self.DebugTileIdRoot = go
        end
        local tiles = self:GetTiles()
        for i = 0, tiles.Count - 1 do
            local txt = CS.UnityEngine.GameObject("TxtTile" .. tiles[i].TileId)
            txt.transform:SetParent(self.DebugTileIdRoot.transform)
            local txtObj = txt:AddComponent(typeof(CS.UnityEngine.UI.Text))
            txtObj.text = tiles[i].TileId
            -- txtObj.font = font
            txtObj.color = CS.UnityEngine.Color.red
            txtObj.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
            txtObj.transform.localScale = Vector3(0.05, 0.05, 1)
            txtObj.transform.position = tiles[i]:GetHeightPosition() * 1.01
            txtObj.transform.forward = -tiles[i]:GetTileUp()
        end
    else
        XUiHelper.Destroy(self.DebugTileIdRoot)
        self.DebugTileIdRoot = nil
    end
end
--endregion

return XPlanet