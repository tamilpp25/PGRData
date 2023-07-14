local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation

local Default = {
    _BlockStatus = 0,       --状态，1阻挡，0不阻挡
}

--缝隙对象
local XRpgMakerGameGap = XClass(XRpgMakerGameObject, "XRpgMakerGameGap")

function XRpgMakerGameGap:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

--改变方向
function XRpgMakerGameGap:ChangeDirectionAction(action, cb)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local gapId = self:GetId()
    local x = XRpgMakerGameConfigs.GetRpgMakerGameGapX(gapId)
    local y = XRpgMakerGameConfigs.GetRpgMakerGameGapY(gapId)
    local cube = self:GetCubeObj(y, x)
    local cubePosition = cube:GetGameObjUpCenterPosition()
    local cubeSize = cube:GetGameObjSize()

    local objPosition = transform.position
    local direction = action.Direction
    local directionPos
    if direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridLeft then
        directionPos = objPosition - Vector3(cubeSize.x / 2, 0, 0)
    elseif direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridRight then
        directionPos = objPosition + Vector3(cubeSize.x / 2, 0, 0)
    elseif direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridTop then
        directionPos = objPosition + Vector3(0, 0, cubeSize.z / 2)
    elseif direction == XRpgMakerGameConfigs.RpgMakerGapDirection.GridBottom then
        directionPos = objPosition - Vector3(0, 0, cubeSize.z / 2)
    end

    local transform = self:GetTransform()
    local lookRotation = LookRotation(directionPos - objPosition)
    self:SetGameObjectRotation(lookRotation)
    self:SetGameObjectPosition(directionPos)

    if cb then
        cb()
    end
end

return XRpgMakerGameGap