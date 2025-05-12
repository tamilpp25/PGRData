---@class XBigWorldMapControl : XControl
---@field private _Model XBigWorldMapModel
local XBigWorldMapControl = XClass(XControl, "XBigWorldMapControl")

function XBigWorldMapControl:OnInit()
    -- 初始化内部变量
    self._NearDistance = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("MapPinNearDistance")
end

function XBigWorldMapControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldMapControl:RemoveAgencyEvent()

end

function XBigWorldMapControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

function XBigWorldMapControl:InitMapData(worldId, levelId)
    if XTool.IsNumberValid(levelId) and XTool.IsNumberValid(worldId) then
        self._Model:InitPinData(worldId, levelId)
    end
end

function XBigWorldMapControl:GetCurrentNpcTransform()
    return CS.StatusSyncFight.XFightClient.GetCurrentNpcTransform(false)
end

function XBigWorldMapControl:GetCurrentNpcPosition()
    local transform = self:GetCurrentNpcTransform()

    return transform.position
end

function XBigWorldMapControl:GetCurrentCameraTransform()
    local camera = XMVCA.XBigWorldGamePlay:GetCamera()

    if not camera then
        return nil
    end

    return camera.transform
end

function XBigWorldMapControl:GetCurrentAreaGroupId()
    local areaId = self._Model:GetCurrentAreaId()

    if XTool.IsNumberValid(areaId) and self:CheckHasArea(areaId) then
        return self._Model:GetBigWorldMapAreaGroupIdByAreaId(areaId)
    end

    return 0
end

---@return XBWMapPinData[]
function XBigWorldMapControl:GetMapPinDatasByLevelId(levelId)
    return self._Model:GetPinDatasByLevelId(levelId)
end

---@return XBWMapPinData
function XBigWorldMapControl:GetPinDataByLevelIdAndPinId(levelId, pinId)
    return self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)
end

function XBigWorldMapControl:GetMapPosXByLevelId(levelId)
    return self._Model:GetBigWorldMapPosXByLevelId(levelId)
end

function XBigWorldMapControl:GetMapPosZByLevelId(levelId)
    return self._Model:GetBigWorldMapPosZByLevelId(levelId)
end

function XBigWorldMapControl:GetMapPixelRatioByLevelId(levelId)
    return self._Model:GetBigWorldMapPixelRatioByLevelId(levelId)
end

function XBigWorldMapControl:GetMapNameByLevelId(levelId)
    return self._Model:GetBigWorldMapMapNameByLevelId(levelId)
end

function XBigWorldMapControl:GetMapImageByLevelId(levelId)
    return self._Model:GetBigWorldMapBaseImageByLevelId(levelId)
end

function XBigWorldMapControl:GetMapMaxScaleByLevelId(levelId)
    return self._Model:GetBigWorldMapMaxScaleByLevelId(levelId)
end

function XBigWorldMapControl:GetMapMinScaleByLevelId(levelId)
    return self._Model:GetBigWorldMapMinScaleByLevelId(levelId)
end

function XBigWorldMapControl:GetLittleMapScaleByLevelId(levelId)
    local scale = self._Model:GetBigWorldMapLittleMapScaleByLevelId(levelId)

    if not XTool.IsNumberValid(scale) then
        scale = 1
    end

    return scale
end

function XBigWorldMapControl:GetMapWidthByLevelId(levelId)
    return self._Model:GetBigWorldMapWidthByLevelId(levelId)
end

function XBigWorldMapControl:GetMapHeightByLevelId(levelId)
    return self._Model:GetBigWorldMapHeightByLevelId(levelId)
end

function XBigWorldMapControl:GetMapGroupIdsByLevelId(levelId)
    local groupIds = self._Model:GetBigWorldMapAreaGroupIdsByLevelId(levelId)
    local result = {}

    if not XTool.IsTableEmpty(groupIds) then
        for _, groupId in pairs(groupIds) do
            table.insert(result, groupId)
        end

        table.sort(result, function(groupIdA, groupIdB)
            local floorIndexA = self:GetFloorIndexByGroupId(groupIdA)
            local floorIndexB = self:GetFloorIndexByGroupId(groupIdB)

            return floorIndexA < floorIndexB
        end)
    end

    return result
end

function XBigWorldMapControl:GetFloorIndexByGroupId(groupId)
    if not XTool.IsNumberValid(groupId) then
        return 0
    end

    return self._Model:GetBigWorldMapAreaGroupFloorIndexByGroupId(groupId)
end

function XBigWorldMapControl:GetAreaIdsByGroupId(groupId)
    return self._Model:GetBigWorldMapAreaGroupAreaIdsByGroupId(groupId)
end

function XBigWorldMapControl:GetMapAreaGroupNameByGroupId(groupId)
    return self._Model:GetBigWorldMapAreaGroupGroupNameByGroupId(groupId)
end

function XBigWorldMapControl:GetAreaNameByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaAreaNameByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaImageByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaAreaImageByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaPosXByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaPosXByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaPosZByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaPosZByAreaId(areaId)
end

function XBigWorldMapControl:GetAreaPixelRatioByAreaId(areaId)
    return self._Model:GetBigWorldMapAreaPixelRatioByAreaId(areaId)
end

function XBigWorldMapControl:GetPinActiveIconByStyleId(styleId)
    return self._Model:GetBigWorldMapPinStyleActiveIconByStyleId(styleId)
end

function XBigWorldMapControl:GetPinUnActiveIconByStyleId(styleId)
    return self._Model:GetBigWorldMapPinStyleUnActiveIconByStyleId(styleId)
end

function XBigWorldMapControl:GetPinIconByStyleId(styleId, isActive)
    if XTool.IsNumberValid(styleId) then
        if isActive then
            return self:GetPinActiveIconByStyleId(styleId)
        end

        return self:GetPinUnActiveIconByStyleId(styleId)
    end

    XLog.Error("XBigWorldMapControl:GetPinIconByStyleId styleId is INVALID! 请检查关卡图钉配置表!")

    return ""
end

function XBigWorldMapControl:GetCollectableCount(levelId)
    return CS.StatusSyncFight.XLevelConfig.GetLevelCollectableSceneObjectCount(levelId)
end

function XBigWorldMapControl:GetCollectedCount(worldId, levelId)
    return CS.StatusSyncFight.XWorldSaveSystem.GetLevelCollectedSceneObjectCount(worldId, levelId)
end

function XBigWorldMapControl:GetCollectableText(worldId, levelId)
    local collectableCount = self:GetCollectableCount(levelId)
    local totalCount = self:GetCollectedCount(worldId, levelId)

    return string.format("%d/%d", totalCount, collectableCount)
end

function XBigWorldMapControl:GetCurrentTrackPins(levelId)
    return self._Model:GetAllTrackPinsByLevelId(levelId)
end

function XBigWorldMapControl:GetMapScreenRect(transform, scale)
    local width = CS.UnityEngine.Screen.width
    local height = CS.UnityEngine.Screen.height
    local centerPosition = self:ScreenToRectPosition2D(transform, width / 2, height / 2)
    local scaleWidth = width / scale
    local scaleHeight = height / scale

    return CS.UnityEngine.Rect(centerPosition.x - scaleWidth / 2, centerPosition.y - scaleHeight / 2, scaleWidth,
        scaleHeight)
end

function XBigWorldMapControl:GetOutScreenTranckPins(levelId, transform, scale, pixelRatio)
    local pinIds = self:GetCurrentTrackPins(levelId)
    local result = {}

    if not XTool.IsTableEmpty(pinIds) then
        if not XTool.IsNumberValid(pixelRatio) then
            pixelRatio = self:GetMapPixelRatioByLevelId(levelId)
        end

        local screenRect = self:GetMapScreenRect(transform, scale)

        for pinId, _ in pairs(pinIds) do
            local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)

            if pinData then
                local pinPosition = pinData:GetWorldPosition2D()
                local trackPos = self:GetOutScreenTranckPosition(levelId, transform, pinPosition.x, pinPosition.y,
                    scale, pixelRatio, screenRect)

                if trackPos then
                    result[pinId] = trackPos
                end
            end
        end
    end

    return result
end

function XBigWorldMapControl:GetOutScreenTranckPosition(levelId, transform, posX, posY, scale, pixelRatio, screenRect)
    if not XTool.IsNumberValid(pixelRatio) then
        pixelRatio = self:GetMapPixelRatioByLevelId(levelId)
    end

    local result = nil
    local mapPosition = self:WorldToMapPosition2D(levelId, posX, posY, pixelRatio)

    screenRect = screenRect or self:GetMapScreenRect(transform, scale)
    if not screenRect:Contains(mapPosition) then
        local centerPos = screenRect.center
        local trackPos = {
            x = 0,
            y = 0,
        }
        local direction = {
            x = 0,
            y = 0,
        }
        local xOffset = mapPosition.x - centerPos.x
        local yOffset = mapPosition.y - centerPos.y

        if mapPosition.x < screenRect.xMin then
            trackPos.x = -(screenRect.width * scale) / 2
            direction.x = -1
        elseif mapPosition.x > screenRect.xMax then
            trackPos.x = (screenRect.width * scale) / 2
            direction.x = 1
        else
            local ratio = (screenRect.height / 2) / math.abs(yOffset)

            trackPos.x = xOffset * ratio
            direction.x = 0
        end
        if mapPosition.y < screenRect.yMin then
            trackPos.y = -(screenRect.height * scale) / 2
            direction.y = -1
        elseif mapPosition.y > screenRect.yMax then
            trackPos.y = (screenRect.height * scale) / 2
            direction.y = 1
        else
            local ratio = (screenRect.width / 2) / math.abs(xOffset)

            trackPos.y = yOffset * ratio
            direction.y = 0
        end

        result = {
            Position = trackPos,
            Direction = direction,
            Angle = self:GetTrackAngle(xOffset, yOffset),
        }
    end

    return result
end

--- 计算向量夹角
function XBigWorldMapControl:GetTrackAngle(x, y)
    local trackVector = Vector2(x, y)
    local angle = Vector2.SignedAngle(Vector2.up, trackVector)

    return angle
end

function XBigWorldMapControl:GetNearDistance()
    if XMain.IsEditorDebug then
        return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("MapPinNearDistance")
    end

    return self._NearDistance
end

---@param pinNodeMap table<number, XUiBigWorldMapPin>
function XBigWorldMapControl:GetScreenPointNearPinDataList(levelId, targetPos, pinNodeMap)
    local result = {}

    if not XTool.IsTableEmpty(pinNodeMap) then
        for id, pinNode in pairs(pinNodeMap) do
            local screenPos = self:WorldToScreenPosition2D(pinNode.Transform.position)

            if self:CheckNearDistance(screenPos, targetPos) then
                local pinData = pinNode:GetPinData()

                if pinData then
                    table.insert(result, pinData)
                end
            end
        end
    end

    return result
end

function XBigWorldMapControl:WorldToScreenPosition2D(worldPos)
    local camera = CS.XUiManager.Instance.UiCamera

    if camera then
        return camera:WorldToScreenPoint(worldPos)
    end

    return Vector2.zero
end

function XBigWorldMapControl:WorldToMapPosition2D(levelId, posX, posZ, pixelRatio)
    if not XTool.IsNumberValid(pixelRatio) then
        pixelRatio = self:GetMapPixelRatioByLevelId(levelId)
    end

    local originX = self:GetMapPosXByLevelId(levelId)
    local originZ = self:GetMapPosZByLevelId(levelId)
    local offsetX = (posX - originX) * pixelRatio
    local offsetZ = (posZ - originZ) * pixelRatio

    return Vector2(offsetX, offsetZ)
end

function XBigWorldMapControl:MapToWorldPosition2D(levelId, posX, posZ, pixelRatio)
    if not XTool.IsNumberValid(pixelRatio) then
        pixelRatio = self:GetMapPixelRatioByLevelId(levelId)
    end

    local originX = self:GetMapPosXByLevelId(levelId)
    local originZ = self:GetMapPosZByLevelId(levelId)
    local offsetX = posX / pixelRatio + originX
    local offsetZ = posZ / pixelRatio + originZ

    return Vector2(offsetX, offsetZ)
end

function XBigWorldMapControl:ScreenToRectPosition2D(transform, posX, posZ)
    local camera = CS.XUiManager.Instance.UiCamera
    local hasValue, rectPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform,
        Vector2(posX, posZ), camera)

    if hasValue then
        return rectPos
    end

    return nil
end

function XBigWorldMapControl:ScreenToWorldPosition2D(levelId, transform, posX, posZ, pixelRatio)
    local screenPos = self:ScreenToRectPosition2D(transform, posX, posZ)

    if screenPos then
        return self:MapToWorldPosition2D(levelId, screenPos.x, screenPos.y, pixelRatio)
    else
        return Vector2.zero
    end
end

function XBigWorldMapControl:CheckCurrentTrackPin(levelId, pinId)
    local currentPinIds = self:GetCurrentTrackPins(levelId)

    return currentPinIds and currentPinIds[pinId]
end

function XBigWorldMapControl:CheckHasTrackPin(levelId)
    return not XTool.IsTableEmpty(self:GetCurrentTrackPins(levelId))
end

function XBigWorldMapControl:CheckHasArea(areaId)
    local configs = self._Model:GetBigWorldMapAreaConfigs()

    return configs and configs[areaId]
end

function XBigWorldMapControl:CheckNearDistance(position, targetPosition)
    local xOffset = position.x - targetPosition.x
    local yOffset = position.y - targetPosition.y
    local distance = math.sqrt(math.pow(xOffset, 2) + math.pow(yOffset, 2))

    return distance <= self:GetNearDistance()
end

function XBigWorldMapControl:TrackPin(levelId, pinId)
    local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        if pinData:IsQuest() then
            if not self:CheckCurrentTrackPin(levelId, pinId) then
                XMVCA.XBigWorldQuest:TrackQuest(pinData.QuestId)
            end
        else
            self:RequestTrackMapPin(levelId, pinId, true)
        end
    end
end

function XBigWorldMapControl:CancelTrackPin(levelId, pinId)
    local pinData = self._Model:GetPinDataByLevelIdAndPinId(levelId, pinId)

    if pinData then
        if pinData:IsQuest() then
            if self:CheckCurrentTrackPin(levelId, pinId) then
                XMVCA.XBigWorldQuest:UnTrackQuest(pinData.QuestId)
            end
        else
            self:RequestTrackMapPin(levelId, pinId, false)
        end
    end
end

function XBigWorldMapControl:SendTeleportCommand(levelId, posX, posY, posZ, eulerAngleY)
    XMVCA.XBigWorldMap:SendTeleportCommand(levelId, posX, posY, posZ, eulerAngleY)
end

function XBigWorldMapControl:SendTrackCommand(levelId, pinId)
    if not self:CheckCurrentTrackPin(levelId, pinId) then
        self._Model:TrackPins(levelId, {
            [pinId] = true,
        })
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_START_TRACK_MAP_PIN, {
            LevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapControl:SendCancelTrackCommand(levelId, pinId)
    if self:CheckCurrentTrackPin(levelId, pinId) then
        self._Model:CancelTrackPins(levelId)
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_STOP_TRACK_MAP_PIN, {
            LevelId = levelId,
            MapPinId = pinId,
        })
    end
end

function XBigWorldMapControl:RequestTrackMapPin(levelId, pinId, isTrack)
    XNetwork.Call("BigWorldSetTrackMapPinIdRequest", {
        MapTrackPinData = {
            WorldId = XMVCA.XBigWorldGamePlay:GetCurrentWorldId(),
            LevelId = levelId,
            TrackPinId = isTrack and pinId or 0,
        },
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if XTool.IsNumberValid(pinId) and isTrack then
            self:SendTrackCommand(levelId, pinId)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, true)
        else
            self:SendCancelTrackCommand(levelId, pinId)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MAP_PIN_TRACK_CHANGE, false)
        end
    end)
end

return XBigWorldMapControl
