local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGuildDormHelper = CS.XGuildDormHelper

---@class XGDNpcRenderingComponent : XGDComponet
---@field Roles XGuildDormRole[]
---@field Npcs XGuildDormNpc[]
local XGDNpcRenderingComponent = XClass(XGDComponet, "XGDNpcRenderingComponent")

function XGDNpcRenderingComponent:Ctor()
    self.Roles= nil
    self.Npcs = nil
    self.Camera = nil
    self.CameraController = nil
end

function XGDNpcRenderingComponent:Init()
    XGDNpcRenderingComponent.Super.Init(self)
    self:SetUpdateIntervalTime(0.05)
    ---@type XGuildDormRoom
    self.Room = XDataCenter.GuildDormManager.GetCurrentRoom()
    
    self.Alpha = XGuildDormConfig.GetRoleAlpha()
    self.Distance = XGuildDormConfig.GetRoleAlphaDistance()
    self.Speed = XGuildDormConfig.GetRoleAlphaSpeed()

    self.DefaultAlpha = 1

    self:UpdateRoleDependence()
end

function XGDNpcRenderingComponent:UpdateRoleDependence()
    self.Camera = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCamera()
    self.CameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()

    local targetOffsetViewport = self.CameraController.TargetOffsetViewport
    self.OffsetViewport = Vector3(targetOffsetViewport.x, targetOffsetViewport.y, 0)
end

function XGDNpcRenderingComponent:Update(dt)
    -- 角色
    self.Roles = self.Room:GetRoles()
    for _, role in pairs(self.Roles or {}) do
        self:UpdateAlpha(role, dt)
    end
    -- Npc
    self.Npcs = self.Room:GetNpcs(true)
    for _, npc in pairs(self.Npcs or {}) do
        self:UpdateAlpha(npc, dt)
    end
end

---@param role XGuildDormBaseRole
function XGDNpcRenderingComponent:UpdateAlpha(role, dt)
    local rolePosition = role:GetRLRole():GetTransform().position + self.OffsetViewport
    if XGuildDormHelper.CheckDistanceInside(self.Camera, rolePosition, self.Distance) then
        role.TargetAlpha = self.Alpha
    else
        role.TargetAlpha = self.DefaultAlpha
    end
    role.FixAlpha = XGuildDormHelper.LerpAlpha(role.FixAlpha, role.TargetAlpha, self.Speed * dt)
    role:GetRLRole():SetAlpha(role.FixAlpha, false)
end

return XGDNpcRenderingComponent