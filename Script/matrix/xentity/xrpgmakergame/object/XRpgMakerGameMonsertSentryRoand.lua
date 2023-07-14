local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3

--显示剩余回合数的哨戒指示物
local XRpgMakerGameMonsertSentryRoand = XClass(XRpgMakerGameObject, "XRpgMakerGameMonsertSentryRoand")

function XRpgMakerGameMonsertSentryRoand:Load(position, x, y)
    local modelKey = XRpgMakerGameConfigs.ModelKeyMaps.SentryRoand
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)

    local cubeObj = self:GetCubeTransform(y, x)
    self:LoadModel(modelPath, cubeObj, nil, modelKey)      --特效绑定在cube上，绑定在怪物上会被改变旋转角度

    self:SetGameObjectPosition(position)
end

return XRpgMakerGameMonsertSentryRoand