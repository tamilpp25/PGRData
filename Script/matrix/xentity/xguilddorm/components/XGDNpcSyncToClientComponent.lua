local MathLerp = CS.UnityEngine.Mathf.Lerp
local Quaternion = CS.UnityEngine.Quaternion
local Vector3 = CS.UnityEngine.Vector3
---@class XGDNpcSyncToClientComponent : XGDComponet
local XGDNpcSyncToClientComponent = XClass(XLuaBehaviour, "XGDSyncToClientComponent")

---@param role XGuildDormRole
---@param room XGuildDormRoom
function XGDNpcSyncToClientComponent:Ctor(role, trans,room)
    self.Role = role
    self.Room = room
    self.Transform = trans
    -- 位置
    self.LastPosition = Vector3.zero
    self.CurrentPosition = Vector3.zero
    -- 旋转
    self.LastRotation = Quaternion.identity
    self.CurrentRotation = Quaternion.identity
    -- 更新当前位置时间
    self.UpdateTime = 0
    
    self.lastPosIsEmpty=true

end

function XGDNpcSyncToClientComponent:UpdateCurrentSyncData(position, rotation,ingoreMoveStateChange)
    if self.lastPosIsEmpty then
        self.lastPosIsEmpty=false
        self.Transform.position=position
        self.Transform.rotation=rotation
    end
    self.LastPosition = self.Transform.position
    self.CurrentPosition = position
    self.LastRotation = self.Transform.rotation
    self.CurrentRotation = rotation
    self.UpdateTime = self.Room:GetRunTime()
    self.IngoreMoveStateChange=ingoreMoveStateChange
    if self.Lock then
        self.Lock=false
    end
end

function XGDNpcSyncToClientComponent:SetMoveLock(islock)
    self.Lock=islock
end

function XGDNpcSyncToClientComponent:UpdateRoleDependence()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDNpcSyncToClientComponent:Update()
    if self.Lock then
        return
    end

    if not self.IngoreMoveStateChange then
        self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
    end
    local doTime = self.Room:GetSyncTime() * 2
    local weight = math.min((self.Room:GetRunTime() - self.UpdateTime) * (1 / doTime), 1)

    self.Transform.position = Vector3.Slerp(self.LastPosition, self.CurrentPosition, weight);
    self.Transform.rotation = Quaternion.Slerp(self.LastRotation, self.CurrentRotation, weight);
end

return XGDNpcSyncToClientComponent