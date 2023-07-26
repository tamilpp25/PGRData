local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

--巡逻路线
local XRpgMakerGameMonsterPatrolLine = XClass(XRpgMakerGameObject, "XRpgMakerGameMonsterPatrolLine")

function XRpgMakerGameMonsterPatrolLine:LoadPatrolLine(modelPath, x, y, direction, modelKey)
    local cubeObj = self:GetCubeTransform(y, x)
    self:LoadModel(modelPath, cubeObj, nil, modelKey)      --特效绑定在cube上，绑定在怪物上会被改变旋转角度

    local objPos = self:GetCubeUpCenterPosition(y, x)
    self:SetGameObjectPosition(objPos)

    self:SetGameObjectLookRotation(direction)
end

return XRpgMakerGameMonsterPatrolLine