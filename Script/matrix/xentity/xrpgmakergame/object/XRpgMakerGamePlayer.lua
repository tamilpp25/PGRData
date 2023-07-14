local XRpgMakerGameObject = require("XEntity/XRpgMakerGame/Object/XRpgMakerGameObject")

local type = type
local pairs = pairs
local CSXResourceManagerLoad = CS.XResourceManager.Load

local DefaultHp = 100

local Default = {
    _CurrentHp = 100,       --当前血量
    _FaceDirection = 0,     --朝向
}

--玩家对象
local XRpgMakerGamePlayer = XClass(XRpgMakerGameObject, "XRpgMakerGamePlayer")

function XRpgMakerGamePlayer:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerGamePlayer:InitData(mapId, roleId)
    local startPointId = XRpgMakerGameConfigs.GetRpgMakerGameStartPointId(mapId)
    local pointX = XRpgMakerGameConfigs.GetRpgMakerGameStartPointX(startPointId)
    local pointY = XRpgMakerGameConfigs.GetRpgMakerGameStartPointY(startPointId)
    local direction = XRpgMakerGameConfigs.GetRpgMakerGameStartPointDirection(startPointId)
    self:SetId(roleId)
    self:SetFaceDirection(direction)
    self:SetCurrentHp(DefaultHp)
    self:UpdatePosition({PositionX = pointX, PositionY = pointY})
end

function XRpgMakerGamePlayer:UpdateData(data)
    self._CurrentHp = data.CurrentHp
    self._FaceDirection = data.FaceDirection
    self:UpdatePosition(data)
end

function XRpgMakerGamePlayer:SetCurrentHp(hp)
    self._CurrentHp = hp
end

function XRpgMakerGamePlayer:SetFaceDirection(faceDirection)
    self._FaceDirection = faceDirection
end

function XRpgMakerGamePlayer:GetFaceDirection()
    return self._FaceDirection
end

function XRpgMakerGamePlayer:GetCurrentHp()
    return self._CurrentHp
end

function XRpgMakerGamePlayer:Die()
    self:SetCurrentHp(0)
end

function XRpgMakerGamePlayer:IsAlive()
    return self._CurrentHp > 0
end

function XRpgMakerGamePlayer:UpdateObjPosAndDirection()
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

function XRpgMakerGamePlayer:PlayMoveAction(action, cb, mapId)
    local nextAction = XDataCenter.RpgMakerGameManager.GetNextAction(true)
    if nextAction then
        if nextAction.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerDrown then
            self:DieByDrown(mapId, action.EndPosition.PositionX, action.EndPosition.PositionY)
        elseif nextAction.ActionType == XRpgMakerGameConfigs.RpgMakerGameActionType.ActionPlayerTransfer then
            self:SetIsTranser(true)
        end
    end

    local skillType = XRpgMakerGameConfigs.GetRoleSkillType(self:GetId())
    self:CheckIsSteelAdsorb(mapId, action.EndPosition.PositionX, action.EndPosition.PositionY, skillType)
    XRpgMakerGamePlayer.Super.PlayMoveAction(self, action, cb, skillType)
end

--杀死怪物
function XRpgMakerGamePlayer:PlayKillMonsterAction(action, cb)
    local monsterId = action.MonsterId
    local cb = cb
    local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(monsterId)
    self:PlayAtkAction(function()
        monsterObj:PlayBeAtkAction(cb)
        monsterObj:RemoveViewAreaAndLine()
        monsterObj:InitSentryData()
    end)
end

--检查是否死亡
function XRpgMakerGamePlayer:CheckIsDeath()
    local currentHp = self:GetCurrentHp()
    local isDeath = currentHp <= 0
    self:SetActive(not isDeath)
end

--加载即将移动方向的特效
function XRpgMakerGamePlayer:LoadMoveDirectionEffect()
    local direction = self:GetFaceDirection()
    if not direction then
        return
    end

    local moveDirectionEffectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.RoleMoveArrow)
    local resource = self:ResourceManagerLoad(moveDirectionEffectPath)
    local cubeUpCenterPos = self:GetDirectionPos(direction)
    if not cubeUpCenterPos then
        return
    end

    self.MoveDirectionEffectObj = self:LoadEffect(resource.Asset, cubeUpCenterPos)
end

function XRpgMakerGamePlayer:SetMoveDirectionEffectActive(isActive)
    if XTool.UObjIsNil(self.MoveDirectionEffectObj) then
        return
    end

    if self.MoveDirectionEffectObj.gameObject.activeSelf ~= isActive then
        self.MoveDirectionEffectObj.gameObject:SetActiveEx(isActive)
    end
end

return XRpgMakerGamePlayer