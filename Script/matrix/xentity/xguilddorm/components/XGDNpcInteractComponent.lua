local Quaternion = CS.UnityEngine.Quaternion
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGuildDormHelper = CS.XGuildDormHelper
---@class XGDNpcInteractComponent : XGDComponet
local XGDNpcInteractComponent = XClass(XGDComponet, "XGDNpcInteractComponent")

---@param role XGuildDormRole
---@param room XGuildDormRoom
function XGDNpcInteractComponent:Ctor(role, room)
    self.Role = role
    self.Room = room
    self.MoveAgent = nil
    self.Transform = nil
    self.AngleSpeed = XGuildDormConfig.GetRoleInteracAngleSpeed()
    self.IsDirectInteract = false
    self.InteractStatus = XGuildDormConfig.InteractStatus.End
    self.InteractInfo = nil
end

function XGDNpcInteractComponent:Init()
    XGDNpcInteractComponent.Super.Init(self)
    self:UpdateRoleDependence()
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TALK_END,self.EndInteract,self)
end

function XGDNpcInteractComponent:Dispose()
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_TALK_END,self.EndInteract,self)
end

function XGDNpcInteractComponent:UpdateRoleDependence()
    self.MoveAgent = self.Role:GetMoveAgent()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDNpcInteractComponent:BeginInteract(currentInteractInfo, isDirectInteract)
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnNpcInteract
    dict["role_level"] = XPlayer.GetLevel()
    dict["npc_id"] = self.Role:GetId()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    
    self.InteractInfo = currentInteractInfo
    if isDirectInteract == nil then isDirectInteract = false end
    --if self.Transform:EqualsPosition(currentInteractInfo.InteractPos.transform.position, 0.1) then
    --    isDirectInteract = true
    --end
    self.IsDirectInteract = isDirectInteract
    -- 设置导航中交互点
    --if isDirectInteract then
    --    self.Transform.position = currentInteractInfo.InteractPos.transform.position
    --    self.Transform.rotation = currentInteractInfo.InteractPos.transform.rotation
    --else
    --    if not self.MoveAgent:SetDestination(currentInteractInfo.InteractPos.transform) then
    --        XLog.Error("当前npc交互导航点错误，无法前往")
    --        return
    --    end
    --end
    
    -- 交互NPC
    self.Npc = self.Room:GetNpc(self.InteractInfo.Id)
    if self.Npc == nil or self.Npc:GetIsRemove() then
        XLog.Debug("当前NPC无法交互")
        return
    end
    self.Npc:SetIsTalking(true)
    
    XDataCenter.GuildDormManager.SetNpcInteractGameStatus(self.InteractInfo.Id)
    -- 改变状态
    --self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
    self.Role:EnableCharacterController(false)
    self.InteractStatus = XGuildDormConfig.InteractStatus.Begin
    self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.Begin)
end

function XGDNpcInteractComponent:EndInteract()
    self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.End)
end

function XGDNpcInteractComponent:Update(dt)
    if self.InteractStatus == XGuildDormConfig.InteractStatus.End then return end
    if self.InteractStatus == XGuildDormConfig.InteractStatus.Begin then
        --self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
        self.InteractStatus = XGuildDormConfig.InteractStatus.Playing
        self.Npc:PlayBehavior(self.InteractInfo.BehaviorType)
        self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.Playing)
    elseif self.InteractStatus == XGuildDormConfig.InteractStatus.Playing then
        -- 角色旋转
        local targetRotation = XGuildDormHelper.GetEulerAngles(self.Npc:GetRLRole():GetTransform(), self.Transform)
        if XGuildDormHelper.SlerpTransformRotation(self.Transform, targetRotation, self.AngleSpeed * dt) then
            self.InteractStatus = XGuildDormConfig.InteractStatus.End
            self.Role:EnableCharacterController(true)
        end
    end
end

return XGDNpcInteractComponent