local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

--地图格子对象
local XRpgMakerGameCube = XClass(XRpgMakerGameObject, "XRpgMakerGameCube")

function XRpgMakerGameCube:Ctor(id, gameObject)

end

--获得格子对象上方中心的坐标
function XRpgMakerGameCube:GetGameObjUpCenterPosition()
    local transform = self:GetTransform()
    local centerPoint = XUiHelper.TryGetComponent(transform, "CenterPoint")
    if not centerPoint then
        XLog.Error("未找到地面节点下名为CenterPoint的节点")
    end
    return centerPoint and centerPoint.transform.position
end

return XRpgMakerGameCube