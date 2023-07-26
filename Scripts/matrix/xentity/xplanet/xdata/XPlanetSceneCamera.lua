---@class XPlanetSceneCamera
local XPlanetSceneCamera = XClass(nil, "XPlanetSceneCamera")

function XPlanetSceneCamera:Ctor(id)
    self._CameraId = id or false
end

function XPlanetSceneCamera:GetCameraId()
    return self._CameraId
end

function XPlanetSceneCamera:SetCameraId(id)
    self._CameraId = id
end

function XPlanetSceneCamera:GetPosition()
    return XPlanetCameraConfigs.GetCameraPosition(self._CameraId)
end

function XPlanetSceneCamera:GetRotation()
    return XPlanetCameraConfigs.GetCameraRotation(self._CameraId)
end

function XPlanetSceneCamera:GetFov()
return XPlanetCameraConfigs.GetCameraFov(self._CameraId)
end

return XPlanetSceneCamera