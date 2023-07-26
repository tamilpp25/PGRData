local Quaternion = CS.UnityEngine.Quaternion
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGuildDormHelper = CS.XGuildDormHelper
---@class XGDFurnitureInteractComponent : XGDComponet
local XGDFurnitureInteractComponent = XClass(XGDComponet, "XGDFurnitureInteractComponent")

---@param role XGuildDormRole
function XGDFurnitureInteractComponent:Ctor(role)
    self.Role = role
    self.MoveAgent = nil
    self.Transform = nil
    self.AngleSpeed = XGuildDormConfig.GetRoleInteracAngleSpeed()
    self.IsDirectInteract = false
end

function XGDFurnitureInteractComponent:Init()
    XGDFurnitureInteractComponent.Super.Init(self)
    self:UpdateRoleDependence()
end

function XGDFurnitureInteractComponent:UpdateRoleDependence()
    self.MoveAgent = self.Role:GetMoveAgent()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDFurnitureInteractComponent:BeginInteract(currentInteractInfo, isDirectInteract)
    if isDirectInteract == nil then isDirectInteract = false end
    if self.Transform:EqualsPosition2D(currentInteractInfo.InteractPos.transform.position, 0.0001) then
        isDirectInteract = true
    end
    self.IsDirectInteract = isDirectInteract
    self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.Begin)
    local agent = self.Role:GetAgent()
    if agent then
        local dict = {}
        dict["button"] = XGlobalVar.BtnGuildDormMain.BtnFurnitureInteract
        dict["role_level"] = XPlayer.GetLevel() 
        dict["can_get_reward"] = agent.Proxy.LuaAgentProxy:CheckCanGetReward()
        dict["furniture_id"] = currentInteractInfo.Id
        CS.XRecord.Record(dict, "200006", "GuildDorm")
    end
    -- 设置导航中交互点
    if isDirectInteract then
        local tempPos = currentInteractInfo.InteractPos.transform.position
        tempPos.y = self.Transform.position.y
        self.Transform.position = tempPos
        self.Transform.rotation = currentInteractInfo.InteractPos.transform.rotation
    else
        if not self.MoveAgent:SetDestination(currentInteractInfo.InteractPos.transform) then
            XLog.Error("当前家具交互导航点错误，无法前往。家具Id:" .. currentInteractInfo.Id)
            XScheduleManager.ScheduleOnce(function()
                self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.End)
            end, 1)
            return
        end
    end
    -- 改变状态
    self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
    self.Role:EnableCharacterController(false)
end

function XGDFurnitureInteractComponent:Update(dt)
    if self.MoveAgent.IsArrive or self.IsDirectInteract then
        if self.Role:GetInteractStatus() == XGuildDormConfig.InteractStatus.Begin then
            local currentInteractInfo = self.Role:GetCurrentInteractInfo()
            self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
            self.Role:PlayBehaviorByType(currentInteractInfo.BehaviorType)
            self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.Playing)
        elseif self.Role:GetInteractStatus() == XGuildDormConfig.InteractStatus.Playing then
            local turnToData = self.Role:GetAgent():GetVarDicByKey("TurnToData")
            if turnToData == nil then return end
            if XGuildDormHelper.SlerpTransformRotation(self.Transform, turnToData.rotation, self.AngleSpeed * dt) then
                if turnToData.finishedCb then turnToData.finishedCb() end
                self.Role:GetAgent():SetVarDicByKey("TurnToData", nil)
            end
        end
    end
end

return XGDFurnitureInteractComponent