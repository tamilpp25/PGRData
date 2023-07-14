local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation

local Default = {
    _ElectricStatus = 1,       --状态，1开启，0关闭
}

--电网对象
local XRpgMakerGameElectricFence = XClass(XRpgMakerGameObject, "XRpgMakerGameElectricFence")

function XRpgMakerGameElectricFence:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self:InitData()
end

function XRpgMakerGameElectricFence:Dispose()
    if self.ElectricFenceEffect then
        CS.UnityEngine.GameObject.Destroy(self.ElectricFenceEffect)
        self.ElectricFenceEffect = nil
    end
    XRpgMakerGameElectricFence.Super.Dispose(self)
end

function XRpgMakerGameElectricFence:InitData()
    local id = self:GetId()
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceX(id)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceY(id)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:SetElectricStatus(XRpgMakerGameConfigs.XRpgMakerGameElectricFenceStatus.Open)
end

--改变方向
function XRpgMakerGameElectricFence:ChangeDirectionAction(action, cb)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local electricFenceId = self:GetId()
    local x = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceX(electricFenceId)
    local y = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceY(electricFenceId)
    local cube = self:GetCubeObj(y, x)
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

function XRpgMakerGameElectricFence:SetElectricStatus(electricStatus)
    self._ElectricStatus = electricStatus
end

--播放状态切换动画
function XRpgMakerGameElectricFence:PlayElectricFenceStatusChangeAction(cb, isNotPlaySound)
    if self.ElectricFenceEffect then
        local isShow = self._ElectricStatus == XRpgMakerGameConfigs.XRpgMakerGameElectricFenceStatus.Open and true or false
        self.ElectricFenceEffect.gameObject:SetActiveEx(isShow)
    end

    if cb then
        cb()
    end
end

--是否会被阻挡
function XRpgMakerGameElectricFence:IsElectricFenceInMiddle(curPosX, curPosY, direction, nextPosX, nextPosY)
    if not self:IsSamePoint(curPosX, curPosY) and not self:IsSamePoint(nextPosX, nextPosY)  then
        return false
    end

    local id = self:GetId()
    local electricDirection = XRpgMakerGameConfigs.GetRpgMakerGameElectricDirection(id)
    if self:IsSamePoint(curPosX, curPosY) and electricDirection == direction then
        return true
    end

    --下一个坐标和电墙位置相同，且方向相反
    if self:IsSamePoint(nextPosX, nextPosY)
        and ((electricDirection == XRpgMakerGameConfigs.RpgMakerGapDirection.GridLeft and direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight)
        or (electricDirection == XRpgMakerGameConfigs.RpgMakerGapDirection.GridRight and direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft)
        or (electricDirection == XRpgMakerGameConfigs.RpgMakerGapDirection.GridTop and direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown)
        or (electricDirection == XRpgMakerGameConfigs.RpgMakerGapDirection.GridBottom and direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp)) then
        return true
    end

    return false
end

function XRpgMakerGameElectricFence:OnLoadComplete()
    local key = XRpgMakerGameConfigs.ModelKeyMaps.ElectricFenceEffect
    local modelPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(key)
    local resource = self:ResourceManagerLoad(modelPath)
    local asset = resource and resource.Asset
    if asset then
        self.ElectricFenceEffect = self:LoadEffect(asset)
    end
    XRpgMakerGameElectricFence.Super.OnLoadComplete(self)
end

return XRpgMakerGameElectricFence