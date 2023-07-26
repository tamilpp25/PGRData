local Vector3 = CS.UnityEngine.Vector3
local Mathf = CS.UnityEngine.Mathf
local Quaternion = CS.UnityEngine.Quaternion
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
---@class XGDMoveComponent : XGDComponet
local XGDMoveComponent = XClass(XGDComponet, "XGDMoveComponent")

---@param role XGuildDormRole
function XGDMoveComponent:Ctor(role)
    self.Role = role
    -- 角色控制器
    self.CharacterController = nil
    self.Transform = nil
    self.MoveDirection = Vector3.zero
    self.Speed = XGuildDormConfig.GetRoleMoveSpeed()
    self.AngleSpeed = XGuildDormConfig.GetRoleAngleSpeed()
    self.IsZeroDirection = false
    ---@type XGuildDormScene
    self.Scene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()
end

function XGDMoveComponent:Init()
    XGDMoveComponent.Super.Init(self)
    self:UpdateRoleDependence()
end

function XGDMoveComponent:UpdateRoleDependence()
    self.CharacterController = self.Role:GetRLRole():GetCharacterController()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDMoveComponent:Update(dt)
    -- 交互中，不处理移动
    if self.Role:GetIsInteracting() then
        return
    end
    local x, y = self.Role:GetCurrentMoveDirection()
    if (x == 0 and y == 0) 
        and self.IsZeroDirection then
        return
    end
    self.IsZeroDirection = (x == 0 and y == 0)
    -- 处理相机缩放
    XDataCenter.GuildDormManager.AllowCameraZoom(self.IsZeroDirection)
    XDataCenter.GuildDormManager.AllowTouch1ForAxis(not self.IsZeroDirection)
    -- 处理play action停止
    if not self.IsZeroDirection and self.Role:GetPlayActionId() > 0 then
        self.Role:StopPlayAction()
        XDataCenter.GuildDormManager.RequestPlayAction(-1)
    end
    -- 处理移动
    CS.XGuildDormHelper.Move(self.CharacterController
        , self.Scene:GetCamera(), x, y, dt, self.Speed, self.AngleSpeed)
    if self.IsZeroDirection then
        self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
    else
        self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.MOVE)
    end
end

return XGDMoveComponent