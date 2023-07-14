local Vector3 = CS.UnityEngine.Vector3
local DeviceMask = CS.UnityEngine.LayerMask.GetMask("Device")
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGDInteractCheckComponent = XClass(XGDComponet, "XGDInteractCheckComponent")

function XGDInteractCheckComponent:Ctor(role, room)
    self.Role = role
    self.Transform = nil    
    self.SceneManager = XDataCenter.GuildDormManager.SceneManager
    -- self.MoveAgent = nil
    self.SignalData = XSignalData.New()
end

function XGDInteractCheckComponent:Init()
    XGDInteractCheckComponent.Super.Init(self)
    self:SetUpdateIntervalTime(0.05)
    self:UpdateRoleDependence()
end

function XGDInteractCheckComponent:UpdateRoleDependence()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDInteractCheckComponent:GetSignalData()
    return self.SignalData
end

function XGDInteractCheckComponent:ClearInteractStatus()
    self.Role:UpdateCurrentInteractInfo(nil)
    self.SignalData:EmitSignal("InteractChanged", false, self.Role:GetPlayerId())
end

function XGDInteractCheckComponent:Update(dt)
    if self.Role:GetInteractStatus() ~= XGuildDormConfig.InteractStatus.End then
        return
    end
    if not self.Role:GetIsOverLastEndInteractTime() then
        return
    end
    --判断射线碰到家私 后期策划可能会需要这段需求，面向家具检测交互
    if DeviceMask == nil then 
        self:ClearInteractStatus()
        return 
    end
    -- local hit = self.Transform:PhysicsRayCast(CS.UnityEngine.Vector3.zero, self.Transform.rotation * CS.UnityEngine.Vector3.forward, DeviceMask, 1)
    local hit = self.Transform:PhysicsRayCastDown(DeviceMask, 1)
    if XTool.UObjIsNil(hit) then 
        self:ClearInteractStatus()
        return 
    end
    local entity = self.SceneManager.GetSceneObjByGameObject(hit.gameObject)
    if entity == nil then 
        self:ClearInteractStatus()
        return 
    end
    if not entity.CheckCanInteract then 
        self:ClearInteractStatus()
        return 
    end
    if not entity:CheckCanInteract() then 
        self:ClearInteractStatus()
        return 
    end
    -- 公会宿舍只拿默认的
    self.Role:UpdateCurrentInteractInfo(entity:GetInteractInfoList()[1])
    self.SignalData:EmitSignal("InteractChanged", true, self.Role:GetPlayerId())
end

return XGDInteractCheckComponent