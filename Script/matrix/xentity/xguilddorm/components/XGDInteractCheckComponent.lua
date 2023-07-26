local Vector3 = CS.UnityEngine.Vector3
local DeviceMask = CS.UnityEngine.LayerMask.GetMask("Device")
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
---@class XGDInteractCheckComponent : XGDComponet
local XGDInteractCheckComponent = XClass(XGDComponet, "XGDInteractCheckComponent")

---@param role XGuildDormRole
---@param room XGuildDormRoom
function XGDInteractCheckComponent:Ctor(role, room)
    self.Role = role
    self.Transform = nil    
    ---@type XGuildDormSceneManager
    self.SceneManager = XDataCenter.GuildDormManager.SceneManager
    -- self.MoveAgent = nil
    self.SignalData = XSignalData.New()
    self.NpcPhysicastOffset = Vector3(0, 0.5, -0.5)
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
    local hit = self.Transform:PhysicsRayCast(self.Transform.rotation * self.NpcPhysicastOffset, self.Transform.rotation * Vector3.forward, DeviceMask, 1)
    if XTool.UObjIsNil(hit) then 
        hit = self.Transform:PhysicsRayCast(Vector3.zero, Vector3.down, DeviceMask, 1)
        if XTool.UObjIsNil(hit) then 
            self:ClearInteractStatus()
            return 
        end
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
    self.Role:UpdateCurrentInteractInfo(entity:GetInteractInfoList())
    self.SignalData:EmitSignal("InteractChanged", true, self.Role:GetPlayerId())
end

return XGDInteractCheckComponent