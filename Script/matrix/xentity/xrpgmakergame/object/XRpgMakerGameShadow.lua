local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs

local DefaultHp = 100

local Default = {
    _CurrentHp = 100,       --当前血量
    _FaceDirection = 0,     --朝向
    _KillByTrapRound = 0,
}

--影子对象
local XRpgMakerGameShadow = XClass(XRpgMakerGameObject, "XRpgMakerGameShadow")

function XRpgMakerGameShadow:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self:InitData()
end

function XRpgMakerGameShadow:InitData()
    local shadowId = self:GetId()
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameShadowX(shadowId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameShadowY(shadowId)
    local direction = XRpgMakerGameConfigs.GetRpgMakerGameShadowDirection(shadowId)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
    self:SetFaceDirection(direction)
    self:SetCurrentHp(DefaultHp)
end

function XRpgMakerGameShadow:UpdateData(data)
    self._CurrentHp = data.CurrentHp
    self._FaceDirection = data.FaceDirection
    self._KillByTrapRound = data.KillByTrapRound
    self:UpdatePosition(data)
end

function XRpgMakerGameShadow:SetCurrentHp(hp)
    self._CurrentHp = hp
end

function XRpgMakerGameShadow:SetFaceDirection(faceDirection)
    self._FaceDirection = faceDirection
end

function XRpgMakerGameShadow:GetFaceDirection()
    return self._FaceDirection
end

function XRpgMakerGameShadow:GetCurrentHp()
    return self._CurrentHp
end

function XRpgMakerGameShadow:Die()
    self:SetCurrentHp(0)
end

function XRpgMakerGameShadow:IsAlive()
    return self._CurrentHp > 0
end

function XRpgMakerGameShadow:UpdateObjPosAndDirection()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local x = self:GetPositionX()
    local y = self:GetPositionY()
    local direction = self:GetFaceDirection()
    local cubePosition = self:GetCubeUpCenterPosition(y, x)
    cubePosition.y = transform.position.y
    self:SetGameObjectPosition(cubePosition)
    self:ChangeDirectionAction({Direction = direction})
end

--检查是否死亡
function XRpgMakerGameShadow:CheckIsDeath()
    local currentHp = self:GetCurrentHp()
    local isDeath = currentHp <= 0
    self:SetActive(not isDeath)
end

function XRpgMakerGameShadow:OnLoadComplete()
    XRpgMakerGameShadow.Super.OnLoadComplete(self)

    if not self.RoleModelPanel then
        return
    end

    local modelKey = self:GetModelKey()
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(modelKey)
    self.RoleModelPanel:LoadEffect(effectPath, modelKey, true, true, true)
end

return XRpgMakerGameShadow