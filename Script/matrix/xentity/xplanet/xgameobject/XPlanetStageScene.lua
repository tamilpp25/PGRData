local XPlanetIScene = require("XEntity/XPlanet/XGameObject/XPlanetIScene")
local XPlanetDebugTool = require("XEntity/XPlanet/XPlanetDebugTool")

---@class XPlanetStageScene:XPlanetIScene
local XPlanetStageScene = XClass(XPlanetIScene, "XPlanetStageScene")

function XPlanetStageScene:Ctor(root, stageId)
end

--region 相机轨道
function XPlanetStageScene:UpdateCameraInStage(isDefaultMin, isGuide)
    if not self:CheckIsHaveCamera() then return end
    -- 默认最近
    if isDefaultMin then
        self._PlanetCamera._FreeModeScrollValue = 0
    end
    self._PlanetCamera:ChangeFreeModeByCamera()
    -- 引导入场镜头
    local camRot = XPlanetConfigs.GetGuideCamRootRotOffset(self._StageId)
    if isGuide and camRot then
        self._PlanetCamera:SetCameraRootLocalRotation(camRot)
        return
    end
    local explore = XDataCenter.PlanetExploreManager.GetExplore()
    -- 初始进入定位角色
    if explore and explore:GetCaptainTransform() then
        local rot = self._PlanetCamera:GetTowardRotation(self._PlanetCamera:GetCameraCenterRayPosition(), explore:GetCaptainTransform().position)
        self._PlanetCamera:GetTransform().rotation = rot * self._PlanetCamera:GetTransform().rotation
    end
end

function XPlanetStageScene:UpdateCameraInSettle(callBack)
    if not self:CheckIsHaveCamera() then return end
    local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamStageOver())
    self._PlanetCamera:PlaySound(XPlanetConfigs.SoundCueId.CamNear)
    self._PlanetCamera:ChangeMovieModeByCamera(cam, XDataCenter.PlanetExploreManager.GetExplore():GetCaptainTransform(), nil, callBack)
end

function XPlanetStageScene:UpdateCameraInBoss(entityTran, callBack)
    if not self:CheckIsHaveCamera() then return end
    local value = XPlanetConfigs.GetCamStageBoss()
    self._PlanetCamera:PlaySound(XPlanetConfigs.SoundCueId.CamNear)
    self._PlanetCamera:ChangeFreeModeByCamera(function()
        self._PlanetCamera:FreeModeLookAt(entityTran.position, nil, function()
            self._PlanetCamera:FreeModeScrollToValue(value, nil, callBack)
        end)
    end)
end
--endregion


--region 星球改造
function XPlanetStageScene:GetBuildObjPosition(buildGuid)
    local build = self._Planet:GetBuildingByBuildGuid(buildGuid, false)
    if XTool.IsTableEmpty(build) then
        return
    end
    return self._Planet:GetBuildingPosition(build:GetOccupyTileList())
end
--endregion


--region 场景加载
function XPlanetStageScene:Release()
    self.Super.Release(self)
    self:DebugStopDrawBuffDependence()
end

function XPlanetStageScene:InitAfterLoad()
    self:RegisterUiEventListener(handler(self, self.OnClick), XPlanetConfigs.SceneUiEventType.OnClick)
    self:UpdateCameraInStage()
    self:DebugDrawBuffDependence()
    self:SetSceneStarEffect()
end

function XPlanetStageScene:SetSceneStarEffect()
    if not self._EffectStar then
        self._EffectStar = self._GroupParticle.gameObject:FindTransform("FxScene02304Star (1)")
    end
    if self._EffectStar then
        self._EffectStar.transform.localPosition = XPlanetConfigs.GetPositionByKey("StageStarEffectOffset")
        self._EffectStar.transform.localRotation = XPlanetConfigs.GetRotationByKey("StageStarEffectRotation")
        self._EffectStar.transform.localScale = XPlanetConfigs.GetPositionByKey("StageStarEffectScale")
    end
end

function XPlanetStageScene:GetAssetPath()
    local chapterId = XPlanetStageConfigs.GetStageChapterId(self._StageId)
    return XPlanetStageConfigs.GetChapterStageSceneUrl(chapterId)
end

function XPlanetStageScene:GetObjName()
    return "PlanetStageScene"
end
--endregion


--region 场景交互
function XPlanetStageScene:OnClick(eventData)
    if not self:CheckIsInNoneMode() then
        return
    end
    if XTool.UObjIsNil(eventData.pointerEnter) then return end
    local tile = eventData.pointerEnter.transform:GetComponent(typeof(CS.Planet.PlanetTile))
    if XTool.UObjIsNil(tile) then return end
    local tileId = tile.TileId
    if self:CheckTileIsHaveBuild(tileId) then
        if not self:CheckIsHavePlanet() then return end
        local building = self._Planet:GetBuildingByTileId(tileId)
        if XTool.IsTableEmpty(building) then return end
        self._PlanetCamera:FreeModeLookAt(tile.transform.position)
        self:ShowRangeTileMaterial(building)
        XDataCenter.PlanetManager.RequestStageOpenBuildDetial(building:GetBuildingId(), building:GetGuid(), false, function() 
            self:ResetRangeTileMaterial(building)
        end)
    end
end

function XPlanetStageScene:GetItemRangeTileIdList(itemId, tileId)
    local result = {}
    local itemType = XPlanetStageConfigs.GetItemRange(itemId)
    if itemType == XPlanetStageConfigs.ItemRangeType.Global then
        return result
    end
    table.insert(result, tileId)
    if itemType == XPlanetStageConfigs.ItemRangeType.Three then
        local tile = self._Planet:GetTile(tileId)
        local neighborIds = tile:GetNeighborIds()
        local neighborMaxIndex = neighborIds.Count - 1
        local isFind = false
        for i = 0, neighborMaxIndex do
            if isFind then break end
            for j = 0, neighborMaxIndex do
                if self:CheckTileIsNeighbor(neighborIds[i], neighborIds[j]) then
                    table.insert(result, neighborIds[i])
                    table.insert(result, neighborIds[j])
                    isFind = true
                    break
                end
            end
            
            if i == neighborMaxIndex and not isFind then    -- 找不到可用占地地块返回首两个相邻地块作为模型占地
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
    elseif itemType == XPlanetStageConfigs.ItemRangeType.Seven then
        local tile = self._Planet:GetTile(tileId)
        local neighborIds = tile:GetNeighborIds()
        for i = 0, neighborIds.Count - 1 do
            table.insert(result, neighborIds[i])
        end
    end
    return result
end

function XPlanetStageScene:RefreshItemSelectTileList(tileIdList)
    for _, tileId in pairs(tileIdList) do
        self._Planet:SetTileSelectMat(tileId)
    end
end

function XPlanetStageScene:ClearItemSelectTileList(tileIdList)
    for _, tileId in pairs(tileIdList) do
        self._Planet:ResetTileMaterial(tileId)
    end
end
--endregion


--region Debug
function XPlanetStageScene:InInDebug()
    local Application = CS.UnityEngine.Application
    local RuntimePlatform = CS.UnityEngine.RuntimePlatform
    return Application.platform == RuntimePlatform.WindowsEditor
end

function XPlanetStageScene:DebugDrawBuffDependence()
    if not self:InInDebug() then
        return
    end
    XDataCenter.PlanetManager.RequestDrawCollisionData(function(res)
        XPlanetDebugTool.StartDrawArrow(self, res)
    end)
end

function XPlanetStageScene:DebugStopDrawBuffDependence()
    if not self:InInDebug() then
        return
    end
    XPlanetDebugTool.StopDrawArrow()
    XPlanetDebugTool.ResetDrawMode()
    XPlanetDebugTool.ResetShowTextMode()
end

function XPlanetStageScene:ShowBuildGuid(active)
    if not self:InInDebug() then
        return
    end
    if not self:CheckIsHavePlanet() then return end
    self._Planet:ShowBuildGuid(active)
end

function XPlanetStageScene:ShowTileid(active)
    if not self:InInDebug() then
        return
    end
    if not self:CheckIsHavePlanet() then return end
    self._Planet:ShowTileId(active)
end
--endregion

return XPlanetStageScene