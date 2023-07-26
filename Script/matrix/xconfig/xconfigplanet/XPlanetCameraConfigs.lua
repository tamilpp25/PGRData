XPlanetCameraConfigs = XPlanetCameraConfigs or {}
local XPlanetCameraConfigs = XPlanetCameraConfigs

---@type XConfig
local _ConfigCamera

function XPlanetCameraConfigs.Init()
    _ConfigCamera = XConfig.New("Client/PlanetRunning/PlanetRunningSceneCamera.tab", XTable.XTablePlanetRunningSceneCamera, "Id")
end

---@return UnityEngine.Vector3
function XPlanetCameraConfigs.GetCameraPosition(cameraId)
    local position = _ConfigCamera:GetProperty(cameraId, "Position")
    local x = position[1]
    local y = position[2]
    local z = position[3]
    return Vector3(x, y, z)
end

---@return UnityEngine.Quaternion
function XPlanetCameraConfigs.GetCameraRotation(cameraId)
    local rotation = _ConfigCamera:GetProperty(cameraId, "Rotation")
    local x = rotation[1]
    local y = rotation[2]
    local z = rotation[3]
    return CS.UnityEngine.Quaternion.Euler(Vector3(x, y, z))
end

function XPlanetCameraConfigs.GetCameraFov(cameraId)
    return _ConfigCamera:GetProperty(cameraId, "Fov")
end
