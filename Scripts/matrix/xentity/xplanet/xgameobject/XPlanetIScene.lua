local XPlanetIObject = require("XEntity/XPlanet/XGameObject/XPlanetIObject")
local XPlanet = require("XEntity/XPlanet/XGameObject/XPlanet")
local XPlanetCamera = require("XEntity/XPlanet/XGameObject/XPlanetCamera")
local XPlanetBuilding = require("XEntity/XPlanet/XGameObject/XPlanetBuilding")

---@class XPlanetIScene:XPlanetIObject
---@field _StageId number
---@field _Planet XPlanet
---@field _PlanetRoot CS.UnityEngine.Transform
---@field _PlanetCamera XPlanetCamera
local XPlanetIScene = XClass(XPlanetIObject, "XPlanetIScene")

function XPlanetIScene:Ctor(root, stageId)
    self:Init(stageId)
end

function XPlanetIScene:Init(stageId)
    self._StageId = stageId
    self._Planet = nil
    self._Mode = XPlanetConfigs.SceneMode.None

    self:_InitCurBuildParams()
end

function XPlanetIScene:ChangeMode(mode)
    self._Mode = mode
end

function XPlanetIScene:CheckIsInNoneMode()
    return self._Mode == XPlanetConfigs.SceneMode.None
end

--region 相机接口
function XPlanetIScene:UpdateCamInMovie(lookAtTran)
    if not self:CheckIsHaveCamera() then return end
    local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamStageMovie())
    self._PlanetCamera:ChangeMovieModeByCamera(cam, lookAtTran, true)
end

---获取当前场景的相机
---@return CS.UnityEngine.Camera
function XPlanetIScene:GetCamera()
    if not self:CheckIsHaveCamera() then
        return
    end
    return self._PlanetCamera:GetCamera()
end

---获取当前鼠标位置的地板
---@return Transfrom
function XPlanetIScene:GetCameraRay()
    if not self:CheckIsHaveCamera() then
        return
    end
    local hit = self._PlanetCamera:RayTileCast()
    if XTool.UObjIsNil(hit) then
        return
    end
    return hit
end

---获取当前鼠标位置的地板
---@return CS.Planet.PlanetTile
function XPlanetIScene:GetCameraRayTile()
    if not self:CheckIsHaveCamera() then
        return
    end
    local hit = self._PlanetCamera:RayTileCast()
    if XTool.UObjIsNil(hit) then
        return
    end
    local tile = hit:GetComponent(typeof(CS.Planet.PlanetTile))
    if XTool.UObjIsNil(tile) then
        return
    end
    return tile
end

---获取指定屏幕坐标的地板
---@param screenPoint Vector2
---@return CS.Planet.PlanetTile
function XPlanetIScene:GetCameraRayTileByScreenPoint(screenPoint)
    if not self:CheckIsHaveCamera() then
        return
    end
    local hit = self._PlanetCamera:RayTileCastByScreenPoint(screenPoint, CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room))
    if XTool.UObjIsNil(hit) then
        return
    end
    local tile = hit:GetComponent(typeof(CS.Planet.PlanetTile))
    if XTool.UObjIsNil(tile) then
        return
    end
    return tile
end

---@return boolean
function XPlanetIScene:CheckCameraIsMove()
    if not self:CheckIsHaveCamera() then
        return false
    end
    return self._PlanetCamera._IsInMove
end

---@param followTran Transform
---@param camera XPlanetSceneCamera
function XPlanetIScene:SetCameraFollow(followTran, camera, cb)
    if not self:CheckIsHaveCamera() then
        if cb then cb() end
        return
    end
    self._PlanetCamera:ChangeFollowModeByCamera(followTran, camera, cb, false)
end

---@param explore XPlanetRunningExplore
function XPlanetIScene:CameraUpdate(explore, deltaTime)
    if not self:CheckIsHaveCamera() then
        return
    end
    --- 引导中时屏蔽旋转等
    if XDataCenter.GuideManager.CheckIsInGuidePlus() then
        return
    end
    self._PlanetCamera:FollowModeUpdate(explore, deltaTime)
    self._PlanetCamera:FreeModeScroll()
    self._PlanetCamera:FreeAfterDragUpdate()
end

function XPlanetIScene:MoveStaticCamera(position, rotation)
    if not self:CheckIsHaveCamera() then
        return
    end
    self._PlanetCamera:StaticModeMove(position, rotation)
end

---相机是否处于跟随视角
function XPlanetIScene:CheckCameraIsFollowMode()
    if not self:CheckIsHaveCamera() then
        return false
    end
    return self._PlanetCamera:CheckIsInFollowMode()
end

---相机是否处于自由旋转视角
function XPlanetIScene:CheckCameraIsFreeMode()
    if not self:CheckIsHaveCamera() then
        return false
    end
    return self._PlanetCamera:CheckIsInFreeMode()
end

---相机是否处于固定视角
function XPlanetIScene:CheckCameraIsStaticMode()
    if not self:CheckIsHaveCamera() then
        return false
    end
    return self._PlanetCamera:CheckIsInStaticMode()
end
--endregion


--region 星球建造接口
--内部接口
--=============================================================
---初始化当前预摆放建筑参数
function XPlanetIScene:_InitCurBuildParams()
    ---当前临时摆放的建筑列表
    ---@type XPlanetBuilding[]
    self._CurBuildingList = {}
    ---当前临时摆放的建筑占地字典
    ---@type table<number, table>
    self._CurBuildOccupyTileListDir = {}
    ---当前临时摆放的建筑范围地块字典
    ---@type table<number, table>
    self._CurBuildRangeTileListDir = {}
    ---当前临时摆放的建筑可否摆放字典
    ---@type table<number, table>
    self._CurBuildCanBuildDir = {}
    self._CurBuildSelectTileList = {}
    self._CurBuildBuildingId = 0
    ---当前选中的建筑是否是地板建筑
    self._CurBuildIsFloor = false
end

---刷新地板的材质
---@param tileId number 地块id
---@param canBuild boolean 该地块所属的建筑能否被建造
---@param canOccupy boolean 该地块能否作为被建造建筑的占地
---@param isRange boolean 是否是建筑的范围
function XPlanetIScene:_UpdateTileMaterial(tileId, canBuild, canOccupy, isRange)
    if isRange then
        self._Planet:SetTileRangeMat(tileId)
        return
    end
    local isNoneTile = self:CheckTileGridType(tileId, XPlanetWorldConfigs.GridType.None)
    if not isNoneTile and canBuild and canOccupy then
        self._Planet:SetTileSelectMat(tileId)
    elseif not isNoneTile and (not canBuild or not canOccupy) then
        self._Planet:SetTileCantBuildMat(tileId)
    elseif isNoneTile and (not canBuild or not canOccupy) then
        self._Planet:SetTileNoneBuildMat(tileId)
    end
end

---恢复地板的材质
---@param tileId number 地块id
function XPlanetIScene:_ResetTileMaterial(tileId)
    self._Planet:ResetTileMaterial(tileId)
end

function XPlanetIScene:_CreateCurBuildData(tileId, buildId)
    self:_InitCurBuildParams()
    local guid = self:CheckIsTalentPlanet() and XDataCenter.PlanetManager.GetTalentBuildGuid() or XDataCenter.PlanetManager.GetStageBuildIncId()

    self._CurBuildIsFloor = XPlanetWorldConfigs.CheckBuildingIsType(buildId, XPlanetWorldConfigs.BuildType.FloorBuild)
    self._CurBuildBuildingId = buildId
    table.insert(self._CurBuildSelectTileList, tileId)
    --创建建筑
    if self._CurBuildIsFloor then
        -- 地板型建筑
        local buildMode = XDataCenter.PlanetManager.GetCurFloorSelectBuildMode(self:CheckIsTalentPlanet())
        table.insert(self._CurBuildingList, XPlanetBuilding.New(self._Root, guid))
        if buildMode == XPlanetConfigs.FloorBuildingBuildMode.Cycle then
            local tile = self._Planet:GetTile(tileId)
            for i = 0, tile:GetNeighborIds().Count - 1 do
                table.insert(self._CurBuildingList, XPlanetBuilding.New(self._Root, guid + i + 1))
                table.insert(self._CurBuildSelectTileList, tile:GetNeighborIds()[i])
            end
        end
    else
        -- 非地板型建筑
        table.insert(self._CurBuildingList, XPlanetBuilding.New(self._Root, guid))
    end

    for index, building in ipairs(self._CurBuildingList) do
        --占地
        self._CurBuildOccupyTileListDir[index] = self:_CreateBuildOccupyTileList(self._CurBuildSelectTileList[index], buildId)
        --范围
        self._CurBuildRangeTileListDir[index] = self:_CreateBuildRangeTileList(self._CurBuildOccupyTileListDir[index], buildId)
        --能否建造
        self._CurBuildCanBuildDir[index] = self:CheckBuildingCanBeBuild(buildId, self._CurBuildOccupyTileListDir[index])
        --赋值
        building:SetBuildingId(self._CurBuildBuildingId)
        building:SetBuildingDirection(1)
        building:SetOccupyTileList(self._CurBuildOccupyTileListDir[index])
        building:SetRangeTileList(self._CurBuildRangeTileListDir[index])
        if self._CurBuildIsFloor then
            building:SetFloorId()
        else
            if self:CheckIsTalentPlanet() then
                building:SetFloorId(XDataCenter.PlanetManager.GetCurBuildSelectFloorId())
            else
                local chapterId = XPlanetStageConfigs.GetStageChapterId(self._StageId)
                local chapterFloorId = XPlanetStageConfigs.GetChapterBaseRoadFloorId(chapterId)
                building:SetFloorId(XTool.IsNumberValid(chapterFloorId) and chapterFloorId or XPlanetWorldConfigs.GetBuildingFloorId(building:GetBuildingId()))
            end
        end
    end
end

---根据鼠标指向的tile获取建筑占地地块
---@param tileId number
---@param buildId number
function XPlanetIScene:_CreateBuildOccupyTileList(tileId, buildId)
    local result = {}
    local occupyType = XPlanetWorldConfigs.GetBuildingGridOccupyType(buildId)
    local neighborIds = self._Planet:GetTile(tileId):GetNeighborIds()
    local neighborMaxIndex = neighborIds.Count - 1

    table.insert(result, tileId)
    if occupyType == XPlanetWorldConfigs.GridOccupyType.Occupy3 then
        local isFind = false
        for i = 0, neighborMaxIndex do
            if isFind then
                break
            end
            for j = 0, neighborMaxIndex do
                if self:CheckTileCanBeBuildOccupy(neighborIds[i], buildId) and
                        self:CheckTileCanBeBuildOccupy(neighborIds[j], buildId) and
                        self:CheckTileIsNeighbor(neighborIds[i], neighborIds[j]) then
                    table.insert(result, neighborIds[i])
                    table.insert(result, neighborIds[j])
                    isFind = true
                    break
                end
            end

            if i == neighborMaxIndex and not isFind then
                -- 找不到可用占地地块返回首两个相邻地块作为模型占地
                for j = 0, neighborMaxIndex do
                    if self:CheckTileIsNeighbor(neighborIds[0], neighborIds[j]) then
                        table.insert(result, neighborIds[0])
                        table.insert(result, neighborIds[j])
                        isFind = true
                        break
                    end
                end
            end
        end
    elseif occupyType == XPlanetWorldConfigs.GridOccupyType.Occupy7 then
        for i = 0, neighborMaxIndex do
            table.insert(result, neighborIds[i])
        end
    end
    return result
end

---获取占地建筑的范围地块
---@param occupyTileIdList number[]
---@param buildId number
function XPlanetIScene:_CreateBuildRangeTileList(occupyTileIdList, buildId)
    return self._Planet:GetBuildRangeTileList(occupyTileIdList, buildId)
end

---旋转占地为3的建筑占地地块
---@param occupyTileIdList number[]
function XPlanetIScene:_GetRotateBuildOccupy3TileList(occupyTileIdList)
    local result = {}
    if #occupyTileIdList ~= 3 then
        return occupyTileIdList
    end
    local tileId1 = occupyTileIdList[1]
    local tileId2 = occupyTileIdList[2]
    local tileId3 = occupyTileIdList[3]
    local newTileId1 = tileId1
    local newTileId2 = tileId3
    local newTileId3 = tileId2
    local tile1 = self._Planet:GetTile(tileId1)
    local tile2 = self._Planet:GetTile(tileId2)
    for i = 0, tile1:GetNeighborIds().Count - 1 do
        for j = 0, tile2:GetNeighborIds().Count - 1 do
            if tile1:GetNeighborIds()[i] == tile2:GetNeighborIds()[j] and tile1:GetNeighborIds()[i] ~= tileId3 then
                newTileId2 = tile1:GetNeighborIds()[i]
                break
            end
        end
    end
    result = { newTileId1, newTileId2, newTileId3 }
    return result
end

---销毁当前预放置建筑
function XPlanetIScene:_DeleteCurBuildData()
    self:ResetCurCardTileMaterial()
    self:ResetCurBuildTileMaterial()
    if not XTool.IsTableEmpty(self._CurBuildingList) then
        for index, building in ipairs(self._CurBuildingList) do
            if self._CurBuildIsFloor and self._CurBuildCanBuildDir[index] and self:CheckBuildingCanBeBuild(self._CurBuildBuildingId, building:GetOccupyTileList()) then
                self._Planet:RemoveFloor(building, true)
            end
            building:Release()
        end
    end
    self:_InitCurBuildParams()
end

---确认摆放建筑
function XPlanetIScene:_SetCurBuildIngList()
    for key, building in ipairs(self._CurBuildingList) do
        if self._CurBuildCanBuildDir[key] then
            self._Planet:AddBuilding(building)
            self._Planet:SetBuilding(building)
            XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_BUILDING)

            self:PlayEffect(XPlanetConfigs.GetBuildEffect(), self._Planet:GetBuildingPosition(building:GetOccupyTileList()), building:GetRotation())
        end
    end
    self:ResetCurBuildTileMaterial()
    self:_InitCurBuildParams()
    self:ChangeMode(XPlanetConfigs.SceneMode.None)
end

function XPlanetIScene:PlayEffect(url, position, rotation, callback)
    self._Planet:PlayEffect(url, position, rotation, callback)
end

---前端建造拦截判断
function XPlanetIScene:_CheckCurBuildingListCanBuild()
    -- 建筑为空即束
    if XTool.IsTableEmpty(self._CurBuildCanBuildDir) then
        XUiManager.TipErrorWithKey("PlanetRunningCantBuild")
        self:_DeleteCurBuildData()
        return false
    end

    local isFloorCanBuild = false
    -- 非地板建筑存在不可造即结束
    for _, canBuild in pairs(self._CurBuildCanBuildDir) do
        if not self._CurBuildIsFloor and not canBuild then
            XUiManager.TipErrorWithKey("PlanetRunningCantBuild")
            self:_DeleteCurBuildData()
            return false
        elseif self._CurBuildIsFloor and canBuild then
            isFloorCanBuild = true
        end
    end
    -- 地板建筑皆不可造即结束
    if self._CurBuildIsFloor and not isFloorCanBuild then
        XUiManager.TipErrorWithKey("PlanetRunningCantBuild")
        self:_DeleteCurBuildData()
        return false
    end
    return true
end


--外部接口
--=============================================================
function XPlanetIScene:DeleteBuildingByGuid(guid, cb)
    if not self:CheckIsHavePlanet() then
        return
    end
    local build = self._Planet:GetBuildingByBuildGuid(guid)
    if XTool.IsTableEmpty(build) then
        return
    end
    if not XPlanetWorldConfigs.GetBuildingCanRecovery(build:GetBuildingId()) then
        XUiManager.TipErrorWithKey("PlanetRunningNoCycle")
        return
    end

    local buildingList = {}
    table.insert(buildingList, build)
    self:DeleteBuilding(buildingList, cb)
end

function XPlanetIScene:DeleteBuildingByTileId(tileId, cb)
    local build = self._Planet:GetBuildingByTileId(tileId)
    if XTool.IsTableEmpty(build) then
        return
    end
    if not XPlanetWorldConfigs.GetBuildingCanRecovery(build:GetBuildingId()) then
        XUiManager.TipErrorWithKey("PlanetRunningNoCycle")
        return
    end

    local buildingList = {}
    table.insert(buildingList, build)
    self:DeleteBuilding(buildingList, cb)
end

function XPlanetIScene:DeleteBuilding(buildingList, cb)
    if not self:CheckIsHavePlanet() then
        return
    end
    if XTool.IsTableEmpty(buildingList) then
        return
    end

    local callBack = function()
        for _, build in ipairs(buildingList) do
            self._Planet:RemoveBuilding(build:GetGuid(), false)
        end
        if cb then
            cb()
        end
    end

    if self:CheckIsTalentPlanet() then
        XDataCenter.PlanetManager.RequestTalentDeleteBuild(buildingList, callBack)
    else
        XDataCenter.PlanetManager.RequestStageDeleteBuild(buildingList, callBack)
    end
end

---松开卡牌请求建造
---@return boolean 前端请求是否通过
function XPlanetIScene:RequestInsertBuildingList(tileId, buildId, isQuickBuild)
    if not self:CheckIsHavePlanet() or not XTool.IsNumberValid(buildId) then
        return false
    end
    self:_CreateCurBuildData(tileId, buildId)
    self:ChangeMode(XPlanetConfigs.SceneMode.InBuild)

    if isQuickBuild then
        self:InsertCurBuildingList()
    else
        self:PreSetCurBuildingList()
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_IN_BUILD)
    end
    return true
end

---预放置建筑
function XPlanetIScene:PreSetCurBuildingList()
    if XTool.IsTableEmpty(self._CurBuildingList) then
        return
    end
    for index, building in ipairs(self._CurBuildingList) do
        if self._CurBuildIsFloor then
            if self._CurBuildCanBuildDir[index] and self:CheckBuildingCanBeBuild(self._CurBuildBuildingId, building:GetOccupyTileList()) then
                self._Planet:UpdateBuildTile(building)
            end
        else
            self._Planet:SetTempBuildingModel(building)
        end
    end
    self:UpdateCurBuildTileMaterial()
end

---获取当前预放置建筑坐标(二次确认面板用)
function XPlanetIScene:GetCurPreBuildingListPosition()
    if XTool.IsTableEmpty(self._CurBuildingList) then
        return Vector3.zero
    end
    if self._CurBuildIsFloor then
        return self:GetTileHeightPosition(self._CurBuildingList[1]:GetOccupyTileList()[1])
    else
        return self._Planet:GetTempModelPosition(self._CurBuildingList[1]:GetOccupyTileList())
    end
end

---获取当前预放置建筑坐标(二次确认面板用)
function XPlanetIScene:GetCurBuildingList()
    return self._CurBuildingList
end

---移动预放置建筑
function XPlanetIScene:MoveCurBuildingList(tileId)
    if XTool.IsTableEmpty(self._CurBuildingList) then
        return
    end

    self:ResetCurBuildTileMaterial()
    if self._CurBuildIsFloor then
        for index, building in ipairs(self._CurBuildingList) do
            if self._CurBuildCanBuildDir[index] and self:CheckBuildingCanBeBuild(self._CurBuildBuildingId, building:GetOccupyTileList()) then
                self._Planet:RemoveFloor(building, true)
            end
        end
        self:_CreateCurBuildData(tileId, self._CurBuildBuildingId)
    else
        for key, building in ipairs(self._CurBuildingList) do
            self._CurBuildSelectTileList[key] = tileId
            --占地
            self._CurBuildOccupyTileListDir[key] = self:_CreateBuildOccupyTileList(self._CurBuildSelectTileList[key], self._CurBuildBuildingId)
            --范围
            self._CurBuildRangeTileListDir[key] = self:_CreateBuildRangeTileList(self._CurBuildOccupyTileListDir[key], self._CurBuildBuildingId)
            --能否建造
            self._CurBuildCanBuildDir[key] = self:CheckBuildingCanBeBuild(self._CurBuildBuildingId, self._CurBuildOccupyTileListDir[key])
            --赋值
            building:SetOccupyTileList(self._CurBuildOccupyTileListDir[key])
            building:SetRangeTileList(self._CurBuildRangeTileListDir[key])
        end
    end
    self:PreSetCurBuildingList()
end

---旋转预放置建筑
function XPlanetIScene:RotateCurBuildingList()
    if XTool.IsTableEmpty(self._CurBuildingList) then
        return
    end
    self:ResetCurBuildTileMaterial()
    local occupyType = XPlanetWorldConfigs.GetBuildingGridOccupyType(self._CurBuildBuildingId)
    for key, building in ipairs(self._CurBuildingList) do
        if occupyType == XPlanetWorldConfigs.GridOccupyType.Occupy3 then
            --占地
            self._CurBuildOccupyTileListDir[key] = self:_GetRotateBuildOccupy3TileList(building:GetOccupyTileList())
            --范围
            self._CurBuildRangeTileListDir[key] = self:_CreateBuildRangeTileList(self._CurBuildOccupyTileListDir[key], self._CurBuildBuildingId)
            --能否建造
            self._CurBuildCanBuildDir[key] = self:CheckBuildingCanBeBuild(self._CurBuildBuildingId, self._CurBuildOccupyTileListDir[key])
            --赋值
            building:SetOccupyTileList(self._CurBuildOccupyTileListDir[key])
            building:SetRangeTileList(self._CurBuildRangeTileListDir[key])
            self._Planet:SetTempBuildingModel(building)
            self:UpdateCurBuildTileMaterial()
            return
        else
            self._Planet:RotateBuilding(building, building:GetBuildingDirection())
        end
    end
    self:UpdateCurBuildTileMaterial()
end

---移除预放置建筑
function XPlanetIScene:RemoveCurBuildingList()
    self:ResetCurBuildTileMaterial()
    self:_DeleteCurBuildData()
    self:ChangeMode(XPlanetConfigs.SceneMode.None)
end

---确认摆放预放置建筑
function XPlanetIScene:InsertCurBuildingList()
    -- 检查是否可造
    if not self:_CheckCurBuildingListCanBuild() then
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
        self:ChangeMode(XPlanetConfigs.SceneMode.None)
        return
    end
    local buildingList = {}
    -- 批量建造中过滤不可造的
    local guid = self:CheckIsTalentPlanet() and XDataCenter.PlanetManager.GetTalentBuildGuid() or XDataCenter.PlanetManager.GetStageBuildIncId()
    for key, building in ipairs(self._CurBuildingList) do
        if self._CurBuildCanBuildDir[key] then
            building:SetId(guid + #buildingList)    -- 重设guid
            table.insert(buildingList, building)
        end
    end
    
    if self:CheckIsTalentPlanet() then
        XDataCenter.PlanetManager.RequestTalentInsertBuild(buildingList, handler(self, self._SetCurBuildIngList))
    else
        XDataCenter.PlanetManager.RequestStageInsertBuild(buildingList, handler(self, self._SetCurBuildIngList))
    end
end

---更新当前卡牌选中占地材质
function XPlanetIScene:UpdateCurCardTileMaterial()
    for key, occupyTileList in pairs(self._CurBuildOccupyTileListDir) do
        for _, tileId in pairs(occupyTileList) do
            local canOccupy = self:CheckTileCanBeBuildOccupy(tileId, self._CurBuildBuildingId)
            local canBuild = self._CurBuildCanBuildDir[key]
            self:_UpdateTileMaterial(tileId, canBuild, canOccupy)
        end
        -- 关卡场景刷范围
        if not self:CheckIsTalentPlanet() then
            for _, tileIdList in pairs(self._CurBuildRangeTileListDir[key]) do
                for _, tileId in ipairs(tileIdList) do
                    self:_UpdateTileMaterial(tileId, false, false, true)
                end
            end
        end
    end
end

---还原当前卡牌选中占地材质
function XPlanetIScene:ResetCurCardTileMaterial()
    for key, occupyTileList in pairs(self._CurBuildOccupyTileListDir) do
        for _, tileId in pairs(occupyTileList) do
            self:_ResetTileMaterial(tileId)
        end
        -- 关卡场景刷范围
        if not self:CheckIsTalentPlanet() then
            for _, tileIdList in pairs(self._CurBuildRangeTileListDir[key]) do
                for _, tileId in ipairs(tileIdList) do
                    self:_ResetTileMaterial(tileId)
                end
            end
        end
    end
end

---更新预摆放建筑占地材质
function XPlanetIScene:UpdateCurBuildTileMaterial()
    if not XTool.IsNumberValid(self._CurBuildBuildingId) then
        return
    end
    if XTool.IsTableEmpty(self._CurBuildingList) then
        return
    end
    for key, _ in pairs(self._CurBuildingList) do
        for _, tileId in pairs(self._CurBuildOccupyTileListDir[key]) do
            local canOccupy = self:CheckTileCanBeBuildOccupy(tileId, self._CurBuildBuildingId)
            local canBuild = self._CurBuildCanBuildDir[key]
            self:_UpdateTileMaterial(tileId, canBuild, canOccupy)
        end
        -- 关卡场景刷范围
        if not self:CheckIsTalentPlanet() then
            for _, tileIdList in pairs(self._CurBuildRangeTileListDir[key]) do
                for _, tileId in ipairs(tileIdList) do
                    self:_UpdateTileMaterial(tileId, false, false, true)
                end
            end
        end
    end
end

---还原当前预摆放建筑占地材质
function XPlanetIScene:ResetCurBuildTileMaterial()
    if not XTool.IsNumberValid(self._CurBuildBuildingId) then
        return
    end
    if XTool.IsTableEmpty(self._CurBuildingList) then
        return
    end
    for key, _ in pairs(self._CurBuildingList) do
        for _, tileId in pairs(self._CurBuildOccupyTileListDir[key]) do
            self:_ResetTileMaterial(tileId)
        end
        -- 关卡场景刷范围
        if not self:CheckIsTalentPlanet() then
            for _, tileIdList in pairs(self._CurBuildRangeTileListDir[key]) do
                for _, tileId in ipairs(tileIdList) do
                    self:_ResetTileMaterial(tileId)
                end
            end
        end
    end
end

---@param building XPlanetBuilding
function XPlanetIScene:ShowRangeTileMaterial(building)
    if self:CheckIsTalentPlanet() or XTool.IsTableEmpty(building) or XTool.IsTableEmpty(building:GetRangeTileList()) then
        return
    end
    for _, rangeTileList in pairs(building:GetRangeTileList()) do
        for _, tileId in ipairs(rangeTileList) do
            self:_UpdateTileMaterial(tileId, false, false, true)
        end
    end
end

---@param building XPlanetBuilding
function XPlanetIScene:ResetRangeTileMaterial(building)
    if self:CheckIsTalentPlanet() or XTool.IsTableEmpty(building) or XTool.IsTableEmpty(building:GetRangeTileList()) then
        return
    end
    for _, rangeTileList in pairs(building:GetRangeTileList()) do
        for _, tileId in ipairs(rangeTileList) do
            self:_ResetTileMaterial(tileId)
        end
    end
end
--endregion


--region 星球操作数据接口
---球Transform
---@return Transform
function XPlanetIScene:GetPlanet()
    if not self:CheckIsHavePlanet() then
        return Vector3.zero
    end
    return self._Planet:GetTransform()
end

---球心坐标
---@return Vector3
function XPlanetIScene:GetPlanetPosition()
    if not self:CheckIsHavePlanet() then
        return Vector3.zero
    end
    return self._Planet:GetTransform().position
end

---地板:获取地块上表面中心坐标
function XPlanetIScene:GetTileHeightPosition(tileId)
    if not self:CheckIsHavePlanet() then
        return
    end
    local tile = self._Planet:GetTile(tileId)
    return tile:GetHeightPosition()
end

---地板:获取地块up方向向量
function XPlanetIScene:GetTileUp(tileId)
    if not self:CheckIsHavePlanet() then
        return
    end
    return self._Planet:GetTile(tileId):GetTileUp()
end

---道路:获取星球道路网格起点
function XPlanetIScene:GetRoadMapStartPoint()
    return XPlanetWorldConfigs.GetRoadStartPointByStageId(self._StageId)
end

---道路:获取道路下一个目标点
function XPlanetIScene:GetNextRoadTileId(tileId)
    local map = self:GetRoadMap()
    local roadTile = map[tileId]
    if roadTile then
        return map[tileId].NextPoint
    end
    return 0
end

---道路:获取道路上一个目标点
function XPlanetIScene:GetBeforeRoadTileId(tileId)
    local map = self:GetRoadMap()
    local roadTile = map[tileId]
    if roadTile then
        return map[tileId].BeforePoint
    end
    return 0
end

---道路:读取星球道路网格
function XPlanetIScene:GetRoadMap()
    return XPlanetWorldConfigs.GetPlanetRoadMap(self._StageId)
end

function XPlanetIScene:GetBuildingList()
    if not self:CheckIsHavePlanet() then
        return false
    end
    return self._Planet:GetAllBuildingObj()
end
--endregion


--region 星球操作判断
---检查是否存在星球
function XPlanetIScene:CheckIsHavePlanet()
    return self._Planet ~= nil
end

---检查是否存在相机
function XPlanetIScene:CheckIsHaveCamera()
    return self:CheckIsHavePlanet() and self._PlanetCamera ~= nil
end

---检测该场景是否是天赋球场景
function XPlanetIScene:CheckIsTalentPlanet()
    return XPlanetWorldConfigs.GetTalentStageId() == self._StageId
end

---建造:检查某地块是否可作为建筑的占地
function XPlanetIScene:CheckTileCanBeBuildOccupy(tileId)
    if not self:CheckTileGridType(tileId, XPlanetWorldConfigs.GridType.BuildingGrid) then
        return false
    end
    if self:CheckTileIsHaveBuild(tileId) then
        return false
    end
    --if not self:CheckTileIsHexagon(tileId) then
    --    return false
    --end
    return true
end

---建造:检查某建筑是否可建造
---@param buildingId number
---@param occupyTileList table
function XPlanetIScene:CheckBuildingCanBeBuild(buildingId, occupyTileList)
    local tileCanBeOccupy = true
    for _, tileId in ipairs(occupyTileList) do
        if not self:CheckTileCanBeBuildOccupy(tileId) then
            tileCanBeOccupy = false
        end
    end
    if self:CheckIsTalentPlanet() then
        return tileCanBeOccupy
    end
    local buildType = XPlanetWorldConfigs.GetBuildingBuildType(buildingId)
    if buildType == XPlanetWorldConfigs.BuildType.RoadBuild or buildType == XPlanetWorldConfigs.BuildType.RoadCallMonsterBuild then
        for _, tileId in ipairs(occupyTileList) do
            local neighborIds = self._Planet:GetTile(tileId):GetNeighborIds()
            for i = 0, neighborIds.Count - 1 do
                local id = neighborIds[i]
                if self:CheckTileGridType(id, XPlanetWorldConfigs.GridType.RoadGrid) then
                    return tileCanBeOccupy
                end
            end
        end
        return false
    end
    return tileCanBeOccupy
end

---地块:检查两地块是否是相邻
function XPlanetIScene:CheckTileIsNeighbor(tileIdA, tileIdB)
    if not self:CheckIsHavePlanet() then
        return false
    end
    return self._Planet:GetTile(tileIdA):CheckIsNeighbor(tileIdB)
end

---检查地板类型
---@param gridType number XPlanetWorldConfigs.GridType
function XPlanetIScene:CheckTileGridType(tileId, gridType)
    local tileData = self._Planet:GetTileData(tileId)
    if XTool.IsTableEmpty(tileData) then
        return false
    end
    return tileData:GetGridType() == gridType
end

---检查地块是否有建筑
function XPlanetIScene:CheckTileIsHaveBuild(tileId)
    local tileData = self._Planet:GetTileData(tileId)
    if XTool.IsTableEmpty(tileData) then
        return false
    end
    return tileData:GetBuildingGuid() >= 0
end

---检查地块是默认建筑
function XPlanetIScene:CheckTileIsDefaultBuild(tileId)
    local tileData = self._Planet:GetTileData(tileId)
    if XTool.IsTableEmpty(tileData) then
        return false
    end
    return XTool.IsNumberValid(tileData:GetBuildingCenter())
end

---检查地块是否是六边形
function XPlanetIScene:CheckTileIsHexagon(tileId)
    local tile = self._Planet:GetTile(tileId)
    if XTool.UObjIsNil(tile) then
        return false
    end
    return tile.isHexagon
end
--endregion


--region 场景加载
function XPlanetIScene:OnLoadSuccess()
    self:InitPlanetRoot()
    self:InitAirEffect()
    self:InitSceneEffect()
    self:InitSkyBox()
    self:InitTopNode()

    self.GoInputHandler = self._PlanetRoot:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self._PlanetRoot.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
end

function XPlanetIScene:Load(onLoadCb)
    if not self:CheckBeforeLoad() then
        return
    end
    local assetPath = self:GetAssetPath()
    local resource = CS.XResourceManager.LoadAsync(assetPath)
    CS.XTool.WaitCoroutine(resource, function()
        if not (resource and resource.Asset) then
            XLog.Error("restaurant load resource error: asset path = " .. assetPath)
            return
        end

        self._Resource = resource
        self._GameObject = XUiHelper.Instantiate(resource.Asset)
        if not XTool.UObjIsNil(self._GameObject) then
            self._Transform = self._GameObject.transform
            self:ResetTransform()
            self._GameObject.name = self:GetObjName()
        end
        self:OnLoadSuccess()

        self:InitCamera()
        self:InitPlanet(function()
            self:SetSkyBox()
            self:SetSceneEffect()
            self:SetTopNode(self._PlanetCamera:GetCameraTransform(), self._Planet:GetTransform())
            self:InitAfterLoad()
            if onLoadCb then
                onLoadCb()
            end
        end)
    end)
end

---加载模型后初始化接口
function XPlanetIScene:InitAfterLoad()
end

function XPlanetIScene:Release()
    self:TryDestroy(self._GameObject)
    self._GameObject = nil
    self._Transform = nil

    if self._Resource then
        self._Resource:Release()
        self._Resource = nil
    end

    if self._Planet then
        self._Planet:Release()
    end
    if self._PlanetCamera then
        self._PlanetCamera:Release()
    end
    self._Planet = nil
    self._PlanetCamera = nil
    
    self._EffectStar = nil
    self._EffectLiuXing = nil
    self:ClearUiEventListener()
end

function XPlanetIScene:SetActive(active)
    if not self:Exist() then
        return
    end
    self._GameObject:SetActiveEx(active)
end
--endregion


--region 场景对象初始化
function XPlanetIScene:InitSceneEffect()
    self._GroupParticle = self._GameObject:FindTransform("GroupParticle")
    if XTool.UObjIsNil(self._GroupParticle) then
        return
    end
    self._EffectLiuXing = self._GroupParticle.gameObject:FindTransform("Fx03604liiuxing")
end

function XPlanetIScene:SetSceneEffect()
    if self._GroupParticle then
        self._GroupParticle:SetParent(self._PlanetCamera:GetCameraTransform(), false)
        self._GroupParticle.transform.localPosition = Vector3.zero
        self._GroupParticle.transform.localRotation = CS.UnityEngine.Quaternion.identity
        self._GroupParticle.transform.localScale = Vector3.one
    end
    if self._EffectLiuXing then
        self._EffectLiuXing:SetParent(self._PlanetAirEffectRoot, false)
        self._EffectLiuXing.transform.position = Vector3(0, 0, 50)
    end
end

function XPlanetIScene:InitAirEffect()
    self._PlanetAirEffectRoot = self._Transform:Find("GroupBase/PlanetAirEffectRoot")
    if XTool.UObjIsNil(self._PlanetAirEffectRoot) then
        return
    end
    self._AirEffect = self._PlanetAirEffectRoot:GetChild(0)
    self._AirEffect.localPosition = Vector3.zero
end

function XPlanetIScene:InitPlanetRoot()
    self._PlanetRoot = self._Transform:Find("GroupBase/PlanetRoot")
    if XTool.UObjIsNil(self._PlanetRoot) then
        local groupBase = self._Transform:Find("GroupBase")
        local go = CS.UnityEngine.GameObject("PlanetRoot")
        go.transform:SetParent(groupBase, false)
        self:TryResetTransform(go.transform)
        self._PlanetRoot = go.transform
    end
end

function XPlanetIScene:InitSkyBox()
    if XTool.UObjIsNil(self._XSkyBox) then
        self._XSkyBox = self._GameObject:FindTransform("XSkybox")
        self._XSkyBox.localPosition = Vector3.zero
    end
end

function XPlanetIScene:SetSkyBox()
    if self._XSkyBox then
        self._XSkyBox:SetParent(self._PlanetCamera:GetCameraTransform(), false)
        self._XSkyBox.transform.localPosition = XPlanetConfigs.GetPositionByKey("SkyBoxOffset")
        self._XSkyBox.transform.localRotation = XPlanetConfigs.GetRotationByKey("SkyBoxRotation")
        self._XSkyBox.transform.localScale = XPlanetConfigs.GetPositionByKey("SkyBoxScale")
    end
end

function XPlanetIScene:InitTopNode()
    local topNodeTran = self._Transform:Find("GroupBase/TopNode")
    if XTool.UObjIsNil(topNodeTran) then
        return
    end
    self._PlanetTopNode = topNodeTran.gameObject:GetComponent(typeof(CS.PlanetTopNode))
end

function XPlanetIScene:SetTopNode(camTran, planetTran)
    if not self._PlanetTopNode then
        return
    end
    self._PlanetTopNode.CameraNode = camTran
    self._PlanetTopNode.PlanetNode = planetTran
end

function XPlanetIScene:InitCamera()
    local cameraRoot = self._Transform:Find("CameraRoot")
    if XTool.UObjIsNil(cameraRoot) then
        local go = CS.UnityEngine.GameObject("CameraRoot")
        go.transform:SetParent(self._Transform, false)
        self:TryResetTransform(go.transform)
        cameraRoot = go
    end
    if XTool.UObjIsNil(self._PlanetCamera) then
        self._PlanetCamera = XPlanetCamera.New(self._Transform, cameraRoot)
    end

    self:RegisterUiEventListener(function()
        self._PlanetCamera:FreeModeBeginDrag()
    end, XPlanetConfigs.SceneUiEventType.OnBeginDrag)
    self:RegisterUiEventListener(function(eventData)
        self._PlanetCamera:FreeModeOnDrag(eventData)
    end, XPlanetConfigs.SceneUiEventType.OnDrag)
    self:RegisterUiEventListener(function()
        self._PlanetCamera:FreeModeEndDrag()
    end, XPlanetConfigs.SceneUiEventType.OnEndDrag)
end

function XPlanetIScene:InitPlanet(onLoadCb)
    self._Planet = XPlanet.New(self._PlanetRoot, self._StageId)
    self._Planet:Load(onLoadCb)
end
--endregion


--region 场景交互
---注册交互响应
---@param func function function(eventData)
---@param uiEventType number XPlanetConfigs.SceneUiEventType 交互类型
function XPlanetIScene:RegisterUiEventListener(func, uiEventType)
    if XTool.UObjIsNil(self.GoInputHandler) then
        return
    end
    if uiEventType == XPlanetConfigs.SceneUiEventType.OnClick then
        self.GoInputHandler:AddPointerClickListener(func)
    elseif uiEventType == XPlanetConfigs.SceneUiEventType.OnPointerDown then
        self.GoInputHandler:AddPointerDownListener(func)
    elseif uiEventType == XPlanetConfigs.SceneUiEventType.OnPointerUp then
        self.GoInputHandler:AddPointerUpListener(func)
    elseif uiEventType == XPlanetConfigs.SceneUiEventType.OnBeginDrag then
        self.GoInputHandler:AddBeginDragListener(func)
    elseif uiEventType == XPlanetConfigs.SceneUiEventType.OnDrag then
        self.GoInputHandler:AddDragListener(func)
    elseif uiEventType == XPlanetConfigs.SceneUiEventType.OnEndDrag then
        self.GoInputHandler:AddEndDragListener(func)
    end
end

---清空交互响应事件
function XPlanetIScene:ClearUiEventListener()
    if XTool.UObjIsNil(self.GoInputHandler) then
        return
    end
    self.GoInputHandler:RemoveAllListeners()
end

---当拖拽建筑卡牌时
---@param buildId number
function XPlanetIScene:OnDragBuildCard(buildId, cb, tile)
    if not self:CheckIsInNoneMode() then
        return
    end
    self:ResetCurCardTileMaterial()
    if not XTool.IsNumberValid(buildId) then
        return
    end
    if not tile then
        tile = self:GetCameraRayTile()
    end
    if XTool.UObjIsNil(tile) then
        return
    end
    local tileId = tile.TileId
    self:_CreateCurBuildData(tileId, buildId)
    self:UpdateCurCardTileMaterial()
end

---当松开建筑卡牌时
---@param buildId number
---@param isQuickBuild boolean
function XPlanetIScene:OnEndDragBuildCard(buildId, isQuickBuild, cb, tile)
    if not self:CheckIsInNoneMode() then
        return
    end
    if not XTool.IsNumberValid(buildId) then
        return
    end
    self:ResetCurCardTileMaterial()
    if not tile then
        tile = self:GetCameraRayTile()
    end
    if XTool.UObjIsNil(tile) then
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
        return
    end

    local tileId = tile.TileId
    --self._PlanetCamera:FreeModeLookAt(tile.transform.position)

    if not self:RequestInsertBuildingList(tileId, buildId, isQuickBuild, cb) then
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    end
end
--endregion
return XPlanetIScene